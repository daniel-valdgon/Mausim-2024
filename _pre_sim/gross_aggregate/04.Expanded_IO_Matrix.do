
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico 
* Date: June 2020
* Version: 1.0
*--------------------------------------------------------------------------------


*--------------------------------------------------------------------------------
*    			      4.1. IO Matriz and CN					
*--------------------------------------------------------------------------------
tempfile Aux_Products_TVA
tempfile Aux_IO_matrix
tempfile Aux_IO_
tempfile Final_expenditure
tempfile Aux_IO_matrix2
tempfile Percentage_IO_TVA

local vat_str 

if (settings[3,1]==0) {
local vat_str ""
}
if (settings[3,1]==1) {
local vat_str "_ref"
}
if (settings[3,1]==2) {
local vat_str "_aliment"
}
if (settings[3,1]==3) {
local vat_str "_aliment_basket"
}
if (settings[3,1]==4) {
local vat_str "_aliment_25"
}
if (settings[3,1]==5) {
local vat_str "_transport"
}
if (settings[3,1]==6) {
local vat_str "_transport_selec"
}
if (settings[3,1]==7) {
local vat_str "_jornaux"
}
if (settings[3,1]==8) {
local vat_str "_gaz"
}
if (settings[3,1]==9) {
local vat_str "_loyer"
}
if (settings[3,1]==10) {
local vat_str "_education"
}
if (settings[3,1]==11) {
local vat_str "_education_private"
}
if (settings[3,1]==12) {
local vat_str "_sante"
}
if (settings[3,1]==13) {
local vat_str "_ref"
}
if (settings[3,1]==14) {
local vat_str "_ref"
}


import excel "$xls_sn", sheet("TVA_raw`vat_str'") firstrow clear
drop if codpr==.
tempfile Aux_Products_TVA
save `Aux_Products_TVA'

merge 1:n codpr using "$data_sn/IO_percentage2.dta", nogen
egen nom_compte=concat(Secteur TVA), punct("_")

/*
drop if substr(nombre_cuentas, 1,1) == "."
drop if substr(nombre_cuentas, 1,1) == "_"
drop if substr(nombre_cuentas, 5,5) == "."
*/

gen var_aux="C"
gen nom_compte2= var_aux+ nom_compte
replace nom_compte2="C16_18" if nom_compte2=="C16_18 "
drop var_aux

tempfile Aux_IO_matrix
save `Aux_IO_matrix'

*save "$data_sn/Aux_IO_matrix.dta", replace


*--------------------------------------------------------------------------------
*    			      4.2. IO Matriz and VAT				
*--------------------------------------------------------------------------------

use "$data_sn/Senegal_consumption_all_by_product.dta", clear
merge n:1  grappe menage using "$root\SENEGAL_ECVHM_final\Dataout\ehcvm_conso_SEN2018_menage.dta" , nogen keepusing (hhid hhweight)

* We exclude auto-production and auto-consumption, gifts, in-kind transfers, and non-market
* bases purchase 

drop if inlist(modep,2,3,4,5)


collapse (sum) depan [aw=hhweight], by(hhid codpr)

merge n:1 codpr using "`Aux_Products_TVA'", gen(merged_TVA)

drop if merged_TVA ==1
tempfile Final_expenditure
save `Final_expenditure'



use `Aux_IO_matrix', clear
bys codpr: gen count_id=_n

levelsof count_id, local(count)

foreach j of local count{
	tempfile Depense_merge`j'
	preserve
	keep if count_id==`j'
	merge 1:n codpr using "`Final_expenditure'", gen(merged_IO`j')
	drop if merged_IO`j'==2
	save "`Depense_merge`j''", replace
	restore
	}

clear

foreach j of local count{
 append using `Depense_merge`j''
}

save `Aux_IO_matrix2'

merge n:1 codpr Secteur using `Aux_IO_matrix', nogen
gen Depense_annuel_IO= depan*pourcentage
collapse (sum) Depense_annuel_IO, by(hhid Secteur TVA )

egen nom_compte=concat( Secteur TVA), punct("_")

gen var_aux="C"
gen nom_compte2= var_aux+ nom_compte
drop var_aux

drop nom_compte
rename nom_compte2 nom_compte

*save `Aux_IO_matrix.dta'


destring Secteur, replace
collapse (sum) Depense_annuel_IO (mean) Secteur , by(nom_compte)

bys Secteur: egen total_IO=total( Depense_annuel_IO)
gen percentage_IO= Depense_annuel_IO/ total_IO
drop if Depense_annuel_IO==0

save `Percentage_IO_TVA'


*--------------------------------------------------------------------------------
*    			      4.3. Expanded IO Matrix				
*--------------------------------------------------------------------------------


* Aca vamos cambiando el codigo 

import excel "$data_sn\IO_Matrix.xlsx", sheet("Sheet1") firstrow clear

destring Secteur, replace force
drop if Secteur==.
merge 1:n Secteur using `Percentage_IO_TVA'

recode percentage_IO .=1

gen nom_compte2=nom_compte 
replace nom_compte2="C16_18" if nom_compte2=="C16_18 " 

tostring Secteur, replace
replace nom_compte2= "C"+Secteur if  nom_compte2==""

gen compte="C"+Secteur

levelsof Secteur, local(Secteur)

foreach var of local Secteur{
	replace C`var'=C`var'*percentage_IO
	}


levelsof nom_compte2, local(nom_compte2) clean
foreach z of local nom_compte2{
	levelsof percentage_IO if nom_compte2=="`z'", local(percentage_`z')
	display `percentage_`z''
	levelsof compte if nom_compte2=="`z'", local(compte_`z') clean
	display `compte_`z''
	levelsof _merge if nom_compte2=="`z'", local(merge_`z')
	display `merge_`z''
	
	if `merge_`z''!=1{
	gen  `z'= `compte_`z'' * `percentage_`z'' 
	}
	
}

replace nom_compte2=compte if _merge==1
levelsof nom_compte2, local(nom_compte_to_keep) clean
keep `nom_compte_to_keep' nom_compte2

order _all, seq
order nom_compte2
sort nom_compte2

tempfile IO_matrix_expanded

save `IO_matrix_expanded'

*save "$dta/IO_matrix_expanded.dta", replace

