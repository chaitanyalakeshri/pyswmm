
**B.11** **Outlet Properties**

*Name * User-assigned outlet name.

*Inlet Node * Name of node on inflow side of outlet.

*Outlet Node * Name of node on discharge side of outlet.

*Description * Click the ellipsis button (or press Enter) to edit an optional description of the outlet.

*Tag * Optional label used to categorize or classify the outlet.

*Inlet Offset * Depth or elevation of outlet above inlet node invert (feet or meters – see note below table of Conduit Properties).

*Flap Gate * ***YES*** if the outlet has a flap gate that prevents backflow, ***NO*** otherwise.

*Rating Curve * Method of defining flow (Q) as a function of depth or head (y) across the outlet.

***FUNCTIONAL/DEPTH*** uses a power function (Q = AyB) to describe this

relation where y is the depth of water above the outlet’s opening at the inlet node.

***FUNCTIONAL/HEAD*** uses the same power function except that y is the difference in head across the outlet’s nodes.

***TABULAR/DEPTH*** uses a tabulated curve of flow versus depth of water above the outlet’s opening at the inlet node.

***TABULAR/HEAD*** uses a tabulated curve of flow versus difference in head across the outlet’s nodes.

***FUNCTIONAL *** (used only for a functional rating curve)

*- Coefficient* Coefficient (A) for the functional relationship between depth or head and flow rate.

*- Exponent* Exponent (B) used for the functional relationship between depth or head and flow rate.

***TABULAR *** (used only for a tabular rating curve)

*- Curve Name* Name of Rating Curve containing the relationship between depth or head and flow rate (double-click to edit the curve).