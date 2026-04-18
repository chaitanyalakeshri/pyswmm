# Chapter 12 — Using Add-In Tools

## What This Folder Contains
Documentation for SWMM's add-in tool framework, which allows third-party external applications to be registered and launched from the Tools menu while SWMM is running, with data exchange via files and the Windows clipboard.

## Files

| File | Description |
|------|-------------|
| `12.1_What_Are_Add-In_Tools.md` | Introduces add-in tools: external applications extending SWMM. Examples: rainfall statistical analysis, spreadsheet editors, unit hydrograph estimators, storage analysis post-processors, alternative routing programs. Data exchange via SWMM files (`.inp`, `.rpt`, `.out`, `.rif`) and clipboard. |
| `12.2_Configuring_Add-In_Tools.md` | Tool Properties dialog fields: Tool Name, Program path, Working Directory, Command-line Parameters. Macro symbols for dynamic path substitution: `$PROJDIR`, `$SWMMDIR`, `$INPFILE`, `$RPTFILE`, `$OUTFILE`, `$RIFFILE`. Execution options: "Disable SWMM while executing" and "Update SWMM after closing." |

## Macro Symbols Reference

| Symbol | Expands To |
|--------|-----------|
| `$PROJDIR` | Directory containing the current SWMM project |
| `$SWMMDIR` | Directory where SWMM is installed |
| `$INPFILE` | Full path to current project `.inp` file |
| `$RPTFILE` | Full path to current project `.rpt` file |
| `$OUTFILE` | Full path to current project `.out` file |
| `$RIFFILE` | Full path to current runoff interface file |

## Key Terms & Concepts
- Add-in tool registration via Tools > Configure Tools
- Command-line parameter substitution with `$` macros
- Tool execution: synchronous (SWMM disabled) or asynchronous
- "Update SWMM after closing": SWMM re-reads `.inp` after tool modifies it
- Use cases: preprocessing, data editing, post-processing, alternative algorithms

## Typical Queries This Folder Answers
- What are SWMM add-in tools and what can they do?
- How do I register an external program to run from SWMM's Tools menu?
- How do I pass the current project file path to an external tool?
- What macro symbols are available for dynamic path substitution?
- How can an external tool read SWMM results and write back to the model?
- What does "Disable SWMM while executing" mean?
- What does "Update SWMM after closing" do?
- What types of practical add-in tools could I create?

## Related Sections
- SWMM file formats for data exchange → `chapter_11_files_used_by_swmm/`
- Program preferences → `chapter_04_swmms_main_window/4.10_Setting_Program_Preferences.md`
