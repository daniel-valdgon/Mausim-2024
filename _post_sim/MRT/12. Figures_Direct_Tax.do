/*=============================================================================

	Project:		Direct Taxes - Figures Scenarios
	Author:			Gabriel 
	Creation Date:	July 18, 2024
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

	global proj_1		"V0_MRT_Test4" 

	global policy		"income_tax"

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

egen tag = tag(hhid)	
	
keep hhid B2 B4 E*	
	
merge m:1 hhid using "$data_out/output_${proj_1}.dta", nogen keep(3) keepusing(hhweight hhsize ${policy}_pc ymp_pc)


tabstat income_tax [aw = hhweight], s(mean sum)

_ebin ymp_pc [aw=hhweight], nq(10) gen(decile_ymp)

tabstat E20A2 [aw = hhweight] if tax_ind == 1, s(min max mean sum) by(decile_ymp)


gsafvbher

gen uno = 1

* Working-age population
gen female = (B2==2)
gen wa_pop = inrange(B4,15,64)
gen nwa_pop = inrange(B4,0,14)
gen n2wa_pop = inrange(B4,65,96)

tab1 E6A E6B [iw = hhweight]

* Individuals
tab E10 E19 [iw = hhweight], row nofreq

tab E10 E12 [iw = hhweight], row nofreq

tab E12 [iw = hhweight]

dagrnr

* Principal activity
gen employee_1 = .
replace employee_1 = 1 if inrange(E10, 1, 6)
replace employee_1 = 0 if inrange(E10, 7, 12)

gen tax_ind_1 = employee_1 == 1 & E20A2>0 & E20A2!=. & E20A1 == 1
replace tax_ind_1 = 0 if E19 == 7

gen tax_base_1 = E20A2*E15 if tax_ind_1 == 1
 

* Secondary activity
gen employee_2 = .
replace employee_2 = 1 if inrange(E27, 1, 6)
replace employee_2 = 0 if inrange(E27, 7, 12)

gen tax_ind_2 = employee_2 == 1 & E31A2>0 & E31A2!=. & E31A1 == 1
gen tax_base_2 = E31A2*E29 if tax_ind_2 == 1

gen tax_ind = tax_ind_1 == 1 | tax_ind_2 == 1

* Allowances
gen allow1 = 60000
gen allow2 = tax_base_1 * 0.20 if E19 == 6

egen allowance = rowtotal(allow1 allow2)
replace allowance = (-1) * allowance

egen tax_base = rowtotal(tax_base_1 tax_base_2 allowance)
replace tax_base = 0 if tax_base <0


* Exemptions
gen exemptions = 0
replace exemptions = 1 if tax_base <= 60000
replace exemptions = 1 if inlist(E8, 1, 2)

replace tax_ind = 0 if exemptions == 1

sum tax_ind allowance tax_base [iw = hhweight]


* Tax
local tax1 = 0.15
local tax2 = 0.25
local tax3 = 0.40

gen tranche = 0
replace tranche = 1 if inrange(tax_base, 1, 90000) 
replace tranche = 2 if inrange(tax_base, 90000, 21000) 
replace tranche = 3 if inrange(tax_base, 21000, .) 

gen income_tax = 0
replace income_tax = tax_base * `tax1' if tranche == 1
replace income_tax = tax_base * `tax2' - 9000  if tranche == 2
replace income_tax = tax_base * `tax3' - 40500 if tranche == 3

replace income_tax = 0 if income_tax < 0

tabstat E20A2 E31A2 income_tax tax_base [aw = hhweight] if tax_base>0 & tax_ind == 1, s(p10 p25 p50 p75 p90 mean min max sum) 

tabstat tax_ind allowance tax_base income_tax [aw = hhweight], s(sum) by(tranche)

gebf

keep hhid tax_ind tax_base income_tax allowance tranche

save "$presim/02_Income_tax_input.dta", replace


gvsvs
gcollapse (sum) income_tax, by(hhid)



gsbd




*------------ Validation
tab wa_pop employee [iw = hhweight], m row // 50.44% Working-age pop
tab employee [iw = hhweight], m // 23% empleados con act principal

tab employee [iw = hhweight], matcell(A1)
tab employee [iw = hhweight] if E20A2>0 & E20A2!=., matcell(A2)
tab employee E20A1 [iw = hhweight] if E20A2>0 & E20A2!=., matcell(A3)

mat A = A1, A2, A3
matlist A

tab E19 [iw = hhweight] if tax_ind == 1





tab employee tax_ind [iw = hhweight], m row




tab tax_ind [iw = hhweight]

tab E20A1 tax_ind [iw = hhweight], row



tab female wa_pop [iw = hhweight], row nofreq



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




/*-------------------------------------------------------/
	4. Absolute and Relative Incidence
/-------------------------------------------------------*/

global income "yd" // yd, ymp

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















