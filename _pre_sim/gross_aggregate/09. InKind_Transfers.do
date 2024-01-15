*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico
* Date: June 2020
* Version: 1.0
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------

/********** Education *******/


use "$datain/s02_me_SEN2018.dta", clear
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


gen am_pre_school_pub = ${Edu_montantPrescolaire}  if ben_pre_school==1   & pub_school==1
gen am_primary_pub    = ${Edu_montantPrimaire}     if ben_primary==1      & pub_school==1
gen am_secondary_pub  = ${Edu_montantSecondaire}   if ben_secondary==1    & pub_school==1
gen am_tertiary_pub  = ${Edu_montantSuperieur}    if ben_tertiary==1     & pub_school==1
 
collapse (sum)  am_pre_school_pub am_primary_pub am_secondary_pub am_tertiary_pub, by(hhid)
egen education_inKind=rowtotal(am_pre_school_pub am_primary_pub am_secondary_pub am_tertiary_pub)

tempfile Transfers_InKind
save `Transfers_InKind'

*save  "$dta/Transfers_InKind.dta", replace





