# Chapter 3 — SWMM's Conceptual Model

## What This Folder Contains
The theoretical foundation for all SWMM computations. Covers the four-compartment modeling framework, all visual and non-visual object types (with equations), and all computational methods for hydrology, hydraulics, and water quality. **This is the primary reference for understanding how SWMM calculates results.**

## Files

| File | Description |
|------|-------------|
| `3.1_Introduction.md` | Four-compartment framework: Atmosphere (rain gages) → Land Surface (subcatchments) → Groundwater (aquifers) → Transport (nodes + links). Describes how water moves between compartments. |
| `3.2_Visual_Objects.md` | Theory for all objects visible on the map: rain gages, subcatchments (pervious/impervious subareas, 5 infiltration models), junction/outfall/flow divider/storage unit nodes, conduits (Manning equation, 24+ shapes, culverts, HEC-22 inlets), pumps (5 curve types), orifices (submerged/partial flow equations), weirs (5 types with equations), outlets, map labels. |
| `3.3_Non-Visual_Objects.md` | Theory for data objects: Climatology (temperature, evaporation, wind, snowmelt, areal depletion, monthly adjustments), Snow Packs (3 subareas: plowable/impervious/pervious), Aquifers (2-zone unsaturated/saturated), Unit Hydrographs (RDII with R-T-K parameters), Transects, Streets, Inlets (HEC-22), External Inflows (direct/DWF/RDII), Control Rules, Pollutants, Land Uses (buildup/washoff/street sweeping), Treatment, Curves, Time Series, Time Patterns, LID Controls (8 types). |
| `3.4_Computational_Methods.md` | All simulation algorithms: Surface Runoff (nonlinear reservoir model), Infiltration (Horton/modified Horton/Green-Ampt/modified Green-Ampt/Curve Number), Groundwater (2-zone mass balance with 6 flux terms), Snowmelt (7-step algorithm: heat budget + degree-day), Flow Routing (Steady/Kinematic Wave/Dynamic Wave — Saint Venant equations), Ponding & Pressurization, Water Quality Routing (CSTR model, first-order decay), LID Representation (vertical layer moisture balance). |

## Key Equations Referenced

| Process | Equation / Method |
|---------|-------------------|
| Overland flow | Manning: Q = (1.49/n) × A × R^(2/3) × S^(1/2) |
| Conduit flow | Manning (gravity), Hazen-Williams or Darcy-Weisbach (pressurized) |
| Orifice flow | Q = C × A × √(2gh) (submerged); weir equation (partial) |
| Weir flow | Q = Cw × L × h^(3/2) (transverse); Cw × S × h^(5/2) (V-notch) |
| Flow divider weir | Q_div = Cw × (fHw)^1.5 |
| Infiltration | Horton: exponential decay; Green-Ampt: wetting front; CN: cumulative depletion |
| Groundwater | 2-zone balance: fI, fE, fU, fEL, fL, fG flux terms |
| Dynamic Wave | Full Saint Venant equations (continuity + momentum) |
| Water quality | CSTR with first-order decay |

## Key Terms & Concepts

**Hydrology:** Rainfall interception, infiltration (5 methods), depression storage, pervious/impervious subareas, groundwater percolation, interflow, RDII, snowmelt (degree-day + heat budget), areal depletion, evapotranspiration, LID layer moisture balance

**Hydraulics:** Kinematic Wave (simplified momentum), Dynamic Wave (full Saint Venant), steady flow, backwater, surcharge, ponding, pressurization, flow reversal, force mains (H-W / D-W), pump curves (Types 1–5), culvert inlet control, HEC-22 inlet capture

**Water Quality:** Pollutant buildup (POW/EXP/SAT/EXT), washoff (EXP/RC/EMC), street sweeping, treatment (CSTR model), co-pollutant relationships, first-order decay, dry weather flow concentrations

**LID:** 8 LID types, layer structure (surface/pavement/soil/storage/drain/drainage mat), clogging, drain control curves, impermeable liner option

**Control:** IF-THEN-ELSE-PRIORITY rules, depth/flow/time conditions, modulated control, PID controller

## Typical Queries This Folder Answers
- What infiltration method should I use and how does it work mathematically?
- How does SWMM compute surface runoff from a subcatchment?
- What are the differences between Steady Flow, Kinematic Wave, and Dynamic Wave routing?
- How is groundwater flow calculated between the unsaturated and saturated zones?
- How does SWMM model snow accumulation and melting?
- What equations govern orifice, weir, and conduit flow?
- What are the 5 pump curve types and how do they relate flow to head?
- How does pollutant buildup and washoff work mathematically?
- How does SWMM route water quality through the drainage network?
- What LID types are available and what layers do they have?
- How does culvert inlet control work (HEC-22 methodology)?
- How does ponding and pressurization work at nodes?

## Related Sections
- Object property values → `appendix_B_visual_object_properties/`
- Configuring these objects in the GUI → `appendix_C_specialized_property_editors/`
- Input file syntax → `appendix_D_command_line_swmm/D.2_Input_File_Format.md`
- Reference values for parameters → `appendix_A_useful_tables/`
