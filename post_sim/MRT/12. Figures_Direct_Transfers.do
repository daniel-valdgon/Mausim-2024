/*============================================================================================
 ======================================================================================

	Project:		Direct Transfers - Figures Scenarios
	Author:			Gabriel 
	Creation Date:	June 26, 2024
	Modified:		
	
	Section: 		1. Validation
					4. Absolute and Relative Incidence
					5. Marginal Contributions
					6. Poverty difference
					
* @Daniel. 

	Note: 			I copy and paste all figures in the Figures excel. Sections 5 and 6 are not working in this do-file, I took them from shiny app. https://gabrielombo.shinyapps.io/WestAfrica_CEQ/. 

	Excel Figures: 
					1. Results: Tables from both R-Shiny (Section 5 and 6) and this do-file (Section 4). 
					2. Distribution: Same tables as in the inputs tool on the reference scenario
					3. Validation: Tables from this do-file (Section 1) and adm data
  
	Scenarios:		V2_MRT_Ref, V2_MRT_Notran, V2_MRT_UBI, V2_MRT_School, V2_MRT_Tekavoul, V2_MRT_Rand 
				
============================================================================================
============================================================================================*/

clear all
macro drop _all

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mauritania/Mausim_2024"
	global path_out		"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mauritania/Mausim_2024"
	
	global thedo     	"${path}/02_scripts"

	global xls_out    	"${path_out}/Figures_MRT.xlsx"
	global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
	
	global numscenarios	6

	global proj_1		"V2_MRT_Ref" 
	global proj_2		"V2_MRT_Notran"  
	global proj_3		"V2_MRT_UBI" 
	global proj_4		"V2_MRT_School" 
	global proj_5		"V2_MRT_Tekavoul" 
	global proj_6		"V2_MRT_Rand" 

	global policy		"am_BNSF1 am_BNSF2 am_Cantine am_elmaouna"

}

* Daniel
if "`c(username)'"=="wb419055" {
	
	global path     	"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024\00_Workshop\Feb_2024\VAT_tool" 
	global path_out 	"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024\00_Workshop\QER"	
	global thedo     	"${path}/gitrepo\daniel"

	global xls_out    	"${path_out}/Figures_Sub_MRT.xlsx"
	global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
	
	* Simulations to run
	global numscenarios	6

	global proj_1		"V2_MRT_Ref" 
	global proj_2		"V2_MRT_Notran"  
	global proj_3		"V2_MRT_UBI" 
	global proj_4		"V2_MRT_School" 
	global proj_5		"V2_MRT_Tekavoul" 
	global proj_6		"V2_MRT_Rand" 
	
	global policy		"am_BNSF1 am_BNSF2 am_Cantine am_elmaouna"
}

	global data_sn 		"${path}/01_data/1_raw/MRT"    
	global presim       "${path}/01_data/2_pre_sim/MRT"
	global data_out    	"${path}/01_data/4_sim_output"
	global theado       "$thedo/ado"
	scalar t1 = c(current_time)

	
*===============================================================================
// Run necessary ado files
*===============================================================================

cap run "$theado//_ebin.ado"
	
/*-------------------------------------------------------/
	1. Validation
/-------------------------------------------------------*/

	
use "$data_sn/Datain/individus_2019.dta", clear

forvalues i = 1/6 {
	gen prog_`i' = (PS4A == `i' | PS4B == `i' | PS4C == `i')
	gen prog_amount_`i' = PS7 if prog_`i' == 1
	
	egen hh_prog_`i' = max(prog_`i' == 1), by(hid)
	egen hh_prog_amount_`i' = total(prog_amount_`i'), by(hid)
}

ren hid hhid
egen tag = tag(hhid)
gen uno = 1
	
* Result data	
merge m:1 hhid using "$data_out/output_${proj_1}.dta", nogen keep(3) keepusing(*deciles* ymp_pc yn_pc yd_pc yc_pc hhsize hhweight am*)

* Programs
global progs "prog_1 prog_2 prog_3 prog_4 prog_5 prog_6"
global hh_progs "hh_prog_1 hh_prog_2 hh_prog_3 hh_prog_4 hh_prog_5 hh_prog_6"
global hh_progs_am "hh_prog_amount_1 hh_prog_amount_2 hh_prog_amount_3 hh_prog_amount_4 hh_prog_amount_5 hh_prog_amount_6"

_ebin ymp_pc [aw=hhweight], nq(10) gen(decile_ymp)

* @Daniel, con las siguientes tablas genero la table de coverage, slides 11

tabm $progs [iw = hhweight] 
tabm $hh_progs if tag == 1 [iw = hhweight] 

* Individuals
tab uno [iw = hhweight] if prog_1==1 | prog_2==1 | prog_3==1 | prog_4==1 | prog_5==1 | prog_6==1
tab uno [iw = hhweight] if prog_1==1 | prog_2==1 | prog_3==1

* Households
tab uno [iw = hhweight] if (hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1 | hh_prog_4==1 | hh_prog_5==1 | hh_prog_6==1) & tag == 1
tab uno [iw = hhweight] if (hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1) & tag == 1

* @Daniel, con las siguientes dos tablas genero las gráficas de coverage, slides 12 y 13

* Figures


tabstat $hh_progs [aw = hhweight] if tag == 1, s(sum) by(decile_ymp) // Slide 12 and 13

tab uno [iw = hhweight] if tag == 1 // All households, Slide 12 and 13



/*-------------------------------------------------------/
	4. Absolute and Relative Incidence
/-------------------------------------------------------*/

global income "ymp" // yd, ymp

forvalues scenario = 1/1 { //$numscenarios {

	*-----  Absolute Incidence
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

	tempfile abs
	save `abs', replace

	*-----  Relative Incidence
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
	replace value = value*(-100) if value < 0
	replace value = value*(100) if value >= 0
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	keep decile *_${income}

	order decile $policy2

	merge 1:1 decile using `abs', nogen
	
	gen scenario = `scenario'
	order scenario, first
	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace

}

/*
clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}
*/
*export excel "$xls_out", sheet(Fig_2) first(variable) sheetmodify 


/*-------------------------------------------------------/
	6. Marginal contributions
/-------------------------------------------------------*/
* @Daniel Taken with the shiny app - Disposable Income, not working now in stata
not working

	global variable 	"yd" // Only one
	global reference 	"zref" // Only one

forvalues scenario = 1/1 { //$numscenarios {

	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${variable}_pc" & reference == "$reference"
	mat pov = J(1,`len', r(mean))'
	 
	sum value if measure == "gini" & variable == "${variable}_pc"
	mat gini = J(1,`len', r(mean))'
	
	* Variables of interest
	gen keep = 0
	global policy2 	"" 
	foreach var in $policy {
		replace keep = 1 if variable == "${variable}_inc_`var'"
		global policy2	"$policy2 v_`var'_pc_${variable}" 
	}	
	
	keep if keep == 1
	
	keep if inlist(measure, "fgt0", "gini") 
	keep if inlist(reference, "$reference", "") 
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "${variable}_inc_`v'"
	}
	
	tab o_variable measure [iw = value] if reference == "$reference", matcell(A1)
	tab o_variable measure [iw = value] if reference == "", matcell(A2)

*-----  Kakwani	
	import excel "$xls_sn", sheet("conc${variable}_${proj_`scenario'}") firstrow clear 
	
	keep ${variable}_centile_pc ${variable}_pc $policy
	keep if ${variable}_centile_pc == 999
	
	ren * var_*
	ren var_${variable}_centile_pc ${variable}_centile_pc
	ren var_${variable}_pc ${variable}_pc
	
	reshape long var_, i(${variable}_centile_pc) j(variable, string)
	ren var_ value
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "`v'_pc"
	}

	tab o_variable [iw = ${variable}_pc], matcell(B1)
	tab o_variable [iw = value], matcell(B2)
	
	* Matrix
	mat A = pov, A1, gini, A2, B1, B2
	
	mat colnames A = gl_pov poverty gl_gini gini ${variable}_pc conc${variable}
	mat rownames A = $policy
		
	keep o_variable
	gsort o_variable

	svmat double A,  names(col)

	gen scenario = `scenario'
	order scenario, first
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `pov_`scenario''
}

export excel "$xls_out", sheet(Fig_4) first(variable) sheetmodify 



/*-------------------------------------------------------/
	7. Poverty difference on simulations
/-------------------------------------------------------*/
* @Daniel Taken with the shiny app - Disposable Income, not working now in stata

	global variable 	"yd" // Only one
	global reference 	"zref" // Only one

	*-----  Marginal contributions
forvalues scenario = 1/$numscenarios {
	
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${variable}_pc" & reference == "$reference"
	mat pov = J(1,`len', r(mean))' 
	
	sum value if measure == "gini" & variable == "${variable}_pc"
	mat gini = J(1,`len', r(mean))'
	
	* Variables of interest
	gen keep = 0
	global policy2 	"" 
	foreach var in $policy {
		replace keep = 1 if variable == "${variable}_inc_`var'"
		global policy2	"$policy2 v_`var'_pc_${variable}" 
	}	
	
	keep if keep == 1
	
	keep if inlist(measure, "fgt0", "gini") 
	keep if inlist(reference, "$reference", "") 
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "${variable}_inc_`v'"
	}
	
	tab o_variable measure [iw = value] if reference == "$reference", matcell(A1)
	tab o_variable measure [iw = value] if reference == "", matcell(A2)

*-----  Kakwani	

	import excel "$xls_sn", sheet("conc${variable}_${proj_`scenario'}") firstrow clear 
	
	keep ${variable}_centile_pc ${variable}_pc $policy
	keep if ${variable}_centile_pc == 999
	
	ren * var_*
	ren var_${variable}_centile_pc ${variable}_centile_pc
	ren var_${variable}_pc ${variable}_pc
	
	reshape long var_, i(${variable}_centile_pc) j(variable, string)
	ren var_ value
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "`v'_pc"
	}

	tab o_variable [iw = ${variable}_pc], matcell(B1)
	tab o_variable [iw = value], matcell(B2)
	
	mat J = J(1,1, .)
	
	* temporal fix for VAT Ind Effects
	local dim `= rowsof(B2)'	
	if ("`dim'" == "2") {
		mat B2 = B2 \ J
	}
	
	* Matrix
	mat A = pov, A1, gini, A2, B1, B2
	
	mat colnames A = gl_pov poverty gl_gini gini ${variable}_pc conc${variable}
	mat rownames A = $policy
	
	keep o_variable
	gsort o_variable

	svmat double A,  names(col)
	
	gen scenario = `scenario'
	order scenario, first
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `pov_`scenario''
}

export excel "$xls_out", sheet(Fig_5) first(variable) sheetreplace 


/*-------------------------------------------------------/
	Scenario names
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {
	
	clear
	set obs 1
	
	gen scenario = `scenario'
	gen name = "${proj_`scenario'}"
	
	local vc : word `scenario' of $coutryscen
	gen country = "`vc'"
	
	tempfile name_`scenario'
	save `name_`scenario'', replace
}

clear
forvalues scenario = 1/$numscenarios {
	append using `name_`scenario''
}

export excel "$xls_out", sheet("Tab_1") first(variable) sheetmodify cell(A16)


scalar t2 = c(current_time)
display "Running the figures took " (clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"









