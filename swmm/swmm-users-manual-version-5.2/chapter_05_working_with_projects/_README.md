# Chapter 5 — Working with Projects

## What This Folder Contains
Project lifecycle management: creating, opening, and saving SWMM projects; setting project-wide defaults; choosing measurement units; configuring link offset conventions; registering calibration data; and viewing raw project data.

## Files

| File | Description |
|------|-------------|
| `5.1_Creating_a_New_Project.md` | Create new unnamed project via File > New. Recommends setting map dimensions immediately if using a backdrop image. |
| `5.2_Opening_an_Existing_Project.md` | Open projects via File > Open dialog (prompts to save current work) or File > Reopen for recently used projects. |
| `5.3_Saving_a_Project.md` | Save under current name (File > Save) or with new name/location (File > Save As). |
| `5.4_Setting_Project_Defaults.md` | Three categories: (a) ID label prefixes and increments for nodes/links, (b) subcatchment defaults (area, width, slope, imperviousness, Manning's n, depression storage, infiltration method), (c) node/link defaults (invert elevation, depth, ponded area, conduit shape/size/roughness, routing method, force main equation). Option to apply as future defaults. |
| `5.5_Measurement_Units.md` | US customary (CFS/GPM/MGD) vs. SI metric (CMS/LPS/MLD) flow units. Manning's n and pollutant concentration always use metric. Warning: changing units does NOT auto-convert existing data. |
| `5.6_Link_Offset_Conventions.md` | Two conventions for conduit/regulator positioning: Depth (offset from node invert elevation) vs. Elevation (absolute elevation). Can switch conventions with optional automatic recalculation. |
| `5.7_Calibration_Data.md` | Register measured field data for model validation. Supported variables: subcatchment runoff/pollutant washoff/groundwater flow-elevation/snow depth, node depth/lateral inflow/flooding/water quality, link flow/depth/velocity. Register via Project > Calibration Data; edit in Notepad. |
| `5.8_Viewing_All_Project_Data.md` | Non-editable listing of all project data (minus map coordinates) in computational engine format via Project > Details. Useful for consistency checking. |

## Key Terms & Concepts
- Project file extension: `.inp` (plain text), `.ini` (settings, auto-generated)
- ID label prefixes with auto-incrementing (e.g., "J-" for junctions: J-1, J-2…)
- Flow units: CFS, GPM, MGD (US) · CMS, LPS, MLD (SI)
- Link offset: Depth convention vs. Elevation convention
- Calibration variables: subcatchment runoff, node depth/flooding, link flow/velocity
- Calibration file format: object name line, then date/time/value records

## Typical Queries This Folder Answers
- How do I create a new SWMM project?
- How do I open recently used projects?
- What are the three categories of project defaults I can configure?
- How do I set custom ID label prefixes for junctions (e.g., "MH-1, MH-2")?
- What flow unit options are available in US and metric systems?
- What happens to existing data if I change the unit system?
- What is the difference between Depth and Elevation offset conventions?
- How do I register measured field data for calibration comparison?
- What parameters support calibration data in SWMM?
- How do I view all project data in computational format?

## Related Sections
- Measurement unit reference table → `appendix_A_useful_tables/A.1_Units_of_Measurement.md`
- Setting simulation options → `chapter_08_running_a_simulation/8.1_Setting_Simulation_Options.md`
- Calibration file format → `chapter_11_files_used_by_swmm/11.5_Calibration_Files.md`
- Viewing calibration comparison → `chapter_09_viewing_results/9.5_Viewing_Results_with_a_Graph.md`
