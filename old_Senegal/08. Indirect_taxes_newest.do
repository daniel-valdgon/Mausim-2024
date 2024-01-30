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

* use "$data_sn/Senegal_consumption_all_by_product.dta", clear
* use "$data_sn/IO_percentage2_clean.dta", clear
* use "$data_sn\informality_final_senegal.dta", clear

/* ---------------------------------------------------------------
1.1  Creating the database for vatmat, with %exempted by Sector
 -----------------------------------------------------------------*/

*We will use household consumption per product to estimate weighted shares of VAT rates, exemptions and informality at the sector level

*THIS SHOULD BE EXACTLY THE SAME AS IN 5.CONSUMPTION_NETDOWN (PRESIM) (1.A)

*1.1.1. Household data --> Product data

*use "$data_sn/Senegal_consumption_all_by_product.dta", clear
*merge n:1 grappe menage using "$data_sn\ehcvm_conso_SEN2018_menage.dta" , nogen keepusing(hhid hhweight)

*We will use household purchases per product to estimate weighted shares of VAT rates, exemptions and informality at the sector level

use "$presim/05_purchases_hhid_codpr.dta", clear 
merge n:1 hhid using "$data_sn\ehcvm_conso_SEN2018_menage.dta" , nogen keepusing(hhweight)

collapse (sum) depan [fw=hhweight], by(codpr)

merge 1:m codpr using "$data_sn/IO_percentage3.dta", nogen

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

collapse (mean) TVA (sum) depan [iw=depan], by(Secteur exempted)

tempfile VAT_secteurs_exempted
save `VAT_secteurs_exempted', replace

collapse (mean) TVA exempted [iw=depan], by(Secteur)

tempfile secteurs
save `secteurs', replace

*1.1.3. Sector data --> IO matrix y vatmat

import excel "$data_sn\IO_Matrix.xlsx", sheet("Sheet1") firstrow clear
drop if Secteur==.

merge 1:1 Secteur using `secteurs', nogen

rename exempted VAT_exempt_share
gen VAT_exempt=0 if VAT_exempt_share==0
replace VAT_exempt=1 if VAT_exempt_share>0 & VAT_exempt_share<.
assert  VAT_exempt_share>0   if VAT_exempt==1 // all exempted sector should have a exemption share 
assert  VAT_exempt_share==0  if VAT_exempt==0 // all non exempted sector should have either zero or missing  

*What to do with sectors with no VAT information? Assume they are half exempted
count if VAT_exempt_share==.
if `r(N)'>0{
	dis as error "`r(N)' sectors have no VAT information, we just assumed they are 50% exempted which implies an average VAT rate of 9%"
	*dis as error "should we include this assumed TVA rate for missing sectors as a parameter in the tool?"
}

replace VAT_exempt_share=0.5 if VAT_exempt_share==.
replace VAT_exempt      =1   if VAT_exempt      ==.
replace TVA=0.09 if TVA==.

tempfile io_original_SY 
save `io_original_SY', replace 

vatmat C1-C35, exempt(VAT_exempt) pexempt(VAT_exempt_share) sector(Secteur)



/* ------------------------------------------
1.2  Estimating indirect effects of VAT
 --------------------------------------------*/
noi dis as result " 1. Effet indirect de la politique de TVA"


*Fixed sectors 
local thefixed 22 32 33 34 13 // electricite, gaz et eau - activites d'administration pub - education et formation - activites de sante et action s - raffinage petrole, cokefaction

gen fixed=0
foreach var of local thefixed {
	replace fixed=1  if  Secteur==`var'
}

*VAT rates (sector level VAT)
merge m:1 Secteur using `io_original_SY', assert(master matched) keepusing(TVA) nogen


*No price control sectors 
gen cp=1-fixed

*vatable sectors 
gen vatable=1-fixed-exempted
replace vatable = 0 if vatable==-1 //Sectors that are fixed and exempted are not VATable

*Indirect effects 
vatpush sector_1-sector_69 , exempt(exempted) costpush(cp) shock(TVA) vatable(vatable) gen(TVA_indirect)


keep Secteur TVA TVA_indirect fixed exempted
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
gen formelle=.
gen exempted=.
local i=1
foreach prod of global products {
	set obs `i'
	qui replace codpr	 = `prod' in `i'
	qui replace TVA      = ${vatrate_`prod'} if codpr==`prod' in `i'
	qui replace formelle = ${vatform_`prod'} if codpr==`prod' in `i'
	qui replace exempted = ${vatexem_`prod'} if codpr==`prod' in `i'
	local ++i
}
tempfile VATrates
save `VATrates'


if $devmode== 1 {
    use "$tempsim/Excises_verylong.dta", clear
}
else{
	use `Excises_verylong', clear
}

merge m:1 codpr using `VATrates', nogen keep(1 3)

gen TVA_direct = achats_avec_excises * TVA * (1-informal_purchase)

*Water and electricity have special VAT policies


*Electricity:

foreach payment in  0 1 {	
	if "`payment'"=="1" local tpay "W"			// Prepaid (Woyofal)
	else if "`payment'"=="0" local tpay "P"		// Postpaid
	foreach pui in DPP DMP DGP{
		if ("`pui'"=="DPP") local client=1
		if ("`pui'"=="DMP") local client=2
		if ("`pui'"=="DGP") local client=3
		if strlen(`"${TariffT1_`tpay'`pui'}"')>0{ //This should skip those cases where the combination puissance*payment does not exist (basically WDGP)
			foreach tranch of varlist tranche*_tool {
				local i = real(substr("`tranch'",8,1))
				cap gen TariffT`i' = 0
				if strlen(`"${TariffT`i'_`tpay'`pui'}"')>0{
					replace TariffT`i' = ${TariffT`i'_`tpay'`pui'} if type_client==`client' & prepaid_woyofal==`payment' & $incBlockTar == 1 //Versión de tarifas marginales
				}
				if $incBlockTar == 0 {																									 //Tarifas planas por hogar
					levelsof tranche_elec_max if type_client==`client' & prepaid_woyofal==`payment', local(tmaxes)
					foreach tmax of local tmaxes{
						replace TariffT`i' = ${TariffT`tmax'_`tpay'`pui'} if type_client==`client' & prepaid_woyofal==`payment' & tranche_elec_max==`tmax'
					}
				}
				cap gen vatratele_net_`i' = 0
				replace vatratele_net_`i' = $vatrate_334 if type_client==`client' & prepaid_woyofal==`payment' & $VATregime_elec < `i' & $full_VAT_nonex_elec == 0  //Exempted below
				replace vatratele_net_`i' = $vatrate_334 if type_client==`client' & prepaid_woyofal==`payment' & $VATregime_elec < tranche_elec_max & $full_VAT_nonex_elec == 1 //Pay if over
			}
		}
	}
}

gen TVA_elec = 0
foreach tranch of varlist tranche*_tool {
	local i = real(substr("`tranch'",8,1))
	replace TVA_elec = TVA_elec + TariffT`i'*tranche`i'_tool*vatratele_net_`i'
}
replace TVA_elec = TVA_elec*(1-informal_purchase)*6



*Water

foreach tranch of varlist tranche*_tool_eau {
	local i = real(substr("`tranch'",8,1))
	cap gen TariffT`i'_eau = 0
	replace TariffT`i'_eau = ${TariffT`i'_eau}
	cap gen vatrateau_net_`i' = 0
	replace vatrateau_net_`i' = $vatrate_332 if $VATregime_eau < `i'			   & $full_VAT_nonex_eau == 0  //Exempted below
	replace vatrateau_net_`i' = $vatrate_332 if $VATregime_eau < tranche_water_max & $full_VAT_nonex_eau == 1  //Pay if over
}

gen TVA_eau = 0
	
foreach tranch of varlist tranche*_tool_eau {
	local i = real(substr("`tranch'",8,1))
	replace TVA_eau = TVA_eau + TariffT`i'_eau*tranche`i'_tool_eau*vatrateau_net_`i'
}
replace TVA_eau = TVA_eau*(1-informal_purchase)*6


*Apply special VAT amounts

replace TVA_direct = TVA_elec if codpr==334
replace TVA_direct = TVA_eau  if codpr==332



*-------------------------------------------------------------------*
*		Merging direct and indirect VAT, and confirmation
*-------------------------------------------------------------------*

merge m:1 Secteur exempted using `ind_effect_VAT', nogen  assert(match using) keep(match)

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
    save "$tempsim/FinalConsumption_verylong.dta", replace
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

if $devmode== 1 {
	save "${tempsim}/VAT_taxes.dta", replace
}

tempfile VAT_taxes
save `VAT_taxes'




















