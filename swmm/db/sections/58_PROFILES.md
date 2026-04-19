# [PROFILES]

**Purpose:** Stores named, ordered lists of link IDs that define saved profile-plot paths in the SWMM GUI. Each profile associates a user-chosen name with a sequence of connected drainage-system links; the GUI can redisplay any saved profile path without the user having to re-enter the link list. The section exists solely as a GUI persistence mechanism — the computational engine reads and recognises the section keyword but does not process any data from it.

**Occurrence:** One row per link batch per profile name. Because the GUI writer emits at most five link IDs per row, a single profile with more than five links will occupy multiple rows, all carrying the same quoted profile name in column 1. Across the file, there is one logical record (profile) per unique name; the name may repeat across consecutive rows. Total row count equals `ceil(total_links / 5)` summed across all profiles.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/text.h:451` — macro `ws_PROFILE` defines the section-header prefix `[PROFILE`; `swmm524_engine/src/enums.h:469` — enum value `s_PROFILE` is listed in `InputSectionType`; `swmm524_engine/src/keywords.c:141` — `ws_PROFILE` is registered in the section-keyword lookup table. There is **no** `case s_PROFILE:` branch in `input.c`; the engine falls through to `default: return 0;`, silently skipping all profile data.
- Engine writer: not applicable — the engine does not write INP files.
- GUI reader: `Uimport.pas:2797` — function `ReadProfileData`; called via dispatch table at `Uimport.pas:2928` (case 44).
- GUI writer: `Uexport.pas:1999` — procedure `ExportProfiles`; called at `Uexport.pas:2444`.
- GUI editor dialog(s): `Dproselect.pas` (profile path selection and path-find form `TProfileSelectForm`); `Dprofile.pas` (saved-profile management form `TProfileSelectionForm`); `Dproplot.pas` (profile plot display-options form `TProfilePlotOptionsForm`); `Fproplot.pas` (MDI child form `TProfilePlotForm` that renders the plot).
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — the `[PROFILES]` section is **not documented** in Appendix D; it is a GUI-only extension.
- Additional manual refs: `chapter_09_viewing_results/9.5_Viewing_Results_with_a_Graph.md` §9.5.2 "Profile Plots" — describes the GUI workflow for creating and saving profile plots.

## Row Format

Each physical row has the form:

```
"Name"  Link1  Link2  Link3  Link4  Link5
```

- `Name` is always enclosed in double quotes and left-padded/truncated to 16 characters inside the quotes using `Format('"%-16s"', [aID])` (`Uexport.pas:2031`).
- Up to five link IDs follow on the same row, separated by spaces (or tabs when tab-delimited output is chosen).
- When a profile contains more than five links the writer starts a new row with the same quoted name and continues the link list (`Uexport.pas:2028–2036`).
- Comment header lines emitted by the GUI:

```
;;Name            Links
;;----------------  ----------
```

The section has no sub-lines or continuation tokens other than the repeated-name multi-row pattern.

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-empty string. The GUI tokenizer (`Uutils.pas:1001`) treats content between double-quote characters as a single token, stripping the quotes, so the stored name may contain spaces. Maximum display width in the INP file is 16 characters (the format string `"%-16s"` left-pads shorter names with spaces inside the quotes), but the internal string is not truncated. Uniqueness is enforced by the GUI: `Dproselect.pas:471` calls `Project.ProfileNames.Find(S, I)` and rejects duplicate names, and `Dprofile.pas:92–93` shows a similar check.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** primary identifier of this row (composite PK with row sequence number for multi-row profiles; unique across all profile records in the project).
- **Technical description:** The profile name is stored in `Project.ProfileNames` (a `TStringList`) at `Uproject.pas:761`. It is the human-readable handle the user assigns when clicking "Save Current Profile" in `Dproselect.pas:461–488`. When reading back from INP (`Uimport.pas:2809`), the GUI looks up `TokList[0]` (the stripped-quote value) in `ProfileNames`; if absent a new entry is created (`Uimport.pas:2812–2817`), otherwise links are appended to the existing entry (`Uimport.pas:2819–2825`). This accumulation logic is what makes the multi-row format work: successive rows with the same name extend the link list for that profile rather than creating a new profile.
- **Source of truth:** `Uimport.pas:2809` (lookup), `Uimport.pas:2814` (insertion), `Dproselect.pas:471` (uniqueness check).

### Link1 … Link5

- **Data type:** NAME_REF
- **Required:** yes (at least one link per row; Link2–Link5 are optional per row)
- **Units:** n/a
- **Valid values / range:** Any string token that matches the ID of an existing link (conduit, pump, orifice, weir, or outlet) in the project. The GUI does not validate existence at write time; existence and connectivity are validated only when a profile plot is opened (`Dproselect.pas:524–567` — `CheckProfile` verifies each link exists and that consecutive links share a node).
- **Default:** none (at least one link ID is mandatory; the reader exits immediately if `Ntoks < 2` — `Uimport.pas:2806`).
- **Cross-section dependency:** Cross-references any link type defined in `[CONDUITS]`, `[PUMPS]`, `[ORIFICES]`, `[WEIRS]`, or `[OUTLETS]`.
- **Database-key hint:** foreign key to the respective link table's `.Name` field; composite with `Name` and ordinal position within the sequence.
- **Technical description:** The link IDs are stored internally as a newline-delimited (`#13`) string in `Project.ProfileLinks` (`Uproject.pas:762`), one string entry per profile. During import each token from position 1 onward (`TokList[1]` … `TokList[Ntoks-1]`) is appended to the existing string for the named profile (`Uimport.pas:2822–2824`). During export the writer iterates this list in order, emitting up to five IDs per row (`Uexport.pas:2026–2036`). The order is critical: the profile-plot renderer (`Fproplot.pas:306–351`) traverses links in the sequence stored in `LinksList`, starting from the node that is *not* shared with the second link (to determine upstream orientation — `Fproplot.pas:330–352`), then walking each successive link by finding the node shared with the previous link's "last" node (`Fproplot.pas:313–314`). Altering link order changes which end of the profile is treated as upstream, and may break the connectivity check entirely.
- **Source of truth:** `Uimport.pas:2822` (token accumulation), `Uexport.pas:2033` (emission), `Fproplot.pas:342–351` (order-dependent traversal), `Dproselect.pas:538–566` (connectivity validation).

## Notes

- **GUI-only section.** The SWMM 5.x computational engine (`swmm524_engine`) registers `[PROFILE` in its keyword tables (`text.h:451`, `keywords.c:141`, `enums.h:469`) so it can identify the section boundary and stop reading the section without error, but it performs no computation with the data. Profile definitions have no effect whatsoever on simulation results.

- **Section-header prefix matching.** Both the GUI reader (`Uimport.pas:105`) and the engine (`text.h:451`) use the prefix `[PROFILE` (without the trailing `S`), meaning the section header `[PROFILES]` is matched by prefix. Any header beginning with `[PROFILE` is accepted.

- **Multi-row format for long profiles.** When a profile contains more than five links, the writer emits multiple rows all bearing the same quoted name. The reader (`Uimport.pas:2819`) concatenates link IDs from successive rows with the same name, so the row count per profile is `ceil(N / 5)` for a profile with N links. A database schema must store ordered link rows rather than a flat set; ordinal position within the list is semantically significant.

- **Link ordering is mandatory.** Links must appear in consecutive-connectivity order (each link sharing a node with its neighbour). The plot renderer determines the upstream end algorithmically from the first two links (`Fproplot.pas:342–351`); reversing the list reverses the plot's horizontal direction. Non-consecutive ordering causes `CheckProfile` (`Dproselect.pas:524`) to return an error index, and the plot is not drawn.

- **Name quoting.** The GUI always writes profile names inside double quotes using `Format('"%-16s"', [aID])` (`Uexport.pas:2031`). The tokenizer (`Uutils.pas:1044–1063`) strips the quotes before storing the name, so the internal representation never contains quotes. The name *may* contain spaces, which is why quoting is required.

- **No engine-side uniqueness enforcement.** Profile names are unique within a project because the GUI enforces it interactively (`Dproselect.pas:471`, `Dprofile.pas:92–93`). There is no engine-level rejection of duplicate profile names because the engine ignores the section entirely.

- **Not listed in Appendix D.** The `[PROFILES]` section does not appear in the Appendix D input-file specification (`D.2_Input_File_Format.md`), confirming it is a purely GUI-level construct appended to the INP file alongside the map-data sections.

- **Parallel storage lists.** Internally the GUI maintains two parallel `TStringList` objects: `Project.ProfileNames` (one entry per profile) and `Project.ProfileLinks` (one entry per profile, containing a `#13`-delimited list of link IDs). These lists are allocated at `Uproject.pas:851–852` and freed at `Uproject.pas:873–874`. A relational schema should represent this as a separate child table with columns `(ProfileName, Ordinal, LinkID)`.
