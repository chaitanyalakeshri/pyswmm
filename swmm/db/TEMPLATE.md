# SWMM INP Section Documentation — Agent Instructions

You are documenting ONE SWMM INP file section for a future relational-database schema design (SQLite / GeoPackage). Another agent is handling every other section; consistency matters for merging.

## Your assignment
Your caller will give you:
- The section name (e.g. `JUNCTIONS`)
- The output file path (e.g. `/home/user/pyswmm/swmm/db/sections/15_JUNCTIONS.md`)

Write ONLY that one file. Do not modify anything else in the repo.

## Sources — explore freely, do not limit yourself

Complex sections have information scattered across multiple places. Grep widely, read surrounding code. A field's semantics often only become clear by consulting all three sources together.

**Reference manual** (well-structured markdown, derived from the official SWMM 5.2 users manual):
`/home/user/pyswmm/swmm/swmm-users-manual-version-5.2/` — start at `_INDEX.md`
- Chapter 6 — working with objects
- Chapter 11 — files used by SWMM
- Appendix A — useful lookup tables (culvert codes, pipe sizes, Manning coefficients, etc.)
- Appendix B — visual object properties (GUI-editable fields per object type)
- Appendix C — specialized editor dialogs (per-object detailed editors)
- Appendix D — command-line SWMM + canonical INP file format reference (D.2 is the authoritative INP syntax spec)

Use Grep to search across the whole manual for terms related to your section.

**SWMM engine C source** (the canonical parser — ground truth for validation rules):
`/home/user/pyswmm/swmm/swmm524_engine/src/`
- `input.c` — main parser entry points, the big dispatch switch, `readXxxx()` functions
- `keywords.c` — allowed keyword strings for enum fields
- `text.h` — format constants and section-name macros
- `enums.h` — enumerated type definitions
- `objects.h` — internal object struct layouts (reveals fields + types)
- Object-type files: `subcatch.c`, `node.c`, `link.c`, `gwater.c`, `lid.c`, `transect.c`, `inlet.c`, `street.c`, `xsect.c`, `infil.c`, `snow.c`, `rdii.c`, `climate.c`, `treatmnt.c`, `landuse.c`, `controls.c`, `table.c`, etc.

**SWMM GUI Delphi source** (shows user-facing field semantics, defaults, dropdown values):
`/home/user/pyswmm/swmm/swmm524_gui/Epaswmm5/`
- `Uimport.pas` — INP reader, per-section `ReadXxxData` procedures
- `Uexport.pas` — INP writer, per-section `ExportXxx` procedures (shows exact column order emitted)
- `D*.pas` / `D*.dfm` — editor dialogs. `.dfm` files reveal dropdown choices, default values, tooltips, validation
- `Uproject.pas`, `Uglobals.pas`, `Uobjects.pas` — internal object model and constants

## Required output structure

Your markdown file must follow this exact layout (for merge consistency):

```
# [SECTION_NAME]

**Purpose:** one paragraph — what this section defines and why it exists.

**Occurrence:** one of — "single global row" | "one row per object" | "multiple rows per object" | "child/sub-data under a parent" — with cardinality notes.

**SWMM source references:**
- Engine parser: `<file>:<line>` — function `<name>`
- Engine writer: (engine does not write INP; this applies to every section — omit or note the report-echo function if one exists in `inputrpt.c`)
- GUI reader: `Uimport.pas:<line>` — procedure `<name>`
- GUI writer: `Uexport.pas:<line>` — procedure `<name>`
- GUI editor dialog(s): `<file>` (if applicable)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — <section heading>
- Additional manual refs: Appendix B/C/chapter entries that elaborate

## Row Format

Show the exact column layout per line as the engine/GUI expects. Include sub-lines or continuation rows. Quote the literal format string from the manual when available. Example:

```
Name  X  Y  MaxDepth  InitDepth  SurDepth  AreaPonded
```

## Fields

For EVERY field (including optional trailing columns), produce a subsection in this EXACT format:

### <FieldName>

- **Data type:** one of — INTEGER | REAL | TEXT | BOOLEAN | DATE | TIME | ENUM | NAME_REF | COORD
- **Required:** yes | no (default: `<value>`)
- **Units:** US units / SI units, or "unitless", or "n/a"
- **Valid values / range:**
  - Numeric: exact range e.g. `> 0`, `≥ 0`, `0–1`, `0–100 (%)`, `any real`
  - Enum: enumerate ALL allowed keyword strings (get from `keywords.c` or dialog `.dfm`); include synonyms
  - Text: length or character constraints if any
  - Cross-reference: name the referenced section and field
- **Default:** value or "none"
- **Cross-section dependency:** exact referenced section and field, or "None". Examples:
  - `[RAINGAGES].Name`
  - `[CURVES].Name where curve type ∈ {PUMP1, PUMP2, PUMP3, PUMP4, PUMP5}`
  - `[PATTERNS].Name`
- **Database-key hint:** suggest role only — "primary identifier of this row" | "foreign key to [XXX].Name" | "composite PK with <other fields>" | "plain data – no key role". Do NOT design the schema.
- **Technical description:** what the field means physically/logically, any conditional behaviour, interaction with other fields, edge cases.
- **Source of truth:** `<file>:<line>` where parsing/validation occurs.

## Notes

- Section-level quirks (prefix matching, optional trailing columns, continuation lines, reserved keywords)
- Known aliases (e.g. `[TABLES]` read-aliases `[CURVES]`)
- Deprecated behaviour / legacy compatibility
- Cross-section constraints (e.g. pump link types 1–5 require a curve of matching type in `[CURVES]`)
- Whether the same object can legitimately appear in multiple rows here
- Ordering, uniqueness, or composite-key considerations the DB designer must know
```

## Style rules

- Every factual claim must be grounded in a file:line citation. No guesses.
- Use the template above verbatim — section headers, bullets, field order. The merge is mechanical.
- If a field is complex, write more. If trivial, two lines are fine.
- Document ALL fields, including optional trailing columns.
- Length: simple sections ~400 words; complex sections (`CONTROLS`, `XSECTIONS`, `LID_CONTROLS`, `OPTIONS`, `CURVES`) may be 2000–4000+ words. Do not truncate for brevity.
- No meta-commentary about the prompt or your process.
- First line of the file must be `# [SECTION_NAME]` (with the brackets).

## After writing

Reply with exactly: `Wrote <path> covering N fields.`
