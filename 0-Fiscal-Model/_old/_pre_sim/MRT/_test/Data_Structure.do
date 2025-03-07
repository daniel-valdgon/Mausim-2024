** PROYECT: Mauritania CEQ
** TO DO: Print Data Structure of VAT_tool
** EDITED BY: Gabriel Lombo
** LAST MODIFICATION: 26 February 2024


* Initial globals

if ("$sim" = "VAT_tool") {
	if "`c(username)'"=="wb621266" {
		global pathdata     "C:\Users\wb621266\OneDrive - WBG\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"
		global path     	"C:\Users\wb621266\OneDrive - WBG\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"
		global thedo     	"${path}/02_scripts"
		global country 		"MRT"
	}
	
	global data_sn 		"${path}/01_data/1_raw/${country}/"    
	global presim       "${path}/01_data/2_pre_sim/${country}/"
	global tempsim      "${path}/01_data/3_temp_sim/"
	global data_out    	"${path}/01_data/4_sim_output/"

	global data			"$data_sn/raw"
	global xls 			"${pathdata}/01_data\1_raw\MRT/Data_Strucutre_SEN.xlsx" 
	
}	



	
* Save labels of each data
global folder "data_sn presim tempsim data_out"	
cap mkdir "${data}"

forvalues i = 1/4 {
	*local i = 2
	local var : word `i' of $folder
	
	local files : dir "$`var'" files "*.dta"
	foreach f of local files {
		
		use "$`var'/`f'", clear
	
		describe, replace
		
		gen id = `i'
		gen folder = "`var'"
		gen data = "`f'"
		order id folder data, first
		
		save "${data}/`i'_`var'_`f'.dta", replace
		
		noi di "`var'_`f'"
	}
}


* Append labels
global n = 23
local files : dir "${data}" files "*.dta"
local var : word 1 of `files'
use "${data}/`var'", clear
gen id2 = 1

forvalues i=2/$n {	
	local var : word `i' of `files'
	append using  "${data}/`var'"
	replace id2 = `i' if id2 == .
}
order id*, first

*rmdir "${data}"

*gen keep (only rawData) primary_key foreign_key

* Variables
*export excel "$xls", sheet("Data_Structure") first(variables) sheetmodify

* Data

keep id id2 folder data

gduplicates drop

export excel "$xls", sheet("Data-Tables") first(variables) sheetmodify

	



