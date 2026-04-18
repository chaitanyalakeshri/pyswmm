# [FILES]

**Purpose:** Declares optional binary or text interface files that the current simulation either reads as pre-computed inputs (`USE`) or writes as output for re-use in later runs (`SAVE`). Six file types are supported: RAINFALL, RUNOFF, HOTSTART, RDII, INFLOWS, and OUTFLOWS. The section allows large models to be decomposed across runs (e.g., save runoff from one run, re-use it in another), avoids repeating expensive computations, and enables daisy-chained sub-model linkage via routing interface files.

**Occurrence:** Multiple rows per project (one row per file assignment). Each row specifies one mode/type/filename triplet. A given file type may appear twice only for HOTSTART (one `USE` row and one `SAVE` row with different filenames). All other file types may appear at most once.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/iface.c:66` — function `iface_readFileParams`
- Engine dispatcher: `swmm524_engine/src/input.c:610` — `case s_FILE: return iface_readFileParams(Tok, Ntokens);`
- Engine writer: Engine does not write INP. No `inputrpt.c` echo exists for `[FILES]`.
- GUI reader: `Uimport.pas:2151` — procedure `ReadFileData` (dispatched at `Uimport.pas:2920`)
- GUI writer: `Uexport.pas:1969` — procedure `ExportFiles`
- GUI editor dialog(s): Simulation Options → Files page (described in `chapter_08_running_a_simulation/8.1_Setting_Simulation_Options.md`); no standalone `.dfm` dialog — managed via `Project.IfaceFiles` string list in `Uproject.pas:766`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [FILES] at line 365
- Additional manual refs: `chapter_11_files_used_by_swmm/11.7_Interface_Files.md` (full description of every interface file type and their binary/text formats); `chapter_08_running_a_simulation/8.1_Setting_Simulation_Options.md` lines 178–186 (GUI interface)

## Row Format

Each data line contains exactly three whitespace-delimited tokens:

```
Mode  FileType  Fname
```

Where `Mode` is `USE` or `SAVE`, `FileType` is one of `RAINFALL RUNOFF HOTSTART RDII INFLOWS OUTFLOWS`, and `Fname` is the file path (quoted if it contains spaces).

The manual lists all valid combinations as:

```
USE / SAVE  RAINFALL   Fname
USE / SAVE  RUNOFF     Fname
USE / SAVE  HOTSTART   Fname
USE / SAVE  RDII       Fname
USE         INFLOWS    Fname
SAVE        OUTFLOWS   Fname
```

Source: `appendix_D_command_line_swmm/D.2_Input_File_Format.md:373–383`

The GUI writer emits lines as `Mode<Tab>FileType<Tab>"Fname"` (always double-quoting the path), shown at `Uexport.pas:1990`.

## Fields

### Mode

- **Data type:** ENUM
- **Required:** yes
- **Units:** n/a
- **Valid values / range:**
  - `USE` — read the file as input to this run
  - `SAVE` — write the file as output from this run
  - (`NO` and `SCRATCH` are also recognised by `FileModeWords` at `keywords.c:56` but are not valid in the `[FILES]` INP section; they are internal engine states only)
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** composite PK with FileType (no two rows may share the same Mode+FileType combination, with the exception of HOTSTART which may appear once as USE and once as SAVE)
- **Technical description:** Controls whether the engine opens the named file for reading (`USE_FILE = 2`) or writing (`SAVE_FILE = 3`). Validated by `findmatch(tok[0], FileModeWords)` at `iface.c:83`; an unrecognised keyword returns `ERR_KEYWORD`. If the mode token is present but no filename token follows (`ntoks < 3`), the function returns 0 silently (no file assignment is made) — `iface.c:87`. INFLOWS only accepts `USE`; OUTFLOWS only accepts `SAVE`; violations return `ERR_ITEMS` at `iface.c:122` and `iface.c:128` respectively.
- **Source of truth:** `swmm524_engine/src/iface.c:83–84`; enum definitions at `swmm524_engine/src/enums.h:101–105`; keyword strings at `swmm524_engine/src/text.h:343–349`

---

### FileType

- **Data type:** ENUM
- **Required:** yes
- **Units:** n/a
- **Valid values / range:**
  - `RAINFALL` — binary rainfall interface file (collated rain gage data)
  - `RUNOFF` — binary runoff interface file (subcatchment runoff results)
  - `HOTSTART` — binary hot-start file (full hydraulic/hydrologic/WQ state snapshot)
  - `RDII` — RDII interface file (rainfall-dependent I/I time series; binary when SWMM-generated, text when externally created)
  - `INFLOWS` — text routing interface file used as inflow source (SWMM5 format, `USE` only)
  - `OUTFLOWS` — text routing interface file written from outfall results (`SAVE` only)
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** composite PK with Mode
- **Technical description:** Determines which internal file handle (`Frain`, `Frunoff`, `Fhotstart1`/`Fhotstart2`, `Frdii`, `Finflows`, `Foutflows`) is populated. Validated by `findmatch(tok[1], FileTypeWords)` at `iface.c:85`. The enum ordinals are `RAINFALL_FILE=0, RUNOFF_FILE=1, HOTSTART_FILE=2, RDII_FILE=3, INFLOWS_FILE=4, OUTFLOWS_FILE=5` (`enums.h:90–96`). For HOTSTART, the engine routes `USE` to `Fhotstart1` and `SAVE` to `Fhotstart2` (`iface.c:104–113`), permitting a single run to both read and write a hot-start file with different names. Rainfall, Runoff, and RDII files cannot be simultaneously used and saved in the same run (manual: `D.2_Input_File_Format.md:391`). The RDII file path is stored without calling `addAbsolutePath` (unlike the other types) — `iface.c:118`. The text/binary distinction: RAINFALL, RUNOFF, and HOTSTART are always binary; RDII is binary when generated by SWMM and text when generated externally; INFLOWS/OUTFLOWS are always text (SWMM5 routing interface format) per `chapter_11_files_used_by_swmm/11.7_Interface_Files.md:55,69`.
- **Source of truth:** `swmm524_engine/src/iface.c:85–86,91–132`; `swmm524_engine/src/enums.h:89–96`; `swmm524_engine/src/keywords.c:54–55`; keyword strings at `swmm524_engine/src/text.h:332–338`

---

### Fname

- **Data type:** TEXT
- **Required:** no (default: `""` — if omitted the mode/type tokens are parsed but no file is assigned; see `iface.c:87`)
- **Units:** n/a
- **Valid values / range:**
  - Any valid filesystem path; maximum 259 characters (`MAXFNAME` defined at `swmm524_engine/src/consts.h:25`)
  - Enclose in double quotes if the path contains spaces (manual: `D.2_Input_File_Format.md:393`)
  - May be a relative path; the engine converts it to an absolute path (anchored to the directory of the `.inp` file) via `addAbsolutePath()` for all types except RDII — `iface.c:95,100,107,112,124,130,118`
  - The GUI reader wraps the path in double quotes and resolves it to a full path via `FullPathName` before storing in `Project.IfaceFiles` (`Uimport.pas:2161`); the GUI writer converts back to a relative path via `RelativePathName` on export (`Uexport.pas:1989`)
- **Default:** none (row is silently no-op if token is absent)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role (the primary key is the Mode+FileType composite)
- **Technical description:** The path to the interface file on disk. For INFLOWS and OUTFLOWS (routing interface files), the file must conform to the SWMM5 routing interface text format described in `chapter_11_files_used_by_swmm/11.7_Interface_Files.md:69–98`: first line `SWMM5`, second line description text, third line integer time step in seconds, then constituent names and node names, then timestep data records. The engine validates format and matching pollutant names/units when opening an INFLOWS file (`iface.c:397–503`). For OUTFLOWS files the engine writes the header automatically when opening (`iface.c:313–373`). Hot-start files use a separate internal binary format managed by `hotstart.c`; their content is described in `chapter_11_files_used_by_swmm/11.7_Interface_Files.md:37–53`.
- **Source of truth:** `swmm524_engine/src/iface.c:88,93–131`; `swmm524_engine/src/consts.h:25`

## Notes

- The section header `[FILES]` is matched via prefix `ws_FILE = "[FILE"` (`text.h:405`), so `[FILES]` and `[FILE]` both resolve to section `s_FILE` (`enums.h:458`). This is consistent with how all section keywords use prefix matching.
- The `NO` and `SCRATCH` tokens appear in `FileModeWords` (index 0 and 1) because the same array is reused for internal engine state management, but neither is a valid INP keyword for the `[FILES]` section. Any attempt to use them will succeed the `findmatch` call but will not match `USE_FILE` (2) or `SAVE_FILE` (3) in any of the switch branches at `iface.c:93–131`, so the file handle will be populated with mode 0 (`NO_FILE`) or 1 (`SCRATCH_FILE`) and the file will never actually be opened.
- INFLOWS and OUTFLOWS are enforced as one-directional: an `INFLOWS` row with mode `SAVE` returns `ERR_ITEMS` (`iface.c:122`); an `OUTFLOWS` row with mode `USE` returns `ERR_ITEMS` (`iface.c:128`). They are the only file types with mode restrictions enforced at parse time.
- A run can simultaneously contain both `USE HOTSTART Fname1` and `SAVE HOTSTART Fname2` (with different filenames). The engine routes them to separate handles `Fhotstart1` and `Fhotstart2` (`iface.c:104–113`). All other types use a single handle.
- The engine checks at runtime that `Finflows.name` and `Foutflows.name` are not the same file; if they are, `ERR_ROUTING_FILE_NAMES` is reported and neither file is opened (`iface.c:154–160`).
- The GUI stores all `[FILES]` rows as raw strings in `Project.IfaceFiles` (a `TStringList` at `Uproject.pas:766`), preserving the three-token structure. It does not maintain separate typed fields. On export, each stored string is re-tokenised and re-emitted with tab separators (`Uexport.pas:1987–1991`).
- When the `[FILES]` section is absent entirely, all file handles default to `NO_FILE` mode and no interface files are used or saved.
- Ordering of rows within the section does not matter; each row is processed independently.
- The section produces no entries in the object-count pass (`input_countObjects`) because there are no named model objects being registered — `input.c:122–123` (only `s_OPTION` and generic object-adding logic run in the count pass; the `[FILES]` switch case falls through to `addObject` which is a no-op for this section type since the tokens do not correspond to any countable object type).
