# [EVENTS]

**Purpose:** Defines one or more discrete hydraulic event periods that restrict full unsteady flow routing to specific time windows within an otherwise continuous simulation. During time intervals that fall outside every listed event, the hydraulic state of the conveyance network is held constant at the values computed at the end of the previous event; hydrology (runoff, groundwater, DWF, etc.) continues to advance throughout the entire simulation, but its inflows to the network are ignored between events. The mechanism is designed to speed up long-term continuous simulations when only a handful of storm events are of interest.

**Occurrence:** one row per object — each row defines one event period (start date/time + end date/time). Zero or more rows; the section may be absent entirely if no event-mode simulation is required. Multiple non-overlapping rows are allowed; they need not be in chronological order (the engine sorts them at run time). Overlapping events are resolved by truncating the earlier event's end time to the start of the next event.

**SWMM source references:**
- Engine parser: `input.c:755` — function `readEvent`; section dispatch at `input.c:619`; object counting at `input.c:441`
- Engine writer: engine does not write INP files; no report-echo function exists for [EVENTS]
- GUI reader: `Uimport.pas:2248` — procedure `ReadEventData` (called at line 3090 when section index == 54)
- GUI writer: `Uexport.pas:498` — procedure `ExportEvents`
- GUI editor dialog: `Devents.pas` / `Devents.dfm` — `TEventsForm` ("Events Editor")
- Manual: `appendix_D_command_line_swmm/D.2_Input_File_Format.md` — section not documented in D.2 (added in build 5.1.011 after the manual was frozen)
- Additional manual refs: `chapter_08_running_a_simulation/8.3_Selecting_Event_Periods.md` — authoritative prose description; `8.1_Setting_Simulation_Options.md` (line 25–30) — GUI access via Options > Events category

## Row Format

```
StartDate  StartTime  EndDate  EndTime
```

Four whitespace-delimited tokens per line. No keyword prefix. The GUI comment header written by `ExportEvents` is:

```
;;Start Date         End Date
```

Example line as emitted by the GUI (`Devents.pas:244`):

```
01/01/2020  06:00  01/01/2020  12:00
```

A row whose first character is `;` (a single semicolon, not `;;`) is stored in `Project.Events` but skipped by the engine parser (treated as a comment). The GUI uses this convention for events whose "Use" checkbox is unchecked (`Devents.pas:243`).

## Fields

### StartDate

- **Data type:** DATE
- **Required:** yes
- **Units:** n/a (calendar date, locale-sensitive)
- **Valid values / range:** Any valid calendar date parseable by `datetime_strToDate`. Accepts `M/D/YYYY`, `D-M-YYYY`, or `YYYY-M-D` depending on the engine's `DateFormat` setting (enum `M_D_Y`, `D_M_Y`, `Y_M_D`). Separator may be `/` or `-`. Month may also be a 3-letter abbreviation.
- **Default:** none
- **Cross-section dependency:** Must fall within the overall simulation window (`[OPTIONS].START_DATE` … `[OPTIONS].END_DATE`), otherwise the event has no effect.
- **Database-key hint:** composite PK with StartTime (together they identify the event start DateTime)
- **Technical description:** Calendar date of the start of the hydraulic event. Combined with `StartTime` to form the `DateTime` value stored in `TEvent.start` (`objects.h:229`). The engine computes `Event[i].start = x[0] + x[1]` where `x[0]` is the encoded date and `x[1]` is the encoded time (`input.c:769`). The combined start must be strictly less than the combined end (`input.c:771`).
- **Source of truth:** `input.c:760` — `datetime_strToDate(tok[0], &x[0])` call within `readEvent`

### StartTime

- **Data type:** TIME
- **Required:** yes
- **Units:** n/a (time of day)
- **Valid values / range:** Any string parseable by `datetime_strToTime`: either `HH:MM:SS` (or `HH:MM`) format, or a decimal number of hours. The GUI constrains entry to `HH:mm` format via `TDateTimePicker` with `Format := 'HH:mm'` (`Devents.pas:81`).
- **Default:** none
- **Cross-section dependency:** None beyond the composite constraint with StartDate (start < end).
- **Database-key hint:** composite PK with StartDate
- **Technical description:** Time-of-day component of the event start. `datetime_strToTime` accepts either `hr:min:sec`, `hr:min`, or a real decimal representing hours; the result is divided by 24 to yield a fractional day (`datetime.c:338–363`). Added to the encoded StartDate to produce `TEvent.start`.
- **Source of truth:** `input.c:762` — `datetime_strToTime(tok[1], &x[1])` call within `readEvent`

### EndDate

- **Data type:** DATE
- **Required:** yes
- **Units:** n/a (calendar date)
- **Valid values / range:** Same format rules as StartDate. Must yield an encoded date such that EndDate + EndTime > StartDate + StartTime.
- **Default:** none
- **Cross-section dependency:** None beyond the composite start < end constraint.
- **Database-key hint:** plain data — no key role
- **Technical description:** Calendar date of the end of the hydraulic event. Stored (together with EndTime) as `TEvent.end` in the global `Event` array (`globals.h:169`). The engine enforces that the combined end strictly exceeds the combined start (`input.c:771`). After sorting, if two events overlap, the first event's end is truncated to the second event's start (`routing.c:958`).
- **Source of truth:** `input.c:764` — `datetime_strToDate(tok[2], &x[2])` call within `readEvent`

### EndTime

- **Data type:** TIME
- **Required:** yes
- **Units:** n/a (time of day)
- **Valid values / range:** Same format rules as StartTime.
- **Default:** none
- **Cross-section dependency:** None beyond the composite start < end constraint.
- **Database-key hint:** plain data — no key role
- **Technical description:** Time-of-day component of the event end. Combined with EndDate to produce `TEvent.end = x[2] + x[3]` (`input.c:770`). The engine's `isBetweenEvents()` function returns `FALSE` (meaning: inside an event, full routing active) when `currentDate >= Event[NextEvent].start` and returns `TRUE` (between events, routing frozen) when `currentDate > Event[NextEvent].end` (`routing.c:337–355`).
- **Source of truth:** `input.c:766` — `datetime_strToTime(tok[3], &x[3])` call within `readEvent`

## Notes

- **Section keyword matching:** Like all SWMM sections, `[EVENTS]` is matched by prefix: `ws_EVENT "[EVENT"` (`text.h:457`). A line beginning with `[EVENTXXX` would match.
- **No named identifier:** Unlike most SWMM objects, each event row has no name field. The engine counts events with `NumEvents++` during the first pass (`input.c:441`) and fills `Event[Mevents]` during the second pass. `NumEvents` is a global integer initialized to 0 (`project.c:876`). There is no `project_addObject` call for events — they are not part of the named-object registry.
- **Internal storage:** `Event` is a C array of `TEvent` structs allocated as `(TEvent *) calloc(NumEvents+1, sizeof(TEvent))` (`project.c:1036`). A sentinel entry `Event[NumEvents].start = BIG` is appended so that the `isBetweenEvents` loop terminates correctly even after all events have passed (`project.c:1037–1038`).
- **Sorting:** Events entered in any order are shell-sorted by `start` date in `sortEvents()` (`routing.c:929–960`) called from `routing_init` (`routing.c:125`). Overlapping events are resolved post-sort by truncating `Event[i].end = Event[i+1].start` (`routing.c:958`).
- **Inter-event time step:** When `BetweenEvents` is `TRUE` the engine selects the maximum possible routing step (advancing to either the next report time or the start of the next event) rather than the normal Courant-limited step (`routing.c:166–179`). This is the primary performance benefit.
- **Storage carryover:** "When a new event occurs, the water in a storage unit node will remain at the same level it had at the end of the previous event" (`8.3_Selecting_Event_Periods.md:5`). DB designers should be aware that initial conditions for each event are implicitly inherited from the prior event's end state.
- **GUI disabled events:** The GUI's Events Editor stores disabled (unchecked) events as lines beginning with a single semicolon (`;`) in `Project.Events` (`Devents.pas:243`). The GUI reader (`ReadEventData`) passes such lines verbatim to `Project.Events` but notes they start with `;`. The engine parser ignores any line whose first character is `;` (normal SWMM comment handling). These "disabled" lines are round-tripped through INP but do not increment `NumEvents`.
- **Double-semicolon comments:** Lines beginning with `;;` are filtered by `ReadEventData` (`Uimport.pas:2255`) and are never stored, consistent with standard SWMM column-header convention.
- **No cross-section dependencies:** Events do not reference any other section objects.
- **Uniqueness:** The engine does not enforce uniqueness of start/end pairs; duplicate event rows produce duplicate `TEvent` entries. After sorting, identical or fully overlapping events collapse when the truncation rule is applied. A DB schema should enforce that (StartDate, StartTime) pairs are unique within a project.
- **Section absent from D.2:** The [EVENTS] section was introduced in build 5.1.011 (`keywords.c:28`) and is not described in Appendix D.2 of the SWMM 5.2 Users Manual. The authoritative prose description is in `chapter_08_running_a_simulation/8.3_Selecting_Event_Periods.md`.
