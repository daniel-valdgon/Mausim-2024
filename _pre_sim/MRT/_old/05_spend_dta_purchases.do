** PROYECT: Mauritania CEQ
** TO DO: Data cleansing of purchases, presim
** EDITED BY: Gabriel Lombo and Daniel Valderrama
** LAST MODIFICATION: 18 January 2024


*ssc install gtools
*ssc install ereplace

global country 		"MRT"
global data_sn 		"${pathdata}/01_data/1_raw/${country}"  

* Bachas Informality - Recode coicop
use "$data_sn\s_Bachas.dta", clear

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


* Get Deciles of income/consumption and aggregate by household
use "$data_sn/s_EPCV.dta" , clear

ren wgt hhweight

egen tag = tag(hid)
gen uno =1 
tab uno [iw = hhweight]
tab uno tag [iw = hhweight*hhsize]


collapse (sum) income = pci consum = pcc, by(hid hhweight hhsize wilaya rural)

gen pci = income/hhsize
gen pcc = consum/hhsize

merge 1:1 hid using "$data_sn/menage_pauvrete_2019.dta", keep(matched)

* By Household @gabriel use quantiles or _ebin using stable option 
xtile q_pci = pci [aw=hhweight*hhsize], n(10)  //@Gabriel delete this xtile if it is not used
xtile q_pcc = pcc [aw=hhweight*hhsize], n(10) // Use consumption



*gen all = 1
*tab all [iw = hhweight]
*global vars "pcexp q_pci q_pcc pci pcc income consum"
*sp_groupfunction [aw=hhweight*hhsize], gini($vars) theil($vars) poverty($vars) povertyline(zref) by(all)


ren hid hhid

save "$presim/01_menages.dta", replace



**** TVA import parameters
clear
gen codpr=.
gen TVA=.
*gen formelle=.
*gen exempted=.
local i=1
foreach prod of global products {
	set obs `i'
	qui replace codpr	 = `prod' in `i'
	qui replace TVA      = ${vatrate_`prod'} if codpr==`prod' in `i'
	*qui replace formelle = ${vatform_`prod'} if codpr==`prod' in `i'
	*qui replace exempted = ${vatexem_`prod'} if codpr==`prod' in `i'
	local i=`i'+1
}
tempfile VATrates
save `VATrates'



* See purchases
use "$data_sn/pivot2019.dta" , clear
  
ren (hid Prod dep) (hhid codpr depan)
merge m:1 hhid using "$presim/01_menages.dta", nogen //@Gabriel use keepusing here to know which variables are you using

* Informality with bachas data
ren (q_pcc fonction) (decile_expenditure coicop)

* Impute informality by decil and coicop
merge m:1 decile_expenditure coicop using `Bachas_mean', gen(mr_bachas)

* Get VAT parameters
merge m:1 codpr using `VATrates', nogen keep(1 3) keepusing(TVA)

* Exclude auto-consumption, donation and transfers
tab source
drop if inlist(source, 1, 3)

* Variables of interest
keep hhid hhweight hsize codpr depan poste milieu wilaya c_inf_mean decile_expenditure TVA

* HH and product level
collapse (sum) depan [aw=hhweight], by(hhid hsize codpr poste milieu wilaya c_inf_mean decile_expenditure TVA)

ren c_inf_mean informal_purchase

* We need to compute the purchases before taxes!!!!!!!!!!!!!
gen depan_for = depan* (1-informal_purchase)/(1+TVA)
gen depan_inf = depan* informal_purchase

ereplace depan=rowtotal(depan_for depan_inf)  // actually the computation is even more complex because shuold include also the indirect effects  

save "$presim/05_purchases_hhid_codpr.dta", replace




* Check
/* Check dapan

use "$presim/05_purchases_hhid_codpr.dta", clear

collapse (sum) depan (mean) c_inf_mean, by(hhid hsize)

merge 1:1 hhid  using "$presim/01_menages.dta", nogen

gen pcdepan = round(depan/hhsize,0.01)

br pc*

gen comp = pcc - pcdepan

*tabstat pcc pcdepan comp zref, s(p1 p10 p25 p50 p75 p90 p99 mean sum count)

tabstat pcc pcdepan comp zref [aw = hhweight*hhsize], s(p1 p10 p25 p50 p75 p90 p99 mean sum count)

twoway (kdensity pcc) (kdensity pcdepan) 
*/











