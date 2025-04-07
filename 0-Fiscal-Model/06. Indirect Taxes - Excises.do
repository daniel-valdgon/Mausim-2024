*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: CEQ West Africa -  7. Excise Taxes					
* Author: Julieth Pico
* Date: June 2020
* Version: 1.1
* Modified: September 2022
*			- Streamlined, take part to pre_sim
*			May 2023 (AG)
*			- Included new excises from recent laws
*			- Excel TVA rates taken into account (before they were hardcoded as 1.18)
*			March 2024 - Gabriel Lombo
*			- Standardize dofile for different countries according to Excises_raw sheet
*--------------------------------------------------------------------------------


if $devmode== 1 {
    *use "$tempsim/Subsidies_verylong.dta", clear
	use "$presim/05_netteddown_expenses_SY.dta", clear 

}
else{
	use`Subsidies_verylong', clear
}

*gen achats_sans_subs = achats_net_excise
*keep hhid codpr achats_sans_subs achats_net_excise informal_purchase
		
global income achats_net_excise

* Check
*tab codpr [iw = achat_gross] if inrange(codpr, 134, 150)


*********************************************************
*2. Calculate expenses from products with excises
*********************************************************


qui {
forvalues j = 1/$n_excises_taux {
	
	*local j 1
	noi di "`j'. Excise on ${prod_label_ex_`j'}"
	
	* Create dummy of exices
	cap drop dum_`j'
	gen dum_`j' = 0
	
	*local j = 1
	di "${codpr_read_ex_`j'}"
	cap drop n
	
	* Gen local of products lenght
	gen n = length("${codpr_read_ex_`j'}") - length(subinstr("${codpr_read_ex_`j'}", " ", "", .)) + 1
	qui sum n
	local n "`r(mean)'"
	drop n
	
	noi di "This excise has `n' categories with the next products: ${codpr_read_ex_`j'}"

	* Assign product code to the survey excise dummy
	forvalues i = 1/`n' {					
		local var : word `i' of ${codpr_read_ex_`j'}
		
		*noi di "`var'"
		replace dum_`j' = 1 if codpr == `var'
	}	
	
	* Create excises expenses
	gen dep_`j' = dum_`j' * $income
	drop dum_`j'
	
	* Assing tax
	if ($sin_beh == 1) gen double ex_`j' = dep_`j' * ${taux_ex_`j'} + dep_`j' * (${taux_ex_`j'} - ${ref_ex_`j'}) * ${elas_ex_`j'}
	
	if ($sin_beh == 0) gen double ex_`j' = dep_`j' * ${taux_ex_`j'}
	
	*gen double ex_`j' = dep_`j' * ${taux_ex_`j'}
	
	* Assign label
	label var ex_`j' "Excise on ${prod_label_ex_`j'}"

}
}


egen excise_taxes = rowtotal(ex_*)

* Confirmation that the calculation is correct for the survey year policies:
gen achats_avec_excises = achats_net_excise + excise_taxes

if $asserts_ref2018 == 1 {
	gen dif3m = achats_net_VAT - achats_avec_excises

	tab codpr if abs(dif3m)>0.0001
	assert abs(dif3m)<0.0001
}


if $devmode== 1 {
    save "$tempsim/Excises_verylong.dta", replace
}
tempfile Excises_verylong
save `Excises_verylong'


*Finally, we are only interested in the per-household amounts, so we will collapse the database:

collapse (sum) dep_* ex_* excise_taxes, by(hhid)

* Assign label
forvalues j = 1/$n_excises_taux {
	label var ex_`j' "Excise on ${prod_label_ex_`j'}"

}
label var excise_taxes "Excise Taxes all"

if $devmode== 1 {
	sum ex_*
	save "${tempsim}/Excise_taxes.dta", replace
}

tempfile Excise_taxes
save `Excise_taxes'

* CHECK...
merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight)

tabstat ex_* excise_taxes [aw = hhweight], s(sum)



