*--------------------------------------------------------------------------------
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


********************************************************************************

global dataout = "$root/SENEGAL_ECVHM_final/Dataout"
global datain  = "$root/SENEGAL_ECVHM_final/Datain"

tempfile section0
tempfile section1
tempfile section11
tempfile section12
tempfile section17

**********************************************************************

/* Proxy mean Test Score */

preserve
use "$datain/s01_me_SEN2018.dta", clear

gen age=2018-s01q03c

gen majeur_60=1 if age>59
recode majeur_60 .=0

gen jeune_15=1 if age<16
recode jeune_15 .=0

collapse (sum) majeur_60 jeune_15, by(hhid)

save `section1' 
restore

preserve
use "$datain/s11_me_SEN2018.dta", clear

gen eau_potable=1 if s11q22==1
recode eau_potable .=0

gen assainissement=s11q58
replace assainissement=8 if s11q58==.


gen revetement_sol=1 if s11q21==1
replace revetement_sol=2 if s11q21==2
replace revetement_sol=3 if s11q21==3
replace revetement_sol=4 if s11q21==4
replace revetement_sol=5 if s11q21==5

gen eau_potable1= s11q27a 
gen eau_potable2= s11q27b

gen eclairage = s11q38

gen revetement_mur = s11q19

gen toilette=1 if inlist(s11q55,1,2,3,4)
replace toilette=2 if inlist(s11q55,5,6,7,8)
replace toilette=3 if inlist(s11q55,9)
replace toilette=4 if inlist(s11q55,10)
replace toilette=5 if inlist(s11q55,11)
replace toilette=6 if inlist(s11q55,12)

gen nombre_pieces=s11q02

collapse (mean) eau_potable assainissement revetement_sol eau_potable1 eau_potable2 eclairage revetement_mur toilette nombre_pieces  , by(hhid)

save `section11' 
restore

preserve
use "$dataout/ehcvm_conso_SEN2018_menage.dta", clear

collapse (mean) hhsize , by(hhid)

save `section0'
restore

preserve
use "$datain/s12_me_SEN2018.dta", clear

keep if inlist(s12q01,29,28,19,18,20,35,34,40,37,16,17)

recode s12q02 2=0

collapse (sum) s12q02  , by(hhid)

gen nombre_assets=s12q02

save `section12'
restore


preserve
use "$datain/s17_me_SEN2018.dta", clear

keep if inlist(s17q02,2,3,7,9,10,11)

recode s17q03 2=0
gen appartient_menage=s17q06*s17q03


collapse (sum) appartient_menage  , by(hhid)

gen possesions_bien_essentiels=1 if appartient_menage>0
recode possesions_bien_essentiels .=0

save `section17'
restore

use "$dataout/ehcvm_conso_SEN2018_menage.dta", clear
merge 1:1 hhid using `section0', nogen
merge 1:1 hhid using `section1', nogen
merge 1:1 hhid using `section11', nogen
merge 1:1 hhid using `section12', nogen
merge 1:1 hhid using `section17', nogen


gen log_cons_pc= log(dtot/hhsize)
gen piece_pc=nombre_pieces/hhsize

reg log_cons_pc majeur_60 jeune_15 eau_potable assainissement revetement_sol ///
	eau_potable1 eau_potable2 eclairage revetement_mur toilette piece_pc ///
	nombre_assets possesions_bien_essentiels

predict xb
	
rename xb PMT


**********************************************************************************
*              Programme National de Bourses de Sécurité Familiale               *
**********************************************************************************

merge 1:1 hhid using "$datain/s00_me_SEN2018.dta", nogen

gen departement=s00q02

levelsof departement, local(department)

foreach var of local department{ 
	preserve
	keep if departement==`var'
	sort PMT
	gen count_id=_n

	levelsof count_id, local(gente)

	gen count_PBSF_`var'=.

	set seed 12345

	tempfile auxiliar_PNBSF_`var'

	foreach z of local gente{
		replace count_PBSF_`var'=hhweight if count_id==1
		replace count_PBSF_`var'= count_PBSF_`var'[`=`z'-1']+hhweight[`z'] if count_id==`z'
	}

save `auxiliar_PNBSF_`var''
restore
}

preserve
clear 
foreach var of local department{ 
	append using `auxiliar_PNBSF_`var''
	}

tempfile auxiliar_PNBSF
save `auxiliar_PNBSF'	
	
*save "$dta/auxiliar_PNBSF.dta", replace
restore

*merge 1:1 hhid using "$dta/auxiliar_PNBSF.dta", nogen keepusing(count_PBSF*)

merge 1:1 hhid using `auxiliar_PNBSF' , nogen keepusing(count_PBSF*)

gen beneficiaire_PNBSF=.
gen am_BNSF=.

levelsof departement, local(department)

foreach var of local department{ 
	replace beneficiaire_PNBSF=1 if count_PBSF_`var'<= ${PNBSF_Beneficiaires`var'} & departement==`var'
	replace am_BNSF= ${PNBSF_montant`var'} if beneficiaire_PNBSF==1 & departement==`var'
} 



**********************************************************************************
*                      Programme des Cantines Scolaires                          *
**********************************************************************************

merge 1:n hhid using "$datain/s02_me_SEN2018.dta", nogen 
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$datain/s01_me_SEN2018.dta", nogen keepusing(s01q03c )

gen age=2018-s01q03c 

**** Identify students by level
*C8 attend or not during 2010/2011
gen attend = 1 if  s02q12==1 // attend school during 2010-2011
gen pub_school=1 if  inlist(s02q09,1,5,6) // Public Francais and communautaire
gen pri_school=1 if  inlist(s02q09,2,3,4)  // Public Francais and communautaire

**Public
gen     ben_pre_school= 0
replace ben_pre_school= 1 if s02q14==1  & attend==1 & pub_school==1
***private
gen     ben_pre_school_pri= 0
replace ben_pre_school_pri= 1 if s02q14==1  & attend==1 & pri_school==1
**Public
gen ben_primary=0
replace ben_primary= 1 if s02q14==2 & attend==1 & pub_school==1  // CI, CP, CE1, CE2, CM1, CM2
replace ben_pre_school =1 if ben_primary==1 & age<=3 
replace ben_primary= 0 if ben_primary==1 & age<=3 

***private
gen ben_primary_pri=0
replace ben_primary_pri= 1 if s02q14==2 & attend==1 & pri_school==1  // CI, CP, CE1, CE2, CM1, CM2
replace ben_pre_school_pri =1 if ben_primary_pri==1 & age<=3 
replace ben_primary_pri= 0 if ben_primary_pri==1 & age<=3 


**Public
gen ben_secondary_low=0
replace ben_secondary_low=1 if s02q14==3 & attend==1 & pub_school==1  // 6ème 5ème 4ème 3ème
replace ben_secondary_low=1 if s02q14==4 & attend==1 & pub_school==1  // 6ème 5ème 4ème 3ème

gen     ben_secondary_low_pri=0
replace ben_secondary_low_pri=1 if s02q14==3 & attend==1 & pri_school==1  // 6ème 5ème 4ème 3ème
replace ben_secondary_low_pri=1 if s02q14==4 & attend==1 & pri_school==1  // 6ème 5ème 4ème 3ème

**Public
gen ben_secondary_up=0
replace ben_secondary_up=1 if  s02q14==5 & attend==1 & pub_school==1  // 2nde 1ère Terminale
replace ben_secondary_up=1 if  s02q14==6 & attend==1 & pub_school==1  // 2nde 1ère Terminale

***private
gen ben_secondary_up_pri=0
replace ben_secondary_up_pri=1 if s02q14==5 & attend==1 & pri_school==1  // 2nde 1ère Terminale
replace ben_secondary_up_pri=1 if s02q14==6 & attend==1 & pri_school==1  // 2nde 1ère Terminale

**Public
gen     ben_secondary = 1 if (ben_secondary_low==1 | ben_secondary_up==1) & pub_school==1 
replace ben_primary   = 1 if  ben_secondary==1 & age<=9
replace ben_secondary = 0 if  ben_secondary==1 & age<=9
***private
gen     ben_secondary_pri = 1 if (ben_secondary_low_pri==1 | ben_secondary_up_pri==1) & pri_school==1
replace ben_primary_pri   = 1 if  ben_secondary_pri==1 & age<=9
replace ben_secondary_pri = 0 if  ben_secondary_pri==1 & age<=9

**Public
gen     ben_tertiary=0
replace ben_tertiary=1 if s02q14==7 & attend==1 & pub_school==1 // Supérieur 1è to 6 et+
replace ben_tertiary=1 if s02q14==8 & attend==1 & pub_school==1 // Supérieur 1è to 6 et+

***private
gen     ben_tertiary_pri=0
replace ben_tertiary_pri=1 if s02q14==7 & attend==1 & pri_school==1 // Supérieur 1è to 6 et+
replace ben_tertiary_pri=1 if s02q14==8 & attend==1 & pri_school==1 // Supérieur 1è to 6 et+

gen ed_level = . 
replace ed_level= 1 if ben_pre_school==1
replace ed_level= 2 if ben_primary==1
replace ed_level= 3 if ben_secondary==1
replace ed_level= 4 if ben_tertiary==1

label define educlevel 1 "Pre-school" 2 "Primary" 3 "Secondary" 4 "Terciary"

gen ed_level_pri = . 
replace ed_level_pri= 1 if ben_pre_school_pri==1
replace ed_level_pri= 2 if ben_primary_pri==1
replace ed_level_pri= 3 if ben_secondary_pri==1
replace ed_level_pri= 4 if ben_tertiary_pri==1

gen preandpri=(ben_pre_school== 1 | ben_primary==1)

levelsof region, local(region)

foreach var of local region{ 
	preserve
	keep if preandpri==1
	keep if region==`var'
	gen rannum= uniform()
	sort rannum
	gen count_id=_n

	levelsof count_id, local(gente)

	gen count_Cantine_`var'=.

	set seed 12345

	tempfile auxiliar_Cantine_`var'

	foreach z of local gente{
		replace count_Cantine_`var'=hhweight if count_id==1
		replace count_Cantine_`var'= count_Cantine_`var'[`=`z'-1']+hhweight[`z'] if count_id==`z'
	}

save `auxiliar_Cantine_`var''
restore
}


preserve
clear 
foreach var of local region{ 
	append using `auxiliar_Cantine_`var''
	}
	
*save "$dta/auxiliar_cantine.dta", replace

tempfile auxiliar_cantine
save `auxiliar_cantine'
restore

*merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$dta/auxiliar_cantine.dta", nogen keepusing(count_Cantine*)

merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using `auxiliar_cantine' , nogen keepusing(count_Cantine*)


gen beneficiaire_Cantine=.
gen am_Cantine=.

levelsof region, local(region)

foreach var of local region{ 
	replace beneficiaire_Cantine=1 if count_Cantine_`var'<= ${Cantine_Elevee`var'} & region==`var'
	replace am_Cantine= ${Cantine_montant`var'} if beneficiaire_Cantine==1 & region==`var'
} 


dis("${Cantine_montant1}")


tempfile auxiliar_cantine_II

save `auxiliar_cantine_II'

*save "$dta/auxiliar_cantine.dta", replace

**********************************************************************************
*                      Bourse de L'education superieur                           *
**********************************************************************************

preserve
	keep if ben_tertiary==1
	gen rannum= uniform()
	sort rannum
	gen count_id=_n

	levelsof count_id, local(gente)

	gen count_bourse_public=.

	set seed 12345

	tempfile auxiliar_bourse_public

	foreach z of local gente{
		replace count_bourse_public=hhweight if count_id==1
		replace count_bourse_public= count_bourse_public[`=`z'-1']+hhweight[`z'] if count_id==`z'
	}

save `auxiliar_bourse_public'
restore


preserve
	keep if ben_tertiary_pri==1
	gen rannum= uniform()
	sort rannum
	gen count_id=_n

	levelsof count_id, local(gente)

	gen count_bourse_privee=.

	set seed 12345

	tempfile auxiliar_bourse_privee

	foreach z of local gente{
		replace count_bourse_privee=hhweight if count_id==1
		replace count_bourse_privee= count_bourse_privee[`=`z'-1']+hhweight[`z'] if count_id==`z'
	}

save `auxiliar_bourse_privee'
restore


merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using `auxiliar_bourse_public' , nogen keepusing(count_bourse_public)
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using `auxiliar_bourse_privee' , nogen keepusing(count_bourse_privee)

gen beneficiaire_bourse=.
gen am_bourse=.

replace beneficiaire_bourse=1 if count_bourse_public<= ${Bourse_BeneficiairePublic} & ben_tertiary==1 
replace am_bourse= ${Bourse_montantPublic} if beneficiaire_bourse==1 & ben_tertiary==1 
replace beneficiaire_bourse=1 if count_bourse_privee<= ${Bourse_BeneficiairePrivee} & ben_tertiary_pri==1 
replace am_bourse= ${Bourse_montantPrivee} if beneficiaire_bourse==1 & ben_tertiary_pri==1 




**********************************************************************************
*                                  CMU                                           *
**********************************************************************************

/*
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$datain/s04_me_SEN2018.dta", gen(merged4)



gen double formal=1 if s10q31==1
replace formal=1 if s10q32==1
replace formal=1 if s10q30==1

egen formal_definitivo=rowtotal(formal)
replace formal_definitivo=1 if formal_definitivo!=0

gen informal = .
replace informal = 1 if formal_definitivo==0 & s04aq10==1
  
gen formality = . 
replace formality = 1 if formal==1
replace formality = 0 if informal==1 
  
bys hhid: egen informalh=max(informal)
 
***Selecting beneficiaries

gen aux2 = 1 if informalh==1 & beneficiaire_PNBSF==1 & s01_q2==1
set seed 264595 


stop
 ***Partial subvention
  gen ben_CMU50h=(uniform()<=prop2) if  informalh==1  & ben_BNSFh!=1 & b1==1
  label var ben_CMU50h "Hhs beneficiary of 50% CMU contributions" 
 
  bys hhid: egen aux = max(ben_CMU50h)
  replace ben_CMU50h = aux
  drop aux
  tabstat ben_CMU50h if b1==1 [w=hhweight], stat(sum) format(%14.0f)

save `data', replace

*Plan Sésame " Sésame" offers to senegalese above 60 years old the right to free health care in the whole country 
***************Expenditure 2015 1277074230
***************Number of beneficiaries 215000 (2014) according 94161 (2015)
***************711361 census 2013
**************+number older than 60 survey 884744
gen pben_sesame = 1 if (ben_CMU50h==1  | ben_BNSFh==1) & b3 >= 60

gen p=1
set seed 480000
sum pben_sesame [w=hhweight] if  pben_sesame==1
gen     ben_sesame=(uniform()<=94161/ `r(sum_w)') if  pben_sesame==1
gen     am_sesame =  1130*`adj_prices' if ben_sesame==1
gen     am_sesame12=am_sesame*12
replace am_sesame =am_sesame*`sc_health'
tabstat ben_sesame am_sesame12 [w=hhweight], stat(sum) format(%14.0f)
*informal and older than 60 years old 


*Gratuité pour les moins de 5 ans free health care for children between 0 and 5 years old. The health center is supposed to see the patient for free without any consultation fees
***************Expenditure 2976000000
***************Number of beneficiaries 2016765 (2015)
*************** 2.2 milliones 
gen ben_moins5 = 1 if (ben_CMU50h==1  | ben_BNSFh==1) & b3 <= 5
sum ben_moins5 [w=hhweight]
gen asign_ben_moins5=`r(sum_w)'

* 691166 assigned. 1325599 Left 
bys hhid: egen hh_informal = max(informal)


*set seed 750000
 set seed 48
sum p [w=hhweight] if  hh_informal==1 &  b3 <= 5 & ben_moins5!=1
gen ben_moins5b=(uniform() <= (2016765- asign_ben_moins5)/`r(sum_w)') if  hh_informal==1 &  b3 <= 5 & ben_moins5!=1
tab ben_moins5b [w=hhweight]
replace ben_moins5=1 if ben_moins5b==1 
drop ben_moins5b
tabstat ben_moins5 [w=hhweight], stat(sum) format(%14.0f)
gen am_moins5 = 123*`adj_prices' if ben_moins5==1
replace am_moins5 =am_moins5*`sc_health'
*Gratuité de la césarienne This programme covers the fees of all deliveries in clinics and health centres and C-sections in regional and district hospitals for all women
***************Expenditure 968745000
***************Number of beneficiaries 17961 (2015)

gen prop5= 17961/28442



gen child = 1 if b1==3 & b3<1 
bys hhid: egen hh_child= max(child)
*set seed 700000
 set seed 50
 *17506 asignados
sum p [w=hhweight] if (ben_CMU50h==1  | ben_BNSFh==1) & hh_child==1 & b2==2 & (b1==1 | b1==2) & b3<=40
gen ben_cesarienne=(uniform()<=(17961/`r(sum_w)')) if (ben_CMU50h==1  | ben_BNSFh==1) & hh_child==1 & b2==2 & (b1==1 | b1==2) & b3<=40
gen am_cesarienne = 4495*`adj_prices' if ben_cesarienne==1
replace am_cesarienne =am_cesarienne*`sc_health'
tabstat ben_cesarienne [w=hhweight], stat(sum) format(%14.0f)

***Subvention 
    
   gen pben_CMU100i = 1 if (ben_cesarienne==1 | ben_sesame ==1) & ben_BNSFh==1 & ben_CMU50h!=1
   bys hhid: egen pben_CMU100h = max(pben_CMU100i)
   sum pben_CMU100h [w=hhweigh] if b1==1
   *66785
   scalar prop6 = 49479/`r(sum_w)'
   di prop6
   
  *set seed 720000
   set seed 50
   *48646
   gen ben_CMU100h=(uniform()<=prop6) if pben_CMU100h==1 & b1==1
   bys hhid: egen ben_CMU100h2 = max(ben_CMU100h)
   replace ben_CMU100h = ben_CMU100h2 if ben_CMU100h2==1
   drop ben_CMU100h2
   tabstat ben_CMU100h if b1==1 [w=hhweight], stat(sum) format(%14.0f)
   
   gen     ben_CMUh =  .
   replace ben_CMUh =  1 if (ben_CMU50h==1 | ben_CMU100h==1)
   label var ben_CMUh "Hhs beneficiary of CMU contributions subsidy"
   
   gen am_subCMU100 = 7000*`adj_prices'/12 if ben_CMU100h==1  
   gen am_subCMU50  = 3500*`adj_prices'/12 if ben_CMU50h ==1  
  


   gen     am_subCMU    = 0
   replace am_subCMU = am_subCMU100 if am_subCMU100!=0 & am_subCMU100!=.
   replace am_subCMU = am_subCMU50  if am_subCMU50!=0 & am_subCMU50!=.

 label var ben_CMU100h "hhs-beneficiary of 100% CMU contributions" 



egen aux = total(hhweight) if ben_CMUh==1 
gen  am_otherCMU = 1294542501/aux/12 if ben_CMUh==1
drop aux
gen  ben_otherCMUh=1 if am_otherCMU!=. & am_otherCMU!=0

*bys  hhid: egen ben_otherCMUh = max(ben_otherCMU)
*drop ben_otherCMU

****generates variables per capita 

egen am_CMU = rowtotal(am_sesame am_cesarienne am_moins5 am_otherCMU)

*/

collapse (mean) am_BNSF (sum) am_Cantine am_bourse, by(hhid)

tempfile Direct_transfers
save `Direct_transfers'
*save "$dta/Direct_transfers.dta", replace


