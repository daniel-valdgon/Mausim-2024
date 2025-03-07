
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

/* Disposable Income in the gross up */
gen double yd_pre=round(dtot/hhsize,0.01)

if $devmode== 1 {
merge 1:1 hhid using "${tempsim}/income_tax_collapse.dta" , nogen
merge 1:1 hhid using "${tempsim}/social_security_contribs.dta" , nogen
merge 1:1 hhid using "${tempsim}/Direct_transfers.dta"  , nogen
merge 1:1 hhid using "${tempsim}/Subsidies" , nogen
merge 1:1 hhid using "${tempsim}/Excise_taxes.dta" , nogen
merge 1:1 hhid using "${tempsim}/VAT_taxes.dta", nogen 
merge 1:1 hhid using "${tempsim}/Transfers_InKind.dta" , nogen
}

else {
merge 1:1 hhid using `income_tax_collapse' , nogen
merge 1:1 hhid using `social_security_contribs' , nogen
merge 1:1 hhid using `Direct_transfers'  , nogen
merge 1:1 hhid using `Subsidies' , nogen
merge 1:1 hhid using `Excise_taxes' , nogen
merge 1:1 hhid using `VAT_taxes' , nogen
merge 1:1 hhid using `Transfers_InKind' , nogen
}

ren subsidy_elec_direct 	sub_10B
ren subsidy_elec_indirect 	sub_10C
ren subsidy_emel_direct 	sub_20B
ren subsidy_emel_indirect 	sub_20C

ren excise_taxes			ind_10B
ren TVA_direct				ind_20B
ren TVA_indirect			ind_20C

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
	
	*local pol_all			`taxcs' `transfers'

	foreach i in `Directaxes' `Contributions' `DirectTransfers'  `Indtaxes' `Subsidies' `InKindTransfers' {
		replace `i'=0 if `i'==.
	}

	foreach var of local taxcs {
		gen `var'_pc= `var'/hhsize
	}
		
	foreach var of local transfers {
		gen `var'_pc= `var'/hhsize
	}
	
	foreach listvar in Directaxes Indtaxes InKindTransfers Contributions DirectTransfers Subsidies taxcs transfers{
		local `listvar'_pc ""
		foreach var of local `listvar' {
			local `listvar'_pc "``listvar'_pc' `var'_pc"
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
egen  double yc_pc = rowtotal(yd_pc `Subsidies_pc' `Indtaxes_pc' )
replace yc_pc=0 if yc_pc==.
replace yc_pc=0 if yc_pc<0
label var yc_pc "Consumable Income per capita"

***************************************Final INCOME
egen  double yf_pc= rowtotal(yc_pc `InKindTransfers_pc' )
replace yf_pc=0 if yf_pc==.
replace yf_pc=0 if yf_pc<0
label var yf_pc "Final Income per capita"

*if ("$country" == "SEN") {
*	merge 1:1 hhid using "$presim\ehcvm_welfare_SEN2018.dta" , keepusing(zref) nogen // THis is country specific for Senegal, zref should be taken from the same data, and from zr
*}


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

gen poor=1 if yc_pc<=zref
recode poor .= 0
tab poor [iw=pondih]

*change taxes and contributions back to positives

foreach i in `Indtaxes_pc' `Directaxes_pc' `Contributions_pc' {
		replace `i'=-`i'
	}

/*
* Other variable to create descriptive statistics outside the CEQ
foreach var in depan  `list_item_stats' income_tax_reduc  { 
gen `var'_pc= `var'/hhsize
}
*/

// international pov lines
if ("$country" == "MRT") {

	* MRT: i2017 - 1.05, i2018 - 0.65, i2019 - 0.98. ccpi_a
	* MRT: i2017 - 3.0799999,	i2018 - 4.2035796. fcpi_a
	* MRT: i2017 - 2.269, i2018 - 3.07. hcpi_a
	* MRT Inflation according to WorldBank Data Dashboard. 2017 - 2.3, 2018 - 3.1
	* Country specific...

	local ppp17 = 12.4452560424805
	local inf17 = 2.3
	local inf18 = 3.1
	local inf19 = 2.3
	cap drop line_1 line_2 line_3
	gen line_1=2.15*365*`ppp17'*`inf17'*`inf18'*`inf19'
	gen line_2=3.65*365*`ppp17'*`inf17'*`inf18'*`inf19'
	gen line_3=6.85*365*`ppp17'*`inf17'*`inf18'*`inf19'

	foreach var in /*line_1 line_2 line_3*/ yd_pc yc_pc  {
		gen test=1 if `var'<=zref
		recode test .= 0
		*noi tab test [iw=hhweight*hhsize]
		drop test
	}

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

*------- Generate policy aggregations
foreach i in `Directaxes' `Contributions' `DirectTransfers'  `Indtaxes' `subsidies' `InKindTransfers' {

	local var `i' 
	
	* Sum Direct and indirect effects 
	if (substr("`var'",-1,.) == "B" | substr("`var'",-1,.) == "C") & substr("`var'",1,3) == "sub" {
		di "`var'"
		forvalues j=1/2 {
			cap egen sub_`j'0A = rowtotal(sub_`j'0*)
			cap egen sub_`j'0A_pc = rowtotal(sub_`j'0*_pc)

		}
	}
	
	if (substr("`var'",-1,.) == "B" | substr("`var'",-1,.) == "C") & substr("`var'",1,3) == "ind" {
		di "`var'"
		forvalues j=1/2 {
			cap egen ind_`j'0A = rowtotal(ind_`j'0*)
			cap egen ind_`j'0A = rowtotal(ind_`j'0*_pc)

		}
	} 
	
	
}

*------- Labels	
*egen contribution_securite_social=rowtotal(`Contributions')

egen dirtax_total = rowtotal(`Directaxes')
egen dirtax_total_pc = rowtotal(`Directaxes_pc')

egen dirtransf_total = rowtotal(`DirectTransfers')
egen dirtransf_total_pc = rowtotal(`DirectTransfers_pc')

*egen sscontribs_total = rowtotal(`Contributions')
*egen sscontribs_total_pc = rowtotal(`Contributions_pc')

egen subsidy_total = rowtotal(`Subsidies')
egen subsidy_total_pc = rowtotal(`Subsidies_pc')

egen indtax_total = rowtotal(`Indtaxes')
egen indtax_total_pc = rowtotal(`Indtaxes_pc')

egen inktransf_total = rowtotal(`InKindTransfers')
egen inktransf_total_pc = rowtotal(`InKindTransfers_pc')

gen sscontribs_total = 0
gen sscontribs_total_pc = 0


*Labeling policy variables

*------- Labels	
foreach i in `Directaxes' `Contributions' `DirectTransfers'  `Indtaxes' `subsidies' `InKindTransfers' {
	local var `i' 
	*di "$`var'_lab"
	label var `var' "$`var'_lab"
	
}

local policylist `Directaxes' dirtax_total `Contributions' sscontribs_total `DirectTransfers' dirtransf_total `Subsidies' subsidy_total `Indtaxes' indtax_total `InKindTransfers' inktransf_total

foreach var of local policylist{
	local labelle : variable label `var'
	label var `var'_pc "`labelle'"
}

save "$data_out/output.dta", replace

if $save_scenario == 1 {	
	save "$data_out/output_${scenario_name_save}.dta", replace
}









