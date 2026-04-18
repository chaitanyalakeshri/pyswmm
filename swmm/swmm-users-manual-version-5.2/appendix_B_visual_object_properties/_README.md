# Appendix B — Visual Object Properties Reference

## What This Folder Contains
Comprehensive property definitions for every visual object that can be placed on the SWMM study area map. Use this appendix as the authoritative reference for what parameters each object type requires and what values are valid.

## Files

| File | Description |
|------|-------------|
| `B.1_Rain_Gage_Properties.md` | Rain gage: name, coordinates, data format (Intensity/Volume/Cumulative), recording interval, snow catch factor, data source (time series or external file with station ID and units). |
| `B.2_Subcatchment_Properties.md` | Subcatchment: area, width, slope, % imperviousness, Manning's n (pervious/impervious), depression storage, subarea routing, infiltration method, groundwater, snow pack, LID controls, land uses, monthly adjustments. |
| `B.3_Junction_Properties.md` | Junction: invert elevation, maximum depth, initial depth, surcharge depth, ponded area. |
| `B.4_Outfall_Properties.md` | Outfall boundary conditions: FREE (critical/normal depth), NORMAL, FIXED (set elevation), TIDAL (curve), TIMESERIES. Includes tide gate and routing to subcatchment options. |
| `B.5_Flow_Divider_Properties.md` | Four divider types: CUTOFF (threshold), OVERFLOW (excess), TABULAR (diversion curve), WEIR (equation with min flow, depth, discharge coefficient). |
| `B.6_Storage_Unit_Properties.md` | Storage unit: invert elevation, max/initial depth, surcharge depth, evaporation factor, seepage soil parameters, storage shape (area-depth curve). |
| `B.7_Conduit_Properties.md` | Conduit: inlet/outlet nodes, cross-section shape/depth, length, Manning's n, inlet/outlet offsets, initial/max flow, head loss coefficients (entry/exit/average), seepage rate, flap gate, culvert code. |
| `B.8_Pump_Properties.md` | Pump: inlet/outlet nodes, pump curve, initial ON/OFF status, startup depth (activation), shutoff depth (deactivation). |
| `B.9_Orifice_Properties.md` | Orifice: type (SIDE/BOTTOM), shape (CIRCULAR/RECTANGULAR), height, width, inlet offset, discharge coefficient (typical 0.65), flap gate, time-to-open/close. |
| `B.10_Weir_Properties.md` | Five weir types (TRANSVERSE, SIDEFLOW, V-NOTCH, TRAPEZOIDAL, ROADWAY): height, length, side slope, offset, discharge coefficients, flap gate, end contractions, surcharge, roadway width/surface. |
| `B.11_Outlet_Properties.md` | Outlet: four rating curve methods: FUNCTIONAL/DEPTH, FUNCTIONAL/HEAD (Q=AyB), TABULAR/DEPTH, TABULAR/HEAD. |
| `B.12_Map_Label_Properties.md` | Map label: text, X/Y coordinates, optional anchor object for zoom behavior, font customization. |

## Key Terms & Concepts
- **Node types**: Junction, Outfall, Flow Divider, Storage Unit
- **Link types**: Conduit, Pump, Orifice, Weir, Outlet
- **Offsets**: Depth convention vs. Elevation convention (set in `chapter_05/5.6_Link_Offset_Conventions.md`)
- **Head loss coefficients**: Entry, exit, average (conduits)
- **Discharge coefficients**: Orifice (0.65 typical), weir (varies by type)
- **Pump control**: Startup/shutoff depth thresholds
- **Outfall types**: FREE, NORMAL, FIXED, TIDAL, TIMESERIES
- **Weir types**: TRANSVERSE, SIDEFLOW, V-NOTCH, TRAPEZOIDAL, ROADWAY
- **Subcatchment**: Pervious/impervious split, depression storage, subarea routing

## Typical Queries This Folder Answers
- What properties define a rain gage and how is its data source specified?
- What parameters does a subcatchment require (area, width, slope, etc.)?
- What are the differences between junction, outfall, flow divider, and storage unit?
- What are the five weir types and their specific parameters?
- How do I set pump startup and shutoff depth thresholds?
- What discharge coefficients apply to orifices and weirs?
- What four rating curve methods are available for outlets?
- What head loss coefficients apply to conduits?
- What outfall boundary conditions can I choose?
- How are conduit offsets specified (depth vs. elevation)?

## Related Sections
- Object theory and equations → `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md`
- Specialized editors for these objects → `appendix_C_specialized_property_editors/`
- Input file syntax for these objects → `appendix_D_command_line_swmm/D.2_Input_File_Format.md`
- Adding/editing objects in the GUI → `chapter_06_working_with_objects/`
