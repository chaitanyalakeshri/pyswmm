# [COORDINATES]

**Purpose:** Assigns map X,Y coordinates to every drainage-system node (junction, outfall, flow divider, storage unit) so the SWMM GUI can draw them as circles on the Study Area Map. The section is purely a visualization aid; it plays no role in any runoff or routing computation. Coordinates are relative to the lower-left origin established by the `[MAP]` section's DIMENSIONS keyword. When a node's coordinates are absent (i.e., set to the sentinel value −1×10¹⁰ internally), the GUI omits that node from the map display but the simulation proceeds normally.

**Occurrence:** One row per node, for every node whose map position is known. Nodes without coordinates are silently skipped on export and need not appear here at all. All four node types (JUNCTION, OUTFALL, DIVIDER, STORAGE) are written together in a single contiguous block in section order JUNCTION → OUTFALL → DIVIDER → STORAGE, in the order they were added to the project.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/enums.h:468` — enum value `s_COORDINATE`; `swmm524_engine/src/input.c:631` — `parseLine()` `default: return 0` branch: the engine recognises the section header via `SectWords` (`keywords.c:138`) but performs no data parsing; all map sections fall through to the silent no-op default.
- Engine writer: Engine does not write INP files; no report-echo function exists for `[COORDINATES]`.
- GUI reader: `Uimport.pas:2575` — function `ReadCoordData`; dispatched at `Uimport.pas:2922` — `case 38: Result := ReadCoordData`.
- GUI writer: `Uexport.pas:2103` — procedure `ExportMap`; `[COORDINATES]` block starts at `Uexport.pas:2138`.
- GUI editor dialog(s): No dedicated dialog. X-Coordinate and Y-Coordinate are edited directly in the node Property Editor (see Appendix B references below); the GUI also updates them when the user drags a node on the map.
- Manual: `appendix_D_command_line_swmm/D.3_Map_Data_Section.md` — Section `[COORDINATES]`
- Additional manual refs: `appendix_B_visual_object_properties/B.3_Junction_Properties.md`, `B.4_Outfall_Properties.md` (X-Coordinate / Y-Coordinate property entries); `appendix_D_command_line_swmm/D.3_Map_Data_Section.md` (Figure D-3 sample data).

## Row Format

One data line per node:

```
Node  Xcoord  Ycoord
```

The GUI emits a 16-character left-justified name field followed by two fixed-precision floating-point columns separated by tabs or spaces (tab vs. space depends on the `TabDelimited` project setting):

```
;;Node            X-Coord             Y-Coord
;;--------------  ------------------  ------------------
N1                4006.62             5463.58
N2                6953.64             4768.21
```

(Example from `appendix_D_command_line_swmm/D.3_Map_Data_Section.md`, Figure D-3.)

## Fields

### Node

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any name that resolves to an existing JUNCTION, OUTFALL, DIVIDER, or STORAGE node in the project. Unknown names are silently skipped by the GUI reader (`Uimport.pas:2589` — `FindNode` returns nil and the block is skipped without error).
- **Default:** none
- **Cross-section dependency:** `[JUNCTIONS].Name` | `[OUTFALLS].Name` | `[DIVIDERS].Name` | `[STORAGE].Name`
- **Database-key hint:** foreign key to the unified nodes table (or to whichever per-type table holds the named node); also acts as a composite PK with Xcoord+Ycoord if uniqueness of the row must be enforced, though the section has at most one canonical row per node.
- **Technical description:** The GUI locates the node object by calling `FindNode(TokList[0])` (`Uimport.pas:2589`). `FindNode` searches across all four node-type lists (JUNCTION=4, OUTFALL=5, DIVIDER=6, STORAGE=7; `Uproject.pas:44–47`). If the name is found, the X and Y values are stored into `TNode.X` and `TNode.Y` (`Uproject.pas:515`). If the name is not found the row is silently ignored — no error is raised — which differs from most simulation sections that return `NODE_ERR`.
- **Source of truth:** `Uimport.pas:2589` (name lookup); `Uimport.pas:2600–2601` (assignment).

### Xcoord

- **Data type:** REAL
- **Required:** yes (if the row is present at all)
- **Units:** Map coordinate units as declared by `[MAP] UNITS` (FEET / METERS / DEGREES / NONE). The coordinate system carries no inherent scale; it is whatever the user chose when drawing or importing the map.
- **Valid values / range:** Any real number representable as an Extended-precision float. The sentinel/missing value is −1.0×10¹⁰ (`MISSING`, defined in `Uproject.pas:21` and `Uglobals.pas:196`). The GUI export skips any node whose stored X equals `MISSING` (`Uexport.pas:2151`).
- **Default:** none (nodes are initialised to `MISSING` on project load, `Uproject.pas:1049`)
- **Cross-section dependency:** `[MAP].DIMENSIONS` — defines the coordinate origin and extent against which this value is interpreted.
- **Database-key hint:** plain data – no key role.
- **Technical description:** Horizontal distance from the lower-left origin of the map bounding rectangle. Parsed with `Uutils.GetExtended` (`Uimport.pas:2594`); if the string cannot be converted, `NUMBER_ERR` is returned and the row is skipped. After reading, the value is stored in `TNode.X : Extended` (`Uproject.pas:515`). The `GetCoordExtents` helper in `Ucoords.pas:30–144` uses X values of all nodes (excluding MISSING) to compute map auto-fit extents. `TransformCoords` in `Ucoords.pas:147–255` rescales X linearly when the user rescales or imports a new coordinate system.
- **Source of truth:** `Uimport.pas:2594–2600` (parsing and assignment).

### Ycoord

- **Data type:** REAL
- **Required:** yes (if the row is present at all)
- **Units:** Same map coordinate units as Xcoord.
- **Valid values / range:** Any real number; sentinel/missing value is −1.0×10¹⁰.
- **Default:** none (initialised to `MISSING` on project load, `Uproject.pas:1050`)
- **Cross-section dependency:** `[MAP].DIMENSIONS` — defines the coordinate origin and extent.
- **Database-key hint:** plain data – no key role.
- **Technical description:** Vertical distance from the lower-left origin of the map bounding rectangle. Positive Y points upward. Parsed with `Uutils.GetExtended` (`Uimport.pas:2596`); error handling identical to Xcoord. Stored in `TNode.Y : Extended` (`Uproject.pas:515`). Both X and Y must differ from `MISSING` for the GUI to emit a row on export (`Uexport.pas:2151`). Appendix B confirms: "If left blank then the junction will not appear on the map" (`B.3_Junction_Properties.md:6–8`).
- **Source of truth:** `Uimport.pas:2596–2601` (parsing and assignment).

## Notes

- **GUI-only section.** The SWMM engine (`swmm524_engine`) recognises `[COORDINATE` as a section keyword (`text.h:444`, `enums.h:468`, `keywords.c:138`) so that it does not raise an `ERR_KEYWORD` error when encountered, but `parseLine()` has no case for `s_COORDINATE` and falls through to `default: return 0` (`input.c:631`). All coordinate data is silently skipped by the command-line engine.

- **Section keyword prefix matching.** The engine uses `findmatch` (prefix comparison), so `[COORDINATES]` matches `ws_COORDINATE = "[COORDINATE"` (`text.h:444`). The GUI's `SectionWords` array uses `'[COORDINATES'` at index 38 (`Uimport.pas:99`) and also uses prefix matching, so `[COORDINATES]` and `[COORDINATE]` both resolve to the same handler.

- **Covered node types.** The GUI export loop spans `I := JUNCTION to STORAGE` (integer range 4–7, `Uexport.pas:2143`), covering JUNCTION (4), OUTFALL (5), DIVIDER (6), and STORAGE (7) (`Uproject.pas:44–47`). Rain gages are handled separately in `[SYMBOLS]`; subcatchment centroids are implicitly derived from `[POLYGONS]`.

- **Optional presence.** A node may exist in `[JUNCTIONS]` (or other node sections) without having a `[COORDINATES]` row. The node participates fully in the simulation; only its map representation is absent. The GUI initialises every node's X and Y to `MISSING` at project load (`Uproject.pas:1049–1050`) and writes a `[COORDINATES]` row only when both differ from `MISSING` (`Uexport.pas:2151`).

- **No duplicate rows.** Each node name should appear at most once. The GUI's export loop iterates over the project's ordered lists and emits exactly one row per node with valid coordinates. The reader does not enforce uniqueness; a second row for the same node would simply overwrite the first stored value.

- **Coordinate system has no mandatory units.** The `[MAP] UNITS` sub-keyword may be `NONE`, meaning coordinates are in arbitrary map units with no real-world scale. Coordinates may or may not correspond to actual geographic coordinates (e.g., state-plane feet, decimal degrees). The SWMM engine imposes no interpretation.

- **DB-key design hint — two-column vs. separate table.** Because every node is represented by exactly one (X, Y) pair, the coordinates could be stored as two nullable REAL columns (`x_coord`, `y_coord`) directly on the unified nodes table (or each per-type node table). This avoids a join for every map query and reflects the one-to-one cardinality cleanly. A separate `coordinates` table (with `node_name` as a foreign key) would be warranted only if the schema must stay strictly normalised, if multiple coordinate reference systems per node need to be supported, or if the `[COORDINATES]` data must be loaded independently from the node simulation data. In a GeoPackage context, a natural fit is a `gpkg_geometry_columns`-backed point geometry on the node feature table, replacing both x_coord and y_coord with a single POINT geometry column.
