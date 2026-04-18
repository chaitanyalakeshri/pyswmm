# [EVAPORATION]

**Purpose:** Specifies how daily potential evaporation rates vary with time across the entire study area. Evaporation acts on standing water on subcatchment surfaces, on subsurface water in groundwater aquifers, on water flowing in open channels, and on water held in storage units. The section supports five mutually exclusive data-source variants (CONSTANT, MONTHLY, TIMESERIES, TEMPERATURE, FILE) and two supplementary modifiers (RECOVERY, DRY_ONLY) that may appear on separate lines in any order. Evaporation rates are potential rates; the actual evaporation loss depends on the water depth available at each simulation time step.

**Occurrence:** Single global section — multiple rows, each starting with a keyword. Exactly one of the five data-source keywords must appear; the two modifier keywords (RECOVERY, DRY_ONLY) are optional and each appears on its own row. There is no per-object identifier: the section applies project-wide.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/climate.c:285` — function `climate_readEvapParams`
- Engine dispatch: `swmm524_engine/src/input.c:487` — `case s_EVAP: return climate_readEvapParams(Tok, Ntokens);`
- Engine writer: The engine does not write INP. No echo of evaporation data appears in `inputrpt.c` (no evaporation section in input report).
- GUI reader: `Uimport.pas:563` — function `ReadEvaporationData` (dispatches to `ReadEvaporationRates` at line 523)
- GUI writer: `Uexport.pas:325` — procedure `ExportEvaporation`
- GUI editor dialog: `Dclimate.pas` / `Dclimate.dfm` — Climatology Editor, Evaporation tab (`EvapSourceCombo`, `EvapValueEdit`, `EvapSeriesCombo`, `EvapGrid1`, `EvapGrid2`, `RecoveryCombo`, `DryOnlyCheckBox`)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [EVAPORATION] (lines 429–484)
- Additional manual refs: `appendix_C_specialized_property_editors/C.2_Climatology_Editor.md` — Evaporation Page; `chapter_03_swmms_conceptual_model/3.3_Non-Visual_Objects.md` — Evaporation subsection; `chapter_11_files_used_by_swmm/11.4_Climate_Files.md`

## Row Format

The section contains multiple keyword-data lines. There is no fixed single-line layout; the format depends on which keyword begins the line:

```
CONSTANT   evap
MONTHLY    e1 e2 e3 e4 e5 e6 e7 e8 e9 e10 e11 e12
TIMESERIES Tseries
TEMPERATURE
FILE       (p1 p2 p3 p4 p5 p6 p7 p8 p9 p10 p11 p12)
RECOVERY   patternID
DRY_ONLY   YES/NO
```

Only one data-source line (CONSTANT / MONTHLY / TIMESERIES / TEMPERATURE / FILE) should be present. RECOVERY and DRY_ONLY each appear on their own line and are independent of which data-source type is chosen. If the entire section is absent, evaporation is assumed to be zero throughout the simulation (`appendix_D_command_line_swmm/D.2_Input_File_Format.md:467`).

## Fields

### Keyword (row-type discriminator)

- **Data type:** ENUM
- **Required:** yes — the first token on every data line selects which sub-format follows
- **Units:** n/a
- **Valid values / range:**
  - `CONSTANT` — single constant rate applies for the whole simulation
  - `MONTHLY` — twelve monthly average rates
  - `TIMESERIES` — user-supplied time series name
  - `TEMPERATURE` — rates computed by the Hargreaves method from daily temperature data
  - `FILE` — rates read daily from the external climate file referenced in `[TEMPERATURE]`
  - `RECOVERY` — supplementary modifier; supplies an optional monthly soil-recovery pattern
  - `DRY_ONLY` — supplementary modifier; controls whether evaporation is suppressed during rain
- **Default:** none — at least one keyword row is required if the section exists
- **Cross-section dependency:** None
- **Database-key hint:** composite PK with a "section singleton" indicator — effectively this is a configuration table, not an object table
- **Technical description:** The engine parser uses `findmatch(tok[0], EvapTypeWords)` to decode the keyword (`climate.c:306`). The `EvapTypeWords` array in `keywords.c:51–53` maps ordinals: `CONSTANT_EVAP=0`, `MONTHLY_EVAP=1` (note: GUI `TSERIES_EVAP=1`, `FILE_EVAP=2`, `MONTHLY_EVAP=3`, `TEMP_EVAP=4` — the engine enum order differs slightly from the GUI constant ordering; the wire keywords are unambiguous). Unrecognised keywords return `ERR_KEYWORD`.
- **Source of truth:** `swmm524_engine/src/climate.c:306`; keyword strings in `swmm524_engine/src/text.h:149–155`; enum values in `swmm524_engine/src/enums.h:298–305`

---

### evap (CONSTANT variant — single rate value)

- **Data type:** REAL
- **Required:** yes, when the data-source keyword is `CONSTANT`
- **Units:** in/day (US) / mm/day (SI)
- **Valid values / range:** `≥ 0`; any non-negative real. The value is replicated into all twelve `monthlyEvap[]` slots (`climate.c:339`).
- **Default:** 0.0 (GUI initialises `EvapData[I] := '0.0'` for all months; `Uproject.pas:1826`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data — no key role
- **Technical description:** A single constant potential evaporation rate applied uniformly across every time step throughout the simulation. Internally stored as `Evap.monthlyEvap[0..11]` (all identical). The engine converts from user units to ft/sec via `UCF(EVAPRATE)` before use (`climate.c:885`). The GUI example in `D.2_Input_File_Format.md:59` shows `CONSTANT  0.02`.
- **Source of truth:** `swmm524_engine/src/climate.c:335–340`

---

### e1 … e12 (MONTHLY variant — twelve monthly rates)

- **Data type:** REAL (12 values, one per calendar month January through December)
- **Required:** yes, all twelve must be present when the data-source keyword is `MONTHLY` (engine enforces `ntoks < 13` → `ERR_ITEMS` at `climate.c:344`)
- **Units:** in/day (US) / mm/day (SI)
- **Valid values / range:** `≥ 0` for each value
- **Default:** 0.0 for all months (GUI default; `Uproject.pas:1826`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data — no key role
- **Technical description:** Provides a separate potential evaporation rate for each month of the year. The rate stays constant within each month and changes at the start of the next month. The engine stores the twelve values in `Evap.monthlyEvap[0..11]` (`objects.h:201`) and selects the appropriate one at runtime by `mon-1` index (`climate.c:889`). The GUI reads and writes all twelve values in order separated by whitespace (`Uexport.pas:351–352`).
- **Source of truth:** `swmm524_engine/src/climate.c:342–348`; `swmm524_engine/src/objects.h:201`

---

### Tseries (TIMESERIES variant — time series name)

- **Data type:** NAME_REF
- **Required:** yes, when the data-source keyword is `TIMESERIES`
- **Units:** n/a (the referenced time series carries values in in/day or mm/day)
- **Valid values / range:** must match a name defined in `[TIMESERIES]`; the engine calls `project_findObject(TSERIES, tok[1])` and returns `ERR_NAME` if not found (`climate.c:352–354`)
- **Default:** none (empty string in GUI; `Uproject.pas:1823`)
- **Cross-section dependency:** `[TIMESERIES].Name`
- **Database-key hint:** foreign key to `[TIMESERIES].Name`
- **Technical description:** The named time series supplies evaporation rates as discrete date–value pairs. Unlike temperature time series (which interpolate), evaporation rates from a time series remain constant at the most recently stated value until the next date-entry is reached — no interpolation is applied between entries (`appendix_C/C.2_Climatology_Editor.md:48`). The engine marks the series with `Tseries[i].refersTo = TIMESERIES_EVAP` (`climate.c:355`) so the time-step scheduler knows to advance through its entries efficiently using `climate_getNextEvapDate`.
- **Source of truth:** `swmm524_engine/src/climate.c:350–356`

---

### (no parameter) — TEMPERATURE variant

- **Data type:** n/a
- **Required:** n/a — the keyword `TEMPERATURE` stands alone with no following token
- **Units:** n/a
- **Valid values / range:** keyword only; if `ntoks < 2` the engine accepts it silently (`climate.c:331` — the check `k != TEMPERATURE_EVAP` exempts this case from the missing-items error)
- **Default:** n/a
- **Cross-section dependency:** Requires a `[TEMPERATURE]` section with an external climate file specified (the `FILE` sub-format of `[TEMPERATURE]`); also uses the site latitude specified via `SNOWMELT` in `[TEMPERATURE]`
- **Database-key hint:** plain data — flag value indicating algorithm selection
- **Technical description:** Instructs SWMM to compute daily potential evaporation using the Hargreaves method, implemented in `climate.c:981–1006` (`getTempEvap`). The computation requires daily maximum and minimum temperatures from an external climate file, as well as the site latitude (`Temp.anglat`). The method uses a 7-day moving average of temperature (variable `Tma`) to smooth the signal (`climate.c:629–636`). The result (in mm/day, converted to in/day for US units) is deposited into `FileValue[EVAP]` and then read by `setEvap` (`climate.c:902–904`). If no climate file is available this variant cannot function.
- **Source of truth:** `swmm524_engine/src/climate.c:331`, `628–636`, `902–904`, `981–1006`

---

### p1 … p12 (FILE variant — optional monthly pan coefficients)

- **Data type:** REAL (12 values, one per calendar month; all optional)
- **Required:** no — if omitted, default values of 1.0 are used for all months; if any are given, all twelve must be present (engine: `ntoks < 13` → `ERR_ITEMS`, `climate.c:363`)
- **Units:** unitless (dimensionless pan-to-free-water-surface conversion factor)
- **Valid values / range:** typically 0 < p ≤ 1; conventional pan coefficients are around 0.7 (`appendix_C/C.2_Climatology_Editor.md:51`); the engine does not enforce a range
- **Default:** 1.0 for all months (engine struct default; GUI: `PanData[I] := '1.0'` at `Uproject.pas:1827`)
- **Cross-section dependency:** Requires `[TEMPERATURE]` section with `FILE` specifying an external climate file that contains evaporation data in its daily records
- **Database-key hint:** plain data — no key role
- **Technical description:** When `FILE` is the data-source type, the engine reads daily pan evaporation values from the climate file into `FileData[EVAP][d]` and then multiplies by the monthly pan coefficient at runtime: `Evap.rate = FileValue[EVAP] / UCF(EVAPRATE); Evap.rate *= Evap.panCoeff[mon-1];` (`climate.c:897–899`). The coefficients account for the difference between pan evaporation (measured from an open evaporation pan) and actual free-water-surface evaporation. Internally stored in `Evap.panCoeff[0..11]` (`objects.h:202`). For NCDC TD-3200 files, the raw pan evaporation is stored in hundredths of inches and converted by dividing by 100 (`climate.c:1316–1321`).
- **Source of truth:** `swmm524_engine/src/climate.c:358–370`, `897–899`; `swmm524_engine/src/objects.h:202`

---

### patternID (RECOVERY modifier — monthly soil recovery pattern)

- **Data type:** NAME_REF
- **Required:** no (modifier row is entirely optional)
- **Units:** n/a (the referenced pattern supplies dimensionless multipliers)
- **Valid values / range:** must match a name defined in `[PATTERNS]` with type `MONTHLY`; the engine calls `project_findObject(TIMEPATTERN, tok[1])` (`climate.c:313–314`); returns `ERR_NAME` if not found. Pattern must be of `MONTHLY_PATTERN` type (`climate.c:915`).
- **Default:** none — if the row is absent, `Evap.recoveryPattern = -1` and `Evap.recoveryFactor = 1.0` (no modification)
- **Cross-section dependency:** `[PATTERNS].Name` where pattern type is `MONTHLY`
- **Database-key hint:** foreign key to `[PATTERNS].Name`
- **Technical description:** Specifies an optional monthly time pattern of multipliers that adjust the rate at which soil infiltration capacity recovers during dry periods. A factor of 1.0 means full (unmodified) recovery; a factor of 0.8 reduces recovery to 80% of normal. This applies globally to all subcatchments regardless of infiltration method. The factor is evaluated monthly via `Pattern[k].factor[mon-1]` and stored in `Evap.recoveryFactor` (`climate.c:912–918`). For example, a pattern factor of 0.8 in July reduces the normal 1%/step recovery rate to 0.8%/step. The intent is to represent seasonal variation in soil drying (e.g., frozen ground in winter). Described at `appendix_C/C.2_Climatology_Editor.md:57` and `appendix_D/D.2_Input_File_Format.md:480`.
- **Source of truth:** `swmm524_engine/src/climate.c:310–316`, `912–918`

---

### YES/NO (DRY_ONLY modifier — suppress evaporation during rain)

- **Data type:** ENUM (boolean keyword)
- **Required:** no (modifier row is optional)
- **Units:** n/a
- **Valid values / range:**
  - `NO` — evaporation proceeds regardless of precipitation (default)
  - `YES` — evaporation is suppressed during any time step with non-zero precipitation
- **Default:** `NO` (`Evap.dryOnly = FALSE`; `climate.c:323`; GUI: `EvapDryOnly := False` at `Uproject.pas:1834`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data — no key role
- **Technical description:** When `YES`, the engine will not apply evaporation losses during rainfall periods. This is physically motivated by the fact that precipitation saturates the air and free surfaces near the ground, greatly reducing net evaporation. The flag is stored in `Evap.dryOnly` (integer boolean in engine; `objects.h:204`). Tokens other than `NO` or `YES` produce `ERR_KEYWORD` (`climate.c:325`). The GUI writer always emits this line (either `DRY_ONLY  YES` or `DRY_ONLY  NO`; `Uexport.pas:359–360`), so the line is always present in GUI-generated files.
- **Source of truth:** `swmm524_engine/src/climate.c:319–327`; `swmm524_engine/src/objects.h:204`

---

## Notes

- **Section-header prefix matching:** The section keyword is matched using prefix `[EVAP` (defined as `ws_EVAP` in `text.h:408`), so `[EVAPORATION]` and any prefix thereof (e.g., `[EVAP]`) would be accepted by the engine's section-recognition loop in `input.c`. The GUI uses the full string `'[EVAPORATION'` (`Uimport.pas:65`).

- **Mutual exclusivity of data-source variants:** Only one of CONSTANT / MONTHLY / TIMESERIES / TEMPERATURE / FILE should appear. The engine overwrites `Evap.type` with each recognised data-source keyword encountered (`climate.c:330`); a second data-source line would silently overwrite the first. The GUI enforces mutual exclusivity via a combo-box (`EvapSourceCombo` in `Dclimate.pas`).

- **GUI enum ordering differs from engine enum ordering:** The engine `EvapType` enum (`enums.h:298–305`) orders: `CONSTANT_EVAP=0, MONTHLY_EVAP=1, TIMESERIES_EVAP=2, TEMPERATURE_EVAP=3, FILE_EVAP=4, RECOVERY=5, DRYONLY=6`. The GUI constants (`Uproject.pas:315–319`) order: `CONSTANT_EVAP=0, TSERIES_EVAP=1, FILE_EVAP=2, MONTHLY_EVAP=3, TEMP_EVAP=4`. Both map to the same keyword strings; the wire format is unambiguous.

- **RECOVERY and DRY_ONLY are not data-source types:** They are handled as a separate branch in `climate_readEvapParams` before the `Evap.type` assignment (`climate.c:309–327`). They do not affect the data-source type stored in `Evap.type`; they modify supplementary fields `Evap.recoveryPattern` and `Evap.dryOnly`.

- **Default when section is absent:** If `[EVAPORATION]` does not appear in the input file, evaporation is zero everywhere in the simulation (`appendix_D/D.2_Input_File_Format.md:467–469`). The engine's `TEvap` struct is zero-initialised at project start.

- **TEMPERATURE and FILE variants require a climate file:** Both variants depend on the presence of a `[TEMPERATURE]` section with an external `FILE` sub-line naming a climate data file. If the climate file is missing or does not contain evaporation data, `FileValue[EVAP]` will remain at its missing/zero value. File formats supported: NOAA GHCN-D, NCDC TD-3200/DS-3210, Canadian Environment Canada files, and a user-prepared format (`chapter_11/11.4_Climate_Files.md`).

- **Units context:** For US unit projects (`FLOW_UNITS` ∈ {CFS, GPM, MGD}), all evaporation rates in this section are in **in/day**. For SI projects ({CMS, LPS, MLD}), rates are in **mm/day**. The engine applies `UCF(EVAPRATE)` to convert to internal ft/sec storage (`climate.c:885, 889, 894, 903`).

- **Monthly adjustments (ADJUSTMENTS section):** Additional per-month additive adjustments (in in/day or mm/day) may be applied via the `[ADJUSTMENTS]` section using the `EVAPORATION` keyword there. These adjustments are accumulated into `Adjust.evap[mon-1]` (an array in `TAdjust`, `objects.h:216`) and added to `Evap.rate` in `setEvap` at `climate.c:910`. This is separate from the `[EVAPORATION]` section but interacts with all five data-source variants.

- **Time-step scheduling optimisation:** The engine function `climate_getNextEvapDate` (`climate.c:659`) is called by the runoff engine to determine the next date when the evaporation rate will change. For `CONSTANT_EVAP` this is set to 365 days in the future; for `MONTHLY_EVAP` it is the start of the next month; for `TIMESERIES_EVAP` it is the next entry in the series; for `FILE_EVAP` and `TEMPERATURE_EVAP` it is the next day. This allows the runoff time step to be extended to that date without recomputing evaporation.

- **DB schema note:** Because only one data-source variant is active at a time, a natural representation is a single-row configuration table with columns for `evap_type` (ENUM), `constant_rate` (REAL nullable), `monthly_rates` (12-column array or child table, nullable), `timeseries_name` (TEXT nullable FK), `pan_coefficients` (12-column array or child table, nullable), `recovery_pattern` (TEXT nullable FK), and `dry_only` (BOOLEAN). The `evap_type` value determines which other columns are meaningful.
