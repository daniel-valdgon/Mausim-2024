/*=============================================================================

	Project:		Agricultural Subsidies - Presim
	Author:			Gabriel 
	Creation Date:	Sep 23, 2024
	Modified:		
	
	Note: 
	
==============================================================================*/

	
set seed 123456789	
	
use "$presim/05_purchases_hhid_codpr.dta", clear

*use "$presim/05_netteddown_expenses_SY.dta", clear

merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight)

		
* Carbon Products 
gen fuel =  inlist(codpr, 233, 234, 254, 255)
		
tab codpr if fuel // All expenses for 377 equal to 0


global purchases depan

tabstat $purchases [aw = hhweight] if fuel == 1 , s(p10 p25 p50 p75 p90 min max mean sum) by(codpr)


*tab coicop fuel [iw = $purchases], row nofreq

keep if fuel == 1

gen lpg = codpr == 233
gen kerosene = codpr == 234
gen gasoline = codpr == 254
gen gasoil = codpr == 255



global fuel "lpg kerosene gasoline gasoil"

foreach i of global fuel {
	gen c_`i' = $purchases * `i' * (1 - informal_purchase)
	drop `i'
}

keep hhid c_*

gcollapse (sum) c_lpg c_kerosene c_gasoline c_gasoil  , by(hhid)

merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight)

egen c_fuel = rowtotal(c_*)

global fuel "fuel ${fuel}" 

* Validation
gen uno = 1

foreach i of global fuel {
	gen d_`i' = c_`i' > 0 & c_`i' != .
}

tabm d_* [iw = hhweight], row


*drop sub_kerosene

tabstat c_* [aw = hhweight], s(mean sum)

keep hhid c_*

*egen sub_fuel = rowtotal(sub_*)


save "$presim/08_subsidies_fuel.dta", replace



