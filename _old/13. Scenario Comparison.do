/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program:  Program for the Impact of Fiscal Reforms - CEQ Mauritania
* Author: 	Gabriel Lombo
* Date: 	2 Feb 2023
* Title: 	Generate Output for Simulation - Test code
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------*/

*ssc install labmask

* Params on the master
global path "C:\Users\wb621266\OneDrive - WBG\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"
global data_out    	"${path}/01_data/4_sim_output"
global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_GMB_2.xlsx" 

* New Params
global xls_out    	"${path}/03_Tool/Graphs_GMB.xlsx" 
global sheetname "Ref_2019_MRT VAT_NoExemp_MRT INF_Desc10_MRT"
global nsim 3


global letters "a b c d e f"


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

global variable2 

gen income = ""
replace income = "a_" + variable if variable == "ymp_pc"
replace income = "b_" + variable if variable == "yn_pc"
replace income = "c_" + variable if variable == "yd_pc"
replace income = "d_" + variable if variable == "yc_pc"
replace income = "e_" + variable if variable == "yf_pc"


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
forvalues i=1/$nsim {	
	*global var : word `i' of $sheetname
	tab income measure [iw = value] if sim == `i' & reference == "", matcell(A`i')
	
	tab income measure [iw = value] if sim == `i' & reference == "zref", matcell(B0`i')

	tab income measure [iw = value] if sim == `i' & reference == "line_1", matcell(B1`i')
	tab income measure [iw = value] if sim == `i' & reference == "line_2", matcell(B2`i')
	tab income measure [iw = value] if sim == `i' & reference == "line_3", matcell(B3`i')
	
	*matlist A`i'
}	
	
	
mat A = B01, A1 \ B02, A2 \ B03, A3
mat rownames A = sim1_$variable sim2_$variable sim3_$variable
mat colnames A = $measure 

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
forvalues i=1/$nsim {	
	
	tab variable quintil [iw = value] if sim == `i', matcell(A`i')
}	

mat A = A1 \ A2 \ A3
mat rownames A = sim1_$variable sim2_$variable sim3_$variable
mat colnames A = $quintil 

matlist A

* Print 
putexcel set "${xls_out}", sheet("output") modify
putexcel K1 = ("Revenue") K2 = matrix(A), names

shell ! "$xls_out"

