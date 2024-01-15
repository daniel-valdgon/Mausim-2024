
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico based on Paul Corral - Indirect effects - VAT Ecuador
* Date: June 2020
* Version: 1.0
*--------------------------------------------------------------------------------

*--------------------------------------------------------------------------------
*    			      4.1 Indirect Effects						
*--------------------------------------------------------------------------------

*===================================================================*
*	4.1.1 Load IO matrix
*===================================================================*

*clear all
*set more off

tempfile ieffects_vat_SN_aux
tempfile Aux_Products_TVA
*tempfile Aux_IO_matrix
tempfile ieffects_vat_SN

use `IO_matrix_expanded' , clear

split nom_compte2, p("_")
gen TVA = nom_compte22
destring TVA, replace

*import excel "$xls/Impuestos indirectos/IO_final.xlsx", sheet("IO_matrix_final") cellrange(A1:CX101) firstrow clear

foreach x of varlist *{
	cap confirm numeric variable `x'
	if _rc==0 local mylist `mylist' `x'
}


/* When read in STATA, the IO Aij coefficients matrix column names are treated by Stata as variables. In 
this step a local macro called sectors is defined and assigned column names which is used as headings for
displaying results */



*===============================================================================
// Items that carry VAT, 
*===============================================================================

 
*-------------------------------------------------------------------------------                 
** Step 4.1.2. indicate VAT products                
*-------------------------------------------------------------------------------
gen dpt_tva = 0
gen tva_red = (1-(1/(1+(TVA/100))))


*** Aca debo poner los productos que a pesar de tener IVA 0 en verdad no pueden cobrar
*** el IVA pagado en otros productos.


gen yes_tva=1
replace yes_tva=0 if nom_compte22=="0"

replace dpt_tva = tva_red if yes_tva==1

gen dpt_all = 0

levelsof (nom_compte2) if yes_tva==1, local(secteurs) 

foreach x of local secteurs{
	gen dpt_`x' = 0
	replace dpt_`x' = (1-(1/(1+(TVA/100)))) if nom_compte2=="`x'"
	replace dpt_all = (1-(1/(1+(TVA/100)))) if nom_compte2=="`x'"
}


*-------------------------------------------------------------------------------------------------------
** Step 4.1.3. Compute indirect price effects on prices of other goods and services as listed in the IO table accounts.                                                             
*-------------------------------------------------------------------------------------------------------
** Define matrices  
gen fixed = 0  
replace fixed=1 if nom_compte22!="0" & nom_compte22!=""


* Product with fixed prices are: public services, education and health


local nogo C22 C28 C32 C33 C34                                          

//Mark fixed prices
foreach x of local nogo{
	replace fixed = 1 if  nom_compte21=="`x'"
}

drop if nom_compte2==""

levelsof nom_compte2, clean local(nom)

costpush `nom',fixed(fixed) priceshock(dpt_tva) genptot(ptot_ivashock) ///
	 genpind(pind_ivashock) 
		
keep nom_compte2 pind_ivashock ptot_ivashock

save `ieffects_vat_SN_aux', replace

*--------------------------------------------------------------------------------
*    			      4.2 Total Effects						
*--------------------------------------------------------------------------------

merge 1:n nom_compte2 using `Aux_IO_matrix' , gen(merged)
drop if merged!=3

merge n:1 codpr Secteur using "$data_sn/IO_percentage2.dta", gen(merged2)
drop if merged2==2

recode pourcentage .=1
gen aux_effect_indirect= pind_ivashock*pourcentage


collapse (sum) aux_effect_indirect (mean) TVA formelle , by(codpr)

save `ieffects_vat_SN'


*===================================================================*
*===================================================================*
*				4.2.1. Total Effects
*===================================================================*
*===================================================================*

*===================================================================*
*	4.2.1.1. Loading the Expenditure Database
*===================================================================*


use "$data_sn/Senegal_consumption_all_by_product.dta", clear
merge n:1  grappe menage using "$root\SENEGAL_ECVHM_final\Dataout\ehcvm_conso_SEN2018_menage.dta" , nogen keepusing (hhid hhweight)

* We exclude auto-production and auto-consumption, gifts, in-kind transfers, and non-market
* bases purchase 

drop if inlist(modep,2,3,4,5)

collapse (sum) depan [aw=hhweight], by(hhid codpr)

merge n:1 codpr using `ieffects_vat_SN' , gen(merged3)
drop if merged3!=3

save "$root_vat\VAT_including_indirect_effects.dta", replace


/* Let's merge with all the database we need to get the resutls */

/* First we need the correlation between the products on the Senegal database and COICOP */
merge n:1 codpr using "$root_vat\correlation_COICOP_senegal.dta" , nogen keepusing(coicop)

/* We need the decile on consumption to then merge the deciles and products with the informality rate*/

merge n:1 hhid using "$root\SENEGAL_ECVHM_final\Dataout\ehcvm_conso_SEN2018_menage.dta" , nogen keepusing(ndtet)

rename  ndtet decile_expenditure
rename coicop product_code
merge n:1 decile_expenditure product_code using "$root_vat\informality_final_senegal.dta" , nogen


/*First we determine the m3 consumed, as just the consumption above 40 m3 pays VAT*/
gen eau_depbim=depan/6 if codpr==332
gen eau_quantity1=(eau_depbim+17070.71)/878.3528 
replace eau_quantity1=. if  eau_quantity<40
gen eau_quantity2=(eau_depbim+9855.4)/697.97
replace eau_quantity2=. if eau_quantity2<=20 | eau_quantity2>40 
gen eau_quantity3=(eau_depbim)/201.95
replace eau_quantity3=. if eau_quantity3>20.2

gen eau_quantity= eau_quantity1
replace eau_quantity= eau_quantity2 if eau_quantity==.
replace eau_quantity= eau_quantity3 if eau_quantity==.

gen eau_quantity_no_TVA=-40 if codpr==332 & eau_quantity>40
replace eau_quantity_no_TVA= -eau_quantity if codpr==332 &  eau_quantity<=40

egen eau_quantity_TVA=rowtotal(eau_quantity eau_quantity_no_TVA)

* We replace the amount payed by the household on the water and sewage bill for the amount over the one they will pay the VAT*/
replace depan=((eau_quantity_TVA)*(739.96))*6 if eau_quantity>40 & codpr==332
replace depan=0 if eau_quantity<=40 & codpr==332

*replace depan=eau_depbim*6 if  eau_quantity>40 & codpr==332
*replace depan=0 if eau_quantity<=40 & codpr==332


/* First we determine the Kwh consumed, as just the consumption above  Kwh pays VAT*/

merge n:1 hhid using "$dta/Electricity_subsidies.dta", keepusing(tranche3 periodicite) gen(merged_electricity)

replace depan=((tranche3*112.65)+866)*12 if codpr==334 & tranche3!=0 & periodicite==1
replace depan=((tranche3*112.65)+866)*6 if codpr==334 & tranche3!=0 & periodicite==2
replace depan=((tranche3*112.65)+866)*4 if codpr==334 & tranche3!=0 & periodicite==3
replace depan=((tranche3*112.65)+866)*3 if codpr==334 & tranche3!=0 & periodicite==4
replace depan=0 if tranche3==0 & codpr==334

/* Education just for private schools */
/*
merge n:1 hhid using "$dta/public_school.dta", gen(merged_public)

replace depan=0 if codpr==642 & pub_school==1
replace depan=0 if codpr==643 & pub_school==1
replace depan=0 if codpr==661 & pub_school==1
replace depan=0 if codpr==664 & pub_school==1
replace depan=0 if codpr==667 & pub_school==1
replace depan=0 if codpr==670 & pub_school==1

*/
/*
merge n:1 hhid using "$dta/Electricity_subsidies.dta", keepusing(tranche3 periodicite prix_electricite) 

replace depan=prix_electricite*12 if codpr==334 & periodicite==1 & tranche3!=0
replace depan=prix_electricite*6 if codpr==334 & periodicite==2 & tranche3!=0
replace depan=prix_electricite*4 if codpr==334 & periodicite==3 & tranche3!=0
replace depan=prix_electricite*3 if codpr==334 & periodicite==4 & tranche3!=0 
replace depan=0 if tranche3==0 & codpr==334 
*/
*save "C:\Users\wb521296\OneDrive - WBG\Desktop\VAT_senegal\before_behavioral_responses.dta", replace

/*
gen formal= depan*(1-informality_purchases)
gen informal= depan*informality_purchases

gen     Tax_TVA_formal=formal*((TVA/100)/(1+(TVA/100))) if TVA==18
replace Tax_TVA_formal=formal*((TVA/100)/(1+(TVA/100))) if TVA==10
replace  Tax_TVA_formal=formal*(aux_effect_indirect/(1+aux_effect_indirect)) if TVA==0

gen Tax_TVA_informal1=informal*0
gen Tax_TVA_informal2=informal*(aux_effect_indirect/(1+aux_effect_indirect))
gen Tax_TVA_informal3=informal*0 if formelle==0
replace Tax_TVA_informal3=informal*(aux_effect_indirect/(1+aux_effect_indirect)) if formelle==1

egen Tax_TVA1=rowtotal(Tax_TVA_formal Tax_TVA_informal1)
egen Tax_TVA2=rowtotal(Tax_TVA_formal Tax_TVA_informal2)
egen Tax_TVA3=rowtotal(Tax_TVA_formal Tax_TVA_informal3)
	
gen efective_VAT= Tax_TVA1/ depan
gen efective_VAT2= Tax_TVA2/ depan
gen efective_VAT3= Tax_TVA3/ depan

save "$dta/Final_TVA_Tax_DPO.dta", replace

collapse (sum) Tax_TVA* TVA depan , by(hhid)

save "$dta/Final_TVA_Tax.dta", replace
*/

*=============================================================================*
*					Introduce Behavioral Responses 							  *
*=============================================================================*

gen factor_behavioral=.
replace factor_behavioral=0.92188 if codpr==1
replace factor_behavioral=0.92188 if codpr==2
replace factor_behavioral=0.92188 if codpr==3
replace factor_behavioral=0.92188 if codpr==4
replace factor_behavioral=0.92188 if codpr==5
replace factor_behavioral=0.92188 if codpr==6
replace factor_behavioral=0.92188 if codpr==7
replace factor_behavioral=0.92188 if codpr==8
replace factor_behavioral=0.92188 if codpr==9
replace factor_behavioral=0.92188 if codpr==10
replace factor_behavioral=0.92188 if codpr==11
replace factor_behavioral=0.88552 if codpr==23
replace factor_behavioral=0.88552 if codpr==24
replace factor_behavioral=0.88552 if codpr==25
replace factor_behavioral=0.88552 if codpr==26
replace factor_behavioral=0.88552 if codpr==27
replace factor_behavioral=0.88552 if codpr==28
replace factor_behavioral=0.88552 if codpr==29
replace factor_behavioral=0.88552 if codpr==30
replace factor_behavioral=0.88552 if codpr==31
replace factor_behavioral=0.88552 if codpr==32
replace factor_behavioral=0.88552 if codpr==33
replace factor_behavioral=0.88552 if codpr==34
replace factor_behavioral=0.86698 if codpr==35
replace factor_behavioral=0.86698 if codpr==36
replace factor_behavioral=0.86698 if codpr==37
replace factor_behavioral=0.86698 if codpr==38
replace factor_behavioral=0.86698 if codpr==39
replace factor_behavioral=0.86698 if codpr==40
replace factor_behavioral=0.86698 if codpr==41
replace factor_behavioral=0.87382 if codpr==44
replace factor_behavioral=0.87382 if codpr==52
replace factor_behavioral=0.90658 if codpr==72
replace factor_behavioral=0.90658 if codpr==73
replace factor_behavioral=0.90658 if codpr==74
replace factor_behavioral=0.90658 if codpr==75
replace factor_behavioral=0.90658 if codpr==76
replace factor_behavioral=0.90658 if codpr==77
replace factor_behavioral=0.90658 if codpr==78
replace factor_behavioral=0.90658 if codpr==79
replace factor_behavioral=0.90658 if codpr==80
replace factor_behavioral=0.90658 if codpr==81
replace factor_behavioral=0.90658 if codpr==82
replace factor_behavioral=0.90658 if codpr==83
replace factor_behavioral=0.90658 if codpr==84
replace factor_behavioral=0.90658 if codpr==85
replace factor_behavioral=0.90658 if codpr==86
replace factor_behavioral=0.90658 if codpr==87
replace factor_behavioral=0.90658 if codpr==88
replace factor_behavioral=0.90658 if codpr==89
replace factor_behavioral=0.90658 if codpr==90
replace factor_behavioral=0.90658 if codpr==92
replace factor_behavioral=0.90658 if codpr==93
replace factor_behavioral=0.90658 if codpr==94
replace factor_behavioral=0.90658 if codpr==95
replace factor_behavioral=0.90658 if codpr==96
replace factor_behavioral=0.90658 if codpr==97
replace factor_behavioral=0.90658 if codpr==98
replace factor_behavioral=0.90658 if codpr==99
replace factor_behavioral=0.90658 if codpr==101
replace factor_behavioral=0.90658 if codpr==102
replace factor_behavioral=0.90658 if codpr==103
replace factor_behavioral=0.90658 if codpr==104
replace factor_behavioral=0.90658 if codpr==105
replace factor_behavioral=0.90658 if codpr==106
replace factor_behavioral=0.90658 if codpr==107
replace factor_behavioral=0.90658 if codpr==108
replace factor_behavioral=0.90658 if codpr==109
replace factor_behavioral=0.90658 if codpr==110
replace factor_behavioral=0.75628 if codpr==205
replace factor_behavioral=0.683308 if codpr==210
replace factor_behavioral=0.683308 if codpr==211
replace factor_behavioral=0.683308 if codpr==212
replace factor_behavioral=0.683308 if codpr==213
replace factor_behavioral=0.683308 if codpr==214
replace factor_behavioral=0.683308 if codpr==215
replace factor_behavioral=0.678934 if codpr==216
replace factor_behavioral=0.756928 if codpr==303
replace factor_behavioral=0.678934 if codpr==315
replace factor_behavioral=0.756928 if codpr==331
replace factor_behavioral=0.662914 if codpr==408
replace factor_behavioral=0.683308 if codpr==629
replace factor_behavioral=0.683308 if codpr==630
replace factor_behavioral=0.692758 if codpr==642
replace factor_behavioral=0.692758 if codpr==643
replace factor_behavioral=0.73774 if codpr==649
replace factor_behavioral=0.73774 if codpr==650
replace factor_behavioral=0.73774 if codpr==651
replace factor_behavioral=0.692758 if codpr==661
replace factor_behavioral=0.692758 if codpr==664
replace factor_behavioral=0.692758 if codpr==667
replace factor_behavioral=0.692758 if codpr==670
replace factor_behavioral=0.699382 if codpr==686
replace factor_behavioral=0.699382 if codpr==692
replace factor_behavioral=0.756928 if codpr==810

/* Medicine services */

merge n:1 hhid using "$root\SENEGAL_ECVHM_final\Dataout\poor.dta" , keepusing(poor) nogen

replace factor_behavioral=0.96634 if inlist(codpr, 681, 682, 683, 684, 685, 691) & poor==1
replace factor_behavioral=0.98578 if inlist(codpr, 681, 682, 683, 684, 685, 691) & poor==0


/* Water and electricity, be carefull because the change on consumption should be just for tranches 1 and 2*/

replace factor_behavioral=0.756928 if codpr==332
replace factor_behavioral=0.94096 if codpr==334 & poor==1
replace factor_behavioral=0.94969 if codpr==334 & poor==0

recode factor_behavioral .=1
/*
replace factor_behavioral=1 if inlist(codpr, 205, 210, 211, 212, 213, 214, 215, 216)
replace factor_behavioral=1 if inlist(codpr, 303, 315, 331, 408, 629, 630, 642, 643)
replace factor_behavioral=1 if inlist(codpr, 649, 650, 651, 661, 664, 667, 670, 681)
replace factor_behavioral=1 if inlist(codpr, 682, 683, 684, 685, 686, 691, 692, 810)
replace factor_behavioral=1 if inlist(codpr, 332, 334)
*/

gen factor_behavioral_f=factor_behavioral

replace factor_behavioral_f=1


*replace factor_behavioral_f=factor_behavioral  if   codpr>=1 & codpr<=138    // aliment 

*replace factor_behavioral_f=factor_behavioral   if   (codpr>=1 & codpr<=138) & !inlist(codpr,17,35,648,114,58,1,23,48,38,7,83,129,56	,2,130,29,30,18,25,73,74,6,121,45,16,77,41,53,91,104,95,119	,84	,98	,85,140,109,100,37,79,81,44,36,107,4,26,55,52,39,78)	// basket 

*replace factor_behavioral_f=factor_behavioral  if   (codpr>=1 & codpr<=138) & !inlist(codpr, 17 ,35 , 648,114,58,1,23,48,38,7,83,129,56,2,130,29,30,18,25,73,74,6,121,45,16)   // basket 25

*replace factor_behavioral_f=factor_behavioral if inlist(codpr,210,214,629)    // transport select

*replace factor_behavioral_f=factor_behavioral    if inlist(codpr,216)

* replace factor_behavioral_f=factor_behavioral  if inlist(codpr,303)

*replace factor_behavioral_f=factor_behavioral    if inlist(codpr,210,211,212,213,214,215,629)   // transport 

* Transport
*replace factor_behavioral_f=factor_behavioral if inlist(codpr,210,211,212,213,214,215,629)
*eplace factor_behavioral_f=factor_behavioral if inlist(codpr,210,214,629)
* Jornaux
 *replace factor_behavioral_f=factor_behavioral if inlist(codpr,216)
* Gaz domestique
*replace factor_behavioral_f=factor_behavioral if inlist(codpr,303)
* Loyer 

*replace factor_behavioral_f=factor_behavioral if    codpr==331

*Education
*replace factor_behavioral_f=factor_behavioral if inlist(codpr,642,643,661,664,667,670)
* Santé
*replace factor_behavioral_f=factor_behavioral if inlist(codpr,681,682,683,684,685,686,691,692)
* water
*replace factor_behavioral_f=factor_behavioral if inlist(codpr,332)
*Electricity
*replace factor_behavioral_f=factor_behavioral if inlist(codpr,334)

replace depan=depan*factor_behavioral_f

gen formal= depan*(1-informality_purchases)
gen informal= depan*informality_purchases


gen Tax_TVA_formal=formal*((TVA/100)/(1+(TVA/100))) if TVA==18
replace Tax_TVA_formal=formal*((TVA/100)/(1+(TVA/100))) if TVA==10
replace  Tax_TVA_formal=formal*(aux_effect_indirect/(1+aux_effect_indirect)) if TVA==0

gen Tax_TVA_informal1=informal*0
gen Tax_TVA_informal2=informal*(aux_effect_indirect/(1+aux_effect_indirect))
gen Tax_TVA_informal3=informal*0 if formelle==0
replace Tax_TVA_informal3=informal*(aux_effect_indirect/(1+aux_effect_indirect)) if formelle==1

egen Tax_TVA1=rowtotal(Tax_TVA_formal Tax_TVA_informal1)
egen Tax_TVA2=rowtotal(Tax_TVA_formal Tax_TVA_informal2)
egen Tax_TVA3=rowtotal(Tax_TVA_formal Tax_TVA_informal3)
	
gen efective_VAT= Tax_TVA1/ depan
gen efective_VAT2= Tax_TVA2/ depan
gen efective_VAT3= Tax_TVA3/ depan

** groups 

gen exempted=depan if TVA==0

gen aliment=1 if codpr>=1 & codpr<=138

gen aliment_exem=depan                                           if  aliment==1  & TVA==0

gen aliment_exem_infor=depan*informality_purchases               if  aliment==1  & TVA==0

gen non_aliment_exem=depan                                       if  aliment==.  & TVA==0

gen non_aliment_exem_infor=depan*informality_purchases           if  aliment==.  & TVA==0

local esc_vat=settings[2,1]

dis("`esc_vat'")

rename Tax_TVA`esc_vat' Tax_TVA

collapse (mean) informality_purchases formelle (sum)Tax_TVA_informal3 Tax_TVA_formal  Tax_TVA TVA depan exempted aliment_exem aliment_exem_infor non_aliment_exem non_aliment_exem_infor , by(hhid)

tempfile Final_TVA_Tax

save `Final_TVA_Tax' 
