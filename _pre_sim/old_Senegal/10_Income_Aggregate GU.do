/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico based on Disposable Income by Mayor Cabrera
* Date: June 2020
* Version: 1.0
*Version 2: 
			- Streamlined
			- Added VAT exempt policies
			- Change gratuite services as cash transfers: am_subCMU am_sesame am_moin5 am_cesarienne. Pendent to ask about am_subCMU
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
****************************************************************************/
*Constructing DisposableIncome
/*
Disposable Income = Consumption Aggregate of HHD Survey
Calculate poverty using Consumption Aggregate of Survey
To estimate Per Capita Disposable Income, it is necessary to identify only members of the household
Check new poverty estimates
*/
*****************************************************************************
use "$data_sn/ehcvm_conso_SEN2018_menage.dta", clear
if $devmode== 1 {
	merge 1:1 hhid using "${tempsim}/income_tax_collapse_GU.dta" , nogen
	merge 1:1 hhid using "${tempsim}/social_security_contribs_GU.dta" , nogen
	merge 1:1 hhid using "${tempsim}/Direct_transfers_GU.dta"  , nogen
}
else {
	merge 1:1 hhid using `income_tax_collapse_GU' , nogen
	merge 1:1 hhid using `social_security_contribs_GU' , nogen
	merge 1:1 hhid using `Direct_transfers_GU'  , nogen
}
*merge 1:1 hhid using "$data_sn/perfect_targetting1.dta", nogen
	local Directaxes 		"income_tax trimf"
	local Contributions 	"csp_ipr csp_fnr csh_css csh_ipm csh_mutsan"
	local DirectTransfers   "am_bourse am_Cantine am_BNSF am_subCMU"    //  am_sesame am_moin5 am_cesarienne
	local taxcs 			`Directaxes' `Contributions'
	local transfers         `DirectTransfers'
	      
	foreach var of local taxcs {
		gen `var'_pc= `var'/hhsize
	}
		
	foreach var of local transfers {
		gen `var'_pc= `var'/hhsize
	}
	
	local Directaxes 		"income_tax_pc trimf_pc"
	local Contributions 	"csp_ipr_pc csp_fnr_pc csh_css_pc csh_ipm_pc csh_mutsan_pc"
	local DirectTransfers   "am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc"   //  am_sesame_pc am_moin5_pc am_cesarienne_pc
	local taxcs 			`Directaxes' `Contributions'
	local transfers         `DirectTransfers'
foreach i in `Directaxes' `Contributions' `DirectTransfers' {
		replace `i'=0 if `i'==.
	}
	
*change taxes and contributions to negatives
foreach i in `Directaxes' `Contributions' {
		replace `i'=-`i'
	}
	
***************************************DISPOSABLE INCOME ---STARTING POINT
gen double yd_pre=round(dtot/hhsize,0.01)
egen  double yd_pc = rowtotal(yd_pre)
replace yd_pc=0 if yd_pc==.
label var yd_pc "Disposable Income per capita"
	 
*************************************** MARKET INCOME plus pensions ---MOVING BACKWARDS
egen double aux = rowtotal(`Directaxes' `Contributions')
replace aux = - aux //(AGV) Note that we converted all taxes and contributions to negative above (line 75)
egen double aux2 = rowtotal(`DirectTransfers')
replace aux2 = - aux2
	  
egen  double ymp_pc= rowtotal(yd_pc aux aux2)
drop aux aux2
sum ymp_pc if ymp_pc<=0
if `r(N)'>0{
	noi dis as error "After subtracting direct transfers, `r(N)' households may have negative market incomes. Check that please!"
}
replace ymp_pc=0 if ymp_pc==.
replace ymp_pc=0 if ymp_pc<0
label var ymp_pc " Market Income plus pensions per capita"
	
noi dis "{opt File gross_ymp_pc, with Market Income plus pensions per capita, has been created.}"
keep hhid ymp_pc	
	
save "$data_sn/gross_ymp_pc.dta", replace


/* This part is only to compare current results with old (Julieth Pico) market income_tax */

use "$data_sn/gross_ymp_pc.dta", clear
rename ymp_pc ymp_pc_new
merge 1:1 hhid using "$data_sn/gross_ymp_pc_JuliethPico.dta", nogen
rename ymp_pc ymp_pc_old
merge 1:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta", keepusing(hhweight hhsize) nogen
sum ymp*
gen weight_pop = hhweight*hhsize
sum ymp* [aw=weight_pop]
gen ln_new=ln(ymp_pc_new)
gen ln_old=ln(ymp_pc_old)
global lnvals = ""
foreach var in 20000 50000 100000 200000 500000 1000000 2000000 5000000{
	*local lnv = round(ln(`var'),0.001)
	local lnv = round(ln(`var'+sqrt((`var')^2 +1)),0.001)
	global lnvals `"$lnvals `lnv' "`var'" "'
}
twoway (hist ln_new [fw=weight_pop], freq) (hist ln_old [fw=weight_pop], color(stc2%50) freq), xlabel($lnvals ) legend(label(1 "New") label(2 "Old") ring(0) pos(10))
graph export "$tempsim/ymp_dist_comp.png", replace
scatter ln_new ln_old, msize(tiny) mcolor(stc1%20) xlabel($lnvals ) ylabel($lnvals )
graph export "$tempsim/ymp_changes_comp.png", replace
noi sum ymp* [aw=weight_pop], deta
