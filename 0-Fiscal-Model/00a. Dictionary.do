/*============================================================================*\
 West Africa - Simulation Tool
 Authors: Gabriel Lombo
 Start Date: March 2025
 Update Date: March 2025
\*============================================================================*/

*----- User Paths
if "`c(username)'"=="gabriellombomoreno" {

	global country		"MRT" 
	*global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 AFW Fiscal Incidence Analysis"

	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 MRT Fiscal Incidence Analysis"
	
	* Tool Sheet names Parameters
	global raw_sheets	"Policy Params_raw Params_region_raw Params_prod_raw Params_tranches_1_raw Params_tranches_2_raw IO_matrix IO_percentage Params_ref_raw Params_prod_ref_raw"

}

*----- Folder and Files	 
* Data
*global data_sn 	"${pathdata}/MRT_2019_EPCV/Data/STATA/1_raw"
*global data_other  "${pathdata}/MRT_FIA_OTHER"

global presim       "${path}/01-Data/2_pre_sim/"
global tempsim      "${path}/01-Data/3_temp_sim"
global data_out    	"${path}/01-Data/4_sim_output"

* Scripts	
global thedo     	"${path}/02-Scripts/`c(username)'/0-Fiscal-Model"
global theado       "$thedo/ado"
global thedo_pre    "$thedo/_pre_sim"

* Tool	
global tool         "${path}/03-Outputs/`c(username)'/Tool" 	
global xls_sn 		"${tool}/MRT_Sim_tool_VI.xlsx"
global xls_out    	"${tool}/Dictionary.xlsx"



*-------------------------------------
// 1. Get data scope
*-------------------------------------

* Describe presim files
local counter = 1
local files : dir "$presim" files "*.dta"
foreach f of local files{

	local pk ""
	
	di "`f'"
	
	use "${presim}//`f'", clear
	
	* Check PK by one var for any
	foreach v1 of varlist _all {
		
		di "`v1'"
		
		confirm variable `v1'
		
		if !_rc {
			
			gunique `v1'
			qui return list
			
			if (`r(maxJ)' == 1 & `r(minJ)' == 1) {
				local pk "`pk'`v1'"
			}	
		}
	}

	* Check first variable to check PK
	
	describe, replace

	keep name type varlab
	
	gen varpk = "`pk'" == name
	
	gen filename = "`f'"
		
	tempfile file_`counter'
	save `file_`counter'', replace	

	local counter = `counter' + 1
}

clear
local ncounter = `counter' - 1
forvalues i = 1/`ncounter' {
	append using `file_`i''
}

gen filetype = "data"

tempfile data_scope
save `data_scope', replace	

noi di in red 	"You have `ncounter' data files in .dta format uploaded in the presim folder. "

*-------------------------------------
// 2. Get parameters scope
*-------------------------------------

* Get only wheets with parameters
import excel using "$xls_sn", describe

local n_sheets `r(N_worksheet)'
global read_sheets ""
forvalues i = 1/`n_sheets' {
    local sheet`i' "`r(worksheet_`i')'"
	forvalues j = 1/18 {
		local v : word `j' of $raw_sheets
		if "`sheet`i''" == "`v'" {
			global read_sheets "$read_sheets `sheet`i''"	
		}
	}	
}

* Read sheets and get structure
local counter = 1
foreach i of global read_sheets  {

	import excel using "$xls_sn", sheet(`i') firstrow clear
	
	describe, replace clear

	keep name type varlab

	gen filename = "`i'"
	
	order filename, first
	
	tempfile file_`counter'
	save `file_`counter'', replace	

	local counter = `counter' + 1	
	
} 

clear
local ncounter = `counter' - 1
forvalues i = 1/`ncounter' {
	append using `file_`i''
}

gen filetype = "tool"

tempfile tool_scope
save `tool_scope', replace	

noi di in red 	"You have `ncounter' sheet names in excel format uploaded in the the tool as parameters. "


*-------------------------------------
// 3. Print
*-------------------------------------

use `data_scope', clear
append using `tool_scope'

gen vartype = "numeric" if inlist(type, "byte", "double", "float", "int", "long")
replace vartype = "string" if substr(type, 1, 3) == "str"
drop type

ren name varname
order filetype filename varname vartype varpk varlab

* Print Data	
export excel "$xls_out", sheet("MRT_dictionary") first(variable) sheetreplace 


















