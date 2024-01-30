

use "$data_sn/Senegal_consumption_all_by_product.dta", clear
merge n:1  grappe menage using "$data_sn\ehcvm_conso_SEN2018_menage.dta" , nogen keepusing (hhid hhweight)

* We exclude auto-production and auto-consumption, gifts, in-kind transfers, and non-market
* bases purchase 
drop if inlist(modep,2,3,4,5)

collapse (sum) depan [aw=hhweight], by(hhid codpr)


/* Let's merge with all the database we need to get the resutls */
/* First we need the correlation between the products on the Senegal database and COICOP */
merge n:1 codpr using "$data_sn\correlation_COICOP_senegal.dta" ,  keepusing(coicop) assert(matched using) keep(matched) nogen

/* We need the decile on consumption to then merge the deciles and products with the informality rate*/

merge n:1 hhid using "$data_sn\ehcvm_conso_SEN2018_menage.dta" ,  keepusing(ndtet) assert(matched) nogen

rename  ndtet decile_expenditure
rename coicop product_code
merge n:1 decile_expenditure product_code using "$data_sn\informality_final_senegal.dta", assert(matched using) keep(master matched) keepusing(pc_non_market_purchase pc_market_purchase product_name consumption_informal consumption_all share_informal_consumption informality_purchases) nogen // products with no infor in the survey 
//AG: Question: is this from Bachas et al? What is the source of these data?

tab codpr if informality_purchases ==.
*All these seem to be formal
bys codpr: egen mean_inf = mean(informality_purchases)
replace informality_purchases=mean_inf if informality_purchases==.
drop mean_inf

merge m:1 hhid using "$data_sn\poor.dta" , keepusing(poor) nogen assert(matched) 


save "$presim/05_purchases_hhid_codpr.dta", replace 
