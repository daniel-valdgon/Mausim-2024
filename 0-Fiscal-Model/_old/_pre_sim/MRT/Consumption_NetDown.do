


/*
 Purpose: Calculating the net expenditures for the survey year

 Editted by: Madi Mangan 
 Last Updated: 19/02/2024

*/

*global path     	"C:\Users\wb621266\OneDrive - WBG\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"
*global country 		"MRT"
*global presim       "${path}/01_data/2_pre_sim/${country}" 
   
   
   
noi dis "We want to take household purchases and remove the direct and indirect effects that VAT, to have on the final value."

   
use "$presim/05_purchases_hhid_codpr.dta", clear 

merge n:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight)

collapse (sum) depan [aw=hhweight], by(codpr)

merge 1:m codpr using "$presim/IO_percentage.dta", nogen //keep(1 3)

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

import excel "$presim/IO_Matrix.xlsx", sheet("IO_matrix") firstrow clear
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
local thefixed $sect_fixed // Fixed sector is also country specific

gen fixed=0
foreach var of local thefixed {
	replace fixed=1  if  sector==`var'
}

*VAT rates (sector level VAT)
merge m:1 sector using `io_original_SY', /*assert(master matched)*/ keepusing(TVA) nogen

*No price control sectors 
gen cp=1-fixed

*vatable sectors 
gen vatable=1-exempted
replace vatable = 0 if vatable==-1 //Sectors that are fixed and exempted are not VATable

*Indirect effects
des sector_*, varlist 
local list "`r(varlist)'"

vatpush `list' , exempt(exempted) costpush(cp) shock(TVA) vatable(vatable) gen(TVA_ind_eff_SY)

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
1.D. Excises 
------------------------------------*/

keep codpr
gen excise = .

forvalues j = 1/$n_excises_taux {
	
	*local j 1
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

tab codpr if excise != . 

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


import excel "$presim/IO_Matrix.xlsx", sheet("IO_matrix") firstrow clear

*Define fixed sectors 
local thefixed $sect_fixed  	//electricite gaz et eau, activites d'administration pub, education et formation, activites de sante et action s, raffinage petrole cokefaction

gen fixed=0
foreach var of local thefixed {
	replace fixed=1  if  sector==`var'
}

*Electricity and Water Shock (weighted average)
*gen shock = $subsidy_shock_elec_SY + $subsidy_shock_eau_SY if Secteur==22
	
global subsidy_shock_elec_SY = 0.04092043	
gen shock = $subsidy_shock_elec_SY if sector==8
	
*Fuel shock
*replace shock = $sr_fuel_ind_SY if Secteur==13

replace shock=0  if shock==.

*Indirect effects 
des sect_*, varlist 
local list "`r(varlist)'"

costpush `list', fixed(fixed) priceshock(shock) genptot(sub_tot_shock) genpind(sub_ind_shock) fix

keep sector sub_ind_shock sub_tot_shock

isid sector
noi dis "Indirect effects of removing VAT from the products that have to pay it, by industry"
tempfile ind_effect_subs_SY
save `ind_effect_subs_SY', replace


/* ------------------------------------
 ------------------------------------
2. Netting down spending 
 ------------------------------------
--------------------------------------*/

*First, we create some auxiliary databases
use "$presim/IO_percentage.dta", clear
gen reps=1
collapse (sum) reps, by(codpr)
tempfile expand_codprs
save `expand_codprs', replace

use "$presim/IO_percentage.dta", clear
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

ren informal_purchase informality_purchases

if ("$rep_VAT" != "policy_VAT") replace informality_purchases = 0 if codpr==376 //En teoría electricidad debería ser 100% formal
*replace informality_purchases = 0 if codpr==332 //En teoría AGUA debería ser 100% formal

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
merge m:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(type_client prepaid_woyofal consumption_electricite) nogen assert(match)

gen codpr_elec = codpr == 376 // Electricity product

* Set parameters
local vat = 0.16
local tarif_s = 24.6*`vat' // 2.46 MRU
*local prime_fix_s = 279.9*`vat'

local tarif_d = 59*`vat' // 5.9 MRU
*local prime_fix_d = 1650.7*`vat'

*local redevance = 404*`vat'

gen VAT_elec = 0
replace VAT_elec = `tarif_s' * consumption_electricite if type_client == 1 & consumption_electricite>300
replace VAT_elec = `tarif_d' * consumption_electricite if type_client == 2 & consumption_electricite>300


gen achats_net_VAT = achat_gross / ( (1 + (1-informal_purchase) * TVA) * (1 + TVA_ind_eff_SY)) 

replace achats_net_VAT = (achat_gross - VAT_elec) / ( (1 + (1-informal_purchase) * TVA) * (1 + TVA_ind_eff_SY)) if codpr_elec == 1


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
merge m:1 sector using `ind_effect_subs_SY', nogen assert(match using) keep(match)

//Net expenditure (before VAT and before subsidy)
gen achats_net_subind = achats_net_excise / (1 - sub_ind_shock) // indirect effect for all goods and services


/*------------------------------------
2.D Expenditures net from Subsidies (direct)
 ------------------------------------*/
*Direct subsidy water
gen subsidy_water_SY = 0
 
*Direct subsidy electricity
gen subs1=0
gen subs2=0

replace subs1 = 140.3*consumption_electricite if type_client == 1
replace subs2 = 105.9*consumption_electricite if type_client == 2

gen subsidy_elec_SY = subs1+subs2
drop subs1 subs2
replace subsidy_elec_SY = 0 if codpr_elec!=1 //Leave only affecting electricity consumption

*gen subsidy_elec_SY = 4 * consumption_electricite

*Direct subsidy fuel
gen subsidy_fuel_SY = 0

gen achats_net = achats_net_subind + (subsidy_water_SY + subsidy_elec_SY) * pondera_informal * pourcentage + subsidy_fuel_SY

keep hhid codpr hhsize depan achat* sector pourcentage pondera_informal informal_purchase


save "$presim/05_netteddown_expenses_SY.dta", replace


/* Data for simulation
global xls_var 			"${tool}/${country}\Dictionary_${country}.xlsx" 

* Test 1 - RawData
global data 		"${presim}" // Data path
global all_data 	"01_menages 05_purchases_hhid_codpr 05_netteddown_expenses_SY" // Data names
global sheet 		"presimData" // Sheet name
global n 			3 // Data number

* First step
global stage 		"stage1" 
var_standardization

capture macro drop xls_var data all_data sheet n stage
*/

