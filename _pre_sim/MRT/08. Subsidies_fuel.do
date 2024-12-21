/*=============================================================================

	Project:		Agricultural Subsidies - Presim
	Author:			Gabriel 
	Creation Date:	Sep 23, 2024
	Modified:		
	
	Note: 
	
==============================================================================*/

	
set seed 123456789	
	
use "$presim/05_purchases_hhid_codpr.dta", clear
		
* Carbon Products 
gen fuel =  inlist(codpr, 233, 234, 254, 255)
		
tab codpr if fuel // All expenses for 377 equal to 0

tab coicop fuel [iw = depan], row nofreq

keep if fuel == 1

gen gasoil = codpr == 255
gen gasoline = codpr == 254
gen lpg = codpr == 233
gen kerosene = codpr == 234


global fuel "gasoil gasoline lpg kerosene"

foreach i of global fuel {
	gen c_`i' = depan * `i'
	drop `i'
}

keep hhid c_*

gcollapse (sum) c_gasoil c_gasoline c_lpg c_kerosene, by(hhid)

merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight)

egen c_fuel = rowtotal(c_*)

global fuel "fuel ${fuel}" 

* Validation
gen uno = 1

foreach i of global fuel {
	gen d_`i' = c_`i' > 0 & c_`i' != .
}

tabm d_* [iw = hhweight], row

* Prices
* Gasoil = 3.3%, gasoline = 3.4%, LPG = 71.5%, kerosene = 3.5%

gen sub_gasoline = c_gasoline * -0.1 / 100
gen sub_gasoil = c_gasoil * 2.1 / 100
gen sub_lpg = c_lpg * 10 / 100
gen sub_kerosene = c_kerosene * -21.2 / 100

drop sub_kerosene

tabstat c_* [aw = hhweight], s(mean sum)
tabstat sub_* [aw = hhweight], s(sum)


keep hhid sub*

egen sub_fuel = rowtotal(sub_*)


save "$presim/08_subsidies_fuel.dta", replace



