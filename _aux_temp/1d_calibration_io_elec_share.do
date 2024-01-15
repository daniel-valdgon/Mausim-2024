
*This do-file can be runned separated from the rest of do-files its final ouput is meant to be inputed manually in the sheet of parameters. It will be updated to be put n the final excel 

*Load consumption data and estimate spending and purchases 
use "$data_sn/Senegal_consumption_all_by_product.dta", clear
merge n:1  grappe menage using "$data_sn/ehcvm_conso_SEN2018_menage.dta" , nogen keepusing (hhid hhweight)

* Keep al spendnig and also purhcases 
gen purchases=depan if inlist(modep,1)
collapse (sum) depan purchases [aw=hhweight], by(hhid codpr)

* First we need the correspondence  between the products on the Senegal database and COICOP 
merge m:1 codpr using "$data_sn/correlation_COICOP_senegal.dta" ,  keepusing(coicop)  keep(matched) nogen //assert(matched using)

* We need the decile on consumption to then merge the deciles and products with the informality rate
merge m:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta" ,  keepusing(ndtet) assert(matched) nogen
rename  ndtet decile_expenditure
rename coicop product_code
merge m:1 decile_expenditure product_code using "$data_sn/informality_final_senegal.dta" , assert(matched using) keep(matched) nogen // products with no infor in the survey 

*Share of inofrmality at household level as total informal purchases over total purchases 
gen electricity_io=depan if codpr==334
gen water_io=depan if codpr==332
gen io_sec_22=depan if codpr==334 |  codpr==332 /* | codpr==303*/

*merge
merge m:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta", keepusing (hhweight hhsize)
*gen pondih= hhweight*hhsize

gcollapse (sum) water_io electricity_io io_sec_22 (first) hhweight hhsize, by(hhid)

gen se=electricity_io/io_sec_22
sum se [iw=hhweight], meanonly 
local se = r(mean)

gen sw=water_io/io_sec_22
sum sw [iw=hhweight], meanonly 
local sw = r(mean)

dis " Share of electricity in the IO-22 sector using consumption is `se' and of water is `sw'"

