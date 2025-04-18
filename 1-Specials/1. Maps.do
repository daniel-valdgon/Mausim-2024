/*============================================================================*\
 Internal validation figures - CEQ Mauritania
 Authors: Gabriel Lombo
 Start Date: January 2024
 Update Date: April 2025
\*============================================================================*/
  
clear all
macro drop _all

* Gabriel - Personal Computer
if "`c(username)'"=="gabriellombomoreno" {			
	global pathdata     "/Users/gabriellombomoreno/Documents/WorldBank/Data/DATA_MRT" 
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 MRT Fiscal Incidence Analysis"
	
	global tool         "${path}/03-Outputs/`c(username)'/Tool" 	
	global thedo     	"${path}/02-Scripts/`c(username)'/1-Specials"
	
}
	
	*----- Figures parameters
	global numscenarios	1
	global proj_1		"MRT_Ref_2019_v2" 
	global proj_2		""
	global proj_3		""
	
	global policy		"subsidy_f1_direct subsidy_f2_direct subsidy_f3_direct"
	
	global income		"yd" // ymp, yn, yd, yc, yf
	global income2		"yc"
	global reference 	"zref" // Only one	
	
	*----- Data
	global data_sn 		"${pathdata}/MRT_2019_EPCV/Data/STATA/1_raw"
    global data_other   "${dathdata}/MRT_FIA_OTHER"

	global presim       "${path}/01-Data/2_pre_sim"
	global tempsim      "${path}/01-Data/3_temp_sim"
	global data_out    	"${path}/01-Data/4_sim_output"

	*----- Tool
	global xls_sn 		"${tool}/MRT_Sim_tool_VI.xlsx"
	global xls_out    	"${tool}/Figures_validation.xlsx"	
	
	*----- Ado	
	global theado       "$thedo/ado"

	scalar t1 = c(current_time)
	

	
*==============================================================================
// Run necessary ado files
*==============================================================================

cap run "$theado//_ebin.ado"	

*==============================================================================
// Policies - Internal Validation
*==============================================================================


*------ Coordinates
*shp2dta using "$data_sn/Shapes/mrt_admbnda_adm1_ansade_20240327.shp", database("$data_sn/mrtdb") coordinates("$data_sn/mrtcoord") genid(id) replace

*------ Map
use "$data_sn/mrtdb", clear

gen name = substr(ADM1_PCODE, 3, 4) // Admin 1

merge m:1 name using `map', gen(mr_coor) 

gen income2 = round(income/10/1000)

spmap income2 using "$data_sn/mrtcoord", id(id) fcolor(Blues) legend(region(lcolor(black) margin(1 1 1 1) fcolor(white)) pos(10) title("Mean tax MRU (000)", size(*0.5))) 

graph export "$report/map_proptax.png", replace

/*-------------------------------------------------------/
	1. Direct Transfers
/-------------------------------------------------------*/
/*
gen hope_t = inlist(wilaya, 3, 5, 9, 10)

tabstat $hh_progs [aw = hhweight] if tag == 1, by(milieu)
tabstat $hh_progs [aw = hhweight] if tag == 1, by(hope_t) 

tab hope_t [iw = hhweight] if (hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1 | hh_prog_4==1 | hh_prog_5==1 | hh_prog_6==1) & tag == 1



gcollapse (mean) $hh_progs, by(hhid hhsize hhweight wilaya milieu hope_t)

gen uno = 1

gcollapse (sum) uno $hh_progs [iw = hhweight], by(wilaya hope_t)


* Tables
*tab wilaya milieu [iw = hh_prog_2]

tostring wilaya, gen(name)
gen len = length(name)
replace name = "0" + name if len == 1


tempfile map 
save `map', replace 


shp2dta using "$data_sn/Shapes/mrt_admbnda_adm1_ansade_20240327.shp", database("$data_sn/mrtdb") coordinates("$data_sn/mrtcoord") genid(id) replace

use "$data_sn/mrtdb", clear

gen name = substr(ADM1_PCODE, 3, 4) // Admin 1

merge m:1 name using `map', gen(mr_coor) 

egen tot = rowtotal($hh_progs)

gen per = tot/uno*100

_ebin per, nq(5) gen(quintil)

tabstat per, s(mean min max p50) by(quintil)

gen cat = . 
replace cat = 1 if inrange(per, 0, 1)
replace cat = 2 if inrange(per, 1, 5)
replace cat = 3 if inrange(per, 5, 10)
replace cat = 4 if inrange(per, 10, 20)
replace cat = 5 if inrange(per, 20, 100)


label define cat 1 "Less than 1%" 2 "1 - 5%" 3 "5 - 10%" 4 "10 - 20%" 5 "More than 20%"
label values cat cat

spmap cat using "$data_sn/mrtcoord", id(id) fcolor(Blues) clm(u) legend(region(lcolor(black) margin(1 1 1 1) fcolor(white)) pos(10)) 

gen hh_prog = round(tot)

spmap hh_prog using "$data_sn/mrtcoord", id(id) fcolor(Blues) legend(region(lcolor(black) margin(1 1 1 1) fcolor(white)) pos(10) title("Number of households", size(*0.5) )) 
*/



* End of do-file



















