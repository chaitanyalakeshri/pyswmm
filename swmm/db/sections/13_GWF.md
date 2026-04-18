# [GWF]

**Purpose:** Defines custom mathematical expressions for computing groundwater flow rates for individual subcatchments. Two expression types are supported: LATERAL (flow from the saturated lower groundwater zone to a conveyance-network node) and DEEP (vertical seepage loss from the lower zone to a deeper aquifer). A LATERAL expression is evaluated and its result **added** to the standard parametric equation; a DEEP expression **replaces** the default linear-loss formula. Subcatchments without entries in this section use only the standard equations from their [GROUNDWATER] parameters and parent [AQUIFERS] data.

**Occurrence:** Multiple rows per object — zero, one, or two rows per subcatchment (one for each expression type). Most subcatchments have no rows here at all. A subcatchment may have a LATERAL row, a DEEP row, both, or neither.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/input.c:514` — dispatches to `gwater_readFlowExpression`; `swmm524_engine/src/gwater.c:258` — function `gwater_readFlowExpression`
- Engine writer: engine does not write INP files; no report-echo function for this section
- GUI reader: `Uimport.pas:760` — procedure `ReadGroundwaterFlowEqn`; section keyword registered at `Uimport.pas:113`
- GUI writer: `Uexport.pas:736` — inside procedure `ExportGroundwater` (lines 733–761 write the `[GWF]` block)
- GUI editor dialog(s): `Dgweqn.pas` / `Dgweqn.dfm` — `TGWEqnForm` ("Custom Groundwater Flow Equation Editor"), invoked from `Dgwater.pas` (`TGroundWaterForm`, lines 225–252)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [GWF] (line 1017)
- Additional manual refs: `appendix_C_specialized_property_editors/C.7_Groundwater_Equation_Editor.md`; `appendix_C_specialized_property_editors/C.6_Groundwater_Flow_Editor.md`; `chapter_03_swmms_conceptual_model/3.4_Computational_Methods.md` (groundwater interflow theory)

## Row Format

```
Subcat   LATERAL/DEEP   Expr
```

Each row contains exactly three logical tokens: the subcatchment name, the flow type keyword, and a mathematical expression. The expression is everything from the third token to the end of the line; it may contain spaces and arithmetic operators. The GUI emits rows as tab-separated columns, left-justified with fixed widths:

```
;;Subcatchment    <TAB>  Flow     <TAB>  Equation
Sub1              <TAB>  LATERAL  <TAB>  0.001*Hgw + 0.05*(Hgw-5)*STEP(Hgw-5)
Sub1              <TAB>  DEEP     <TAB>  0.002
```

Source: `Uexport.pas:737–756`; `D.2_Input_File_Format.md:1025`

## Fields

### Subcat

- **Data type:** NAME_REF
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Must match an existing subcatchment name from [SUBCATCHMENTS]. Case-insensitive match via `project_findObject(SUBCATCH, tok[0])`.
- **Default:** none
- **Cross-section dependency:** `[SUBCATCHMENTS].Name`; the referenced subcatchment must also have a [GROUNDWATER] row with an associated [AQUIFERS] entry for the expressions to be evaluated at runtime.
- **Database-key hint:** foreign key to [SUBCATCHMENTS].Name; combined with FlowType forms the composite PK of this section
- **Technical description:** Identifies which subcatchment the custom flow expression belongs to. The engine stores the parsed expression tree on the subcatchment object: `Subcatch[j].gwLatFlowExpr` for LATERAL and `Subcatch[j].gwDeepFlowExpr` for DEEP (`objects.h:394–395`). A subcatchment may have at most one LATERAL and one DEEP expression; a second occurrence of the same Subcat+FlowType combination silently overwrites the earlier one (`gwater.c:298–299`).
- **Source of truth:** `gwater.c:280–281` — `project_findObject` call with error on not-found

---

### FlowType

- **Data type:** ENUM
- **Required:** yes
- **Units:** n/a
- **Valid values / range:**
  - `LATERAL` — custom lateral groundwater flow to a drainage-network node; result is **added** to the standard parametric flow computed from the [GROUNDWATER] A1/B1/A2/B2/A3 coefficients
  - `DEEP` — custom deep percolation (seepage to a lower aquifer); result **replaces** the default formula `LGLR × (Hgw / Hgs)` where LGLR is the aquifer's lower groundwater loss rate
  - Prefix matching is used: `match(tok[1], "LAT")` accepts any token starting with "LAT"; `match(tok[1], "DEEP")` requires prefix "DEEP"
- **Default:** none (required)
- **Cross-section dependency:** None
- **Database-key hint:** composite PK with Subcat
- **Technical description:** Selects whether the expression replaces the DEEP seepage formula or supplements the LATERAL flow formula. At runtime, if `LatFlowExpr != NULL`, the engine adds `mathexpr_eval(LatFlowExpr, getVariableValue) / UCF(GWFLOW)` to the parametric GW flow (`gwater.c:667–669`). If `DeepFlowExpr != NULL`, the deep loss is computed entirely from `mathexpr_eval(DeepFlowExpr, getVariableValue) / UCF(RAINFALL)` instead of the aquifer-based default (`gwater.c:658–662`). The distinction in unit-conversion factor (`UCF(GWFLOW)` vs. `UCF(RAINFALL)`) reflects the different units of the two expression types (see Expr field below).
- **Source of truth:** `gwater.c:284–287`

---

### Expr

- **Data type:** TEXT (parsed math expression string)
- **Required:** yes (at least a numeric constant)
- **Units:** 
  - LATERAL expressions: cfs/acre (US customary) or cms/ha (SI). The engine divides by `UCF(GWFLOW)` = 43560.0 (US) or 3048.0 (SI) to convert to ft/sec internally (`gwater.c:669`; `swmm5.c:116`).
  - DEEP expressions: in/hr (US customary) or mm/hr (SI). The engine divides by `UCF(RAINFALL)` to convert to ft/sec internally (`gwater.c:659`).
- **Valid values / range:** Any well-formed mathematical expression composed of the allowed variables, numeric literals, operators, and built-in functions listed below. The expression string occupies the remainder of the input line after the FlowType token; whitespace inside the expression is permitted (`gwater.c:289–295`).

  **Allowed domain variables (case-insensitive):**

  | Symbol | Description | Units in expression |
  |--------|-------------|---------------------|
  | `Hgw`   | Height of the water table (lower zone depth) above aquifer bottom | ft (US) or m (SI) |
  | `Hsw`   | Height of surface water at receiving node above aquifer bottom | ft (US) or m (SI) |
  | `Hcb`   | Height of channel bottom (node invert, or overridden value) above aquifer bottom | ft (US) or m (SI) |
  | `Hgs`   | Height of ground surface above aquifer bottom (= total aquifer depth) | ft (US) or m (SI) |
  | `Ks`    | Saturated hydraulic conductivity of the aquifer soil | in/hr (US) or mm/hr (SI) |
  | `K`     | Unsaturated hydraulic conductivity at current moisture content | in/hr (US) or mm/hr (SI) |
  | `Theta` | Moisture content of the upper unsaturated zone | dimensionless fraction |
  | `Phi`   | Soil porosity of the aquifer | dimensionless fraction |
  | `Fi`    | Current surface infiltration rate | in/hr (US) or mm/hr (SI) |
  | `Fu`    | Percolation rate from upper unsaturated zone to lower saturated zone | in/hr (US) or mm/hr (SI) |
  | `A`     | Subcatchment area | acres (US) or hectares (SI) |

  Source: `gwater.c:41–57` (enum `GWvariables` and `GWVarWords[]` string table); `gwater.c:850–872` (`getVariableValue` switch); `Dgweqn.pas:67–81` (GUI help text).

  **Allowed arithmetic operators:** `+`, `-`, `*`, `/`, `^` (exponentiation). Standard operator precedence and any level of nested parentheses. Source: `mathexpr.c:14–43`.

  **Allowed built-in math functions** (from `mathexpr.c:81–84`):

  | Function | Description |
  |----------|-------------|
  | `abs(x)` | Absolute value |
  | `sgn(x)` | Sign: +1 if x ≥ 0, −1 otherwise |
  | `step(x)` | Heaviside step: 0 if x ≤ 0, 1 if x > 0 — useful for threshold-conditional flow |
  | `sqrt(x)` | Square root |
  | `log(x)` | Natural logarithm (base e) |
  | `log10(x)` | Base-10 logarithm |
  | `exp(x)` | Exponential e^x |
  | `sin(x)`, `cos(x)`, `tan(x)`, `cot(x)` | Trigonometric functions |
  | `asin(x)`, `acos(x)`, `atan(x)`, `acot(x)` | Inverse trigonometric functions |
  | `sinh(x)`, `cosh(x)`, `tanh(x)`, `coth(x)` | Hyperbolic functions |

  Source: `mathexpr.c:81–84`; `D.2_Input_File_Format.md:1049` (cross-reference to [TREATMENT] section); `appendix_C_specialized_property_editors/C.7_Groundwater_Equation_Editor.md`.

- **Default:** none (field is required if the row exists; GUI stores empty string as "no equation" which suppresses the row entirely)
- **Cross-section dependency:** None (self-contained expression); the variable values at evaluation time are derived from the subcatchment's linked [AQUIFERS] properties and the associated drainage-network node's current state
- **Database-key hint:** plain data — no key role
- **Technical description:** The expression string is parsed once at load time by `mathexpr_create(exprStr, getVariableIndex)` into a binary expression tree (`gwater.c:304`). At each runoff time step the engine calls `mathexpr_eval` with `getVariableValue` as the value-lookup callback (`gwater.c:659`, `669`). If parsing fails, error `ERR_MATH_EXPR` is returned (`gwater.c:305`). The expression is stored on `TSubcatch.gwLatFlowExpr` or `TSubcatch.gwDeepFlowExpr` (`objects.h:394–395`).

  For LATERAL flow: the evaluated result (in the user's flow units, cfs/acre or cms/ha) is added onto the parametric standard-equation result, allowing the standard equation to be retained or bypassed. To bypass completely, set A1 = A2 = A3 = 0 in [GROUNDWATER] (`C.7_Groundwater_Equation_Editor.md`; `Dgweqn.pas:60–64`).

  For DEEP flow: the evaluated result (in/hr or mm/hr) replaces the default formula entirely. Leaving the expression blank and having no DEEP row causes the engine to fall back to the aquifer's lower groundwater loss rate coefficient (`gwater.c:661–662`).

  The STEP function is particularly useful for creating threshold-controlled flow: `0.001 * (Hgw - 5) * STEP(Hgw - 5)` produces flow only when the water table exceeds 5 ft above the aquifer bottom (`D.2_Input_File_Format.md:1054`; `Dgweqn.pas:83–88`).

  GUI storage: the expression string is held in `TSubcatch.GwLatFlowEqn` or `TSubcatch.GwDeepFlowEqn` (`Uproject.pas:497–498`). An empty string suppresses the row during export (`Uexport.pas:747`, `753`).

- **Source of truth:** `gwater.c:258–311` (`gwater_readFlowExpression`); `mathexpr.c` (expression parser)

## Notes

- **Section alias / legacy name:** `text.h:454` defines `ws_GW_FLOW = "[GW_FLOW"` as **Deprecated**. The current canonical keyword is `[GWF]` (`text.h:455`). The deprecated `[GW_FLOW]` form is no longer present in the `keywords.c` dispatch table or in `input.c`'s switch statement; it exists in `text.h` only as a historical artifact.

- **Relationship to [GROUNDWATER]:** The [GWF] section is strictly supplementary to [GROUNDWATER]. A subcatchment must have a [GROUNDWATER] row (and thus a linked aquifer and receiving node) for its GWF expressions to be evaluated. Expressions are silently ignored if `GW == NULL` at runtime (`gwater.c:495`).

- **LATERAL additive behaviour:** The LATERAL custom equation result is *added to*, not substituted for, the result of the standard A1/B1/A2/B2/A3 parametric formula. Setting all five standard coefficients to 0 in [GROUNDWATER] is required if the intent is to replace the standard equation entirely (`C.7_Groundwater_Equation_Editor.md`; `Dgweqn.pas:60–64`).

- **DEEP replacement behaviour:** The DEEP custom equation always replaces the default formula; there is no additive mode for deep flow (`gwater.c:658–662`).

- **Uniqueness and overwriting:** Each subcatchment may have at most one LATERAL and one DEEP row. If the same subcatchment+type combination appears more than once, the engine deletes the earlier expression tree and stores the new one (`gwater.c:298–299`). The DB designer should enforce a unique constraint on (Subcat, FlowType).

- **Row optionality:** The entire [GWF] section and every row within it are optional. The GUI omits the section entirely if no subcatchment has any expression defined (`Uexport.pas:733`).

- **Expression length:** The expression string is assembled by concatenating all tokens from position 2 onwards up to `MAXLINE` characters (`gwater.c:290–295`). `MAXLINE` is defined in `headers.h` (typically 1024).

- **Variable name case:** Variable names in expressions are matched case-insensitively via `findmatch` / `sametext` in the math expression parser. The canonical forms as documented in `GWVarWords[]` are all-uppercase: `HGW`, `HSW`, `HCB`, `HGS`, `KS`, `K`, `THETA`, `PHI`, `FI`, `FU`, `A` (`gwater.c:56–57`). The GUI help text shows mixed-case versions (Hgw, Ks, etc.) which are also accepted.

- **Unit consistency:** Expression authors must ensure their constants are numerically consistent with the expected output units (cfs/acre or cms/ha for LATERAL; in/hr or mm/hr for DEEP) and with the height variables which are always in feet (US) or meters (SI) relative to the aquifer bottom, regardless of flow-units setting.

- **Flow sign convention:** Positive LATERAL flow means water leaves the aquifer and enters the drainage node; negative means the node feeds water back into the aquifer (bank storage). When A3 ≠ 0 in the standard equation, negative flow is forced to zero to preserve model consistency (`gwater.c:828`). No equivalent guard exists for the custom expression result; the combined flow is bounded by `MaxGWFlowPos` / `MaxGWFlowNeg` (`gwater.c:671–672`).
