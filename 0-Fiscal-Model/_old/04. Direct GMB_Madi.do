
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ for The Gambia, Senegal and Mauritania
* Editted by: Madi Mangan
* Date: April 2024
* Version: 1.0
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------



set seed 1234
use  "$presim/07_dir_trans_PMT.dta", clear 

/**********************************************************************************/
noi dis as result " 1. Programme National de Bourses de Sécurité Familiale "
/**********************************************************************************/

	gen benefsdep_PNBSF=.
	gen montantdep_PNBSF=.
	merge m:1 departement using "$tempsim/departments.dta", nogen
	replace benefsdep_PNBSF = Beneficiaires
	replace montantdep_PNBSF = Montant
	drop Beneficiaires Montant

	
	if ($pnbsf_PMT ==0) {  // Random targeting inside each department
		bysort departement (pmt_seed): gen potential_ben= sum(hhweight) // check this for  for soft coding. 
		gen _e1=abs(potential_ben-benefsdep_PNBSF)
		bysort departement: egen _e=min(_e1)
		gen _icum=potential_ben if _e==_e1
			gen numicum = (_icum!=.)
			bysort departement numicum (_icum): gen rep = _n
			replace _icum = . if rep>1
		bysort departement: egen Beneficiaires_i=total(_icum)
		bysort departement: egen _icum2_sd=sd(_icum)
		assert _icum2_sd==.
			sum benefsdep_PNBSF if _icum!=.
			local realbenefs = r(sum)
		drop _icum2_sd _icum _e _e1 rep
		gen am_BNSF = montantdep_PNBSF*(potential_ben<=Beneficiaires_i)
		gen beneficiaire_PNBSF = (potential_ben<=Beneficiaires_i)
                replace beneficiaire_PNBSF = 0 if benefsdep_PNBSF ==0                    // This is a temporal fix that we should look at later. 
		replace am_BNSF = 0 if benefsdep_PNBSF ==0
		drop Beneficiaires_i potential_ben numicum
			sum hhweight
			local potential = r(sum)
			sum beneficiaire_PNBSF [iw=hhweight]
			nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
			if `potential'<=`r(sum)'{
				nois dis as error "Check if assigning every potential beneficiary makes sense."
			}

	}

	if ($pnbsf_PMT ==1) {  // PMT targeting inside each department
		bysort departement (PMT pmt_seed): gen potential_ben= sum(hhweight)
		gen _e1=abs(potential_ben-benefsdep_PNBSF)
		bysort departement: egen _e=min(_e1)
		gen _icum=potential_ben if _e==_e1
			gen numicum = (_icum!=.)
			bysort departement numicum (_icum): gen rep = _n
			replace _icum = . if rep>1
		bysort departement: egen Beneficiaires_i=total(_icum)
		bysort departement: egen _icum2_sd=sd(_icum)
		assert _icum2_sd==.
			sum benefsdep_PNBSF if _icum!=.
			local realbenefs = r(sum)
		drop _icum2_sd _icum _e _e1 rep
		gen am_BNSF = montantdep_PNBSF*(potential_ben<=Beneficiaires_i)
		gen beneficiaire_PNBSF = (potential_ben<=Beneficiaires_i)
                replace beneficiaire_PNBSF = 0 if benefsdep_PNBSF ==0                    // This is a temporal fix that we should look at later. 
		replace am_BNSF = 0 if benefsdep_PNBSF ==0
		drop Beneficiaires_i potential_ben numicum
			sum hhweight
			local potential = r(sum)
			sum beneficiaire_PNBSF [iw=hhweight]
			nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
			if `potential'<=`r(sum)'{
				nois dis as error "Check if assigning every potential beneficiary makes sense."
			}
	}
	
	
/**********************************************************************************/
noi dis as result " 2. Universal Basic Transfer to household member who are at least 18 "
/**********************************************************************************/
	
	gen hhsize_18 = hhsiz // to run senegal 
gen rev_universel = hhsize_18*$UBI_person  
nois dis as text "In Excel we request that each individual is given $" $UBI_person " as a UBI"
	
	
	
/**********************************************************************************/
noi dis as result " 3. School Feeding Programme "
/**********************************************************************************/

qui {
	cap drop interview__key interview__id id_menage grappe vague
	merge 1:m hhid  using  "$presim/07_educ.dta", nogen // not matched ae

	/*------------------------------------------------
	 Sorting beneficiaries within each region RANDOMLY

	Notes: 
	ben_pre_school==1 	attends pre-school, or primary & younger than 3,  and public
	ben_primary==1		attends primary public school 
	------------------------------------------------*/

	gen preandpri=(ben_pre_school== 1 | ben_primary==1)

	gen benefsreg_CS=.
	gen montantreg_CS=.
	merge m:1 region using "$tempsim/cantine.dta", nogen assert(matched)
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
}


/**********************************************************************************/
noi dis as result " 5. Transfer to students in public institution"
/**********************************************************************************/
gen prepri_sec=(ben_pre_school== 1 | ben_primary==1 | ben_secondary == 1)
gen rev_pubstu = prepri_sec*$transt_Pub_student





/**********************************************************************************/
noi dis as result " 3. Scholarships for students in Tertiary institution  "
/**********************************************************************************/

*------------------------------------------------
noi dis as result "     Public "
/*
Notes: 
ben_tertiary==1 	attends public college
------------------------------------------------*/

qui {
	gsort -ben_tertiary ter_seed
	gen potential_ben = sum(hhweight) if ben_tertiary==1
	gen _e1=abs(potential_ben-${Bourse_BeneficiairePublic})
	egen _e=min(_e1)
	gen _icum=potential_ben if _e==_e1
		gen numicum = (_icum!=.)
		bysort numicum (_icum): gen rep = _n
		replace _icum = . if rep>1
	sort _icum, stable
	egen Beneficiaires_i=total(_icum)
	egen _icum2_sd=sd(_icum)
	assert _icum2_sd==.
	drop _icum2_sd _icum _e _e1 rep
	gen am_bourse_pub = ${Bourse_montantPublic}*(potential_ben<=Beneficiaires_i)
	gen beneficiaire_bourse_pub = (potential_ben<=Beneficiaires_i)
	drop Beneficiaires_i potential_ben numicum
		sum hhweight if ben_tertiary==1
		local potential = r(sum)
		sum beneficiaire_bourse_pub [iw=hhweight]
		nois dis as text "Excel requested ${Bourse_BeneficiairePublic} beneficiaries, and we assigned `r(sum)' of the potential `potential'"
		if `potential'<=`r(sum)'{
			nois dis as error "Check if assigning every potential beneficiary makes sense."
		}
}

*------------------------------------------------
noi dis as result "     Private "
/*
Notes: 
ben_tertiary_pri==1 	attends private college
------------------------------------------------*/

qui {
	gsort -ben_tertiary_pri ter2_seed
	gen potential_ben = sum(hhweight) if ben_tertiary_pri==1
	gen _e1=abs(potential_ben-${Bourse_BeneficiairePrivee})
	egen _e=min(_e1)
	gen _icum=potential_ben if _e==_e1
		gen numicum = (_icum!=.)
		bysort numicum (_icum): gen rep = _n
		replace _icum = . if rep>1
	sort _icum, stable
	egen Beneficiaires_i=total(_icum)
	egen _icum2_sd=sd(_icum)
	assert _icum2_sd==.
	drop _icum2_sd _icum _e _e1 rep
	gen am_bourse_pri = ${Bourse_montantPrivee}*(potential_ben<=Beneficiaires_i)
	gen beneficiaire_bourse_pri = (potential_ben<=Beneficiaires_i)
	drop Beneficiaires_i potential_ben numicum
		sum hhweight if ben_tertiary_pri==1
		local potential = r(sum)
		sum beneficiaire_bourse_pri [iw=hhweight]
		nois dis as text "Excel requested $Bourse_BeneficiairePrivee beneficiaries, and we assigned `r(sum)' of the potential `potential'"
		if `potential'<=`r(sum)'{
			nois dis as error "Check if assigning every potential beneficiary makes sense."
		}
	
	gen beneficiaire_bourse = beneficiaire_bourse_pub + beneficiaire_bourse_pri
	gen am_bourse = am_bourse_pub + am_bourse_pri
}




****generates variables per household 
****Remember that PNBSF and UBI are calculated at the household level,
****but the school lunches is at the individual level

collapse (mean) am_BNSF rev_universel (sum) am_Cantine rev_pubstu am_bourse, by(hhid)


if $devmode== 1 {
    save "$tempsim/Direct_transfers.dta", replace
}

tempfile Direct_transfers
save `Direct_transfers'


	
	
