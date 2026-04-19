# [LOADINGS]

**Purpose:** Specifies the initial pollutant buildup (surface accumulation) present on each subcatchment at the start of a simulation. When a value is provided for a particular subcatchment-pollutant pair, it overrides the buildup that would otherwise be computed from the `DRY_DAYS` option in `[OPTIONS]` applied to that subcatchment's buildup functions. Only pollutants with explicitly non-zero initial buildup need to appear; any omitted pollutant falls back to the antecedent dry-days calculation.

**Occurrence:** Multiple rows per object — one or more rows per subcatchment (one row per subcatchment per continued line), with each row carrying one or more pollutant-buildup pairs. A subcatchment may be absent entirely if all its pollutants are to be initialised via `DRY_DAYS`. The same subcatchment name must appear again at the start of each continuation line if more pairs are needed.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/subcatch.c:324` — function `subcatch_readInitBuildup`
- Engine dispatch: `swmm524_engine/src/input.c:592` — `case s_LOADING:`
- Engine section keyword: `swmm524_engine/src/text.h:438` — `#define ws_LOADING "[LOADING"` (prefix match, not exact)
- Engine enum: `swmm524_engine/src/enums.h:466` — `s_LOADING` in `InputSectionType`
- Engine writer: The engine does not write INP files. `swmm524_engine/src/inputrpt.c` does not echo this section in the report.
- GUI reader: `Uimport.pas:1900` — function `ReadLoadData` (dispatched at line 2916 as case 32)
- GUI writer: `Uexport.pas:1606` — procedure `ExportLoadings`
- GUI editor dialog: `Dloads.pas` / `Dloads.dfm` — `TInitLoadingsForm` (caption "Initial Buildup Editor")
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[LOADINGS]` (lines 2034–2052)
- Additional manual refs: `appendix_C_specialized_property_editors/C.10_Initial_Buildup_Editor.md`

## Row Format

```
Subcat  Pollut  InitBuildup  Pollut  InitBuildup  ...
```

Each data line begins with the subcatchment name followed by one or more whitespace-delimited `Pollut InitBuildup` pairs. Additional pairs beyond the first are optional on the same line, and continuation lines (with the subcatchment name repeated) are permitted. The GUI emits one pair per row; the engine parser accepts any number of pairs per row.

GUI column order as emitted by `ExportLoadings` (`Uexport.pas:1617–1629`):

```
;;Subcatchment    Pollutant         Buildup
;;-------------- ---------------- ----------
<Subcat>         <Pollut>         <InitBuildup>
```

## Fields

### Subcat

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any name matching an existing subcatchment defined in `[SUBCATCHMENTS]`. Case-sensitive lookup via `project_findObject(SUBCATCH, tok[0])`.
- **Default:** none (field is mandatory)
- **Cross-section dependency:** `[SUBCATCHMENTS].Name`
- **Database-key hint:** foreign key to `[SUBCATCHMENTS].Name`
- **Technical description:** Identifies the subcatchment whose initial surface buildup is being specified. The engine resolves the name at parse time; an unrecognised name triggers `ERR_NAME` (`subcatch.c:344`). The GUI also validates against the project subcatchment list at `Uimport.pas:1911–1913`. On continuation lines the subcatchment name must be re-entered as the first token; the engine accumulates all pairs for the same subcatchment across multiple rows by writing into `Subcatch[j].initBuildup[m]` (overwriting if the same pollutant appears twice).
- **Source of truth:** `swmm524_engine/src/subcatch.c:343–344`

### Pollut

- **Data type:** NAME_REF
- **Required:** yes (at least one pair per row)
- **Units:** n/a
- **Valid values / range:** Any name matching an existing pollutant defined in `[POLLUTANTS]`. Case-sensitive lookup via `project_findObject(POLLUT, tok[k-1])`.
- **Default:** none (field is mandatory within each pair)
- **Cross-section dependency:** `[POLLUTANTS].Name`
- **Database-key hint:** foreign key to `[POLLUTANTS].Name`
- **Technical description:** Names the pollutant for which an initial buildup value is being assigned. The engine iterates through token pairs starting at position 2: `k` advances by 2 each iteration (`subcatch.c:347`). An unrecognised pollutant name triggers `ERR_NAME`. If a pollutant is not listed for a given subcatchment, its initial buildup defaults to zero and is subsequently computed by `landuse_getInitBuildup` from the antecedent dry-days period (`landuse.c:402`). The GUI validates pollutant names against `Project.Lists[POLLUTANT]` at `Uimport.pas:1914`.
- **Source of truth:** `swmm524_engine/src/subcatch.c:350–351`

### InitBuildup

- **Data type:** REAL
- **Required:** yes (paired with each Pollut token)
- **Units:** US: lbs/acre; SI: kg/hectare
- **Valid values / range:** `≥ 0` (any non-negative real). The engine accepts any parseable double via `getDouble`; the GUI dialog restricts input to positive numbers (`emPosNumber` mask, `Dloads.pas:91`). A value of zero is treated the same as absent — the fallback dry-days buildup computation applies for that pollutant.
- **Default:** 0 (absent entry implies zero; zero implies dry-days fallback)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Specifies how much pollutant mass per unit area already exists on the subcatchment surface at simulation start. The engine stores the raw value directly into `Subcatch[j].initBuildup[m]` (`subcatch.c:357`), which the objects.h comment describes as "initial pollutant buildup (mass/ft2)" but the user-facing units are lbs/acre (US) or kg/ha (SI) as stated in the manual (`D.2_Input_File_Format.md:2044`) and confirmed by the GUI column headings in `Dloads.pas:58–59`. The conversion between user units and internal ft2-based storage occurs inside `landuse_getInitBuildup` via `fArea = f * area * UCF(LANDAREA)` (`landuse.c:389`), where the stored value is multiplied by the land-area fraction in user area units, yielding mass in lbs or kg per land-use subdivision (`landuse.c:398`). If `initBuildup[p] > 0.0` the computed value replaces any dry-days estimate; if exactly zero the dry-days path executes (`landuse.c:395–403`). Co-pollutant fractions defined in `[POLLUTANTS]` do **not** propagate to initial buildup — they apply only to washoff (`landuse.c:367`, comment at line 368). If a non-zero value is specified it completely overrides the `DRY_DAYS`-based calculation for that pollutant across all land uses within the subcatchment.
- **Source of truth:** `swmm524_engine/src/subcatch.c:353–357`; `swmm524_engine/src/landuse.c:394–404`

## Notes

- **Prefix matching:** The section header is matched by the prefix `"[LOADING"` (`text.h:438`), so both `[LOADING]` and `[LOADINGS]` (and any longer prefix) resolve to `s_LOADING`. The GUI always emits `[LOADINGS]` (`Uexport.pas:1616`).
- **Pair structure on each line:** The engine parser requires at least 3 tokens (subcatchment name + one pollutant + one value; `subcatch.c:340`). Additional pairs are consumed by the `k = k+2` loop. If an odd number of extra tokens remain (pollutant given but no value), the engine returns `ERR_ITEMS` (`subcatch.c:352`). The GUI always writes exactly one pair per output row (`Uexport.pas:1624–1629`).
- **Continuation lines:** The manual (`D.2_Input_File_Format.md:2048`) explicitly states that when more than one line is needed, the subcatchment name must be repeated as the first token on each continuation line. The engine simply performs another lookup on `tok[0]` for each new line, so repeated entries for the same subcatchment-pollutant combination overwrite rather than accumulate.
- **Interaction with DRY_DAYS:** If a subcatchment-pollutant pair is absent from `[LOADINGS]`, initial buildup is calculated by applying the `START_DRY_DAYS` option value (from `[OPTIONS]`) to the buildup function defined in `[BUILDUP]` for each land use (`landuse.c:379`, `402`). A `[LOADINGS]` entry with value `> 0` bypasses this entirely for the named pollutant.
- **Zero-valued entries:** The GUI does not emit rows where `InitBuildup` is zero (`Dloads.pas:147–151`). The engine accepts zero, but it produces identical behaviour to omission (dry-days path taken; `landuse.c:397`).
- **Co-pollutant exclusion:** The `landuse_getInitBuildup` function explicitly notes that co-pollutant contributions are not applied to initial buildup (only to washoff), so specifying `InitBuildup` for a primary pollutant does not indirectly set the co-pollutant's initial buildup (`landuse.c:367–368`).
- **Uniqueness:** There is no uniqueness constraint enforced by the engine; a duplicate `(Subcat, Pollut)` pair on a later line silently overwrites the earlier value. For database design, the composite key `(Subcat, Pollut)` should be treated as unique.
- **Composite key:** The pair `(Subcat, Pollut)` uniquely identifies a row in this section for any given project.
- **GUI subcatch flag:** When any non-zero initial loading is entered, the GUI sets `C.Data[SUBCATCH_LOADING_INDEX] := 'YES'` (`Uimport.pas:1925`; `Uedit.pas:1422`) where `SUBCATCH_LOADING_INDEX = 23` (`Uproject.pas:132`). This flag drives the property editor to display the Initial Buildup Editor. The flag does not appear in the INP file.
