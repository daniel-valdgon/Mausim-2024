/*============================================================================*\
 Purpose: Netting down household expenditures for Subsidies and Indirect Taxes
 
 Editted by: Gabriel Lombo
 Last Updated: March 2025
\*============================================================================*/
  

set seed 123456789   
   
noi dis "We want to take household purchases and remove the direct and indirect effects that VAT, to have on the final value."

*===============================================================================
// Policy Expenditures
*===============================================================================
* Reverse order. VAT, Excises, Subsidies, Custom Duties
* Parameters sheets: VAT, Excises, Subsidies, Custom Duties...

*-------------------------------------
// 1. Expanding IO - Matrix
*-------------------------------------

*----- Household data --> Product data

use "$presim/05_purchases_hhid_codpr.dta", clear 

merge n:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight)

collapse (sum) depan [aw=hhweight], by(codpr)

merge 1:m codpr using "$presim/IO_percentage.dta", nogen keep(1 3)

tempfile prod_weights
save `prod_weights', replace

* VAT parameters
use `prod_weights', clear
gen TVA=.
gen formelle=.
gen exempted=.

* Locate parameters
levelsof codpr, local(produits)
foreach prod of local produits {
	replace TVA      = ${vatrate_`prod'} if codpr==`prod'
	replace formelle = ${vatform_`prod'} if codpr==`prod'
	replace exempted = ${vatexem_`prod'} if codpr==`prod'
}

replace depan = 0 if depan == .
replace depan = depan * pourcentage


*----- Product data --> Sector data

gen all=1

collapse (mean) TVA (sum) all [iw=depan], by(sector exempted) 

ren all depan // this was to make TVA a weighted average but not depan

tempfile VAT_secteurs_exempted
save `VAT_secteurs_exempted', replace

collapse (mean) TVA exempted [iw=depan], by(sector)

tempfile secteurs
save `secteurs', replace


*----- Sector data --> IO matrix y vatmat

use "${presim}/IO_Matrix.dta", clear

drop if sector==.

merge 1:1 sector using `secteurs', nogen

rename exempted VAT_exempt_share
gen VAT_exempt=0 if VAT_exempt_share==0
replace VAT_exempt=1 if VAT_exempt_share>0 & VAT_exempt_share<.
assert  VAT_exempt_share>0   if VAT_exempt==1 // all exempted sector should have a exemption share 
assert  VAT_exempt_share==0  if VAT_exempt==0 // all non exempted sector should have either zero or missing  

* Sectors with no VAT information are assumed they are half exempted
count if VAT_exempt_share==.
if `r(N)'>0 {
	local numsect `r(N)'
	sum TVA
	local avgrate = round(`r(mean)' * 100, 0.01)
	dis as error "`numsect' sectors have no VAT information, we just assumed they are no exempted and assume the average VAT rate of `avgrate'%"
	*dis as error "should we include this assumed TVA rate for missing sectors as a parameter in the tool?"
}

replace VAT_exempt_share = 0 if VAT_exempt_share == .
replace VAT_exempt       = 0 if VAT_exempt       == .

sum TVA
replace TVA = `r(mean)' if TVA == .

tempfile io_original_SY 
save `io_original_SY', replace 
 
 
des sect_*, varlist 
local list "`r(varlist)'"
vatmat `list' , exempt(VAT_exempt) pexempt(VAT_exempt_share) sector(sector)  


*-------------------------------------
// 2. Estimating Indirect Effects of VAT
*-------------------------------------

noi dis as result " 1. Effet indirect de la politique de TVA"

merge m:1 sector using "${presim}/IO_Matrix.dta", assert(matched) keepusing(fixed)
merge m:1 sector using `io_original_SY', assert(master matched) keepusing(TVA) nogen

gen cp = 1 - fixed
gen vatable=1-exempted
replace vatable = 0 if vatable == -1 // Sectors that are fixed and exempted are not VATable

des sector_*, varlist 
local list "`r(varlist)'"
vatpush `list' , exempt(exempted) costpush(cp) shock(TVA) vatable(vatable) gen(TVA_ind_eff_SY)

keep sector TVA TVA_ind_eff_SY exempted

tempfile ind_effect_VAT_SY
save `ind_effect_VAT_SY'


*-------------------------------------
// 3. Estimating Direct Effects of VAT
*-------------------------------------

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
	local i = `i' + 1
}
tempfile VAT_rates_SY
save `VAT_rates_SY'

*-------------------------------------
// 4. Estimating Direct Effects of Excises
*-------------------------------------

keep codpr
gen excise = .

forvalues j = 1/$n_excises_taux {
	
	* Gen local of products lenght
	gen n = length("${codpr_read_ex_`j'}") - length(subinstr("${codpr_read_ex_`j'}", " ", "", .)) + 1
	qui sum n
	local n "`r(mean)'"
	drop n
	
	noi di "This excise has `n' categories with the next products: ${codpr_read_ex_`j'}"

	* Assign product code to the survey excise dummy
	forvalues i = 1/`n' {					
	
		local var : word `i' of ${codpr_read_ex_`j'}
		replace excise = ${taux_ex_`j'} if codpr == `var'
	}		
}

drop if codpr == .

keep codpr excise

drop if excise == .
isid codpr

tempfile Excises_SY
save `Excises_SY', replace


*-------------------------------------
// 5. Estimating Indirect Effects of Subsidies
*-------------------------------------

global subsidy_shock_elec_SY = 0.04092043	
global subsidy_shock_fuel_SY = 0.04092043	

*----- Electricity

use "${presim}/IO_Matrix.dta", clear

gen shock = $subsidy_shock_elec_SY if sector==8
replace shock = 0  if shock == .

des sect_*, varlist 
local list "`r(varlist)'"
costpush `list', fixed(fixed) priceshock(shock) genptot(sub_tot_shock) genpind(sub_ind_shock) fix

ren (sub_ind_shock sub_tot_shock) (sub_ind_shock1 sub_tot_shock1)
keep sector sub_ind_shock1 sub_tot_shock1

isid sector

tempfile ind_effect_subs_elec_SY
save `ind_effect_subs_elec_SY', replace

*----- Fuel

use "${presim}/IO_Matrix.dta", clear

gen shock = $subsidy_shock_fuel_SY if sector == 13
replace shock = 0  if shock == .

des sect_*, varlist 
local list "`r(varlist)'"
costpush `list', fixed(fixed) priceshock(shock) genptot(sub_tot_shock) genpind(sub_ind_shock) fix

ren (sub_ind_shock sub_tot_shock) (sub_ind_shock2 sub_tot_shock2)
keep sector sub_ind_shock2 sub_tot_shock2

isid sector

*tempfile ind_effect_subs_fuel_SY
*save `ind_effect_subs_fuel_SY', replace

*----- Sum Indirect Effects
merge 1:1 sector using `ind_effect_subs_elec_SY', assert(3)

gen sub_ind_shock = sub_ind_shock1 + sub_ind_shock2
gen sub_tot_shock = sub_tot_shock1 + sub_tot_shock2

tempfile ind_effect_subs_SY
save `ind_effect_subs_SY', replace



*-------------------------------------
// 7. Estimating Direct Effects of Custom Duties
*-------------------------------------

clear
gen codpr=.
gen CD_rate=.
gen CD_imp=.
local i=1
foreach prod of global products {
	set obs `i'
	qui replace codpr = `prod' in `i'
	qui replace CD_rate = ${cdrate_`prod'} if codpr==`prod' in `i'
	qui replace CD_imp = ${cdimp_`prod'} if codpr==`prod' in `i'
	local i = `i' + 1
}
tempfile CD_rates_SY
save `CD_rates_SY'


*===============================================================================
// Netting down spending 
*===============================================================================

*-------------------------------------
// 0. Auxiliary databases
*-------------------------------------

use "$presim/IO_percentage.dta", clear
gen reps=1
collapse (sum) reps, by(codpr)
tempfile expand_codprs
save `expand_codprs', replace


use "$presim/IO_percentage.dta", clear
bys codpr: gen order = _n
tempfile IO_percentage_unique
save `IO_percentage_unique', replace


* Now, we start by taking only purchases, and expand it by sectors
use "$presim/05_purchases_hhid_codpr.dta", clear
merge m:1 codpr using `expand_codprs', nogen keep(1 3)
expand reps
bys codpr hhid: gen order = _n
merge m:1 codpr order using `IO_percentage_unique', nogen keep(1 3)
drop reps order
*gen achat_gross = depan * pourcentage
gen achat_gross = depan * pourcentage

*-------------------------------------
// 1. Expenditures net from Excises
*-------------------------------------

* Calculate net expenditure direct pre-VAT	
merge m:1 codpr using `VAT_rates_SY' , nogen keep(1 3) //assert(match) // notice here we merge!! product-exemption level

assert TVA == 0 if exempted == 1
replace TVA = 0 if exempted == 1 // this should not be needed 

merge m:1 sector exempted using `ind_effect_VAT_SY', nogen  assert(match using)  keep(match)

* Expand by level of informality 
ren informal_purchase informality_purchases

* replace informality_purchases = 0 if codpr==376 //En teoría electricidad debería ser 100% formal

gen inf_expandable = (informality_purchases > 0 & informality_purchases < 1)

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
merge m:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(type_client prepaid_woyofal consumption_electricite) nogen assert(match)

gen codpr_elec = codpr == 376 // Electricity product

* Set parameters
local vat = 0.16
local tarif_s = 24.6 * `vat' // 2.46 MRU
*local prime_fix_s = 279.9*`vat'

local tarif_d = 59*`vat' // 5.9 MRU
*local prime_fix_d = 1650.7*`vat'

*local redevance = 404*`vat'

gen VAT_elec = 0
replace VAT_elec = `tarif_s' * consumption_electricite if type_client == 1 & consumption_electricite>300
replace VAT_elec = `tarif_d' * consumption_electricite if type_client == 2 & consumption_electricite>300

gen achats_net_VAT = achat_gross / ( (1 + (1-informal_purchase) * TVA) * (1 + TVA_ind_eff_SY)) 

replace achats_net_VAT = (achat_gross - VAT_elec) / ( (1 + (1-informal_purchase) * TVA) * (1 + TVA_ind_eff_SY)) if codpr_elec == 1


*-------------------------------------
// 2. Expenditures net from Excises
*-------------------------------------

merge m:1 codpr using `Excises_SY', nogen keep(master match) 

replace excise = 0 if excise == .
gen achats_net_excise = achats_net_VAT  / (1 + excise) 


*-------------------------------------
// 3. Expenditures net from Subsidies
*-------------------------------------
*----- Indirect effects 
merge m:1 sector using `ind_effect_subs_SY', nogen assert(match using) keep(match)

gen achats_net_subind = achats_net_excise / (1 - sub_ind_shock) 

*----- Direct effects
* Electricity
forval i=1/7{
	gen tranche`i'_tool=. //(AGV) The user can use up to 7 tranches in the tool, but certainly most of them will not be used
}
 
foreach payment in 0 1 {  	
		
	if "`payment'"=="1" local tpay "W"			// Prepaid (Woyofal)
	else if "`payment'"=="0" local tpay "P"		// Postpaid

	foreach pui in DPP DMP DGP{
		if ("`pui'"=="DPP") local client=1
		if ("`pui'"=="DMP") local client=2
		if ("`pui'"=="DGP") local client=3
		if strlen(`"$tholdsElec`tpay'`pui'"')>0{ //This should skip those cases where the combination puissance*payment does not exist (basically WDGP)
			local i=0
			global MaxT0_`tpay'`pui' 0 //This "tranche 0" is helpful for the next loops
			foreach tranch in ${tholdsElec`tpay'`pui'}{
				local j = `i'+1
				replace tranche`j'_tool=${Max`tranch'_`tpay'`pui'}-${MaxT`i'_`tpay'`pui'} if consumption_electricite>=${Max`tranch'_`tpay'`pui'} & type_client==`client' & prepaid_woyofal==`payment'
				replace tranche`j'_tool=consumption_electricite-${MaxT`i'_`tpay'`pui'} if consumption_electricite<${Max`tranch'_`tpay'`pui'} & consumption_electricite>${MaxT`i'_`tpay'`pui'} & type_client==`client' & prepaid_woyofal==`payment'
				local ++i
				dis "`pui' households, prepaid=`payment', tranche `i'"
			}
		}
	}
}

forval i=1/7{
	replace tranche`i'_tool=0 if tranche`i'_tool==. & prepaid_woyofal!=.	
}

gen tranche_elec_max = .
forval i=1/7{
	local l = 8-`i'
	replace tranche_elec_max = `l' if tranche`l'_tool!=0 & tranche`l'_tool !=. & tranche_elec_max==.
	gen subsidy`i'=.
}

if $incBlockTar == 1 {
	foreach payment in  0 1 {	
		if "`payment'"=="1" local tpay "W"			// Prepaid (Woyofal)
		else if "`payment'"=="0" local tpay "P"		// Postpaid
		foreach pui in DPP DMP DGP{
			if ("`pui'"=="DPP") local client=1
			if ("`pui'"=="DMP") local client=2
			if ("`pui'"=="DGP") local client=3
			local condition_exists = strlen(`"${tholdsElec`tpay'`pui'}"')
			if `condition_exists'>0{ //This should skip those cases where the combination puissance*payment does not exist (basically WDGP)
				local i=1
				foreach tranch in ${tholdsElec`tpay'`pui'}{
					replace subsidy`i'=${Subvention`tranch'_`tpay'`pui'}*tranche`i'_tool if type_client==`client' & prepaid_woyofal==`payment'
					*noi dis "`pui' housholds, prepaid=`payment', tranche `i'"
					local ++i
				}
			}
		}
	}
}

if $incBlockTar == 0 {
	foreach payment in  0 1 {	
		if "`payment'"=="1" local tpay "W"			// Prepaid (Woyofal)
		else if "`payment'"=="0" local tpay "P"		// Postpaid
		foreach pui in DPP DMP DGP{
			if ("`pui'"=="DPP") local client=1
			if ("`pui'"=="DMP") local client=2
			if ("`pui'"=="DGP") local client=3
			local condition_exists = strlen(`"${tholdsElec`tpay'`pui'}"')
			if `condition_exists'>0{ //This should skip those cases where the combination puissance*payment does not exist (basically WDGP)
				levelsof tranche_elec_max if type_client==`client' & prepaid_woyofal==`payment', local(tranches)
				foreach tranch of local tranches {
					dis ${SubventionT`tranch'_`tpay'`pui'}
					replace subsidy1=${SubventionT`tranch'_`tpay'`pui'}*consumption_electricite  if type_client==`client' & prepaid_woyofal==`payment' & tranche_elec_max==`tranch'
				}
			}
		}
	}
}

foreach v of varlist subsidy1-subsidy7 {
	replace `v' = 6 * `v'
}

egen subsidy_elec_SY = rowtotal(subsidy1 subsidy2 subsidy3 subsidy4 subsidy5 subsidy6 subsidy7) 
 
replace subsidy_elec_SY = 0 if codpr_elec!=1

* Fuel
merge m:1 hhid using "$presim/08_subsidies_fuel.dta",  nogen assert(match)

global sub_lpg 10
global sub_gasoline 10
global sub_gasoil 10

gen sub_1 = c_lpg * ${sub_lpg} / 100
gen sub_3 = c_gasoline * ${sub_gasoline} / 100
gen sub_4 = c_gasoil * ${sub_gasoil} / 100

egen subsidy_fuel_SY = rowtotal(sub_1 sub_3 sub_4)

gen achats_net_sub = achats_net_subind + (subsidy_fuel_SY + subsidy_elec_SY) * pondera_informal * pourcentage



*-------------------------------------
// 3. Expenditures net from Custom Duties
*-------------------------------------

* Calculate net expenditure direct pre-VAT	
merge m:1 codpr using `CD_rates_SY' , nogen keep(1 3) //assert(match) // notice here we merge!! product-exemption level

*assert CD_rate == 0 if CD_imp == 0
replace CD_rate = 0 if CD_imp == 0 // this should not be needed 

tab CD_rate CD_imp

gen achats_net = achats_net_sub / ( 1 +  (1 - informal_purchase) * (1 + CD_imp))

*-------------------------------------
// 4. Final Data
*-------------------------------------

sum hhid codpr hhsize sector pourcentage pondera_informal informal_purchase depan achat_gross achats_net_VAT achats_net_excise achats_net_subind achats_net_sub achats_net 


keep hhid codpr informal_purchase hhsize sector pourcentage achat_gross achats_net_VAT achats_net_excise achats_net_subind achats_net_sub achats_net


save "$presim/05_netteddown_expenses_SY.dta", replace


