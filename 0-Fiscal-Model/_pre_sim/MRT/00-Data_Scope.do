/*============================================================================*\
 West Africa - Simulation Tool
 Authors: Gabriel Lombo
 Start Date: March 2025
 Update Date: March 2025
\*============================================================================*/
 
*----- Globals
global country		"MRT" 

global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 AFW Fiscal Incidence Analysis"
 
global xls_out		"${path}/03-Output/gabriellombomoreno/Tool/Dictionary.xlsx"

global all_data 	"01_menages 02_Income_tax_input 05_netteddown_expenses_SY 05_purchases_hhid_codpr 07_dir_trans_PMT 07_educ 08_subsidies_elect 08_subsidies_fuel 08_subsidies_agric IO_Matrix IO_percentage" // Data names

global folder 		"${path}/01-Data/2_pre_sim/${country}" 


*----- Print variables structure
* Lenght
clear
set obs 1 
gen n = length("$all_data") - length(subinstr("$all_data", " ", "", .)) + 1
qui sum n
global n "`r(mean)'"
drop n

* Read Data
forvalues i=1/$n {
	
	* First parameters
	global var : word `i' of $all_data

	* Read data
	use "${folder}/${var}.dta", clear

	* Variables description
	describe, replace

	keep name type varlab

	gen data = "$var"
	order data, first
		
	save "${folder}/lab_${var}.dta", replace 
} 
	
* Append data
global var : word 1 of $all_data
use "${folder}/lab_${var}.dta", clear
erase "${folder}/lab_${var}.dta"

if ($n > 1) {
	forvalues i=2/$n {	
		global var : word `i' of $all_data
		append using  "${folder}/lab_${var}"
		erase "${folder}/lab_${var}.dta"
	}
}

* Print Data	
export excel using "$xls_out", sheet("${country}_datacheck") sheetreplace first(variable) locale(C)  nolabel	
	

	
	