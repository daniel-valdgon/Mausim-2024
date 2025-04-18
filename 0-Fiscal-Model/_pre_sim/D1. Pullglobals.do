/*============================================================================*\
 To do: Read Netting down parameters
 Author: Gabriel Lombo
 Start Date: April 2025
 Update Date: 
\*============================================================================*/
  
*===============================================================================
// Set globals in this do-file
*===============================================================================

global sheet1 "Params_ref_raw"
global sheet2 "Params_prod_ref_raw"
global sheet3 "IO_matrix"
global sheet4 "IO_percentage"


*===============================================================================
// Read Parameters
*===============================================================================

*-------------------------------------
// Parameters
*------------------------------------- 

import excel "$xls_sn", sheet("${sheet1}") first clear

* Store as parameters
keep globalname globalvalue

levelsof globalname, local(params)
foreach z of local params {
	levelsof globalvalue if globalname == "`z'", local(val)
	global `z' `val'
}	


*-------------------------------------
// Parameters by product
*------------------------------------- 

import excel "$xls_sn", sheet("${sheet2}") first clear

levelsof codpr, local(products)
global products "`products'"

* Organize table
ren * value_*
ren value_codpr codpr

reshape long value_, i(codpr) j(var_, string)

tostring codpr, replace
gen globalname = var_ + codpr

ren value_ globalvalue

* Store as parameters
keep globalname globalvalue

levelsof globalname, local(params)
foreach z of local params {
	levelsof globalvalue if globalname == "`z'", local(val)
	global `z' `val'
}	


*-------------------------------------
// Sector: IO Matrix
*-------------------------------------

import excel "$data_sn/IO_Matrix.xlsx", sheet("IO_matrix") firstrow clear
	 
local cats "fixed elec_sec emel_sec fuel_sec"  	 
	 
local fixed 	"8 9" 
local elec_sec  "8"
local emel_sec 	"1"
local fuel_sec 	"9 12"


foreach i of local cats {
	gen `i' = 0
	foreach j of local `i' {
		di "`i'", "`j'"
		replace `i' = 1 if sector == `j'
	}
} 

save "$presim/IO_Matrix.dta", replace


*-------------------------------------
// IO_percentage: Products - Sector
*-------------------------------------

import excel "$xls_sn", sheet("IO_percentage") firstrow clear

save "$presim/IO_percentage.dta", replace
	







