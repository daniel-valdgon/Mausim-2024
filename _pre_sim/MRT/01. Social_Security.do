/*=============================================================================

	Project:		Social Security - Presim
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

keep hhid idind hhweight wilaya milieu B2 B4 E* F* G0 G12B D13

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

*---------- Parameters

local ap_private 	0.14
local ap_public 	0.18

*---------- Tax income

gen tax_ind = E18B == 1 & pos == 1
replace tax_ind = 0 if E19 == 7

gen an_income = income * 12 if tax_ind == 1
 
*---------- Social Contributions
gen public = inrange(E11, 1, 4)

tab E11 public [iw = hhweight] if tax_ind == 1, m

gen ss_contrib_pub = an_income * `ap_public' * public
gen ss_contrib_pri = an_income * `ap_private' * (1 - public)

egen ss_contrib =  rowtotal(ss_contrib_pub ss_contrib_pri)

*---------- Pensions

local soc_cont 	28830 // Mean wage MRO
local pen_old	1.50 // 150% publico o 40% privado
local pen_other	0.50 // Orphans 

tab E8 [iw = hhweight]

tab D13 E8 [iw = hhweight] if inlist(E8, 1, 2), m col nofreq
tab D13 E18B [iw = hhweight] if tax_ind == 1, col

gen pen_old = E8 == 1
gen pen_other = E8 == 2

gen ss_ben_old = `soc_cont' * `pen_old' * pen_old
gen ss_ben_other = `soc_cont' * `pen_other' * pen_other

egen ss_ben =  rowtotal(ss_ben_old ss_ben_other)


* CNAM
gen cnam = D13 == 1

keep hhid idind ss_contrib* ss_ben* cnam


save "$presim/01_social_security.dta", replace



