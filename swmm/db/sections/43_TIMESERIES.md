# [TIMESERIES]

**Purpose:** Defines one or more named time series objects that describe how a quantity varies over time. Time series are referenced by other sections such as `[RAINGAGES]` (rainfall data), `[EVAPORATION]` (evaporation data), `[TEMPERATURE]` (temperature data), `[OUTFALLS]` (stage boundary conditions), and `[INFLOWS]` (external flow/quality inflows). Each series is identified by a unique name, and its data may be supplied either inline in the INP file or via a path to an external text file.

**Occurrence:** Multiple rows per object — a single named time series typically spans many rows (one or more data triplets per row). The series name must appear as the first token on every row that belongs to it. Multiple date–time–value triplets may be packed onto a single row. The FILE variant requires exactly one row for the named series.

**SWMM source references:**
- Engine parser: `table.c:113` — function `table_readTimeseries`; called from `input.c:602`
- Engine first-pass (object counting): `input.c:400` — `case s_TIMESERIES` in the section-counting switch
- Engine writer: the engine does not write INP files; no echo of `[TIMESERIES]` in `inputrpt.c` (only rain-gage time series IDs appear in the input report at `inputrpt.c:113`)
- GUI reader: `Uimport.pas:2021` — function `ReadTimeseriesData`
- GUI writer: `Uexport.pas:1856` — procedure `ExportTimeseries`
- GUI editor dialog: `Dtseries.pas` / `Dtseries.dfm` — `TTimeseriesForm`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[TIMESERIES]` (line 2390)
- Additional manual refs: Appendix C.23 (Time Series Editor); Section 11.6 (Time Series Files)

## Row Format

Three mutually exclusive row formats exist:

**Format 1 — absolute date+time with value (one or more triplets per row):**
```
Name  Date  Hour  Value  [Date  Hour  Value  ...]
```

**Format 2 — elapsed time from simulation start with value (one or more pairs per row):**
```
Name  Time  Value  [Time  Value  ...]
```

**Format 3 — external file reference (exactly one per named series):**
```
Name  FILE  Fname
```

The GUI always writes one triplet per row in the date+time+value layout (Format 1), padding each field to 10 characters, even when the date is empty (`Uexport.pas:1886–1894`). Multiple triplets per row are valid only for direct-entry formats and are handled by the engine's token-consuming loop (`table.c:155–202`).

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-empty string without spaces, double-quotes, semicolons, or a leading `[` character. The GUI enforces these restrictions at key-press time (`Dtseries.pas:272–277`). Names are case-insensitive for lookup (`Uimport.pas:2043–2044`).
- **Default:** none
- **Cross-section dependency:** None (this is the object being defined; other sections reference it)
- **Database-key hint:** primary identifier of this row (composite PK with row sequence number because the same Name appears on multiple rows)
- **Technical description:** The unique label for this time series. The engine registers each new name during the first pass (`input.c:402–407`) using `project_addObject(TSERIES, ...)` and then resolves it by index during data reading (`table.c:135–136`). The GUI stores all series names in `Project.Lists[TIMESERIES]` (index 22 in `Uproject.pas:62`) and checks for duplicates before accepting edits (`Dtseries.pas:322–329`).
- **Source of truth:** `table.c:135–136`, `input.c:402–407`

---

### Date

- **Data type:** DATE
- **Required:** no (default: last recorded date; if no prior date was set, midnight of the simulation start date is used)
- **Units:** n/a (calendar date)
- **Valid values / range:** A date string parseable by `datetime_strToDate()` in the form `M/D/YYYY` or `M-D-YYYY` (e.g., `6/15/2001` or `6-15-2001`). Only present in Format 1 rows. Only required at rows where the calendar date changes; subsequent rows for the same day may omit it.
- **Default:** Inherited from `Tseries[j].lastDate`, which is initialised to `0.0` (i.e., the simulation start date) (`table.c:272`)
- **Cross-section dependency:** None
- **Database-key hint:** composite PK with Name and Time (together they uniquely identify a data point)
- **Technical description:** The engine attempts `datetime_strToDate(tok[k], &d)` while in state 1 of the parsing loop (`table.c:160–163`). If parsing succeeds, `Tseries[j].lastDate` is updated and the token index is advanced; if it fails, the token is assumed to be a time value and the existing `lastDate` is reused. This "sticky date" mechanism allows a single date to cover many subsequent rows. The GUI stores the date string in `TTimeseries.Dates` (a `TStringList`) and emits it on every row, using an empty string when the date is unchanged (`Uexport.pas:1890`).
- **Source of truth:** `table.c:159–168`

---

### Hour / Time

- **Data type:** TIME (two sub-interpretations share this single token position)
- **Required:** yes (for Formats 1 and 2; absent for Format 3)
- **Units:** n/a (time-of-day or elapsed hours)
- **Valid values / range:**
  - **Format 1 (absolute mode):** 24-hour military clock string `HH:MM` or `HH:MM:SS`, e.g. `20:40`. Parsed by `datetime_strToTime()`. Values ≥ `24:00` are allowed and represent time on the following day relative to the last recorded date.
  - **Format 2 (elapsed mode):** A non-negative decimal number (hours since simulation start, e.g. `2.5`) or a `hours:minutes` string where hours may exceed 24 (e.g. `52:20`). When a plain decimal is detected by `getDouble()`, the value is divided by 24 to convert hours to the internal day fraction (`table.c:174`).
  - The engine uses `getDouble()` first; if that fails it falls back to `datetime_strToTime()` (`table.c:174–178`).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** composite PK with Name and Date
- **Technical description:** In state 2 of the parsing loop, the engine reads exactly one time token (`table.c:170–185`). The resulting fractional-day value is added to `Tseries[j].lastDate` to produce the absolute x-value stored in the linked list (`table.c:181`). This unification means the engine always stores times internally as absolute Julian date-time values regardless of which input format was used. The GUI stores the raw time string in `TTimeseries.Times`.
- **Source of truth:** `table.c:170–185`

---

### Value

- **Data type:** REAL
- **Required:** yes (for Formats 1 and 2; absent for Format 3)
- **Units:** Depends on usage context (e.g., rainfall intensity in in/hr or mm/hr for rain gages; flow in the project's flow units for `[INFLOWS]`; stage in ft or m for outfall boundary conditions; temperature in °F or °C; etc.). The `[TIMESERIES]` section itself is dimensionless — units are imposed by the consuming section.
- **Valid values / range:** Any finite real number parseable by `getDouble()`. The engine does not range-check the value within this parser (`table.c:191–195`).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** In state 3 of the parsing loop, `getDouble(tok[k], &y)` is called; failure triggers `ERR_NUMBER` (error code 211, `table.c:192–193`). A successful read calls `table_addEntry(&Tseries[j], x, y)` to append the point to the series' linked list (`table.c:195`). After storing the value, the state machine resets to state 1 so that the next token on the same row is interpreted as a potential date (`table.c:197–199`). This enables multiple date–time–value (or time–value) triplets to be packed on a single line.
- **Source of truth:** `table.c:188–200`

---

### FILE keyword

- **Data type:** TEXT (literal keyword)
- **Required:** yes when using Format 3
- **Units:** n/a
- **Valid values / range:** Must be the exact string `FILE` (case-insensitive via `strcomp` which is a case-insensitive compare in the engine; `text.h:153` defines `w_FILE "FILE"`).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role (signals which row format is in use)
- **Technical description:** When `tok[1]` matches `w_FILE`, the engine branches to the file-mode path (`table.c:143–148`): `tok[2]` is taken as the filename, resolved to an absolute path with `addAbsolutePath()`, stored in `Tseries[j].file.name`, and `Tseries[j].file.mode` is set to `USE_FILE`. No further tokens are read. Validation (opening the file, checking data ordering) occurs later in `table_validate()` at `table.c:297–307`. The GUI checks the `FILE` keyword on import (`Uimport.pas:2060`) and serialises it back as the literal string `FILE` on export (`Uexport.pas:1881`).
- **Source of truth:** `table.c:143–148`

---

### Fname

- **Data type:** TEXT
- **Required:** yes when Format 3 is used (i.e., the FILE keyword is present)
- **Units:** n/a (file path)
- **Valid values / range:** A valid filesystem path, up to `MAXFNAME` = 259 characters (`consts.h:25`). Paths containing spaces must be enclosed in double-quotes. Relative paths are resolved relative to the directory of the SWMM input file via `addAbsolutePath()`. On export the GUI emits a relative path wrapped in double-quotes (`Uexport.pas:1880–1881`).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The external file must itself contain lines in the same date–time–value or time–value format as direct inline entry, with one data point per line. Comment lines beginning with `;` and blank lines are silently skipped by `table_getNextFileEntry()` (`table.c:858–860`). The engine opens the file during the validation phase (`table_validate`, `table.c:298–300`) and reads it as a text file (`"rt"` mode). Failure to open the file returns `ERR_TABLE_FILE_OPEN` (code 361); failure to read returns `ERR_TABLE_FILE_READ` (code 363). The GUI validates at save time that the file exists (`Dtseries.pas:332–338`).
- **Source of truth:** `table.c:143–148`, `table.c:297–307`, `table.c:835–895`

## Notes

- **Multiple formats on the same line:** For Formats 1 and 2, the engine's while-loop continues consuming tokens after each triplet/pair, so a single row can contain many data points. The only limit is line length in the INP file. The GUI always emits one triplet per row.

- **Sticky date:** The date token is optional in Format 1. The parser (state machine in `table.c:155–202`) attempts to parse each new token as a date first; if it fails, the previous date is reused and the token is treated as a time. This means that for a given calendar date, only the first row where that date appears needs to carry the date string — all subsequent rows for the same day may omit it.

- **Elapsed vs. absolute time:** The two time-reference methods (calendar date + time-of-day versus elapsed hours since simulation start) are determined automatically by whether the time token is a valid calendar date string. There is no explicit keyword to select the mode; the engine infers the mode from whether a date token is successfully parsed before each time token.

- **Multiple rows per series name:** The same `Name` must appear as `tok[0]` on every row. The engine locates the already-registered series object by index during the second pass and appends data to it. The GUI similarly looks up the series by name in `Project.Lists[TIMESERIES]` (`Uimport.pas:2043–2044`).

- **Time ordering required:** The engine's `table_validate()` function (`table.c:285–327`) enforces strictly increasing x-values (time) across all entries. Violation returns `ERR_CURVE_SEQUENCE` (code 171). The GUI similarly checks ordering in `TTimeseriesForm.TimeOrdered` (`Dtseries.pas:350`).

- **Rainfall special case:** For rain-gage time series, SWMM treats each value as a constant rate lasting for the gage's recording interval. No interpolation is performed. For all other uses, SWMM linearly interpolates between recorded values. (Manual D.2, line 2433; Appendix C.23, line 52.)

- **External file format:** External files follow the same date–time–value or time–value format but permit only one data point per line. The file is read lazily at simulation time via `table_getNextFileEntry()`, not loaded into memory at startup (`table.c:831–895`).

- **Name uniqueness:** Within the section, each `Name` must be unique. The engine checks for duplicates during the first pass with `project_findObject` / `project_addObject` (`input.c:402–406`). The GUI enforces uniqueness in `ValidateData` (`Dtseries.pas:322–329`).

- **No GUI-visible comment field in the INP output:** The `TTimeseries.Comment` field is written as a comment line (prefixed with `;`) before the series rows by `ExportComment()` in `Uexport.pas:1877`. It does not appear as a parseable column and is not read back by the engine; it is only preserved by the GUI's own reader.

- **Cross-section references (consumers of `[TIMESERIES].Name`):**
  - `[RAINGAGES]` — `Tseries` field references a series name
  - `[EVAPORATION]` — `TIMESERIES Tseries` line
  - `[TEMPERATURE]` — `TIMESERIES Tseries` line
  - `[OUTFALLS]` — `Tseries` field for `TIMESERIES` outfall type
  - `[INFLOWS]` — `Tseries` field per node/pollutant inflow row
