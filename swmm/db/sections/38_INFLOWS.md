# [INFLOWS]

**Purpose:** Specifies external hydrograph and pollutograph inflows that enter the drainage network at specific nodes. Each row assigns a time-varying plus constant baseline inflow of either flow (FLOW) or a named pollutant to a junction, outfall, storage, or divider node. The actual inflow at each time step is computed as: `Inflow = cf * (sf * TimeSeriesValue + BaselineValue * PatternFactor)`, where `cf` is the units-conversion factor, `sf` is the scaling factor, and the optional time pattern modulates the baseline on a periodic basis.

**Occurrence:** Multiple rows per object — a node may have one row for FLOW and one additional row per pollutant constituent; the combination (Node, Constituent) must be unique within the section.

**SWMM source references:**
- Engine parser: `inflow.c:41` — function `inflow_readExtInflow`; dispatch in `input.c:577`
- Engine writer: No INP writer in the engine. The presence of external inflow is echoed to the report file (`inputrpt.c:173`) as a `Yes` flag in the node summary table but the full inflow data is not reprinted.
- GUI reader: `Uimport.pas:1760` — procedure `ReadExInflowData`; registered at `Uimport.pas:2912`
- GUI writer: `Uexport.pas:1676` — procedure `ExportInflows`; writes `[INFLOWS]` header at `Uexport.pas:1692`
- GUI editor dialog: `Dinflows.pas` / `Dinflows.dfm` — "Direct Inflows" tab of the `TInflowsForm` node-inflow editor (three-tab dialog also covering DWF and RDII)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[INFLOWS]` starting at line 2198
- Additional manual refs: See Appendix B node-property `Inflows` and the remarks at D.2 lines 2228–2247 for the formula and the outfall-specific note.

## Row Format

The section supports two line variants:

```
Node  FLOW      TimeSeries  (FLOW    1.0        Sfactor  Baseline  BaselinePat)
Node  Pollutant TimeSeries  (Type    UnitsFactor Sfactor  Baseline  BaselinePat)
```

Columns 1–3 are always required (though `TimeSeries` may be an empty string `""`). Columns 4–8 are optional trailing fields with defined defaults. The GUI emits columns in the order shown in `Uexport.pas:1693–1695`:

```
Node  Constituent  TimeSeries  Type  Mfactor  Sfactor  Baseline  Pattern
```

## Fields

### Node

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match a node name defined in `[JUNCTIONS]`, `[OUTFALLS]`, `[STORAGE]`, or `[DIVIDERS]`. The engine searches with `project_findObject(NODE, tok[0])`; an unrecognised name produces `ERR_NAME`.
- **Default:** none
- **Cross-section dependency:** `[JUNCTIONS].Name`, `[OUTFALLS].Name`, `[STORAGE].Name`, or `[DIVIDERS].Name`
- **Database-key hint:** composite PK with Constituent (foreign key to [JUNCTIONS/OUTFALLS/STORAGE/DIVIDERS].Name)
- **Technical description:** Identifies the node receiving the external inflow. The engine attaches a linked list of `TExtInflow` objects to `Node[j].extInflow` (`objects.h:502`), one per distinct constituent. If the same (Node, Constituent) pair appears more than once, the second entry overwrites the first (`inflow.c:154–182`).
- **Source of truth:** `inflow.c:64–65`

### Constituent

- **Data type:** TEXT (keyword `FLOW`) or NAME_REF (pollutant name)
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** The literal keyword `FLOW` (case-insensitive prefix match via `match()`) sets `param = -1` for a flow inflow. Any other value must be the name of a pollutant declared in `[POLLUTANTS]`; the engine looks it up with `project_findObject(POLLUT, tok[1])`. An unrecognised string that is neither `FLOW` nor a known pollutant name produces `ERR_NAME`.
- **Default:** none
- **Cross-section dependency:** `[POLLUTANTS].Name` when not `FLOW`
- **Database-key hint:** composite PK with Node
- **Technical description:** Stored internally as an integer index (`param` field of `TExtInflow`, `objects.h:432`): `-1` for FLOW, or the zero-based pollutant index. The GUI labels this column "Constituent" in the export header (`Uexport.pas:1693`) and populates a combo box from `[FLOW] + project pollutant list` (`Dinflows.pas:485–487`).
- **Source of truth:** `inflow.c:68–73`

### TimeSeries

- **Data type:** NAME_REF
- **Required:** no (default: none — omitting or supplying an empty string `""` means no time-series component)
- **Units:** flow units (for FLOW constituent); pollutant mass or concentration units (for pollutant constituent)
- **Valid values / range:** Name of a time series defined in `[TIMESERIES]`. May be an empty token or the two-character literal `""` to indicate "no time series." The engine checks `strlen(tok[2]) > 0` before resolving; an empty string leaves `tSeries = -1` so the time-series component contributes zero (`inflow.c:76–81`, `inflow.c:231`). A non-empty string that does not match a known time series produces `ERR_NAME`. Upon successful lookup the engine stamps `Tseries[tseries].refersTo = EXTERNAL_INFLOW` (`inflow.c:80`).
- **Default:** none (empty → no time-series component)
- **Cross-section dependency:** `[TIMESERIES].Name`
- **Database-key hint:** foreign key to [TIMESERIES].Name (nullable)
- **Technical description:** Recorded in `TExtInflow.tSeries` (`objects.h:434`). At each routing time step `inflow_getExtInflow()` calls `table_tseriesLookup()` with this index, multiplies the looked-up value by `sFactor`, and adds it to the baseline term (`inflow.c:231`). If `tSeries == -1` (no series), `tsv = 0.0` and only the baseline contributes.
- **Source of truth:** `inflow.c:76–81`

### Type

- **Data type:** ENUM
- **Required:** no (default: `CONCEN` for pollutant rows; implicitly `FLOW` for the FLOW constituent row)
- **Units:** unitless
- **Valid values / range:**
  - `FLOW` — used internally for the FLOW-constituent row; the engine sets `type = FLOW_INFLOW` automatically when `param == -1`, so writing `FLOW` here on a FLOW row is conventional but redundant (`inflow.c:84–88`). The GUI always writes `FLOW` for the FLOW row (`Dinflows.pas:511`).
  - `CONCEN` — pollutant inflow expressed as a concentration (project units). Default for all pollutant rows (`inflow.c:55`, `Dinflows.pas:512`). GUI default shown in `Dinflows.dfm:126,129`.
  - `MASS` — pollutant inflow expressed as a mass flow rate. Requires UnitsFactor to convert to project mass-per-second units.
  - Matching is case-insensitive prefix (`match()`) against `w_CONCEN` and `w_MASS` (`inflow.c:93–94`). An unrecognised keyword produces `ERR_KEYWORD`.
- **Default:** `CONCEN` (for pollutant rows); `FLOW` (for FLOW row, set automatically)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Stored as `TExtInflow.type` (`objects.h:433`). During routing, `CONCEN_INFLOW` multiplies the computed pollutant value by the node's total flow inflow to yield a mass load (`routing.c:487`). `MASS_INFLOW` is treated directly as a mass-per-second load. `FLOW_INFLOW` adds to the node's lateral flow.
- **Source of truth:** `inflow.c:53–95`

### UnitsFactor

- **Data type:** REAL
- **Required:** no (default: `1.0`; for FLOW rows the value is always treated as `1.0` and is ignored)
- **Units:** converts user-supplied mass flow rate units into project mass-per-second units (US: mg/s; SI: mg/s)
- **Valid values / range:** `> 0`. The engine validates with `cf > 0.0` and rejects zero or negative values with `ERR_NUMBER` (`inflow.c:101–102`). Only parsed when `type == MASS_INFLOW` and `ntoks >= 5` (`inflow.c:96–103`); otherwise the stored value is `1.0`.
- **Default:** `1.0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Called `Mfactor` in the GUI export header (`Uexport.pas:1694`) and `unitsFactor` in the manual. Stored internally as `TExtInflow.cFactor` (`objects.h:436`). For `MASS_INFLOW` rows an additional factor of `1/LperFT3` (= 1/28.317) is applied by the engine (`inflow.c:130`, `consts.h:87`) to convert from the US internal volume base (ft³) to litres. This means `cFactor` as stored already embeds both the user-supplied conversion and the litre-per-cubic-foot factor. For `CONCEN_INFLOW` rows `cFactor` is left at its initial `1.0`. For `FLOW_INFLOW` rows `cFactor` is set to `1/UCF(FLOW)` to convert the time-series value from the project flow units into internal cfs (`inflow.c:87`); the field in the INP is meaningless for FLOW rows and the GUI always writes `1.0`.
- **Source of truth:** `inflow.c:96–103`, `inflow.c:129–130`

### Sfactor

- **Data type:** REAL
- **Required:** no (default: `1.0`)
- **Units:** unitless (dimensionless multiplier applied to the raw time-series values)
- **Valid values / range:** Any real number; no explicit range restriction in the engine. Parsed from `tok[5]` when `ntoks >= 6` (`inflow.c:107–112`). The GUI defaults to `1.0` (`Dinflows.pas:516`).
- **Default:** `1.0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Stored as `TExtInflow.sFactor` (`objects.h:438`). Multiplied against each looked-up time-series value: `tsv = table_tseriesLookup(...) * sf` (`inflow.c:231`). Allows users to scale an existing time series without modifying it. Has no effect if no time series is supplied (`tSeries == -1`).
- **Source of truth:** `inflow.c:107–112`

### Baseline

- **Data type:** REAL
- **Required:** no (default: `0.0`)
- **Units:** same units as the time series (flow units for FLOW rows; concentration or mass-rate units for pollutant rows, before internal conversion)
- **Valid values / range:** Any real number; `≥ 0` is physically meaningful but the engine imposes no lower-bound check. Parsed from `tok[6]` when `ntoks >= 7` (`inflow.c:114–119`).
- **Default:** `0.0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Stored as `TExtInflow.baseline` (`objects.h:437`). Added to the scaled time-series value after optional multiplication by the baseline time-pattern factor: `cf * (tsv + blv * patternFactor)` (`inflow.c:228–232`). Enables a constant floor inflow even when the time series is zero or absent. The GUI hint text confirms: "If Baseline or Time Series is left blank its value is 0" (`Dinflows.pas:141–143`).
- **Source of truth:** `inflow.c:114–119`

### BaselinePat

- **Data type:** NAME_REF
- **Required:** no (default: none — no pattern applied)
- **Units:** n/a
- **Valid values / range:** Name of a time pattern defined in `[PATTERNS]`. The engine resolves with `project_findObject(TIMEPATTERN, tok[7])`; an unrecognised name produces `ERR_NAME` (`inflow.c:124–127`). An empty or absent token leaves `basePat = -1`.
- **Default:** none (no modulation of baseline)
- **Cross-section dependency:** `[PATTERNS].Name`
- **Database-key hint:** foreign key to [PATTERNS].Name (nullable)
- **Technical description:** Stored as `TExtInflow.basePat` (`objects.h:435`). At each routing time step `inflow_getExtInflow()` evaluates the time pattern at the current month/day/hour and multiplies it against the baseline value (`inflow.c:224–229`). Any pattern type (MONTHLY, DAILY, HOURLY, WEEKEND) is valid; `getPatternFactor()` dispatches on `Pattern[p].type` (`inflow.c:456–484`). The GUI hint confirms that an absent pattern "defaults to a constant factor of 1.0" (`Dinflows.pas:145–146`).
- **Source of truth:** `inflow.c:122–127`

## Notes

- **Constituent uniqueness per node:** The engine uses a singly-linked list (`TExtInflow.next`, `objects.h:439`) keyed on the `param` index. If a second row with the same (Node, Constituent) pair appears, the engine reuses the existing `TExtInflow` node and overwrites all its fields (`inflow.c:154–182`). A DB design should treat (Node, Constituent) as a composite primary key and enforce uniqueness.

- **Time series may be absent:** `TimeSeries` may be an empty token or the literal `""`. The engine tests `strlen(tok[2]) > 0` (`inflow.c:76`) before looking up the series. This allows a pure constant-baseline inflow without any time series. The GUI writes `""` when the field is empty (`Uexport.pas:1714`).

- **FLOW constituent is mandatory for CONCEN pollutant inflows:** If a node receives a pollutant inflow of type `CONCEN`, it must also receive a FLOW inflow at that same node (so there is a carrier flow to carry the concentration). The one exception is an Outfall node, where reverse flow can occur and carry pollutant concentration inward without a separately declared FLOW inflow (manual, D.2 line 2236–2238). `MASS`-type pollutant inflows do not require a FLOW inflow.

- **FLOW inflow type column handling:** For FLOW constituent rows the engine ignores token[3] (Type) — it sets `type = FLOW_INFLOW` automatically at `inflow.c:84–88` — and also ignores token[4] (UnitsFactor), instead computing `cf = 1/UCF(FLOW)` to convert to internal cfs. The GUI always writes `FLOW` and `1.0` in those columns anyway (`Dinflows.pas:511`, `Dinflows.pas:515`).

- **Internal units conversion formula:** For MASS inflows the stored `cFactor` is `userMfactor / LperFT3` (28.317 L/ft³, `consts.h:87`). For FLOW inflows `cFactor = 1/UCF(FLOW)`. For CONCEN inflows `cFactor = 1.0`. The combined inflow value returned by `inflow_getExtInflow()` is always in internal units (cfs for flow, mg/L·cfs or mg/s for quality) (`inflow.c:207–233`).

- **Node type scope:** The GUI iterates `JUNCTION` through `STORAGE` when exporting (`Uexport.pas:1701`), which covers all four node types: junction, outfall, storage, and divider (`enums.h:71–74`).

- **Multiple pollutants per node:** A node may have one FLOW row and one row per pollutant in `[POLLUTANTS]`, giving up to N+1 rows per node (N = number of pollutants).

- **Section keyword prefix match:** The section header `[INFLOWS]` is matched as prefix `[INFLOW` (`text.h:433`), so `[INFLOWS]` and even a truncated `[INFLOW]` are accepted.

- **Ordering:** The GUI writes FLOW first (column 0 in the hidden grid, `Dinflows.pas:485`), then pollutants in the order they appear in the project pollutant list. The engine imposes no ordering requirement.
