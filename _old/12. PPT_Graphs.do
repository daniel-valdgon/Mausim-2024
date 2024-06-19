
/*==============================================================================*\
 Senegal Mini Simulation Tool, indirect taxes (VAT) informality by Bacha's Method
 To do: Create presentation
 Authors: Madi Mangan and Gabriel Lombo
 Start Date: January 2024
 Update Date: 02nd April 2024
 
\*==============================================================================*/


    
	
	*******************************************************************
	***** GLOBAL PATHS ************************************************
	
	*global path "/Users/manganm/Documents/GitHub/Feb_2024/VAT_tool" // Madi		
	   
	*global data_sn 		"${path}/01_data/1_raw"
    *global tempsim      "${path}/01_data/3_temp_sim"
	*global Vat_sn       "${path}/03_Tool/VAT_mini.xlsx"
	
	
	*******************************************************************
	**// 1.  Composition of expenditure by VAT Rates and and deciles **
	*******************************************************************

	if "`c(username)'"=="gabriellombomoreno" {
		global path     	"/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool"
		
		global country 		"MRT"
		
		global presim       "${path}/01_data/2_pre_sim/${country}"
		global tempsim      "${path}/01_data/3_temp_sim"
		global data_out    	"${path}/01_data/4_sim_output"
	
		global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
		global xls_out    	"${path}/03_Tool/Graphs_`c(username)'.xlsx" 
		
		// No dejar espacios o espacios dobles...
		global sheetname 	"V3_MRT_VAT_Ref V3_MRT_VAT_NoExemp V3_MRT_VAT_Inf"
		*global "V3_MRT_Exc_Ref V3_MRT_Exc_SinProd"
	}
	
	if "`c(username)'"=="wb621266" {
		global path     	"C:\Users\wb621266\OneDrive - WBG\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"
		
		global country 		"MRT"
		
		global presim       "${path}/01_data/2_pre_sim/${country}"
		global tempsim      "${path}/01_data/3_temp_sim"
		global data_out    	"${path}/01_data/4_sim_output"
	
		global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
		global xls_out    	"${path}/03_Tool/Graphs_`c(username)'.xlsx" 
		
		global sheetname 	""
	}

    if "`c(username)'"=="manganm" {
		global path     	"/Users/manganm/Documents/GitHub/vat_tool_GMB"
		*global thedo     	"${path}/02_scripts"
		global country 		"GMB"
	
		global presim       "${path}/01_data/2_pre_sim/${country}"
		global data_out    	"${path}/01_data/4_sim_output"
	
		global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_${country}_2.xlsx" 

		* New Params
		global xls_out    	"${path}/03_Tool/Graphs_${country}.xlsx" 
		global sheetname "Ref_2019_GMB VAT_NoExempt_GMB INF_DES10_GMB"
		global nsim 3
	}
	
	
	
	use "$presim/01_menages.dta", clear
	
	keep hhsize hhid hhweight

	merge 1:m hhid using "$tempsim/FinalConsumption_verylong.dta"

	*gen double ymp_pc = round(achats_net/hhsize,0.01)
	gen double ymp_pc = round(achats_avec_excises/hhsize,0.01)

   
	gen pondih= hhweight*hhsize
	_ebin ymp_pc [aw=pondih], nq(10) gen(deciles_pc)
   
	tab TVA
	
    if ("$country" == "MRT") {
		replace TVA = .18 if inrange(TVA, 0.1999, 0.2001) 
	}
   
	*collapse (sum)  ymp_pc  [fw=pondih], by(hhid TVA)
	collapse (sum)  ymp_pc  [iw=pondih], by(hhid TVA)

	egen VAT = group(TVA)
   
	label define VAT 1 "Exempted" 2 "Basic" 3 "Standard"
	label values VAT VAT 
	
	drop TVA
   
	reshape wide ymp_pc, i(hhid) j(VAT)
   
    if ("$country" == "GMB") {
		egen cons = rowtotal(ymp_pc1 ymp_pc2)
		rename ymp_pc1 Exempted
		rename ymp_pc2 Standard
		
		foreach x in Exempted Standard {
			gen share_`x' = `x'/cons 
		}
	}
	
	if ("$country" == "MRT") {
		egen cons = rowtotal(ymp_pc*)
		rename ymp_pc1 Exempted
		rename ymp_pc2 Basic 
		rename ymp_pc3 Standard
	
		foreach x in Exempted Basic Standard {
			gen share_`x' = `x'/cons 
		}
	}
   
	// recover the hhweight and hhsize again 
   
	merge m:1 hhid using "$presim/01_menages.dta", keepusing(hhweight hhsize) nogen
 
   
	gen pondih= hhweight*hhsize
	_ebin cons [aw=pondih], nq(10) gen(deciles_pc)
 

  
	if ("$country" == "GMB") {
		collapse share_Exempted share_Standard (sum) Exempted [iw=pondih], by(deciles_pc)
	}	
	
	if ("$country" == "MRT") {
		collapse share_Exempted share_Basic share_Standard (sum) Exempted [iw=pondih], by(deciles_pc)
	}
	*collapse share_Exempted share_Basic share_Standard (sum)Exempted [fw=pondih], by(deciles_pc)
	
 
   
	** plot in Excel 
	preserve
	drop Exempted
        global cell = "A2"
        export excel using "$xls_out", sheet("Motivation", modify) first(variable) cell($cell ) keepcellfmt
	restore
   
   
    *******************************************************************
	** 2.  Percentage of potential tax revenue from exempted products *
	*******************************************************************
	// distribution of the consumption on exempted products
	
	*collapse percent Exempted [fw=pondih], by(deciles_pc)
	
	egen total  = sum(Exempted)
	gen percent = (Exempted/total)*100
	keep percent deciles_pc

        global cell = "A16"
        export excel using "$xls_out", sheet("Motivation", modify) first(variable) cell($cell ) keepcellfmt
	twoway bar percent deciles_pc
	
	*export excel using "Vat_sn", sheet("") sheetreplace first(variable)
   
	
	********************************************************************
	** 3. Formality purchases across households by place of purchase​  **
	********************************************************************

	use "$presim/05_purchases_hhid_codpr.dta", clear

	if ("$country" == "GMB") ren c_inf_mean share_informal_consumption
	if ("$country" == "MRT") ren informal_purchase share_informal_consumption
	
	collapse (mean) c_inf_mean=share_informal_consumption (p50) c_inf_p50=share_informal_consumption , by(decile_expenditure /*product_code*/)
	global cell = "A35"
        export excel using "$xls_out", sheet("Motivation", modify) first(variable) cell($cell ) keepcellfmt

    
	*twoway rarea c_inf_mean c_inf_p50 decile_expenditure, title("Formality purchases across households by place of purchase​")
	
	
	twoway  lowess /*lfitci*/ c_inf_mean decile_expenditure || lowess c_inf_p50 decile_expenditure, /*yaxis(0(.20)1)*/ lpattern(dash solid) title("Formality purchases across households by place of purchase (Mauritania)​") xtitle("Expenditure Deciles") ytitle("Informal Budget Share") legend( label (1 "Mean") label (2 "Median"))
	
gab
	********************************************************************
	** 4. Scenario Compariston​  									  **
	********************************************************************

	*ssc install labmask
	
	* Gen macro for results organization

	global letters "a b c d e f g h i j k l"
	
	gen nsim = length("${sheetname}") - length(subinstr("${sheetname}", " ", "", .)) + 1
	qui sum nsim
	global nsim "`r(mean)'"
	drop nsim
	
	
	* Import and save simulation results
	forvalues i=1/$nsim {	
		
		global var : word `i' of $sheetname
		
		import excel "$xls_sn", sheet("all${var}") firstrow clear
		
		global label : word `i' of $letters
		
		gen sim = `i'
		gen sim_s = "${var}"
		
		tempfile Sim`i'
		save `Sim`i''	
	}


	* Append simulation results
	use `Sim1', clear

	forvalues i = 2/$nsim {
		append using `Sim`i''
	}

	/* Labels
	label var zref "Seuil de pauvreté national"
	label var line_1 "Seuil de pauvreté international 2.15 USD (2017 PPP)"
	label var line_2 "Seuil de pauvreté international 3.65 USD (2017 PPP)"
	label var line_3 "Seuil de pauvreté international 6.85 USD (2017 PPP)"
		
	label var ymp_pc "Revenu de marché plus pensions"
	label var yn_pc "Revenu net de marché"
	label var yd_pc "Revenu disponible"
	label var yc_pc "Revenu consommable"	
	*/

	*label values measure ""
	*label define measure measure	

	*export excel "$xls_out", sheet("all") first(variables) sheetreplace
	save "$data_out/AllSim.dta", replace

	 
	* Generate output - Compare Scenarios to print excel
	* 1. Comparison reforms on principal indicators
	use "$data_out/AllSim.dta", clear

	keep concat yd_deciles_pc measure value _population variable deciles_pc all reference sim*

	labmask sim, values(sim_s)

	global variable "ymp_pc yn_pc yd_pc yc_pc yf_pc"
	global reference "zref line_1 line_2 line_3"
	global measure "fgt0 fgt1 fgt2 gini theil"

	gen income = ""
	
	forvalues i = 1/5 {
		local l : word `i' of $letters
		local v : word `i' of $variable
		replace income = "`l'_" + variable if variable == "`v'"
		di "`l' - `v'"
	}
	

	* Filter indicators of interest
	gen test = .
	foreach i in $variable {
		foreach j in $measure {
			replace test = 1 if (variable == "`i'" &  measure == "`j'") 
		}
	}
	tab test

	keep if test == 1

	
	* Generate matrix
	global count ""
	global rownames ""
	forvalues i=1/$nsim {	
		
		global count "$count B0`i', A`i' \"
		
		local sim : word `i' of $sheetname
		global rownames "$rownames `sim'_$variable"
		
		tab income measure [iw = value] if sim == `i' & reference == "", matcell(A`i')
		tab income measure [iw = value] if sim == `i' & reference == "zref", matcell(B0`i')
		
		*tab income measure [iw = value] if sim == `i' & reference == "line_1", matcell(B1`i')
		*tab income measure [iw = value] if sim == `i' & reference == "line_2", matcell(B2`i')
		*tab income measure [iw = value] if sim == `i' & reference == "line_3", matcell(B3`i')
	}	
		
	global count = substr("$count", 1, length("$count")-1)
		
	mat A = $count
	mat colnames A = $measure 
	mat rownames A = $rownames
	
	matlist A
	 
	putexcel set "${xls_out}", sheet("output") modify
	putexcel A1 = ("Indicadores principales - Simulaciones") A2 = matrix(A), names
		
		
	* 2. Total revenue by quintil
	use "$data_out/AllSim.dta", clear

	* Names
	global variable "Tax_TVA_pc TVA_direct_pc TVA_indirect_pc"
	global quintil "1 2 3 4 5"

	replace variable = "a_" + variable if variable == "Tax_TVA_pc"
	replace variable = "b_" + variable if variable == "TVA_direct_pc"
	replace variable = "c_" + variable if variable == "TVA_indirect_pc"

	* Filters
	keep if inlist(variable, "a_Tax_TVA_pc", "b_TVA_direct_pc", "c_TVA_indirect_pc")
	keep if measure == "benefits"

	* Grouping by quintil
	recode deciles_pc (1=1) (2=1) (3=2) (4=2) (5=3) (6=3) (7=4) (8=4) (9=5) (10=5), generate(quintil)

	collapse (sum) value, by(sim variable quintil)

	drop if quintil == 0

	replace value = value/1000000000

	* Generate matrix
	global count ""
	global rownames ""
	mat R = J(1,5,.)

	forvalues i=1/$nsim {	
		
		global count "$count A`i' \"
		
		local sim : word `i' of $sheetname
		global rownames "$rownames `sim'_$variable"
		
		tab variable quintil [iw = value] if sim == `i', matcell(A`i')
		
		sum value if sim == `i' & variable == "c_TVA_indirect_pc"		
		if (r(max) == 0) mat A`i' = A`i' \ R
	}	

	global count = substr("$count", 1, length("$count")-1)
	
	mat A = $count
	mat colnames A = $quintil 
	mat rownames A = $rownames

	matlist A

	* Print 
	putexcel set "${xls_out}", sheet("output") modify
	putexcel K1 = ("Revenue") K2 = matrix(A), names

	shell ! "$xls_out"


	gab
			
/// ---------------------------------------------------------------// 
** Absolute and relative incidence of VAT by deciles 

import excel "$xls_sn", sheet(allRef_2019_GMB) firstrow clear 

preserve
keep if measure=="benefits" 
gen keep = 0
foreach var in TVA_direct TVA_indirect TVA {
	replace keep = 1 if variable == "`var'_pc"
}	
keep if keep ==1 

replace variable=variable+"_ymp" if deciles_pc!=.
replace variable=variable+"_yd" if deciles_pc==.

egen decile=rowtotal(yd_deciles_pc deciles_pc)

keep decile variable value
rename value v_

reshape wide v_, i(decile) j(variable) string
drop if decile ==0
keep decile *_yd

foreach var in v_TVA_direct_pc_yd v_TVA_indirect_pc_yd{
	egen ab_`var' = sum(`var')
	gen in_`var' = `var'*100/ab_`var'
}

ren in_v_TVA_direct_pc_yd direct_absolute_inc 
ren in_v_TVA_indirect_pc_yd indirect_absolute_inc
*ren [in_v_TVA_direct_pc_yd in_v_TVA_indirect_pc_yd] [direct_absolute_inc indirect_absolute_inc]
keep decile  direct_absolute_inc indirect_absolute_inc 

global cell = "B40"
export excel using "$xls_out", sheet("TVA", modify) first(variable) cell($cell ) keepcellfmt

restore

*** relative 

keep if measure=="netcash" 
gen keep = 0
foreach var in TVA_direct TVA_indirect TVA {
	replace keep = 1 if variable == "`var'_pc"
}	
keep if keep ==1 

replace variable=variable+"_ymp" if deciles_pc!=.
replace variable=variable+"_yd" if deciles_pc==.

egen decile=rowtotal(yd_deciles_pc deciles_pc)


keep decile variable value
replace value = value*(-100)
rename value v_

reshape wide v_, i(decile) j(variable) string
drop if decile ==0
keep decile *_yd

global cell = "B55"
export excel using "$xls_out", sheet("TVA", modify) first(variable) cell($cell ) keepcellfmt






/// ---___---____------___---____--- Marginal contributions ---___---__---___// 
 
 *Figure of marginal contributions
 import excel "$xls_sn", sheet(allRef_2019_GMB) firstrow clear 
 
*Effect of VAT on ymp inequality
// total
sum value if concat=="ymp_pc_gini__ymp_."
assert r(N)==1
local pre = r(mean)
sum value if concat=="yc_inc_Tax_TVA_gini__ymp_."
assert r(N)==1
local post = r(mean)
local effect_1 = round(100*(`post'-`pre'),0.0001)

// direct 
sum value if concat=="ymp_inc_TVA_direct_gini__ymp_."
assert r(N)==1
local post = r(mean)
local effect_2 = round(100*(`post'-`pre'),0.0001) 


// indirect 
sum value if concat=="ymp_inc_TVA_indirect_gini__ymp_."
assert r(N)==1
local post = r(mean)
local effect_3 = round(100*(`post'-`pre'),0.0001) 

 *Effect of VAT on ymp poverty
 
 // total
sum value if concat=="ymp_pc_fgt0_zref_ymp_."
assert r(N)==1
local pre = r(mean)
sum value if concat=="ymp_inc_Tax_TVA_fgt0_zref_ymp_."
assert r(N)==1
local post = r(mean)
local effect_4 = round(100*(`post'-`pre'),0.0001)

// direct 
sum value if concat=="ymp_inc_TVA_direct_fgt0_zref_ymp_."
assert r(N)==1
local post = r(mean)
local effect_5 = round(100*(`post'-`pre'),0.0001)  

// indirect 
sum value if concat=="ymp_inc_TVA_indirect_fgt0_zref_ymp_."
assert r(N)==1
local post = r(mean)
local effect_6 = round(100*(`post'-`pre'),0.0001) 
 
 
 clear 
 set obs 6
gen mar =.
forval n=1/6{
	replace mar = `effect_`n'' in `n'
}
 * export to excel 
 global cell = "B35"
 export excel using "$xls_out", sheet("output", modify) first(variable) cell($cell ) keepcellfmt


/// ---___---____------___---____--- Marginal contributions  of Excises ---___---__---___// 

*Figure of marginal contributions
 import excel "$xls_sn", sheet(allRef_Exc_2020_GMB) firstrow clear 
 
 ** effects on poverty - Poverty Prevalence
 // total
sum value if concat=="ymp_pc_fgt0_zref_ymp_."
assert r(N)==1
local pre = r(mean)
sum value if concat=="ymp_inc_excise_taxes_fgt0_zref_ymp_."
assert r(N)==1
local post = r(mean)
local effect_1 = round(100*(`post'-`pre'),0.0001)
 
 ** effect on inequality - GINI
 // total
sum value if concat=="ymp_pc_gini__ymp_."
assert r(N)==1
local pre = r(mean)
sum value if concat=="ymp_inc_excise_taxes_gini__ymp_."
assert r(N)==1
local post = r(mean)
local effect_2 = round(100*(`post'-`pre'),0.0001)

clear 
set obs 2
gen mar =.
forval n=1/2{
	replace mar = `effect_`n'' in `n'
}
* export to excel 
global cell = "B49"
export excel using "$xls_out", sheet("output", modify) first(variable) cell($cell ) keepcellfmt



/// ---------------------------------------------------------------// 
** Absolute and relative incidence of VAT by deciles 

import excel "$xls_sn", sheet(allRef_Exc_2020_GMB) firstrow clear 

preserve
keep if measure=="benefits" 
gen keep = 0
foreach var in excise_taxes {
	replace keep = 1 if variable == "`var'_pc"
}	
keep if keep ==1 

replace variable=variable+"_ymp" if deciles_pc!=.
replace variable=variable+"_yd" if deciles_pc==.

egen decile=rowtotal(yd_deciles_pc deciles_pc)

keep decile variable value
rename value v_

reshape wide v_, i(decile) j(variable) string
drop if decile ==0
keep decile *_yd

foreach var in v_excise_taxes_pc_yd {
	egen ab_`var' = sum(`var')
	gen in_`var' = `var'*100/ab_`var'
}

ren in_v_excise_taxes_pc_yd Absolute_inc 
keep decile  Absolute_inc  

global cell = "B4"
export excel using "$xls_out", sheet("Excises", modify) first(variable) cell($cell ) keepcellfmt
restore


*** relative 

keep if measure=="netcash" 
gen keep = 0
foreach var in excise_taxes {
	replace keep = 1 if variable == "`var'_pc"
}	
keep if keep ==1 

replace variable=variable+"_ymp" if deciles_pc!=.
replace variable=variable+"_yd" if deciles_pc==.

egen decile=rowtotal(yd_deciles_pc deciles_pc)


keep decile variable value
replace value = value*(-100)
rename value v_

reshape wide v_, i(decile) j(variable) string
drop if decile ==0
keep decile *_yd
ren v_excise_taxes_pc_yd Relative

global cell = "B20"
export excel using "$xls_out", sheet("Excises", modify) first(variable) cell($cell ) keepcellfmt




// Excises Revenue 
	
    global sheetname "Ref_Exc_2020_GMB Sin_Exc_2020_GMB"
	global nsim 2		
		
		
		
	* Gen macro for results organization

	global letters "a b c d e f g h i j k l"
	
	gen nsim = length("${sheetname}") - length(subinstr("${sheetname}", " ", "", .)) + 1
	qui sum nsim
	global nsim "`r(mean)'"
	drop nsim
	
	
	* Import and save simulation results
	forvalues i=1/$nsim {	
		
		global var : word `i' of $sheetname
		
		import excel "$xls_sn", sheet("all${var}") firstrow clear
		
		global label : word `i' of $letters
		
		gen sim = `i'
		gen sim_s = "${var}"
		
		tempfile Sim`i'
		save `Sim`i''	
	}


	* Append simulation results
	use `Sim1', clear

	forvalues i = 2/$nsim {
		append using `Sim`i''
	}

	
	save "$data_out/AllSim.dta", replace

		
	use "$data_out/AllSim.dta", clear

	* Names
	global variable "excise_taxes_pc"
	global quintil "1 2 3 4 5"

	replace variable = "a_" + variable if variable == "excise_taxes_pc"

	* Filters
	keep if inlist(variable, "a_excise_taxes_pc")
	keep if measure == "benefits"

	* 1. Grouping by quintil
	recode deciles_pc (1=1) (2=1) (3=2) (4=2) (5=3) (6=3) (7=4) (8=4) (9=5) (10=5), generate(quintil)

	collapse (sum) value, by(sim variable quintil)

	drop if quintil == 0

	replace value = value/1000000000

	* Generate matrix
	global count ""
	global rownames ""
	mat R = J(1,5,.)

	forvalues i=1/$nsim {	
		
		global count "$count A`i' \"
		
		local sim : word `i' of $sheetname
		global rownames "$rownames `sim'_$variable"
		
		tab variable quintil [iw = value] if sim == `i', matcell(A`i')
		
		sum value if sim == `i' & variable == "c_excise_taxes_pc"		
		if (r(max) == 0) mat A`i' = A`i' \ R
	}	

	global count = substr("$count", 1, length("$count")-1)
	
	mat A = $count
	mat colnames A = $quintil 
	mat rownames A = $rownames

	matlist A

	* Print 
	putexcel set "${xls_out}", sheet("output") modify
	putexcel T1 = ("Revenue") T2 = matrix(A), names

	shell ! "$xls_out"

		
		
		
	* 2. Comparison reforms on principal indicators
	use "$data_out/AllSim.dta", clear

	keep concat yd_deciles_pc measure value _population variable deciles_pc all reference sim*

	labmask sim, values(sim_s)

	global variable "ymp_pc yn_pc yd_pc yc_pc yf_pc"
	global reference "zref line_1 line_2 line_3"
	global measure "fgt0 fgt1 fgt2 gini theil"

	gen income = ""
	
	forvalues i = 1/5 {
		local l : word `i' of $letters
		local v : word `i' of $variable
		replace income = "`l'_" + variable if variable == "`v'"
		di "`l' - `v'"
	}
	

	* Filter indicators of interest
	gen test = .
	foreach i in $variable {
		foreach j in $measure {
			replace test = 1 if (variable == "`i'" &  measure == "`j'") 
		}
	}
	tab test

	keep if test == 1

	
	* Generate matrix
	global count ""
	global rownames ""
	forvalues i=1/$nsim {	
		
		global count "$count B0`i', A`i' \"
		
		local sim : word `i' of $sheetname
		global rownames "$rownames `sim'_$variable"
		
		tab income measure [iw = value] if sim == `i' & reference == "", matcell(A`i')
		tab income measure [iw = value] if sim == `i' & reference == "zref", matcell(B0`i')
		
	}	
		
	global count = substr("$count", 1, length("$count")-1)
		
	mat A = $count
	mat colnames A = $measure 
	mat rownames A = $rownames
	
	matlist A
	 
	putexcel set "${xls_out}", sheet("output") modify
	putexcel AA1 = ("Principal indicators - Simulations") AA2 = matrix(A), names
			
		
	
**** --------------------------------------- END --------------------- ---- ***

**** --------------------------------------- END --------------------- ---- ***



	
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
