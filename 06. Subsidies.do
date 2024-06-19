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



/***********************************************************************************
*TESTS
***********************************************************************************/

*-------- Welfare 
// Adding indirect effect to database and expanding direct effect per product (codpr)
use "$presim/05_netteddown_expenses_SY.dta", clear 

merge m:1 hhid codpr using "$presim/08_subsidies_elect.dta", nogen keepusing(codpr_elec) keep(master match)

merge m:1 hhid using `Elec_subsidies_direct_hhid', nogen assert(using matched) keep(matched)
*merge m:1 hhid using `Water_subsidies_direct_hhid', nogen assert(using matched) keep(matched)

merge m:1 sector using `io_ind_elec', nogen assert(using matched) keep(matched)
*merge m:1 sector using `io_ind_eau', nogen assert(using matched) keep(matched)


if $devmode== 1 {
    save "$presim/Subsidies_check_correct_netdown.dta", replace
}

use "$presim/Subsidies_check_correct_netdown.dta", clear

*1. Removing direct subsidies
replace subsidy_elec_direct = 0 if codpr_elec!=1
replace subsidy_elec_direct = subsidy_elec_direct*pourcentage*pondera_informal

*replace subsidy_eau_direct = 0 if codpr!=332
*replace subsidy_eau_direct = subsidy_eau_direct*pourcentage*pondera_informal

*gen achats_sans_subs_dir = achats_net - subsidy_fuel_direct - subsidy_elec_direct - subsidy_eau_direct
gen achats_sans_subs_dir = achats_net - subsidy_elec_direct


if $asserts_ref2018 == 1{
	gen dif1 = achats_net_subind-achats_sans_subs_dir
	tab codpr if abs(dif1)>0.00001
	assert abs(dif1)<0.00001
}

*2. Removing indirect subsidies

gen subsidy_elec_indirect = achats_net * elec_ind_shock 
*gen subsidy_eau_indirect  = achats_net * eau_ind_shock

*gen achats_sans_subs = achats_sans_subs_dir - subsidy_fuel_indirect - subsidy_elec_indirect - subsidy_eau_indirect

gen achats_sans_subs = achats_sans_subs_dir - subsidy_elec_indirect


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
foreach var in subsidy_fuel_direct subsidy_fuel_indirect subsidy_eau_direct subsidy_eau_indirect subsidy_agric {
	gen `var'=0
}

*Finally, we are only interested in the per-household amounts, so we will collapse the database:
collapse (sum) subsidy_fuel_direct subsidy_fuel_indirect subsidy_elec_direct subsidy_elec_indirect subsidy_eau_direct subsidy_eau_indirect subsidy_agric, by(hhid) 

*merge 1:1 hhid using `Agricultural_subsidies', nogen keepusing(subsidy_agric) 

if $devmode== 1 {
    save "$tempsim/Subsidies.dta", replace
}
tempfile Subsidies
save `Subsidies'



