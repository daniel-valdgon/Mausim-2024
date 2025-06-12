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
					5. Poverty and Inequality
					6. Map
					
	Note:
===============================================================================
==============================================================================*/

clear all
macro drop _all

global all_bypolicy "dirtax_total income_tax_1 income_tax_3 ss_contribs_total dirtransf_total am_prog_1 am_prog_2 am_prog_3 am_prog_4 ss_ben_sa indtax_total excise_taxes CD_direct Tax_TVA TVA_direct TVA_indirect subsidy_total subsidy_elec subsidy_fuel subsidy_emel_direct inktransf_educ am_educ_1 am_educ_2 am_educ_3 am_educ_4 inktransf_health"


* Gabriel - Personal Computer
if "`c(username)'"=="gabriellombomoreno" {			
	global pathdata     "/Users/gabriellombomoreno/Documents/WorldBank/Data/DATA_MRT" 
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 MRT Fiscal"
	
	global tool         "${path}/03-Outputs/`c(username)'/Tool" 	
	global thedo     	"${path}/02-Scripts/`c(username)'/0-Fiscal-Model"
	
}
	
	*----- Figures parameters
	global numscenarios	2
	global proj_1		"MRT_Ref_2019" 
	global proj_2		"MRT_Ref_NoQ_2019"
	global proj_3		""
	
	
	global policy		"inktransf_educ am_educ_1 am_educ_2 am_educ_3 am_educ_4 inktransf_health"
	
	global income		"yd" // ymp, yn, yd, yc, yf
	global income2		"yc"
	global reference 	"zref" // Only one	
	
	*----- Data
	global data_sn 		"${pathdata}/MRT_2019_EPCV/Data/STATA/1_raw"
    global data_other   "${dathdata}/MRT_FIA_OTHER"

	global presim       "${path}/01-Data/2_pre_sim"
	global tempsim      "${path}/01-Data/3_temp_sim"
	global data_out    	"${path}/01-Data/4_sim_output"

	*----- Tool
	global xls_sn 		"${tool}/MRT_Sim_tool_VI.xlsx"
	global xls_out    	"${tool}/Figures_print.xlsx"	
	
	*----- Ado	
	global theado       "$thedo/ado"

	scalar t1 = c(current_time)
	
/*
Policies:

Social Protection: am_prog_1 am_prog_2 am_prog_3 am_prog_4 subsidy_emel_direct

Direct Transfers: am_prog_1 am_prog_2 am_prog_3 am_prog_4

Direct Tax: income_tax_1 income_tax_2 income_tax_3

Subsidies: subsidy_total subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_f1_direct subsidy_f2_direct subsidy_f3_direct subsidy_emel_direct subsidy_inag_direct*

Indirect Taxes: indtax_total excise_taxes CD_direct TVA_direct TVA_indirect

All policies: dirtax_total income_tax_1 income_tax_3 ss_contribs_total dirtransf_total am_prog_1 am_prog_2 am_prog_3 am_prog_4 ss_ben_sa indtax_total excise_taxes CD_direct Tax_TVA TVA_direct TVA_indirect subsidy_total subsidy_elec subsidy_fuel subsidy_emel_direct inktransf_educ am_educ_1 am_educ_2 am_educ_3 am_educ_4 inktransf_health
*/	
	
*==============================================================================
// Run necessary ado files
*==============================================================================

cap run "$theado//_ebin.ado"	


/*-------------------------------------------------------/
	0. Validation
/-------------------------------------------------------*/

*use "$data_out/output_${proj_1}.dta", nogen keep(3) keepusing(*deciles* ymp_pc yn_pc yd_pc yc_pc hhsize hhweight am* subsidy*)


/*
{
	/*----- Read Data
	use "$data_sn/Datain/individus_2019.dta", clear
			
	ren hid hhid

	*keep hhid A1 A2 A3 C4*

	merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize decile_expenditure)

	tab wilaya [iw = hhweight]

	merge m:1 hhid using "$data_out/output_${proj_2}.dta", nogen keep(3) keepusing(*deciles* ymp_pc yn_pc yd_pc yc_pc hhsize hhweight am* subsidy*)
	
	*/
	
	use "$data_out/output_${proj_2}.dta", clear
	
	keep hhid *deciles* ymp_pc yn_pc yd_pc yc_pc hhsize hhweight am* subsidy*

	merge 1:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(wilaya)

	
	foreach var of varlist am_prog_1 am_prog_2 am_prog_3 am_prog_4 subsidy_emel_direct {
		gen dt_`var' = `var' > 0
	}	
	 
	
	egen dt_sum = rowtotal(dt_*)
	gen dt_1 = dt_sum == 1
	gen dt_2 = dt_sum == 2
	gen dt_345 = dt_sum >= 3
	gen dt_any = dt_sum >= 1
	
	order dt_sum, last
	
	
	_ebin ymp_pc [aw=hhweight], nq(10) gen(decile_ymp)

	
	tabm dt_* [iw = hhweight], row nofreq
	
	tabstat dt_* [aw = hhweight], s(mean) by(decile_ymp)
	
	tabstat dt_1 [aw = hhweight], s(mean) by(wilaya)
	
	
}

gsb


*/


/*-------------------------------------------------------/
	1. Names
/-------------------------------------------------------*/

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

*----- Policy
clear
set obs 1
gen policy = "$policy"
split policy, p(" ")
drop policy

export excel "$xls_out", sheet(Policy) first(variable) sheetreplace cell(A1)

*----- Other parameters
clear
set obs 1
gen income = "$income"
gen income2 =  "$income2"
gen pov_line = "$reference"

export excel "$xls_out", sheet(Other) first(variable) sheetreplace cell(A1)


/*-------------------------------------------------------/
	2. Netcashflow
/-------------------------------------------------------*/

global allpolicy	"dirtax_total ss_contribs_total dirtransf_total subsidy_total indtax_total inktransf_total"
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

export excel "$xls_out", sheet(Netcash) first(variable) sheetreplace cell(A1)




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
	gen val2 = . 
	replace val2 = -1 * value * 100 if value < 0
	replace val2 = value * 100 if value >= 0
	drop value
	rename val2 v_

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

export excel "$xls_out", sheet(Rel_Incidence) first(variable) sheetreplace cell(A1)

/*-------------------------------------------------------/
	3. Absolute Incidence
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {

	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="benefits" 
	gen keep = 0

	global policy2 	""
	global policy3 	""	
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
		global policy3	"$policy3 in_v_`var'_pc_${income}" 
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
		gen in_`var' = `var' * 100/ab_`var'
	}
	
	preserve 
	
		keep decile v_*
		gen scenario = `scenario'
		order scenario decile $policy2
		ren (*) (scenario decile $policy)
		
		tempfile v_`scenario'
		save `v_`scenario'', replace	
	
	restore

	keep decile in_*
	gen scenario = `scenario'
	order scenario decile $policy3
	ren (*) (scenario decile $policy)
	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace
	
}


clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}

export excel "$xls_out", sheet(Ab_Incidence) first(variable) sheetreplace cell(A1)


clear
forvalues scenario = 1/$numscenarios {
	append using `v_`scenario''
}

export excel "$xls_out", sheet(Total) first(variable) sheetreplace cell(A1)
	
	
	
/*-------------------------------------------------------/
	4. Marginal Contributions
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {

*local scenario = 1
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
	global policy3 	"" 	
	local counter = 1
	foreach var in $policy {
		replace keep = 1 if variable == "${income}_inc_`var'"
		global policy2	"$policy2 v_`var'_pc_${income}" 
		global policy3	"$policy3 cat_`counter'_`var'" 
		local counter = `counter' + 1
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
	
	*gen var = substr(variable, 3, length(variable))
	*drop variable
	
	ren variable var
	reshape wide cat_ , i(scenario cat) j(var, string)

	order scenario cat $policy3
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

export excel "$xls_out", sheet(Coverage) first(variable) sheetreplace 



/*-------------------------------------------------------/
	6. Poverty and Inequality
/-------------------------------------------------------*/

*------	Compare Scenarios
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


*------	Compare Income concepts, first scenario
global income_concepts "ymp yn yd yc yf"
local counter = 1
foreach j of global income_concepts {

	local scenario = 1

	
	di "`j', `counter'"
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "`j'_pc" & reference == "$reference"
	global pov0 = r(mean)

	sum value if measure == "fgt1" & variable == "`j'_pc" & reference == "$reference"
	global pov1 = r(mean)

	sum value if measure == "fgt2" & variable == "`j'_pc" & reference == "$reference"
	global pov2 = r(mean)	
	
	sum value if measure == "gini" & variable == "`j'_pc"
	global gini1 = r(mean)

	sum value if measure == "theil" & variable == "`j'_pc"
	global theil1 = r(mean)
	
	clear
	set obs 1 
	
	gen gl_fgt0 = $pov0
	gen gl_fgt1 = $pov1
	gen gl_fgt2 = $pov2	
	gen gl_gini = $gini1
	gen gl_theil = $theil1	
	
	gen inc = "`j'"
	order inc, first
	
	tempfile pov_`counter'
	save `pov_`counter'', replace

	local counter = `counter' + 1	
}	

clear
forvalues counter = 1/5 {
	append using `pov_`counter''
}


export excel "$xls_out", sheet(Poverty_inc) first(variable) sheetreplace 


scalar t2 = c(current_time)
display "Running the figures took " (clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"









