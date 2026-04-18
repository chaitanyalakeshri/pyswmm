# Appendix D — Command Line SWMM & Input File Format

## What This Folder Contains
Documentation for running SWMM from the command line and the complete specification of the SWMM `.inp` input file format. This is the authoritative technical reference for every keyword, section, and parameter in a SWMM input file.

## Files

| File | Description |
|------|-------------|
| `D.1_General_Instructions.md` | Command syntax (`runswmm inpfile rptfile [outfile]`), PATH variable setup, overview of 25+ section keywords in input file organization. |
| `D.2_Input_File_Format.md` | **Complete `.inp` file specification.** Documents every section and its parameters: `[OPTIONS]` (40+ settings), hydrology sections, network sections, water quality sections, data sections, and reporting/output sections. Most comprehensive reference document in this manual. |
| `D.3_Map_Data_Section.md` | Map/visualization sections for the GUI: `[MAP]`, `[COORDINATES]`, `[VERTICES]`, `[POLYGONS]`, `[SYMBOLS]`, `[LABELS]`, `[BACKDROP]`. Note: these are GUI-only and do not affect simulation results. |

## Key Input File Sections (in D.2)

**Analysis Control:**
`[OPTIONS]` — flow units, infiltration method, routing method (STEADY/KINWAVE/DYNWAVE), time steps, tolerances, surcharge method, force main equation, parallel threads

**Hydrology:**
`[RAINGAGES]` · `[EVAPORATION]` · `[TEMPERATURE]` · `[ADJUSTMENTS]` · `[SUBCATCHMENTS]` · `[SUBAREAS]` · `[INFILTRATION]` · `[LID_CONTROLS]` · `[LID_USAGE]` · `[AQUIFERS]` · `[GROUNDWATER]` · `[GWF]` · `[SNOWPACKS]`

**Drainage Network:**
`[JUNCTIONS]` · `[OUTFALLS]` · `[DIVIDERS]` · `[STORAGE]` · `[CONDUITS]` · `[PUMPS]` · `[ORIFICES]` · `[WEIRS]` · `[OUTLETS]` · `[XSECTIONS]` · `[TRANSECTS]` · `[STREETS]` · `[INLETS]` · `[INLET_USAGE]` · `[LOSSES]` · `[CONTROLS]`

**Water Quality:**
`[POLLUTANTS]` · `[LANDUSES]` · `[COVERAGES]` · `[LOADINGS]` · `[BUILDUP]` · `[WASHOFF]` · `[TREATMENT]`

**External Inputs:**
`[INFLOWS]` · `[DWF]` · `[RDII]` · `[HYDROGRAPHS]`

**Data Objects:**
`[CURVES]` · `[TIMESERIES]` · `[PATTERNS]`

**Reporting:**
`[REPORT]` · `[FILES]`

## Key Terms & Concepts
- Command-line execution: `runswmm inpfile rptfile outfile`
- Flow routing: STEADY, KINWAVE (Kinematic Wave), DYNWAVE (Dynamic Wave)
- Cross-section shapes: CIRCULAR, RECT_OPEN, TRAPEZOIDAL, ELLIPSE, ARCH, PARABOLIC, EGG, BASKETHANDLE, SEMICIRCULAR, RECT_TRIANGULAR, RECT_ROUND, MODIFIED_BASKET, HORIZ_ELLIPSE, VERT_ELLIPSE, ARCH, CUSTOM, STREET, IRREGULAR
- LID types: BIO_CELL, RAIN_GARDEN, GREEN_ROOF, INFIL_TRENCH, PERM_PAVEMENT, RAIN_BARREL, ROOFTOP_DISCON, VEG_SWALE
- Pump curves: Type1 (volume-flow), Type2 (depth-flow), Type3 (head-flow), Type4 (depth-head), Type5 (speed-ratio)
- Curve types: STORAGE, SHAPE, DIVERSION, TIDAL, PUMP1–5, RATING, CONTROL, WEIR
- Buildup functions: POW, EXP, SAT, EXT
- Washoff functions: EXP, RC, EMC
- Surcharge methods: EXTRAN, SLOT (Preissmann Slot)
- Force main equations: HAZEN-WILLIAMS, DARCY-WEISBACH
- Inlet types: GRATE, CURB, SLOTTED, CUSTOM; Grate types: P-BAR, CURVED_VANE, TILT_BAR, RETICULINE, GENERIC

## Typical Queries This Folder Answers
- How do I run SWMM from the command line?
- What is the complete syntax for the `[INFILTRATION]` section?
- How do I define an LID control in the input file?
- What options does `[OPTIONS]` support and what are the defaults?
- How do I specify pump curves in the input file?
- How do I write a `[CONTROLS]` rule in the input file?
- What cross-section shapes are available and how are they defined?
- How do I set up `[RDII]` and `[HYDROGRAPHS]` sections?
- What is the format of `[TIMESERIES]` with external files?
- How do I configure dynamic wave options (variable time step, inertial terms)?
- What are all the valid keywords for each section?

## Related Sections
- GUI equivalents → `appendix_B_visual_object_properties/` and `appendix_C_specialized_property_editors/`
- Theory → `chapter_03_swmms_conceptual_model/`
- File types overview → `chapter_11_files_used_by_swmm/11.1_Project_Files.md`
