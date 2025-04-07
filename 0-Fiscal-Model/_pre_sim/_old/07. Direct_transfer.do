

/*
Author     : Gabriel Lombo
Start date : 24 April 2024
Last Update: 24 April 2024 

Objective  : Presimulation for Direct Transfer for the purpose of fiscal microsimulation to study the incidence of Direct transfer
           **I compile and adopt the key characteristics of the household necessary for assignment of social programmes 
*/


*====================================================================
dis "=======       Defining allocation on direct transfers		====="
*====================================================================

set seed 123456789

use "$presim/PMT_EPCV_harmonized.dta", clear


*-------------- Elegibility

gen eleg_1 = 1 // Tekavoul
gen eleg_2 = worry == 1 // reason_drought == 1 // Food Transfers
replace eleg_2 = 1 if hh_prog_2 == 1

gen eleg_3 = elmaouna == 1 // (elmaouna == 1 & milieu == 2) // Elmaouna
gen eleg_5 = 1 // UBI
gen eleg_6 = 1 // Public Student
	
sum PMT_1
replace PMT_1 = r(min) if hh_prog_1 == 1	

sum PMT_2
replace PMT_2 = r(min) if hh_prog_2 == 1

sum PMT_3
replace PMT_3 = r(min) if hh_prog_2 == 1	
	
gen PMT_4 = PMT	


	
*--------------Adding seeds
gen pmt_seed= uniform()
*egen = min(pmt_seed) if hh_prog_1==1, by(wilaya)

gen pmt_seed_1 = pmt_seed - hh_prog_1
gen pmt_seed_2 = pmt_seed - hh_prog_2
gen pmt_seed_3 = pmt_seed

ren hid hhid 
keep hhid PMT* eleg* welfare wilaya moughataa commune hhsize hhweight pmt* hh_prog_1

gen departement = wilaya
gen geo_zzt = wilaya
gen region = wilaya

save "$presim/07_dir_trans_PMT.dta", replace

*erase "$presim/PMT_EPCV_harmonized.dta"


*====================================================================
dis "=======       Defining benefits from education system	====="
*====================================================================


use "$data_sn/individus_2019.dta", clear

merge m:1 hid using "$presim/PMT_EPCV_harmonized", keepusing(hh_prog_3) keep(1 3)

global attend C5 // attend school during 2019-2020
global public C8
global level  C7N

gen attend = inrange($attend, 1, 4)

gen pub_school=1 if   $public ==1  // attend Public school
gen pri_school=1 if   $public ==2 // attend private school 

**** Identify students by level

*-------------- Early Childhood Education 
**Public
gen     ben_pre_school= 0
replace ben_pre_school= 1 if inrange($level, 2, 4)  & attend==1 & pub_school==1
***Private
gen     ben_pre_school_pri= 0
replace ben_pre_school_pri= 1 if inrange($level, 2, 4)  & attend==1 & pri_school==1

*--------------Primaire
**Public
gen ben_primary=0
replace ben_primary= 1 if $level ==5 & attend==1 & pub_school==1 

**Private
gen ben_primary_pri=0
replace ben_primary_pri= 1 if $level ==5 & attend==1 & pri_school==1 

*--------------Secondaire 1 (Post Primaire) Général and Secondaire 1 (Post Primaire) Technique
**Public
gen ben_secondary_low=0
replace ben_secondary_low=1 if inrange($level, 6, 7) & attend==1 & pub_school==1  // 6ème 5ème 4ème 3ème

**Private
gen     ben_secondary_low_pri=0
replace ben_secondary_low_pri=1 if inrange($level, 6, 7) & attend==1 & pri_school==1  // 6ème 5ème 4ème 3ème

*--------------Secondaire 2 Général  and Secondaire 2 Technique
**Public
gen ben_secondary_up=0
replace ben_secondary_up=1 if  inrange($level, 9, 10) & attend==1 & pub_school==1  // 2nde 1ère Terminale

***Private
gen ben_secondary_up_pri=0
replace ben_secondary_up_pri=1 if inrange($level, 9, 10) & attend==1 & pri_school==1  // 2nde 1ère Terminale

*--------------Combining into secondary and primary
**Public
gen     ben_secondary = 1 if (ben_secondary_low==1 | ben_secondary_up==1) & pub_school==1 

***Private
gen     ben_secondary_pri = 1 if (ben_secondary_low_pri==1 | ben_secondary_up_pri==1) & pri_school==1

*--------------Teritiary
**Public
gen     ben_tertiary=0
replace ben_tertiary=1 if inlist($level, 8, 11, 12) & attend==1 & pub_school==1

***Private
gen     ben_tertiary_pri=0
replace ben_tertiary_pri=1 if inlist($level, 8, 11, 12) & attend==1 & pri_school==1

*--------------Defining type of beneficiary ed_level
gen ed_level = . 
replace ed_level= 1 if ben_pre_school==1
replace ed_level= 2 if ben_primary==1
replace ed_level= 3 if ben_secondary==1
replace ed_level= 4 if ben_tertiary==1

label define ed_level 1 "Pre-school" 2 "Primary" 3 "Secondary" 4 "Terciary"
label val ed_level ed_level

gen ed_level_pri = . 
replace ed_level_pri= 1 if ben_pre_school_pri==1
replace ed_level_pri= 2 if ben_primary_pri==1
replace ed_level_pri= 3 if ben_secondary_pri==1
replace ed_level_pri= 4 if ben_tertiary_pri==1
                                                 
gen prepri_sec=(ben_pre_school== 1 | ben_primary==1 | ben_secondary == 1)

ren wilaya region
ren hid hhid 											 

keep hhid region ben* hh_prog_3

*-------------- Elegibility
* School feeding
*gen elegible_4 = 2
*replace elegible_4 = 1 if hh_prog_3 == 1
	
gen eleg_4=(ben_pre_school== 1 | ben_primary==1)			
gen preandpri=(ben_pre_school== 1 | ben_primary==1)			


*--------------Adding seeds
gen pmt_seed_4= uniform()
replace pmt_seed = pmt_seed_4 - hh_prog_3

*gen ter_seed= uniform()
*gen ter2_seed= uniform()


*gen cmu50_seed=runiform()
*gen pben_sesame_seed=runiform()
*gen pben_moins5_seed=runiform()
*gen cesarienne_seed=runiform()
*gen cmu100_seed=runiform()

save "$presim/07_educ.dta", replace






	
