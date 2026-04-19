# [SYMBOLS]

**Purpose:** Assigns map display coordinates (X, Y) to each rain gage object so that it can be rendered as a bitmap symbol on SWMM's Study Area Map in the graphical user interface. This section is a pure visualization aid — it has no effect on any runoff or routing computation. The coordinates share the same map reference frame defined in the [MAP] section (origin at lower-left, axes pointing right and up). Gages that have not been placed on the map are simply omitted from this section; their X/Y fields remain at the sentinel value MISSING (`-1.0e10`) internally.

**Occurrence:** one row per object — exactly one row per rain gage that has been placed on the map. Rain gages that exist in [RAINGAGES] but have never been positioned on the map are omitted entirely from this section. A given gage name must appear at most once.

**SWMM source references:**
- Engine parser: The C engine defines the section keyword macro `ws_SYMBOL` as `"[SYMBOL"` (`swmm524_engine/src/text.h:447`) and the enum constant `s_SYMBOL` (`swmm524_engine/src/enums.h:469`), but the `parseLine()` switch in `input.c` contains no `case s_SYMBOL:` handler — it falls through to `default: return 0;` (`swmm524_engine/src/input.c:631`). The engine therefore silently skips every line of this section; it is invisible to simulations.
- Engine writer: Not applicable — the engine does not write INP files.
- GUI reader: `Uimport.pas:2485` — function `ReadSymbolData`; dispatched as case 41 of the section-dispatch table at `Uimport.pas:2925`.
- GUI writer: `Uexport.pas:2103` — procedure `ExportMap`; the [SYMBOLS] block is written at `Uexport.pas:2240–2257`.
- GUI editor dialog(s): No dedicated dialog. Coordinates are set implicitly when the user drags a rain gage symbol on the Study Area Map (via `Ucoords.pas`).
- Manual: `appendix_D_command_line_swmm/D.3_Map_Data_Section.md` — Section `[SYMBOLS]` (line 97–101)
- Additional manual refs: `appendix_D_command_line_swmm/D.3_Map_Data_Section.md` lines 6–41 (overview of all seven map data sections and their GUI-only role); `appendix_D_command_line_swmm/_README.md` line 12 (section inventory).

## Row Format

One line per placed rain gage:

```
Gage  Xcoord  Ycoord
```

Example from the manual (D.3_Map_Data_Section.md:34):

```
[SYMBOLS]
;;Gage           X-Coord           Y-Coord
;;-------------- ------------------ ------------------
G1               5298.01            9139.07
```

The GUI writes the gage name left-justified in a 16-character field (`%-16s`) followed by two floating-point coordinate values each in an 18-character field whose decimal precision matches the map's `Digits` setting (`Fmt = '%-18.' + IntToStr(Digits) + 'f'`; `Uexport.pas:2125`). Fields are separated by a tab character (or a space if the project is not tab-delimited; `Uexport.pas:2119`).

## Fields

### Gage

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match the name of an existing rain gage as declared in [RAINGAGES]. The lookup is performed by `Project.Lists[RAINGAGE].IndexOf(TokList[0])` (`Uimport.pas:2500`). If no matching gage is found the row is silently ignored (no error is raised).
- **Default:** none
- **Cross-section dependency:** `[RAINGAGES].Name`
- **Database-key hint:** foreign key to [RAINGAGES].Name; acts as the primary identifier of this row (unique per row).
- **Technical description:** The name token that identifies which rain gage is being positioned. The GUI reader locates the `TRaingage` object in memory by searching the `RAINGAGE` list; if found, it assigns the parsed X and Y to the object's map-coordinate fields. Gages absent from this section retain X = MISSING = `-1.0e10` and Y = MISSING = `-1.0e10` (`Uimport.pas:347–348`; `Uproject.pas:1029–1030`). The exporter skips any gage whose coordinates are still MISSING (`Uexport.pas:2249`).
- **Source of truth:** `Uimport.pas:2500` (lookup); `Uimport.pas:2495–2496` (token-count guard).

### Xcoord

- **Data type:** COORD
- **Required:** yes
- **Units:** Map coordinate units as declared by [MAP].UNITS (FEET / METERS / DEGREES / NONE). Coordinates have no fixed physical unit — they are in whatever system the [MAP] section establishes. The manual notes that the coordinate system "has no units" unless the modeller explicitly chooses a real-world reference frame (`D.3_Map_Data_Section.md:20`).
- **Valid values / range:** any real number; parsed by `Uutils.GetExtended()` (`Uimport.pas:2506`). No explicit bounds check is applied beyond successful numeric parsing.
- **Default:** none (a row in [SYMBOLS] is only emitted if X ≠ MISSING)
- **Cross-section dependency:** None — internally consistent with [MAP].DIMENSIONS lower-left / upper-right X bounds, but no enforcement occurs.
- **Database-key hint:** plain data – no key role.
- **Technical description:** Horizontal position of the rain gage symbol relative to the origin at the lower-left corner of the map bounding box. The value is stored in `TRaingage.X : Extended` (`Uproject.pas:561`). On export the GUI formats it as a fixed-point real with the map's digit precision (`Uexport.pas:2252`). This coordinate is used only for rendering the gage icon on screen and is completely ignored by the simulation engine.
- **Source of truth:** `Uimport.pas:2506` (parse); `Uproject.pas:561` (storage field).

### Ycoord

- **Data type:** COORD
- **Required:** yes
- **Units:** Same map coordinate units as Xcoord (see above).
- **Valid values / range:** any real number; parsed by `Uutils.GetExtended()` (`Uimport.pas:2508`). No explicit bounds check.
- **Default:** none (a row in [SYMBOLS] is only emitted if Y ≠ MISSING)
- **Cross-section dependency:** None — internally consistent with [MAP].DIMENSIONS lower-left / upper-right Y bounds, but no enforcement occurs.
- **Database-key hint:** plain data – no key role.
- **Technical description:** Vertical position of the rain gage symbol relative to the origin at the lower-left corner of the map bounding box. The value is stored in `TRaingage.Y : Extended` (`Uproject.pas:561`). The coordinate system places Y increasing upward. Used only for GUI rendering; the simulation engine ignores it completely.
- **Source of truth:** `Uimport.pas:2508` (parse); `Uproject.pas:561` (storage field).

## Notes

- **GUI-only section.** The engine C source defines the section-name macro `ws_SYMBOL "[SYMBOL"` (`text.h:447`) and the enum `s_SYMBOL` (`enums.h:469`) purely for section-header recognition during file scanning, but the `parseLine()` dispatch switch has no handler for `s_SYMBOL` and falls through to `default: return 0;` (`input.c:631`). Every data line in this section is discarded without error when running command-line SWMM. The section need not be present for a valid simulation.
- **Omission semantics.** A rain gage not listed in [SYMBOLS] simply has no map position. The GUI treats this as MISSING (`-1.0e10`) for both X and Y (`Uimport.pas:347–348`). The gage is still fully functional for simulation purposes.
- **Unknown gage name.** If a gage name token in [SYMBOLS] does not match any entry in the [RAINGAGES] list, `ReadSymbolData` sets `J = -1` and the `if (J >= 0)` guard at `Uimport.pas:2503` causes the row to be silently skipped — no error is emitted.
- **Minimum token count.** The reader enforces `Ntoks >= 3` (gage + X + Y); lines with fewer tokens produce an `ITEMS_ERR` error message (`Uimport.pas:2495–2496`).
- **Coordinate precision.** On export, the floating-point format string is derived from `MapForm.Map.Dimensions.Digits` (an integer indicating decimal places) so that the written precision matches the rest of the map sections (`Uexport.pas:2125`).
- **Section header prefix matching.** The GUI section-header list uses `'[SYMBOLS'` (without closing bracket, index 41, `Uimport.pas:102`). This means the reader matches any header whose first eight characters are `[SYMBOLS` — a standard SWMM convention for all section names.
- **Uniqueness.** Each gage should appear at most once. If a gage appears twice, the second entry silently overwrites the first (no duplicate-detection code exists in `ReadSymbolData`).
- **No composite key.** This section has a single identifying column (Gage name). DB designers should model it as a one-to-one extension table of [RAINGAGES], with Gage as both the primary key and a foreign key to [RAINGAGES].Name.
- **Map data is not required for command-line usage.** The D.3 manual states explicitly: "Map data are not needed for running the command line version of SWMM." (`D.3_Map_Data_Section.md:41`).
