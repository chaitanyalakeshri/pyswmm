
**B.2** **Subcatchment Properties **

*Name * User-assigned subcatchment name.

*X-Coordinate * Horizontal location of the subcatchment's centroid on the Study Area Map. If left blank then the subcatchment will not appear on the map.

*Y-Coordinate * Vertical location of the subcatchment's centroid on the Study Area Map. If left blank then the subcatchment will not appear on the map.

*Description * Click the ellipsis button (or press Enter) to edit an optional description of the subcatchment.

*Tag * Optional label used to categorize or classify the subcatchment.

*Rain Gage * Name of the rain gage associated with the subcatchment.

*Outlet * Name of the node or subcatchment which receives the subcatchment's runoff.

*Area * Area of the subcatchment, including any LID controls (acres or hectares).

*Width**1 * Characteristic width of the overland flow path for sheet flow runoff (feet or meters).

*% Slope * Average percent slope of the subcatchment.

*% Imperv * Percent of land area (excluding the area used for LID controls) which is impervious.

*N-Imperv * Manning's coefficient (*n*) for overland flow over the impervious portion of the subcatchment (see Section A.6 for typical values).

*N-Perv * Manning's coefficient (*n*) for overland flow over the pervious portion of the subcatchment (see Section A.6 for typical values).

*Dstore-Imperv * Depth of depression storage on the impervious portion of the subcatchment (inches or millimeters) (see Section A.5 for typical values).

*Dstore-Perv * Depth of depression storage on the pervious portion of the subcatchment (inches or millimeters) (see Section A.5 for typical values).

*% Zero-Imperv * Percent of the impervious area with no depression storage.

*Subarea Routing * Choice of internal routing of runoff between pervious and impervious areas:

***IMPERV***: runoff from pervious area flows to impervious area,

***PERV***:  runoff from impervious area flows to pervious area,

***OUTLET***: runoff from both areas flows directly to outlet.


*Percent Routed * Percent of runoff routed between subareas.

*Infiltration Data * Click the ellipsis button (or press Enter) to edit infiltration parameters for the subcatchment.

*Groundwater * Click the ellipsis button (or press Enter) to edit groundwater flow parameters for the subcatchment.

*Snow Pack * Name of snow pack parameter set (if any) assigned to the subcatchment.

*LID Controls * Click the ellipsis button (or press Enter) to edit the use of low impact development controls in the subcatchment.

*Land Uses * Click the ellipsis button (or press Enter) to assign land uses to the subcatchment. Only needed if pollutant buildup/washoff modeled.

*Initial Buildup * Click the ellipsis button (or press Enter) to specify initial quantities of pollutant buildup over the subcatchment.

*Curb Length * Total length of curbs in the subcatchment (any length units). Used only when pollutant buildup is normalized to curb length.

*N-Perv Pattern* Name of optional monthly pattern that adjusts pervious Manning’s *n*.

*Dstore Pattern * Name of optional monthly pattern that adjusts depression storage.

*Infil. Pattern * Name of optional monthly pattern that adjusts infiltration rate.

1 An initial estimate of the characteristic width is given by the subcatchment area divided by the average maximum overland flow length. The maximum overland flow length is the length of the flow path from the furthest drainage point of the subcatchment before the flow becomes channelized. Maximum lengths from several different possible flow paths should be averaged. These paths should reflect slow flow, such as over pervious surfaces, more than rapid flow over pavement, for example. Adjustments should be made to the width parameter to produce good fits to measured runoff hydrographs.