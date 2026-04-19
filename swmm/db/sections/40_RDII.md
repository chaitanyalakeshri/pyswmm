# [RDII]

**Purpose:** Assigns Rainfall-Dependent Infiltration and Inflow (RDII) to drainage system nodes. RDII represents stormwater flows entering sanitary or combined sewers through direct inflow connections (downspouts, sump pumps, foundation drains) and infiltration through cracked pipes, leaky joints, and poor manhole connections. Each row ties a node to a Unit Hydrograph group (defined in `[HYDROGRAPHS]`) and specifies the sewershed area that drains to that node; SWMM then convolves the UH responses with the rainfall record from the gage assigned to that UH group to produce a time series of RDII inflows at the node. The section is omitted when no node receives RDII. As an alternative, RDII may be supplied via an external interface file declared in `[FILES]` rather than computed from hydrographs.

**Occurrence:** one row per object — exactly one row per node that receives RDII inflow; a node may appear only once. Cardinality: 0 or 1 RDII row per node; typically many fewer rows than total nodes.

**SWMM source references:**
- Engine parser: `rdii.c:152` — function `rdii_readRdiiInflow`; dispatched from `input.c:586–587`
- Engine writer: engine does not write INP. `inputrpt.c:173` flags nodes with `rdiiInflow` set in the input summary report (marks them as having "Yes" for inflows).
- GUI reader: `Uimport.pas:1876` — function `ReadIIInflowData`; section index 31 dispatched at `Uimport.pas:2915`
- GUI writer: `Uexport.pas:1780` — procedure `ExportIIflows`
- GUI editor dialog(s): `appendix_C_specialized_property_editors/C.9_Inflows_Editor.md` — "RDII Inflow Page" of the Inflows Editor dialog (accessed via the node's `Inflows` property)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md:2275–2287` — Section `[RDII]`
- Additional manual refs: `chapter_03_swmms_conceptual_model/3.3_Non-Visual_Objects.md:97–131` (unit hydrograph conceptual description); `appendix_C_specialized_property_editors/C.9_Inflows_Editor.md:63–68` (GUI field labels and semantics); `appendix_B_visual_object_properties/B.3_Junction_Properties.md:14` (junction `Inflows` property)

## Row Format

```
Node  UHgroup  SewerArea
```

Each data line contains exactly three whitespace-delimited tokens. The GUI emits fixed-width columns (`%-16s`, tab, `%-16s`, tab, `%-10s`) but the engine parses by token position regardless of spacing (`rdii.c:152–193`). There are no continuation rows; no sub-lines.

## Fields

### Node

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match an existing node name (junction, outfall, flow divider, or storage unit). The engine calls `project_findObject(NODE, tok[0])` and returns `ERR_NAME` if the name is not found (`rdii.c:168–169`). The GUI iterates all four node type lists (`JUNCTION` to `STORAGE`) when both reading (`Uimport.pas:1887`) and writing (`Uexport.pas:1794`), confirming any node type is valid.
- **Default:** none
- **Cross-section dependency:** `[JUNCTIONS].Name` OR `[OUTFALLS].Name` OR `[DIVIDERS].Name` OR `[STORAGE].Name`
- **Database-key hint:** primary identifier of this row; composite PK with no second field (each node appears at most once)
- **Technical description:** The name of the drainage network node that will receive computed RDII inflows at each routing time step. A given node may appear in `[RDII]` at most once; assigning a second row to the same node overwrites the first because `Node[j].rdiiInflow` is replaced without freeing the old allocation if one exists (`rdii.c:180–192`). In the GUI, the inflow object is stored in `aNode.IIInflow` (a string list) and the `NODE_INFLOWS_INDEX` flag is set to `'YES'` (`Uimport.pas:1893`).
- **Source of truth:** `rdii.c:168–169`

### UHgroup

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match the name of a Unit Hydrograph group defined in the `[HYDROGRAPHS]` section. The engine calls `project_findObject(UNITHYD, tok[1])` and returns `ERR_NAME` if the name is not found (`rdii.c:172–173`). The GUI populates a dropdown list from `Project.Lists[UNITHYD]` in the Inflows Editor RDII page (`C.9_Inflows_Editor.md:63`).
- **Default:** none
- **Cross-section dependency:** `[HYDROGRAPHS].Name`
- **Database-key hint:** foreign key to `[HYDROGRAPHS].Name`
- **Technical description:** References the `TUnitHyd` object (stored in `UnitHyd[]`) that provides the set of triangular unit hydrographs (short-, medium-, and long-term) and the rain gage used to drive RDII computation at this node. Multiple nodes may reference the same UH group; each node's individual contribution is scaled by its own `SewerArea`. At simulation open, the engine marks `UnitHyd[k].isUsed = TRUE` (via `Gage[g].isUsed = TRUE` in `rdii_readUnitHydParams`) to activate RDII processing. The `IGNORE_RDII` option in `[OPTIONS]` globally disables all RDII computation regardless of entries in this section (`rdii.c:423`; `globals.h:86`).
- **Source of truth:** `rdii.c:172–173`

### SewerArea

- **Data type:** REAL
- **Required:** yes
- **Units:** US: acres / SI: hectares
- **Valid values / range:** `≥ 0`. The engine reads the value with `getDouble(tok[2], &a)` and rejects negative values with `ERR_NUMBER` (`rdii.c:176–177`). Runtime validation in `validateRdii()` also flags `area < 0.0` with `ERR_RDII_AREA` (`rdii.c:867–869`). A value of `0.0` is accepted (produces zero RDII inflow).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The area (in acres for US customary units, hectares for SI) of the sewershed whose pipes drain to this node and whose rainfall-induced I/I will be represented by the referenced UH group. The engine converts the value to ft² internally by dividing by `UCF(LANDAREA)`, where `UCF(LANDAREA)` is `2.2956e-5` (ac → ft²) or `0.92903e-5` (ha → ft²) (`rdii.c:189`; `swmm5.c:111`). The resulting `TRdiiInflow.area` (ft²) is multiplied by each UH's rainfall-depth response at each time step to obtain the volumetric RDII contribution from this node (`rdii.c:64–65`). Per the manual, this sewershed area is typically only a small, localized portion of the total subcatchment area that contributes surface runoff to the node (`C.9_Inflows_Editor.md:68`).
- **Source of truth:** `rdii.c:176–177`, `rdii.c:189`

## Notes

- Section keyword `[RDII` is matched by prefix (the engine uses `findmatch` against `ws_RDII` = `"[RDII"`); a full `[RDII]` tag also works because only the bracketed prefix needs to match (`text.h:436`; `keywords.c:134`).
- Each node may appear at most once. If a node name is listed twice, the second row silently overwrites the first (no error is raised) because `rdii_readRdiiInflow` calls `malloc` only when `Node[j].rdiiInflow == NULL`, reusing the existing struct otherwise (`rdii.c:180–192`).
- The section is independent of `[INFLOWS]` and `[DWF]`; a node may simultaneously have direct external inflows, dry-weather inflows, and RDII inflows.
- The `IGNORE_RDII YES` option in `[OPTIONS]` causes the engine to skip all RDII inflow computation at `rdii_openRdii` time (`rdii.c:423`) regardless of entries here. The data is still parsed and stored.
- RDII may alternatively be supplied via a pre-computed binary or text file declared as `USE RDII <Fname>` in `[FILES]` (`D.2_Input_File_Format.md:379`). When an RDII interface file is used, `[RDII]` and `[HYDROGRAPHS]` entries may still be present (for documentation) but the file data takes precedence; rainfall and RDII files cannot be simultaneously used and saved in the same run (`D.2_Input_File_Format.md:391`).
- The GUI `ExportIIflows` procedure iterates node types from `JUNCTION` to `STORAGE` in enum order and emits a row for any node whose `IIInflow` string list has at least two entries (`Uexport.pas:1794–1806`), matching the engine's acceptance of all node types.
- The engine stores `TRdiiInflow` as a heap-allocated struct pointed to by `Node[j].rdiiInflow` (`objects.h:456–462`, `objects.h:504`). Memory is freed by `rdii_deleteRdiiInflow` during project teardown.
- There is no ordering requirement among rows. Uniqueness of `Node` per row is a logical constraint enforced by overwrite behaviour, not by an error.
- Cross-section constraint: the referenced `UHgroup` must exist in `[HYDROGRAPHS]`, which must in turn declare a valid rain gage from `[RAINGAGES]`. Missing references produce `ERR_NAME` at parse time (`rdii.c:172–173`).
