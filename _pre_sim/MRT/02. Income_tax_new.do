/*=============================================================================

	Project:		Direct Taxes - Presim
	Author:			Gabriel 
	Creation Date:	July 18, 2024
	Modified:		
	
	Note: 
	
==============================================================================*/

/*
	Output: 02_Income_tax_input.dta

	Income
	Exemptions
	Allowances
	Tax Base
	Rate
	Tranches or regime
*/
	
/*-------------------------------------------------------/
	0. Prep Data
/-------------------------------------------------------*/

	
	
use "$data_sn/Datain/individus_2019.dta", clear
		
ren hid hhid
	
merge m:1 hhid using "$presim/01_menages.dta", nogen keep(3) keepusing(hhweight hhsize)

keep hhid hhweight wilaya milieu B2 B4 E* F* G0

gen uno = 1

sum E10 E20A2 E20A1 E19 E15

/*-------------------------------------------------------/
	0. Impute Income
/-------------------------------------------------------*/

tab E20B E20A1 [iw = hhweight], m // Individuals who didnt want to report the money received

gen pos = E20A2>0 & E20A2!=. 

preserve 

	tabstat E20A2 [aw = hhweight] if E18B == 1 & pos == 1, s(p50) by(E11)

	keep if E18B == 1

	gen tot = 1
	gen n_imp = pos == 0

	collapse (sum) tot pos n_imp (mean) inc_imp = E20A2, by(B2 E11)

	tempfile wages_impute
	save `wages_impute', replace

restore

* Merge imputed wages
merge m:1 B2 E11 using `wages_impute', gen(mr_imp) keep(1 3) keepusing(inc_imp)

mat aux_inc = (0, 60000, 80000, 100000, 130000, 250000, 450000, 700000, 700000)

gen inc_imp2 = inc_imp if inrange(E20B, 1, 8) | pos==1

forvalues i = 1/8 {
	replace inc_imp2 = aux_inc[1,`i'] if inc_imp < aux_inc[1,`i'] & E20B == `i'
	replace inc_imp2 = aux_inc[1,`i'+1] if inc_imp > aux_inc[1,`i'+1] & E20B == `i'
}

replace inc_imp2 = inc_imp if E20B == 0

tabstat inc_imp2  [aw = hhweight], s(min max mean) by(E20B)

egen income = rowtotal(E20A2 inc_imp2)

*br E20A2 inc_imp* income E20B

gen pos2 = income>0 & income!=. 
tab pos2 pos [iw = hhweight] if E18B == 1 // 23,609 to impute


/*-------------------------------------------------------/
	1. Tax Income - ITS
/-------------------------------------------------------*/

gen tax_ind = E18B == 1 & pos == 1
replace tax_ind = 0 if E19 == 7

gen an_income = income*12 if tax_ind == 1
  
gen allow1 = 60000
gen allow2 = an_income * 0.20 if E19 == 6
 
egen allow = rowtotal(allow1 allow2)
replace allow = (-1) * allow

drop allow1 allow2

egen tax_base = rowtotal(an_income allow)
replace tax_base = 0 if tax_base < 0

gen exemp_ind = 0
replace exemp_ind = 1 if tax_base <= 60000
replace exemp_ind = 1 if inlist(E8, 1, 2)

replace tax_ind = 0 if exemp_ind == 1 
 

ren (tax_ind allow an_income tax_base) (tax_ind_1 allow_1 an_income_1 tax_base_1)
 
gen regime_1 = tax_ind_1



* Tax
local tax1 = 0.15 // 0.15
local tax2 = 0.25 // 0.25
local tax3 = 0.40 // 0.40

gen tranche = 0
replace tranche = 1 if inrange(tax_base, 1, 90000) 
replace tranche = 2 if inrange(tax_base, 90000, 21000) 
replace tranche = 3 if inrange(tax_base, 21000, .) 

gen income_tax = 0
replace income_tax = tax_base * `tax1' if tranche == 1
replace income_tax = tax_base * `tax2' - 9000  if tranche == 2
replace income_tax = tax_base * `tax3' - 40500 if tranche == 3

replace income_tax = 0 if income_tax < 0




**---------- Tax entreprises
* Principal activity
gen emp2 = inrange(E10, 7, 8) & E13C == 1
gen tax_ind2 = emp2 == 1 & E20A2>0 & E20A2!=. & E20A1 == 1
gen tax_base2 = E20A2*E15 if tax_ind2 == 1

tab E10 emp2 [iw = hhweight]
tab E10 tax_ind2 [iw = hhweight]


gen regime = 0
replace regime = 1 if E11 == 10 & tax_ind2 == 1
replace regime = 2 if inrange(E11, 5, 9) & tax_ind2 == 1

* Tax
local tax1 = 0.03
local tax2 = 0.3

gen income_tax2 = 0
replace income_tax2 = tax_base2 * `tax1' if regime == 1
replace income_tax2 = tax_base2 * `tax2' if regime == 2

tabstat tax_ind2 tax_base2 income_tax2 [aw = hhweight], s(sum) by(regime)


**---------- Tax property
gen tax_ind3 = F1 == 1 & G0 == 1

gen tax_base3 = 12751.6 if tax_ind2 == 1

local tax1 = 0.1

gen income_tax3 = 0
replace income_tax3 = tax_base3 * `tax1' if tax_ind2 == 1


tabstat tax_ind3 tax_base3 income_tax3 [aw = hhweight], s(sum) by(regime)

keep hhid tax_ind* tax_base* income_tax* allowance tranche regime

save "$presim/02_Income_tax_input.dta", replace







