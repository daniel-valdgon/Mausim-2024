

/*
Author     : Gabriel Lombo
Start date : 24 April 2024
Last Update: 24 April 2024 

Objective  : Presimulation for Direct Transfer for the purpose of fiscal microsimulation to study the incidence of Direct transfer
           **I compile and adopt the key characteristics of the household necessary for assignment of social programmes 
*/


set seed 123456789

*==========================================================
*		Data checking 
*==========================================================

use "$presim/PMT_EPCV_harmonized", clear

	//demographics
	su hhsize HH_female-Prop_65plus HH_female HH_age HH_celibat HH_maried HH_widowed HH_divorce tx_Dependance /*Pop0_3 Pop4_6 Pop7_9 Pop10_12 Pop13plus*/ /*HH_size_1 HH_size_2_3 HH_size_4_5 HH_size_6*/ HH_size_0_3 HH_size_4_7 HH_size_8_10 HH_size_11_13 HH_size_14 [w=hhweight]
	su HH_age
	replace HH_age = r(mean) if HH_age ==.m 
	*
	gen HH_age2 = HH_age*HH_age 
	lab var HH_age2 "Squared Age of Household head"
	*
	su Pop0_14 Pop65plus Pop15_64 if tx_Dependance==. // no working age population (74)
	replace tx_Dependance = Pop0_14 + Pop65plus if tx_Dependance==. // 74 changes
	**
	gen log_size = log(hhsize)
	lab var log_size "Logarithm of the household size"
	**
	
	global demographics HH_female HH_age  HH_celibat HH_maried HH_widowed HH_divorce tx_Dependance  log_size
	global demographics2 HH_female HH_age  HH_celibat HH_maried HH_widowed  tx_Dependance  log_size

	//education
	su HH_noeduc-Peop_edu [w=hhweight]
	local edu HH_noeduc HH_prim HH_sec HH_sup
	foreach var of  local edu {  // only 3 changes at most
		replace `var' = 0 if `var' ==.
	}

	global education /*HH_noeduc-HH_sup*/ HH_noeduc-HH_prim HH_sec_sup /*Peop_Educ_noeduc-Peop_Educ_sup*/ Peop_Educ_noeduc-Peop_Educ_prim Peop_Educ_sec_sup /**/ /* Pop_sec Pop_sup*/ Pop_noeduc Pop_prim  Pop_sec_sup

	//health
	su HH_disable HH_disable_visual HH_disable_physical [w=hhweight]
	global health HH_disable HH_disable_visual HH_disable_physical
	
	//housing
	su occupancy_owner-dist_water [w=hhweight]
	
	local house wall_cement wall_mud roof_thatch roof_ironsheet floor_earth floor_tiles floor_cement light_elect light_solar light_poor cook_firewoodC cook_firewoodP cook_charcoal toilet_flush toilet_pit toilet_other water_piped water_psPipe water_wellC water_wellP /*disposal_burnt disposal_compost disposal_collected disposal_dump disposal_bush*/
	
	foreach var of local house {  // 29 changes to zero at most
		replace `var' = 0 if `var' ==.
	}
	global housing occupancy_owner-occupancy_free wall_cement-light_solar light_poor-water_wellP /**/ /*cook_charcoal-cook_charcoal waterpipe impwater imptoilet disposal_burnt-disposal_bush*/

	global housing2 occupancy_owner-occupancy_free wall_cement-light_solar light_poor-water_wellC /*disposal_burnt-disposal_bush*/

	//asset
	su landphone-conditioner [w=hhweight]
	local asset /*mobile*/ landphone computer /*bicycle*/ motorcycle car radio tv refrigerator fan conditioner
	foreach var of local asset {  // 3 changes to zero at most
		replace `var' = 0 if `var' ==.
	}
	global asset /*mobile landphone*/ computer /*bicycle*/ motorcycle car radio tv /*refrigerator fan conditioner*/

	//agriculture 
	su nbr_land agric_hold [w=hhweight]
	replace nbr_land = 0 if agric_hold ==0 // 1 changes
	su nbr_land if agric_hold ==1 
	replace nbr_land = r(mean) if nbr_land ==. & agric_hold ==1  // 33 changes to the mean
	global agriculture nbr_land /* agric_hold*/ 

	//livestock
	**
	gen log_medium_livestock = log(medium_livestock+1)
	gen log_large_livestock = log(large_livestock +1)
	lab var log_medium_livestock "Logarithm of number of medium livestock"
	lab var log_large_livestock "Logarithm of number of large livestock"
	**
	su large_livestock medium_livestock [w=hhweight] 
	*global livestock medium_livestock large_livestock  
	global livestock log_medium_livestock log_medium_livestock 

	//employment
	su HH_work HH_work_employee HH_work_farm HH_work_business agriculture industries services [w=hhweight] 
	global employment  /*HH_work*/ HH_work_employee HH_work_farm HH_work_business agriculture industries services /*Pop_not_work*/ 
	
	//shocks
	sum ${shocks} [w=hhweight]
	*global shocks ${shocks}
	
	****



	
*==========================================================
***	Model selection for National
*	Two methods : (i) Regression by leaps and bounds, and (ii) LASSO
*==========================================================

*-------------- Covariates
	svyset cluster [w=hhweight]
	svy : mean $demographics $health $education $employment $housing $asset $agriculture $livestock $shocks

	global vlist $demographics $health $education $employment $housing $asset $agriculture $livestock $shocks /* final list of variable*/
	global vlist2 $demographics2 $health $education $employment $housing2 $asset $agriculture $livestock $shocks /* final list of variable*/
	global vlist_ur $demographics $health $education $employment $housing_ur $asset $agriculture $livestock $shocks

	gen double welfare = log(pcexp)

*-------------- Proxy Mean Test
	splitsample , generate(sample_nat) split(0.7 0.3) rseed(12345)

	****leaps and bounds
	vselect welfare $vlist if sample_nat==1 [aw=hhweight], forward r2adj
	return list
	global vlist2=r(predlist)

	stepwise, pr(.0999999) pe(.099999) : reg welfare $vlist2  [pw=hhweight] if sample_nat==1
	
	matrix X = e(b)
	matrix X = X[1,1..`e(df_m)']
	
	global myvar: colnames X	

	global myvar_mi $myvar

	reg welfare $myvar_mi [pw=hhweight] if sample_nat==1
	estimates store l_bounds_nat
	*lassogof l_bounds_nat, over(sample_nat)

	predict xb
	rename xb PMT
	
*-------------- Targeting: Logit on (1) Tekavoul, (2) Food Distribution, (3) School Feeding Program
				
forvalues i = 1/3 {
	
	gen rev_hh_prog_`i' = 0 if  hh_prog_`i' == 1
	replace rev_hh_prog_`i' = 1 if  hh_prog_`i' == 0
	
	*drop hh_prog_`i'
	*ren Ahh_prog_`i' hh_prog_`i'
	
	vselect rev_hh_prog_`i' $vlist if sample_nat==1 [aw=hhweight], forward r2adj
	return list
	
	global vlist2=r(predlist)

	stepwise, pr(.0999999) pe(.099999) : reg rev_hh_prog_`i' $vlist2  [pw=hhweight] if sample_nat==1
	
	matrix X = e(b)
	matrix X = X[1,1..`e(df_m)']
	
	global myvar: colnames X	

	global myvar_mi $myvar

	reg rev_hh_prog_`i' $myvar_mi [pw=hhweight] if sample_nat==1
	estimates store l_bounds_nat
	
	predict xb_`i'
	rename xb_`i' PMT_`i'
}	

save "$presim/PMT_temp.dta", replace



use "$presim/PMT_temp.dta", clear


*-------------- Elegibility
gen eleg_1 = 1 // Tekavoul
gen eleg_2 = reason_drought == 1 // Food Transfers
replace eleg_2 = 1 if hh_prog_2 == 1

gen eleg_3 = (elmaouna == 1 & milieu == 2) // Elmaouna
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






	
