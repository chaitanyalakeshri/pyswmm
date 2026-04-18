# [GROUNDWATER]

**Purpose:** The `[GROUNDWATER]` section links each subcatchment to an aquifer defined in `[AQUIFERS]` and specifies the coefficients that govern lateral groundwater exchange between that aquifer and a conveyance-system node. For each subcatchment-aquifer pairing it records the ground surface elevation, five flow-equation coefficients (A1, B1, A2, B2, A3), a fixed surface-water depth option, a threshold water-table elevation, and optional per-subcatchment overrides for the aquifer's initial conditions (bottom elevation, initial water-table elevation, initial unsaturated-zone moisture content). The associated `[GWF]` section (parsed by the same code path) extends this by allowing user-supplied mathematical expressions that add to or replace the standard lateral and deep groundwater flow equations.

**Occurrence:** One row per subcatchment that has groundwater interaction. A subcatchment with no row in this section generates no groundwater flow. Each subcatchment may appear at most once. The companion `[GWF]` section is handled separately and may contribute zero, one, or two additional rows per subcatchment (one for LATERAL flow, one for DEEP flow).

**SWMM source references:**
- Engine parser: `swmm524_engine/src/gwater.c:179` — function `gwater_readGroundwaterParams`; `[GWF]` rows parsed at `gwater.c:258` — function `gwater_readFlowExpression`
- Engine dispatch: `swmm524_engine/src/input.c:511` — `case s_GROUNDWATER`; `input.c:514` — `case s_GWF`
- Engine writer: Engine does not write INP files. No groundwater-specific echo exists in `inputrpt.c` (only pollutant concentration header references GW at `inputrpt.c:58`).
- GUI reader: `Uimport.pas:715` — procedure `ReadGroundwaterData`; `Uimport.pas:760` — procedure `ReadGroundwaterFlowEqn`; dispatch at `Uimport.pas:2893` (section index 9) and `2936` (section index 52)
- GUI writer: `Uexport.pas:661` — procedure `ExportGroundwater` (writes both `[GROUNDWATER]` at line 673 and `[GWF]` at line 736)
- GUI editor dialog: `Dgwater.pas` — `TGroundWaterForm`; custom equation sub-dialog `Dgweqn.pas`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[GROUNDWATER]` (line 957) and Section `[GWF]` (line 1017)
- Additional manual refs: `appendix_C_specialized_property_editors/C.6_Groundwater_Flow_Editor.md`; `appendix_C_specialized_property_editors/C.7_Groundwater_Equation_Editor.md`

## Row Format

```
Subcat  Aquifer  Node  Esurf  A1  B1  A2  B2  A3  Dsw  (Egwt  Ebot  Egw  Umc)
```

Columns 1–10 are required. Columns 11–14 are optional and can be omitted or replaced with `*` to signal "use the parent aquifer value." The GUI writes all 14 columns whenever any optional column is non-blank, substituting `*` for blank optional columns (`Uexport.pas:704–721`). The engine accepts `*` as a sentinel for MISSING and falls back to the parent aquifer value (`gwater.c:222–228`).

The `[GWF]` sub-section (written immediately after `[GROUNDWATER]` by `ExportGroundwater`) uses a different single-row format:

```
Subcat  LATERAL|DEEP  Expr
```

where `Expr` is a free-form mathematical expression that may span the rest of the line (`gwater.c:289–295`).

## Fields

### Subcat

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any name matching an entry in `[SUBCATCHMENTS]`
- **Default:** none
- **Cross-section dependency:** `[SUBCATCHMENTS].Name`
- **Database-key hint:** composite PK with (Subcat); also foreign key to [SUBCATCHMENTS].Name
- **Technical description:** Identifies the subcatchment whose groundwater behaviour is being configured. Only one `[GROUNDWATER]` row is permitted per subcatchment. The engine allocates a `TGroundwater` struct on the subcatchment (`gwater.c:231–237`) and attaches it via `Subcatch[j].groundwater`.
- **Source of truth:** `gwater.c:198–208` — `project_findObject(SUBCATCH, tok[0])`

---

### Aquifer

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any name matching an entry in `[AQUIFERS]`
- **Default:** none
- **Cross-section dependency:** `[AQUIFERS].Name`
- **Database-key hint:** foreign key to [AQUIFERS].Name
- **Technical description:** References the aquifer object that supplies soil hydraulic properties (porosity, conductivity, evaporation fractions, etc.) and default initial conditions shared by all subcatchments assigned to it. At runtime the engine dereferences this as `Aquifer[gw->aquifer]` to obtain `TAquifer` parameters (`gwater.c:367–373`). If the aquifer name is left blank in the GUI the subcatchment generates no groundwater flow (`Dgwater.pas:325`).
- **Source of truth:** `gwater.c:205–207` — `project_findObject(AQUIFER, tok[1])`

---

### Node

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any name matching a node in `[JUNCTIONS]`, `[OUTFALLS]`, `[DIVIDERS]`, or `[STORAGE]`
- **Default:** none
- **Cross-section dependency:** `[JUNCTIONS].Name` | `[OUTFALLS].Name` | `[DIVIDERS].Name` | `[STORAGE].Name`
- **Database-key hint:** foreign key to the node tables
- **Technical description:** The drainage-system node that receives lateral groundwater inflow (or from which bank-storage reverse flow can enter the aquifer). At each time step the engine reads `Node[n].newDepth` and `Node[n].invertElev` to establish the surface-water head Hsw used in the flow equation (`gwater.c:527–541`). When `Dsw` > 0 the node depth is overridden by the fixed surface-water depth.
- **Source of truth:** `gwater.c:208` — `project_findObject(NODE, tok[2])`

---

### Esurf

- **Data type:** REAL
- **Required:** yes
- **Units:** ft (US) / m (SI)
- **Valid values / range:** any real; must be ≥ initial water-table elevation (validated at `gwater.c:375`)
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Elevation of the ground surface above the aquifer for this subcatchment. Together with the aquifer bottom elevation it defines the total aquifer depth: `TotalDepth = surfElev − bottomElev` (`gwater.c:525`). Also used to cap the saturated-zone depth during initialisation (`gwater.c:406–409`). The engine rejects the configuration with `ERR_GROUND_ELEV` if `surfElev < waterTableElev` (`gwater.c:375–377`). Internally stored as ft after unit conversion: `x[0] / UCF(LENGTH)` (`gwater.c:242`).
- **Source of truth:** `gwater.c:242` — `gw->surfElev = x[0] / UCF(LENGTH)`

---

### A1

- **Data type:** REAL
- **Required:** yes
- **Units:** (cfs/acre) / ft^B1  (US) or (cms/ha) / m^B1 (SI) — units depend on B1
- **Valid values / range:** any real ≥ 0; set to 0 to suppress the groundwater-head term
- **Default:** `0` (GUI default, `Dgwater.pas:27`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Groundwater-head coefficient in the lateral flow equation: `QL = A1*(Hgw − Hcb)^B1 − A2*(Hsw − Hcb)^B2 + A3*Hgw*Hsw`. Controls the influence of the saturated-zone height above the channel bottom. When B1 = 0 the term degenerates to the constant A1 (`gwater.c:812–813`). Units must be consistent with `QL` in cfs/acre (US) or cms/ha (SI).
- **Source of truth:** `gwater.c:244` — `gw->a1 = x[1]`; flow computation at `gwater.c:812–813`

---

### B1

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (exponent)
- **Valid values / range:** any real ≥ 0; B1 = 0 makes the term a constant equal to A1
- **Default:** `0` (GUI default, `Dgwater.pas:27`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Exponent applied to the groundwater head difference `(Hgw − Hcb)` in the lateral flow equation. A value of 1.0 gives a linear response; higher values give a nonlinear response. When B1 = 0 the engine uses A1 directly as a constant (`gwater.c:812`).
- **Source of truth:** `gwater.c:245` — `gw->b1 = x[2]`

---

### A2

- **Data type:** REAL
- **Required:** yes
- **Units:** (cfs/acre) / ft^B2 (US) or (cms/ha) / m^B2 (SI)
- **Valid values / range:** any real ≥ 0; set to 0 to suppress the surface-water term
- **Default:** `0` (GUI default, `Dgwater.pas:27`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Surface-water coefficient in the lateral flow equation, counteracting groundwater outflow when the channel is also full. When A2 = A1 and B2 = B1 and A3 = 0 the equation reduces to flow proportional to the net head difference. Setting A2 = 0 means surface-water level has no direct suppressing effect on groundwater outflow (only the A3 interaction term can then represent back-flow). When B2 = 0 the term degenerates to constant A2 (`gwater.c:817–820`).
- **Source of truth:** `gwater.c:246` — `gw->a2 = x[3]`; computation at `gwater.c:816–820`

---

### B2

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (exponent)
- **Valid values / range:** any real ≥ 0
- **Default:** `0` (GUI default, `Dgwater.pas:27`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Exponent applied to the surface-water head difference `(Hsw − Hcb)`. When B2 = 0 the engine uses A2 directly as a constant for the surface-water term (`gwater.c:817`).
- **Source of truth:** `gwater.c:247` — `gw->b2 = x[4]`

---

### A3

- **Data type:** REAL
- **Required:** yes
- **Units:** (cfs/acre) / ft² (US) or (cms/ha) / m² (SI)
- **Valid values / range:** any real; typically 0 or a small positive value
- **Default:** `0` (GUI default, `Dgwater.pas:27`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Groundwater–surface-water interaction coefficient. Represents the combined head product term `A3 * Hgw * Hsw` in the flow equation. When A3 ≠ 0 the engine enforces a non-negative flow (`gwater.c:828`), preventing bank-storage reversal, because the cross-product term is derived from groundwater models that assume unidirectional flow (`C.6_Groundwater_Flow_Editor.md`). To guarantee no negative fluxes without this term: set A1 ≥ A2, B1 ≥ B2, and A3 = 0.
- **Source of truth:** `gwater.c:248` — `gw->a3 = x[5]`; enforcement at `gwater.c:828`

---

### Dsw

- **Data type:** REAL
- **Required:** yes
- **Units:** ft (US) / m (SI)
- **Valid values / range:** ≥ 0; set to 0 to use the dynamically computed surface-water depth from flow routing
- **Default:** `0` (GUI default, `Dgwater.pas:27`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Fixed depth of surface water above the receiving node's invert elevation. When > 0 the engine bypasses the actual simulated depth and uses this constant value to compute `Hsw = Dsw + Node[n].invertElev − bottomElev` (`gwater.c:538–539`). When = 0, the engine reads `Node[n].newDepth` for the current simulation depth (`gwater.c:541`). Useful for sensitivity analysis or when the drainage node is tidal with a known fixed stage. Internally stored as ft after `x[6] / UCF(LENGTH)` (`gwater.c:248`).
- **Source of truth:** `gwater.c:248` — `gw->fixedDepth = x[6] / UCF(LENGTH)`; runtime use at `gwater.c:537–541`

---

### Egwt

- **Data type:** REAL
- **Required:** no (default: use receiving node's invert elevation)
- **Units:** ft (US) / m (SI) — absolute elevation
- **Valid values / range:** any real elevation; leave blank or use `*` to inherit from node invert
- **Default:** `*` (blank — use node invert elevation; `Dgwater.pas:27` index 9 is `''`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Threshold water-table elevation (as an absolute elevation, not depth) that must be exceeded before any lateral groundwater flow occurs. Internally converted to height above the aquifer bottom: `Hstar = nodeElev − bottomElev` (`gwater.c:532–533`). If the water table height `lowerDepth ≤ Hstar`, `getGWFlow` returns zero (`gwater.c:809`). This allows the modeller to prevent premature groundwater outflow in subcatchments where the channel bottom sits above a naturally elevated node invert. The sentinel value MISSING causes the engine to fall back to `Node[n].invertElev − bottomElev` (`gwater.c:532–533`).
- **Source of truth:** `gwater.c:249` — `gw->nodeElev = x[7]`; runtime at `gwater.c:532–533`

---

### Ebot

- **Data type:** REAL
- **Required:** no (default: use parent aquifer's `Ebot`)
- **Units:** ft (US) / m (SI) — absolute elevation
- **Valid values / range:** any real elevation below Esurf and below Egw
- **Default:** `*` (blank — inherited from `[AQUIFERS].Ebot`; `Dgwater.pas:27` index 10 is `''`)
- **Cross-section dependency:** `[AQUIFERS].Ebot` (fallback)
- **Database-key hint:** plain data – no key role
- **Technical description:** Per-subcatchment override of the aquifer bottom elevation. The engine substitutes the parent aquifer value when this field is MISSING (`gwater.c:370`). This is useful when the local aquifer thickness differs from the representative value in the shared `[AQUIFERS]` record. Internally stored in ft: `x[8] /= UCF(LENGTH)` (`gwater.c:227`).
- **Source of truth:** `gwater.c:250` — `gw->bottomElev = x[8]`; fallback at `gwater.c:370`

---

### Egw

- **Data type:** REAL
- **Required:** no (default: use parent aquifer's `Egw`)
- **Units:** ft (US) / m (SI) — absolute elevation
- **Valid values / range:** any real; must be ≥ Ebot and ≤ Esurf (enforced indirectly through `ERR_GROUND_ELEV` and the init cap at `gwater.c:406`)
- **Default:** `*` (blank — inherited from `[AQUIFERS].Egw`; `Dgwater.pas:27` index 11 is `''`)
- **Cross-section dependency:** `[AQUIFERS].Egw` (fallback)
- **Database-key hint:** plain data – no key role
- **Technical description:** Per-subcatchment override of the initial water-table elevation. Used by `gwater_initState` to compute the initial saturated-zone depth: `lowerDepth = waterTableElev − bottomElev` (`gwater.c:405`). The engine caps this so the saturated zone cannot reach the surface (`gwater.c:406–409`). Internally stored in ft after `x[9] /= UCF(LENGTH)` (`gwater.c:227`).
- **Source of truth:** `gwater.c:251` — `gw->waterTableElev = x[9]`; fallback at `gwater.c:371`

---

### Umc

- **Data type:** REAL
- **Required:** no (default: use parent aquifer's `Umc`)
- **Units:** unitless (volumetric fraction, 0–1)
- **Valid values / range:** `wiltingPoint ≤ Umc < porosity` (validated indirectly through the aquifer validation and init clamping at `gwater.c:399–401`)
- **Default:** `*` (blank — inherited from `[AQUIFERS].Umc`; `Dgwater.pas:27` index 12 is `''`)
- **Cross-section dependency:** `[AQUIFERS].Umc` (fallback); must be between the aquifer's wilting point and porosity
- **Database-key hint:** plain data – no key role
- **Technical description:** Per-subcatchment override of the initial moisture content of the unsaturated upper zone (theta). Stored dimensionlessly (no unit conversion applied at `gwater.c:228`). Initialises `gw->theta` in `gwater_initState` (`gwater.c:398`); if the value exceeds porosity it is clamped to `porosity − XTOL` (`gwater.c:399–401`). Fallback to parent aquifer value occurs when MISSING (`gwater.c:372`).
- **Source of truth:** `gwater.c:252` — `gw->upperMoisture = x[10]`; fallback at `gwater.c:372`

---

## Notes

- **Column count:** The engine requires at minimum 11 tokens (cols 1–11, i.e. Subcat through Dsw); `ntoks < 11` triggers `ERR_ITEMS` (`gwater.c:202`). The GUI requires ≥ 10 tokens excluding the subcatchment name (`Uimport.pas:736`). The GUI always stores 13 groundwater parameters internally (indices 0–12 in the `Groundwater` TStringlist) and writes all of them if any optional column is non-blank (`Uexport.pas:709–721`).
- **`*` sentinel:** Both the engine and the GUI use `*` (the single asterisk character) as a sentinel meaning "use the parent aquifer value." The engine tests `*tok[m] != '*'` to detect it (`gwater.c:222`); the GUI substitutes `*` for empty strings at export time (`Uexport.pas:705`).
- **[GWF] section relationship:** The `[GWF]` section is parsed by the same source file (`gwater.c:258–311`) and exported by the same GUI procedure (`Uexport.pas:733–759`). The keyword on each [GWF] row must be exactly `LATERAL` or `DEEP` (prefix-matched with `match()`, so `LAT` also works in the engine — `gwater.c:285`). In the GUI these expressions are stored as `GwLatFlowEqn` and `GwDeepFlowEqn` on the `TSubcatch` object (`Uproject.pas:497–498`). For lateral flow the custom equation result is *added* to the standard equation; for deep flow it *replaces* the standard equation (`gwater.c:657–668`).
- **Flow equation variables available in [GWF]:** `HGW`, `HSW`, `HCB`, `HGS`, `KS`, `K`, `THETA`, `PHI`, `FI`, `FU`, `A` — all heights relative to aquifer bottom in ft or m (`gwater.c:56–57`, `GWVarWords[]`).
- **Unit consistency:** Flow-coefficient units depend on the project unit system. In US customary units, `QL` is in cfs/acre (equivalent to in/hr); in SI units, cms/ha. Users must ensure A1, A2, A3, and any custom equation results use consistent units.
- **Bank storage (negative flow):** When A3 = 0, `QL` can be negative, representing flow from the channel into the aquifer. The engine limits negative flow so the aquifer cannot accept more water than its unsaturated capacity or than the node is delivering (`gwater.c:559–562`). When A3 ≠ 0, negative QL is forced to zero (`gwater.c:828`).
- **Subcatchment uniqueness:** Each subcatchment may appear at most once in `[GROUNDWATER]`. The engine attaches the `TGroundwater` struct directly to `Subcatch[j].groundwater` (`gwater.c:231–237`) and overwrites any previous entry without error, so a duplicate row would silently replace the first.
- **Ordering:** No ordering constraint. The engine identifies the subcatchment by name lookup, not by position.
- **Aquifer vs. subcatchment initial conditions:** `[AQUIFERS]` provides shared defaults for `Ebot`, `Egw`, and `Umc`. The `[GROUNDWATER]` optional columns let each subcatchment override these when local conditions differ. The resolution order is: per-subcatchment [GROUNDWATER] value → parent [AQUIFERS] value (`gwater.c:370–372`).
- **`IGNORE_GROUNDWATER` option:** Setting `IGNORE_GROUNDWATER YES` in `[OPTIONS]` causes the engine to skip all groundwater calculations even if `[GROUNDWATER]` rows are present (`D.2_Input_File_Format.md` line 213).
