# [OUTFALLS]

**Purpose:** Defines each outfall node — the terminal downstream boundary of the drainage network. An outfall sets the hydraulic boundary condition (stage elevation) for flow exiting the model. Five boundary condition types are supported (FREE, NORMAL, FIXED, TIDAL, TIMESERIES), each imposing a different rule for computing the water-surface elevation at the outlet. Optionally, outfall discharge can be re-routed onto the surface of a named subcatchment, allowing inter-model water routing. Under Dynamic Wave routing these nodes enforce the specified stage; under Steady Flow and Kinematic Wave they behave as ordinary junctions.

**Occurrence:** One row per object. Each outfall occupies exactly one row. The column layout varies by type: FREE and NORMAL have no data column; FIXED, TIDAL, and TIMESERIES each have one extra data column before the optional trailing columns.

**SWMM source references:**
- Engine parser: `swmm/swmm524_engine/src/input.c:523` — dispatches via `readNode(OUTFALL)` → `node_readParams` → `outfall_readParams`; core parsing at `swmm/swmm524_engine/src/node.c:1333` — function `outfall_readParams`
- Engine writer: The engine does not write INP. No INP-echo function exists in `inputrpt.c` for this section.
- GUI reader: `Uimport.pas:889` — function `ReadOutfallData`
- GUI writer: `Uexport.pas:849` — procedure `ExportOutfalls`
- GUI editor dialog(s): `objprops.txt:752` — `OutfallProps` array (property editor definition, no separate dialog form for outfall nodes)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [OUTFALLS] (lines 1144–1170)
- Additional manual refs: `appendix_B_visual_object_properties/B.4_Outfall_Properties.md`; `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md` (section 3.2.4)

## Row Format

The exact column layout depends on the outfall type. Parenthesised columns are optional.

```
Name  Elev  FREE        (Gated) (RouteTo)
Name  Elev  NORMAL      (Gated) (RouteTo)
Name  Elev  FIXED   Stage   (Gated) (RouteTo)
Name  Elev  TIDAL   Tcurve  (Gated) (RouteTo)
Name  Elev  TIMESERIES  Tseries  (Gated) (RouteTo)
```

Minimum tokens: 3 (Name, Elev, Type). For FIXED/TIDAL/TIMESERIES the data column (token 4) is required. Gated and RouteTo are always optional trailing tokens.

The GUI writer emits all six columns always, padding the data column with spaces when the type is FREE or NORMAL: `swmm/swmm524_gui/Epaswmm5/Uexport.pas:885–892`.

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-whitespace string; must be unique across all nodes (junctions, outfalls, dividers, storage units share the same NODE namespace).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** primary identifier of this row
- **Technical description:** User-assigned label for the outfall node. Parsed as token 0. The engine looks this up in the global NODE object table via `project_findID(NODE, tok[0])`. Duplicate names across any node type trigger `ERR_DUP_NAME`.
- **Source of truth:** `swmm/swmm524_engine/src/node.c:1355` (lookup); `swmm/swmm524_engine/src/input.c:307–312` (registration during first-pass count)

---

### Elev

- **Data type:** REAL
- **Required:** yes
- **Units:** ft (US) / m (SI)
- **Valid values / range:** any real (negative elevations are permitted for below-datum systems)
- **Default:** `0` (GUI default from `objprops.txt:343`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Invert elevation of the outfall node. Stored internally in feet after division by `UCF(LENGTH)`. This elevation is the datum from which the computed stage depth is measured. For FIXED, TIDAL, and TIMESERIES types the reported stage is an absolute elevation; the node depth is computed as `stage − invertElev`. For FREE and NORMAL types the depth is derived from the connecting conduit's hydraulic properties.
- **Source of truth:** `swmm/swmm524_engine/src/node.c:1358` (parsed as `x[0]`); stored at `node.c:156–162` as `Node[j].invertElev` via `node_setParams`

---

### Type

- **Data type:** ENUM
- **Required:** yes
- **Units:** unitless
- **Valid values / range:**
  - `FREE` — outfall stage set to minimum of critical and normal flow depth in the connecting conduit
  - `NORMAL` — outfall stage set to normal flow depth in the connecting conduit
  - `FIXED` — outfall stage held at a constant user-specified elevation
  - `TIDAL` — outfall stage read from a tidal curve (water elevation vs. hour-of-day)
  - `TIMESERIES` — outfall stage supplied by a time series of water elevations
- **Default:** `FREE` (GUI default `objprops.txt:346`; also the fallback when an unrecognised keyword is encountered at `Uimport.pas:913`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Selects the hydraulic boundary condition type. Internally mapped to the `OutfallType` enum (`enums.h:389–394`): `FREE_OUTFALL=0`, `NORMAL_OUTFALL=1`, `FIXED_OUTFALL=2`, `TIDAL_OUTFALL=3`, `TIMESERIES_OUTFALL=4`. This field controls both which subsequent data column is required and how `outfall_setOutletDepth` computes the node's water depth at each routing time step (`node.c:1413–1490`). Under FREE and NORMAL routing, the outfall type only matters under Dynamic Wave; under other routing methods the node is treated as a junction. The GUI uses `OutfallOptions` (`objprops.txt:186–192`) to populate the Type dropdown.
- **Source of truth:** `swmm/swmm524_engine/src/node.c:1360–1361` (keyword match via `OutfallTypeWords`); `swmm/swmm524_engine/src/keywords.c:99–100` (keyword array `OutfallTypeWords`)

---

### Stage  *(FIXED type only — token 4)*

- **Data type:** REAL
- **Required:** yes, when Type = `FIXED`; absent for all other types
- **Units:** ft (US) / m (SI)
- **Valid values / range:** any real (must be a valid elevation in the model's coordinate system)
- **Default:** `0` (GUI default `objprops.txt:348`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Fixed water-surface elevation imposed at the outfall for every routing time step. Stored as `Outfall[k].fixedStage` (in feet) after unit conversion. During dynamic wave routing, `outfall_setOutletDepth` sets `stage = Outfall[i].fixedStage` and derives node depth as `stage − invertElev` when the fixed stage exceeds the critical-depth elevation (`node.c:1442–1444`). If the token cannot be parsed as a number the engine returns `ERR_NUMBER`.
- **Source of truth:** `swmm/swmm524_engine/src/node.c:1376–1378` (parsing); `node.c:158` (stored in struct); `node.c:1442–1444` (used at runtime)

---

### Tcurve  *(TIDAL type only — token 4)*

- **Data type:** NAME_REF
- **Required:** yes, when Type = `TIDAL`; absent for all other types
- **Units:** n/a (reference)
- **Valid values / range:** Must be the name of a curve in `[CURVES]` whose type is `TIDAL` (water surface elevation in ft or m versus hour of day, 0–24).
- **Default:** `*` (GUI placeholder `objprops.txt:350`)
- **Cross-section dependency:** `[CURVES].Name` where curve type = `TIDAL`
- **Database-key hint:** foreign key to [CURVES].Name
- **Technical description:** References a tidal stage curve. The engine resolves the name to an integer curve index via `project_findObject(CURVE, tok[3])` and stores it as `Outfall[k].tideCurve`. At runtime, `outfall_setOutletDepth` calls `table_lookup(&Curve[k], x)` where `x` is the current time-of-day in hours, obtaining the stage elevation for that hour (`node.c:1446–1452`). The tidal curve must exist; a missing name produces `ERR_NAME`. The `TIDAL` curve type is enum value 2 in `CurveType` (`enums.h:440`).
- **Source of truth:** `swmm/swmm524_engine/src/node.c:1380–1383` (parsing and index lookup); `node.c:159` (stored); `node.c:1446–1452` (runtime use)

---

### Tseries  *(TIMESERIES type only — token 4)*

- **Data type:** NAME_REF
- **Required:** yes, when Type = `TIMESERIES`; absent for all other types
- **Units:** n/a (reference)
- **Valid values / range:** Must be the name of a time series in `[TIMESERIES]`. The series values are water surface elevations in ft (US) or m (SI).
- **Default:** `*` (GUI placeholder `objprops.txt:352`)
- **Cross-section dependency:** `[TIMESERIES].Name`
- **Database-key hint:** foreign key to [TIMESERIES].Name
- **Technical description:** References a time series that prescribes the outfall stage as an absolute water elevation varying over the simulation period. The engine resolves the name to an index via `project_findObject(TSERIES, tok[3])` and stores it as `Outfall[k].stageSeries`. It also marks the time series with `Tseries[m].refersTo = TIMESERIES_OUTFALL` so the time series module knows what units to use. At runtime, `outfall_setOutletDepth` calls `table_tseriesLookup` to interpolate the stage at the current simulation date/time (`node.c:1454–1458`). Missing name produces `ERR_NAME`.
- **Source of truth:** `swmm/swmm524_engine/src/node.c:1385–1390` (parsing and index lookup); `node.c:160` (stored); `node.c:1454–1458` (runtime use)

---

### Gated

- **Data type:** ENUM
- **Required:** no (default: `NO`)
- **Units:** unitless
- **Valid values / range:** `NO` | `YES`
- **Default:** `NO`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Indicates whether a flap gate is present at the outfall to prevent reverse flow (backflow from the receiving water body into the drainage system). Stored as `Outfall[k].hasFlapGate` (a `char` boolean). Token position depends on type: for FREE and NORMAL it is token 3 (index `n-1` where `n=4`); for FIXED, TIDAL, TIMESERIES it is token 4 (index `n-1` where `n=5`). The engine uses `findmatch(tok[n-1], NoYesWords)` so the accepted keywords are exactly `NO` (0) and `YES` (1) as defined in `text.h:343–344` and `keywords.c:72`. An unrecognised value returns `ERR_KEYWORD`. In the GUI the default is `'NO'` (`objprops.txt:344`) and the dropdown offers `NO` / `YES` (`objprops.txt:761–762`).
- **Source of truth:** `swmm/swmm524_engine/src/node.c:1392–1396` (parsing); `node.c:161` (stored); `keywords.c:72` (keyword list)

---

### RouteTo

- **Data type:** NAME_REF
- **Required:** no (default: none — outfall discharge leaves the model)
- **Units:** n/a (reference)
- **Valid values / range:** Name of a subcatchment defined in `[SUBCATCHMENTS]`. If omitted, the outfall discharge exits the model entirely.
- **Default:** none / empty string (GUI default `objprops.txt:345`)
- **Cross-section dependency:** `[SUBCATCHMENTS].Name`
- **Database-key hint:** foreign key to [SUBCATCHMENTS].Name
- **Technical description:** Added in engine build 5.1.008 (`objects.h:31`). When specified, the volumetric flow that exits the outfall is delivered to the named subcatchment's surface as runon during each routing time step. This enables cascading drainage between SWMM sub-models or recirculation scenarios. The engine resolves the name via `project_findObject(SUBCATCH, tok[n])` and stores the index as `Outfall[k].routeTo`. Token position is `n` where `n = 4` (FREE/NORMAL) or `n = 5` (FIXED/TIDAL/TIMESERIES), i.e., one position after the Gated token. If the subcatchment name is not found, `ERR_NAME` is returned. When `routeTo >= 0` at init time, the engine allocates a pollutant-load routing array `Outfall[k].wRouted` (`node.c:164–168`). Volume and pollutant mass routed are accumulated in `Outfall[k].vRouted` and `Outfall[k].wRouted` and applied to the subcatchment's runon. The `RUNOFF_RUNON` category in `RunoffTotals` tracks this flow (`enums.h:267`).
- **Source of truth:** `swmm/swmm524_engine/src/node.c:1399–1404` (parsing); `node.c:162` (stored); `node.c:164–168` (allocation); `node.c:280–286` (init)

## Notes

- **Minimum tokens:** The engine requires at least 3 tokens (Name, Elev, Type) at `node.c:1354`. For FIXED, TIDAL, and TIMESERIES types a 4th token is mandatory (`node.c:1372`); failing to provide it yields `ERR_ITEMS`.
- **Type keyword fallback in GUI:** The GUI's `ReadOutfallData` falls back to `FREE_OUTFALL` (index 0) if the type keyword is unrecognised (`Uimport.pas:913`). The engine instead returns `ERR_KEYWORD` (`node.c:1361`). This divergence means files with invalid type keywords may load silently in the GUI but fail in the engine.
- **Stage-data column always emitted by GUI writer:** `ExportOutfalls` always emits the Stage/Tcurve/Tseries column, padding with 16 spaces for FREE and NORMAL types (`Uexport.pas:892`). The engine ignores this padding whitespace because token 3 is only consumed for type ≥ FIXED.
- **Only one link per outfall:** The manual states "only one link can be incident on an outfall node" (`D.2_Input_File_Format.md:1146`; `3.2_Visual_Objects.md:85`). This is a topological constraint enforced during validation, not by the INP parser itself.
- **Dynamic Wave vs. other routing:** Under Steady Flow or Kinematic Wave routing, outfalls behave as simple junctions; the Type and Stage fields have no hydraulic effect in those modes (`3.2_Visual_Objects.md:85`).
- **Duplicate names:** Outfall names share the global NODE namespace with junctions, dividers, and storage units. A name already registered for any node type triggers `ERR_DUP_NAME` (`input.c:308–311`).
- **Tidal curve type:** The `[CURVES]` entry referenced by Tcurve must have curve type `TIDAL` (enum value 2 in `CurveType`, `enums.h:440`). The x-axis of the curve is hour of day (0–24) and the y-axis is absolute water-surface elevation in project length units.
- **TIMESERIES stage units:** The referenced `[TIMESERIES]` values are absolute water-surface elevations in project length units (ft or m), not depths. The engine divides by `UCF(LENGTH)` to convert to internal feet (`node.c:1457–1458`).
- **RouteTo and pollutant routing:** When RouteTo is set, the outfall's entire discharge (flow + pollutant loads) is transferred to the subcatchment surface each time step. This requires the subcatchment to be present and pre-allocated. The mass is tracked separately from normal subcatchment runon in `Outfall[k].wRouted`.
- **Uniqueness:** Each outfall name must be unique. Multiple rows for the same name are not permitted and will trigger an error.
- **Ordering:** The INP section has no required ordering. The engine processes rows in file order during the second pass.
