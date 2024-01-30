** PROYECT: Mauritania CEQ
** TO DO: Data cleansing of purchases, presim
** EDITED BY: Gabriel Lombo and Daniel Valderrama
** LAST MODIFICATION: 18 January 2024

* Paramteters and data

global path "C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\MauSim\01_data\01_raw\EPCV_2019\Datain"

global path "C:\Users\wb621266\OneDrive - WBG\Mausim_2024\01_data\01_raw"

global presim "C:\Users\wb621266\OneDrive - WBG\Mausim_2024\01_data\02_pre_sim"

*ssc install gtools

* Bachas Informality
use "$presim\informality Bachas_mean.dta", clear

gen coicop = .
replace coicop = 1 if product_name == "Food and non-alcoholic beverages"
replace coicop = 2 if product_name == "Alcoholic beverages, tobacco and narcotics"
replace coicop = 3 if product_name == "Clothing and footwear"
replace coicop = 4 if product_name == "Housing, water, electricity, gas and other fuels"
replace coicop = 5 if product_name == "Furnishings, household equipment and routine household maintenance"
replace coicop = 6 if product_name == "Health"
replace coicop = 7 if product_name == "Transport"
replace coicop = 8 if product_name == "Communication"
replace coicop = 9 if product_name == "Recreation and culture"
replace coicop = 10 if product_name == "Education"
replace coicop = 11 if product_name == "Restaurants and hotels"
replace coicop = 12 if product_name == "Miscellaneous goods and services"

save "$presim\informality Bachas_mean_v2.dta", replace




* Get Deciles of income
use "$path/EPCV2019_income.dta" , clear

gunique hid idp

*twoway (kdensity pci) (kdensity pcc)

*ren wgt hhweight
gsort hid idp

gen hhweight = wgt*hhsize

gen uno =1 
tab uno [iw = wgt] // 4millones de personas
*tab uno [aw = hhweight*hhsize] if pci==.
*tab uno [aw = hhweight*hhsize] if pcc==. // 6 obs without weight, all obs with consumption per capita

gcollapse (sum) pci pcc, by(hid hhweight hhsize)

* By Household
xtile q_pci = pci [aw=hhweight], n(10)  
xtile q_pcc = pcc [aw=hhweight], n(10)

tempfile deciles
save `deciles', replace

* See purchases
use "$path/pivot2019.dta" , clear
merge m:1 hid using `deciles', nogen

*ren wta_hh hhweight

* Informality with bachas data
ren (q_pcc fonction) (decile_expenditure coicop)

merge m:1 decile_expenditure coicop using "$presim\informality Bachas_mean_v2.dta", gen(mr_bachas)



/* Temp table to make the IO matrix - All expenses
keep Prod poste groupe fonction

egen tag = tag(Prod)

keep if tag==1

decode Prod, gen(prod) 
decode poste, gen(class) 
decode groupe, gen(group) 
decode fonction, gen(div) 

tostring Prod, gen(code_prod) 
tostring poste, gen(code_class) 
tostring groupe, gen(code_group) 
tostring fonction, gen(code_div) 

export delimited using "$presim\raw_prod.csv", delimiter(";") replace


import delimited using "$presim\raw_prod.csv", delimiter(";") clear

br code*

keep code_prod code_prod prod code_div code_group code_class
*/
/* Statistical Unit
gunique hid Prod

gduplicates tag hid Prod, gen(dup)
tab dup
br if dup>0

gunique hid Prod source

* Leave out Don/Transfers 
tab source
tab methode if inlist(source, 1, 3)
*/
* Exclude auto-consumption, donation and transfers
drop if inlist(source, 1, 3)

* Variables of interest
gunique hid Prod

*gen uno = 1
*egen tag = tag(hid)
*tab uno [iw = hhweight] if tag ==1

keep hid hhweight hsize Prod dep poste milieu wilaya c_inf_mean

* HH and product level
collapse (sum) dep [aw=hhweight], by(hid hsize Prod poste milieu wilaya c_inf_mean)


/* We need the decile on consumption to then merge the deciles and products with the informality rate*/


*merge n:1 hhid using `deciles',  keepusing(ndtet) assert(matched) nogen
/*
rename  ndtet decile_expenditure
rename coicop product_code
merge n:1 decile_expenditure product_code using "$data_sn\informality_final_senegal.dta", assert(matched using) keep(master matched) keepusing(pc_non_market_purchase pc_market_purchase product_name consumption_informal consumption_all share_informal_consumption informality_purchases) nogen // products with no infor in the survey 
*/

save "$presim/05_purchases_hhid_codpr.dta", replace

