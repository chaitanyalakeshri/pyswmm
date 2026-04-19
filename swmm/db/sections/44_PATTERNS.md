# [PATTERNS]

**Purpose:** Defines named time patterns of periodic multiplier factors that are applied to baseline dry weather flow (DWF) rates or pollutant concentrations. Four pattern types are supported: MONTHLY (12 factors, one per calendar month), DAILY (7 factors, one per day of week), HOURLY (24 factors, one per hour of day), and WEEKEND (24 hourly factors applied specifically to weekend days). The resulting multiplier at any simulation time step is the product of all applicable pattern factors assigned to a given DWF inflow. Monthly patterns are also used outside DWF to adjust subcatchment depression storage, pervious surface roughness, soil infiltration recovery rate, and groundwater evaporation rate.

**Occurrence:** Multiple rows per object — a single named pattern spans one or more input lines. The first line carries `Name`, `Type`, and as many multiplier values as fit; continuation lines carry `Name` only (Type is omitted) followed by additional values. There is no limit on the number of patterns. Each pattern name must be unique.

**SWMM source references:**
- Engine parser: `input.c:375` — first pass registers the object (`s_PATTERN` case); `input.c:583` — second pass dispatches to function `inflow_readDwfPattern`; `inflow.c:410` — function `inflow_readDwfPattern`
- Engine writer: Engine does not write INP files. No pattern-specific echo exists in `inputrpt.c`.
- GUI reader: `Uimport.pas:1832` — function `ReadPatternData`
- GUI writer: `Uexport.pas:1812` — procedure `ExportPatterns`
- GUI editor dialog(s): `Dpattern.pas` — `TPatternForm` dialog (type combo, multiplier grid)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[PATTERNS]` at line 2438
- Additional manual refs: Chapter 3 `3.3_Non-Visual_Objects.md` §3.3.15 "Time Patterns"; Appendix C `C.22_Time_Pattern_Editor.md`

## Row Format

**First line of each pattern:**
```
Name  Type  Factor1  Factor2  ...  FactorN
```

**Continuation lines (same pattern, additional factors):**
```
Name  Factor_next  Factor_next+1  ...
```

On a continuation line the type keyword is absent; the engine detects this because `Pattern[j].ID` is already set from the first line (`inflow.c:432`). The GUI writes 6 values per line for MONTHLY/HOURLY/WEEKEND and 7 per line for DAILY, then wraps onto continuation lines as needed (`Uexport.pas:1835–1848`).

The manual states the canonical full-line forms explicitly (`D.2_Input_File_Format.md:2446–2452`):
```
Name  MONTHLY  Factor1 Factor2 ... Factor12
Name  DAILY    Factor1 Factor2 ... Factor7
Name  HOURLY   Factor1 Factor2 ... Factor24
Name  WEEKEND  Factor1 Factor2 ... Factor24
```

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-whitespace string; must be unique across all patterns. Maximum storage is 24 `double` factors (`objects.h:424`), so the name itself has no enforced length limit in the engine beyond general token limits.
- **Default:** none
- **Cross-section dependency:** Referenced by `[DWF]` (up to four patterns per inflow entry); also referenced by `[ADJUSTMENTS]`, `[AQUIFERS]`, and subcatchment N-PERV/DSTORE/INFIL climate adjustment entries.
- **Database-key hint:** Primary identifier of this row; used as foreign key from `[DWF].Pat1`–`Pat4` and climate adjustment references.
- **Technical description:** The pattern name is registered in the engine's TIMEPATTERN object array during the first parse pass (`input.c:377–382`). On continuation lines the same name must appear as token[0]; the engine looks up the existing object by name (`inflow.c:427`) rather than creating a new one. The GUI performs an `IndexOf` check and reuses the existing `TPattern` object when the name already exists (`Uimport.pas:1848–1864`).
- **Source of truth:** `input.c:375–382` (registration); `inflow.c:427–428` (lookup on all lines)

### Type

- **Data type:** ENUM
- **Required:** yes (first line only; omitted on continuation lines)
- **Units:** n/a
- **Valid values / range:**
  - `MONTHLY` — 12 monthly factors (Jan–Dec)
  - `DAILY` — 7 daily factors (Sun=day 1 through Sat)
  - `HOURLY` — 24 hourly factors (midnight hour 0 through 11 PM hour 23)
  - `WEEKEND` — 24 hourly factors applied only to weekend days (Sat/Sun)
- **Default:** none (required on first line; continuation lines must not include it)
- **Cross-section dependency:** None
- **Database-key hint:** Composite PK with Name — determines the count and semantics of all factor fields.
- **Technical description:** The keyword is matched against `PatternTypeWords[]` = `{"MONTHLY","DAILY","HOURLY","WEEKEND", NULL}` (`keywords.c:101`). The resulting integer (`MONTHLY_PATTERN=0`, `DAILY_PATTERN=1`, `HOURLY_PATTERN=2`, `WEEKEND_PATTERN=3`) is stored in `Pattern[j].type` (`inflow.c:438`). The engine uses this value in `getPatternFactor` to index into `factor[]` by month (0–11), day of week (0–6), or hour (0–23) (`inflow.c:465–477`). WEEKEND pattern replaces HOURLY on Saturdays and Sundays (`inflow.c:379–385`). The type is detected on the first line by testing whether `Pattern[j].ID == NULL`; if ID is already set the current line is treated as a continuation and no type token is expected (`inflow.c:432–439`). The GUI validates against the 4-element `PatternTypes` array (`objprops.txt:168–169`; `Uimport.pas:1855`). The groundwater module rejects a non-MONTHLY pattern referenced for the upper evaporation adjustment (`gwater.c:351`). Similarly, monthly adjustment functions in `climate.c` and `subcatch.c` check `Pattern[p].type == MONTHLY_PATTERN` before using the factor (`climate.c:915`; `subcatch.c:1142,1151`).
- **Source of truth:** `keywords.c:101`; `inflow.c:436–438`; `enums.h:383–387`

### Factor1 … FactorN

- **Data type:** REAL
- **Required:** no (default: `1.0`)
- **Units:** unitless (dimensionless multiplier)
- **Valid values / range:** Any real number; the engine calls `getDouble` without range checking (`inflow.c:446`). The manual recommends factors average to 1.0 to preserve the baseline value (`C.22_Time_Pattern_Editor.md`).
- **Default:** `1.0` — the engine initialises all 24 slots to 1.0 before reading (`inflow.c:402`); the GUI initialises all Data[] entries to `'1.0'` (`Uproject.pas:2087`).
- **Cross-section dependency:** None directly; the product of matching factors from up to four patterns is applied to the baseline rate in `[DWF]`.
- **Database-key hint:** Plain data – no key role.
- **Technical description:** The engine stores up to 24 `double` values in `Pattern[j].factor[0..23]` regardless of pattern type (`objects.h:423–424`). The `count` field tracks how many have been supplied (`objects.h:423`). Reading stops when 24 slots are filled (`inflow.c:443`). Expected counts by type: MONTHLY=12, DAILY=7, HOURLY=24, WEEKEND=24 (`D.2_Input_File_Format.md:2446–2452`). Fewer factors than expected are silently accepted; the unset slots remain at 1.0. Values may span multiple input lines by repeating the pattern name without the type keyword. The GUI writes 6 values per continuation row for MONTHLY/HOURLY/WEEKEND, and 7 per row for DAILY (`Uexport.pas:1835`), though the engine imposes no per-line limit. At runtime, `getPatternFactor` retrieves the factor for the appropriate time index and returns it as a multiplier; the calling routine (`inflow_getDwfInflow`) multiplies all applicable pattern factors together (`inflow.c:374–385`).
- **Source of truth:** `inflow.c:443–450` (reading loop); `inflow.c:402` (initialisation); `objects.h:423–425` (struct)

## Notes

- A pattern's factors may be spread across as many input lines as needed. Each continuation line begins with the pattern name (token[0]) but must NOT include the type keyword; the engine differentiates first versus continuation lines by checking whether `Pattern[j].ID == NULL` (`inflow.c:432`).
- The maximum number of storable factors is hard-coded to 24 (`factor[24]` in `objects.h:424`; loop guard at `inflow.c:443`). Supplying more than 24 factors on the input lines silently discards the excess.
- DAILY patterns index Sunday as day 0 (or "day 1" in the manual's 1-based wording), Monday as day 1, …, Saturday as day 6 (`D.2_Input_File_Format.md:2470`; `inflow.c:471`).
- HOURLY patterns start at midnight (hour 0) through 11 PM (hour 23) (`D.2_Input_File_Format.md:2472`; `inflow.c:474`).
- WEEKEND pattern factors override the HOURLY pattern on weekend days. Both may be present simultaneously for the same DWF inflow; the engine picks WEEKEND on Saturdays and Sundays and HOURLY otherwise (`inflow.c:378–385`).
- Each DWF inflow entry in `[DWF]` can reference up to four patterns (one of each type). The engine internally reorders them by type after parsing to speed lookup (`inflow.c:331–357`).
- Monthly patterns have uses beyond DWF: they are the only type accepted by the groundwater upper evaporation adjustment (`gwater.c:351`), climate adjustments (`climate.c:915`), and subcatchment N-PERV/DSTORE/INFIL monthly overrides (`subcatch.c:1142,1151`).
- Pattern names must be unique across all TIMEPATTERN objects; duplicate names cause `ERR_DUP_NAME` during the first parse pass (`input.c:379–381`).
- The GUI separates consecutive patterns in the exported INP with a semicolon-only comment line (`Uexport.pas:1850`) for readability; this is not parsed by the engine.
- No ordering constraint exists between patterns in the section; the engine resolves references by name at object-initialisation time.
