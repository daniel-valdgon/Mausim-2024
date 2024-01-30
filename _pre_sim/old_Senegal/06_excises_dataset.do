*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: CEQ Senegal - 5. Excise Taxes					
* Author: Daniel Valderrama 
* Date: June 2020
* Version: 1.0
* Modified:  This eliminates the deletiong of cod_pro that are not excise taxes 
*--------------------------------------------------------------------------------

*--------------------------------------------------------------------------------
*    			   
*--------------------------------------------------------------------------------

use "$data_sn/Senegal_consumption_all_by_product.dta", clear
merge n:1  grappe menage using "$data_sn\ehcvm_conso_SEN2018_menage.dta" , nogen keepusing (hhid hhweight)

drop if inlist(modep,2,3,4,5)

save "$presim/06_Excises_dataset.dta", replace
