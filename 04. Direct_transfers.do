/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico
* Date: June 2020
* Version: 1.0
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------

*set more off
*clear all

*global root = "C:\Users\wb521296\OneDrive - WBG\Desktop\Senegal\CEQ 2020"

Pendent: Find out why when uncomment
 merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$presim/07_dir_trans_PMT_educ_health.dta"
and comment the other merge does not work 


*********************************************************************************/

set seed 1234
use  "$presim/07_dir_trans_PMT.dta", clear // hh level dataset 1.7 mlln

/**********************************************************************************/
noi dis as result " 1. Programme National de Bourses de Sécurité Familiale         "
/**********************************************************************************/

qui {
	gen benefsdep_PNBSF=.
	gen montantdep_PNBSF=.

	levelsof departement, local(department)
	foreach var of local department { 
		replace benefsdep_PNBSF  = ${PNBSF_Beneficiaires`var'} if departement==`var'
		replace montantdep_PNBSF = ${PNBSF_montant`var'}       if departement==`var'
	}

	if ($pnbsf_PMT ==0) {  // Random targeting inside each department
		bysort departement (pmt_seed): gen potential_ben= sum(hhweight)
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
		drop Beneficiaires_i potential_ben numicum
			sum hhweight
			local potential = r(sum)
			sum beneficiaire_PNBSF [iw=hhweight]
			nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
			if `potential'<=`r(sum)'{
				nois dis as error "Check if assigning every potential beneficiary makes sense."
			}
	}
}


/**********************************************************************************/
noi dis as result " 2. Programme des Cantines Scolaires                            "
/**********************************************************************************/

qui {
	drop interview__key interview__id id_menage grappe vague
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

	levelsof region, local(region)
	foreach var of local region { 
		replace benefsreg_CS  = ${Cantine_Elevee`var'}  if region==`var'
		replace montantreg_CS = ${Cantine_montant`var'} if region==`var'
	}
	
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
noi dis as result " 3. Bourse de L'education superieur (Publique et Priveé)        "
/**********************************************************************************/

*------------------------------------------------
noi dis as result "     Publique "
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
noi dis as result "     Privée "
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


/**********************************************************************************/
noi dis as result " 4. Couverture Maladie Universelle                              "
/**********************************************************************************/

merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$presim/07_dir_trans_PMT_educ_health.dta"


merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s03_me_SEN2018.dta", nogen keepusing(s03q37) keep(1 3)
tab s03q37 [iw=hhweight]

*test seed define in educ are still working 
*gen cmu50_seed2=runiform()
*mdesc cmu50_seed2 cmu50_seed

*Now that 07_dir_trans_PMT_educ_health is able to merge, repeating the generation of all the formal/informal variables is not needed because it is done in pre-sim.

***Selecting beneficiaries

*gen aux2 = 1 if informalh==1 & beneficiaire_PNBSF==1 & s01q02==1 // at least one informal hh member| PNBSF beneficiarie || household head

*------------------------------------------------
noi dis as result "     CMU 50% gratuite"
/*Assign random benefits to informal households
  not beneficiaries from PNBSF
Notes: 
AG: I will simplify the calculation using the new algorithm, but 
I will not change the way that these variables were calculated before.
Nevertheless, we require further clarifications (who exactly is benefiting
from these programs, by how much, how do we define if the individual/the hh is
the beneficiary, has the CMU changed in the last years, do the macro data on 
health expenditure makes sense, what are the sources of the numbers we currently
have on the tool, etc.)
------------------------------------------------*/

qui {
	gen sample = (informalh==1 & beneficiaire_PNBSF!=1) // at least one hh member informal, do not receive PNBSF 
	bys hhid: egen cmu50_seedh = mean(cmu50_seed) //I do this because I want complete households
	gsort -sample cmu50_seedh hhid
	gen potential_ben = sum(hhweight) if sample==1
	gen _e1=abs(potential_ben-${CMU_b_CMU_parcial})
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
	gen benh_subCMU50 = (potential_ben<=Beneficiaires_i)
	bys hhid: egen ben_subCMU50h = mean(benh_subCMU50)
	replace ben_subCMU50h = round(ben_subCMU50h,1)
	gen am_subCMU50  = ${CMU_m_CMU_parcial}*ben_subCMU50h
	drop Beneficiaires_i potential_ben sample cmu50_seedh benh_subCMU50 numicum
		sum hhweight if informalh==1 & beneficiaire_PNBSF!=1
		local potential = r(sum)
		sum ben_subCMU50h [iw=hhweight]
		nois dis as text "Excel requested ${CMU_b_CMU_parcial} beneficiaries, and we assigned `r(sum)' of the potential `potential'"
		if `potential'<=`r(sum)'{
			nois dis as error "Check if assigning every potential beneficiary makes sense."
		}
		
	label var ben_subCMU50h "Hhs beneficiary of 50% CMU contributions"
}


*------------------------------------------------
noi dis as result "     Plan Sésame"
/*Plan Sésame " Sésame" offers to senegalese above 60 years old the right to free health care in the whole country 
*Household is beneficiary of CMU or from PNBSF, and older than 60 y/o

AG: Only beneficiaries of the CMU50%? Should not be all CMU beneficiaries???
------------------------------------------------*/

qui {
	gen sample = ((ben_subCMU50h==1 | beneficiaire_PNBSF==1) & age >= 60)
	gsort -sample pben_sesame_seed
	gen potential_ben = sum(hhweight) if sample==1
	gen _e1=abs(potential_ben-${CMU_b_Plan_Sesame})
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
	gen ben_sesame = (potential_ben<=Beneficiaires_i)
	gen am_sesame  = ${CMU_m_Plan_Sesame}*(potential_ben<=Beneficiaires_i)
	drop Beneficiaires_i potential_ben sample numicum
		sum hhweight if (ben_subCMU50h==1 | beneficiaire_PNBSF==1) & age >= 60
		local potential = r(sum)
		sum ben_sesame [iw=hhweight]
		nois dis as text "Excel requested ${CMU_b_Plan_Sesame} beneficiaries, and we assigned `r(sum)' of the potential `potential'"
		if `potential'<=`r(sum)'{
			nois dis as error "Check if assigning every potential beneficiary makes sense."
		}
}



*------------------------------------------------
noi dis as result "     Gratuité pour les moins de 5 ans"
/*Gratuité pour les moins de 5 ans free health care 
for children between 0 and 5 years old.

The health center is supposed to see the patient for free without any consultation fees
RANDOM 
AG: Same as before, shouldn't be all 0-5yo? Regardless of PNBSF/CMU50%/CMU100%??? 
------------------------------------------------*/

qui {
	gen sample = ((ben_subCMU50h==1 | beneficiaire_PNBSF==1) & age <= 5)
	gsort -sample pben_moins5_seed
	gen potential_ben = sum(hhweight) if sample==1
	gen _e1=abs(potential_ben-${CMU_b_Soins_gratuit_enfants})
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
	gen ben_moins5 = (potential_ben<=Beneficiaires_i)
	gen am_moin5  = ${CMU_m_Soins_gratuit_enfants}*(potential_ben<=Beneficiaires_i)
	drop Beneficiaires_i potential_ben sample numicum
		sum hhweight if (ben_subCMU50h==1 | beneficiaire_PNBSF==1) & age <= 5
		local potential = r(sum)
		sum ben_moins5 [iw=hhweight]
		nois dis as text "Excel requested ${CMU_b_Soins_gratuit_enfants} beneficiaries, and we assigned `r(sum)' of the potential `potential'"
		if `potential'<=`r(sum)'{
			nois dis as error "Check if assigning every potential beneficiary makes sense."
		}
}


*------------------------------------------------
noi dis as result "     Gratuité de la césarienne"
/*Gratuité de la césarienne This programme covers the fees of all 
deliveries in clinics and health centres and C-sections in 
regional and district hospitals for all women

RANDOM 
AG: Same as before, shouldn't be regardless of PNBSF/CMU50%/CMU100%??? 
------------------------------------------------*/


gen child = 1 if s01q02==3 & age<=1 
bys hhid: egen hh_child= max(child)
gen pben_cesarienne_old=1 if (ben_subCMU50h==1  | beneficiaire_PNBSF==1) & hh_child==1 & s01q01==2 & (s01q02==1 | s01q02==2) & age<=40 // (DV it should be excluded gender in case mother died or mother is the household head)

*AG Issue: What happens if the mother is not household head or spouse? There is another way:
gen mom_in_hh = (s01q29==1 & age<=1)
gen momcode = s01q30 if mom_in_hh
sort hhid momcode, stable
by hhid : replace momcode="" if _n>1 & momcode==momcode[_n-1]
by hhid : gen allmomcodes = momcode[1]
by hhid : replace allmomcodes = allmomcodes[_n-1] + " " + momcode if _n>1
by hhid : replace allmomcodes = allmomcodes[_N]
split allmomcodes, gen(mc)
gen pben_cesarienne=0
foreach var of varlist mc*{
	destring `var', replace
	replace pben_cesarienne=1 if s01q00a==`var'
}
assert s01q01==2 if pben_cesarienne==1 //Assert that all the potential beneficiaries are women
replace pben_cesarienne = 0 if !(ben_subCMU50h==1  | beneficiaire_PNBSF==1)
tab pben_cesarienne pben_cesarienne_old [iw=hhweight] , mis //The new definition includes 198K recently pregnant women that are not heads/spouses and excludes 21K women that maybe are not mothers but step-mothers

drop mom_in_hh momcode allmomcodes mc* pben_cesarienne_old child hh_child

qui {
	gsort -pben_cesarienne cesarienne_seed
	gen potential_ben = sum(hhweight) if pben_cesarienne==1
	gen _e1=abs(potential_ben-${CMU_b_Cesariennes})
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
	gen ben_cesarienne = (potential_ben<=Beneficiaires_i)
	gen am_cesarienne  = ${CMU_m_Cesariennes}*(potential_ben<=Beneficiaires_i)
	drop Beneficiaires_i potential_ben numicum
		sum hhweight if pben_cesarienne==1
		local potential = r(sum)
		sum ben_cesarienne [iw=hhweight]
		nois dis as text "Excel requested ${CMU_b_Cesariennes} beneficiaries, and we assigned `r(sum)' of the potential `potential'"
		if `potential'<=`r(sum)'{
			nois dis as error "Check if assigning every potential beneficiary makes sense."
		}
}

*------------------------------------------------
noi dis as result "     CMU 100% gratuite"
/*	CMU 
	Subvention 100%
	RANDOM 
------------------------------------------------*/


gen ben_CMU100i = 1 if (ben_cesarienne==1 | ben_sesame ==1) & beneficiaire_PNBSF==1 & ben_subCMU50h!=1
bys hhid: egen pben_CMU100h = max(ben_CMU100i)

* AG: In the original code, the first ones to be eligible to receive this program are 
* households in PNBSF that are not pben_CMU100h, i.e., households with at least one
* person benefiting from cesarienne or sesame and that are not in CMU50%.

* AG: If I understand correctly, there should be 2 million people in CMU100%. We assign first to those PNBSF 
* beneficiaries that are not in CMU50% that have received cesarienne or sesame. Those are 93K people.
* Therefore, all of them are in CMU100% and there are 1'907K remaining. Those ones are the ones that
* we seek in the following algorithm, restricting to those in PNBSF and that do not belong to a household
* with an already benefiting person. I do not understand a) why the first set has to be restricted to people
* with cesarienne or sesame, and b) why the second set should exclude those in households with someone
* already benefiting. The consequence of this is that when we aggregate the variable to the household level,
* the relatives of the first set count as beneficiaries as well and then the number of benefiting individuals
* is larger than 2 million. The procedures for set 1 and set 2 are not consistent.

tab ben_CMU100i pben_CMU100h [iw=hhweight], mis //93K beneficiaries and 1'327 relatives. 
*The original global "faltantes" = $CMU_b_CMU_total - `ben_CMU100i' yields 1'907K people. But I think it should be:

sum pben_CMU100h [iw=hhweight]
local already_in = r(sum)
global remaining = $CMU_b_CMU_total - `already_in'

qui {
	gen sample = (beneficiaire_PNBSF==1 & pben_CMU100h!=1)
	bys hhid: egen cmu100_seedh = mean(cmu100_seed) //I do this because I want complete households
	gsort -sample cmu100_seedh hhid
	gen potential_ben = sum(hhweight) if sample==1
	gen _e1=abs(potential_ben-${remaining})
	egen _e=min(_e1)
	gen _icum=potential_ben if _e==_e1
		gen numicum = (_icum!=.)
		bysort numicum (_icum): gen rep = _n
		replace _icum = . if rep>1
	sort _icum, stable
	egen Beneficiaires_i=total(_icum)
	egen _icum2_sd=sd(_icum)
	assert _icum2_sd==.
	drop _icum2_sd _icum _e _e1 numicum
	gen benh_subCMU100 = (potential_ben<=Beneficiaires_i)
	bys hhid: egen ben_subCMU100h = mean(benh_subCMU100)
	replace ben_subCMU100h = round(ben_subCMU100h,1)
	replace ben_subCMU100h = pben_CMU100h if pben_CMU100h==1 & ben_subCMU100h==0       //Integrating the first set of beneficiaries into the second 
	gen am_subCMU100  = ${CMU_m_CMU_total}*ben_subCMU100h
	drop Beneficiaires_i potential_ben sample cmu100_seedh benh_subCMU100
		sum hhweight if (beneficiaire_PNBSF==1 & pben_CMU100h!=1) | (pben_CMU100h==1)  //Set 2 or Set 1
		local potential = r(sum)
		sum ben_subCMU100h [iw=hhweight]
		nois dis as text "Excel requested ${CMU_b_CMU_total} beneficiaries, and we assigned " `r(sum)' " of the potential " `potential'
		if `potential'<=`r(sum)'{
			nois dis as error "Check if assigning every potential beneficiary makes sense."
		}
	label var ben_subCMU100h "Hhs beneficiary of 100% CMU contributions"
}

/* Leaving the old code for reference
preserve
	keep if beneficiaire_PNBSF==1 & pben_CMU100h!=1 & s01q02==1
	
	ren cmu100_seed random
	*gen random=runiform()
	sort random
	gen count_id=_n

	levelsof count_id, local(households)

	gen count_CMU_100=.
	gen pondera=hhweight*hhsize

	tempfile auxiliar_CMU_100
	
	foreach z of local households{
		replace count_CMU_100=pondera if count_id==1
		replace count_CMU_100= count_CMU_100[`=`z'-1']+pondera[`z'] if count_id==`z'
	}

	save `auxiliar_CMU_100'
restore

merge n:1 interview__key interview__id id_menage grappe vague  using `auxiliar_CMU_100' , nogen keepusing(count_CMU_100)
 
 
sum ben_CMU100i [iw=hhweight] if (ben_cesarienne==1 | ben_sesame ==1) & beneficiaire_PNBSF==1 & ben_subCMU50h!=1
local ben_CMU100i = `r(sum)' // population that is eligible for ben_CMU100i
global faltantes= $CMU_b_CMU_total - `ben_CMU100i'  // difference between total beneficiaries 

gen ben_CMU100i_2=1 if count_CMU_100 <=$faltantes
gen total_ben_CMU100i=ben_CMU100i
replace total_ben_CMU100i=ben_CMU100i_2 if total_ben_CMU100i!=1 // add new beneficiaries ben_CMU100i_2 to old beneficiaries

bys hhid: egen ben_CMU100h = max(total_ben_CMU100i)
label var ben_CMU100h "Hhs beneficiary of 100% CMU contributions" 
tab ben_CMU100h total_ben_CMU100i [iw=hhweight], mis
dis "There are 2,003,351 CMU benefs, and 1,327,285 relatives of them. (after reform)"
dis "There are 1,542,399 CMU benefs, and 1,276,691 relatives of them. (before reform)"
tab ben_CMU100h beneficiaire_PNBSF [iw=hhweight], mis
gen hhwhhw=hhweight/hhsize
tab ben_CMU100h beneficiaire_PNBSF [iw=hhwhhw], mis col
*/

/*------------------------------------------------
***Amount of CMU100 and CMU50 combined 
------------------------------------------------*/

gen       ben_subCMUh =  0
replace   ben_subCMUh =  1 if (ben_subCMU50h==1 | ben_subCMU100h==1)
label var ben_subCMUh "Hhs beneficiary of CMU contributions subsidy"

gen     am_subCMU    = 0
replace am_subCMU = am_subCMU100 if am_subCMU100!=0
replace am_subCMU = am_subCMU50  if am_subCMU50!=0

****generates variables per household 
****Remember that PNBSF and CMU were calculated at the household level,
****but the other ones are at the individual level

egen am_CMU = rowtotal(am_sesame am_moin5 am_cesarienne)

collapse (mean) am_BNSF am_subCMU am_subCMU100 am_subCMU50 ///
		 (sum)  am_CMU am_sesame am_moin5 am_cesarienne am_Cantine am_bourse, by(hhid)

label var am_CMU "Sesame + moins5 + cesarienne"
label var am_subCMU "Couverture Maladie Universelle 50% + 100%"

*noi dis as error "I know this is not a direct transfer but a SS contribution, but the easiest option for now is to create it here"
*noi dis as error "We are also, from now on, considering Sésame, césarienne, and moins 5 ans as in kind transfers, although they are created here"
noi gen csh_mutsan = (am_subCMU!=0)*7000
noi label var csh_mutsan "Contrib. Health independent & poor"

replace csh_mutsan=0 //This means that independent/poor households that receive free healthcare from mutuelles de santé do not pay for their affiliation, but benefit from this subsidy (in other words, they receive a net benefit from having to pay 0).

//am_BNSF am_subCMU am_subCMU100 am_subCMU50
//am_CMU am_sesame am_moin5 am_cesarienne am_Cantine am_bourse

*AG:I know they are only a few, but shouldn't we include free dialyses?

 
if $devmode== 1 {
    save "$tempsim/Direct_transfers.dta", replace
}

tempfile Direct_transfers
save `Direct_transfers'



