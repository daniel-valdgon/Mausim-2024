/*==============================================================================
 Senegal Indirect taxes
 Author: Andres Gallegos
 Date: May 2023
 Version: 1.0

 Notes: 
	*

*========================================================================================*/

/*==================================================================
-------------------------------------------------------------------*
			1. Computing indirect price effects of VAT
-------------------------------------------------------------------*
===================================================================*/

global informal_reduc_rate 0
/* ---------------------------------------------------------------
1.1  Creating the database for vatmat, with %exempted by Sector
 -----------------------------------------------------------------*/


use "$presim/05_purchases_hhid_codpr.dta", clear

merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight)

collapse (sum) depan [iw=hhweight], by(codpr) 

merge 1:m codpr using "$presim/IO_percentage.dta", nogen keepusing(sector pourcentage) keep(1 3)

tempfile prod_weights
save `prod_weights'

use `prod_weights', clear
gen rate=.
*gen formelle=.
gen imported=.

levelsof codpr, local(produits)
foreach prod of local produits {
	replace rate      = ${cdrate_`prod'} if codpr==`prod'
	replace imported = ${cdimp_`prod'} if codpr==`prod'
}

replace depan      = 0 if depan==.
replace depan      = depan*pourcentage

ren rate TVA 
*ren imported exempted

gen exempted = imported == 0

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

use "$presim/IO_Matrix.dta", clear 
drop if sector==.

merge 1:1 sector using `secteurs', nogen

rename exempted VAT_exempt_share
gen VAT_exempt=0 if VAT_exempt_share==0
replace VAT_exempt=1 if VAT_exempt_share>0 & VAT_exempt_share<.
assert  VAT_exempt_share>0   if VAT_exempt==1 // all exempted sector should have a exemption share 
assert  VAT_exempt_share==0  if VAT_exempt==0 // all non exempted sector should have either zero or missing  

*What to do with sectors with no VAT information? Assume they are no exempted & avg. rate
count if VAT_exempt_share==.
if `r(N)'>0{
	local numsect `r(N)'
	sum TVA
	local avgrate = round(`r(mean)'*100,0.01)
	dis as error "`numsect' sectors have no VAT information, we just assumed they are no exempted and assume the average VAT rate of `avgrate'%"
	*dis as error "should we include this assumed TVA rate for missing sectors as a parameter in the tool?"
}

replace VAT_exempt_share=0 if VAT_exempt_share==.
replace VAT_exempt      =0 if VAT_exempt      ==.
sum TVA
replace TVA=`r(mean)' if TVA==.

tempfile io_original_SY 
save `io_original_SY', replace 

des sect_*, varlist 
local list "`r(varlist)'"
vatmat `list' , exempt(VAT_exempt) pexempt(VAT_exempt_share) sector(sector) 

/* ------------------------------------------
1.2  Estimating indirect effects of VAT
 --------------------------------------------*/
noi dis as result " 1. Effet indirect de la politique de TVA"

*Fixed sectors 
merge m:1 sector using "$presim/IO_Matrix.dta", assert(master matched) keepusing(fixed) nogen
 
*VAT rates (sector level VAT)
merge m:1 sector using `io_original_SY', assert(master matched) keepusing(TVA) nogen

*No price control sectors 
gen cp=1-fixed

*vatable sectors 
gen vatable=1-fixed-exempted
replace vatable = 0 if vatable==-1 //Sectors that are fixed and exempted are not VATable


*Indirect effects 
des sector_*, varlist 
local list "`r(varlist)'"

vatpush `list' , exempt(exempted) costpush(cp) shock(TVA) vatable(vatable) gen(TVA_indirect)


keep sector TVA TVA_indirect fixed exempted
rename TVA TVA_mean_sector

tempfile ind_effect_VAT
save `ind_effect_VAT'

 
/*==================================================================
-------------------------------------------------------------------*
			2. Computing direct price effects of VAT
-------------------------------------------------------------------*
===================================================================*/
noi dis as result " 2. Effet direct de la politique de TVA"

clear
gen codpr=.
gen TVA=.
*gen formelle=.
gen exempted=.
local i=1
foreach prod of global products {
	set obs `i'
	qui replace codpr	 = `prod' in `i'
	qui replace TVA      = ${cdrate_`prod'} if codpr==`prod' in `i'
	*qui replace formelle = ${vatform_`prod'} if codpr==`prod' in `i'
	qui replace exempted = ${cdimp_`prod'} if codpr==`prod' in `i'
	local i=`i'+1
}
tempfile VATrates
save `VATrates'


if $devmode== 1 {
	use "$tempsim/Excises_verylong.dta", clear
}
else{
	use `Excises_verylong', clear
}

keep hhid codpr informal_purchase achats*

merge m:1 codpr using `VATrates', nogen keep(1 3)

merge 1:1 hhid codpr informal_purchase using "$tempsim/Subsidies_verylong.dta", assert(matched) keepusing(tranche*_tool type_client type_client prepaid_woyofal tranche_elec_max sector achat_gross achats_sans_subs_dir)

* Informality simulation assumption
noi dis as result "Simulation with the assumption that informality decrease in ${informal_reduc_rate} %"

egen aux = max(informal_purchase * achats_avec_excises * $informal_reduc_rate), by(hhid codpr)
gen aux_f = (1 - informal_purchase) * (achats_avec_excises + aux) 
gen aux_i = informal_purchase * (achats_avec_excises - aux)

bysort hhid codpr: egen x_bef=total(achats_avec_excises)
ereplace achats_avec_excises = rowtotal(aux_f aux_i)
*egen achats_avec_excises2 = rowtotal(aux_f aux_i)
bysort hhid codpr: egen x_aft=total(achats_avec_excises)

* Check
drop aux aux_f aux_i x_bef x_aft 

gen TVA_direct = achats_avec_excises * TVA * (1-informal_purchase)

*replace TVA_direct = TVA_elec if codpr==376


*-------------------------------------------------------------------*
*		Merging direct and indirect VAT, and confirmation
*-------------------------------------------------------------------*

merge m:1 sector exempted using `ind_effect_VAT', nogen  /*assert(match using)*/ keep(match)

rename TVA_indirect TVA_indirect_shock
gen TVA_indirect = TVA_indirect_shock * achats_avec_excises

*Confirmation that the calculation is correct for the survey year policies:
gen achats_avec_VAT = (achats_avec_excises + TVA_direct) * (1 + TVA_indirect_shock)
gen dif4 = achat_gross - achats_avec_VAT
tab codpr if abs(dif4)>0.0001


if $asserts_ref2018 == 1{
	assert abs(dif4)<0.0001
}

gen achats_avec_VAT2 = achats_avec_excises + TVA_direct + TVA_indirect

gen interaction_VATs = achats_avec_VAT-achats_avec_VAT2
sum interaction_VATs, deta

if $devmode== 1 {
    save "$tempsim/FinalConsumption_verylong2.dta", replace
}
else{
	save `FinalConsumption_verylong', replace
}

*Finally, we are only interested in the per-household amounts, so we will collapse the database:

collapse (sum) TVA_indirect TVA_direct interaction_VATs achats_avec_VAT achats_avec_excises achats_sans_subs achats_sans_subs_dir achats_net, by(hhid)

label var achats_net "Purchases before any policy"
label var achats_sans_subs_dir "Purchases - Dir. Subsidies"
label var achats_sans_subs "Purchases - All Subsidies"
label var achats_avec_excises "Purchases - All Subs. + Excises"
label var achats_avec_VAT "Purchases - All Subs. + Excises + VAT"

*Correction: We will count the interaction as further indirect effects
replace TVA_indirect = TVA_indirect+interaction_VATs
drop interaction_VATs

ren (TVA_direct TVA_indirect) (CD_direct CD_indirect)


if $devmode== 1 {
	save "${tempsim}/CustomDuties_taxes.dta", replace
}

tempfile VAT_taxes
save `VAT_taxes'


