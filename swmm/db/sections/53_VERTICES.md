# [VERTICES]

**Purpose:** Assigns X,Y map coordinates to interior vertex points of polyline links (conduits, pumps, orifices, weirs, and outlets), enabling curved or bent link shapes on the SWMM study-area map. Each row records one interior vertex for a named link; the two endpoint coordinates (the inlet and outlet nodes) are stored separately in `[COORDINATES]` and are not repeated here. This section is purely cartographic: it plays no role in any hydraulic or hydrologic computation, and the command-line SWMM engine ignores its contents entirely. Data are written and read exclusively by the GUI.

**Occurrence:** Multiple rows per object — zero or more rows per link, one row per interior vertex point. Links with straight-line geometry have no entries in this section. A single link may contribute any number of rows (one per bend point), and all rows for a given link must appear consecutively, ordered from inlet node to outlet node.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/enums.h:468` — enum value `s_VERTICES` in `InputSectionType`; `swmm524_engine/src/keywords.c:138` — `ws_VERTICES` listed in `SectWords[]`. The engine's `parseLine()` switch in `swmm524_engine/src/input.c:631` hits `default: return 0` for `s_VERTICES`, so rows are read and discarded without error.
- Engine writer: Not applicable — the engine does not write INP files.
- GUI reader: `Uimport.pas:2608` — procedure `ReadVertexData`; dispatched from the section-switch at `Uimport.pas:2923` (case 39).
- GUI writer: `Uexport.pas:2163` — inside procedure `ExportMap`; iterates link types `CONDUIT` (8) through `OUTLET` (12) as defined in `Uproject.pas:48–52`.
- GUI editor dialog(s): No dedicated dialog — vertices are added/edited interactively on the map canvas via `Uedit.pas:222–228` (`TLink.Vlist.Add`) and `Umap.pas` drawing routines.
- Manual: `appendix_D_command_line_swmm/D.3_Map_Data_Section.md` — Section `[VERTICES]` (lines 58–76).
- Additional manual refs: `appendix_D_command_line_swmm/D.3_Map_Data_Section.md` lines 4–41 (overview of all map sections and example figure D-3 showing link 3 with two interior vertices).

## Row Format

One row per interior vertex point:

```
Link  Xcoord  Ycoord
```

Example from the manual (link "3" has two interior vertices):

```
[VERTICES]
;;Link           X-Coord            Y-Coord
;;-------------- ------------------ ------------------
3                5430.46            2019.87
3                7251.66            927.15
```

The GUI emits a 16-character left-justified link name, a tab (or space) separator, and two 18-character floating-point coordinates formatted to the map's configured decimal precision (default 3 digits, set in `Umap.pas:127`). Comment header lines beginning with `;;` are emitted by the GUI writer (`Uexport.pas:2164–2166`) and ignored by the reader.

## Fields

### Link

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any string matching the name of an existing link. The GUI reader (`Uimport.pas:2623`) calls `FindLink(TokList[0])` and silently skips rows where the name is not found — no error is raised for an unrecognised link name. Cross-reference: `[CONDUITS].Name`, `[PUMPS].Name`, `[ORIFICES].Name`, `[WEIRS].Name`, or `[OUTLETS].Name`.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** foreign key to the link's Name in whichever link section owns this link (conduits, pumps, orifices, weirs, or outlets); together with `VertexOrder` (see Notes) forms a composite PK for this table.
- **Technical description:** Identifies the link whose polyline shape is being described. The GUI iterates link types in the order CONDUIT → PUMP → ORIFICE → WEIR → OUTLET (`Uexport.pas:2168`) and emits all vertices for each link consecutively. Multiple rows sharing the same link name define a multi-segment polyline for that link.
- **Source of truth:** `Uimport.pas:2623` (`FindLink`); `Uexport.pas:2168–2182`.

### Xcoord

- **Data type:** REAL
- **Required:** yes
- **Units:** map coordinate units (feet, meters, decimal degrees, or dimensionless — set by `[MAP] UNITS`); unitless with respect to hydraulics
- **Valid values / range:** Any real number. The GUI reader uses `Uutils.GetExtended` (`Uimport.pas:2628`) which accepts any floating-point representation. No bounds checking is performed.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Horizontal map coordinate of the interior vertex, measured relative to the origin at the lower-left corner of the map extent as defined in `[MAP] DIMENSIONS`. Stored internally as Delphi `Extended` (80-bit extended precision, `Uvertex.pas:27`). Written with up to 18 characters and a configurable number of decimal places (`Uexport.pas:2176–2178`); default is 3 decimal digits (`Umap.pas:127`).
- **Source of truth:** `Uimport.pas:2628–2632`; `Uvertex.pas:27`.

### Ycoord

- **Data type:** REAL
- **Required:** yes
- **Units:** map coordinate units (same as Xcoord)
- **Valid values / range:** Any real number; same constraints as Xcoord.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Vertical map coordinate of the interior vertex, measured relative to the origin at the lower-left corner of the map extent. The coordinate system has Y increasing upward (standard SWMM map convention). Stored and emitted with the same precision as Xcoord.
- **Source of truth:** `Uimport.pas:2629–2632`; `Uvertex.pas:28`.

## Notes

**Engine vs GUI scope:** The engine defines `s_VERTICES` in its section enum (`enums.h:468`) and lists `ws_VERTICES` in `SectWords[]` (`keywords.c:138`) so that the section header is recognized without triggering an "unknown section" error. However, `parseLine()` returns 0 (no-op) for this section (`input.c:631`). The section is therefore fully GUI-only; omitting it entirely from a file fed to the command-line engine has no effect on simulation results.

**Ordering requirement (critical for DB design):** The manual (`D.3_Map_Data_Section.md:74`) explicitly states: "Include a separate line for each interior vertex of the link, **ordered from the inlet node to the outlet node**." The GUI writer iterates `aLink.Vlist.First` → `.Next` chain in insertion order, which preserves this inlet-to-outlet sequence (`Uexport.pas:2173–2180`). The DXF exporter also relies on this ordering (`Udxf.pas:285–292`): it draws Node1 (inlet) → interior vertices in list order → Node2 (outlet). A relational DB table must therefore include an explicit sequence/order column (e.g. `VertexOrder INTEGER`) as part of the composite primary key `(LinkName, VertexOrder)` to reconstruct the correct polyline geometry.

**Straight-line links omitted:** Links with no interior vertices are not listed at all (`D.3_Map_Data_Section.md:76`). In DB terms, a link with zero rows in the VERTICES table is a straight-line segment drawn directly between its inlet and outlet node coordinates.

**Link types covered:** The GUI writer exports vertices for all five link categories: conduit, pump, orifice, weir, and outlet (`Uexport.pas:2168`). There is no separate section for different link types; all share this one `[VERTICES]` section distinguished only by the link name.

**Silent skip on unknown link:** If a vertex row references a link name that does not exist in the project, `ReadVertexData` silently ignores the row (no error is appended to `ErrList`) — `Uimport.pas:2626`. This differs from the behavior for other referencing errors (e.g. `LINK_ERR`) and means orphaned vertex rows in a hand-edited file will be silently discarded.

**`ReverseVertexLists` procedure:** A procedure of this name exists in `Uimport.pas:3137` that reverses the vertex linked-list for every link. It is defined but never called in the current SWMM 5.2.4 codebase — it is dead code. DB designers should not assume any reversal occurs during import.

**Coordinate precision:** The number of decimal places written is controlled by the map `Digits` field (`Umap.pas:127`, default 3). For geographic coordinate systems (degrees), `Uupdate.pas:798` may override this with `MAXDEGDIGITS`. The reader accepts any valid floating-point string regardless of precision.

**Tab-delimited vs space-delimited:** The GUI can write either tab-separated or space-separated columns depending on `Uglobals.TabDelimited` (`Uexport.pas:2119`). The reader tokenizes on whitespace so both formats are accepted.

**No duplicate-link-name constraint within section:** The same link name may legally appear in multiple consecutive rows (one per vertex). This is not an error; it is the normal multi-vertex case. A DB primary key on `(LinkName, VertexOrder)` handles this correctly.
