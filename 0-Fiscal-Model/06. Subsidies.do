/********************************************************************************
********************************************************************************
* Program: Subsidies
* Date: March 2024
* Version: 1.0

Modified: Generalize the electricity subsidies to include fixed cost 
			
*--------------------------------------------------------------------------------

************************************************************************************/
noi dis as result " 1. Subvention directe à l'Électricité                          "
************************************************************************************

noi use "$presim/08_subsidies_elect.dta", clear 

keep hhid consumption_electricite type_client prepaid_woyofal

*Define tranches for subsidies consumption_electricite is bimonthly so intervals should also be bimonthly 

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

egen subsidy_elec_direct=rowtotal(subsidy*)


*Tranches are bimonthly therefore subsidy is bimonthly. Here we convert to annual values everything 
foreach v of varlist subsidy* {
	replace `v'=6*`v'
}


forval i=1/7{
	sum tranche`i'_tool
	if `r(mean)'==0{
		drop tranche`i'_tool
	}
	sum subsidy`i'
	if `r(N)'==0{
		drop subsidy`i'
	}
}

tempfile Elec_subsidies_direct_hhid
save `Elec_subsidies_direct_hhid'

************************************************************************************/
noi dis as result " 2. Subvention indirecte à l'Électricité                        "
************************************************************************************

use "$presim/IO_Matrix.dta", clear 

*Shock
gen shock=$subsidy_shock_elec if elec_sec==1
replace shock=0  if shock==.

*Indirect effects 
des sect_*, varlist 
local list "`r(varlist)'"
	
costpush `list', fixed(fixed) priceshock(shock) genptot(elec_tot_shock) genpind(elec_ind_shock) fix
	
keep sector elec_ind_shock elec_tot_shock
	
tempfile io_ind_elec
save `io_ind_elec', replace


************************************************************************************/
noi dis as result " 1. Subvention directe Fuel                        "
************************************************************************************

global sub_kerosene = 5

use "$presim/08_subsidies_fuel.dta", clear

gen sub_1 = c_lpg * ${sub_lpg} / 100
gen sub_2 = c_kerosene * ${sub_kerosene} / 100

gen sub_3 = c_gasoline * ${sub_gasoline} / 100
gen sub_4 = c_gasoil * ${sub_gasoil} / 100

egen sub_fuel = rowtotal(sub_1 sub_2 sub_3 sub_4)

rename sub_fuel subsidy_fuel_direct
rename sub_1 subsidy_f1_direct
rename sub_2 subsidy_f2_direct
rename sub_3 subsidy_f3_direct 
rename sub_4 subsidy_f4_direct 


tempfile Fuel_subsidies_direct_hhid
save `Fuel_subsidies_direct_hhid', replace

************************************************************************************/
noi dis as result " 2. Subvention indirecte Fuel                       "
************************************************************************************

use "$presim/IO_Matrix.dta", clear 

global subsidy_shock = 3.3/100 * (0.0779 + 0.1273)/2

*Shock
gen shock = $subsidy_shock if fuel_sec==1

replace shock=0  if shock==.

*Indirect effects 
des sect_*, varlist 
local list "`r(varlist)'"
	
costpush `list', fixed(fixed) priceshock(shock) genptot(fuel_tot_shock) genpind(fuel_ind_shock) fix
	
keep sector fuel_ind_shock fuel_tot_shock fuel_ind_shock fuel_tot_shock
	
tempfile io_ind_fuel
save `io_ind_fuel', replace


************************************************************************************/
noi dis as result " 1. Subvention -  Temwine                          "
************************************************************************************

global 	pr_label_5 	"Temwine"
global 	pr_div_5	"departement"
global 	pnbsf_PMT	0

set seed 1234

local i = 5

import excel "$xls_sn", sheet(prog_`i'_raw) first clear
drop if location ==.		
			
destring beneficiaires, replace	
destring montant, replace		

ren location ${pr_div_`i'}
			
keep ${pr_div_`i'} beneficiaires montant
			
save "$tempsim/${pr_div_`i'}_`i'.dta", replace 






use  "$presim/08_subsidies_emel.dta", clear 


gen sub_emel = uno * emel_prod * depan * ${sub_temwine}

gen subsidy_emel_direct = sub_emel
replace subsidy_emel_direct = ${max_am_temwine} if sub_emel > ${max_am_temwine}


gcollapse (sum) subsidy_emel_direct (max) max_eleg_1 emel_prod, by(hhid hhsize)


merge 1:1 hhid using   "$presim/07_dir_trans_PMT.dta", nogen  keepusing(wilaya) assert (matched)

merge 1:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight) assert (matched)


keep hhid hhweight hhsize wilaya subsidy_emel_direct

ren wilaya departement

gen pmt_seed_5 = uniform()
gen eleg_5 = 1

		*local i = 5
		noi di "Program number `i', ${pr_label_`i'}, assigning by ${pr_div_`i'}"

		gen benefsdep =.
		gen montantdep =.		
		merge m:1 departement /*region*/ using "$tempsim/${pr_div_`i'}_`i'.dta", nogen
		replace benefsdep = beneficiaires
		replace montantdep = montant
		drop beneficiaires montant
		

			
	if ($pnbsf_PMT ==0) {  // PMT targeting inside each department
		
		bysort departement (pmt_seed_`i'): gen potential_ben= sum(hhweight) if eleg_`i'==1
		gen _e1=abs(potential_ben-benefsdep)
		bysort departement: egen _e=min(_e1)
		gen _icum=potential_ben if _e==_e1
			gen numicum = (_icum!=.)
			bysort departement numicum (_icum): gen rep = _n
			replace _icum = . if rep>1
		bysort departement: egen Beneficiaires_i=total(_icum)
		bysort departement: egen _icum2_sd=sd(_icum)
		assert _icum2_sd==.
			sum benefsdep if _icum!=.
			local realbenefs = r(sum)
		drop _icum2_sd _icum _e _e1 rep
		gen am = montantdep*(potential_ben<=Beneficiaires_i)
		gen beneficiaire = (potential_ben<=Beneficiaires_i)
		replace beneficiaire = 0 if benefsdep == 0 // This is a temporal fix that we should look at later. 
		replace am = 0 if benefsdep ==0
		drop Beneficiaires_i potential_ben numicum
			sum hhweight if eleg_`i'==1
			local potential = r(sum)
			sum beneficiaire [iw=hhweight]
			nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
			if `potential'<=`r(sum)'{
				nois dis as error "Check if assigning every potential beneficiary makes sense."
			}
	}
	
	if ($pnbsf_PMT ==1) {  // PMT targeting inside each department
		
		bysort departement (PMT_`i' pmt_seed_`i'): gen potential_ben= sum(hhweight) if eleg_`i'==1
		gen _e1=abs(potential_ben-benefsdep)
		bysort departement: egen _e=min(_e1)
		gen _icum=potential_ben if _e==_e1
			gen numicum = (_icum!=.)
			bysort departement numicum (_icum): gen rep = _n
			replace _icum = . if rep>1
		bysort departement: egen Beneficiaires_i=total(_icum)
		bysort departement: egen _icum2_sd=sd(_icum)
		assert _icum2_sd==.
			sum benefsdep if _icum!=.
			local realbenefs = r(sum)
		drop _icum2_sd _icum _e _e1 rep
		gen am = montantdep*(potential_ben<=Beneficiaires_i)
		gen beneficiaire = (potential_ben<=Beneficiaires_i)
		replace beneficiaire = 0 if benefsdep == 0 // This is a temporal fix that we should look at later. 
		replace am = 0 if benefsdep ==0
		drop Beneficiaires_i potential_ben numicum
			sum hhweight if eleg_`i'==1
			local potential = r(sum)
			sum beneficiaire [iw=hhweight]
			nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
			if `potential'<=`r(sum)'{
				nois dis as error "Check if assigning every potential beneficiary makes sense."
			}
	}

	
	*ren am am_prog_`i'
	*ren beneficiaire beneficiaire_prog_`i'
	
	gen am_prog_5 = beneficiaire * subsidy_emel_direct
	
	drop benefsdep montantdep
		
	
	
*}	

*collapse (mean) am_prog_5, by(hhid)

keep hhid am_prog_5
ren am_prog_5 subsidy_emel_direct

if $devmode== 1 {
    save "$tempsim/Temwine.dta", replace
}




************************************************************************************/
noi dis as result " 1. Subvention - Agricultural Inputs                          "
************************************************************************************

use "$presim/08_subsidies_fert.dta", clear


gen subsidy_inag_direct = d_sub * ${sub_inag} * fert_val

keep hhid subsidy_inag_direct

merge 1:1 hhid using "$tempsim/Temwine.dta", nogen


tempfile Agric_subsidies_direct_hhid
save `Agric_subsidies_direct_hhid', replace


************************************************************************************/
noi dis as result " 2. Subvention indirecte à Temwine                       "
************************************************************************************

use "$presim/IO_Matrix.dta", clear 

global subsidy_shock_elec = (145 - 70) / 145 * 0.1498

*Shock
gen shock = $subsidy_shock if emel_sec==1
replace shock=0  if shock==.

*Indirect effects 
des sect_*, varlist 
local list "`r(varlist)'"
	
costpush `list', fixed(fixed) priceshock(shock) genptot(emel_tot_shock) genpind(emel_ind_shock) fix
	
gen inag_ind_shock = emel_ind_shock
gen inag_tot_shock	= emel_tot_shock
	
keep sector emel_ind_shock emel_tot_shock inag_ind_shock inag_tot_shock
	
tempfile io_ind_agric
save `io_ind_agric', replace


/***********************************************************************************
*TESTS
***********************************************************************************/

*-------- Welfare 
// Adding indirect effect to database and expanding direct effect per product (codpr)
use "$presim/05_netteddown_expenses_SY.dta", clear 

keep hhid codpr sector pourcentage pondera_informal achats_net achats_net_excise informal_purchase achat_gross 

merge m:1 hhid codpr using "$presim/08_subsidies_elect.dta", nogen keepusing(codpr_elec) keep(master match)

merge m:1 hhid using `Elec_subsidies_direct_hhid', nogen assert(using matched) keep(matched)
merge m:1 hhid using `Agric_subsidies_direct_hhid', nogen assert(using matched) keep(matched)
merge m:1 hhid using `Fuel_subsidies_direct_hhid', nogen assert(using matched) keep(matched)


merge m:1 sector using `io_ind_elec', nogen assert(using matched) keep(matched)
merge m:1 sector using `io_ind_agric', nogen assert(using matched) keep(matched)
merge m:1 sector using `io_ind_fuel', nogen assert(using matched) keep(matched)



if $devmode== 1 {
    save "$presim/Subsidies_check_correct_netdown.dta", replace
}

use "$presim/Subsidies_check_correct_netdown.dta", clear

*1. Removing direct subsidies
replace subsidy_elec_direct = 0 if codpr_elec!=1
replace subsidy_elec_direct = subsidy_elec_direct * pourcentage * pondera_informal

*replace subsidy_eau_direct = 0 if codpr!=332
*replace subsidy_eau_direct = subsidy_eau_direct*pourcentage*pondera_informal

*gen achats_sans_subs_dir = achats_net - subsidy_fuel_direct - subsidy_elec_direct - subsidy_eau_direct
gen achats_sans_subs_dir = achats_net - subsidy_elec_direct - subsidy_emel_direct - subsidy_inag_direct // - subsidy_fuel_direct


if $asserts_ref2018 == 1{
	gen dif1 = achats_net_subind-achats_sans_subs_dir
	tab codpr if abs(dif1)>0.00001
	assert abs(dif1)<0.00001
}

*2. Removing indirect subsidies

gen subsidy_elec_indirect = achats_net * elec_ind_shock
gen subsidy_emel_indirect = achats_net * emel_ind_shock 
gen subsidy_inag_indirect = achats_net * inag_ind_shock 
gen subsidy_fuel_indirect = achats_net * fuel_ind_shock

*gen achats_sans_subs = achats_sans_subs_dir - subsidy_fuel_indirect - subsidy_elec_indirect - subsidy_eau_indirect

gen achats_sans_subs = achats_sans_subs_dir - subsidy_elec_indirect - subsidy_emel_indirect - subsidy_inag_indirect // - subsidy_fuel_indirect


if $asserts_ref2018 == 1{
	gen dif2 = achats_net_excise-achats_sans_subs
	tab codpr if abs(dif2)>0.00001
	assert abs(dif2)<0.00001
}

*We are interested in the detailed long version, to continue the confirmation process with excises and VAT

if $devmode== 1 {
    save "$tempsim/Subsidies_verylong.dta", replace
}
tempfile Subsidies_verylong
save `Subsidies_verylong'


* Create variables in cero
foreach var in subsidy_eau_direct subsidy_eau_indirect {
	gen `var'=0
}

*Finally, we are only interested in the per-household amounts, so we will collapse the database:
collapse (sum) subsidy_elec_direct subsidy_elec_indirect subsidy_eau_direct subsidy_eau_indirect (mean) subsidy_emel_direct subsidy_emel_indirect subsidy_inag_direct subsidy_inag_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_f1_direct subsidy_f2_direct subsidy_f3_direct subsidy_f4_direct, by(hhid) 

*merge 1:1 hhid using `Agricultural_subsidies', nogen keepusing(subsidy_agric) 

if $devmode== 1 {
    save "$tempsim/Subsidies.dta", replace
}
tempfile Subsidies
save `Subsidies'



