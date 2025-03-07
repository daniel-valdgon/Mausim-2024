** PROYECT: Mauritania CEQ
** TO DO: Data cleansing and standarization
** EDITED BY: Gabriel Lombo
** LAST MODIFICATION: 18 January 2024

* program: standarize(varlist (all_data)), stage(stage) import(data_sn) export(xls_var) sheet(sheet) n(4)

cap program drop var_standardization
program define var_standardization, rclass
	/*version 14.2
	#delimit ;
	syntax varlist (min=2 numeric) [if] [in], 
		stage(varlist max=1 numeric)
		import(varlist max=1 numeric)
		export(varlist max=1 numeric)
		;
	#delimit cr		
	*/
qui {
	
	

	if ("$stage" == "stage1") {
	forvalues i=1/$n {
	
		* First parameters
		*local i = 2
		global var : word `i' of $all_data

		* Read data
		use "${data}/${var}.dta", clear

		* Variables description
		describe, replace

		keep name type varlab

		ren * old_*
		ren old_varlab varlab

		gen process = "$sheet"
		gen data = "$var"
		order process data, first
		
		* Save	
		*tempfile $var 
		*save `$var', replace 
		
		save "${data}/lab_${var}.dta", replace // Temporary solution, shouldn't save any data on .dta
	} 
	
	* Append data
	global var : word 1 of $all_data
	use "${data}/lab_${var}.dta", clear
	erase "${data}/lab_${var}.dta"

	if ($n > 1) {
		forvalues i=2/$n {	
			global var : word `i' of $all_data
			append using  "${data}/lab_${var}"
			erase "${data}/lab_${var}.dta"
		}
	}
	
	
	export excel "$xls_var", sheet("$sheet") first(variables) //sheetmodify
	
	putexcel set "$xls_var", sheet("$sheet") modify
	putexcel F1 = ("new_name") G1 = ("new_type") H1 = ("keepvar") I1 = ("primary_key"), names
	
}
 

if ("$stage" == "stage2") {
	
	* Import
	import excel "$xls_var", sheet("$sheet") first clear

	* Default
	cap tostring new_name new_type, replace
	replace new_name = old_name if inlist(new_name, ".", "")
	replace new_type = old_type if inlist(new_type, ".", "")
	replace primary_key = 0 if primary_key == .
	replace keepvar = 0 if keepvar == .
	
	/* Default when I have no data... Not OK
	egen aux_keepvar = max(keepvar), by(data)
	replace keepvar = 1 if aux_keepvar == 0

	egen aux_tag = tag(data)
	egen aux_primary_key = max(primary_key), by(data)
	replace primary_key = aux_tag if aux_primary_key == 0
	
	drop aux*
	*/
	* Export
	save "${data}/${sheet}.dta", replace // Tempdata

	* Final results
	*use "${data_sn}/${sheet}.dta", clear

	keep if keepvar == 1

	export excel "$xls_var", sheet("s_${sheet}") first(variables) sheetreplace
		
	* Assignation process for each data
	forvalues i=1/$n {
	
		* First parameters
		*local i = 2
		global var : word `i' of $all_data
		
		* Read data
		use "${data}/${sheet}.dta", clear
		
		keep if data == "$var"
	
		*** Get parameters
		* New names
		levelsof old_name, local(params)
		foreach z of local params {
			levelsof new_name  if old_name=="`z'", local(val)
			global `z' `val'
		}

		/* New class
		levelsof new_name, local(params)
		foreach z of local params {
			levelsof new_type  if new_name=="`z'", local(val)
			global `z'_t `val'
		}
		*/

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
		
		*** Assign parameters to data
		* Read data
		use "${data}/${var}.dta", clear

		* Rename
		foreach i of varlist _all {
			rename `i' $`i'
		}

		/* Var type
		foreach i of varlist _all {
			recast $`i'_t `i'
		}
		*/

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
		noi di "${var}"
		noi di "$primarykey"
		noi gunique $primarykey

		noi save "${data}/s_${var}.dta", replace
		
		*noi ds
		
	}	
	
	erase "${data}/${sheet}.dta"

}

}

end



	
	