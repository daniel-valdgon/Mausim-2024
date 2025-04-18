/*============================================================================*\
 Agricultural Subsidies
 Authors: Gabriel Lombo
 Start Date: September 2024
 Update Date: 
\*============================================================================*/
 
	
set seed 123456789
	
	
/*-------------------------------------------------------/
	1. Temwine - EMEL
/-------------------------------------------------------*/
	
*------- Welfare Targeting and eligibility
	
use "$presim/PMT_EPCV_harmonized", clear

ren hid hhid

merge 1:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight hhsize) assert (matched)


keep hhid wilaya moughataa milieu PMT hhweight hhsize
	
tabstat PMT [aw = hhweight], s(p25 p50 p75 min max mean) by(wilaya)	

gcollapse (mean) regPMT = PMT [iw = hhweight], by(wilaya moughataa milieu)

*reshape wide regPMT, i(wilaya moughataa) j(milieu)

tempfile PMT 
save `PMT', replace 



use "$presim/PMT_EPCV_harmonized", clear

ren hid hhid

merge 1:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight hhsize) assert (matched)

keep hhid wilaya moughataa milieu PMT hhweight hhsize

merge m:1 wilaya moughataa milieu using `PMT', nogen assert (matched)

gen eleg_1 = 0

sum regPMT [aw = hhweight] if milieu == 1, d
replace eleg_1 = 1 if regPMT < r(p10) & milieu == 1

sum regPMT [aw = hhweight] if milieu == 2, d
replace eleg_1 = 1 if regPMT < r(p10) & milieu == 2

egen max_eleg_1 = max(eleg_1), by(wilaya moughataa milieu)

tabstat max_eleg_1 [aw = hhweight], s(mean) by(wilaya)
	
tab wilaya max_eleg_1 [iw = hhweight]	

keep hhid max_eleg_1 wilaya

tempfile hhEMEL 
save `hhEMEL', replace 
	
*------- Depanses to add subsidy


use "$presim/05_purchases_hhid_codpr.dta", clear

merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight) assert (matched)
	
merge m:1 hhid using `hhEMEL', nogen	
	
gen emel_prod = 0

* Products to be subsidized: Ble, Riz local, Sucre, Huile, Pates

replace emel_prod = 1 if inlist(codpr, 8, 10, 13, 152, 153, 159, 160, 161, 162)

gen uno = 1	
	
tab codpr if emel_prod

tab coicop emel_prod [iw = depan], row nofreq


/*
gen sub_emel = uno * emel_prod * depan * 50/100

gen subsidy_emel_direct = sub_emel
replace subsidy_emel_direct = 227396.4 if sub_emel > 227396.4

*tabstat subsidy_emel_direct [aw = hhweight] if subsidy_emel_direct > 0, s(min max mean sd p50 sum count)  

*tab uno [iw = hhweight] if  subsidy_emel_direct > 0

gcollapse (sum) subsidy_emel_direct (max) max_eleg_1 emel_prod, by(hhid hhsize)
*/
*ren wilaya departement

save "$presim/08_subsidies_emel.dta", replace



/*
di (15600 + 18300 + 14400) / 3

* Inflation rates 2013 - 2019: 4.13 + 3.53 + 3.25 + 1.47 + 2.25 + 3.07 + 2.30
di 4.13 + 3.53 + 3.25 + 1.47 + 2.25 + 3.07

di 16100 * (1 + 17.7/100) *12 // max value of subsidie by year = 18949.7

tabstat depan, s(mean sum) by(emel_prod)
tabstat depan if emel_prod == 1 , s(mean sum) by(codpr)


di 0.130 / 1.59 * 100
*/

/*-------------------------------------------------------/
	2. Fertilizers
/-------------------------------------------------------*/

*------- Communtiy Survey	
* Identification
use "$data_sn/Datain/data_communaitaire_EPCV2019.dta", clear

gunique US_ORDRE A_01

duplicates tag US_ORDRE A_01, gen(dup) // Duplicates by school, D category

keep US_ORDRE A* B1 B2 B5 B6 NOM_DE_LA_OCALITE C1 C1A C1B C1C C9 C10 F* dup
drop AUTEC

gduplicates drop

gunique US_ORDRE A_01

* Check 
gen uno = 1
tab A1 uno

tabstat B*, s(sum) by(A1)

* Agricultural use

sum C*

gen agric = 0
replace agric = 1 if C1A == 1 | C1B == 1 | C1C == 1

gen market = C9 == 1
gen market_d = C10

gen visit = F5 == 1
gen fert = F17 == 1
gen pest = F18 == 1

gunique A1 A2 A3

gcollapse (sum) B1 B2 B5 uno agric market visit fert pest (mean) market_d, by(A1 A2 A3)

foreach var of varlist agric-pest {
	gen d_`var' = `var' > 0
}

sum *

tabstat B*, s(sum) by(A1)

tempfile communautaire 
save `communautaire', replace 


*------- Individual Survey

use "$data_sn/Datain/individus_2019.dta", clear
		
ren hid hhid
	
keep hhid A1 A2 A3 F3 F5 F6 E10* PS8 PS12

merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize)

* Add to houshold level
drop E10 PS8

egen credit_fert = max(PS12 == 8), by(hhid)

drop PS12

gduplicates drop 

* Value in kg of fertilizer

tabstat F3 [aw = hhweight], s(sum)

di (3489.4 + 1508.4 + 1385.1) * 1000 // Total fertilizer in MRT
di 261995  // Total ha in MRT
di 228368.3 / 261995 * 100 // % fertilizer in the survey
di 6382900 * 0.87165137 // Fertilizer to distribute
di 5563663.5 / 228368.3 // 24.4 kg per ha

di 300 / 0.0281 / 1000 * 10 // Value of a kg in MRO for 2019

* Fertilizer consumption
gen fert_use = F3 * 24.4
gen fert_val =  fert_use * 106.76157

tabstat F3 fert_use fert_val [aw = hhweight], s(p10 p25 p50 p75 p90 mean min max sum)

tabstat F3 fert_use fert_val [aw = hhweight] if F3 > 0, s(p10 p25 p50 p75 p90 mean min max sum)

*------- Option 1: Community level
merge m:1 A1 A2 A3 using `communautaire', gen(mr_com)

* Check merge
tab A1 mr_com [iw = hhweight], row nofreq

*gen d_sub = d_fert == 1 | d_pest == 1 


*------- Option 2: Community level

gen d_sub = F3 > 1

*gen subsidy_inag_direct = d_sub * 0.65 * fert_val

*tabstat d_sub subsidy_inag_direct [aw = hhweight], s(p50 mean min max sum)


keep hhid A1 A2 A3 fert pest d_fert d_pest mr_com d_sub fert_use fert_val F3

*--- Final Data

save "$presim/08_subsidies_fert.dta", replace

*merge 1:1 hhid using "$presim/08_subsidies_emel.dta", nogen

*save "$presim/08_subsidies_agric.dta", replace



