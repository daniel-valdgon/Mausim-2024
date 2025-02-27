/*==============================================================================*\
 West Africa Mini Simulation Tool for indirect taxes (VAT)
 Authors: Madi Mangan, Gabriel Lombo, Daniel Valderrama
 Start Date: January 2024
 Update Date: March 2024
 
\*==============================================================================*/
   
	*******************************************************************
	***** GLOBAL PATHS ************************************************
	
	//Users (change this according to your own folder location)	
	
clear all
macro drop _all


* Gabriel - Personal Computer
if "`c(username)'"=="gabriellombomoreno" {
			
	global pathdata     	"/Users/gabriellombomoreno/Documents/WorldBank/Data/DATA_MRT" 
	global path     		"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 MRT Fiscal Incidence Analysis"
	
	global tool         "${path}/3-Outputs/`c(username)'/Tool" 
	global thedo     	"${path}/2-Scripts/`c(username)'/0-Fiscal-Model"
}

* Other user
if "`c(username)'"=="..." {

	global pathdata     	".../DATA_MRT/MRT_2019_EPCV/Data/STATA/1_raw" 
	global path     		".../01 MRT Fiscal Incidence Analysis"

}

	* Data
	global data_sn 		"${pathdata}/MRT_2019_EPCV/Data/STATA/1_raw"
    global data_other   "${pathdata}/MRT_FIA_OTHER"

	global presim       "${path}/1-Cleaned_data/2_pre_sim"
	global tempsim      "${path}/1-Cleaned_data/3_temp_sim"
	global data_out    	"${path}/1-Cleaned_data/4_sim_output"

	* Tool	
	global xls_sn 		"${tool}/SN_Sim_tool_VI.xlsx"
	global xls_out    	"${tool}/SN_Sim_tool_VI.xlsx"	
	
	* Scripts	
	global theado       "$thedo/ado"
	global thedo_pre    "$thedo/_pre_sim"
	
	scalar t1 = c(current_time)
	
// Global about the type of simulation.
global devmode = 1  			// Indicates if we run a developers mode of the tool.
								// In the developers mode all the data is being saved 
								// in .dta files in the subfolders in 3_temp_sim 
global asserts_ref2018 = 0
global run_presim = 1			// 1 = run presim and simulation, 0 = Run only simulation


	
*===============================================================================
// Run necessary ado files
*===============================================================================

local files : dir "$theado" files "*.ado"
foreach f of local files{
	 qui: cap run "$theado//`f'"
}

*===============================================================================
// Run pre_simulation files (Only run once)
*===============================================================================
{
if $run_presim == 1 {

	
	qui: include "$thedo_pre/01. Pullglobals.do" 
	
	qui: include "$thedo_pre/05. Spend_dta_purchases.do" 

	qui: include "$thedo_pre/01. Social_Security.do" 	

	qui: include "$thedo_pre/02. Income_tax.do" 
	
	qui: include "$thedo_pre/07. PMT.do" 

	qui: include "$thedo_pre/07. Direct_transfer.do" 
	
	qui: include "$thedo_pre/08. Subsidies_elect.do" 
	
	qui: include "$thedo_pre/08. Subsidies_agric.do" 

	qui: include "$thedo_pre/08. Subsidies_fuel.do" 
	
	qui: include "$thedo_pre/09. Inkind Transfers.do" 

	qui: include "$thedo_pre/Consumption_NetDown.do"
	
	noi di "You run the pre simulation do files"
}	

}
	
*******************************************************************
//-Run do-files to the VAT simulation. // 
{
*-------------------------------------
// 1. Pull Macros
*-------------------------------------

qui: include  "$thedo/01. Pullglobals.do"

*-------------------------------------
// 1. Social Security
*-------------------------------------

qui: include "$thedo/01. Social Contributions.do" 

*-------------------------------------
// 2. Direct taxes
*-------------------------------------

qui: include "$thedo/02. Income Tax.do"

*-------------------------------------
// 4. Direct transfers
*-------------------------------------

qui: include "$thedo/04. Direct Transfer.do"

*-------------------------------------
// 6. Subsidies
*-------------------------------------

qui: include "$thedo/06. Subsidies.do"

*-------------------------------------
// 7. Excises
*-------------------------------------

qui: include "$thedo/07. Excise_taxes.do"

*-------------------------------------
// 5. Custom Duties
*-------------------------------------

qui: include "$thedo/08. Custom_duties.do"

*-------------------------------------
// 8. VAT
*-------------------------------------

qui: include "$thedo/08. Indirect_taxes.do"

*-------------------------------------
// 9. Inkind Transfers
*-------------------------------------

qui: include "$thedo/09. InKind_Transfers.do"

*-------------------------------------
// 10. Final income aggregation
*-------------------------------------

qui: include "$thedo/10. Income_Aggregate_cons_based.do"

*-------------------------------------
// 11. Process outputs
*-------------------------------------

qui: include "$thedo/11. Output_scenarios.do"

if "`sce_debug'"=="yes" dis as error  "You have not turned off the debugging phase in ind tax dofile !!!"

*===============================================================================
// Launch Excel
*===============================================================================

shell ! "$xls_out"

scalar t2 = c(current_time)

display "Running the complete tool took " (clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"

}


	
	
	
	
	
	