/*============================================================================================
 ======================================================================================

	Project:		Subsidies - Tables and Figures
	Author:			Gabriel 
	Creation Date:	Apr 21, 2023
	Modified:		
	
	Note:			This do-file produces all the fugures and tables on subsidies. 
					It supports several simulations with the excel file Figures_Sub_MRT.xlsx. 
					It works independently of the tool and uses as input the tool SN_Sim_tool_VI, output data and presim data
					The 4,5,6 figgres supports several simulations and countries
					Figure 4 and 6 supports several policies with global policy
					Figure 5 can support n consumers (type of clients), n tranches and (prepaid or postpaid)
					
	Section: 		1. AdminData: Tariff Structure
					2. AdminData: Consumption and Coverage
					3. AdminData: Indirect effects: Impact of subsidy
					4. Absolute and Relative Incidence
					5. Electricity coverage per decile
					6. Povery results
============================================================================================
============================================================================================*/

clear all
macro drop _all

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mausim_2024"
	global report "${path}/04. Reports/5. Subsidies/Electricity/2. Presentation/Figures"
	
	global thedo     	"${path}/02. Scripts"

	global xls_out    	"${report}/Figures12_Subsidies_Electricity.xlsx"
	global xls_sn    	"${path}/03. Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
	

	global numscenarios	3
	global coutryscen	"MRT MRT MRT"	// Fill with the country of each simulation
	
	global proj_1		"v3_MRT_Ref" 
	global proj_2		"v3_MRT_ElecRef"  
	global proj_3		"v3_MRT_Compen" 
	global proj_4		"" 
}

* Daniel
if "`c(username)'"=="wb419055" {
	
	global path     	"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024\00_Workshop\Feb_2024\VAT_tool" 
	global path_out 	"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024\00_Workshop\QER"	
	global thedo     	"${path}/gitrepo\daniel"

	global xls_out    	"${path_out}/Figures_Sub_MRT.xlsx"
	global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
	
	* Simulations to run
	global numscenarios	2			// Update
	global coutryscen	"MRT SEN" 	// Update
	global proj_1		"" 			// Update
	global proj_2		"" 			// Update
}

	global policy		"subsidy_total subsidy_elec_direct subsidy_elec_indirect"
	
	global presim       "${path}/01. Data/2_pre_sim/MRT"
	global data_out    	"${path}/01. Data/4_sim_output"
	global theado       "$thedo/ado"
	scalar t1 = c(current_time)

*===============================================================================
// Run necessary ado files
*===============================================================================

cap run "$theado//costpush.ado"

/*-------------------------------------------------------/
	1. AdminData: Tariff Structure
/-------------------------------------------------------*/

local scenario 1
import excel "$xls_sn", sheet("p_${proj_`scenario'}") firstrow clear 

global prep "P"
global user "DPP DMP"
global tranch "T1 T2"

cap drop keep 
gen keep = 0
replace keep = 1 if globalname == "cost_elec_dom" 
replace keep = 1 if globalname == "cost_elec_prof"
replace keep = 1 if globalname == "tariff_elec_prof"

* Define length of loops
local var_names "prep user tranch"
forvalues i = 1/3 {
	local v : word `i' of `var_names'
	local n_`v' 0
	foreach j of global `v' {
		local n_`v' = `n_`v'' + 1
	}
	global n_`v' `n_`v''
}

* This loop might be usefull when you have several tranches and users
forvalues i = 1/$n_prep {
	local t1 : word `i' of $prep
	forvalues j = 1/$n_user {
		local t2 : word `j' of $user
		forvalues k = 1/$n_tranch {
			local z : word `k' of $tranch
			replace keep = 1 if globalname == "Tariff`z'_`t1'`t2'"
		}
	}	
}
keep if keep == 1
destring globalcontent, replace

drop keep 


export excel "$xls_out", sheet("Tab_1") first(variable) sheetmodify cell(A30)

/*-------------------------------------------------------/
	2. AdminData: Consumption and Coverage
/-------------------------------------------------------*/

use "$presim/08_subsidies_elect.dta", clear // It runs the latests simulation done

merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight hhsize) 

*-----  Household coverage
tabm hh_elec* [iw = hhweight], row matcell(A)

mat colnames A = No Yes
mat rownames A = HHusesElectricity HHPrincipalSource HHPositiveDepan HHSimulationCoverage

*putexcel set "${xls_out}", sheet("Tab_1") modify
*putexcel A1 = matrix(A), names
 
 
*-----  Mean consumption
gen all = 1
gen kwh_b = consumption_electricite/hhsize

tabstat all kwh_b consumption_electricite [aw = hhweight] if inlist(type_client, 1, 2), s(mean sum) by(type_client) save

matrix A = r(Stat1), r(Stat2), r(StatTotal)

putexcel set "${xls_out}", sheet("Tab_1") modify
putexcel A10 = matrix(A), names

/*-------------------------------------------------------/
	3. AdminData: Indirect effects: Impact of subsidy
/-------------------------------------------------------*/

use "$presim/IO_Matrix.dta", clear 

*Shock
gen shock=-0.1 if elec_sec==1
replace shock=0  if shock==.

*Indirect effects 
des sect_*, varlist 
local list "`r(varlist)'"
	
costpush `list', fixed(fixed) priceshock(shock) genptot(elec_tot_shock) genpind(elec_ind_shock) fix
	
drop sect_*

gsort elec_ind_shock
keep sector_name elec_ind_shock elec_tot_shock
export excel "$xls_out", sheet("Fig_1") first(variable) sheetmodify


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
	replace value = value*(-100) if value < 0
	replace value = value*(100) if value >= 0
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

export excel "$xls_out", sheet(Fig_2) first(variable) sheetmodify 


/*-------------------------------------------------------/
	5. Electricity coverage per decile
/-------------------------------------------------------*/
*-----  Coverage and consumption
forvalues scenario = 1/$numscenarios {
	
	*local scenario = 1
	local vc : word `scenario' of $coutryscen
	global presim "${path}/01. Data/2_pre_sim/`vc'"
	
	* Purcases 
	use "$presim/05_purchases_hhid_codpr.dta", clear
	*use "$data_sn/pivot2019.dta", clear

	rename depan depan2
	
	merge m:1 hhid using "$presim/01_menages.dta", keepusing(hhweight) keep(3) nogen
	merge 1:1 hhid codpr using "$presim/08_subsidies_elect.dta", keepusing(codpr_elec hh_elec) nogen

	gen elec=0
	replace elec = depan2 if hh_elec==1

	collapse (firstnm) hhweight (sum) depan2 elec hh_elec, by(hhid)

	gen share_elec = elec/depan2
	gen cshare_elec = share_elec if share_elec>0
	gen coverage = (hh_elec>0)
	
	tempfile elec_share
	save `elec_share'
	
	* Output
	use "$data_out/output_${proj_`scenario'}.dta", clear

	keep hhid depan yd_deciles_pc hhsize hhweight
	
	merge 1:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(type_client consumption_electricite prepaid_woyofal) keep(3) nogen
	
	merge 1:1 hhid using `elec_share', keep(3) nogen

	qui: sum type_client
	local n_type_client = r(max)
	
	forvalues i = 0/1 { 
		forvalues j = 1/`n_type_client' { 
				gen a_user_`i'_`j' = prepaid_woyofal == `i' & type_client==`j' 
				gen a_c_user_`i'_`j' = consumption_electricite/hhsize if prepaid_woyofal == `i' & type_client==`j' 
		}
	}

	collapse (mean) *user_* *share_elec coverage [aw=hhweight], by(yd_deciles_pc) fast

	foreach v of varlist a_user* *share_elec coverage {
		replace `v'=100*`v'
	}
		
	gen scenario = `scenario'
	order scenario yd_deciles_pc a_user* a_c_user*, first
	
	tempfile elec1_`scenario'
	save `elec1_`scenario'', replace

}

clear
forvalues scenario = 1/$numscenarios {
	append using `elec1_`scenario''
}

export excel "$xls_out", sheet(Fig_3) first(variable) sheetmodify 



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









