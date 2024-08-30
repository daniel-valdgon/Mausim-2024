/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
 Program: CEQ Mauritania
 Author: Gabriel
 Date: 2024
 

*--------------------------------------------------------------------------------*/

use  "$presim/02_Income_tax_input.dta", replace 

keep hhid income_tax*

rename income_tax2 income_tax_reduc
rename income_tax3 trimf





if $devmode== 1 {
	save "$tempsim/Direct_taxes_complete_Senegal.dta", replace
}


tempfile Direct_taxes_complete
save `Direct_taxes_complete'


*Tax data collapsed 
collapse (sum) income_tax income_tax_reduc (max) trimf /*hhweight (mean) hhsize */, by(hhid)

label var income_tax "Household Income Tax payment"
label var income_tax_reduc "Tax Rep. de l'Impot Min. Fiscal"
label var trimf "Tax Prop"


if $devmode== 1 {
    save "$tempsim/income_tax_collapse.dta", replace
}

tempfile income_tax_collapse
save `income_tax_collapse'

