# [INFILTRATION]

**Purpose:** Supplies infiltration parameters for each subcatchment. These parameters govern the rate at which rainfall (and ponded water) infiltrates into the upper soil zone of a subcatchment's pervious sub-area. Infiltration is computed only for the pervious fraction of each subcatchment. The section supports five infiltration models — HORTON, MODIFIED_HORTON, GREEN_AMPT, MODIFIED_GREEN_AMPT, and CURVE_NUMBER — each requiring a different set of numerical parameters. A per-subcatchment method keyword may optionally override the project-wide default set in `[OPTIONS] INFILTRATION`.

**Occurrence:** One row per subcatchment. Every subcatchment that has a pervious sub-area should appear here; subcatchments present in `[SUBCATCHMENTS]` but absent from this section use the project-default infiltration method with zero or default parameters (no automatic error is raised by the engine, but the behaviour is physically meaningless).

**SWMM source references:**
- Engine parser: `infil.c:128` — function `infil_readParams`; dispatched from `input.c:502` — `case s_INFIL`
- Engine writer: Engine does not write INP files. The project-default infiltration method is echoed to the report file via `report.c:304`.
- GUI reader: `Uimport.pas:661` — function `ReadInfiltrationData`; dispatched at `Uimport.pas:2891`
- GUI writer: `Uexport.pas:591` — procedure `ExportInfiltration`
- GUI editor dialog: `Dinfil.pas` / `Dinfil.dfm` — `TInfilForm`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [INFILTRATION] (line 646)
- Additional manual refs: `appendix_C_specialized_property_editors/C.8_Infiltration_Editor.md`; `appendix_A_useful_tables/A.2_Soil_Characteristics.md`; `appendix_A_useful_tables/A.4_SCS_Curve_Numbers.md`; `chapter_03_swmms_conceptual_model/3.4_Computational_Methods.md`

## Row Format

The generic format is:

```
Subcat  p1  p2  p3  (p4  p5)  (Method)
```

The meaning of p1–p5 differs by infiltration method; p4 and p5 are only used for Horton/Modified Horton. The optional trailing `Method` keyword overrides the project-wide default. The GUI always emits all five parameter slots (unused ones are written as `0`).

### Per-method column layouts

**HORTON / MODIFIED_HORTON** (5 required numeric columns + optional Method):
```
Subcat  MaxRate  MinRate  Decay  DryTime  (MaxVol)  (Method)
```

**GREEN_AMPT / MODIFIED_GREEN_AMPT** (3 required numeric columns + optional Method):
```
Subcat  Suction  Ksat  IMD  (Method)
```

**CURVE_NUMBER** (3 token columns, second is deprecated + optional Method):
```
Subcat  CurveNumber  (unused)  DryTime  (Method)
```

The engine reads exactly `n` tokens depending on the method: 5 for Horton/Modified Horton, 4 for the others. Source: `infil.c:155–160`.

---

## Fields

### Subcat

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match an existing subcatchment name defined in `[SUBCATCHMENTS]`.
- **Default:** none
- **Cross-section dependency:** `[SUBCATCHMENTS].Name`
- **Database-key hint:** foreign key to `[SUBCATCHMENTS].Name`; also serves as primary identifier of this row (one row per subcatchment)
- **Technical description:** First token on every line; identifies the subcatchment whose pervious sub-area infiltration parameters are being specified. The engine looks up the subcatchment index via `project_findObject(SUBCATCH, tok[0])` and returns `ERR_NAME` if not found.
- **Source of truth:** `infil.c:143–144`

---

### Method

- **Data type:** ENUM
- **Required:** no (default: project-wide `[OPTIONS] INFILTRATION` value, itself defaulting to `HORTON`)
- **Units:** n/a
- **Valid values / range:**
  - `HORTON`
  - `MODIFIED_HORTON`
  - `GREEN_AMPT`
  - `MODIFIED_GREEN_AMPT`
  - `CURVE_NUMBER`
- **Default:** project-wide infiltration model set in `[OPTIONS] INFILTRATION` (`HORTON` if unspecified)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Optional trailing token on the data line. The engine performs prefix matching against `InfilModelWords[]` (keywords.c:60–61) on the **last** token. If a match is found, it is consumed and the effective model for this subcatchment is set to that value; the number of remaining numeric tokens is then re-evaluated (ntoks decremented). If absent, the method supplied as the `m` argument to `infil_readParams` (which equals the global `InfilModel` variable set by `[OPTIONS]`) is used instead. This mechanism (added in build 5.1.015) allows per-subcatchment override of the global infiltration method within a single project.
- **Source of truth:** `infil.c:147–160`; keyword strings in `text.h:132–136`; GUI option array in `objprops.txt:103–105`

---

## HORTON and MODIFIED_HORTON fields

These two models share the same parameter layout. MODIFIED_HORTON uses cumulative infiltration (Fe) rather than time-on-curve (tp) to track capacity, which better handles ponded conditions. Both use `horton_setParams()` and store their state in `THorton`.

### p1 — MaxRate (Horton/Modified Horton)

- **Data type:** REAL
- **Required:** yes
- **Units:** US: in/hr / SI: mm/hr
- **Valid values / range:** `≥ 0`; must be `≥ MinRate` (p2) — engine returns `FALSE` (error 235) if `f0 < fmin`
- **Default:** GUI default `3.0` (in/hr) (`objprops.txt:644`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Maximum (initial) infiltration rate on the Horton curve, f₀. The engine converts from user units (in/hr or mm/hr) to ft/sec internally: `infil->f0 = p[0] / UCF(RAINFALL)`. Representative values from the manual: sandy soils ~5 in/hr, loam ~3 in/hr, clay ~1 in/hr (dry, unvegetated); double these for dense vegetation. The `InfilFactor` (monthly hydraulic conductivity adjustment) is applied multiplicatively at runtime, not at parse time.
- **Source of truth:** `infil.c:337–338`, `infil.c:351`

### p2 — MinRate (Horton/Modified Horton)

- **Data type:** REAL
- **Required:** yes
- **Units:** US: in/hr / SI: mm/hr
- **Valid values / range:** `≥ 0`; must be `≤ MaxRate`
- **Default:** GUI default `0.5` (in/hr) (`objprops.txt:644`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Minimum (asymptotic) infiltration rate on the Horton curve, fmin. Equivalent physically to the soil's saturated hydraulic conductivity. See Soil Characteristics Table (`A.2_Soil_Characteristics.md`) for typical values by soil texture class (K column, range ~0.01–4.74 in/hr).
- **Source of truth:** `infil.c:339`, `infil.c:351`

### p3 — Decay (Horton/Modified Horton)

- **Data type:** REAL
- **Required:** yes
- **Units:** 1/hr (unitless rate)
- **Valid values / range:** `≥ 0`
- **Default:** GUI default `4` (1/hr) (`objprops.txt:644`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Decay rate constant kd of the Horton infiltration curve. The engine converts from 1/hr to 1/sec: `infil->decay = p[2] / 3600`. Typical values are 2–7 hr⁻¹. If `kd == 0` the infiltration rate is constant at f0.
- **Source of truth:** `infil.c:342`

### p4 — DryTime (Horton/Modified Horton)

- **Data type:** REAL
- **Required:** yes (required when n=5 tokens; however the parser special-cases it as "optional trailing" if ntoks > n: `infil.c:173–177`)
- **Units:** days
- **Valid values / range:** `> 0` (if 0 is supplied a TINY value is substituted to avoid division by zero)
- **Default:** GUI default `7` (days) (`objprops.txt:644`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Time for a fully saturated soil to dry completely. The engine converts to a regeneration constant kr (1/sec) assuming 98% dry along an exponential drying curve: `infil->regen = -log(1 - 0.98) / p[3] / SECperDAY`. This is then further scaled at runtime by `Evap.recoveryFactor`. Typical range is 2–14 days.
- **Source of truth:** `infil.c:346–347`

### p5 — MaxVol (Horton/Modified Horton)

- **Data type:** REAL
- **Required:** no (default: `0`, meaning no limit)
- **Units:** US: inches / SI: mm
- **Valid values / range:** `≥ 0`; `0` means unlimited (no cumulative cap applied)
- **Default:** `0` (`objprops.txt:644`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Maximum total cumulative infiltration volume Fmax. When non-zero, the engine tracks Fe (cumulative infiltration) and cuts off further infiltration once Fe reaches Fmax. Converted internally: `infil->Fmax = p[4] / UCF(RAINDEPTH)`. This parameter can be estimated as (porosity − wilting point) × depth of infiltration zone. The parser reads p5 only when `ntoks > n` after consuming the method keyword (`infil.c:173–177`).
- **Source of truth:** `infil.c:350`, `infil.c:173–177`

---

## GREEN_AMPT and MODIFIED_GREEN_AMPT fields

Both models use the Green-Ampt piston-flow equation and share the same three input parameters; they differ only in how the upper soil zone moisture deficit is updated during low-intensity rainfall periods. Parameters are stored in `TGrnAmpt` and set by `grnampt_setParams()`.

### p1 — Suction (Green-Ampt/Modified Green-Ampt)

- **Data type:** REAL
- **Required:** yes
- **Units:** US: inches / SI: mm
- **Valid values / range:** `≥ 0`
- **Default:** GUI default `3.5` (in) (`objprops.txt:645`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Average capillary suction head along the wetting front, Ψ. Stored internally in feet: `infil->S = p[0] / UCF(RAINDEPTH)`. Typical values by soil texture (from `A.2_Soil_Characteristics.md`, Ψ column): sand 1.93 in, loam 3.50 in, clay 12.60 in. Used in the Green-Ampt equation as part of the driving head term `(S + depth) * IMD` at runtime.
- **Source of truth:** `infil.c:585`, `grnampt_setParams`

### p2 — Ksat (Green-Ampt/Modified Green-Ampt)

- **Data type:** REAL
- **Required:** yes
- **Units:** US: in/hr / SI: mm/hr
- **Valid values / range:** `> 0` (strictly positive — the validation at `infil.c:584` requires `p[1] > 0`)
- **Default:** GUI default `0.5` (in/hr) (`objprops.txt:645`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Saturated hydraulic conductivity of the soil, Ks. Stored internally in ft/sec: `infil->Ks = p[1] / UCF(RAINFALL)`. Ks is also used to compute the upper soil zone depth Lu via Mein's equation: `Lu = 4.0 * sqrt(ksat_in_per_hr) / 12`. The `InfilFactor` (monthly adjustment, build 5.1.008) is applied to Ks at runtime. Typical values from Table A.2: sand 4.74 in/hr, clay 0.01 in/hr.
- **Source of truth:** `infil.c:584–591`

### p3 — IMD (Green-Ampt/Modified Green-Ampt)

- **Data type:** REAL
- **Required:** yes
- **Units:** fraction (dimensionless, ft/ft)
- **Valid values / range:** `0 ≤ IMD ≤ 1.0` (engine returns error if `p[2] < 0` or `p[2] > 1.0`)
- **Default:** GUI default `0.25` (`objprops.txt:645`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Initial soil moisture deficit (IMDmax), defined as the difference between soil porosity φ and the initial volumetric moisture content θ: IMD = φ − θ. Stored directly as `infil->IMDmax`. For a completely drained soil, IMD = φ − FC (field capacity). If IMD = 0 then no capillary-driven infiltration occurs (only gravity drainage at rate Ks). The engine performs an additional validity check (build 5.2.0 `ERR_INFIL_PARAMS` = 235) if the resulting parameters produce an invalid initial deficit. Typical values from Table A.2: porosity φ ranges from 0.398 (sandy clay loam) to 0.501 (silt loam).
- **Source of truth:** `infil.c:584`, `infil.c:587`; error code at `error.h:109`

---

## CURVE_NUMBER fields

Uses the NRCS (SCS) Curve Number approach. Total infiltration capacity is derived from the curve number; capacity depletes with cumulative rainfall and regenerates exponentially during dry periods. State is stored in `TCurveNum`.

### p1 — CurveNumber

- **Data type:** REAL (treated as a real number by the parser; internally clamped)
- **Required:** yes
- **Units:** unitless (dimensionless index)
- **Valid values / range:** Clamped to `[10, 99]` by the engine (values below 10 are raised to 10; values at or above 100 are rejected by the GUI with error code 3 in `Dinfil.pas:342`). The manual further restricts to CN < 100.
- **Default:** GUI default `80` (`objprops.txt:647`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** SCS Curve Number. The engine converts CN to maximum infiltration capacity Smax (ft) using the standard SCS formula: `Smax = (1000.0 / CN - 10.0) / 12.0` (converting from inches to feet). CN values by soil group and land use are tabulated in `appendix_A_useful_tables/A.4_SCS_Curve_Numbers.md`. Hydrologic soil groups are defined in `appendix_A_useful_tables/A.3_NRCS_Hydrologic_Soil_Group.md`.
- **Source of truth:** `infil.c:871–873`

### p2 — (deprecated, Curve Number only)

- **Data type:** REAL
- **Required:** yes (must be present syntactically as a token to satisfy the `n=4` token count requirement; the value is read into `x[1]` but never used)
- **Units:** n/a (was formerly in/hr or mm/hr representing a conductivity; now ignored)
- **Valid values / range:** Any real; typically `0` or the old Ksat value from earlier SWMM versions
- **Default:** GUI default `0.5` (`objprops.txt:647`; written as `0` if empty)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** This field was originally a saturated hydraulic conductivity for use in CN recovery but has been deprecated. The engine parses it as `x[1]` (index 1 in the zero-based parameter array), which is passed to `curvenum_setParams()` as `p[1]`; however `curvenum_setParams` does not reference `p[1]` at all. The GUI tooltip explicitly states "This property has been deprecated and its value is ignored." (`Dinfil.pas:101`). Retained for backward compatibility with older INP files. DB designers should store it as nullable/ignored.
- **Source of truth:** `infil.c:165–170`; `infil.c:877` (p[1] unused in `curvenum_setParams`); `Dinfil.pas:101`

### p3 — DryTime (Curve Number)

- **Data type:** REAL
- **Required:** yes
- **Units:** days
- **Valid values / range:** `> 0` (engine returns `FALSE` if `p[2] <= 0`, triggering error 235)
- **Default:** GUI default `7` (days) (`objprops.txt:647`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Time for a fully saturated soil to dry completely. The engine converts to a regeneration constant regen (1/sec): `infil->regen = 1.0 / (p[2] * SECperDAY)`. It also derives the maximum inter-event time `Tmax = 0.06 / regen`. During dry periods between rain events, infiltration capacity S regenerates toward Smax at rate `regen * Smax * tstep * Evap.recoveryFactor`. Typical range is 2–14 days. Read from `x[2]` i.e., the third numeric token after the subcatchment name.
- **Source of truth:** `infil.c:877–883`

---

## Notes

- **Section keyword prefix matching:** The engine matches the `[INFILTRATION]` section header using prefix matching via the `ws_INFIL` constant (`text.h:411` = `"[INFIL"`). Any line beginning with `[INFIL` activates this section parser. The full canonical keyword is `[INFILTRATION]`.

- **Token count by model:** The parser strictly requires `n` numeric tokens depending on the active method: 5 for HORTON/MODIFIED_HORTON, 4 for GREEN_AMPT/MODIFIED_GREEN_AMPT/CURVE_NUMBER. A line with fewer tokens causes `ERR_ITEMS`. The optional p5 (MaxVol) for Horton is consumed only if `ntoks > n` after the method keyword check. Source: `infil.c:155–177`.

- **Per-subcatchment method override:** Since build 5.1.015, the optional trailing `Method` keyword allows mixing infiltration models within a single project. The engine checks the last token against `InfilModelWords[]`; if it matches, the method for that row is set to that value and the token count is decremented before checking the required numeric count. The GUI writer (`Uexport.pas:622`) emits the method keyword only when a subcatchment's model differs from the project default.

- **MODIFIED_HORTON vs HORTON:** Both share the `THorton` struct and `horton_setParams()`. MODIFIED_HORTON uses the formula `fp = f0 - kd * Fe` (capacity as a linear function of cumulative infiltration) instead of the time-based exponential, tracking recovery via `Fe *= exp(-kr * tstep)`. Source: `infil.c:496–555`.

- **MODIFIED_GREEN_AMPT vs GREEN_AMPT:** Both use the same three parameters and `grnampt_setParams()`. The difference is in how IMD is depleted during below-Ksat rainfall: GREEN_AMPT resets IMD at the start of each new wetting event, while MODIFIED_GREEN_AMPT does not deplete moisture deficit in the upper zone during low-intensity rain. Source: `infil.c:715–719`.

- **InfilFactor (monthly conductivity adjustment):** At runtime the engine applies a global or subcatchment-specific monthly pattern factor (`InfilFactor`) to hydraulic conductivity for both Horton and Green-Ampt models. This factor is set via `infil_setInfilFactor()` from either `Adjust.hydconFactor` (global) or a MONTHLY pattern assigned to `Subcatch[j].infilPattern`. It does not affect CURVE_NUMBER. Source: `infil.c:262–284`.

- **Infiltration applies only to pervious sub-area:** Impervious sub-areas of a subcatchment generate no infiltration; the engine calls `infil_getInfil()` from `getSubareaRunoff()` only for the pervious fraction.

- **Green-Ampt also used by storage nodes:** The `grnampt_setParams()` / `grnampt_initState()` / `grnampt_getInfil()` functions are reused for seepage through the bottom/sides of storage nodes (via `[STORAGE]` section Psi/Ksat/IMD columns). The same parameter semantics apply. Source: `infil.c:59–66`, `infil.h:106–110`.

- **Error 235 (ERR_INFIL_PARAMS):** Returned by the engine when `horton_setParams`, `grnampt_setParams`, or `curvenum_setParams` returns FALSE due to invalid parameter values (e.g., f0 < fmin, Ksat ≤ 0, IMD > 1, DryTime ≤ 0 for CN). Source: `infil.c:195`; `error.h:109`.

- **GUI default values (objprops.txt):** Horton defaults: MaxRate=3.0, MinRate=0.5, Decay=4, DryTime=7, MaxVol=0. Green-Ampt defaults: Suction=3.5, Ksat=0.5, IMD=0.25. Curve Number defaults: CN=80, deprecated=0.5, DryTime=7. Source: `objprops.txt:643–648`.

- **Ordering and uniqueness:** One row per subcatchment; the subcatchment name is effectively the primary key. Duplicate rows for the same subcatchment would cause the second to overwrite the first in the engine (last-parsed wins), but the GUI never emits duplicates.
