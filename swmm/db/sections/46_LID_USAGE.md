# [LID_USAGE]

**Purpose:** Deploys previously defined LID (Low Impact Development) controls within specific subcatchments. Each row assigns one LID control type to one subcatchment, specifying how many replicate units are placed, their physical dimensions, initial moisture state, what fraction of the subcatchment's impervious and pervious runoff they intercept, whether their outflow is returned to the pervious sub-area, and where underdrain flow is routed. A subcatchment may contain multiple LID types (multiple rows), and the same LID process type may appear in multiple subcatchments.

**Occurrence:** Multiple rows per object — one row per (Subcatchment, LIDProcess) deployment. The same subcatchment may have several rows (one per LID control type placed in it). The LID process name is not unique within the section; the composite (Subcatchment, LIDProcess) identifies each deployment.

**SWMM source references:**
- Engine parser: `input.c:616` — dispatches to `lid_readGroupParams`; `lid.c:415` — function `lid_readGroupParams`
- Engine writer: Engine does not write INP. Report-echo function `lid_writeSummary` at `lid.c:869` echoes a tabular LID Control Summary to the RPT file.
- GUI reader: `Uimport.pas:2119` — function `ReadLidUsageData` (wrapper); actual parsing delegated to `Ulid.pas:828` — function `ReadLidUsageData`
- GUI writer: `Ulid.pas:431` — procedure `ExportLIDGroups` (called via `Uexport.pas:2340` as `Ulid.ExportLIDGroups(S, Tab)`)
- GUI editor dialog(s): `Appendix C.17 LID Usage Editor` (invoked from the LID Group Editor, `C.16`)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[LID_USAGE]` (lines 870–915)
- Additional manual refs: Appendix C.16 (LID Group Editor), Appendix C.17 (LID Usage Editor)

## Row Format

```
Subcat  LID  Number  Area  Width  InitSat  FromImp  ToPerv  (RptFile  DrainTo  FromPerv)
```

The first eight columns are required. Three optional trailing columns (`RptFile`, `DrainTo`, `FromPerv`) may be omitted. Use `*` as a placeholder for any skipped optional field when a field that follows it is present. The GUI always emits all eleven columns, writing `*` for absent optional values (`Ulid.pas:483,487,490`).

## Fields

### Subcatchment

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match a name in `[SUBCATCHMENTS]`.
- **Default:** none
- **Cross-section dependency:** `[SUBCATCHMENTS].Name`
- **Database-key hint:** composite PK with LIDProcess (and potentially Number for multi-row same-type deployments; see Notes)
- **Technical description:** Identifies the receiving subcatchment. The engine calls `project_findObject(SUBCATCH, toks[0])` and returns `ERR_NAME` if not found (`lid.c:448–449`). The GUI wrapper (`Uimport.pas:2126`) calls `FindSubcatch(TokList[0])` and emits `SUBCATCH_ERR` if nil.
- **Source of truth:** `lid.c:448`

### LIDProcess

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match a name defined in `[LID_CONTROLS]`.
- **Default:** none
- **Cross-section dependency:** `[LID_CONTROLS].Name`
- **Database-key hint:** composite PK with Subcatchment
- **Technical description:** Identifies which LID control type is being deployed. The engine calls `project_findObject(LID, toks[1])` and returns `ERR_NAME` if not found (`lid.c:452–453`). The GUI stores this as the key string in the subcatchment's LID list (`Ulid.pas:868`).
- **Source of truth:** `lid.c:452`

### Number

- **Data type:** INTEGER
- **Required:** yes
- **Units:** unitless (count)
- **Valid values / range:** `≥ 0`. A value of 0 causes the entire row to be silently skipped — no LID unit is created (`lid.c:458`). Negative values return `ERR_NUMBER`.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Number of identical replicate LID units placed in the subcatchment (e.g., number of rain barrels). The total area occupied equals `Number × Area`. The engine uses this count when accumulating `totalLidArea` during validation (`lid.c:1139`). GUI stores as `LidUnit.Data[UNIT_COUNT]` (index 0, `Ulid.pas:41`).
- **Source of truth:** `lid.c:456–458`

### Area

- **Data type:** REAL
- **Required:** yes
- **Units:** ft² (US) / m² (SI)
- **Valid values / range:** `≥ 0`
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Surface area of each single replicate LID unit. The engine converts to internal ft² via `x[0] / SQR(UCF(LENGTH))` (`lid.c:547`). If the "LID Occupies Full Subcatchment" option is used in the GUI, this field is computed as total subcatchment area divided by the number of units and the input field is disabled (`C.17`). Validation checks that the sum of `Number × Area` across all LIDs in a subcatchment does not exceed the subcatchment's total area by more than 0.1% (`lid.c:1195–1198`, error `ERR_LID_AREAS`). GUI stores as `LidUnit.Data[UNIT_AREA]` (index 1, `Ulid.pas:42`).
- **Source of truth:** `lid.c:547`, `lid.c:1139`, `lid.c:1195`

### Width

- **Data type:** REAL
- **Required:** yes
- **Units:** ft (US) / m (SI)
- **Valid values / range:** `≥ 0`. May be 0 for LID types that do not use overland outflow (bio-retention cells, rain gardens, rain barrels).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Width of the outflow face of each replicate unit. Applies to LID types that convey surface runoff via overland flow: roofs, permeable pavement, infiltration trenches, and vegetative swales. For vegetative swales specifically, validation at `lid.c:1173–1178` reports `ERR_LID_PARAMS` if `fullWidth ≤ 0`. The engine converts to internal ft via `x[1] / UCF(LENGTH)` (`lid.c:548`). GUI stores as `LidUnit.Data[UNIT_WIDTH]` (index 2, `Ulid.pas:43`).
- **Source of truth:** `lid.c:548`, `lid.c:1173`

### InitSat

- **Data type:** REAL
- **Required:** yes
- **Units:** % (0–100)
- **Valid values / range:** `0–100`
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Initial saturation level, in percent, for the LID's soil, storage, and drain mat layers. For soil layers, 0% corresponds to the wilting-point moisture content and 100% to full porosity. For storage layers, it corresponds to initial water depth. The engine stores the fractional form: `lidUnit->initSat = x[2] / 100.0` (`lid.c:549`). Values `> 100` return `ERR_NUMBER` (`lid.c:467–469`). GUI field label is "% Initially Saturated" (`C.17`); stored as `LidUnit.Data[INIT_MOISTURE]` (index 3, `Ulid.pas:44`).
- **Source of truth:** `lid.c:463–469`, `lid.c:549`

### FromImpervious

- **Data type:** REAL
- **Required:** yes
- **Units:** % (0–100)
- **Valid values / range:** `0–100`
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Percent of the impervious portion of the subcatchment's non-LID area whose runoff is diverted to and treated by this LID unit. For example, if rain barrels capture roof runoff and roofs represent 60% of the impervious area, set this to 60. Use 0 for LIDs that treat only direct rainfall (green roofs, roof disconnection). Ignored if the LID occupies the entire subcatchment. The manual parameter name is `FromImp`; the INP column header is `FromImp`. The engine stores as fraction: `lidUnit->fromImperv = x[3] / 100.0` (`lid.c:550`). Validation at `lid.c:1199–1201` raises `ERR_LID_CAPTURE_AREA` if the sum of `fromImperv` across all LIDs in the subcatchment exceeds 1.001 (100.1%). Note: if the subcatchment internally routes some impervious runoff onto its pervious area, this percentage applies only to the remaining un-routed impervious area (`C.17`). GUI stores as `LidUnit.Data[FROM_IMPERV]` (index 4, `Ulid.pas:45`).
- **Source of truth:** `lid.c:463–469`, `lid.c:550`, `lid.c:1199`

### ToPerv

- **Data type:** INTEGER (boolean flag)
- **Required:** yes
- **Units:** unitless
- **Valid values / range:** `0` or `1`
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Flag indicating whether surface and drain outflow from the LID unit should be routed back onto the pervious sub-area of the containing subcatchment. `1` = route back to pervious area; `0` = route to normal subcatchment outlet. Commonly set to 1 for rain barrels, rooftop disconnection, and green roofs. If `ToPerv = 1` and `DrainTo` specifies a different outlet, only the excess surface flow is returned to the pervious area; underdrain flow goes to `DrainTo` (manual remark at line ~909). If the subcatchment has no pervious area (`fracImperv ≥ 0.999`), the engine overrides this to 0 at validation (`lid.c:1183`). The engine stores as a boolean int: `lidUnit->toPerv = (x[4] > 0.0)` (`lid.c:551`). GUI stores as `LidUnit.Data[ROUTE_TO]` (index 5, `Ulid.pas:46`).
- **Source of truth:** `lid.c:551`, `lid.c:1183`

### RptFile

- **Data type:** TEXT
- **Required:** no (default: `*` / none)
- **Units:** n/a (file path)
- **Valid values / range:** A valid file system path. Enclose in double quotes if the path contains spaces. Use `*` as a placeholder if this field is omitted but `DrainTo` or `FromPerv` follows.
- **Default:** none (field omitted or `*`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Optional path to a tab-delimited text file where detailed time series results for this LID unit will be written at each reporting time step. The engine opens this file in write mode via `createLidRptFile` (`lid.c:567–577`) and returns `ERR_RPT_FILE` if the file cannot be opened (`lid.c:559–561`). The GUI stores the full path in `LidUnit.Data[RPT_FILE_NAME]` (index 6, `Ulid.pas:47`) and writes a relative path on export (`Ulid.pas:482`). Token 8 (0-indexed) in the INP line; the token `*` means no report file (`lid.c:472`, `Ulid.pas:853`).
- **Source of truth:** `lid.c:471–472`, `lid.c:559–561`

### DrainTo

- **Data type:** NAME_REF
- **Required:** no (default: `*` / none)
- **Units:** n/a
- **Valid values / range:** Name of a node in `[JUNCTIONS]`, `[OUTFALLS]`, `[DIVIDERS]`, or `[STORAGE]`, or a name in `[SUBCATCHMENTS]`. Use `*` as a placeholder if omitted but `FromPerv` follows.
- **Default:** Subcatchment outlet (same as the subcatchment's `[SUBCATCHMENTS]` outlet node/subcatchment)
- **Cross-section dependency:** `[SUBCATCHMENTS].Name` or any node section Name
- **Database-key hint:** foreign key to [SUBCATCHMENTS].Name or to a node table Name
- **Technical description:** Optional name of the subcatchment or node that receives flow from the LID unit's underdrain line, if different from the subcatchment's normal outlet. The engine first tries to match a subcatchment name, then a node name, returning `ERR_NAME` if neither is found (`lid.c:476–482`). At validation, if neither `drainNode` nor `drainSubcatch` is set, they inherit the subcatchment's configured outlet (`lid.c:1186–1190`). Token 9 (0-indexed); the token `*` means use default routing (`lid.c:475`). GUI stores as `LidUnit.Data[DRAIN_TO]` (index 8, `Ulid.pas:49`).
- **Source of truth:** `lid.c:474–482`, `lid.c:1186`

### FromPerv

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** % (0–100)
- **Valid values / range:** `0–100`. Values outside this range return `ERR_NUMBER` (`lid.c:489`).
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Percent of the pervious portion of the subcatchment's non-LID area whose runoff is diverted to and treated by this LID unit. Analogous to `FromImpervious` but for the pervious sub-area. Use 0 for LIDs treating only direct rainfall. Ignored if the LID occupies the entire subcatchment. Added in engine build 5.1.013 (`lid.h` header comment line 23). The engine stores as fraction: `lidUnit->fromPerv = x[5] / 100.0` (`lid.c:552`). Validation at `lid.c:1199–1201` checks that the sum of `fromPerv` across all LIDs in the subcatchment does not exceed 1.001. Token 10 (0-indexed); the token `*` is treated as 0 (`lid.c:487–490`, `Ulid.pas:864`). GUI stores as `LidUnit.Data[FROM_PERV]` (index 9, `Ulid.pas:50`). The GUI initialises this to `'0'` before parsing (`Ulid.pas:863`).
- **Source of truth:** `lid.c:486–491`, `lid.c:552`, `lid.c:1199`

## Notes

- **Minimum tokens:** The engine requires at least 8 tokens per line (`lid.c:445`); the GUI likewise requires `Ntoks ≥ 8` (`Ulid.pas:840`). The three optional trailing tokens (positions 8, 9, 10 in 0-based indexing) may be absent.
- **Placeholder `*`:** Both the engine and GUI treat the literal token `*` for `RptFile` and `DrainTo` as "not supplied". The GUI emits `*` for absent optional fields to preserve column count (`Ulid.pas:483,487,490`).
- **Number = 0 is a no-op:** If `Number` is 0 the engine returns 0 (success) without creating any LID unit (`lid.c:458`). This allows users to temporarily disable an LID without removing the row.
- **Same LID process in multiple subcatchments:** A given LID process (from `[LID_CONTROLS]`) may appear in any number of different subcatchments. Multiple rows with the same `Subcatchment` value but different `LIDProcess` values are each independent deployments within that subcatchment.
- **Area validation:** The sum of `Number × Area` across all LID rows for the same subcatchment must not exceed the subcatchment's total area by more than 0.1% (`lid.c:1195–1198`, error `ERR_LID_AREAS`). If it equals the total area within 0.1%, the engine snaps `Subcatch[j].lidArea` to exactly the total area (`lid.c:1205`).
- **Capture-area validation:** The sum of `FromImpervious` fractions across all LID rows for the same subcatchment must not exceed 100% (tolerance 0.1%); the same applies to the sum of `FromPerv` fractions (`lid.c:1199–1201`, error `ERR_LID_CAPTURE_AREA`). The C.16 LID Group Editor also enforces that the combined percentages remain ≤ 100%.
- **ToPerv overridden:** If the subcatchment is 100% impervious (`fracImperv ≥ 0.999`), the engine silently resets `toPerv` to 0 at validation (`lid.c:1183`).
- **Vegetative swale width requirement:** For a LID of type `VEG_SWALE`, `Width` must be > 0; the engine reports `ERR_LID_PARAMS` otherwise (`lid.c:1173–1178`).
- **DrainTo defaults to subcatchment outlet:** When `DrainTo` is absent (or `*`), the engine assigns the subcatchment's configured `outNode` or `outSubcatch` to the LID unit at validation (`lid.c:1186–1190`).
- **GUI column order (ExportLIDGroups):** Subcatchment, LIDProcess, Number, Area, Width, InitSat, FromImp, ToPerv, RptFile, DrainTo, FromPerv — exactly 11 columns (`Ulid.pas:450–455`).
- **Report echo:** `lid_writeSummary` (`lid.c:869`) writes a LID Control Summary table to the RPT file, not to the INP file. It echoes Number, Unit Area, Unit Width, % Area, % Imperv, and % Perv for each deployed LID unit.
- **Section keyword prefix matching:** The engine uses prefix matching on section keywords (`text.h:453` defines `ws_LID_USAGE` as `"[LID_USAGE"`); the closing bracket is not required.
