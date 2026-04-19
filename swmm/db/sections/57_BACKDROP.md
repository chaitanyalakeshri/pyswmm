# [BACKDROP]

**Purpose:** Specifies the file name and map-coordinate bounding rectangle of a raster or vector image that is displayed as a static background layer behind the SWMM study-area map in the GUI. The backdrop is purely a visualization aid (street map, topographic map, aerial photograph, site plan, etc.) that helps users position drainage objects by sight. It plays no role in any runoff or routing computation.

**Occurrence:** Single global block — at most one `[BACKDROP]` section per INP file; the section contains exactly two data rows (one `FILE` line and one `DIMENSIONS` line). The section is emitted by the GUI only when a backdrop image file is loaded; it is omitted entirely when no backdrop is in use.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/keywords.c:140` — section keyword `ws_BACKDROP` is recognized in the `SectWords` array and maps to enum value `s_BACKDROP` (`enums.h:469`). However, neither `addObject()` nor `parseLine()` contains a `case s_BACKDROP:` branch (`input.c:251–458` and `input.c:464–632`), so all content lines fall through to `default: return 0` — the engine silently ignores the entire section.
- Engine writer: none — the engine never writes INP files.
- GUI reader: `Uimport.pas:2722` — procedure `ReadBackdropData`; dispatched at `Uimport.pas:2927` (section index 43).
- GUI writer: `Uexport.pas:2289–2305` — inline block within the map-export code path (no named procedure); writes `[BACKDROP]`, then the `FILE` line, then the `DIMENSIONS` line.
- GUI editor dialog: `Dbackdrp.pas` — `TBackdropFileForm`; handles image-file selection, optional world-file geo-referencing, and coordinate computation. Also `Fmain.pas` (View >> Backdrop sub-menu) and the Backdrop Dimensions resize dialog.
- Manual: `appendix_D_command_line_swmm/D.3_Map_Data_Section.md` — section `[BACKDROP]`
- Additional manual refs: `chapter_07_working_with_the_map/7.4_Utilizing_a_Backdrop_Image.md` (full GUI workflow including world files, alignment, and resize)

## Row Format

The section contains exactly two keyword-prefixed lines (order does not matter to the reader, but the GUI always writes `FILE` first):

```
FILE        Fname
DIMENSIONS  X1  Y1  X2  Y2
```

Both lines begin with a recognized sub-keyword (`FILE` or `DIMENSIONS`). The `FILE` value is enclosed in double quotes by the GUI writer (`Uexport.pas:2297`). There are no continuation rows and no header comment row is emitted by the GUI for this section.

## Fields

### FILE sub-keyword / Fname

- **Data type:** TEXT
- **Required:** yes (the section is omitted entirely if no file is set; once the section is present, `FILE` is mandatory)
- **Units:** n/a (file-system path)
- **Valid values / range:** Any file-system path string accepted by the Windows TPicture loader. Supported image formats: Windows metafile (`.wmf`, `.emf`), bitmap (`.bmp`), JPEG (`.jpg`/`.jpeg`), PNG (`.png`). The GUI writer stores a path relative to the project directory (`Uexport.pas:2294` — `RelativePathName()`). The reader converts it back to an absolute path (`Uimport.pas:2741` — `FullPathName(TokList[1])`). The value is enclosed in double quotes by the writer to allow spaces in the path.
- **Default:** `''` (empty; `Umap.pas:131` — `DefMapBackdrop.Filename := ''`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Full or relative path to the image file that is rendered as the map backdrop. The GUI records the path relative to the saved project directory and converts it to absolute on load. If the file cannot be found at load time the GUI emits a warning and resets the backdrop to the default (no-image) state (`Fmap.pas:887–892`). Metafile format is preferred over raster formats because it is resolution-independent and scales without quality loss on zoom (`chapter_07/7.4_Utilizing_a_Backdrop_Image.md`). The internal `TMapBackdrop.Source` field is set to `bdFile` upon reading (`Uimport.pas:2742`); the enum `TBackdropSource = (bdNone, bdFile, bdWebStreet, bdWebTopo, bdWebAerial)` (`Umap.pas:58`) but only `bdFile` is ever written to the INP file.
- **Source of truth:** `Uimport.pas:2738–2743` (read); `Uexport.pas:2292–2297` (write)

### DIMENSIONS sub-keyword / X1

- **Data type:** REAL
- **Required:** yes (within a `DIMENSIONS` line; must supply all four values or the reader raises `ITEMS_ERR`)
- **Units:** map coordinate units (same dimensionless or geo-referenced units as `[MAP].DIMENSIONS`)
- **Valid values / range:** Any real number; lower-left X coordinate of the backdrop image in map-space. Must be less than X2 for the backdrop to be recognized as having a valid extent (`Uimport.pas:2839` — `Backdrop.LowerLeft.X < Backdrop.UpperRight.X`).
- **Default:** `0.0` (`Umap.pas:132` — `DefMapBackdrop.LowerLeft.X`)
- **Cross-section dependency:** Logically consistent with `[MAP].DIMENSIONS` coordinate space; no enforced foreign-key relationship.
- **Database-key hint:** plain data – no key role
- **Technical description:** The X coordinate of the left edge of the backdrop image in world (map) coordinates. Together with Y1, X2, Y2 it defines the bounding rectangle into which the image is stretched when rendered.
- **Source of truth:** `Uimport.pas:2753–2754` (parsed into `Backdrop.LowerLeft.X`); `Uexport.pas:2299` (written via `FloatToStrF`)

### DIMENSIONS sub-keyword / Y1

- **Data type:** REAL
- **Required:** yes
- **Units:** map coordinate units
- **Valid values / range:** Any real number; lower-left Y coordinate. Must be less than Y2 for the backdrop to be recognized as valid.
- **Default:** `0.0` (`Umap.pas:132` — `DefMapBackdrop.LowerLeft.Y`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The Y coordinate of the bottom edge of the backdrop image in world (map) coordinates.
- **Source of truth:** `Uimport.pas:2755` (parsed into `Backdrop.LowerLeft.Y`); `Uexport.pas:2300`

### DIMENSIONS sub-keyword / X2

- **Data type:** REAL
- **Required:** yes
- **Units:** map coordinate units
- **Valid values / range:** Any real number; must be greater than X1.
- **Default:** `0.0` (`Umap.pas:133` — `DefMapBackdrop.UpperRight.X`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The X coordinate of the right edge of the backdrop image in world (map) coordinates.
- **Source of truth:** `Uimport.pas:2756` (parsed into `Backdrop.UpperRight.X`); `Uexport.pas:2301`

### DIMENSIONS sub-keyword / Y2

- **Data type:** REAL
- **Required:** yes
- **Units:** map coordinate units
- **Valid values / range:** Any real number; must be greater than Y1.
- **Default:** `0.0` (`Umap.pas:133` — `DefMapBackdrop.UpperRight.Y`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The Y coordinate of the top edge of the backdrop image in world (map) coordinates. Together X1, Y1, X2, Y2 define the axis-aligned bounding rectangle. When backdrop dimensions are valid (LowerLeft < UpperRight), the GUI uses them to expand the map extent at project load time (`Uimport.pas:2838–2854`).
- **Source of truth:** `Uimport.pas:2757` (parsed into `Backdrop.UpperRight.Y`); `Uexport.pas:2302`

## Notes

- **Engine completely ignores this section.** The C engine recognizes `[BACKDROP]` as a known section keyword (`keywords.c:140`, `enums.h:469`) so it does not report an unknown-section error, but neither `addObject()` nor `parseLine()` processes any content for `s_BACKDROP`. All data lines silently return 0. The section is purely a GUI construct (`D.3_Map_Data_Section.md`: "map data are only used as a visualization aid… they play no role in any of the runoff or routing computations").

- **Sub-keywords parsed by GUI reader:** `BackdropWords` array (5 entries, index 0–4): `('FILE', 'DIMENSIONS', 'UNITS', 'OFFSET', 'SCALING')` (`objprops.txt:180–181`). Indices 2 (`UNITS`), 3 (`OFFSET`), and 4 (`SCALING`) are explicitly marked deprecated in the reader (`Uimport.pas:2762`, `2770`). The GUI writer never emits these three deprecated keywords; only `FILE` and `DIMENSIONS` appear in current output.

- **Deprecated sub-keywords (do not use in new files):**
  - `UNITS` — formerly set map distance units from inside `[BACKDROP]`; now ignored (writes to `MapForm.Map.Dimensions.Units` as a side-effect but is superseded by `[MAP].UNITS`).
  - `OFFSET X Y` — formerly specified a pixel offset for the backdrop; stored in local variables `BackdropX`/`BackdropY` but never applied in current code.
  - `SCALING X Y` — formerly specified a scale factor; stored in `BackdropW`/`BackdropH` but never applied in current code.

- **World file geo-referencing:** The GUI dialog (`Dbackdrp.pas`) supports an optional "world file" (6-line text file containing pixel-to-world transform coefficients) to automatically compute the `DIMENSIONS` bounding rectangle from real-world coordinates. This geo-referencing happens interactively and the result is stored as the four `DIMENSIONS` values; the world file itself is not referenced in the INP.

- **File path handling:** The GUI writer stores a path relative to the project directory (`Uexport.pas:2294`). The reader converts it to an absolute path (`Uimport.pas:2741`). Users editing INP files by hand may use absolute or relative paths; the engine ignores the path entirely.

- **Conditional emission:** The GUI writer only emits `[BACKDROP]` when `Backdrop.Filename` is non-empty (`Uexport.pas:2292`). If no backdrop has been loaded, the section is absent from the INP file. A database representation should treat the entire record as optional (nullable or absent row).

- **Internal fields not serialized to INP:** `TMapBackdrop` (`Umap.pas:61–69`) also contains `Watermark` (boolean, lightened rendering), `Grayscale` (boolean, monochrome rendering), and `Visible` (boolean, toggled via View >> Backdrop >> Watermark). These runtime display flags are not written to the INP file and revert to defaults (`False`) on each project load.

- **Uniqueness:** At most one backdrop per project; there is no name key. A relational table for this section would be a single-row lookup or a set of scalar values on the project/map record.
