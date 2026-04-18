
### Appendix D **COMMAND LINE SWMM **


**D.1** **General Instructions**

EPA SWMM can also be run as a console application from the command line within a DOS window. In this case the study area data are placed into a text file and results are written to a text file. The command line for running SWMM in this fashion is:

runswmm inpfile rptfile outfile

where inpfile is the name of the input file, rptfile is the name of the output report file, and outfile is the name of an optional binary output file. The latter stores all time series results

in a special binary format that will require a separate post-processor program for viewing. If no binary output file name is supplied then all time series results will appear in the report file. As written, the above command assumes that you are working in the directory in which EPA SWMM was installed or that this directory has been added to the PATH variable in your user profile. Otherwise full pathnames for the runswmm executable and the files on the command line must be used.

**D.2** **Input File Format**

The input file for command line SWMM has the same format as the project file used by the Windows version of the program. Figure D-1 illustrates an example SWMM 5 input file. It is organized in sections, where each section begins with a keyword enclosed in brackets. The various section keywords are listed below.

[TITLE] project title [OPTIONS] analysis options

[REPORT] output reporting instructions [FILES] interface file options

[RAINGAGES] rain gage information

[EVAPORATION] evaporation data [TEMPERATURE] air temperature and snow melt data [ADJUSTMENTS] monthly adjustments applied to climate variables