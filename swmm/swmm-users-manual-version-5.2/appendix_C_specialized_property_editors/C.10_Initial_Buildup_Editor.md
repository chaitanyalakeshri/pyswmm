
**C.10** **Initial Buildup Editor ** The Initial Buildup Editor is invoked from the Property Editor when editing the Initial Buildup property of a subcatchment. It specifies the amount of pollutant buildup existing over the subcatchment at the start of the simulation.

![Figure](images/img_0364.png)


The editor consists of a data entry grid with two columns. The first column lists the name of each pollutant in the project and the second column contains edit boxes for entering the initial buildup values. If no buildup value is supplied for a pollutant, it is assumed to be 0. The units for buildup are either pounds per acre when US customary units are in use or kilograms per hectare when SI metric units are in use. If a non-zero value is specified for the initial buildup of a pollutant, it will override any initial buildup computed from the Antecedent Dry Days parameter specified on the Dates page of the Simulation Options dialog.