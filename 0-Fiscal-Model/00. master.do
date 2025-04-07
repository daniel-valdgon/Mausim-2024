/*============================================================================*\
 Simulation Tool - Mauritania
 Authors: Gabriel Lombo, Madi Mangan, Andrés Gallegos, Daniel Valderrama
 Start Date: January 2024
 Update Date: March 2025
\*============================================================================*/
  
clear all
macro drop _all
 
*----- Define your directory path
global path     	".../MauSim_Tool"



*===============================================================================
// Set Up - Parameters
*===============================================================================
*----- Do not modify after this line

if "`c(username)'"=="gabriellombomoreno" {
			
	global pathdata     "/Users/gabriellombomoreno/Documents/WorldBank/Data/DATA_MRT"
	
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 MRT Fiscal Incidence Analysis"
	
}

	*version 18

	* Data
	global data_sn 		"${pathdata}/MRT_2019_EPCV/Data/STATA/1_raw"
    global data_other   "${pathdata}/MRT_FIA_OTHER"

	global presim       "${path}/01-Data/2_pre_sim"
	global tempsim      "${path}/01-Data/3_temp_sim"
	global data_out    	"${path}/01-Data/4_sim_output"

	* Tool	
	*global tool         "${path}/03-Outputs" 
	global tool         "${path}/03-Outputs/`c(username)'/Tool"	// 	  
	global xls_sn 		"${tool}/MRT_Sim_tool_VI.xlsx"
	global xls_out    	"${tool}/MRT_Sim_tool_VI.xlsx"	
	
	* Scripts	
	*global thedo     	"${path}/02-Scripts"		
	global thedo     	"${path}/02-Scripts/`c(username)'/0-Fiscal-Model" // 
	global theado       "$thedo/ado"	
	global thedo_pre    "$thedo/_pre_sim"
	
	scalar t1 = c(current_time)
	
	
	// Global about the type of simulation.
	global devmode = 1  		// Indicates if we run a developers mode of the tool.
								// In the developers mode all the data is being saved 
								// in .dta files in the subfolders in 3_temp_sim 
	global asserts_ref2018 = 0	
	
*===============================================================================
// Isolate Environment
*===============================================================================

sysdir set PLUS "${thedo}/ado"

* Other packages: labutil shp2dta gtools vselect tab_chi ereplace 
local user_commands //Add required user-written commands

foreach command of local user_commands {
	capture which `command'
	if _rc == 111 {
		ssc install `command'
	}
}
	
*===============================================================================
// Run ado files
*===============================================================================

local files : dir "$theado" files "*.ado"
foreach f of local files{
	 qui: cap run "$theado//`f'"
}


*===============================================================================
// Run pre_simulation files (Only run once)
*===============================================================================

if (0) qui: do "${thedo_pre}/00. Master - Presim.do"

*===============================================================================
// Run simulation files
*===============================================================================

*-------------------------------------
// 00. Set up
*-------------------------------------

if (0) qui: do "${thedo}/00a. Dictionary.do"

if (1) qui: do "${thedo}/00b. Pullglobals.do"


*-------------------------------------
// 01. Social Security Contributions
*-------------------------------------

if (1) qui: do "${thedo}/01. Social Security Contributions.do" 

*-------------------------------------
// 02. Direct Taxes
*-------------------------------------

if (1) qui: do "${thedo}/02. Direct Taxes - Income Tax.do" 

*-------------------------------------
// 03. Direct Transfers
*-------------------------------------

if (1) qui: do "${thedo}/03. Direct Transfers.do" 

*-------------------------------------
// 04. Indirect Taxes - Custom Duties
*-------------------------------------

if (1) qui: do "${thedo}/04. Indirect Taxes - Custom Duties.do" 

*-------------------------------------
// 05. Indirect Subsidies
*-------------------------------------

if (1) qui: do "${thedo}/05. Indirect Subsidies.do" 

*-------------------------------------
// 06. Indirect Taxes - Excises 
*-------------------------------------

if (1) qui: do "${thedo}/06. Indirect Taxes - Excises.do"
 
*-------------------------------------
// 06. Indirect Taxes - VAT 
*-------------------------------------
 
 
if (1) qui: do "${thedo}/07. Indirect Taxes - VAT.do" 

*-------------------------------------
// 05. In-Kind Transfers
*-------------------------------------

if (1) qui: do "${thedo}/08. In-Kind Transfers.do" 

*-------------------------------------
// 06. Income Aggregates
*-------------------------------------

if (1) qui: do "${thedo}/09. Income Aggregates.do" 

*-------------------------------------
// 07. Process outputs
*-------------------------------------

if (1) qui: do "${thedo}/10. Outputs - Tool.do" 

if (0) qui: do "${thedo}/10. Outputs - Figures.do" 


if "`sce_debug'"=="yes" dis as error  ///
	"You have not turned off the debugging phase in ind tax dofile !!!"


*===============================================================================
// Launch Excel
*===============================================================================

shell ! "$xls_out"

scalar t2 = c(current_time)

display "Running the complete tool took " ///
	(clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"


* End of do-file
	