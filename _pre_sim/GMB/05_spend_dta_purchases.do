** PROYECT: Mauritania CEQ
** TO DO: Data cleansing of purchases, presim
** EDITED BY: Madi Mangan
** LAST MODIFICATION: 14 February 2024

*ssc install gtools
global path2 "/Users/manganm/Documents/GitHub/vat_tool/_pre_sim/GMB"

* Bachas Informality - Recode coicop
use "$data_sn/informality Bachas_mean.dta", clear

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

tempfile Bachas_mean
save `Bachas_mean', replace


* Get Deciles of income and aggregate by household
use "$data_sn/Welfare_temp.dta" , clear

keep hid pc_hhdr pl_abs pl_ext pl_fd wta_hh cons_decile_nom hhsize rururb hhtexp wel_abs

*gsort hid idp
*ren pl_abs zref

gen zref = pl_abs

ren wel_abs dtot2
ren wta_hh hhweight

ren pc_hhdr pcc
ren cons_decile_nom q_pcc
*gen dtot = hhtexp
ren rururb rural
gen consum = pcc
ren hid hhid
*ren pl_ext zref

gen dtot = dtot2*hhsize

drop dtot2
/*
gen double yd_pre=round(dtot/hhsize,0.01)

gen all = 1
tab all [iw = hhweight*hhsize]

global vars "dtot dtot2 yd_pre"
sp_groupfunction [aw=hhweight*hhsize], gini($vars) theil($vars) poverty($vars) povertyline(pl_fd pl_abs pl_ext zref) by(all)

tab all variable [iw = value] if reference == "zref" & measure == "fgt0"
*/

save "$presim/01_menages.dta", replace


**** TVA import parameters
clear
gen codpr=.
gen TVA=.
gen formelle=.
gen exempted=.
local i=1
foreach prod of global products {
	set obs `i'
	qui replace codpr	 = `prod' in `i'
	qui replace TVA      = ${vatrate_`prod'} if codpr==`prod' in `i'
	qui replace formelle = ${vatform_`prod'} if codpr==`prod' in `i'
	qui replace exempted = ${vatexem_`prod'} if codpr==`prod' in `i'
	local i=`i'+1
}
tempfile VATrates
save `VATrates'


* See purchases
use "$data_sn/all_purchase_coicop" , clear
drop if hid=="" // check this later, hid cannot be missing 

ren hid hhid
merge m:1 hhid using "$presim/01_menages.dta" // nogen //
drop if _m ==1. // investigage later, this is some issues with the using data, all unmerged have consumption equals to zero. 
drop _m
ren category cat_old

// lets attempt to clean the variable category 
gen category = ""
replace category = "Food and non-alcoholic beverages" if code <=257
replace category = "Alcoholic beverages, tobacco and narcotics" if code >257 & code <=412
replace category = "Clothing and footwear" if code >=700 & code<=782
replace category = "Housing, water, electricity, gas and other fuels" if category == "Electricity, Gas, and other fuels" | category == "Rent.dta" | category == "Utilities.dta" | item == "Charcoal" | item == "Biogas (saw dust/briquette, etc)" | item == "Firewood"
replace category = "Furnishings, household equipment and routine household maintenance" if category == "Electricity, Gas, and other fuels" | category == "Equipment for House" | category == "Furniture, Furnishing, Decorations" | category == "Non-Durable Household Goods" | category == "Household Textiles" | item == "Bleach (ordsavel)" | item == "Candle" | code >=413 & code<= 424
replace category = "Health" if category == "Health.dta"
replace category = "Transport" if code >=608 & code <= 633
replace category = "Communication" if code >= 634 & code <= 638 | item == "internet costs" | item == "mobile communication (nopal, e-credit)" | item == "mobile communication (scratch cards)" | item == "newspapers (local daily)"
replace category = "Recreation and culture" if category == "Hair dressing, Saloon, and Personal Grooming" | item == "Cassette/DVD rental" | code>= 639 & code<=646
replace category = "Education" if category == "Mod 4 Education expenditure.dta"
replace category = "Restaurants and hotels" if category == "Restaurant.dta"
replace category = "Miscellaneous goods and services" if category == "Miscellaneous Goods and Services " | item == "Other frequent (specify)"

*replace category = "Recreation and culture" if category "Nonfood (12 months)" /*== "Nonfood (12 months)"   | category == "Nonfood (3 months)" */ // not completely correct


gen coicop = .
replace coicop = 1 if category == "Food and non-alcoholic beverages"
replace coicop = 2 if category == "Alcoholic beverages, tobacco and narcotics"
replace coicop = 3 if category == "Clothing and footwear"
replace coicop = 4 if category == "Housing, water, electricity, gas and other fuels"
replace coicop = 5 if category == "Furnishings, household equipment and routine household maintenance"
replace coicop = 6 if category == "Health"
replace coicop = 7 if category == "Transport"
replace coicop = 8 if category == "Communication"
replace coicop = 9 if category == "Recreation and culture"
replace coicop = 10 if category == "Education"
replace coicop = 11 if category == "Restaurants and hotels"
replace coicop = 12 if category == "Miscellaneous goods and services"
replace coicop = 9 if coicop==.

* Informality with bachas data
ren (q_pcc) (decile_expenditure)


merge m:1 decile_expenditure coicop using `Bachas_mean', gen(mr_bachas)
drop if mr_bachas==2


* Variables of interest
keep hhid hhweight hhsize code purchase vat_0 /* poste milieu wilaya */ c_inf_mean decile_expenditure

* HH and product level
collapse (sum) purchase [aw=hhweight], by(hhid hhsize code vat_0 /* poste milieu wilaya */ c_inf_mean decile_expenditure)

ren (code purchase hhsize vat_0) (codpr depan hsize TVA)

gen informal_purchase = c_inf_mean

* We need to compute the purchases before taxes!!!!!!!!!!!!!
gen depan_for = depan* (1-informal_purchase)/(1+TVA)
gen depan_inf = depan* informal_purchase

egen depan2 =rowtotal(depan_for depan_inf)

*replace depan= depan2  // actually the computation is even more complex because shuold include also the indirect effects  




save "$presim/05_purchases_hhid_codpr.dta", replace

qui: include "${path2}/Consumption_NetDown.do"
replace depan = achats_net_VAT
keep TVA c_inf_mean codpr decile_expenditure depan depan2 depan_for depan_inf hhid hsize informal_purchase


save "$presim/05_purchases_hhid_codpr.dta", replace


/*
global informality_decrease = 0 // 0 keep the lvl of informality


if $informality_decrease == 1 {
	noi dis as result "Simulation with assumption on informality decrease of $informality_rate"
	
	*replace informal_purchase = informal_purchase*(1- $informality_rate) 
	save "$presim/05_purchases_hhid_codpr.dta", replace

} 
else {
	save "$presim/05_purchases_hhid_codpr.dta", replace
}


preserve 
   import excel "$xls_sn", sheet("IO_percentage_GMB") firstrow clear
   *ren Secteur sector
   duplicates drop codpr, force
   save "$presim/IO_percentage_GMB.dta", replace 
restore
*/








