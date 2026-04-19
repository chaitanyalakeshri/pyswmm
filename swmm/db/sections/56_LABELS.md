# [LABELS]

**Purpose:** Assigns X,Y map coordinates and display text to user-defined annotation labels on the SWMM study area map. Each row defines one text label, its position, an optional anchor node that keeps the label near a network object during zoom operations, and optional font styling (name, size, bold, italic). This section is purely a GUI visualization aid; it has no effect on any hydrologic or hydraulic computation.

**Occurrence:** One row per map label. A project may have zero or more labels. Each row describes exactly one label; there are no continuation lines.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/input.c:631` — `parseLine()` `default: return 0` branch; `s_LABEL` is recognized in the section keyword table (`keywords.c:139`, `enums.h:468`) but the engine performs no action on its data — all rows are silently ignored.
- Engine writer: Engine does not write INP files; no echo function exists for this section.
- GUI reader: `Uimport.pas:2677` — function `ReadLabelData`; dispatched at `Uimport.pas:2926` for section index 42.
- GUI writer: `Uexport.pas:2265` — inside `ExportMap()`; emits all eight columns unconditionally for every label.
- GUI editor dialog: `Dlabel.pas` — minimal frameless text-entry dialog for initial label text; font edited via `Uedit.pas:398` `EditLabelFont()` using the system `FontDialog`.
- Manual: `appendix_D_command_line_swmm/D.3_Map_Data_Section.md` — section `[LABELS]` (lines 103–115).
- Additional manual refs: `appendix_B_visual_object_properties/B.12_Map_Label_Properties.md` — GUI property editor fields.

## Row Format

```
Xcoord  Ycoord  "Label"  (Anchor  "Font"  Size  Bold  Italic)
```

Columns 1–3 are required. Columns 4–8 are optional trailing columns written by the GUI but not mandatory for a valid INP file.

The manual states the format as:

> *Xcoord  Ycoord  Label (Anchor  Font  Size  Bold  Italic)*

(`D.3_Map_Data_Section.md`, line 103)

The GUI always emits all eight columns; when no anchor exists it writes `""` for column 4 (`Uexport.pas:2273`).

## Fields

### Xcoord

- **Data type:** REAL
- **Required:** yes
- **Units:** map coordinate units (same system used by `[MAP]` DIMENSIONS — may be feet, meters, degrees, or dimensionless)
- **Valid values / range:** any real number; the coordinate system origin is the lower-left corner of the map bounding rectangle
- **Default:** none
- **Cross-section dependency:** None (coordinate space defined by `[MAP]` DIMENSIONS)
- **Database-key hint:** plain data – no key role (forms composite position with Ycoord)
- **Technical description:** Horizontal coordinate of the upper-left corner of the label as displayed on the study area map. The GUI stores this as an `Extended` (80-bit float) in `TMapLabel.X` (`Uproject.pas:712`). The export format string is `'%-18.<D>f'` where `<D>` is the map's `Digits` precision setting (`Uexport.pas:2125`). A value of `MISSING` (= −1.0×10¹⁰, `Uglobals.pas:196`) indicates the label has not been placed; rows with `MISSING` coordinates are not exported by the GUI.
- **Source of truth:** `Uimport.pas:2691` (`Uutils.GetExtended(TokList[0], X)`); `Uproject.pas:712` (field declaration)

---

### Ycoord

- **Data type:** REAL
- **Required:** yes
- **Units:** map coordinate units (same system as Xcoord)
- **Valid values / range:** any real number
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Vertical coordinate of the upper-left corner of the label on the study area map. Stored as `TMapLabel.Y` (`Uproject.pas:713`). Parsed identically to Xcoord.
- **Source of truth:** `Uimport.pas:2693` (`Uutils.GetExtended(TokList[1], Y)`)

---

### Label

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** any text string; must be surrounded by double quotes in the INP file; double quotes within the text are not supported. The GUI stores the string in `Project.Lists[MAPLABEL]` (`Uimport.pas:2700`); TokList[2] is the third token after the parser strips surrounding quotes.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** primary identifier of this row (no uniqueness constraint is enforced — two labels may share the same text)
- **Technical description:** The visible text string drawn on the map. Entered by the user through the `TLabelForm` dialog (`Dlabel.pas`). Stored as a `PChar` pointer (`TMapLabel.Text`) referencing the string held in the project's `MAPLABEL` list (`Uproject.pas:711`). When exported the GUI wraps the text in double quotes: `'"' + Slist[J] + '"'` (`Uexport.pas:2276`). There is no enforced maximum length in the parser; practical limits are imposed by `MAXLINE` (the engine's line-length limit, `input.c:148`) if the file is also processed by the command-line engine, though the engine ignores label data entirely.
- **Source of truth:** `Uimport.pas:2696` (`S := TokList[2]`); `Uimport.pas:2700` (added to `MAPLABEL` list)

---

### Anchor

- **Data type:** NAME_REF
- **Required:** no (default: `""`)
- **Units:** n/a
- **Valid values / range:** name of an existing node (junction, outfall, divider, or storage unit) in the project; or an empty double-quoted string `""` to indicate no anchoring. The manual (`D.3_Map_Data_Section.md`, line 107) and `B.12_Map_Label_Properties.md` (line 10) also mention subcatchments as valid anchors, but the GUI import parser resolves the name exclusively through `Project.FindNode()` (`Uimport.pas:2707`), which searches only `JUNCTION..STORAGE` (`Uproject.pas:1279`). An unresolved name (including a subcatchment name) is silently ignored — `aMapLabel.Anchor` remains `nil`.
- **Default:** `""` (no anchor; `TMapLabel.Anchor := nil` in constructor, `Uproject.pas:1780`)
- **Cross-section dependency:** `[JUNCTIONS].Name`, `[OUTFALLS].Name`, `[DIVIDERS].Name`, or `[STORAGE].Name`
- **Database-key hint:** foreign key to node tables (JUNCTION / OUTFALL / DIVIDER / STORAGE); nullable
- **Technical description:** When set to a valid node name, the anchor causes the label to maintain a constant pixel offset from the anchor node as the map is zoomed in, preventing the label from drifting outside the visible area. The GUI exports `""` when `Anchor = nil` and the bare node ID when `Anchor <> nil` (`Uexport.pas:2273–2274`). The import checks `Ntoks >= 4` and `Length(TokList[3]) > 0` before attempting resolution (`Uimport.pas:2704–2708`); an empty string or `""` token causes the condition `Length > 0` to fail (after quote-stripping), leaving the anchor nil. Stored as a `TNode` pointer in `TMapLabel.Anchor` (`Uproject.pas:714`).
- **Source of truth:** `Uimport.pas:2704–2708`; `Uproject.pas:714, 1279, 1780`

---

### Font

- **Data type:** TEXT
- **Required:** no (default: `"Arial"`)
- **Units:** n/a
- **Valid values / range:** any font name available on the host operating system; font names containing spaces must be surrounded by double quotes per the manual (`D.3_Map_Data_Section.md`, line 109). The GUI always writes the font name in double quotes (`Uexport.pas:2277`).
- **Default:** `"Arial"` (set in `TMapLabel.Create`, `Uproject.pas:1781`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Name of the Windows font used to draw the label. Stored as `TMapLabel.FontName` (type `String`, `Uproject.pas:715`). Read from `TokList[4]` when `Ntoks >= 5` (`Uimport.pas:2710`). If this column is absent the default `"Arial"` is used. The font is applied via `TMapLabel.GetFont()` (`Uproject.pas:1787`) to produce a `TFont` object for rendering.
- **Source of truth:** `Uimport.pas:2710`; `Uproject.pas:715, 1781`

---

### Size

- **Data type:** INTEGER
- **Required:** no (default: `10`)
- **Units:** typographic points
- **Valid values / range:** positive integer; any value accepted by `StrToInt`; the Windows font system imposes practical limits (typically 1–2048 pt). No explicit range check in the parser.
- **Default:** `10` (set in `TMapLabel.Create`, `Uproject.pas:1782`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Font size in points for the label text. Stored as `TMapLabel.FontSize` (type `Integer`, `Uproject.pas:716`). Parsed with `StrToInt(TokList[5])` when `Ntoks >= 6` (`Uimport.pas:2711`). Exported as a decimal integer `Format('%d', [FontSize])` (`Uexport.pas:2278`). No validation is performed — a non-numeric token would raise a run-time exception in `StrToInt`.
- **Source of truth:** `Uimport.pas:2711`; `Uproject.pas:716, 1782`

---

### Bold

- **Data type:** INTEGER (Boolean encoded as 0/1)
- **Required:** no (default: `0`)
- **Units:** n/a
- **Valid values / range:** `0` (not bold) or `1` (bold). The manual uses the keywords `YES`/`NO` (`D.3_Map_Data_Section.md`, line 113) but the GUI reads and writes integer 0/1 (`Uimport.pas:2712–2713`, `Uexport.pas:2279–2280`). The engine ignores this field entirely.
- **Default:** `0` (`FontBold := False` in `TMapLabel.Create`, `Uproject.pas:1783`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Controls whether the label is drawn in bold weight. Stored as `TMapLabel.FontBold` (type `Boolean`, `Uproject.pas:717`). The import reads `TokList[6]` when `Ntoks >= 7` and sets `FontBold := True` if the integer value equals 1 (`Uimport.pas:2712–2713`). The export converts the boolean with `if FontBold then TrueFalse := 1 else TrueFalse := 0` then writes `IntToStr(TrueFalse)` (`Uexport.pas:2279–2280`). Note: the manual documents `YES`/`NO` but actual INP files produced by the GUI use `1`/`0`.
- **Source of truth:** `Uimport.pas:2712–2713`; `Uproject.pas:717, 1783`

---

### Italic

- **Data type:** INTEGER (Boolean encoded as 0/1)
- **Required:** no (default: `0`)
- **Units:** n/a
- **Valid values / range:** `0` (not italic) or `1` (italic). Same encoding as Bold; manual says `YES`/`NO` but GUI writes `0`/`1`.
- **Default:** `0` (`FontItalic := False` in `TMapLabel.Create`, `Uproject.pas:1784`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Controls whether the label is drawn in italic style. Stored as `TMapLabel.FontItalic` (type `Boolean`, `Uproject.pas:718`). Parsed from `TokList[7]` when `Ntoks >= 8` (`Uimport.pas:2714–2715`). Exported analogously to Bold (`Uexport.pas:2281–2282`).
- **Source of truth:** `Uimport.pas:2714–2715`; `Uproject.pas:718, 1784`

---

## Notes

- **GUI-only section.** The SWMM command-line engine recognises the `[LABEL` section-keyword prefix and assigns it enum value `s_LABEL` (`enums.h:468`), but `parseLine()` falls to `default: return 0` (`input.c:631`), meaning all label rows are silently discarded. The section does not affect simulation results.
- **Prefix matching.** Both the engine (`text.h:448`, `ws_LABEL = "[LABEL"`) and the GUI (`Uimport.pas:103`, `'[LABELS'`) use prefix-based keyword matching. The heading `[LABELS]` matches the stored prefix `[LABEL`/`[LABELS` in both parsers. A heading of bare `[LABEL]` would also be accepted.
- **Column 4 (Anchor) encoding.** When no anchor is set the GUI exports the literal two-character token `""` (empty double-quoted string). On re-import `Length(TokList[3])` evaluates to zero after quote-stripping, so the anchor remains `nil` (`Uimport.pas:2706`).
- **Font columns always written.** The GUI export (`Uexport.pas:2265–2285`) emits all eight columns (Xcoord, Ycoord, Label, Anchor, Font, Size, Bold, Italic) for every label regardless of whether the font matches the default. The manual states "if no font information is provided then a default font is used" (`D.3_Map_Data_Section.md`, line 115), implying columns 4–8 are truly optional when writing INP files by hand.
- **Manual vs. GUI discrepancy on Bold/Italic encoding.** The manual (`D.3_Map_Data_Section.md:113`) describes Bold and Italic as accepting `YES`/`NO`. The GUI reader expects integer `1`/`0` and uses `StrToInt` (`Uimport.pas:2712–2715`); `YES` would raise a run-time conversion error. Files produced by the GUI always use `1`/`0`.
- **Anchor resolves only nodes.** Despite the manual and `B.12` documentation stating the anchor can be a "node or subcatchment", `ReadLabelData` calls `Project.FindNode()` which searches only `JUNCTION..STORAGE` (`Uproject.pas:1279`). Subcatchment names are silently unresolved.
- **No uniqueness constraint.** Multiple labels may have identical text. There is no primary key enforced at the INP level; rows are identified positionally in the `Project.Lists[MAPLABEL]` list.
- **No row ordering constraint.** Labels may appear in any order within the section; the GUI preserves insertion order.
- **Coordinate system.** Map coordinates have no inherent unit unless the `[MAP]` section specifies `UNITS FEET`, `METERS`, `DEGREES`, or `NONE`. Labels share the same coordinate system as `[COORDINATES]`, `[VERTICES]`, `[POLYGONS]`, and `[SYMBOLS]`.
- **Section not listed in D.2.** The `[LABELS]` section is documented in `D.3_Map_Data_Section.md` (map data annex), not in the main `D.2_Input_File_Format.md` INP reference, because it is a GUI visualisation construct rather than a simulation-input section.
