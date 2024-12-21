/*======================================================
 =======================================================

	Project:		Read Data used in presim
	Author:			Gabriel 
	Creation Date:	Apr 21, 2023
	Modified:		
	
	Note:
	Data input: 	1. Informality Bachas
					2. EPCV2019_income
					3. pivot2019

	Data output: 	1. 01_menages
					2. 05_purchases_hhid_codpr
					3. IO_Matrix
========================================================
=======================================================*/


*ssc install gtools
*ssc install ereplace
*net install gr0034.pkg

set seed 123456789

*-----  Bachas Informality - Recode coicop
use "$data_sn/informality_Bachas_mean.dta", clear

* Standardization
keep decile_expenditure product_name c_inf_mean
ren c_inf_mean informal_purchase

gen coicop = .
replace coicop = 1 if product_name == "Food and non-alcoholic beverages"
replace coicop = 2 if product_name == "Alcoholic beverages, tobacco and narcotics"
replace coicop = 3 if product_name == "Clothing and footwear"
replace coicop = 4 if product_name == "Housing, water, electricity, gas and other fuels"
replace coicop = 5 if product_name == "Furnishings, household equipment and routine household maintenance"
replace coicop = 6 if product_name == "Health"
replace coicop = 7 if product_name == "Transport"
replace coicop = 8 if product_name == "Communication"
replace coicop = 9 if product_name == "Recreation and culture"
replace coicop = 10 if product_name == "Education"
replace coicop = 11 if product_name == "Restaurants and hotels"
replace coicop = 12 if product_name == "Miscellaneous goods and services"

labmask coicop, values(product_name)

tempfile Bachas_mean
save `Bachas_mean', replace


*----- Household Data
use "$data_sn/EPCV2019_income.dta" , clear

* Standardization
keep hid idp wgt hhsize pcc

ren hid hhid
ren wgt hhweight

* Disposable Income
collapse (sum) dtot = pcc, by(hhid hhweight hhsize)

ren hhid hid
merge 1:1 hid using "$data_sn/menage_pauvrete_2019.dta", keep(matched) keepusing(hhweight hhsize zref pcexp) nogen

gen pcc = dtot/hhsize

gen pondih = hhweight*hhsize
_ebin pcc [aw=pondih], nq(10) gen(decile_expenditure)

drop pondih
ren hid hhid
/**** Create poverty lines

* MRT: i2017 - 1.05, i2018 - 0.65, i2019 - 0.98. ccpi_a
* MRT: i2017 - 3.0799999,	i2018 - 4.2035796. fcpi_a
* MRT: i2017 - 2.269, i2018 - 3.07. hcpi_a
* MRT Inflation according to WorldBank Data Dashboard. 2017 - 2.3, 2018 - 3.1
* Country specific...

local ppp17 = 12.4452560424805
local inf17 = 2.3
local inf18 = 3.1
local inf19 = 2.3
cap drop line_1 line_2 line_3
gen line_1=2.15*365*`ppp17'*`inf17'*`inf18'*`inf19'
gen line_2=3.65*365*`ppp17'*`inf17'*`inf18'*`inf19'
gen line_3=6.85*365*`ppp17'*`inf17'*`inf18'*`inf19'

foreach var in /*line_1 line_2 line_3*/ yd_pc yc_pc  {
	gen test=1 if `var'<=zref
	recode test .= 0
	noi tab test [iw=hhweight*hhsize]
	drop test
}
*/

save "$presim/01_menages.dta", replace



*----- Purchases Data
use "$data_sn/pivot2019.dta" , clear

* Standardization
keep hid Prod source methode dep fonction class_EPCV2019 wta_pop

ren hid hhid
ren Prod codpr
ren dep depan
ren fonction coicop

* Merge data 
merge m:1 hhid using "$presim/01_menages.dta", nogen keepusing(decile_expenditure hhweight hhsize) keep(3) //Get decile
merge m:1 decile_expenditure coicop using `Bachas_mean', nogen keepusing(informal_purchase) keep(1 3) // Get informality

* Exclude auto-consumption, donation and transfers
tab source
drop if inlist(source, 1, 3)

* HH and product level
collapse (sum) depan [aw=hhweight], by(hhid hhsize codpr coicop informal_purchase decile_expenditure)


save "$presim/05_purchases_hhid_codpr.dta", replace


*----- IO Matrix
import excel "$data_sn/IO_Matrix.xlsx", sheet("IO_matrix") firstrow clear
	 
local thefixed 		"8 9" 
local sect_elec  	"8"
local sect_emel 	"1"
local sect_fuel 	"9 12"

 	
gen fixed=0
foreach var of local thefixed {
	replace fixed=1  if  sector==`var'
}

gen elec_sec=0
foreach var of local sect_elec {
	replace elec_sec=1  if  sector==`var'
}

gen emel_sec = 0
foreach var of local sect_emel {
	replace emel_sec=1  if  sector==`var'
}

gen fuel_sec = 0
foreach var of local sect_fuel {
	replace fuel_sec=1  if  sector==`var'
}
	
save "$presim/IO_Matrix.dta", replace


*----- Create Maps
shp2dta using "$data_sn/Shapes/mrt_admbnda_adm1_ansade_20240327.shp", database("$presim/mrtdb") coordinates("$presim/mrtcoord") genid(id) replace






