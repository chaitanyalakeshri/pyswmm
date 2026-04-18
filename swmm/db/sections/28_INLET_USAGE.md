# [INLET_USAGE]

**Purpose:** Assigns existing inlet structures (defined in `[INLETS]`) to specific street or open channel conduits, specifying which sewer node receives the captured flow and providing optional parameters that control inlet count, clogging, flow restriction, local gutter depression geometry, and on-grade/on-sag placement. This section implements the dual-drainage street/channel capture subsystem: at each routing time step SWMM uses HEC-22 methods (for standard inlets) or a user-supplied diversion/rating curve (for custom inlets) to determine how much of the overland flow in the conduit is intercepted and diverted to the connected sewer node.

**Occurrence:** One row per conduit that has an inlet assigned to it. A conduit may have at most one `[INLET_USAGE]` row (the engine allocates one `TInlet` struct per link). Only conduits with a `STREET`, `RECT_OPEN`, or `TRAPEZOIDAL` cross-section shape can validly carry an inlet; any other shape raises Warning 12 and the inlet is silently removed at validation time.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/inlet.c:362` — function `inlet_readUsageParams`
- Engine dispatch: `swmm524_engine/src/input.c:628` — `case s_INLET_USAGE`
- Engine section enum: `swmm524_engine/src/enums.h:471` — `s_INLET_USAGE`
- Engine section keyword macro: `swmm524_engine/src/text.h:460` — `ws_INLET_USAGE "[INLET_USAGE"`
- Engine validation: `swmm524_engine/src/inlet.c:464` — function `inlet_validate`
- Engine runtime: `swmm524_engine/src/inlet.c:555` — function `inlet_findCapturedFlows`
- Engine writer: (no INP echo; no inlet-usage block in `inputrpt.c`)
- GUI reader: `Uimport.pas:2939` — dispatches to `Uinlet.ReadInletUsageData(TokList, Ntoks)` (section index 56)
- GUI reader implementation: `Uinlet.pas:399` — procedure `ReadInletUsageData`
- GUI writer: `Uexport.pas:2362` — calls `Uinlet.ExportInletUsage(S)`
- GUI writer implementation: `Uinlet.pas:597` — procedure `ExportInletUsage`
- GUI editor dialog: `Dinletusage.pas` / `Dinletusage.dfm`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[INLET_USAGE]` (line 1837)
- Additional manual refs: `appendix_C_specialized_property_editors/C.12_Inlet_Usage_Editor.md`; `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md` (lines 348–381)

## Row Format

```
Conduit  Inlet  Node  (Number  %Clogged  Qmax  aLocal  wLocal  Placement)
```

Columns 4–9 (zero-indexed) are optional. The manual states: *"Only the first three parameters are required. The default number of inlets is 1 (for each side of a two-sided street) while the remaining parameters have default values of 0."* (`D.2_Input_File_Format.md:1867`). The GUI export (`Uinlet.pas:579–593`) always writes all eight data columns but omits the `Placement` token when its value equals `AUTOMATIC`.

## Fields

### Conduit

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must be the name of an existing conduit link in the project.
- **Default:** none
- **Cross-section dependency:** The referenced conduit must have cross-section type `STREET` for grate/curb/combo/slotted inlets, or `RECT_OPEN` / `TRAPEZOIDAL` for drop-grate/drop-curb inlets. Custom inlets are accepted for any conduit. Mismatches trigger Warning 12 and the inlet is discarded at validation time (`inlet.c:528–545`).
- **Database-key hint:** composite PK with this field; also foreign key to `[CONDUITS].Name`
- **Technical description:** Identifies the conduit link that carries the surface flow being intercepted. The engine looks up this name via `project_findObject(LINK, tok[0])` (`inlet.c:392`). The GUI validates that the name exists in `Project.Lists[CONDUIT]` (`Uinlet.pas:427–429`). At runtime the engine uses `Link[linkIndex].newFlow` (on-grade) or `Node[Link[i].node2].inflow` (on-sag) as the input flow to the capture computation (`inlet.c:595–610`).
- **Source of truth:** `inlet.c:391–393`

### Inlet

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must be the name of an existing inlet design defined in the `[INLETS]` section.
- **Default:** none
- **Cross-section dependency:** `[INLETS].Name`
- **Database-key hint:** composite PK with `Conduit`; also foreign key to `[INLETS].Name`
- **Technical description:** Identifies the inlet design to use. The engine uses `project_findObject(INLET, tok[1])` to obtain `designIndex` (`inlet.c:396–397`), which selects the `TInletDesign` entry (type, dimensions, capture coefficients). The GUI checks `Project.Lists[INLET]` and returns `INLET_ERR` if the name is not found (`Uinlet.pas:432–436`).
- **Source of truth:** `inlet.c:396–397`

### Node

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must be the name of any node (junction, outfall, storage, or divider) in the project.
- **Default:** none
- **Cross-section dependency:** `[JUNCTIONS].Name` | `[OUTFALLS].Name` | `[STORAGE].Name` | `[DIVIDERS].Name`
- **Database-key hint:** foreign key to the relevant node table
- **Technical description:** The node that receives all flow captured by the inlet. During routing, `inlet->flowCapture` is added as a lateral inflow to this node (`inlet.c:614`). Any overflow from this capture node can flow back into the conduit as backflow (`inlet.c:618`). The GUI validates that the node exists via `Project.GetNode(TokList[2])` (`Uinlet.pas:442–444`).
- **Source of truth:** `inlet.c:400–401`

### Number

- **Data type:** INTEGER
- **Required:** no (default: `1`)
- **Units:** unitless (count)
- **Valid values / range:** integer ≥ 1
- **Default:** `1`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Number of identical inlet units placed in the conduit. For a two-sided street, this is the count on each side (so the total number of openings is doubled). The parser rejects values < 1 (`inlet.c:405–406`). Stored as `inlet->numInlets` and used inside the capture-flow equations to scale the total interception. The GUI offers a combo-list of 1–5 in the editor (`Dinletusage.pas:100`; the string `'1'#13'2'#13'3'#13'4'#13'5'`).
- **Source of truth:** `inlet.c:404–406`

### %Clogged

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** percent (0–99)
- **Valid values / range:** `0 ≤ %Clogged < 100` (engine enforces `< 99.` not `< 100.`; `inlet.c:411–413`)
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Fractional reduction in effective inlet opening area due to debris, sediment, or other obstruction. Internally stored as `inlet->clogFactor = 1.0 - (pctClogged / 100.)` (`inlet.c:451`). A value of 0 means unobstructed; 40 reduces capture by 40 %. Values ≥ 100 are rejected by the parser. The GUI mask for this field is `emPosNumber` (positive number; `Dinletusage.pas:203–205`).
- **Source of truth:** `inlet.c:408–413`

### Qmax

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** project flow units (CFS, GPM, MGD, CMS, LPS, or MLD depending on `[OPTIONS].FLOW_UNITS`)
- **Valid values / range:** `≥ 0`; value of `0` means no restriction
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Upper bound on the flow that a single inlet can capture. The stored internal value is converted to CFS/CMS at parse time via `inlet->flowLimit = flowLimit / UCF(FLOW)` (`inlet.c:452`). During routing, captured flow is capped at `flowLimit` before being transferred to the capture node. A value of 0 disables the restriction (`D.2_Input_File_Format.md:1869`). GUI label is "Flow Restriction" (`Dinletusage.pas:77`).
- **Source of truth:** `inlet.c:415–417`

### aLocal

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** US: inches or feet (see note); SI: millimetres or metres (see note)
- **Valid values / range:** `≥ 0`
- **Default:** `0`
- **Cross-section dependency:** None; ignored for drop inlets (`C.12_Inlet_Usage_Editor.md`)
- **Database-key hint:** plain data – no key role
- **Technical description:** Height of a local gutter depression that exists only over the length of the inlet structure (distinct from the continuous depression of the `STREET` cross-section which exists over the full curb length). A local depression increases the effective capture efficiency of on-grade inlets. The manual specifies units as "in or mm" (`D.2_Input_File_Format.md:1857`), but the engine stores it as `inlet->localDepress = aLocal / UCF(LENGTH)` converting from the project's length unit (ft or m) (`inlet.c:453`). The GUI tooltip says "ft or m" (`Dinletusage.pas:94–95`). This apparent discrepancy is resolved by examining that the project length unit (`UCF(LENGTH)`) maps to ft or m; the manual's "in or mm" notation is a documentation inconsistency — the value is treated as feet (US) or metres (SI). A value of 0 means no local depression.
- **Source of truth:** `inlet.c:419–421`

### wLocal

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** ft (US) / m (SI)
- **Valid values / range:** `≥ 0`; should be at least as large as the width of the inlet opening into the gutter
- **Default:** `0`
- **Cross-section dependency:** Ignored if `aLocal = 0` or if the inlet is a drop inlet (`C.12_Inlet_Usage_Editor.md`)
- **Database-key hint:** plain data – no key role
- **Technical description:** Width of the local gutter depression. Per the manual: *"It should be at least as large as the width that the inlet extends out into the gutter."* Stored as `inlet->localWidth = wLocal / UCF(LENGTH)` (`inlet.c:454`). The GUI requires both `aLocal` and `wLocal` to be present together — if token index 6 (aLocal) is found the parser also requires token index 7 (wLocal) or returns `ERR_ITEMS` (`Uinlet.pas:480–495`). The engine's `inlet_readUsageParams` does not enforce paired presence but treats missing `wLocal` as 0.
- **Source of truth:** `inlet.c:423–425`

### Placement

- **Data type:** ENUM
- **Required:** no (default: `AUTOMATIC`)
- **Units:** n/a
- **Valid values / range:**
  - `AUTOMATIC` — program determines placement from network topography at validation time
  - `ON_GRADE` — inlet is on a continuous slope; HEC-22 on-grade capture equations are used
  - `ON_SAG` — inlet is at a sag/sump point; HEC-22 on-sag (weir/orifice) equations are used
- **Default:** `AUTOMATIC`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Controls which hydraulic capture model is applied. When set to `AUTOMATIC` the engine calls `getInletPlacement(inlet, j)` at each routing step, which returns `ON_GRADE` if the bypass node (`Link[i].node2`) has `degree > 0` (at least one downstream conduit), otherwise `ON_SAG` (`inlet.c:1129–1143`). The manual describes this as: *"the program uses the network topography to determine whether an inlet operates on-grade or on-sag"* (`D.2_Input_File_Format.md:1873`). The keyword list is defined locally in `inlet.c:146–147` as `{"AUTOMATIC", "ON_GRADE", "ON_SAG"}` and matched with `findmatch` (`inlet.c:430`). The GUI offers the same three keywords in a combo list (`Dinletusage.pas:101`: `'AUTOMATIC'#13'ON_GRADE'#13'ON_SAG'`). The GUI writer omits the token when the value is `AUTOMATIC` (`Uinlet.pas:591–592`).
- **Source of truth:** `inlet.c:428–432`

## Notes

- **One inlet per conduit:** The engine stores inlet usage as a linked list (`TInlet.nextInlet`), but each link may carry at most one `TInlet` struct (`inlet.c:435–443`). If a link name appears a second time in `[INLET_USAGE]` the existing struct is reused and overwritten. The GUI also enforces one inlet per conduit by storing usage via `aLink.Inlet` pointer (`Uinlet.pas:508–513`).

- **Section keyword prefix matching:** `ws_INLET_USAGE` is defined as `"[INLET_USAGE"` (`text.h:460`) and `ws_INLET` as `"[INLET"` (`text.h:459`). The section dispatcher uses prefix matching, so `[INLET_USAGE]` must appear before `[INLET]` in `SectWords[]`/`Sections[]` arrays to avoid misidentification. Both the engine (`keywords.c:145`) and GUI (`Uimport.pas:116–118`) list `[INLET_USAGE` before `[INLET` for this reason.

- **Validation and Warning 12:** `inlet_validate()` (`inlet.c:464`) traverses all inlet usages and removes any whose conduit cross-section is incompatible with the inlet type (e.g., a curb-opening inlet on a trapezoidal channel). The removed inlet issues `WARN12` and sets `Link[i].inlet = NULL`. This check occurs after all parsing is complete.

- **Local depression units inconsistency:** The `D.2_Input_File_Format.md` manual (line 1857) states `aLocal` is in "in or mm", but the engine divides by `UCF(LENGTH)` which converts from feet or metres (the project's length unit). The GUI tooltip (`Dinletusage.pas:94`) says "ft or m". Users supplying inch or mm values will produce incorrect results; the unit should be treated as ft (US) or m (SI).

- **Paired aLocal/wLocal requirement in GUI:** The GUI's `ReadInletUsageData` (`Uinlet.pas:480–495`) requires that if token[6] (`aLocal`) is present, token[7] (`wLocal`) must also be present or an `ITEMS_ERR` is returned. The engine parser does not enforce this and treats missing `wLocal` as 0.

- **Placement token omission on export:** `ExportInletUsage` (`Uinlet.pas:591–592`) omits the `Placement` column when its value is `AUTOMATIC`, making the column truly optional for the default case.

- **Cross-section shape constraints (summary):**
  - `STREET` cross-section: accepts `GRATE`, `CURB OPENING`, `COMBINATION`, `SLOTTED DRAIN`, and `CUSTOM` inlets.
  - `RECT_OPEN` or `TRAPEZOIDAL` cross-section: accepts `DROP GRATE`, `DROP CURB`, and `CUSTOM` inlets.
  - Any other cross-section shape: no valid inlet type exists; `inlet_validate` removes any assigned inlet with Warning 12 (`inlet.c:498–505`, `D.2_Input_File_Format.md:1863–1865`).

- **Routing model dependency:** On-sag inlets under non-Dynamic-Wave routing have their captured flow capped to prevent extraction of more flow than the bypass node actually has available (`inlet.c:633–639`). Under Dynamic Wave routing no such cap is applied.

- **Backflow:** If the capture node overflows (i.e., `Node[m].overflow > 0`), a fraction of that overflow is returned to the bypass node as backflow, proportioned among all inlets sharing the same capture node via `getBackflowRatios()` (`inlet.c:549–550`).

- **SWMM version:** `[INLET_USAGE]` and the dual-drainage inlet system were introduced in SWMM 5.2.0 (`keywords.c` comment: *"Build 5.2.0: Support added for Streets and Inlets."*).
