# [TITLE]

**Purpose:** Attaches a descriptive title and optional multi-line notes to a SWMM project. The text is entirely free-form; SWMM does not parse it for any values. The first line is used as a page header in the output `.rpt` report file, as the header line in routing interface files, and optionally in the GUI print page setup. Remaining lines serve as project notes visible in the GUI browser. The section is entirely optional: a project runs identically whether or not it is present.

**Occurrence:** Multiple rows per object — up to `MAXTITLE` (3) lines are accepted and stored by the engine; the GUI stores an unlimited number of lines internally (all emitted to the INP), but the engine silently discards any line beyond the third.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/input.c:694` — function `readTitle`; dispatch case at `input.c:475`
- Engine report echo: `swmm524_engine/src/report.c:235` — function `report_writeTitle` (writes stored title lines to the `.rpt` report file; not an INP writer). Also used in `swmm524_engine/src/iface.c:332` where `Title[0]` is written as a header into the routing interface file.
- Engine writer: the engine does not write INP files. `inputrpt.c` does not echo this section.
- GUI reader: `Uimport.pas:263` — function `ReadTitleData`; triggered at `Uimport.pas:3081–3083` for all non-comment lines while the current section is 0 (`[TITLE]`)
- GUI writer: `Uexport.pas:60` — procedure `ExportTitle`; called first among all section export procedures at `Uexport.pas:2330`
- GUI editor dialog: `Dnotes.pas` — `TNotesEditorForm` (free-form memo with optional "Use as header" checkbox); invoked from `Uedit.pas:1768` via `EditNotes`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — section beginning at line 86 ("Section: [TITLE]")
- Additional manual refs: section listing overview at D.2 line 19; example project file at D.2 line 59

## Row Format

```
<any free-form text — no column structure>
```

Any number of lines may be present. Lines are not parsed into tokens. There are no mandatory keywords and no fixed column positions. The GUI emits a comment header line before the data:

```
[TITLE]
;;Project Title/Notes
<line 1>
<line 2>
...
```

The `;;Project Title/Notes` line begins with `;;` and is a comment; it is ignored by both the engine parser (`;` prefix, `input.c:186`) and the GUI reader (`Uimport.pas:3083`).

## Fields

### TitleLine

- **Data type:** TEXT
- **Required:** no (default: empty — section may be omitted entirely)
- **Units:** n/a
- **Valid values / range:** Any printable text. A trailing newline character (ASCII 10) is stripped from the end of each line before storage (`input.c:708–709`). Maximum length per line: `MAXMSG` = 1024 characters (`consts.h:23`). The engine stores at most `MAXTITLE` = 3 lines (`consts.h:22`); lines beyond the third are silently ignored by the engine (`input.c:702–714`). The GUI imposes no count limit on import or export (`Uexport.pas:69–70`).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Each non-blank, non-comment line in the `[TITLE]` section is passed verbatim to `readTitle` (`input.c:694`). The function iterates over `Title[0..MAXTITLE-1]` (declared in `globals.h:61` as `char Title[MAXTITLE][MAXMSG+1]`) and places the raw line text into the first slot whose length is currently zero. Once all three slots are filled, subsequent lines produce no error and are silently discarded (`readTitle` always returns 0, `input.c:716`). The line is never tokenised or interpreted in any way.

  `Title[0]` (the first title line) has two secondary uses in the engine: (1) it is written as the second line of any routing outflows interface file (`iface.c:332`); (2) all non-empty slots are written to the `.rpt` report file header by `report_writeTitle` (`report.c:245–248`), which is called immediately after input reading completes (`swmm5.c:298`).

  In the GUI, `Project.Title` (`Uproject.pas:752`) holds a single `String` that is always kept equal to `Lists[NOTES].Strings[0]` — the first title line. It is updated whenever the notes editor is closed (`Uedit.pas:1780`). The notes editor dialog (`Dnotes.pas`) exposes a "Use as header" checkbox whose state is stored in `TitleAsHeader` (`Uglobals.pas:410`); when set, the GUI additionally copies `Project.Title` into the print page setup header (`Uedit.pas:1786–1788`). All lines in `Project.Lists[NOTES]` (category `NOTES = 0`, `Uproject.pas:40`) are emitted verbatim to the INP by `ExportTitle` without truncation.

- **Source of truth:** `swmm524_engine/src/input.c:694–717` (parsing and storage); `swmm524_engine/src/consts.h:22–23` (limits `MAXTITLE` and `MAXMSG`); `swmm524_engine/src/globals.h:61` (storage array declaration)

## Notes

- **Section keyword prefix matching:** The engine matches section headers using `findmatch` (`input.c:107`, `input.c:207`), which tests whether a candidate string is a prefix of the keyword array entry. The registered prefix for this section is `[TITLE` (`text.h:403`), so `[TITLE]`, `[TITLES]`, or any string beginning with `[TITLE` are all accepted. Matching is case-insensitive.
- **No tokenisation, no parse errors:** Unlike every other SWMM section, lines in `[TITLE]` bypass the `getTokens` tokeniser entirely. The raw `line` pointer is passed directly to `readTitle` (`input.c:476`). Because no token parsing occurs, there is no mechanism by which malformed content can produce a parse error; `readTitle` always returns 0.
- **Silent overflow:** Lines 4 and beyond (when more than 3 lines are present) are accepted without any error or warning code but are never stored in the engine arrays. The GUI writes all lines it holds to the INP, so a round-trip through a GUI save → engine run can result in the engine retaining only the first 3 lines while the INP retains all of them.
- **GUI internal storage model:** The GUI stores all title/notes lines in `Project.Lists[NOTES]` (a `TStringList`, category index `NOTES = 0`, `Uproject.pas:40`). The derived field `Project.Title` is always the first string of that list and is kept synchronised by the notes editor (`Uedit.pas:1775–1780`). On import, comment lines starting with `;;` are skipped (`Uimport.pas:3083`) and therefore never reach `ReadTitleData`.
- **Ordering in exported file:** `ExportTitle` is the first procedure called in the INP export sequence (`Uexport.pas:2330`), so `[TITLE]` always appears at the top of a GUI-generated INP file. The engine parser accepts sections in any order.
- **Sections may appear in any order:** D.2 states explicitly that sections can appear in any arbitrary order. `[TITLE]` has no special positional requirement for the engine.
- **Uniqueness / composite key:** Not applicable. Multiple lines for a single project are normal. No uniqueness constraint applies within this section.
- **Database design note:** Because title content is purely descriptive and unreferenced by any other section, a DB schema may represent it either as a simple one-to-many table (project_id → line_number, line_text) or, if only the first line matters, as a single TEXT column in the project metadata table. The engine limit of 3 stored lines should be noted as a behavioural cap distinct from the INP storage limit.
