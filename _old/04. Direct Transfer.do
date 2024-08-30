
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ for The Gambia, Senegal and Mauritania
* Editted by: Madi Mangan
* Date: April 2024
* Version: 1.0
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------

set seed 1234
use  "$presim/07_dir_trans_PMT.dta", clear 

keep hhid PMT* eleg* departement pmt_seed* hhweight hhsize

/**********************************************************************************/
*noi dis as result " 1. Tekavoul "
/**********************************************************************************/

*global prog_label "Tekavoul"
*global prog_n 1
*global eleg eleg_1
*global targ PMT_1
*global seed pmt_seed_1


forvalues i = 1/3 {
	
	noi di "Program number ${index_prog_`i'}, ${label_prog_`i'}"

	gen benefsdep =.
	gen montantdep =.
	merge m:1 departement using "$tempsim/departments`i'.dta", nogen
	replace benefsdep = Beneficiaires
	replace montantdep = Montant
	drop Beneficiaires Montant
	
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

	ren am am_${label_prog_`i'}
	ren beneficiaire beneficiaire_${label_prog_`i'}
	drop benefsdep montantdep
	
}

	
/**********************************************************************************/
noi dis as result " 2. Universal Basic Transfer to household member who are at least 18 "
/**********************************************************************************/


gen rev_universel = hhsize * $UBI_person  
nois dis as text "In Excel we request that each individual is given $" $UBI_person " as a UBI"
	
/**********************************************************************************/
noi dis as result " 3. School Feeding Programme "
/**********************************************************************************/

	local i = 4

	noi di "Program number ${index_prog_`i'}, ${label_prog_`i'}"

	merge 1:m hhid  using  "$presim/07_educ.dta", nogen // not matched ae
	
	gen benefsreg_CS=.
	gen montantreg_CS=.
	merge m:1 region using "$tempsim/cantine.dta", nogen //assert(matched)
	replace benefsreg_CS = nombre_elevees
	replace montantreg_CS = montant_cantine
	drop montant_cantine nombre_elevees
	
	gsort pmt_seed -preandpri
	bysort region (pmt_seed -preandpri): gen potential_ben= sum(hhweight) if preandpri==1
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
*}


/**********************************************************************************/
noi dis as result " 5. Transfer to students in public institution"
/**********************************************************************************/

gen rev_pubstu = 0 //prepri_sec * $transt_Pub_student

****generates variables per household 
****Remember that PNBSF and UBI are calculated at the household level,
****but the school lunches is at the individual level

collapse (mean) am_BNSF* am_elmaouna rev_universel (sum) am_Cantine rev_pubstu, by(hhid hhweight)

if $devmode== 1 {
    save "$tempsim/Direct_transfers.dta", replace
}

tempfile Direct_transfers
save `Direct_transfers'

