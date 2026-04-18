# [SUBCATCHMENTS]

**Purpose:** Identifies each subcatchment within the study area. A subcatchment is a hydrologic land unit whose topography and drainage system direct surface runoff to a single discharge point. Each subcatchment generates runoff from rainfall via overland flow across pervious and impervious subareas; it is the primary unit at which infiltration, snow melt, groundwater interaction, LID controls, and pollutant buildup/washoff are computed.

**Occurrence:** One row per object. Each row defines exactly one subcatchment by its eight required positional fields plus one optional trailing field. Associated parameters (Manning's n, depression storage, infiltration, groundwater, snow pack, LID usage, land uses, initial loadings, monthly patterns) are supplied in companion sections (`[SUBAREAS]`, `[INFILTRATION]`, `[GROUNDWATER]`, `[SNOWPACKS]`, `[LID_USAGE]`, `[COVERAGES]`, `[LOADINGS]`, `[ADJUSTMENTS]`).

**SWMM source references:**
- Engine parser: `swmm524_engine/src/input.c:493` — dispatch `case s_SUBCATCH:` → calls `subcatch_readParams()`; object registration at `input.c:268`
- Engine parser (function): `swmm524_engine/src/subcatch.c:119` — function `subcatch_readParams()`
- Engine validation: `swmm524_engine/src/subcatch.c:364` — function `subcatch_validate()`
- Engine writer: Engine does not write INP files. The report echo appears in `swmm524_engine/src/inputrpt.c:27` — function `inputrpt_writeInput()`, which echoes Name, Area, Width, %Imperv, %Slope, and Rain Gage to the `.rpt` file (line 128–149).
- GUI reader: `Uimport.pas:596` — function `ReadSubcatchmentData`; section dispatch at `Uimport.pas:2889`
- GUI writer: `Uexport.pas:518` — procedure `ExportSubcatchments`
- GUI editor dialog(s): `Ddefault.pas` (project defaults for subcatchment properties), property editor in main GUI via `Uedit.pas`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[SUBCATCHMENTS]` (line 584)
- Additional manual refs: `appendix_B_visual_object_properties/B.2_Subcatchment_Properties.md`; `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md` §3.2.2; `appendix_A_useful_tables/A.1_Units_of_Measurement.md`

## Row Format

```
Name  Rgage  OutID  Area  %Imperv  Width  Slope  Clength  (Spack)
```

Columns 1–8 are required; column 9 (`Spack`) is optional. The section header keyword is matched by prefix: the engine recognises any token beginning with `[SUBCATCHMENT` (`text.h:409`). The GUI recognises `[SUBCATCHMENT` (index 5 in `SectionWords`, `Uimport.pas:66`).

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-empty token without whitespace; must be unique among all subcatchment names. The engine enforces uniqueness: a duplicate triggers `ERR_DUP_NAME` (`input.c:270`). Names and node names share the same namespace — the GUI comment at `Uproject.pas:1494` notes "subcatchments and nodes cannot share same IDs".
- **Default:** none
- **Cross-section dependency:** None (this is the primary key; other sections reference it)
- **Database-key hint:** primary identifier of this row
- **Technical description:** User-assigned label for the subcatchment. At parse time the engine calls `project_findID(SUBCATCH, tok[0])` (`subcatch.c:139`) to look up the already-registered name; duplicates cause an error at registration time (`input.c:268–272`). The GUI stores it in the `TSubcatch.ID` field (`Uproject.pas:486`).
- **Source of truth:** `subcatch.c:139`, `input.c:268–272`

---

### Rgage

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match a name declared in `[RAINGAGES]`. The engine calls `project_findObject(GAGE, tok[1])`; an unknown name triggers `ERR_NAME` (`subcatch.c:143–145`).
- **Default:** `'*'` (GUI factory default, `objprops.txt:253` — signals "no gage assigned" until set by user)
- **Cross-section dependency:** `[RAINGAGES].Name`
- **Database-key hint:** foreign key to `[RAINGAGES].Name`
- **Technical description:** Name of the rain gage that provides precipitation data for this subcatchment. Stored internally as an integer index (`Subcatch[j].gage`, `subcatch.c:173`). During validation (`subcatch_validate`, `subcatch.c:411–413`) the gage's `isUsed` flag is set to `TRUE`. Multiple subcatchments may share the same rain gage.
- **Source of truth:** `subcatch.c:143–145, 173, 411–413`

---

### OutID

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match either a node name from `[JUNCTIONS]`/`[OUTFALLS]`/`[STORAGE]`/`[DIVIDERS]`, or a subcatchment name from `[SUBCATCHMENTS]`. The engine searches both namespaces (`subcatch.c:148–153`); if neither resolves, `ERR_NAME` is returned. During validation an error is raised if both `outNode` and `outSubcatch` resolve simultaneously (`subcatch.c:376–377`).
- **Default:** `'*'` (GUI factory default, `objprops.txt:254` — signals "no outlet assigned" until set)
- **Cross-section dependency:** `[JUNCTIONS].Name` OR `[OUTFALLS].Name` OR `[STORAGE].Name` OR `[DIVIDERS].Name` OR `[SUBCATCHMENTS].Name`
- **Database-key hint:** foreign key to either a node table or `[SUBCATCHMENTS].Name`
- **Technical description:** Receiving location for this subcatchment's runoff. A subcatchment outlet allows cascading runoff from one subcatchment to another (inter-subcatchment routing). Stored as two separate integer indices: `Subcatch[j].outNode` (≥0 when a node) and `Subcatch[j].outSubcatch` (≥0 when a subcatchment); exactly one must be non-negative after parsing (`subcatch.c:148–153`). The DB designer must store the outlet type (node vs. subcatchment) as well as the referenced name.
- **Source of truth:** `subcatch.c:148–153, 174–175, 376–377`

---

### Area

- **Data type:** REAL
- **Required:** yes
- **Units:** US: acres / SI: hectares
- **Valid values / range:** ≥ 0 (the engine accepts zero; `subcatch.c:158`: `x[i] < 0.0` triggers error)
- **Default:** `5` (GUI factory default, acres, `objprops.txt:255`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Total land area of the subcatchment including any area occupied by LID controls. Converted to ft² internally by dividing by `UCF(LANDAREA)` (`subcatch.c:176`). Used in computing runoff volumes and the overland-flow alpha coefficient in `subcatch_validate` (`subcatch.c:392–408`). The GUI displays units as `(ac)` / `(ha)` (`objprops.txt:285`).
- **Source of truth:** `subcatch.c:155–160, 176`

---

### %Imperv

- **Data type:** REAL
- **Required:** yes
- **Units:** percent (unitless ratio after conversion)
- **Valid values / range:** 0–100. The engine clamps the value at 100 via `MIN(x[4], 100.0)` (`subcatch.c:177`); values below 0 trigger `ERR_NUMBER` (`subcatch.c:158`).
- **Default:** `25` (GUI factory default, `objprops.txt:258`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Percentage of the subcatchment's land area (excluding LID-covered area) that is impervious. Stored internally as a fraction `fracImperv` (`subcatch.c:177`). Drives the split of subcatchment area into pervious and impervious subareas used by `[SUBAREAS]` parameters. The GUI label is `% Imperv`.
- **Source of truth:** `subcatch.c:156–160, 177`

---

### Width

- **Data type:** REAL
- **Required:** yes
- **Units:** US: feet / SI: meters
- **Valid values / range:** ≥ 0 (`subcatch.c:158`: `x[i] < 0.0` triggers error). Physically meaningful values are > 0; a value of 0 causes the alpha coefficient to be 0, suppressing overland flow.
- **Default:** `500` (GUI factory default, feet, `objprops.txt:256`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Characteristic width of the overland flow path. Used together with area and slope in the Manning's kinematic wave equation to compute the alpha coefficient for each subarea (`subcatch_validate`, `subcatch.c:406`): `alpha = MCOEFF * width / area * sqrt(slope) / N`. An initial estimate is `Area / (maximum overland flow path length)`; the user should calibrate this to match measured hydrographs (manual footnote, `B.2_Subcatchment_Properties.md:20`). Converted to feet internally by dividing by `UCF(LENGTH)` (`subcatch.c:178`).
- **Source of truth:** `subcatch.c:156–160, 178, 406`

---

### Slope

- **Data type:** REAL
- **Required:** yes
- **Units:** percent (converted to ft/ft internally)
- **Valid values / range:** ≥ 0 (`subcatch.c:158`). A slope of 0 yields an alpha of 0 (no overland flow contribution from slope term).
- **Default:** `0.5` (GUI factory default, percent, `objprops.txt:257`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Average percent slope of the subcatchment. Converted to a dimensionless rise/run by dividing by 100 (`subcatch.c:179`). Appears under the square root in the Manning's overland-flow alpha calculation (`subcatch.c:406`). The GUI label is `% Slope`; units shown as `(%)` for both US and SI (`objprops.txt:287`).
- **Source of truth:** `subcatch.c:156–160, 179`

---

### Clength

- **Data type:** REAL
- **Required:** yes
- **Units:** any consistent length unit (not converted; user-chosen)
- **Valid values / range:** ≥ 0 (`subcatch.c:158`). Use 0 if pollutant buildup is not normalised to curb length.
- **Default:** `0` (GUI factory default, `objprops.txt:273`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Total curb length in the subcatchment. Used only when pollutant buildup functions in `[BUILDUP]` are expressed per unit of curb length (buildup normalisation option). Stored as `Subcatch[j].curbLength` (`subcatch.c:180`). If no water-quality simulation is performed, this field has no effect and 0 is correct. The manual notes "Use 0 if not applicable" (`D.2_Input_File_Format.md:610`).
- **Source of truth:** `subcatch.c:156–160, 180`

---

### Spack

- **Data type:** NAME_REF
- **Required:** no (default: none — snow pack not assigned)
- **Units:** n/a
- **Valid values / range:** Must match a name declared in `[SNOWPACKS]`. If present and not found, the engine returns `ERR_NAME` (`subcatch.c:167`).
- **Default:** `''` (empty string, GUI factory default `objprops.txt:269`)
- **Cross-section dependency:** `[SNOWPACKS].Name`
- **Database-key hint:** foreign key to `[SNOWPACKS].Name`, nullable
- **Technical description:** Optional name of a snow pack parameter set that describes snow accumulation, redistribution, and melting over this subcatchment. When present and valid, the engine calls `snow_createSnowpack(j, k)` to attach the snow pack object (`subcatch.c:188`). Multiple subcatchments may share the same snow pack parameter set. Stored as a pointer `Subcatch[j].snowpack` after creation. Token is at position 8 (0-based) in the line; the engine checks `ntoks > 8` before reading (`subcatch.c:164–169`). The GUI always emits this column (as empty string when not assigned) to maintain fixed column width in the export (`Uexport.pas:549`).
- **Source of truth:** `subcatch.c:163–190`

---

## Notes

- **Section-header prefix matching:** The engine matches section headers by prefix against `ws_SUBCATCH = "[SUBCATCHMENT"` (`text.h:409`). This means `[SUBCATCHMENTS]` (with trailing `S`) is the canonical form used in INP files, but any token beginning `[SUBCATCHMENT` is accepted. The GUI likewise uses `'[SUBCATCHMENT'` as the match string (`Uimport.pas:66`).

- **Two-pass parsing:** The engine performs two passes over the input file. The first pass (object registration, `input.c:268–272`) counts objects and allocates the `Subcatch[]` array. The second pass (parameter loading, `input.c:493–497`) fills in field values. This is why `project_findID()` succeeds in `subcatch_readParams()` — the subcatchment is already registered.

- **Companion sections — one row per subcatchment:** `[SUBAREAS]` must contain one entry per subcatchment (Manning's n, depression storage, routing); `[INFILTRATION]` must also contain one entry per subcatchment. `[GROUNDWATER]`, `[LID_USAGE]`, `[COVERAGES]`, `[LOADINGS]`, and `[ADJUSTMENTS]` (for monthly patterns) are optional and relate back to this section's Name field.

- **Monthly adjustment patterns:** Three optional monthly-adjustment pattern references (pervious N, depression storage, infiltration rate) are stored in `SUBCATCH_N_PERV_PAT_INDEX`, `SUBCATCH_DS_PAT_INDEX`, and `SUBCATCH_INFIL_PAT_INDEX` (`Uproject.pas:134–136`). These are NOT emitted in `[SUBCATCHMENTS]` rows; instead they appear as `N-PERV`, `DSTORE`, and `INFIL` entries in the `[ADJUSTMENTS]` section (`Uexport.pas:364–412`, `Uimport.pas:2229–2243`).

- **Outlet ambiguity rule:** If a name given in `OutID` is found as both a node and a subcatchment, both indices will be set ≥ 0 simultaneously, and `subcatch_validate` will report `ERR_SUBCATCH_OUTLET` (`subcatch.c:376–377`). The INP spec requires OutID to resolve unambiguously; node names and subcatchment names should not collide (`Uproject.pas:1494`).

- **Uniqueness:** Each subcatchment name must be unique within the `[SUBCATCHMENTS]` section. Duplicate names cause `ERR_DUP_NAME` during the first pass (`input.c:270`).

- **Factory defaults (GUI only):** When a new subcatchment is created in the GUI, its properties are pre-filled from `DefSubcatch` (`objprops.txt:247–275`): Area=5, Width=500, Slope=0.5%, %Imperv=25, N-Imperv=0.01, N-Perv=0.1, DS-Imperv=0.05 in, DS-Perv=0.05 in, %Zero-Imperv=25, RouteTo=OUTLET, %Routed=100, InfilModel=HORTON. These defaults can be overridden in the Project Defaults dialog (`Ddefault.pas:98–108, 280–288`).

- **Ordering:** The section does not require alphabetical ordering. The engine processes rows in the order they appear, and the internal index assigned to each subcatchment reflects that order.

- **Curb length units:** Unlike all other numeric fields, `Clength` is stored without unit conversion (`subcatch.c:180`). The user must supply it in whatever units the `[BUILDUP]` buildup functions assume for the per-length normalisation; the engine never converts this value.
