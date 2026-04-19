# [COVERAGES]

**Purpose:** Assigns land use categories to subcatchments for water quality simulations by specifying the percentage of each subcatchment's total area that is covered by each named land use. These coverage fractions drive the pollutant buildup and washoff calculations in the surface quality model: at each time step the engine scales buildup accumulation, street sweeping removal, and washoff loads by the fractional area (`TLandFactor.fraction`) attributed to each land use on the subcatchment. A subcatchment with no entries in this section will produce no pollutant runoff regardless of what buildup or washoff functions are defined.

**Occurrence:** Multiple rows per object. A subcatchment may be described by one or more rows; each row carries the subcatchment name as its first token followed by one or more repeating (LanduseName, Percent) pairs. When a subcatchment requires more pairs than fit comfortably on one line, additional lines may be used — each continuation line must still carry the same subcatchment name in its first token. The same subcatchment name may therefore appear on multiple rows. Only land uses that actually cover the subcatchment need to be listed; omitted land uses implicitly have zero coverage.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/input.c:574` — dispatch `case s_COVERAGE:` → calls `subcatch_readLanduseParams(Tok, Ntokens)`
- Engine parser (function): `swmm524_engine/src/subcatch.c:284` — function `subcatch_readLanduseParams()`
- Engine section keyword: `swmm524_engine/src/text.h:432` — `#define ws_COVERAGE "[COVERAGE"` (prefix match; any token beginning with `[COVERAGE` is accepted)
- Engine enum: `swmm524_engine/src/enums.h:465` — `s_COVERAGE` in the `InputSectionType` enumeration
- Engine object struct: `swmm524_engine/src/objects.h:364–371` — `TLandFactor` struct; `objects.h:392` — `TSubcatch.landFactor` array field
- Engine writer: The engine does not write INP files. No `[COVERAGES]` echo appears in `swmm524_engine/src/inputrpt.c`; the report echo in `inputrpt_writeInput()` does not summarise coverage percentages.
- GUI reader: `swmm524_gui/Epaswmm5/Uimport.pas:1692` — function `ReadCoverageData`; section dispatch at `Uimport.pas:2911` (case 27)
- GUI section keyword: `swmm524_gui/Epaswmm5/Uimport.pas:88` — `'[COVERAGE'` at index 27 in the section-word array
- GUI writer: `swmm524_gui/Epaswmm5/Uexport.pas:1577` — procedure `ExportCoverages`; called from the main export routine at `Uexport.pas:2368`
- GUI editor dialog: `swmm524_gui/Epaswmm5/` — Land Use Assignment Editor (invoked from subcatchment Property Editor via the *Land Uses* row); described in `appendix_C_specialized_property_editors/C.13_Land_Use_Assignment_Editor.md`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[COVERAGES]` (line 2015)
- Additional manual refs: `appendix_C_specialized_property_editors/C.13_Land_Use_Assignment_Editor.md`; `appendix_B_visual_object_properties/B.2_Subcatchment_Properties.md` (*Land Uses* property, line 55)

## Row Format

```
Subcat  Landuse  Percent  [Landuse  Percent  ...]
```

The canonical format from D.2 (`D.2_Input_File_Format.md:2019`) is:

```
Subcat  Landuse  Percent  Landuse  Percent  . . .
```

A row must contain at least the subcatchment name, one land use name, and one percentage value (minimum 3 tokens). Additional (Landuse, Percent) pairs extend the row with no upper limit beyond what the parser can tokenise. The GUI writer (`Uexport.pas:1592–1602`) emits one (Subcatchment, LandUse, Percent) triple per line — one land use per line — which is the simplest valid layout. The engine parser handles any number of pairs per line by iterating in steps of 2 (`subcatch.c:307`).

Example from the manual (D.2, line 76):

```
[COVERAGES]
;;Subcatch     Landuse      Pcnt  Landuse       Pcnt
;;================================================== 
AREA1          RESIDENTIAL  80    UNDEVELOPED   20
AREA2          RESIDENTIAL  55    UNDEVELOPED   45
```

## Fields

### Subcat

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must exactly match a name declared in `[SUBCATCHMENTS]`. The engine calls `project_findObject(SUBCATCH, tok[0])` and returns `ERR_NAME` if the name is unknown (`subcatch.c:303–304`). The GUI calls `FindSubcatch(TokList[0])` and raises `SUBCATCH_ERR` on failure (`Uimport.pas:1704–1706`).
- **Default:** none
- **Cross-section dependency:** `[SUBCATCHMENTS].Name`
- **Database-key hint:** composite PK with Landuse (together they identify one coverage record); also foreign key to `[SUBCATCHMENTS].Name`
- **Technical description:** Identifies the subcatchment to which the land use percentages on this row apply. The same subcatchment name may appear on more than one row; the engine accumulates all assignments across multiple rows, overwriting the fraction for any land use that appears more than once for the same subcatchment. The GUI stores the land uses in `TSubcatch.LandUses` (a `TStringlist` of name=value pairs, `Uproject.pas:499`) and updates `TSubcatch.Data[SUBCATCH_LANDUSE_INDEX]` with the resulting count (`Uimport.pas:1724`).
- **Source of truth:** `subcatch.c:303–304`; `Uimport.pas:1704–1706`

---

### Landuse  *(repeating — one per pair)*

- **Data type:** NAME_REF
- **Required:** yes (at least one pair required per row; individual pairs within the repeating group are required together with their Percent)
- **Units:** n/a
- **Valid values / range:** Must exactly match a name declared in `[LANDUSES]`. The engine calls `project_findObject(LANDUSE, tok[k-1])` for each pair and returns `ERR_NAME` if the name is unknown (`subcatch.c:310–311`). The GUI uses `S.LandUses.IndexOfName(S1)` to locate or create the entry (`Uimport.pas:1717–1721`).
- **Default:** none
- **Cross-section dependency:** `[LANDUSES].Name`
- **Database-key hint:** composite PK with Subcat; also foreign key to `[LANDUSES].Name`
- **Technical description:** Name of a land use category whose spatial coverage within the named subcatchment is being specified. Each land use declared in `[LANDUSES]` may appear at most once per subcatchment across all rows (a second occurrence overwrites the first). The land use index `m` obtained from `project_findObject(LANDUSE, ...)` is used directly as the array index into `Subcatch[j].landFactor[m]` (`subcatch.c:317`), so land use order in the `[LANDUSES]` section determines the internal array slot. The pairing requirement (Landuse must be followed by Percent) is enforced: if a Landuse token appears without a following Percent token, the engine returns `ERR_ITEMS` (`subcatch.c:312`).
- **Source of truth:** `subcatch.c:310–312`; `Uimport.pas:1716–1721`

---

### Percent  *(repeating — one per pair, immediately following its Landuse)*

- **Data type:** REAL
- **Required:** yes (required whenever its paired Landuse is present)
- **Units:** percent (unitless ratio × 100); internally stored as a fraction 0–1
- **Valid values / range:** Any non-negative real number parseable by `getDouble()`. The engine does not clamp or validate the range beyond requiring a numeric value (`subcatch.c:313–314`). No upper bound of 100 is enforced by the parser; the manual states that percentages "do not necessarily have to add up to 100" (`C.13_Land_Use_Assignment_Editor.md:2`). Negative values are not explicitly rejected by the parser but would produce nonsensical results downstream.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data — no key role
- **Technical description:** Specifies what fraction of the subcatchment's total surface area is covered by the paired land use. The engine divides the token value by 100 before storing it as `Subcatch[j].landFactor[m].fraction` (`subcatch.c:317`). This fraction is subsequently used in three places in the surface quality model (`surfqual.c`): (1) `surfqual_getBuildup()` multiplies the per-unit-area buildup rate by the fraction to obtain the mass added to the subcatchment (`surfqual.c:109`); (2) `surfqual_sweepBuildup()` skips land uses with a fraction of 0.0 when applying street-sweeping removal (`surfqual.c:158`); (3) `surfqual_getWashoff()` integrates washoff loads across all land uses weighted by their fractions. Percentages for different land uses on the same subcatchment do not need to sum to 100; any uncovered remainder is simply not attributed to any land use and produces no pollutant load. The GUI reader stores values as strings in `TSubcatch.LandUses` (`Uimport.pas:1718–1721`) and later converts them to `Single` floats via `Uutils.GetSingle` when validating (`Uimport.pas:1711`).
- **Source of truth:** `subcatch.c:313–317`; `surfqual.c:109, 158`

---

## Notes

- **Repeating-group pattern:** The core structure of each row is a single Subcat identifier followed by one or more (Landuse, Percent) pairs. The engine loop at `subcatch.c:307` (`for ( k = 2; k <= ntoks; k = k+2 )`) reads pairs indefinitely until tokens are exhausted. There is no syntax delimiter between pairs — the parser relies solely on alternating position. A row with an odd total number of tokens (e.g., `AREA1 RESIDENTIAL 80 UNDEVELOPED`) will cause `ERR_ITEMS` because the last Landuse token has no following Percent (`subcatch.c:312`).

- **Continuation lines:** When a subcatchment has many land uses, the user must repeat the subcatchment name at the start of each additional line. The manual explicitly states: "If more than one line is needed, then the subcatchment name must still be entered first on the succeeding lines" (`D.2_Input_File_Format.md:2027`). Each such line is an independent row processed identically; the engine looks up the same subcatchment index each time and writes into its `landFactor` array.

- **Section keyword prefix matching:** The engine matches the section header using the prefix `[COVERAGE` (`text.h:432`). The section tag `[COVERAGES]` in INP files is therefore matched by this prefix rule, consistent with other section keywords in SWMM.

- **GUI writes one pair per line:** `ExportCoverages` (`Uexport.pas:1592–1602`) emits exactly one row per (subcatchment, land use) combination, each containing only a single (Landuse, Percent) pair. This is a valid subset of the format the parser accepts. Round-tripping through the GUI will therefore expand compact multi-pair lines into separate single-pair lines without altering semantics.

- **Zero-coverage land uses omitted:** Neither the GUI export nor the manual requires a subcatchment to list every land use. If a land use is not mentioned for a subcatchment, its `landFactor[m].fraction` remains 0.0 (default initialisation), which is equivalent to listing it with Percent = 0 (`D.2_Input_File_Format.md:2029`).

- **No pollutant runoff without coverage:** A subcatchment that has no entries in `[COVERAGES]` will generate zero pollutant load in runoff even if `[BUILDUP]` and `[WASHOFF]` functions are defined, because all `landFactor` fractions remain 0.0 (`D.2_Input_File_Format.md:2031`).

- **Overwrite semantics for duplicate land use on same subcatchment:** If the same (Subcat, Landuse) pair appears on more than one row (or more than once within the same row), the engine silently overwrites the earlier fraction with the later value (`subcatch.c:317`). The GUI reader uses `IndexOfName` to detect existing entries and replaces them (`Uimport.pas:1717–1721`), so the last occurrence wins.

- **Ordering and composite key:** For database design purposes, the natural key of one coverage record is (Subcat, Landuse). No explicit ordering within the section is required by the engine. Within the GUI internal model, land uses are stored in order of first encounter in the `TSubcatch.LandUses` stringlist (`Uproject.pas:499`).

- **Dependency on [LANDUSES]:** The `[LANDUSES]` section must be parsed before `[COVERAGES]` so that land use names resolve to valid internal indices. The engine's section dispatch processes sections in the order they appear in the INP file, and by convention `[LANDUSES]` precedes `[COVERAGES]` (D.2 table of contents, line 48–50). If `[COVERAGES]` appears before `[LANDUSES]`, the `project_findObject(LANDUSE, ...)` call will fail with `ERR_NAME`.
