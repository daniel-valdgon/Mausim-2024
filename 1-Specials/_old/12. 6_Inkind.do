/*=============================================================================
===============================================================================
	Project:		Direct Taxes - Figures Scenarios
	Author:			Gabriel 
	Creation Date:	Sep 3, 2024
	Modified:		
	
	Section: 		1. Names
					2. Relative Incidence
					3. Absolute Incidence
					4. Marginal Contributions
					5. Poverty and Inequality - Compare Scenarios
					6. Map
					
	Note:
===============================================================================
==============================================================================*/

clear all
macro drop _all

local dirtr			"dirtransf_total am_prog_1 am_prog_2 am_prog_3 am_prog_4"
local dirtax		"dirtax_total income_tax_1 income_tax_2 income_tax_3"
local sub			"subsidy_total subsidy_elec_direct subsidy_elec_indirect subsidy_emel subsidy_emel_direct subsidy_emel_indirect"
local indtax		"indtax_total excise_taxes Tax_TVA TVA_direct TVA_indirect"
local inktr			"inktransf_total education_inKind"

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mausim_2024"
	*global report 		"${path}/04. Reports/7. Summary/2. Presentation/Figures"
	global thedo     	"${path}/02. Scripts"

	global xls_out		"${path}/03. Tool/General_Results.xlsx"
	global xls_sn    	"${path}/03. Tool/SN_Sim_tool_VI_`c(username)'.xlsx"
	
	* Set Parameters
	global numscenarios	1
	
	global proj_1		"Ref_MRT_2019" 
	global proj_2		"v1_MRT_ElecReform"
	global proj_3		"v2_MRT_Elec_CM"  
	global proj_4		"RevRecSinGoods"
	global proj_5		"DoubleSinGoodsBR"

	global policy		"`inktr'"	
	
	global income		"yc" // ymp, yn, yd, yc, yf
	global income2		"yf"
	global reference 	"zref" // Only one
}

	global allpolicy	"dirtax_total sscontribs_total dirtransf_total subsidy_total indtax_total inktransf_total" 
	global data_sn 		"${path}/01. Data/1_raw/MRT"    
	global presim       "${path}/01. Data/2_pre_sim/MRT"
	global data_out    	"${path}/01. Data/4_sim_output"
	global theado       "$thedo/ado"	

	scalar t1 = c(current_time)
	
*==============================================================================
// Run necessary ado files
*==============================================================================

cap run "$theado//_ebin.ado"	

/*-------------------------------------------------------/
	0. Validation and Assumptions
/-------------------------------------------------------*/

use "$presim/07_educ.dta", clear

merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight hhsize) 

tabm ben* [iw = hhweight], m

*----- First option

use "$data_sn/Datain/individus_2019.dta", clear
		
ren hid hhid
	
keep hhid A1 A2 A3 C4*

merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize)

tab C4N [iw = hhweight]

/*-------------------------------------------------------/
	1. Names
/-------------------------------------------------------*/
gab
*----- Scenarios
forvalues scenario = 1/$numscenarios {
	
	clear
	set obs 1
	
	gen scenario = `scenario'
	gen name = "${proj_`scenario'}"
	
	tempfile name_`scenario'
	save `name_`scenario'', replace
}

clear
forvalues scenario = 1/$numscenarios {
	append using `name_`scenario''
}

export excel "$xls_out", sheet(Scenarios) first(variable) sheetreplace cell(A1)

*putexcel B2 = "$policy", sheet(table2)

/*-------------------------------------------------------/
	2. Netcashflow
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {

	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="netcash" 
	gen keep = 0

	global policy2 	""
	foreach var in $allpolicy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	*gen val2 = . 
	*replace val2 = value * (-100) if value < 0
	*replace val2 = value*(100) if value >= 0
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	
	keep decile *_${income}
	gen scenario = `scenario'
	order scenario decile $policy2
	ren (*) (scenario decile $allpolicy)
	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace

}

clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}

export excel "$xls_out", sheet(Netcash) first(variable) sheetmodify cell(A1)


/*-------------------------------------------------------/
	2. Relative Incidence - Boxplot
/-------------------------------------------------------*/

*local scenario 1
*use "$data_out/output_${proj_`scenario'}.dta", clear

*keep hhid hhweight income_tax_1 yd_deciles_pc

*reshape wide yd_deciles_pc, i(hhid) 

/*-------------------------------------------------------/
	2. Relative Incidence
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {

	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="netcash" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	*gen val2 = . 
	*replace val2 = value * (-100) if value < 0
	*replace val2 = value*(100) if value >= 0
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	
	keep decile *_${income}
	gen scenario = `scenario'
	order scenario decile $policy2
	ren (*) (scenario decile $policy)
	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace

}

clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}

export excel "$xls_out", sheet(Incidence) first(variable) sheetmodify cell(A1)

/*-------------------------------------------------------/
	3. Absolute Incidence
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {

	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="benefits" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	keep decile *_${income}

	foreach var in $policy2 {
		egen ab_`var' = sum(`var')
		gen in_`var' = `var'*100/ab_`var'
	}

	keep decile in_*
	gen scenario = `scenario'
	order scenario, first
	ren (*) (scenario decile $policy)

	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace
	
}


clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}

export excel "$xls_out", sheet(Incidence) first(variable) sheetmodify cell(S1)
	
	
/*-------------------------------------------------------/
	4. Marginal Contributions
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {
	
	local scenario 1
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${income}_pc" & reference == "$reference"
	global pov0 = r(mean)
	 
	sum value if measure == "fgt1" & variable == "${income}_pc" & reference == "$reference"
	global pov1 = r(mean) 
	 
	sum value if measure == "gini" & variable == "${income}_pc"
	global gini1 = r(mean)
	
	* Variables of interest
	gen keep = 0
	global policy2 	"" 
	foreach var in $policy {
		replace keep = 1 if variable == "${income}_inc_`var'"
		global policy2	"$policy2 v_`var'_pc_${income}" 
	}	
	
	keep if keep == 1
	
	keep if inlist(measure, "fgt0", "fgt1", "gini") 
	keep if inlist(reference, "$reference", "") 
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "${income}_inc_`v'"
	}
	
	ren value val_
	keep o_variable measure val_
	gsort o_variable
	
	reshape wide val_, i(o_variable) j(measure, string)
	
	gen gl_fgt0 = $pov0
	gen gl_fgt1 = $pov1
	gen gl_gini = $gini1
	
	tempfile mc
	save `mc', replace

*-----  Kakwani	
	import excel "$xls_sn", sheet("conc${income}_${proj_`scenario'}") firstrow clear 
	
	global policy2: subinstr global policy " " "_pc ", all
	di "$policy2"
	
	keep ${income}_centile_pc ${income}_pc $policy2
	keep if ${income}_centile_pc == 999
	
	ren * var_*
	ren var_${income}_centile_pc income_centile_pc
	ren var_${income}_pc income_pc
	
	reshape long var_, i(income_centile_pc) j(variable, string)
	ren var_ value_
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "`v'_pc"
	}

	keep o_variable income_pc value_
	ren value value_k

	merge 1:1 o_variable using `mc', nogen
	
	gen scenario = `scenario'
	
	ren * cat_*
	ren (cat_scenario cat_o_variable) (scenario variable)
	
	reshape long cat_ , i(scenario variable) j(cat, string)
	
	gen var = substr(variable, 3, length(variable))
	drop variable
	
	reshape wide cat_ , i(scenario cat) j(var, string)

	ren * (scenario indic $policy)
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `pov_`scenario''
}

export excel "$xls_out", sheet(Marginal) first(variable) sheetreplace 

/*-------------------------------------------------------/
	5. Coverage
/-------------------------------------------------------*/
	
forvalues scenario = 1/$numscenarios {
	
	*local scenario = 1
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	keep if measure=="coverage" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
	}	
	keep if keep ==1 
	
	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	
	keep decile *_${income}
	gen scenario = `scenario'
	order scenario decile $policy2
	ren (*) (scenario decile $policy)
	
	tempfile cov_`scenario'
	save `cov_`scenario'', replace
	
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `cov_`scenario''
}

export excel "$xls_out", sheet(Coverage) first(variable) sheetmodify 



/*-------------------------------------------------------/
	6. Poverty and Inequality - Compare Scenarios
/-------------------------------------------------------*/
	
forvalues scenario = 1/$numscenarios {
	
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${income2}_pc" & reference == "$reference"
	global pov0 = r(mean)

	sum value if measure == "fgt1" & variable == "${income2}_pc" & reference == "$reference"
	global pov1 = r(mean)
	
	sum value if measure == "gini" & variable == "${income2}_pc"
	global gini1 = r(mean)
	
	
	clear
	set obs 1 
	
	gen gl_fgt0 = $pov0
	gen gl_fgt1 = $pov1
	gen gl_gini = $gini1
	
	gen scenario = `scenario'
	order scenario, first
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
	
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `pov_`scenario''
}

export excel "$xls_out", sheet(Poverty) first(variable) sheetreplace 


scalar t2 = c(current_time)
display "Running the figures took " (clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"









