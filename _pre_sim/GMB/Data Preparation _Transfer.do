/*
Author.   :  Madi Mangan 
Start date:  09 - 04 - 2024

Aim: create the necessary files for the PMT and beneficiary selection for transfer. 
*/






********************************************************************************
**** INDIVIDUAL - Section 1,2, 3, 4, 6 

*** Section 2 - Roster
use "$data_sn/IHS1 -  Hhold Roster.dta", clear
count 
renvars,l
count
duplicates drop
duplicates tag (settlement eanum select_hhold s1q1),gen(dup)  //check duplicate IDs.  11208
drop dup

clonevar select_hhold_dup  = select_hhold
//Household head name: MODOU BOYE
replace select_hhold = 100 if eanum == 63229 & select_hhold_dup == 11 & intervdate == 12022020
//Household head name: FARAMBA SANYANG
replace select_hhold = 100 if eanum == 75104 & select_hhold_dup == 85 & intervdate == 15072020
//Household head name: MALANG NJIE
replace select_hhold = 111 if eanum == 75104 & select_hhold_dup == 91 & intervdate == 18082020

duplicates tag ( settlement eanum select_hhold s1q1),gen(dup)
drop dup

replace settlement=35125  if settlement==1    & lga==3 & eanum==35115
replace settlement=75101  if settlement==12   & lga==7 & eanum==75106
replace settlement=70109  if settlement==70   & lga==7 & eanum==70113
replace settlement=41210  if settlement==4012 & lga==4 & eanum==41204
replace settlement=43115  if settlement==4311 & lga==4 & eanum==43108
drop select_hhold_dup

*use "$data\Stata\DataPART1\Hhold Roster.dta" , clear  //test file

label define lga 1 "Banjul"  2 "Kanifing"  3 "Brikama" 4 "Mansakonko"  5 "Kerewan"  ///
	6 "Kuntaur"  7 "Janjangbureh"  8 "Basse", modify
la val lga lga 

ta lga_name 
ta lga_name lga 
drop lga_name  //drop this as not useful

la define quarter  1 "Quarter 1"  2 "Quarter 2"  3 "Quarter 3"  4 "Quarter 4",replace 
la val quarter quarter

clonevar district1=district
replace district1=10   if district<=12
replace district1=20   if district>=20 & district<30
ta district1
ta district1 district
la define district1   10 "Banjul City Council"  20 "Kanifing Municipal Council"   /// 
  30 "Kombo North"  31 "Kombo South"  32 "Kombo Central"  33 "Kombo East"  34 "Foni Brefet"  ///
  35 "Foni Bintang Karanai"  36 "Foni Kansala"  37 "Foni Bondali"  38 "Foni Jarrol"  ///
  40 "Kiang West"  41 "Kiang Central"  42 "Kiang East"  43 "Jarra West"  44 "Jarra Central"  45 "Jarra East"  ///  
  50 "Lower Niumi"  51 "Upper Niumi"  52 "Jokadu"  53 "Lower Badibu"  54 "Central Badibu"  55 "Illiasa"  56 "Sabach Sanjar"  ///  
  60 "Lower Saloum"  61 "Upper Saloum"  62 "Nianija"  63 "Niani"  64 "Sami"  ///
  70 "Niamina Dankunku"  71 "Niamina West"  72 "Niamina East"  73 "Lower Fuladu West"  74 "Upper Fuladu West"  75 "Janjanbureh"  /// 
  80 "Jimara"  81 "Basse"  82 "Tumana"  83 "Kantora"  84 "Wuli West"  85 "Wuli East"  86 "Sandu", modify   
la val district1 district1  

la define district  10 "Banjul South"  11 "Banjul Central"  12 "Banjul North"  ///
	20 "Bakau"  21 "New Jeshwang"  22 "Sere Kunda Central"  23 "Sere Kunda East"  24 "Sere Kunda West"  ///  
	30 "Kombo North"  31 "Kombo South"  32 "Kombo Central"  33 "Kombo East"  34 "Foni Brefet"   ///
	35 "Foni Bintang Karanai"  36 "Foni Kansala"  37 "Foni Bondali"  38 "Foni Jarrol"  /// 
	40 "Kiang West"  41 "Kiang Central"  42 "Kiang East"  43 "Jarra West"  44 "Jarra Central"  45 "Jarra East"  /// 
	50 "Lower Niumi"  51 "Upper Niumi"  52 "Jokadu"  53 "Lower Badibu"  54 "Central Badibu"  55 "Illiasa"  56 "Sabach Sanjar"  ///
	60 "Lower Saloum"  61 "Upper Saloum"  62 "Nianija"  63 "Niani"  64 "Sami"  ///
	70 "Niamina Dankunku"  71 "Niamina West"  72 "Niamina East"  73 "Lower Fuladu West"  74 "Upper Fuladu West"  75 "Janjanbureh"  ///  
	80 "Jimara"  81 "Basse"  82 "Tumana"  83 "Kantora"  84 "Wuli West"  85 "Wuli East"  86 "Sandu", modify 
la val district district

drop name_distr //not useful 

drop s1q2  //name of respondent

la define area 1 "Urban"  2 "Rural", modify
la val area area 

la define more_hh_members 1 "Yes"  2 "No",modify 
la val more_hh_members more_hh_members

ta intervday intervmonth
 
ta intervyear,m 
ta intervmonth intervyear
replace intervyear=2021  if intervyear==2018 // That is probably an error because the survey was carry out fron February 2020 to January 2021

replace rec_type="PART 1 Section 1"
la var rec_type "PART 1 Section 1"

gen hid= string(int( settlement ),"%05.0f") + string(int( eanum ),"%05.0f") + string(int( select_hhold ),"%03.0f" ),before(lga)

la var quarter 			"Quarter"
la var lga              "Local Governemnt Area"
la var district         "District"
la var district1        "District (level of aggregation for analyses)"
la var settlement       "Settlement"
la var area             "Area"
la var eanum            "Eunumeration area" 
la var select_hhold     "Household number"
la var hid              "Unique HH identifier"
la var s1q1 			"S1Q1 - Member ID"
la var s1q3  			"S1Q3 - Sex"
la var s1q5a			"S1Q5A - [NAME] got a birth certificate from the Registrar's Office"
la var s1q5b			"S1Q5B - If not, what is the main reason?"
la var s1q6				"S1Q6 - What is [NAME]'s Relationship to Household Head"
la var s1q7				"S1Q7 - What is [NAME]'s Nationality (citizenship)?"
la var s1q8				"S1Q8 - What is [NAME]'s Ethinicity?"
la var other_s1q8 	    "S1Q8 - OTHER Ethnicity"
la var s1q17    		"S1Q17 - [NAME]'s Father industry of occupation"
la var s1q23    		"S1Q23 - [NAME]'s Mother industry of occupation"
la var more_hh_members	"Are there any other household member"
la var rec_type 		"PART A Section 1"


order hid lga quarter district district1 area settlement settlmnt_name eanum select_hhold rec_type
ren rec_type PT1_Sect_1
ren settlmnt_name settlement_name

sort hid s1q1 
ren s1q1 idnum 

*compress 
*save "$temp\Roster_0.dta", replace 


drop intervdate-interview_status number_of_hhold_members
ta s1q5_years  //one negative value. 10 Missing ages
replace s1q5_years = abs(s1q5_years)
gen valid=1
compress 
save "$data_sn/Hhold Roster.dta", replace 


********************************************************************************
*** SECTION 2 - HEALTH
use "$data_sn/IHS1 - sect2a - Health for all the Hhold Members.dta" , clear 
count 
renvars,l
count
duplicates drop
duplicates tag (settlement eanum select_hhold idnum),gen(dup)  //check duplicate IDs.  11208
ta dup 
drop dup 


clonevar select_hhold_dup  = select_hhold
//Household head name: MODOU BOYE
replace select_hhold = 100 if eanum == 63229 & select_hhold_dup == 11 & (name=="MODOU BOYE" | name=="IDA SECKA" | name=="MOD SARR" | name=="ALAGIE KEBBA SECKA" | name=="ISATOU BOYE" | name=="BABUCARR BOYE")
//Household head name: FARAMBA SANYANG
replace select_hhold = 100 if eanum == 75104 & select_hhold_dup == 85 & (name=="FARAMBA SANYANG" | name=="DANDANG DAMPHA" | name=="MUSA DARBOE" | name=="DANDANG JAMMEH" | name=="KADDY DARBOE")
//Household head name: MALANG NJIE
replace select_hhold = 111 if eanum == 75104 & select_hhold_dup == 91 & (name=="MALANG NJIE" | name=="MAMA TOURAY" | name=="SAINEY NJIE" | name=="SANNA NJIE" | name=="SARJO NJIE" | name=="DAWDA NJIE" | name=="SULAYMAN NJIE" | name=="SARJO NJIE")

duplicates tag ( settlement eanum select_hhold idnum),gen(dup)
ta dup 
drop if dup==1
drop dup

replace settlement=35125  if settlement==1    & lga==3 & eanum==35115
replace settlement=75101  if settlement==12   & lga==7 & eanum==75106
replace settlement=70109  if settlement==70   & lga==7 & eanum==70113
replace settlement=41210  if settlement==4012 & lga==4 & eanum==41204
replace settlement=43115  if settlement==4311 & lga==4 & eanum==43108
drop select_hhold_dup settlmnt_name area

gen PT1_Sect_2="PART 1 Section 2"
la var PT1_Sect_2 "PART 1 Section 2"

drop name sex age name_distr

order settlement eanum select_hhold PT1_Sect_2
sort settlement eanum select_hhold idnum 

gen hid= string(int( settlement ),"%05.0f") + string(int( eanum ),"%05.0f") + string(int( select_hhold ),"%03.0f" ),before(lga)

la var s2aq2         		"S2AQ2 - For the last two weeks has [NAME] been sick/injured?"
la var s2aq3_main    		"S2AQ3_MAIN - During the last 2 weeks, what symptoms has [NAME] suffered from?"
la var other_s2aq3_main		"S2AQ3 - OTHER main illness [NAME] suffered from last 2 weeks"
la var s2aq3_second			"S2AQ3_SECOND - During the last 2 weeks, what symptoms has [NAME] suffered from?"
la var s2aq4_main       	"S2AQ4_MAIN - Did [NAME] consult health provider for illness/injury last 2 weeks"
la var s2aq4_second     	"S2AQ4_SECOND - Did [NAME] consult health provider for illness/injury last 2 weeks"
la var s2aq5_main       	"S2AQ5_MAIN - Main reason [NAME] did not visit a health provider"
la var other_s2aq5_second 	"S2AQ5 - OTHER Main reason [NAME] did not visit a health provider"
la var s2aq6_second  		"S2AQ6_SECOND - Last 2 weeks who diagnosed [NAME]'s sickness/injury?"
la var s2aq7 				"S2AQ7 - Days last 2 weeks was [NAME] too ill not to do usual activities"
la var s2aq8 				"S2AQ8 - Did [NAME] visit health provider for any other health related reason"
la var s2aq9				"S2AQ9 - What was the reason for [NAME]'s visit?"
la var s2aq10 				"S2AQ10 - What type of facility did [NAME] visit?"
la var s2aq11				"S2AQ11 - Where is the location of facility visited by [NAME]?"
la var s2aq12				"S2AQ12 - Wistance from [NAME]'s house to health care facility visited?"
la var s2aq13				"S2AQ13 - How long did [NAME] take to travel for the consultation?"
la var s2aq14				"S2AQ14 - What was the main mode of transport to the facility used by [NAME]?"
la var other_s2aq14			"S2AQ14 - OTHER mode of transport to facility used by [NAME]?"
la var s2aq15 				"S2AQ15 - How much did [NAME] pay to travel to the health care facility?"
la var s2aq16				"S2AQ16 - How long did [NAME] wait for the services to be rendered?"
la var s2aq17				"S2AQ17 - Was [NAME] satisfied with the service offered?"
la var s2aq18a				"S2AQ18A - First reason [NAME] not satisfied with the health provider services?"
la var other_s2aq18a		"S2AQ18A - OTHER first reason [NAME] was not satisfied with the provider?"
la var s2aq18b				"S2AQ18B - Second reason [NAME] not satisfied with the health provider services"
la var other_s2aq18b		"S2AQ18B - OTHER second reason [NAME] not satisfied with the health provider services"
la var s2aq18c 				"S2AQ18C - Third reason [NAME] not satisfied with the health provider services?"
la var other_s2aq18c 		"S2AQ18C - OTHER third main reason why name was not satisfied with the provider?"
la var s2aq19				"S2AQ19 - Did [NAME] pay for the health care services provided?"
la var s2aq20a  			"S2AQ20A - Consultations"
la var s2aq20b				"S2AQ20B - Dental fees"
la var s2aq20c				"S2AQ20C - injection"
la var s2aq20d 				"S2AQ20D - lab fees"
la var s2aq20e				"S2AQ20E - X-ray"
la var s2aq20f				"S2Aq20F - Scanning"
la var s2aq20g				"S2AQ20G - Ambulance services"
la var s2aq20h				"S2AQ20H - Child birth/delivery"
la var s2aq20i				"S2AQ20I - Immunization"
la var s2aq20j 				"S2AQ20J - Medicines (Prescriptions and over-the counter)"
la var s2aq20k				"S2AQ20K - Other charges"
la var s2aq20l				"S2AQ20L - Total expenditure"
renvars s2aq24_1 other_s2aq24_1 s2aq24_2 other_s2aq24_2 / s2aq24_main other_s2aq24_main s2aq24_second other_s2aq24_second
la var s2aq24_main			"S2AQ24_MAIN - Main reason for by passing the facility nearest household"
la var other_s2aq24_main	"S2AQ24_MAIN - OTHER main reason for by passing the facility nearest household"
la var s2aq24_second		"S2AQ24_SECOND - Second reason for by passing the facility nearest household"
la var other_s2aq24_second	"S2AQ24_SECOND - OTHER second reason for by passing the facility nearest household"
la var s2aq27_medical_facility "S2AQ27A - Hospitalisation (medical facility)"
la var s2aq27_traditional_healer "S2AQ27B - Hospitalisation (traditional healer)" 
renvars s2aq27_medical_facility s2aq27_traditional_healer / s2aq27a s2aq27b

compress 
save "$data_sn/Health for all the Hhold Members.dta", replace



use "$data_sn/IHS1 - Sect2c - Disability.dta" , clear 
count 
renvars,l
count
duplicates drop
duplicates tag (settlement eanum select_hhold idnum),gen(dup)  //check duplicate IDs.  11208
ta dup 
drop dup 

clonevar select_hhold_dup  = select_hhold
//Household head name: MODOU BOYE
replace select_hhold = 100 if eanum == 63229 & select_hhold_dup == 11 & (name=="MODOU BOYE" | name=="IDA SECKA" | name=="MOD SARR" | name=="ALAGIE KEBBA SECKA" | name=="ISATOU BOYE" | name=="BABUCARR BOYE")
//Household head name: FARAMBA SANYANG
replace select_hhold = 100 if eanum == 75104 & select_hhold_dup == 85 & (name=="FARAMBA SANYANG" | name=="DANDANG DAMPHA" | name=="MUSA DARBOE" | name=="DANDANG JAMMEH" | name=="KADDY DARBOE")
//Household head name: MALANG NJIE
replace select_hhold = 111 if eanum == 75104 & select_hhold_dup == 91 & (name=="MALANG NJIE" | name=="MAMA TOURAY" | name=="SAINEY NJIE" | name=="SANNA NJIE" | name=="SARJO NJIE" | name=="DAWDA NJIE" | name=="SULAYMAN NJIE" | name=="SARJO NJIE")

duplicates tag ( settlement eanum select_hhold idnum),gen(dup)
ta dup 
drop dup

replace settlement=35125  if settlement==1    & lga==3 & eanum==35115
replace settlement=75101  if settlement==12   & lga==7 & eanum==75106
replace settlement=70109  if settlement==70   & lga==7 & eanum==70113
replace settlement=41210  if settlement==4012 & lga==4 & eanum==41204
replace settlement=43115  if settlement==4311 & lga==4 & eanum==43108
gen hid= string(int( settlement ),"%05.0f") + string(int( eanum ),"%05.0f") + string(int( select_hhold ),"%03.0f" ),before(lga)
drop lga-name_distr settlmnt_name area intervdate- number_of_hhold_members name sex age s1q5_months select_hhold_dup s2cmoree 

order settlement eanum select_hhold 
sort settlement eanum select_hhold idnum 
 
compress 
save "$data_sn/Health_2c.dta", replace 

********************************************************************************
*** SECTION 3 - EDUCATION 
use "$data_sn/IHS1 - SECT3A - Education General.dta" , clear 
count 
renvars,l
duplicates drop
ren s3aq1 idnum 
duplicates tag (settlement eanum select_hhold idnum),gen(dup)  //check duplicate IDs.  11208
ta dup 
drop dup 

ren s3aq1_name name 

clonevar select_hhold_dup  = select_hhold
//Household head name: MODOU BOYE
replace select_hhold = 100 if eanum == 63229 & select_hhold_dup == 11 & (name=="MODOU BOYE" | name=="IDA SECKA" | name=="MOD SARR" | name=="ALAGIE KEBBA SECKA" | name=="ISATOU BOYE" | name=="BABUCARR BOYE")
//Household head name: FARAMBA SANYANG
replace select_hhold = 100 if eanum == 75104 & select_hhold_dup == 85 & (name=="FARAMBA SANYANG" | name=="DANDANG DAMPHA" | name=="MUSA DARBOE" | name=="DANDANG JAMMEH" | name=="KADDY DARBOE")
//Household head name: MALANG NJIE
replace select_hhold = 111 if eanum == 75104 & select_hhold_dup == 91 & (name=="MALANG NJIE" | name=="MAMA TOURAY" | name=="SAINEY NJIE" | name=="SANNA NJIE" | name=="SARJO NJIE" | name=="DAWDA NJIE" | name=="SULAYMAN NJIE" | name=="SARJO NJIE")

duplicates tag ( settlement eanum select_hhold idnum),gen(dup)
ta dup 
drop if dup==1 & idnum==.  //all infor missing 
drop dup
gen hid= string(int( settlement ),"%05.0f") + string(int( eanum ),"%05.0f") + string(int( select_hhold ),"%03.0f" ),before(lga)
drop lga-name_distr settlmnt_name area intervdate-number_of_hhold_members name select_hhold_dup

replace rec_type="PART 1 Section 3"
la var rec_type "PART 1 Section 3"

order settlement eanum select_hhold rec_type
ren rec_type PT1_Sect_3
sort settlement eanum select_hhold idnum  

compress 
save "$data_sn/Education General.dta", replace 



********************************************************************************
*** SECTION 8 - HOUSING

use "$data_sn/IHS1 - Sect8A - Housing.dta" , clear 
count 
renvars,l
duplicates drop

ta s8aq1,m
 
clonevar select_hhold_dup  = select_hhold
//Household head name: MODOU BOYE
replace select_hhold = 100 if eanum == 63229 & select_hhold_dup == 11 & intervdate == 12022020
//Household head name: FARAMBA SANYANG
replace select_hhold = 100 if eanum == 75104 & select_hhold_dup == 85 & intervdate == 15072020
//Household head name: MALANG NJIE
replace select_hhold = 111 if eanum == 75104 & select_hhold_dup == 91 & intervdate == 18082020

duplicates tag ( settlement eanum select_hhold),gen(dup)
ta dup
drop if dup==1  //all roster data missing infor 
drop dup

replace settlement=35125  if settlement==1    & lga==3 & eanum==35115
replace settlement=75101  if settlement==12   & lga==7 & eanum==75106
replace settlement=70109  if settlement==70   & lga==7 & eanum==70113
replace settlement=41210  if settlement==4012 & lga==4 & eanum==41204
replace settlement=43115  if settlement==4311 & lga==4 & eanum==43108

gen PT1_Sect_8="PART 1 Section 8"
la var PT1_Sect_8 "PART 1 Section 8"
gen hid= string(int( settlement ),"%05.0f") + string(int( eanum ),"%05.0f") + string(int( select_hhold ),"%03.0f" ),before(lga)
drop lga-name_distr area intervdate-number_of_hhold_members select_hhold_dup settlmnt_name

order settlement eanum select_hhold PT1_Sect_8 
sort settlement eanum select_hhold 

compress 
save "$data_sn/housing.dta", replace 


// create the dataset household size 18: number of household members at least 18 years old. 
use "$data_sn/Stata/PART A Section 1_2_3_4_6-Individual level.dta", clear
gen al =1 if s1q11a>=18
replace al =0 if al ==. 
egen hhsize_18 = sum(al), by(hid)
label var hhsize_18 "Number of household members aged 18 and older"

collapse (mean) hhsize_18, by(hid)
ren hid hhid
save "$data_sn/hhsize_18.dta", replace 
