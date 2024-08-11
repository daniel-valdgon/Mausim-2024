/*=============================================================================

	Project:		Direct Taxes - Presim
	Author:			Gabriel 
	Creation Date:	July 18, 2024
	Modified:		
	
	Note: 
	
==============================================================================*/

	
use "$data_sn/Datain/individus_2019.dta", clear
		
ren hid hhid
	
merge m:1 hhid using "$presim/01_menages.dta", nogen keep(3) keepusing(hhweight hhsize)

gen uno = 1

keep hhid hhweight B2 B4 E* F* G0

/* Working-age population
gen female = (B2==2)
gen wa_pop = inrange(B4,15,64)
gen nwa_pop = inrange(B4,0,14)
gen n2wa_pop = inrange(B4,65,96)

tab1 E6A E6B [iw = hhweight]

* Individuals
tab E10 E19 [iw = hhweight], row nofreq
tab E10 E12 [iw = hhweight], row nofreq
*/
** Tax income
* Principal activity
gen employee_1 = .
replace employee_1 = 1 if inrange(E10, 1, 1)
replace employee_1 = 0 if inrange(E10, 2, 12)

gen tax_ind_1 = E18B == 1 & E20A2>0 & E20A2!=. & E20A1 == 1
replace tax_ind_1 = 0 if E19 == 7

gen tax_base_1 = E20A2*E15 if tax_ind_1 == 1
 

/* Secondary activity
gen employee_2 = .
replace employee_2 = 1 if inrange(E27, 1, 1)
replace employee_2 = 0 if inrange(E27, 2, 12)

gen tax_ind_2 = employee_2 == 1 & E31A2>0 & E31A2!=. & E31A1 == 1
gen tax_base_2 = E31A2*E29 if tax_ind_2 == 1

gen tax_ind = tax_ind_1 == 1 | tax_ind_2 == 1
*/
* Allowances
gen allow1 = 60000
gen allow2 = tax_base_1 * 0.20 if E19 == 6

egen allowance = rowtotal(allow1 allow2)
replace allowance = (-1) * allowance

egen tax_base = rowtotal(tax_base_1 allowance)
replace tax_base = 0 if tax_base <0


* Exemptions
gen exemptions = 0
replace exemptions = 1 if tax_base <= 60000
replace exemptions = 1 if inlist(E8, 1, 2)

replace tax_ind = 0 if exemptions == 1

sum tax_ind allowance tax_base [iw = hhweight]


* Tax
local tax1 = 0.1 // 0.15
local tax2 = 0.2 // 0.25
local tax3 = 0.3 // 0.40

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







