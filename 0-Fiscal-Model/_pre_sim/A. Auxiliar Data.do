/*============================================================================*\
 Presim Data - Mauritania
 Authors: Gabriel Lombo
 Start Date: March 2025
 Update Date: 
\*============================================================================*/
   

set seed 123456789

*===============================================================================
// A: Auxiliar Data
*===============================================================================

*-------------------------------------
// Informality - Bachas
*-------------------------------------

use "${data_sn}/informality_Bachas_mean.dta", clear

* Standardization
keep decile_expenditure product_name c_inf_mean
ren c_inf_mean informal_purchase

gen coicop = .
replace coicop = 1 if product_name == "Food and non-alcoholic beverages"
replace coicop = 2 if product_name == "Alcoholic beverages, tobacco and narcotics"
replace coicop = 3 if product_name == "Clothing and footwear"
replace coicop = 4 if product_name == "Housing, water, electricity, gas and other fuels"
replace coicop = 5 if product_name == "Furnishings, household equipment and routine household maintenance"
replace coicop = 6 if product_name == "Health"
replace coicop = 7 if product_name == "Transport"
replace coicop = 8 if product_name == "Communication"
replace coicop = 9 if product_name == "Recreation and culture"
replace coicop = 10 if product_name == "Education"
replace coicop = 11 if product_name == "Restaurants and hotels"
replace coicop = 12 if product_name == "Miscellaneous goods and services"

labmask coicop, values(product_name)

save "${presim}/Aux_informality.dta", replace

drop product_name
reshape wide informal_purchase, i(decile_expenditure) j(coicop)

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
	

*-------------------------------------
// Maps
*-------------------------------------

shp2dta using "$data_other/Shapes/mrt_admbnda_adm1_ansade_20240327.shp", database("$presim/Aux_mrtdb") coordinates("$presim/Aux_mrtcoord") genid(id) replace








