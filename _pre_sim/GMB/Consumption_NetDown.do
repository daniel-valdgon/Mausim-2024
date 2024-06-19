


/*
 Purpose: Calculating the net expenditures for the survey year

 Editted by: Madi Mangan 
 Last Updated: 19/02/2024

*/


   noi dis "We want to take household purchases and remove the direct and indirect effects that VAT, to have on the final value."
   

   
use "$presim/05_purchases_hhid_codpr.dta", clear 
merge n:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight)

collapse (sum) depan [aw=hhweight], by(codpr)

merge 1:m codpr using "$presim/IO_percentage_GMB.dta", nogen

tempfile prod_weights
save `prod_weights', replace


use `prod_weights', clear
gen TVA=.
gen formelle=.
gen exempted=.

levelsof codpr, local(produits)
foreach prod of local produits {
	replace TVA      = ${vatrate_`prod'} if codpr==`prod'
	replace formelle = ${vatform_`prod'} if codpr==`prod'
	replace exempted = ${vatexem_`prod'} if codpr==`prod'
}

replace depan      = 0 if depan==.
replace depan      = depan*pourcentage

*1.1.2. Product data --> Sector data

/*
collapse (mean) TVA (sum) depan [iw=depan], by(sector exempted)


		tempfile VAT_secteurs_exempted
		save `VAT_secteurs_exempted', replace

		collapse (mean) TVA exempted [iw=depan], by(sector)

		tempfile secteurs
		save `secteurs', replace
*/

*1.1.2. Product data --> Sector data

gen all=1
collapse (mean) TVA (sum) all [iw=depan], by(sector exempted) 
ren all depan // this was to make TVA a weighted average but not depan

tempfile VAT_secteurs_exempted
save `VAT_secteurs_exempted', replace

collapse (mean) TVA exempted [iw=depan], by(sector)

tempfile secteurs
save `secteurs', replace

*1.1.3. Sector data --> IO matrix y vatmat

import excel "$data_sn/IO_matrix_GMB.xlsx", sheet("IO") firstrow clear
drop if sector==.

merge 1:1 sector using `secteurs', nogen

rename exempted VAT_exempt_share
gen VAT_exempt=0 if VAT_exempt_share==0
replace VAT_exempt=1 if VAT_exempt_share>0 & VAT_exempt_share<.
assert  VAT_exempt_share>0   if VAT_exempt==1 // all exempted sector should have a exemption share 
assert  VAT_exempt_share==0  if VAT_exempt==0 // all non exempted sector should have either zero or missing  

*What to do with sectors with no VAT information? Assume they are half exempted
count if VAT_exempt_share==.
if `r(N)'>0{
	dis as error "`r(N)' sectors have no VAT information, we just assumed they are 50% exempted which implies an average VAT rate of 8%"
	*dis as error "should we include this assumed TVA rate for missing sectors as a parameter in the tool?"
}

replace VAT_exempt_share=0.5 if VAT_exempt_share==.
replace VAT_exempt      =1   if VAT_exempt      ==.
replace TVA=0.09 if TVA==.

tempfile io_original_SY 
save `io_original_SY', replace 

vatmat sect_1-sect_35, exempt(VAT_exempt) pexempt(VAT_exempt_share) sector(sector)


/* ------------------------------------------
1.2  Estimating indirect effects of VAT
 --------------------------------------------*/
noi dis as result " 1. Effet indirect de la politique de TVA"

*VAT rates (sector level VAT)
merge m:1 sector using `io_original_SY', /*assert(master matched)*/ keepusing(TVA) nogen

*No price control sectors 
gen cp=1

*vatable sectors 
gen vatable=1-exempted
replace vatable = 0 if vatable==-1 //Sectors that are fixed and exempted are not VATable

*Indirect effects
vatpush sector_1-sector_69 , exempt(exempted) costpush(cp) shock(TVA) vatable(vatable) gen(TVA_ind_eff_SY)


keep sector TVA TVA_ind_eff_SY exempted


noi dis "Indirect effects of removing VAT from the products that have to pay it, by industry and exemption status"
tempfile ind_effect_VAT_SY
save `ind_effect_VAT_SY'


/* ------------------------------------
1.C Direct effects of VAT on prices 
--------------------------------------*/

noi dis as result " 2. Effet direct de la politique de TVA"

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
tempfile VAT_rates_SY
save `VAT_rates_SY'


/* ------------------------------------
 ------------------------------------
2. Netting down spending 
 ------------------------------------
--------------------------------------*/

*First, we create some auxiliary databases
use "$presim/IO_percentage_GMB.dta", clear
gen reps=1
collapse (sum) reps, by(codpr)
tempfile expand_codprs
save `expand_codprs', replace

use "$presim/IO_percentage_GMB.dta", clear
bys codpr: gen order = _n
tempfile IO_percentage3_unique
save `IO_percentage3_unique', replace


*Now, we start by taking only purchases, and expand it by sectors
use "$presim/05_purchases_hhid_codpr.dta", clear
merge m:1 codpr using `expand_codprs', nogen keep(1 3)
expand reps
bys codpr hhid: gen order = _n
merge m:1 codpr order using `IO_percentage3_unique', nogen keep(1 3)
drop reps order
gen achat_gross = depan*pourcentage


/*------------------------------------
2.A Expenditures net from VAT 
------------------------------------*/

*Calculate net expenditure direct pre-VAT	
merge m:1 codpr using `VAT_rates_SY', nogen keep(1 3) // assert(match) // notice here we merge!! product-exemption level

assert TVA==0 if exempted==1
replace TVA=0 if exempted==1 // this should not be needed 


merge m:1 sector exempted using `ind_effect_VAT_SY', nogen  /* assert(match using) */ keep(match)


*EXPANDIR PRODUCTOS POR NIVEL DE INFORMALIDAD 1/0

*replace informality_purchases = 0 if codpr==334 //En teoría electricidad debería ser 100% formal
*replace informality_purchases = 0 if codpr==332 //En teoría AGUA debería ser 100% formal
ren informal_purchase informality_purchases

gen inf_expandable = (informality_purchases>0 & informality_purchases<1)

gen id=_n
expand 2 if inf_expandable==1
bys id: gen dup=_n
gen informal_purchase = informality_purchases
replace informal_purchase = 1 if informality_purchases>0 & informality_purchases<1 & dup==1
replace informal_purchase = 0 if informality_purchases>0 & informality_purchases<1 & dup==2
gen pondera_informal = 1
replace pondera_informal = informality_purchases if informality_purchases>0 & informality_purchases<1 & dup==1
replace pondera_informal = 1-informality_purchases if informality_purchases>0 & informality_purchases<1 & dup==2
drop id inf_expandable dup

replace achat_gross = achat_gross * pondera_informal
label var informal_purchase "1 = purchase was done informally => no VAT paid"


gen achats_net_VAT = achat_gross / ( (1 + (1-informal_purchase) * TVA) * (1 + TVA_ind_eff_SY) ) 


save "$presim/05_netteddown_expenses_SY.dta", replace



