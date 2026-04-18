# [STORAGE]

**Purpose:** Defines each storage node in the drainage network. Storage nodes represent detention basins, retention ponds, catch basins, cisterns, or any other facility whose primary function is to hold water volume. Their hydraulic behaviour is governed entirely by a surface-area-versus-depth relationship, which may be expressed analytically (FUNCTIONAL or one of four geometric shapes) or tabularly (a named STORAGE curve). Storage nodes participate in all flow-routing regimes, may lose water through evaporation and seepage (Green-Ampt exfiltration), and can be covered (pressurised surcharge) or open.

**Occurrence:** One row per storage node. Each row defines one unique named node. A node that appears in `[STORAGE]` must not appear in `[JUNCTIONS]`, `[OUTFALLS]`, or `[DIVIDERS]`. The same name must not appear twice in this section.

**SWMM source references:**
- Engine parser: `swmm524_engine/src/node.c:654` — function `storage_readParams`; dispatched via `node.c:117` `node_readParams` → `input.c:527` `readNode(STORAGE)`
- Engine writer: engine does not write INP; the input-report echo (`inputrpt.c`) does not echo the `[STORAGE]` section individually — nodes appear only in the generic Node Summary table (`inputrpt.c:158–177`).
- GUI reader: `Uimport.pas:935` — procedure `ReadStorageData`
- GUI writer: `Uexport.pas:955` — procedure `ExportStorage`
- GUI editor dialog: `Dstorage.pas` — `TStorageForm` (Storage Shape Editor); invoked from the Storage Shape property of the node property grid (`appendix_C/C.20_Storage_Shape_Editor.md`)
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section `[STORAGE]` (lines 1223–1322)
- Additional manual refs: `appendix_B/B.6_Storage_Unit_Properties.md`; `appendix_C/C.20_Storage_Shape_Editor.md`; `chapter_03/3.2_Visual_Objects.md` §3.2.6

## Row Format

Three mutually exclusive line formats depending on the geometry type:

```
;; TABULAR geometry:
Name  Elev  Ymax  Y0  TABULAR   Acurve  (Ysur  Fevap  Psi  Ksat  IMD)

;; FUNCTIONAL geometry:
Name  Elev  Ymax  Y0  FUNCTIONAL  A1  A2  A0  (Ysur  Fevap  Psi  Ksat  IMD)

;; Analytical shape (CYLINDRICAL / CONICAL / PARABOLIC / PYRAMIDAL):
Name  Elev  Ymax  Y0  Shape  L  W  Z  (Ysur  Fevap  Psi  Ksat  IMD)
```

Columns in parentheses are optional trailing fields. The minimum token count is 6 for TABULAR and 8 for all others (`node.c:676`, `node.c:710`). The GUI comment header emitted by `ExportStorage` reads:

```
;;Name           Elev.    MaxDepth   InitDepth  Shape      Curve Type/Params            SurDepth  Fevap    Psi      Ksat     IMD
```

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-empty string; must be unique across all node sections (`[JUNCTIONS]`, `[OUTFALLS]`, `[DIVIDERS]`, `[STORAGE]`). Duplicate names generate `ERR_DUP_NAME` (`input.c:315`).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** primary identifier of this row; foreign key target for links (`[CONDUITS]`, `[PUMPS]`, `[ORIFICES]`, `[WEIRS]`, `[OUTLETS]`) referencing this node as `Node1`/`Node2`; also referenced by `[INFLOWS]`, `[DWF]`, `[RDII]`, `[TREATMENT]`, `[COORDINATES]`.
- **Technical description:** User-assigned label for the storage node. Looked up via `project_findID(NODE, tok[0])` (`node.c:677`). The engine shares a single flat NODE namespace across all node types.
- **Source of truth:** `node.c:676–678`

---

### Elev

- **Data type:** REAL
- **Required:** yes
- **Units:** ft (US) / m (SI)
- **Valid values / range:** any real (typically ≥ 0 for above-datum elevations, but negative values are valid for below-datum systems)
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Invert (bottom) elevation of the storage unit. Stored internally in feet after dividing by `UCF(LENGTH)` (`node.c:137`). Governs the hydraulic head calculations for all inflows and outflows.
- **Source of truth:** `node.c:681–685`; stored as `Node[j].invertElev` at `node.c:137`

---

### Ymax

- **Data type:** REAL
- **Required:** yes
- **Units:** ft (US) / m (SI)
- **Valid values / range:** `> 0`; the engine validates that the computed volume at full depth is non-negative: `node_validate` calls `node_getVolume(j, fullDepth)` and emits `ERR_STORAGE_VOLUME` if negative (`node.c:220–222`).
- **Default:** none (GUI default `5` per `objprops.txt:415`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Water depth at which the unit is considered full (i.e., maximum design depth above the invert). Stored as `Node[j].fullDepth` (`node.c:172`). If surcharge depth `Ysur > 0` the unit can hold additional depth under pressurised conditions.
- **Source of truth:** `node.c:681–685`, `node.c:172`

---

### Y0

- **Data type:** REAL
- **Required:** yes
- **Units:** ft (US) / m (SI)
- **Valid values / range:** `≥ 0`; must satisfy `Y0 ≤ Ymax + Ysur` at validation time (`node.c:216–217`).
- **Default:** none (GUI default `0` per `objprops.txt:416`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Initial water depth in the storage unit at the start of the simulation. Stored as `Node[j].initDepth` (`node.c:173`).
- **Source of truth:** `node.c:681–685`, `node.c:173`

---

### Shape (geometry type keyword)

- **Data type:** ENUM
- **Required:** yes
- **Units:** n/a (unitless keyword)
- **Valid values / range:**
  - `TABULAR` — surface area read from a named curve in `[CURVES]`
  - `FUNCTIONAL` — surface area computed by the power function A = A0 + A1·D^A2
  - `CYLINDRICAL` — elliptical cylinder with vertical sides
  - `CONICAL` — truncated elliptical cone
  - `PARABOLIC` — elliptical paraboloid (keyword is `PARABOLIC` in both `text.h:194` and `text.h:228`, not `PARABOLOID`; enum constant is `PARABOLOID` in `enums.h:401`)
  - `PYRAMIDAL` — truncated rectangular pyramid or box
  The full list is defined in `keywords.c:108–110` as `RelationWords[]`.
- **Default:** none (GUI default `FUNCTIONAL` per `objprops.txt:420`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Selects the geometric model. Matched via `findmatch(tok[4], RelationWords)` (`node.c:688`). For TABULAR, the next token is `Acurve`; for all others, the next three tokens are `L`, `W`, `Z` (or `A1`, `A2`, `A0` for FUNCTIONAL). The keyword `PARABOLIC` is the canonical INP string for the paraboloid shape — the manual (D.2 line 1255) uses `PARABOLOID` in the parameter description but the actual keyword accepted by the parser is `PARABOLIC` (see `text.h:194`: `#define w_PARABOLOID "PARABOLIC"`). The GUI also writes `'PARABOLIC'` (`Dstorage.pas:270`).
- **Source of truth:** `node.c:688–690`; keyword table `keywords.c:108–110`; `text.h:186–195`; `enums.h:396–402`

---

### Acurve

- **Data type:** NAME_REF
- **Required:** yes (only when Shape = `TABULAR`)
- **Units:** n/a
- **Valid values / range:** Must resolve to an existing curve name in `[CURVES]` with curve type `STORAGE` (x = depth in ft or m, y = surface area in ft² or m²). The engine calls `project_findObject(CURVE, tok[5])` and returns `ERR_NAME` if not found (`node.c:701–703`).
- **Default:** none (GUI default empty string per `objprops.txt:424`)
- **Cross-section dependency:** `[CURVES].Name` where curve type = `STORAGE`
- **Database-key hint:** foreign key to `[CURVES].Name`
- **Technical description:** Name of the depth–area lookup table. The first curve point should give the surface area at depth 0 (the base area); if omitted the engine assumes zero area at depth 0. The curve is extrapolated linearly beyond the last point to reach `Ymax` if necessary. Stored internally as `Storage[k].aCurve` (curve index) (`node.c:178`). This column occupies token position 5 when Shape = `TABULAR`; the column is absent for all other shape types.
- **Source of truth:** `node.c:699–704`; `node.c:178`

---

### A1

- **Data type:** REAL
- **Required:** yes (when Shape ≠ `TABULAR`)
- **Units:** For FUNCTIONAL: ft²/ft^A2 (US) or m²/m^A2 (SI) — the coefficient in the power law. For geometric shapes, this is the dimension `L` (see below).
- **Valid values / range:**
  - FUNCTIONAL: any real ≥ 0 (the engine does not range-check A1 explicitly)
  - CYLINDRICAL / CONICAL / PARABOLIC / PYRAMIDAL: `> 0` (engine enforces `y[0] > 0` at `node.c:732`)
- **Default:** none (GUI default `0` for FUNCTIONAL per `objprops.txt:422`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** In FUNCTIONAL mode (`tok[5]`): the multiplier coefficient of the depth term in `A = A0 + A1·D^A2`. In geometric modes, this is dimension `L` (token position 5):
  - CYLINDRICAL: major axis length (full diameter along long axis) in ft or m
  - CONICAL: base major axis length in ft or m
  - PARABOLIC: major axis length at full height H in ft or m
  - PYRAMIDAL: base length in ft or m
  Internally the engine converts all geometric shapes to equivalent `a1/a2/a0` power-law coefficients (see `node.c:750–783`). The GUI stores this in `STORAGE_COEFF1_INDEX` (index 15, `Uproject.pas:200`) and writes it as column 3 of the geometry params (`Uexport.pas:993`).
- **Source of truth:** `node.c:707–716` (parsing); `node.c:750–783` (conversion); `node.c:175`

---

### A2

- **Data type:** REAL
- **Required:** yes (when Shape ≠ `TABULAR`)
- **Units:** For FUNCTIONAL: dimensionless exponent. For geometric shapes, this is dimension `W`.
- **Valid values / range:**
  - FUNCTIONAL: any real; a value of 0 gives constant area (vertical walls); typical values 0–2
  - CYLINDRICAL / CONICAL / PARABOLIC / PYRAMIDAL: `> 0` (engine enforces `y[1] > 0` at `node.c:733`)
- **Default:** none (GUI default `0` per `objprops.txt:423`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** In FUNCTIONAL mode (`tok[6]`): the exponent applied to depth in the power law expression. In geometric modes, this is dimension `W` (token position 6):
  - CYLINDRICAL: minor axis width (full diameter along short axis) in ft or m
  - CONICAL: base minor axis width in ft or m
  - PARABOLIC: minor axis width at full height H in ft or m
  - PYRAMIDAL: base width in ft or m
  The GUI stores this in `STORAGE_COEFF2_INDEX` (index 16, `Uproject.pas:201`) and writes it as column 4 of the geometry params (`Uexport.pas:994`).
- **Source of truth:** `node.c:707–716`; `node.c:750–783`; `node.c:176`

---

### A0

- **Data type:** REAL
- **Required:** yes (when Shape ≠ `TABULAR`)
- **Units:** For FUNCTIONAL: ft² (US) / m² (SI) — a constant surface area added at all depths. For geometric shapes (except CYLINDRICAL), this is dimension `Z` (side slope or height).
- **Valid values / range:**
  - FUNCTIONAL: `≥ 0` (engine enforces `y[2] ≥ 0` at `node.c:724`)
  - CYLINDRICAL: not used; engine forces `x[6] = 0.0` and `STORAGE_COEFF0_INDEX` to `'0'` in the GUI (`Dstorage.pas:275`)
  - CONICAL: Z = side slope (run/rise) in the plane of the major axis; `≥ 0` (engine enforces `y[2] ≥ 0` at `node.c:734`)
  - PARABOLIC: Z = full height H in ft or m; must be `> 0` (engine enforces `y[2] ≠ 0` at `node.c:738`)
  - PYRAMIDAL: Z = side wall slope (run/rise); `≥ 0` (engine enforces `y[2] ≥ 0` at `node.c:734`; Z = 0 gives a box)
- **Default:** none (GUI default `1000` for FUNCTIONAL per `objprops.txt:421`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** In FUNCTIONAL mode (`tok[7]`): the constant base area term, giving the surface area at zero depth. In geometric modes, this is the third shape parameter Z (token position 7):
  - CONICAL: side slope (run/rise along the major-axis cross-section)
  - PARABOLIC: full height of the paraboloid (height at which L and W are measured)
  - PYRAMIDAL: side wall slope (run/rise); set to 0 for a rectangular box
  The GUI stores this in `STORAGE_COEFF0_INDEX` (index 14, `Uproject.pas:199`) and writes it as column 5 of the geometry params (`Uexport.pas:995`). Note: the GUI column ordering for geometric shapes is L→W→Z mapped to COEFF1→COEFF2→COEFF0, which is an internal indexing convention that does not affect the INP file column order (`Dstorage.pas:261–276`, `Uexport.pas:993–995`).
- **Source of truth:** `node.c:707–716`; `node.c:720–739`; `node.c:750–783`; `node.c:177`

---

### Ysur

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** ft (US) / m (SI)
- **Valid values / range:** `≥ 0`
- **Default:** `0` — no surcharge capacity; node overflows when depth reaches `Ymax`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Maximum additional water depth above `Ymax` that a *covered* (closed) storage unit can sustain under surcharge (pressurised) conditions before losing water. When `Ysur = 0` the unit is treated as open (excess water overflows freely). When `Ysur > 0` the unit acts as a pressurised vessel up to depth `Ymax + Ysur`. Stored as `Node[j].surDepth` (`node.c:179`). The engine parses this as the first optional token after the shape parameters (`node.c:786–792`), tracking the advancing token index `n`.
- **Source of truth:** `node.c:786–792`; `node.c:179`; manual D.2:1257

---

### Fevap

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** unitless (fraction, 0–1)
- **Valid values / range:** `0` to `1.0`
- **Default:** `0` — no evaporation losses
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Fraction of the potential evaporation rate (from `[EVAPORATION]`) that is actually realised from the water surface of this storage unit. A value of 1.0 means the full potential evaporation is applied. Stored as `Storage[k].fEvap` (`node.c:180`; `objects.h:551`). Used at runtime in `storage_getLosses` (`node.c:1072`). The GUI default is `0` (`objprops.txt:418`).
- **Source of truth:** `node.c:794–800`; `node.c:180`; `objects.h:551`

---

### Psi

- **Data type:** REAL
- **Required:** no (default: `0`; omit to disable seepage)
- **Units:** inches (US) / mm (SI)
- **Valid values / range:** `≥ 0`
- **Default:** `0` (omitted — no seepage unless Ksat is provided)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Green-Ampt capillary suction head for the soil surrounding the storage unit. This is the same parameter as `Psi` in the `[INFILTRATION]` section when using the Green-Ampt method. Only relevant when `Ksat > 0`. If `Psi = 0` and `IMD = 0` alongside a non-zero `Ksat`, seepage proceeds at a constant rate equal to `Ksat` (no matric suction). Parsed in `exfil.c:61` as `x[0]`.
- **Source of truth:** `exfil.c:34–70`; manual D.2:1265–1322

---

### Ksat

- **Data type:** REAL
- **Required:** no (default: `0`; omit to disable seepage entirely)
- **Units:** in/hr (US) / mm/hr (SI)
- **Valid values / range:** `≥ 0`; if `Ksat = 0` no exfiltration object is created and seepage is disabled (`exfil.c:65–66`)
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Saturated hydraulic conductivity of the soil at the bottom and sloped sides of the storage unit. This is the primary switch for enabling seepage: when `Ksat > 0` the engine constructs a Green-Ampt exfiltration object and calculates seepage losses each time step. It can appear as the *only* seepage token (a single extra column after `Fevap`), in which case `Psi = 0` and `IMD = 0` are assumed, yielding constant-rate seepage. This shortcut is explicit in `exfil.c:48–54`. The GUI marks `STORAGE_SEEPAGE_INDEX` as `'YES'` if `Ksat > 0`, otherwise `'NO'` (`Uimport.pas:998–1000`).
- **Source of truth:** `exfil.c:34–70`; `node.c:806–807`; `Uimport.pas:988`

---

### IMD

- **Data type:** REAL
- **Required:** no (default: `0`; must accompany `Psi` and `Ksat` as the third seepage token)
- **Units:** unitless (fraction, 0–1 representing porosity minus current moisture content)
- **Valid values / range:** `0` to `1.0`
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Initial moisture deficit (IMD = porosity − current volumetric moisture content) of the surrounding soil. When `IMD = 0` the soil is pre-saturated and seepage proceeds at the constant rate `Ksat`. When `IMD > 0` the Green-Ampt equation computes a time-varying seepage rate that decreases as the soil wets. This is the `IMDmax` parameter of the underlying `TGrnAmpt` object. Parsed in `exfil.c:61` as `x[2]`. Must appear together with `Psi` and `Ksat` — either all three are supplied or none (except the single-token `Ksat` shortcut).
- **Source of truth:** `exfil.c:34–70`; manual D.2:1269; `Uproject.pas:206`

---

## Notes

1. **Three mutually exclusive row formats.** The geometry type keyword in column 5 (0-indexed column 4) determines which tokens follow it. TABULAR takes one name token; FUNCTIONAL takes three numeric tokens (A1 A2 A0); the four analytical shapes also take three numeric tokens (L W Z). All formats then optionally append `Ysur Fevap` and seepage parameters.

2. **PARABOLIC vs. PARABOLOID.** The INP keyword for the elliptical paraboloid shape is `PARABOLIC` (defined as `#define w_PARABOLOID "PARABOLIC"` at `text.h:194`). The Appendix D manual text uses the word `PARABOLOID` as a description but the actual parser token is `PARABOLIC`. The GUI writes `'PARABOLIC'` (`Dstorage.pas:270`). The `enums.h` enum constant is named `PARABOLOID` (value 4 in `StorageType`). Do not confuse the constant name with the INP string.

3. **CYLINDRICAL forces Z = 0.** The GUI explicitly resets `STORAGE_COEFF0_INDEX` to `'0'` for cylindrical shapes (`Dstorage.pas:275`). The engine's CYLINDRICAL conversion formula uses only L and W (`node.c:750–756`), ignoring the Z slot.

4. **Optional seepage token variants.** The seepage block after `Fevap` is flexible: if only one token remains beyond `Fevap`, it is taken as `Ksat` alone (constant seepage, `Psi = 0`, `IMD = 0`) per `exfil.c:48–54`. If three tokens remain they are `Psi Ksat IMD`. Any other count (2 or > 3) causes `ERR_ITEMS` at `exfil.c:58`. The GUI always writes all three tokens together (`Uexport.pas:1002–1004`) and only when `Ksat > 0`.

5. **Shape-to-coefficients conversion.** All geometric shapes are internally reduced to the three-parameter power-law representation `a0 + a1·D + a2·D²` (quadratic or sub-quadratic depending on shape) that is stored on `TStorage.a0/a1/a2` (`objects.h:552–554`). This conversion happens inside `storage_readParams` (`node.c:742–783`). Runtime area and volume calculations use these stored coefficients, not the raw L/W/Z values.

6. **Surcharge behaviour.** A non-zero `Ysur` makes the storage unit act like a closed vessel. Water can exceed `Ymax` up to `Ymax + Ysur` before losses occur. This is used to model underground cisterns, tanks, or force-main surcharge segments. Open ponds should leave `Ysur = 0`.

7. **Token-count minimum.** The engine enforces `ntoks ≥ 6` for all formats (`node.c:676`) and `ntoks ≥ 8` for non-TABULAR formats (`node.c:710`). Fewer tokens produce `ERR_ITEMS`.

8. **Node namespace.** Storage nodes share the global `NODE` object array with junctions, outfalls, and dividers. The name must be unique across all node types. Each storage node is also indexed in the `Storage[]` sub-array via `Node[j].subIndex`.

9. **TABULAR curve extrapolation.** The named STORAGE curve is extrapolated linearly beyond its last data point if the unit's `Ymax` exceeds the last depth entry. The first curve point should give the base area at depth 0; if the first depth > 0, the area is linearly interpolated from 0 (`Dstorage.pas:581–595`; manual D.2:1278).

10. **Volume validation.** After all nodes are set up, `node_validate` calls `node_getVolume(j, fullDepth)` for storage nodes and raises `ERR_STORAGE_VOLUME` if the result is negative (`node.c:220–222`). This catches, for example, a FUNCTIONAL shape with a large negative `A0`.

11. **Coordinate representation.** The `[COORDINATES]` section records the map (x, y) location of each storage node; this is separate from the `[STORAGE]` section and not stored here. The GUI imports and exports coordinates in a dedicated section (`Uexport.pas:2212–2222`).
