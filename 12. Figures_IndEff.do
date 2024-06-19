/*============================================================================================
 ======================================================================================

	Project:		VAT & Excises - Tables and Figures
	Author:			Gabriel 
	Creation Date:	May 8, 2024
	Modified:		
	
	Note:			

					

============================================================================================
============================================================================================*/

clear all
macro drop _all

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool"
	global path_out		"/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool/QER"
	global thedo     	"${path}/02_scripts"

	global xls_out    	"${path_out}/Figures_IndEff44_MRT.xlsx"
	global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
	
	global numscenarios	3
	global proj_1		"VF44_MRT_Sub_Ref" 
	global proj_2		"VF44_MRT_Sub_NoExemp"  
	global proj_3		"VF44_MRT_Sub_InfReduc" 
	global proj_4		""  
	
	global country		"MRT"
}

* Daniel
if "`c(username)'"=="wb419055" {
	
	global path     	"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024\00_Workshop\Feb_2024\VAT_tool" 
	global path_out 	"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024\00_Workshop\QER"	
	global thedo     	"${path}/gitrepo\daniel"

	global xls_out    	"${path_out}/Figures_Sub_MRT.xlsx"
	global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
	
	* Simulations to run
	global numscenarios	2	// Update
	global proj_1		"" 	// Update
	global proj_2		"" 	// Update
}

	global policy		"Tax_TVA TVA_direct TVA_indirect"
	
	global data_out    	"${path}/01_data/4_sim_output"
	global presim       "${path}/01_data/2_pre_sim/MRT"
	global tempsim       "${path}/01_data/3_temp_sim"

	global theado       "$thedo/ado"
	
*===============================================================================
// Run necessary ado files
*===============================================================================

cap run "$theado//_ebin.ado"
	
	
/*-------------------------------------------------------/
	1. Motivation: Informality results
/-------------------------------------------------------*/

	use "$presim/01_menages.dta", clear
	
	keep hhsize hhid hhweight

	merge 1:m hhid using "$tempsim/FinalConsumption_verylong.dta"

	*gen double ymp_pc = round(achats_net/hhsize,0.01)
	gen double ymp_pc = round(achats_avec_excises/hhsize,0.01)

   
	gen pondih= hhweight*hhsize
	_ebin ymp_pc [aw=pondih], nq(10) gen(deciles_pc)
   
	tab TVA
	
    if ("$country" == "MRT") {
		replace TVA = .18 if inrange(TVA, 0.1999, 0.2001) 
	}
   
	*collapse (sum)  ymp_pc  [fw=pondih], by(hhid TVA)
	collapse (sum)  ymp_pc  [iw=pondih], by(hhid TVA)

	egen VAT = group(TVA)
   
	label define VAT 1 "Exempted" 2 "Basic" 3 "Standard"
	label values VAT VAT 
	
	drop TVA
   
	reshape wide ymp_pc, i(hhid) j(VAT)
   
    if ("$country" == "GMB") {
		egen cons = rowtotal(ymp_pc1 ymp_pc2)
		rename ymp_pc1 Exempted
		rename ymp_pc2 Standard
		
		foreach x in Exempted Standard {
			gen share_`x' = `x'/cons 
		}
	}
	
	if ("$country" == "MRT") {
		egen cons = rowtotal(ymp_pc*)
		rename ymp_pc1 Exempted
		rename ymp_pc2 Basic 
		rename ymp_pc3 Standard
	
		foreach x in Exempted Basic Standard {
			gen share_`x' = `x'/cons 
		}
	}
   
	// recover the hhweight and hhsize again 
   
	merge m:1 hhid using "$presim/01_menages.dta", keepusing(hhweight hhsize) nogen
 
	gen pondih= hhweight*hhsize
	_ebin cons [aw=pondih], nq(10) gen(deciles_pc)

  
	if ("$country" == "GMB") {
		collapse share_Exempted share_Standard (sum) Exempted [iw=pondih], by(deciles_pc)
	}	
	
	if ("$country" == "MRT") {
		collapse share_Exempted share_Basic share_Standard (sum) Exempted [iw=pondih], by(deciles_pc)
	}	
 
   
	** plot in Excel 
	preserve
	drop Exempted
        global cell = "A1"
        export excel using "$xls_out", sheet("Tab_1", modify) first(variable) cell($cell ) keepcellfmt
	restore
   
   
    *******************************************************************
	** 2.  Percentage of potential tax revenue from exempted products *
	*******************************************************************
	// distribution of the consumption on exempted products
	
	*collapse percent Exempted [fw=pondih], by(deciles_pc)
	
	egen total  = sum(Exempted)
	gen percent = (Exempted/total)*100
	keep percent deciles_pc

    global cell = "A15"
    export excel using "$xls_out", sheet("Tab_1", modify) first(variable) cell($cell ) keepcellfmt
	*twoway bar percent deciles_pc
	   
	
	********************************************************************
	** 3. Formality purchases across households by place of purchase​  **
	********************************************************************

	use "$presim/05_purchases_hhid_codpr.dta", clear

	if ("$country" == "GMB") ren c_inf_mean share_informal_consumption
	if ("$country" == "MRT") ren informal_purchase share_informal_consumption
	
	collapse (mean) c_inf_mean=share_informal_consumption (p50) c_inf_p50=share_informal_consumption , by(decile_expenditure /*product_code*/)
	
	global cell = "A35"
    export excel using "$xls_out", sheet("Tab_1", modify) first(variable) cell($cell ) keepcellfmt
	
	
	twoway  lowess /*lfitci*/ c_inf_mean decile_expenditure || lowess c_inf_p50 decile_expenditure, /*yaxis(0(.20)1)*/ lpattern(dash solid) title("Mauritania​") xtitle("Déciles de consommation par habitant") ytitle("Partage informel du budget") legend( label (1 "Mean") label (2 "Median"))

	*graph save "$path_out/informality", replace

	graph export "$path_out/informality.png", width(600) height(450) replace
	
	
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
	

/*-------------------------------------------------------/
	4. Revenue
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {

	*local scenario = 1
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	* Names
	global variable "Tax_TVA_pc TVA_direct_pc TVA_indirect_pc"
	global quintil "1 2 3 4 5"

	replace variable = "a_" + variable if variable == "Tax_TVA_pc"
	replace variable = "b_" + variable if variable == "TVA_direct_pc"
	replace variable = "c_" + variable if variable == "TVA_indirect_pc"

	* Filters
	keep if inlist(variable, "a_Tax_TVA_pc", "b_TVA_direct_pc", "c_TVA_indirect_pc")
	keep if measure == "benefits"

	* Grouping by quintil
	recode deciles_pc (1=1) (2=1) (3=2) (4=2) (5=3) (6=3) (7=4) (8=4) (9=5) (10=5), generate(quintil)

	collapse (sum) value, by(variable quintil)

	drop if quintil == 0

	replace value = value/1000000000

	drop if quintil == .
	
	*tostring quintil, replace
	*replace quintil = "var_" + quintil
	
	reshape wide value, i(variable) j(quintil)

	gen scenario = `scenario'
	order scenario, first
	
	tempfile rev_`scenario'
	save `rev_`scenario'', replace
}

clear
forvalues scenario = 1/$numscenarios {
	append using `rev_`scenario''
}
	
global cell = "J2"
export excel using "$xls_out", sheet("output", modify) first(variable) cell($cell ) keepcellfmt
	

/*-------------------------------------------------------/
	6. Poverty results
/-------------------------------------------------------*/

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
		global policy2	"$policy2 v_`var'_pc_yd" 
	}	
	
	keep if keep == 1
	
	keep if inlist(measure, "fgt0", "gini") 
	keep if inlist(reference, "$reference", "") 
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "yd_inc_`v'"
	}
	
	tab o_variable measure [iw = value] if reference == "$reference", matcell(A1)
	tab o_variable measure [iw = value] if reference == "", matcell(A2)

*-----  Kakwani	

	import excel "$xls_sn", sheet("conc${variable}_${proj_`scenario'}") firstrow clear 
	
	keep yd_centile_pc ${variable}_pc $policy
	keep if yd_centile_pc == 999
	
	ren * var_*
	ren var_yd_centile_pc yd_centile_pc
	ren var_${variable}_pc ${variable}_pc
	
	reshape long var_, i(yd_centile_pc) j(variable, string)
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

export excel "$xls_out", sheet(Fig_4) first(variable) sheetreplace 



/*-------------------------------------------------------/
	6. Poverty difference on simulations
/-------------------------------------------------------*/

	global variable 	"yc" // Only one
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

