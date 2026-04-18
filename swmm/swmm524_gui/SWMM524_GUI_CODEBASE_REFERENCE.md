# EPA SWMM 5.2.4 GUI - Codebase Reference Guide

> **Project:** Storm Water Management Model (SWMM) Version 5.2.4 - Graphical User Interface
> 
> **Language:** Delphi/Object Pascal
> 
> **IDE:** Embarcadero Delphi 10.4
> 
> **Author:** L. Rossman (EPA)
> 
> **Last Updated:** Version 5.2.4 (July 2023)

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Project Structure](#project-structure)
3. [Core Architecture](#core-architecture)
4. [Key Components](#key-components)
5. [Data Model](#data-model)
6. [File Organization](#file-organization)
7. [Critical Constants and Configuration](#critical-constants-and-configuration)
8. [Building the Project](#building-the-project)
9. [Integration with SWMM Engine](#integration-with-swmm-engine)
10. [Coding Conventions](#coding-conventions)

---

## Project Overview

### Purpose
EPA SWMM 5.2.4 GUI is the Windows graphical user interface for the Storm Water Management Model. It provides a visual environment for:
- Creating and editing stormwater drainage system models
- Running hydraulic and hydrologic simulations
- Visualizing results through maps, graphs, and reports
- Managing water quality analysis and LID (Low Impact Development) controls

### Technology Stack
- **Development Environment:** Embarcadero Delphi 10.4
- **Language:** Object Pascal (Delphi)
- **Target Platforms:** Windows 32-bit and 64-bit
- **Simulation Engine:** External DLL (`swmm5.dll`)

### Key Features
- MDI (Multiple Document Interface) application
- Interactive map-based model builder
- Property editor for hydraulic components
- Real-time simulation monitoring
- Comprehensive reporting and visualization
- Import/Export capabilities (DXF, various formats)
- LID controls and green infrastructure modeling
- Inlet and street flow modeling
- Calibration data management

---

## Project Structure

### Root Directory Layout

```
swmm524_gui/
├── Epaswmm5/          # Main GUI application source code
│   ├── *.pas          # Pascal source units
│   ├── *.dfm          # Delphi form files
│   ├── *.dpr          # Main project file
│   ├── *.dproj        # Delphi project configuration
│   ├── *.res          # Resource files (icons, cursors)
│   ├── objprops.txt   # Object property definitions
│   └── viewvars.txt   # View variable definitions
├── Components/        # Custom Delphi components
│   ├── NumEdit.pas    # Numeric text edit control
│   ├── OpenDlg.pas    # File open dialog with preview
│   ├── PgSetup.pas    # Page setup dialog
│   ├── VirtList.pas   # Virtual listbox control
│   ├── Xprinter.pas   # Print control component
│   ├── Epa.dpk        # Component package file
│   └── Epa.dproj      # Component project
└── readme.txt         # Project documentation
```

### Main Project Files

- **`Epaswmm5.dpr`** - Main program entry point
- **`Epaswmm5.dproj`** - Delphi project configuration (XML)
- **`Epaswmm5.cfg`** - Compiler configuration
- **`Epaswmm5.res`** - Compiled resources (icons, cursors)

---

## Core Architecture

### Application Pattern: MDI (Multiple Document Interface)

The application uses an MDI architecture with:
- **Parent Form:** `TMainForm` (Fmain.pas) - Contains menu, toolbars, status bar, browser panel
- **Child Forms:** Various specialized windows for different views and tasks

### MDI Child Forms

| Form Class | Unit | Purpose |
|------------|------|---------|
| `TMapForm` | Fmap.pas | Interactive study area map |
| `TStatusForm` | Fstatus.pas | Simulation status and progress |
| `TResultsForm` | Fresults.pas | Summary results tables |
| `TGraphForm` | Fgraph.pas | Time series graphs |
| `TProfilePlotForm` | Fproplot.pas | Longitudinal profile plots |
| `TTableForm` | Ftable.pas | Tabular time series data |
| `TStatsReportForm` | Fstats.pas | Statistical analysis reports |

### Stay-On-Top Forms (Auto-Created)

| Form Class | Unit | Purpose |
|------------|------|---------|
| `TOVMapForm` | Fovmap.pas | Overview/bird's eye map |
| `TReportingForm` | Dreporting.pas | Report object selection |
| `TReportSelectForm` | Dreport.pas | Report content configuration |
| `TTimePlotForm` | Dtimeplot.pas | Time plot settings |
| `TFindForm` | Dfind.pas | Object search/locate |
| `TQueryForm` | Dquery.pas | Query objects by criteria |
| `TEventsForm` | Devents.pas | Event analysis |
| `TInletUsageForm` | Dinletusage.pas | Inlet configuration |

### Major Subsystems

1. **Project Management** (Uproject.pas)
   - Data model representation
   - Object management
   - File I/O operations

2. **Map System** (Umap.pas, Fmap.pas)
   - GIS-like map display
   - Object drawing and selection
   - Coordinate management
   - Backdrop image support

3. **Property Editing** (PropEdit.pas, Fproped.pas)
   - Generic property editor framework
   - Type-safe property handling
   - Validation and input masking

4. **Simulation Control** (Fsimul.pas)
   - SWMM engine interface
   - Progress monitoring
   - Real-time animation

5. **Output Processing** (Uoutput.pas, Uresults.pas)
   - Binary output file reading
   - Result caching and retrieval
   - Statistical calculations

6. **Visualization** (Ugraph.pas, Ulegend.pas)
   - Graph rendering
   - Legend management
   - Color mapping and themes

---

## Key Components

### Core Units (Prefix: U)

These units provide fundamental functionality:

| Unit | Description |
|------|-------------|
| **Uglobals.pas** | Global constants, types, and data structures |
| **Uproject.pas** | TProject class - core data model |
| **Uutils.pas** | Utility functions (string handling, conversions, math) |
| **Umap.pas** | Map drawing and coordinate management |
| **Uvertex.pas** | Polygon/polyline vertex management |
| **Uoutput.pas** | Binary output file handling |
| **Uresults.pas** | Results processing and retrieval |
| **Ulegend.pas** | Map legend generation |
| **Ugraph.pas** | Graph plotting utilities |
| **Uedit.pas** | Object editing operations |
| **Uimport.pas** | Data import functions |
| **Uexport.pas** | Data export functions |
| **Uvalidate.pas** | Input data validation |
| **Uinifile.pas** | INI file configuration |
| **Utools.pas** | Analysis tools |
| **Ucalib.pas** | Calibration data handling |
| **Ustats.pas** | Statistical computations |
| **Ulid.pas** | LID control management |
| **Uinlet.pas** | Inlet management |
| **Ubrowser.pas** | Browser panel management |
| **Uclipbrd.pas** | Clipboard operations |
| **Ucoords.pas** | Coordinate transformations |
| **Ucombine.pas** | File combining operations |
| **Udxf.pas** | DXF file import/export |
| **Uupdate.pas** | Project update/migration |

### Form Units (Prefix: F)

Main visual forms:

| Unit | Form | Description |
|------|------|-------------|
| **Fmain.pas** | TMainForm | Main MDI parent window |
| **Fmap.pas** | TMapForm | Study area map display |
| **Fproped.pas** | TPropEditForm | Property editor panel |
| **Fgraph.pas** | TGraphForm | Time series graph window |
| **Fproplot.pas** | TProfilePlotForm | Profile plot window |
| **Ftable.pas** | TTableForm | Tabular data display |
| **Fstats.pas** | TStatsReportForm | Statistics report |
| **Fstatus.pas** | TStatusForm | Status report display |
| **Fresults.pas** | TResultsForm | Summary results |
| **Fsimul.pas** | TSimulationForm | Simulation control |
| **Fovmap.pas** | TOVMapForm | Overview map |

### Dialog Units (Prefix: D)

Dialog forms for data entry and configuration:

| Unit | Form | Purpose |
|------|------|---------|
| **Dabout.pas** | TAboutBoxForm | About dialog |
| **Dprefers.pas** | TPreferencesForm | User preferences |
| **Dproject.pas** | TProjectForm | Project information |
| **Dsummary.pas** | TProjectSummaryForm | Project summary |
| **Ddefault.pas** | TDefaultsForm | Default values |
| **Doptions.pas** | TAnalysisOptionsForm | Analysis options |
| **Dclimate.pas** | TClimatologyForm | Climate data |
| **Dcurve.pas** | TCurveDataForm | Curve editor |
| **Dtseries.pas** | TTimeseriesForm | Time series editor |
| **Dpattern.pas** | TPatternForm | Pattern editor |
| **Dtransect.pas** | TTransectForm | Transect editor |
| **Dxsect.pas** | TXsectionForm | Cross-section editor |
| **Dcontrol.pas** | TControlsForm | Control rules |
| **Dpollut.pas** | TPollutantForm | Pollutant properties |
| **Dlanduse.pas** | TLanduseForm | Land use editor |
| **Daquifer.pas** | TAquiferForm | Aquifer properties |
| **Dsnow.pas** | TSnowpackForm | Snow pack parameters |
| **Dlid.pas** | TLidControlDlg | LID control editor |
| **Dlidgroup.pas** | TLidGroupDlg | LID group editor |
| **Dlidusage.pas** | TLidUsageDlg | LID usage settings |
| **Dinfil.pas** | TInfilForm | Infiltration parameters |
| **Dgwater.pas** | TGroundWaterForm | Groundwater properties |
| **Dgweqn.pas** | TGWEqnForm | Groundwater equation |
| **Dinflows.pas** | TInflowsForm | External inflows |
| **Dtreat.pas** | TTreatmentForm | Treatment editor |
| **Dloads.pas** | TInitLoadingsForm | Initial loadings |
| **Dinlet.pas** | TInletEditorForm | Inlet editor |
| **Dinletusage.pas** | TInletUsageForm | Inlet usage |
| **Dstreet.pas** | TStreetEditorForm | Street properties |
| **Dculvert.pas** | TCulvertSelectorForm | Culvert selection |
| **Dstorage.pas** | TStorageForm | Storage unit shape |
| **Darchpipe.pas** | TArchPipeForm | Arch pipe dimensions |
| **Dunithyd.pas** | TUnitHydForm | Unit hydrograph |
| **Dsubland.pas** | TSubLandUsesForm | Subcatchment land uses |
| **Dcalib1.pas** | TCalibDataForm | Calibration data |
| **Dstats.pas** | TStatsSelectForm | Statistics selection |
| **Devents.pas** | TEventsForm | Event definition |
| **Dmap.pas** | TMapOptionsForm | Map options |
| **Dmapdim.pas** | TMapDimensionsForm | Map dimensions |
| **Dmapexp.pas** | TMapExportForm | Map export settings |
| **Dbackdrp.pas** | TBackdropFileForm | Backdrop file |
| **Dbackdim.pas** | TBackdropDimensionsForm | Backdrop sizing |
| **Dlabel.pas** | TLabelForm | Map label properties |
| **Dlegend.pas** | TLegendForm | Legend editor |
| **Dcolramp.pas** | TColorRampForm | Color ramp selector |
| **Dreport.pas** | TReportSelectForm | Report configuration |
| **Dreporting.pas** | TReportingForm | Reporting objects |
| **Dquery.pas** | TQueryForm | Query builder |
| **Dfind.pas** | TFindForm | Find object |
| **Dcopy.pas** | TCopyToForm | Copy dialog |
| **Dgrouped.pas** | TGroupEditForm | Group editing |
| **Dgrpdel.pas** | TGroupDeleteForm | Group deletion |
| **Dcombine.pas** | TFileCombineForm | File combining |
| **Diface.pas** | TIfaceFileForm | Interface file |
| **Dnotes.pas** | TNotesEditorForm | Notes editor |
| **Dtools1.pas** | TToolOptionsForm | Tool options |
| **Dtools2.pas** | TToolPropertiesForm | Tool properties |
| **Dchart.pas** | TChartOptionsDlg | Chart options |
| **Dprevplot.pas** | TPreviewPlotForm | Plot preview |
| **Dproplot.pas** | TProfilePlotOptionsForm | Profile plot options |
| **Dprofile.pas** | TProfileSelectionForm | Profile selection |
| **Dproselect.pas** | TProfileSelectForm | Profile selector |
| **Dtimeplot.pas** | TTimePlotForm | Time plot settings |
| **Dwelcome.pas** | TWelcomeForm | Welcome screen |

### Frame Units

Reusable visual components:

| Unit | Frame | Purpose |
|------|-------|---------|
| **GridEdit.pas** | TGridEditFrame | Grid-based data editor |
| **UpDnEdit.pas** | TUpDnEditBox | Spin edit control |
| **Animator.pas** | TAnimatorFrame | Animation player |

### Custom Component Units

Located in `Components/` folder:

| Unit | Component | Description |
|------|-----------|-------------|
| **NumEdit.pas** | TNumEdit | Numeric text editor with validation |
| **OpenDlg.pas** | TOpenTxtFileDialog | Open dialog with text preview |
| **PgSetup.pas** | TPageSetupDialog | Page setup and print configuration |
| **VirtList.pas** | TVirtualListBox | Virtual listbox (unlimited items) |
| **Xprinter.pas** | TPrintControl | Enhanced printing with preview |

### Property Editor Framework

| Unit | Description |
|------|-------------|
| **PropEdit.pas** | Generic property editor base classes and types |

Key types:
- `TPropRecord` - Property definition structure
- `TEditStyle` - Property edit control types (esEdit, esComboList, esButton, etc.)
- `TEditMask` - Input validation masks (emNumber, emPosNumber, emNoSpace, etc.)

---

## Data Model

### Object Categories (from Uproject.pas)

The SWMM model consists of multiple object types organized hierarchically:

#### Core Object Types (Constants)

```pascal
NOTES        = 0;   // Title/Notes
OPTION       = 1;   // Simulation Options
RAINGAGE     = 2;   // Rain Gages
SUBCATCH     = 3;   // Subcatchments

// Node types
JUNCTION     = 4;   // Junctions
OUTFALL      = 5;   // Outfalls
DIVIDER      = 6;   // Flow Dividers
STORAGE      = 7;   // Storage Units

// Link types
CONDUIT      = 8;   // Conduits
PUMP         = 9;   // Pumps
ORIFICE      = 10;  // Orifices
WEIR         = 11;  // Weirs
OUTLET       = 12;  // Outlets

MAPLABEL     = 13;  // Map Labels

// Curve types
CONTROLCURVE   = 14;  // Control Curves
DIVERSIONCURVE = 15;  // Diversion Curves
PUMPCURVE      = 16;  // Pump Curves
RATINGCURVE    = 17;  // Rating Curves
SHAPECURVE     = 18;  // Shape Curves
STORAGECURVE   = 19;  // Storage Curves
TIDALCURVE     = 20;  // Tidal Curves
WEIRCURVE      = 21;  // Weir Curves

// Time-based data
TIMESERIES     = 22;  // Time Series
PATTERN        = 23;  // Time Patterns
TRANSECT       = 24;  // Transects

// Other
HYDROGRAPH     = 25;  // Unit Hydrographs
POLLUTANT      = 26;  // Pollutants
LANDUSE        = 27;  // Land Uses
AQUIFER        = 28;  // Aquifers
CONTROL        = 29;  // Control Rules
CLIMATE        = 30;  // Climatology
SNOWPACK       = 31;  // Snow Packs
LID            = 32;  // LID Controls
STREET         = 33;  // Street Sections
INLET          = 34;  // Inlets

MAXCLASS       = 34;  // Maximum class index
```

### TProject Class Structure

The `TProject` class (Uproject.pas) is the central data repository:

```pascal
TProject = class(TObject)
  // Collections of objects
  Lists: array[0..MAXCLASS] of TStringList;
  
  // Project properties
  Title: String;
  Notes: TStringList;
  FileName: String;
  HasChanged: Boolean;
  
  // Methods
  constructor Create;
  destructor Destroy; override;
  function GetObject(ObjType: Integer; Index: Integer): TObject;
  function GetID(ObjType: Integer; Index: Integer): String;
  // ... many more methods
end;
```

### Object Data Storage

Each object type has:
1. **Property Array** - String array holding property values
2. **Property Records** - TPropRecord array defining property metadata
3. **Default Values** - Default property values

Example for Junctions:

```pascal
// Property indices
JUNCTION_MAX_DEPTH_INDEX = 8;
JUNCTION_INIT_DEPTH_INDEX = 9;
JUNCTION_SURCHARGE_DEPTH_INDEX = 10;
JUNCTION_PONDED_AREA_INDEX = 11;

// Property definitions
JunctionProps: array [0..11] of TPropRecord;

// Default values
DefJunction: array [0..11] of String;
```

### View Variables (Themes)

Display themes for visualizing model properties and results (viewvars.txt):

#### Subcatchment Views
- Input: Area, Width, Slope, Imperviousness, LID Usage
- Summary: Total Precip, Evap, Infil, Runoff, Peak Runoff, Runoff Coeff
- Time Series: Rainfall, Snow Depth, Evaporation, Infiltration, Runoff, GW Flow, GW Elevation, Soil Moisture, Washoff

#### Node Views
- Input: Invert Elevation
- Summary: Max Depth, Max HGL, Max Lateral Flow, Total Lateral Flow, Max Flooding, Flood Volume, Hours Flooded
- Time Series: Depth, Head, Volume, Lateral Inflow, Total Inflow, Flooding, Quality

#### Link Views
- Input: Diameter, Roughness, Slope
- Summary: Max Flow, Max Velocity, Max Capacity, Hours Surcharged, Hours Capacity Limited
- Time Series: Flow, Depth, Velocity, Volume, Capacity, Quality

---

## File Organization

### Naming Conventions

**Unit Prefixes:**
- `F` - Form units (visual forms)
- `D` - Dialog units (dialog forms)
- `U` - Utility/core units (no visual component)

**Common File Extensions:**
- `.pas` - Pascal source code
- `.dfm` - Delphi form definition (binary or text)
- `.dpr` - Delphi project main program
- `.dproj` - Delphi project configuration (XML)
- `.res` - Compiled resource file
- `.dpk` - Delphi package source
- `.bpl` - Compiled binary package library
- `.dcu` - Delphi compiled unit
- `.ico` - Icon file
- `.txt` - Text configuration/data

### Important Configuration Files

| File | Purpose |
|------|---------|
| `objprops.txt` | Object property definitions (included in Uproject.pas) |
| `viewvars.txt` | View variable definitions (included in Uglobals.pas) |
| `epaswmm5.ini` | User preferences and settings (runtime) |
| `Epaswmm5.cfg` | Compiler configuration |

### Data File Formats

SWMM uses several file formats:

| Extension | Description |
|-----------|-------------|
| `.inp` | SWMM input file (text format, main project file) |
| `.rpt` | SWMM report file (simulation results text report) |
| `.out` | SWMM binary output file (time series results) |
| `.hsf` | Hot start file (initial conditions) |
| `.map` | Map backdrop configuration |
| `.scn` | Scenario file |

---

## Critical Constants and Configuration

### Version Information

```pascal
VERSIONID1 = 51000;  // Minimum supported version (5.1.0)
VERSIONID2 = 52004;  // Current version (5.2.4)
```

### File Names

```pascal
INIFILE = 'epaswmm5.ini';        // Configuration file
HLPFILE = 'UserGuide.chm';       // Help file
BASICTUTORFILE = 'BasicTutorial.chm';
INLETSTUTORFILE = 'InletsTutorial.chm';
```

### Maximum Limits

```pascal
MAXINTERVALS = 4;   // Max. color scale interval index
MAXSERIES    = 5;   // Max. graph series index
MAXCOLS      = 10;  // Max. columns in a table
MAXFILTERS   = 10;  // Max. filter conditions for table
MAXQUALPARAMS = 3;  // Max. types of WQ analyses
MAXMRUINDEX   = 9;  // Max. index of Most Recently Used files
```

### Unit Systems

```pascal
TUnitSystem = (usUS, usSI);  // US or SI units

USFlowUnits: array[0..2] = ('CFS', 'GPM', 'MGD');
SIFlowUnits: array[0..2] = ('CMS', 'LPS', 'MLD');
```

### Map Constants

```pascal
MINMAPSIZE = 100;    // Minimum map size
SYMBOLSIZE = 4;      // Node symbol size
PIXTOL = 5;          // Pixel tolerance for selection
```

### Conversion Factors

```pascal
METERSperFOOT     = 0.3048;
FEETperMETER      = 3.281;
ACRESperFOOT2     = 2.2956e-5;
ACRESperMETER2    = 24.71e-5;
HECTARESperMETER2 = 0.0001;
HECTARESperFOOT2  = 0.92903e-5;
```

### Special Values

```pascal
FLOWTOL = 0.005;        // Zero flow tolerance
MISSING = -1.0e10;      // Missing/undefined value
NOXY = -9999999;        // Missing coordinate
```

---

## Building the Project

### Prerequisites

1. **Embarcadero Delphi 10.4** (or compatible version)
2. **EPA Custom Components** installed (see below)
3. **Windows SDK** (for Win32/Win64 compilation)

### Installing EPA Custom Components

Follow these steps (from `Components/Installation.txt`):

1. **Unzip** the Components folder to a directory (e.g., `C:\Delphi\Components\Epa`)

2. **Open** `Epa.dproj` in Delphi

3. **Build 32-bit version:**
   - Select "Windows 32-bit" as Target Platform
   - Set Package output directory to `Win32\`
   - Set Unit output directory to `Win32\`
   - Build the package (Project > Build Epa)

4. **Build 64-bit version:**
   - Select "Windows 64-bit" as Target Platform
   - Set Package output directory to `Win64\`
   - Set Unit output directory to `Win64\`
   - Build the package

5. **Install the package:**
   - Component > Install Packages
   - Add > Navigate to `Epa\Win32\epa.bpl`
   - OK to complete installation

6. **Configure Library Paths:**
   - Tools > Options > Language > Delphi > Library
   - For "Windows 32-bit": Add EPA components folder to Library Path
   - For "Windows 64-bit": Add EPA components folder to Library Path

### Building the Main Application

1. Open `Epaswmm5\Epaswmm5.dproj` in Delphi

2. Select target platform (Win32 or Win64)

3. Build the project (Project > Build Epaswmm5)

4. The executable will be created in the output directory

### Build Configurations

- **Debug** - Includes debug information, assertions enabled
- **Release** - Optimized, no debug info, smaller executable

### Output Files

After successful build:
- `Epaswmm5.exe` - Main executable
- `*.dcu` - Compiled units
- Required DLLs:
  - `swmm5.dll` - SWMM computation engine (not included in GUI source)

---

## Integration with SWMM Engine

### SWMM DLL Interface (swmm5.pas)

The GUI communicates with the SWMM computational engine through a DLL interface:

```pascal
// Core functions
function swmm_run(F1, F2, F3: PAnsiChar): Integer; stdcall;
function swmm_open(F1, F2, F3: PAnsiChar): Integer; stdcall;
function swmm_start(SaveFlag: Integer): Integer; stdcall;
function swmm_step(var ElapsedTime: Double): Integer; stdcall;
function swmm_end: Integer; stdcall;
function swmm_report: Integer; stdcall;
function swmm_close: Integer; stdcall;
function swmm_getVersion: Integer; stdcall;
function swmm_getError(ErrMsg: PAnsiChar; MsgLen: Integer): Integer; stdcall;
function swmm_getWarnings: Integer; stdcall;
function swmm_getMassBalErr(var Erunoff, Eflow, Equal: Single): Integer; stdcall;
```

### Simulation Workflow

1. **Preparation:**
   - GUI generates `.inp` file from project data
   - User initiates simulation

2. **Execution:**
   - `swmm_open()` - Opens input file
   - `swmm_start()` - Initializes simulation
   - Loop: `swmm_step()` - Advances simulation time step
   - GUI updates progress and can animate results
   - `swmm_end()` - Completes simulation
   - `swmm_report()` - Generates text report
   - `swmm_close()` - Closes files

3. **Results Processing:**
   - GUI reads binary `.out` file
   - Extracts time series data
   - Generates visualizations

### File Parameters

| Parameter | Description |
|-----------|-------------|
| F1 | Input file name (.inp) |
| F2 | Report file name (.rpt) |
| F3 | Binary output file name (.out) |

---

## Coding Conventions

### Naming Conventions

**Classes:**
- Prefix with `T`
- PascalCase
- Examples: `TProject`, `TMainForm`, `TNumEdit`

**Variables:**
- PascalCase for global/published
- camelCase for local
- Examples: `MainForm`, `selectedNode`, `i`

**Constants:**
- ALL_CAPS for global constants
- PascalCase for typed constants
- Examples: `MAXCLASS`, `DefJunction`

**Procedures/Functions:**
- PascalCase
- Descriptive verb-noun pairs
- Examples: `GetNodeID()`, `ValidateInput()`, `DrawMap()`

**Form Components:**
- Descriptive names with type suffix
- Examples: `OKBtn`, `CancelBtn`, `NameEdit`, `TypeCombo`

### Code Organization

**Unit Structure:**
```pascal
unit UnitName;

interface

uses
  // Standard units
  Windows, SysUtils, Classes,
  // VCL units
  Forms, Controls, Dialogs,
  // Project units
  Uglobals, Uproject;

const
  // Constants

type
  // Type declarations

var
  // Global variables

// Function declarations

implementation

// Implementation of functions

initialization
  // Initialization code

finalization
  // Cleanup code

end.
```

### Comments

- Use `//` for single-line comments
- Use `{ }` or `(* *)` for multi-line comments
- File headers use structured format:
```pascal
{-------------------------------------------------------------------}
{                    Unit:    UnitName.pas                          }
{                    Project: EPA SWMM                              }
{                    Version: 5.2                                   }
{                    Date:    MM/DD/YY    (5.2.X)                   }
{                    Author:  L. Rossman                            }
{                                                                   }
{   Description of unit purpose                                     }
{-------------------------------------------------------------------}
```

### Property Definitions

Properties are defined using TPropRecord arrays:

```pascal
PropertyProps: array[0..N] of TPropRecord =
  ((Name: 'PropertyName';
    Style: esEdit;           // Edit style
    Mask: emNumber;          // Input mask
    Length: 0;               // Max length (0=default)
    List: ''),               // List items (for combos)
   ...
  );
```

### Error Handling

- Use try-finally for resource cleanup
- Use try-except for error handling
- Display user-friendly error messages
- Log errors when appropriate

### String Handling

- Use `String` type (Unicode in modern Delphi)
- Use `PAnsiChar` for DLL interfaces
- Convert between string types as needed
- Resource strings for localizable text

---

## Best Practices for Development

### When Adding New Features

1. **Object Types:**
   - Add constant to Uproject.pas
   - Define property indices
   - Create property record array
   - Implement default values
   - Update import/export routines

2. **Dialog Forms:**
   - Follow naming convention (D prefix)
   - Implement property validation
   - Use standard button layout (OK/Cancel)
   - Handle ESC/Enter keys appropriately

3. **Map Objects:**
   - Update drawing routines in Umap.pas
   - Add selection handling
   - Implement property editor interface
   - Update coordinate management

4. **View Variables:**
   - Add to viewvars.txt
   - Update legend generation
   - Implement data retrieval
   - Add units and formatting

### Code Quality Guidelines

1. **Keep functions focused** - Single responsibility principle
2. **Avoid deep nesting** - Extract methods when needed
3. **Use meaningful names** - Self-documenting code
4. **Comment complex logic** - Explain why, not what
5. **Validate inputs** - Check bounds and types
6. **Handle edge cases** - Empty lists, nil pointers, etc.
7. **Test thoroughly** - Unit tests, integration tests
8. **Follow existing patterns** - Consistency matters

### Performance Considerations

1. **Map Drawing:**
   - Use double-buffering to prevent flicker
   - Implement view frustum culling for large models
   - Cache computed values

2. **Data Access:**
   - Use TStringList for fast lookups
   - Cache frequently accessed data
   - Minimize file I/O

3. **Memory Management:**
   - Free objects in reverse creation order
   - Use try-finally blocks
   - Avoid memory leaks with proper cleanup

### UI/UX Guidelines

1. **Consistency:**
   - Follow Windows UI conventions
   - Use standard keyboard shortcuts
   - Maintain consistent button placement

2. **Feedback:**
   - Show progress for long operations
   - Provide status bar updates
   - Use appropriate cursors

3. **Validation:**
   - Validate on data entry
   - Provide clear error messages
   - Prevent invalid states

---

## Key Data Structures

### TProject

Central data repository for the model:

```pascal
TProject = class(TObject)
  Lists: array[0..MAXCLASS] of TStringList;  // Object collections
  CurrentItem: array[0..MAXCLASS] of Integer; // Current selection
  Title: String;
  Notes: TStringList;
  FileName: String;
  HasChanged: Boolean;
  // ... methods
end;
```

### Node/Link Objects

Base classes for network elements:

```pascal
TNode = class(TObject)
  ID: String;
  X, Y: Extended;         // Map coordinates
  Zindex: Integer;        // Layer index
  Data: array of String;  // Property values
end;

TLink = class(TObject)
  ID: String;
  Node1, Node2: TNode;    // Endpoints
  Vlist: TVertexList;     // Intermediate vertices
  Data: array of String;  // Property values
end;
```

### Map Data Structures

```pascal
TMapExtent = record
  X1, Y1: Extended;  // Lower-left
  X2, Y2: Extended;  // Upper-right
end;

TMapOptions = record
  ShowGages: Boolean;
  ShowSubcatchments: Boolean;
  ShowNodes: Boolean;
  ShowLinks: Boolean;
  ShowLabels: Boolean;
  // ... more options
end;
```

---

## Integration Points

### File I/O

**Input File (.inp):**
- Text format
- Section-based structure
- Generated by `Uexport.pas`
- Parsed by `Uimport.pas`

**Output File (.out):**
- Binary format
- Handled by `Uoutput.pas`
- Contains time series results
- Random access for efficiency

**Map File (.map):**
- Backdrop configuration
- Coordinate system
- View settings

### External Tools

**DXF Import/Export:**
- `Udxf.pas` handles AutoCAD DXF files
- Import network geometry
- Export map for external editing

**Calibration Data:**
- `Ucalib.pas` manages observed data
- Comparison with simulation results
- Statistical analysis

---

## Appendix: File Categories

### Forms (F* prefix) - 17 files
Core visual windows

### Dialogs (D* prefix) - 62 files
Dialog boxes for data entry and configuration

### Utilities (U* prefix) - 26 files
Core functionality without visual components

### Components (Components folder) - 5 files
Custom Delphi components

### Frames - 3 files
Reusable visual components

### Configuration - 2 files
objprops.txt, viewvars.txt

### Resources - Multiple .res, .ico files
Icons, cursors, and other binary resources

---

## Additional Notes

### Thread Safety
- Simulation runs in separate thread
- UI updates via message passing
- Synchronization for shared data

### Localization
- String constants defined for easy translation
- Resource strings supported
- Date/time formatting respects locale

### Extensibility
- Plugin architecture for custom tools
- Custom property editor types
- Extensible file format

### Documentation References

For detailed algorithm information, consult:
- SWMM User's Manual (UserGuide.chm)
- SWMM Reference Manual (EPA documentation)
- SWMM 5 Code Documentation (C source code)

---

## Summary

This document provides a comprehensive reference for understanding and working with the EPA SWMM 5.2.4 GUI codebase. The application is a sophisticated MDI-based Delphi application that provides a complete graphical interface for stormwater modeling. Key areas of focus include:

1. **MDI Architecture** with multiple specialized child forms
2. **Data Model** based on the TProject class managing multiple object types
3. **Property Editor Framework** for flexible data entry
4. **Map System** for visual model building and display
5. **DLL Interface** to the SWMM computational engine
6. **Comprehensive I/O** for various file formats

When extending or modifying this codebase, follow the established patterns, maintain consistency with naming conventions, and ensure proper integration with the existing architecture.

---

**Document Version:** 1.0
**Created:** Based on SWMM 5.2.4 GUI source code analysis
**For Use With:** AI/LLM-assisted development and code understanding

