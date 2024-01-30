/*

Main changes with respect the past 

// DV: important!!!!!!!!! before was this combination of variables that did not match perfectly( key interview__key interview__id id_menage grappe vague) we replace them by hhid and it works now


*/

tempfile section0
tempfile section1
tempfile section11
tempfile section12
tempfile section17
set seed 123456789

**********************************************************************

/*=================================================
=================================================
		1. Proxy mean Test Score 
=================================================
=================================================*/

/*------------------------------------------------
 `section1' :demographics by household level 
------------------------------------------------*/
 
	preserve
	use "$data_sn/s01_me_SEN2018.dta", clear
	
	replace s01q03a=. if s01q03a==999 | s01q03a==9999
	replace s01q03b=. if s01q03b==999 | s01q03b==9999
	replace s01q03c=. if s01q03c==999 | s01q03c==9999
	gen date_survey_started = date(s00q23a,"YMD#hms")
	gen age = date_survey_started-mdy(s01q03b,s01q03a,s01q03c)
	replace age=floor(age/365.25)
	replace age= s01q04a if age==.
	replace age=2018-s01q03c if vague==1 & age==.
	replace age=2019-s01q03c if vague==2 & age==.

	gen majeur_60=1 if age>59
	recode majeur_60 .=0
	
	gen jeune_15=1 if age<16
	recode jeune_15 .=0
	
	collapse (sum) majeur_60 jeune_15, by(hhid)
	
	save `section1' 
	restore

/*------------------------------------------------
 `section11' : Access to utilities and housing
------------------------------------------------*/
	preserve
	use "$data_sn/s11_me_SEN2018.dta", clear
	
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

/*------------------------------------------------
 `section0' : household size
------------------------------------------------*/

	preserve
	use "$data_sn/ehcvm_conso_SEN2018_menage.dta", clear
	
	collapse (mean) hhsize , by(hhid)
	
	save `section0'
	restore

/*------------------------------------------------
 `section12' : nombre_assets 
------------------------------------------------*/
	
	preserve
	use "$data_sn/s12_me_SEN2018.dta", clear
	
	keep if inlist(s12q01,29,28,19,18,20,35,34,40,37,16,17)
	
	recode s12q02 2=0
	
	collapse (sum) s12q02  , by(hhid)
	
	gen nombre_assets=s12q02
	
	save `section12'
	restore

/*------------------------------------------------
 `section17' : possesions_bien_essentiels
------------------------------------------------*/

	preserve
	use "$data_sn/s17_me_SEN2018.dta", clear
	
	keep if inlist(s17q02,2,3,7,9,10,11)
	
	recode s17q03 2=0
	gen appartient_menage=s17q06*s17q03
	
	
	collapse (sum) appartient_menage  , by(hhid)
	
	gen possesions_bien_essentiels=1 if appartient_menage>0
	recode possesions_bien_essentiels .=0
	
	save `section17'
	restore

/*------------------------------------------------
 Merging all data
------------------------------------------------*/

use "$data_sn/ehcvm_conso_SEN2018_menage.dta", clear
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

/*------------------------------------------------
 Sorting individuals by within each department by PMT score
------------------------------------------------*/

merge 1:1 hhid using "$data_sn/s00_me_SEN2018.dta", nogen

gen departement=s00q02


*==================================================================================
dis "==============        Adding SEEDS!!!!!!!!!!!		==========="
*==================================================================================
*Note Seed were not working the sim do-file so they wil be generated here 
//set seed was defined above at the beggining of the do-file 
gen pmt_seed= uniform()


save "$presim/07_dir_trans_PMT.dta", replace

*==================================================================================
dis "==============         Defining benefits from education system		==========="
*==================================================================================

drop interview__key interview__id id_menage grappe vague
merge 1:n hhid using "$data_sn/s02_me_SEN2018.dta", nogen 
merge 1:1  hhid s01q00a using "$data_sn/s01_me_SEN2018.dta", nogen keepusing(s01q03a s01q03b s01q03c  s01q04a) // DV: important!!!!!!!!! before was this combination of variables that did not match perfectly( key interview__key interview__id id_menage grappe vague) we replace them by hhid and it works now

replace s01q03a=. if s01q03a==999 | s01q03a==9999
replace s01q03b=. if s01q03b==999 | s01q03b==9999
replace s01q03c=. if s01q03c==999 | s01q03c==9999
gen date_survey_started = date(s00q23a,"YMD#hms")
gen age = date_survey_started-mdy(s01q03b,s01q03a,s01q03c)
replace age=floor(age/365.25)
replace age= s01q04a if age==.
replace age=2018-s01q03c if vague==1 & age==.
replace age=2019-s01q03c if vague==2 & age==.

**** Identify students by level
*C8 attend or not during 2010/2011
gen attend = 1 if  s02q12==1 // attend school during 2010-2011
gen pub_school=1 if  inlist(s02q09,1,5,6) // Public Francais and communautaire
gen pri_school=1 if  inlist(s02q09,2,3,4)  // Public Francais and communautaire

*--------------Maternelle
**Public
gen     ben_pre_school= 0
replace ben_pre_school= 1 if s02q14==1  & attend==1 & pub_school==1
***Private
gen     ben_pre_school_pri= 0
replace ben_pre_school_pri= 1 if s02q14==1  & attend==1 & pri_school==1
*--------------Primaire
**Public
gen ben_primary=0
replace ben_primary= 1 if s02q14==2 & attend==1 & pub_school==1  // CI, CP, CE1, CE2, CM1, CM2
replace ben_pre_school =1 if ben_primary==1 & age<=3 
replace ben_primary= 0 if ben_primary==1 & age<=3 
**Private
gen ben_primary_pri=0
replace ben_primary_pri= 1 if s02q14==2 & attend==1 & pri_school==1  // CI, CP, CE1, CE2, CM1, CM2
replace ben_pre_school_pri =1 if ben_primary_pri==1 & age<=3 
replace ben_primary_pri= 0 if ben_primary_pri==1 & age<=3 
*--------------Secondaire 1 (Post Primaire) Général and Secondaire 1 (Post Primaire) Technique
**Public
gen ben_secondary_low=0
replace ben_secondary_low=1 if s02q14==3 & attend==1 & pub_school==1  // 6ème 5ème 4ème 3ème
replace ben_secondary_low=1 if s02q14==4 & attend==1 & pub_school==1  // 6ème 5ème 4ème 3ème
**Private
gen     ben_secondary_low_pri=0
replace ben_secondary_low_pri=1 if s02q14==3 & attend==1 & pri_school==1  // 6ème 5ème 4ème 3ème
replace ben_secondary_low_pri=1 if s02q14==4 & attend==1 & pri_school==1  // 6ème 5ème 4ème 3ème
*--------------Secondaire 2 Général  and Secondaire 2 Technique
**Public
gen ben_secondary_up=0
replace ben_secondary_up=1 if  s02q14==5 & attend==1 & pub_school==1  // 2nde 1ère Terminale
replace ben_secondary_up=1 if  s02q14==6 & attend==1 & pub_school==1  // 2nde 1ère Terminale
***Private
gen ben_secondary_up_pri=0
replace ben_secondary_up_pri=1 if s02q14==5 & attend==1 & pri_school==1  // 2nde 1ère Terminale
replace ben_secondary_up_pri=1 if s02q14==6 & attend==1 & pri_school==1  // 2nde 1ère Terminale
*--------------Combining into secondary and primary
**Public
gen     ben_secondary = 1 if (ben_secondary_low==1 | ben_secondary_up==1) & pub_school==1 
replace ben_primary   = 1 if  ben_secondary==1 & age<=9
replace ben_secondary = 0 if  ben_secondary==1 & age<=9
***Private
gen     ben_secondary_pri = 1 if (ben_secondary_low_pri==1 | ben_secondary_up_pri==1) & pri_school==1
replace ben_primary_pri   = 1 if  ben_secondary_pri==1 & age<=9
replace ben_secondary_pri = 0 if  ben_secondary_pri==1 & age<=9
*--------------Teritiary
**Public
gen     ben_tertiary=0
replace ben_tertiary=1 if s02q14==7 & attend==1 & pub_school==1 // Supérieur 1è to 6 et+
replace ben_tertiary=1 if s02q14==8 & attend==1 & pub_school==1 // Supérieur 1è to 6 et+
***Private
gen     ben_tertiary_pri=0
replace ben_tertiary_pri=1 if s02q14==7 & attend==1 & pri_school==1 // Supérieur 1è to 6 et+
replace ben_tertiary_pri=1 if s02q14==8 & attend==1 & pri_school==1 // Supérieur 1è to 6 et+

*--------------Defining type of beneficiary ed_level
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



*==================================================================================
dis "==============        Adding SEEDS!!!!!!!!!!!		==========="
*==================================================================================
*Note Seed were not working the sim do-file so they wil be generated here 
//set seed was defined above at the beggining of the do-file 
gen school_seed= uniform()
gen ter_seed= uniform()
gen ter2_seed= uniform()


gen cmu50_seed=runiform()
gen pben_sesame_seed=runiform()
gen pben_moins5_seed=runiform()
gen cesarienne_seed=runiform()
gen cmu100_seed=runiform()

save "$presim/07_educ.dta", replace

*==================================================================================
dis "==============        Adding variables to define health system		==========="
*==================================================================================

merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s04_me_SEN2018.dta", gen(merged4)
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s01_me_SEN2018.dta", gen(merged5) update
merge n:1 interview__key interview__id id_menage grappe vague  using "$data_sn/s00_me_SEN2018.dta", gen(merged6) keepusing(hhid) update
merge n:1 hhid  using "$data_sn/ehcvm_conso_SEN2018_menage.dta", gen(merged7) keepusing(hhweight) update

gen formal=1 if s04q38==1 // cotise-t-il à l'IPRES, au FNR ou à la Retraite Complém
replace formal=1 if inlist(s04q31,1,2,6) // Public employee or NGO 
replace formal=1 if s04q42==1 // receive payslip
recode formal .=0

gen formal_definitivo=formal // completely exhaustive dummy so not needed previous code

gen informal = .
replace informal = 1 if formal_definitivo==0 & s04q10==1 //  Parmi les réponses aux questions 4.06, 4.07, 4.08, 4.09 y en a-t-il une affirmative (employed)
  
gen formality = . 
replace formality = 1 if formal==1
replace formality = 0 if informal==1 
  
bys hhid: egen informalh=max(informal)
 
*==================================================================================
dis "==============        Adding SEEDS!!!!!!!!!!!		==========="
*==================================================================================
*Note Seed were not working the sim do-file so they wil be generated here 

cap gen pmt_seed= uniform()




save "$presim/07_dir_trans_PMT_educ_health.dta", replace
	