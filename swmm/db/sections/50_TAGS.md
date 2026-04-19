# [TAGS]

**Purpose:** Associates a short free-text label (a "tag") with any rain gage, subcatchment, node, or link object in the model. Tags serve purely as user-defined classification or grouping metadata: they are not used in any hydraulic or hydrologic computation. Common uses include denoting drainage basin membership, infrastructure ownership, inspection priority, or any other categorical grouping that analysts want to carry through export and reporting. In the GUI, tags can be used as filters in the Group Edit dialog and in the Group Delete operation.

**Occurrence:** One row per tagged object. Only objects whose tag value is non-empty are written. An object that has no tag assigned produces no row in this section. The same object name may not legitimately appear twice in this section under the same ObjectType keyword (the second occurrence would silently overwrite the first in the GUI reader), but the same name can appear under different ObjectType keywords if that name happens to be shared across object categories.

**SWMM source references:**
- Engine parser: The SWMM 5.2 engine C source (`/home/user/pyswmm/swmm/swmm524_engine/src/`) contains no parser or struct for `[TAGS]`. Tags are a GUI-only construct; the command-line engine ignores this section entirely.
- Engine writer: Not applicable — the engine does not write INP files and does not process this section.
- GUI reader: `Uimport.pas:2440` — procedure `ReadTagData`; section keyword `'[TAG'` is index 49 in `SectionWords` array (`Uimport.pas:110`); dispatched at `Uimport.pas:2933`.
- GUI writer: `Uexport.pas:2044` — procedure `ExportTags`; called from `SaveProject` at `Uexport.pas:2442`.
- GUI editor dialog(s): No dedicated dialog. The tag field appears as a plain text property named *Tag* in each object's Property Editor (e.g., `appendix_B_visual_object_properties/B.1_Rain_Gage_Properties.md:15`, `B.2_Subcatchment_Properties.md:12`, `B.3_Junction_Properties.md:12`, `B.4_Outfall_Properties.md:12`, `B.5_Flow_Divider_Properties.md:12`, `B.6_Storage_Unit_Properties.md:12`, `B.7_Conduit_Properties.md:12`, `B.8_Pump_Properties.md:12`, `B.9_Orifice_Properties.md:12`, `B.10_Weir_Properties.md:12`, `B.11_Outlet_Properties.md:12`). The Group Edit dialog (`Dgrouped.pas:271`) uses a tag filter to restrict bulk edits.
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — `[TAGS]` is not documented in the D.2 reference (the section listing at lines 19–57 of D.2 omits `[TAGS]`). It is a GUI-only section appended after the main data sections.
- Additional manual refs: `chapter_06_working_with_objects/6.10_Editing_or_Deleting_a_Group.md:55` — describes using Tag as a filter in the Group Edit dialog.

## Row Format

Each row has exactly three whitespace-delimited tokens:

```
ObjectType  Name  Tag
```

Where `ObjectType` is one of the four literal keywords `Gage`, `Subcatch`, `Node`, or `Link`; `Name` is the object identifier; and `Tag` is the free-text label value. No continuation rows, sub-lines, or header rows exist for this section.

The GUI emits tokens formatted with fixed-width padding (16 characters for `Name` and `Tag`), but the reader tokenises by whitespace so no exact column width is required for parsing (`Uexport.pas:2059–2097`).

## Fields

### ObjectType

- **Data type:** ENUM
- **Required:** yes
- **Units:** n/a
- **Valid values / range:**
  - `Gage` — applies the tag to a rain gage (matched against `Project.Lists[RAINGAGE]`, `Uimport.pas:2461`)
  - `Subcatch` — applies the tag to a subcatchment (matched against `Project.Lists[SUBCATCH]`, `Uimport.pas:2466`)
  - `Node` — applies the tag to any node: Junction (category code 4), Outfall (5), Divider (6), or Storage (7); matched by `FindNode` which searches all four node lists (`Uimport.pas:2472`)
  - `Link` — applies the tag to any link: Conduit (8), Pump (9), Orifice (10), Weir (11), or Outlet (12); matched by `FindLink` which searches all five link lists (`Uimport.pas:2477`)
- **Default:** none — the field is required as the first token on every row
- **Cross-section dependency:** None
- **Database-key hint:** composite PK with `Name` — ObjectType + Name uniquely identifies the tagged object
- **Technical description:** The parser uses prefix-matching via `Uutils.FindKeyWord` against a four-element array `('Gage', 'Subcatch', 'Node', 'Link')` declared as `TagTypes` at `Uimport.pas:2445`. Matching is case-insensitive prefix matching (same `FindKeyWord` utility used throughout the GUI). An unrecognised keyword returns -1, which triggers `KEYWORD_ERR` (`Uimport.pas:2458`). The Node keyword intentionally collapses all four node sub-types (Junction, Outfall, Divider, Storage) into a single keyword, and similarly Link collapses all five link sub-types, because those sub-types share a common name-space within SWMM. MapLabel (category 13) is not taggable and has no ObjectType keyword.
- **Source of truth:** `Uimport.pas:2444–2456` (`TagTypes` array and `FindKeyWord` call).

### Name

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must be the name of an existing object of the type indicated by `ObjectType`. Case-insensitive lookup. If the name is not found, no error is raised — the row is silently ignored (`Uimport.pas:2461–2478`: each branch checks `if J >= 0` or `if aNode <> nil` / `if aLink <> nil` before assigning).
- **Default:** none — the field is required as the second token on every row
- **Cross-section dependency:**
  - When `ObjectType = Gage`: `[RAINGAGES].Name`
  - When `ObjectType = Subcatch`: `[SUBCATCHMENTS].Name`
  - When `ObjectType = Node`: `[JUNCTIONS].Name` or `[OUTFALLS].Name` or `[DIVIDERS].Name` or `[STORAGE].Name`
  - When `ObjectType = Link`: `[CONDUITS].Name` or `[PUMPS].Name` or `[ORIFICES].Name` or `[WEIRS].Name` or `[OUTLETS].Name`
- **Database-key hint:** foreign key into the appropriate object table; composite PK together with `ObjectType`
- **Technical description:** Because SWMM maintains separate name-spaces for rain gages, subcatchments, nodes, and links, the same string can appear under different `ObjectType` rows without conflict. Node sub-types (Junction, Outfall, Divider, Storage) share one name-space; link sub-types (Conduit, Pump, Orifice, Weir, Outlet) share another. If a name does not exist in the target list, the assignment is skipped without error, meaning stale tag rows from a deleted object produce no parse error.
- **Source of truth:** `Uimport.pas:2461–2478`.

### Tag

- **Data type:** TEXT
- **Required:** yes (must be non-empty; the GUI only writes a row when `Length(Data[TAG_INDEX]) > 0`, `Uexport.pas:2057`)
- **Units:** n/a
- **Valid values / range:** Any non-empty text string; no length constraint is enforced by the parser. The GUI stores the value in the `Data[TAG_INDEX]` string slot of the object (`Uproject.pas:93`: `TAG_INDEX = 4`). Single-word values are most common, but multi-word values containing spaces would be problematic because the reader tokenises by whitespace — effectively limiting the tag to a single whitespace-free token.
- **Default:** none (empty string means no row is emitted)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The tag string is stored at index 4 of each object's `Data` string array (`Uproject.pas:93`: `TAG_INDEX = 4`). This is the same index across all taggable object types (rain gages, subcatchments, nodes, links). In the GUI, the tag appears as the property labelled *Tag* in each object's Property Editor and is described as "Optional label used to categorize or classify the [object]" (e.g., `B.1_Rain_Gage_Properties.md:15`). The Group Edit dialog (`Dgrouped.pas:271–276`) can filter selected objects by tag value before bulk-editing another property. The Group Delete function likewise accepts a tag filter. No validation of tag content is performed; any non-empty string is accepted.
- **Source of truth:** `Uimport.pas:2462`, `2468`, `2473`, `2478` (assignment); `Uexport.pas:2057`, `2067`, `2079`, `2092` (emission guard).

## Notes

- **Engine transparency:** The SWMM 5.2 C engine source (`/home/user/pyswmm/swmm/swmm524_engine/src/`) contains no parsing code for `[TAGS]`. The section is entirely GUI-side metadata. When the command-line engine reads a project file it encounters `[TAGS]` as an unrecognised section and skips all rows in it.

- **Section keyword prefix matching:** The GUI reader recognises section headings by prefix: the stored keyword is `'[TAG'` (`Uimport.pas:110`), so both `[TAG]` and `[TAGS]` match. This is consistent with the prefix-match approach used for all sections in `FindNewSection` (`Uimport.pas:2992`).

- **Manual omission:** The D.2 Input File Format appendix does not document `[TAGS]`. The section listing in D.2 (lines 19–57) does not include it. Documentation is found only in the Appendix B property tables and the Group Edit description in Chapter 6.

- **Node and link type collapsing:** The `Node` keyword in ObjectType covers all four node sub-types (Junction, Outfall, Divider, Storage — category codes 4–7 in `Uproject.pas:44–47`). The `Link` keyword covers all five link sub-types (Conduit, Pump, Orifice, Weir, Outlet — codes 8–12 in `Uproject.pas:48–52`). The DB schema must account for this: a `Node` tag row does not record which sub-type the node belongs to.

- **Silent duplicate handling:** If the same `ObjectType + Name` combination appears on two rows, the second row's tag value silently overwrites the first. No error or warning is raised.

- **Silent missing-object handling:** If `Name` does not correspond to an existing object of the given `ObjectType`, the row is silently ignored (`Uimport.pas:2461–2478`). This can occur when an object is deleted and the project file is not cleanly re-saved.

- **Whitespace in tag values:** The reader tokenises the input line by whitespace. A tag value containing spaces would be split into multiple tokens; only the third token (`TokList[2]`) is stored as the tag. Multi-word tag values are therefore not reliably round-trippable.

- **Ordering and uniqueness:** The GUI writes rows in a fixed order: all Gage rows first, then Subcatch, then Node (iterating Junction→Outfall→Divider→Storage), then Link (Conduit→Pump→Orifice→Weir→Outlet), each sub-list sorted by the internal list order (`Uexport.pas:2054–2099`). The parser imposes no ordering requirement.

- **Not stored in the binary output file:** Tags are not written to the SWMM binary output (`.out`) file and are not accessible from post-processor results. They exist only in the project (`.inp`) file.
