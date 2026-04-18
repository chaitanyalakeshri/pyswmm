
**B.5** **Flow Divider Properties **

*Name * User-assigned divider name.

*X-Coordinate * Horizontal location of the divider on the Study Area Map. If left blank then the divider will not appear on the map.

*Y-Coordinate * Vertical location of the divider on the Study Area Map. If left blank then the divider will not appear on the map.

*Description * Click the ellipsis button (or press Enter) to edit an optional description of the divider.

*Tag * Optional label used to categorize or classify the divider.

*Inflows * Click the ellipsis button (or press Enter) to assign external direct, dry weather or RDII inflows to the divider.

*Treatment * Click the ellipsis button (or press Enter) to edit a set of treatment functions for pollutants entering the node.

*Invert El. * Invert elevation of the divider (feet or meters).

*Max. Depth * Maximum depth of divider (i.e., from ground surface to invert) (feet or meters). See description for *Junctions*.

*Initial Depth * Depth of water at the divider at the start of the simulation (feet or meters).

*Surcharge Depth * Additional depth of water beyond the maximum depth that the divider can sustain before overflowing (feet or meters).

*Ponded Area * Area occupied by ponded water atop the junction after flooding occurs (sq. feet or sq. meters). See description for *Junctions*.

*Diverted Link * Name of link which receives the diverted flow.

*Type * Type of flow divider. Choices are:

***CUTOFF*** (diverts all inflow above a defined cutoff value),

***OVERFLOW ***(diverts all inflow above the flow capacity of the non- diverted link),

***TABULAR*** (uses a Diversion Curve to express diverted flow as a function of the total inflow),

***WEIR*** (uses a weir equation to compute diverted flow).

***CUTOFF*** ***DIVIDER***

*- Cutoff Flow * Cutoff flow value used for a ***CUTOFF*** divider (flow units).

***TABULAR*** ***DIVIDER***

*- Curve Name * Name of Diversion Curve for a ***TABULAR*** divider (double-click to edit).


***WEIR DIVIDER***

* - Min. Flow * Minimum flow at which diversion begins for a ***WEIR*** divider (flow units).

* - Max. Depth * Vertical height of ***WEIR*** opening (feet or meters)

* - Coefficient * Product of ***WEIR***'s discharge coefficient and its length. Weir coefficients are typically in the range of 2.65 to 3.10 per foot, for flows in CFS.

**Note:**  Flow dividers are operational only for Steady Flow and Kinematic Wave flow routing. For Dynamic Wave flow routing they behave as Junction nodes.