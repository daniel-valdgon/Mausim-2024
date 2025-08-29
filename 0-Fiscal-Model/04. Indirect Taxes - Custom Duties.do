/*============================================================================*\
 Indirect Taxes simulation - Custom Duties
 Authors: Gabriel Lombo
 Start Date: January 2024
 Update Date: April 2025
\*============================================================================*/
 
clear
gen codpr=.
gen CD=.
gen imported=.
local i=1
foreach prod of global products {
	set obs `i'
	qui replace codpr	 = `prod' in `i'
	qui replace CD      = ${cdrate_`prod'} if codpr==`prod' in `i'
	qui replace imported = ${cdimp_`prod'} if codpr==`prod' in `i'
	local i=`i'+1
}
tempfile CDrates
save `CDrates'


*-------------------------------------
// Direct Effect
*-------------------------------------

use "$presim/05_netteddown_expenses_SY.dta", clear
*use "$tempsim/Excises_verylong.dta", clear

isid hhid codpr informal_purchase

merge m:1 codpr using `CDrates', nogen keep(1 3)

replace CD = 0 if imported == 0

tab CD imported

gen CD_direct = achats_net * CD // * (1 - informal_purchase)


*-------------------------------------
// Income definition
*-------------------------------------

*gen achats_avec_VAT = (achats_avec_excises + CD_direct)
gen achats_avec_CD = (achats_net + CD_direct)

gen dif4 = achats_net - achats_avec_CD

tab codpr if abs(dif4)>0.0001

tabstat achats_net_sub achats_avec_CD, s(sum mean p50)


if $asserts_ref2018 == 1 {
	assert abs(dif4)<0.0001
}

if $devmode== 1 {
    save "$tempsim/FinalConsumption_verylong.dta", replace
}
else{
	save `FinalConsumption_verylong', replace
}

*-------------------------------------
// Data by household
*-------------------------------------



collapse (sum) CD_direct achats_net achats_avec_CD /*achats_avec_excises achats_sans_subs achats_sans_subs_dir*/, by(hhid)

label var achats_avec_CD "Purchases after custom duties"

if $devmode== 1 {
	save "${tempsim}/CustomDuties_taxes.dta", replace
}

* CHECK...
merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight)

tabstat * [aw = hhweight], s(sum mean)








