# Appendix C — Specialized Property Editors Reference

## What This Folder Contains
Documentation for 27 specialized dialog editors in SWMM that handle complex parameter sets for hydrology, hydraulics, water quality, LID, climate, and control. These editors are accessed via the Property Editor's ellipsis (…) buttons or dedicated menus.

## Files

| File | Description |
|------|-------------|
| `C.1_Aquifer_Editor.md` | Groundwater aquifer properties: porosity, wilting point, field capacity, hydraulic conductivity, ET depth, bottom elevation, initial water table. |
| `C.2_Climatology_Editor.md` | 6-tab climate dialog: temperature source, evaporation (5 methods), wind speed, snowmelt parameters, areal depletion curves, monthly adjustments to temperature/evap/rainfall/conductivity. |
| `C.3_Control_Rules_Editor.md` | IF-THEN-ELSE-PRIORITY control rules for pumps and regulators; condition/action clauses, modulated controls (curves, time series, PID controllers), named variables, arithmetic expressions. |
| `C.4_Cross-Section_Editor.md` | Conduit cross-section shape and geometry; supports custom Shape Curves, Street sections, and Irregular (Transect) sections. 24+ shapes available. |
| `C.5_Curve_Editor.md` | Generic X-Y curve editor for: Control, Diversion, Pump (Types 1–5), Rating, Shape, Storage, Tidal, Weir curves. Includes graphical view and file save/load. |
| `C.6_Groundwater_Flow_Editor.md` | Groundwater-surface water interaction coefficients A1–A3, B1–B2; links subcatchment to aquifer and receiving node; surface elevation and water table threshold. |
| `C.7_Groundwater_Equation_Editor.md` | Custom lateral/deep groundwater flow equations using symbols (Hgw, Hsw, Hcb, Hgs, Phi, Theta, Ks, K) and math functions including STEP. |
| `C.8_Infiltration_Editor.md` | Parameters by method: Horton (max/min rate, decay, drying time), Green-Ampt (suction head, conductivity, initial deficit), Curve Number (CN, drying time). |
| `C.9_Inflows_Editor.md` | 3-tab external inflow dialog: Direct inflows (baseline + time series + scale factor), Dry Weather Flow (monthly/daily/hourly/weekend patterns), RDII (unit hydrograph assignment). |
| `C.10_Initial_Buildup_Editor.md` | Grid for setting initial pollutant buildup (lbs/acre or kg/ha) at simulation start, overriding antecedent dry day calculation. |
| `C.11_Inlet_Structure_Editor.md` | Inlet types and design: grate (type, area, splash velocity), curb opening (length, height, throat angle), combination, slotted drain, drop, custom (curve-based). |
| `C.12_Inlet_Usage_Editor.md` | Place inlet structures in conduits: capture node, number of inlets, clogging %, flow restriction, depression dimensions, placement (on-grade/on-sag/automatic). |
| `C.13_Land_Use_Assignment_Editor.md` | Assign % land use coverage to a subcatchment for water quality simulation. |
| `C.14_Land_Use_Editor.md` | Define land use categories: name/street sweeping, pollutant buildup functions (POW/EXP/SAT/EXT with rate constants), washoff parameters (EXP/RC/EMC with removal efficiencies). |
| `C.15_LID_Control_Editor.md` | Comprehensive LID design: Surface layer (berm, vegetation, roughness, slope), Pavement, Soil (porosity, conductivity, suction), Storage (thickness, seepage, clogging), Drain system (coefficients, offset, delays, control curves), Drainage Mat; pollutant removal efficiencies. |
| `C.16_LID_Group_Editor.md` | Group multiple LID controls in a subcatchment; manages total area percentages and impervious/pervious treatment constraints. |
| `C.17_LID_Usage_Editor.md` | Deploy LID: area per unit, number of replicates, surface width, initial saturation %, impervious/pervious treatment %, drain routing, detailed report file output. |
| `C.18_Pollutant_Editor.md` | Pollutant properties: concentration units, rain/groundwater/initial/I&I/DWF concentrations, decay coefficient, snow-only flag, co-pollutant relationship. |
| `C.19_Snow_Pack_Editor.md` | Snow simulation: melt coefficients (min/max), base melt temperature, free water capacity, initial depth, areal depletion; removal operations (depth thresholds, redistribution fractions). |
| `C.20_Storage_Shape_Editor.md` | Storage volume-depth relationship: Cylindrical, Conical, Parabolic, Pyramidal, Functional (polynomial A=aD^b+c), or Tabular (user curve). |
| `C.21_Street_Section_Editor.md` | Street cross-section: road width, curb height, cross slope, gutter depression, backing width/slope, roughness for street conduit hydraulics. |
| `C.22_Time_Pattern_Editor.md` | Recurring multipliers (averaging to 1.0): Monthly (12 values), Daily (7 by day of week), Hourly (24), Weekend Hourly (24). Used for DWF adjustment. |
| `C.23_Time_Series_Editor.md` | Time-varying data input via grid (date/time/value) or external file; supports graphical view; used for rainfall, inflows, temperatures, outfall stages. |
| `C.24_Title_Notes_Editor.md` | Multi-line project notes; option to use first line as print header. |
| `C.25_Transect_Editor.md` | Irregular channel cross-section: up to 1500 station-elevation points, Manning's n by region (left overbank/main channel/right overbank), bank station markers, modifiers. |
| `C.26_Treatment_Editor.md` | Pollutant treatment expressions using C (concentration), R_ (removal fraction), FLOW, DEPTH, AREA, DT, HRT and math/trig functions. Example: `C = BOD * exp(-0.05 * HRT)`. |
| `C.27_Unit_Hydrograph_Editor.md` | RDII unit hydrographs: R-T-K shape parameters (rainfall fraction, time to peak hours, recession ratio), initial abstraction (Dmax, Drec, Do) for short/medium/long-term responses; up to 12 monthly variants. |

## Key Terms & Concepts
- Infiltration: Horton, Modified Horton, Green-Ampt, Modified Green-Ampt, Curve Number
- LID types: Bio-retention, rain garden, green roof, infiltration trench, permeable pavement (continuous/block), rain barrel, rooftop disconnection, vegetative swale
- Control: IF-THEN-ELSE-PRIORITY, PID controller, modulated control via curve/time series
- Pollutant buildup: POW (power), EXP (exponential), SAT (saturation), EXT (external time series)
- Pollutant washoff: EXP (exponential), RC (rating curve), EMC (event mean concentration)
- Groundwater: unsaturated/saturated zone, lateral flow, deep percolation
- RDII: R-T-K parameters, initial abstraction, short/medium/long-term response
- Storage shape: cylindrical, conical, parabolic, pyramidal, functional, tabular
- Street sweeping: removal fractions, cleaning intervals

## Typical Queries This Folder Answers
- How do I configure Green-Ampt infiltration parameters? → `C.8`
- How do I design an LID bio-retention cell with a drain? → `C.15`
- How do I create IF-THEN control rules for a pump? → `C.3`
- How do I define a pump curve? → `C.5`
- How do I model snowmelt? → `C.2` + `C.19`
- How do I set up RDII with unit hydrographs? → `C.9` + `C.27`
- How do I define pollutant buildup and washoff by land use? → `C.14`
- How do I specify water quality treatment at a node? → `C.26`
- How do I define an irregular channel cross-section? → `C.25`
- How do I set storage node volume-depth relationship? → `C.20`
- How do I configure street inlets and capture? → `C.11` + `C.12` + `C.21`

## Related Sections
- Object-level property lists → `appendix_B_visual_object_properties/`
- Theory behind these parameters → `chapter_03_swmms_conceptual_model/`
- Input file syntax equivalents → `appendix_D_command_line_swmm/D.2_Input_File_Format.md`
