# [ORIFICES]

**Purpose:** Defines each orifice link in the drainage network. An orifice is a flow-control structure that limits outflow from a node (typically a storage unit or manhole) through an opening of known geometry and discharge coefficient. Orifices model outlet structures, diversion structures, and controllable gates. Flow through a fully submerged orifice is computed as Q = C·A·√(2g·h); when head is below a critical threshold the engine switches to an equivalent weir formula for partially-filled conditions. The opening area can be modulated dynamically via Control Rules (gate fraction). Cross-section geometry (shape and dimensions) is specified separately in the `[XSECTIONS]` section.

**Occurrence:** One row per orifice link. Each orifice name must be unique within the `[LINKS]` namespace (shared with conduits, pumps, weirs, and outlets). Cross-section geometry for each orifice appears as a companion row in `[XSECTIONS]`.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/input.c:342` — dispatch `case s_ORIFICE` → `readLink(ORIFICE)`; `swmm524_engine/src/link.c:1641` — function `orifice_readParams`
- Engine writer: Engine does not write INP files; no orifice echo function exists in `inputrpt.c`.
- GUI reader: `Uimport.pas:1153` — procedure `ReadOrificeData` (section key `[ORIFICE` at line 77)
- GUI writer: `Uexport.pas:1086` — procedure `ExportOrifices`
- GUI editor dialog(s): `objprops.txt:857` — `OrificeProps` array (property editor definition)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` line 1380 — `[ORIFICES]` section
- Additional manual refs: `appendix_B_visual_object_properties/B.9_Orifice_Properties.md`; `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md` lines 430–456

## Row Format

```
Name  Node1  Node2  Type  Offset  Cd  (Gated  Orate)
```

Columns 7 (`Gated`) and 8 (`Orate`) are optional and default to `NO` and `0` respectively. The cross-section shape and dimensions are **not** on this row; they appear as a companion row in the `[XSECTIONS]` section under the same `Name`.

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-whitespace string; must be unique across all link types.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** Primary identifier of this row; foreign key anchor for `[XSECTIONS]` rows that reference this link name.
- **Technical description:** User-assigned label for the orifice. Internally registered as a LINK object (`project_addObject(LINK, id, ...)`) so names must not clash with conduit, pump, weir, or outlet names.
- **Source of truth:** `swmm524_engine/src/link.c:1658` — `project_findID(LINK, tok[0])`; `swmm524_engine/src/input.c:342–346` — duplicate-name check.

---

### Node1 (Inlet Node)

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must be an existing node name (junction, outfall, storage unit, or divider).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** Foreign key to `[JUNCTIONS].Name` / `[OUTFALLS].Name` / `[STORAGE].Name` / `[DIVIDERS].Name`.
- **Technical description:** The upstream (inlet) node of the orifice link. The orifice opening offset is measured relative to the invert elevation of this node. Orifice flow is computed from the head difference between Node1 and Node2.
- **Source of truth:** `swmm524_engine/src/link.c:1660` — `project_findObject(NODE, tok[1])`; `Uimport.pas:1167` — `FindNode(TokList[1])`.

---

### Node2 (Outlet Node)

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must be an existing node name; must differ from Node1.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** Foreign key to `[JUNCTIONS].Name` / `[OUTFALLS].Name` / `[STORAGE].Name` / `[DIVIDERS].Name`.
- **Technical description:** The downstream (outlet) node of the orifice link. Flow direction is from Node1 to Node2 under positive head; when `Gated = NO` reverse flow is permitted.
- **Source of truth:** `swmm524_engine/src/link.c:1662` — `project_findObject(NODE, tok[2])`; `Uimport.pas:1168` — `FindNode(TokList[2])`.

---

### Type

- **Data type:** ENUM
- **Required:** yes
- **Units:** unitless
- **Valid values / range:**
  - `SIDE` — orifice oriented in a vertical plane (opening in the side wall of the upstream node)
  - `BOTTOM` — orifice oriented in a horizontal plane (opening at the bottom of the upstream node)
- **Default:** `SIDE` (`objprops.txt:494` — `DefOrifice[5]`)
- **Cross-section dependency:** None
- **Database-key hint:** Plain data – no key role.
- **Technical description:** Controls the geometric orientation of the orifice. For `SIDE` orifices the head is measured to the centerline of the opening; for `BOTTOM` orifices the engine computes an `hCrit` crossover depth below which weir-flow equations replace the standard orifice equation. This also affects how surface area is accumulated for dynamic wave mass balance (`link.c:1855–1921`).
- **Source of truth:** `swmm524_engine/src/link.c:1666` — `findmatch(tok[3], OrificeTypeWords)`; `swmm524_engine/src/keywords.c:98` — `OrificeTypeWords[] = { w_SIDE, w_BOTTOM, NULL }`; `swmm524_engine/src/enums.h:426–428` — `SIDE_ORIFICE`, `BOTTOM_ORIFICE`; `objprops.txt:863–864` — dropdown `'SIDE'#13'BOTTOM'`.

---

### Offset

- **Data type:** REAL
- **Required:** yes
- **Units:** feet (US) / meters (SI); interpretation depends on `[OPTIONS].LINK_OFFSETS`
- **Valid values / range:** `≥ 0` (negative values are silently clamped to 0 during validation); when `LINK_OFFSETS = ELEVATION` the token `*` is accepted as a sentinel meaning "compute from invert" (stored as `MISSING`).
- **Default:** `0` (`objprops.txt:498` — `DefOrifice[9]`)
- **Cross-section dependency:** None
- **Database-key hint:** Plain data – no key role.
- **Technical description:** The elevation of the bottom of a SIDE orifice, or the elevation of the center of a BOTTOM orifice, measured above the invert of the inlet node (when `LINK_OFFSETS = DEPTH`) or as an absolute elevation (when `LINK_OFFSETS = ELEVATION`). During `link_setParams` the value is converted to internal length units: `Link[j].offset1 = x[1] / UCF(LENGTH)`. Also used for profile-plot rendering in the GUI (`Fproplot.pas:1107` — `GetOffset(aLink, ORIFICE_BOTTOM_HT_INDEX, aLink.Node1)`). Negative offsets are zeroed at validation time (`link.c:1716`).
- **Source of truth:** `swmm524_engine/src/link.c:1669–1671` — parsing with `ELEV_OFFSET` sentinel; `link.c:1716` — clamping; `swmm524_engine/src/link.c:365` — `Link[j].offset1 = x[1] / UCF(LENGTH)`.

---

### Cd (Discharge Coefficient)

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless
- **Valid values / range:** `≥ 0` (engine rejects negative values at parse time); typical value is 0.65.
- **Default:** `0.65` (`objprops.txt:499` — `DefOrifice[10]`)
- **Cross-section dependency:** None
- **Database-key hint:** Plain data – no key role.
- **Technical description:** The dimensionless discharge coefficient C in the orifice flow equation Q = C·A·√(2g·h). Stored in `Orifice[k].cDisch` and used to derive the effective flow coefficient `cOrif` (adjusted for gate setting) and the equivalent weir coefficient `cWeir` during `orifice_setSetting`. Typical values range from 0.5 to 0.7 depending on orifice geometry and edge conditions.
- **Source of truth:** `swmm524_engine/src/link.c:1672` — `if ( ! getDouble(tok[5], &x[2]) || x[2] < 0.0 )`; `link.c:367` — `Orifice[k].cDisch = x[2]`; `appendix_B_visual_object_properties/B.9_Orifice_Properties.md:24` — "A typical value is 0.65".

---

### Gated (Flap Gate)

- **Data type:** ENUM
- **Required:** no (default: `NO`)
- **Units:** unitless
- **Valid values / range:**
  - `NO` — no flap gate; reverse flow (from Node2 to Node1) is permitted.
  - `YES` — flap gate installed; reverse flow is blocked.
- **Default:** `NO` (`objprops.txt:500` — `DefOrifice[11]`; `appendix_D.../D.2_Input_File_Format.md:1400`)
- **Cross-section dependency:** None
- **Database-key hint:** Plain data – no key role.
- **Technical description:** When set to `YES`, the engine sets `Link[j].hasFlapGate = 1`, which prevents negative flow (back-flow from outlet to inlet). Parsed from `NoYesWords` keyword list.
- **Source of truth:** `swmm524_engine/src/link.c:1675–1679` — `findmatch(tok[6], NoYesWords)`; `link.c:368` — `Link[j].hasFlapGate = (x[3] > 0.0) ? 1 : 0`; `swmm524_engine/src/keywords.c:72` — `NoYesWords[] = { w_NO, w_YES, NULL }`.

---

### Orate (Time to Open/Close)

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** decimal hours
- **Valid values / range:** `≥ 0`; `0` means instantaneous open/close.
- **Default:** `0` (`objprops.txt:501` — `DefOrifice[12]`)
- **Cross-section dependency:** None
- **Database-key hint:** Plain data – no key role.
- **Technical description:** The time in decimal hours for a fully closed orifice to open completely (or a fully open orifice to close). Internally stored in seconds after multiplying by 3600: `Orifice[k].orate = x[4] * 3600.0` (`link.c:369`). Used in `orifice_setSetting` to linearly ramp the gate opening fraction (`Link[j].setting`) toward the `targetSetting` over successive routing time steps. When `Orate = 0` the setting changes instantaneously. This field enables simulation of motorized gates controlled by Control Rules.
- **Source of truth:** `swmm524_engine/src/link.c:1682–1685` — `if ( ! getDouble(tok[7], &x[4]) || x[4] < 0.0 )`; `link.c:369` — `Orifice[k].orate = x[4] * 3600.0`; `link.c:1742–1749` — use in `orifice_setSetting`.

---

## Cross-Section Geometry (companion rows in `[XSECTIONS]`)

The `[ORIFICES]` row does **not** carry shape or dimension data. The GUI writes orifice cross-section data into the `[XSECTIONS]` section under the same link name. The engine validates the cross-section in `orifice_validate` (`link.c:1707–1708`): only `CIRCULAR` and `RECT_CLOSED` are accepted; any other shape triggers `ERR_REGULATOR_SHAPE`.

Fields read from `[XSECTIONS]` for an orifice link:

| Field | GUI index | Description |
|---|---|---|
| Shape | `ORIFICE_SHAPE_INDEX = 6` | `CIRCULAR` or `RECT_CLOSED` |
| Height (Geom1) | `ORIFICE_HEIGHT_INDEX = 7` | Diameter (circular) or height (rectangular), ft or m |
| Width (Geom2) | `ORIFICE_WIDTH_INDEX = 8` | Width of rectangular orifice; 0 for circular (GUI emits `0` for circular, `Uexport.pas:1268–1271`) |

Sources: `Uproject.pas:242–251`; `Uimport.pas:1396–1404`; `Uexport.pas:1261–1273`; `objprops.txt:865–866` — dropdown `'CIRCULAR'#13'RECT_CLOSED'`; `swmm524_engine/src/link.c:1707–1708` — validation.

## Notes

- **[XSECTIONS] dependency:** Every `[ORIFICES]` row **must** have a matching row in `[XSECTIONS]` giving the shape (`CIRCULAR` or `RECT_CLOSED`) and dimensions. The engine will report `ERR_REGULATOR_SHAPE` if the cross-section is absent or of an unsupported type (`link.c:1707–1708`). In the GUI these two sources are stored as a single in-memory object and exported together.
- **Routing restriction:** Orifices not connected to a storage unit node can only be used with Dynamic Wave flow routing. When connected to a storage unit they work under all routing methods (`chapter_03/3.2_Visual_Objects.md:434`).
- **LINK_OFFSETS interaction:** The `Offset` field interprets its value as a depth above the node invert when `[OPTIONS].LINK_OFFSETS = DEPTH`, or as an absolute invert elevation when `LINK_OFFSETS = ELEVATION`. When elevation mode is active, the sentinel value `*` in the INP file signals that offset should be computed from the node invert (stored internally as `MISSING`); `link.c:1669`.
- **Gate control via Control Rules:** The gate opening fraction (`Link[j].setting`, range 0–1) is set by Control Rules referencing the orifice's name. When `Orate > 0` the engine ramps the setting gradually over routing time steps rather than applying it instantaneously (`link.c:1729–1760`).
- **Negative offset clamped:** If the parsed `Offset` value converts to a negative internal length, `orifice_validate` silently sets it to 0 (`link.c:1716`).
- **Unique name space:** Orifice names occupy the shared LINK name space. The engine checks for duplicates with `project_addObject` at `input.c:342–346`; duplicate names produce `ERR_DUP_NAME`.
- **Section header prefix matching:** The GUI reads this section on the prefix `[ORIFICE` (without the trailing S), matching both `[ORIFICES]` and any abbreviation (`Uimport.pas:77`).
- **Composite key for DB design:** A single orifice appears as one row in `[ORIFICES]` and one companion row in `[XSECTIONS]`. The database designer must join these two sections on `Name`.
