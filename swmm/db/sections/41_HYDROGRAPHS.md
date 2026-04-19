# [HYDROGRAPHS]

**Purpose:** Defines groups of triangular unit hydrographs (UH) used to compute rainfall-dependent infiltration and inflow (RDII) entering the drainage system. Each UH group is associated with a rain gage and can contain up to three individual hydrographs per month (short-term, medium-term, and long-term responses). The R, T, K shape parameters together with optional initial abstraction parameters fully characterise how excess rainfall is translated into RDII flow at nodes listed in [RDII].

**Occurrence:** Multiple rows per object. Each UH group requires at least one header row (Name + RainGage) and then one data row per response type per month that is explicitly defined. The same group name repeats across all rows that belong to it; months not listed are treated as having no RDII contribution.

**SWMM source references:**
- Engine parser: `rdii.c:224` — function `rdii_readUnitHydParams`; legacy multi-type format: `rdii.c:293` — function `readOldUHFormat`; dispatch: `input.c:589`
- Engine writer: engine does not write INP files; runtime validation in `rdii.c:827`–`858` (checks negative T/K and R-sum > 1.01).
- GUI reader: `Uimport.pas:396` — function `ReadHydrographData`; legacy format: `Uimport.pas:365` — function `ReadOldHydrographFormat`; dispatch at `Uimport.pas:2887`
- GUI writer: `Uexport.pas:201` — procedure `ExportHydrographs`
- GUI editor dialog: `Dunithyd.pas` — `TUnitHydForm`
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — Section [HYDROGRAPHS] at line 2290
- Additional manual refs: `appendix_C_specialized_property_editors/C.27_Unit_Hydrograph_Editor.md`

## Row Format

Two distinct row types appear under this section header:

**Header row** (2 tokens — establishes the group and its rain gage):
```
Name  Raingage
```

**Data row** (6–9 tokens — defines UH shape for one response type in one month):
```
Name  Month  SHORT|MEDIUM|LONG  R  T  K  [Dmax  Drec  D0]
```

**Legacy data row** (11–14 tokens — old single-row format defining all three response types at once; still accepted):
```
Name  Month  R_short  T_short  K_short  R_med  T_med  K_med  R_long  T_long  K_long  [Dmax  Drec  D0]
```

The GUI always writes the modern per-response-type format (`Uexport.pas:254–268`). The engine accepts both formats (`rdii.c:263–266`).

## Fields

### Name

- **Data type:** TEXT
- **Required:** yes
- **Units:** n/a
- **Valid values / range:** Any string not containing spaces, double-quotes, semicolons, or a leading `[`; validated by GUI at `Dunithyd.pas:271–282`.
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** primary identifier of this row; composite PK with Month and ResponseType on data rows; appears alone on the header row
- **Technical description:** The name assigned to the UH group object. The engine stores it in `TUnitHyd.ID` (`objects.h:469`). The same name must appear on the header row and on every subsequent data row belonging to the group. The engine hash-table lookup (`input.c:282`, `rdii.c:236`) allows a group to span multiple lines without duplication in the object registry.
- **Source of truth:** `rdii.c:236–241` (engine lookup/assignment); `Uimport.pas:412–425` (GUI lookup/creation)

---

### Raingage

- **Data type:** NAME_REF
- **Required:** yes (must appear on the 2-token header row before any data rows for that group)
- **Units:** n/a
- **Valid values / range:** Must match an existing name in [RAINGAGES]; error `ERR_NAME` raised if not found (`rdii.c:246–248`).
- **Default:** none
- **Cross-section dependency:** `[RAINGAGES].Name`
- **Database-key hint:** foreign key to [RAINGAGES].Name
- **Technical description:** Identifies which rain gage supplies rainfall depth data to this UH group. Stored in `TUnitHyd.rainGage` as an integer index (`objects.h:470`). The gage's `isUsed` flag is set to `TRUE` when the reference is parsed (`rdii.c:249`). Only one gage can be assigned per group; it is set on the 2-token header line and is not repeated on data rows.
- **Source of truth:** `rdii.c:244–250`

---

### Month

- **Data type:** ENUM
- **Required:** yes (on every data row)
- **Units:** n/a
- **Valid values / range:**
  - `ALL` — applies parameters to all twelve months
  - `JAN`, `FEB`, `MAR`, `APR`, `MAY`, `JUN`, `JUL`, `AUG`, `SEP`, `OCT`, `NOV`, `DEC` — individual calendar months (prefix-matched via `datetime_findMonth`)
  - GUI uses short labels `'All'`, `'Jan'` … `'Dec'` (objprops.txt:214–216, `Uimport.pas:440`)
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** composite PK with Name and ResponseType
- **Technical description:** Specifies which month (or all months) the R-T-K and IA values on this row apply to. Internally stored as a 0-based month index 0–11; index 0 in the engine corresponds to January, not "All". When `ALL` is supplied the engine broadcasts the same parameters to all twelve months (`rdii.c:358–366`, `setUnitHydParams`). Month-specific rows applied later overwrite the all-months defaults for that month only. Months not listed default to zero (no RDII).
- **Source of truth:** `rdii.c:255–260`, `rdii.c:358–384`

---

### ResponseType

- **Data type:** ENUM
- **Required:** yes (on every modern data row; absent on legacy rows)
- **Units:** n/a
- **Valid values / range:** `SHORT`, `MEDIUM`, `LONG` — defined in `keywords.c:153` as `UHTypeWords[]` referencing `text.h:169–171` (`w_SHORT`, `w_MEDIUM`, `w_LONG`). Case-insensitive prefix match via `findmatch`. GUI emits `Short`, `Medium`, `Long` (`objprops.txt:222`).
- **Default:** none
- **Cross-section dependency:** None
- **Database-key hint:** composite PK with Name and Month
- **Technical description:** Distinguishes the three triangular unit hydrograph responses within a single month. SHORT (index 0) represents a rapid near-surface response; MEDIUM (index 1) an intermediate response; LONG (index 2) a slow groundwater-fed response. When the token at position 2 does not match any of the three keywords the engine falls back to the legacy row format (`rdii.c:263–266`).
- **Source of truth:** `rdii.c:263`; `keywords.c:153`

---

### R

- **Data type:** REAL
- **Required:** yes (on data rows)
- **Units:** unitless (dimensionless fraction)
- **Valid values / range:** `≥ 0`; the sum of R values across all three response types for a given month must not exceed 1.01 (engine error `ERR_UNITHYD_RATIOS = 153` at `rdii.c:854–856`). Values between 0 and 1 are typical; a value of 0 effectively disables this response.
- **Default:** 0.0 (initialised in `rdii_initUnitHyd` at `rdii.c:215`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Response ratio — the fraction of each unit of rainfall depth (after initial abstraction) that eventually becomes RDII flow. Stored in `TUnitHyd.r[month][uhType]` (`objects.h:474`). The R values for the three types do not need to sum to 1.0, but their sum must not exceed 1.01 per month (manual line 2320; engine check `rdii.c:852–856`). Token index: position 3 on a modern data row.
- **Source of truth:** `rdii.c:269–272`, `rdii.c:373`

---

### T

- **Data type:** REAL
- **Required:** yes (on data rows)
- **Units:** hours (US and SI)
- **Valid values / range:** `> 0`; negative values cause engine error `ERR_UNITHYD_TIMES = 151` (`rdii.c:842–844`). Must be a positive number; zero base time (T=0 stored as 0 seconds) causes the engine to skip the hydrograph (`rdii.c:836`).
- **Default:** 0.0 (0 seconds; no contribution)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Time to peak of the triangular unit hydrograph, in hours. Stored internally as seconds: `TUnitHyd.tPeak[month][uhType] = (long)(T * 3600)` (`rdii.c:377`). Together with K it determines the time base: `tBase = T * (1 + K)` hours (`rdii.c:376`). Token index: position 4 on a modern data row.
- **Source of truth:** `rdii.c:269–273`, `rdii.c:374–378`

---

### K

- **Data type:** REAL
- **Required:** yes (on data rows)
- **Units:** unitless (dimensionless ratio)
- **Valid values / range:** `> 0`; must produce a positive base time. Stored alongside T to derive `tBase`.
- **Default:** 0.0
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Recession limb ratio — the ratio of the duration of the UH recession limb to the time to peak T. The hydrograph time base equals `T*(1+K)` hours (`rdii.c:376`). The area under the resulting triangle equals 1 in·hr (or mm·hr) before scaling by R (manual line 2322). Token index: position 5 on a modern data row.
- **Source of truth:** `rdii.c:269–273`, `rdii.c:375–378`

---

### Dmax

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** US: inches / SI: millimetres (same units as rainfall depth)
- **Valid values / range:** `≥ 0`; if absent or 0 no initial abstraction is applied.
- **Default:** 0.0 (`rdii_initUnitHyd` at `rdii.c:212`; GUI default empty string treated as 0 in `Uexport.pas:266`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Maximum initial abstraction depth available for this response type in the specified month. Rainfall is reduced by the available initial abstraction before being passed through the unit hydrograph. Stored in `TUnitHyd.iaMax[month][uhType]` (`objects.h:471`). Applies per-response-type, so different IA depths can be set for SHORT, MEDIUM, and LONG within the same month. Token index: position 6 on a modern data row (optional).
- **Source of truth:** `rdii.c:276–282`, `rdii.c:381`

---

### Drec

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** US: inches/day / SI: mm/day
- **Valid values / range:** `≥ 0`
- **Default:** 0.0 (`rdii.c:213`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Initial abstraction recovery rate — the rate at which utilised initial abstraction depth is replenished during dry periods. Stored in `TUnitHyd.iaRecov[month][uhType]` (`objects.h:472`). Token index: position 7 on a modern data row (optional). GUI column header: `Drecov` (`Uexport.pas:220`).
- **Source of truth:** `rdii.c:276–282`, `rdii.c:382`

---

### D0

- **Data type:** REAL
- **Required:** no (default: `0`)
- **Units:** US: inches / SI: millimetres
- **Valid values / range:** `≥ 0`; represents already-used IA depth at simulation start. Should be ≤ Dmax.
- **Default:** 0.0 (`rdii.c:214`)
- **Cross-section dependency:** None
- **Database-key hint:** plain data – no key role
- **Technical description:** Initial abstraction depth already consumed at the start of the simulation (initial condition). Stored in `TUnitHyd.iaInit[month][uhType]` (`objects.h:473`). A non-zero value reduces the effective IA capacity at time zero. Token index: position 8 on a modern data row (optional). GUI column header: `Dinit` (`Uexport.pas:220`).
- **Source of truth:** `rdii.c:276–282`, `rdii.c:383`

---

## Notes

- **Two distinct row types:** The header row (exactly 2 tokens: Name + Raingage) establishes the group and must appear before any data rows for that group. Data rows have 6–9 tokens. The engine dispatches based on token count at `rdii.c:244–252`.

- **Multiple rows per group:** A single UH group (unique Name) can span many rows — one header plus up to 3 response types × 13 month slots (ALL + 12 individual months) = up to 39 data rows. The object is not duplicated in the engine registry when the same Name is seen again (`input.c:280–288`).

- **Month inheritance:** If `ALL` is listed, parameters are broadcast to all 12 months. Subsequent month-specific rows for that group overwrite the inherited values for the named month only (`rdii.c:358–384`, `setUnitHydParams`). A month not listed at all defaults to zeroed parameters (no RDII).

- **Legacy (old) row format:** The engine also accepts a single data row that encodes all three response types together: `Name Month R_short T_short K_short R_med T_med K_med R_long T_long K_long [Dmax Drec D0]`. This requires ≥ 11 tokens and is detected when token[2] does not match SHORT/MEDIUM/LONG (`rdii.c:263–266`, `readOldUHFormat`). The GUI never writes this format but reads it for backward compatibility (`Uimport.pas:445`).

- **Validation:** The engine checks (in `rdii.c:827–858`): (a) tPeak ≥ 0 for each defined UH; (b) r ≥ 0; (c) the sum of R values across all three types for any given month ≤ 1.01. Violations generate error messages 151 and 153.

- **Units dependency:** The Dmax, Drec, and D0 fields are in rainfall depth units (inches for US unit systems, mm for SI). The unit system is set globally in [OPTIONS] and affects display in the GUI (`Dunithyd.pas:142–144`).

- **Cross-section constraint:** Each UH group referenced in [RDII] must exist in [HYDROGRAPHS] (`rdii.c:172–173`). The rain gage referenced in Raingage must exist in [RAINGAGES].

- **Composite key:** For relational storage, the natural composite key on data rows is (Name, Month, ResponseType). The header row keyed by Name alone. Both share the Name foreign-key relationship to the logical group object.

- **No engine INP writer:** The engine has no report-echo for [HYDROGRAPHS] in `inputrpt.c`; only the GUI's `ExportHydrographs` procedure writes this section.
