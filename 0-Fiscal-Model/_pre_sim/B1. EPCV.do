/*============================================================================*\
 EPCV Survey Data
 Authors: Gabriel Lombo
 Start Date: March 2025
 Update Date: 
\*============================================================================*/
   
/*
*----- Data tyding and cleaning
* Primary Key
* Variables // keep, names, label and type (missing)

*----- Data construction
* Join
* Indicators
* Label
*/   
 

set seed 123456789

	
*===============================================================================
// B: EPCV data
*===============================================================================
		
*-------------------------------------
// Parameters
*-------------------------------------
	
* International poverty lines	
global ppp = 12.44526 * 10
global ppp_ipc19 = 1.05471		

/* Labels
global line_1
global line_2
global line_3
*/	
*-------------------------------------
// Household: Household Data
*-------------------------------------

use "$data_sn/EPCV2019_income.dta" , clear

*----- Data tyding and cleaning
* Primary Key
isid hid idp

* Variables
keep hid idp wgt hhsize pcc wilaya

sum *
*tabmiss *

ren hid hhid
ren wgt hhweight

*----- Data construction
collapse (sum) dtot = pcc, by(hhid hhweight hhsize wilaya)

ren hhid hid

merge 1:1 hid using "$data_sn/menage_pauvrete_2019.dta", keep(matched) keepusing(hhweight hhsize zref pcexp) nogen

gen pcc = dtot / hhsize

gen pondih = hhweight * hhsize

_ebin pcc [aw = pondih], nq(10) gen(decile_expenditure)

drop pondih
ren hid hhid

gen line_1 = 2.15 * 365 * ${ppp} * ${ppp_ipc19}
gen line_2 = 3.65 * 365 * ${ppp} * ${ppp_ipc19}
gen line_3 = 6.85 * 365 * ${ppp} * ${ppp_ipc19}


* Label

save "$presim/01_menages.dta", replace


*-------------------------------------
// Individual Data
*-------------------------------------

use "$data_sn/individus_2019.dta", clear

*----- Data tyding and cleaning
* Primary Key
isid hid idind

* Variables
ren hid hhid
ren idind indid

keep hhid indid

save "$presim/B2-Individual.dta", replace

*-------------------------------------
// Expenditure Data
*-------------------------------------

use "$data_sn/pivot2019.dta" , clear

*----- Data tyding and cleaning
* Primary Key
isid hid Prod source methode

* Variables
keep hid Prod source methode dep fonction class_EPCV2019 wta_pop

ren hid hhid
ren Prod codpr
ren dep depan
ren fonction coicop

*----- Data construction
merge m:1 hhid using "$presim/01_menages.dta", nogen keepusing(decile_expenditure hhweight hhsize) keep(3) //Get decile

merge m:1 decile_expenditure coicop using "${presim}/Aux_informality.dta", nogen keepusing(informal_purchase) keep(1 3) // Get informality

tab source
drop if inlist(source, 1, 3)

collapse (sum) depan [aw=hhweight], by(hhid hhsize codpr coicop informal_purchase decile_expenditure)


* Label

save "$presim/05_purchases_hhid_codpr.dta", replace







