

/*
Author:			Gabriel Lombo
Start date: 	24 April 2024
Last Update: 	22 June 2024

Note:		 	Validation of Administrative data with the survey
Sources: 		1. PER
				2. BOOST, Taazour
			
Figures:		1. Tekavoul 
					a) 0.1% - 2019; 0.2% - 2021 : GDP expenditures - PER 
					b) 0.06% - 2019; 0.16% - 2021 : GDP expenditures - BOOST
				2. School lunches 
					a) 120.000 students
				3. Food transfers
*/

global path			"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mauritania/Mausim_2024"
global data_sn 		"${path}/01_data/1_raw/MRT"    
global presim 		"${path}/01_data/2_pre_sim/MRT"    
global data_out    	"${path}/01_data/4_sim_output"
global xls_out    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx"

global GDP 2958000 // MRO


/*------------------------------------------------
* Food Consumption Score - FCS
------------------------------------------------*/

use "${data_out}/output_VF_MRT_Ref.dta", clear

sum *

tabstat am_BNSF1 am_BNSF2 rev_universel am_Cantine rev_pubstu [aw = hhweight], s(mean sum)



gen uno = 1

tab yd_deciles_pc [iw = hhweight] if am_BNSF1>0
tab yd_deciles_pc [iw = hhweight] if am_BNSF2>0
tab yd_deciles_pc [iw = hhweight] if rev_universel>0
tab yd_deciles_pc [iw = hhweight] if am_Cantine>0

egen cash_transf = rowtotal(am_BNSF1 am_BNSF2 am_Cantine)
	
tabstat cash_transf, s(mean sum) by(yd_deciles_pc)	


*----- Read Data
ren hhid hid 
merge 1:1 hid using "$data_sn/program_EPCV.dta", nogen keep(3)

ren hid hhid
merge 1:m hhid using "$data_sn/program_EPCV_indiv.dta" , nogen keep(3)

egen tag = tag(hhid)


forvalues i = 1/6 {
	gen prog_`i' = (PS4A == `i' | PS4B == `i' | PS4C == `i')
	gen prog_amount_`i' = PS7 if prog_`i' == 1
}

tabm prog_1 prog_2 prog_3 prog_4 prog_5 prog_6 [iw = hhweight] , col nofreq

forvalues i = 1/6 {
	*tab yd_deciles_pc [iw = hhweight] if prog_`i' ==1, matcell(A`i') 
	tab yd_deciles_pc [iw = hhweight] if hh_prog_`i' ==1 & tag ==1, matcell(B`i') 
}

* YMP pc
_ebin ymp_pc [aw=hhweight], nq(10) gen(deciel_ymp)

forvalues i = 1/6 {
	tab deciel_ymp [iw = hhweight] if hh_prog_`i' ==1 & tag ==1, matcell(B`i') 
}

tabstat hh_prog_1 hh_prog_2 hh_prog_3 hh_prog_4 hh_prog_5 hh_prog_6 hh_prog_n [aw = hhweight] if tag == 1, s(sum) by(deciel_ymp)

tabstat hh_prog_1 hh_prog_2 hh_prog_3 hh_prog_4 hh_prog_5 hh_prog_6 hh_prog_n [aw = hhweight] if tag == 1, s(sum) by(yd_deciles_pc)

tabstat ymp_pc yd_pc [aw = hhweight] if tag == 1, s(sum) by(deciel_ymp)

tabstat ymp_pc yd_pc [aw = hhweight] if tag == 1, s(sum) by(yd_deciles_pc)


* Individuals
tab yd_deciles_pc [iw = hhweight] if prog_1==1 | prog_2==1 | prog_3==1 | prog_4==1 | prog_5==1 | prog_6==1, matcell(C1)

tab yd_deciles_pc [iw = hhweight] if prog_1==1 | prog_2==1 | prog_3==1, matcell(C2)

* Households
tab yd_deciles_pc [iw = hhweight] if (hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1 | hh_prog_4==1 | hh_prog_5==1 | hh_prog_6==1) & tag == 1, matcell(C3)
tab yd_deciles_pc [iw = hhweight] if (hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1) & tag == 1, matcell(C4)



mat A = A1, A2, A6
mat B = B1, B2, B6
mat C = C1, C2, C3, C4

matlist A
matlist B
matlist C

mat T = A, B, C
matlist T


tab tag [iw = hhweight] if hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1 | hh_prog_4==1 | hh_prog_5==1 | hh_prog_6==1

tab tag [iw = hhweight] if hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1



/*-------------------------------------------------------/
	4. Absolute and Relative Incidence
/-------------------------------------------------------*/

global proj_1 "VF_MRT_Ref"
global policy "am_BNSF1 am_BNSF2 am_Cantine am_elmaouna"
global numscenarios 1

forvalues scenario = 1/$numscenarios {

	*-----  Absolute Incidence
	import excel "$xls_out", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="benefits" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_ymp" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	rename value v_
	drop if decile ==0
	
	reshape wide v_, i(decile) j(variable) string

	// keep decile //*_yd

	foreach var in $policy2 {
		egen ab_`var' = sum(`var')
		gen in_`var' = `var'*100/ab_`var'
	}

	keep decile in_*

	tempfile abs
	save `abs', replace

	*-----  Relative Incidence
	import excel "$xls_out", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="netcash" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_ymp" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	replace value = value*(-100) if value < 0
	replace value = value*(100) if value >= 0
	rename value v_

	drop if decile ==0

	reshape wide v_, i(decile) j(variable) string
	keep decile *_yd

	*order decile $policy2

	merge 1:1 decile using `abs', nogen
	
	gen scenario = `scenario'
	order scenario, first
	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace

}

clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}

export excel "$xls_out", sheet(Fig_2) first(variable) sheetmodify 





/*------------------------------------------------
* Programs
------------------------------------------------*/

*----- Read Data
use "$data_sn/program_EPCV.dta", clear

ren hid hhid

merge 1:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight hhsize) keep(3)

merge 1:m hhid using "$presim/07_educ.dta", nogen keep(3)






*----- Read Data
use "$data_sn/program_EPCV.dta", clear

ren hid hhid

merge 1:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight hhsize) keep(3)

merge 1:m hhid using "$data_sn/program_EPCV_indiv.dta" , nogen keep(3)

egen tag = tag(hhid)
gen uno = 1



forvalues i = 1/6 {
	gen prog_`i' = (PS4A == `i' | PS4B == `i' | PS4C == `i')
	gen prog_amount_`i' = PS7 if prog_`i' == 1
}

tabm prog_1 prog_2 prog_3 prog_4 prog_5 prog_6 [iw = hhweight]

tab uno [iw = hhweight] if prog_1==1 | prog_2==1 | prog_3==1 | prog_4==1 | prog_5==1 | prog_6==1
tab uno [iw = hhweight] if prog_1==1 | prog_2==1 | prog_3==1

tabm hh_prog_1 hh_prog_2 hh_prog_3 hh_prog_4 hh_prog_5 hh_prog_6 [iw = hhweight] if tag==1

tab tag [iw = hhweight] if hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1 | hh_prog_4==1 | hh_prog_5==1 | hh_prog_6==1
tab tag [iw = hhweight] if hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1



tab region [aw = hhweight] if tag == 1, m 

tab commune [aw = hhweight], m 


*----- Tekavoul
sum PS7 if hh_prog_1 == 1, d

tabstat hh_prog_1 hh_prog_amount_1 [aw = hhweight] if tag == 1, s(sum) by(wilaya) save

local ben = r(StatTotal)[1,1]
local spend = r(StatTotal)[1,2]/1000000

di "Survey has " round(`ben') " households beneficieres; " round(`spend') " millions of MRO spending; " round(`spend' / $GDP * 100, 0.01) " spending as % GDP"


*----- School feeding programs
egen max = max(PS4B == 9)

sum PS7 if PS4A == 3 & PS4B == 9, d // 4.250 MRU 


* Total
tabstat PS4A PS7 [aw = hhweight] if PS4A == 3 , s(sum) by(region)

* Students
tabstat hh_prog_amount_max_3 [aw = hhweight] if tag == 1, s(p10 p25 p50 p75 p90 mean sd) by(region)

tabstat PS7  [aw = hhweight]  if PS4A == 3 & PS4B == 6, by(region) s(p25 p50 p75 mean sd sum)

bysort hhid : egen n = count(uno) if PS4A == 3

tabstat PS7  [aw = hhweight] if PS4A == 3, by(region) s(p10 p25 p50 p75 p90 mean sd count)


tab region [iw = hhweight] if ben_primary==1 & milieu == 2 & inlist(region, 1, 3, 10) 
// Regional distribugion and beneficiaries


*----- Food Transfers
sum PS7 if PS4A == 2 & PS4B == 9, d // 4.250 MRU 

tabstat PS7 if PS4A == 2 & PS4B == 9 & wilaya == 1, by(hhsize) s(mean p50)

tab prog_2 [aw = hhweight]




tabstat hh_prog_amount_2 [aw = hhweight] if tag == 1 & region == 1, s(min max mean p25 p50 p75 count) by(hhsize) save

tabstat hh_prog_amount_2 [aw = hhweight] if tag == 1 & hh_prog_2==1, s(mean p50 count) by(commune)

tabstat hh_prog_amount_2 [aw = hhweight] if tag == 1 & hh_prog_2==1, s(p10 p25 p50 p75 p90 mean sd)  by(hhsize)

tabstat PS7 [aw = hhweight] if  PS4A==2 & hhsize == 1, s(p10 p25 p50 p75 p90 mean sd count)  by(region)


****
tabstat hh_prog_amount_2 [aw = hhweight] if tag == 1 & hh_prog_2==1 & hhsize ==1, s(p10 p25 p50 p75 p90 mean sd count)  by(region)
tabstat hh_prog_amount_2 [aw = hhweight] if tag == 1 & hh_prog_2==1 & hhsize ==2, s(p10 p25 p50 p75 p90 mean sd count)  by(region)
tabstat hh_prog_amount_2 [aw = hhweight] if tag == 1 & hh_prog_2==1 & hhsize ==5, s(p10 p25 p50 p75 p90 mean sd count)  by(region)

gen prog_2 = (PS4A == 2 | PS4B == 2 | PS4C == 2)

bysort hhid : egen count = count(uno) if prog_2 == 1


tab prog_2 count [iw = hhweight]

tab hhsize region [iw = PS7] if prog_2==1 & count==1

tab hhsize region [iw = hh_prog_amount_max_2] if tag == 1 & hh_prog_2==1 & count==1


// Hipotesis, beneficio mensual de 375

*----- Elmaouna



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

keep hid occupation equipments habitation adults PS*

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
keep hid elmaouna

tempfile elmaouna
save "$data_sn/el.dta", replace




*********************

* A lunch
use "$presim/05_purchases_hhid_codpr.dta", clear

tab codpr if codpr == 99
gen depan_pc = round(depan / hhsize)

tabstat depan_pc if codpr == 99, s(p50  mean)

sum  if decile_expenditure == 1, d


****


use "$data_sn/Datain/menage_2019.dta", clear

keep hid wilaya moughataa commune milieu A10*

ren hid hhid

merge 1:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight hhsize) keep(3)

ren hhid hid

merge 1:m hid using "$data_sn/Datain/individus_2019.dta", gen(mr_id) keepusing(B1 B2 B4 B5 PS* C*) //keep(2 3)

keep hid A* B1 B2 B4 B5 wilaya moughataa commune milieu hhweight hhsize PS1 PS2 PS4* PS5* PS6* PS7 C*


forvalues i = 1/6 {
	gen prog_`i' = (PS4A == `i' | PS4B == `i' | PS4C == `i')
	egen hh_prog_`i' = max(prog_`i'), by(hid)
	
	gen prog_amount_`i' = PS7 if prog_`i' == 1
	egen hh_prog_amount_`i' = total(prog_amount_`i'), by(hid)
	
	egen hh_prog_amount_max_`i' = max(prog_amount_`i'), by(hid)
}


egen tag = tag(hid)






*keep hid hhweight hhsize wilaya moughataa commune milieu hh_prog*

global prog hh_prog_1 hh_prog_2 hh_prog_3 hh_prog_4 hh_prog_5 hh_prog_6 
global prog_amount hh_prog_amount_1 hh_prog_amount_2 hh_prog_amount_3 hh_prog_amount_4 hh_prog_amount_5 hh_prog_amount_6

global prog_amount hh_prog_amount_max_1 hh_prog_amount_max_2 hh_prog_amount_max_3 hh_prog_amount_max_4 hh_prog_amount_max_5 hh_prog_amount_max_6

egen hh_prog_n = rowtotal($prog)
egen hh_prog_amount_n = rowtotal($prog_amount)
egen hh_prog_amount_max_n = rowtotal($prog_amount_max)

gen hh_prog = hh_prog_n>0

gduplicates drop

save "$data_sn/program_EPCV.dta",replace


**************

tab PS4A

*tabstat PS7 if PS5A == 12 & PS4A == 1, by(moughataa)

tabstat PS7 if PS5A == 1, by(PS4A)


* HH
egen tag = tag(hid)
gen uno = 1

tab PS4A [iw = hhweight] if tag == 1, m
tab PS4B [iw = hhweight] if tag == 1, m
tab PS4C [iw = hhweight] if tag == 1, m

gsort hid -tag
egen max = max(PS4B==9), by(hid)

gen chief = B1==1

forvalues i = 1/6 {
	gen prog_`i' = (PS4A == `i' | PS4B == `i' | PS4C == `i')
	egen hh_prog_`i' = max(prog_`i'), by(hid)
	
	gen prog_amount_`i' = PS7 if prog_`i' == 1
	egen hh_prog_amount_`i' = max(prog_amount_`i'), by(hid)
	
	drop prog_`i' prog_amount_`i'
}

svdbf

/*
gen n_prog = 0
replace n_prog = 1 if inrange(PS4A, 1, 6) & PS4B == 9
replace n_prog = 2 if inrange(PS4A, 1, 6) & inrange(PS4B, 1, 6) & PS4C == 9
replace n_prog = 3 if inrange(PS4A, 1, 6) & inrange(PS4B, 1, 6) & inrange(PS4C, 1, 6)

egen hh_n_prog = max(n_prog), by(hid)
*/



egen hh_prog_n = rowtotal($prog)
egen hh_prog_amount_n = rowtotal($prog_amount)

gen hh_prog = hh_prog_n>0

*gduplicates tag hid , gen(dup)



egen sum_transf = sum(PS7), by(hid)

tab hh_prog_n [iw = hhweight] if tag == 1

tabm hh_prog $prog [iw = hhweight] if tag == 1, m row
tabm hh_prog $prog [iw = hhweight] if tag == 1, m row

tab hh_prog_1 [iw = hhweight]

br if hid == 23206
br if wilaya == 3 & PS7 == 60000


tabstat hh_prog_n hh_prog_amount_n [aw = hhweight] if tag == 1, s(mean) by(wilaya) 

tabstat hh_prog_n hh_prog_amount_n [aw = hhweight] if tag == 1, s(sum) by(wilaya) 


forvalues i = 1/3 {

	tabstat hh_prog_`i' hh_prog_amount_`i' [aw = hhweight] if tag == 1, s(mean) by(wilaya) save

	tabstat hh_prog_`i' hh_prog_amount_`i' [aw = hhweight] if tag == 1, s(sum) by(wilaya) save
}

* scholar food program
tab C4N [iw = hhweight] // 5 primaria

gen primary = C4N == 5
egen hh_primary = max(primary), by(hid)
egen hh_primary_tot = total(primary), by(hid)

tabstat  [aw = hhweight] if tag == 1 & milieu == 2 & hh_primary>0, s(mean median sum)  by(wilaya) 


tab  hh_primary_tot hh_prog_3 if tag == 1 & milieu == 2, m

br hid hh_primary_tot hh_prog_3 C4N PS4A* if hh_prog_3




tab hh_primary [iw = hhweight] if tag == 1 & milieu == 2 & hh_primary>0




tabstat hh_prog_3 hh_prog_amount_3  [aw = hhweight] if tag == 1, s(mean median sum)  by(wilaya) 


tabstat hh_prog_3 hh_prog_amount_3 [aw = hhweight] if tag == 1 & wilaya == 3, s(mean sum)  by(hhsize)


br A* hid hhsize wilaya moughataa commune PS4A PS5A PS6A PS7 hh_prog_3 hh_prog_amount_3 if hh_prog_3==1

tab PS4A

tabstat hh_prog_1 hh_prog_amount_1 [aw = hhweight] if tag == 1 & wilaya == 3, s(mean sum)  by(A10M)

tabstat hh_prog_1 hh_prog_amount_1 [aw = hhweight] if tag == 1 & wilaya == 3, s(mean sum)  by(A10M)




set dp comma











