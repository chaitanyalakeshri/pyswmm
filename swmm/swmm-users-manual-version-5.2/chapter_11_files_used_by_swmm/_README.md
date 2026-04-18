# Chapter 11 — Files Used by SWMM

## What This Folder Contains
Documentation of all file types that SWMM reads and writes: project files, simulation output files, external rainfall and climate data files, calibration files, time series files, and interface files for modular system analysis. The `.inp` project file is the only required file; all others are optional.

## Files

| File | Description |
|------|-------------|
| `11.1_Project_Files.md` | **`.inp`** (plain text, all model data organized in keyword sections) and **`.ini`** (GUI settings: map display, legend colors, default values, calibration file paths). `.ini` is auto-generated; project loads without it. |
| `11.2_Report_and_Output_Files.md` | **`.rpt`** (plain text Status Report + all Summary Results tables) and **`.out`** (binary, complete numerical results used by GUI for plots/tables/statistics). Both saved automatically with same base name as `.inp`. |
| `11.3_Rainfall_Files.md` | External text rainfall data. Supported formats: NOAA/NCEI Climate Data Online, DS-3240 (hourly), DS-3260 (15-minute), HLY03/HLY21 (Canadian hourly), FIF21 (Canadian 15-min), or user-prepared space-delimited format: `StationID Year Mon Day Hr Min Value`. |
| `11.4_Climate_Files.md` | External climate data (temperature, evaporation, wind speed). Formats: GHCN-D (NOAA), DS-3200/3210, Canadian, or user-prepared: `Station Year Mon Day MaxTemp MinTemp [Evap] [Wind]`. Missing values = asterisk; forward-filled. US: °F/in/day/mph; SI: °C/mm/day/km/h. |
| `11.5_Calibration_Files.md` | Measured field data for model validation. Plain text format: object name line, then records with `Date Time Value`. Supports: subcatchment runoff/groundwater/snowpack/pollutant washoff; node depth/inflow/flooding/WQ; link flow/depth/velocity. Register via Project > Calibration Data. |
| `11.6_Time_Series_Files.md` | External time series data files. Two formats: (1) Date/Time/Value with calendar dates (month/day/year, 24-hr time); (2) Time/Value with decimal hours since simulation start. Comments with `;`. Rainfall: zero periods omitted; other series: values interpolated. |
| `11.7_Interface_Files.md` | Binary/text files for modular analysis: **Rainfall Interface** (collects multiple rain gages, reusable), **Runoff Interface** (saves runoff for scenario reuse), **Hot Start** (complete hydrologic/hydraulic/WQ state — enables warm-start, divides long runs, avoids DW instabilities), **RDII Interface** (RDII flow time series), **Routing Interface** (outfall discharge time series for linking sub-models; text format with SWMM5 header). |

## File Extension Summary

| Extension | Type | Format |
|-----------|------|--------|
| `.inp` | Project file | Plain text (keyword sections) |
| `.ini` | GUI settings | Plain text (auto-generated) |
| `.rpt` | Report file | Plain text |
| `.out` | Output file | Binary |
| (user-named) | Rainfall data | Plain text (multiple formats) |
| (user-named) | Climate data | Plain text (multiple formats) |
| (user-named) | Calibration data | Plain text |
| (user-named) | Time series data | Plain text |
| (user-named) | Interface files | Binary (rainfall/runoff/hot start/RDII) or text (routing/RDII) |

## Hot Start File — State Variables Saved

Subcatchment: ponded depth/WQ, pollutant buildup, infiltration state, snow pack, unsaturated zone moisture, water table elevation, groundwater outflow
Node: water depth, lateral inflow, water quality
Link: flow rate, water depth, control setting, water quality
**Note:** LID unit hydrologic state is NOT saved in hot start files.

## Routing Interface File Text Format
Line 1: `SWMM5` · Line 2: description · Line 3: time step (seconds) · Line 4: number of variables · Line 5+: variable names/units · Node count · Node names · Data rows: `NodeName Year Mon Day Hr Min Sec Flow [Concentration...]`

## Typical Queries This Folder Answers
- What file types does SWMM use and what are their extensions?
- How do I prepare a user-formatted rainfall file for SWMM?
- How do I download and use NCEI rainfall data with SWMM?
- What format must climate data be in (temperature, evaporation)?
- How do I set up calibration data for comparing simulated vs. measured flow?
- What is the time series file format for external inflows?
- How do I save and reuse a hot start file to avoid re-running spinup?
- How do I divide a 10-year continuous simulation into manageable pieces?
- How do I link two separate SWMM models at their boundary?
- What state variables are preserved in a hot start file?
- Can I reuse previous runoff results for a new scenario? (→ Runoff Interface File)
- What is the RDII interface file text format?

## Related Sections
- Project file content → `appendix_D_command_line_swmm/D.2_Input_File_Format.md`
- Calibration data in GUI → `chapter_05_working_with_projects/5.7_Calibration_Data.md`
- Interface file setup in simulation options → `chapter_08_running_a_simulation/8.1_Setting_Simulation_Options.md`
- Using calibration overlays in graphs → `chapter_09_viewing_results/9.5_Viewing_Results_with_a_Graph.md`
