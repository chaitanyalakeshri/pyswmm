# [WASHOFF]

**Purpose:** Specifies the rate at which pollutants are washed off from each land use category during wet-weather runoff events. Each row pairs a land use with a pollutant and assigns one of three washoff function types (EXP, RC, or EMC) along with the function's coefficients and optional removal efficiencies for street sweeping and best-management practices (BMPs). The section is the companion to `[BUILDUP]` and is used by the surface water-quality engine to compute the pollutant load leaving each subcatchment at every time step.

**Occurrence:** Multiple rows per object. There is one row for every (land use, pollutant) combination that has washoff behaviour defined. A land use with N pollutants can appear up to N times in this section. Land-use/pollutant pairs that have no washoff (i.e. function type NONE) are simply omitted.

**SWMM source references:**
- Engine parser: `swmm/swmm524_engine/src/input.c:571` — dispatch `case s_WASHOFF` calls `landuse_readWashoffParams(Tok, Ntokens)` defined at `swmm/swmm524_engine/src/landuse.c:281`
- Engine writer: Engine does not write INP files. No report-echo function for `[WASHOFF]` exists in `inputrpt.c`.
- GUI reader: `swmm/swmm524_gui/Epaswmm5/Uimport.pas:1662` — function `ReadWashoffData`; dispatched from the main section handler at line 2910 (case 26).
- GUI writer: `swmm/swmm524_gui/Epaswmm5/Uexport.pas:1538` — procedure `ExportWashoff`
- GUI editor dialog: `swmm/swmm524_gui/Epaswmm5/Dlanduse.pas` — `TLanduseForm`, Washoff tab; dropdown list defined at line 163 (`'NONE'#13'EXP'#13'RC'#13'EMC'`); default values at line 92 (`DefWashoff: ('EMC', '0.0', '0.0', '0.0', '0.0')`)
- Manual: `swmm/swmm-users-manual-version-5.2/appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[WASHOFF]`, Table D-4 "Pollutant wash off functions"
- Additional manual refs: `chapter_03_swmms_conceptual_model/3.3_Non-Visual_Objects.md` (Pollutant Washoff subsection, equations); `appendix_C_specialized_property_editors/C.14_Land_Use_Editor.md` (Washoff Page description)

## Row Format

```
Landuse  Pollutant  FuncType  C1  C2  SweepRmvl  BmpRmvl
```

All seven tokens are expected by the GUI reader (`Uimport.pas:1673`: `if nToks < 7 then Result := ErrMsg(ITEMS_ERR, '')`). The engine parser requires at least 5 tokens when FuncType is not NONE (`landuse.c:308`); SweepRmvl and BmpRmvl default to 0 if omitted.

## Fields

### Landuse

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must exactly match a name declared in `[LANDUSES]`.
- **Default:** none
- **Cross-section dependency:** `[LANDUSES].Name`
- **Database-key hint:** composite PK with `Pollutant` (first half of the composite key)
- **Technical description:** Identifies the land use category for which this washoff function applies. The engine calls `project_findObject(LANDUSE, tok[0])` and returns `ERR_NAME` if not found (`landuse.c:298–299`). In the GUI the matching is done via `Project.Lists[LANDUSE].IndexOf(TokList[0])` (`Uimport.pas:1676`). A land use may have at most one washoff entry per pollutant, but can appear in as many rows as there are pollutants.
- **Source of truth:** `swmm/swmm524_engine/src/landuse.c:298–299`

---

### Pollutant

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must exactly match a name declared in `[POLLUTANTS]`.
- **Default:** none
- **Cross-section dependency:** `[POLLUTANTS].Name`
- **Database-key hint:** composite PK with `Landuse` (second half of the composite key)
- **Technical description:** Identifies the pollutant whose washoff is being described. The engine calls `project_findObject(POLLUT, tok[1])` and returns `ERR_NAME` if not found (`landuse.c:300–301`). The GUI resolves it through `Project.Lists[POLLUTANT].IndexOf(TokList[1])` (`Uimport.pas:1677`). At runtime, the engine stores washoff functions in the array `Landuse[j].washoffFunc[p]` indexed by pollutant ordinal (`landuse.c:345`).
- **Source of truth:** `swmm/swmm524_engine/src/landuse.c:300–301`

---

### FuncType

- **Data type:** ENUM
- **Required:** yes
- **Units:** unitless
- **Valid values / range:**
  - `NONE` — no washoff (enum `NO_WASHOFF = 0`)
  - `EXP` — exponential washoff (enum `EXPON_WASHOFF = 1`)
  - `RC` — rating curve washoff (enum `RATING_WASHOFF = 2`)
  - `EMC` — event mean concentration (enum `EMC_WASHOFF = 3`)
  - Matching is done with `findmatch(tok[2], WashoffTypeWords)` where `WashoffTypeWords[] = { w_NONE, w_EXP, w_RC, w_EMC, NULL }` (`keywords.c:156`). Prefix matching applies: `NONE`, `EXP`, `RC`, `EMC` are the canonical tokens (`text.h:299–300, 289`).
- **Default:** `EMC` (GUI default, `Dlanduse.pas:92`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Selects the mathematical model used to compute the pollutant washoff rate. When `NONE` is specified the parser skips reading C1/C2 but still stores `NO_WASHOFF` in `funcType` (`landuse.c:297, 306`). The three active function types have different output units and different interpretations of C1 and C2 (see fields below and Table D-4 in the manual). The engine also branches on this enum inside `landuse_getWashoffQual()` (`landuse.c:630`).
- **Source of truth:** `swmm/swmm524_engine/src/landuse.c:304–306`; enum definition at `enums.h:318–322`

---

### C1

- **Data type:** REAL
- **Required:** yes (when FuncType ≠ NONE)
- **Units:**
  - EXP: (in/hr)^(−C2) per hour in US units, or (mm/hr)^(−C2) per hour in SI — stored internally divided by 3600 (`landuse.c:340`)
  - RC: depends on the flow units set in `[OPTIONS]` — stored internally multiplied by `UCF(FLOW)^C2` (`landuse.c:341`)
  - EMC: concentration in mass/L (same as the pollutant's concentration units) — stored internally multiplied by `LperFT3` (`landuse.c:342`)
- **Valid values / range:** `≥ 0` (engine returns `ERR_NUMBER` if `x[0] < 0.0`, `landuse.c:331`)
- **Default:** `0.0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The primary washoff coefficient, called C1 in Table D-4 of the manual. Its physical meaning differs by function type:
  - **EXP**: proportionality constant in `W = C1 · q^C2 · B` where W is mass/hour, q is runoff per unit area (in/hr or mm/hr), and B is the current buildup mass. The engine divides the stored value by 3600 to convert to mass/sec internally.
  - **RC**: proportionality constant in `W = C1 · Q^C2` where W is mass/sec and Q is runoff in user-defined flow units. The engine scales the coefficient at parse time by `UCF(FLOW)^C2` to convert to internal units (ft³/s).
  - **EMC**: the event mean concentration of the pollutant in the washoff. Entered in the same concentration units as the pollutant (mg/L, µg/L, or counts/L). Internally multiplied by `LperFT3` (28.317 L/ft³) to convert to mass/ft³.
  The GUI labels this field "Coefficient" (`Dlanduse.pas:164`).
- **Source of truth:** `swmm/swmm524_engine/src/landuse.c:309–310, 331, 339–342`

---

### C2

- **Data type:** REAL
- **Required:** yes (when FuncType ≠ NONE)
- **Units:** unitless (dimensionless exponent)
- **Valid values / range:** `−10 ≤ C2 ≤ 10` — the engine returns `ERR_NUMBER` outside this range (`landuse.c:332–333`)
- **Default:** `0.0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The exponent in the washoff function. Its role depends on FuncType:
  - **EXP**: the exponent applied to the runoff rate per unit area (q) in `W = C1 · q^C2 · B`. Typical values in literature are 1–2.
  - **RC**: the exponent applied to the total runoff flow Q in `W = C1 · Q^C2`. A value of 1.0 with an appropriate C1 degenerates to an EMC-equivalent.
  - **EMC**: C2 is parsed and stored but ignored at runtime — the washoff concentration is simply the constant C1 regardless of C2.
  The GUI labels this field "Exponent" (`Dlanduse.pas:165`).
- **Source of truth:** `swmm/swmm524_engine/src/landuse.c:311–313, 332–333, 347`

---

### SweepRmvl

- **Data type:** REAL
- **Required:** no (default: `0.0`)
- **Units:** percent (0–100 %)
- **Valid values / range:** `0 ≤ SweepRmvl ≤ 100` — engine returns `ERR_NUMBER` outside this range (`landuse.c:334–335`)
- **Default:** `0.0`
- **Cross-section dependency:** None — but interacts with the street sweeping parameters (`SweepInterval`, `SweepAvailability`, `LastSwept`) on the parent `[LANDUSES]` entry.
- **Database-key hint:** plain data – no key role
- **Technical description:** The fraction of pollutant buildup available for sweeping removal (as a percent) that is actually removed for this specific pollutant during a sweeping event. The engine stores this as a fraction (divides by 100, `landuse.c:348`): `sweepEffic = x[2] / 100.0`. This is a per-pollutant efficiency applied on top of the land-use-wide availability factor set in `[LANDUSES]`. If the land use has no sweeping interval, this field has no effect. The GUI labels this "Cleaning Effic." (`Dlanduse.pas:166`; hint at line 127).
- **Source of truth:** `swmm/swmm524_engine/src/landuse.c:313–317, 334–335, 348`

---

### BmpRmvl

- **Data type:** REAL
- **Required:** no (default: `0.0`)
- **Units:** percent (0–100 %)
- **Valid values / range:** `0 ≤ BmpRmvl ≤ 100` — engine returns `ERR_NUMBER` outside this range (`landuse.c:336–337`)
- **Default:** `0.0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** A lumped removal efficiency (percent) representing any best management practice (BMP) controls associated with this land use that are not explicitly modelled as LID controls. At each time step, after the washoff load is calculated and buildup is reduced, the engine reduces the load by `bmpEffic` fraction before routing it into the conveyance system (`landuse.c:599–603`). Stored internally as a fraction (`landuse.c:349`). The `landuse_getAvgBMPEffic()` function also uses this field to compute the average BMP efficiency across all land uses for ponded water quality (`landuse.c:543–547`). The GUI labels this "BMP Effic." (`Dlanduse.pas:167`; hint at line 128–129).
- **Source of truth:** `swmm/swmm524_engine/src/landuse.c:319–322, 336–337, 349, 599–603`

---

## Notes

- **Token count requirement:** The GUI reader (`Uimport.pas:1673`) requires all 7 tokens; entering fewer raises an `ITEMS_ERR`. The engine parser is slightly more permissive: it only requires ≥ 5 tokens when FuncType ≠ NONE (`landuse.c:308`), and treats SweepRmvl and BmpRmvl as optional (defaulting to 0).
- **NONE function type:** When FuncType is `NONE`, C1, C2, SweepRmvl, and BmpRmvl are all set to 0.0 and no washoff computation occurs for that (land use, pollutant) pair (`landuse.c:297, 306`). The GUI dropdown includes NONE as the first option (`Dlanduse.pas:163`), but the default for new entries is EMC (`Dlanduse.pas:92`).
- **EMC without buildup:** The EMC function type can be used even if no buildup function is defined for the same (land use, pollutant) pair. The engine permits EMC-based washoff to proceed even when buildup is zero, because the check `if buildup == 0 return 0` only applies when a non-trivial buildup function exists (`landuse.c:635–637`). This allows EMC to represent a constant event concentration loading. (Manual, `3.3_Non-Visual_Objects.md`, Pollutant Washoff section.)
- **Internal unit conversions at parse time:** All three function types have their coefficients converted to internal units (ft-lb-sec) at parse time, not at runtime. This means the stored `coeff` value in `Landuse[j].washoffFunc[p].coeff` does NOT equal the user-entered C1 (`landuse.c:339–342`). Database consumers must store the user-entered value (pre-conversion), not the internal value.
- **Composite key:** The (Landuse, Pollutant) pair must be unique within this section. The engine stores one `TWashoff` struct per pollutant per land use in `Landuse[j].washoffFunc[p]` — duplicate entries for the same pair silently overwrite the previous one.
- **Cross-section ordering dependency:** `[LANDUSES]` and `[POLLUTANTS]` must be parsed before `[WASHOFF]` so that name-resolution lookups succeed. This ordering is enforced by the standard INP section dispatch.
- **Relationship to `[BUILDUP]`:** The EXP washoff function explicitly depends on the current buildup mass (B) computed from `[BUILDUP]` parameters. RC and EMC do not depend on buildup, but all function types deplete the buildup pool as washoff proceeds (`landuse.c:582–596`).
- **Co-pollutant interaction:** After washoff loads are computed per land use, `landuse_getCoPollutLoad()` can add additional load from co-pollutant relationships defined in `[POLLUTANTS]`. This is unrelated to `[WASHOFF]` parameters but part of the same surface water-quality computation chain.
- **GUI section index:** The GUI assigns index 26 to `[WASHOFF]` in its section array (`Uimport.pas:87`), making it case 26 in the reader dispatch (`Uimport.pas:2910`).
