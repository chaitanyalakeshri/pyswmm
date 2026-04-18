
**B.7** **Conduit Properties **

*Name * User-assigned conduit name.

*Inlet Node * Name of node on the inlet end of the conduit (normally the end at higher elevation).

*Outlet Node * Name of node on the outlet end of the conduit (normally the end at lower elevation).

*Description * Click the ellipsis button (or press Enter) to edit an optional description of the conduit.

*Tag * Optional label used to categorize or classify the conduit.

*Shape * Click the ellipsis button (or press Enter) to edit the geometric properties of the conduit's cross-section.

*Max. Depth * Maximum depth of the conduit's cross-section (feet or meters).

*Length * Conduit length (feet or meters).

*Roughness * Manning's roughness coefficient (*n*)  (see Section A.7 for closed conduit values or Section A.8 for open channel values).

*Inlet Offset * Depth or elevation of the conduit invert above the node invert at the upstream end of the conduit (feet or meters). See note below.

*Outlet Offset * Depth or elevation of the conduit invert above the node invert at the downstream end of the conduit (feet or meters). See note below.

*Initial Flow * Initial flow in the conduit (flow units).

*Maximum Flow * Maximum flow allowed in the conduit (flow units) – use 0 or leave blank if not applicable.

*Entry Loss Coeff. * Head loss coefficient associated with energy losses at the entrance of the conduit. For culverts, refer to Table A11.

*Exit Loss Coeff. * Head loss coefficient associated with energy losses at the exit of the conduit. For culverts, use a value of 1.0

*Avg. Loss Coeff. * Head loss coefficient associated with energy losses along the length of the conduit.

*Seepage Loss Rate * Rate of seepage loss into surrounding soil (inches or millimeters per hour).

*Flap Gate * ***YES*** if a flap gate exists that prevents backflow through the conduit, or ***NO*** if no flap gate exists.

*Culvert Code * If the conduit is a culvert subject to possible inlet flow control click the ellipsis button (or press Enter) to select a code number for its inlet geometry from those listed in Appendix A10


*Inlets * Click the ellipsis button (or press Enter) to assign a storm drain inlet to a street or open channel conduit.

**NOTE:** Conduits and flow regulators (orifices, weirs, and outlets) can be offset some distance above the invert of their connecting end nodes. There are two different conventions available for specifying the location of these offsets. The Depth convention uses the offset distance from the node’s invert (distance

between  and  in the figure on the right). The Elevation convention uses the absolute elevation of

![Figure](images/img_0334.png)


the offset location (the elevation of point  in the figure). The choice of convention can be made on the Status Bar of SWMM’s main window or on the Node/Link Properties page of the Project Defaults dialog.