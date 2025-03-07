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




