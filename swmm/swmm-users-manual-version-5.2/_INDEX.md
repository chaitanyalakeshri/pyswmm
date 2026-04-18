# SWMM 5.2 User Manual — AI Navigation Index

This directory is a markdown conversion of the EPA SWMM 5.2 User's Manual (~500 pages). Each subfolder is a chapter or appendix. Each subfolder also contains a `_README.md` with file-level descriptions and query routing. **Read this index first, then a folder's `_README.md`, then individual files.**

---

## Folder Registry

| Folder | Content | Key Use |
|--------|---------|---------|
| `00_front_matter/` | Abstract, disclaimer, forward, acknowledgements | Understanding SWMM's scope and authors |
| `chapter_01_introduction/` | What SWMM is, capabilities, applications, installation, workflow | Entry point for new users |
| `chapter_02_quick_start_tutorial/` | Full modeling walkthrough from setup to statistics | Step-by-step learning path |
| `chapter_03_swmms_conceptual_model/` | Theory behind all objects and computational methods | Understanding equations and logic |
| `chapter_04_swmms_main_window/` | Menus, toolbars, panels, keyboard shortcuts | GUI navigation reference |
| `chapter_05_working_with_projects/` | Create/open/save, units, defaults, calibration data | Project lifecycle management |
| `chapter_06_working_with_objects/` | Add, edit, delete, group, convert SWMM objects | Object manipulation how-to |
| `chapter_07_working_with_the_map/` | Map layers, themes, backdrop, queries, legends, export | Map visualization and navigation |
| `chapter_08_running_a_simulation/` | Simulation options, execution, troubleshooting | Running and debugging simulations |
| `chapter_09_viewing_results/` | Reports, time-series graphs, profile plots, tables, statistics | Post-simulation analysis |
| `chapter_10_printing_and_copying/` | Printer setup, page format, print/copy output | Exporting results for reports |
| `chapter_11_files_used_by_swmm/` | All file formats SWMM reads and writes | File integration reference |
| `chapter_12_using_add-in_tools/` | Third-party tool integration via Tools menu | Extending SWMM capabilities |
| `appendix_A_useful_tables/` | Manning's n, soil properties, curve numbers, pipe sizes, EMC | Lookup tables for parameter values |
| `appendix_B_visual_object_properties/` | Property definitions for every visual SWMM object | Object configuration reference |
| `appendix_C_specialized_property_editors/` | 27 specialized dialog editors (aquifer, LID, control rules, etc.) | Advanced parameter editor reference |
| `appendix_D_command_line_swmm/` | Command-line usage and complete `.inp` file specification | Input file format and CLI reference |
| `appendix_E_error_and_warning_messages/` | Error codes 101–363 and warnings 01–12 | Error diagnosis and resolution |

---

## Quick Decision Guide

**"What is SWMM? What can it model?"**
→ `chapter_01_introduction/1.1_What_is_SWMM.md`, `1.2_Modeling_Capabilities.md`

**"I'm new — where do I start?"**
→ `chapter_01_introduction/` then `chapter_02_quick_start_tutorial/`

**"How do I do X in the GUI?"**
→ `chapter_04_swmms_main_window/` (menus, panels) · `chapter_06_working_with_objects/` (editing objects) · `chapter_07_working_with_the_map/` (map tools)

**"What are the equations and theory behind X?"**
→ `chapter_03_swmms_conceptual_model/` — covers all hydrology, hydraulics, water quality equations

**"What parameters does object X need?"**
→ Visual objects → `appendix_B_visual_object_properties/` · Editors → `appendix_C_specialized_property_editors/`

**"What value should I use for Manning's n / soil type / curve number / pipe size?"**
→ `appendix_A_useful_tables/`

**"What does error code XXX mean?"**
→ `appendix_E_error_and_warning_messages/E_Error_and_Warning_Messages.md`

**"How do I set simulation options and run?"**
→ `chapter_08_running_a_simulation/8.1_Setting_Simulation_Options.md`

**"How do I view/analyze results?"**
→ `chapter_09_viewing_results/`

**"What does the .inp input file look like?"**
→ `appendix_D_command_line_swmm/D.2_Input_File_Format.md`

**"What file formats does SWMM use?"**
→ `chapter_11_files_used_by_swmm/`

---

## Topic Keyword Index (A–Z)

| Topic | Primary File(s) |
|-------|----------------|
| Add-in tools | `chapter_12/12.1_What_Are_Add-In_Tools.md`, `12.2_Configuring_Add-In_Tools.md` |
| Antecedent dry days | `chapter_08/8.1_Setting_Simulation_Options.md` |
| Aquifer / groundwater zones | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.1_Aquifer_Editor.md`, `appendix_C/C.6_Groundwater_Flow_Editor.md` |
| Arch pipe sizes (standard) | `appendix_A/A.13_Standard_Arch_Pipe_Sizes.md` |
| Backdrop image (map) | `chapter_07/7.4_Utilizing_a_Backdrop_Image.md` |
| Buildup functions (pollutant) | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.14_Land_Use_Editor.md`, `appendix_D/D.2_Input_File_Format.md` |
| Calibration data | `chapter_05/5.7_Calibration_Data.md`, `chapter_11/11.5_Calibration_Files.md` |
| Climate files (temperature/evaporation) | `chapter_11/11.4_Climate_Files.md`, `appendix_C/C.2_Climatology_Editor.md` |
| Conduit properties | `appendix_B/B.7_Conduit_Properties.md`, `chapter_03/3.2_Visual_Objects.md` |
| Conduit cross-section shapes | `appendix_C/C.4_Cross-Section_Editor.md`, `appendix_D/D.2_Input_File_Format.md` |
| Continuity error (mass balance) | `chapter_08/8.5_Troubleshooting_Results.md`, `chapter_09/9.1_Viewing_a_Status_Report.md` |
| Control rules (IF-THEN-ELSE) | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.3_Control_Rules_Editor.md`, `appendix_D/D.2_Input_File_Format.md` |
| Culvert codes and entrance losses | `appendix_A/A.10_Culvert_Code_Numbers.md`, `appendix_A/A.11_Culvert_Entrance_Loss_Coeff.md` |
| Curve editor (pump, storage, rating) | `appendix_C/C.5_Curve_Editor.md` |
| Curve numbers (SCS/NRCS) | `appendix_A/A.4_SCS_Curve_Numbers.md`, `chapter_03/3.4_Computational_Methods.md` |
| Depression storage | `appendix_A/A.5_Depression_Storage.md`, `appendix_B/B.2_Subcatchment_Properties.md` |
| Dynamic Wave routing | `chapter_03/3.4_Computational_Methods.md`, `chapter_08/8.1_Setting_Simulation_Options.md` |
| Elliptical pipe sizes (standard) | `appendix_A/A.12_Standard_Elliptical_Pipe_Sizes.md` |
| Error codes (101–363) | `appendix_E/E_Error_and_Warning_Messages.md` |
| Event mean concentration (EMC) | `appendix_A/A.9_Water_Quality_Urban_Runoff.md`, `appendix_C/C.14_Land_Use_Editor.md` |
| Evaporation | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.2_Climatology_Editor.md` |
| Flow divider | `appendix_B/B.5_Flow_Divider_Properties.md`, `chapter_03/3.2_Visual_Objects.md` |
| Flow Instability Index (FII) | `chapter_08/8.5_Troubleshooting_Results.md` |
| Flow routing (Steady/KW/DW) | `chapter_03/3.4_Computational_Methods.md`, `chapter_08/8.1_Setting_Simulation_Options.md` |
| Frequency analysis / statistics | `chapter_09/9.8_Viewing_a_Statistics_Report.md`, `chapter_02/2.7_Running_a_Continuous_Simulation.md` |
| Graph (time series / profile / scatter) | `chapter_09/9.5_Viewing_Results_with_a_Graph.md`, `chapter_09/9.6_Customizing_a_Graphs_Appearance.md` |
| Green-Ampt infiltration | `chapter_03/3.4_Computational_Methods.md`, `appendix_C/C.8_Infiltration_Editor.md`, `appendix_A/A.2_Soil_Characteristics.md` |
| Groundwater flow equations | `chapter_03/3.4_Computational_Methods.md`, `appendix_C/C.7_Groundwater_Equation_Editor.md` |
| Horton infiltration | `chapter_03/3.4_Computational_Methods.md`, `appendix_C/C.8_Infiltration_Editor.md` |
| Hot start file | `chapter_11/11.7_Interface_Files.md` |
| Hydrologic soil group (HSG A/B/C/D) | `appendix_A/A.3_NRCS_Hydrologic_Soil_Group.md` |
| Inflows (direct / DWF / RDII) | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.9_Inflows_Editor.md` |
| Infiltration methods | `chapter_03/3.4_Computational_Methods.md`, `appendix_C/C.8_Infiltration_Editor.md` |
| Initial buildup | `appendix_C/C.10_Initial_Buildup_Editor.md` |
| Inlet structure (grate / curb / slotted) | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.11_Inlet_Structure_Editor.md`, `appendix_C/C.12_Inlet_Usage_Editor.md` |
| Input file format (.inp) | `appendix_D/D.2_Input_File_Format.md` |
| Installation | `chapter_01/1.4_Installing_EPA_SWMM.md` |
| Interface files | `chapter_11/11.7_Interface_Files.md` |
| Junction properties | `appendix_B/B.3_Junction_Properties.md`, `chapter_03/3.2_Visual_Objects.md` |
| Keyboard shortcuts | `chapter_04/4.3_Keyboard_Shortcuts.md` |
| Kinematic Wave routing | `chapter_03/3.4_Computational_Methods.md`, `chapter_08/8.1_Setting_Simulation_Options.md` |
| Land use categories | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.13_Land_Use_Assignment_Editor.md`, `appendix_C/C.14_Land_Use_Editor.md` |
| LID controls (rain garden, green roof, etc.) | `chapter_03/3.2_Visual_Objects.md`, `chapter_03/3.3_Non-Visual_Objects.md`, `chapter_03/3.4_Computational_Methods.md`, `appendix_C/C.15_LID_Control_Editor.md`, `appendix_C/C.16_LID_Group_Editor.md`, `appendix_C/C.17_LID_Usage_Editor.md` |
| Link offset conventions (depth vs. elevation) | `chapter_05/5.6_Link_Offset_Conventions.md` |
| Manning's n — overland flow | `appendix_A/A.6_Mannings_Coeff_Overland_Flow.md` |
| Manning's n — closed conduits / pipes | `appendix_A/A.7_Mannings_Coeff_Closed_Conduits.md` |
| Manning's n — open channels | `appendix_A/A.8_Mannings_Coeff_Open_Channels.md` |
| Map browser (themes, time period, animation) | `chapter_04/4.8_Map_Browser.md` |
| Map display options | `chapter_07/7.13_Setting_Map_Display_Options.md` |
| Map export (DXF / metafile / text) | `chapter_07/7.14_Exporting_the_Map.md` |
| Map labels | `appendix_B/B.12_Map_Label_Properties.md` |
| Map query (criteria-based search) | `chapter_07/7.10_Submitting_a_Map_Query.md` |
| Map themes (color-coded properties) | `chapter_07/7.2_Selecting_a_Map_Theme.md` |
| Measurement units (US vs. SI) | `chapter_05/5.5_Measurement_Units.md`, `appendix_A/A.1_Units_of_Measurement.md` |
| Orifice properties | `appendix_B/B.9_Orifice_Properties.md`, `chapter_03/3.2_Visual_Objects.md` |
| Outfall properties | `appendix_B/B.4_Outfall_Properties.md`, `chapter_03/3.2_Visual_Objects.md` |
| Output file (.out) | `chapter_11/11.2_Report_and_Output_Files.md` |
| Outlet properties | `appendix_B/B.11_Outlet_Properties.md`, `chapter_03/3.2_Visual_Objects.md` |
| PID controller (control rules) | `appendix_C/C.3_Control_Rules_Editor.md` |
| Pollutant editor | `appendix_C/C.18_Pollutant_Editor.md`, `chapter_03/3.3_Non-Visual_Objects.md` |
| Ponding and pressurization | `chapter_03/3.4_Computational_Methods.md`, `chapter_08/8.1_Setting_Simulation_Options.md` |
| Printing and copying | `chapter_10_printing_and_copying/` (all files) |
| Profile plot | `chapter_09/9.5_Viewing_Results_with_a_Graph.md` |
| Project browser | `chapter_04/4.7_Project_Browser.md` |
| Project defaults | `chapter_05/5.4_Setting_Project_Defaults.md` |
| Project file (.inp / .ini) | `chapter_11/11.1_Project_Files.md` |
| Property editor | `chapter_04/4.9_Property_Editor.md` |
| Pump properties and curves | `appendix_B/B.8_Pump_Properties.md`, `chapter_03/3.2_Visual_Objects.md`, `appendix_C/C.5_Curve_Editor.md` |
| Rain gage | `appendix_B/B.1_Rain_Gage_Properties.md`, `chapter_03/3.2_Visual_Objects.md` |
| Rainfall files (NCEI / user-prepared) | `chapter_11/11.3_Rainfall_Files.md` |
| RDII (rainfall-dependent infiltration/inflow) | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.9_Inflows_Editor.md`, `appendix_C/C.27_Unit_Hydrograph_Editor.md`, `chapter_11/11.7_Interface_Files.md` |
| Report file (.rpt) | `chapter_11/11.2_Report_and_Output_Files.md` |
| Routing interface file | `chapter_11/11.7_Interface_Files.md` |
| Runoff computation | `chapter_03/3.4_Computational_Methods.md` |
| Runoff interface file | `chapter_11/11.7_Interface_Files.md` |
| Saint Venant equations | `chapter_03/3.4_Computational_Methods.md` |
| Simulation options (all tabs) | `chapter_08/8.1_Setting_Simulation_Options.md` |
| Snow pack / snowmelt | `chapter_03/3.3_Non-Visual_Objects.md`, `chapter_03/3.4_Computational_Methods.md`, `appendix_C/C.2_Climatology_Editor.md`, `appendix_C/C.19_Snow_Pack_Editor.md` |
| Soil characteristics (K, porosity, etc.) | `appendix_A/A.2_Soil_Characteristics.md` |
| Statistical analysis (frequency, events) | `chapter_09/9.8_Viewing_a_Statistics_Report.md` |
| Status report | `chapter_09/9.1_Viewing_a_Status_Report.md` |
| Storage unit / detention basin | `appendix_B/B.6_Storage_Unit_Properties.md`, `appendix_C/C.20_Storage_Shape_Editor.md`, `chapter_03/3.2_Visual_Objects.md` |
| Street section geometry | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.21_Street_Section_Editor.md` |
| Subcatchment properties | `appendix_B/B.2_Subcatchment_Properties.md`, `chapter_03/3.2_Visual_Objects.md` |
| Summary results tables | `chapter_09/9.2_Viewing_Summary_Results.md` |
| Surcharge (node / conduit) | `chapter_03/3.4_Computational_Methods.md`, `chapter_08/8.1_Setting_Simulation_Options.md` |
| Time patterns (monthly / daily / hourly) | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.22_Time_Pattern_Editor.md` |
| Time series (data / editor / files) | `appendix_C/C.23_Time_Series_Editor.md`, `chapter_11/11.6_Time_Series_Files.md`, `chapter_03/3.3_Non-Visual_Objects.md` |
| Transect (irregular channel) | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.25_Transect_Editor.md` |
| Treatment expressions (water quality) | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.26_Treatment_Editor.md` |
| Troubleshooting simulation errors | `chapter_08/8.5_Troubleshooting_Results.md`, `appendix_E/E_Error_and_Warning_Messages.md` |
| Tutorial (hands-on walkthrough) | `chapter_02_quick_start_tutorial/` (all 7 sections) |
| Units of measurement (US ↔ SI) | `appendix_A/A.1_Units_of_Measurement.md`, `chapter_05/5.5_Measurement_Units.md` |
| Unit hydrograph (RDII) | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.27_Unit_Hydrograph_Editor.md` |
| Variable time step (Courant) | `chapter_08/8.1_Setting_Simulation_Options.md` |
| Warnings (01–12) | `appendix_E/E_Error_and_Warning_Messages.md` |
| Washoff functions (pollutant) | `chapter_03/3.3_Non-Visual_Objects.md`, `appendix_C/C.14_Land_Use_Editor.md` |
| Water quality modeling | `chapter_03/3.3_Non-Visual_Objects.md`, `chapter_03/3.4_Computational_Methods.md`, `chapter_02/2.6_Simulating_Water_Quality.md` |
| Weir properties | `appendix_B/B.10_Weir_Properties.md`, `chapter_03/3.2_Visual_Objects.md` |

---

## Cross-Reference: "I need to configure..."

| Task | Files to Read |
|------|--------------|
| Infiltration (Horton / Green-Ampt / CN) | `appendix_C/C.8_Infiltration_Editor.md` + `appendix_A/A.2_Soil_Characteristics.md` + `appendix_A/A.4_SCS_Curve_Numbers.md` |
| Manning's roughness value selection | `appendix_A/A.6` (overland) · `A.7` (pipes) · `A.8` (channels) |
| Groundwater interaction | `appendix_C/C.1_Aquifer_Editor.md` + `C.6_Groundwater_Flow_Editor.md` + `C.7` |
| Snow accumulation/melt | `appendix_C/C.2_Climatology_Editor.md` + `C.19_Snow_Pack_Editor.md` |
| Pollutants and water quality | `appendix_C/C.14_Land_Use_Editor.md` + `C.18_Pollutant_Editor.md` + `C.26_Treatment_Editor.md` |
| LID controls | `appendix_C/C.15_LID_Control_Editor.md` + `C.16_LID_Group_Editor.md` + `C.17_LID_Usage_Editor.md` |
| RDII inflows | `appendix_C/C.9_Inflows_Editor.md` + `C.27_Unit_Hydrograph_Editor.md` |
| Control rules for pumps/gates | `appendix_C/C.3_Control_Rules_Editor.md` |
| Storage node geometry | `appendix_C/C.20_Storage_Shape_Editor.md` |
| Street/inlet system (dual drainage) | `appendix_C/C.11_Inlet_Structure_Editor.md` + `C.12` + `C.21_Street_Section_Editor.md` |
| External climate data | `chapter_11/11.4_Climate_Files.md` + `appendix_C/C.2_Climatology_Editor.md` |
| Simulation time steps and routing | `chapter_08/8.1_Setting_Simulation_Options.md` |
| Linking two SWMM models | `chapter_11/11.7_Interface_Files.md` |

---

## Object → Property Reference Map

| Object Type | Properties File | Theory File |
|-------------|----------------|-------------|
| Rain Gage | `appendix_B/B.1_Rain_Gage_Properties.md` | `chapter_03/3.2_Visual_Objects.md` |
| Subcatchment | `appendix_B/B.2_Subcatchment_Properties.md` | `chapter_03/3.2_Visual_Objects.md` |
| Junction | `appendix_B/B.3_Junction_Properties.md` | `chapter_03/3.2_Visual_Objects.md` |
| Outfall | `appendix_B/B.4_Outfall_Properties.md` | `chapter_03/3.2_Visual_Objects.md` |
| Flow Divider | `appendix_B/B.5_Flow_Divider_Properties.md` | `chapter_03/3.2_Visual_Objects.md` |
| Storage Unit | `appendix_B/B.6_Storage_Unit_Properties.md` + `appendix_C/C.20` | `chapter_03/3.2_Visual_Objects.md` |
| Conduit | `appendix_B/B.7_Conduit_Properties.md` | `chapter_03/3.2_Visual_Objects.md` |
| Pump | `appendix_B/B.8_Pump_Properties.md` | `chapter_03/3.2_Visual_Objects.md` |
| Orifice | `appendix_B/B.9_Orifice_Properties.md` | `chapter_03/3.2_Visual_Objects.md` |
| Weir | `appendix_B/B.10_Weir_Properties.md` | `chapter_03/3.2_Visual_Objects.md` |
| Outlet | `appendix_B/B.11_Outlet_Properties.md` | `chapter_03/3.2_Visual_Objects.md` |
| Map Label | `appendix_B/B.12_Map_Label_Properties.md` | — |
| Aquifer | `appendix_C/C.1_Aquifer_Editor.md` | `chapter_03/3.3_Non-Visual_Objects.md` |
| LID Control | `appendix_C/C.15_LID_Control_Editor.md` | `chapter_03/3.3_Non-Visual_Objects.md` + `3.4` |
| Transect | `appendix_C/C.25_Transect_Editor.md` | `chapter_03/3.3_Non-Visual_Objects.md` |
| Control Rule | `appendix_C/C.3_Control_Rules_Editor.md` | `chapter_03/3.3_Non-Visual_Objects.md` |

---

## Input File Section → Documentation Map

For any `[SECTION]` keyword in a SWMM `.inp` file, the authoritative reference is:
**`appendix_D_command_line_swmm/D.2_Input_File_Format.md`**

Key sections: `[OPTIONS]`, `[RAINGAGES]`, `[SUBCATCHMENTS]`, `[SUBAREAS]`, `[INFILTRATION]`, `[LID_CONTROLS]`, `[LID_USAGE]`, `[AQUIFERS]`, `[GROUNDWATER]`, `[SNOWPACKS]`, `[JUNCTIONS]`, `[OUTFALLS]`, `[DIVIDERS]`, `[STORAGE]`, `[CONDUITS]`, `[PUMPS]`, `[ORIFICES]`, `[WEIRS]`, `[OUTLETS]`, `[XSECTIONS]`, `[TRANSECTS]`, `[STREETS]`, `[INLETS]`, `[INLET_USAGE]`, `[LOSSES]`, `[CONTROLS]`, `[POLLUTANTS]`, `[LANDUSES]`, `[COVERAGES]`, `[BUILDUP]`, `[WASHOFF]`, `[TREATMENT]`, `[INFLOWS]`, `[DWF]`, `[RDII]`, `[HYDROGRAPHS]`, `[CURVES]`, `[TIMESERIES]`, `[PATTERNS]`, `[REPORT]`, `[MAP]`, `[COORDINATES]`, `[VERTICES]`, `[POLYGONS]`
