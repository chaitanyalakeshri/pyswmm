# Appendix A — Useful Reference Tables

## What This Folder Contains
Standardized lookup tables for hydrologic and hydraulic design values: Manning's roughness coefficients, soil properties, SCS curve numbers, depression storage, pipe sizes, culvert codes, and urban stormwater water quality data. Use this appendix when selecting parameter values for SWMM inputs.

## Files

| File | Description |
|------|-------------|
| `A.1_Units_of_Measurement.md` | Conversion table between US customary and SI metric units for all SWMM parameters (flow, area, depth, concentration, Manning's n, infiltration rate, slope). |
| `A.2_Soil_Characteristics.md` | 11 soil texture classes with: saturated hydraulic conductivity K (0.01–4.74 in/hr), suction head Ψ (1.93–12.60 in), porosity, field capacity, wilting point. Includes equation Ψ = 3.23 K^−0.328. |
| `A.3_NRCS_Hydrologic_Soil_Group.md` | HSG classification A/B/C/D by saturated hydraulic conductivity range. A (>1.42 in/hr, low runoff) through D (<0.06 in/hr, high runoff). |
| `A.4_SCS_Curve_Numbers.md` | SCS/NRCS curve numbers by land use and HSG under AMC-II (from TR-55, 2nd ed. 1986). |
| `A.5_Depression_Storage.md` | Initial loss (depression storage) by surface type: impervious 0.05–0.10 in, lawns 0.10–0.20 in, pasture 0.20 in, forest litter 0.30 in. |
| `A.6_Mannings_Coeff_Overland_Flow.md` | Manning's n for overland flow: smooth asphalt 0.011, dense woods/underbrush up to 0.80; agricultural surfaces 0.05–0.17. |
| `A.7_Mannings_Coeff_Closed_Conduits.md` | Manning's n for 9 pipe materials: concrete, plastic, cast iron, corrugated metal, vitrified clay, asbestos-cement, brick. Range 0.011–0.026. |
| `A.8_Mannings_Coeff_Open_Channels.md` | Manning's n for concrete channels (0.011–0.020), excavated earth (0.020–0.140), natural streams (0.030–0.100) by condition. |
| `A.9_Water_Quality_Urban_Runoff.md` | Event Mean Concentrations (EMC) for 10 urban stormwater pollutants: TSS (180–548 mg/L), BOD, COD, phosphorus, nitrogen, copper, lead (182–443 µg/L), zinc (202–633 µg/L). |
| `A.10_Culvert_Code_Numbers.md` | Codes 1–57 for circular concrete, corrugated metal, elliptical, arch, and rectangular box culverts with various inlet types (headwall, wingwall, bevel, tapered). |
| `A.11_Culvert_Entrance_Loss_Coeff.md` | Entrance loss coefficients by culvert material and inlet configuration: 0.2 (beveled/tapered) to 0.9 (projecting corrugated metal, no headwall). |
| `A.12_Standard_Elliptical_Pipe_Sizes.md` | 23 standard elliptical concrete pipe codes with minor/major axis in inches and mm. Range: 14×23 in to 116×180 in. |
| `A.13_Standard_Arch_Pipe_Sizes.md` | Arch conduit sizes: concrete (codes 1–17), corrugated steel 2⅔×½" (18–29), 3×1" (30–44), structural plate (45–102) in US and metric dimensions. |

## Key Terms & Concepts
- Manning's n (roughness coefficient) for overland flow, pipes, open channels
- Green-Ampt soil parameters (K, Ψ, porosity, field capacity, wilting point)
- NRCS/SCS Hydrologic Soil Groups (A, B, C, D)
- SCS Curve Numbers (AMC-II, TR-55)
- Depression storage (initial loss)
- Event Mean Concentration (EMC)
- Culvert inlet control, entrance loss coefficients
- Standard pipe sizes (elliptical, arch, circular)
- Unit conversion (US ↔ SI)

## Typical Queries This Folder Answers
- What Manning's n should I use for a concrete pipe / grassy surface / natural stream?
- What soil hydraulic conductivity corresponds to clay loam?
- What hydrologic soil group has K between 0.57–1.42 in/hr?
- What SCS curve number applies to residential land on Group B soils?
- What depression storage value for an impervious surface?
- What culvert code represents a circular concrete pipe with groove-end projecting?
- What are typical heavy metal concentrations in urban stormwater?
- How do I convert in/hr to mm/hr?

## Related Sections
- Infiltration parameters used in → `appendix_C/C.8_Infiltration_Editor.md`
- Soil groups used in → `chapter_03/3.4_Computational_Methods.md`
- Culvert codes entered in → `appendix_B/B.7_Conduit_Properties.md`
- EMC values used in → `appendix_C/C.14_Land_Use_Editor.md`
