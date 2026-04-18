-- ============================================================================
-- SWMM5 DuckDB Schema
-- ============================================================================
-- Purpose: Comprehensive database schema for storing SWMM5 inp file data
-- Version: 1.0
-- Created: Based on SWMM 5.2.4 GUI codebase
-- 
-- This schema supports:
-- - All SWMM5 object types (35 object categories)
-- - Spatial data using DuckDB spatial extension (deck.gl compatible)
-- - Normalized relationships with foreign keys
-- - Zero-copy data transfer to deck.gl via GeoArrow
-- ============================================================================

-- Install and load spatial extension for geometry support
INSTALL spatial;
LOAD spatial;

-- ============================================================================
-- GROUP 1: Independent Base Tables (No Dependencies)
-- ============================================================================

-- Title and Notes
CREATE TABLE title_notes (
    id INTEGER PRIMARY KEY,
    title TEXT,
    notes TEXT
);

-- Simulation Options
CREATE TABLE options (
    compatibility VARCHAR,
    report_controls VARCHAR,
    report_input VARCHAR,
    flow_units VARCHAR,
    infiltration VARCHAR,
    flow_routing VARCHAR,
    link_offsets VARCHAR,
    min_slope DOUBLE,
    allow_ponding VARCHAR,
    skip_steady_state VARCHAR,
    ignore_rainfall VARCHAR,
    ignore_rdii VARCHAR,
    ignore_snowmelt VARCHAR,
    ignore_groundwater VARCHAR,
    ignore_routing VARCHAR,
    ignore_quality VARCHAR,
    start_date DATE,
    start_time TIME,
    report_start_date DATE,
    report_start_time TIME,
    end_date DATE,
    end_time TIME,
    sweep_start VARCHAR,
    sweep_end VARCHAR,
    dry_days DOUBLE,
    report_step TIME,
    wet_step TIME,
    dry_step TIME,
    routing_step INTEGER,
    rule_step TIME,
    inertial_damping VARCHAR,
    normal_flow_limited VARCHAR,
    force_main_equation VARCHAR,
    surcharge_method VARCHAR,
    variable_step INTEGER,
    lengthening_step DOUBLE,
    min_surface_area DOUBLE,
    max_trials INTEGER,
    head_tolerance DOUBLE,
    sys_flow_tol DOUBLE,
    lat_flow_tol DOUBLE,
    minimum_step DOUBLE,
    threads INTEGER
);

-- Climatology (Temperature, Evaporation, Wind Speed, Snow Melt)
CREATE TABLE climatology (
    id VARCHAR PRIMARY KEY,
    category VARCHAR, -- TEMPERATURE, EVAPORATION, WINDSPEED, SNOWMELT
    data_type VARCHAR, -- TIMESERIES, FILE, CONSTANT, MONTHLY, etc.
    time_series_id VARCHAR,
    file_name VARCHAR,
    file_path VARCHAR,
    constant_value DOUBLE,
    monthly_values VARCHAR, -- Comma-separated 12 values
    units VARCHAR,
    comment TEXT
);

-- Tags (optional categorization)
CREATE TABLE tags (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    category VARCHAR
);

-- ============================================================================
-- GROUP 2: Lookup/Reference Tables
-- ============================================================================

-- Rain Gages
CREATE TABLE raingages (
    id VARCHAR PRIMARY KEY,
    x_coordinate DOUBLE,
    y_coordinate DOUBLE,
    description TEXT,
    tag VARCHAR,
    rain_format VARCHAR, -- INTENSITY, VOLUME, CUMULATIVE
    time_interval VARCHAR,
    snow_catch_factor DOUBLE,
    data_source VARCHAR, -- TIMESERIES, FILE
    time_series_id VARCHAR,
    file_name VARCHAR,
    file_path VARCHAR,
    station_id VARCHAR,
    rain_units VARCHAR, -- IN, MM
    geometry GEOMETRY -- POINT geometry for spatial queries
);

-- Aquifers
CREATE TABLE aquifers (
    id VARCHAR PRIMARY KEY,
    porosity DOUBLE,
    wilting_point DOUBLE,
    field_capacity DOUBLE,
    conductivity DOUBLE,
    conductivity_slope DOUBLE,
    tension_slope DOUBLE,
    upper_evap_fraction DOUBLE,
    lower_evap_depth DOUBLE,
    lower_gw_loss_rate DOUBLE,
    bottom_elevation DOUBLE,
    water_table_elevation DOUBLE,
    unsaturated_zone_moisture DOUBLE,
    lateral_flow_coeff DOUBLE,
    comment TEXT
);

-- Snow Packs
CREATE TABLE snowpacks (
    id VARCHAR PRIMARY KEY,
    surface_type VARCHAR, -- PLOWABLE, IMPERVIOUS, PERVIOUS, REMOVAL
    min_melt_coeff DOUBLE,
    max_melt_coeff DOUBLE,
    base_temp DOUBLE,
    free_water_capacity DOUBLE,
    initial_snow_depth DOUBLE,
    initial_free_water DOUBLE,
    fraction_100_cover DOUBLE,
    depth_100_cover DOUBLE,
    comment TEXT
);

-- Pollutants
CREATE TABLE pollutants (
    id VARCHAR PRIMARY KEY,
    units VARCHAR, -- MG/L, UG/L, #/L, etc.
    rain_concentration DOUBLE,
    gw_concentration DOUBLE,
    ii_concentration DOUBLE,
    dwf_concentration DOUBLE,
    decay_coefficient DOUBLE,
    snow_only_buildup VARCHAR,
    co_pollutant VARCHAR,
    co_pollutant_fraction DOUBLE,
    comment TEXT
);

-- Land Uses
CREATE TABLE landuses (
    id VARCHAR PRIMARY KEY,
    sweeping_interval DOUBLE,
    availability_fraction DOUBLE,
    last_swept_date DATE,
    buildup_function VARCHAR,
    washoff_function VARCHAR,
    comment TEXT
);

-- Unit Hydrographs
CREATE TABLE unit_hydrographs (
    id VARCHAR PRIMARY KEY,
    response_type VARCHAR, -- Short, Medium, Long
    r1 DOUBLE,
    t1 DOUBLE,
    r2 DOUBLE,
    t2 DOUBLE,
    r3 DOUBLE,
    t3 DOUBLE,
    r4 DOUBLE,
    t4 DOUBLE,
    r5 DOUBLE,
    t5 DOUBLE,
    comment TEXT
);

-- Streets
CREATE TABLE streets (
    id VARCHAR PRIMARY KEY,
    crown_width DOUBLE,
    curb_height DOUBLE,
    cross_slope_percent DOUBLE,
    mannings_n DOUBLE,
    depression_height DOUBLE,
    depression_width DOUBLE,
    number_of_sides INTEGER,
    backing_width DOUBLE,
    backing_slope DOUBLE,
    backing_mannings_n DOUBLE,
    comment TEXT
);

-- Inlets
CREATE TABLE inlets (
    id VARCHAR PRIMARY KEY,
    inlet_type VARCHAR,
    curb_length DOUBLE,
    clogging_factor DOUBLE,
    clogging_interval DOUBLE,
    last_clogged_date DATE,
    comment TEXT
);

-- ============================================================================
-- GROUP 3: Curve Tables (Metadata + Data Points)
-- ============================================================================

-- Control Curves
CREATE TABLE control_curves (
    id VARCHAR PRIMARY KEY,
    comment TEXT
);

CREATE TABLE control_curve_data (
    curve_id VARCHAR NOT NULL,
    x_value DOUBLE NOT NULL,
    y_value DOUBLE NOT NULL,
    PRIMARY KEY (curve_id, x_value),
    FOREIGN KEY (curve_id) REFERENCES control_curves(id));

-- Diversion Curves
CREATE TABLE diversion_curves (
    id VARCHAR PRIMARY KEY,
    comment TEXT
);

CREATE TABLE diversion_curve_data (
    curve_id VARCHAR NOT NULL,
    x_value DOUBLE NOT NULL,
    y_value DOUBLE NOT NULL,
    PRIMARY KEY (curve_id, x_value),
    FOREIGN KEY (curve_id) REFERENCES diversion_curves(id));

-- Pump Curves
CREATE TABLE pump_curves (
    id VARCHAR PRIMARY KEY,
    curve_type VARCHAR, -- TYPE1, TYPE2, TYPE3, TYPE4
    comment TEXT
);

CREATE TABLE pump_curve_data (
    curve_id VARCHAR NOT NULL,
    x_value DOUBLE NOT NULL,
    y_value DOUBLE NOT NULL,
    PRIMARY KEY (curve_id, x_value),
    FOREIGN KEY (curve_id) REFERENCES pump_curves(id));

-- Rating Curves
CREATE TABLE rating_curves (
    id VARCHAR PRIMARY KEY,
    comment TEXT
);

CREATE TABLE rating_curve_data (
    curve_id VARCHAR NOT NULL,
    x_value DOUBLE NOT NULL,
    y_value DOUBLE NOT NULL,
    PRIMARY KEY (curve_id, x_value),
    FOREIGN KEY (curve_id) REFERENCES rating_curves(id));

-- Shape Curves
CREATE TABLE shape_curves (
    id VARCHAR PRIMARY KEY,
    comment TEXT
);

CREATE TABLE shape_curve_data (
    curve_id VARCHAR NOT NULL,
    x_value DOUBLE NOT NULL,
    y_value DOUBLE NOT NULL,
    PRIMARY KEY (curve_id, x_value),
    FOREIGN KEY (curve_id) REFERENCES shape_curves(id));

-- Storage Curves
CREATE TABLE storage_curves (
    id VARCHAR PRIMARY KEY,
    comment TEXT
);

CREATE TABLE storage_curve_data (
    curve_id VARCHAR NOT NULL,
    x_value DOUBLE NOT NULL,
    y_value DOUBLE NOT NULL,
    PRIMARY KEY (curve_id, x_value),
    FOREIGN KEY (curve_id) REFERENCES storage_curves(id));

-- Tidal Curves
CREATE TABLE tidal_curves (
    id VARCHAR PRIMARY KEY,
    comment TEXT
);

CREATE TABLE tidal_curve_data (
    curve_id VARCHAR NOT NULL,
    x_value DOUBLE NOT NULL,
    y_value DOUBLE NOT NULL,
    PRIMARY KEY (curve_id, x_value),
    FOREIGN KEY (curve_id) REFERENCES tidal_curves(id));

-- Weir Curves
CREATE TABLE weir_curves (
    id VARCHAR PRIMARY KEY,
    comment TEXT
);

CREATE TABLE weir_curve_data (
    curve_id VARCHAR NOT NULL,
    x_value DOUBLE NOT NULL,
    y_value DOUBLE NOT NULL,
    PRIMARY KEY (curve_id, x_value),
    FOREIGN KEY (curve_id) REFERENCES weir_curves(id));

-- ============================================================================
-- GROUP 4: Time-Varying Data (Metadata + Data Points)
-- ============================================================================

-- Time Series
CREATE TABLE time_series (
    id VARCHAR PRIMARY KEY,
    description TEXT,
    file_name VARCHAR,
    file_path VARCHAR,
    comment TEXT
);

CREATE TABLE time_series_data (
    series_id VARCHAR NOT NULL,
    date_time TIMESTAMP NOT NULL,
    value DOUBLE NOT NULL,
    PRIMARY KEY (series_id, date_time),
    FOREIGN KEY (series_id) REFERENCES time_series(id));

-- Time Patterns
CREATE TABLE patterns (
    id VARCHAR PRIMARY KEY,
    pattern_type VARCHAR, -- MONTHLY, DAILY, HOURLY, WEEKEND
    comment TEXT
);

CREATE TABLE pattern_data (
    pattern_id VARCHAR NOT NULL,
    month INTEGER, -- For MONTHLY patterns (1-12)
    day INTEGER, -- For DAILY patterns (1-7)
    hour INTEGER, -- For HOURLY patterns (1-24)
    value DOUBLE NOT NULL,
    PRIMARY KEY (pattern_id, month, day, hour),
    FOREIGN KEY (pattern_id) REFERENCES patterns(id));

-- Transects
CREATE TABLE transects (
    id VARCHAR PRIMARY KEY,
    n_left_overbank DOUBLE,
    n_right_overbank DOUBLE,
    n_main_channel DOUBLE,
    left_bank_station DOUBLE,
    right_bank_station DOUBLE,
    station_modifier DOUBLE,
    elevation_modifier DOUBLE,
    meander_modifier DOUBLE,
    comment TEXT
);

CREATE TABLE transect_data (
    transect_id VARCHAR NOT NULL,
    station DOUBLE NOT NULL,
    elevation DOUBLE NOT NULL,
    PRIMARY KEY (transect_id, station),
    FOREIGN KEY (transect_id) REFERENCES transects(id));

-- ============================================================================
-- GROUP 5: LID Controls
-- ============================================================================

-- LID Controls
CREATE TABLE lid_controls (
    id VARCHAR PRIMARY KEY,
    lid_type VARCHAR, -- BIO_CELL, RAIN_GARDEN, GREEN_ROOF, etc.
    comment TEXT
);

-- LID Surface Layer
CREATE TABLE lid_surface_layer (
    lid_control_id VARCHAR PRIMARY KEY,
    surface_storage_depth DOUBLE,
    surface_vegetation_fraction DOUBLE,
    surface_roughness DOUBLE,
    surface_slope DOUBLE,
    surface_swale_side_slope DOUBLE,
    FOREIGN KEY (lid_control_id) REFERENCES lid_controls(id));

-- LID Pavement Layer
CREATE TABLE lid_pavement_layer (
    lid_control_id VARCHAR PRIMARY KEY,
    pavement_thickness DOUBLE,
    pavement_void_ratio DOUBLE,
    pavement_impervious_fraction DOUBLE,
    pavement_permeability DOUBLE,
    pavement_clogging_factor DOUBLE,
    FOREIGN KEY (lid_control_id) REFERENCES lid_controls(id));

-- LID Soil Layer
CREATE TABLE lid_soil_layer (
    lid_control_id VARCHAR PRIMARY KEY,
    soil_thickness DOUBLE,
    soil_porosity DOUBLE,
    soil_field_capacity DOUBLE,
    soil_wilting_point DOUBLE,
    soil_conductivity DOUBLE,
    soil_conductivity_slope DOUBLE,
    soil_suction_head DOUBLE,
    FOREIGN KEY (lid_control_id) REFERENCES lid_controls(id));

-- LID Storage Layer
CREATE TABLE lid_storage_layer (
    lid_control_id VARCHAR PRIMARY KEY,
    storage_height DOUBLE,
    storage_void_ratio DOUBLE,
    storage_filtration_rate DOUBLE,
    storage_clogging_factor DOUBLE,
    storage_drain_coefficient DOUBLE,
    storage_drain_exponent DOUBLE,
    storage_drain_offset DOUBLE,
    storage_drain_delay DOUBLE,
    FOREIGN KEY (lid_control_id) REFERENCES lid_controls(id));

-- LID Drain Layer
CREATE TABLE lid_drain_layer (
    lid_control_id VARCHAR PRIMARY KEY,
    drain_coefficient DOUBLE,
    drain_exponent DOUBLE,
    drain_offset DOUBLE,
    drain_delay DOUBLE,
    drain_open_level DOUBLE,
    drain_close_level DOUBLE,
    FOREIGN KEY (lid_control_id) REFERENCES lid_controls(id));

-- LID Drain Mat Layer
CREATE TABLE lid_drainmat_layer (
    lid_control_id VARCHAR PRIMARY KEY,
    drainmat_thickness DOUBLE,
    drainmat_void_ratio DOUBLE,
    drainmat_roughness DOUBLE,
    FOREIGN KEY (lid_control_id) REFERENCES lid_controls(id));

-- LID Drain Removals (for pollutant removal)
CREATE TABLE lid_drain_removals (
    lid_control_id VARCHAR NOT NULL,
    pollutant_id VARCHAR NOT NULL,
    removal_fraction DOUBLE,
    PRIMARY KEY (lid_control_id, pollutant_id),
    FOREIGN KEY (lid_control_id) REFERENCES lid_controls(id),
    FOREIGN KEY (pollutant_id) REFERENCES pollutants(id));

-- ============================================================================
-- GROUP 6: Nodes (Reference Raingages, Curves, Time Series)
-- ============================================================================

-- Junctions
CREATE TABLE junctions (
    id VARCHAR PRIMARY KEY,
    x_coordinate DOUBLE,
    y_coordinate DOUBLE,
    description TEXT,
    tag VARCHAR,
    invert_elevation DOUBLE,
    max_depth DOUBLE,
    initial_depth DOUBLE,
    surcharge_depth DOUBLE,
    ponded_area DOUBLE,
    geometry GEOMETRY -- POINT geometry
);

-- Outfalls
CREATE TABLE outfalls (
    id VARCHAR PRIMARY KEY,
    x_coordinate DOUBLE,
    y_coordinate DOUBLE,
    description TEXT,
    tag VARCHAR,
    invert_elevation DOUBLE,
    tide_gate VARCHAR, -- YES, NO
    route_to VARCHAR, -- Subcatchment ID
    boundary_type VARCHAR, -- FREE, NORMAL, FIXED, TIDAL, TIMESERIES
    fixed_stage DOUBLE,
    tidal_curve_id VARCHAR,
    time_series_id VARCHAR,
    geometry GEOMETRY, -- POINT geometry
    FOREIGN KEY (tidal_curve_id) REFERENCES tidal_curves(id),
    FOREIGN KEY (time_series_id) REFERENCES time_series(id)
);

-- Dividers
CREATE TABLE dividers (
    id VARCHAR PRIMARY KEY,
    x_coordinate DOUBLE,
    y_coordinate DOUBLE,
    description TEXT,
    tag VARCHAR,
    invert_elevation DOUBLE,
    max_depth DOUBLE,
    initial_depth DOUBLE,
    surcharge_depth DOUBLE,
    ponded_area DOUBLE,
    diverted_link_id VARCHAR,
    divider_type VARCHAR, -- CUTOFF, TABULAR, WEIR, OVERFLOW
    cutoff_flow DOUBLE,
    diversion_curve_id VARCHAR,
    min_flow DOUBLE,
    max_depth_weir DOUBLE,
    discharge_coefficient DOUBLE,
    geometry GEOMETRY, -- POINT geometry
    FOREIGN KEY (diversion_curve_id) REFERENCES diversion_curves(id)
);

-- Storage Units
CREATE TABLE storage_units (
    id VARCHAR PRIMARY KEY,
    x_coordinate DOUBLE,
    y_coordinate DOUBLE,
    description TEXT,
    tag VARCHAR,
    invert_elevation DOUBLE,
    max_depth DOUBLE,
    initial_depth DOUBLE,
    surcharge_depth DOUBLE,
    evaporation_factor DOUBLE,
    storage_curve_type VARCHAR, -- FUNCTIONAL, TABULAR
    storage_curve_coeff0 DOUBLE,
    storage_curve_coeff1 DOUBLE,
    storage_curve_coeff2 DOUBLE,
    storage_curve_id VARCHAR,
    geometry GEOMETRY, -- POINT geometry
    FOREIGN KEY (storage_curve_id) REFERENCES storage_curves(id)
);

-- ============================================================================
-- GROUP 7: Subcatchments (Reference Nodes, Raingages, Patterns, LIDs)
-- ============================================================================

-- Subcatchments
CREATE TABLE subcatchments (
    id VARCHAR PRIMARY KEY,
    x_coordinate DOUBLE,
    y_coordinate DOUBLE,
    description TEXT,
    tag VARCHAR,
    raingage_id VARCHAR,
    outlet VARCHAR, -- Node ID or Subcatchment ID
    area DOUBLE,
    width DOUBLE,
    slope_percent DOUBLE,
    imperviousness_percent DOUBLE,
    n_imperv DOUBLE,
    n_perv DOUBLE,
    dstore_imperv DOUBLE,
    dstore_perv DOUBLE,
    percent_zero_imperv DOUBLE,
    subarea_routing VARCHAR, -- OUTLET, IMPERVIOUS, PERVIOUS
    percent_routed DOUBLE,
    snowpack_id VARCHAR,
    curb_length DOUBLE,
    n_perv_pattern_id VARCHAR,
    dstore_pattern_id VARCHAR,
    infiltration_pattern_id VARCHAR,
    FOREIGN KEY (raingage_id) REFERENCES raingages(id),
    FOREIGN KEY (snowpack_id) REFERENCES snowpacks(id),
    FOREIGN KEY (n_perv_pattern_id) REFERENCES patterns(id),
    FOREIGN KEY (dstore_pattern_id) REFERENCES patterns(id),
    FOREIGN KEY (infiltration_pattern_id) REFERENCES patterns(id)
);

-- Subcatchment Geometries (Polygons)
CREATE TABLE subcatchment_geometries (
    subcatchment_id VARCHAR PRIMARY KEY,
    geometry GEOMETRY, -- POLYGON geometry
    FOREIGN KEY (subcatchment_id) REFERENCES subcatchments(id));

-- Infiltration Parameters
CREATE TABLE infiltration_parameters (
    subcatchment_id VARCHAR PRIMARY KEY,
    infiltration_model VARCHAR, -- HORTON, MODIFIED_HORTON, GREEN_AMPT, MODIFIED_GREEN_AMPT, CURVE_NUMBER
    -- Horton parameters
    max_infil_rate DOUBLE,
    min_infil_rate DOUBLE,
    decay_constant DOUBLE,
    dry_time DOUBLE,
    max_volume DOUBLE,
    -- Green-Ampt parameters
    suction_head DOUBLE,
    conductivity DOUBLE,
    initial_deficit DOUBLE,
    -- Curve Number parameters
    curve_number DOUBLE,
    conductivity_cn DOUBLE,
    dry_days_cn DOUBLE,
    FOREIGN KEY (subcatchment_id) REFERENCES subcatchments(id));

-- Groundwater Parameters
CREATE TABLE groundwater_parameters (
    subcatchment_id VARCHAR PRIMARY KEY,
    aquifer_id VARCHAR,
    node_id VARCHAR,
    surface_elevation DOUBLE,
    aquifer_bottom_elevation DOUBLE,
    water_table_elevation DOUBLE,
    lateral_flow_coefficient DOUBLE,
    surface_flow_coefficient DOUBLE,
    surface_gw_exchange_coefficient DOUBLE,
    surface_flow_exponent DOUBLE,
    gw_flow_coefficient DOUBLE,
    gw_flow_exponent DOUBLE,
    threshold_water_depth DOUBLE,
    custom_lateral_flow_equation TEXT,
    custom_deep_flow_equation TEXT,
    FOREIGN KEY (subcatchment_id) REFERENCES subcatchments(id),
    FOREIGN KEY (aquifer_id) REFERENCES aquifers(id),
    FOREIGN KEY (node_id) REFERENCES junctions(id)
);

-- LID Usage
CREATE TABLE lid_usage (
    subcatchment_id VARCHAR NOT NULL,
    lid_control_id VARCHAR NOT NULL,
    number_of_units INTEGER,
    area_per_unit DOUBLE,
    width_per_unit DOUBLE,
    initial_saturation DOUBLE,
    from_impervious_percent DOUBLE,
    to_pervious_percent DOUBLE,
    report_file_name VARCHAR,
    drain_to VARCHAR, -- Node ID
    initial_depth DOUBLE,
    PRIMARY KEY (subcatchment_id, lid_control_id),
    FOREIGN KEY (subcatchment_id) REFERENCES subcatchments(id),
    FOREIGN KEY (lid_control_id) REFERENCES lid_controls(id));

-- Land Use Assignments
CREATE TABLE subcatchment_landuses (
    subcatchment_id VARCHAR NOT NULL,
    landuse_id VARCHAR NOT NULL,
    area_fraction DOUBLE,
    PRIMARY KEY (subcatchment_id, landuse_id),
    FOREIGN KEY (subcatchment_id) REFERENCES subcatchments(id),
    FOREIGN KEY (landuse_id) REFERENCES landuses(id));

-- Initial Buildup
CREATE TABLE initial_buildup (
    subcatchment_id VARCHAR NOT NULL,
    landuse_id VARCHAR NOT NULL,
    pollutant_id VARCHAR NOT NULL,
    initial_buildup_value DOUBLE,
    PRIMARY KEY (subcatchment_id, landuse_id, pollutant_id),
    FOREIGN KEY (subcatchment_id) REFERENCES subcatchments(id),
    FOREIGN KEY (landuse_id) REFERENCES landuses(id),
    FOREIGN KEY (pollutant_id) REFERENCES pollutants(id));

-- ============================================================================
-- GROUP 8: Links (Reference Nodes, Curves, Transects, Inlets)
-- ============================================================================

-- Conduits
CREATE TABLE conduits (
    id VARCHAR PRIMARY KEY,
    inlet_node_id VARCHAR NOT NULL,
    outlet_node_id VARCHAR NOT NULL,
    description TEXT,
    tag VARCHAR,
    shape VARCHAR, -- CIRCULAR, RECT_CLOSED, RECT_OPEN, TRAPEZOIDAL, TRIANGULAR, etc.
    max_depth DOUBLE,
    length DOUBLE,
    roughness DOUBLE,
    inlet_offset DOUBLE,
    outlet_offset DOUBLE,
    initial_flow DOUBLE,
    maximum_flow DOUBLE,
    entry_loss_coefficient DOUBLE,
    exit_loss_coefficient DOUBLE,
    avg_loss_coefficient DOUBLE,
    seepage_loss_rate DOUBLE,
    flap_gate VARCHAR, -- YES, NO
    culvert_code VARCHAR,
    inlet_indicator VARCHAR,
    width_param DOUBLE,
    left_slope DOUBLE,
    right_slope DOUBLE,
    barrels INTEGER,
    transect_id VARCHAR,
    FOREIGN KEY (inlet_node_id) REFERENCES junctions(id),
    FOREIGN KEY (outlet_node_id) REFERENCES junctions(id),
    FOREIGN KEY (transect_id) REFERENCES transects(id)
);

-- Pumps
CREATE TABLE pumps (
    id VARCHAR PRIMARY KEY,
    inlet_node_id VARCHAR NOT NULL,
    outlet_node_id VARCHAR NOT NULL,
    description TEXT,
    tag VARCHAR,
    pump_curve_id VARCHAR,
    initial_status VARCHAR, -- ON, OFF
    startup_depth DOUBLE,
    shutoff_depth DOUBLE,
    FOREIGN KEY (inlet_node_id) REFERENCES junctions(id),
    FOREIGN KEY (outlet_node_id) REFERENCES junctions(id),
    FOREIGN KEY (pump_curve_id) REFERENCES pump_curves(id)
);

-- Orifices
CREATE TABLE orifices (
    id VARCHAR PRIMARY KEY,
    inlet_node_id VARCHAR NOT NULL,
    outlet_node_id VARCHAR NOT NULL,
    description TEXT,
    tag VARCHAR,
    orifice_type VARCHAR, -- SIDE, BOTTOM
    shape VARCHAR, -- CIRCULAR, RECT_CLOSED
    height DOUBLE,
    width DOUBLE,
    inlet_offset DOUBLE,
    discharge_coefficient DOUBLE,
    flap_gate VARCHAR, -- YES, NO
    time_to_open_close DOUBLE,
    FOREIGN KEY (inlet_node_id) REFERENCES junctions(id),
    FOREIGN KEY (outlet_node_id) REFERENCES junctions(id)
);

-- Weirs
CREATE TABLE weirs (
    id VARCHAR PRIMARY KEY,
    inlet_node_id VARCHAR NOT NULL,
    outlet_node_id VARCHAR NOT NULL,
    description TEXT,
    tag VARCHAR,
    weir_type VARCHAR, -- TRANSVERSE, SIDEFLOW, V-NOTCH, TRAPEZOIDAL, ROADWAY
    height DOUBLE,
    length DOUBLE,
    side_slope DOUBLE,
    inlet_offset DOUBLE,
    discharge_coefficient DOUBLE,
    flap_gate VARCHAR, -- YES, NO
    end_contractions INTEGER,
    end_coefficient DOUBLE,
    can_surcharge VARCHAR, -- YES, NO
    coeff_curve_id VARCHAR,
    road_width DOUBLE,
    road_surface VARCHAR, -- PAVED, GRAVEL
    FOREIGN KEY (inlet_node_id) REFERENCES junctions(id),
    FOREIGN KEY (outlet_node_id) REFERENCES junctions(id),
    FOREIGN KEY (coeff_curve_id) REFERENCES weir_curves(id)
);

-- Outlets
CREATE TABLE outlets (
    id VARCHAR PRIMARY KEY,
    inlet_node_id VARCHAR NOT NULL,
    outlet_node_id VARCHAR NOT NULL,
    description TEXT,
    tag VARCHAR,
    inlet_offset DOUBLE,
    flap_gate VARCHAR, -- YES, NO
    rating_curve_type VARCHAR, -- FUNCTIONAL/DEPTH, TABULAR/DEPTH, FUNCTIONAL/HEAD, TABULAR/HEAD
    discharge_coefficient DOUBLE,
    discharge_exponent DOUBLE,
    rating_curve_id VARCHAR,
    FOREIGN KEY (inlet_node_id) REFERENCES junctions(id),
    FOREIGN KEY (outlet_node_id) REFERENCES junctions(id),
    FOREIGN KEY (rating_curve_id) REFERENCES rating_curves(id)
);

-- Link Geometries (LineStrings)
-- Note: link_id can reference any link type (conduit, pump, orifice, weir, outlet)
-- Foreign key constraint not enforced here due to multiple parent tables
CREATE TABLE link_geometries (
    link_id VARCHAR PRIMARY KEY,
    link_type VARCHAR NOT NULL, -- CONDUIT, PUMP, ORIFICE, WEIR, OUTLET
    geometry GEOMETRY -- LINESTRING geometry
);

-- Link Vertices (for polylines with intermediate points)
-- Note: link_id can reference any link type (conduit, pump, orifice, weir, outlet)
-- Foreign key constraint not enforced here due to multiple parent tables
CREATE TABLE link_vertices (
    link_id VARCHAR NOT NULL,
    vertex_order INTEGER NOT NULL,
    x_coordinate DOUBLE NOT NULL,
    y_coordinate DOUBLE NOT NULL,
    PRIMARY KEY (link_id, vertex_order)
);

-- Inlet Assignments
CREATE TABLE inlet_assignments (
    link_id VARCHAR NOT NULL,
    inlet_id VARCHAR NOT NULL,
    PRIMARY KEY (link_id, inlet_id),
    FOREIGN KEY (link_id) REFERENCES conduits(id),
    FOREIGN KEY (inlet_id) REFERENCES inlets(id));

-- ============================================================================
-- GROUP 9: Complex Sub-Properties
-- ============================================================================

-- External Inflows (Direct, Dry Weather, RDII)
CREATE TABLE external_inflows (
    node_id VARCHAR NOT NULL,
    inflow_type VARCHAR, -- DIRECT, DRY_WEATHER, RDII
    time_series_id VARCHAR,
    baseline_value DOUBLE,
    baseline_pattern_id VARCHAR,
    scale_factor DOUBLE,
    pollutant_id VARCHAR,
    pollutant_concentration DOUBLE,
    pollutant_pattern_id VARCHAR,
    PRIMARY KEY (node_id, inflow_type, pollutant_id),
    FOREIGN KEY (node_id) REFERENCES junctions(id),
    FOREIGN KEY (time_series_id) REFERENCES time_series(id),
    FOREIGN KEY (baseline_pattern_id) REFERENCES patterns(id),
    FOREIGN KEY (pollutant_id) REFERENCES pollutants(id),
    FOREIGN KEY (pollutant_pattern_id) REFERENCES patterns(id)
);

-- Treatment Functions
CREATE TABLE treatment_functions (
    node_id VARCHAR NOT NULL,
    pollutant_id VARCHAR NOT NULL,
    treatment_function TEXT,
    PRIMARY KEY (node_id, pollutant_id),
    FOREIGN KEY (node_id) REFERENCES junctions(id),
    FOREIGN KEY (pollutant_id) REFERENCES pollutants(id));

-- Control Rules
CREATE TABLE control_rules (
    id VARCHAR PRIMARY KEY,
    rule_text TEXT NOT NULL,
    comment TEXT
);

-- Cross Sections (for conduits with custom shapes)
CREATE TABLE cross_sections (
    conduit_id VARCHAR PRIMARY KEY,
    shape_type VARCHAR,
    max_depth DOUBLE,
    geom1 DOUBLE,
    geom2 DOUBLE,
    geom3 DOUBLE,
    geom4 DOUBLE,
    barrels INTEGER,
    culvert_code VARCHAR,
    FOREIGN KEY (conduit_id) REFERENCES conduits(id));

-- Losses (for conduits)
CREATE TABLE conduit_losses (
    conduit_id VARCHAR PRIMARY KEY,
    entry_loss_coefficient DOUBLE,
    exit_loss_coefficient DOUBLE,
    avg_loss_coefficient DOUBLE,
    seepage_loss_rate DOUBLE,
    FOREIGN KEY (conduit_id) REFERENCES conduits(id));

-- Storage Unit Seepage
CREATE TABLE storage_seepage (
    storage_unit_id VARCHAR PRIMARY KEY,
    conductivity DOUBLE,
    porosity DOUBLE,
    wilting_point DOUBLE,
    field_capacity DOUBLE,
    suction_head DOUBLE,
    conductivity_slope DOUBLE,
    FOREIGN KEY (storage_unit_id) REFERENCES storage_units(id));

-- ============================================================================
-- GROUP 10: Map Elements
-- ============================================================================

-- Map Labels
CREATE TABLE map_labels (
    id VARCHAR PRIMARY KEY,
    text VARCHAR NOT NULL,
    x_coordinate DOUBLE NOT NULL,
    y_coordinate DOUBLE NOT NULL,
    anchor_node_id VARCHAR,
    anchor_subcatchment_id VARCHAR,
    font_name VARCHAR,
    font_size INTEGER,
    font_style VARCHAR,
    font_color INTEGER,
    geometry GEOMETRY, -- POINT geometry
    FOREIGN KEY (anchor_node_id) REFERENCES junctions(id),
    FOREIGN KEY (anchor_subcatchment_id) REFERENCES subcatchments(id)
);

-- ============================================================================
-- INDEXES for Performance
-- ============================================================================

-- Spatial indexes (DuckDB spatial extension - using standard index syntax)
-- Note: DuckDB may optimize spatial queries automatically, but explicit indexes help
CREATE INDEX idx_raingages_geometry ON raingages(geometry);
CREATE INDEX idx_junctions_geometry ON junctions(geometry);
CREATE INDEX idx_outfalls_geometry ON outfalls(geometry);
CREATE INDEX idx_dividers_geometry ON dividers(geometry);
CREATE INDEX idx_storage_units_geometry ON storage_units(geometry);
CREATE INDEX idx_subcatchment_geometries_geometry ON subcatchment_geometries(geometry);
CREATE INDEX idx_link_geometries_geometry ON link_geometries(geometry);
CREATE INDEX idx_map_labels_geometry ON map_labels(geometry);

-- Foreign key indexes
CREATE INDEX idx_subcatchments_raingage ON subcatchments(raingage_id);
CREATE INDEX idx_subcatchments_outlet ON subcatchments(outlet);
CREATE INDEX idx_conduits_inlet_node ON conduits(inlet_node_id);
CREATE INDEX idx_conduits_outlet_node ON conduits(outlet_node_id);
CREATE INDEX idx_pumps_inlet_node ON pumps(inlet_node_id);
CREATE INDEX idx_pumps_outlet_node ON pumps(outlet_node_id);
CREATE INDEX idx_orifices_inlet_node ON orifices(inlet_node_id);
CREATE INDEX idx_orifices_outlet_node ON orifices(outlet_node_id);
CREATE INDEX idx_weirs_inlet_node ON weirs(inlet_node_id);
CREATE INDEX idx_weirs_outlet_node ON weirs(outlet_node_id);
CREATE INDEX idx_outlets_inlet_node ON outlets(inlet_node_id);
CREATE INDEX idx_outlets_outlet_node ON outlets(outlet_node_id);
CREATE INDEX idx_time_series_data_series ON time_series_data(series_id);
CREATE INDEX idx_time_series_data_datetime ON time_series_data(date_time);
CREATE INDEX idx_pattern_data_pattern ON pattern_data(pattern_id);
CREATE INDEX idx_curve_data_curves ON control_curve_data(curve_id);
CREATE INDEX idx_external_inflows_node ON external_inflows(node_id);
CREATE INDEX idx_treatment_functions_node ON treatment_functions(node_id);
CREATE INDEX idx_lid_usage_subcatchment ON lid_usage(subcatchment_id);
CREATE INDEX idx_subcatchment_landuses_subcatchment ON subcatchment_landuses(subcatchment_id);
CREATE INDEX idx_initial_buildup_subcatchment ON initial_buildup(subcatchment_id);

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================

