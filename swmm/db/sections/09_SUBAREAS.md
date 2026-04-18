# [SUBAREAS]

**Purpose:** Supplies the overland-flow hydraulic parameters and internal runoff-routing choice for every subcatchment. Each subcatchment is modelled as up to three contiguous subareas: an impervious surface with no depression storage (IMPERV0), an impervious surface with depression storage (IMPERV1), and a pervious surface (PERV). The [SUBAREAS] section provides one row per subcatchment that sets Manning's roughness coefficients and depression-storage depths for the impervious and pervious fractions, the fraction of the impervious area that carries zero depression storage, and whether runoff from one subarea type is routed internally to the other before leaving the subcatchment.

**Occurrence:** One row per subcatchment object defined in [SUBCATCHMENTS]. Exactly one row is expected per subcatchment; the section does not support continuation lines or multiple rows per object.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/subcatch.c:196` — function `subcatch_readSubareaParams`
- Engine writer: engine does not write INP; no SUBAREAS echo function exists in `inputrpt.c`
- GUI reader: `Uimport.pas:631` — function `ReadSubareaData`
- GUI writer: `Uexport.pas:555` — procedure `ExportSubAreas`
- GUI editor dialog(s): subcatchment properties are edited inline via the property editor; field indices defined in `Uproject.pas:120–126`; dropdown values and defaults in `objprops.txt:259–265, 722–723`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [SUBAREAS] (line 615)
- Additional manual refs: `appendix_B_visual_object_properties/B.2_Subcatchment_Properties.md` lines 26–45; `appendix_A_useful_tables/A.5_Depression_Storage.md`; `appendix_A_useful_tables/A.6_Mannings_Coeff_Overland_Flow.md`

## Row Format

```
Subcat  Nimp  Nperv  Simp  Sperv  %Zero  RouteTo  (%Routed)
```

Columns 1–7 are required; column 8 (`%Routed`) is optional and is omitted from the output when `RouteTo` is `OUTLET` (`Uexport.pas:584–585`).

## Fields

### Subcat

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match a name defined in [SUBCATCHMENTS]. Case-insensitive lookup via `project_findObject(SUBCATCH, tok[0])`.
- **Default:** none
- **Cross-section dependency:** `[SUBCATCHMENTS].Name`
- **Database-key hint:** foreign key to [SUBCATCHMENTS].Name; together with the one-row-per-subcatchment constraint it also acts as the primary identifier of this row
- **Technical description:** Identifies the subcatchment whose subarea parameters are being set. The engine looks up the index of this name in the global SUBCATCH array; if not found, error ERR_NAME is raised.
- **Source of truth:** `swmm524_engine/src/subcatch.c:214–216`

---

### Nimp

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (dimensionless Manning's roughness coefficient)
- **Valid values / range:** `≥ 0` (the engine rejects any value `< 0.0` with ERR_NAME)
- **Default:** `0.01` (GUI default, `objprops.txt:259`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Manning's n for overland sheet flow across the impervious fraction of the subcatchment. The same value is assigned to both IMPERV0 (impervious with no depression storage) and IMPERV1 (impervious with depression storage) subareas (`subcatch.c:240–241`). Typical values for smooth asphalt are ~0.011 and for smooth concrete ~0.012; see `appendix_A_useful_tables/A.6_Mannings_Coeff_Overland_Flow.md`. Higher values slow overland flow and increase ponding time.
- **Source of truth:** `swmm524_engine/src/subcatch.c:219–223, 240–241`

---

### Nperv

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (dimensionless Manning's roughness coefficient)
- **Valid values / range:** `≥ 0`
- **Default:** `0.1` (GUI default, `objprops.txt:260`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Manning's n for overland sheet flow across the pervious fraction of the subcatchment. Assigned to the PERV subarea (`subcatch.c:242`). Typical values range from 0.05 (fallow soil) to 0.80 (dense forest underbrush); see `appendix_A_useful_tables/A.6_Mannings_Coeff_Overland_Flow.md`. A monthly-varying pattern (N-Perv Pattern, stored as `SUBCATCH_PERV_N_INDEX`) is supported in the GUI but is a separate per-simulation adjustment not stored in [SUBAREAS].
- **Source of truth:** `swmm524_engine/src/subcatch.c:219–223, 242`

---

### Simp

- **Data type:** REAL
- **Required:** yes
- **Units:** US: inches / SI: millimetres
- **Valid values / range:** `≥ 0`
- **Default:** `0.05` (GUI default, `objprops.txt:261`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Depth of depression (detention) storage on the impervious subarea. Rain that falls into this "bucket" does not contribute to runoff until the bucket is full. The value is assigned only to IMPERV1 (impervious *with* depression storage); IMPERV0 always has zero depression storage by design (`subcatch.c:244–245`). The engine converts the value from the user's rain-depth unit to internal feet via `UCF(RAINDEPTH)`. Typical impervious values are 0.05–0.10 inches (`A.5_Depression_Storage.md`).
- **Source of truth:** `swmm524_engine/src/subcatch.c:244–246`

---

### Sperv

- **Data type:** REAL
- **Required:** yes
- **Units:** US: inches / SI: millimetres
- **Valid values / range:** `≥ 0`
- **Default:** `0.05` (GUI default, `objprops.txt:262`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Depth of depression storage on the pervious subarea. Assigned to the PERV subarea after unit conversion (`subcatch.c:246`). Typical pervious values are 0.10–0.30 inches for lawns, pasture, and forest litter (`A.5_Depression_Storage.md`).
- **Source of truth:** `swmm524_engine/src/subcatch.c:246`

---

### %Zero

- **Data type:** REAL
- **Required:** yes
- **Units:** percent (%)
- **Valid values / range:** `0–100` (engine enforces `≥ 0`; values > 100 are not explicitly blocked but are physically meaningless)
- **Default:** `25` (GUI default, `objprops.txt:263`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Percentage of the total impervious area that has zero depression storage (i.e., it falls in the IMPERV0 subarea). The remaining impervious area (100 − %Zero) is modelled as IMPERV1. Internally, `fArea` for IMPERV0 is set to `fracImperv × (%Zero/100)` and for IMPERV1 to `fracImperv × (1 − %Zero/100)` (`subcatch.c:248–249`). A value of 0 means all impervious area has depression storage; a value of 100 means none does.
- **Source of truth:** `swmm524_engine/src/subcatch.c:248–249`

---

### RouteTo

- **Data type:** ENUM
- **Required:** yes
- **Units:** n/a
- **Valid values / range:**
  - `OUTLET` — runoff from both impervious and pervious subareas drains directly to the subcatchment outlet
  - `IMPERV` — runoff from the pervious subarea is routed onto the impervious subarea before reaching the outlet
  - `PERV` — runoff from the impervious subareas is routed onto the pervious subarea before reaching the outlet
  - The engine keyword list is `{ "OUTLET", "IMPERV", "PERV", NULL }` (`subcatch.c:77`). The GUI property editor and manual use the longer forms `OUTLET`, `IMPERVIOUS`, `PERVIOUS` (`objprops.txt:723`; `D.2_Input_File_Format.md:639`), but the engine matches via prefix: `"IMPERV"` matches both `IMPERV` and `IMPERVIOUS`; `"PERV"` matches both `PERV` and `PERVIOUS` because `findmatch` calls `match()` which does prefix comparison. Either spelling is accepted by the engine.
- **Default:** `OUTLET` (manual line 641; GUI default `objprops.txt:264`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Controls internal routing of runoff between subareas within the subcatchment before it exits to the outlet node or downstream subcatchment. When `IMPERV` is selected, pervious runoff is added to the impervious subarea inflow (case 1 in `subcatch.c:558–570`); the fraction that bypasses directly to the outlet is `1 − PctRouted/100`. When `PERV` is selected, impervious runoff (IMPERV0 and IMPERV1) is added to pervious area inflow (case 2 in `subcatch.c:573–590`). If the subcatchment is either 100% impervious or 0% impervious, any non-OUTLET setting is silently overridden to `OUTLET` (`subcatch.c:263–264`). LID runoff calculations also respect this flag (`lid.c:1770, 1796`).
- **Source of truth:** `swmm524_engine/src/subcatch.c:77, 225–227, 259–278`; `swmm524_engine/src/enums.h:329–332`

---

### %Routed

- **Data type:** REAL
- **Required:** no (default: `100`)
- **Units:** percent (%)
- **Valid values / range:** `0–100` (engine enforces this range explicitly; `subcatch.c:234`)
- **Default:** `100` (implicitly 1.0 in the engine; GUI default `objprops.txt:265`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Percentage of runoff from the "source" subarea (as determined by `RouteTo`) that is routed to the "destination" subarea rather than directly to the outlet. The complement `(100 − %Routed)` still flows to the outlet. The engine stores this as `fOutlet = 1 − x[6]` where `x[6] = %Routed/100` (`subcatch.c:231, 268, 276`). This field is only meaningful when `RouteTo` is not `OUTLET`; the GUI writer omits it from the INP file when `RouteTo` is `OUTLET` (`Uexport.pas:584–585`), and the engine defaults to 100 if the token is absent. When reading, token index 7 (eighth token) is consumed only if `ntoks >= 8` (`subcatch.c:232`; `Uimport.pas:653–654`).
- **Source of truth:** `swmm524_engine/src/subcatch.c:229–237, 268, 276–277`

---

## Notes

- **Section keyword prefix matching:** The section header `[SUBAREAS]` is matched by the engine token `ws_SUBAREA = "[SUBAREA"` (`text.h:410`), meaning any header beginning with `[SUBAREA` (e.g., `[SUBAREAS]`) will be accepted. This is consistent with all other SWMM INP section headers.
- **One row per subcatchment:** The parser overwrites data for any subcatchment name it finds; if the same subcatchment name appears twice in [SUBAREAS], the second row silently replaces the first. There is no uniqueness enforcement in the engine.
- **Mandatory section for runoff simulation:** All seven required tokens must be present (`ntoks < 7` triggers `ERR_ITEMS`; `subcatch.c:212`). If a subcatchment appears in [SUBCATCHMENTS] but has no matching row in [SUBAREAS], the subarea fields retain their zero-initialised defaults from `project_init`, which means no overland flow delay and no depression storage.
- **Internal subarea split vs. INP fields:** The INP section provides one `Nimp` value that applies to *both* IMPERV0 and IMPERV1 and one `Simp` value that applies only to IMPERV1 (IMPERV0 always has dStore = 0). The three-subarea split is entirely an internal engine detail; the INP format does not expose IMPERV0 and IMPERV1 as separate rows.
- **RouteTo keyword aliases:** The engine's `RunoffRoutingWords` list uses the short forms `OUTLET`, `IMPERV`, `PERV`, but `findmatch` performs prefix comparison, so the longer GUI/manual spellings `IMPERVIOUS` and `PERVIOUS` are silently accepted. The GUI writer always emits the short engine forms (`Uexport.pas:583`).
- **%Routed column omission:** The GUI exporter conditionally omits the `%Routed` column when `RouteTo` equals `OUTLET` (`Uexport.pas:584`). INP files produced by third-party tools that always emit 8 columns are still parsed correctly because the engine reads `%Routed` only when `ntoks >= 8` (`subcatch.c:232`).
- **Unit system:** `Simp` and `Sperv` are in inches (US) or millimetres (SI); the engine divides by `UCF(RAINDEPTH)` to convert to feet for internal storage. Manning's n and `%Zero` are unitless; `%Routed` is dimensionless (percent).
- **LID interaction:** When LID controls are present, the engine adjusts impervious and pervious runoff contributions using the same `routeTo` flags set by this section (`lid.c:1770, 1796`). The [SUBAREAS] routing choice therefore affects how LID drainage is credited back to the subarea water balance.
