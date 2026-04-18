# Chapter 9 — Viewing Results

## What This Folder Contains
All methods for examining SWMM simulation output: reading status and summary reports, accessing time-series data, visualizing results on the map (with animation), creating graphs (time series, profile, scatter), customizing graph appearance, generating tabular reports, and performing statistical frequency analysis.

## Files

| File | Description |
|------|-------------|
| `9.1_Viewing_a_Status_Report.md` | Status Report contents: simulation options used, error/warning messages, input data summary, rainfall file statistics, control rule actions, system-wide mass continuity errors (runoff/groundwater/conveyance), stability metrics (non-convergence frequency, Flow Instability Index, time step ranges). |
| `9.2_Viewing_Summary_Results.md` | Summary tables for: subcatchments (runoff, LID performance, groundwater), nodes (depth, inflow, surcharge, flooding hours), links (flow, pollutant loads, surcharge), storage facilities, outfall loads, street flow capture, flow classification, pumping statistics. |
| `9.3_Time_Series_Results.md` | Available time-series variables: subcatchment (rainfall, snow depth, losses, runoff, infiltration, groundwater flow/elevation), node (depth, head, volume, lateral inflow, flooding rate, water quality concentrations), link (flow, depth, velocity, capacity ratio), system-wide (temperature, pollutant concentration summaries). |
| `9.4_Viewing_Results_on_the_Map.md` | Map-based visualization: color-coded themes by any parameter, temporal animation, flyover labeling (ID + value), parameter annotations, map queries for criterion-based identification, DXF/metafile export. |
| `9.5_Viewing_Results_with_a_Graph.md` | Three graph types: Time Series Plots (up to 6 series, calibration data overlay), Profile Plots (water depth variation along connected link path — hydraulic grade line), Scatter Plots (bivariate relationships between two object parameters). Zoom and pan controls. |
| `9.6_Customizing_a_Graphs_Appearance.md` | Graph Options dialog for time series/scatter: General (colors, 3D effects, titles), Axes (gridlines, scaling, inversion), Legend (position, transparency, symbols), Styles (lines, markers, patterns, labels). Profile Plot Options: colors, styles, axes, vertical exaggeration, node labels. |
| `9.7_Viewing_Results_with_a_Table.md` | Two table formats: Table by Object (multiple variables for one object's time series), Table by Variable (one variable across multiple objects). Both support date range selection and elapsed/calendar time display. |
| `9.8_Viewing_a_Statistics_Report.md` | Statistical frequency analysis: event segregation by day/month/flow threshold; per-event statistics (mean, max, total); summary statistics (mean, std dev, skewness, median); frequency/return period estimation. 4-page report: summaries, rankings, histogram, exceedance frequency plot. |

## Key Result Variables

| Object Type | Available Time-Series Variables |
|-------------|--------------------------------|
| Subcatchment | Rainfall, snow depth, evaporation, infiltration, runoff, groundwater flow, groundwater elevation, pollutant washoff |
| Node | Depth, hydraulic head, volume, lateral inflow, flooding, surcharge, water quality concentrations |
| Link | Flow rate, depth, velocity, capacity ratio, pollutant concentrations |
| System | Temperature, total rainfall, runoff, losses, flooding, outfall loads |

## Key Terms & Concepts
- Mass continuity error (runoff, groundwater, conveyance)
- Flow Instability Index (FII): 0–150 normalized scale
- Flooding: water volume that cannot enter overloaded nodes
- Surcharge: conduit running full (pressurized)
- Capacity ratio: flow / full flow capacity (>1 = surcharged)
- Profile plot: longitudinal hydraulic grade line along selected path
- Calibration overlay: compare simulated vs. measured time series
- Statistics: event segregation, return period, exceedance probability
- LID performance summary: infiltration, evaporation, surface outflow rates

## Typical Queries This Folder Answers
- How do I check mass balance errors after a simulation?
- Which nodes are flooding and for how many hours?
- Which links are surcharged or near capacity?
- How do I create a time series plot of flow at a specific conduit?
- How do I overlay measured field data against simulated results?
- How do I view a hydraulic grade line (profile plot) along a flow path?
- How do I create a scatter plot of two variables?
- How do I customize graph axis labels, colors, and styles?
- How do I export time series data as a table for spreadsheet use?
- How do I run a frequency analysis to find the 10-year return period flow?
- How do I animate results over time on the map?
- What is the LID performance summary table?
- How do I view pump operating statistics?

## Related Sections
- Status report and troubleshooting → `chapter_08_running_a_simulation/8.5_Troubleshooting_Results.md`
- Reporting options (which objects to output) → `chapter_08_running_a_simulation/8.2_Setting_Reporting_Options.md`
- Printing/copying results → `chapter_10_printing_and_copying/`
- Map visualization features → `chapter_07_working_with_the_map/`
