# [TITLE]

**Purpose:** Attaches a descriptive title and optional multi-line notes to a SWMM project. The text is free-form; SWMM does not parse it for values. The first line is used as a page header in the output report file and, optionally, in the GUI print page setup. Remaining lines serve as project notes. The section is entirely optional: a project runs identically whether or not it is present.

**Occurrence:** Multiple rows per object — up to `MAXTITLE` (3) lines accepted by the engine; the GUI stores an unlimited number of lines internally (all emitted to the INP), but the engine only keeps the first 3 non-empty lines.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/input.c:694` — function `readTitle`; dispatch case at `input.c:475`
- Engine report echo: `swmm524_engine/src/report.c:235` — function `report_writeTitle` (writes stored title lines to the `.rpt` report file; not an INP writer)
- Engine writer: engine does not write INP files. `inputrpt.c` does not echo this section.
- GUI reader: `Uimport.pas:263` — function `ReadTitleData`; triggered at `Uimport.pas:3081–3083` for all non-comment lines while in section 0 (`[TITLE]`)
- GUI writer: `Uexport.pas:60` — procedure `ExportTitle`; called first among all sections at `Uexport.pas:2330`
- GUI editor dialog: `Dnotes.pas` — `TNotesEditorForm` (memo with optional "Use as header" checkbox); invoked from `Uedit.pas:1768`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[TITLE]` (page beginning at "Section: [TITLE]")
- Additional manual refs: overview list at D.2 line 19; example project file at D.2 line 59

## Row Format

```
<any free-form text — no column structure>
```

Any number of lines may be present. Lines are not parsed into tokens. There are no mandatory keywords and no column positions. The GUI emits a comment line before the data:

```
[TITLE]
;;Project Title/Notes
<line 1>
<line 2>
...
```

The `;;Project Title/Notes` line is a comment (starts with `;;`) and is ignored by both the engine and GUI reader.

## Fields

### TitleLine

- **Data type:** TEXT
- **Required:** no (default: empty — section may be omitted entirely)
- **Units:** n/a
- **Valid values / range:** Any printable text. Newline (`\n`, ASCII 10) is stripped from the end of each line before storage (`input.c:708–709`). Maximum length per line: `MAXMSG` = 1024 characters (`consts.h:23`). The engine stores at most `MAXTITLE` = 3 lines (`consts.h:22`); lines beyond the third are silently discarded by the engine (`input.c:702–714`). The GUI imposes no count limit on import/export (`Uexport.pas:69–70`).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Each non-blank line in the `[TITLE]` section is passed verbatim to `readTitle` (`input.c:694`). The function iterates over `Title[0..MAXTITLE-1]` (`globals.h:61`) and places the line in the first slot that is currently empty. Once all three slots are filled, subsequent lines are ignored with no error. The engine stores the entire raw line (after newline stripping) as a single string; it is never tokenised or interpreted. `Title[0]` (the first line) is additionally used as a header in the SWMM interface (routing) output file (`iface.c:332`) and as the page header in the report (`report.c:245–248`). The GUI designates `Project.Title` (a single `String` field in `Uproject.pas:752`) as exactly `Lists[NOTES].Strings[0]` — the first line — and updates it whenever the notes editor is closed (`Uedit.pas:1780`). If `TitleAsHeader` (`Uglobals.pas:410`) is checked in the notes editor (`Dnotes.pas:96`), the GUI also sets it as the print page header (`Uedit.pas:1786–1788`). Comment lines beginning with `;;` are skipped by the GUI reader (`Uimport.pas:3083`) and therefore never reach `ReadTitleData`.
- **Source of truth:** `swmm524_engine/src/input.c:694–717` (parsing); `swmm524_engine/src/consts.h:22–23` (limits); `swmm524_engine/src/globals.h:61` (storage array)

## Notes

- **Section keyword prefix matching:** The engine matches section headers using the `match()` function (`input.c:798`), which checks whether the section keyword string is a prefix of the bracketed token. The prefix for `[TITLE]` is `[TITLE` (`text.h:403`), meaning `[TITLE]`, `[TITLES]`, etc. are all accepted. Section keywords are case-insensitive.
- **No tokens, no errors:** Unlike all other sections, lines inside `[TITLE]` are never split into tokens by `getTokens`. The raw line pointer is passed directly to `readTitle`. Because of this, no parse error can arise from malformed content.
- **Overflow silently dropped:** If more than 3 lines of title text are present in the INP, lines 4 and beyond are accepted without an error code (`readTitle` returns 0 regardless, `input.c:716`), but they are never stored in the engine. The GUI writes all lines it holds to the INP, so a round-trip through the engine can lose lines 4+.
- **GUI internal storage:** The GUI stores title/notes in `Project.Lists[NOTES]` (a `TStringList`, category index `NOTES = 0`, `Uproject.pas:40`). All lines of `Lists[NOTES]` are emitted verbatim to the INP by `ExportTitle` (`Uexport.pas:69–70`), with no upper-bound limit imposed by the GUI.
- **Ordering:** `ExportTitle` is called first among all export procedures (`Uexport.pas:2330`), so `[TITLE]` always appears at the top of the INP file emitted by the GUI.
- **Sections can appear in any order:** The D.2 manual states sections may appear in arbitrary order; `[TITLE]` has no special positional requirement for the engine parser.
- **Uniqueness / composite key:** Not applicable. Multiple rows for the same project are normal and expected. No uniqueness constraint applies.
- **Database design note:** Because title content is purely descriptive and not referenced by any other section, a database schema should represent this as a simple one-to-many table (project → title_lines) or as a TEXT column in the project table if only the first line is of interest.
