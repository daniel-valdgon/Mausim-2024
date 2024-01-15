
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico based on Disposable Income by Mayor Cabrera
* Date: June 2020
* Version: 1.0
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------

**folders
*clear
*set more off

****************************************************************************
*Constructing DisposableIncome
/*
Disposable Income = Consumption Aggregate of HHD Survey
Calculate poverty using Consumption Aggregate of Survey
To estimate Per Capita Disposable Income, it is necessary to identify only members of the household
Check new poverty estimates
*/
*****************************************************************************

**key a07b a08
**gen hhid = string(a01) + string(a02) + string(a03)  + string(a04)+ string(a07b) + string(a08)

/*
use "$dataout/ehcvm_conso_SEN2018_menage.dta", clear
merge 1:1 hhid using "$dta/income_tax_collapse.dta", nogen
merge 1:1 hhid using "$dta/social_security_contributions.dta", nogen
merge 1:1 hhid using "$dta/Final_TVA_Tax.dta"
merge 1:1 hhid using "$dta/Excise_taxes.dta", nogen
merge 1:1 hhid using "$dta/Direct_transfers.dta", nogen 
merge 1:1 hhid using "$dta/Transfers_InKind.dta", nogen
merge 1:1 hhid using "$dta/Electricity_subsidies.dta", nogen
merge 1:1 hhid using "$dta/Agricultural_subsidies.dta", nogen
merge 1:1 hhid using "$dta/perfect_targetting1.dta", nogen
*/

use "$dataout/ehcvm_conso_SEN2018_menage.dta", clear
merge 1:1 hhid using `income_tax_collapse' , nogen
merge 1:1 hhid using `social_security_contributions' , nogen
merge 1:1 hhid using `Final_TVA_Tax' , nogen
merge 1:1 hhid using `Excise_taxes' , nogen
merge 1:1 hhid using `Direct_transfers'  , nogen
merge 1:1 hhid using `Transfers_InKind' , nogen
merge 1:1 hhid using `Electricity_subsidies' , nogen
merge 1:1 hhid using `Agricultural_subsidies' , nogen
merge 1:1 hhid using "$dta/perfect_targetting1.dta", nogen


/* Disposable Income */

gen double yd_pre=round(dtot/hhsize,0.01)

	local Directaxes 		"income_tax "
	local Indtaxes 			"excise_taxes Tax_TVA"
	local Education 		"education_inKind" 
	local Contributions 	"csp_ipr csp_fnr csh_css"
	local DirectTransfers   "am_bourse am_Cantine am_BNSF "
	local subsidies         "subsidy_elec"
	local taxcs 			`Directaxes' `Indtaxes' `Contributions'
	local transfers         `DirectTransfers' `subsidies' `Education'
	      


foreach var of local taxcs{
	gen `var'_pc= `var'/hhsize
	}
	
foreach var of local transfers{
	gen `var'_pc= `var'/hhsize
	}
	
	local Directaxes 		"income_tax_pc "
	local Indtaxes 			"excise_taxes_pc Tax_TVA_pc"
	local Education 		"education_inKind_pc" 
	local Contributions 	"csp_ipr_pc csp_fnr_pc csh_css_pc"
	local DirectTransfers   "am_bourse_pc am_Cantine_pc am_BNSF_pc" 
	local taxcs 			`Directaxes' `Indtaxes' `Contributions'
	local transfers         `DirectTransfers' `subsidies' `Education'	

foreach i in `Directaxes' `Contributions' `DirectTransfers'  `Indtaxes'  `subsidies' `Education' {
		replace `i'=0 if `i'==.
	}
	
*change taxes and contributions to negatives

foreach i in `Indtaxes' `Directaxes' `Contributions' {
		replace `i'=-`i'
	}
	
***************************************DISPOSABLE INCOME ---STARTING POINT

*egen  double yd_pc = rowtotal(yd_pre `DirectTransfers')

egen  double yd_pc = rowtotal(yd_pre)

replace yd_pc=0 if yd_pc==.
label var yd_pc "Disposable Income per capita"
	 

*************************************** MARKET INCOME plus pensions ---MOVING BACKWARDS

egen double aux = rowtotal(`Directaxes' `Contributions')
replace aux = - aux
egen double aux2 = rowtotal(`DirectTransfers')
replace aux2 = - aux2
	  
egen  double ymp_pc= rowtotal(yd_pc aux aux2)

drop aux aux2
replace ymp_pc=0 if ymp_pc==.
replace ymp_pc=0 if ymp_pc<0
label var ymp_pc " Market Income plus pensions per capita" 
	

keep hhid ymp_pc	
	
save "$dta/gross_ymp_pc.dta", replace


