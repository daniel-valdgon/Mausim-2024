

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


*==========================================================
*Group of variables : 		Direct transfers
*==========================================================

* A lunch
use "$presim/05_purchases_hhid_codpr.dta", clear

tab codpr if codpr == 99
gen depan_pc = round(depan / hhsize)

tabstat depan_pc if codpr == 99, s(p50  mean)

sum if decile_expenditure == 1 


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


keep hid hhweight hhsize wilaya moughataa commune milieu hh_prog*

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











