
/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico based on Disposable Income by Mayor Cabrera
* Date: June 2020
* Version: 1.0

*Version 2: 
			- Streamlined
			- Added VAT exempt policies
			- Change gratuite services as cash transfers: am_subCMU am_sesame am_moin5 am_cesarienne. Pendent to ask about am_subCMU

*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------

****************************************************************************/


*Constructing DisposableIncome
/*
Disposable Income = Consumption Aggregate of HHD Survey
Calculate poverty using Consumption Aggregate of Survey
To estimate Per Capita Disposable Income, it is necessary to identify only members of the household
Check new poverty estimates
*/

*****************************************************************************


use "$presim/01_menages.dta", clear

keep hhid hhsize hhweight dtot zref line_*

foreach var in csh_mutsan am_bourse am_subCMU am_sesame am_moin5 am_cesarienne Sante_inKind {
	gen `var'=0
} 

gen double yd_pre= dtot / hhsize


* Now casting from 2019 to 2024
if $nowcast24 == 1 {

	replace zref = zref * ${nc_ipc_gr}
	*replace hhweight = hhweight * ${nc_pop_gr}
	
	replace yd_pre = yd_pre * ${nc_gdp_gr}

	replace line_1 = line_1 * ${ppp_ipc}
	replace line_2 = line_2 * ${ppp_ipc}
	replace line_3 = line_3 * ${ppp_ipc}

}


if $devmode== 1 {
	merge 1:1 hhid using "${tempsim}/social_security_contribs.dta", nogen keepusing(hhid ss*)
	merge 1:1 hhid using "${tempsim}/income_tax_collapse.dta", nogen keepusing(hhid income_tax_*)
	merge 1:1 hhid using "${tempsim}/Direct_transfers.dta", nogen keepusing(hhid rev_universel am_prog*)
	merge 1:1 hhid using "${tempsim}/CustomDuties_taxes", nogen keepusing(hhid CD*)
	merge 1:1 hhid using "${tempsim}/Subsidies", nogen keepusing(hhid subsidy*)
	merge 1:1 hhid using "${tempsim}/Excise_taxes.dta", nogen keepusing(hhid excise_taxes)
	merge 1:1 hhid using "${tempsim}/VAT_taxes.dta", nogen keepusing(hhid TVA* achats_avec_VAT)
	merge 1:1 hhid using "${tempsim}/Transfers_InKind.dta", nogen keepusing(hhid health_inKind am_educ* education* am_health*)
}

else {
	merge 1:1 hhid using `social_security_contribs' , nogen
	merge 1:1 hhid using `income_tax_collapse' , nogen
	merge 1:1 hhid using `Direct_transfers'  , nogen
	merge 1:1 hhid using `Subsidies' , nogen
	merge 1:1 hhid using `Excise_taxes' , nogen
	merge 1:1 hhid using `VAT_taxes' , nogen
	merge 1:1 hhid using `Transfers_InKind' , nogen
}

*All policies, regarless of them being taxes or subsidies, should be positive 

*Gross market income that is going to be used as basis of all calculations:
*merge 1:1 hhid using "$presim/gross_ymp_pc.dta" , nogen
gen ymp_pc=yd_pre
	

	local Directaxes 		"${Directaxes}"
	local Contributions 	"${Contributions}" 
	local DirectTransfers   "${DirectTransfers}"
	local Subsidies         "${Subsidies}"
	local Indtaxes 			"${Indtaxes}"
	local InKindTransfers	"${InKindTransfers}" 
		
	local taxcs 			`Directaxes' `Indtaxes' `Contributions'
	local transfers         `DirectTransfers' `Subsidies' `InKindTransfers'
		
		
	di "`Directaxes' /// `Contributions' /// `DirectTransfers' /// `Subsidies' /// `Indtaxes' /// `InKindTransfers'"


	foreach i in `Directaxes' `Contributions' `DirectTransfers'  `Indtaxes' `subsidies' `InKindTransfers' {
		replace `i'=0 if `i'==.
	}

	foreach var of local taxcs {
		gen `var'_pc= `var'/hhsize
	}
		
	foreach var of local transfers {
		gen `var'_pc= `var'/hhsize
	}
	
	foreach listvar in Directaxes Indtaxes InKindTransfers Contributions DirectTransfers subsidies taxcs transfers{
		local `listvar'_pc ""
		foreach var of local `listvar' {
			local `listvar'_pc "``listvar'_pc' `var'_pc"
			di "`listvar'_pc"
		}

	}
	
*change taxes and contributions to negatives (only _pc to calculate income definitions)

	foreach i in `Indtaxes_pc' `Directaxes_pc' `Contributions_pc' {
		replace `i'=-`i'
	}
	
*************************************** NET MARKET INCOME  ---STARTING POINT:  MARKET INCOME CALCULATED IN THE GROSSING UP
 
egen  double aux= rowtotal(`Directaxes_pc' `Contributions_pc' ) // Income before tax minus taxes and contributions
egen  double yn_pc= rowtotal(ymp_pc aux) 
replace yn_pc=0 if yn_pc==.
replace yn_pc=0 if yn_pc<0
label var yn_pc "Net Market Income per capita" 

			
***************************************DISPOSABLE INCOME --ASSERT THAT WE ARRIVE TO THE SAME PER CAPITA CONSUMPTION


egen  double yd_pc = rowtotal(yn_pc `DirectTransfers_pc') 
replace yd_pc=0 if yd_pc==.
label var yd_pc "Disposable Income per capita"

gen double dif_grossup = yd_pc-yd_pre

if $asserts_ref2018 == 1{
	count if abs(dif_grossup) >0.01
	if `r(N)'>0{
		noi dis as error "The disposable income obtained is different than the per capita consumption that we assumed in the grossing up."
		noi dis as error "This happened because you changed policies that affected direct transfers, income tax, or SS contributions."
		assert `r(N)'==0
	}
	else {
		noi dis "{opt The disposable income obtained is equal to the per capita consumption that we assumed in the grossing up.}"
		noi dis "{opt This means that you have not changed any policies related with direct transfers, income tax, or SS contributions.}"
	}
}

***************************************CONSUMABLE INCOME ---MOVING FORWARD : adding indirect taxes and subsidies
egen  double yc_pc = rowtotal(yd_pc `subsidies_pc' `Indtaxes_pc' )
replace yc_pc=0 if yc_pc==.
replace yc_pc=0 if yc_pc<0
label var yc_pc "Consumable Income per capita"

***************************************Final INCOME
egen  double yf_pc= rowtotal(yc_pc `InKindTransfers_pc' )
replace yf_pc=0 if yf_pc==.
replace yf_pc=0 if yf_pc<0
label var yf_pc "Final Income per capita"


* Some results 
gen all = 1
gen pondih= hhweight*hhsize
 

_ebin ymp_pc [aw=pondih], nq(100) gen(ymp_centile_pc)
_ebin yn_pc [aw=pondih], nq(100) gen(yn_centile_pc)
_ebin yd_pc [aw=pondih], nq(100) gen(yd_centile_pc)
_ebin yc_pc [aw=pondih], nq(100) gen(yc_centile_pc)
_ebin yf_pc [aw=pondih], nq(100) gen(yf_centile_pc)

_ebin ymp_pc [aw=pondih], nq(10) gen(deciles_pc)
_ebin yd_pc [aw=pondih], nq(10) gen(yd_deciles_pc)
_ebin yc_pc [aw=pondih], nq(10) gen(yc_deciles_pc)

egen contribution_securite_social=rowtotal(`Contributions')

gen poor=1 if yc_pc<=zref
recode poor .= 0
tab poor [iw=pondih]


*change taxes and contributions back to positives

foreach i in `Indtaxes_pc' `Directaxes_pc' `Contributions_pc' {
		replace `i'=-`i'
}


save "$data_out/output.dta", replace


if "$scenario_name_save" == "v3_MRT_Ref" & $save_scenario ==1 {
	save "$data_out/output_ref.dta", replace
}

** New poor and old poor using _ref and selected scenario 

use "$data_out/output.dta" , clear


rename poor poor_simu

merge 1:1 hhid using "$data_out/output_ref"  , keepusing(poor) nogen

rename poor poor_ref 

gen new_poor_pc=  poor_simu==1 & poor_ref==0

gen old_poor_pc=  poor_simu==0 & poor_ref==1
sort hhid

cap drop depan // Just changed...
gen depan=achats_avec_VAT
gen depan_pc=depan/hhsize

*Generate other measures not used in income calculations
*gen income_tax_reduc_pc = income_tax_reduc/hhsize

*----- Generate policy aggregations



* Specific policy
gen ss_contribs_total = ss_contrib_pri + ss_contrib_pub
gen ss_contribs_total_pc = ss_contrib_pri_pc + ss_contrib_pub_pc


gen Tax_TVA = TVA_direct + TVA_indirect
gen Tax_TVA_pc = TVA_direct_pc + TVA_indirect_pc

gen subsidy_elec = subsidy_elec_direct + subsidy_elec_indirect
gen subsidy_elec_pc = subsidy_elec_direct_pc + subsidy_elec_indirect_pc

gen subsidy_fuel = subsidy_fuel_direct + subsidy_fuel_indirect
gen subsidy_fuel_pc = subsidy_fuel_direct_pc + subsidy_fuel_indirect_pc

gen subsidy_total = subsidy_elec + subsidy_fuel + subsidy_emel_direct + subsidy_inag_direct
gen subsidy_total_pc = subsidy_elec_pc + subsidy_fuel_pc + subsidy_emel_direct_pc + subsidy_inag_direct_pc

gen inktransf_educ = am_educ_1 + am_educ_2 + am_educ_3 + am_educ_4 + am_educ_7
gen inktransf_educ_pc = am_educ_1_pc + am_educ_2_pc + am_educ_3_pc + am_educ_4_pc + am_educ_7_pc

gen inktransf_health = am_health
gen inktransf_health_pc = am_health_pc

gen am_prog_sa = am_prog_1 + am_prog_2 + am_prog_3 + am_prog_4
gen am_prog_sa_pc = am_prog_1_pc + am_prog_2_pc + am_prog_3_pc + am_prog_4_pc

gen am_prog = am_prog_1 + am_prog_2 + am_prog_3 + am_prog_4
gen am_prog_pc = am_prog_1_pc + am_prog_2_pc + am_prog_3_pc + am_prog_4_pc

gen ss_ben_sa = ss_ben_old + ss_ben_other
gen ss_ben_sa_pc = ss_ben_old_pc + ss_ben_other_pc


* General policy
egen dirtax_total = rowtotal(`Directaxes')
egen dirtax_total_pc = rowtotal(`Directaxes_pc')

egen dirtransf_total = rowtotal(`DirectTransfers')
egen dirtransf_total_pc = rowtotal(`DirectTransfers_pc')

egen sscontribs_total = rowtotal(`Contributions')
egen sscontribs_total_pc = rowtotal(`Contributions_pc')

*egen subsidy_total = rowtotal(`Subsidies')
*egen subsidy_total_pc = rowtotal(`Subsidies_pc')

egen indtax_total = rowtotal(`Indtaxes')
egen indtax_total_pc = rowtotal(`Indtaxes_pc')

egen inktransf_total = rowtotal(`InKindTransfers')
egen inktransf_total_pc = rowtotal(`InKindTransfers_pc')



*------- Per capita totals
foreach i in `Directaxes' `Contributions' `DirectTransfers'  `Indtaxes' `subsidies' `InKindTransfers' {
	
}

*------- Labels	Policy 
foreach i in `Directaxes' `Contributions' `DirectTransfers'  `Indtaxes' `subsidies' `InKindTransfers' {
	local var `i' 
	*di "$`var'_lab"
	label var `var' "$`var'_lab"
	
}

local policylist `Directaxes' dirtax_total `Contributions' ss_contribs_total `DirectTransfers' dirtransf_total am_prog_sa ss_ben_sa `subsidies' subsidy_elec subsidy_fuel subsidy_total `Indtaxes' Tax_TVA indtax_total `InKindTransfers' inktransf_educ inktransf_health inktransf_total

foreach var of local policylist{
	local labelle : variable label `var'
	label var `var'_pc "`labelle'"
}



save "$data_out/output.dta", replace

if $save_scenario == 1 {	
	save "$data_out/output_${scenario_name_save}.dta", replace
}








