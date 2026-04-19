# [MAP]

**Purpose:** Provides the bounding-rectangle coordinates and distance units for the SWMM Study Area Map. This section is purely a visualization aid for the GUI; it carries no information used in runoff or routing computations. The engine registers the section keyword but performs no parsing of its content. The GUI uses the data to scale the map window, convert measured distances to real-world units, and control the decimal-digit precision of all coordinate output.

**Occurrence:** Single global block. Each sub-keyword (`DIMENSIONS`, `UNITS`) appears at most once per INP file. The section contains exactly two lines in normal GUI-generated files.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/enums.h:470` — enum value `s_MAP` in `InputSectionType`; `swmm524_engine/src/keywords.c:142` — `ws_MAP` registered in `SectWords[]`; `swmm524_engine/src/input.c:631` — `parseLine()` `default: return 0;` — the engine recognises the section header but silently discards every line of content.
- Engine writer: none — the engine does not write INP files and has no report-echo function for this section.
- GUI reader: `Uimport.pas:2520` — function `ReadMapData`; dispatched from `ParseInpLine` at `Uimport.pas:2921` (case 37).
- GUI writer: `Uexport.pas:2103` — procedure `ExportMap`; writes `[MAP]` header, `DIMENSIONS` line, and `Units` line at `Uexport.pas:2121–2133`.
- GUI editor dialog: `Dmapdim.pas` / `Dmapdim.dfm` — `TMapDimensionsForm` (Map Dimensions dialog, opened via View >> Dimensions).
- Manual: `appendix_D_command_line_swmm/D.3_Map_Data_Section.md` — Section [MAP] (lines 43–49).
- Additional manual refs: `chapter_07_working_with_the_map/7.3_Setting_the_Maps_Dimensions.md` (GUI walkthrough for setting map dimensions).

## Row Format

The section contains two keyword-led lines (order is conventional but not enforced by the parser):

```
DIMENSIONS  X1  Y1  X2  Y2
UNITS       FEET / METERS / DEGREES / NONE
```

Each line begins with a sub-keyword token followed by its arguments. Comment lines beginning with `;;` are ignored. No object names appear; the entire section defines a single global coordinate frame.

Example from the manual (`D.3_Map_Data_Section.md:28`):

```
[MAP]
DIMENSIONS  0.00  0.00  10000.00  10000.00
UNITS       None
```

## Fields

### Sub-keyword: DIMENSIONS

The `DIMENSIONS` keyword introduces the bounding-rectangle row. All four coordinate arguments follow on the same line.

---

### X1

- **Data type:** REAL
- **Required:** yes (if DIMENSIONS line is present; the entire DIMENSIONS line is optional but if present requires all 4 values)
- **Units:** same unit system as declared by `UNITS` sub-keyword (feet, metres, decimal degrees, or dimensionless)
- **Valid values / range:** any real; must be strictly less than X2 (`Uimport.pas:2545`: `X[1] < X[3]`)
- **Default:** `0.00` (GUI default: `Umap.pas:120–121`, `DefMapDimensions.LowerLeft.X = 0.00`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** X coordinate of the lower-left corner of the full map extent. Defines the left edge of the coordinate space in which all object coordinates (`[COORDINATES]`, `[VERTICES]`, `[POLYGONS]`, `[SYMBOLS]`, `[LABELS]`) are expressed. The GUI uses this together with X2 to compute its horizontal scaling factor.
- **Source of truth:** `Uimport.pas:2548` (`LowerLeft.X := X[1]`); `Uexport.pas:2127` (written as `FloatToStrF(LowerLeft.X, ffFixed, 18, D)`).

---

### Y1

- **Data type:** REAL
- **Required:** yes (if DIMENSIONS line is present)
- **Units:** same as X1
- **Valid values / range:** any real; must be strictly less than Y2 (`Uimport.pas:2545`: `X[2] < X[4]`)
- **Default:** `0.00` (`Umap.pas:120–121`, `DefMapDimensions.LowerLeft.Y = 0.00`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Y coordinate of the lower-left corner of the full map extent. Defines the bottom edge of the coordinate space. The origin of the map coordinate system is at (X1, Y1).
- **Source of truth:** `Uimport.pas:2549` (`LowerLeft.Y := X[2]`); `Uexport.pas:2128`.

---

### X2

- **Data type:** REAL
- **Required:** yes (if DIMENSIONS line is present)
- **Units:** same as X1
- **Valid values / range:** any real strictly greater than X1
- **Default:** `10000.00` (`Umap.pas:121`, `DefMapDimensions.UpperRight.X = 10000.00`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** X coordinate of the upper-right corner of the full map extent. Together with X1 defines the total horizontal span of the map.
- **Source of truth:** `Uimport.pas:2550` (`UpperRight.X := X[3]`); `Uexport.pas:2129`.

---

### Y2

- **Data type:** REAL
- **Required:** yes (if DIMENSIONS line is present)
- **Units:** same as X1
- **Valid values / range:** any real strictly greater than Y1
- **Default:** `10000.00` (`Umap.pas:121`, `DefMapDimensions.UpperRight.Y = 10000.00`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Y coordinate of the upper-right corner of the full map extent. Together with Y1 defines the total vertical span of the map.
- **Source of truth:** `Uimport.pas:2551` (`UpperRight.Y := X[4]`); `Uexport.pas:2130`.

---

### Sub-keyword: UNITS

The `UNITS` keyword introduces the distance-unit selection row.

---

### Units

- **Data type:** ENUM
- **Required:** no (default: `None`)
- **Units:** unitless (this field declares units, it does not have units itself)
- **Valid values / range:**
  - `Feet` — US customary feet
  - `Meters` — SI metres
  - `Degrees` — decimal degrees of latitude/longitude
  - `None` — no real-world unit; coordinates are arbitrary
  - Matching is case-insensitive and uses only the **first character** of the supplied token (`Uimport.pas:2560`: `Copy(TokList[1], 1, 1)`). Therefore `F`/`f`, `M`/`m`, `D`/`d`, `N`/`n` are all valid initial characters.
- **Default:** `None` (`Umap.pas:126`; `Dmapdim.dfm:155` — `ItemIndex = 3` corresponds to index 3 in `TMapUnits = (muFeet, muMeters, muDegrees, muNone)`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Controls two downstream GUI behaviours:
  1. **Coordinate decimal precision** — when `Degrees` is selected the GUI switches `Dimensions.Digits` to `MAXDEGDIGITS` (6 decimal places, `Uglobals.pas:64`); for all other units `Digits` reverts to 3 (`Umap.pas:127`). This precision is applied when writing all coordinate values in `[COORDINATES]`, `[VERTICES]`, `[POLYGONS]`, `[SYMBOLS]`, and `[LABELS]` (`Uexport.pas:2124–2125`).
  2. **Length/area unit-conversion factor** — `UpdateMapUnits` (`Uupdate.pas:765`) sets `LengthUCF` and `AreaUCF` inside `MapForm.Map.Dimensions`. When map units are `Feet` but the flow-unit system is SI, `LengthUCF` is set to `METERSperFOOT`; when map units are `Meters` or `Degrees` but the flow-unit system is US, `LengthUCF` is set to `FEETperMETER` (`Uupdate.pas:778–793`). These conversion factors are used when the GUI auto-computes conduit lengths from map coordinates (auto-length feature).
  - The engine never reads this value; it falls through to the `default: return 0` branch of `parseLine()` (`input.c:631`).
- **Source of truth:** `Uimport.pas:2560–2566` (parsing); `Uexport.pas:2132` (writing: `MapUnits[Ord(Units)]`); `Uglobals.pas:151–152` (string table `MapUnits`); `Dmapdim.dfm:148–161` (dialog radio group with four items).

## Notes

- The engine registers `ws_MAP` in `SectWords[]` (`keywords.c:142`) and assigns it enum value `s_MAP` (`enums.h:470`), enabling the section-dispatch logic to advance to the correct section state. However, no `case s_MAP:` branch exists in `parseLine()` (`input.c:473–632`); the fall-through `default: return 0` discards every content line silently. The section is therefore registered but never parsed by the simulation engine.
- The entire `[MAP]` section is **optional** for command-line SWMM runs. Map data are not needed for any computation (`D.3_Map_Data_Section.md:41`).
- The GUI's `ReadFile` loop sets `MapExtentSet := False` before parsing (`Uimport.pas:3263`). Upon successfully reading a `DIMENSIONS` line the flag is set to `True` (`Uimport.pas:2552`). After the full file is read, `SetMapDimensions` (`Uimport.pas:2829`) is called (`Uimport.pas:3302`) to merge the declared dimensions with the bounding box of all object coordinates and the backdrop image extent. This means the stored dimensions may be expanded beyond what the `[MAP]` section declares if object coordinates lie outside.
- The `UNITS` keyword matching uses only the first character of the argument (`Copy(TokList[1], 1, 1)`), so any string beginning with `F`, `M`, `D`, or `N` (case-insensitive) is accepted as a valid unit token. The exported spelling uses the full word (`Feet`, `Meters`, `Degrees`, `None`) as defined in `MapUnits[]` (`Uglobals.pas:151–152`).
- When `UNITS Degrees` is set the GUI also stores `XperDeg = 111195` metres per degree (`Umap.pas:122–123`) and uses it to convert subcatchment polygon areas from degree-squared to real-world area (`Umap.pas:2026`, `Umap.pas:2162`).
- The section header uses prefix matching in both the engine (`ws_MAP = "[MAP"`, `text.h:443`) and the GUI (`'[MAP'` at `Uimport.pas:98`). A section named `[MAPDIMENSIONS]` or any token starting with `[MAP` would be recognised.
- The `[MAP]` section appears in the INP file before `[COORDINATES]` and all other map-data sections (`[VERTICES]`, `[POLYGONS]`, `[SYMBOLS]`, `[LABELS]`, `[BACKDROP]`). The GUI `ExportMap` procedure writes them in this order (`Uexport.pas:2103–2443`).
- No uniqueness or composite-key constraints apply — the section defines a single global record, not a table of named objects.
- A database designer should store `DIMENSIONS` (four REAL columns: `x_min`, `y_min`, `x_max`, `y_max`) and `UNITS` (one ENUM column) as a single-row global-settings table. No foreign keys to other sections are required.
