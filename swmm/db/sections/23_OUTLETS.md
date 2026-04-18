# [OUTLETS]

**Purpose:** Defines each outlet flow-control device (link) in the drainage network. Outlets model outflows from storage units or flow diversions where the discharge rate is a user-defined function of either water depth above the outlet opening at the inlet node or the hydraulic head difference between the two end nodes. Unlike orifices and weirs (which use fixed hydraulic equations), outlets accept either a tabular rating curve from the `[CURVES]` section or a power-function (`Q = C1 * H^C2`) as the flow-rate relationship. Outlets can be used under all flow-routing methods when the inlet node is a storage node; if not connected to a storage node they require Dynamic Wave routing.

**Occurrence:** One row per object. Each line defines one outlet link. Two alternative line formats exist depending on whether the rating type is TABULAR (one curve-name column) or FUNCTIONAL (two numeric columns for coefficient and exponent). An optional trailing `Gated` column applies to both formats.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/link.c:2524` — function `outlet_readParams`; called via `link_readParams` at `link.c:155` and `readLink` at `input.c:738` dispatched from `input.c:544`
- Engine section counter: `input.c:356–361` — increments `Nobjects[LINK]` and `Nlinks[OUTLET]`
- Engine writer: (engine does not write INP; no report-echo function in `inputrpt.c` for this section)
- GUI reader: `Uimport.pas:1247` — function `ReadOutletData`; section keyword registered at `Uimport.pas:79`
- GUI writer: `Uexport.pas:1181` — procedure `ExportOutlets`
- GUI editor dialog(s): inline property editor via `OutletProps` array defined in `objprops.txt:902–920`; constants in `Uproject.pas:272–282`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md:1472` — section `[OUTLETS]`
- Additional manual refs: `appendix_B_visual_object_properties/B.11_Outlet_Properties.md`; `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md:428`; `appendix_C_specialized_property_editors/C.3_Control_Rules_Editor.md:73`

## Row Format

Two mutually exclusive formats, distinguished by the value of the `Type` field:

```
Name  Node1  Node2  Offset  TABULAR/DEPTH    Qcurve           (Gated)
Name  Node1  Node2  Offset  TABULAR/HEAD     Qcurve           (Gated)
Name  Node1  Node2  Offset  FUNCTIONAL/DEPTH C1  C2           (Gated)
Name  Node1  Node2  Offset  FUNCTIONAL/HEAD  C1  C2           (Gated)
```

The GUI header comment line (written by `Uexport.pas:1191–1193`) is:
```
;;Name          From Node       To Node         Offset     Type            QTable/Qcoeff    Qexpon    Gated
```

Minimum token count: 6 for TABULAR variants; 7 for FUNCTIONAL variants (`link.c:2541`, `link.c:2575`). The `Gated` column is always optional.

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-whitespace string; must be unique among all link names (`input.c:357–358` calls `project_addObject` which returns an error on duplicate)
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** primary identifier of this row
- **Technical description:** User-assigned label for the outlet link. The engine resolves the name to an index via `project_findID(LINK, tok[0])` at `link.c:2542`. Must match the name registered in the first-pass counter loop (`input.c:356–361`). Referenced by `[CONTROLS]` action clauses to set the outlet's SETTING multiplier (`appendix_C/C.3_Control_Rules_Editor.md:100`).
- **Source of truth:** `link.c:2542–2543`

---

### Node1

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Name of an existing node in the project (junction, storage, outfall, or divider)
- **Default:** none
- **Cross-section dependency:** `[JUNCTIONS].Name`, `[STORAGE].Name`, `[OUTFALLS].Name`, or `[DIVIDERS].Name`
- **Database-key hint:** foreign key to the nodes tables
- **Technical description:** The inlet (upstream) node of the outlet link. Flow calculation uses the water depth and hydraulic head at this node. The crest elevation is computed as `Node[n1].invertElev + Link[j].offset1` (`link.c:2649`). Under all routing methods, the effective driving head is computed relative to this node. Under Steady and Kinematic Wave routing, `Node1` must be a storage node (error 139 is raised otherwise: `appendix_E/E_Error_and_Warning_Messages.md`).
- **Source of truth:** `link.c:2544–2546`

---

### Node2

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Name of an existing node in the project; must differ from `Node1`
- **Default:** none
- **Cross-section dependency:** `[JUNCTIONS].Name`, `[STORAGE].Name`, `[OUTFALLS].Name`, or `[DIVIDERS].Name`
- **Database-key hint:** foreign key to the nodes tables
- **Technical description:** The outlet (downstream) node of the outlet link. Under TABULAR/HEAD and FUNCTIONAL/HEAD rating types with Dynamic Wave routing, the head at this node is subtracted from the head at `Node1` to give the effective driving head (`link.c:2650–2652`). Under Steady or Kinematic Wave routing, the downstream head is assumed to equal the invert elevation of `Node1` (`link.c:2632`).
- **Source of truth:** `link.c:2544–2547`

---

### Offset

- **Data type:** REAL
- **Required:** yes
- **Units:** ft (US) / m (SI) — interpreted as depth or elevation depending on `LINK_OFFSETS` option
- **Valid values / range:** Any real number when `LINK_OFFSETS = ELEVATION` (a `*` token means missing/default; `link.c:2550`). When `LINK_OFFSETS = DEPTH`, negative values are clamped to 0.0 (`link.c:2555`).
- **Default:** 0.0 (GUI default `objprops.txt:545`: `'0'`)
- **Cross-section dependency:** None directly; interpreted relative to `[OPTIONS].LINK_OFFSETS` setting
- **Database-key hint:** plain data – no key role
- **Technical description:** Height of the outlet opening above the invert elevation of the inlet node (`Node1`). When `LINK_OFFSETS = DEPTH` this is a depth directly (ft or m). When `LINK_OFFSETS = ELEVATION` this is an absolute elevation, and `link_convertOffsets` at `link.c:468` subtracts the node invert to convert to a depth offset stored in `Link[j].offset1`. A warning is raised (`WARN10a` or `WARN10b`) and the offset may be adjusted if the opening lies below the invert of the downstream node (`link.c:427–436`). The offset defines the crest elevation: `hcrest = Node[n1].invertElev + Link[j].offset1` (`link.c:2649`). No flow passes if the upstream depth does not exceed `hcrest`.
- **Source of truth:** `link.c:2549–2556`; unit conversion in `link.c:387`

---

### Type

- **Data type:** ENUM
- **Required:** yes
- **Units:** unitless
- **Valid values / range:**
  - `TABULAR/DEPTH` — flow is read from a rating curve in `[CURVES]`; independent variable is water depth above the offset at `Node1`
  - `TABULAR/HEAD` — flow is read from a rating curve in `[CURVES]`; independent variable is hydraulic head difference between the two end nodes
  - `FUNCTIONAL/DEPTH` — flow is computed as `Q = C1 * H^C2`; `H` is water depth above offset at `Node1`
  - `FUNCTIONAL/HEAD` — flow is computed as `Q = C1 * H^C2`; `H` is hydraulic head difference between end nodes
  - Legacy synonyms (GUI backward-compat only): bare `TABULAR` → `TABULAR/DEPTH`; bare `FUNCTIONAL` → `FUNCTIONAL/DEPTH` (`Uimport.pas:1279–1280`)
- **Default:** `FUNCTIONAL/DEPTH` (GUI default `objprops.txt:547`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Determines both the form of the rating relationship (tabular vs. power function) and the hydraulic variable driving it (depth vs. head). The engine parses this in two steps: (1) `findmatch(tok[4], RelationWords)` at `link.c:2559` uses prefix matching against `{ "TABULAR", "FUNCTIONAL", ... }` to determine TABULAR (0) vs. FUNCTIONAL (1); (2) `strtok(tok[4], "/")` at `link.c:2568–2570` extracts the qualifier and sets `x[5] = NODE_HEAD` if the qualifier is `"HEAD"`, otherwise `NODE_DEPTH` (default). This means bare `TABULAR` or `FUNCTIONAL` tokens are parsed correctly by the engine as depth-based. The stored value `Outlet[k].curveType` is either `NODE_DEPTH` (1) or `NODE_HEAD` (2) from `enums.h:201–202`. The TABULAR/HEAD variant only uses Dynamic Wave head difference when `RouteModel == DW` (`link.c:2650`).
- **Source of truth:** `link.c:2558–2570`; `keywords.c:108`; `enums.h:201–202`

---

### Qcurve  *(TABULAR types only)*

- **Data type:** NAME_REF
- **Required:** yes, when `Type` is `TABULAR/DEPTH` or `TABULAR/HEAD`; absent otherwise
- **Units:** n/a (references a curve whose X values are ft or m, Y values are in the project flow units)
- **Valid values / range:** Name of an existing entry in `[CURVES]` section with curve type `RATING`
- **Default:** `*` (GUI internal sentinel `objprops.txt:552`)
- **Cross-section dependency:** `[CURVES].Name` where curve type = `RATING`
- **Database-key hint:** foreign key to `[CURVES].Name`
- **Technical description:** Name of the rating curve that tabulates flow rate as a function of depth or head. The engine resolves the name via `project_findObject(CURVE, tok[5])` and stores the index in `Outlet[k].qCurve` (`link.c:2586–2588`). At runtime, `outlet_getFlow` calls `table_lookup(&Curve[m], h)` where `h` is the head in user units after `h = head * UCF(LENGTH)` conversion (`link.c:2683–2688`). The returned table value is then divided by `UCF(FLOW)` to convert to internal units. The curve must be of type `RATING` (`enums.h:441`, keyword `"RATING"` from `text.h:313`). The GUI populates the dropdown from `Project.Lists[RATINGCURVE]` (`Fproped.pas:382`). When this column is present, columns `C1` and `C2` are absent. Column position is token index 5 (0-based).
- **Source of truth:** `link.c:2583–2589`

---

### C1  *(FUNCTIONAL types only)*

- **Data type:** REAL
- **Required:** yes, when `Type` is `FUNCTIONAL/DEPTH` or `FUNCTIONAL/HEAD`; absent otherwise
- **Units:** flow units / (ft^C2) in US customary; flow units / (m^C2) in SI — i.e., the coefficient is in project flow and length units
- **Valid values / range:** Any real (non-negative values are physically meaningful; the GUI mask `emPosNumber` in `objprops.txt:915` enforces a positive number)
- **Default:** `10.0` (GUI default `objprops.txt:549`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Coefficient `A` in the power-function relation `Q = A * H^B` where `H` is either water depth above the outlet opening or head difference across the nodes (in user length units) and `Q` is in user flow units. Stored as `Outlet[k].qCoeff` (`link.c:389`). At runtime: `return Outlet[k].qCoeff * pow(h, Outlet[k].qExpon) / UCF(FLOW)` where `h = head * UCF(LENGTH)` is already in user units (`link.c:2683–2691`). Column position is token index 5.
- **Source of truth:** `link.c:2576–2577`; `link.c:389`

---

### C2  *(FUNCTIONAL types only)*

- **Data type:** REAL
- **Required:** yes, when `Type` is `FUNCTIONAL/DEPTH` or `FUNCTIONAL/HEAD`; absent otherwise
- **Units:** unitless (dimensionless exponent)
- **Valid values / range:** Any real (the GUI mask `emPosNumber` in `objprops.txt:916` enforces a positive value; the manual states `Q = C1 * H^C2`)
- **Default:** `0.5` (GUI default `objprops.txt:550`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Exponent `B` in the power-function `Q = A * H^B`. Stored as `Outlet[k].qExpon` (`link.c:390`). A value of 0.5 corresponds to orifice-type flow; values around 1.5 approximate weir-type flow. The minimum token count for FUNCTIONAL rows is 7 (Name, Node1, Node2, Offset, Type, C1, C2); if fewer are present the engine returns `ERR_ITEMS` (`link.c:2575`). Column position is token index 6.
- **Source of truth:** `link.c:2578–2579`; `link.c:390`

---

### Gated

- **Data type:** ENUM
- **Required:** no (default: `NO`)
- **Units:** unitless
- **Valid values / range:**
  - `NO` — no flap gate; reverse flow is permitted
  - `YES` — a flap gate prevents flow from reversing direction
- **Default:** `NO` (GUI default `objprops.txt:546`; manual `D.2_Input_File_Format.md:1508`; `link.c:2564` initialises `x[4] = 0.0` before the optional token is read)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Specifies whether the outlet contains a flap (check) valve that blocks reverse flow. Stored as `Link[j].hasFlapGate` (1 = YES, 0 = NO) via `link.c:392`. At runtime, `link_setFlapGate` is called in `outlet_getInflow` (`link.c:2657`); if the gate is closed due to reverse flow direction the function returns 0.0. Token position is index 6 for TABULAR rows and index 7 for FUNCTIONAL rows (`link.c:2593–2597`; `Uimport.pas:1301`). The GUI emits this field unconditionally as the last column (`Uexport.pas:1219`).
- **Source of truth:** `link.c:2592–2597`; `link.c:392`

---

## Notes

- **Routing restriction.** Under Steady Flow or Kinematic Wave routing, outlets (like orifices and weirs) can only be used as outflow links from storage nodes. Error 139 is raised if an outlet's `Node1` is not a storage node under these routing methods (`appendix_E/E_Error_and_Warning_Messages.md`; `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md:428`). Under Dynamic Wave routing there is no such restriction.

- **Head vs. depth for non-DW routing.** When `RouteModel != DW`, the downstream head `h2` is set to `Node[n1].invertElev` (i.e., 0 depth) regardless of `Node2` conditions (`link.c:2630–2633`). Effectively, TABULAR/HEAD and FUNCTIONAL/HEAD behave identically to their DEPTH counterparts when Dynamic Wave routing is not used.

- **Flow direction.** The outlet always routes flow from `Node1` to `Node2`. If upstream head falls below downstream head (`dir < 0.0`), the outlet either reverses flow (if no flap gate) or is closed (if gated). Reverse flow is computed symmetrically by swapping `h1` and `h2` (`link.c:2638–2643`).

- **Control rule SETTING.** An outlet's flow can be modulated at runtime by a `CONTROLS` rule that sets `OUTLET <name> SETTING = <value>`. The setting acts as a multiplier on the rating-curve or functional flow result: `dir * Link[j].setting * outlet_getFlow(k, head)` (`link.c:2667`). The default setting is 1.0 (`link.c:335`).

- **Backward-compatible type keywords.** The GUI reader (`Uimport.pas:1279–1280`) silently upgrades bare `TABULAR` → `TABULAR/DEPTH` and bare `FUNCTIONAL` → `FUNCTIONAL/DEPTH`. The engine's `findmatch` uses prefix matching (`input.c:798–823`), so bare `TABULAR` and `FUNCTIONAL` tokens are also accepted directly by the engine parser and correctly treated as depth-based.

- **TABULAR curve type.** The curve referenced by `Qcurve` must have type `RATING` in `[CURVES]` (`enums.h:441`; keyword `"RATING"` at `text.h:313`). The GUI enforces this by restricting the dropdown to `Project.Lists[RATINGCURVE]` (`Fproped.pas:382`). The engine does not validate curve type at parse time; it resolves by index at `link.c:2586–2588` and uses whatever curve is stored at that index.

- **Offset clamping warnings.** If the outlet crest elevation (`Node1.invertElev + offset`) is below `Node2.invertElev`, WARN10a is reported under KW/Steady routing and WARN10b under DW routing (which also adjusts the offset upward automatically: `link.c:427–436`).

- **Uniqueness.** Each outlet has a unique name within the combined link namespace (conduits, pumps, orifices, weirs, and outlets all share `Nobjects[LINK]`). Duplicate names produce `ERR_DUP_NAME` during the first-pass count (`input.c:357–358`).

- **No XSECTION entry required.** Unlike conduits, orifices, and weirs, outlets do not require a corresponding entry in `[XSECTIONS]`. The engine assigns a DUMMY cross-section internally (`link.c:395`).

- **Composite PK consideration.** The `Name` column uniquely identifies each outlet row. No secondary rows or continuation lines exist for this section.
