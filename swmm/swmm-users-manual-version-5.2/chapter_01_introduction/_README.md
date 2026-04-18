# Chapter 1 — Introduction to EPA SWMM

## What This Folder Contains
Foundational overview of SWMM: what it is, its full modeling capabilities, typical real-world applications, installation instructions, the standard modeling workflow, and a map of the entire manual.

## Files

| File | Description |
|------|-------------|
| `1.1_What_is_SWMM.md` | Defines SWMM as a dynamic rainfall-runoff simulation model first released in 1971; Version 5 is a complete rewrite. Tracks runoff quantity and quality through drainage networks (pipes, channels, storage, pumps, regulators). |
| `1.2_Modeling_Capabilities.md` | Full capability list: hydrologic (rainfall, evaporation, snow, infiltration, groundwater, interflow, LID, overland flow), hydraulic (24+ conduit shapes, storage, pumps, weirs, orifices, dynamic control rules), water quality (buildup/washoff, BMPs, treatment). |
| `1.3_Typical_Applications_of_SWMM.md` | Real-world use cases: flood control design, detention facility sizing, flood plain mapping, CSO/SSO minimization, pollutant load generation, BMP effectiveness evaluation. Thousands of global applications. |
| `1.4_Installing_EPA_SWMM.md` | Windows installation for 32-bit and 64-bit systems. File naming: `swmm52#(x86/x64)_setup.exe`. Setup via Windows Run dialog. Directory structure. Uninstallation via Windows Settings. |
| `1.5_Steps_in_Using_SWMM.md` | Standard 6-step workflow: (1) set defaults, (2) draw network, (3) edit properties, (4) select analysis options, (5) run simulation, (6) view results. CAD/GIS import option for large systems. |
| `1.6_About_This_Manual.md` | Roadmap of all 12 chapters and 5 appendices — what each covers. Use as navigation guide for the full manual. |

## Key Terms & Concepts
- Dynamic rainfall-runoff simulation (event and continuous)
- Subcatchments, junctions, outfalls, storage nodes, conduits, pumps, weirs, orifices
- Kinematic Wave and Dynamic Wave routing
- Low Impact Development (LID)
- Combined Sewer Overflow (CSO), Sanitary Sewer Overflow (SSO)
- Best Management Practices (BMPs)
- Pollutant buildup, washoff, treatment
- Rainfall-Dependent Infiltration/Inflow (RDII)
- Windows 32-bit / 64-bit installation

## Typical Queries This Folder Answers
- What is EPA SWMM and what problems does it solve?
- What hydrologic, hydraulic, and water quality processes can SWMM simulate?
- What are typical engineering applications of SWMM?
- How do I install SWMM on Windows?
- What is the standard workflow for building and running a SWMM model?
- Can SWMM import data from CAD or GIS?
- What chapter covers [topic]? (→ `1.6_About_This_Manual.md`)

## Related Sections
- Hands-on tutorial → `chapter_02_quick_start_tutorial/`
- Detailed theory → `chapter_03_swmms_conceptual_model/`
- GUI overview → `chapter_04_swmms_main_window/`
