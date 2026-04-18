# [ADJUSTMENTS]

**Purpose:** Specifies optional monthly correction factors and offsets applied to four global climate variables — air temperature, evaporation rate, rainfall intensity, and soil hydraulic conductivity — once per calendar month throughout the simulation. In addition, the section accommodates per-subcatchment monthly patterns (time-pattern objects of type MONTHLY) that independently scale the pervious Manning's *n* (N-PERV), pervious depression storage (DSTORE), and infiltration rate (INFIL) of individual subcatchments. Together these mechanisms allow long-term continuous simulations to embed seasonal climate variability without requiring external data files.

**Occurrence:** Mixed. The four climate rows (TEMPERATURE, EVAPORATION, RAINFALL, CONDUCTIVITY) appear at most once each as singleton global rows. The subcatchment-pattern rows (N-PERV, DSTORE, INFIL) appear at most once per subcatchment per type, so up to three rows per subcatchment. All rows are optional; the section itself may be absent entirely. The section header keyword `[ADJUSTMENTS]` is matched by the engine via the prefix `[ADJUSTMENT` (`text.h:456`).

**SWMM source references:**
- Engine parser: `climate.c:377` — function `climate_readAdjustments`
- Engine dispatch: `input.c:490` — `case s_ADJUST:` inside `readData()`
- Engine writer: engine does not write INP; no echo of `[ADJUSTMENTS]` is present in `inputrpt.c`
- GUI reader: `Uimport.pas:2169` — function `ReadAdjustmentData`; dispatched at `Uimport.pas:2937`
- GUI writer: `Uexport.pas:414` — procedure `ExportAdjustments`; subcatchment patterns written by `Uexport.pas:364` — procedure `ExportSubcatchAdjustments`; called from main export loop at `Uexport.pas:2381`
- GUI editor dialog: `Dclimate.pas` / `Dclimate.dfm` — "Adjustments" tab of the Climatology Editor (`Dclimate.pas:568` reads data into grid; `Dclimate.pas:709` retrieves it)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[ADJUSTMENTS]` (lines 557–581)
- Additional manual refs: `appendix_C_specialized_property_editors/C.2_Climatology_Editor.md` (Adjustments Page, lines 100–114); `appendix_B_visual_object_properties/B.2_Subcatchment_Properties.md` (N-Perv Pattern, Dstore Pattern, Infil. Pattern, lines 61–65)

## Row Format

The section contains two distinct line shapes depending on whether the row is a global climate adjustment or a per-subcatchment pattern assignment.

**Global climate rows (one row per type):**
```
<Type>  v1  v2  v3  v4  v5  v6  v7  v8  v9  v10  v11  v12
```
where `<Type>` is one of `TEMPERATURE`, `EVAPORATION`, `RAINFALL`, or `CONDUCTIVITY`, and `v1`–`v12` are values for January through December.

**Subcatchment pattern rows (one row per subcatchment per type):**
```
<Type>  SubcatchName  PatternName
```
where `<Type>` is one of `N-PERV`, `DSTORE`, or `INFIL`.

The GUI header comment line emitted before the data is:
```
;;Parameter   <tab>  Subcatchment    <tab>  Monthly Adjustments
```
(`Uexport.pas:445–447`)

## Fields

### Type (row discriminator)

- **Data type:** ENUM
- **Required:** yes — first token on every row; determines the interpretation of all subsequent tokens
- **Units:** n/a
- **Valid values / range:**
  - `TEMPERATURE` (prefix match `TEMP`) — global additive temperature row
  - `EVAPORATION` (prefix match `EVAP`) — global additive evaporation row
  - `RAINFALL` (prefix match `RAIN`) — global multiplicative rainfall row
  - `CONDUCTIVITY` (prefix match `CONDUCT`) — global multiplicative conductivity row
  - `N-PERV` (exact match `N-PERV`) — per-subcatchment pervious-*n* pattern row
  - `DSTORE` (exact match `DSTORE`) — per-subcatchment depression-storage pattern row
  - `INFIL` (exact match `INFIL`) — per-subcatchment infiltration-rate pattern row
  The engine uses `match()` (prefix comparison) for the first four types and `match()` for the last three as well; `match()` requires the token to equal the start of the keyword string, so `TEMP` matches `TEMPERATURE`, etc. (`climate.c:398,409,420,431,443,454,465`)
- **Default:** none — row type is always required
- **Cross-section dependency:** None
- **Database-key hint:** composite PK with SubcatchName for N-PERV/DSTORE/INFIL rows; plain discriminator (no key) for the four global rows
- **Technical description:** The token is parsed first; the remainder of the line is interpreted differently according to which type was matched. An unrecognised keyword causes `ERR_KEYWORD`. (`climate.c:475`)
- **Source of truth:** `climate.c:393–475`

---

### v1 … v12  (TEMPERATURE row)

- **Data type:** REAL
- **Required:** yes — exactly 12 values must follow the `TEMPERATURE` keyword; fewer tokens returns `ERR_ITEMS` (`climate.c:400`)
- **Units:** US: degrees F (additive offset); SI: degrees C (additive offset). At `climate_validate()` the SI values are converted internally to °F by multiplying by 9/5 (`climate.c:524`).
- **Valid values / range:** any real (positive or negative); a value of `0.0` means no adjustment for that month
- **Default:** `0.0` for all 12 months (set in `project.c:943`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Each value is an additive offset applied each timestep in the corresponding calendar month. The adjustment is added to the air temperature computed from a time series or climate file (`climate.c:806–807,862`). When neither a time series nor a climate file is specified, air temperature is fixed at 70 °F and the adjustment is still applied. The same offset is used for both the daily minimum and maximum temperatures read from a climate file (`climate.c:806–807`). Values are stored in `Adjust.temp[0..11]` (°F internally; `objects.h:215`).
- **Source of truth:** `climate.c:398–407` (parsing); `climate.c:524` (unit conversion); `climate.c:806,862` (application)

---

### v1 … v12  (EVAPORATION row)

- **Data type:** REAL
- **Required:** yes — exactly 12 values must follow the `EVAPORATION` keyword; fewer tokens returns `ERR_ITEMS` (`climate.c:411`)
- **Units:** US: in/day (additive offset); SI: mm/day (additive offset). Internally stored in ft/s after `climate_validate()` divides by `UCF(EVAPRATE)` (`climate.c:525`).
- **Valid values / range:** any real (positive or negative); a value of `0.0` means no adjustment
- **Default:** `0.0` for all 12 months (set in `project.c:944`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Each value is an additive offset applied to the current evaporation rate at each simulation timestep when the month matches. The adjustment is added after the base evaporation rate is determined from whichever evaporation source is active (`climate.c:910`). Negative offsets can drive evaporation to zero but will not produce negative rates (the engine clamps elsewhere). Values are stored in `Adjust.evap[0..11]` (ft/s internally; `objects.h:216`).
- **Source of truth:** `climate.c:409–418` (parsing); `climate.c:525` (unit conversion); `climate.c:910` (application)

---

### v1 … v12  (RAINFALL row)

- **Data type:** REAL
- **Required:** yes — exactly 12 values must follow the `RAINFALL` keyword; fewer tokens returns `ERR_ITEMS` (`climate.c:422`)
- **Units:** unitless multiplier (dimensionless)
- **Valid values / range:** any real ≥ 0 recommended; `1.0` = no change; `> 1.0` = increase; `0 < x < 1.0` = decrease
- **Default:** `1.0` for all 12 months (set in `project.c:945`). The GUI reader stores an empty string when the parsed value equals the default `1.0`, and re-emits `1.0` on export for blank cells (`Uimport.pas:2207`; `Uexport.pas:476`).
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Each value is a multiplicative factor applied to the rainfall depth (or intensity) produced by every rain gage at each timestep in the matching month. The current month's factor is cached at the start of each day into `Adjust.rainFactor` (`climate.c:652`), and applied at the point of gage reading: `return r1 * Gage[j].unitsFactor * Adjust.rainFactor` (`gage.c:702`). The same factor also scales RDII gage reads (`rdii.c:1194`). Values are stored in `Adjust.rain[0..11]` (`objects.h:217`).
- **Source of truth:** `climate.c:420–430` (parsing); `climate.c:652` (daily update); `gage.c:702` (application)

---

### v1 … v12  (CONDUCTIVITY row)

- **Data type:** REAL
- **Required:** yes — exactly 12 values must follow the `CONDUCTIVITY` keyword; fewer tokens returns `ERR_ITEMS` (`climate.c:433`)
- **Units:** unitless multiplier (dimensionless)
- **Valid values / range:** `> 0`; a parsed value `≤ 0` is silently replaced with `1.0` at parse time (`climate.c:438`). `1.0` = no change.
- **Default:** `1.0` for all 12 months (set in `project.c:946`). GUI stores empty string for values equal to default `1.0` (`Uimport.pas:2219`).
- **Cross-section dependency:** None; however, if a subcatchment's `INFIL` pattern row is present, the per-subcatchment pattern overrides this global factor for that subcatchment (`infil.c:271–283`).
- **Database-key hint:** plain data – no key role
- **Technical description:** Each value is a multiplicative factor applied to soil hydraulic conductivity used by both Horton and Green-Ampt infiltration methods, by groundwater exfiltration through storage-unit or channel bottoms, and by conduit seepage losses. The current month's factor is cached daily into `Adjust.hydconFactor` (`climate.c:653`). Within `infil_setInfilFactor()` the global factor is the default; per-subcatchment MONTHLY_PATTERN overrides it (`infil.c:262–284`). The factor is also applied to conduit seepage (`link.c:1378`) and exfiltration from storage nodes (`exfil.c:174,190`). Values stored in `Adjust.hydcon[0..11]` (`objects.h:218`).
- **Source of truth:** `climate.c:431–441` (parsing, clamping); `climate.c:653` (daily update); `infil.c:262–284` (application); `link.c:1378`; `exfil.c:174,190`

---

### SubcatchName  (N-PERV, DSTORE, INFIL rows)

- **Data type:** NAME_REF
- **Required:** yes — second token on N-PERV / DSTORE / INFIL rows; missing token returns `ERR_ITEMS` (`climate.c:445,456,467`)
- **Units:** n/a
- **Valid values / range:** must match the name of an existing subcatchment defined in `[SUBCATCHMENTS]`; unresolved name returns `ERR_NAME` (`climate.c:447,458,469`)
- **Default:** none
- **Cross-section dependency:** `[SUBCATCHMENTS].Name`
- **Database-key hint:** foreign key to [SUBCATCHMENTS].Name; composite PK with Type (N-PERV / DSTORE / INFIL)
- **Technical description:** Identifies which subcatchment receives the pattern assignment. Resolved via `project_findObject(SUBCATCH, tok[1])`. The resulting integer index is stored in `Subcatch[i].nPervPattern`, `Subcatch[i].dStorePattern`, or `Subcatch[i].infilPattern` respectively (initialised to -1 in `subcatch.c:181–183`; `objects.h:397–399`). Each subcatchment may have at most one pattern per type.
- **Source of truth:** `climate.c:443–474`; `objects.h:397–399`; `subcatch.c:181–183`

---

### PatternName  (N-PERV, DSTORE, INFIL rows)

- **Data type:** NAME_REF
- **Required:** yes — third token on N-PERV / DSTORE / INFIL rows; missing token returns `ERR_ITEMS` (`climate.c:445,456,467`)
- **Units:** n/a (the pattern factors are dimensionless multipliers)
- **Valid values / range:** must match the name of an existing time pattern defined in `[PATTERNS]`; unresolved name returns `ERR_NAME` (`climate.c:449,461,473`). The engine further requires the pattern to be of type `MONTHLY_PATTERN` (12 monthly factors) at runtime; if the pattern exists but is not monthly, the adjustment silently has no effect (`subcatch.c:1142,1151`; `infil.c:278`).
- **Default:** none (no pattern assigned; -1 sentinel in the struct)
- **Cross-section dependency:** `[PATTERNS].Name` where pattern type = MONTHLY
- **Database-key hint:** foreign key to [PATTERNS].Name
- **Technical description:** The pattern's 12 monthly factors are applied as multiplicative scalars at each runoff timestep:
  - **N-PERV**: The Alpha (runoff coefficient) for the pervious subarea is divided by the current month's factor (`Alpha /= f`; if `f ≤ 0`, Alpha is forced to 0). Because Alpha is proportional to 1/n, dividing Alpha by f is equivalent to multiplying Manning's *n* by f. Applied only to the PERV subarea (`subcatch.c:1149–1157`).
  - **DSTORE**: Multiplies the pervious depression storage depth `Dstore` by the current month's factor; negative factors are ignored (`if (f >= 0.0) Dstore *= f`). Applied only to the PERV subarea (`subcatch.c:1140–1147`).
  - **INFIL**: Completely overrides the global `CONDUCTIVITY` monthly factor for this subcatchment. The factor replaces `Adjust.hydconFactor` in `InfilFactor` rather than multiplying it (`infil.c:280–282`). If the pattern value is ≤ 0, the guard at `Pattern[p].type == MONTHLY_PATTERN` still runs and could set InfilFactor to 0, so pattern factors should be positive.
  The GUI stores the pattern name in `Subcatch.Data[SUBCATCH_N_PERV_PAT_INDEX]` (index 25), `SUBCATCH_DS_PAT_INDEX` (26), and `SUBCATCH_INFIL_PAT_INDEX` (27) respectively (`Uproject.pas:134–136`). These indices are validated as optional (blank allowed) in `Uvalidate.pas:65–66`. In `Uedit.pas:493–495`, the dropdown for all three is populated with `GetMonthlyPatternNames`, confirming only MONTHLY patterns are intended.
- **Source of truth:** `climate.c:443–474` (parsing); `subcatch.c:1125–1159` (N-PERV and DSTORE application); `infil.c:262–284` (INFIL application); `Uproject.pas:134–136`

## Notes

- **Section name prefix matching:** The engine's section-dispatch uses `ws_ADJUST = "[ADJUSTMENT"` (`text.h:456`), so the canonical header `[ADJUSTMENTS]` is recognised by the prefix `[ADJUSTMENT`. A file that spells it as `[ADJUSTMENT]` (without the trailing `S`) will also be accepted.
- **Row-keyword prefix matching:** Within the section, `TEMPERATURE`, `EVAPORATION`, `RAINFALL`, and `CONDUCTIVITY` are also matched by prefix via `match()`. Thus abbreviated forms (`TEMP`, `EVAP`, `RAIN`, `CONDUCT`) are valid. `N-PERV`, `DSTORE`, and `INFIL` use the same `match()` function; since no other keyword starts with those prefixes, they behave as exact matches in practice.
- **All rows are optional:** Neither the section header nor any of its seven row types is required. Absent global rows default to identity (0 for additive, 1.0 for multiplicative). Absent per-subcatchment rows mean no pattern override.
- **Global vs. per-subcatchment conductivity:** The `CONDUCTIVITY` row sets a global monthly multiplier. A subcatchment's `INFIL` pattern row completely replaces (does not stack with) the global factor for that subcatchment's infiltration calculation (`infil.c:271–282`). The global factor still applies to conduit seepage and storage exfiltration regardless of any INFIL pattern.
- **Pattern type enforcement at runtime:** The engine only applies N-PERV / DSTORE / INFIL patterns when `Pattern[p].type == MONTHLY_PATTERN` (`enums.h:384`). If a non-monthly pattern name is accidentally referenced, the adjustment silently does nothing. The GUI restricts the dropdown to monthly patterns (`Uedit.pas:492`), so this edge case arises only in hand-edited INP files.
- **Repeatability across years:** The same monthly values repeat for the same calendar month in every simulated year (manual D.2, line 581). There is no mechanism to assign different values for the same month in different years.
- **N-PERV semantics (inverse relationship):** Manning's *n* enters the kinematic-wave runoff coefficient Alpha as `Alpha ∝ 1/n`. The N-PERV pattern multiplies *n*, not Alpha directly. Doubling the N-PERV pattern factor (f = 2) halves Alpha (and thus halves peak runoff), consistent with increased surface roughness in winter. A factor ≤ 0 forces zero runoff from the pervious subarea (`subcatch.c:1155`).
- **DSTORE pattern applies only to pervious subarea:** Depression storage on the impervious subarea is not adjustable via this section. Only `Subcatch[j].dStorePattern` (pervious) is populated here.
- **GUI initialisation defaults:** `TempAdjust`, `EvapAdjust`, `RainAdjust`, and `CondAdjust` are initialised to empty strings in `Uproject.pas:1828–1831`. Empty cells are not written to the INP file. On export, if any month has a non-default value, all 12 months are written (defaulting missing months to `0.0` for additive rows and `1.0` for multiplicative rows; `Uexport.pas:454,465,476,488`).
- **Ordering:** Within the section, any row order is accepted by the parser. The GUI emits global climate rows first (TEMPERATURE, EVAPORATION, RAINFALL, CONDUCTIVITY), followed by all subcatchment N-PERV rows, then DSTORE rows, then INFIL rows, iterating subcatchments in project-list order (`Uexport.pas:364–411,448–492`).
- **No uniqueness constraint on subcatchment rows:** The parser does not reject duplicate rows for the same subcatchment and type; the last one wins (later calls to `project_findObject` and pattern assignment overwrite the earlier value).
