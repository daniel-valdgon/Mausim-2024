/*============================================================================*\
 In-kind Transfers
 Authors: Gabriel Lombo
 Start Date: November 2024
 Update Date: 
\*============================================================================*/
 

	
set seed 123456789	
	
/*-------------------------------------------------------/
	1. Distances by region
/-------------------------------------------------------*/
	
*----- Read Data aun unique 
 
* Agglomerations
import delimited "$data_other/QGis/Agglomerations.csv", clear
	
gunique agglomerat

ren (agglomerat populati_8 built_up_3 voronoi_21) (id pop built_up voronoi)

keep id agglomer_1 pop built_up voronoi adm1_*

drop if pop == 0

tempfile agg
save `agg', replace	


* Health institutions
import delimited "$data_other/QGis/Health.csv", clear

ren latitude id2

drop if id2 == .

gunique id2

gduplicates tag id2, gen(dup)

bysort id2: gen count = _n

tab dup count
drop if count == 2
drop dup count

drop longitude 

tempfile health
save `health', replace	


* Matrix distances
import delimited "$data_other/QGis/Distances.csv", clear

ren (inputid targetid) (id id2)

gunique id id2 
gduplicates tag id id2, gen(dup)

tab dup

egen dist = min(distance), by(id id2)

drop distance dup
gduplicates drop

gunique id id2 


tempfile dist
save `dist', replace		
	
*----- Merge Data

merge m:1 id using `agg', gen(mr1) keep(3)
merge m:1 id2 using `health', gen(mr2) keep(3)

drop mr1 mr2
	
* Identifiers	
egen gr1 = group(id)
egen gr2 = group(id2)
	
gunique gr1 gr2

gen uno = 1
egen tag = tag(id)


*----- Analytics

* Preliminary statistics

tab1 typedorganismeexploitant formationsanitaire, m
sum *
tabstat dist, s(min mean p50 max) by(agglomer_1)

* Data Scope
gen h_type = .
replace h_type = 1 if formationsanitaire == "PS"
replace h_type = 2 if inlist(formationsanitaire, "CS", "H1", "H2", "H3")

*----- Indicators
local ref_dist 0 500 1000 5000 10000 50000 .
forvalues i = 1/6 {
	
	local j = `i' + 1
	local min : word `i' of `ref_dist'
	local max : word `j' of `ref_dist'

	
	forvalues k = 1/2 {
		
		gen dum_hc`i'_`k' = inrange(dist, `min', `max') & h_type == `k'
		
		egen id_n_hc`i'_`k' = sum(dum_hc`i'_`k'), by(id)
		gen id_d_hc`i'_`k' = id_n_hc`i'_`k' > 0 & id_n_hc`i'_`k' != .
		
		drop dum_hc`i'_`k'
		
	}
	
	egen id_nt_hc`i' = rowtotal(id_n_hc`i'_*)
	egen id_dt_thc`i' = rowtotal(id_d_hc`i'_*)
		
}

* Nearest distance
egen id_dist = min(dist), by(id)

gen id_c_dist = 0
replace id_c_dist = 1 if inrange(id_dist, 0, 150)
replace id_c_dist = 2 if inrange(id_dist, 150, 250) 
replace id_c_dist = 3 if inrange(id_dist, 250, 500) 
replace id_c_dist = 4 if inrange(id_dist, 500, 1000) 
replace id_c_dist = 5 if inrange(id_dist, 1000, 5000) 
replace id_c_dist = 6 if inrange(id_dist, 5000, 1000000) 


tab id_dist tag

* Group by Wilaya

keep if tag == 1
keep adm1_en adm1_pcode id*
gen uno = 1

gcollapse (mean) id_dist (max) id_c_dist id_dt_* id_d_hc* (sum) id_nt_* uno, by(adm1*) 

gen wilaya = adm1_en
replace wilaya = "Hodh charghy" if adm1_en == "Hodh Chargui"
replace wilaya = "Hodh Gharby" if adm1_en == "Hodh El Gharbi"
replace wilaya = "Dakhlett Nouadibou" if adm1_en == "Dakhlet Nouadhibou"
replace wilaya = "Tirs-ezemour" if adm1_en == "Tiris Zemmour"
*replace wilaya = "Inchiri" if adm1_en == "Inchiri"
replace wilaya = "Nouakchott" if adm1_en == "Nouakchott Nord"
replace wilaya = "Dakhlett Nouadibou" if adm1_en == "Dakhlet Nouadibou"


save "$presim/distances_indicators.dta", replace


/*-------------------------------------------------------/
	2. Survey
/-------------------------------------------------------*/

*----- Accessibility
use "$data_sn/Datain/Capital_Social_2019.dta", clear

* ID
tostring US_ORDRE A7, replace
gen len = length(A7)
replace A7 = "0" + A7 if len == 1
gen hhid = US_ORDRE + A7
destring hhid, replace  
 
gunique hhid

// Educ = 9, 10, Health = 6 hospital, 7 Health center 
keep if I0 == 7
keep hhid I6 I8 I10_1

tempfile cap_social
save `cap_social', replace


*----- Infrastructure
use "$data_sn/Datain/Distance_Infra_2019.dta", clear

* ID
tostring US_ORDRE A7, replace
gen len = length(A7)
replace A7 = "0" + A7 if len == 1
gen hhid = US_ORDRE + A7
destring hhid, replace  
 
gunique hhid

// Educ = 4, 5. Health = 6
keep if G_0 == 6

keep hhid G8 G9

tempfile dist_sy
save `dist_sy', replace


*----- Use of health service	
use "$data_sn/Datain/individus_2019.dta", clear

ren hid hhid

ren wilaya location
	
keep hhid A1 A2 A3 milieu location D*
order hhid A1 A2 A3 milieu location, first

merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize) nogen

merge m:1 hhid using `cap_social', nogen keep(3)
merge m:1 hhid using `dist_sy', nogen keep(3)

gen uno = 1

*----- Data review
* ID
gunique hhid D0

* Other Data
tab D8 [iw = hhweight], m
tab D8 I8 [iw = hhweight], row nofreq // 90% of consistency on the use on health
tab D8 I6 [iw = hhweight], row nofreq // 41% used health center but hasn't in the village
tab D8 G9 [iw = hhweight], m row nofreq 

local letter A B C D E F G H I J K L
forvalues i = 1/12 {
	
	local var : word `i' of `letter'

	gen sick`var' = D7`var' == "`var'"
}

tabm sick* [iw = hhweight], m row nofreq

* Health
tab D9 D8 [iw = hhweight], col nofreq
tab D9A D8 [iw = hhweight], col nofreq
 
tab D11AA [iw = hhweight]

tab D8 D13 [iw = hhweight], m row nofreq


* Expenses
sum D16-D21

egen exp_health = rowtotal(D16-D21)	
tabstat	exp_health, s(mean min max) by(D8)
gen exp_health_pos = exp_health>0

tab D11AA exp_health_pos  [iw = hhweight] if D8 == 1, m col nofreq

tab D8 [iw = hhweight], m

*----- Indicators Simulation

* Dummy use or not
* Dummy distance
* Level of use
* Level of distance

gen ht_use = D8 == 1
gen ht_pub = inlist(D9, 1, 2, 3, 4)
gen ht_times = D10
gen ht_dist = G9
egen ht_exp = rowtotal(D16-D21)	

* Insurance
gen cnam = D13 == 1


gcollapse (firstnm) A1 A2 A3 milieu (sum) ht_use ht_pub ht_times cnam (mean) ht_dist, by(hhid location)

merge 1:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize) nogen

decode A1, gen(wilaya) 

merge m:1 wilaya using "$presim/distances_indicators.dta", keep(1 3) gen(mr_dist)

*---- Analytics
tab ht_dist id_c_dist [iw = hhweight] if milieu == 1, m nofreq cell

tabstat id_d_hc*_1 [aw = hhweight], s(sum) by(wilaya)
tabstat id_d_hc*_2 [aw = hhweight], s(sum) by(wilaya)
tabstat id_nt_hc* [aw = hhweight], s(mean) by(wilaya)


forvalues i = 1/6 {
	tab wilaya id_d_hc`i'_1 [iw = hhweight], matcell(A`i')
	tab wilaya id_d_hc`i'_2 [iw = hhweight], matcell(B`i')

}

mat A = A1, A2, A3, A4, A5, A6
mat B = B1, B2, B3, B4, B5, B6

mat colnames A = 0 1 0 1 0 1 0 1 0 1 
mat colnames B = 0 1 0 1 0 1 0 1 0 1 

matlist A
matlist B


keep hhid location ht_use ht_pub ht_times ht_dist id_c_dist id_nt_hc1 id_nt_hc2 id_nt_hc3 id_nt_hc4 id_nt_hc5 id_nt_hc6 cnam


save "$presim/inkind_transfers.dta", replace


/*-------------------------------------------------------/
	3. Education
/-------------------------------------------------------*/


use "$data_sn/Datain/individus_2019.dta", clear

ren hid hhid

*----- Human Opportunity Index
* Definition of circumstances
gen female = B2 == 2
gen urban = milieu == 1

gen head_educ2 = C4N if B1 == 1
gen head_status2 = B5 if B1 == 1

mvencode head_educ2 head_status2, mv(0)

egen head_educ = max(head_educ2), by(hhid)
egen head_status = max(head_status2), by(hhid)
egen head_female = max(B2 == 2 & B1 == 1), by(hhid)



*keep hid C5 C8 C7N
*ren hid hhid 

merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize) nogen

tab C7N [iw = hhweight]
tab C7N [iw = hhweight], nol

gen public = C8 == 1

gen level_1 = C7N == 4 & public == 1
gen level_2 = C7N == 5 & public == 1
gen level_3 = C7N == 6 & public == 1
gen level_4 = C7N == 7 & public == 1
gen level_7 = C7N == inlist(C7N, 10, 11)  & public == 1
gen level_8 = C7N == 8  & public == 1
gen level_11 = C7N == inlist(C7N, 2, 3)  & public == 1
*gen level_12 = C7N == 1
gen level_13 = C7N == 9  & public == 1

keep hhid level* public milieu

save "$presim/inkind_transfers2.dta", replace





