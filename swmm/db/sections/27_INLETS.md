# [INLETS]

**Purpose:** Defines named inlet structure designs that describe the physical geometry and type of storm drain inlets used to capture overland flow from street conduits or open channels and divert it into below-ground sewer nodes. Each design record specifies one inlet type (GRATE, CURB, SLOTTED, DROP_GRATE, DROP_CURB, or CUSTOM) and the dimensional or curve parameters needed for FHWA HEC-22 capture-efficiency calculations. A single inlet name may appear on two consecutive rows (once with GRATE and once with CURB) to define a combination inlet.

**Occurrence:** One row per inlet design parameter set; a combination inlet uses two rows (GRATE + CURB) sharing the same Name. The section stores design templates only — actual placement into conduits is recorded in `[INLET_USAGE]`.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/inlet.c:313` — function `inlet_readDesignParams`; per-type sub-parsers at lines 814 (`readGrateInletParams`), 868 (`readCurbInletParams`), 911 (`readSlottedInletParams`), 939 (`readCustomInletParams`)
- Engine dispatch: `swmm524_engine/src/input.c:625` — `case s_INLET`
- Engine object count pass: `swmm524_engine/src/input.c:449` — `case s_INLET` (registers unique names before parsing)
- Engine writer: engine does not write INP; no echo function found in `inputrpt.c` for this section
- GUI reader: `Uinlet.pas:219` — function `ReadInletDesignData`; sub-readers at lines 150 (`ReadGrateInletData`), 175 (`ReadCurbInletData`), 194 (`ReadSlottedInletData`), 208 (`ReadCustomInletData`); called via `Uimport.pas:2940`
- GUI writer: `Uinlet.pas:319` — procedure `ExportInletDesigns`; called from `Uexport.pas:2361`
- GUI editor dialog: `Dinlet.pas` / `Dinlet.dfm` — `TInletEditorForm`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[INLETS]` (line 1721)
- Additional manual refs: `appendix_C_specialized_property_editors/C.11_Inlet_Structure_Editor.md`; `chapter_03_swmms_conceptual_model/3.3_Non-Visual_Objects.md` (section 3.3.7)

## Row Format

The exact column layout depends on the inlet type keyword in column 2. There are six distinct row formats:

```
;; GRATE or DROP_GRATE
Name  GRATE|DROP_GRATE  Length  Width  GrateType  (Aopen  Vsplash)

;; CURB or DROP_CURB
Name  CURB|DROP_CURB  Length  Height  (Throat)

;; SLOTTED
Name  SLOTTED  Length  Width

;; CUSTOM
Name  CUSTOM  CurveName
```

A combination inlet is produced by supplying both a GRATE row and a CURB row for the same `Name` (in either order). The engine automatically promotes the type to `COMBO_INLET` when it detects that both grate and curb sub-data have been loaded for one design.

Source: `appendix_D_command_line_swmm/D.2_Input_File_Format.md:1727–1733`; `inlet.c:322–328`

---

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-empty string that does not begin with `[`; must be unique within the project's INLET object list (duplicate names on separate lines are allowed only when building a combination inlet)
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** primary identifier of this row (or composite PK with InletType for combination inlets where two rows share one Name)
- **Technical description:** The logical name that uniquely identifies this inlet design in the project. It is referenced by the `[INLET_USAGE]` section to place this design into a specific conduit. During the first parsing pass the engine registers each new name exactly once; subsequent lines with the same name (combination inlet) update the existing design object rather than creating a new one (`input.c:449–457`). In the GUI the name must not begin with `[` (enforced at `Dinlet.pas:304`).
- **Source of truth:** `inlet.c:335–338`; `input.c:449–457`

---

### InletType

- **Data type:** ENUM
- **Required:** yes
- **Units:** unitless
- **Valid values / range:**
  - `GRATE` — on-grade or on-sag grated inlet, used with STREET conduits only
  - `CURB` — curb opening inlet, used with STREET conduits only; also second row for a combination inlet
  - `SLOTTED` — slotted drain inlet, used with STREET conduits only
  - `DROP_GRATE` — drop grate inlet for open RECT_OPEN or TRAPEZOIDAL channels
  - `DROP_CURB` — drop curb inlet for open RECT_OPEN or TRAPEZOIDAL channels
  - `CUSTOM` — user-defined capture curve, compatible with any conduit type
  - (Internal only: `COMBO_INLET` — automatically set when both GRATE and CURB data exist for one Name; not a valid INP keyword)
- **Default:** none
- **Cross-section dependency:** `[XSECTIONS]` shape: GRATE/CURB/SLOTTED require STREET; DROP_GRATE/DROP_CURB require RECT_OPEN or TRAPEZOIDAL; CUSTOM is unrestricted (validated in `inlet.c:483–505`)
- **Database-key hint:** composite PK with Name for combination inlets; plain data otherwise
- **Technical description:** Determines which sub-parser is invoked and which downstream HEC-22 equations are applied. The keyword strings are defined in `inlet.c:136` as `InletTypeWords[]` = `{"GRATE","CURB","","SLOTTED","DROP_GRATE","DROP_CURB","CUSTOM",NULL}`. The empty string at index 2 is the internal `COMBO_INLET` slot and is never written to INP. DROP_GRATE and DROP_CURB use the same parsing logic as their non-drop counterparts but the engine applies different hydraulic equations (no gutter spread, direct sump computation) and they are excluded from STREET conduits during validation (`inlet.c:495–504`).
- **Source of truth:** `inlet.c:135–136`, `341–358`

---

## Fields — GRATE and DROP_GRATE rows

### Length (grate)

- **Data type:** REAL
- **Required:** yes (for GRATE / DROP_GRATE rows)
- **Units:** US: ft / SI: m
- **Valid values / range:** `> 0`
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The grate's dimension measured parallel to the street curb (or channel flow direction). Stored internally in feet after division by the unit conversion factor `UCF(LENGTH)`. Used in HEC-22 on-grade capture efficiency formulas to determine how much of the flow spread is intercepted.
- **Source of truth:** `inlet.c:830–831`, `853`

### Width (grate)

- **Data type:** REAL
- **Required:** yes (for GRATE / DROP_GRATE rows)
- **Units:** US: ft / SI: m
- **Valid values / range:** `> 0`
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The grate's dimension measured perpendicular to flow (the grate width extending from the curb face into the gutter). Together with `Length` it establishes the gross grate area. The effective open area is derived from `GrateType` (predetermined fraction) or from the explicit `Aopen` field for GENERIC grates.
- **Source of truth:** `inlet.c:832–833`, `854`

### GrateType

- **Data type:** ENUM
- **Required:** yes (for GRATE / DROP_GRATE rows)
- **Units:** unitless
- **Valid values / range:**
  - `P_BAR-50` — parallel bar grate, 1⅞" on-center bar spacing; open area ratio 0.90; splash coefficients from HEC-22 Chart 5B
  - `P_BAR-50x100` — parallel bar grate with 1⅞" bars and lateral rods at 4" on-center; open ratio 0.80
  - `P_BAR-30` — parallel bar grate, 1⅛" on-center; open ratio 0.60
  - `CURVED_VANE` — curved vane grate; open ratio 0.35
  - `TILT_BAR-45` — 45° tilt bar grate; open ratio 0.17
  - `TILT_BAR-30` — 30° tilt bar grate; open ratio 0.34
  - `RETICULINE` — honeycomb pattern; open ratio 0.80
  - `GENERIC` — user-specified open ratio and splash velocity (see `Aopen` and `Vsplash` fields)
- **Default:** `P_BAR-50` (GUI default at `Uinlet.pas:65`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Selects the standard HEC-22 grate geometry. For all non-GENERIC types the engine looks up predetermined open area ratios (`GrateOpeningRatios[]` at `inlet.c:161–169`) and splash-over velocity polynomial coefficients (`SplashCoeffs[]` at `inlet.c:151–158`) from HEC-22 Chart 5B. For `GENERIC` the user must supply `Aopen` and (optionally) `Vsplash`. The keyword strings are defined in `inlet.c:138–140` as `GrateTypeWords[]`.
- **Source of truth:** `inlet.c:836–837`, `839–849`; `Uinlet.pas:70–73`

### Aopen

- **Data type:** REAL
- **Required:** yes when GrateType = `GENERIC`; ignored otherwise
- **Units:** unitless (fraction)
- **Valid values / range:** `> 0` and `≤ 1.0`
- **Default:** 0.8 (GUI default at `Uinlet.pas:65`; field is absent from INP for non-GENERIC grates)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The fraction of the grate's gross area that is physically open to water. Used in the on-sag orifice flow calculation for the grate inlet. For the seven standard grate types the engine substitutes the corresponding entry from `GrateOpeningRatios[]` and this column must not be supplied in INP.
- **Source of truth:** `inlet.c:840–844`, `856`

### Vsplash

- **Data type:** REAL
- **Required:** no; applicable only when GrateType = `GENERIC`
- **Units:** US: ft/s / SI: m/s
- **Valid values / range:** `≥ 0`
- **Default:** 0 (GUI default at `Uinlet.pas:65`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** The minimum approach-flow velocity at which water begins to shoot over the grate (splash-over), reducing capture efficiency. When 0 the engine treats all approach flow as potentially capturable regardless of velocity. For standard grate types this value is computed internally from the cubic-polynomial coefficients in `SplashCoeffs[]` (`inlet.c:151–158`) as a function of grate length; the INP field is absent for those types.
- **Source of truth:** `inlet.c:845–849`, `857`; `appendix_D_command_line_swmm/D.2_Input_File_Format.md:1747`

---

## Fields — CURB and DROP_CURB rows

### Length (curb)

- **Data type:** REAL
- **Required:** yes (for CURB / DROP_CURB rows)
- **Units:** US: ft / SI: m
- **Valid values / range:** `> 0`
- **Default:** 2 ft (GUI default at `Uinlet.pas:66`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Length of the curb opening measured parallel to the flow direction. In a combination inlet only the curb opening portion that extends beyond the grate length contributes to total capture efficiency. Stored internally in feet.
- **Source of truth:** `inlet.c:884–885`, `898`

### Height

- **Data type:** REAL
- **Required:** yes (for CURB / DROP_CURB rows)
- **Units:** US: ft / SI: m
- **Valid values / range:** `> 0`
- **Default:** 0.5 ft (GUI default at `Uinlet.pas:66`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Height of the curb opening. Used in on-sag orifice flow calculations. The effective orifice area is `Length × Height` reduced by any clogging factor. Must be ≤ the curb height of the associated STREET cross-section for physically consistent results.
- **Source of truth:** `inlet.c:886–887`, `899`

### Throat

- **Data type:** ENUM
- **Required:** no (CURB only; not used for DROP_CURB)
- **Units:** unitless
- **Valid values / range:**
  - `HORIZONTAL` — throat opening faces horizontally (flush with pavement surface)
  - `INCLINED` — throat opening is at an angle
  - `VERTICAL` — throat opening faces vertically (default)
- **Default:** `VERTICAL` (engine: `inlet.c:890`; GUI: `Uinlet.pas:67`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Controls the discharge coefficient used in on-sag orifice flow calculations via `getCurbOrificeFlow` in `inlet.c`. `VERTICAL` is the most common configuration and produces the lowest discharge for a given opening. For DROP_CURB the throat angle is always assumed VERTICAL and the field is silently ignored if supplied (`inlet.c:891`). The keyword strings are defined in `inlet.c:142–143` as `ThroatAngleWords[]`.
- **Source of truth:** `inlet.c:889–895`, `900`; `appendix_D_command_line_swmm/D.2_Input_File_Format.md:1749–1751`

---

## Fields — SLOTTED rows

### Length (slotted)

- **Data type:** REAL
- **Required:** yes (for SLOTTED rows)
- **Units:** US: ft / SI: m
- **Valid values / range:** `> 0`
- **Default:** 4 ft (GUI default at `Uinlet.pas:68`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Length of the slotted drain parallel to the curb. Slotted drain inlets are modelled as a series of very narrow slots; longer slots capture proportionally more flow on-grade.
- **Source of truth:** `inlet.c:926–927`, `932`

### Width (slotted)

- **Data type:** REAL
- **Required:** yes (for SLOTTED rows)
- **Units:** US: ft / SI: m
- **Valid values / range:** `> 0`
- **Default:** 0.5 ft (GUI default at `Uinlet.pas:68`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Width of the slot opening. Used in on-sag orifice calculations for the slotted drain. In practice slotted drain widths are small (a few inches).
- **Source of truth:** `inlet.c:928–929`, `933`

---

## Fields — CUSTOM rows

### CurveName

- **Data type:** NAME_REF
- **Required:** yes (for CUSTOM rows)
- **Units:** n/a
- **Valid values / range:** Name of an existing curve in `[CURVES]` whose `CurveType` is either `DIVERSION` (on-grade use: captured flow vs. approach flow) or `RATING` (on-sag use: captured flow vs. water depth)
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** foreign key to `[CURVES].Name` where curve type ∈ {DIVERSION_CURVE, RATING_CURVE}
- **Technical description:** The single parameter for a custom inlet. The engine looks up this curve name at parse time (`inlet.c:953–955`) and stores the curve index. During simulation, `getCustomCapturedFlow` (`inlet.c:593–596`) uses the curve to compute captured flow as a function of either approach flow (Diversion curve) or node water depth (Rating curve). The GUI stores the curve name in two distinct slots — `CUSTOM_INLET_DIVRSN_CURVE` (index 10) and `CUSTOM_INLET_RATING_CURVE` (index 11) — and writes whichever is non-empty (`Uinlet.pas:387–390`). Only one is used at a time. The manual notes: "Diversion curves are best suited for on-grade inlets and Rating curves for on-sag inlets" (`appendix_D_command_line_swmm/D.2_Input_File_Format.md:1825–1827`).
- **Source of truth:** `inlet.c:948–957`; `Uinlet.pas:208–215`, `387–391`

---

## Notes

- **Combination inlets** are defined by supplying two rows for the same Name — one with keyword `GRATE` and one with keyword `CURB` (in either order). The engine detects the combination when both grate and curb sub-data are present on the same design object and sets `type = COMBO_INLET` (`inlet.c:859–862`, `902–905`). In the GUI the combo type is shown as "COMBINATION" in the type dropdown but is never written as such to INP. Only the portion of the curb opening that extends beyond the grate length contributes to capture in a combination inlet (`appendix_C_specialized_property_editors/C.11_Inlet_Structure_Editor.md`).

- **Conduit-type compatibility constraints** are enforced during validation (`inlet.c:483–505`). Placing an incompatible inlet type on a conduit causes a warning (WARN12) and silently removes the inlet from that conduit. GRATE, CURB, SLOTTED (and COMBO) require STREET cross-sections; DROP_GRATE and DROP_CURB require RECT_OPEN or TRAPEZOIDAL; CUSTOM is accepted by any conduit. These same rules are applied in the GUI to filter the dropdown list of available designs when editing `[INLET_USAGE]` (`Uinlet.pas:544–558`).

- **Object registration pass**: before full parsing, `input.c:449–457` walks through all lines and registers each unique inlet Name as a project INLET object. This means the same name on a second line (combination inlet) increments neither the object count nor raises a duplicate-name error.

- **GENERIC grate sub-fields are mandatory**: if `GrateType` = `GENERIC` but `Aopen` is absent, the engine returns `ERR_ITEMS` (`inlet.c:842`). For all other grate types, supplying `Aopen` or `Vsplash` columns causes them to be ignored (no error raised).

- **DROP_CURB drops the Throat field silently**: the engine only reads `Throat` when `InletDesigns[i].type == CURB_INLET` (`inlet.c:891`); a THROAT token on a DROP_CURB line is parsed but discarded, and a blank is acceptable.

- **Units conversion**: all dimensional fields (Length, Width, Height, Vsplash) are divided by `UCF(LENGTH)` or `UCF(LENGTH)` at read time to convert from project units to internal US customary units (feet, ft/s). The stored values are therefore always in feet regardless of whether the project uses US or SI units.

- **CUSTOM curve validation at runtime**: although the curve name must exist in `[CURVES]` at parse time (`inlet.c:953–955`), the curve type check (DIVERSION vs. RATING) is performed at `inlet.c:490–495` during `inlet_validate()` after all sections are parsed. An invalid curve type results in the inlet being silently removed with WARN12.

- **Section keyword prefix matching**: the section header `[INLET` is matched by the engine's prefix-based section scanner (text.h:459 defines `ws_INLET "[INLET"`). Because `[INLET_USAGE` is also defined (`text.h:460`), order in `keywords.c:145` matters — `ws_INLET_USAGE` is listed before `ws_INLET` to prevent the shorter prefix from matching inlet-usage lines.

- **No ordering requirement** within the section; however, a combination inlet's two rows must both appear before the inlet is used in `[INLET_USAGE]` to ensure both sub-structs are populated before validation.

- **The section does not appear in `inputrpt.c`** — the engine produces no echo of this section to the report file. Summary results for inlets appear instead in the Street Flow Summary table produced by `inlet_writeStatsReport` (`inlet.c:204`, `inlet.h:28`).
