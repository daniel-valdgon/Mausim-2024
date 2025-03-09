/*============================================================================================
 ======================================================================================

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
				
============================================================================================
============================================================================================*/

clear all
macro drop _all

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mausim_2024"
	global report 		"${path}/04. Reports/2. Direct Taxes/2. Presentation/Figures"	
	global thedo     	"${path}/02. Scripts"

	global xls_out		"${report}/Figure12_Direct_Taxes.xlsx"
	global xls_sn    	"${path}/03. Tool/SN_Sim_tool_VI_`c(username)'.xlsx"
	
	global numscenarios	3
	
	global proj_1		"Ref_MRT_2019" 
	global proj_2		"v1_MRT_IRPPNoAll"
	global proj_3		"v1_MRT_DT_CM"


	global policy		"dirtax_total income_tax_1 income_tax_2 income_tax_3"
	global allpolicy	"dirtax_total sscontribs_total dirtransf_total subsidy_total indtax_total inktransf_total" 
	
	global income		"yd" // ymp, yn, yd, yc, yf
	global reference 	"zref" // Only one
}

	global data_sn 		"${path}/01. Data/1_raw/MRT"    
	global presim       "${path}/01. Data/2_pre_sim/MRT"
	global data_out    	"${path}/01. Data/4_sim_output"
	global theado       "$thedo/ado"	
	global variable 	"$income"

	scalar t1 = c(current_time)

	
*===============================================================================
// Run necessary ado files
*===============================================================================

cap run "$theado//_ebin.ado"	


/*-------------------------------------------------------/
	0. Validation and Assumptions
/-------------------------------------------------------*/

use "$data_sn/Datain/individus_2019.dta", clear
		
ren hid hhid
	
merge m:1 hhid using "$presim/01_menages.dta", nogen keep(3) keepusing(hhweight hhsize)
merge 1:1 idind using "$presim/02_Income_tax_input.dta", nogen


*-------- Wages and Salaries
tab E11 E18B [iw = hhweight], m

gen worker = inrange(E11, 1, 9)
gen soc_sec = E18B == 1

gen pos = E20A2>0 & E20A2!=. & worker == 1 
gen pos_soc_sec = E20A2>0 & E20A2!=. & soc_sec == 1 

tabstat an_income_1 [aw = hhweight] if pos_soc_sec == 1, s(mean)


gen aux_income_1 = an_income_1/1000/10


twoway  (kdensity aux_income_1 [aw = hhweight] if B2 == 1) ///
		(kdensity aux_income_1 [aw = hhweight] if B2 == 2) ///
		(kdensity aux_income_1 [aw = hhweight]), ///
		xtitle("MRU (000)") ytitle("Density") ///
		legend( label (1 "Male annual labor income") label (2 "Female annual labor income") label (3 "Annual labor income") position(1))  

graph export "$report/income.png", width(1500) height(900) replace


gen aux_income_21 = inc_imp/1000/10
gen aux_income_2 = inc_imp2/1000/10

twoway  (kdensity aux_income_2 [aw = hhweight]), ///
		xtitle("MRU (000)") ytitle("Density") 

graph export "$report/income_imp.png", width(1500) height(900) replace

drop aux_income_1 aux_income_2

*-------- Property tax

keep hhid hhweight wilaya G0 F1 G12B G10 an_income_3 tax_ind_3
gduplicates drop 

gen owner = F1 == 1

tab G0 owner [iw = hhweight], col nofreq

* Values to impute multiplied by 12

tabstat an_income_3 [aw = hhweight] if tax_ind_3 == 1, s(mean) by(wilaya)

collapse (mean) income = an_income_3 [aw = hhweight] if tax_ind_3 == 1, by(wilaya)

tostring wilaya, gen(name)
gen len = length(name)
replace name = "0" + name if len == 1
keep name income

tempfile map
save `map', replace


/*------------------------------------------------------/
	10. Map
/-------------------------------------------------------*/

*------ Coordinates
*shp2dta using "$data_sn/Shapes/mrt_admbnda_adm1_ansade_20240327.shp", database("$data_sn/mrtdb") coordinates("$data_sn/mrtcoord") genid(id) replace

*------ Map
use "$data_sn/mrtdb", clear

gen name = substr(ADM1_PCODE, 3, 4) // Admin 1

merge m:1 name using `map', gen(mr_coor) 

gen income2 = round(income/10/1000)

spmap income2 using "$data_sn/mrtcoord", id(id) fcolor(Blues) legend(region(lcolor(black) margin(1 1 1 1) fcolor(white)) pos(10) title("Mean tax MRU (000)", size(*0.5))) 

graph export "$report/map_proptax.png", replace


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
	2 Relative Incidence - Boxplot
/-------------------------------------------------------*/

*local scenario 1
*use "$data_out/output_${proj_`scenario'}.dta", clear

*keep hhid hhweight income_tax_1 yd_deciles_pc

*reshape wide yd_deciles_pc, i(hhid) 

/*-------------------------------------------------------/
	2 Relative Incidence
/-------------------------------------------------------*/

	global income		"ymp" // ymp, yn, yd, yc, yf


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

	global income		"ymp" // ymp, yn, yd, yc, yf


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

	global income		"ymp" // ymp, yn, yd, yc, yf


forvalues scenario = 1/$numscenarios {
	
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${variable}_pc" & reference == "$reference"
	global pov0 = r(mean)
	 
	sum value if measure == "fgt1" & variable == "${variable}_pc" & reference == "$reference"
	global pov1 = r(mean) 
	 
	sum value if measure == "gini" & variable == "${variable}_pc"
	global gini1 = r(mean)
	
	* Variables of interest
	gen keep = 0
	global policy2 	"" 
	foreach var in $policy {
		replace keep = 1 if variable == "${variable}_inc_`var'"
		global policy2	"$policy2 v_`var'_pc_${variable}" 
	}	
	
	keep if keep == 1
	
	keep if inlist(measure, "fgt0", "fgt1", "gini") 
	keep if inlist(reference, "$reference", "") 
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "${variable}_inc_`v'"
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
	import excel "$xls_sn", sheet("conc${variable}_${proj_`scenario'}") firstrow clear 
	
	keep ${variable}_centile_pc ${variable}_pc $policy
	keep if ${variable}_centile_pc == 999
	
	ren * var_*
	ren var_${variable}_centile_pc income_centile_pc
	ren var_${variable}_pc income_pc
	
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
	5. Poverty and Inequality - Compare Scenarios
/-------------------------------------------------------*/
	
	global income		"yd" // ymp, yn, yd, yc, yf

	
forvalues scenario = 1/$numscenarios {
	
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${variable}_pc" & reference == "$reference"
	global pov0 = r(mean)

	sum value if measure == "fgt1" & variable == "${variable}_pc" & reference == "$reference"
	global pov1 = r(mean)
	
	sum value if measure == "gini" & variable == "${variable}_pc"
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

/*-------------------------------------------------------/
	6. Coverage
/-------------------------------------------------------*/
	
	global income		"ymp" // ymp, yn, yd, yc, yf

	
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




scalar t2 = c(current_time)
display "Running the figures took " (clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"









