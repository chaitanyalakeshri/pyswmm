# [JUNCTIONS]

**Purpose:** Defines each junction node in the drainage network. Junctions are point nodes where conduits, pumps, orifices, weirs, and outlet links connect together. Physically they represent manhole structures in sewer systems, pipe connection fittings, or confluences of natural open channels. External inflows (direct, dry-weather, or RDII) can be assigned to junctions. Under surcharge conditions a junction can sustain additional pressure head above the ground elevation; when the `ALLOW_PONDING` simulation option is enabled and `Apond` is non-zero, floodwater is stored in a virtual surface pond and subsequently drains back into the conveyance system when capacity allows.

**Occurrence:** One row per junction node. Each junction must appear exactly once in this section.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/input.c:521` — function `readNode(JUNCTION)` → delegates to `swmm524_engine/src/node.c:606` — function `junc_readParams`
- Engine writer: The engine does not write INP files. The input-echo Node Summary table is written by `swmm524_engine/src/inputrpt.c:160–177` and prints `invertElev`, `fullDepth`, `pondedArea`, and external-inflow flag.
- GUI reader: `Uimport.pas:857` — function `ReadJunctionData`
- GUI writer: `Uexport.pas:816` — procedure `ExportJunctions`
- GUI editor dialog(s): `Ddefault.pas` (project-level defaults for invert, max depth, ponded area); node property editor accessed via property grid
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [JUNCTIONS]
- Additional manual refs: `appendix_B_visual_object_properties/B.3_Junction_Properties.md`; `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md` §3.2.3

## Row Format

```
Name  Elev  (Ymax  Y0  Ysur  Apond)
```

Mandatory fields: `Name`, `Elev`. Fields `Ymax`, `Y0`, `Ysur`, `Apond` are optional and default to `0` when omitted. The GUI always writes all six columns regardless of value (`Uexport.pas:838–844`).

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-blank string token. Must be unique across all node types (`[JUNCTIONS]`, `[OUTFALLS]`, `[DIVIDERS]`, `[STORAGE]`). The engine uses prefix matching for section keywords (`text.h:415`: `ws_JUNCTION = "[JUNC"`), so names beginning with `[JUNC` at column 1 would be misinterpreted; in practice node names appear after the section header line.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** Primary identifier of this row; foreign key target from `[CONDUITS]`, `[PUMPS]`, `[ORIFICES]`, `[WEIRS]`, `[OUTLETS]` (as from-node or to-node), `[INFLOWS]`, `[DWF]`, `[RDII]`, `[TREATMENT]`, `[COORDINATES]`.
- **Technical description:** User-assigned label for the junction. The engine stores it as a `char*` in `TNode.ID` (`objects.h:493`). On import the GUI looks up the name in the global node hash table via `project_findID(NODE, tok[0])` (`node.c:623`); a duplicate name returns `ERR_DUP_NAME` (error 207) during the first-pass count phase (`input.c:301–305`).
- **Source of truth:** `node.c:623–624` (name resolution); `input.c:300–305` (duplicate detection).

---

### Elev (InvertElev)

- **Data type:** REAL
- **Required:** yes
- **Units:** feet (US) / metres (SI)
- **Valid values / range:** Any real number (negative values are physically meaningful for below-sea-level networks).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** Plain data – no key role.
- **Technical description:** Elevation of the junction's invert (the lowest interior surface). Stored internally in feet as `Node[j].invertElev` after dividing by `UCF(LENGTH)` (`node.c:137`). This is the datum from which all water depths at the node are measured. It also establishes the reference elevation for computing conduit offsets and the hydraulic grade line.
- **Source of truth:** `node.c:137` (assignment); `node.c:630–634` (parsing via `getDouble`).

---

### Ymax (MaxDepth / fullDepth)

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** feet (US) / metres (SI)
- **Valid values / range:** `≥ 0`
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** Plain data – no key role.
- **Technical description:** The maximum depth of the junction from the invert to the ground (or cover) surface, i.e. the total height of the node volume. Stored as `Node[j].fullDepth` (`objects.h:499`). When this value is `0` at the time of validation, SWMM automatically sets `fullDepth` to the distance from the invert to the top of the highest connecting conduit crown (`link.c:452–453`), which may subsequently trigger `WARN02` if a connecting link raises the effective depth beyond a user-specified value (`node.c:210–213`). The engine enforces `x[1] >= 0` (`node.c:639–642`). The GUI index for this field is `JUNCTION_MAX_DEPTH_INDEX = 8` (`Uproject.pas:154`).
- **Source of truth:** `node.c:150` (assignment); `node.c:639–642` (non-negative check); `link.c:452–453` (auto-set when zero).

---

### Y0 (InitDepth / initDepth)

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** feet (US) / metres (SI)
- **Valid values / range:** `≥ 0`; must satisfy `Y0 ≤ Ymax + Ysur` at validation time, otherwise `ERR_NODE_DEPTH` (error 138) is raised.
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** Plain data – no key role.
- **Technical description:** Water depth at the start of the simulation. Stored as `Node[j].initDepth` (`objects.h:498`). This depth is used to set `oldDepth` and `newDepth` at simulation initialisation (`node.c:247`). If `Y0 > Ymax + Ysur` the engine issues an error and aborts (`node.c:216–217`). The GUI index is `JUNCTION_INIT_DEPTH_INDEX = 9` (`Uproject.pas:155`).
- **Source of truth:** `node.c:151` (assignment); `node.c:215–217` (validation); `node.c:247` (initialisation).

---

### Ysur (SurchargeDepth / surDepth)

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** feet (US) / metres (SI)
- **Valid values / range:** `≥ 0`
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** Plain data – no key role.
- **Technical description:** Additional pressure head above the ground elevation (`Elev + Ymax`) that the junction can sustain under surcharged conditions before water is considered to overflow. Stored as `Node[j].surDepth` (`objects.h:500`). A non-zero value allows the node to act as a pressurised manhole or bolted cover: the engine keeps water in the system up to `invertElev + fullDepth + surDepth` before treating any excess as overflow/flooding. This is also used to model connections to force-main sections where the maximum sustainable pressure head is known (`D.2_Input_File_Format.md` remark). The GUI index is `JUNCTION_SURCHARGE_DEPTH_INDEX = 10` (`Uproject.pas:156`). The engine enforces `x[3] >= 0` (`node.c:639–642`).
- **Source of truth:** `node.c:152` (assignment); `node.c:639–642` (non-negative check); `objects.h:500`.

---

### Apond (PondedArea / pondedArea)

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** square feet (US) / square metres (SI)
- **Valid values / range:** `≥ 0`
- **Default:** `0`
- **Cross-section dependency:** `[OPTIONS]` — `ALLOW_PONDING` must be set to `YES` for this parameter to have any effect at run time.
- **Database-key hint:** Plain data – no key role.
- **Technical description:** Surface area of the virtual pond that forms atop the junction once the water depth exceeds `Ymax + Ysur`. Stored as `Node[j].pondedArea` in ft² (`objects.h:501`). The engine divides the value by `UCF(LENGTH)²` when converting from user units to internal feet² (`node.c:153`). When the node is flooded and `AllowPonding` is `TRUE` in globals and `pondedArea > 0`, the engine uses this constant area to compute the volume of floodwater stored on the surface (`node.c:573–583`; `dynwave.c:661`; `flowrout.c:442–443`). A zero `Apond` means overflow is immediately lost from the system (no storage). The GUI index is `JUNCTION_PONDED_AREA_INDEX = 11` (`Uproject.pas:157`). The engine enforces `x[4] >= 0` (`node.c:639–642`).
- **Source of truth:** `node.c:153` (assignment); `node.c:573–583` (ponded-surface area computation); `dynwave.c:661`; `flowrout.c:442–443`; `stats.c:555`.

---

## Notes

- **Section keyword matching:** The engine uses prefix matching. The section header `[JUNCTIONS]` is matched by the prefix `[JUNC` (`text.h:415`; `keywords.c:124`). Any section keyword starting with `[JUNC` (case-insensitive due to `match()` in `input.c:787–793`) is treated as this section.
- **Minimum required tokens:** Only `Name` and `Elev` (two tokens) are mandatory. The engine returns `ERR_ITEMS` (203) if fewer than two tokens are present (`node.c:622`). Fields 3–6 (`Ymax`, `Y0`, `Ysur`, `Apond`) are silently set to `0.0` when absent (`node.c:628–635`).
- **Auto-depth from links:** When `Ymax = 0`, the engine does not keep it at zero; `link_setParams` later extends each connected non-storage node's `fullDepth` to accommodate the crown of every connecting conduit (`link.c:452–453`). Warning 02 (`WARN02`) is issued if a conduit raises the effective full depth beyond the user-supplied value (`node.c:210–213`).
- **Surcharge interaction with force mains:** Setting `Ysur > 0` effectively creates a pressurised headspace above ground. This is the recommended way to model bolted manhole covers or junction points in a force-main system (`D.2_Input_File_Format.md` remarks).
- **Ponding requires OPTIONS flag:** `Apond > 0` has no effect unless `ALLOW_PONDING YES` is present in `[OPTIONS]`. The global flag `AllowPonding` defaults to `FALSE` (`project.c:848`).
- **Units of Apond:** The GUI column header is `Aponded` (`Uexport.pas:827`). The engine report uses `UCF(LENGTH)²` for the conversion when echoing to the report file (`inputrpt.c:172`).
- **Uniqueness:** Each junction name must be globally unique across all node types (`JUNCTION`, `OUTFALL`, `STORAGE`, `DIVIDER`). The engine uses a single shared hash table for all nodes (`input.c:300–305`).
- **No duplicate rows:** A junction may appear only once in `[JUNCTIONS]`. A second row with the same name returns `ERR_DUP_NAME` (207) during the object-counting pass.
- **GUI always writes all columns:** `ExportJunctions` always emits all six columns for every row, using the default value `0` for any unset optional fields (`Uexport.pas:838–844`). This means round-tripping through the GUI will materialise implicit zeros explicitly.
- **Ordering:** The engine imposes no ordering requirement within the section. The GUI preserves insertion order.
- **No enum or keyword fields:** All fields are purely numeric (except `Name`). No keyword strings appear in this section.
