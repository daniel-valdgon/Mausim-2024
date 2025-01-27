/*==============================================================================

	Project:		Ciustom Duties - Tables and Figures
	Author:			Gabriel 
	Creation Date:	
	Modified:		
	
	Note:			
==============================================================================*/

clear all
macro drop _all

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mausim_2024"
	global report 		"${path}/04. Reports/4. Indirect Taxes/2. Presentation/Figures"
	
	global thedo     	"${path}/02. Scripts"

	global xls_out    	"${report}/Figures12_Indirect_Taxes.xlsx"
	global xls_sn    	"${path}/03. Tool/SN_Sim_tool_VI_`c(username)'.xlsx"
	global mapping		"${path}/03. Tool/Mapping.xlsx"
	
	global numscenarios	1
	global proj_1		"Ref_MRT_2019" 
	global proj_2		"v1_MRT_NoExemp"  
	global proj_3		"v1_MRT_NoExempBut" 
	global proj_4		"v1_MRT_NoExemp_CM"  
	global proj_5		"v1_MRT_NoExBut_CM"  

	
	global country		"MRT"
}

	global policy		"Tax_TVA TVA_direct TVA_indirect"
	
	global data_sn 		"${path}/01. Data/1_raw/MRT"    
	global presim       "${path}/01. Data/2_pre_sim/MRT"
	global tempsim      "${path}/01. Data/3_temp_sim"
	global data_out    	"${path}/01. Data/4_sim_output"

	global theado       "$thedo/ado"
	
*===============================================================================
// Run necessary ado files
*===============================================================================

cap run "$theado//_ebin.ado"
	
/*-------------------------------------------------------/
	1. Motivation: Informality results
/-------------------------------------------------------*/

*----- 1. Rates custom duties
import excel using "$mapping", sheet("Master") firstrow clear

sum *

tab Tariff_min_4dig Tariff_min_6dig, row m
tab IOMatrix_4dig

*ren (Tariff_CD2 Imported) (custom_rate imported) 

keep codpr Tariff* IOMatrix_4dig

tempfile custom
save `custom', replace

*----- 1. 
use "$presim/05_purchases_hhid_codpr.dta", clear

merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize) nogen

merge m:1 codpr using `custom' , keep(3) nogen


tabstat depan [aw = hhweight] if IOMatrix_4dig == 1, s(p50 mean min max sum) by(Tariff_min_4dig)

tabstat depan [aw = hhweight] if IOMatrix_4dig == 1, s(p50 mean min max sum) by(Tariff_min_6dig)





*----- 1. Test all purcgase
use "$presim/05_purchases_hhid_codpr.dta", clear

merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize) nogen

tabstat depan [aw = hhweight], s(sum)



