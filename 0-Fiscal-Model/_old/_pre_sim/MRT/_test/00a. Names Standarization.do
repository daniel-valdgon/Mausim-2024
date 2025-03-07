** PROYECT: Mauritania CEQ
** TO DO: Data cleansing and standarization
** EDITED BY: Gabriel Lombo
** LAST MODIFICATION: 18 January 2024


* Parameters
*global path 		"C:\Users\wb621266\OneDrive - WBG\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"
*global pathdata 	"C:\Users\wb621266\OneDrive - WBG\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"

*global country 		"MRT"
*global data_sn 		"${pathdata}/01_data/1_raw/${country}"    	
global xls 			"${path}/01_data/1_raw/${country}/VarList.xlsx"

* Export labels
cap program drop export_lab
program define export_lab 

*global data "${data_sn}/EPCV2019_income.dta"
*global sheet "EPCV"

* Read data
use "$data", clear

* Variables
describe, replace

keep name type varlab

ren * old_*
ren old_varlab varlab

* Default
gen new_name = ""
gen new_type = old_type
gen keepvar = .
gen primary_key = .
*gen presim05 = ""
*gen sim08 = ""
gen comments = ""

gen data = "$sheet"
order data, first

* Temp file
*tempfile $sheet
save "${data_sn}/lab_$sheet.dta", replace

* Export
*export excel "$xls", sheet("$sheet") first(variables) sheetreplace

end



* Read excel, rename, keep and see primary key
cap program drop standardize
program define standardize

*global data "${data_sn}/EPCV2019_income.dta"
*global data_new "${data_sn}/s_EPCV.dta"
*global sheet "EPCV"

* Import
import excel "$xls", sheet("rawData") first clear

keep if data == "$sheet"

* Default, make dure the code run
cap tostring new_name, replace
replace new_name = old_name if inlist(new_name, ".", "")
replace primary_key = 0 if primary_key == .
replace keepvar = 0 if keepvar == .

* New names
levelsof old_name, local(params)
foreach z of local params {
	levelsof new_name  if old_name=="`z'", local(val)
	global `z' `val'
}

* Variables to keep
levelsof new_name, local(params)
foreach z of local params {
	levelsof keepvar if new_name=="`z'", local(val)
	global `z'_k `val'
}

* Primary key
levelsof new_name, local(params)
foreach z of local params {
	levelsof primary_key if new_name=="`z'", local(val)
	global `z'_id `val'
}

*global c:all globals
*macro list c


* Use data
use "$data", clear

* Rename
foreach i of varlist _all {
	rename `i' $`i'
}

* Keep
global keepvar "" 
foreach i of varlist _all {
	if ( $`i'_k == 1) {
		global keepvar "$keepvar `i'" 
	}
}

di "$keepvar"
keep $keepvar

* Primary key
global primarykey "" 
foreach i of varlist _all {
	if ( $`i'_id == 1) {
		global primarykey "$primarykey `i'" 
	}
}

di "$primarykey"

gunique $primarykey

save "${data_new}", replace

end


clear 
global data "${data_sn}/EPCV2019_income.dta"
global sheet "EPCV"
global data_new "${data_sn}/s_${sheet}.dta"
standardize 

clear
global data "${data_sn}/pivot2019.dta"
global sheet "Pivot"
global data_new "${data_sn}/s_${sheet}.dta"
standardize 

clear
global data "$data_sn/menage_pauvrete_2019.dta"
global sheet "Pauvrete"
global data_new "${data_sn}/s_${sheet}.dta"
standardize 

clear
global data "$data_sn\informality Bachas_mean.dta"
global sheet "Bachas"
global data_new "${data_sn}/s_${sheet}.dta"
standardize 



