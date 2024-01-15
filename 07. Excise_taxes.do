*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: CEQ Senegal -  5. Excise Taxes					
* Author: Julieth Pico
* Date: June 2020
* Version: 1.0
* Modified: September 2022
*			- Streamlined, take part to pre_sim
*			May 2023 (AG)
*			- Included new excises from recent laws
*			- Excel TVA rates taken into account (before they were hardcoded as 1.18)
*--------------------------------------------------------------------------------


if $devmode== 1 {
    use "$tempsim/Subsidies_verylong.dta", clear
}
else{
	use `Subsidies_verylong', clear
}

global depan achats_sans_subs

*********************************************************
*2. Calculate expenses from products with excises
*********************************************************


noi dis as result " 1. Boissons et boissons alcoholiques"
	gen boissons_alco=1 if inlist(codpr,137,138,301,302)
	recode boissons_alco .=0
	gen dep_boissons_alco=boissons_alco*$depan

	gen boissons=1 if inlist(codpr,135,133)  //Loi 2018-10: Elle s'applique également aux jus obtenus à partir de fruits ou légumes (133)
	recode boissons .=0 
	gen dep_boissons=boissons*$depan


noi dis as result " 2. Café"
	gen cafe=1 if inlist(codpr,129)
	recode cafe .=0
	gen dep_cafe=cafe*$depan


noi dis as result " 3. Thé"
	gen the=1 if inlist(codpr,130)
	recode the .=0
	gen dep_the=the*$depan


noi dis as result " 4. Beurres et Corps Gras"
	gen beurre_et_autres=1 if inlist(codpr, 44,45,46,47,48,49,51,53,54)
	recode beurre_et_autres .=0
	gen dep_beurre_et_autres=beurre_et_autres*$depan

	gen Autres_corp_gras=1 if inlist(codpr,55,56,57,58,59,32)  //Loi 2020-33: Elle s'applique également aux charcuteries (32)
	recode Autres_corp_gras .=0
	gen dep_autres_corp_gras=Autres_corp_gras*$depan


noi dis as result " 5. Tabacs"
	gen Cigarrettes=1 if inlist(codpr,201)
	recode Cigarrettes .=0
	gen dep_cigarrettes=Cigarrettes*$depan


noi dis as result " 6. Produits cosmetiques" //  (Check ordonnance 007-2020)
	gen cosmetiques = 1 if inlist(codpr,321,415)
	recode cosmetiques .=0
	gen dep_cosmetiques = cosmetiques*$depan


noi dis as result " 7. Bouillons alimentaires" //  (Check Loi 2021-29)
	gen bouillons = 1 if inlist(codpr,121,122)
	recode bouillons .=0
	gen dep_bouillons = bouillons*$depan


*Taxe sur les sachets, conditionnements ou emballages non récupérables en plastique: (Check Loi 2022-19)
*Ask later how to account for this tax. Seems imposible


noi dis as result " 8. Textiles" //  (Check Loi 2020-33)
gen textiles = 1 if inlist(codpr,501,502,503,504,505,506,521,804,806,615)
recode textiles .=0
gen dep_textiles = textiles*$depan


gen double ex_alc = (dep_boissons_alco)*$taux_alcohol 
gen double ex_nal = (dep_boissons)*$taux_boissons
gen double ex_cof = (dep_cafe)*$taux_cafe
gen double ex_tea = (dep_the)*$taux_te
gen double ex_fat1= (dep_beurre_et_autres)*$taux_beurre
gen double ex_fat2= (dep_autres_corp_gras)*$taux_autres_corps
gen double ex_tab = (dep_cigarrettes)*$taux_cigarettes
gen double ex_cos = (dep_cosmetiques)*$taux_cosmetiques
gen double ex_bou = (dep_bouillons)*$taux_bouillons
gen double ex_tex = (dep_textiles)*$taux_textiles

egen excise_taxes=rowtotal(ex_alc ex_nal ex_cof ex_tea ex_fat1 ex_fat2 ex_tab ex_cos ex_bou ex_tex )


*Confirmation that the calculation is correct for the survey year policies:
gen achats_avec_excises = achats_net_excise + excise_taxes

if $asserts_ref2018 == 1{
	gen dif3m = achats_net_VAT - achats_avec_excises
	tab codpr if abs(dif3m)>0.0001
	assert abs(dif3m)<0.0001
}



*We are interested in the detailed long version, to continue the confirmation process with VAT

if $devmode== 1 {
    save "$tempsim/Excises_verylong.dta", replace
}
tempfile Excises_verylong
save `Excises_verylong'





*Finally, we are only interested in the per-household amounts, so we will collapse the database:

collapse (sum) dep_boissons_alco dep_boissons dep_cafe dep_the dep_beurre_et_autres dep_autres_corp_gras dep_cigarrettes dep_cosmetiques dep_bouillons dep_textiles ex*, by(hhid)

label var ex_cof       "Excise on coffee"
label var ex_tea       "Excise on Tea"
label var ex_fat1      "Excise on Fatty products 1"
label var ex_fat2      "Excise on Fatty products 2"
label var ex_alc       "Excise on Alcoholic Beverages"
label var ex_nal       "Excise on Beverages"
label var ex_tab       "Excise on Tobacco"
label var ex_cos       "Excise on Cosmetic Products"
label var ex_bou       "Excise on Bouillons"
label var ex_tex       "Excise on Textiles"
label var excise_taxes "Excise Taxes all"

if $devmode== 1 {
	sum ex_*
	save "${tempsim}/Excise_taxes.dta", replace
}

tempfile Excise_taxes
save `Excise_taxes'


