/*============================================================================*\
 Direct Transfers simulation
 Authors: Gabriel Lombo
 Start Date: January 2024
 Update Date: April 2025
\*============================================================================*/
  
set seed 123456789

use  "$presim/07_dir_trans_PMT.dta", clear 

keep hhid PMT* eleg* departement pmt_seed* hhweight hhsize

*-------------------------------------
// Beneficiary Allocation: Tekavoul, Food Distribution, Shock Responsive
*-------------------------------------


global prog_hh 		""
global prog_indiv 	""

forvalues i = 1/3 {
	
	if "${pr_div_`i'}" == "departement" & "${pr_type_`i'}" == "hh" {
	
		noi di "Program number `i', ${pr_label_`i'}, assigning by ${pr_div_`i'}"

		gen benefsdep =.
		gen montantdep =.
		merge m:1 departement using "$tempsim/${pr_div_`i'}_`i'.dta", nogen
		replace benefsdep = beneficiaires
		replace montantdep = montant
		drop beneficiaires montant
		
		*----- Random
		if (${tar_PMT_`i'} == 0) {  
			
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
		
		*----- PMT
		if (${tar_PMT_`i'} == 1) {  
			
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
			*replace am = 0 if benefsdep ==0
			drop Beneficiaires_i potential_ben numicum
				sum hhweight if eleg_`i'==1
				local potential = r(sum)
				sum beneficiaire [iw=hhweight]
				nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
				if `potential'<=`r(sum)'{
					nois dis as error "Check if assigning every potential beneficiary makes sense."
				}
		}
				
	gen am_prog_`i' = am
	ren beneficiaire beneficiaire_prog_`i'
	drop benefsdep montantdep
	drop am
	
	global prog_hh $prog_hh am_prog_`i'

	
	}
}


*-------------------------------------
// School feeding program allocation
*-------------------------------------

merge 1:m hhid  using  "$presim/07_educ.dta", nogen keepusing(hhid pmt_seed_4 eleg_4) // not matched ae

*keep hhid hhweight departement PMT_4 eleg_4 pmt_seed_4	
	
forvalues i = 4/4 {
		
	if ("${pr_div_`i'}" == "departement" | "${pr_div_`i'}" == "region") & "${pr_type_`i'}" == "indiv" {
	
		local i = 4
		noi di "Program number `i', ${pr_label_`i'}, assigning by ${pr_div_`i'}"

		gen benefsdep =.
		gen montantdep =.		
		merge m:1 departement /*region*/ using "$tempsim/${pr_div_`i'}_`i'.dta", nogen
		replace benefsdep = beneficiaires
		replace montantdep = montant
		drop beneficiaires montant

	*----- Random	
	if (${tar_PMT_`i'} == 0) {
		
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

	*----- PMT	
	if (${tar_PMT_`i'} == 1) { 
		
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

	gen am_prog_`i' = am 
	ren beneficiaire beneficiaire_prog_`i'
	drop benefsdep montantdep
	
	global prog_indiv $prog_indiv am_prog_`i'
	
	}	
}	

*-------------------------------------
// Others
*-------------------------------------

gen rev_universel = 0 
gen rev_pubstu = 0 //prepri_sec * $transt_Pub_student

*-------------------------------------
// Data by household
*-------------------------------------


collapse (mean) $prog_hh rev_universel (sum) $prog_indiv, by(hhid)

if $devmode== 1 {
    save "$tempsim/Direct_transfers.dta", replace
}

tempfile Direct_transfers
save `Direct_transfers'


global prog_total $prog_hh $prog_indiv

