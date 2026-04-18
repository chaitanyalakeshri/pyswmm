# [STREETS]

**Purpose:** Defines the cross-section geometry of conduits that represent streets or roadways. Each named street section describes a half-street profile (from the curb to the crown) including the gutter depression, optional street backing (sidewalk/lawn), and Manning's roughness values for the road surface and backing. Street sections are referenced by conduits whose `[XSECTIONS]` shape is set to `STREET`; the engine converts the dimensional inputs into an internal transect geometry table used for hydraulic routing.

**Occurrence:** One row per object. Each street section is identified by a unique name. The five required fields must all appear on the same line; up to six additional optional fields may follow on the same line. No continuation lines are used.

**SWMM source references:**
- Engine parser: `swmm/swmm524_engine/src/street.c:58` — function `street_readParams`
- Engine writer: Engine does not write INP. Report-echo of parsed street geometry (area, hydraulic radius, width lookup tables) appears in `swmm/swmm524_engine/src/inputrpt.c:323–352` (Street Summary block).
- GUI reader: `swmm/swmm524_gui/Epaswmm5/Uimport.pas:1425` — function `ReadStreetData`
- GUI writer: `swmm/swmm524_gui/Epaswmm5/Uexport.pas:1289` — procedure `ExportStreets`
- GUI editor dialog: `swmm/swmm524_gui/Epaswmm5/Dstreet.pas` / `Dstreet.dfm` — Street Section Editor (caption "Street Section Editor")
- Manual: `swmm/swmm-users-manual-version-5.2/appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [STREETS] at line 1681
- Additional manual refs:
  - `appendix_C_specialized_property_editors/C.21_Street_Section_Editor.md` — full field-by-field GUI description
  - `chapter_03_swmms_conceptual_model/3.3_Non-Visual_Objects.md` (section 3.3.6) — conceptual model and Figure 3-7 sketch
  - `appendix_D_command_line_swmm/D.2_Input_File_Format.md:1543` — `[XSECTIONS]` *Street* parameter cross-reference

## Row Format

```
Name  Tcrown  Hcurb  Sx  nRoad  (a  W  Sides  Tback  Sback  nBack)
```

The manual format string (D.2, line 1687):
```
Name Tcrown Hcurb Sx nRoad (a W)(Sides Tback Sback nBack)
```

The GUI header comment written by `ExportStreets` (`Uexport.pas:1298–1301`):
```
;;Name           Tcrown   Hcurb    Sx       nRoad    a        W        Sides    Tback    Sback    nBack
```

All eleven data columns are emitted in a single line. Columns 6–11 are optional; if the gutter has no depression (`a = 0`) the gutter-width column `W` is ignored by the engine even if present. If no backing exists the last three backing columns (`Tback Sback nBack`) may be omitted.

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any non-empty string without leading `[`. The GUI enforces no leading bracket and no spaces (`esNoSpace` style, `Dstreet.dfm:355`). Maximum practical length is not specified in the engine; the GUI uses a standard name field.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** primary identifier of this row
- **Technical description:** User-assigned name for the street cross-section profile. This name is referenced in the `[XSECTIONS]` section's *Street* field (`D.2_Input_File_Format.md:1543`) when a conduit's shape is `STREET`. The engine stores it as `Street[i].ID` (`objects.h:629`). Duplicate names are rejected with `ERR_DUP_NAME` (`input.c:444–445`). The GUI also prevents duplicate names at the dialog level (`Dstreet.pas:101–106`).
- **Source of truth:** `swmm/swmm524_engine/src/input.c:443–446` (object registration); `swmm/swmm524_engine/src/street.c:83–85` (lookup and assignment)

---

### Tcrown

- **Data type:** REAL
- **Required:** yes
- **Units:** US: ft / SI: m
- **Valid values / range:** `> 0`
- **Default:** `30` (GUI default, `objprops.txt:622`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Distance from the street curb to the crown (high point) of the roadway. Labeled `Tmax` internally (`objects.h:632`). Stored internally in feet as `street->width = x[1] / UCF(LENGTH)` (`street.c:125`). The GUI label is "Road Width (Tcrown)" (`Dstreet.dfm:26`). The manual notes typical traffic lanes are 10–12 ft (3.3–3.7 m) wide with gutters of 1–3 ft (0.3–1 m) wide (`C.21_Street_Section_Editor.md`). Used in `transect_createStreetTransect` (`transect.c:613`) to define the half-street profile width `w3`.
- **Source of truth:** `swmm/swmm524_engine/src/street.c:89–91` (validation: must be `> 0`); `swmm/swmm524_engine/src/street.c:125` (assignment)

---

### Hcurb

- **Data type:** REAL
- **Required:** yes
- **Units:** US: ft / SI: m
- **Valid values / range:** `> 0`
- **Default:** `0.5` (GUI default, `objprops.txt:623`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Height of the curb measured with respect to the street's cross slope (i.e., the vertical distance from the gutter flow-line at the curb to the top of the curb). Stored internally in feet as `street->curbHeight = x[2] / UCF(LENGTH)` (`street.c:126`). Labeled `Hc` internally (`objects.h:633`). The GUI label is "Curb Height (Hcurb)" (`Dstreet.dfm:33`). The manual states typical heights are 0.33–0.67 ft (0.1–0.2 m) with 0.5 ft (0.15 m) standard in the U.S. (`C.21_Street_Section_Editor.md`). Used in `transect_createStreetTransect` as part of the `y1` elevation: `y1 = street->curbHeight + street->gutterDepression` (`transect.c:616`). The GUI's `SetMaxDepth` method also uses `Hcurb` as the starting estimate for the street's maximum hydraulic depth (`Uproject.pas:1961`).
- **Source of truth:** `swmm/swmm524_engine/src/street.c:89–91` (validation); `swmm/swmm524_engine/src/street.c:126` (assignment)

---

### Sx

- **Data type:** REAL
- **Required:** yes
- **Units:** percent (unitless ratio × 100)
- **Valid values / range:** `> 0`
- **Default:** `2` (GUI default, `objprops.txt:624`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Cross slope of the roadway portion of the street, expressed as a percentage. Converted to a dimensionless slope internally: `street->slope = x[3] / 100.0` (`street.c:127`). The GUI label is "Cross Slope (Sx)" (`Dstreet.dfm:39`). The manual notes typical values of 1–4% with 2% common (`C.21_Street_Section_Editor.md`). Used in `transect_createStreetTransect` to compute the elevation of the gutter transitions (`transect.c:615,618`).
- **Source of truth:** `swmm/swmm524_engine/src/street.c:89–91` (validation); `swmm/swmm524_engine/src/street.c:127` (assignment and conversion)

---

### nRoad

- **Data type:** REAL
- **Required:** yes
- **Units:** unitless (Manning's n)
- **Valid values / range:** `> 0`; typical range 0.013–0.017 for road surfaces
- **Default:** `0.016` (GUI default, `objprops.txt:625`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Manning's roughness coefficient for the paved road surface. Stored as `street->roughness` (`street.c:128`; `objects.h:636`). Used in `transect_createStreetTransect` to assign roughness to the channel zone of the transect: `Nchannel = street->roughness` (`transect.c:658`). When no backing is present this value also applies to the overbank zones (`transect.c:661–663`). The GUI label is "Road Roughness" (`Dstreet.dfm:47`).
- **Source of truth:** `swmm/swmm524_engine/src/street.c:89–91` (validation); `swmm/swmm524_engine/src/street.c:128` (assignment)

---

### a

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** US: ft / SI: m  
  > Note: The manual D.2 states the unit as "in or mm" (`D.2_Input_File_Format.md:1699`); however, the engine applies `UCF(LENGTH)` — the standard foot/meter conversion factor — not an inch/millimeter conversion (`street.c:129`). The GUI stores and writes the value in the same units as all other length fields (ft or m). The "in or mm" description in the manual appears to reflect the typical magnitude of the value rather than a distinct conversion; users should enter the value in ft (US) or m (SI), as the engine processes it with `UCF(LENGTH)`.
- **Valid values / range:** `≥ 0`
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Height of the depressed gutter section below where the roadway cross slope would meet the curb. A value of 0 means the gutter is not depressed (conventional gutter). When `a > 0`, the gutter `W` field becomes meaningful; if `a = 0`, the engine ignores `W` regardless (`D.2_Input_File_Format.md:1716`). Stored as `street->gutterDepression = x[5] / UCF(LENGTH)` (`street.c:129`). Used in `transect_createStreetTransect` in the `y3` calculation: `y3 = street->gutterDepression + street->slope * w2` (`transect.c:615`). A typical depressed gutter depth is 0.17 ft (~2 in, 0.05 m) (`C.21_Street_Section_Editor.md`).
- **Source of truth:** `swmm/swmm524_engine/src/street.c:94–96` (validation); `swmm/swmm524_engine/src/street.c:129` (assignment)

---

### W

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** US: ft / SI: m
- **Valid values / range:** `≥ 0`
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Width of the depressed gutter zone measured from the curb face to where the gutter rejoins the roadway cross slope. Ignored by the engine when `a = 0` (`D.2_Input_File_Format.md:1716`). Stored as `street->gutterWidth = x[6] / UCF(LENGTH)` (`street.c:130`). In `transect_createStreetTransect` this is `w2` (`transect.c:613`). A typical depressed gutter width is 2 ft (0.6 m); conventional gutters use 0 (`C.21_Street_Section_Editor.md`). The GUI label is "Gutter Width (W)" (`Dstreet.dfm:54`).
- **Source of truth:** `swmm/swmm524_engine/src/street.c:99–101` (validation); `swmm/swmm524_engine/src/street.c:130` (assignment)

---

### Sides

- **Data type:** INTEGER
- **Required:** no (default: `2`)
- **Units:** unitless
- **Valid values / range:** `1` (single-sided) or `2` (two-sided)
- **Default:** `2`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Controls whether the street cross-section is symmetric. A value of `1` means the section represents only one side of the street (from curb to crown); a value of `2` mirrors the profile symmetrically about the crown. Stored as `street->sides` (`street.c:131`; `objects.h:630`). In `transect_createStreetTransect`, a one-sided street uses 5 station-elevation pairs and a two-sided street uses 8 (`transect.c:634–654`). The GUI represents this as two radio buttons — "One Sided" and "Two Sided" (default checked) — rather than a numeric field (`Dstreet.dfm:301–318`; `Dstreet.pas:152–176`). The engine rejects values other than 1 or 2 (`street.c:106–107`).
- **Source of truth:** `swmm/swmm524_engine/src/street.c:104–107` (validation and default); `swmm/swmm524_engine/src/street.c:131` (assignment)

---

### Tback

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** US: ft / SI: m
- **Valid values / range:** `≥ 0`
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Width of the area backing the street (e.g., sidewalk, lawn, or embankment) extending beyond the curb in the direction away from the road crown. Enter `0` if no backing exists. When `Tback = 0`, the engine treats the backing parameters as absent and applies `nRoad` to the overbank zones of the transect (`transect.c:659–663`). When `Tback > 0`, the engine requires that `Sback` and `nBack` also be present (`street.c:116`). Stored as `street->backWidth = x[8] / UCF(LENGTH)` (`street.c:132`). Used in `transect_createStreetTransect` as `w1` (`transect.c:611`). The GUI label is "Backing Width (Tback)" (`Dstreet.dfm:68`).
- **Source of truth:** `swmm/swmm524_engine/src/street.c:110–121` (validation and conditional requirement); `swmm/swmm524_engine/src/street.c:132` (assignment)

---

### Sback

- **Data type:** REAL
- **Required:** conditional — required when `Tback > 0`; ignored otherwise
- **Units:** percent (unitless ratio × 100)
- **Valid values / range:** `> 0` when `Tback > 0`; `≥ 0` otherwise
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Slope of the backing surface expressed as a percentage. Converted to a dimensionless slope internally: `street->backSlope = x[9] / 100.0` (`street.c:133`). When `Tback > 0`, a zero or negative `Sback` causes `ERR_NUMBER` (`street.c:118–119`). Used in `transect_createStreetTransect` to compute the top elevation of the backing: `ymax = street->backSlope * street->backWidth + y1` (`transect.c:617`). The GUI label is "Backing Slope (Sback)" (`Dstreet.dfm:74`). The manual notes that if backing width is non-zero, this must be a positive number (`C.21_Street_Section_Editor.md`).
- **Source of truth:** `swmm/swmm524_engine/src/street.c:117–120` (conditional validation); `swmm/swmm524_engine/src/street.c:133` (assignment)

---

### nBack

- **Data type:** REAL
- **Required:** conditional — required when `Tback > 0`; ignored otherwise
- **Units:** unitless (Manning's n)
- **Valid values / range:** `> 0` when `Tback > 0`
- **Default:** `0`
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Manning's roughness coefficient for the backing surface (sidewalk, lawn, etc.). Stored as `street->backRoughness` (`street.c:134`; `objects.h:639`). When `Tback > 0`, a zero or negative `nBack` causes `ERR_NUMBER` (`street.c:118–119`). In `transect_createStreetTransect`, when backing is present this value is assigned to the left and right overbank roughness (`Nleft = Nright = street->backRoughness`, `transect.c:668–669`). When `Tback = 0`, this field is ignored and `nRoad` applies everywhere. The GUI label is "Backing Roughness" (`Dstreet.dfm:82`); the manual notes this parameter is ignored if backing width is 0 (`C.21_Street_Section_Editor.md`).
- **Source of truth:** `swmm/swmm524_engine/src/street.c:117–120` (conditional validation); `swmm/swmm524_engine/src/street.c:134` (assignment)

## Notes

- **Minimum token check differs between engine and GUI.** The engine requires at least 5 tokens (Name + 4 required parameters) and returns `ERR_ITEMS` otherwise (`street.c:80`). The GUI's `ReadStreetData` requires `nToks >= 8` (`Uimport.pas:1435`), reflecting the GUI's convention of always writing all 10 data columns via `ExportStreets` (`Uexport.pas:1314`). Files produced by the GUI will always have all 11 columns present even when backing and gutter parameters are zero.
- **Gutter unit discrepancy.** The manual D.2 describes the gutter depression `a` as being in "in or mm" (`D.2_Input_File_Format.md:1699`) which is a misleading description; the engine converts all length fields including `a` uniformly via `UCF(LENGTH)` (ft/m). Users should enter `a` in feet (US) or meters (SI), the same as `Tcrown`, `Hcurb`, `W`, `Tback`.
- **Backing parameter dependency.** If `Tback > 0`, then `Sback` and `nBack` must also be provided and must be `> 0`; the engine returns `ERR_ITEMS` if only `Tback` is given without `Sback`/`nBack` (`street.c:116`). If `Tback = 0`, all three backing columns may be omitted or set to 0.
- **Street referenced by [XSECTIONS].** A conduit whose `[XSECTIONS]` shape is `STREET` must supply this street section's `Name` in the `Tsect` column of the `[XSECTIONS]` row (`D.2_Input_File_Format.md:1543`). The conduit's `Geom1` (MaxDepth) is ignored and computed automatically by the engine from the street geometry (`Uproject.pas:1433–1449`).
- **Internal transect creation.** After parsing, `street_readParams` immediately calls `transect_createStreetTransect` (`street.c:135`) which builds the hydraulic geometry tables (area, hydraulic radius, width vs. depth) stored in `TStreet.transect` (`objects.h:640`). This geometry drives all routing calculations for street conduits.
- **Uniqueness.** Each `Name` must be unique within the `[STREETS]` section; duplicates are rejected with `ERR_DUP_NAME` at the object-registration pass (`input.c:444–445`).
- **One row per street section.** Unlike `[TRANSECTS]` (which spans multiple sub-lines), each street section occupies exactly one line. There are no continuation records.
- **GUI default values** (from `objprops.txt:621–631`): Tcrown=30, Hcurb=0.5, Sx=2, nRoad=0.016, a=0, W=0, Sides=2, Tback=0, Sback=0, nBack=0.
- **Section keyword matching.** The engine uses prefix matching on `[STREET` (macro `ws_STREET`, `text.h:458`), so `[STREETS]` in the INP file is matched correctly.
