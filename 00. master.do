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

* Madi
if "`c(username)'"=="" {
	global pathdata     "...\OneDrive - WBG\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"
	global path     	"...\OneDrive - WBG\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"
	global thedo     	"${path}/gitrepo/madi"
	
	global country 		"SEN"
	
	* Reading parameters on my country or other countries reference tool
	if ("$country" == "GMB") global xls_sn "${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx"
	else 					 global xls_sn "${path}/03_Tool/policy_inputs/${country}/SN_Sim_tool_VI_${country}_ref.xlsx" 
	
	global xls_out    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx"
}	

* Gabriel - Personal Computer
if "`c(username)'"=="gabriellombomoreno" {
	
	global pathdata     "/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mausim_2024"
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mausim_2024"
	global thedo     	"${path}/02. Scripts"
	global tool         "${path}/03. Tool" 
	
	global country 		"MRT"
	global run_presim 	0		// 1 = run presim

	{
		local tool_gl substr("$path", strrpos("$path", "/")+1, length("$path"))
		if `tool_gl' == "Regional_tool" {
			global xls_sn 		"${tool}/policy_inputs/${country}/SN_Sim_tool_VI_${country}_ref.xlsx"
			global xls_out    	"${tool}/SN_Sim_tool_VI_`c(username)'.xlsx"	
		} 
		if `tool_gl' == "Mausim_2024"{
			global xls_sn    	"${tool}/SN_Sim_tool_VI_`c(username)'.xlsx"	
			global xls_out    	"${tool}/SN_Sim_tool_VI_`c(username)'.xlsx"	
		}
	}
}

* Andres
if "`c(username)'"=="andre" {
	global pathdata     "C:/Users/andre/Dropbox/Energy_Reform/vat_tool"
	global path     	"C:/Users/andre/Dropbox/Energy_Reform/vat_tool"
	*global thedo     	"${path}/gitrepo\andres"
	global country 		"MRT"
	global scenario_name_save2 "V1_${country}_Sub_Ref76"
	global xls_sn 		"${path}/03_Tool/policy_inputs/${country}/SN_Sim_tool_VI_${country}_ref.xlsx"
	global xls_out    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx"	
}

* Andres - Personal Computer
if "`c(username)'"=="andre" {
	global pathdata     "C:/Users/andre/Dropbox/Energy_Reform/vat_tool"
	global path     	"C:/Users/andre/Dropbox/Energy_Reform/vat_tool"
	global thedo     	"${path}/02_scripts"
}

* Daniel
if "`c(username)'"=="wb419055" {
	
	global country "MRT" 	// leave the country global within your username
	global hh_coverage	1 // 1: 44% coverage, 2: 76% Coverage

	//Project folder 
	global path     	"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024"
	
	// Data folder when using data from an external library (not often in West Africa tool}
	global pathdata     "C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024" 
	
	// Personal folder with do-file 
	global thedo     	"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024/00_gitrepo\wb419055"
	
	// Output files @Gabriel why not part of the tool (Also let's move them to be in the same excel file style) 
	global xls_sn    	"${path}/03_Tool/policy_inputs/${country}/SN_Sim_tool_VI_${country}_ref.xlsx" // excel file with policy inputs 
	global xls_out    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" // excel file with outputs

}
	
	global data_sn 		"${path}/01. Data/1_raw/${country}"    
	global presim       "${path}/01. Data/2_pre_sim/${country}"
	global tempsim      "${path}/01. Data/3_temp_sim"
	global data_out    	"${path}/01. Data/4_sim_output"

	global tool         "${path}/03. Tool" 
	
	global theado       "$thedo/ado"
	global thedo_pre    "$thedo/_pre_sim/${country}"
	
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

gab

*===============================================================================
// Run pre_simulation files (Only run once)
*===============================================================================

if ("$country" == "MRT" & $run_presim == 1) {

	
	qui: include "$thedo_pre/01. Pullglobals.do" 
	
	qui: include "$thedo_pre/02. Income_tax.do" 
	
	qui: include "$thedo_pre/05. Spend_dta_purchases.do" 
	
	qui: include "$thedo_pre/07. PMT.do" 

	qui: include "$thedo_pre/07. Direct_transfer.do" 
	
	qui: include "$thedo_pre/08. Subsidies_elect.do" 
	
	qui: include "$thedo_pre/Consumption_NetDown.do"
	
	noi di "You run the pre simulation do files"
}

	*******************************************************************
	//-Creating the other necessary variables to run do-files 10 & 11. // 
	
	use  "$presim/01_menages.dta", replace 
 
	keep hhid
 
	// 03. Social security contribution
	preserve
		 foreach var in csh_css csp_fnr csp_ipr csh_ipm {
			gen `var'=0
		 } 
		 save "$tempsim/social_security_contribs.dta", replace
	restore
	
	 // 09. Transfers InKind
	preserve
		foreach var in am_sante Sante_inKind am_pre_school_pub am_primary_pub am_secondary_pub am_tertiary_pub education_inKind{
			gen `var'=0
		}
		save "${tempsim}/Transfers_InKind" , replace 
	restore
		
	
*******************************************************************
//-Run do-files to the VAT simulation. // 
	
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




	
	
	
	
	
	