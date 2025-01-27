/*============================================================================================
 ======================================================================================

	Project:		Direct Transfers - Figures Scenarios
	Author:			Gabriel 
	Creation Date:	June 26, 2024
	Modified:		
	
	Section: 		1. Validation
					4. Absolute and Relative Incidence
					5. Marginal Contributions
					6. Poverty difference
					
* @Daniel. 

	Note: 			I copy and paste all figures in the Figures excel. Sections 5 and 6 are not working in this do-file, I took them from shiny app. https://gabrielombo.shinyapps.io/WestAfrica_CEQ/. 

	Excel Figures: 
					1. Results: Tables from both R-Shiny (Section 5 and 6) and this do-file (Section 4). 
					2. Distribution: Same tables as in the inputs tool on the reference scenario
					3. Validation: Tables from this do-file (Section 1) and adm data
  
	Scenarios:		
				
============================================================================================
============================================================================================*/

clear all
macro drop _all

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mausim_2024"
	global report 		"${path}/04. Reports/3. Direct Transfers/2. Presentation/Figures"
	
	global thedo     	"${path}/02. Scripts"

	global xls_out    	"${report}/Figures12_Direct_Transfers.xlsx"
	global xls_sn    	"${path}/03. Tool/SN_Sim_tool_VI_`c(username)'.xlsx"
	
	global numscenarios	1

	global proj_1		"MRT_Ref_2024" 
	global proj_2		"Ref_MRT_2024"  
	global proj_3		"Ref_MRT_2019" 
	global proj_4		"v1_MRT_Tekavoul" 
	global proj_5		"v1_MRT_School" 
	global proj_6		"v1_MRT_Elmaouna" 
	global proj_7		"v1_MRT_Food" 

	global policy		"am_prog_1 am_prog_2 am_prog_3 am_prog_4"

}



	global data_sn 		"${path}/01. Data/1_raw/MRT"    
	global presim       "${path}/01. Data/2_pre_sim/MRT"
	global data_out    	"${path}/01. Data/4_sim_output"
	global theado       "$thedo/ado"
	scalar t1 = c(current_time)

	
*===============================================================================
// Run necessary ado files
*===============================================================================

cap run "$theado//_ebin.ado"
	
	
/*-------------------------------------------------------/
	1. Validation
/-------------------------------------------------------*/

	
use "$data_sn/Datain/individus_2019.dta", clear

forvalues i = 1/6 {
	gen prog_`i' = (PS4A == `i' | PS4B == `i' | PS4C == `i')
	gen prog_amount_`i' = PS7 if prog_`i' == 1
	
	egen hh_prog_`i' = max(prog_`i' == 1), by(hid)
	egen hh_prog_amount_`i' = total(prog_amount_`i'), by(hid)
}

ren hid hhid
egen tag = tag(hhid)
gen uno = 1	
	
* Result data	
merge m:1 hhid using "$data_out/output_${proj_1}.dta", nogen keep(3) keepusing(*deciles* ymp_pc yn_pc yd_pc yc_pc hhsize hhweight am*)

* Programs
global progs "prog_1 prog_2 prog_3 prog_4 prog_5 prog_6"
global hh_progs "hh_prog_1 hh_prog_2 hh_prog_3 hh_prog_4 hh_prog_5 hh_prog_6"
global hh_progs_am "hh_prog_amount_1 hh_prog_amount_2 hh_prog_amount_3 hh_prog_amount_4 hh_prog_amount_5 hh_prog_amount_6"


_ebin ymp_pc [aw=hhweight], nq(10) gen(decile_ymp)
_ebin yn_pc [aw=hhweight], nq(10) gen(decile_yn)
_ebin yd_pc [aw=hhweight], nq(10) gen(decile_yd)
_ebin yc_pc [aw=hhweight], nq(10) gen(decile_yc)


* Coverage Table. Slide 11
tabm $progs [iw = hhweight] 
tabm $hh_progs if tag == 1 [iw = hhweight] 


* Individuals
tab uno [iw = hhweight] if prog_1==1 | prog_2==1 | prog_3==1 | prog_4==1 | prog_5==1 | prog_6==1
tab uno [iw = hhweight] if prog_1==1 | prog_2==1 | prog_3==1

* Households
tab uno [iw = hhweight] if (hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1 | hh_prog_4==1 | hh_prog_5==1 | hh_prog_6==1) & tag == 1
tab uno [iw = hhweight] if (hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1) & tag == 1

* Coverage - SLides 12 and 13
tab uno [iw = hhweight] if tag == 1 // All households

tabstat $hh_progs [aw = hhweight] if tag == 1, s(sum) by(decile_yc) save

return list



mat A = r(Stat1) \ r(Stat2) \ r(Stat3) \ r(Stat4) \ r(Stat5) \ r(Stat6) \ r(Stat7) \ r(Stat9) \ r(Stat9) \ r(Stat10)

mat rownames A = 1 2 3 4 5 6 7 8 9 10

*putexcel set "$xls_out", modify sheet(Fig_1)
*putexcel A1 = matrix(A), names

*export excel "$xls_out", sheet(Fig_2) first(variable) sheetmodify 


tabstat hh_prog_1 hh_prog_2 [aw = hhweight] if tag == 1, s(sum) by(decile_ymp)


gasb


/*-------------------------------------------------------/
	1. Map
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

/*-------------------------------------------------------/
	4. Absolute and Relative Incidence
/-------------------------------------------------------*/

global income "ymp" // yd, ymp

forvalues scenario = 1/$numscenarios {

	*-----  Absolute Incidence
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="benefits" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	keep decile *_${income}

	foreach var in $policy2 {
		egen ab_`var' = sum(`var')
		gen in_`var' = `var'*100/ab_`var'
	}

	keep decile in_*

	tempfile abs
	save `abs', replace

	*-----  Relative Incidence
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="netcash" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	replace value = value*(-100) if value < 0
	replace value = value*(100) if value >= 0
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	keep decile *_${income}

	order decile $policy2

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


/*-------------------------------------------------------/
	6. Marginal Contributions
/-------------------------------------------------------*/

	global variable 	"ymp" // Only one
	global reference 	"zref" // Only one
	global policy		"am_prog_1 am_prog_2 am_prog_3 am_prog_4 dirtransf_total"

forvalues scenario = 1/1 { //$numscenarios {
	
	*local scenario 1
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${variable}_pc" & reference == "$reference"
	global pov0 = r(mean)
	 
	sum value if measure == "fgt1" & variable == "${variable}_pc" & reference == "$reference"
	global pov1 = r(mean) 
	 
	sum value if measure == "gini" & variable == "${variable}_pc"
	global gini1 = r(mean)
	
	* Variables of interest
	gen keep = 0
	global policy2 	"" 
	foreach var in $policy {
		replace keep = 1 if variable == "${variable}_inc_`var'"
		global policy2	"$policy2 v_`var'_pc_${variable}" 
	}	
	
	keep if keep == 1
	
	keep if inlist(measure, "fgt0", "fgt1", "gini") 
	keep if inlist(reference, "$reference", "") 
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "${variable}_inc_`v'"
	}
	
	keep o_variable measure value
	gsort o_variable
	
	reshape wide value, i(o_variable) j(measure, string)
	
	gen gl_pov0 = $pov0
	gen gl_gini = $gini1
	gen gl_pov1 = $pov1

	
	tempfile mc
	save `mc', replace

*-----  Kakwani	
	import excel "$xls_sn", sheet("conc${variable}_${proj_`scenario'}") firstrow clear 
	
	keep ${variable}_centile_pc ${variable}_pc $policy
	keep if ${variable}_centile_pc == 999
	
	ren * var_*
	ren var_${variable}_centile_pc ${variable}_centile_pc
	ren var_${variable}_pc ${variable}_pc
	
	reshape long var_, i(${variable}_centile_pc) j(variable, string)
	ren var_ value
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "`v'_pc"
	}

	keep o_variable ${variable}_pc value
	ren value value_k

	merge 1:1 o_variable using `mc', nogen
	
	gen scenario = `scenario'
	order scenario o_variable gl_pov0 valuefgt0 gl_pov1 valuefgt1 gl_gini valuegini value_k ${variable}_pc  gl_pov1
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
}	

clear
forvalues scenario = 1/1 { //$numscenarios {
	append using `pov_`scenario''
}

export excel "$xls_out", sheet(Fig_3_1) first(variable) sheetmodify 


/*-------------------------------------------------------/
	7. Poverty and Inequality
/-------------------------------------------------------*/

	global variable 	"yd" // Only one
	global reference 	"zref" // Only one
	global policy		"am_prog_1 am_prog_2 am_prog_3 am_prog_4"

	
forvalues scenario = 1/$numscenarios {
	
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${variable}_pc" & reference == "$reference"
	global pov0 = r(mean)

	sum value if measure == "fgt1" & variable == "${variable}_pc" & reference == "$reference"
	global pov1 = r(mean)
	
	sum value if measure == "gini" & variable == "${variable}_pc"
	global gini1 = r(mean)
	
	
	clear
	set obs 1 
	
	gen gl_pov0 = $pov0
	gen gl_gini = $gini1
	gen gl_pov1 = $pov1
	
	gen scenario = `scenario'
	order scenario, first
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
	
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `pov_`scenario''
}

export excel "$xls_out", sheet(Fig_4) first(variable) sheetmodify 




/*-------------------------------------------------------/
	Scenario names
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {
	
	clear
	set obs 1
	
	gen scenario = `scenario'
	gen name = "${proj_`scenario'}"
	
	tempfile name_`scenario'
	save `name_`scenario'', replace
}

clear
forvalues scenario = 1/$numscenarios {
	append using `name_`scenario''
}

export excel "$xls_out", sheet("Tab_1") first(variable) sheetmodify cell(A1)


scalar t2 = c(current_time)
display "Running the figures took " (clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"









