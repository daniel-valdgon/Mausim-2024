
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ for The Gambia, Senegal and Mauritania
* Editted by: Madi Mangan
* Date: April 2024
* Version: 1.0
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------

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

