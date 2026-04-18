# Appendix E — Error and Warning Messages

## What This Folder Contains
Complete reference for all SWMM error codes (101–363) and warning codes (01–12). Use this folder whenever a SWMM simulation fails or generates warnings.

## Files

| File | Description |
|------|-------------|
| `E_Error_and_Warning_Messages.md` | Single comprehensive document listing all error codes 101–363 and warnings 01–12, organized by category with explanations and remediation guidance. |

## Error Code Categories

| Range | Category |
|-------|----------|
| 101–111 | Memory allocation, solver initialization, subcatchment/conduit parameter validation |
| 111–145 | Conduit geometry, cross-section validity, pump curves, node connectivity, dividers, weirs, storage nodes |
| 151–159 | Unit hydrograph, RDII, rain gage, time series validation |
| 161–173 | Pollutant/treatment cyclic dependencies, curve/time series data ordering |
| 181–195 | Snowmelt, LID control, simulation date/time step validation |
| 200–235 | Input file parsing: formatting, keywords, duplicates, undefined objects, control rules, transects, infiltration |
| 301–363 | File I/O: opening/reading rainfall, climate, runoff, hot start, RDII, routing interface files |

## Warning Codes Summary

| Code | Meaning |
|------|---------|
| 01 | Wet weather time step auto-reduced for rain gage recording interval |
| 02 | Node maximum depth auto-increased |
| 03–05 | Conduit offset/elevation/slope auto-corrections applied |
| 06–07 | Time step auto-adjustments made |
| 08–09 | Elevation and time series interval warnings |
| 10a/10b | Regulator crest elevation issues (routing-method dependent) |
| 11–12 | Control rule attribute mismatches; inlet placement restrictions |

## Key Terms & Concepts
- Kinematic Wave constraints: positive slopes, no cyclic loops, single outlet per junction
- Dynamic Wave constraints: requires at least one outfall node; more flexible topology
- Cyclic loop detection
- Time series/curve data ordering (X-values must be increasing)
- LID layer and area validation
- File format compatibility for external data files
- Interface file format errors
- Infiltration parameter ranges (Horton, Green-Ampt)

## Typical Queries This Folder Answers
- What does error 138 mean? ("Initial depth greater than maximum depth")
- Why is SWMM reporting ERROR 103 (Kinematic Wave solver failure)?
- What causes ERROR 171 (curve data out of sequence)?
- Why can't SWMM open my rainfall file (ERROR 301–320)?
- What does WARNING 01 mean about my time step?
- What are cyclic loop errors and how do I fix them?
- What are the connectivity requirements for outfall nodes?
- Why is my LID control throwing an error?
- What file format problems cause ERROR 301–363?

## Related Sections
- Troubleshooting simulation runs → `chapter_08_running_a_simulation/8.5_Troubleshooting_Results.md`
- Simulation options that affect errors → `chapter_08_running_a_simulation/8.1_Setting_Simulation_Options.md`
- Input file syntax errors → `appendix_D_command_line_swmm/D.2_Input_File_Format.md`
