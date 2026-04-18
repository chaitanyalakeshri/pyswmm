# [DIVIDERS]

**Purpose:** Identifies each flow divider node in the drainage network. Flow dividers are junction nodes with exactly two outflow conduits where the total inflow is split between the two outflow links according to one of four prescribed diversion methods (CUTOFF, OVERFLOW, TABULAR, or WEIR). They are used to model flow splits at bifurcation points such as overflows to bypasses, relief sewers, or diversion structures.

**Occurrence:** One row per divider node. All divider nodes must appear exactly once in this section. Because the divider sub-type controls which type-specific trailing columns are present, each row has a variable number of tokens depending on the divider type.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/node.c:1113` — function `divider_readParams`
- Engine object counting pass: `swmm524_engine/src/input.c:321` — `case s_DIVIDER` (first pass, counts objects); `swmm524_engine/src/input.c:529` — `case s_DIVIDER: return readNode(DIVIDER)` (second pass, reads params)
- Engine writer: Engine does not write INP files. The node summary (not the INP text) is echoed via `inputrpt.c` in the generic node table at line 168, listing node type, invert, depth, and ponded area — but no divider-specific parameters are reported there.
- GUI reader: `Uimport.pas:1007` — procedure `ReadDividerData`
- GUI writer: `Uexport.pas:901` — procedure `ExportDividers`
- GUI editor dialog: `objprops.txt:776` — `DividerProps` array (property editor definition with list values, masks, headings)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md:1173` — Section [DIVIDERS]
- Additional manual refs: `appendix_B_visual_object_properties/B.5_Flow_Divider_Properties.md`; `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md:106`

## Row Format

Each row has a mandatory prefix of four tokens, followed by type-specific parameter token(s), then up to four optional trailing tokens:

```
; OVERFLOW (no type-specific params):
Name  Elev  DivLink  OVERFLOW  (Ymax  Y0  Ysur  Apond)

; CUTOFF:
Name  Elev  DivLink  CUTOFF   Qmin  (Ymax  Y0  Ysur  Apond)

; TABULAR:
Name  Elev  DivLink  TABULAR  Dcurve  (Ymax  Y0  Ysur  Apond)

; WEIR:
Name  Elev  DivLink  WEIR     Qmin  Ht  Cd  (Ymax  Y0  Ysur  Apond)
```

Fields in parentheses are optional; all default to `0`. The GUI always emits all four optional trailing fields (DIVIDER_MAX_DEPTH_INDEX=8 through DIVIDER_PONDED_AREA_INDEX=11 in `Uexport.pas:948`).

Example from D.2 (line 64):
```
NODE5  3.0  C6  CUTOFF  1.0
```

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-whitespace string; must be unique among all node names (junctions, outfalls, storage units, dividers share the same `NODE` namespace). Maximum practical length is not hard-coded in C source but the GUI uses `emNoSpace` mask (`objprops.txt:777`).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** primary identifier of this row; also a foreign key from links' node1/node2 in `[CONDUITS]`, `[PUMPS]`, `[ORIFICES]`, `[WEIRS]`, `[OUTLETS]`
- **Technical description:** User-assigned name that uniquely identifies the divider node. The engine registers it in the global `NODE` hash table during the first input pass (`input.c:322`, `project_addObject(NODE, id, ...)`). Duplicate names across node types raise `ERR_DUP_NAME`.
- **Source of truth:** `node.c:1137` — `project_findID(NODE, tok[0])`

---

### Elev

- **Data type:** REAL
- **Required:** yes
- **Units:** feet (US) / metres (SI)
- **Valid values / range:** any real; negative values allowed for below-datum inverts
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Invert elevation of the node. Stored internally in metres (divided by `UCF(LENGTH)` at `node.c:137`). Used as the datum for all depth calculations. If `Ymax` is 0, the engine sets `fullDepth` to the distance from this invert to the crown of the highest connecting conduit at validation time (`node.c:200–210`).
- **Source of truth:** `node.c:1141` — `getDouble(tok[1], &x[0])`; `node.c:137` — `Node[j].invertElev = x[0] / UCF(LENGTH)`

---

### DivLink

- **Data type:** NAME_REF
- **Required:** yes (a `*` or empty string is accepted syntactically but will fail validation)
- **Units:** n/a
- **Valid values / range:** Name of an existing link in the `[CONDUITS]` (or other link type) section. The link must be attached to this node (i.e., have this node as either node1 or node2). A `*` or empty string sets the internal index to `-1`, which triggers `ERR_DIVIDER_LINK` at validation.
- **Default:** `*` (GUI default, `objprops.txt:386`)
- **Cross-section dependency:** `[CONDUITS].Name` (or any link section)
- **Database-key hint:** foreign key to the link that receives diverted flow (the "diversion link")
- **Technical description:** The name of exactly one of the two outflow conduits from this node; this is the link that receives the *diverted* portion of the flow. The other conduit attached to this node receives the undiverted portion. At validation (`node.c:1227`), the engine confirms the named link is actually connected to the node, otherwise error 136 (`ERR_DIVIDER_LINK`) is raised. Under OVERFLOW diversion logic the non-diversion link gets flow first, then the diversion link receives the excess (`node.c:1278–1283`).
- **Source of truth:** `node.c:1150–1155` — `project_findObject(LINK, tok[2])`; `node.c:1226–1230` — `divider_validate`; `error.h:48` — `ERR_DIVIDER_LINK = 136`

---

### Type

- **Data type:** ENUM
- **Required:** yes
- **Units:** unitless
- **Valid values / range:**
  - `CUTOFF` — diverts all flow above a threshold cutoff value (enum `CUTOFF_DIVIDER = 0`)
  - `TABULAR` — diverted flow read from a DIVERSION_CURVE table (enum `TABULAR_DIVIDER = 1`)
  - `WEIR` — diverted flow computed by weir equation (enum `WEIR_DIVIDER = 2`)
  - `OVERFLOW` — diverts all flow exceeding the capacity of the non-diversion link (enum `OVERFLOW_DIVIDER = 3`)
- **Default:** `CUTOFF` (GUI default, `objprops.txt:387`)
- **Cross-section dependency:** None (but controls which subsequent columns are required)
- **Database-key hint:** plain data – no key role
- **Technical description:** Determines the algorithm used to split total inflow between the two outflow conduits and controls which type-specific parameter fields follow on the same line. The keyword is matched case-insensitively using `findmatch(tok[3], DividerTypeWords)` (`node.c:1159`). The `DividerTypeWords` array is `{ "CUTOFF", "TABULAR", "WEIR", "OVERFLOW", NULL }` (`keywords.c:50`). Note: the enum order in `enums.h:412` is CUTOFF=0, TABULAR=1, WEIR=2, OVERFLOW=3 — matching the array order exactly. An unrecognised keyword triggers `ERR_KEYWORD`.
- **Source of truth:** `node.c:1159` — `findmatch(tok[3], DividerTypeWords)`; `keywords.c:50`; `enums.h:412–416`; `text.h:187–189, 374`

---

### Qmin *(CUTOFF type — token index 4; WEIR type — token index 4)*

- **Data type:** REAL
- **Required:** yes when Type = `CUTOFF` or `WEIR`; absent for `OVERFLOW` and `TABULAR`
- **Units:** flow units (CFS, GPM, MGD, CMS, LPS, or MLD per project `[OPTIONS]` FLOW_UNITS)
- **Valid values / range:** `≥ 0`; GUI mask is `emPosNumber` (`objprops.txt:793, 799`)
- **Default:** `0` (GUI default `objprops.txt:389, 393`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** For `CUTOFF`: when total inflow ≤ Qmin, no flow is diverted; above Qmin, all excess is diverted (`node.c:1272–1273`). For `WEIR`: minimum inflow threshold below which no diversion occurs; also used in the weir fraction equation `f = (Qin - Qmin) / (Qmax - Qmin)` (`node.c:1294`). Stored internally in CFS (`x[4] / UCF(FLOW)` at `node.c:187`). Validation for `WEIR` checks that Qmin ≤ Qmax (`node.c:1243`), otherwise error 137 (`ERR_WEIR_DIVIDER`) is raised.
- **Source of truth:** `node.c:1175–1180` (CUTOFF branch); `node.c:1184–1191` (WEIR branch); `node.c:187` — stored as `Divider[k].qMin`

---

### Dcurve *(TABULAR type — token index 4)*

- **Data type:** NAME_REF
- **Required:** yes when Type = `TABULAR`; absent for all other types
- **Units:** n/a
- **Valid values / range:** Name of a curve in the `[CURVES]` section with curve type `DIVERSION`. The curve relates total inflow (x-axis, in flow units) to diverted flow (y-axis, in flow units). A `*` is the GUI placeholder default (`objprops.txt:391`).
- **Default:** `*`
- **Cross-section dependency:** `[CURVES].Name` where curve type = `DIVERSION` (enum `DIVERSION_CURVE = 1`, `enums.h:439`)
- **Database-key hint:** foreign key to `[CURVES].Name`
- **Technical description:** At runtime, the engine calls `table_lookup(&Curve[m], qIn * UCF(FLOW))` to obtain diverted flow from the curve, then converts back to internal units (`node.c:1309`). If the curve index is `-1` (not found), the diverted flow is set to 0 (`node.c:1310`). The GUI populates the curve dropdown from `Project.Lists[DIVERSIONCURVE]` (`Fproped.pas:378`).
- **Source of truth:** `node.c:1165–1171` — `project_findObject(CURVE, tok[4])`; `node.c:1307–1310` — runtime lookup

---

### Ht *(WEIR type only — token index 5)*

- **Data type:** REAL
- **Required:** yes when Type = `WEIR`
- **Units:** feet (US) / metres (SI)
- **Valid values / range:** `> 0`; validation requires `Divider[k].dhMax > 0.0` (`node.c:1236`)
- **Default:** `0` (GUI default `objprops.txt:394`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Height of the weir opening (referred to as `Hw` or `dhMax` in the engine). Used to compute maximum weir flow: `Qmax = Cw * Hw^1.5 / UCF(FLOW)` (`node.c:1241`). When the fractional depth `f = (Qin - Qmin)/(Qmax - Qmin) > 1`, the divider transitions from a weir equation to an orifice equation: `Qdiv = Qmax * sqrt(f)` (`node.c:1298`). Stored internally without unit conversion — the raw value from the input is assigned to `Divider[k].dhMax` (`node.c:188`). Note: the GUI label is "Max. Depth" (`objprops.txt:800`); the manual labels it as weir height (`appendix_B/B.5_Flow_Divider_Properties.md:53`).
- **Source of truth:** `node.c:1188` — `getDouble(tok[5], &x[5])`; `node.c:188` — stored as `Divider[k].dhMax`; `node.c:1236` — validation

---

### Cd *(WEIR type only — token index 6)*

- **Data type:** REAL
- **Required:** yes when Type = `WEIR`
- **Units:** unitless (product of discharge coefficient and weir length; typical range 2.65–3.10 per foot for CFS)
- **Valid values / range:** `> 0`; validation requires `Divider[k].cWeir > 0.0` (`node.c:1236`)
- **Default:** `0` (GUI default `objprops.txt:395`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Combined weir discharge coefficient (coefficient × weir crest length), labelled `cWeir` internally. The manual describes it as the "Product of WEIR's discharge coefficient and its length" with typical values 2.65–3.10 per foot for CFS (`appendix_B/B.5:55`). Used in `Qmax = Cw * Hw^1.5 / UCF(FLOW)` (`node.c:1241`) and in the weir equation `Qdiv = Cw * (f*Hw)^1.5 / UCF(FLOW)` (`node.c:1301–1302`). Stored without conversion: `Divider[k].cWeir = x[6]` (`node.c:189`).
- **Source of truth:** `node.c:1189` — `getDouble(tok[6], &x[6])`; `node.c:189` — stored as `Divider[k].cWeir`; `node.c:1241` — Qmax calculation

---

### Ymax *(optional — token index n, where n = 4 for OVERFLOW, 5 for CUTOFF/TABULAR, 7 for WEIR)*

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** feet (US) / metres (SI)
- **Valid values / range:** `≥ 0`; GUI mask is `emPosNumber` (`objprops.txt:785`)
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Maximum depth from the node's invert to the ground surface (i.e., rim elevation minus invert elevation). If set to 0, the engine automatically assigns `fullDepth` as the distance from the invert to the crown of the highest connecting conduit (`manual:D.2:1214`; `node.c:200–210`). Used in depth and surcharge calculations. Stored as `Node[j].fullDepth = x[7] / UCF(LENGTH)` (`node.c:190`). The optional trailing parameters are read in a loop starting at token index `n` and filling `x[7]` through `x[10]` (`node.c:1198–1206`).
- **Source of truth:** `node.c:1196–1206` — optional trailing loop; `node.c:190` — `Node[j].fullDepth`

---

### Y0 *(optional — one position after Ymax)*

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** feet (US) / metres (SI)
- **Valid values / range:** `≥ 0`; must not exceed `Ymax + Ysur` (validated at `node.c:216`)
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Initial water depth at the start of the simulation. Stored as `Node[j].initDepth = x[8] / UCF(LENGTH)` (`node.c:191`). If this exceeds `fullDepth + surDepth`, error `ERR_NODE_DEPTH` is raised (`node.c:216–217`).
- **Source of truth:** `node.c:1196–1206`; `node.c:191` — `Node[j].initDepth`

---

### Ysur *(optional — one position after Y0)*

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** feet (US) / metres (SI)
- **Valid values / range:** `≥ 0`; GUI mask `emPosNumber` (`objprops.txt:787`)
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Maximum additional pressure head above the ground surface that the node can sustain under surcharge conditions before water is lost to flooding. Stored as `Node[j].surDepth = x[9] / UCF(LENGTH)` (`node.c:192`). Only relevant under Dynamic Wave routing (where the node behaves as a junction); under Steady or Kinematic Wave routing the divider logic does not consider surcharge separately.
- **Source of truth:** `node.c:1196–1206`; `node.c:192` — `Node[j].surDepth`

---

### Apond *(optional — one position after Ysur)*

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** square feet (US) / square metres (SI)
- **Valid values / range:** `≥ 0`; GUI mask `emPosNumber` (`objprops.txt:788`)
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Surface area available for ponding above the node once water depth exceeds `Ymax + Ysur`. Surface ponding only occurs when this value is non-zero AND the `ALLOW_PONDING` option is set to `YES` in `[OPTIONS]` (`manual:D.2:1216–1218`). Stored as `Node[j].pondedArea = x[10] / (UCF(LENGTH)*UCF(LENGTH))` (`node.c:193`).
- **Source of truth:** `node.c:1196–1206`; `node.c:193` — `Node[j].pondedArea`

---

## Notes

- **Variable column count:** The number of mandatory tokens varies by type: OVERFLOW requires 4 tokens minimum; CUTOFF and TABULAR require 5; WEIR requires 7. The engine enforces these minimum counts with `ntoks < N` checks at `node.c:1136, 1167, 1177, 1186`. The four optional trailing fields (Ymax, Y0, Ysur, Apond) are always at the same relative position after the type-specific block (`node.c:1198–1206`), with the loop starting at token index `n` (which is set to 4, 5, or 7 depending on type) and populating `x[7]` through `x[10]`.

- **Enum order mismatch between engine and GUI:** In the engine (`enums.h:412–416` and `keywords.c:50`) the order is CUTOFF=0, TABULAR=1, WEIR=2, OVERFLOW=3. The GUI (`objprops.txt:199–202`) defines the same order. However, the manual example (`D.2:64`) uses the same column order. A DB designer should store the keyword string, not the enum integer, to remain independent of implementation ordering.

- **Routing-mode limitation:** Divider nodes are only active under Steady Flow (`SF`) or Kinematic Wave (`KW`) routing. Under Dynamic Wave (`DW`) routing they behave as ordinary junction nodes with no diversion logic applied (`manual:D.2:1220`; `chapter_03/3.2_Visual_Objects.md:108`). This is a critical cross-section constraint: a project using Dynamic Wave routing will silently ignore the divider parameters.

- **Two-conduit constraint:** A divider must have exactly two outflow conduits. The engine validates this at `flowrout.c:218–220`: if `Node[j].degree > 2` for a DIVIDER node, an error is raised. The `degree` field counts the number of outflow links.

- **DivLink `*` wildcard:** The GUI default for DivLink is `*` (`objprops.txt:386`). The engine accepts `*` or an empty string by setting `x[1] = -1.0` (`node.c:1147`), which triggers `ERR_DIVIDER_LINK = 136` at `divider_validate` unless a valid link name is supplied.

- **WEIR Cd semantics:** `Cd` is not a pure dimensionless discharge coefficient but the product of the discharge coefficient and the weir crest length. The manual (`appendix_B/B.5:55`) states typical values 2.65–3.10 per foot for CFS flow units; values in SI units will differ. This combined parameter means the weir "length" is baked into Cd and is not separately configurable.

- **WEIR flow transition:** When `f = (Qin - Qmin) / (Qmax - Qmin) > 1` (weir fully submerged), the engine switches from a weir equation to an orifice-like equation `Qdiv = Qmax * sqrt(f)` (`node.c:1298`). This behaviour is not documented in the manual but is in the engine source.

- **Uniqueness:** Each divider node name must be unique across all node types. The engine uses a single `NODE` hash table (`input.c:315–325`).

- **INP section keyword:** The section header is `[DIVIDERS]` (bracketed). The engine recognises it via `s_DIVIDER` in `InputSectionType` (`enums.h:461`).

- **No continuation lines:** Each divider is fully described on a single line. There are no sub-data rows or continuation tokens for this section.

- **GUI comment lines:** The GUI emits `;;`-prefixed comment lines and a header/separator row before the data rows (`Uexport.pas:911–916`). These are ignored by the engine parser.
