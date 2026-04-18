# Chapter 7 — Working with the Map

## What This Folder Contains
All map visualization and navigation features: controlling layer visibility, applying color-coded themes, setting map dimensions, using backdrop images, measuring distances, zooming/panning, finding objects, running map queries, using legends, using the Overview Map, customizing display options, and exporting the map.

## Files

| File | Description |
|------|-------------|
| `7.1_Viewing_Map_Layers.md` | Toggle visibility of layers (rain gages, subcatchments, nodes, links, labels, backdrop) via View > Layers or right-click context menus. |
| `7.2_Selecting_a_Map_Theme.md` | Apply color-coded themes to subcatchments, nodes, or links showing any parameter value. Select via Map Browser dropdown; colors update as time period changes. |
| `7.3_Setting_the_Maps_Dimensions.md` | Set physical map dimensions: enter corner coordinates, or use Auto-Size; select distance units; optionally recompute conduit lengths and subcatchment areas from new dimensions. |
| `7.4_Utilizing_a_Backdrop_Image.md` | Load backdrop images (street maps, topographic maps, site plans) in metafile, bitmap, JPEG, or PNG format. Align, resize, watermark; use world coordinate files (.wld) for geo-referencing. |
| `7.5_Measuring_Distances.md` | Measure distances by clicking points; right-click or Enter to finish; auto-calculates polygon area for closed shapes. Results in project units. |
| `7.6_Zooming_the_Map.md` | Zoom in (100% or custom rectangle selection), zoom out; mouse wheel zooming; zoom controls via View > Zoom or toolbar. |
| `7.7_Panning_the_Map.md` | Pan by dragging with left mouse button held; also via Overview Map drag or mouse wheel pan. |
| `7.8_Viewing_at_Full_Extent.md` | View entire study area at once: View > Full Extent or toolbar button. |
| `7.9_Finding_an_Object.md` | Map Finder dialog (View > Find Object): search by object type and name; case-insensitive; highlights found object; lists connections. |
| `7.10_Submitting_a_Map_Query.md` | Query map for objects meeting criteria (e.g., flooded nodes, links with velocity < threshold, objects with LID controls, external inflows); results update automatically with time period changes. |
| `7.11_Using_the_Map_Legends.md` | Color legends associating ranges with parameter values; Legend Editor dialog: auto-scale, color ramps, reverse colors; move legends by dragging. |
| `7.12_Using_the_Overview_Map.md` | Overview Map window shows full system with rectangle indicating current zoom area; drag rectangle to navigate; toggle display; resize window. |
| `7.13_Setting_Map_Display_Options.md` | Map Options dialog (Tools > Map Display Options): subcatchment fill styles, node/link sizing (fixed or proportional to values), labels, annotations, symbols, flow direction arrows, background color. |
| `7.14_Exporting_the_Map.md` | Export as DXF (CAD), enhanced metafile (EMF), or ASCII text (.map) via File > Export > Map. Annotation not exported; map labels are exported. |

## Key Terms & Concepts
- **Map layers**: rain gages, subcatchments, nodes, links, labels, backdrop image
- **Map themes**: color-code any parameter (depth, flow, velocity, concentration, etc.)
- **Backdrop image**: metafile (.wmf/.emf), bitmap (.bmp), JPEG (.jpg), PNG (.png); world file (.wld) for geo-referencing
- **Map query**: criterion-based object identification (any simulated parameter vs. threshold)
- **Legend Editor**: color ramps, auto-scaling, custom color/value ranges
- **Overview Map**: navigation aid showing zoom context
- **Display options**: subcatchment fill, node/link proportional sizing, flow arrows, annotations
- **Export formats**: DXF (AutoCAD), EMF (vector metafile), ASCII .map (text)
- **Distance measurement**: single line or polygon area

## Typical Queries This Folder Answers
- How do I show/hide the backdrop image?
- How do I color-code the map to show which nodes are flooding?
- How do I load a Google Maps export or site plan as a backdrop?
- How do I use a world coordinate file to georeference my backdrop?
- How do I measure the length of a drainage path on the map?
- How do I find a specific junction named "MH-42"?
- How do I query the map for all links where velocity is below 2 ft/s?
- How do I customize the legend color ranges?
- How do I export the map to AutoCAD DXF format?
- How do I make conduit lines thicker or proportional to flow?
- How do I show flow direction arrows?

## Related Sections
- Map Browser (themes, animation) → `chapter_04_swmms_main_window/4.8_Map_Browser.md`
- Map visualization of results → `chapter_09_viewing_results/9.4_Viewing_Results_on_the_Map.md`
- Printing the map → `chapter_10_printing_and_copying/10.4_Printing_the_Current_View.md`
