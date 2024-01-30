*-----------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico
* Date: June 2020
* Version: 1.0

*Version 2: 
*Oct 2022: 
	
	// 1. Definition of beneficiaries as user of public hospitals in q07 and q23 omitted some public hospital categories for Q23: 4 Poste de santé, 5	Case de santé,  6	Autre public (y compris maternité rurale).
	
	// Note: 
		//  To be decided if use eligibility vs use approach. 
			// Eligibility approach needs adm data on coverage because coverage of CMU is relatively low  
			// Use approach does no capture household who did not suffer from illness during the period asked for the survey
*Version 3: 


*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------

/********** Education *******/


use "$presim/07_educ.dta", clear


gen am_pre_school_pub = ${Edu_montantPrescolaire}  if ben_pre_school==1   & pub_school==1
gen am_primary_pub    = ${Edu_montantPrimaire}     if ben_primary==1      & pub_school==1
gen am_secondary_pub  = ${Edu_montantSecondaire}   if ben_secondary==1    & pub_school==1
gen am_tertiary_pub   = ${Edu_montantSuperieur}    if ben_tertiary==1     & pub_school==1
 
collapse (sum)  am_pre_school_pub am_primary_pub am_secondary_pub am_tertiary_pub, by(hhid)
egen education_inKind=rowtotal(am_pre_school_pub am_primary_pub am_secondary_pub am_tertiary_pub)

tempfile Transfers_InKind_Education
save `Transfers_InKind_Education'

/********** Health *******/

use "$data_sn/s03_me_SEN2018.dta", clear
merge n:1 hhid  using "$data_sn/ehcvm_conso_SEN2018_menage.dta", gen(merged7) keepusing(hhweight) update

// Question: s03q07 Où [NOM] a-t-il été consulté la première fois pour cet épisode de maladie ? 
	// Precedent question: s03q05 [NOM] a t-il  été consulté dans un service  de santé (y compris pharmacie), ou un guérisseur traditionnel au cours des 30 derniers jours du fait de ce problème de santé ?

gen     hcare_level  = 1  if (s03q07==4 | s03q07==5  | s03q07==6)  // 1) Poste de santé 2) Case de santé 3) Autre public (y compris maternité rurale)

replace hcare_level  = 2  if (s03q07==1 | s03q07==2  | s03q07==3)  // 1) Hôpital national 2) Hôpital régional (y compris hôpital de police, militaire) 3) Centre de santé

 
gen consult_prim= hcare_level==1
gen consult_sec=  hcare_level==2

// Où [NOM] a-t-il été hospitalisé pour ce dernier problème de santé ?  [INS: Adaptez et gardez 6 niveaux publics]

gen hospita=1 if (s03q23==1 | s03q23==2  | s03q23==3) // 1) Hôpital national 2) Hôpital régional (y compris hôpital de police, militaire) 3) Centre de santé

gen     freq=0
bys id: egen consult_sec_hh=total(consult_sec)
bys id: egen hospita_hh=total(hospita)
bys id: egen consult_prim_hh=total(consult_prim)

*gen y = s03q12==1

gen publichealth=1 if (s03q07==1 | s03q07==2  | s03q07==3 | s03q07==4 | s03q07==5  | s03q07==6 | s03q23==1 | s03q23==2  | s03q23==3) // access to public health in general 
sum publichealth [iw=hhweight]
local sante_beneficiare `r(sum)' // dis "`sante_beneficiare'"

gen depense_person=$Montant_Assurance_maladie/`sante_beneficiare' 
gen am_sante=depense_person if publichealth==1

dis "$Montant_Assurance_maladie"
sum depense_person, d

collapse (sum) am_sante, by(hhid)
egen Sante_inKind=rowtotal(am_sante)
merge 1:1 hhid using `Transfers_InKind_Education', nogen


if $devmode== 1 {
    save "$tempsim/Transfers_InKind.dta", replace
}

tempfile Transfers_InKind
save `Transfers_InKind'


