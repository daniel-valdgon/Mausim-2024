*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico
* Date: June 2020
* Version: 1.0
*--------------------------------------------------------------------------------

*--------------------------------------------------------------------------------
*    			   5. Excise Taxes					
*--------------------------------------------------------------------------------

*clear all
*set more off

/*
Excise Taxes
=========================================

*/

use "$data_sn/Senegal_consumption_all_by_product.dta", clear
merge n:1  grappe menage using "$root\SENEGAL_ECVHM_final\Dataout\ehcvm_conso_SEN2018_menage.dta" , nogen keepusing (hhid hhweight)

* We exclude auto-production and auto-consumption, gifts, in-kind transfers, and non-market
* bases purchase 

drop if inlist(modep,2,3,4,5)
drop if codpr==151
drop if codpr==152
drop if codpr==332
drop if codpr==333
drop if codpr==334
drop if codpr==335
drop if codpr==336
drop if codpr==337
drop if codpr==338
drop if codpr==521
drop if codpr==619
drop if codpr==620
drop if codpr==621
drop if codpr==622
drop if codpr==625
drop if codpr==644
drop if codpr==646
drop if codpr==661
drop if codpr==662
drop if codpr==663
drop if codpr==664
drop if codpr==665
drop if codpr==666
drop if codpr==667
drop if codpr==668
drop if codpr==669
drop if codpr==670
drop if codpr==671
drop if codpr==672
drop if codpr==681
drop if codpr==682
drop if codpr==683
drop if codpr==684
drop if codpr==685
drop if codpr==686
drop if codpr==691
drop if codpr==692
drop if codpr==801
drop if codpr==802
drop if codpr==803
drop if codpr==804
drop if codpr==805
drop if codpr==806
drop if codpr==807
drop if codpr==808
drop if codpr==809
drop if codpr==810
drop if codpr==811
drop if codpr==812
drop if codpr==813
drop if codpr==814
drop if codpr==815
drop if codpr==816
drop if codpr==817
drop if codpr==818
drop if codpr==819
drop if codpr==820
drop if codpr==821
drop if codpr==822
drop if codpr==823
drop if codpr==824
drop if codpr==825
drop if codpr==826
drop if codpr==827
drop if codpr==828
drop if codpr==829
drop if codpr==830
drop if codpr==831
drop if codpr==832
drop if codpr==833
drop if codpr==834
drop if codpr==835
drop if codpr==836
drop if codpr==837
drop if codpr==838
drop if codpr==839
drop if codpr==840
drop if codpr==841
drop if codpr==842
drop if codpr==843

* Boissons et boissons alcoholiques


gen boissons_alco=1 if inlist(codpr,137,138,301,302)
recode boissons_alco .=0
gen dep_boissons_alco=boissons_alco*depan

gen boissons=1 if inlist(codpr,135)
recode boissons .=0 
gen dep_boissons=boissons*depan

* Coffe

gen cafe=1 if inlist(codpr,129)
recode cafe .=0
gen dep_cafe=cafe*depan

* The

gen the=1 if inlist(codpr,130)
recode the .=0
gen dep_the=the*depan

* Corps Gras

gen beurre_et_autres=1 if inlist(codpr, 44,45,46,47,48,49,51,53,54)
recode beurre_et_autres .=0
gen dep_beurre_et_autres=beurre_et_autres*depan

gen Autres_corp_gras=1 if inlist(codpr,55,56,57,58,59)
recode Autres_corp_gras .=0
gen dep_autres_corp_gras=Autres_corp_gras*depan


* Cigarrettes

gen Cigarrettes=1 if inlist(codpr,201)
recode Cigarrettes .=0
gen dep_cigarrettes=Cigarrettes*depan


collapse (sum) dep_boissons_alco dep_boissons dep_cafe dep_the dep_beurre_et_autres dep_autres_corp_gras dep_cigarrettes  [aw=hhweight], by(hhid)

gen dep_boissons_alco_tva=dep_boissons_alco/1.18
gen dep_boissons_tva=dep_boissons/1.18
gen dep_cafe_tva=dep_cafe/1.18
gen dep_the_tva=dep_the/1.18
gen dep_beurre_et_autres_tva=dep_beurre_et_autres/1.18
gen dep_autres_corp_gras_tva=dep_autres_corp_gras/1.18
gen dep_cigarrettes_tva= dep_cigarrettes/1.18

gen double ex_alc = (dep_boissons_alco_tva)*$taux_alcohol 
gen double ex_nal = (dep_boissons_tva)*$taux_boissons
gen double ex_cof = (dep_cafe_tva)*$taux_cafe
gen double ex_tea = (dep_the_tva)*$taux_te
gen double ex_fat1= (dep_beurre_et_autres_tva)*$taux_beurre
gen double ex_fat2= (dep_autres_corp_gras_tva)*$taux_autres_corps
gen double ex_tab = (dep_cigarrettes_tva)*$taux_cigarettes

egen excise_taxes=rowtotal(ex_alc ex_nal ex_cof ex_tea ex_fat1 ex_fat2 ex_tab )


label var ex_cof       "Excise on coffee"
label var ex_tea       "Excise on Tea"
label var ex_fat1      "Excise on Fatty products 1"
label var ex_fat2      "Excise on Fatty products 2"
label var ex_alc       "Excise on Alcoholic Beverages"
label var ex_nal       "Excise on Beverages"
label var ex_tab       "Excise on Tobacco"
label var excise_taxes "Excise Taxes all"

*save "$dta/Excise_taxes.dta", replace

tempfile Excise_taxes

save `Excise_taxes'

