# [CONDUITS]

**Purpose:** Defines each conduit link in the drainage network. Conduits are pipes or channels that convey water from one node to another. Every conduit requires a named upstream node and a named downstream node, a physical length, and a Manning's roughness coefficient. Two optional upstream/downstream invert offsets control where the conduit barrel sits relative to its end-node inverts. Two further optional columns cap the initial flow and the maximum allowed flow. Cross-section geometry is supplied separately in `[XSECTIONS]`; local (minor) loss coefficients, flap-gate flags, and seepage rates are supplied separately in `[LOSSES]`.

**Occurrence:** One row per conduit link. Each conduit appears exactly once. Cardinality: one-to-one with the conduit objects registered in `[XSECTIONS]`.

**SWMM source references:**
- Engine parser: `input.c:532–533` — dispatch to `readLink(CONDUIT)`, which calls `link.c:738–751` — function `readLink`, which calls `link.c:933–988` — function `conduit_readParams`
- Engine writer: Engine does not write INP. The report-echo function `inputrpt.c:195–219` prints conduit length, slope, and roughness to the `.rpt` file.
- GUI reader: `Uimport.pas:1065–1102` — procedure `ReadConduitData`
- GUI writer: `Uexport.pas:1011–1044` — procedure `ExportConduits`
- GUI editor dialog(s): `Dxsect.dfm` (Cross-Section Editor, launched from conduit property sheet)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [CONDUITS] (lines 1325–1354)
- Additional manual refs: `appendix_B_visual_object_properties/B.7_Conduit_Properties.md`; `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md` §3.2.7; `chapter_05_working_with_projects/5.6_Link_Offset_Conventions.md`

## Row Format

```
Name  Node1  Node2  Length  N  Z1  Z2  (Q0  Qmax)
```

Columns 1–7 are required (minimum token count = 7; `conduit_readParams` returns `ERR_ITEMS` if `ntoks < 7`: `link.c:948`). Columns 8 (`Q0`) and 9 (`Qmax`) are optional and default to `0`.

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-whitespace string that uniquely identifies a link object in the project. Maximum token length limited by `MAXID` (31 characters implied by project hashing).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** primary identifier of this row
- **Technical description:** User-assigned name for the conduit. The engine resolves it via `project_findID(LINK, tok[0])` to obtain the pre-allocated internal link index (`link.c:949`). The name must have been counted during the first pass (`input.c:328–333`), so every name in this section must be unique among all links.
- **Source of truth:** `link.c:949–950`

---

### Node1

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Name of an existing node (junction, outfall, storage, or divider).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** foreign key to [JUNCTIONS|OUTFALLS|STORAGE|DIVIDERS].Name
- **Technical description:** Name of the conduit's upstream (inlet) node — normally the end at higher elevation. The engine resolves it with `project_findObject(NODE, tok[1])`; an unknown name returns `ERR_NAME` (`link.c:951–952`). Under Dynamic Wave routing, if the conduit has a negative slope the engine automatically reverses node1 and node2 at validation time (`link.c:1082–1087` via `conduit_reverse`), so the physical "upstream" end may differ from the INP-specified end after preprocessing.
- **Source of truth:** `link.c:951–952`

---

### Node2

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Name of an existing node (junction, outfall, storage, or divider). Must differ from Node1.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** foreign key to [JUNCTIONS|OUTFALLS|STORAGE|DIVIDERS].Name
- **Technical description:** Name of the conduit's downstream (outlet) node — normally the end at lower elevation. Resolved with `project_findObject(NODE, tok[2])` (`link.c:953–954`). See also Node1 notes on automatic reversal.
- **Source of truth:** `link.c:953–954`

---

### Length

- **Data type:** REAL
- **Required:** yes
- **Units:** US: ft / SI: m
- **Valid values / range:** `> 0` — the engine reports `ERR_LENGTH` if `Conduit[k].length <= 0.0` at validation (`link.c:1040–1041`).
- **Default:** none (GUI project default: `400` ft, stored at `CONDUIT_LENGTH_INDEX = 7` in `DefConduit`, `objprops.txt:444`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Physical length of the conduit along its axis (ft or m). Converted to internal units at parse time: `Conduit[k].length = x[0] / UCF(LENGTH)` (`link.c:344`). Under Dynamic Wave routing with conduit lengthening enabled (`LengtheningStep > 0`), the engine may compute a modified length `Conduit[k].modLength` for stability purposes without altering the stored value (`link.c:1115`). For IRREGULAR cross-sections a roughness-based length factor is also applied (`link.c:1098–1102`). The `inputrpt.c` report echoes the length in user units (`inputrpt.c:216`).
- **Source of truth:** `link.c:957–958`, `link.c:344`

---

### N

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (Manning's roughness)
- **Valid values / range:** `> 0` — the engine reports `ERR_ROUGHNESS` if `Conduit[k].roughness <= 0.0` at validation (`link.c:1042–1043`). Typical values: 0.010–0.035 for pipes, 0.015–0.150 for open channels (see `appendix_A/A.7` and `A.8`).
- **Default:** none (GUI project default: `0.01`, stored at `CONDUIT_ROUGHNESS_INDEX = 8` in `DefConduit`, `objprops.txt:445`)
- **Cross-section dependency:** If the cross-section type is `IRREGULAR`, the roughness is overridden at validation by `Transect[...].roughness` (`link.c:1021`). If the type is `STREET`, roughness is overridden by `Street[...].roughness` (`link.c:1028`). For `FORCE_MAIN` sections under Darcy-Weisbach, roughness is interpreted as the pipe roughness height (in or mm) and converted (`link.c:1033–1036`).
- **Database-key hint:** plain data – no key role
- **Technical description:** Manning's roughness coefficient *n* for the conduit. Stored directly as `Conduit[k].roughness = x[1]` (no unit conversion needed; dimensionless). Under DW routing a `roughFactor` is derived from this value for the friction-slope term computation (`link.c:1120–1137`).
- **Source of truth:** `link.c:959–960`, `link.c:346`

---

### Z1

- **Data type:** REAL
- **Required:** yes
- **Units:** US: ft / SI: m (depth above node invert, or absolute elevation depending on `LINK_OFFSETS` option)
- **Valid values / range:** `≥ 0` when expressed as depth (DEPTH_OFFSET mode); any real when expressed as elevation (ELEV_OFFSET mode). The engine warns and clamps negative depth offsets to 0 at validation (`link.c:1058–1062`, Warning WARN03).
- **Default:** `0` (depth mode default in `DefConduit`, `objprops.txt:446`); `*` (sentinel for ELEV_OFFSET mode, `Uupdate.pas:713`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Offset of the conduit invert above the invert of its upstream node (Node1). Behaviour depends on the global `LINK_OFFSETS` option (`enums.h:345–347`): in `DEPTH` mode (default) this is a distance above the node invert and is stored directly (`Link[j].offset1 = x[2] / UCF(LENGTH)`, `link.c:347`); in `ELEVATION` mode the token may be `*` (mapped to `MISSING`) meaning "use node invert elevation exactly", or an absolute elevation that is converted at validation by `link_convertOffsets` → `link_getOffsetHeight` (`link.c:468–504`) to a depth above the node invert. The resulting internal value is always a depth in ft. For FILLED_CIRCULAR cross-sections an additional offset equal to the bottom fill depth is added (`link.c:1071–1073`).
- **Source of truth:** `link.c:963–965`, `link.c:347`, `link.c:468–504`

---

### Z2

- **Data type:** REAL
- **Required:** yes
- **Units:** US: ft / SI: m (depth above node invert, or absolute elevation depending on `LINK_OFFSETS` option)
- **Valid values / range:** Same as Z1.
- **Default:** `0` (depth mode); `*` (elevation mode)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Offset of the conduit invert above the invert of its downstream node (Node2). Parsed identically to Z1 (`link.c:966–968`). Stored as `Link[j].offset2 = x[3] / UCF(LENGTH)` (`link.c:348`). Converted in ELEV_OFFSET mode by `link_convertOffsets` using Node2's invert elevation (`link.c:481–482`). A negative offset after conversion triggers Warning WARN03 and is clamped to 0 (`link.c:1063–1067`).
- **Source of truth:** `link.c:966–968`, `link.c:348`

---

### Q0

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** flow units (CFS, GPM, MGD, CMS, LPS, or MLD as set by `[OPTIONS] FLOW_UNITS`)
- **Valid values / range:** `≥ 0`; any real accepted by the parser, but negative values have undefined physical meaning.
- **Default:** `0` (`link.c:971`, `objprops.txt:448`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Initial flow rate in the conduit at the start of the simulation. Stored as `Link[j].q0 = x[4] / UCF(FLOW)` converting to internal units (cfs) (`link.c:349`). When Q0 is 0 the conduit begins dry. Parsed only when `ntoks >= 8` (`link.c:972–976`).
- **Source of truth:** `link.c:971–976`, `link.c:349`

---

### Qmax

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** flow units (same as Q0)
- **Valid values / range:** `≥ 0`; a value of `0` means no upper bound is enforced.
- **Default:** `0` (no limit) (`link.c:977`, `objprops.txt:449`, manual line 1347)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Maximum flow allowed in the conduit. Stored as `Link[j].qLimit = x[5] / UCF(FLOW)` (`link.c:350`). A value of `0` is the sentinel for "no limit" (`link.c:338`). When a positive Qmax is set, flow routing clips computed flow to this ceiling. Parsed only when `ntoks >= 9` (`link.c:977–982`).
- **Source of truth:** `link.c:977–982`, `link.c:350`, `link.c:338`

---

## Notes

- **Companion sections:** `[CONDUITS]` records only the network topology, geometry offsets, and flow bounds. Cross-section shape must be provided in `[XSECTIONS]` (one row per conduit — if absent, the engine reports `ERR_NO_XSECT` at validation, `link.c:1050–1051`). Local head losses, flap gates, and seepage rates are optional and belong in `[LOSSES]` (parsed by `link_readLossParams`, `link.c:271–311`; GUI reads via `ReadLossData`, `Uimport.pas:1519–1545`; GUI writes via `ExportLosses`, `Uexport.pas:1380–1418`).

- **Uniqueness:** Each conduit name must be unique across all link types (`CONDUIT`, `PUMP`, `ORIFICE`, `WEIR`, `OUTLET`). A duplicate name triggers `ERR_DUP_NAME` during the counting pass (`input.c:329–330`).

- **Offset convention switch:** The interpretation of Z1 and Z2 is controlled by the `LINK_OFFSETS` option in `[OPTIONS]`. Allowed values are `DEPTH` (default) and `ELEVATION` (`enums.h:345–347`). In ELEVATION mode the GUI writes `*` for an offset that coincides exactly with the node invert (`Uupdate.pas:713–714`); the engine maps `*` to `MISSING` (a large negative sentinel), which `link_getOffsetHeight` converts to depth 0 (`link.c:498`). See `chapter_05/5.6_Link_Offset_Conventions.md` for the user-facing description.

- **Automatic conduit reversal:** Under Dynamic Wave routing, if the computed slope of a conduit is negative (downstream invert higher than upstream invert), the engine reverses the node1/node2 assignment internally at validation (`link.c:1082–1087`). The GUI mirrors this by swapping the offset values (`Uproject.pas:1763–1768`). The INP file is not rewritten; the internal direction flag (`Link[j].direction`) records the reversal.

- **Conduit with IRREGULAR or STREET cross-section:** When the xsection type is `IRREGULAR`, the roughness N from `[CONDUITS]` is overridden by the transect's composite roughness at validation (`link.c:1021`). When the type is `STREET`, roughness is taken from the `[STREETS]` object (`link.c:1028`). In both cases the N column must still be present and parseable; it seeds the transect roughness default when creating a new transect via the GUI (`Uedit.pas:1152`).

- **Barrels:** The number of barrels (parallel identical conduit barrels) is not a column in `[CONDUITS]`; it is the 7th token (after the 4 geometry parameters) of the corresponding `[XSECTIONS]` row. It defaults to 1 (`link.c:190`).

- **Culvert code:** Also not in `[CONDUITS]` — it is the 8th token of the `[XSECTIONS]` row (`link.c:258–263`). The culvert code triggers inlet-control flow reduction for culverts.

- **Seepage and head loss data exclusion from this section:** The `[LOSSES]` section stores Kentry, Kexit, Kavg, FlapGate, and SeepageRate for conduits. These are stored in `Link[j].cLossInlet`, `Link[j].cLossOutlet`, `Link[j].cLossAvg`, `Link[j].hasFlapGate`, and `Link[j].seepRate` (`link.c:305–309`). Minor losses are only applied in Dynamic Wave routing (`D.2_Input_File_Format.md` line 1902).

- **Minimum token requirement:** The engine enforces `ntoks >= 7`; the GUI enforces the same (`Uimport.pas:1075`). Fewer tokens cause `ERR_ITEMS`.

- **GUI default values** (from `objprops.txt:436–462`): Length = `400`, Roughness = `0.01`, Shape = `CIRCULAR`, MaxDepth (Geom1) = `1`, InOffset = `0`, OutOffset = `0`, InitFlow = `0`, MaxFlow = `0`.

- **Report echo:** `inputrpt.c:195–219` lists each link's upstream node, downstream node, type, length (in user units), slope (%), and roughness in the `.rpt` file under the "Link Summary" table.
