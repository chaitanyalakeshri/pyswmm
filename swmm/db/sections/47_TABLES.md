# [TABLES]

**Purpose:** The `[TABLES]` section heading is a GUI-only alias for `[CURVES]`. Both section keywords cause the GUI reader to invoke the same `ReadCurveData` procedure, which parses x-y tabular data that describes functional relationships between two quantities. These curve objects are referenced by storage nodes, pumps, outlets, flow dividers, outfalls, conduit cross-sections, LID underdrains, weirs, and modulated control rules elsewhere in the INP file. The SWMM 5.x engine does not recognise `[TABLES]` at all; the engine's section-keyword table (`SectWords[]` in `keywords.c`) contains only `[CURVE` (matching `[CURVES]`). The GUI writer (`ExportCurves` in `Uexport.pas`) always emits `[CURVES]`, never `[TABLES]`. Consequently `[TABLES]` is purely a read-time alias that allows older or third-party INP files that use `[TABLES]` to be loaded correctly by the GUI.

**Occurrence:** Multiple rows per object. A named curve is introduced on its first line (Name + Type + optional first x-y pair) and may continue across as many subsequent lines as needed by repeating the curve name. Multiple x-y pairs may appear on a single line. One curve object typically spans 1–N lines.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/input.c:598` — `case s_CURVE:` dispatches to `table_readCurve` (in `table.c:67`). The engine section list (`keywords.c:136`) contains only `ws_CURVE` = `"[CURVE"`; `[TABLE` is absent, so the engine silently ignores any `[TABLES]` section.
- Engine writer: The engine does not write INP files. `inputrpt.c` does not echo curve data.
- GUI reader: `Uimport.pas:106` — `SectionWords[45]` = `'[TABLE'`; `Uimport.pas:2929` — `case 45: Result := ReadCurveData;`. The function `ReadCurveData` begins at `Uimport.pas:1931`.
- GUI writer: `Uexport.pas:1901` — procedure `ExportCurves`. Emits the literal header `[CURVES]` (line 1911); `[TABLES]` is never written.
- GUI editor dialog(s): `Dcurve.pas` / `Dcurve.dfm` — the Curve Editor dialog (`TCurveDataForm`) used for all curve types.
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md:2332` — `[CURVES]` section specification. `[TABLES]` does not appear in the manual.
- Additional manual refs: `chapter_03_swmms_conceptual_model/3.3_Non-Visual_Objects.md:328` — conceptual description of Curve objects; `appendix_C_specialized_property_editors/C.5_Curve_Editor.md:1` — Curve Editor dialog description.

## Row Format

First line for a new curve (Name + Type on the first appearance; optional x-y pairs may follow on the same line):

```
Name  Type  [X-value  Y-value  ...]
```

Continuation lines (same curve name, type field is blank or omitted):

```
Name  X-value  Y-value  [X-value  Y-value  ...]
```

Multiple x-y pairs may appear on any line. If only the name and type appear (no data values) the first line is a "type declaration" row with data following on subsequent lines. Subsequent lines must repeat the curve name but the Type field is omitted; the parser treats any token at position 2 (0-indexed as `TokList[1]`) on the first occurrence as the curve type keyword.

Authoritative format string from the manual (`D.2_Input_File_Format.md:2336`):

> `Name  Type`  (first line)
> `Name  X-value  Y-value  ...`  (data lines)

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-empty string without leading `[`. Must be unique within the set of all curve objects across all curve categories (`CONTROLCURVE` through `WEIRCURVE`, object-class indices 14–21 in the GUI's `Uproject.pas:54–61`). The GUI uses a hash/list lookup: `Project.FindCurve(ID, ObjType, Index)` at `Uimport.pas:1956`.
- **Default:** none
- **Cross-section dependency:** None (this field defines the primary identifier).
- **Database-key hint:** Primary identifier of this row; composite PK with row sequence number within the curve because multiple rows share the same Name.
- **Technical description:** The user-assigned name of the curve. On the first line the name is new and triggers creation of a curve object of the appropriate type. On continuation lines the name must match an already-created curve; the parser compares the current token against `PrevID` to avoid a repeated dictionary lookup (`Uimport.pas:1951–1955`). The engine looks up the curve by name via `project_findObject(CURVE, tok[0])` at `table.c:82`.
- **Source of truth:** `Uimport.pas:1950–1956`; engine: `table.c:82–90`.

### Type

- **Data type:** ENUM
- **Required:** yes (on the first line for a given Name only; absent on continuation lines)
- **Units:** unitless
- **Valid values / range:** The GUI accepts the following 12 keywords (case-insensitive, `CurveTypeOptions` array at `objprops.txt:207–209`):

  | Keyword    | GUI ObjType constant | Engine enum             |
  |------------|----------------------|-------------------------|
  | `CONTROL`  | `CONTROLCURVE` (14)  | `CONTROL_CURVE`         |
  | `DIVERSION`| `DIVERSIONCURVE` (15)| `DIVERSION_CURVE`       |
  | `PUMP1`    | `PUMPCURVE` (16)     | `PUMP1_CURVE`           |
  | `PUMP2`    | `PUMPCURVE` (16)     | `PUMP2_CURVE`           |
  | `PUMP3`    | `PUMPCURVE` (16)     | `PUMP3_CURVE`           |
  | `PUMP4`    | `PUMPCURVE` (16)     | `PUMP4_CURVE`           |
  | `PUMP5`    | `PUMPCURVE` (16)     | `PUMP5_CURVE`           |
  | `RATING`   | `RATINGCURVE` (17)   | `RATING_CURVE`          |
  | `SHAPE`    | `SHAPECURVE` (18)    | `SHAPE_CURVE`           |
  | `STORAGE`  | `STORAGECURVE` (19)  | `STORAGE_CURVE`         |
  | `TIDAL`    | `TIDALCURVE` (20)    | `TIDAL_CURVE`           |
  | `WEIR`     | `WEIRCURVE` (21)     | `WEIR_CURVE`            |

  The engine uses `CurveTypeWords[]` at `keywords.c:46–49`: `{ w_STORAGE, w_DIVERSION, w_TIDAL, w_RATING, w_CONTROLS, w_SHAPE, w_WEIR, w_PUMP1, w_PUMP2, w_PUMP3, w_PUMP4, w_PUMP5, NULL }`.

- **Default:** none
- **Cross-section dependency:** None.
- **Database-key hint:** Plain data – no key role; determines how the x-y data is interpreted by the simulation engine and which object categories reference this curve.
- **Technical description:** Specifies the curve's physical meaning and controls axis semantics in the Curve Editor dialog. For pump curves, the five sub-types (`PUMP1`–`PUMP5`) are stored under the same GUI object category (`PUMPCURVE`) but distinguished by `aCurve.CurveCode` (`Uimport.pas:1997–1998`). In the engine the type keyword must match one entry in `CurveTypeWords[]`; a mismatch returns `ERR_KEYWORD` (`table.c:92`). If the first line carries only a Name and Type (no x-y pair), the line acts as a header-only declaration; the engine handles this at `table.c:94` (`if (ntoks == 2) return 0`). Continuation lines (where `ID == PrevID` in the GUI) skip the type field entirely and jump directly to parsing x-y pairs starting at token index `K = 2` (first line with data) or `K = 2` (continuation), as shown at `Uimport.pas:1959` and `2010–2014`.
- **Source of truth:** `Uimport.pas:1963–2005`; engine: `table.c:91–96`; keyword list: `keywords.c:46–49`.

### X-value

- **Data type:** REAL
- **Required:** yes (at least one x-y pair must exist across all lines of the curve; a name+type-only first line with no subsequent data pairs is accepted by the parser but produces an empty/degenerate curve)
- **Units:** Depends on curve type (US / SI):
  - `STORAGE`: depth in ft (m)
  - `DIVERSION`: total inflow in flow units (CFS / CMS / etc.)
  - `TIDAL`: hour of day (0–24), dimensionless
  - `PUMP1`: inlet wet-well volume in ft³ (m³)
  - `PUMP2`: inlet node depth in ft (m)
  - `PUMP3`: head difference (outlet − inlet) in ft (m), decreasing flow with increasing head
  - `PUMP4`: inlet node depth in ft (m) — continuous
  - `PUMP5`: head difference (outlet − inlet) in ft (m), variable-speed version
  - `RATING`: head in ft (m)
  - `SHAPE`: depth/full-depth (dimensionless fraction)
  - `CONTROL`: controller variable value (units match the variable referenced in a control rule)
  - `WEIR`: head in ft (m)
- **Valid values / range:** Must be numeric (`getDouble` at `table.c:102`). X-values must be entered in strictly increasing order (the manual states this at `D.2_Input_File_Format.md:2352`; the GUI warns but does not refuse out-of-order data — see `Dcurve.pas:113`: `MSG_OUT_OF_ORDER`).
- **Default:** none
- **Cross-section dependency:** None.
- **Database-key hint:** Composite PK with Name and row-sequence within the curve (x-value ordering is enforced by convention, not by the parser).
- **Technical description:** The independent variable of the tabular relationship. Multiple x-y pairs may appear on a single line; the parser steps through tokens in increments of 2 (`for k = k1; k < ntoks; k = k+2` at `table.c:99`). Values are stored as linked `TTableEntry` nodes (`objects.h:88–93`) chained via `table_addEntry(&Curve[j], x, y)` at `table.c:106`.
- **Source of truth:** `table.c:99–106`; `Uimport.pas:2010–2014`.

### Y-value

- **Data type:** REAL
- **Required:** yes (paired with each X-value; the parser requires an even number of remaining tokens — it returns `ERR_ITEMS` if `k+1 >= ntoks` at `table.c:101`)
- **Units:** Depends on curve type (US / SI):
  - `STORAGE`: surface area in ft² (m²)
  - `DIVERSION`: diverted outflow in flow units
  - `TIDAL`: water surface elevation (stage) in ft (m)
  - `PUMP1`–`PUMP5`: pump outflow in flow units
  - `RATING`: outflow rate in flow units
  - `SHAPE`: width/full-depth (dimensionless fraction)
  - `CONTROL`: control setting (dimensionless, 0–1 for pumps/gates; or flow adjustment factor for LID underdrains)
  - `WEIR`: discharge coefficient in CFS (CMS) units
- **Valid values / range:** Any real number (`getDouble` at `table.c:104`). No range validation occurs in the parser; physical constraints are enforced implicitly by the simulation engine when the curve is used.
- **Default:** none
- **Cross-section dependency:** None.
- **Database-key hint:** Plain data – no key role.
- **Technical description:** The dependent variable paired with each X-value. Together with X-value, one x-y pair encodes one row of the tabular relationship. The engine stores both values in a `TTableEntry` struct (`objects.h:88–92`) linked into the `TTable` object representing the curve (`objects.h:95–111`).
- **Source of truth:** `table.c:99–106`; `Uimport.pas:2010–2014`.

## Notes

- **`[TABLES]` is a GUI-only read alias for `[CURVES]`.** The GUI `SectionWords` array (`Uimport.pas:60–118`) registers `'[TABLE'` at index 45 alongside `'[CURVE'` at index 33. The dispatch table at `Uimport.pas:2917` and `2929` routes both indices to the identical `ReadCurveData` function (`Uimport.pas:1931`). The engine's `SectWords[]` (`keywords.c:118–146`) contains only `ws_CURVE` = `"[CURVE"` and has no entry for `"[TABLE"`. If a file containing `[TABLES]` is passed directly to the engine CLI, the `[TABLES]` section header causes `findmatch` to return −1 and `sect` is set to −1 (`input.c:107–117`), meaning all subsequent data rows are silently discarded. Only the GUI handles `[TABLES]`.
- **The GUI writer never emits `[TABLES]`.** `ExportCurves` (`Uexport.pas:1901`) unconditionally adds the literal string `'[CURVES]'` at line 1911. Any INP file saved by the GUI will use `[CURVES]`.
- **Section-header prefix matching.** Both the GUI (`Uimport.pas:2992`: `Pos(SectionWords[K], S) = 1`) and the engine (`input.c:107`: `findmatch` using `match()` which calls `strncmp`) match section keywords by prefix. Thus `[CURVES]`, `[CURVES] ; comment`, and `[CURVESANYTHING]` all match `[CURVE`; similarly `[TABLES]` matches `[TABLE`.
- **Multi-line curves.** A curve may span an arbitrary number of lines. The name must be repeated on every line. The GUI uses `PrevID` / `PrevIndex` to avoid redundant lookups (`Uimport.pas:1951–1954`). The engine relies on `Curve[j].ID == NULL` being the sentinel for "first line" (`table.c:87`).
- **Multiple x-y pairs per line.** Up to the token limit (`MAXTOKS` in the engine, `MAXITEMS = 100` rows in the GUI editor `Dcurve.pas:73`) pairs may appear on a single line. The parser iterates in steps of 2.
- **X-values must be in strictly increasing order** (manual `D.2_Input_File_Format.md:2352`). The GUI warns the user but does not reject the data (`Dcurve.pas:113`); the engine does not validate ordering at parse time.
- **Pump curve sub-types.** `PUMP1`–`PUMP5` are all stored in the single GUI object category `PUMPCURVE` (index 16 in `Uproject.pas:56`) and distinguished by `aCurve.CurveCode` (0–4). The engine uses `PUMP1_CURVE` through `PUMP5_CURVE` enum values (`enums.h:445–449`).
- **`SHAPE` curve triggers an additional object count.** In the engine's first-pass object counting (`input.c:395`), a `SHAPE` curve also increments `Nobjects[SHAPE]`, allocating a separate shape-conduit descriptor.
- **Uniqueness.** Each curve name must be unique within its curve type category. The GUI does not enforce cross-category uniqueness, but the engine stores all curves in a single `CURVE` object pool identified by name.
- **No [TABLES] entry in the official manual.** Appendix D.2 documents only `[CURVES]`. `[TABLES]` is an undocumented backward-compatibility alias introduced in the GUI reader.
- **Cross-section dependencies.** Curves are referenced by: `[STORAGE].Curve` (STORAGE type), `[XSECTIONS].Curve` (SHAPE type), `[PUMPS].Pcurve` (PUMP1–PUMP5 types), `[OUTLETS].Qcurve` (RATING type), `[OUTFALLS].Tcurve` (TIDAL type), `[DIVIDERS].Dcurve` (DIVERSION type), `[WEIRS].CDischarge` (WEIR type), and `[CONTROLS]` rule modulation expressions (CONTROL type).
