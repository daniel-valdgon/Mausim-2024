

/*
Author     : Gabriel Lombo
Start date : 24 April 2024
Last Update: 24 April 2024 

Objective  : Presimulation for Direct Transfer for the purpose of fiscal microsimulation to study the incidence of Direct transfer
           **I compile and adopt the key characteristics of the household necessary for assignment of social programmes 
*/

*global path			"/Users/gabriellombomoreno/Documents/WorldBank/Mausim_2024"
*global data_sn 		"${path}/01_data/1_raw/MRT"    
*global presim 		"${path}/01_data/2_pre_sim/MRT"    

set seed 123456789

*==========================================================
*Group of variables : 		socio-demographics
*==========================================================

*----- Data on household location 
 
use "$data_sn/Datain/individus_2019.dta", clear

* Variables
global head B1 // s1q6
global sex B2 // s1q3
global age B4 // $s1q5_years
global status B5 // s1q10

* Assigning categories
gen HH_female = ($sex==2)
gen HH_age = $age

gen HH_celibat =($status==1) if $status ~=.	
gen HH_maried = ($status==2 | $status==3) if $status ~=.
gen HH_divorce =($status==4) if $status ~=.
gen HH_widowed =($status==5) if $status ~=. 

gen age0_14 =($age<=14)
gen age65plus =($age>=65 & $age!=.) 
gen age15_64 =(inrange($age,15,64))

bysort hid: egen Pop0_14 =sum(age0_14)
bysort hid: egen Pop65plus =sum(age65plus)
bysort hid : egen Pop15_64 =sum(age15_64)

gen tx_Dependance = (Pop0_14 + Pop65plus)/Pop15_64

//Pantaleo proposed categories
gen age0_3 = ($age <=3)
gen age4_6 =(inrange($age,4,6))
gen age7_9 =(inrange($age,7,9))
gen age10_12 =(inrange($age,10,12))
gen age13plus =($age>=13 & $age!=.)

bysort hid: egen Pop0_3 =sum(age0_3)
bysort hid: egen Pop4_6 =sum(age4_6)
bysort hid: egen Pop7_9 =sum(age7_9)
bysort hid: egen Pop10_12 =sum(age10_12)
bysort hid: egen Pop13plus =sum(age13plus)

* Household size
gen n=1
egen taille=total(n), by(hid)
drop n
gen share_dep=(Pop0_14+Pop65plus)/taille /*Dependent share*/

gen age0_4 =($age<=4)
gen age5_14 =(inrange($age,5,14))

bysort hid : egen Pop0_4 =sum(age0_4)
bysort hid: egen Pop5_14 =sum(age5_14)

gen Prop_0_4 = Pop0_4/taille
gen Prop_5_14 = Pop5_14/taille
gen Prop_15_64 = Pop15_64 /taille
gen Prop_65plus = Pop65plus/taille

***HH size categories
gen HH_size_1 = (taille ==1)
lab var HH_size_1 "1 members household"
gen HH_size_2 = (taille ==2)
lab var HH_size_2 "2 member household"
gen HH_size_3 = (taille ==3)
lab var HH_size_3 "3 memberss household"
gen HH_size_4 = (taille ==4)
lab var HH_size_4 "4 members household"
gen HH_size_5 = (taille ==5)
lab var HH_size_5 "5 members household"
gen HH_size_2_3 = (taille>=2 & taille<=3)
lab var HH_size_2_3 "2 to 3 members household"
gen HH_size_4_5 = (taille>=4 & taille<=5)
lab var HH_size_4_5 "4 to 5 members household"
gen HH_size_6 = (taille>=6)
lab var HH_size_6 "6 members household"

***HH size categories (Pantaleo)
gen HH_size_0_3 = (taille>=0 & taille<=3)
lab var HH_size_0_3 "0 to 3 members household"
gen HH_size_4_7 = (taille>=4 & taille<=7)
lab var HH_size_4_7 "4 to 7 members household"
gen HH_size_8_10 = (taille>=8 & taille<=10)
lab var HH_size_8_10 "8 to 10 members household"
gen HH_size_11_13 = (taille>=11 & taille<=13)
lab var HH_size_11_13 "11 to 13 members household"
gen HH_size_14 = (taille >=14)
lab var HH_size_14 "14 members household"



*==========================================================
*Groupe de variable : 			Education
*==========================================================

gen EDUCATION = "EDUCATION SECTION"

global no_school C2
global level C4N

replace $level = 0 if $no_school ==5 /*Assigning no education to people who never attended a school*/
gen HH_noeduc=($level==0)  if $head ==1 & $level ~=. /* Household head has no education level : 1 if no education or preschool, 0 if not */
gen HH_prim=inrange($level, 2,5)  if $head ==1 & $level ~=. /* Household head has a primary education level : 1 if primary, 0 if not */
gen HH_sec=inrange($level, 6,7)  if $head ==1 & $level ~=. /* Household head has a secondary education level : 1 if secondary (lower or upper), 0 if not */
gen HH_sup=inrange($level, 8,12)  if $head ==1 & $level ~=. /* Household head has a tertiairy education level : 1 if diploma (post-secondary) or university, 0 if not */

gen HH_sec_sup = (HH_sec==1 | HH_sup==1)
lab var HH_sec_sup "Household head has a secondary or tertiairy education level : 1 if diploma (post-secondary) or university, 0 if not"

bysort hid : egen Pop_noeduc =sum($level == 0) 						/* number of people with no education */
bysort hid : egen Pop_prim =sum(inrange($level, 2,5)) 						/* number of people with primary education */
bysort hid : egen Pop_sec =sum(inrange($level, 6,7))				/* number of people with secondary education */
bysort hid : egen Pop_sup =sum(inrange($level, 8,12))				/* number of people with higher education */
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

bysort hid : egen Peop_Educ =max($level) /* Education level of the most educated in the household */

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

*==========================================================
*Group of variables : 		Health
*==========================================================

gen HEALTH = "HEALTH SECTION"

global 	disable D5

gen HH_disable = ($disable==0) if $disable ~=. & $head ==1 /* Household head has any form of disability: 1 if yes, 0 if not */
gen HH_disable_visual = ($disable ==3) if $disable ~=. & $head ==1 /* Household head has visual disability: 1 if yes, 0 if not */
gen HH_disable_physical = ($disable ==2 | $disable ==5) if $disable ~=. & $head ==1 /* Household head has moving/hand/feet steps disability: 1 if yes, 0 if not */

keep if $head == 1
keep hid HH_female-HH_disable_physical
save "$data_sn/hh_head.dta",replace


*==================================== ======================
*Group of variables : 		Housing
*==========================================================

use "$data_sn/Datain/Distance_Infra_2019.dta", clear

* Household id
tostring US_ORDRE A7, replace
gen len = length(A7)
replace A7 = "0" + A7 if len == 1
gen hid = US_ORDRE + A7
destring hid, replace  

keep if G_0 == 1 // Water distance
keep hid G9

tempfile water_dist
save `water_dist'


use "$data_sn/Datain/menage_2019.dta", clear
merge 1:1 hid using `water_dist', nogen keep(2 3)

global owner F1 
global wall G2 
global roof G1 
global floor G3
global light G7
global fuel G6
global toilet G5
global toilet_share G5C
global water G4
global water_dist G9


*global disposal I2 // Variable not found

gen occupancy_owner = ($owner ==1 | $owner ==2) if $owner ~=. /* household is owner of its place : 1 if yes, 0 if not */
gen occupancy_renting = ($owner ==3) if $owner ~=. /* household is renting the place : 1 if yes, 0 if not */
gen occupancy_free = ($owner ==4) if $owner ~=. /* household has the place for renting free : 1 if yes, 0 if not */
gen occupancy_other = ($owner >=5) //if $owner ~=. /* household has other type of occupancy status : 1 if yes, 0 if not */


gen wall_cement = ($wall ==4) if $wall ~=.  /* exterior wall is made of cement blocks/concrete : 1 if yes, 0 if not */
gen wall_mud = ($wall ==4) if $wall ~=.  /* exterior wall is made of mud/kirinting : 1 if yes, 0 if not */

gen roof_thatch  = ($roof ==2) if $roof~=. /* roof is made of thatch : 1 if yes, 0 if not */
gen roof_ironsheet = ($roof ==5) if $roof~=.  /* roof is made of corrugated iron sheet (maybe corresponds to Metal/Tin) : 1 if yes, 0 if not */

gen floor_earth  = ($roof ==1) if $roof ~=. /* floor is made of earth/mud : 1 if yes, 0 if not */
gen floor_tiles = ($roof ==5) if $roof ~=. /* floor is made of tiles : 1 if yes, 0 if not */
gen floor_cement= ($roof ==6) if $roof ~=. /* floor is made of cement/concrete : 1 if yes, 0 if not */

gen light_elect = ($light ==1 | $light ==2) if $light ~=. /* main lighting fuel is electricity (nawec or generator) : 1 if yes, 0 if not */
gen light_solar = ($light ==7) if $light ~=. /* main lighting fuel is solar power : 1 if yes, 0 if not */
gen light_candles = ($light ==5) if $light ~=. /* main lighting fuel is candles : 1 if yes, 0 if not */
gen light_battery  = inlist($light, 6,8) if $light ~=. /* battery power light : 1 if yes, 0 if not */
gen light_poor = inlist($light, 3,4,9) /* Poor lighting source (lamp, candle, battery and other) : 1 if yes, 0 if not */

//Important: a small change here
gen cook_firewoodC = ($fuel==1) if $fuel ~=. /* main cooking fuel is firewood (no distinction between collecter or purchased) : 1 if yes, 0 if not */

gen cook_firewoodP = ($fuel==2) if $fuel ~=. /* main cooking fuel is firewood purchased : 1 if yes, 0 if not */
gen cook_charcoal = ($fuel==3) if $fuel ~=. /* main cooking fuel is charcoal : 1 if yes, 0 if not */

gen toilet_flush = ($toilet >=11 & $toilet <=16) if $toilet ~=. /* main type of toilet is flush (piped, spetic, pit) : 1 if yes, 0 if not */
gen toilet_pit = ($toilet >=21 & $toilet <=23) if $toilet ~=. /* main type of toilet is pit (VIP, with slab, without slab) : 1 if yes, 0 if not */
gen toilet_other = ($toilet >=31 & $toilet <=51) if $toilet ~=. /* main type of toilet is other (bucket, open, private pan) : 1 if yes, 0 if not */
gen toilet_shared = ($toilet_share ==1) /* toilet is shared with other households : 1 if yes, 0 if not */

gen water_piped  = ($water ==11 | $water ==12 | $water ==13) if $fuel ~=. /* main drinking water is piped into dwelling or coumpound : 1 if yes, 0 if not */
gen water_psPipe = ($water ==14 | $water ==15) if $water ~=. /* main drinking water is public stand pipe : 1 if yes, 0 if not */
gen water_wellC = ($water >=20 & $water <=22) if $fuel ~=. /* main drinking water is (un)protected in coumpound : 1 if yes, 0 if not */
//Change
gen water_wellP = ($water >=31 & $water <=35) if $water ~=. /* main drinking water is public well with  : 1 if yes, 0 if not */

gen dist_water = $water_dist  /* distance to water source (km) */

/*
gen disposal_burnt  = (s8aq15==1 | s8aq15==2) if s8aq15~=.  /* garbage disposal via landfill/burry/burnt : 1 if yes, 0 if not */
gen disposal_compost = (s8aq15==3) if s8aq15~=.  /* garbage disposal via compsot : 1 if yes, 0 if not */
gen disposal_collected = (s8aq15>=5 & s8aq15<=7) if s8aq15~=. /* garbage disposal collected (municipal or private) : 1 if yes, 0 if not */
gen disposal_dump = (s8aq15==9) if s8aq15~=.  /* garbage disposal via public dump : 1 if yes, 0 if not */
gen disposal_bush = (s8aq15==10) if s8aq15~=.  /* garbage disposal via bush or open space : 1 if yes, 0 if not */
*/


keep hid occupancy_owner-dist_water
tempfile housing
save `housing', replace



*==========================================================
*Group of variables :  		Household assets
*==========================================================

use "$data_sn/Datain/Equipement_2019.dta", clear

* Household id
tostring US_ORDRE A7, replace
gen len = length(A7)
replace A7 = "0" + A7 if len == 1
gen hid = US_ORDRE + A7
destring hid, replace  



global article F16_N
global has F16A

keep if inlist($article, 3,4,5,7,8,9,11,13,14,15,16)

keep hid ${article} ${has}
rename $has ${has}_
reshape wide $has , i(hid) j($article)

*gen mobile = ($has ==7)                  /*Household has mobile phone : 1 if yes, o if not */
gen landphone = (${has}_7 ==1)               /*Household has landline phone : 1 if yes, o if not*/
gen computer = (${has}_11 ==1)     /*Household has computer/laptop/tablet : 1 if yes, o if not*/
*gen bicycle = ($has ==15)                 /*Household has bicyle : 1 if yes, o if not*/
gen motorcycle = (${has}_15 ==1)              /*Household has motorcycle : 1 if yes, o if not*/
gen car = inlist(${has}_13, 1)                     /*Household has car/van : 1 if yes, o if not*/
gen truck = (${has}_14 ==1)                   /*Household has truck/lorry : 1 if yes, o if not*/
gen animal_cart = (${has}_16 ==1)             /*Household has Animal drawn cart  : 1 if yes, o if not*/
*gen boat = ($article ==1)                    /*Household has boat/canoe : 1 if yes, o if not*/
gen radio = (${has}_5 ==1)     				 /*Household has radio : 1 if yes, o if not*/
gen tv = (${has}_4 ==1)                      /*Household has tv : 1 if yes, o if not*/
gen refrigerator = (${has}_3 ==1)            /*Household has refrigerator : 1 if yes, o if not*/
gen fan = (${has}_9 ==1)                     /*Household has fan : 1 if yes, o if not*/
gen conditioner = (${has}_8 ==1)             /*Household has air conditioner : 1 if yes, o if not*/

keep hid landphone-conditioner
tempfile assets
save `assets', replace


*==========================================================
*Group of variables :  		Agriculture
*==========================================================


use "$data_sn/Datain/individus_2019.dta", clear

global hold_land F2_1
global land F2_2

bys hid: egen nbr_land =max($land) /*Number of land cultivated by household*/
keep hid $hold_land nbr_land
drop if $hold_land ==. //
ta $hold_land
ta nbr_land
ta nbr_land if $hold_land==2 
replace nbr_land =0 if $hold_land==2 
gen agric_hold = ($hold_land==1) /*Household involved in land cultivation : 1 if yes, o if not*/

egen tag = tag(hid)
keep if tag==1

keep hid agric_hold nbr_land

tempfile agriculture
save `agriculture', replace


use "$data_sn/Datain/individus_2019.dta", clear


* F8 ganado vacuno y camellos, cattle
* F10 ovejas y cabras, sheep, goats
* F12 burros y caballos, horses, oxen, donkeys
* F14 Aves de corral, birds
* No pigs in the survey

global cattle F8
global sheep F10
global horses F12
global birds F14


gen horses = $horses
gen sheep = $sheep
gen cattle = $cattle
gen birds = $birds

*Large: horses oxen donkeys cattle
gen large_livestock = horses + cattle
replace large_livestock=0 if large_livestock==.

*Medium : sheep goats pigs
gen medium_livestock = sheep + birds
replace medium_livestock=0 if medium_livestock==.

collapse (max) medium_livestock large_livestock, by(hid)

keep hid medium_livestock large_livestock

tempfile livestock
save `livestock', replace


*==========================================================
*Group of variables :  		Employment 
*==========================================================

use "$data_sn/Datain/individus_2019.dta", clear

global work E1
global employee E10
global entreprise E11
global head B1


keep if $head ==1

***Worked as an employee, or own account in farm or enterprise (added temp absent): 1 if yes, 0 if not
//HH is unemployed : 1 if yes
gen HH_work = $work ==1

gen HH_work_employee = ($employee ==1)

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
*Group of variables :  		Shocks & Food insubsistency 
*==========================================================

*set comma pd

use "$data_sn/Datain/individus_2019.dta", clear

global worry SA1
global nofood SA4
global time_drought SA5 // Mars to juin
global reason_drought SA6

global shocks "worry nofood time_drought reason_drought SAvar7 SAvar8 SAvar9 SAvar10 SAvar11 SAvar12 SAvar13 SAvar15" 


gen worry = $worry == 1
gen nofood = $nofood == 1
gen time_drought = ${time_drought}_3 == 1 | ${time_drought}_4 == 1 | ${time_drought}_5 == 1 | ${time_drought}_6 == 1
gen reason_drought = ${reason_drought}_A == 1 | ${reason_drought}_B == 1 | ${reason_drought}_C == 1 | ${reason_drought}_A == 2 | ${reason_drought}_B == 2 | ${reason_drought}_C == 2 | ${reason_drought}_A == 8 | ${reason_drought}_B == 8 | ${reason_drought}_C == 8

ren SA_8 SA8

forvalues i = 7/13 {
	gen SAvar`i' = SA`i' == 1
}

gen SAvar15 = SA15 == 1 


/*
gen prog_2 = (PS4A == 2 | PS4B == 2 | PS4C == 2)
tab prog_2 nofood [iw = hhweight], m row
tab prog_2 nofood [iw = hhweight] if milieu == 2, m row
tab nofood milieu [iw = hhweight], m row
tabm SA5* [iw = hhweight], m row nol nofreq
tab1 $shocks [iw = hhweight], m
*/

foreach x of global shocks {
	egen hh_`x' = max(`x'), by(hid)
}

keep hid $shocks
gduplicates drop

tempfile shocks
save `shocks', replace


* Elmaouna

use "$data_sn/Datain/Equipement_2019.dta", clear

tostring US_ORDRE A7, replace
gen len = length(A7)
replace A7 = "0" + A7 if len == 1
gen hid = US_ORDRE + A7
destring hid, replace  

keep if inlist(F16_CODE, 6,8,9,11,12,13,14,15,17)

egen equipe = max(F16A == 1), by(hid)

keep hid equipe
gduplicates drop

tempfile assets2
save `assets2', replace

use "$data_sn/Datain/individus_2019.dta", clear
merge m:1 hid using `assets2', nogen keep(1 3)


global occupation E10
global equipments equipe
global habitation G0
global adults B4


gen occupation = inrange($occupation, 1, 7)
gen equipments = $equipments == 1
gen habitation = inrange($habitation, 1, 3)
gen adults = inrange($adults, 18, 65)

gcollapse (max) occupation equipments habitation (sum) adults, by(hid)


merge 1:1 hid using `agriculture', nogen keep(1 3)
merge 1:1 hid using `livestock', nogen keep(1 3)

ren hid hhid
merge 1:1 hhid using "$presim/01_menages.dta", nogen keep(3) keepusing(hhsize hhweight)

gen ratio = medium_livestock / hhsize

gen elmaouna = 1
replace elmaouna = 0 if occupation == 1
replace elmaouna = 0 if equipments == 1
replace elmaouna = 0 if habitation == 1
replace elmaouna = 0 if adults > 2
replace elmaouna = 0 if hhsize > 21

replace elmaouna = 0 if ratio > 1 & medium_livestock > 7 & large_livestock > 1


ren hhid hid

save "$data_sn/elmaouna.dta", replace

keep hid elmaouna

tempfile elmaouna
save `elmaouna', replace

*==========================================================
*Finalizing the dataset
*==========================================================

use "$data_sn/Datain/menage_2019.dta", clear

gen cluster = US_ORDRE

keep hid idmen wilaya moughataa commune milieu cluster

ren hid hhid

merge 1:1 hhid using "$presim/01_menages.dta", nogen keep(3) keepusing(hhsize hhweight pcexp)

ren hhid hid

**
gen DEMOGRAPHICS = "DEMOGRAPHICS SECTION"
merge 1:1 hid using "$data_sn/hh_head.dta", keep(1 3) nogen

**
gen HOUSING = "HOUSING SECTION"
merge 1:1 hid using `housing', keep(1 3) nogen

**
gen ASSETS = "ASSETS SECTION"
merge 1:1 hid using `assets', keep(1 3) nogen


**
gen AGRICULTURE = "AGRICULTURE SECTION"
merge 1:1 hid using `agriculture', keep(1 3) nogen


**
gen LIVESTOCK = "LIVESTOCK SECTION"
merge 1:1 hid using `livestock', keep(1 3) nogen

**
gen EMPLOYMENT = "EMPLOYMENT SECTION"
merge 1:1 hid using `employment', keep(1 3) nogen

**
merge 1:1 hid using `shocks', keep(1 3) nogen
merge 1:1 hid using `elmaouna', keep(1 3) nogen


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
*lab var disposal_burnt "garbage disposal via landfill/burry/burnt : 1 if yes, 0 if not"
*lab var disposal_compost "garbage disposal via compsot : 1 if yes, 0 if not"
*lab var disposal_collected "garbage disposal collected (municipal or private) : 1 if yes, 0 if not"
*lab var disposal_dump "garbage disposal via public dump : 1 if yes, 0 if not"
*lab var disposal_bush "garbage disposal via bush or open space : 1 if yes, 0 if not"
lab var dist_water "distance to water source (km)"


lab var ASSETS "ASSETS SECTION"
*lab var mobile "Household has mobile phone : 1 if yes, 0 if not"
lab var landphone "Household has landline phone : 1 if yes, 0 if not"
lab var computer "Household has computer/laptop/tablet : 1 if yes, 0 if not"
*lab var bicycle "Household has bicyle : 1 if yes, 0 if not"
*lab var motorcycle "Household has motorcycle : 1 if yes, 0 if not"
lab var car "Household has car/van : 1 if yes, 0 if not"
lab var truck "Household has truck/lorry : 1 if yes, 0 if not"
lab var animal_cart "Household has Animal drawn cart  : 1 if yes, 0 if not"
*lab var boat "Household has boat/canoe : 1 if yes, 0 if not"
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


describe
save "$data_sn/PMT_EPCV_harmonized",replace


************


use "$data_sn/Datain/menage_2019.dta", clear

keep hid wilaya moughataa commune milieu A10*

ren hid hhid

merge 1:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight hhsize) keep(3)

ren hhid hid

merge 1:m hid using "$data_sn/Datain/individus_2019.dta", gen(mr_id) keepusing(B1 B2 B4 B5 PS* C*) //keep(2 3)

keep hid A* B1 B2 B4 B5 wilaya moughataa commune milieu hhweight hhsize PS1 PS2 PS4* PS5* PS6* PS7 C*

global progi prog_1 prog_2 prog_3 prog_4 prog_5 prog_6


global hh_prog hh_prog_1 hh_prog_2 hh_prog_3 hh_prog_4 hh_prog_5 hh_prog_6
 
global prog_amount hh_prog_amount_1 hh_prog_amount_2 hh_prog_amount_3 hh_prog_amount_4 hh_prog_amount_5 hh_prog_amount_6

global prog_amount_max hh_prog_amount_max_1 hh_prog_amount_max_2 hh_prog_amount_max_3 hh_prog_amount_max_4 hh_prog_amount_max_5 hh_prog_amount_max_6

forvalues i = 1/6 {
	gen prog_`i' = (PS4A == `i' | PS4B == `i' | PS4C == `i')
	egen hh_prog_`i' = max(prog_`i'), by(hid)
	
	gen prog_amount_`i' = PS7 if prog_`i' == 1
	egen hh_prog_amount_`i' = total(prog_amount_`i'), by(hid)
	
	egen hh_prog_amount_max_`i' = max(prog_amount_`i'), by(hid)
}

egen tag = tag(hid)

tabstat $progi [aw = hhweight], s(sum)
tabstat $hh_prog [aw = hhweight] if tag == 1, s(sum)

egen prog_n = rowtotal($progi)

keep hid hhweight hhsize wilaya moughataa commune milieu hh_prog*



egen hh_prog_n = rowtotal($hh_prog)
egen hh_prog_amount_n = rowtotal($prog_amount)
egen hh_prog_amount_max_n = rowtotal($prog_amount_max)

gen hh_prog = hh_prog_n>0

gduplicates drop

save "$data_sn/program_EPCV.dta",replace


*==========================================================
*Data checking 
*==========================================================



use "$data_sn/PMT_EPCV_harmonized", clear

	//demographics
	su hhsize HH_female-Prop_65plus HH_female HH_age HH_celibat HH_maried HH_widowed HH_divorce tx_Dependance /*Pop0_3 Pop4_6 Pop7_9 Pop10_12 Pop13plus*/ /*HH_size_1 HH_size_2_3 HH_size_4_5 HH_size_6*/ HH_size_0_3 HH_size_4_7 HH_size_8_10 HH_size_11_13 HH_size_14 [w=hhweight]
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

	svyset cluster [w=hhweight]
	svy : mean $demographics $health $education $employment $housing $asset $agriculture $livestock $shocks

	global vlist $demographics $health $education $employment $housing $asset $agriculture $livestock $shocks /* final list of variable*/
	global vlist2 $demographics2 $health $education $employment $housing2 $asset $agriculture $livestock $shocks /* final list of variable*/
	global vlist_ur $demographics $health $education $employment $housing_ur $asset $agriculture $livestock $shocks

	gen double welfare = log(pcexp)

*==========================================================
***Model selection for National
*Two methods : (i) Regression by leaps and bounds, and (ii) LASSO
*==========================================================

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
	
*** Logit on observable programs

	merge 1:1 hid using "$data_sn/program_EPCV.dta", keep(3) keepusing(hh_prog_1 hh_prog_2 hh_prog_3) nogen
	
* Program 1 - Tekavoul CCT	
	
	*reg hh_prog_2 $vlist 
		
				
forvalues i = 1/3 {
	
	gen Ahh_prog_`i' = 0 if  hh_prog_`i' == 1
	replace Ahh_prog_`i' = 1 if  hh_prog_`i' == 0
	
	drop hh_prog_`i'
	ren Ahh_prog_`i' hh_prog_`i'
	
	vselect hh_prog_`i' $vlist if sample_nat==1 [aw=hhweight], forward r2adj
	return list
	
	global vlist2=r(predlist)

	stepwise, pr(.0999999) pe(.099999) : reg hh_prog_`i' $vlist2  [pw=hhweight] if sample_nat==1
	
	matrix X = e(b)
	matrix X = X[1,1..`e(df_m)']
	
	global myvar: colnames X	

	global myvar_mi $myvar

	reg hh_prog_`i' $myvar_mi [pw=hhweight] if sample_nat==1
	estimates store l_bounds_nat
	
	predict xb_`i'
	rename xb_`i' PMT_`i'
	
	egen min = min(PMT_`i'), by(wilaya)
	egen max = max(PMT_`i'), by(wilaya)
	
	*replace PMT_`i' = min-1 if hh_prog_`i' == 0
	*replace PMT_`i' = max if milieu == 1
	*replace PMT_`i' = max if large_livestock > 0
	*replace PMT_`i' = max if medium_livestock > 0

	drop min max
}	


			
ren hid hhid 

keep hhid PMT* elmaouna welfare wilaya moughataa commune milieu hhsize hhweight

gen departement = wilaya
gen geo_zzt = wilaya
gen region = wilaya


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




use "$data_sn/Datain/individus_2019.dta", clear

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
*ren lga region	
ren wilaya region
ren hid hhid 											 

keep hhid region ben* PS* 

save "$data_sn/program_EPCV_indiv.dta", replace




keep hhid region ben*


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






	
