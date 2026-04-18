# [PUMPS]

**Purpose:** Defines each pump link in the drainage network. A pump is a one-directional link that lifts water from an inlet node to an outlet node; its flow rate is determined by one of five pump-curve types (or an "Ideal" mode), and the curve itself is stored in the `[CURVES]` section with a matching curve type keyword (`PUMP1`–`PUMP5`). The five curve types relate pump flow to different hydraulic variables: wet-well volume (Type 1), inlet depth step-wise (Type 2), delivered head (Type 3), inlet depth continuously (Type 4), or delivered head with variable speed (Type 5). Pump on/off transitions can be automated through startup/shutoff water-depth thresholds or through `[CONTROLS]` rule actions.

**Occurrence:** One row per pump link. Each pump link name must be unique across the entire `[LINKS]` namespace (conduits, pumps, orifices, weirs, outlets share one namespace). Optional trailing fields are omitted when their default values apply.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/link.c:1406` — function `pump_readParams`; dispatch from `swmm524_engine/src/input.c:535` — `case s_PUMP: return readLink(PUMP)`
- Engine object allocation (pass 1): `swmm524_engine/src/input.c:335` — increments `Nobjects[LINK]` and `Nlinks[PUMP]`
- Engine validation: `swmm524_engine/src/link.c:1473` — function `pump_validate`
- Engine runtime (flow computation): `swmm524_engine/src/link.c:1548` — function `pump_getInflow`
- Engine report echo: `swmm524_engine/src/inputrpt.c:202` — echoes pump type into the status report (no INP re-write)
- GUI reader: `Uimport.pas:1105` — function `ReadPumpData`
- GUI writer: `Uexport.pas:1048` — procedure `ExportPumps`
- GUI editor dialog(s): `objprops.txt:844` — `PumpProps` array (property editor definition); `Dcurve.pas:199` — curve-type picker for `PUMPCURVE`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[PUMPS]` (line 1357)
- Additional manual refs: `appendix_B_visual_object_properties/B.8_Pump_Properties.md`; `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md` lines 384–416 (pump type descriptions); `appendix_C_specialized_property_editors/C.5_Curve_Editor.md` (curve editor); `appendix_C_specialized_property_editors/C.3_Control_Rules_Editor.md` lines 63–104 (PUMP STATUS/SETTING actions); `appendix_E_error_and_warning_messages/E_Error_and_Warning_Messages.md` lines 34–36 (errors 121–122)

## Row Format

```
Name  Node1  Node2  Pcurve  (Status  Startup  Shutoff)
```

The first four columns are required. `Status`, `Startup`, and `Shutoff` are optional and may be omitted (they default to `ON`, `0`, and `0` respectively). The GUI header comment line emitted by `ExportPumps` shows the column labels as: `Name`, `From Node`, `To Node`, `Pump Curve`, `Status`, `Startup`, `Shutoff`.

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-blank string without whitespace (mask `emNoSpace` enforced by the GUI property editor at `objprops.txt:845`). Must be unique across all link objects.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** Primary identifier of this row; foreign key target from `[CONTROLS]` rule action clauses and any other section that references a link by name.
- **Technical description:** User-assigned label for the pump link. The engine resolves it to an integer index via `project_findID(LINK, tok[0])` at `link.c:1423`. Because all link types (conduits, pumps, orifices, weirs, outlets) share a single name hash table, the name must be unique across all link sections.
- **Source of truth:** `swmm524_engine/src/link.c:1422–1424` (ID lookup and error on duplicate).

---

### Node1 (Inlet Node)

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Name of an existing node (junction, outfall, divider, or storage unit) defined in `[JUNCTIONS]`, `[OUTFALLS]`, `[DIVIDERS]`, or `[STORAGE]`.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** Foreign key to the unified nodes table (keyed on node `Name`).
- **Technical description:** The upstream (inlet) end of the pump. Water is drawn from this node. Startup and shutoff depth thresholds (fields `Startup` and `Shutoff`) are evaluated against the water depth at this node. For a Type 1 pump, the wet-well volume used in curve lookup is taken from this node (`Node[n1].newVolume` at `link.c:1579`). The engine resolves the name at `link.c:1425–1427` (`project_findObject(NODE, tok[1])`).
- **Source of truth:** `swmm524_engine/src/link.c:1425–1427`.

---

### Node2 (Outlet Node)

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Name of an existing node; same constraints as `Node1`.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** Foreign key to the unified nodes table.
- **Technical description:** The downstream (outlet) end of the pump. For Type 3 and Type 5 pumps, the delivered head used in curve lookup is computed as the difference in hydraulic head between this node and the inlet node (`(Node[n2].newDepth + Node[n2].invertElev) - (Node[n1].newDepth + Node[n1].invertElev)`) at `link.c:1599–1601`. Reverse flow through a pump is never permitted; the engine clamps negative computed flow to zero at `link.c:1632`.
- **Source of truth:** `swmm524_engine/src/link.c:1427–1428`.

---

### Pcurve (Pump Curve)

- **Data type:** NAME_REF
- **Required:** yes (but the special literal `*` signals an Ideal pump and is explicitly allowed)
- **Units:** n/a
- **Valid values / range:** Either the literal `*` (asterisk) to specify an Ideal pump, or the name of a curve object defined in `[CURVES]` whose curve type is one of `PUMP1`, `PUMP2`, `PUMP3`, `PUMP4`, or `PUMP5`. Any other curve type causes error 121 at validation.
- **Default:** `*` (Ideal pump) — this is the factory default shown in `objprops.txt:478`.
- **Cross-section dependency:** `[CURVES].Name` where `[CURVES].Type ∈ {PUMP1, PUMP2, PUMP3, PUMP4, PUMP5}`. The curve type determines which hydraulic variable is used as the x-axis:
  - **PUMP1** — x = wet-well volume at inlet node (ft³ or m³); flow is step-wise constant over volume intervals. Enum: `PUMP1_CURVE` (`enums.h:445`).
  - **PUMP2** — x = water depth at inlet node (ft or m); flow is step-wise constant over depth intervals. Enum: `PUMP2_CURVE` (`enums.h:446`).
  - **PUMP3** — x = delivered head (ft or m); flow varies continuously with head (standard pump characteristic curve). Enum: `PUMP3_CURVE` (`enums.h:447`).
  - **PUMP4** — x = water depth at inlet node (ft or m); flow varies continuously with depth. Enum: `PUMP4_CURVE` (`enums.h:448`).
  - **PUMP5** — x = delivered head (ft or m); flow varies with head like Type 3, but the curve shifts when a control rule changes the pump's speed `SETTING` (affinity laws: flow ∝ speed, head ∝ speed²). Enum: `PUMP5_CURVE` (`enums.h:449`).
- **Database-key hint:** Foreign key to `[CURVES].Name`; nullable (NULL when `*`).
- **Technical description:** The engine parses this token at `link.c:1430–1440`. If the token equals `"*"` (tested with `strcomp`) the curve index is stored as `-1` and the pump is later assigned type `IDEAL_PUMP` during validation (`link.c:1489–1490`). Otherwise `project_findObject(CURVE, tok[3])` is called and the integer curve index is stored in `Pump[k].pumpCurve` via `link_setParams` at `link.c:354`. During validation (`pump_validate`, `link.c:1473`), the referenced curve's `curveType` is checked to fall within `[PUMP1_CURVE..PUMP5_CURVE]`; a mismatch triggers error 121. The internal pump type integer is derived as `Curve[m].curveType - PUMP1_CURVE` (`link.c:1501`). Curve bounds (`Pump[k].xMin`, `Pump[k].xMax`) are extracted by scanning all curve entries at `link.c:1502–1511`; operating outside these bounds causes `Link[j].flowClass` to be flagged (reported in the summary statistics as "percent of time pump operates above/below curve").

  The GUI legacy-format skip logic (`Uimport.pas:1136`) checks whether `TokList[3]` is one of `('TYPE1','TYPE2','TYPE3','TYPE4')` (the older 4-element `PumpTypes` array in `objprops.txt:154`); if so, `N` is advanced to 4, and the actual curve name is taken from `TokList[4]`. This handles .inp files written by older SWMM 5.0 GUI versions that included the pump type as an explicit column.

- **Source of truth:** `swmm524_engine/src/link.c:1430–1440` (parse); `link.c:1487–1515` (validation); `enums.h:437–449` (curve type enum).

---

### Status (Initial Status)

- **Data type:** ENUM
- **Required:** no (default: `ON`)
- **Units:** unitless
- **Valid values / range:** `OFF` (0) | `ON` (1). Matched via `OffOnWords[]` array (`keywords.c:73`).
- **Default:** `ON` — confirmed by `objprops.txt:479` (`'ON'` default), `link.c:1443` (`x[1] = 1.0` before optional parse), and `D.2_Input_File_Format.md:1371`.
- **Cross-section dependency:** None
- **Database-key hint:** Plain data — no key role.
- **Technical description:** The on/off state of the pump at simulation time zero. Stored as `Pump[k].initSetting` (1.0 = ON, 0.0 = OFF) via `link_setParams` at `link.c:356`, then copied to `Link[j].setting` and `Link[j].targetSetting` by `pump_initState` at `link.c:1542–1543`. During simulation, if `Link[j].setting == 0.0` the pump returns zero flow immediately (`link.c:1569`). Control rules can subsequently toggle the pump by setting STATUS to ON or OFF (`C.3_Control_Rules_Editor.md:100`). For a Type 5 pump, SETTING in a control rule is interpreted as a speed multiplier (not a boolean), but the boolean STATUS action still applies.
- **Source of truth:** `swmm524_engine/src/link.c:1443–1448` (parse `OffOnWords`); `keywords.c:73` (`OffOnWords`); `link.c:353–360` (`link_setParams` PUMP case).

---

### Startup (Startup Depth)

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** US: feet / SI: meters
- **Valid values / range:** `≥ 0`. Must be strictly greater than `Shutoff` if either is non-zero (else error 122). A value of `0` disables automatic startup control by depth.
- **Default:** `0` — `objprops.txt:480`, `link.c:1452` (`x[2] = 0.0`), `D.2_Input_File_Format.md:1373`.
- **Cross-section dependency:** None
- **Database-key hint:** Plain data — no key role.
- **Technical description:** The water depth at the inlet node (Node1) at which the pump automatically turns ON. Stored as `Pump[k].yOn` in internal SI units (divided by `UCF(LENGTH)`) at `link.c:357`. Validation at `link.c:1518` emits error 122 if `yOn > 0` and `yOn <= yOff`. Depth-based control is subordinate to `[CONTROLS]` rules; if a rule sets the pump STATUS, that overrides the depth thresholds. The GUI property editor unit label adapts to the project unit system: `' (ft)'` or `' (m)'` (`objprops.txt:485`).
- **Source of truth:** `swmm524_engine/src/link.c:1453–1457` (parse); `link.c:357` (store); `link.c:1517–1519` (validation).

---

### Shutoff (Shutoff Depth)

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** US: feet / SI: meters
- **Valid values / range:** `≥ 0`. Must be strictly less than `Startup` if either is non-zero (else error 122). A value of `0` disables automatic shutoff control by depth.
- **Default:** `0` — `objprops.txt:481`, `link.c:1458` (`x[3] = 0.0`), `D.2_Input_File_Format.md:1374`.
- **Cross-section dependency:** None
- **Database-key hint:** Plain data — no key role.
- **Technical description:** The water depth at the inlet node (Node1) below which the pump automatically turns OFF. Stored as `Pump[k].yOff` in internal SI units (divided by `UCF(LENGTH)`) at `link.c:358`. The constraint is: if auto-control is active (`yOn > 0`), then `yOn` must strictly exceed `yOff` (`link.c:1518`). Like Startup, this threshold is overridden by explicit `[CONTROLS]` rule STATUS actions. The GUI property editor shows unit label `' (ft)'` or `' (m)'` (`objprops.txt:485`).
- **Source of truth:** `swmm524_engine/src/link.c:1458–1463` (parse); `link.c:358` (store); `link.c:1517–1519` (validation).

---

## Notes

1. **Pump curve type is NOT a column in `[PUMPS]`** — the curve type (`PUMP1`–`PUMP5`) is an attribute of the curve object itself in `[CURVES]`, not of the pump row. The engine derives the pump's operating mode by reading `Curve[m].curveType` during `pump_validate` (`link.c:1494–1501`). Database designers must join `[PUMPS].Pcurve` → `[CURVES].Name` and inspect `[CURVES].Type` to know which physical variable governs flow.

2. **Legacy format compatibility** — Older SWMM 5.0 GUI files occasionally included an explicit pump-type keyword (`TYPE1`, `TYPE2`, `TYPE3`, or `TYPE4`) as column 4 (between Node2 and Pcurve). The GUI `ReadPumpData` detects this by testing whether token[3] matches any of `PumpTypes[0..3]` and, if so, advances the read pointer by one (`Uimport.pas:1136–1137`). The engine parser does not implement this backward-compatibility skip; files with the old format may be rejected or misparse when passed directly to the command-line engine.

3. **Ideal pump** — Specified by entering `*` as `Pcurve`. No curve lookup occurs; the pump simply passes the total inflow arriving at the inlet node through to the outlet node (`pump_getInflow`: `Node[n1].inflow + Node[n1].overflow`, `link.c:1573`). Error 134 prevents an outflow-only ideal pump from having all-ideal-pump inflows at the same node (`E_Error_and_Warning_Messages.md:42`).

4. **Curve bounds and off-curve operation** — At each time step, if the controlling hydraulic variable falls outside `[xMin, xMax]` of the curve, `Link[j].flowClass` is set to `YES` (Types 1–3, 5) or to `DN_DRY`/`UP_DRY` (Type 4). The summary statistics report the percentage of time the pump operates outside its curve bounds (`9.3_Time_Series_Results.md`).

5. **Variable speed (Type 5) and CONTROLS SETTING** — A control rule can apply a `SETTING` to a pump (any type). For all types except 5, the setting is a simple flow multiplier (`C.3_Control_Rules_Editor.md:104`). For Type 5, the setting is a relative speed ratio: the head argument to the curve lookup is divided by `s²` and the resulting flow is multiplied by `s` (`link.c:1598–1607`), consistent with pump affinity laws.

6. **Type 1 pump wet-well volume** — During validation, a Type 1 pump's `xMax` (maximum volume in ft³) is used to set `Node[n1].fullVolume` if the inlet node is a storage unit and if `xMax` exceeds the current `fullVolume` (`link.c:1522–1528`). This ensures the storage node can represent the full operational range of the pump curve.

7. **No cross-section row required** — Unlike conduits, pumps do not require a corresponding row in `[XSECTIONS]`. The engine sets `Link[j].xsect.yFull = 0.0` explicitly during `pump_validate` (`link.c:1484`).

8. **Uniqueness** — Each pump name must be globally unique across all link sections. The two-pass parser adds the name to the shared LINK hash table in pass 1 (`input.c:336–339`) and would emit `ERR_DUP_NAME` on collision.

9. **Ordering** — No required ordering within `[PUMPS]`. The section is tokenised in a single sequential pass. Pump objects are referenced by name throughout the input file; all sections are fully parsed before validation runs.

10. **Error codes** — Error 121 ("missing or invalid pump curve assigned to Pump xxx") is raised if `Pcurve` names a curve that exists but has a non-pump curve type, or if the curve name cannot be found. Error 122 ("startup depth not higher than shutoff depth") is raised when both depths are non-zero and `Startup ≤ Shutoff`.
