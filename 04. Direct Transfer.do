
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ for The Gambia, Senegal and Mauritania
* Editted by: Madi Mangan
* Date: April 2024
* Version: 1.0
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------

set seed 1234
use  "$presim/07_dir_trans_PMT.dta", clear 

keep hhid PMT* elmaouna departement pmt_seed hhweight hhsize milieu

/**********************************************************************************/
noi dis as result " 1. Programme National de Bourses de Sécurité Familiale "
/**********************************************************************************/

forvalues i = 1/2 {
	
	*local i = 1
	gen benefsdep_PNBSF`i' =.
	gen montantdep_PNBSF`i' =.
	merge m:1 departement using "$tempsim/departments`i'.dta", nogen
	replace benefsdep_PNBSF`i' = Beneficiaires
	replace montantdep_PNBSF`i' = Montant
	drop Beneficiaires Montant
	
	if ($pnbsf_PMT ==0) {  // Random targeting inside each department
	
		bysort departement (pmt_seed): gen potential_ben= sum(hhweight) // check this for  for soft coding. 
		gen _e1=abs(potential_ben-benefsdep_PNBSF`i')
		bysort departement: egen _e=min(_e1)
		gen _icum=potential_ben if _e==_e1
		
		gen numicum = (_icum!=.)
		bysort departement numicum (_icum): gen rep = _n
		replace _icum = . if rep>1
			
		bysort departement: egen Beneficiaires_i=total(_icum)
		bysort departement: egen _icum2_sd=sd(_icum)
		
		assert _icum2_sd==.
		sum benefsdep_PNBSF`i' if _icum!=.
		local realbenefs = r(sum)
			
		drop _icum2_sd _icum _e _e1 rep
		gen am_BNSF`i' = montantdep_PNBSF`i'*(potential_ben<=Beneficiaires_i)
		gen beneficiaire_PNBSF`i' = (potential_ben<=Beneficiaires_i)
		drop Beneficiaires_i potential_ben numicum
		sum hhweight
		local potential = r(sum)
		sum beneficiaire_PNBSF`i' [iw=hhweight]
		nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
		if `potential'<=`r(sum)'{
			nois dis as error "Check if assigning every potential beneficiary makes sense."
		}
	}	

	if ($pnbsf_PMT ==1) {  // PMT targeting inside each department
		
		bysort departement (PMT_`i' pmt_seed): gen potential_ben= sum(hhweight)
		gen _e1=abs(potential_ben-benefsdep_PNBSF`i')
		bysort departement: egen _e=min(_e1)
		gen _icum=potential_ben if _e==_e1
			gen numicum = (_icum!=.)
			bysort departement numicum (_icum): gen rep = _n
			replace _icum = . if rep>1
		bysort departement: egen Beneficiaires_i=total(_icum)
		bysort departement: egen _icum2_sd=sd(_icum)
		assert _icum2_sd==.
			sum benefsdep_PNBSF`i' if _icum!=.
			local realbenefs = r(sum)
		drop _icum2_sd _icum _e _e1 rep
		gen am_BNSF`i' = montantdep_PNBSF`i'*(potential_ben<=Beneficiaires_i)
		gen beneficiaire_PNBSF`i' = (potential_ben<=Beneficiaires_i)
		drop Beneficiaires_i potential_ben numicum
			sum hhweight
			local potential = r(sum)
			sum beneficiaire_PNBSF`i' [iw=hhweight]
			nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
			if `potential'<=`r(sum)'{
				nois dis as error "Check if assigning every potential beneficiary makes sense."
			}
	}
	
}	

/**********************************************************************************/
noi dis as result " 1. Elmaouna "
/**********************************************************************************/
	
	gen elegible = (elmaouna == 1 & beneficiaire_PNBSF2 == 0 & milieu == 2)
	
	gen benefsdep =.
	gen montantdep =.
	merge m:1 departement using "$tempsim/departments3.dta", nogen
	replace benefsdep = Beneficiaires
	replace montantdep = Montant
	drop Beneficiaires Montant
	
	if ($pnbsf_PMT ==0) {  // PMT targeting inside each department
		
		gsort pmt_seed -elegible
		bysort departement (pmt_seed -elegible): gen potential_ben= sum(hhweight) if elegible==1
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
		drop Beneficiaires_i potential_ben numicum
			sum hhweight if elegible==1
			local potential = r(sum)
			sum beneficiaire [iw=hhweight]
			nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
			if `potential'<=`r(sum)'{
				nois dis as error "Check if assigning every potential beneficiary makes sense."
			}
	}
	
	if ($pnbsf_PMT ==1) {  // PMT targeting inside each department
		
		gsort pmt_seed -elegible
		bysort departement (PMT_1 pmt_seed -elegible): gen potential_ben= sum(hhweight) if elegible==1
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
		drop Beneficiaires_i potential_ben numicum
			sum hhweight if elegible==1
			local potential = r(sum)
			sum beneficiaire [iw=hhweight]
			nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
			if `potential'<=`r(sum)'{
				nois dis as error "Check if assigning every potential beneficiary makes sense."
			}
	}

	ren am am_elmaouna
	ren beneficiaire beneficiaire_elmaouna	
	
/**********************************************************************************/
noi dis as result " 2. Universal Basic Transfer to household member who are at least 18 "
/**********************************************************************************/
	
	
gen rev_universel = hhsize * $UBI_person  
nois dis as text "In Excel we request that each individual is given $" $UBI_person " as a UBI"
	
	

/**********************************************************************************/
noi dis as result " 3. School Feeding Programme "
/**********************************************************************************/

qui {
	
	merge 1:m hhid  using  "$presim/07_educ.dta", nogen // not matched ae

	/*------------------------------------------------
	 Sorting beneficiaries within each region RANDOMLY

	Notes: 
	ben_pre_school==1 	attends pre-school, or primary & younger than 3,  and public
	ben_primary==1		attends primary public school 
	------------------------------------------------*/

	*gen preandpri=(ben_pre_school== 1 | ben_primary==1)

	gen preandpri=(ben_primary==1 & milieu == 2)
	
	gen benefsreg_CS=.
	gen montantreg_CS=.
	merge m:1 region using "$tempsim/cantine.dta", nogen //assert(matched)
	replace benefsreg_CS = nombre_elevees
	replace montantreg_CS = montant_cantine
	drop montant_cantine nombre_elevees
	
	
	gsort pmt_seed -preandpri
	bysort region (PMT_3 pmt_seed -preandpri): gen potential_ben= sum(hhweight) if preandpri==1
	gen _e1=abs(potential_ben-benefsreg_CS)
	bysort region: egen _e=min(_e1)
	gen _icum=potential_ben if _e==_e1
		gen numicum = (_icum!=.)
		bysort region numicum (_icum): gen rep = _n
		replace _icum = . if rep>1
	sort _icum, stable
	bysort region: egen Beneficiaires_i=total(_icum)
	bysort region: egen _icum2_sd=sd(_icum)
	assert _icum2_sd==.
		sum benefsreg_CS if _icum!=.
		local realbenefs = r(sum)
	drop _icum2_sd _icum _e _e1 rep
	gen am_Cantine = montantreg_CS*(potential_ben<=Beneficiaires_i)
	gen beneficiaire_Cantine = (potential_ben<=Beneficiaires_i)
	drop Beneficiaires_i potential_ben numicum
		sum hhweight if preandpri==1
		local potential = r(sum)
		sum beneficiaire_Cantine [iw=hhweight]
		nois dis as text "Excel requested `realbenefs' beneficiaries, and we assigned `r(sum)' of the potential `potential'"
		if `potential'<=`r(sum)'{
			nois dis as error "Check if assigning every potential beneficiary makes sense."
		}

	tempfile auxiliar_cantine_II
	save `auxiliar_cantine_II' // *save "$dta/auxiliar_cantine.dta", replace
}


/**********************************************************************************/
noi dis as result " 5. Transfer to students in public institution"
/**********************************************************************************/

gen rev_pubstu = 0 //prepri_sec * $transt_Pub_student

****generates variables per household 
****Remember that PNBSF and UBI are calculated at the household level,
****but the school lunches is at the individual level

collapse (mean) am_BNSF* am_elmaouna rev_universel (sum) am_Cantine rev_pubstu, by(hhid)

if $devmode== 1 {
    save "$tempsim/Direct_transfers.dta", replace
}

tempfile Direct_transfers
save `Direct_transfers'

*sum *
*tabstat am_BNSF1 am_BNSF2 rev_universel am_Cantine rev_pubstu [aw = hhweight], s(mean sum) by(milieu)

	
	
