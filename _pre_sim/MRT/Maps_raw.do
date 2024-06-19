/*============================================================================================
 ======================================================================================

	Project:		Subsidies tables and Admin comparison
	Author:			Gabriel Lombo 
	Creation Date:	Apr 12, 2024
	Modified:		
	Note: 			Extra tables, graphs and maps
============================================================================================
============================================================================================*/

* Pckg
*ssc install spmap
*ssc install shp2dta
*ssc install mif2dta

* Data 
use "$presim/08_subsidies_elect_adj.dta", clear

merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight) 

keep if codpr == 376

* Admin Data comparison
gen all = 1
gen kwh_m = consumption_electricite/12
gen kwh_b = consumption_electricite/6

gen bill_m = achats_net_subind/12
gen bill_b = achats_net_subind/6

cap drop bill_b2

sum bill_b, d
gen bill_b2 = bill_b
replace bill_b2 = . if bill_b2 > r(p99) & type_client


tabstat all achats_net_subind bill* consumption_electricite kwh_* [aw = hhweight] if inlist(type_client, 1, 2), s(p50 mean sum) by(type_client)
 

* Maps
gen kwh_d = kwh_m if domestic == 1 
gen kwh_s = kwh_m if domestic == 0 

gen depan_d = depan/12 if domestic == 1 
gen depan_s = depan/12 if domestic == 0 

gen dom = domestic == 1
gen soc = domestic == 0

mvencode kwh_d kwh_s depan_d depan_s dom soc, mv(0) override

* Admin
global var A1
global n 1 // A1-1, A2-2, A3-4

gcollapse (mean) kwh kwh_d kwh_s depan_d depan_s dom soc [iw = hhweight], by($var)

tostring $var, gen(name)

gen len = length(name)

replace name = "0" + name if len == $n

tempfile stats 
save `stats', replace 


* Create maps

shp2dta using "$data_sn/shapes/mrt_admbnda_adm1_ansade_20240327", database("$data_sn/mrtdb") coordinates("$data_sn/mrtcoord") genid(id) replace

use "$data_sn/mrtdb", clear

gen name = substr(ADM1_PCODE, 3, 4) // Admin 1
*gen name = substr(ADM2_PCODE, 3, 5) // Admin 2
*gen name = substr(ADM3_PCODE, 3, 7) // Admin 3

merge m:1 name using `stats', gen(mr_coor) 

* Gen variables
gen per_dom = dom / (dom + soc)

gduplicates tag name, gen(dup)

spmap kwh using "$data_sn/mrtcoord", id(id) fcolor(Blues)













