/*********************************************************/
noi dis "{opt Spending Adjustment for changes in income coming from direct taxes and transfers}"
/*********************************************************/

use "$data_sn/ehcvm_conso_SEN2018_menage.dta", clear

/* Disposable Income in the survey year */
gen double yd_pre=round(dtot/hhsize,0.01)

if $devmode== 1 {
merge 1:1 hhid using "${tempsim}/income_tax_collapse.dta" , nogen
merge 1:1 hhid using "${tempsim}/social_security_contribs.dta" , nogen
merge 1:1 hhid using "${tempsim}/Direct_transfers.dta"  , nogen
}
else {
merge 1:1 hhid using `income_tax_collapse' , nogen
merge 1:1 hhid using `social_security_contribs' , nogen
merge 1:1 hhid using `Direct_transfers'  , nogen
}


*merge 1:1 hhid using "$data_sn/perfect_targetting1.dta", nogen
merge 1:1 hhid using "$data_sn/gross_ymp_pc.dta" , nogen
recast double ymp_pc

local Directaxes 		"income_tax trimf"
local Contributions 	"csp_ipr csp_fnr csh_css csh_ipm csh_mutsan" //(AGV) Note that csh_mutsan is created in 7DirTransfers and not in 3SSC (as it should)
local DirectTransfers   "am_bourse am_Cantine am_BNSF am_subCMU"
local Policies 			`Directaxes' `Contributions' `DirectTransfers'
	  


foreach var of local Policies {
	recast double `var'
	replace `var' = `var'/hhsize
	replace `var' = 0 if `var' ==.
}

egen double aux_resta= rowtotal(`Directaxes' `Contributions' )
egen double aux_suma= rowtotal(`DirectTransfers' )

gen double yd_post = round(ymp_pc - aux_resta + aux_suma,0.01)


gen double dif_grossup = yd_post-yd_pre
count if abs(dif_grossup) >0.1
if `r(N)'>0{
	*noi dis as error "The disposable income obtained is different than the per capita consumption that we assumed in the grossing up."
	*noi dis as error "This happened because you changed policies that affected direct transfers, income tax, or SS contributions."
	noi dis as error "There were changes to PIT, transfers or social security contributions that made the current disposable income different from the baseline."
	*assert `r(N)'==0
}
else {
	noi dis "{opt The disposable income obtained is equal to the per capita consumption that we assumed in the grossing up.}"
	noi dis "{opt This means that you have not changed any policies related with direct transfers, income tax, or SS contributions.}"
}

keep hhid yd_pre yd_post

gen double adjustment_factor = yd_post/yd_pre
compress
if $devmode== 1 {
    save "$tempsim/adjustment_spending.dta", replace
}
tempfile adjustment_spending
save `adjustment_spending'

/*********************************************************
2. Adjusting depan (aggregated and netted_down)
*********************************************************/

use "$presim/05_purchases_hhid_codpr.dta", clear 
merge n:1 hhid using `adjustment_spending' , nogen keepusing(adjustment_factor)

replace depan = depan*adjustment_factor

save "$tempsim/05_purchases_hhid_codpr_Adjusted.dta", replace 

use "$presim/05_netteddown_expenses_SY.dta", clear 
merge n:1 hhid using `adjustment_spending' , nogen keepusing(adjustment_factor)

replace achat_gross 		= adjustment_factor*achat_gross
replace achats_net_VAT 		= adjustment_factor*achats_net_VAT
replace achats_net_excise 	= adjustment_factor*achats_net_excise
replace achats_net_subind 	= adjustment_factor*achats_net_subind
replace achats_net 			= adjustment_factor*achats_net

compress
save "$tempsim/05_netteddown_expenses_SY_Adjusted.dta", replace 

/*********************************************************
3. Pulling globals from survey year 
*********************************************************/

import excel "$xls_sn", sheet("p_Ref_2018") first clear    
	local globales "TariffT1_eau TariffT2_eau TariffT3_eau MaxT1_eau MaxT2_eau sp_super sp_ordinaire sp_pirogue sp_gasoil sp_pet_lamp sp_butane sp_fuel_hh"
	foreach z of local globales {
		levelsof globalcontent if globalname=="`z'", local(val)
		global `z'_SY `val'
	}

/*********************************************************
4. Adjusting electricity (space for improvement in September)
*********************************************************/


use "$data_sn/s12_me_SEN2018.dta", clear
 
keep if inlist(s12q01,14,16,20,23,37) //  14=Robot de cuisine, 16=REfrigerateur, 20=Appareil TV, 23=Lave-lige, seche linge, 37=Ordinateur
recode s12q02 2=0 // has an article: =1 Oui =0 Non

keep s12q01 s12q02 hhid

rename s12q02 article
drop if article!=0 & article!=1

reshape wide article, i(hhid) j(s12q01)

merge 1:1 hhid using "$data_sn/s11_me_SEN2018.dta", nogen

if $devmode== 1 {
    merge 1:1 hhid using "$tempsim/adjustment_spending.dta", nogen
}
else{
	merge 1:1 hhid using `adjustment_spending', nogen
}

*Spending,  periodicity and pre-payment status
gen prix_electricite=s11q37a*adjustment_factor 	// 11.37a. Quel est le montant de la dernière facture d'électricité ? 
gen periodicite=s11q37b  		// 11.37b. Périodicité de la dernière facture

/*------------------------------------------------
* Type of energy power (petite, Moyenne, Grande) 
------------------------------------------------*/
 
*Proxy to define type of energy supplier for household with electricity 

merge 1:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(a_type_client type_client prepaid_woyofal hhweight) nogen assert(match)


/*------------------------------------------------
* Consumption in monthly and bi-monthly values 
------------------------------------------------*/


* Pre-paid costumers theshold depends on Bi-monthly consumption: This assumption makes sense with info in newspapers about the implications of the increase in prices of 2019 {7K-mes, 15K-bimonthly}. Receipts confirmed this also. 
	
gen aux_pelec=prix_electricite 		*(2*30.42/7)		if  periodicite==1 //Weekly
replace aux_pelec=prix_electricite  *2	 				if  periodicite==2 //Monthly
replace aux_pelec=prix_electricite 	*1					if  periodicite==3 // Bimonthly
replace aux_pelec=prix_electricite 	*2/4				if  periodicite==4 // Quarter


* Post-paid costumers tranches are based on monthly consumption (Petra Valickova info)
gen 	aux_pelec_m=prix_electricite 	*(30.42/7)			if  periodicite==1 //Weekly
replace aux_pelec_m=prix_electricite  	*1	 				if  periodicite==2 //Monthly
replace aux_pelec_m=prix_electricite 	*0.5				if  periodicite==3 // Bimonthly
replace aux_pelec_m=prix_electricite 	*1/4				if  periodicite==4 // Quarter



/**********************************************************************************
*       			2. Backing out consumption from electricity spending 
**********************************************************************************/

*Tariffs of 2019
	
	/* 
	Additional components to the tariff:
		TCO of 2.5%: Sur les taxes, la taxe communale (Tco) de 2,5% sur les tarifs pour toutes les trois tranches de consommation	
		VAT on third tranche: la Taxe sur la valeur (Tva) de 18% uniquement sur les tarifs de la troisième tranche. 
		Redevance lump sum: I use 872 as redevence based on electricity bill pictures. 429 for pre-paid 

		https://www.seneplus.com/economie/senelec-confine-ses-abonnes-dans-les-tranches-dachat
		https://www.facebook.com/senelecofficiel/photos/a.285487988767323/857068984942551/?type=3
		
		All tariffs from 2019 before the decree of december 1st from Senelec's 
	*/
	
* Post-paid tariffs 
  global price1_DPP=90.47*1.025   			 
  global price2_DPP=101.64*1.025  			
  global price3_DPP=112.65*1.18*1.025  		
	
  global price1_DMP=96.02*1.025  			
  global price2_DMP=102.44*1.025 			
  global price3_DMP=112.02*1.025*1.18 		

  global price3_DGP=103.55*1.025*1.18 // We do not have info for 2019 before the big increase only for 2020, which is 115.54 so we use 90% of that price 
   
* Pre-paid tariffs 
  global price1_WDPP=90.47*1.025   			 
  global price2_WDPP=101.64*1.025  			
  global price3_WDPP=101.64*1.18*1.025  		
	
  global price1_WDMP=96.02*1.025  			
  global price2_WDMP=102.44*1.025 			
  global price3_WDMP=102.44*1.025*1.18 		

 
/*------------------------------------------------
* Backing out consumption from electricity spending 
Post-paid tariffs 
----------------------------------------------*/

*Measuring consumption for DPP= Small suppliers ranges 150,250,+

	gen consumption_DPP3= ((aux_pelec - (872+(100*${price2_DPP})+(150*${price1_DPP})))/${price3_DPP}) if type_client==1 
		replace consumption_DPP3=0 if consumption_DPP3<0 & type_client==1
	gen consumption_DPP2= ((aux_pelec - (872+150*${price1_DPP}))/${price2_DPP}) if type_client==1
		replace consumption_DPP2=0 if consumption_DPP2<0 & type_client==1
		replace consumption_DPP2=100 if consumption_DPP2!=. & consumption_DPP2>100 & type_client==1
	gen consumption_DPP1= (aux_pelec-872)/${price1_DPP} if type_client==1
		replace consumption_DPP1=150 if consumption_DPP1!=. & consumption_DPP1>150 & type_client==1
		replace consumption_DPP1=0 if consumption_DPP1<0
	
*Measuring consumption for DMP= Medium suppliers 50,300,+

	gen consumption_DMP3 = ((aux_pelec - (872+(250*${price2_DMP})+(50*${price1_DMP})))/${price3_DMP}) if type_client==2
		replace consumption_DMP3=0 if consumption_DMP3<0 & type_client==2
	gen consumption_DMP2= ((aux_pelec - (872+50*${price1_DMP}))/${price2_DMP}) if type_client==2
		replace consumption_DMP2=0 if consumption_DMP2<0 & type_client==2
		replace consumption_DMP2=250 if consumption_DMP2!=. & consumption_DMP2>250 & type_client==2
	gen consumption_DMP1= (aux_pelec-872)/${price1_DMP} if type_client==2
		replace consumption_DMP1=50 if consumption_DMP1!=. & consumption_DMP1>50 & type_client==2

*Previous estimates are only valid for post-paid users (prepaid_woyofal==0)	
	foreach v in consumption_DPP3 consumption_DPP2 consumption_DPP1 consumption_DMP3 consumption_DMP2 consumption_DMP1 {
		replace `v'=. if prepaid_woyofal==1 // only valid (non-missing) for prepaid_woyofal==0 
	}
	
/*------------------------------------------------
* Backing out consumption from electricity spending 
Pre-paid tariffs 
----------------------------------------------*/

*Measuring consumption for DPP= Small suppliers ranges 150,250,+

	gen consumption_DPP3_m= ((aux_pelec_m - (429+(100*${price2_WDPP})+(150*${price1_WDPP})))/${price3_WDPP}) if type_client==1
		replace consumption_DPP3_m=0 if consumption_DPP3_m<0 & type_client==1
	gen consumption_DPP2_m= ((aux_pelec_m - (429+150*${price1_WDPP}))/${price2_WDPP}) if type_client==1
		replace consumption_DPP2_m=0 if consumption_DPP2_m<0 & type_client==1
		replace consumption_DPP2_m=100 if consumption_DPP2_m!=. & consumption_DPP2_m>100 & type_client==1
	gen consumption_DPP1_m= (aux_pelec_m-429)/${price1_WDPP} if type_client==1
		replace consumption_DPP1_m=150 if consumption_DPP1_m!=. & consumption_DPP1_m>150 & type_client==1
	
*Measuring consumption for DMP= Medium suppliers 50,300,+

	gen consumption_DMP3_m = ((aux_pelec_m - (429+(250*${price2_WDMP})+(50*${price1_WDMP})))/${price3_WDMP}) if type_client==2
		replace consumption_DMP3_m=0 if consumption_DMP3_m<0 & type_client==2
	gen consumption_DMP2_m= ((aux_pelec_m - (429+50*${price1_WDMP}))/${price2_WDMP}) if type_client==2
		replace consumption_DMP2_m=0 if consumption_DMP2_m<0 & type_client==2
		replace consumption_DMP2_m=250 if consumption_DMP2_m!=. & consumption_DMP2_m>250 & type_client==2
	gen consumption_DMP1_m= (aux_pelec_m-429)/${price1_WDMP} if type_client==2
		replace consumption_DMP1_m=50 if consumption_DMP1_m!=. & consumption_DMP1_m>50 & type_client==2

*Previous estimates are only valid for pre-paid (v=. if prepaid_woyofal==0), also use monthly consumption and therefore monthly Kwh consumed. We multiply by two 	
	foreach v in consumption_DPP3_m consumption_DPP2_m consumption_DPP1_m consumption_DMP3_m consumption_DMP2_m consumption_DMP1_m {
		replace `v'=. if prepaid_woyofal==0 // only valid (non-missing) for prepaid_woyofal==1
		replace `v'=`v'*2 // to put derived consumption in bi-monthly units 
	}
	

/*------------------------------------------------
* Backing out consumption of DGP (do not have pre-paid vs post-paid differentiation, we asume bi-monthly
----------------------------------------------*/
*Measuring consumption for  DGP = Grande suppliers 
	gen consumption_DGP= (aux_pelec-869.21-872)/${price3_DGP} if type_client==3 // Prime Fixe Mensuelle en FCFA/kW 869 + 872 redevance as fixed cost 
	replace consumption_DGP=0 if consumption_DGP==.

/*------------------------------------------------
* Assigning consumption in each bracket 
------------------------------------------------*/
egen consumption_electricite=rowtotal(consumption_DMP* consumption_DPP* consumption_DGP)
	egen tranche1= rowtotal(consumption_DPP1* consumption_DMP1*)
	egen tranche2= rowtotal(consumption_DPP2* consumption_DMP2*)
	egen tranche3= rowtotal(consumption_DPP3* consumption_DMP3*)	// we are excluding consumption_DGP from tranche 3

label var 	consumption_electricite "Bi-monthly electricity consumption"
label var tranche1 "Bi-monthly consumption for tranche 1 (pre & post)"
label var tranche2 "Bi-monthly consumption for tranche 2 (pre & post)"
label var tranche3 "Bi-monthly consumption for tranche 3 (pre & post)"

foreach v in consumption_electricite tranche1 tranche2 tranche3 consumption_DGP {
	gen `v'_yr=`v'*6
	local lab: variable label `v'
	local sub_Lab=substr("`lab'", 11,.)
	label var `v'_yr "Yearly `sub_Lab'"
}
*-----------------------------

keep hhid aux_pelec_m aux_pelec  prix_electricite periodicite consumption_electricite tranche1 tranche2 tranche3 consumption_DGP prepaid_woyofal type_client consumption_D* s11q24a  consumption_electricite_yr tranche1_yr tranche2_yr tranche3_yr consumption_DGP_yr hhweight a_type_client s00q01 s00q02 s00q04
order hhid
sort hhid 
compress
save "$tempsim/08_subsidies_elect_Adjusted.dta", replace

/*********************************************************
5. Adjusting water 
*********************************************************/


use "$tempsim/05_purchases_hhid_codpr_Adjusted.dta", replace

gen eau_depbim=depan/6 if codpr==332 // bi-monthly spending 
collapse (sum) eau_depbim, by(hhid)

*villes non assainies 
global price_t1 $TariffT1_eau_SY //188.5
global price_t2 $TariffT2_eau_SY //636.3
global price_t3 $TariffT3_eau_SY //778.8

global Max_t1 $MaxT1_eau_SY //20
global Max_t2 $MaxT2_eau_SY //40

//Consumption for bracket >40
	gen eau_quantity3=(eau_depbim+($price_t3-$price_t2)*($Max_t2-$Max_t1)+($price_t3-$price_t1)*$Max_t1)/$price_t3  
	replace eau_quantity3=0 if  eau_quantity3<=$Max_t2
	replace eau_quantity3=eau_quantity3-$Max_t2 if eau_quantity3>$Max_t2
	
//Consumption for bracket 20-40, which is even less consumption between 20 and 40
	gen eau_quantity2=(eau_depbim+(($price_t2-$price_t1)*$Max_t1))/$price_t2
	replace eau_quantity2=0       if eau_quantity2<=$Max_t1
	replace eau_quantity2=$Max_t1 if eau_quantity2>=$Max_t2
	replace eau_quantity2=eau_quantity2-$Max_t1 if eau_quantity2>$Max_t1 & eau_quantity2<$Max_t2

//Consumption for bracket <20.2
	gen eau_quantity1=(eau_depbim)/$price_t1
	replace eau_quantity1=$Max_t1 if eau_quantity1>=$Max_t1 

//aggregating consumption variable 	
egen eau_quantity=rowtotal(eau_quantity1 eau_quantity2 eau_quantity3), missing

/*Test */

gen value= eau_quantity1*$price_t1 +   eau_quantity2*$price_t2 +   eau_quantity3*$price_t3
compare value eau_depbim

label var eau_quantity "m3 water consumed bimonthly"
compress
save "$tempsim/05_water_quantities_Adjusted.dta", replace


/*********************************************************
5. Adjusting fuels
*********************************************************/


use "$tempsim/05_purchases_hhid_codpr_Adjusted.dta", clear 

merge m:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta", keepusing (hhweight hhsize)

local super_carb	$sp_super_SY   // (0.75*695+0.25*775) Because 75 percent of the time of the survey was under 695. IN particular for 2018: 695, 2019: 695 April and May , 775 Jun and July 
local ess_ord		$sp_ordinaire_SY //665
local ess_pir		$sp_pirogue_SY //497
local gasoil        $sp_gasoil_SY    // 665 pero realmente era 655
local pet_lamp		$sp_pet_lamp_SY	 // 410 price per litre 
local butane		$sp_butane_SY // (4285/9) price of gas for 9kg= very close to weighted price of 2.7, 6 and 9 kg
local fuel_hh		$sp_fuel_hh_SY //497 

gen q_fuel = depan/`fuel_hh' if inlist(codpr, 208, 209, 304) // 208	Carburant pour véhicule 209	Carburant pour motocyclette 304	Carburant pour groupe electrogène à usage domestique (0.5*`super_carb'+0.5*`ess_ord')

gen q_fuel208 = depan/`fuel_hh' if inlist(codpr, 208)
gen q_fuel209 = depan/`fuel_hh' if inlist(codpr, 209)
gen q_fuel304 = depan/`fuel_hh' if inlist(codpr, 304)

gen q_pet_lamp=depan/`pet_lamp' if inlist(codpr, 202)     // 202	Pétrole lampant =Kerosene
gen q_butane = depan/`butane'   if inlist(codpr, 303)     // 303	Gaz domestique

collapse (sum) q_fuel* q_pet_lamp q_butane , by(hhid) 
compress
save "$tempsim/08_subsidies_fuel_Adjusted.dta", replace


































