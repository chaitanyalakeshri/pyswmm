# [AQUIFERS]

**Purpose:** Defines the physical and hydraulic properties of each unconfined groundwater aquifer in the study area. Each aquifer object represents a subsurface soil column composed of two coupled zones: a lower saturated zone (where pore space is fully filled with water) and an upper unsaturated zone (where moisture varies between the wilting point and full saturation), with a moving boundary (the water table) separating them. Aquifer objects supply the soil parameters used by SWMM's groundwater module to compute percolation through the unsaturated zone, evapotranspiration losses, lateral discharge to the drainage network, and deep seepage to a lower aquifer. One aquifer object can be shared by multiple subcatchments; per-subcatchment overrides for initial conditions are provided in the companion `[GROUNDWATER]` section.

**Occurrence:** One row per aquifer object. Each named aquifer appears exactly once. Multiple subcatchments may reference the same aquifer name via the `[GROUNDWATER]` section.

**SWMM source references:**
- Engine parser: `gwater.c:119` — function `gwater_readAquiferParams`
- Engine object count / pre-pass: `input.c:274` — `addObject` case `s_AQUIFER`
- Engine data-read dispatch: `input.c:505` — `input_readData` case `s_AQUIFER`
- Engine validation: `gwater.c:328` — function `gwater_validateAquifer` (called from `swmm_open`)
- Engine writer: engine does not write INP files; no report-echo function for this section exists in `inputrpt.c`
- GUI reader: `Uimport.pas:691` — function `ReadAquiferData` (dispatched at `Uimport.pas:2892`)
- GUI writer: `Uexport.pas:628` — procedure `ExportAquifers`
- GUI editor dialog: `Daquifer.pas` — `TAquiferForm`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[AQUIFERS]` (lines 918–954)
- Additional manual refs: `appendix_C_specialized_property_editors/C.1_Aquifer_Editor.md`; `chapter_03_swmms_conceptual_model/3.3_Non-Visual_Objects.md` §3.3.3; `appendix_C/C.6_Groundwater_Flow_Editor.md`

## Row Format

Each data row provides exactly 13 required tokens plus one optional token:

```
Name  Por  WP  FC  Ks  Kslp  Tslp  ETu  ETs  Seep  Ebot  Egw  Umc  (Epat)
```

The GUI comment header emitted by `ExportAquifers` (`Uexport.pas:639–642`) labels the columns:

```
;;Name           Por    WP     FC     Ksat   Kslope Tslope ETu    ETs    Seep   Ebot   Egw    Umc    ETupat
```

The engine requires `ntoks >= 13` (token 0 = Name, tokens 1–12 = the 12 numeric parameters); token 13, if present, is the optional evaporation pattern name (`gwater.c:139`).

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-empty string without internal whitespace; must be unique among all aquifer names (duplicate triggers `ERR_DUP_NAME` at `input.c:275–277`). The GUI enforces no-space and uniqueness in `Daquifer.pas:133–256`.
- **Default:** none
- **Cross-section dependency:** None (this field is the primary key; the `[GROUNDWATER]` section references it)
- **Database-key hint:** primary identifier of this row
- **Technical description:** The user-assigned label for this aquifer. It is the string stored in `TAquifer.ID` (`objects.h:238`). The section-heading match uses prefix `[AQUIFER` (`text.h:412`), so the bracketed keyword `[AQUIFERS]` is recognized by the engine's `findmatch` prefix logic.
- **Source of truth:** `input.c:274–278` (object registration), `gwater.c:140–141` (name lookup during data read)

---

### Por (Porosity)

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (volumetric fraction, volume of voids / total soil volume)
- **Valid values / range:** `> 0`; must be greater than `FC` (field capacity); validated at `gwater.c:337–338`
- **Default:** `0.5` (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Soil porosity — the fraction of total soil volume occupied by pore space. Sets the upper bound on moisture content. Stored as `Aquifer[j].porosity` (`objects.h:239`). The engine validation rejects any aquifer where `porosity <= 0` or where `fieldCapacity >= porosity`.
- **Source of truth:** `gwater.c:161` (assignment), `gwater.c:337` (validation)

---

### WP (Wilting Point)

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (volumetric fraction)
- **Valid values / range:** `≥ 0`; must be strictly less than `FC`; validated indirectly at `gwater.c:339`
- **Default:** `0.15` (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The residual soil moisture content of a completely dry soil — the moisture content at which plants can no longer extract water. This is the lower bound on moisture content in the unsaturated zone. The initial unsaturated zone moisture (`Umc`) must satisfy `Umc >= WP` (`gwater.c:347`). Stored as `Aquifer[j].wiltingPoint` (`objects.h:240`).
- **Source of truth:** `gwater.c:162` (assignment), `gwater.c:339` (validation via `wiltingPoint >= fieldCapacity`)

---

### FC (Field Capacity)

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (volumetric fraction)
- **Valid values / range:** `> WP` and `< Por`; validated at `gwater.c:338–339`
- **Default:** `0.30` (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The soil moisture content after all gravitational (free) water has drained from the soil. Below field capacity, downward percolation through the unsaturated zone does not occur. Stored as `Aquifer[j].fieldCapacity` (`objects.h:241`).
- **Source of truth:** `gwater.c:163` (assignment), `gwater.c:338` (validation: `fieldCapacity >= porosity`)

---

### Ks (Saturated Hydraulic Conductivity)

- **Data type:** REAL
- **Required:** yes
- **Units:** in/hr (US) / mm/hr (SI) — converted internally to ft/sec by dividing by `UCF(RAINFALL)` at `gwater.c:164`
- **Valid values / range:** `> 0`; validated at `gwater.c:340`
- **Default:** `5.0` (in/hr) (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The hydraulic conductivity of the soil when fully saturated. Used to compute percolation from the unsaturated zone to the saturated zone and to drive the groundwater table dynamics. Internally stored in ft/sec as `Aquifer[j].conductivity` (`objects.h:242`).
- **Source of truth:** `gwater.c:164` (assignment with unit conversion), `gwater.c:340` (validation)

---

### Kslp (Conductivity Slope)

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (dimensionless)
- **Valid values / range:** `≥ 0`; validated at `gwater.c:341`
- **Default:** `10.0` (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The average slope of the curve that relates the logarithm of hydraulic conductivity to the soil moisture deficit (porosity minus moisture content). It is used in the Brooks-Corey or similar empirical relationship for unsaturated hydraulic conductivity. Larger values produce a steeper exponential decrease in conductivity with decreasing moisture. Stored as `Aquifer[j].conductSlope` (`objects.h:243`).
- **Source of truth:** `gwater.c:165` (assignment), `gwater.c:341` (validation: `conductSlope < 0.0`)

---

### Tslp (Tension Slope)

- **Data type:** REAL
- **Required:** yes
- **Units:** inches (US) / mm (SI) — converted internally to ft by dividing by `UCF(LENGTH)` at `gwater.c:166`
- **Valid values / range:** `≥ 0`; validated at `gwater.c:342`
- **Default:** `15.0` (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The average slope of the soil tension (capillary suction head) versus soil moisture content curve. Used to compute capillary forces that drive moisture redistribution in the unsaturated zone. Internally stored in ft as `Aquifer[j].tensionSlope` (`objects.h:244`).
- **Source of truth:** `gwater.c:166` (assignment with unit conversion), `gwater.c:342` (validation)

---

### ETu (Upper Evaporation Fraction)

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (fraction, 0–1)
- **Valid values / range:** `≥ 0`; validated at `gwater.c:343`; the GUI input mask is `emPosNumber` (`Daquifer.pas:140`) which enforces non-negative values
- **Default:** `0.35` (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The fraction of the potential evaporation rate that is available for evapotranspiration from the upper unsaturated zone. A value of 1.0 means the full potential evaporation rate can be drawn from the unsaturated zone; lower values reduce ET from that zone. This fraction can be further modified month by month if an `Epat` pattern is supplied. Stored as `Aquifer[j].upperEvapFrac` (`objects.h:245`).
- **Source of truth:** `gwater.c:167` (assignment), `gwater.c:343` (validation)

---

### ETs (Lower Evaporation Depth)

- **Data type:** REAL
- **Required:** yes
- **Units:** ft (US) / m (SI) — converted internally from ft/m by dividing by `UCF(LENGTH)` at `gwater.c:168`
- **Valid values / range:** `≥ 0`; validated at `gwater.c:344`
- **Default:** `14.0` (ft) (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The maximum depth below the ground surface into the lower saturated zone over which evapotranspiration can still occur. When the water table lies below this depth, ET from the saturated zone is zero. Stored as `Aquifer[j].lowerEvapDepth` (`objects.h:246`).
- **Source of truth:** `gwater.c:168` (assignment with unit conversion), `gwater.c:344` (validation)

---

### Seep (Lower Groundwater Loss Rate)

- **Data type:** REAL
- **Required:** yes
- **Units:** in/hr (US) / mm/hr (SI) — converted internally to ft/sec by dividing by `UCF(RAINFALL)` at `gwater.c:169`
- **Valid values / range:** `≥ 0` (GUI mask is `emPosNumber`; no explicit lower-bound check beyond non-negative)
- **Default:** `0.002` (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The seepage rate from the lower saturated zone to a deep (unmodeled) groundwater layer when the water table is at the ground surface. The actual deep seepage rate at any time step is computed as a function of this coefficient and the current water-table elevation relative to the ground surface (see `C.6_Groundwater_Flow_Editor.md` for the deep flow formula). This loss is irretrievable and acts as a sink on the groundwater balance. Stored as `Aquifer[j].lowerLossCoeff` (`objects.h:247`).
- **Source of truth:** `gwater.c:169` (assignment with unit conversion)

---

### Ebot (Bottom Elevation)

- **Data type:** REAL
- **Required:** yes
- **Units:** ft (US) / m (SI) — converted internally by dividing by `UCF(LENGTH)` at `gwater.c:170`
- **Valid values / range:** any real (can be negative for below-datum aquifers); must be `≤ Egw` (validated at `gwater.c:345`). The GUI input mask is `emNumber` (allows negative values), `Daquifer.pas:143`.
- **Default:** `0.0` (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The elevation of the impermeable bottom boundary of the aquifer, in the same datum as the rest of the model. This determines the total aquifer thickness and is used as the reference elevation for computing heights of the saturated and unsaturated zones. Individual subcatchments may override this value via the `[GROUNDWATER]` section `Ebot` field. Stored as `Aquifer[j].bottomElev` (`objects.h:249`).
- **Source of truth:** `gwater.c:170` (assignment with unit conversion), `gwater.c:345` (validation: `waterTableElev < bottomElev`)

---

### Egw (Initial Water Table Elevation)

- **Data type:** REAL
- **Required:** yes
- **Units:** ft (US) / m (SI) — converted internally by dividing by `UCF(LENGTH)` at `gwater.c:171`
- **Valid values / range:** any real; must be `≥ Ebot` (validated at `gwater.c:345`). The GUI input mask is `emNumber` (allows negative values), `Daquifer.pas:144`.
- **Default:** `10.0` (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The elevation of the groundwater table at the start of the simulation. Together with `Ebot`, this determines the initial depth of the saturated zone. Individual subcatchments may override this value in the `[GROUNDWATER]` section. Stored as `Aquifer[j].waterTableElev` (`objects.h:250`).
- **Source of truth:** `gwater.c:171` (assignment with unit conversion), `gwater.c:345` (validation)

---

### Umc (Unsaturated Zone Initial Moisture)

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (volumetric fraction)
- **Valid values / range:** `WP ≤ Umc ≤ Por`; validated at `gwater.c:346–347`
- **Default:** `0.30` (GUI default, `Daquifer.pas:84`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The initial volumetric moisture content of the unsaturated upper zone at the start of the simulation. Must lie between the wilting point and the porosity. This sets the initial state of the unsaturated zone ODE solver. Individual subcatchments may override this value via the `[GROUNDWATER]` section. Stored as `Aquifer[j].upperMoisture` (`objects.h:251`).
- **Source of truth:** `gwater.c:172` (assignment), `gwater.c:346–347` (validation)

---

### Epat (Upper Evaporation Pattern)

- **Data type:** NAME_REF
- **Required:** no (default: `""` — blank, no pattern applied)
- **Units:** n/a
- **Valid values / range:** name of an existing `[PATTERNS]` object whose type is `MONTHLY` (12 multipliers). If the named pattern exists but is not of type `MONTHLY_PATTERN`, validation fails with `ERR_AQUIFER_PARAMS` (`gwater.c:351–353`). If the token is absent entirely, the internal index is set to `-1` (`gwater.c:152`).
- **Default:** `""` (no pattern; `Daquifer.pas:85`)
- **Cross-section dependency:** `[PATTERNS].Name` where pattern type = `MONTHLY`
- **Database-key hint:** foreign key to `[PATTERNS].Name`
- **Technical description:** An optional name of a monthly time pattern whose 12 multiplier values are applied each month to scale the `ETu` (upper evaporation fraction). This allows seasonal variation in evapotranspiration from the unsaturated zone without altering the base fraction. If omitted or blank, the `ETu` value is used unchanged throughout the simulation. The GUI renders this field as a combo-edit populated from the project's `PATTERN` list (`Daquifer.pas:145–146`). Stored as `Aquifer[j].upperEvapPat` (`objects.h:252`).
- **Source of truth:** `gwater.c:152–157` (optional token read and lookup), `gwater.c:350–354` (validation that pattern type is MONTHLY)

---

## Notes

- **Section-keyword prefix matching:** The engine matches section headings by prefix. The macro `ws_AQUIFER` is defined as `"[AQUIFER"` (`text.h:412`). Therefore `[AQUIFERS]` (with the trailing `S]`) is correctly recognized. No other section name starts with `[AQUIFER`, so there is no ambiguity.

- **Minimum token count:** The engine requires exactly 13 tokens (Name + 12 numeric parameters) before attempting to read the optional 14th token (`Epat`). Fewer than 13 tokens triggers `ERR_ITEMS` (`gwater.c:139`).

- **Two-pass parsing:** During the first pass (`input_countObjects`), the engine registers each aquifer name via `project_addObject(AQUIFER, ...)` (`input.c:275`). Duplicate names are rejected immediately with `ERR_DUP_NAME`. During the second pass (`input_readData`), `gwater_readAquiferParams` looks up the pre-registered name with `project_findID` (`gwater.c:140`); an unrecognised name returns `ERR_NAME`.

- **Unit conversion on read:** Five of the twelve numeric parameters undergo unit conversion when read: `Ks` and `Seep` are divided by `UCF(RAINFALL)` (converting in/hr or mm/hr → ft/sec); `Tslp`, `ETs`, `Ebot`, and `Egw` are divided by `UCF(LENGTH)` (ft or m → ft internally). The remaining parameters (`Por`, `WP`, `FC`, `Kslp`, `ETu`, `Umc`) are dimensionless fractions or slopes and are stored as-is.

- **Per-subcatchment overrides:** The `[GROUNDWATER]` section allows `Ebot`, `Egw`, and `Umc` to be overridden for individual subcatchments. When a `[GROUNDWATER]` record's optional fields are absent (i.e., stored as `MISSING`), the aquifer-level values are substituted at validation time (`gwater.c:369–372`).

- **Evaporation pattern constraint:** The `Epat` field, if provided, must reference a pattern of type `MONTHLY_PATTERN` (12 monthly factors). Patterns of type `DAILY_PATTERN`, `HOURLY_PATTERN`, or `WEEKEND_PATTERN` are rejected during `gwater_validateAquifer` with error `ERR_AQUIFER_PARAMS` (error code 109, `error.h:27`).

- **Uniqueness:** Each aquifer must have a unique name. The same aquifer object (same name) cannot appear more than once in the `[AQUIFERS]` section; doing so triggers `ERR_DUP_NAME` in the first pass.

- **Relationship to `[GROUNDWATER]`:** The `[AQUIFERS]` section defines aquifer-wide soil properties. The `[GROUNDWATER]` section binds a specific subcatchment to an aquifer by name and provides the flow-exchange parameters and optional per-subcatchment initial conditions. An aquifer defined in `[AQUIFERS]` but not referenced by any `[GROUNDWATER]` row is parsed and stored without error but has no effect on the simulation.

- **GUI data array layout:** The GUI stores the 13 data values (indices 0–12) in `TAquifer.Data[0..MAXAQUIFERPROPS]` where `MAXAQUIFERPROPS = 12` (`Uproject.pas:29`, `595`). Index 0 = `Por`, index 11 = `Umc`, index 12 = `Epat`. The aquifer name is stored separately as the key in `Project.Lists[AQUIFER]`.
