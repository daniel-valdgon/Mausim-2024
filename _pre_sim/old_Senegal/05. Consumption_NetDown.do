*Calculating the net expenditures for the survey year

/* ------------------------------------
 ------------------------------------
1. Indirect and direct effects of VAT, Excises and Subsidies 
 ------------------------------------
--------------------------------------*/

noi dis "We want to take household purchases and remove the direct and indirect effects that VAT, subsidies, and excises have on the final value."

/* ------------------------------------
1.A Expanding IO matrix 
 --------------------------------------*/

*I need VAT rates from survey year, and other things
import excel "$xls_sn", sheet("p_Ref_2018") first clear
	keep if substr(globalname,1,3)=="vat" | substr(globalname,1,4)=="taux" | substr(globalname,1,10)=="Subvention" | substr(globalname,1,3)=="mp_" | substr(globalname,1,3)=="sp_" | substr(globalname,1,3)=="sr_" | substr(globalname,1,13)=="subsidy_shock"
	levelsof globalname, local(globals)
	global excises_sy ""
	foreach z of local globals {
		levelsof globalcontent if globalname=="`z'", local(val)
		global `z'_SY `val'
		if substr("`z'",1,4)=="taux"{
			global excises_sy $excises_sy "`z'"
		}
	}

	
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
	replace TVA      = ${vatrate_`prod'_SY} if codpr==`prod'
	replace formelle = ${vatform_`prod'_SY} if codpr==`prod'
	replace exempted = ${vatexem_`prod'_SY} if codpr==`prod'
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
	noi dis as error "`r(N)' sectors have no VAT information, we just assumed they are 50% exempted which implies an average VAT rate of 9%"
	noi dis as error "should we include this assumed TVA rate for missing sectors as a parameter in the tool?"
}

replace VAT_exempt_share=0.5 if VAT_exempt_share==.
replace VAT_exempt      =1   if VAT_exempt      ==.
replace TVA=0.09 if TVA==.

tempfile io_original_SY 
save `io_original_SY', replace 

vatmat C1-C35, exempt(VAT_exempt) pexempt(VAT_exempt_share) sector(Secteur)



/* ------------------------------------
1.B  Estimating indirect effects of VAT
 --------------------------------------*/


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
vatpush sector_1-sector_69 , exempt(exempted) costpush(cp) shock(TVA) vatable(vatable) gen(TVA_ind_eff_SY)


keep Secteur TVA TVA_ind_eff_SY fixed exempted

noi dis "Indirect effects of removing VAT from the products that have to pay it, by industry and exemption status"
tempfile ind_effect_VAT_SY
save `ind_effect_VAT_SY'


/* ------------------------------------
1.C Direct effects of VAT on prices 
--------------------------------------*/

*This may seem overcomplicated but it's actually faster than opening the Excel again
clear
gen codpr=.
gen TVA=.
gen exempted=.
local n=1
foreach prod of global products {
	set obs `n'
	replace codpr    = `prod' in -1
	replace TVA      = ${vatrate_`prod'_SY} if codpr==`prod'
	replace exempted = ${vatexem_`prod'_SY} if codpr==`prod'
	local ++n
}
isid codpr
noi dis "Direct effects of removing VAT from the products that have to pay it, by product"
tempfile VAT_rates_SY
save `VAT_rates_SY', replace


/* ------------------------------------
1.D. Excises 
------------------------------------*/

keep codpr
gen excise = .
replace excise = $taux_alcohol_SY 		if inlist(codpr,137,138,301,302)
replace excise = $taux_boissons_SY 		if inlist(codpr,135,133)
replace excise = $taux_cafe_SY 			if inlist(codpr,129)
replace excise = $taux_te_SY 			if inlist(codpr,130)
replace excise = $taux_beurre_SY 		if inlist(codpr, 44,45,46,47,48,49,51,53,54)
replace excise = $taux_autres_corps_SY 	if inlist(codpr,55,56,57,58,59,32)
replace excise = $taux_cigarettes_SY 	if inlist(codpr,201)
replace excise = $taux_cosmetiques_SY 	if inlist(codpr,321,415)
replace excise = $taux_bouillons_SY 	if inlist(codpr,121,122)
replace excise = $taux_textiles_SY 		if inlist(codpr,501,502,503,504,505,506,521,804,806,615)

drop if codpr==.

keep codpr excise
drop if excise==.
isid codpr
noi dis "Direct effects of removing excises from the products that have to pay it, by product. As these are final consumption, there are no indirect effects"
tempfile Excises_SY
save `Excises_SY', replace


/*------------------------------------
1.E Subsidy Indirect effects on prices 
------------------------------------*/


import excel "$data_sn\IO_Matrix.xlsx", sheet("Sheet1") firstrow clear

*Define fixed sectors 
local thefixed 22 32 33 34 13 	//electricite gaz et eau, activites d'administration pub, education et formation, activites de sante et action s, raffinage petrole cokefaction

gen fixed=0
foreach var of local thefixed {
	replace fixed=1  if  Secteur==`var'
}

*Electricity and Water Shock (weighted average)
gen shock = $subsidy_shock_elec_SY + $subsidy_shock_eau_SY if Secteur==22
	
*Fuel shock
replace shock = $sr_fuel_ind_SY if Secteur==13

replace shock=0  if shock==.

*Indirect effects 
costpush C1-C35, fixed(fixed) priceshock(shock) genptot(sub_tot_shock) genpind(sub_ind_shock) fix

keep Secteur sub_ind_shock sub_tot_shock

isid Secteur
noi dis "Indirect effects of removing VAT from the products that have to pay it, by industry"
tempfile ind_effect_subs_SY
save `ind_effect_subs_SY', replace


/* ------------------------------------
 ------------------------------------
2. Netting down spending 
 ------------------------------------
--------------------------------------*/

*First, we create some auxiliary databases
use "$data_sn/IO_percentage3.dta", clear
gen reps=1
collapse (sum) reps, by(codpr)
tempfile expand_codprs
save `expand_codprs', replace

use "$data_sn/IO_percentage3.dta", clear
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


merge m:1 Secteur exempted using `ind_effect_VAT_SY', nogen  assert(match using) keep(match)


*EXPANDIR PRODUCTOS POR NIVEL DE INFORMALIDAD 1/0

replace informality_purchases = 0 if codpr==334 //En teoría electricidad debería ser 100% formal
replace informality_purchases = 0 if codpr==332 //En teoría AGUA debería ser 100% formal

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

*electricity VAT
merge m:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(tranche*_yr type_client prepaid_woyofal consumption_DGP_yr) nogen assert(match)
replace tranche3_yr = tranche3_yr + consumption_DGP_yr
gen VAT_elec = 0
replace VAT_elec = 112.65*0.18*tranche3_yr if prepaid_woyofal==0 & type_client==1
replace VAT_elec = 112.02*0.18*tranche3_yr if prepaid_woyofal==0 & type_client==2
replace VAT_elec = 103.55*0.18*tranche3_yr if prepaid_woyofal==0 & type_client==3
replace VAT_elec = 101.64*0.18*tranche3_yr if prepaid_woyofal==1 & type_client==1
replace VAT_elec = 102.44*0.18*tranche3_yr if prepaid_woyofal==1 & type_client==2
replace VAT_elec = VAT_elec*(1-informal_purchase)*pourcentage //electricity should be 100% formal

*water VAT
merge m:1 hhid using "$presim/05_water_quantities.dta",  keepusing(eau_quantity*) nogen assert(match)
gen VAT_water = 0
global price_t3 778.87
replace VAT_water = eau_quantity3*6*0.18*$price_t3
replace VAT_water = VAT_water*(1-informal_purchase)*pourcentage //water should be 100% formal


gen achats_net_VAT = achat_gross / ( (1 + (1-informal_purchase) * TVA) * (1 + TVA_ind_eff_SY) ) //This is not exactly correct for water and electricity, we will correct that now:

replace achats_net_VAT = (achat_gross - VAT_elec) / (1 + TVA_ind_eff_SY) if codpr == 334 //Electricity indirect effect is 0 because its regulated, but im leaving it just in case
replace achats_net_VAT = (achat_gross - VAT_water) / (1 + TVA_ind_eff_SY) if codpr == 332 //Water indirect effect is 0 because its regulated, but im leaving it just in case



/*------------------------------------
2.B Expenditures net from Excises
 ------------------------------------*/

merge m:1 codpr using `Excises_SY', nogen keep(master match) 

replace excise=0 if excise==.
gen achats_net_excise = achats_net_VAT  / (1 + excise) 


/*------------------------------------
2.C Expenditures net from Subsidies (indirect)
 ------------------------------------*/

*PREPARE PRE-FISCAL EXPENDITURES FOR INDIRECT SUBSIDIES 
*Calculate net expenditure (before subsidies)
merge m:1 Secteur using `ind_effect_subs_SY', nogen assert(match using) keep(match)

//Net expenditure (before VAT and before subsidy)
gen achats_net_subind = achats_net_excise / (1 - sub_ind_shock) // indirect effect for all goods and services


/*------------------------------------
2.D Expenditures net from Subsidies (direct)
 ------------------------------------*/

*Direct subsidy water
gen subsidy_water_SY = (${SubventionT3_eau_SY}*eau_quantity3+${SubventionT2_eau_SY}*eau_quantity2+${SubventionT1_eau_SY}*eau_quantity1)*6 //These are bimonthly quantities
replace subsidy_water_SY = 0 if codpr!=332 //Leave only affecting water consumption

*Direct subsidy electricity
gen subs1=0
gen subs2=0
gen subs3=0
foreach payment in  0 1 {	
	if "`payment'"=="1" local tpay "W"			// Prepaid (Woyofal)
	else if "`payment'"=="0" local tpay "P"		// Postpaid
	foreach pui in DPP DMP DGP{
		if ("`pui'"=="DPP") local client=1
		if ("`pui'"=="DMP") local client=2
		if ("`pui'"=="DGP") local client=3
		if strlen(`"${SubventionT1_`tpay'`pui'_SY}"')>0{
			local i=1
			foreach tranch in T1 T2 T3{
				replace subs`i'=${Subvention`tranch'_`tpay'`pui'_SY}*tranche`i'_yr if type_client==`client' & prepaid_woyofal==`payment'
				noi dis "`pui' households, prepaid=`payment', tranche `i'"
				local ++i
			}
		}
	}
}
gen subsidy_elec_SY = subs1+subs2+subs3
drop subs1 subs2 subs3
replace subsidy_elec_SY = 0 if codpr!=334 //Leave only affecting electricity consumption

*Direct subsidy fuel
*We have to recalculate quantities given that "fuel_hh" is three different product codes
gen q_fuel_hh  = achat_gross/$sp_fuel_hh_SY  if inlist(codpr, 208, 209, 304)
gen q_pet_lamp = achat_gross/$sp_pet_lamp_SY if inlist(codpr, 202)
gen q_butane   = achat_gross/$sp_butane_SY   if inlist(codpr, 303)
recode q_fuel_hh q_pet_lamp q_butane (.=0)
gen subsidy_fuel_SY = q_fuel_hh*($mp_fuel_hh_SY - $sp_fuel_hh_SY ) + q_pet_lamp*($mp_pet_lamp_SY - $sp_pet_lamp_SY ) + q_butane*($mp_butane_SY - $sp_butane_SY )
replace subsidy_fuel_SY = 0 if subsidy_fuel_SY == .

*Net expenditures from subsidies
*Note that elec and water subsidies require to be scaled by %informal and %sector

gen achats_net = achats_net_subind + (subsidy_water_SY+subsidy_elec_SY)*pondera_informal*pourcentage + subsidy_fuel_SY


isid hhid codpr Secteur informal_purchase
keep hhid codpr Secteur informal_purchase pourcentage pondera_informal achats_net achats_net_subind achats_net_excise achats_net_VAT achat_gross

save "$presim/05_netteddown_expenses_SY.dta", replace




/* Tests and amazing plots
use "$presim/05_netteddown_expenses_SY.dta", clear
gen pond = pourcentage * pondera_informal

collapse (sum) achat* [iw=pond], by(hhid)
gen la=ln(achat_gross)
gen lb=ln( achats_net_VAT )
gen lc=ln( achats_net_excise )
gen ld=ln( achats_net_subind )
gen le=ln( achats_net )
twoway (kdensity la) (kdensity lb) (kdensity lc) (kdensity ld) (kdensity le) if la>12, legend(ring(0) pos(10) label(1 "Gross") label(2 "- VAT") label(3 "- Excises") label(4 "+ Ind. Subsidies") label(5 "+ Dir. Subsidies")) xlabel(12.2 "200K" 12.61 " " 12.89 " " 13.12 "500K" 13.8 "1M" 14.5 "2M" 14.9 " " 15.2 " " 15.42 "5M" 16.118 "10M" 16.8 "20M" 17.2 " ")



