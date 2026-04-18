# Chapter 8 — Running a Simulation

## What This Folder Contains
Everything needed to configure and execute a SWMM simulation: selecting process models and routing methods, setting all time step and numerical options, configuring which objects to report, defining event periods for long-term simulations, running the simulation, and diagnosing errors and instabilities.

## Files

| File | Description |
|------|-------------|
| `8.1_Setting_Simulation_Options.md` | **Primary configuration reference.** Five tabbed pages: (1) General — process models (aquifer, groundwater, snowmelt), infiltration method, routing method (Steady/Kinematic Wave/Dynamic Wave), ponding, minimum conduit slope. (2) Dates — start/end analysis, start reporting, street sweeping dates, antecedent dry days. (3) Time Steps — reporting interval, wet/dry weather runoff steps, control rule step, routing step, steady flow period tolerances. (4) Dynamic Wave — inertial terms (KEEP/DAMPEN/IGNORE), supercritical flow definition, force main equation, surcharge method (Extran/Slot), variable time steps (Courant), minimum nodal surface area, head convergence tolerance, max iterations, parallel threads. (5) Files — interface file management. |
| `8.2_Setting_Reporting_Options.md` | Configure which objects generate detailed time-series output: three tabs (Subcatchments, Nodes, Links) with selective or all-object reporting. Options: report input summary, report control actions, report average results. |
| `8.3_Selecting_Event_Periods.md` | Define discrete time windows for full hydraulic routing in long-term continuous runs. Outside events, system state held constant (hydrologic accounting continues). Useful for focusing intensive computation on critical storm events. Identifies events via rainfall frequency analysis (Section 9.8). |
| `8.4_Starting_a_Simulation.md` | Execute via Project > Run Simulation or toolbar button. Run Status window shows progress. Stop button or Esc halts run (partial results available). Run status indicator: green ✓ = success, modified project = results invalidated. |
| `8.5_Troubleshooting_Results.md` | Diagnose: error messages (code + description from Appendix E), unknown ID errors, file errors, drainage layout errors (outfall connectivity, flow divider rules, Kinematic Wave constraints, Dynamic Wave requirements), excessive continuity errors (>10% threshold, time step causes, problematic nodes), unstable flow (Flow Instability Index: 0–150 scale; top 5 problematic links listed; fixes: reduce time step, dampen inertial terms, enable conduit lengthening). |

## Key Configuration Parameters

| Category | Key Options |
|----------|-------------|
| Routing method | STEADY, KINWAVE, DYNWAVE |
| Infiltration method | HORTON, MOD_HORTON, GREEN_AMPT, MOD_GREEN_AMPT, CURVE_NUMBER |
| Wet weather time step | Typical: 60–300 seconds |
| Routing time step | Kinematic Wave: 60–300 s; Dynamic Wave: ≤30 s |
| Inertial terms | KEEP (full), DAMPEN (near critical flow), IGNORE (diffusion wave) |
| Surcharge method | EXTRAN (nodal head variation), SLOT (Preissmann Slot) |
| Force main equation | HAZEN_WILLIAMS, DARCY_WEISBACH |
| Variable time step factor | Typical: 75% (safety factor on Courant criterion) |
| Continuity error threshold | ~10% acceptable |
| Flow Instability Index | 0–150 scale (higher = more unstable) |

## Key Terms & Concepts
- Kinematic Wave constraints: positive slopes, no loops, single junction outlet
- Dynamic Wave: handles backwater, pressurization, loops, negative slopes; requires at least 1 outfall
- Courant stability criterion for variable time step
- Flow Instability Index (FII): normalized oscillation count for links
- Mass continuity error: percentage of inflow unaccounted; check Status Report
- Event periods: selective full hydraulic routing for long continuous runs
- Antecedent dry days: sets initial surface pollutant buildup
- Preissmann Slot: virtual slot to handle surcharge in Dynamic Wave
- Head convergence tolerance: default 0.005 ft / 0.0015 m
- Nodal surface area: default 12.566 ft² / 1.167 m²

## Typical Queries This Folder Answers
- What infiltration and routing method should I choose?
- What time step should I use for Dynamic Wave vs. Kinematic Wave?
- How do I enable groundwater or snowmelt modeling?
- What does "Allow Ponding" do?
- How do I set the simulation start/end dates?
- How do I optimize performance for long-term continuous simulations?
- What is the Flow Instability Index and how do I fix instabilities?
- What continuity error is acceptable?
- How do I select which objects to report detailed results for?
- What drainage layout rules prevent errors in Kinematic Wave routing?
- Why is my simulation failing (error identification)?
- How do I use variable time steps with Courant stability?
- What does it mean when SWMM reports "unknown ID" errors?

## Related Sections
- Error code lookup → `appendix_E_error_and_warning_messages/E_Error_and_Warning_Messages.md`
- Status report interpretation → `chapter_09_viewing_results/9.1_Viewing_a_Status_Report.md`
- Routing theory → `chapter_03_swmms_conceptual_model/3.4_Computational_Methods.md`
- Input file options → `appendix_D_command_line_swmm/D.2_Input_File_Format.md` (`[OPTIONS]` section)
