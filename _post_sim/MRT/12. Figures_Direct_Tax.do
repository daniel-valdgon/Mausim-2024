/*=============================================================================

	Project:		Direct Transfers - Figures Scenarios
	Author:			Gabriel 
	Creation Date:	June 26, 2024
	Modified:		
	
	Section: 		1. Validation
					4. Absolute and Relative Incidence
					5. Marginal Contributions
					6. Poverty difference

	Note: 
	
==============================================================================*/

clear all
macro drop _all

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mauritania/Mausim_2024"
	global path_out		"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mauritania/Mausim_2024"
	
	global thedo     	"${path}/02_scripts"

	global xls_out    	"${path_out}/Figures_MRT.xlsx"
	global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
	
	global numscenarios	1

	global proj_1		"" 

	global policy		"am_BNSF1 am_BNSF2 am_Cantine am_elmaouna"

}

	global data_sn 		"${path}/01_data/1_raw/MRT"    
	global presim       "${path}/01_data/2_pre_sim/MRT"
	global data_out    	"${path}/01_data/4_sim_output"
	global theado       "$thedo/ado"
	

*===============================================================================
// Run necessary ado files
*===============================================================================

cap run "$theado//_ebin.ado"
	
/*-------------------------------------------------------/
	1. Validation
/-------------------------------------------------------*/

	
use "$data_sn/Datain/individus_2019.dta", clear
		
ren hid hhid
	
merge m:1 hhid using "$presim/01_menages.dta", nogen keep(3) keepusing(hhweight hhsize)

gen uno = 1

gen employee = inrange(E10, 1, 4)

* Wages

tab1 E10 [iw = hhweight]
tab1 E13* [iw = hhweight] if E10 == 7, m

// E20B, E19, E2

tab1 E2A E2B E2C E2D E2E E2F E2G E2H E2I E2J [iw = hhweight]

tab E20B [iw = hhweight] if E2A == 1

tab E15 [iw = hhweight]  if E2A == 1

* Patron: IBAPP, all in regime 3, flat rate 
* Assumption: Mensual revenue corresponds to sales?
* How to annualize the data?
tabstat E20A2 if E10 == 7 [aw = hhweight], s(count mean max) by(E15)

tab1 E10 [iw = hhweight], m
















