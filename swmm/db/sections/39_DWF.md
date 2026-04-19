# [DWF]

**Purpose:** Specifies dry weather flow (DWF) and its quality entering the drainage system at specific conveyance-network nodes. Each row defines the average baseline value of a single constituent (flow or a named pollutant) at one node, together with up to four optional time patterns (monthly, daily, hourly, and weekend-hourly) whose multipliers modulate that baseline over the simulation period. DWF represents steady sanitary base-flow or water-quality loads that are independent of rainfall.

**Occurrence:** Multiple rows per node; one row per (Node, Constituent) pair. A single node may have multiple rows — one for FLOW plus one for each pollutant — and each row can appear in any order. The engine builds a singly-linked list (`TDwfInflow.next`) of constituent records hanging off each node object, so there is no enforced ordering within a node.

**SWMM source references:**
- Engine parser: `inflow.c:237` — function `inflow_readDwfInflow`
- Engine dispatch: `input.c:580-581` — `case s_DWF: return inflow_readDwfInflow(Tok, Ntokens)`
- Engine writer: engine does not write INP files; dry weather inflow presence is echoed to the report file at `inputrpt.c:173` as a boolean "Yes" flag on the node summary table.
- GUI reader: `Uimport.pas:1801` — function `ReadDWInflowData`
- GUI writer: `Uexport.pas:1731` — procedure `ExportDWflows`
- GUI editor dialog: `appendix_C_specialized_property_editors/C.9_Inflows_Editor.md` — "Dry Weather Inflows Page"
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[DWF]` (line 2250)
- Additional manual refs: Appendix C.9 (Inflows Editor, Dry Weather page); `[PATTERNS]` section of D.2 (line 2438) for pattern type semantics

## Row Format

```
Node  Constituent  AveFlow  (Pat1  Pat2  Pat3  Pat4)
```

The manual's canonical format string (`D.2_Input_File_Format.md:2254`):

```
Node  Type  Base  (Pat1  Pat2  Pat3  Pat4)
```

The GUI comment header emitted by `ExportDWflows` (`Uexport.pas:1746-1751`) uses the labels:

```
;;Node            Constituent       Baseline    Patterns
;;--------------  ----------------  ----------  ----------
```

Tokens 0–2 are required; tokens 3–6 (the four pattern names) are optional and may be omitted individually by leaving blank tokens or by simply omitting trailing tokens.

## Fields

### Node

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match the `Name` of an existing node. The engine searches all node types: `project_findObject(NODE, tok[0])` (`inflow.c:258-259`). The GUI writer iterates node types JUNCTION through STORAGE (`Uexport.pas:1752`), so any node type (junction, outfall, flow divider, storage unit) is accepted.
- **Default:** none
- **Cross-section dependency:** `[JUNCTIONS].Name`, `[OUTFALLS].Name`, `[DIVIDERS].Name`, or `[STORAGE].Name`
- **Database-key hint:** composite PK with Constituent (foreign key to node tables)
- **Technical description:** Identifies the conveyance-system node that receives the dry weather inflow. There is no type restriction in the engine parser — any node type may receive DWF. During simulation, the engine iterates all nodes at each routing step and accumulates the DWF contribution to `Node[j].newLatFlow` (`routing.c:536`).
- **Source of truth:** `inflow.c:258-259`

---

### Constituent

- **Data type:** TEXT (keyword or NAME_REF)
- **Required:** yes
- **Units:** n/a
- **Valid values / range:**
  - The keyword `FLOW` (matched via `match(tok[1], w_FLOW)`, `text.h:389`, `inflow.c:265`) designates the hydraulic flow constituent. `FLOW` is a reserved word and cannot be used as a pollutant name (`D.2_Input_File_Format.md:1988`).
  - Any pollutant name previously declared in `[POLLUTANTS]` is also valid. The engine resolves the pollutant index via `project_findObject(POLLUT, tok[1])` (`inflow.c:262-263`).
  - Any other token causes `ERR_NAME` (`inflow.c:266`).
- **Default:** none
- **Cross-section dependency:** `[POLLUTANTS].Name`; or the reserved keyword `FLOW`
- **Database-key hint:** composite PK with Node
- **Technical description:** Selects which constituent's average value is being specified on this row. Internally, `FLOW` maps to `param = -1`; pollutants map to their zero-based index in the `Pollut[]` array (`inflow.c:248-266`). The engine stores one `TDwfInflow` struct per (node, constituent) pair in a linked list; if the same (node, constituent) pair appears twice in the INP file, the second occurrence overwrites the first (`inflow.c:285-305`). The GUI similarly uses `DWInflow.IndexOfName` and replaces an existing entry (`Uimport.pas:1821-1824`).
- **Source of truth:** `inflow.c:261-267`

---

### AveFlow

- **Data type:** REAL
- **Required:** yes
- **Units:**
  - When Constituent is `FLOW`: project flow units (CFS, GPM, MGD, CMS, LPS, or MLD as set in `[OPTIONS] FLOW_UNITS`). The engine divides the parsed value by `UCF(FLOW)` to convert to internal units of cubic feet per second (`inflow.c:272`).
  - When Constituent is a pollutant: pollutant concentration units as declared in `[POLLUTANTS]` (MG/L, UG/L, or #/L). No unit conversion is applied for pollutants (`inflow.c:270-272`).
- **Valid values / range:** any real number; physically meaningful values are `≥ 0`. The engine places no explicit lower-bound check; a zero or negative baseline produces zero or negative flow.
- **Default:** none (field is required)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The average (baseline) dry weather flow rate or pollutant concentration entering the node. At run time the actual inflow equals `AveFlow × (product of all applicable pattern multipliers)` (`inflow_getDwfInflow`, `inflow.c:361-388`). If no patterns are assigned, the multiplier product is 1.0 and the inflow equals `AveFlow` exactly for the entire simulation. The manual labels this field `Base` (`D.2_Input_File_Format.md:2260`); the GUI header labels it `Baseline` (`Uexport.pas:1746`); the C struct field is `avgValue` (`objects.h:449`).
- **Source of truth:** `inflow.c:270-272`

---

### Pat1

- **Data type:** NAME_REF
- **Required:** no (default: none — no pattern applied for that slot)
- **Units:** n/a
- **Valid values / range:** Name of a time pattern declared in `[PATTERNS]`. The engine resolves via `project_findObject(TIMEPATTERN, tok[i])` and returns `ERR_NAME` if the name is not found (`inflow.c:280-281`). The pattern type (MONTHLY, DAILY, HOURLY, WEEKEND) determines which slot it occupies internally after `inflow_initDwfInflow` reorders the array (`inflow.c:331-357`). An empty string is silently skipped (`inflow.c:279`).
- **Default:** none (factor defaults to 1.0 if absent)
- **Cross-section dependency:** `[PATTERNS].Name`
- **Database-key hint:** foreign key to [PATTERNS].Name
- **Technical description:** First of up to four optional time-pattern names. The engine reads tokens 3 through 6 (up to four tokens) and initially stores them positionally in `pats[0..3]` (`inflow.c:275-283`). After parsing, `inflow_initDwfInflow` (`inflow.c:331-357`) re-sorts the four slot indices by pattern type into the fixed order: `patterns[MONTHLY_PATTERN]`, `patterns[DAILY_PATTERN]`, `patterns[HOURLY_PATTERN]`, `patterns[WEEKEND_PATTERN]` (`enums.h:383-387`). Therefore the four pattern names in the INP file may be given in **any order**; the engine determines their slots from the declared type of each pattern, not from their column position. The manual confirms this: "The patterns can be any combination of monthly, daily, hourly and weekend hourly patterns, listed in any order" (`D.2_Input_File_Format.md:2272`).
- **Source of truth:** `inflow.c:275-283`; `inflow.c:331-357`

---

### Pat2

- **Data type:** NAME_REF
- **Required:** no (default: none)
- **Units:** n/a
- **Valid values / range:** Same as Pat1 — a valid `[PATTERNS]` name, or an empty/absent token.
- **Default:** none
- **Cross-section dependency:** `[PATTERNS].Name`
- **Database-key hint:** foreign key to [PATTERNS].Name
- **Technical description:** Second optional pattern slot (INP token 4, zero-based column index 4). See Pat1 for full semantics. After `inflow_initDwfInflow` reorders, the actual pattern type it occupies is determined by the pattern's own declared type, not by column position.
- **Source of truth:** `inflow.c:276-283`

---

### Pat3

- **Data type:** NAME_REF
- **Required:** no (default: none)
- **Units:** n/a
- **Valid values / range:** Same as Pat1.
- **Default:** none
- **Cross-section dependency:** `[PATTERNS].Name`
- **Database-key hint:** foreign key to [PATTERNS].Name
- **Technical description:** Third optional pattern slot (INP token 5). See Pat1.
- **Source of truth:** `inflow.c:276-283`

---

### Pat4

- **Data type:** NAME_REF
- **Required:** no (default: none)
- **Units:** n/a
- **Valid values / range:** Same as Pat1.
- **Default:** none
- **Cross-section dependency:** `[PATTERNS].Name`
- **Database-key hint:** foreign key to [PATTERNS].Name
- **Technical description:** Fourth optional pattern slot (INP token 6). The engine accepts at most four pattern names (tokens 3–6 inclusive) (`inflow.c:276` loop `for (i=3; i<7; i++)`). Any additional tokens beyond index 6 are silently ignored. See Pat1 for full reordering semantics.
- **Source of truth:** `inflow.c:276-283`

## Notes

- **Composite primary key:** The logical primary key of this section is `(Node, Constituent)`. If the same pair appears in multiple rows, the later row silently overwrites the earlier one in both the engine (`inflow.c:285-305`) and the GUI (`Uimport.pas:1821-1824`).

- **Pattern slot order at runtime:** After parsing, `inflow_initDwfInflow` (`inflow.c:331-357`) reorders the four raw slot indices into a fixed internal array position by pattern type: index 0 = `MONTHLY_PATTERN`, index 1 = `DAILY_PATTERN`, index 2 = `HOURLY_PATTERN`, index 3 = `WEEKEND_PATTERN` (`enums.h:383-387`). At each routing time step `inflow_getDwfInflow` (`inflow.c:361-388`) multiplies all applicable factors: monthly factor × daily factor × (weekend factor if weekend day, else hourly factor). A missing pattern for a slot defaults to factor 1.0.

- **Pattern type semantics** (`D.2_Input_File_Format.md:2464-2478`; `text.h:157-161`):
  - `MONTHLY`: 12 multipliers, one per calendar month.
  - `DAILY`: 7 multipliers, one per day of week (Sunday = day 1 / index 0).
  - `HOURLY`: 24 multipliers, one per hour starting from midnight.
  - `WEEKEND`: 24 multipliers applied in place of `HOURLY` on Saturday and Sunday.

- **Flow units conversion:** The average flow value is internally stored in CFS regardless of the project's `FLOW_UNITS` setting. The conversion occurs at parse time via `x /= UCF(FLOW)` (`inflow.c:272`). Pollutant concentration values are stored as-is, with no unit conversion.

- **Default pollutant DWF concentration:** If a pollutant's `Cdwf` field in `[POLLUTANTS]` is non-zero and a node has a FLOW DWF inflow but no explicit pollutant row in `[DWF]` for that pollutant, the engine automatically loads `q × Pollut[p].dwfConcen` as the pollutant mass inflow (`routing.c:543-550`). An explicit `[DWF]` row for a pollutant at the same node overrides this default and subtracts it to avoid double-counting (`routing.c:564-569`).

- **Node type scope:** Any node type (junction, outfall, flow divider, storage) may appear in this section. The engine does not restrict by node type (`inflow.c:258`). The GUI exports JUNCTION through STORAGE types (`Uexport.pas:1752`).

- **Minimum token count:** The parser requires at least 3 tokens (Node, Constituent, AveFlow); fewer tokens produce `ERR_ITEMS` (`inflow.c:257`).

- **Empty pattern tokens:** An empty string `""` for a pattern slot is silently ignored (`inflow.c:279`: `if ( strlen(tok[i]) == 0 ) continue`), allowing placeholder entries without triggering an error.

- **Section is skipped if no DWF defined:** The GUI writer skips the section entirely if `DWFCount == 0` (`Uexport.pas:1741`), so `[DWF]` is absent from INP files with no dry weather inflows.

- **Linked-list storage:** The engine stores all DWF records for a node as a singly-linked list (`TDwfInflow.next`, `objects.h:451`), allocated with `malloc` per entry and freed via `inflow_deleteDwfInflows` at project teardown (`inflow.c:311-327`). The DB schema should store them as a flat table with (Node, Constituent) as composite key.
