# SWMM5 DuckDB Schema Documentation

## Overview

This schema provides a comprehensive database structure for storing SWMM5 (Storm Water Management Model) inp file data in DuckDB. The schema is designed to:

- Store all 35 SWMM5 object types
- Support spatial data using DuckDB's spatial extension (compatible with deck.gl via GeoArrow)
- Maintain normalized relationships with foreign keys
- Enable zero-copy data transfer to deck.gl for visualization

## Files

- `swmm5_schema.sql` - Main SQL schema file with all table definitions
- `swmm5_column_mapping.json` - JSON mapping of database column names to UI field names
- `swmm5_schema_README.md` - This documentation file

## Installation

1. Ensure DuckDB is installed with spatial extension support
2. Run the schema file:
   ```sql
   .read swmm5_schema.sql
   ```
   Or in DuckDB CLI:
   ```bash
   duckdb my_database.db < swmm5_schema.sql
   ```

## Schema Structure

### Table Groups (in dependency order)

1. **Independent Base Tables**: `title_notes`, `options`, `climatology`, `tags`
2. **Lookup/Reference Tables**: `raingages`, `aquifers`, `snowpacks`, `pollutants`, `landuses`, `unit_hydrographs`, `streets`, `inlets`
3. **Curve Tables**: 8 curve types, each with metadata table + data points table
4. **Time-Varying Data**: `time_series`, `patterns`, `transects` (each with data tables)
5. **LID Controls**: `lid_controls` + 7 layer property tables
6. **Nodes**: `junctions`, `outfalls`, `dividers`, `storage_units`
7. **Subcatchments**: `subcatchments` + geometry, infiltration, groundwater, LID usage, land use, buildup tables
8. **Links**: `conduits`, `pumps`, `orifices`, `weirs`, `outlets` + geometry and vertex tables
9. **Complex Sub-Properties**: `external_inflows`, `treatment_functions`, `control_rules`, `cross_sections`, `losses`, `storage_seepage`
10. **Map Elements**: `map_labels`

## Spatial Data

All spatial data is stored using DuckDB's `GEOMETRY` type:

- **Nodes** (junctions, outfalls, dividers, storage units): `POINT` geometries
- **Subcatchments**: `POLYGON` geometries  
- **Links** (conduits, pumps, orifices, weirs, outlets): `LINESTRING` geometries
- **Rain Gages**: `POINT` geometries
- **Map Labels**: `POINT` geometries

### Creating Geometries

Example for creating a point geometry:
```sql
INSERT INTO junctions (id, geometry)
VALUES ('J1', ST_GeomFromText('POINT(100.0 200.0)'));
```

Example for creating a polygon:
```sql
INSERT INTO subcatchment_geometries (subcatchment_id, geometry)
VALUES ('S1', ST_GeomFromText('POLYGON((0 0, 100 0, 100 100, 0 100, 0 0))'));
```

Example for creating a linestring:
```sql
INSERT INTO link_geometries (link_id, link_type, geometry)
VALUES ('C1', 'CONDUIT', ST_GeomFromText('LINESTRING(0 0, 100 100)'));
```

## Important Notes

### Link Geometries and Vertices

The `link_geometries` and `link_vertices` tables can reference any link type (conduits, pumps, orifices, weirs, outlets). Since DuckDB doesn't support foreign keys that reference multiple parent tables, these tables don't have foreign key constraints. When querying, ensure `link_id` and `link_type` match the appropriate parent table.

Example query to get all link geometries:
```sql
SELECT lg.*, c.id as conduit_id, p.id as pump_id
FROM link_geometries lg
LEFT JOIN conduits c ON lg.link_id = c.id AND lg.link_type = 'CONDUIT'
LEFT JOIN pumps p ON lg.link_id = p.id AND lg.link_type = 'PUMP'
-- ... similar for other link types
```

### Curve Data

All curve types (control, diversion, pump, rating, shape, storage, tidal, weir) follow the same pattern:
- Metadata table: `{curve_type}_curves` (e.g., `pump_curves`)
- Data points table: `{curve_type}_curve_data` (e.g., `pump_curve_data`)

### Time Series and Patterns

- `time_series` stores metadata, `time_series_data` stores the actual time-value pairs
- `patterns` stores metadata, `pattern_data` stores pattern values (monthly/daily/hourly/weekend)

### LID Controls

LID controls have a hierarchical structure:
- `lid_controls` - Main table
- `lid_surface_layer`, `lid_pavement_layer`, `lid_soil_layer`, `lid_storage_layer`, `lid_drain_layer`, `lid_drainmat_layer` - Layer properties
- `lid_drain_removals` - Pollutant removal fractions

### Subcatchment Relationships

Subcatchments can reference:
- Rain gages (via `raingage_id`)
- Outlet nodes or other subcatchments (via `outlet`)
- Snow packs (via `snowpack_id`)
- Patterns (for N-perv, Dstore, infiltration adjustments)
- Multiple LID controls (via `lid_usage` table)
- Multiple land uses (via `subcatchment_landuses` table)

## Querying Examples

### Get all nodes with their geometries:
```sql
SELECT j.id, j.invert_elevation, j.geometry
FROM junctions j
UNION ALL
SELECT o.id, o.invert_elevation, o.geometry
FROM outfalls o
UNION ALL
SELECT d.id, d.invert_elevation, d.geometry
FROM dividers d
UNION ALL
SELECT s.id, s.invert_elevation, s.geometry
FROM storage_units s;
```

### Get all links with their geometries:
```sql
SELECT c.id, c.inlet_node_id, c.outlet_node_id, lg.geometry
FROM conduits c
LEFT JOIN link_geometries lg ON c.id = lg.link_id AND lg.link_type = 'CONDUIT'
UNION ALL
SELECT p.id, p.inlet_node_id, p.outlet_node_id, lg.geometry
FROM pumps p
LEFT JOIN link_geometries lg ON p.id = lg.link_id AND lg.link_type = 'PUMP';
-- ... similar for other link types
```

### Get subcatchments with their polygons:
```sql
SELECT s.*, sg.geometry
FROM subcatchments s
LEFT JOIN subcatchment_geometries sg ON s.id = sg.subcatchment_id;
```

## Exporting for deck.gl

To export spatial data for deck.gl visualization, you can use DuckDB's spatial functions:

```sql
-- Export nodes as GeoJSON
SELECT 
    id,
    ST_AsGeoJSON(geometry) as geometry
FROM junctions;

-- Export subcatchments as GeoJSON
SELECT 
    s.id,
    ST_AsGeoJSON(sg.geometry) as geometry
FROM subcatchments s
JOIN subcatchment_geometries sg ON s.id = sg.subcatchment_id;

-- Export links as GeoJSON
SELECT 
    link_id,
    link_type,
    ST_AsGeoJSON(geometry) as geometry
FROM link_geometries;
```

For zero-copy transfer to deck.gl via GeoArrow, DuckDB's spatial extension should automatically handle the conversion when using appropriate query patterns.

## Column Name Mapping

The `swmm5_column_mapping.json` file provides a mapping between database column names (snake_case) and UI field names (as displayed in SWMM5 GUI). Use this file to:

- Display user-friendly field names in your application
- Map UI input to database columns
- Generate forms and reports with proper labels

## Performance Considerations

1. **Indexes**: The schema includes indexes on foreign keys and commonly queried columns
2. **Spatial Queries**: DuckDB's spatial extension optimizes spatial queries automatically
3. **Large Datasets**: For very large models, consider partitioning time series data by date ranges

## Maintenance

- **Backup**: Regularly backup your DuckDB database file
- **Vacuum**: Run `VACUUM` periodically to reclaim space
- **Analyze**: Run `ANALYZE` to update statistics for query optimization

## Version Compatibility

This schema is designed for SWMM5 version 5.2.4. For other versions, some fields may need adjustment.

## Support

For issues or questions:
- SWMM5 Documentation: https://www.epa.gov/water-research/storm-water-management-model-swmm
- DuckDB Documentation: https://duckdb.org/docs/
- DuckDB Spatial Extension: https://duckdb.org/docs/extensions/spatial


