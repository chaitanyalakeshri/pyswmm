# [LANDUSES]

**Purpose:** Defines the named land-use categories that exist within the drainage area. Each land-use category can be assigned a street-sweeping schedule (interval, fraction available for removal, and number of days since the last sweeping). Land uses serve solely as the hook for water-quality modelling: they are referenced by [COVERAGES] (which allocates them to subcatchments), [BUILDUP] (which attaches pollutant accumulation functions), and [WASHOFF] (which attaches pollutant wash-off functions). No hydraulic or hydrologic behaviour depends on [LANDUSES] entries; if no pollutant simulation is being performed this section may be omitted entirely.

**Occurrence:** One row per land-use object. Each row is unique; the land-use name is the primary identifier. Street-sweeping columns are optional — when absent they all default to 0.0. The section header is matched by prefix `[LANDUSE` (note: no trailing `S` in the engine keyword macro), so `[LANDUSES]` and `[LANDUSE]` both match.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/input.c:562` — dispatch to `landuse_readParams()`; object registration at `input.c:369`
- Engine parser function: `swmm524_engine/src/landuse.c:51` — function `landuse_readParams`
- Engine report echo: `swmm524_engine/src/inputrpt.c:74` — "Landuse Summary" block; prints `sweepInterval`, `sweepRemoval`, `sweepDays0` for every land use
- GUI reader: `Uimport.pas:1604` — procedure `ReadLanduseData`; dispatcher at `Uimport.pas:2908`
- GUI writer: `Uexport.pas:1469` — procedure `ExportLanduses`
- GUI editor dialog: `Dlanduse.pas` / `Dlanduse.dfm` — three-tabbed editor (General, Buildup, Washoff)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — section [LANDUSES], line 2000
- Additional manual refs: `appendix_C_specialized_property_editors/C.14_Land_Use_Editor.md`; `appendix_C_specialized_property_editors/C.13_Land_Use_Assignment_Editor.md`; `chapter_03_swmms_conceptual_model/3.3_Non-Visual_Objects.md` §3.3.11

## Row Format

```
Name  (SweepInterval  Availability  LastSweep)
```

The three sweeping columns are optional as a group: either all three must be present or all three must be absent. If any sweeping column is provided, all three must be supplied or the engine returns `ERR_ITEMS` (`landuse.c:70`).

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-empty string with no embedded spaces (the engine uses whitespace tokenisation). Must have been previously registered in the first-pass object-count loop (`input.c:369`); an unrecognised name returns `ERR_NAME`.
- **Default:** none
- **Cross-section dependency:** Referenced by [COVERAGES].Landuse, [BUILDUP].Landuse, [WASHOFF].Landuse
- **Database-key hint:** primary identifier of this row
- **Technical description:** User-assigned label for the land-use category (e.g. `RESIDENTIAL`, `COMMERCIAL`, `UNDEVELOPED`). The string is stored via `project_findID(LANDUSE, tok[0])` and written back as `Landuse[j].ID`. The GUI enforces uniqueness and disallows embedded spaces (`Dlanduse.pas:136` — `Mask:emNoSpace`).
- **Source of truth:** `swmm524_engine/src/landuse.c:65–66`

### SweepInterval

- **Data type:** REAL
- **Required:** no (default: `0.0`)
- **Units:** days
- **Valid values / range:** `≥ 0`; a value of `0` means no street sweeping is applied to this land use
- **Default:** `0.0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The number of days between successive street-sweeping events on this land use. When positive, the engine periodically removes a fraction of accumulated pollutant buildup. The interval governs how often the sweep event fires relative to the simulation clock. A value of `0` effectively disables sweeping (`objects.h:844`).
- **Source of truth:** `swmm524_engine/src/landuse.c:71` — `getDouble(tok[1], &Landuse[j].sweepInterval)`

### Availability (SweepRemoval)

- **Data type:** REAL
- **Required:** no (default: `0.0`); must be supplied together with SweepInterval and LastSweep
- **Units:** unitless (fraction, 0–1)
- **Valid values / range:** `0.0 – 1.0` (inclusive); values outside this range trigger `ERR_NUMBER` at `landuse.c:84–86`
- **Default:** `0.0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The fraction of the total accumulated pollutant buildup on the land use that is available for removal by street sweeping. This is a land-use-level availability factor; the per-pollutant sweeping-removal efficiency is stored separately in the [WASHOFF] section (`sweepEffic` field in `TWashoff`, `objects.h:834`). The actual mass removed = SweepRemoval × per-pollutant sweepEffic × current buildup. Stored as `Landuse[j].sweepRemoval` (`objects.h:845`). In the GUI this field is labelled "Availability" (`Dlanduse.pas:140`, `Uexport.pas:1492`).
- **Source of truth:** `swmm524_engine/src/landuse.c:73`, validation at `landuse.c:84–86`

### LastSweep (SweepDays0)

- **Data type:** REAL
- **Required:** no (default: `0.0`); must be supplied together with SweepInterval and Availability
- **Units:** days
- **Valid values / range:** `≥ 0`
- **Default:** `0.0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The number of days that elapsed since this land use was last swept at the start of the simulation. Used to initialise `landFactor[i].lastSwept` as `StartDateTime - Landuse[i].sweepDays0` (`landuse.c:385`). A value of `0` means the land use was swept on the very first day of the simulation; a value equal to `SweepInterval` means sweeping is about to occur. In the GUI this field is labelled "Last Swept" (`Dlanduse.pas:141`, `Uexport.pas:1493`). Stored as `Landuse[j].sweepDays0` (`objects.h:846`).
- **Source of truth:** `swmm524_engine/src/landuse.c:75`; applied at `landuse.c:385`

## Notes

- **Section keyword matching:** The engine token `ws_LANDUSE` is defined as `"[LANDUSE"` (no trailing `S`) in `text.h:429`. The INP writer emits `[LANDUSES]` (with `S`) in `Uexport.pas:1478`; both spellings are accepted by the engine because its section dispatch tests only the prefix.
- **Sweeping columns are all-or-nothing:** If `ntoks > 1` the engine requires exactly 4 tokens (Name + three sweeping values); supplying only 1 or 2 sweeping values returns `ERR_ITEMS` (`landuse.c:70`). There is no way to supply just SweepInterval without also supplying Availability and LastSweep.
- **Buildup and washoff data are NOT in this section:** The [LANDUSES] section records only the land-use name and street-sweeping schedule. Pollutant buildup functions (function type, coefficients, normalizer) go in [BUILDUP]; washoff functions (function type, coefficient, exponent, per-pollutant sweeping efficiency, BMP efficiency) go in [WASHOFF]. Both sections cross-reference land uses by Name.
- **Per-pollutant sweep efficiency is in [WASHOFF], not here:** `Availability` (SweepRemoval) in [LANDUSES] is a global factor for all pollutants. The per-pollutant fractional removal is `sweepEffic` inside `TWashoff` (`objects.h:834`), stored via [WASHOFF] records. The net removal = SweepRemoval × sweepEffic.
- **Water-quality dependency:** If no pollutants are defined, land-use objects have no effect. Conversely, if pollutants are defined but no land uses are assigned to a subcatchment (via [COVERAGES]), no pollutant buildup/washoff occurs on that subcatchment (`D.2_Input_File_Format.md:2031`).
- **Ordering and uniqueness:** Each Name must be unique within [LANDUSES]; a duplicate triggers `ERR_DUP_NAME` during the first-pass count at `input.c:370`. Order of rows is irrelevant to the engine.
- **GUI default values for sweeping:** The GUI initialises all three sweeping fields to `'0'` when creating a new land use (`Dlanduse.pas:227–229`). When all three are `'0'` the exporter still writes them to the INP file (`Uexport.pas:1490–1494`).
- **Internal object arrays:** After parsing, each `TLanduse` struct (`objects.h:841–849`) also holds `buildupFunc` and `washoffFunc` pointer arrays (one entry per pollutant), but these are populated by [BUILDUP] and [WASHOFF] parsers, not by [LANDUSES].
- **Report echo:** `inputrpt.c:74–93` prints a "Landuse Summary" table in the RPT file showing each land use's sweep interval, maximum removal fraction, and last swept days. This is the only engine output that echoes [LANDUSES] data.
