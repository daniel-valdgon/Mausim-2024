/*==============================================================================*\
 West Africa - Simulation Tool
 Authors: Madi Mangan, Gabriel Lombo, Daniel Valderrama, Andrés Gallegos
 Start Date: November 2024
 Update Date: 
\*==============================================================================*/
   
	*******************************************************************
	***** GLOBAL PATHS ************************************************
	
clear all
macro drop _all

* Gabriel - Personal Computer
if "`c(username)'"=="gabriellombomoreno" {
	
	global country 		"MRT"
	
	global pathdata     "/Users/gabriellombomoreno/Documents/WorldBank/Data/DATA_MRT/MRT_2019_EPCV/Data/STATA/1_raw"	
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 AFW Fiscal Incidence Analysis"

}

	* Data
	global presim       "${path}/01-Data/2_pre_sim/${country}"
	global tempsim      "${path}/01-Data/3_temp_sim"
	global data_out    	"${path}/01-Data/4_sim_output"

	* Scripts
	global thedo     	"${path}/02-Scripts/`c(username)'/1-Fiscal-Model"		
	global theado       "$thedo/ado"
	global thedo_pre    "${path}/02-Scripts/`c(username)'/0-Standardize-Data/${country}"
	
	* Tool
	global tool         "${path}/03-Output/`c(username)'/Tool" 	
	
	global xls_sn		"${tool}/Inputs/SN_Sim_tool_VI_${country}_ref.xlsx"
	global xls_out		"${tool}/SN_Sim_tool_VI.xlsx"

	scalar t1 = c(current_time)
	
// Global about the type of simulation.
global devmode = 1  			// Indicates if we run a developers mode of the tool.
								// In the developers mode all the data is being saved 
								// in .dta files in the subfolders in 3_temp_sim 
global asserts_ref2018 = 0
						
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
	
*******************************************************************
//-Run do-files to the VAT simulation. // 
	
use "$presim/01_menages.dta", clear

keep hhid 	

save "${tempsim}/social_security_contribs.dta", replace

*-------------------------------------
// 1. Pull Macros
*-------------------------------------

qui: include  "$thedo/01. Pullglobals.do"

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

*===============================================================================
// Scope
*===============================================================================

global all_data 	"01_menages 02_Income_tax_input 05_netteddown_expenses_SY 05_purchases_hhid_codpr 07_dir_trans_PMT 07_educ 08_subsidies_elect 08_subsidies_fuel 08_subsidies_agric IO_Matrix IO_percentage" // Names of data
global n 			11
global data 		"${path}/01-Cleaned_data/2_pre_sim/${country}" 
global sheet		"PresimData"

* Variables
forvalues i=1/$n {
	
	* First parameters
	global var : word `i' of $all_data

	* Read data
	use "${data}/${var}.dta", clear

	* Variables description
	describe, replace

	keep name type varlab

	gen process = "$sheet"
	gen data = "$var"
	order process data, first
		
	save "${data}/lab_${var}.dta", replace 
} 
	
	* Append data
	global var : word 1 of $all_data
	use "${data}/lab_${var}.dta", clear
	erase "${data}/lab_${var}.dta"

	if ($n > 1) {
		forvalues i=2/$n {	
			global var : word `i' of $all_data
			append using  "${data}/lab_${var}"
			erase "${data}/lab_${var}.dta"
		}
	}
	
export excel using "$xls_out", sheet("DT_${scenario_name_save}") sheetreplace first(variable) locale(C)  nolabel
*/	
	

	
	
	
	
	
	