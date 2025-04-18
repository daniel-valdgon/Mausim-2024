/*============================================================================*\
 Direct Taxes
 Authors: Gabriel Lombo
 Start Date: July 2024
 Update Date: April 2025
\*============================================================================*/
 
	
/*-------------------------------------------------------/
	0. Prep Data
/-------------------------------------------------------*/

	
	
use "$data_sn/Datain/individus_2019.dta", clear
	
ren hid hhid	
	
merge m:1 hhid using "$presim/01_menages.dta", nogen keep(3) keepusing(hhweight hhsize)

keep hhid idind hhweight wilaya milieu B2 B4 E* F* G0 G12B

gen uno = 1

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
	1. Allocation and Annual Income
/-------------------------------------------------------*/

**---------- Tax entreprises

gen tax_ind = E18B == 1 & pos == 1
replace tax_ind = 0 if E19 == 7

gen an_income = income*12 if tax_ind == 1
  
gen allow1_ind_1 = tax_ind == 1
gen allow2_ind_1 = E19 == 6

ren (tax_ind an_income) (tax_ind_1 an_income_1)
 
gen regime_1 = tax_ind_1


**---------- Tax entreprises
* Principal activity
gen emp2 = inrange(E10, 7, 8) & E13C == 1
gen tax_ind_2 = emp2 == 1 & E20A2>0 & E20A2!=. & E20A1 == 1
gen an_income_2 = E20A2*E15 if tax_ind_2 == 1

gen regime_2 = 0
replace regime_2 = 1 if E11 == 10 & tax_ind_2 == 1
replace regime_2 = 2 if inrange(E11, 5, 9) & tax_ind_2 == 1


**---------- Tax property
gen tax_ind_3 = F1 == 1 & inlist(G0, 1, 3)

gen an_rent = G12B*12


preserve 
	keep wilaya hhweight F1 G0 an_rent
	keep if F1 == 3
	keep if inlist(G0, 1, 3)
	
	collapse (mean) imp_rent = an_rent [aw = hhweight], by(wilaya)
	
	tempfile imp_rent
	save `imp_rent', replace
	
	tab wilaya [iw = imp_rent], 
	
restore

merge m:1 wilaya using `imp_rent', nogen keep(3) 

gen an_income_3 = imp_rent if tax_ind_3  == 1
replace an_income_3 = 0 if tax_ind_3  == 0

gen regime_3 = tax_ind_3

keep hhid idind allow1_ind_* allow2_ind_* an_income_* tax_ind_* regime_* inc_imp2 inc_imp imp_rent


save "$presim/02_Income_tax_input.dta", replace







