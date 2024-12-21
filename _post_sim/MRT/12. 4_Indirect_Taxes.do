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
	
	global data_out    	"${path}/01. Data/4_sim_output"
	global presim       "${path}/01. Data/2_pre_sim/MRT"
	global tempsim      "${path}/01. Data/3_temp_sim"

	global theado       "$thedo/ado"
	
*===============================================================================
// Run necessary ado files
*===============================================================================

cap run "$theado//_ebin.ado"
	
	
/*-------------------------------------------------------/
	1. Motivation: Informality results
/-------------------------------------------------------*/

import delimited using "$mapping", sheet("Master")

gasb

	use "$presim/01_menages.dta", clear
	
	keep hhsize hhid hhweight

	merge 1:m hhid using "$tempsim/FinalConsumption_verylong.dta"


	*---------- 4. Products less consumed by the poor ​
	use "$presim/05_purchases_hhid_codpr.dta", clear

	gen poor = inrange(decile, 1, 4)
	
	gen quintil = 0
	replace quintil = 1 if inrange(decile, 1, 2)
	replace quintil = 2 if inrange(decile, 3, 4)
	replace quintil = 3 if inrange(decile, 5, 6)
	replace quintil = 4 if inrange(decile, 7, 8)
	replace quintil = 5 if inrange(decile, 9, 10)
	
	gen bottom40 = 0
	replace bottom40 = 1 if inrange(decile, 1, 4)
	replace bottom40 = 2 if inrange(decile, 10, 10)

	
	gcollapse (sum) sum=depan (mean) value = depan (p50) median = depan, by(codpr bottom40)
	
	keep codpr bottom40 value
	reshape wide value, i(codpr) j(bottom40)
	
	*egen bottom40 = rowtotal(value1 value2 value3 value4)
	
	*gen ratio2 = value10 / bottom40
	
	gen ratio = value2/value1
	
	*tab coicop quintil [iw = mean]
	

/*-------------------------------------------------------/
	4. Absolute and Relative Incidence
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {

	*-----  Absolute Incidence
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="benefits" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_yd" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	keep decile *_yd

	foreach var in $policy2 {
		egen ab_`var' = sum(`var')
		gen in_`var' = `var'*100/ab_`var'
	}

	keep decile in_*

	tempfile abs
	save `abs', replace

	*-----  Relative Incidence
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="netcash" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_yd" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	replace value = value * (-100) if value < 0
	replace value = value * (100) if value >= 0
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	keep decile *_yd

	order decile $policy2

	merge 1:1 decile using `abs', nogen
	
	gen scenario = `scenario'
	order scenario, first
	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace

}

clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}

export excel "$xls_out", sheet(Tab_2) first(variable) sheetreplace 
	
	


