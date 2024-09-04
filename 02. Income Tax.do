/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
 Program: CEQ Mauritania
 Author: Gabriel
 Date: 2024
 

*--------------------------------------------------------------------------------*/

use  "$presim/02_Income_tax_input.dta", replace 

*------ Allowances PIT

local i = 1
	
gen aux1 = allow1_ind_`i' * ${DirTax_1_allow1_val}
gen aux2 = allow1_ind_`i' * ${DirTax_1_allow2_val}
gen aux3 = allow2_ind_`i' * ${DirTax_1_allow3_val} * an_income_`i'
	
egen allow_`i' = rowtotal(aux1 aux2 aux3)	
replace	allow_`i' = (-1 * allow_`i')
	
*------ Tax Base	
	
egen tax_base_`i' = rowtotal(an_income_`i' allow_`i')	
replace tax_base_`i' = 0 if tax_base_`i' < 0	

gen tax_base_2 = an_income_2
gen tax_base_3 = an_income_3

drop aux1 aux2 aux3 allow1_ind_1 allow2_ind_1 allow_1


*global names_DirTax "Tax1_A"

global all_regimes "A B"
global all_dirtax "Tax1 Tax2 Tax3"

* Create Tax Base for all taxes
local n1 = wordcount("$all_dirtax")
local n2 = wordcount("$all_regimes")

forvalues i = 1/`n1' {
	
	local var1 : word `i' of ${all_dirtax}

	gen income_tax_`i' = .	
	gen threshold_tax_`i' = ""
	
	forvalues j = 1/`n2' {

		local var2 : word `j' of ${all_regimes}



		foreach t of global tholds`var1'_`var2' {
					
			local min = ${min`t'_`var1'_`var2'}
			local max =${max`t'_`var1'_`var2'}
			local rate=${rate`t'_`var1'_`var2'}
			local plus=${plus`t'_`var1'_`var2'}
			
			noi di "Tax type: `var1'_`var2', thold: `t'. Parameters: min=`min', max=`max', rate=`rate', plus=`plus'"

			replace income_tax_`i' = ((tax_base_`i'-`min')*`rate')+`plus' if tax_base_`i'>=`min' & tax_base_`i'<=`max' & tax_ind_`i'==1 & regime_`j' == 1
			
			replace threshold_tax_`i' = "`t'" if tax_base_`i'>=`min' & tax_base_`i'<=`max' & tax_ind_`i'==1 &  regime_`j' == 1
			
		}
	}	
}	

order hhid *_1 *_2 *_3

if $devmode== 1 {
	save "$tempsim/Direct_taxes_complete.dta", replace
}


tempfile Direct_taxes_complete
save `Direct_taxes_complete'


*Tax data collapsed 
collapse (sum) income_tax_1 income_tax_2 (max) income_tax_3, by(hhid)

label var income_tax_1 "Household Income Tax payment"
label var income_tax_2 "Tax Rep. de l'Impot Min. Fiscal"
label var income_tax_3 "Tax Prop"


if $devmode== 1 {
    save "$tempsim/income_tax_collapse.dta", replace
}

tempfile income_tax_collapse
save `income_tax_collapse'

*sum income_tax_1 [aw = hhweight] if tax_ind_1, d
*tabstat tax_base_1 inc_tax_1 [aw = hhweight], s(mean sum) by(threshold_tax_1)

