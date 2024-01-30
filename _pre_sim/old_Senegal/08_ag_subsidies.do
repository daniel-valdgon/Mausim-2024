


use "$data_sn/s16b_me_SEN2018.dta", clear

global total_agriculture 53260000000
keep if inlist(s16bq01, 11,12,13,17,18,20,21) // select specific seeds used ans inputs :	Semences de petit mil,   Semences de sorgho , Semences de maïs , Semences de sésame , Semences de haricots/niébé ,   Autres semences,  Semences d'arachide 


keep if inlist(s16bq04, 1,2,6,7,8,.) //  household who report obtain the seed from Coopérative, Marché/Boutique (Market) , Structure Etatique (structure estatal) , Banque céréalière (Bank of cereals), Autre

keep if s16bq09c!=. // value different from missing 

collapse (sum) s16bq09c , by(hhid)
merge 1:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta", nogen keepusing(hhweight)
drop if s16bq09c==.


save "$presim/08_agr_subsidies.dta", replace