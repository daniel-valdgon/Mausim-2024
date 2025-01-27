

/*
Author:			Gabriel Lombo
Start date: 	24 April 2024
Last Update: 	22 June 2024

Note:		 	Validation of Administrative data with the survey
Sources: 		1. PER
				2. BOOST, Taazour
			
Figures:		1. Tekavoul 
					a) 0.1% - 2019; 0.2% - 2021 : GDP expenditures - PER 
					b) 0.06% - 2019; 0.16% - 2021 : GDP expenditures - BOOST
				2. School lunches 
					a) 120.000 students
				3. Food transfers
*/

global path			"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mauritania/Mausim_2024"
global data_sn 		"${path}/01_data/1_raw/MRT"    
global presim 		"${path}/01_data/2_pre_sim/MRT"    


/*------------------------------------------------
* Food Consumption Score - FCS
------------------------------------------------*/

import excel "${data_sn}/Other/SA.xlsx", clear first 

keep codpr categoryFCP categoryFCP_2

tempfile SA_prod
save `SA_prod'

use "$data_sn/Datain/auto_2019.dta", clear

* Household id
tostring US_ORDRE A7, replace
gen len = length(A7)
replace A7 = "0" + A7 if len == 1
gen hhid = US_ORDRE + A7
destring hhid, replace  

ren K0 codpr
merge m:1 codpr using `SA_prod', keep(1 3) 

labmask categoryFCP, values(categoryFCP_2)

tab categoryFCP, nol

local category "Stap Pulse Dairy Pr Veg Fruit Fat Sugar Cond"

forvalues i = 1/7 {
	local var : word `i' of `category'
	gen FCS`var' = K2 * 7/12 if categoryFCP == `i'
}

gen FCSSugar = 0

gcollapse (mean) FCS*, by(hhid)


*------------------------------------------------------------------------------*

*	                        WFP RAM Standardized Scripts
*                     Calculating Food Consumption Score (FCS)
*-----------------------------------------------------------------------------


** Label FCS relevant variables
	label var FCSStap		"Consumption over the past 7 days: cereals, grains and tubers"
	label var FCSPulse		"Consumption over the past 7 days: pulses"
	label var FCSDairy		"Consumption over the past 7 days: dairy products"
	label var FCSPr			"Consumption over the past 7 days: meat, fish and eggs"
	label var FCSVeg		"Consumption over the past 7 days: vegetables"
	label var FCSFruit		"Consumption over the past 7 days: fruit"
	label var FCSFat		"Consumption over the past 7 days: fat and oil"
	label var FCSSugar		"Consumption over the past 7 days: sugaror sweets"
	*label var FCSCond		"Consumption over the past 7 days: condiments or spices"

** Clean and recode missing values
	recode FCSStap FCSVeg FCSFruit FCSPr FCSPulse FCSDairy FCSFat FCSSugar (. = 0)

** Create FCS 
	gen FCS = (FCSStap * 2) + (FCSPulse * 3) + (FCSDairy * 4) + (FCSPr * 4) + 	///
			  (FCSVeg  * 1) + (FCSFruit * 1) + (FCSFat * 0.5) + (FCSSugar * 0.5)	  

	label var FCS "Food Consumption Score"

** Create FCG groups based on 21/35 or 28/42 thresholds
*** Use this when analyzing a country with low consumption of sugar and oil

*** thresholds 21-35
	gen FCSCat21 = cond(FCS <= 21, 1, cond(FCS <= 35, 2, 3))
	label var FCSCat21 "FCS Categories, thresholds 21-35"

*** thresholds 28-42
	gen FCSCat28 = cond(FCS <= 28, 1, cond(FCS <= 42, 2, 3))
	label var FCSCat28 "FCS Categories, thresholds 28-42"


*** define variables labels and properties for "FCS Categories"
	label def FCSCat 1 "Poor" 2 "Borderline" 3 "Acceptable"
	label val FCSCat21 FCSCat28 FCSCat
	
	merge 1:1 hhid using "$presim/01_menages.dta", nogen keep(3) keepusing(hhsize hhweight)
	
	ren hhid hid
	
	merge 1:1 hid using "$data_sn/elmaouna.dta", nogen keep(3)

	merge 1:1 hid using "$data_sn/program_EPCV.dta", nogen keep(3)
	
	tab1 FCSCat21 FCSCat28 [iw = hhweight]
	
	sum FCS
	
	tabstat FCS if FCS>0 & milieu == 2 [aw = hhweight], s(mean p50) by(elmaouna)
	
	
	
	
forvalues i = 1/6 {
	tab hh_prog_`i' [iw = hhweight]
	*reg hh_prog_`i' FCS if FCS>0
}

asgsf


tabstat hh_prog_1 hh_prog_2 hh_prog_3 hh_prog_4 hh_prog_5 hh_prog_6 [aw = hhweight], s(mean sum) 

tabstat hh_prog_amount_1 hh_prog_amount_2 hh_prog_amount_3 hh_prog_amount_4 hh_prog_amount_5 hh_prog_amount_6 [aw = hhweight], s(mean sum) 
	
tab wilaya [iw = hhweight] if hh_prog_6==1
	

tabstat hh_prog_amount_6 [aw = hhweight] if hh_prog_6, s(p25 p50 p75 mean sd count) by(wilaya)
	
	
	
tabstat hh_prog_amount_6 [aw = hhweight] if hh_prog_6, s(p25 p50 p75 mean sd count) by(hhsize)
	
	
logit hh_prog_2 FCS if FCS>0
	
	
egen mode = mode(hh_prog_amount_6) if hh_prog_6==1, by(wilaya) minmode
tabstat mode [aw = hhweight] if hh_prog_6, s(mean count) by(wilaya)
	
egen mode2 = mode(hh_prog_amount_6) if hh_prog_6==1, by(hhsize) minmode
tabstat hh_prog_amount_6 mode2 [aw = hhweight] if hh_prog_6, s(p50) by(hhsize)
	
	
	
	* other
	
	tab wilaya hh_prog [iw = hhweight], nol row nofreq
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	