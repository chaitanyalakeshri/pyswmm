# [RAINGAGES]

**Purpose:** Defines every rain gage object that supplies precipitation data to the study area. Each gage specifies the format of the rainfall record (intensity, volume, or cumulative volume), the time interval between readings, a snow-catch correction factor, and the data source (either an in-file time series or an external rainfall file with optional station ID, depth units, and start date). Subcatchments reference a gage by name, so the section must be present whenever any subcatchment is in the model.

**Occurrence:** One row per object. Each distinct rain gage occupies exactly one row. The row layout differs after column 5 depending on whether the data source is `TIMESERIES` or `FILE`.

**SWMM source references:**
- Engine parser: `swmm/swmm524_engine/src/gage.c:58` — function `gage_readParams`; dispatches to `readGageSeriesFormat` (line 133) or `readGageFileFormat` (line 168)
- Engine parser dispatch: `swmm/swmm524_engine/src/input.c:479` — `case s_RAINGAGE` in `parseLine`
- Engine report-echo: `swmm/swmm524_engine/src/inputrpt.c:95` — "Raingage Summary" block (not an INP writer; echoes Name, Data Source, Data Type, Recording Interval to the .rpt file)
- GUI reader: `swmm/swmm524_gui/Epaswmm5/Uimport.pas:330` — function `ReadRaingageData`; sub-procedures `ReadOldRaingageData` (line 275) and `ReadNewRaingageData` (line 296)
- GUI writer: `swmm/swmm524_gui/Epaswmm5/Uexport.pas:158` — procedure `ExportRaingages`
- GUI editor dialog: `swmm/swmm524_gui/Epaswmm5/objprops.txt:681` — `RaingageProps` array (Property Editor definition)
- Manual: `swmm/swmm-users-manual-version-5.2/appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [RAINGAGES] (lines 396–427)
- Additional manual refs:
  - `appendix_B_visual_object_properties/B.1_Rain_Gage_Properties.md` — GUI property list
  - `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md` — conceptual description (section 3.2.1)
  - `chapter_11_files_used_by_swmm/11.3_Rainfall_Files.md` — supported external rainfall file formats

## Row Format

Two mutually exclusive formats depending on the fifth token (`TIMESERIES` or `FILE`):

```
; TIMESERIES format:
Name  Form  Intvl  SCF  TIMESERIES  Tseries

; FILE format:
Name  Form  Intvl  SCF  FILE  Fname  (Sta  Units)
```

Column order emitted by GUI (`Uexport.pas:180–196`):
```
Name  GAGE_DATA_FORMAT  GAGE_DATA_FREQ  GAGE_SNOW_CATCH  GAGE_DATA_SOURCE  <source-dependent fields>
```

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-whitespace string; must be unique within the section. The engine uses prefix matching (`match()` in `input.c:798`) so names that are prefixes of other names can cause misidentification — avoid ambiguous names.
- **Default:** none
- **Cross-section dependency:** Referenced by `[SUBCATCHMENTS].Rgage` and `[HYDROGRAPHS]` (gage name on the header line).
- **Database-key hint:** primary identifier of this row
- **Technical description:** User-assigned label for the rain gage. The engine stores a pointer to the interned string (`Gage[j].ID`, `objects.h:119`). Duplicate names trigger `ERR_DUP_NAME` (`input.c:263`).
- **Source of truth:** `swmm/swmm524_engine/src/input.c:263` (duplicate check) and `swmm/swmm524_engine/src/gage.c:79` (ID lookup via `project_findID`).

---

### Form (RainType / GAGE_DATA_FORMAT)

- **Data type:** ENUM
- **Required:** yes
- **Units:** unitless
- **Valid values / range:**
  - `INTENSITY` — each value is an average rainfall rate in inches/hour or mm/hour over the recording interval
  - `VOLUME` — each value is the total depth of rain that fell during the recording interval (in or mm)
  - `CUMULATIVE` — each value is the cumulative rainfall since the start of the most recent non-zero sequence (in or mm); resets when the running total decreases
- **Default:** `INTENSITY` (GUI default from `objprops.txt:236`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Controls how raw values from the time series or file are converted to rainfall intensity (in/hr or mm/hr) inside `convertRainfall()` (`gage.c:674`). `RAINFALL_INTENSITY` passes values through unchanged; `RAINFALL_VOLUME` divides by the recording interval and multiplies by 3600; `CUMULATIVE_RAINFALL` computes the increment since the last stored cumulative total. Keywords are matched against `RainTypeWords[]` (`keywords.c:106`): `{"INTENSITY", "VOLUME", "CUMULATIVE", NULL}`. The engine enumerates these as `RAINFALL_INTENSITY`, `RAINFALL_VOLUME`, `CUMULATIVE_RAINFALL` (`enums.h:284–287`). When two gages share the same time series, both must have the same `rainType` or error `ERR_RAIN_GAGE_FORMAT` is issued (`gage.c:240`).
- **Source of truth:** `swmm/swmm524_engine/src/gage.c:141` (`readGageSeriesFormat`) and `swmm/swmm524_engine/src/gage.c:175` (`readGageFileFormat`), both call `findmatch(tok[1], RainTypeWords)`.

---

### Intvl (RecordingInterval / GAGE_DATA_FREQ)

- **Data type:** TEXT (parsed as decimal hours or HH:MM)
- **Required:** yes
- **Units:** hours (decimal) or HH:MM format; stored internally as seconds
- **Valid values / range:** Any positive value. May be entered as a decimal number (e.g., `0.25` = 15 min) or in hours:minutes format (e.g., `0:15`). Must be `> 0`. The GUI offers a preset list: `0:01`, `0:05`, `0:10`, `0:15`, `0:20`, `0:30`, `1:00`, `6:00`, `12:00`, `24:00` (`objprops.txt:690`).
- **Default:** `1:00` (GUI default from `objprops.txt:237`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The nominal spacing between successive rainfall records. The engine converts this to seconds: for decimal input `x[2] = floor(x * 3600 + 0.5)`; for HH:MM input `x[2] = floor(aTime * SECperDAY + 0.5)` (`gage.c:146–151`). Stored as `Gage[j].rainInterval` (integer, seconds). During validation, if the gage interval exceeds the minimum time-series interval, error `ERR_RAIN_GAGE_INTERVAL` is raised; if it is less, warning `WARN09` is issued (`gage.c:253–258`). If the interval is less than `WetStep`, warning `WARN01` fires and the wet-weather time step is reduced to match (`gage.c:260–263`). The FILE format uses a multiplied form (`x[2] *= 3600`) without rounding (`gage.c:180`).
- **Source of truth:** `swmm/swmm524_engine/src/gage.c:145–152` (series format) and `swmm/swmm524_engine/src/gage.c:179–185` (file format).

---

### SCF (SnowCatchFactor / GAGE_SNOW_CATCH)

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (dimensionless multiplier)
- **Valid values / range:** Any real; typically `> 0`. Use `1.0` for no adjustment. The GUI enforces a positive number (`Mask:emPosNumber`, `objprops.txt:692`).
- **Default:** `1.0` (GUI default `objprops.txt:238`; engine default `x[3] = 1.0` at `gage.c:87`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Snow catch deficiency correction factor. When the temperature is at or below the snowmelt threshold, the recorded rainfall is multiplied by this factor before being treated as snowfall: `*snowfall = Gage[j].rainfall * Gage[j].snowFactor / UCF(RAINFALL)` (`gage.c:516`). A factor greater than 1.0 corrects for under-catch of snow by the gage due to wind, etc.
- **Source of truth:** `swmm/swmm524_engine/src/gage.c:155–156` (parsing) and `gage.c:516` (use).

---

### DataSource (GAGE_DATA_SOURCE)

- **Data type:** ENUM
- **Required:** yes
- **Units:** n/a
- **Valid values / range:**
  - `TIMESERIES` — rainfall data come from an in-file `[TIMESERIES]` entry
  - `FILE` — rainfall data come from an external binary or text rainfall file
- **Default:** `TIMESERIES` (GUI default `objprops.txt:239`, engine array `GageDataWords[]` at `keywords.c:59`)
- **Cross-section dependency:** Determines which of the two subsequent column groups is present.
- **Database-key hint:** plain data – no key role
- **Technical description:** Selects the branch taken in `gage_readParams` (`gage.c:94–106`). The engine tests `tok[4]` against `GageDataWords[] = {"TIMESERIES", "FILE", NULL}` (`keywords.c:59`). If neither keyword matches, `ERR_KEYWORD` is returned (`gage.c:106`). After reading, `Gage[j].dataSource` is set to `RAIN_TSERIES` (0) or `RAIN_FILE` (1) (`enums.h:110–112`, `gage.c:116–117`). The GUI also uses this field to gate which property-editor rows are visible (TIMESERIES heading vs DATA FILE heading, `objprops.txt:695–701`).
- **Source of truth:** `swmm/swmm524_engine/src/gage.c:94` and `swmm/swmm524_engine/src/keywords.c:59`.

---

### Tseries (SeriesName / GAGE_SERIES_NAME) — TIMESERIES format only

- **Data type:** NAME_REF
- **Required:** yes, when `DataSource = TIMESERIES`
- **Units:** n/a
- **Valid values / range:** Must match an entry in `[TIMESERIES]`. The engine resolves the name via `project_findObject(TSERIES, tok[5])` and raises `ERR_NAME` if not found (`gage.c:159–160`).
- **Default:** none
- **Cross-section dependency:** `[TIMESERIES].Name`
- **Database-key hint:** foreign key to [TIMESERIES].Name
- **Technical description:** Name of the time series object that holds the rainfall values. Stored as an integer index in `Gage[j].tSeries` (`gage.c:111`). At validation, the engine checks that the referenced time series is not itself a file-backed series (`refersTo >= 0` would issue `ERR_RAIN_GAGE_TSERIES`) and that the recording intervals are compatible (`gage.c:247–258`). Multiple gages may reference the same time series; the second gage is made a "co-gage" (`coGage`) of the first so rainfall is read only once (`gage.c:231–244`). The GUI provides a dropdown populated from the project's `[TIMESERIES]` list (`objprops.txt:697`).
- **Source of truth:** `swmm/swmm524_engine/src/gage.c:157–163` (`readGageSeriesFormat`).

---

### Fname (FileName / GAGE_FILE_NAME / GAGE_FILE_PATH) — FILE format only

- **Data type:** TEXT
- **Required:** yes, when `DataSource = FILE`
- **Units:** n/a
- **Valid values / range:** Valid file system path. Enclose in double quotes if it contains spaces. May be a relative path (resolved relative to the INP file location via `addAbsolutePath()`, `gage.c:120`). The engine copies it into `Gage[j].fname` (length limit `MAXFNAME`).
- **Default:** none
- **Cross-section dependency:** None (references an external file, not another INP section)
- **Database-key hint:** plain data – no key role
- **Technical description:** Path to an external rainfall file. Supported formats include NCEI hourly/15-min text, older DS-3240/DS-3260 formats, Canadian HLY03/HLY21/FIF21 formats, and a standard user-prepared format (station, year, month, day, hour, minute, precipitation) — see `chapter_11/11.3_Rainfall_Files.md`. The GUI wraps the stored full path in quotes during export and converts it to a relative path (`Uexport.pas:191`). The GUI stores the full path in `GAGE_FILE_PATH` (index 15) and the bare filename in `GAGE_FILE_NAME` (index 12) for display purposes (`Uimport.pas:358–359`).
- **Source of truth:** `swmm/swmm524_engine/src/gage.c:102–103` and `gage.c:118–121`.

---

### Sta (StationID / GAGE_STATION_NUM) — FILE format, optional

- **Data type:** TEXT
- **Required:** no (default: `*`)
- **Units:** n/a
- **Valid values / range:** Alphanumeric station identifier string. Required only when using a user-prepared formatted rainfall file; ignored for NCEI and Canadian format files. The engine copies it into `Gage[j].staID` (length limit `MAXMSG`, `gage.c:122–123`). The GUI default is `'*'` (`objprops.txt:244`).
- **Default:** `*` (wildcard — matches any station in the file)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Identifies which station's records to extract from the external file. In user-prepared files a single file may contain data for multiple stations. When set to `*`, SWMM matches the first station encountered. Only applicable when `DataSource = FILE`. The manual notes: "The station name and depth units entries are only required when using a user-prepared formatted rainfall file" (`D.2_Input_File_Format.md:426`).
- **Source of truth:** `swmm/swmm524_engine/src/gage.c:103` and `swmm/swmm524_engine/src/gage.c:122–123`.

---

### Units (RainUnits / GAGE_RAIN_UNITS) — FILE format, optional

- **Data type:** ENUM
- **Required:** no (default: `IN`)
- **Units:** n/a (this field specifies the unit, not a quantity)
- **Valid values / range:**
  - `IN` — rainfall depths in the file are in inches
  - `MM` — rainfall depths in the file are in millimeters
  - Keywords from `RainUnitsWords[] = {"IN", "MM", NULL}` (`keywords.c:107`); GUI list identical (`objprops.txt:702`).
- **Default:** `IN` (GUI default `objprops.txt:245`; engine array position 0)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Tells the engine the depth units stored in a user-prepared rainfall file. Only used when `DataSource = FILE`. Stored as `Gage[j].rainUnits` (`objects.h:128`). The engine uses this to set `Gage[j].unitsFactor` so that all rainfall values are stored internally in project units. For NCEI and standard binary rainfall interface files, units are fixed by the file format. The manual states this field is only required for user-prepared files (`D.2_Input_File_Format.md:426`); it is optional for NCEI format files.
- **Source of truth:** `swmm/swmm524_engine/src/gage.c:193–194` (`readGageFileFormat`).

## Notes

- **Two distinct INP row formats share the same section.** The fifth token determines layout: `TIMESERIES` produces a 6-token row `(Name Form Intvl SCF TIMESERIES Tseries)`; `FILE` produces an 8-token row with two optional trailing tokens `(Name Form Intvl SCF FILE Fname Sta Units)`. The engine minimum for FILE is 8 tokens (`gage.c:101`). The GUI exports the FILE format with all three source-specific columns (Fname, Sta, Units) always present (`Uexport.pas:191–194`).
- **Legacy / old format compatibility.** The GUI `ReadRaingageData` (`Uimport.pas:352`) first tries to interpret token[1] as a data-source keyword (`RaingageOptions`). If it matches, it falls into `ReadOldRaingageData`, which reads in the pre-5.x column order: `(Name Source SeriesName Format Interval)`. If it does not match, `ReadNewRaingageData` is called, which expects the current canonical order. This means old-style INP files with the source keyword in column 2 are still accepted by the GUI.
- **Section keyword prefix matching.** The engine section keyword for this section is `ws_RAINGAGE = "[RAINGAGE"` (`text.h:406`). Because `match()` uses prefix matching, `[RAINGAGES]` (with the trailing "S") and `[RAINGAGE]` are both accepted — the engine matches the first characters.
- **Duplicate name detection.** Each gage name must be unique. Duplicates cause `ERR_DUP_NAME` at the counting pass (`input.c:263`).
- **Co-gage sharing.** When two or more gages reference the same time series, the engine assigns a `coGage` index to all but the first (`gage.c:226–244`). The co-gage adopts the rainfall value of the primary gage each time step, avoiding redundant time series reads. Both gages must have the same `rainType`; a mismatch triggers `ERR_RAIN_GAGE_FORMAT`.
- **Unused gage validation skip.** Gages not referenced by any subcatchment have `isUsed = FALSE` and skip validation (`gage.c:226`). No error is raised for an unreferenced gage.
- **Wet-weather time step interaction.** If `rainInterval < WetStep`, the global wet-weather time step is automatically reduced to match, with warning `WARN01` (`gage.c:260–263`, `text.h:46`). If the time series minimum interval is finer than `rainInterval`, warning `WARN09` fires (`gage.c:256–258`, `text.h:54`).
- **Start-date column (FILE format).** The engine `readGageFileFormat` also reads an optional ninth token (`tok[8]`) as a start date (`gage.c:198–204`), stored in `Gage[j].startFileDate`. This column is not documented in the D.2 manual section but is present in the engine source and stored in `objects.h:124`. The GUI does not write this column.
- **Uniqueness and ordering.** Each gage name must appear exactly once. Section ordering relative to other sections is unrestricted (the engine makes two passes; gages are counted first, then parsed). However, the time series referenced by a gage must be defined in `[TIMESERIES]` — it is resolved at parse time (`gage.c:159`), so `[TIMESERIES]` must have already been counted (first pass) before `[RAINGAGES]` is parsed (second pass), which is satisfied because both passes read the whole file.
- **No continuation lines.** Each gage is exactly one line; there are no sub-rows or multi-line entries.
