/********************************************************************************
********************************************************************************
* Program: Program for the Impact of Fiscal Reforms
* Author: Julieth Pico 
* Date: August 2019
* Version: 1.0

Modified: 	Daniel Valderrama 
			-Shorten it for R-Shinny
			-Converting to Soft-code the intervals
			-Re-estimate the Kwh consumed (done in the pre_sim dofile). This is a major change: 
				a. Adjuts user of DPP and DMP using administrative data_sn
				b. Correct for prices for each tranche of consumption including redevance, TCO, VAT and tarifss before the policy change of 2019 
				c. Correct the reading of tranche to bi-monthly for post-paid and monthly for pre-paid 
			- In the excel file now contains a variable define as cos and other as tariffs. User should input those variables in 2019 prices. So deflate the nominal values 
			- Adding pre-paid and postpaid 
			- Allow tranches to be soft-coded
			
			Pendent: 
			- Add it Indirect effects from Electricity
			- Added the agricultural as parameter in the excel tool 
			
*--------------------------------------------------------------------------------

************************************************************************************/
noi dis as result " 1. Subvention directe à l'Électricité                          "
************************************************************************************

use "$tempsim/08_subsidies_elect_Adjusted.dta", clear

*Define tranches for subsidies consumption_electricite is bimonthly so intervals should also be bimonthly 

forval i=1/7{
	gen tranche`i'_tool=. //(AGV) The user can use up to 7 tranches in the tool, but certainly most of them will not be used
}

foreach payment in  0 1 {	
		
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
replace tranche_elec_max = 1 if tranche1_tool !=. & tranche_elec_max==.

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

import excel "$data_sn\IO_Matrix.xlsx", sheet("Sheet1") firstrow clear
	
	*Define fixed sectors 
	local thefixed 22 32 33 34 13 	//electricite gaz et eau, activites d'administration pub, education et formation, activites de sante et action s, raffinage petrole cokefaction

	gen fixed=0
	foreach var of local thefixed {
		replace fixed=1  if  Secteur==`var'
	}
	
	*Shock
	gen shock=$subsidy_shock_elec if Secteur==22
	replace shock=0  if shock==.

	*Indirect effects 
	costpush C1-C35, fixed(fixed) priceshock(shock) genptot(elec_tot_shock) genpind(elec_ind_shock) fix
	
	keep Secteur elec_ind_shock elec_tot_shock
	
tempfile io_ind_elec
save `io_ind_elec', replace



/**********************************************************************************/
noi dis as result " 3. Subvention Agricole (aux producteurs)                       "
/**********************************************************************************/

*AG: There are no sources on this policy. I did some research and it seems like the whole budget of the Dept. of Agriculture was 53 milliards.  Check this at the end.

use "$presim/08_agr_subsidies.dta", clear

egen total_intrat_achete=total(s16bq09c*hhweight)
gen pourc_subvention=s16bq09c/total_intrat_achete
gen subsidy_agric=${total_agriculture}*pourc_subvention

*16/10/2023 AGV: We decided to remove agricultural subsidies until we understand correctly how to model it.
replace subsidy_agric=0

if $devmode== 1 {
    save "$tempsim/Agricultural_subsidies.dta", replace
}
tempfile Agricultural_subsidies
save `Agricultural_subsidies'

 
/**********************************************************************************/
noi dis as result " 4. Subvention directe aux Carburants                           "
/**********************************************************************************/

use "$tempsim/08_subsidies_fuel_Adjusted.dta", clear

*Compute subsidy receive for each tranche of consumption 

rename q_fuel q_fuel_hh 

foreach pdto in pet_lamp butane {
	gen sub_`pdto'	= .
	replace sub_`pdto'= (${mp_`pdto'}-${sp_`pdto'})*q_`pdto' 		
}

foreach pdto in fuel_hh fuel208 fuel209 fuel304 {
	gen sub_`pdto'	= .
	replace sub_`pdto'= (${mp_fuel_hh}-${sp_fuel_hh})*q_`pdto' 		
}

egen subsidy_fuel_direct=rowtotal(sub_fuel_hh sub_pet_lamp sub_butane)  

tempfile fuel_dir_sub_hhid
save `fuel_dir_sub_hhid'



************************************************************************************
noi dis as result " 5. Subvention indirecte aux Carburants                         "
************************************************************************************
	
// load IO
import excel "$data_sn\IO_Matrix.xlsx", sheet("Sheet1") firstrow clear
drop if Secteur==.

gen shock=$sr_fuel_ind if inlist(Secteur, 13)
	replace shock=0 if shock==. 
	
// Fixed 
gen fixed=1 if inlist(Secteur, 32, 33, 34, 22, 13) // health, education, electricity , oil 
	replace fixed=0 if fixed==.

// Cost push 
costpush C1-C35, fixed(fixed) price(shock) genptot(fuel_tot_shock) genpind(fuel_ind_shock) fix

tempfile fuel_ind_sim_Secteur
save `fuel_ind_sim_Secteur', replace 


*-------- Welfare 
// Adding indirect effect to database and expanding direct effect per product (codpr)

use "$tempsim/05_netteddown_expenses_SY_Adjusted.dta", clear 
merge m:1 Secteur using `fuel_ind_sim_Secteur' , assert(matched using) keep(matched) nogen

merge m:1 hhid using `fuel_dir_sub_hhid' , assert(matched using) keep(matched) nogen

gen subsidy_fuel_indirect=achats_net*fuel_ind_shock

rename subsidy_fuel_direct subsidy_fuel_direct_hhidlevel
gen subsidy_fuel_direct = 0
replace subsidy_fuel_direct = sub_butane*pourcentage*pondera_informal   if codpr==303
replace subsidy_fuel_direct = sub_pet_lamp*pourcentage*pondera_informal if codpr==202
replace subsidy_fuel_direct = sub_fuel208*pourcentage*pondera_informal  if codpr==208
replace subsidy_fuel_direct = sub_fuel209*pourcentage*pondera_informal  if codpr==209
replace subsidy_fuel_direct = sub_fuel304*pourcentage*pondera_informal  if codpr==304

tempfile fuel_verylong
save `fuel_verylong', replace 

egen subvention_fuel=rowtotal(subsidy_fuel_indirect subsidy_fuel_direct)

collapse (sum) subsidy_fuel_indirect subsidy_fuel_direct subvention_fuel (mean) subsidy_fuel_direct_hhidlevel, by(hhid)

if $asserts_ref2018 == 1{
	assert abs(subsidy_fuel_direct-subsidy_fuel_direct_hhidlevel) <0.0001
}

drop subsidy_fuel_direct_hhidlevel

if $devmode== 1 {
    save "$tempsim/Fuel_subsidies.dta", replace
}
tempfile Fuel_subsidies
save `Fuel_subsidies', replace 





/**********************************************************************************/
noi dis as result " 6. Subvention directe à l'Eau                                  "
/**********************************************************************************/

use "$tempsim/05_water_quantities_Adjusted.dta", clear


*Define tranches for subsidies consumption_electricite is bimonthly so intervals should also be bimonthly 

forval i=1/7{
	gen tranche`i'_tool_eau=. //(AGV) The user can use up to 7 tranches in the tool, but certainly most of them will not be used
}


local i=0
global MaxT0_eau 0 //This "tranche 0" is helpful for the next loops
foreach tranch in $typesEaueau {
	local j = `i'+1
	replace tranche`j'_tool_eau=${Max`tranch'_eau}-${MaxT`i'_eau} if eau_quantity>=${Max`tranch'_eau}
	replace tranche`j'_tool_eau=eau_quantity-${MaxT`i'_eau} if eau_quantity<${Max`tranch'_eau} & eau_quantity>${MaxT`i'_eau}
	local ++i
	dis "Water consumption, tranche `i'"
}

forval i=1/7{
	replace tranche`i'_tool_eau=0 if tranche`i'_tool_eau==.
}

gen tranche_water_max = .
forval i=1/7{
	local l = 8-`i'
	replace tranche_water_max = `l' if tranche`l'_tool_eau!=0 & tranche`l'_tool_eau !=. & tranche_water_max==.
	gen subsidy`i'=.
}
replace tranche_water_max = 1 if tranche1_tool_eau !=. & tranche_water_max==.

local i=1
foreach tranch in $typesEaueau {
	replace subsidy`i'=${Subvention`tranch'_eau}*tranche`i'_tool_eau
	local ++i
}

egen subsidy_eau_direct=rowtotal(subsidy*)

*Tranches are bimonthly therefore subsidy is bimonthly. Here we convert to annual values everything 
foreach v of varlist subsidy* {
	replace `v'=6*`v'
}

forval i=1/7{
	sum tranche`i'_tool_eau
	if `r(mean)'==0{
		drop tranche`i'_tool_eau
	}
	sum subsidy`i'
	if `r(N)'==0{
		drop subsidy`i'
	}
}

tempfile Water_subsidies_direct_hhid
save `Water_subsidies_direct_hhid'
	

************************************************************************************
noi dis as result " 7. Subvention indirecte à l'Eau                                "
************************************************************************************


import excel "$data_sn\IO_Matrix.xlsx", sheet("Sheet1") firstrow clear
	
	*Define fixed sectors 
	local thefixed 22 32 33 34 13 	//electricite gaz et eau, activites d'administration pub, education et formation, activites de sante et action s, raffinage petrole cokefaction

	gen fixed=0
	foreach var of local thefixed {
		replace fixed=1  if  Secteur==`var'
	}
	
	*Shock
	gen shock=$subsidy_shock_eau if Secteur==22
	replace shock=0  if shock==.

	*Indirect effects 
	costpush C1-C35, fixed(fixed) priceshock(shock) genptot(eau_tot_shock) genpind(eau_ind_shock) fix
	
	keep Secteur eau_ind_shock eau_tot_shock
	
tempfile io_ind_eau
save `io_ind_eau', replace




/***********************************************************************************
*TESTS
***********************************************************************************/

use `fuel_verylong', clear

merge m:1 hhid using `Elec_subsidies_direct_hhid', nogen assert(using matched) keep(matched)
merge m:1 hhid using `Water_subsidies_direct_hhid', nogen assert(using matched) keep(matched)

merge m:1 Secteur using `io_ind_elec', nogen assert(using matched) keep(matched)
merge m:1 Secteur using `io_ind_eau', nogen assert(using matched) keep(matched)

if $devmode== 1 {
    save "$presim/Subsidies_check_correct_netdown.dta", replace
}

*use "$presim/Subsidies_check_correct_netdown.dta", clear

*1. Removing direct subsidies

replace subsidy_elec_direct = 0 if codpr!=334
replace subsidy_elec_direct = subsidy_elec_direct*pourcentage*pondera_informal
replace subsidy_eau_direct = 0 if codpr!=332
replace subsidy_eau_direct = subsidy_eau_direct*pourcentage*pondera_informal

gen achats_sans_subs_dir = achats_net - subsidy_fuel_direct - subsidy_elec_direct - subsidy_eau_direct



if $asserts_ref2018 == 1{
	gen dif1 = achats_net_subind-achats_sans_subs_dir
	tab codpr if abs(dif1)>0.00001
	assert abs(dif1)<0.00001
}

*2. Removing indirect subsidies

gen subsidy_elec_indirect = achats_net * elec_ind_shock 
gen subsidy_eau_indirect  = achats_net * eau_ind_shock

gen achats_sans_subs = achats_sans_subs_dir - subsidy_fuel_indirect - subsidy_elec_indirect - subsidy_eau_indirect


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





*Finally, we are only interested in the per-household amounts, so we will collapse the database:

collapse (sum) subsidy_fuel_direct subsidy_elec_direct subsidy_eau_direct subsidy_elec_indirect subsidy_eau_indirect subsidy_fuel_indirect, by(hhid)

merge 1:1 hhid using `Agricultural_subsidies', nogen keepusing(subsidy_agric) 

if $devmode== 1 {
    save "$tempsim/Subsidies.dta", replace
}
tempfile Subsidies
save `Subsidies'



