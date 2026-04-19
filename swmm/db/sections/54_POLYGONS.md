# [POLYGONS]

**Purpose:** Stores the ordered sequence of X,Y map-coordinate vertices that define the closed-polygon outline of each subcatchment (and, in the GUI's extended usage, of each storage node) on the SWMM Study Area Map. The polygon is used solely for visualisation: it is drawn on screen by the GUI, it drives centroid computation for the subcatchment's map position, and it is exported to CAD/GIS tools. It plays no role whatsoever in any hydrological or hydraulic computation — the engine's command-line mode ignores the section entirely.

**Occurrence:** multiple rows per object. Each subcatchment (or storage node) that has a polygon outline contributes one INP row per vertex. Subcatchments with zero or one vertex are silently omitted from the section; subcatchments with exactly two vertices display only a centroid symbol and no filled polygon. There is no fixed row count per object; the polygon may have as few as three vertices or many dozens. Rows for the same object must appear consecutively because the GUI reader appends each vertex to the in-progress list for the current object. All subcatchment polygon vertices appear first, followed (within the same `[Polygons]` section header) by storage-node polygon vertices.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/text.h:446` — macro `ws_POLYGON "[POLYGON"` (prefix-match token); `swmm524_engine/src/enums.h:468` — enum value `s_POLYGON`; `swmm524_engine/src/keywords.c:139` — entry in `SectWords[]`; `swmm524_engine/src/input.c:631` — `parseLine()` `default: return 0;` branch — the engine silently discards all map-section data including `[POLYGONS]`; no dedicated parse function exists in the engine.
- Engine writer: engine does not write INP files; no echo of polygon data appears in report output.
- GUI reader: `Uimport.pas:2638` — function `ReadPolygonData`; dispatched at `Uimport.pas:2924` (case 40 in the section-dispatch switch).
- GUI writer: `Uexport.pas:2103` — procedure `ExportMap`; polygon export at `Uexport.pas:2186–2233`.
- GUI editor dialog(s): vertices are managed interactively via the Map Toolbar vertex-editing mode (`Uvertex.pas`, `Umap.pas`); no dedicated dialog form. `TVertexList` class defined in `Uvertex.pas:35`.
- Manual: `appendix_D_command_line_swmm/D.3_Map_Data_Section.md` — Section `[POLYGONS]` (lines 78–94).
- Additional manual refs: `chapter_06_working_with_objects/6.2_Adding_Objects.md` (drawing subcatchment polygons); `chapter_06_working_with_objects/6.8_Shaping_a_Subcatchment.md` (vertex editing); `appendix_D_command_line_swmm/D.3_Map_Data_Section.md` (complete map-section description).

## Row Format

Each data line carries exactly three whitespace-delimited tokens:

```
Subcat  Xcoord  Ycoord
```

Where `Subcat` is the subcatchment (or storage node) name and `Xcoord`/`Ycoord` are floating-point map coordinates. The GUI writes each field left-justified in a fixed-width column separated by a tab (or space when not tab-delimited), using `Format('%-16s', [name])` for the name and `Format('%-18.<D>f', [coord])` for coordinates, where `D` is the map's decimal-digit precision setting (`Uexport.pas:2125`). Comment lines starting with `;;` precede each subsection (subcatchments and storage nodes). The section keyword as written by the GUI is `[Polygons]` (mixed case), but the engine/GUI parser matches by prefix `[POLYGON` (case-insensitive prefix match via `ws_POLYGON`).

## Fields

### Subcat

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match the name of an existing subcatchment in `[SUBCATCHMENTS]`, or — per the GUI's extended behaviour — an existing storage node in `[STORAGE]`. The GUI reader (`Uimport.pas:2653`) first looks up the token in `Project.Lists[SUBCATCH]`; if not found it falls back to `Project.Lists[STORAGE]` (`Uimport.pas:2659–2661`). Tokens that match neither list are silently ignored (no vertex is appended, no error is raised). The manual only mentions subcatchments; storage-node polygon support is a GUI-only extension.
- **Default:** none (field is mandatory)
- **Cross-section dependency:** `[SUBCATCHMENTS].Name` (primary path); `[STORAGE].Name` (storage-node fallback, GUI only).
- **Database-key hint:** foreign key to `[SUBCATCHMENTS].Name` (or `[STORAGE].Name` for storage nodes); combined with vertex sequence number forms composite PK.
- **Technical description:** Identifies which object's polygon the vertex row extends. All vertices for a given object must appear in consecutive rows. A new object begins when the name changes. The GUI reader appends each parsed (X,Y) vertex to the `TVertexList` (`Vlist`) of the matched object (`Uimport.pas:2671`). When loading is complete, `TSubcatch.SetCentroid` (`Uproject.pas:1627`) is called to compute the polygon centroid via `TVertexList.PolygonCentroid` (`Uvertex.pas:304`), which uses the Graphics Gems IV signed-area formula; the result becomes the subcatchment's `(X,Y)` map position. The polygon is drawn as a filled, framed shape by `Umap.pas` when the vertex count is ≥ 3; with ≤ 2 vertices only the centroid symbol is shown (`chapter_06_working_with_objects/6.8_Shaping_a_Subcatchment.md:8`).
- **Source of truth:** `Uimport.pas:2652–2655` (subcatchment lookup), `Uimport.pas:2658–2661` (storage-node fallback).

### Xcoord

- **Data type:** REAL
- **Required:** yes
- **Units:** map coordinate units as declared in `[MAP]` UNITS keyword: Feet / Meters / Degrees / None. When UNITS is None the coordinate system is arbitrary (no real-world projection). Coordinates are always stored as `Extended` (80-bit float) internally (`Uvertex.pas:27`).
- **Valid values / range:** any real number; must be parseable by `Uutils.GetExtended` (`Uimport.pas:2667`). No explicit range constraint is enforced; the map bounding rectangle declared in `[MAP]` DIMENSIONS implicitly defines a valid extent but the parser does not check against it.
- **Default:** none (field is mandatory)
- **Cross-section dependency:** None.
- **Database-key hint:** plain data — no key role; participates in composite PK only when combined with `Subcat` + vertex sequence index.
- **Technical description:** Horizontal (east) coordinate of this vertex relative to the map's lower-left origin. The origin and extent are set by the `[MAP]` DIMENSIONS record; coordinates should lie within that bounding rectangle for the vertex to be visible, but the parser does not enforce this. The PolygonArea and PolygonCentroid computations in `Uvertex.pas:413` and `Uvertex.pas:304` use a numerically scaled (shifted by minimum X,Y) shoelace formula to avoid floating-point cancellation for large coordinates.
- **Source of truth:** `Uimport.pas:2667` (parse and range validation call), `Uvertex.pas:27` (storage type).

### Ycoord

- **Data type:** REAL
- **Required:** yes
- **Units:** same as `Xcoord` — map coordinate units declared in `[MAP]` UNITS. The map's Y axis has its origin at the lower-left (south) of the bounding rectangle, so Y increases northward.
- **Valid values / range:** any real number; must be parseable by `Uutils.GetExtended` (`Uimport.pas:2669`).
- **Default:** none (field is mandatory)
- **Cross-section dependency:** None.
- **Database-key hint:** plain data — no key role.
- **Technical description:** Vertical (north) coordinate of this vertex. Together with `Xcoord` it defines one vertex of the subcatchment's outline polygon. The GUI's polygon-drawing code (`Umap.pas:828–836`) converts stored (X,Y) map coordinates to screen pixel coordinates via the map transform before passing the resulting point array to `Canvas.Polygon`. The signed-area centroid formula in `Uvertex.pas:367–388` uses both X and Y to compute the weighted centroid.
- **Source of truth:** `Uimport.pas:2669` (parse), `Uvertex.pas:367` (use in centroid formula).

## Notes

- **GUI-only section.** The SWMM computational engine recognises `[POLYGON` as a valid section keyword (it appears in `SectWords[]` at `keywords.c:139` and maps to `s_POLYGON` in `enums.h:468`), but `parseLine()` in `input.c:631` falls through to `default: return 0;` for this section code. No data is read, no error is raised. The section is entirely irrelevant to command-line SWMM runs and to all simulation results.

- **Vertex ordering.** The manual (`D.3_Map_Data_Section.md:94`) states vertices must appear "ordered in a consistent clockwise or counter-clockwise sequence." The GUI does not enforce a specific winding direction during interactive polygon creation (the user clicks vertices in whatever order they choose). The PolygonCentroid and PolygonArea functions in `Uvertex.pas:304` and `Uvertex.pas:413` use the absolute value of the signed area (`Abs(A)/2.0` at `Uvertex.pas:464`) so they are winding-direction agnostic. The polygon is drawn with `Canvas.Polygon` which also ignores winding direction for screen rendering. In practice files produced by the GUI may be CW or CCW depending on user drawing direction.

- **No explicit closure vertex.** The polygon ring is implicitly closed: the GUI does not write a repeated first-vertex at the end, and `Canvas.Polygon` automatically closes the ring. A database designer must be aware that the ring is open (last vertex ≠ first vertex) in the INP representation.

- **Minimum vertex count.** A subcatchment with fewer than 3 vertices has no renderable polygon; the GUI displays only the centroid symbol (`6.8_Shaping_a_Subcatchment.md:8`). A subcatchment with exactly 2 vertices still contributes 2 rows to the section but produces no filled polygon. A subcatchment with 0 vertices contributes no rows at all and is absent from the section.

- **Storage-node polygon (undocumented extension).** The GUI `ReadPolygonData` (`Uimport.pas:2659`) and `ExportMap` (`Uexport.pas:2211–2233`) also handle storage-node polygons within the same `[Polygons]` section, writing them after the subcatchment entries with a `;;Storage Node` comment header. This is not documented in the manual and is not mentioned in the D.3 section. The engine ignores it identically. A DB designer must therefore allow `Subcat` to reference either `[SUBCATCHMENTS].Name` or `[STORAGE].Name`.

- **Section header case sensitivity.** The GUI writes `[Polygons]` (initial cap only, `Uexport.pas:2187`) but reads `[POLYGONS` (case-folded prefix match per `ws_POLYGON "[POLYGON"` in `text.h:446`). Any capitalisation of `[POLYGON…]` is accepted by both the GUI reader and the engine's section-keyword matcher.

- **Composite key and ordering.** There is no explicit sequence-number column in the INP format. The vertex order is entirely positional (insertion order in the linked list `TVertexList`). A relational schema must add a surrogate sequence column (e.g., `vertex_seq INTEGER`) to preserve the polygon ring order. The natural composite PK for a normalised vertex table is `(subcatch_name, vertex_seq)`.

- **GeoPackage geometry-column suitability.** Because `[POLYGONS]` stores the complete set of outline vertices for each subcatchment as an ordered, implicitly-closed ring, the natural database representation is a **GeoPackage GEOMETRY column of type POLYGON** (OGC Simple Features) on a table keyed by subcatchment name, rather than a normalised vertex table. This approach:
  - Preserves ring topology and winding order in a single atomic value.
  - Enables spatial queries (containment, area, intersection) via SpatiaLite or GDAL without reconstructing the ring from rows.
  - Matches how GIS tools (QGIS, ArcGIS, PostGIS) natively represent subcatchment boundaries imported from SWMM.
  - Requires that the map coordinate system be known (recorded from `[MAP]` UNITS) so an SRID can be assigned; when UNITS is `None` the SRID should be 0 (undefined).
  
  However, a normalised vertex table `(subcatch_name TEXT, vertex_seq INTEGER, x REAL, y REAL)` is also valid and avoids a geometry-capable driver dependency. Either design must account for the storage-node polygon extension. If a POLYGON geometry column is chosen, storage-node polygons belong in a separate `storage_polygons` geometry layer keyed by `[STORAGE].Name`, because mixing subcatchment and node geometries in one layer would produce a heterogeneous feature type.

- **No units conversion.** Coordinates are written and read as raw floating-point values in whatever map units the project declares. No unit conversion is applied during export or import.

- **Interaction with [MAP] section.** The bounding rectangle defined in `[MAP]` DIMENSIONS determines the visible map extent but does not constrain polygon vertex coordinates. The coordinates stored here must be interpreted relative to the same origin and units declared in `[MAP]`.
