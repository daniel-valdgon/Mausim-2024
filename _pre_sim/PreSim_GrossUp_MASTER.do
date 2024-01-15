/*==============================================================================
 Senegal Master Simulation Tool
 Author: Julieth Pico, Juan Pablo Baquero and Daniel VAlderrama
 Date: June 2020
 Version: 1.0

Update Aug-Dec 2022

Modified August 17: 
	* Combine the three RGU in one excel file, changes time of execution from 91-103 segs to 50 segs 
	* Use tempfiles rather than preserve restore when loading the same excel sheet multiple times
	* Add the reference policy parameters
	Current tool time =119.12

Note: The surveys took place in two waves (Sept-Dec 2018 and Apr-July 2019), each covering half of the sample.

Pendent: 
	1. Create a reference scenario and users scenario (The ideals is that reference reads from a differente set of sheets). Line 24 dofile 01
		Details: This tool has not reference scenario because it was designed to include several baselines scenarios for VAT. Still scenarios can include changes not related to VAT and therefore one should be able to save them with a different name, not related to the VAT scenario. THis is something that needs to be changed

*========================================================================================*/

qui{
noi dis "{hi: {c TLC}{dup 57:{c -}}{c TRC}}"
noi dis "{hi: {c |} If you are reading this, the pre-simulation is running! {c |}}"
noi dis "{hi: {c |} This should be done just once.                          {c |}}"
noi dis "{hi: {c BLC}{dup 57:{c -}}{c BRC}}"
}


set type double, permanently

//User 	
if "`c(username)'"=="WB419055" {
	global path     	"C:\Users\WB419055\OneDrive - WBG\SenSim Tool\Senegal_tool\Senegal_tool"
	global data_sn     	= "$path/01. Data/1_raw"
	global data_dev    	= "$path/01. Data"
}

//User 	
if "`c(username)'"=="andre" {
	global path     	"C:\Users\andre\Dropbox\Energy_Reform\Senegal_tool"
	global data_sn     = "$path/01. Data/1_raw"
	global data_dev    	= "$path/01. Data"
}

//dta paths	
global presim     	"$data_dev/2_pre_sim"
global tempsim      "$data_dev/3_temp_sim"
global data_out    	"$data_dev/4_sim_output"

//code and excel 
*_SN_Sim_tool_V_high
*_SN_Sim_tool_V_low
*_SN_Sim_tool_V_baseline_psia


*BE SURE TO LOAD THE PARAMETERS FROM REF_2018
global xls_sn       "$path/03. Tool/SN_Sim_tool_VI_Eduard_test.xlsx" //
global thedo        "$path/02. Dofile" 
global theado       "$thedo/ado" 
global thedo_pre    "$thedo/_pre_sim" 


// Global about the type of simulation.
global devmode = 1  	// Indicates if we run a developers mode of the tool.
						// In the developers mode all the data is being saved 
						//  in .dta files in the subfolders in 3_temp_sim 

*===============================================================================
//------------------------------------------------------------------------------
// DO NOT MODIFY BEYOND THIS POINT
//------------------------------------------------------------------------------
*===============================================================================

scalar t1 = c(current_time)

*===============================================================================
// Run necessary ado files
*===============================================================================

local files : dir "$theado" files "*.ado"
foreach f of local files{
	cap run "$theado\\`f'"
}

*===============================================================================
// Run pre_simulation files (Only run once)
*===============================================================================

global new_behavioral="No" // this is a temporal application to switch between new and old behavioral effects 

include "$thedo_pre/run_pre_sim.do"

*THE POLICY CALCULATIONS AND EVERYTHING SHOULD BE EXACTLY THE SAME AS USING THE MAIN TOOL, SO
*INSTEAD OF COPYING EVERY DO FILE IN _GROSS_UP, I WILL USE THE MAIN DO FILES DIRECTLY. 

*===============================================================================
// 0. Pull Macros
*===============================================================================

*qui: include  "$thedo/_gross_up/01. Pullglobals GU.do"
qui: include  "$thedo/01. Pullglobals.do"
// this should be exactly the same as the main file 

import excel "$xls_sn", sheet("IO_percentage3") firstrow clear
save "$data_sn/IO_percentage3.dta", replace

*-------------------------------------
// 1. Income Tax 
*-------------------------------------

*qui: include "$thedo/_gross_up/02. Income Tax GU.do"
qui: include  "$thedo/02. Income Tax.do"
// this should be exactly the same as the main file, except for the name of the file that is created at the end

*-------------------------------------
// 2. Social Security Contributions
*-------------------------------------

*qui: include "$thedo/_gross_up/03. SocialSecurityContributions GU.do"
qui: include "$thedo/03. SocialSecurityContributions.do"
// this should be exactly the same as the main file, except for the name of the file that is created at the end

*-------------------------------------
// 4. Transfers and social programs
*-------------------------------------

*qui: include "$thedo/_gross_up/07. Direct_transfers GU.do"
qui: include "$thedo/04. Direct_transfers.do"

*-------------------------------------
// 7. Final income aggregation
*-------------------------------------

foreach filename in income_tax_collapse social_security_contribs Direct_transfers{
	use "${tempsim}/`filename'.dta" , clear
	save "${tempsim}/`filename'_GU.dta" , replace
}

*THIS IS DIFFERENT FROM THE MAIN ONE. KEEP THE GU
qui: include "$thedo/_pre_sim/10_Income_Aggregate GU.do"


*===============================================================================
// Launch Excel
*===============================================================================

shell ! "$xls_sn"




scalar t2 = c(current_time)
display "Running the complete tool for gross-up took " (clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"