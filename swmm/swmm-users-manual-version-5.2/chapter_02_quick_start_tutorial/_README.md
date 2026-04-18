# Chapter 2 — Quick Start Tutorial

## What This Folder Contains
A complete step-by-step walkthrough modeling a 12-acre residential drainage system. Covers the full SWMM workflow from project creation through water quality analysis and long-term continuous simulation with statistical frequency analysis.

## Files

| File | Description |
|------|-------------|
| `2.1_Example_Study_Area.md` | Introduces the tutorial system: 3 subcatchments (S1–S3), 4 conduits (C1–C4), 4 junctions (J1–J4), 1 outfall. Baseline geometry and connectivity used throughout the tutorial. |
| `2.2_Project_Setup.md` | Launching SWMM, configuring project defaults (ID prefixes, subcatchment parameters, node/link properties, infiltration model), setting map display options, verifying map dimensions. |
| `2.3_Drawing_Objects.md` | Drawing drainage objects on the map: subcatchments (polygon vertices), junction/outfall nodes (click), conduits (connect nodes), rain gages; moving and reshaping with vertex selection mode. |
| `2.4_Setting_Object_Properties.md` | Editing properties via Property Editor; group editing (setting multiple subcatchment outlets at once); assigning invert elevations, pipe diameters, rain gage time series; saving the project. |
| `2.5_Running_a_Simulation.md` | Configure Kinematic Wave routing and time steps; run simulation; interpret status report (mass balance, infiltration, runoff); read summary reports (flooding, surcharge); view color-coded map results; create time series and profile plots; switch to Dynamic Wave routing. |
| `2.6_Simulating_Water_Quality.md` | Define TSS and Lead pollutants; create Residential and Undeveloped land uses; set buildup/washoff functions; assign land use mixtures to subcatchments; specify antecedent dry days; run and interpret quality continuity report. |
| `2.7_Running_a_Continuous_Simulation.md` | Long-term simulation with NCDC DSI 3240 historical rainfall; multi-year analysis periods; statistical frequency analysis on results (event ranking, histograms, frequency plots). Preview of advanced SWMM features. |

## Key Terms & Concepts
- Project defaults: ID prefixes, subcatchment/node/link properties, infiltration method
- Object drawing: subcatchment polygon, node click, conduit drag, rain gage
- Group editing: assign property to multiple objects at once
- Kinematic Wave vs. Dynamic Wave routing
- Status report: mass balance error, infiltration, runoff continuity
- Summary report: flooding, surcharge, peak flow
- Color-coded map themes with legends
- Time series plot: compare conduit flows
- Profile plot: water surface depths along flow path
- Water quality: pollutant definition, land use buildup/washoff, EMC, co-pollutant
- Continuous simulation: NCDC DSI 3240 rainfall format
- Statistical analysis: event segregation, frequency plots, return periods

## Typical Queries This Folder Answers
- How do I set up a new SWMM project from scratch?
- How do I draw subcatchments, nodes, and conduits on the map?
- How do I connect subcatchments to drainage nodes?
- What is the difference between Kinematic Wave and Dynamic Wave routing?
- How do I create rainfall time series data?
- How do I interpret the status report and mass balance errors?
- How do I view results on the map with color coding?
- How do I create time series and profile plots?
- How do I add water quality simulation (pollutants, land uses, buildup/washoff)?
- How do I run a long-term continuous simulation with historical rainfall?
- How do I perform statistical frequency analysis?
- What is the group edit feature and how do I use it?

## Related Sections
- Object properties in detail → `appendix_B_visual_object_properties/`
- Theory behind calculations → `chapter_03_swmms_conceptual_model/`
- All simulation options → `chapter_08_running_a_simulation/8.1_Setting_Simulation_Options.md`
- Statistical analysis details → `chapter_09_viewing_results/9.8_Viewing_a_Statistics_Report.md`
