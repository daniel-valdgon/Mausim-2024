
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


use "$data_sn/ehcvm_conso_SEN2018_menage.dta", clear

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

*All policies, regarless of them being taxes or subsidies, should be positive 

*Gross market income that is going to be used as basis of all calculations:
merge 1:1 hhid using "$data_sn/gross_ymp_pc.dta" , nogen

	local Directaxes 		"income_tax trimf"
	local Contributions 	"csh_css csh_ipm csh_mutsan" //(AGV) Note that csh_mutsan is created in 4.DirTransfers and not in 3.SSC (as it should). csp_ipr csp_fnr excluded because, in PDI, pension contributions are not included.
	local DirectTransfers   "am_bourse am_Cantine am_BNSF am_subCMU"
	local subsidies         "subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_eau_direct subsidy_eau_indirect subsidy_agric"
	local Indtaxes 			"excise_taxes TVA_direct TVA_indirect"
	local InKindTransfers	"education_inKind Sante_inKind am_sesame am_moin5 am_cesarienne" //(AGV) Note that  am_sesame am_moin5 am_cesarienne are created in the direct transfers file, but they act more like in kind transfers
	local taxcs 			`Directaxes' `Indtaxes' `Contributions'
	local transfers         `DirectTransfers' `subsidies' `InKindTransfers'
	

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

merge 1:1 hhid using "$data_sn\ehcvm_welfare_SEN2018.dta" , keepusing(zref) nogen

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

/*
* Other variable to create descriptive statistics outside the CEQ
foreach var in depan  `list_item_stats' income_tax_reduc  { 
gen `var'_pc= `var'/hhsize
}
*/

// international pov lines

*2011 PPP:
*gen line_1=179514.1606
*gen line_2=302339.6389
*gen line_3=519646.2543

*2017 PPP

preserve
	use "$data_sn/s02_me_SEN2018.dta", clear
	keep hhid s00q23a s00q24a s00q25a s00q23b s00q24b s00q25b
	duplicates drop
	tempfile dates
	save `dates'
restore

merge 1:1 hhid using `dates', keepusing(s00q23a s00q24a s00q25a s00q23b s00q24b s00q25b) nogen
local n=1
foreach var in s00q23a s00q24a s00q25a s00q23b s00q24b s00q25b{
	gen mois`n' = substr(`var',6,2)
	gen an`n' = substr(`var',1,4)
	replace mois`n'="" if mois`n'=="##"
	replace an`n'="" if an`n'=="##N/"
	destring mois`n', replace
	destring an`n', replace
	local ++n
}

egen month=rowmean(mois*)
replace month=round(month)

tab month an1, mis

drop mois* 
drop an2-an6

*The data on inflation correspond to the ratio of monthly cpi and average 2017 cpi
*source: https://www.worldbank.org/en/research/brief/inflation-database
gen ipc_month_yr_svy_17=. 
replace ipc_month_yr_svy_17=1.024191896 if month==9
replace ipc_month_yr_svy_17=1.017667176 if month==10
replace ipc_month_yr_svy_17=1.011047895  if month==11
replace ipc_month_yr_svy_17=1.017572615  if month==12
replace ipc_month_yr_svy_17=1.008759992  if month==4
replace ipc_month_yr_svy_17=1.009150417 if month==5
replace ipc_month_yr_svy_17=1.013347483 if month==6
replace ipc_month_yr_svy_17=1.01598285 if month==7


gen line_1=2.15*365*238.57769775*ipc_month_yr_svy_17
gen line_2=3.65*365*238.57769775*ipc_month_yr_svy_17
gen line_3=6.85*365*238.57769775*ipc_month_yr_svy_17




save "$data_out/output.dta", replace


if "$scenario_name_save" == "Ref_2018" & $save_scenario ==1 {
	save "$data_out/output_ref.dta", replace
}

** New poor and old poor using _ref and selected scenario

use "$data_out/output.dta" , clear


rename poor poor_simu

merge 1:1 hhid using "$data_out\output_ref"  , keepusing(poor) nogen

rename poor poor_ref 

gen new_poor_pc=  poor_simu==1 & poor_ref==0

gen old_poor_pc=  poor_simu==0 & poor_ref==1
sort hhid


gen depan=achats_avec_VAT
gen depan_pc=depan/hhsize

*Generate other measures not used in income calculations

gen income_tax_reduc_pc = income_tax_reduc/hhsize


*Generate policy aggregations

gen Tax_TVA = TVA_direct + TVA_indirect
gen Tax_TVA_pc = TVA_direct_pc+TVA_indirect_pc

gen subsidy_elec = subsidy_elec_direct + subsidy_elec_indirect
gen subsidy_elec_pc = subsidy_elec_direct_pc + subsidy_elec_indirect_pc

gen subsidy_eau = subsidy_eau_direct + subsidy_eau_indirect
gen subsidy_eau_pc = subsidy_eau_direct_pc + subsidy_eau_indirect_pc

gen subsidy_fuel = subsidy_fuel_direct + subsidy_fuel_indirect
gen subsidy_fuel_pc = subsidy_fuel_direct_pc + subsidy_fuel_indirect_pc

egen dirtax_total = rowtotal(`Directaxes')
egen dirtax_total_pc = rowtotal(`Directaxes_pc')

egen dirtransf_total = rowtotal(`DirectTransfers')
egen dirtransf_total_pc = rowtotal(`DirectTransfers_pc')

egen sscontribs_total = rowtotal(`Contributions')
egen sscontribs_total_pc = rowtotal(`Contributions_pc')

gen subsidy_total = subsidy_elec + subsidy_fuel + subsidy_eau + subsidy_agric
gen subsidy_total_pc = subsidy_elec_pc + subsidy_fuel_pc + subsidy_eau_pc + subsidy_agric_pc

gen indtax_total = excise_taxes + Tax_TVA
gen indtax_total_pc = excise_taxes_pc + Tax_TVA_pc

gen am_CMU_progs = am_sesame + am_moin5 + am_cesarienne
gen am_CMU_progs_pc = am_sesame_pc + am_moin5_pc + am_cesarienne_pc

gen inktransf_total = Sante_inKind + education_inKind + am_CMU_progs
gen inktransf_total_pc = Sante_inKind_pc + education_inKind_pc + am_CMU_progs_pc


*Labeling policy variables

label var dirtax_total	"Impôts directs"
label var income_tax	"Impôt sur le Revenu"
label var income_tax_reduc	"Déductions et Quotient Familial"
label var trimf	"TRIMF"
label var sscontribs_total	"Cotisations de Securité Sociale"
label var csp_ipr	"Cotisation Retraite IPRES (DELETED)"
label var csp_fnr	"Cotisation Retraite FNR (DELETED)"
label var csh_css	"Risque Maladie et Allocation Familiale"
label var csh_ipm	"Cotisation Santé à IPM"
label var dirtransf_total	"Transferts directs"
label var am_BNSF	"BNSF"
label var am_Cantine	"Cantines Scolaires"
label var am_bourse	"Bourse d'Éducation Universitaire"
label var am_subCMU	"Assurance CMU"
label var subsidy_total	"Subventions"
label var subsidy_elec	"Subv. Électricité"
label var subsidy_elec_direct	"Effet Direct Élec."
label var subsidy_elec_indirect	"Effet Indirect Élec."
label var subsidy_fuel	"Subv. Carburants"
label var subsidy_fuel_direct	"Effet Direct Carb."
label var subsidy_fuel_indirect	"Effet Indirect Carb."
label var subsidy_eau	"Subv. Eau"
label var subsidy_eau_direct	"Effet Direct Eau"
label var subsidy_eau_indirect	"Effet Indirect Eau"
label var subsidy_agric	"Subv. Agricole"
label var indtax_total	"Taxes Indirectes"
label var excise_taxes	"Droits d'Accise"
label var Tax_TVA "TVA"
label var TVA_direct	"Effet Direct TVA"
label var TVA_indirect	"Effet Indirect TVA"
label var inktransf_total	"Transferts en nature"
label var Sante_inKind	"Santé (en nature)"
label var education_inKind	"Éducation (en nature)"
label var am_CMU_progs	"Programmes CMU"
label var am_sesame	"Plan Sésame"
label var am_moin5	"Soins gratuits pour les enfants moins 5 ans"
label var am_cesarienne	"Cesarienne gratuite"


local policylist `Directaxes' income_tax_reduc dirtax_total `Contributions' sscontribs_total `DirectTransfers' dirtransf_total `subsidies' subsidy_elec subsidy_fuel subsidy_eau subsidy_total `Indtaxes' Tax_TVA indtax_total `InKindTransfers' am_CMU_progs inktransf_total

foreach var of local policylist{
	local labelle : variable label `var'
	label var `var'_pc "`labelle'"
}



save "$data_out/output.dta", replace

if $save_scenario == 1 {	
	save "$data_out/output_${scenario_name_save}.dta", replace
}









