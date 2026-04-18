# Chapter 6 — Working with Objects

## What This Folder Contains
Practical guide for all object manipulation operations in SWMM: the taxonomy of object types, how to add/draw each type, select and move them, edit properties, convert between types, copy/paste properties, reshape links and subcatchments, delete objects, and perform group operations.

## Files

| File | Description |
|------|-------------|
| `6.1_Types_of_Objects.md` | Complete SWMM object taxonomy. Physical (visual): Nodes (Junction, Outfall, Flow Divider, Storage Unit), Links (Conduit, Pump, Orifice, Weir, Outlet), Subcatchments, Rain Gages, Transects, Streets, Inlets, Map Labels. Non-physical (data): Project Title/Notes, Simulation Options, Climatology, Aquifers, Control Rules, Snow Packs, Curves, Unit Hydrographs, Time Series, LID Controls, Time Patterns, Pollutants, Land Uses. |
| `6.2_Adding_Objects.md` | How to add each object type: Rain Gages (single click), Subcatchments (polygon vertices, right-click to close), Nodes (single click), Links (drag from upstream to downstream node, intermediate vertices with additional clicks), Map Labels (click and type). Via Project Browser menu or Map Toolbar buttons. |
| `6.3_Selecting_and_Moving_Objects.md` | Select objects via arrow cursor mode on map or by clicking in Project Browser. Move by dragging with left mouse button. Two methods: map drag or drag from Project Browser to map position. |
| `6.4_Editing_Objects.md` | Access Property Editor by double-clicking, right-click > Edit, or menu. Unit system (US/SI) determined by flow unit choice. All properties documented in appendices. |
| `6.5_Converting_an_Object.md` | Convert node types (e.g., Junction → Outfall) or link types (e.g., Orifice → Weir) without delete/recreate. Preserved for nodes: name, position, description, tag, inflows, treatment, invert elevation. Preserved for links: name, end nodes, description, tag. |
| `6.6_Copying_and_Pasting_Objects.md` | Copy object properties to clipboard (right-click > Copy); paste into same-category objects. Excluded from copy: name, coordinates, end nodes, tag, comments. Map Labels copy only font properties. |
| `6.7_Shaping_and_Reversing_Links.md` | Add vertices (Insert key or right-click), delete vertices (Delete key), move vertices by dragging — all in Vertex Selection mode (arrow-tip cursor). Reverse link direction via right-click menu to ensure upstream end is higher. |
| `6.8_Shaping_a_Subcatchment.md` | Subcatchment polygon editing uses same vertex operations as links. Subcatchments with ≤2 vertices display only as centroid symbol. |
| `6.9_Deleting_an_Object.md` | Delete via: Project Browser delete button, Delete key, Edit menu, or right-click context menu. Deletion confirmation optional (set in Preferences). |
| `6.10_Editing_or_Deleting_a_Group.md` | Select region: draw polygon with Select Region tool. Group Edit: modify common properties with optional Tag filter; operations: Replace / Multiply / Add on numerical properties. Group Delete: select category to delete. |

## Key Terms & Concepts
- **Physical objects**: visible on map (nodes, links, subcatchments, rain gages, labels)
- **Non-physical objects**: data-only (curves, time series, control rules, LID controls, pollutants, etc.)
- **Vertex Selection mode**: cursor changes to arrow-tip for editing link/subcatchment shape
- **Group Edit**: apply Replace/Multiply/Add operation to multiple objects' same property
- **Tag filter**: restrict group operations to objects with a specific tag value
- **Type conversion**: node type ↔ node type; link type ↔ link type (preserves core properties)
- **Copy/paste**: transfers most properties except identifying info (name, coords, tag)

## Typical Queries This Folder Answers
- How do I draw a subcatchment polygon on the map?
- How do I connect a conduit between two nodes?
- How do I add intermediate vertices to a conduit (to make it curved)?
- How do I move a junction node to a new position?
- How do I convert a junction to a storage unit without losing data?
- What properties are preserved when I convert object types?
- How do I copy one conduit's properties to several other conduits?
- How do I reshape a subcatchment boundary?
- How do I reverse a link's direction?
- How do I select all objects in a region and edit them at once?
- How do I filter a group edit to only affect objects with a specific tag?
- How do I add a new time series or curve (non-physical object)?

## Related Sections
- Object property values → `appendix_B_visual_object_properties/`
- Object theory → `chapter_03_swmms_conceptual_model/3.2_Visual_Objects.md`
- GUI overview → `chapter_04_swmms_main_window/`
