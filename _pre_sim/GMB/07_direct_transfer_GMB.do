

/*
Author     : Madi Mangan
Start date : 04 April 2024
Last Update: 04 April 2024 

Objective  : Presimulation for Direct Transfer for the purpose of fiscal microsimulation to study the incidence of Direct transfer
           **I compile and adopt the key characteristics of the household necessary for assignment of social programmes 
*/


		tempfile section0
		tempfile section1
		tempfile section11
		tempfile section12
		tempfile section17
		set seed 123456789
		
		
**********************************************************************

*==========================================================
*Group of variables : 		socio-demographics
*==========================================================

use "$data_sn/Hhold Roster.dta", clear
*gen s3aq1 = s1q1
merge 1:1 hid idnum using "$data_sn/Education General.dta", nogen // education data
*gen idnum = s1q1 
merge 1:1 hid idnum using "$data_sn/Health for all the Hhold Members.dta", nogen
merge 1:1 hid idnum using "$data_sn/Health_2c.dta", nogen 


gen HH_female = (s1q3==2)	/* Household head head is female : 1 if yes, 0 if no  */
gen HH_age = s1q5_years 		/* Age of Household head */
gen HH_celibat =(s1q10==1) if s1q10 ~=.	/* Household head is single : 1 if yes, 0 if no*/
gen HH_maried =(s1q10==2) if s1q10 ~=. 	/* Household head is marie : 1 if yes, 0 if no*/
gen HH_widowed =(s1q10==6) if s1q10 ~=. 	/* Household head is widowed : 1 if yes, 0 if no*/
gen HH_divorce =(s1q10==4 | s1q10==5) if s1q10 ~=.	/* Household head is divorced or separated : 1 if yes, 0 if no*/


gen age0_14 =(s1q5_years<=14)  										/* people less than 15 years old : 1 if yes, 0 if no*/
gen age65plus =(s1q5_years>=65 & s1q5_years!=.)  								/* people more than 65 years old : 1 if yes, 0 if no*/
gen age15_64 =(inrange(s1q5_years,15,64))   						/* people between 15 years old and 64 years old : 1 if yes, 0 if no*/
bysort hid: egen Pop0_14 =sum(age0_14) 						/* number of people less than 15 years old in the Household*/
bysort hid: egen Pop65plus =sum(age65plus)  						/* number of people 65 years+ in the Household */
bysort hid : egen Pop15_64 =sum(age15_64) 					 /* number of people between 15 and 16 years old in the Household */
gen tx_Dependance = (Pop0_14 + Pop65plus)/Pop15_64					/* Dependance ratio in the household */

//Pantaleo proposed categories
gen age0_3 =(s1q5_years<=3)  										/* people less than 3 years old : 1 if yes, 0 if no*/
gen age4_6 =(inrange(s1q5_years,4,6))   						/* people between 4 years old and 6 years old : 1 if yes, 0 if no*/
gen age7_9 =(inrange(s1q5_years,7,9))   						/* people between 7 years old and 9 years old : 1 if yes, 0 if no*/
gen age10_12 =(inrange(s1q5_years,10,12))   						/* people between 10 years old and 12 years old : 1 if yes, 0 if no*/
gen age13plus =(s1q5_years>=13 & s1q5_years!=.)   						/* people more than 12 years old : 1 if yes, 0 if no : 1 if yes, 0 if no*/

bysort hid: egen Pop0_3 =sum(age0_3) 						/* number of people less than 3 years old in the Household*/
bysort hid: egen Pop4_6 =sum(age4_6) 						/* number of people between 4 and 6 years old in the Household*/
bysort hid: egen Pop7_9 =sum(age7_9) 						/* number of people between 7 and 9 years old in the Household*/
bysort hid: egen Pop10_12 =sum(age10_12) 						/* number of people between 10 and 12 years old in the Household*/
bysort hid: egen Pop13plus =sum(age13plus)  						/* number of people 13 years+ in the Household */



gen n=1
egen taille=total(n),by(hid)
drop n
gen share_dep=(Pop0_14+Pop65plus)/taille /*Dependent share*/

gen age0_4 =(s1q5_years<=4)  											/* people less than 5 years old : 1 if yes, 0 if no */ 
gen age5_14 =(inrange(s1q5_years,5,14))   							/* people between 5 years old and 14 years old : 1 if yes, 0 if no */
bysort hid : egen Pop0_4 =sum(age0_4) 						/* number of people less than 5 years old in the Household */
bysort hid: egen Pop5_14 =sum(age5_14 ) 						/* number of people between 5 and 14 years old in the Household */

gen Prop_0_4 = Pop0_4/taille  /* Proportion of people less than 5 years old in the household */
gen Prop_5_14 = Pop5_14/taille  /* Proportion of people between 5 years old and 14 years in the household */
gen Prop_15_64 = Pop15_64 /taille  /* Proportion of people between 15 years and 64 years old in the household */
gen Prop_65plus = Pop65plus/taille  /* Proportion of people more than 65 years old in the household */

***HH size categories
gen HH_size_1 = (taille ==1) /*1 member household*/
lab var HH_size_1 "1 members household"
gen HH_size_2 = (taille ==2) /*2 member household*/
lab var HH_size_2 "2 member household"
gen HH_size_3 = (taille ==3) /*3 member household*/
lab var HH_size_3 "3 memberss household"
gen HH_size_4 = (taille ==4) /*4 member household*/
lab var HH_size_4 "4 members household"
gen HH_size_5 = (taille ==5) /*5 member household*/
lab var HH_size_5 "5 members household"
gen HH_size_2_3 = (taille>=2 & taille<=3) /*2 to 3 members household*/
lab var HH_size_2_3 "2 to 3 members household"
gen HH_size_4_5 = (taille>=4 & taille<=5) /*4 to 5 members household*/
lab var HH_size_4_5 "4 to 5 members household"
gen HH_size_6 = (taille>=6) /*6+ members household*/
lab var HH_size_6 "6 members household"

***HH size categories (Pantaleo)
gen HH_size_0_3 = (taille>=0 & taille<=3) /*0 to 3 members household*/
lab var HH_size_0_3 "0 to 3 members household"
gen HH_size_4_7 = (taille>=4 & taille<=7) /*4 to 7 members household*/
lab var HH_size_4_7 "4 to 7 members household"
gen HH_size_8_10 = (taille>=8 & taille<=10) /*8 to 10 members household*/
lab var HH_size_8_10 "8 to 10 members household"
gen HH_size_11_13 = (taille>=11 & taille<=13) /*11 to 13 members household*/
lab var HH_size_11_13 "11 to 13 members household"
gen HH_size_14 = (taille >=14) /*14+ members household*/
lab var HH_size_14 "14 members household"


*==========================================================
*Groupe de variable : 			Education
*==========================================================

gen EDUCATION = "EDUCATION SECTION"

replace s3aq6 = 0 if s3aq2==2 /*Assigning no education to people who never attended a school*/
gen HH_noeduc=(s3aq6==0 )  if s1q6==1 & s3aq6 ~=. /* Household head has no education level : 1 if no education or preschool, 0 if not */
gen HH_prim=(s3aq6==1)  if s1q6==1 & s3aq6 ~=. /* Household head has a primary education level : 1 if primary, 0 if not */
gen HH_sec=(s3aq6==2 | s3aq6==3)  if s1q6==1 & s3aq6 ~=. /* Household head has a secondary education level : 1 if secondary (lower or upper), 0 if not */
gen HH_sup=(s3aq6==6 )  if s1q6==1 & s3aq6 ~=. /* Household head has a tertiairy education level : 1 if diploma (post-secondary) or university, 0 if not */

gen HH_sec_sup = (HH_sec==1 | HH_sup==1)
lab var HH_sec_sup "Household head has a secondary or tertiairy education level : 1 if diploma (post-secondary) or university, 0 if not"

bysort hid : egen Pop_noeduc =sum(s3aq6==0) 						/* number of people with no education */
bysort hid : egen Pop_prim =sum(s3aq6==1) 						/* number of people with primary education */
bysort hid : egen Pop_sec =sum(s3aq6==2 | s3aq6==3)				/* number of people with secondary education */
bysort hid : egen Pop_sup =sum(s3aq6==6)				/* number of people with higher education */
egen Pop_sec_sup = rsum(Pop_sec Pop_sup)

replace Pop_noeduc= Pop_noeduc/taille
replace Pop_prim= Pop_prim/taille
replace Pop_sec= Pop_sec/taille
replace Pop_sup= Pop_sup/taille
replace Pop_sec_sup= Pop_sec_sup/taille

lab var Pop_noeduc "Proportion of individual with no education in the HH"
lab var Pop_prim "Proportion of individual with primary education in the HH"
lab var Pop_sec_sup "Proportion of individual with secondary or tertiairy education in the HH"



gen HH_edu=0 if HH_noeduc==1
replace HH_edu=1 if HH_prim==1
replace HH_edu=2 if HH_sec==1
replace HH_edu=3 if HH_sup==1

label define educ 0 "No education" 1 "Primary Education" 2 "Secondary Education" 3 "University"
label values HH_edu educ

bysort hid : egen Peop_Educ =max(s3aq6) /* Education level of the most educated in the household */

gen Peop_Educ_noeduc=(Peop_Educ==0)  /* Most educated person in the household has no education level : 1 if no education or preschool, 0 if not */
gen Peop_Educ_prim=(Peop_Educ==1)    /* Most educated person in the household has primary education level  : 1 if primary, 0 if not */
gen Peop_Educ_sec=(Peop_Educ==2 | Peop_Educ==3)  /* Most educated person in the household has secondary education level : 1 if primary, 0 if not */
gen Peop_Educ_sup=(Peop_Educ==6)  /* Most educated person in the household has higher education level : 1 if diploma (post-secondary) or university, 0 if not */

gen Peop_Educ_sec_sup = (Peop_Educ_sec==1 | Peop_Educ_sup==1)
lab var Peop_Educ_sec_sup "Most educated person in the household has secondary or higher education level : 1 if diploma (post-secondary) or university, 0 if no"

gen Peop_edu=0 if Peop_Educ_noeduc==1
replace Peop_edu=1 if Peop_Educ_prim==1
replace Peop_edu=2 if Peop_Educ_sec==1
replace Peop_edu=3 if Peop_Educ_sup==1
label val Peop_edu educ


gen HEALTH = "HEALTH SECTION"

gen HH_disable = (s2cq3==1) if s2cq3 ~=. & s1q6==1 /* Household head has any form of disability: 1 if yes, 0 if not */
gen HH_disable_visual = (s2cq4==1) if s2cq3 ~=. & s1q6==1 /* Household head has visual disability: 1 if yes, 0 if not */
gen HH_disable_physical = (s2cq4==3 | s2cq4==4) if s2cq3 ~=. & s1q6==1 /* Household head has moving/hand/feet steps disability: 1 if yes, 0 if not */


**
keep if s1q6 == 1
keep hid HH_female-HH_disable_physical
save "$data_sn/IHS2015_Indiv",replace


*==================================== ======================
*Group of variables : 		Housing
*==========================================================

use "$data_sn/Housing.dta", clear

gen occupancy_owner = (s8aq2==1) if s8aq2 ~=. /* household is owner of its place : 1 if yes, 0 if not */
gen occupancy_renting = (s8aq2==2) if s8aq2 ~=. /* household is renting the place : 1 if yes, 0 if not */
gen occupancy_free = (s8aq2==3) if s8aq2 ~=. /* household has the place for renting free : 1 if yes, 0 if not */
gen occupancy_other = (s8aq2>=4 & s8aq2<=9) if s8aq2 ~=. /* household has other type of occupancy status : 1 if yes, 0 if not */


gen wall_cement = (s8aq21==4) if s8aq21 ~=.  /* exterior wall is made of cement blocks/concrete : 1 if yes, 0 if not */
gen wall_mud = (s8aq21==1) if s8aq21 ~=.  /* exterior wall is made of mud/kirinting : 1 if yes, 0 if not */

gen roof_thatch  = (s8aq22==1) if s8aq22~=. /* roof is made of thatch : 1 if yes, 0 if not */
gen roof_ironsheet = (s8aq22==2) if s8aq22~=.  /* roof is made of corrugated iron sheet (maybe corresponds to Metal/Tin) : 1 if yes, 0 if not */

gen floor_earth  = (s8aq23==1) if s8aq23 ~=. /* floor is made of earth/mud : 1 if yes, 0 if not */
gen floor_tiles = (s8aq23==3) if s8aq23 ~=. /* floor is made of tiles : 1 if yes, 0 if not */
gen floor_cement= (s8aq23==4) if s8aq23 ~=. /* floor is made of cement/concrete : 1 if yes, 0 if not */

gen light_elect = (s8aq12==1 | s8aq12==2) if s8aq12 ~=. /* main lighting fuel is electricity (nawec or generator) : 1 if yes, 0 if not */
gen light_solar = (s8aq12==3) if s8aq12 ~=. /* main lighting fuel is solar power : 1 if yes, 0 if not */
gen light_candles = (s8aq12==6) if s8aq12 ~=. /* main lighting fuel is candles : 1 if yes, 0 if not */
gen light_battery  = (s8aq12==7) if s8aq12 ~=. /* battery power light : 1 if yes, 0 if not */
gen light_poor = (s8aq12>=6 & s8aq12<=9) /* Poor lighting source (lamp, candle, battery and other) : 1 if yes, 0 if not */

//Important: a small change here
gen cook_firewood = (s8aq8==1) if s8aq8 ~=. /* main cooking fuel is firewood (no distinction between collecter or purchased) : 1 if yes, 0 if not */

ren cook_firewood cook_firewoodC

gen cook_firewoodP = (s8aq8==2) if s8aq8 ~=. /* main cooking fuel is firewood purchased : 1 if yes, 0 if not */
gen cook_charcoal = (s8aq8==2) if s8aq8 ~=. /* main cooking fuel is charcoal : 1 if yes, 0 if not */

gen toilet_flush = (s8aq18>=1 & s8aq18<=3) if s8aq18 ~=. /* main type of toilet is flush (piped, spetic, pit) : 1 if yes, 0 if not */
gen toilet_pit = (s8aq18>=4 & s8aq18<=6) if s8aq18 ~=. /* main type of toilet is pit (VIP, with slab, without slab) : 1 if yes, 0 if not */
gen toilet_other = (s8aq18>=7 & s8aq18<=8) if s8aq18 ~=. /* main type of toilet is other (bucket, open, private pan) : 1 if yes, 0 if not */
gen toilet_shared = (s8aq19==1) /* toilet is shared with other households : 1 if yes, 0 if not */

gen water_piped  = (s8aq6==1 | s8aq6==2) if s8aq6 ~=. /* main drinking water is piped into dwelling or coumpound : 1 if yes, 0 if not */
gen water_psPipe = (s8aq6==3) if s8aq6 ~=. /* main drinking water is public stand pipe : 1 if yes, 0 if not */
gen water_wellC = (s8aq6>=4 & s8aq6<=7) if s8aq6 ~=. /* main drinking water is (un)protected in coumpound : 1 if yes, 0 if not */
//Change
gen water_wellP = (s8aq6==8) if s8aq6 ~=. /* main drinking water is public well with  : 1 if yes, 0 if not */

gen disposal_burnt  = (s8aq15==1 | s8aq15==2) if s8aq15~=.  /* garbage disposal via landfill/burry/burnt : 1 if yes, 0 if not */
gen disposal_compost = (s8aq15==3) if s8aq15~=.  /* garbage disposal via compsot : 1 if yes, 0 if not */
gen disposal_collected = (s8aq15>=5 & s8aq15<=7) if s8aq15~=. /* garbage disposal collected (municipal or private) : 1 if yes, 0 if not */
gen disposal_dump = (s8aq15==9) if s8aq15~=.  /* garbage disposal via public dump : 1 if yes, 0 if not */
gen disposal_bush = (s8aq15==10) if s8aq15~=.  /* garbage disposal via bush or open space : 1 if yes, 0 if not */

gen dist_water = s8aq7  /* distance to water source (km) */


keep hid occupancy_owner-dist_water
tempfile housing
save `housing', replace



*==========================================================
*Group of variables :  		Household assets
*==========================================================

use "$data_sn/Stata/PART A Section 9-Ownership of durable assets.dta", clear

keep if inlist(s9q1,18,19,17,14,16,22,30,31,32,34,35,36,41,40,38,33)
keep hid s9q1 s9q2
rename s9q2 s9q2_
reshape wide s9q2_ , i(hid) j(s9q1)

gen mobile = (s9q2_33==1)                  /*Household has mobile phone : 1 if yes, o if not */
gen landphone = (s9q2_32==1)               /*Household has landline phone : 1 if yes, o if not*/
gen computer = (s9q2_30==1|s9q2_31==1)     /*Household has computer/laptop/tablet : 1 if yes, o if not*/
gen bicycle = (s9q2_34==1)                 /*Household has bicyle : 1 if yes, o if not*/
gen motorcycle = (s9q2_35==1)              /*Household has motorcycle : 1 if yes, o if not*/
gen car = (s9q2_36==1)                     /*Household has car/van : 1 if yes, o if not*/
gen truck = (s9q2_38==1)                   /*Household has truck/lorry : 1 if yes, o if not*/
gen animal_cart = (s9q2_41==1)             /*Household has Animal drawn cart  : 1 if yes, o if not*/
gen boat = (s9q2_40==1)                    /*Household has boat/canoe : 1 if yes, o if not*/
gen radio = (s9q2_18==1 | s9q2_19==1)      /*Household has radio : 1 if yes, o if not*/
gen tv = (s9q2_22==1)                      /*Household has tv : 1 if yes, o if not*/
gen refrigerator = (s9q2_14==1)            /*Household has refrigerator : 1 if yes, o if not*/
gen fan = (s9q2_17==1)                     /*Household has fan : 1 if yes, o if not*/
gen conditioner = (s9q2_16==1)             /*Household has air conditioner : 1 if yes, o if not*/

keep hid mobile-conditioner
tempfile assets
save `assets', replace


*==========================================================
*Group of variables :  		Agriculture
*==========================================================

use "$data_sn/Stata/Part B Section 3A-Agriculture holding.dta", clear

bys hid: egen nbr_land =max(s3aq2) /*Number of land cultivated by household*/
keep hid s3aq1 nbr_land
drop if s3aq1 ==. //
ta s3aq1
ta nbr_land
ta nbr_land if s3aq1==2 
replace nbr_land =0 if s3aq1==2 
gen agric_hold = (s3aq1==1) /*Household involved in land cultivation : 1 if yes, o if not*/

keep hid agric_hold nbr_land

tempfile agriculture
save `agriculture', replace


** use "C:\Users\WB487133\OneDrive - WBG\Attachments\Rose\Gambia\Poverty decomposition\HH-head for poverty correlates.dta", clear
use "$data_sn/Stata/PART B Section 3E-Livestock ownership.dta", clear 

gen horses = s3eq4a if s3eq2 ==1
recode horses .=0
gen oxen = s3eq4a if   s3eq2 ==2
recode oxen .=0
gen donkeys = s3eq4a if   s3eq2 ==3
recode donkeys .=0
gen cattle = s3eq4a if   s3eq2 ==4
recode cattle .=0

gen sheep = s3eq4a if   s3eq2 ==5
recode sheep .=0
gen goats = s3eq4a if   s3eq2 ==6
recode goats .=0
gen pigs = s3eq4a if   s3eq2 ==7
recode pigs .=0

*Large: horses oxen donkeys cattle
gen large_livestock = horses + oxen + donkeys + cattle
replace large_livestock=0 if large_livestock==.
*Medium : sheep goats pigs
gen medium_livestock = sheep + goats + pigs
replace medium_livestock=0 if medium_livestock==.

collapse (max) medium_livestock large_livestock, by(hid)

keep hid medium_livestock large_livestock

tempfile livestock
save `livestock', replace


*==========================================================
*Group of variables :  		Employment 
*==========================================================

*use "C:\Users\WB487133\OneDrive - WBG\Attachments\Rose\Gambia\Poverty decomposition\HH-head for poverty correlates.dta", clear
use "$data_sn/Stata/PART A Section 1_2_3_4_6-Individual level.dta", clear
keep if idnum ==1
***Worked as an employee, or own account in farm or enterprise (added temp absent): 1 if yes, 0 if not
//HH is unemployed : 1 if yes
gen HH_work = 1 if s4q3 ==1
*replace HH_work = 1 if s4aq5 == 1
*replace HH_work = 1 if s4aq7==1
*replace HH_work = 1  if s4aq10 ==1
*replace HH_work =0 if HH_work ==.
recode HH_work (1=0) (0=1)

gen HH_work_employee = (s4q3 ==1) /*Work as an employee: 1 if yes 0 if no*/
*gen HH_work_farm = (s4aq5 == 1) /*Work on their own account on a farm: 1 if yes 0 if no*/
*gen HH_work_business = (s4aq7 == 1) /*Work on their own account or in a business enterprise: 1 if yes 0 if no*/


***Industry
*replace industry4_7_1 =5 if industry4_7_1 ==. // for people with no job
*replace industry4_7_1 = 5 if HH_work ==1 // to keep the same definition as in the social registry data (88 changes) // unemployed

*tab industry4_7_1, generate (industry4_7_1_) // Sector of employment of the head (omitted : other)
*rename industry4_7_1_1 agriculture  // work in agriculture sector
*rename industry4_7_1_2 industries  // work in industry sector
*rename industry4_7_1_3 services  // work in services sector

foreach var in HH_work_farm HH_work_business agriculture industries services ownhouse waterpipe impwater imptoilet {
	gen `var' =1
}

keep hid HH_work HH_work_employee HH_work_farm HH_work_business agriculture industries services /*added variables for housing*/ ownhouse waterpipe impwater imptoilet

tempfile employment
save `employment', replace





*==========================================================
*Finalizing the dataset
*==========================================================

use "$data_sn/GMB_IHS2020_E_hhsize.dta", clear
keep lga district district1 eanum cluster hhno country hid rururb econzone capital surveyr wta_hh_c wta_pop_c hhsize pc_hhdr pc_hh

**
gen DEMOGRAPHICS = "DEMOGRAPHICS SECTION"
merge 1:1 hid using "$data_sn/IHS2015_Indiv"
drop if _m==2
drop _m

**
gen HOUSING = "HOUSING SECTION"
merge 1:1 hid using `housing'
drop if _m==2
drop _m

**
gen ASSETS = "ASSETS SECTION"
merge 1:1 hid using `assets'
drop if _m==2
drop _m

**
gen AGRICULTURE = "AGRICULTURE SECTION"
merge 1:1 hid using `agriculture'
drop if _m==2
drop _m

**
gen LIVESTOCK = "LIVESTOCK SECTION"
merge 1:1 hid using `livestock'
drop if _m==2
drop _m

**
gen EMPLOYMENT = "EMPLOYMENT SECTION"
merge 1:1 hid using `employment'
drop if _m==2
drop _m


***Labelling the variable
lab var DEMOGRAPHICS  "DEMOGRAPHICS SECTION"
lab var HH_female "Household head head is female : 1 if yes, 0 if no"
lab var HH_age "Age of Household head"
lab var HH_celibat "Household head is single : 1 if yes, 0 if no"
lab var HH_maried "Household head is marie : 1 if yes, 0 if no"
lab var HH_widowed "Household head is widowed : 1 if yes, 0 if no"
lab var HH_divorce "Household head is divorced or separated : 1 if yes, 0 if no"
lab var age0_14 "people less than 15 years old : 1 if yes, 0 if no"
lab var age65plus "people more than 65 years old : 1 if yes, 0 if no"
lab var age15_64 "people between 15 years old and 64 years old : 1 if yes, 0 if no"
lab var Pop0_14 "number of people less than 15 years old in the Household"
lab var Pop65plus "number of people 65 years+ in the Household"
lab var Pop15_64 "number of people between 15 and 16 years old in the Household"
lab var tx_Dependance "Dependance ratio in the household"
lab var share_dep "Dependent share"
lab var age0_4 "people less than 5 years old : 1 if yes, 0 if no"
lab var age5_14 "people between 5 years old and 14 years old : 1 if yes, 0 if no"
lab var Pop0_4 "number of people less than 5 years old in the Household"
lab var Pop5_14 "number of people between 5 and 14 years old in the Household"
lab var Prop_0_4 "Proportion of people less than 5 years old in the household"
lab var Prop_5_14  "Proportion of people between 5 years old and 14 years in the household"
lab var Prop_15_64 "Proportion of people between 15 years and 64 years old in the household"
lab var Prop_65plus "Proportion of people more than 65 years old in the household"
lab var Pop0_3 "number of people less than 3 years old in the Household"
lab var Pop4_6 "number of people between 4 and 6 years old in the Household"
lab var Pop7_9 "number of people between 7 and 9 years old in the Household"
lab var Pop10_12 "number of people between 10 and 12 years old in the Household"
lab var Pop13plus "number of people 13 years+ in the Household"
lab var HH_size_1 "1 member household"
lab var HH_size_2_3 "2 to 3 members household"
lab var HH_size_4_5 "4 to 5 members household"
lab var HH_size_6 "6+ members household"
lab var HH_size_0_3 "0 to 3 members household"
lab var HH_size_4_7 "4 to 7 members household"
lab var HH_size_8_10 "8 to 10 members household"
lab var HH_size_11_13 "11 to 13 members household"
lab var HH_size_14 "14+ members household"

lab var EDUCATION  "EDUCATION SECTION"
lab var HH_noeduc "Household head has no education level : 1 if no education or preschool, 0 if not"
lab var HH_prim "Household head has a primary education level : 1 if primary, 0 if not"
lab var HH_sec "Household head has a secondary education level : 1 if secondary (lower or upper), 0 if not"
lab var HH_sup "Household head has a tertiairy education level : 1 if diploma (post-secondary) or university, 0 if not"
lab var Peop_Educ "Education level of the most educated in the household"
lab var Peop_Educ_noeduc "Most educated person in the household has no education level : 1 if no education or preschool, 0 if not"
lab var Peop_Educ_prim "Most educated person in the household has primary education level  : 1 if primary, 0 if not"
lab var Peop_Educ_sec"Most educated person in the household has secondary education level : 1 if primary, 0 if not"
lab var Peop_Educ_sup "Most educated person in the household has higher education level : 1 if diploma (post-secondary) or university, 0 if not"

lab var HEALTH "HEALTH SECTION"
lab var HH_disable "Household head has any form of disability: 1 if yes, 0 if not"
lab var HH_disable_visual "Household head has visual disability: 1 if yes, 0 if not"
lab var HH_disable_physical "Household head has moving/hand/feet steps disability: 1 if yes, 0 if not"

lab var HOUSING "HOUSING SECTION"
lab var occupancy_owner "household is owner of its place : 1 if yes, 0 if not"
lab var occupancy_renting "household is renting the place : 1 if yes, 0 if not"
lab var occupancy_free "household has the place for renting free : 1 if yes, 0 if not"
lab var occupancy_other "household has other type of occupancy status : 1 if yes, 0 if not"
lab var wall_cement "exterior wall is made of cement blocks/concrete : 1 if yes, 0 if not"
lab var wall_mud "exterior wall is made of mud/kirinting : 1 if yes, 0 if not"
lab var roof_thatch  "roof is made of thatch : 1 if yes, 0 if not"
lab var roof_ironsheet "roof is made of corrugated iron sheet (maybe corresponds to Metal/Tin) : 1 if yes, 0 if not"
lab var floor_earth  "floor is made of earth/mud : 1 if yes, 0 if not"
lab var floor_tiles "floor is made of tiles : 1 if yes, 0 if not"
lab var floor_cement "floor is made of cement/concrete : 1 if yes, 0 if not"
lab var light_elect "main lighting fuel is electricity (nawec or generator) : 1 if yes, 0 if not"
lab var light_solar "main lighting fuel is solar power : 1 if yes, 0 if not"
lab var light_candles "main lighting fuel is candles : 1 if yes, 0 if not"
lab var light_battery  "battery power light : 1 if yes, 0 if not"
lab var light_poor "Poor lighting source (lamp, candle, battery and other) : 1 if yes, 0 if not"
lab var cook_firewoodC "main cooking fuel is firewood collected : 1 if yes, 0 if not"
lab var cook_firewoodP "main cooking fuel is firewood purchased : 1 if yes, 0 if not"
lab var cook_charcoal "main cooking fuel is charcoal : 1 if yes, 0 if not"
lab var toilet_flush "main type of toilet is flush (piped, spetic, pit) : 1 if yes, 0 if not"
lab var toilet_pit "main type of toilet is pit (VIP, with slab, without slab) : 1 if yes, 0 if not"
lab var toilet_other "main type of toilet is other (bucket, open, private pan) : 1 if yes, 0 if not"
lab var toilet_shared "toilet is shared with other households : 1 if yes, 0 if not"
lab var water_piped  "main drinking water is piped into dwelling or coumpound : 1 if yes, 0 if not"
lab var water_psPipe "main drinking water is public stand pipe : 1 if yes, 0 if not"
lab var water_wellC "main drinking water is (un)protected in coumpound : 1 if yes, 0 if not"
lab var water_wellP "main drinking water is public well with or without pump : 1 if yes, 0 if not"
lab var disposal_burnt "garbage disposal via landfill/burry/burnt : 1 if yes, 0 if not"
lab var disposal_compost "garbage disposal via compsot : 1 if yes, 0 if not"
lab var disposal_collected "garbage disposal collected (municipal or private) : 1 if yes, 0 if not"
lab var disposal_dump "garbage disposal via public dump : 1 if yes, 0 if not"
lab var disposal_bush "garbage disposal via bush or open space : 1 if yes, 0 if not"
lab var dist_water "distance to water source (km)"


lab var ASSETS "ASSETS SECTION"
lab var mobile "Household has mobile phone : 1 if yes, 0 if not"
lab var landphone "Household has landline phone : 1 if yes, 0 if not"
lab var computer "Household has computer/laptop/tablet : 1 if yes, 0 if not"
lab var bicycle "Household has bicyle : 1 if yes, 0 if not"
lab var motorcycle "Household has motorcycle : 1 if yes, 0 if not"
lab var car "Household has car/van : 1 if yes, 0 if not"
lab var truck "Household has truck/lorry : 1 if yes, 0 if not"
lab var animal_cart "Household has Animal drawn cart  : 1 if yes, 0 if not"
lab var boat "Household has boat/canoe : 1 if yes, 0 if not"
lab var radio "Household has radio : 1 if yes, 0 if not"
lab var tv "Household has tv : 1 if yes, 0 if not"
lab var refrigerator "Household has refrigerator : 1 if yes, 0 if not"
lab var fan "Household has fan : 1 if yes, 0 if not"
lab var conditioner "Household has air conditioner : 1 if yes, 0 if not"

lab var AGRICULTURE "AGRICULTURE SECTION"
lab var nbr_land "Number of land cultivated by household"
lab var agric_hold "Household involved in land cultivation : 1 if yes, 0 if not"


lab var LIVESTOCK "LIVESTOCK SECTION"
/*
lab var livestock_own "Household (any member) owning livestock : 1 if yes, 0 if not"
lab var cattle "Number of cattle currently owned by household"
lab var sheep "Number of sheep currently owned by household"
lab var goats "Number of goat currently owned by household"
lab var pigs "Number of pigs currently owned by household"
lab var poultry "Number of poultry currently owned by household"
lab var horses "Number of horses currently owned by household"
lab var donkeys "Number of donkeys currently owned by household"
*/
lab var large_livestock "Number of large livestock (Horse donkey cattle) currently owned by household"
lab var medium_livestock "Number of medium livestock (goats pigs sheep) currently owned by household"

lab var EMPLOYMENT "EMPLOYMENT SECTION"
lab var HH_work "HH head is unemployed: 1 if yes, 0 if no"
lab var HH_work_employee "Work as an employee: 1 if yes 0 if no"
lab var HH_work_farm "Work on their own account on a farm: 1 if yes 0 if no"
lab var HH_work_business "Work on their own account or in a business enterprise: 1 if yes 0 if no"
lab var agriculture "work in agriculture sector"
lab var industries  "work in industry sector" 
lab var services "work in services sector"


***Saving
describe
save "$data_sn/PMT_IHS2020_harmonized",replace
erase "$data_sn/IHS2015_Indiv.dta"



/// PMT

*==========================================================
*Data checking 
*==========================================================

	//demographics
	su /*hhsize HH_female-Prop_65plus*/ HH_female HH_age HH_celibat HH_maried HH_widowed HH_divorce tx_Dependance /*Pop0_3 Pop4_6 Pop7_9 Pop10_12 Pop13plus*/ /*HH_size_1 HH_size_2_3 HH_size_4_5 HH_size_6*/ HH_size_0_3 HH_size_4_7 HH_size_8_10 HH_size_11_13 HH_size_14 [w=wta_pop_c]
	su HH_age
	replace HH_age = r(mean) if HH_age ==.m // 2 changes
	*
	gen HH_age2 = HH_age*HH_age /* Squared Age of Household head */
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
	su HH_noeduc-Peop_edu [w=wta_pop_c]
	local edu HH_noeduc HH_prim HH_sec HH_sup
	foreach var of  local edu {  // only 3 changes at most
		replace `var' = 0 if `var' ==.
	}

	global education /*HH_noeduc-HH_sup*/ HH_noeduc-HH_prim HH_sec_sup /*Peop_Educ_noeduc-Peop_Educ_sup*/ Peop_Educ_noeduc-Peop_Educ_prim Peop_Educ_sec_sup /**/ /* Pop_sec Pop_sup*/ Pop_noeduc Pop_prim  Pop_sec_sup

	//health
	su HH_disable HH_disable_visual HH_disable_physical [w=wta_pop_c]
	global health HH_disable HH_disable_visual HH_disable_physical

	//housing
	su occupancy_owner-dist_water [w=wta_pop_c]
	local house wall_cement wall_mud roof_thatch roof_ironsheet floor_earth floor_tiles floor_cement light_elect light_solar light_poor cook_firewoodC cook_firewoodP cook_charcoal toilet_flush toilet_pit toilet_other water_piped water_psPipe water_wellC water_wellP disposal_burnt disposal_compost disposal_collected disposal_dump disposal_bush
	foreach var of local house {  // 29 changes to zero at most
		replace `var' = 0 if `var' ==.
	}
	global housing occupancy_owner-occupancy_free wall_cement-light_solar light_poor-disposal_bush /**/ /*cook_charcoal-cook_charcoal waterpipe impwater imptoilet disposal_burnt-disposal_bush*/
	*global housing_ur occupancy_owner-light_solar light_poor-water_psPipe water_wellP-disposal_bush
	global housing2 occupancy_owner-occupancy_free wall_cement-light_solar light_poor-water_wellC disposal_burnt-disposal_bush 

	//asset
	su mobile-conditioner [w=wta_pop_c]
	local asset mobile landphone computer bicycle motorcycle car radio tv refrigerator fan conditioner
	foreach var of local asset {  // 3 changes to zero at most
		replace `var' = 0 if `var' ==.
	}
	global asset /*mobile landphone*/ computer bicycle motorcycle car radio tv /*refrigerator fan conditioner*/

	//agriculture 
	su nbr_land agric_hold [w=wta_pop_c]
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
	su large_livestock medium_livestock [w=wta_pop_c] 
	*global livestock medium_livestock large_livestock  
	global livestock log_medium_livestock log_medium_livestock 

	//employment
	su HH_work HH_work_employee HH_work_farm HH_work_business agriculture industries services [w=wta_pop_c] 
	global employment  /*HH_work*/ HH_work_employee HH_work_farm HH_work_business agriculture industries services /*Pop_not_work*/ 

	****
	svyset cluster [w=wta_pop_c]
	svy : mean $demographics $health $education $employment $housing $asset $agriculture $livestock 

	global vlist $demographics $health $education $employment $housing $asset $agriculture $livestock  /* final list of variable*/
	global vlist2 $demographics2 $health $education $employment $housing2 $asset $agriculture $livestock  /* final list of variable*/
	global vlist_ur $demographics $health $education $employment $housing_ur $asset $agriculture $livestock 



	gen double welfare = log(pc_hhdr)
	gen double log_pl_abs = log(18039.95)
	*replace wta_pop_c = round(wta_pop_c)
	

*==========================================================
***Model selection for National
*Two methods : (i) Regression by leaps and bounds, and (ii) LASSO
*==========================================================

	splitsample , generate(sample_nat) split(0.7 0.3) rseed(12345)  /*diving the sample into a training and validation sub samples */

	//
	****leaps and bounds
	vselect welfare $vlist if sample_nat==1 [aw=wta_pop_c], forward r2adj
	return list
	global vlist2=r(predlist)

	stepwise, /*pr(.0500001) pe(.05)*/ pr(.0999999) pe(.099999) : reg welfare $vlist2  [pw=wta_pop_c] if sample_nat==1
		matrix X = e(b)
		matrix X = X[1,1..`e(df_m)']
		global myvar: colnames X	
	*le global myvar contient les variables du modele national
	global myvar_mi $myvar

	reg welfare $myvar_mi [pw=wta_pop_c] if sample_nat==1
	estimates store l_bounds_nat
	*lassogof l_bounds_nat, over(sample_nat)




predict xb
	
rename xb PMT


keep hid PMT welfare
merge 1:1 hid using "$data_sn/GMB_IHS2020_E_hhsize.dta", nogen 

keep hid pc_hhdr pl_abs pl_ext pl_fd wta_hh_c ndfdecil ndecil hhsize rururb hhtexp wta_pop_c hhtexpdr hhtexpdr1 hhtexpdr2 PMT lga district welfare
ren hid hhid 
merge 1:1 hhid using "$data_sn/hhsize_18.dta", keep(3) nogen 
gen departement = district
gen geo_zzt = district
ren wta_hh_c hhweight
ren lga region	
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

use "$data_sn/Education General.dta", clear 
merge m:1 hid using "$data_sn/GMB_IHS2020_E_hhsize.dta", nogen keepusing(lga) keep(3) // this passage is just to clean some observation. 


*C8 attend or not during 2020/2021
gen attend = 1 if  s3aq11==1 // attend school during 2010-2011

gen pub_school=1 if   s3aq10==1  // attend Public school
gen pri_school=1 if   s3aq10 ==2 // attend private school 

**** Identify students by level

*-------------- Early Childhood Education 
**Public
gen     ben_pre_school= 0
replace ben_pre_school= 1 if s3aq12==0  & attend==1 & pub_school==1
***Private
gen     ben_pre_school_pri= 0
replace ben_pre_school_pri= 1 if s3aq12==0  & attend==1 & pri_school==1

*--------------Primaire
**Public
gen ben_primary=0
replace ben_primary= 1 if s3aq12==1 & attend==1 & pub_school==1  // CI, CP, CE1, CE2, CM1, CM2

**Private
gen ben_primary_pri=0
replace ben_primary_pri= 1 if s3aq12==1 & attend==1 & pri_school==1  // CI, CP, CE1, CE2, CM1, CM2

*--------------Secondaire 1 (Post Primaire) Général and Secondaire 1 (Post Primaire) Technique
**Public
gen ben_secondary_low=0
replace ben_secondary_low=1 if s3aq12==2 & attend==1 & pub_school==1  // 6ème 5ème 4ème 3ème

**Private
gen     ben_secondary_low_pri=0
replace ben_secondary_low_pri=1 if s3aq12==2 & attend==1 & pri_school==1  // 6ème 5ème 4ème 3ème

*--------------Secondaire 2 Général  and Secondaire 2 Technique
**Public
gen ben_secondary_up=0
replace ben_secondary_up=1 if  s3aq12==3 & attend==1 & pub_school==1  // 2nde 1ère Terminale

***Private
gen ben_secondary_up_pri=0
replace ben_secondary_up_pri=1 if s3aq12==3 & attend==1 & pri_school==1  // 2nde 1ère Terminale
*replace ben_secondary_up_pri=1 if s02q14==6 & attend==1 & pri_school==1  // 2nde 1ère Terminale
*--------------Combining into secondary and primary
**Public
gen     ben_secondary = 1 if (ben_secondary_low==1 | ben_secondary_up==1) & pub_school==1 

***Private
gen     ben_secondary_pri = 1 if (ben_secondary_low_pri==1 | ben_secondary_up_pri==1) & pri_school==1

*--------------Teritiary
**Public
gen     ben_tertiary=0
replace ben_tertiary=1 if s3aq12==4 & attend==1 & pub_school==1 // Supérieur 1è to 6 et+
replace ben_tertiary=1 if s3aq12==5 & attend==1 & pub_school==1 
replace ben_tertiary=1 if s3aq12==6 & attend==1 & pub_school==1 

***Private
gen     ben_tertiary_pri=0
replace ben_tertiary_pri=1 if s3aq12==4 & attend==1 & pri_school==1 // Supérieur 1è to 6 et+
replace ben_tertiary_pri=1 if s3aq12==5 & attend==1 & pri_school==1
replace ben_tertiary_pri=1 if s3aq12==6 & attend==1 & pri_school==1


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
                                                 
												 // WHAT SHOULD DO WITH THE ZEROS?? 
gen prepri_sec=(ben_pre_school== 1 | ben_primary==1 | ben_secondary == 1)												 
								 
*ren lga region	
ren hid hhid 											 


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






	
