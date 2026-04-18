# [LOSSES]

**Purpose:** Specifies minor head loss coefficients at conduit entrances, exits, and along the conduit length, together with an optional flap-gate flag and an optional seepage (exfiltration) rate. These parameters allow the hydraulic model to account for energy losses in addition to friction losses, and for water loss through the conduit walls into the surrounding soil. All fields apply exclusively to conduit links; rows referencing non-conduit links are silently ignored by the GUI reader.

**Occurrence:** One row per conduit object that has at least one non-default value. Only conduits with at least one non-zero loss coefficient, a non-zero seepage rate, or a flap gate set to YES are written to this section. A conduit absent from this section retains default values (all zeros, no flap gate). Multiple rows for the same conduit name are not prevented by the parser — the last row wins.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/input.c:553` — dispatch `case s_LOSSES:` calls `link_readLossParams(Tok, Ntokens)` in `swmm524_engine/src/link.c:271`
- Engine writer: Engine does not write INP files; no report-echo function for this section was found in `inputrpt.c`.
- GUI reader: `Uimport.pas:1519` — function `ReadLossData`
- GUI writer: `Uexport.pas:1380` — procedure `ExportLosses`
- GUI editor dialog(s): Conduit property editor (`objprops.txt:820`); fields appear as rows 13–17 of `ConduitProps` array
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [LOSSES] at line 1876
- Additional manual refs: `appendix_B_visual_object_properties/B.7_Conduit_Properties.md` lines 30–38; `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md` lines 373–377; `appendix_A_useful_tables/A.11_Culvert_Entrance_Loss_Coeff.md`

## Row Format

```
Conduit  Kentry  Kexit  Kavg  (Flap  Seepage)
```

Exact column header emitted by the GUI writer (`Uexport.pas:1412`):
```
;;Link           Kentry     Kexit      Kavg       Flap Gate  Seepage
```

All six columns are written by the GUI even though only the first four are required by the engine parser. Columns 5 and 6 are optional in the INP file; the engine accepts 4, 5, or 6 tokens per row (`link.c:286, 295, 300`).

## Fields

### Conduit

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Name of an existing link. The engine resolves it with `project_findObject(LINK, tok[0])` (`link.c:287`). If the name is not found, `ERR_NAME` is raised. The GUI reader additionally checks `aLink.Ltype <> CONDUIT` and silently skips the row if the named link is not a conduit (`Uimport.pas:1533`); the engine parser does not distinguish link types and will apply loss values to any link type.
- **Default:** none
- **Cross-section dependency:** Must match a name defined in `[CONDUITS]`.
- **Database-key hint:** foreign key to `[CONDUITS].Name` (or more broadly `[LINKS].Name`); composite PK with no other field since only one row per conduit is meaningful.
- **Technical description:** Identifies which conduit receives the loss parameters. The engine stores the result in `Link[j]` where `j` is the index of the named link object. If a conduit is listed in `[CONDUITS]` but absent from `[LOSSES]`, the engine initialises `cLossInlet`, `cLossOutlet`, and `cLossAvg` to `0.0` and `hasFlapGate` to `FALSE` (`project.c:1156–1159`).
- **Source of truth:** `link.c:287`

### Kentry

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (dimensionless head loss coefficient)
- **Valid values / range:** `≥ 0`; negative values are rejected with `ERR_NUMBER` (`link.c:291–292`). Typical culvert entrance values range from 0.2 to 0.9 (see `appendix_A/A.11_Culvert_Entrance_Loss_Coeff.md`).
- **Default:** `0` (GUI default from `objprops.txt:450`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Minor head loss coefficient at the upstream (entrance) end of the conduit. During Dynamic Wave flow routing the engine computes the entrance loss term as `Kentry × v_entrance² / 2g`, where `v_entrance = q / a1` (`dwflow.c:567`). This term enters the momentum equation via `findLocalLosses()` (`dwflow.c:554–571`). Minor losses are **only** applied under Dynamic Wave routing; they have no effect under Steady Flow or Kinematic Wave routing (`D.2_Input_File_Format.md:1902`). When the conduit is reversed internally (e.g., negative slope detected), the engine swaps `cLossInlet` and `cLossOutlet` so the entry loss always applies at the hydraulic upstream end (`link.c:1181–1183`).
- **Source of truth:** `link.c:291–292, 305`; loss application: `dwflow.c:567`

### Kexit

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (dimensionless head loss coefficient)
- **Valid values / range:** `≥ 0`; negative values are rejected with `ERR_NUMBER` (`link.c:291–292`). A value of 1.0 is recommended for culvert exits (`B.7_Conduit_Properties.md:32`).
- **Default:** `0` (GUI default from `objprops.txt:451`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Minor head loss coefficient at the downstream (exit) end of the conduit. Computed as `Kexit × v_exit² / 2g`, where `v_exit = q / a2` (`dwflow.c:568`). Like Kentry, this is only active under Dynamic Wave routing. When the conduit is reversed, `Kexit` is swapped with `Kentry` (`link.c:1182`).
- **Source of truth:** `link.c:291–292, 306`; loss application: `dwflow.c:568`

### Kavg

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (dimensionless head loss coefficient)
- **Valid values / range:** `≥ 0`; negative values are rejected with `ERR_NUMBER` (`link.c:291–292`).
- **Default:** `0` (GUI default from `objprops.txt:452`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Average (distributed) minor head loss coefficient applied across the full length of the conduit. Computed as `Kavg × v_avg² / 2g`, where `v_avg = q / aMid` (`dwflow.c:569`). This can represent bends, manholes, junctions, or other losses distributed along the conduit length. Like the other loss coefficients, it is only active under Dynamic Wave routing. The engine sets `Conduit[k].hasLosses = TRUE` when any of `cLossInlet`, `cLossOutlet`, or `cLossAvg` is non-zero (`link.c:1148–1153`).
- **Source of truth:** `link.c:291–292, 307`; loss application: `dwflow.c:569`

### Flap

- **Data type:** ENUM
- **Required:** no (default: `NO`)
- **Units:** n/a
- **Valid values / range:** `NO` | `YES` (matched via `NoYesWords[]` in `keywords.c:72`, defined as `w_NO` = `"NO"` and `w_YES` = `"YES"` in `text.h:343–344`). Any other token causes `ERR_KEYWORD`.
- **Default:** `NO` (GUI default from `objprops.txt:454`; engine default `FALSE` from `project.c:1159`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Indicates whether a flap gate (check valve) is installed on the conduit to prevent reverse flow. When `YES`, the engine sets `Link[j].hasFlapGate = 1` (`link.c:308`). During routing, `link_setFlapGate()` (`link.c:643`) is called to block flow when the hydraulic conditions would cause reverse flow through the conduit. The GUI property editor labels this field "Flap Gate" with a drop-down list of `NO` / `YES` (`objprops.txt:838–839`); the export column header is also "Flap Gate" (`Uexport.pas:1412–1413`). The INP column header uses "Flap Gate" (two words) while the manual's parameter name is a single word `Flap` (`D.2_Input_File_Format.md:1884`). Note that flap gates on outfall nodes are a separate property (`[OUTFALLS]`) and are independent of this field.
- **Source of truth:** `link.c:295–298, 308`; gate enforcement: `link.c:643–668`

### Seepage

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** in/hr (US customary) / mm/hr (SI)
- **Valid values / range:** Any real number that `getDouble()` accepts; no explicit non-negativity check in the parser (`link.c:300–303`), though negative seepage is physically meaningless. The GUI property editor masks the field as `emNumber` (numeric) with label "Seepage Loss Rate" and shows units `(in/hr)` / `(mm/hr)` (`objprops.txt:837`; `objprops.txt:464–469`).
- **Default:** `0` (GUI default from `objprops.txt:453`; engine default from `link.c:284`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Rate of exfiltration (seepage) of water through the conduit walls into the surrounding soil. The value is converted from in/hr (or mm/hr) to ft/s (or m/s) internally by dividing by `UCF(RAINFALL)` (`link.c:309`). During routing, `conduit_getLossRate()` (`link.c:1334`) computes the volumetric seepage loss rate as `seepRate × flowWidth × length`, where `flowWidth` is the water surface width at the current flow depth (`link.c:1376–1378`). For `RECT_CLOSED` sections the full maximum width is used (`link.c:1369`). The monthly hydraulic conductivity adjustment factor `Adjust.hydconFactor` is applied (`link.c:1378`). Seepage is active under **all** routing methods (Steady, Kinematic Wave, and Dynamic Wave), unlike minor loss coefficients which are Dynamic Wave only. Total losses (seepage + evaporation) are capped at the current conduit flow volume to prevent negative flows (`link.c:1386–1393`). This field models constant exfiltration only; rainfall-dependent infiltration/inflow should instead be modelled via `[RDII]` (`3.2_Visual_Objects.md:344`).
- **Source of truth:** `link.c:300–303, 309`; runtime computation: `link.c:1334–1399`

## Notes

- **Minimum token requirement:** The engine requires at least 4 tokens (`Conduit Kentry Kexit Kavg`); rows with fewer tokens raise `ERR_ITEMS` (`link.c:286`). The `Flap` and `Seepage` columns are genuinely optional.
- **Only conduits are meaningful:** The GUI reader silently skips rows for non-conduit links (`Uimport.pas:1533`). The engine parser does not type-check, but `cLossInlet`, `cLossOutlet`, `cLossAvg`, and `seepRate` are only used in `dwflow.c` (dynamic wave) and `link.c` (seepage) code paths that are conduit-specific.
- **Sparse section:** The GUI writer omits conduits whose all five values are at their defaults (three loss coeffs = `0`, seepage = `0`, flap gate = `NO`) (`Uexport.pas:1395–1399`). Conduits absent from the section retain engine-initialised defaults of zero/FALSE.
- **Minor losses are Dynamic Wave only:** `Kentry`, `Kexit`, and `Kavg` are applied only during Dynamic Wave routing. Under Steady Flow and Kinematic Wave routing these coefficients are read and stored but have no computational effect (`D.2_Input_File_Format.md:1902`; `3.4_Computational_Methods.md:99`).
- **Seepage applies under all routing methods:** Unlike minor losses, seepage computed via `conduit_getLossRate()` is called from routing code that is routing-method aware and applies under Steady Flow, Kinematic Wave, and Dynamic Wave routing.
- **Conduit reversal:** If the engine internally reverses a conduit direction (e.g., when it detects the slope is negative), it swaps `cLossInlet` and `cLossOutlet` so that the entry loss always remains at the hydraulic upstream end (`link.c:1181–1183`).
- **Composite uniqueness:** Only one row per conduit is meaningful. Duplicate rows for the same conduit name cause the later row to overwrite the earlier one since the parser directly assigns to `Link[j]` fields (`link.c:305–309`).
- **Column ordering in export vs. manual:** The GUI writer emits columns in the order `Kentry Kexit Kavg FlapGate Seepage` (`Uexport.pas:1401–1405`), which matches the manual format string `Conduit Kentry Kexit Kavg (Flap Seepage)` (`D.2_Input_File_Format.md:1884`).
- **No cross-section dependency:** Loss parameters can be specified regardless of conduit cross-section shape or culvert code; the seepage calculation uses the flow width from the cross-section internally, but this is transparent to the user.
