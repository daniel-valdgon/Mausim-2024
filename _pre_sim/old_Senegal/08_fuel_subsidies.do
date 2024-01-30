
/* Notes: 
- Data on prices mostly from 

	*Pg 3-5 prices of *CANAL TTC from : "structure des prix des PP du 14 december 2019.pdf" 
	* Confirmed by https://senegal.opendataforafrica.org/ahrgyqb/prix-de-vente-aux-consommateurs-des-produits-p%C3%A9troliers
	
-National Q of LPG  
	https://senpetrogaz.sn/2022/06/09/gaz-butane-un-produit-zero-taxe-au-senegal-sans-augmentation-de-prix-malgre-la-situation-mondiale-par-birame-sow

	*Q= 200,000 Tons in 2022
	la botella de 6 kg se vende a 2885 F
	la botella de 12,5 se vende a 6.250 F más barata que la de 6 kg en Malí, que supera los 6.300 Fcfa (ver la tabla anterior).
	
	*Q=164000 in 2018 (about 6000 for exports)
	Source: https://www.tresor.economie.gouv.fr/Articles/11e09942-7250-4626-8f4b-7d415d860a14/files/0363ad4a-a3ef-4b97-98fe-baab979150d3

-Take into account that prices change between 2018 and 2019 

*/ 


/**********************************************************************************
*            			1. Fuel subsidies 
**********************************************************************************/
 
use "$presim/05_purchases_hhid_codpr.dta", clear 

merge m:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta", keepusing (hhweight hhsize)




local super_carb	$sp_super_SY   // (0.75*695+0.25*775) Because 75 percent of the time of the survey was under 695. IN particular for 2018: 695, 2019: 695 April and May , 775 Jun and July 
local ess_ord		$sp_ordinaire_SY //665
local ess_pir		$sp_pirogue_SY //497


local gasoil        $sp_gasoil_SY    // 665 pero realmente era 655
local pet_lamp		$sp_pet_lamp_SY	 // 410 price per litre 
local butane		$sp_butane_SY // (4285/9) price of gas for 9kg= very close to weighted price of 2.7, 6 and 9 kg
local fuel_hh		$sp_fuel_hh_SY //497 

/*---Conversion factors 
*Quantities are for prices adjusted for temperature. OUr measures of consumption are not adjusted.Therefore for essence ordinarie 1.373 and for super 1.353
*/

/*
local conv_fuel = 0.5*1.353+ 0.5*1.373 //average super and essence
local conv_butane = 1
local conv_pet_lamp = 1.23

*Official macrodata: Regular tons (annualized based 2022 Jan-Jun from forWB IMF)/ conversion factor 25  
local macro_fuel =  350392.00 /`conv_fuel'
local macro_butane =   186088.00/`conv_fuel'
local macro_pet_lamp =  3976.00 /`conv_fuel'
*/

gen q_fuel = depan/`fuel_hh' if inlist(codpr, 208, 209, 304) // 208	Carburant pour véhicule 209	Carburant pour motocyclette 304	Carburant pour groupe electrogène à usage domestique (0.5*`super_carb'+0.5*`ess_ord')

gen q_pet_lamp=depan/`pet_lamp'  if inlist(codpr, 202)     // 202	Pétrole lampant =Kerosene
gen q_butane =depan/`butane'   if inlist(codpr, 303) // 303	Gaz domestique

/*
cap frame drop stats 
frame create stats 
frame copy default stats, replace
frame stats {

collapse (sum) q_fuel q_pet_lamp q_butane [iw=hhweight]

	foreach v in pet_lamp butane fuel {
		replace q_`v'=q_`v'*1.049109739 /1000 // 1.04 is real per-capita consumption   
		gen off_`v'=`macro_`v''
	}
	export excel using "$presim/fuels_nat_survey.xlsx",  sheet(macro_validation) replace 
}
*/


collapse (sum) q_fuel q_pet_lamp q_butane , by(hhid) 


save "$presim/08_subsidies_fuel.dta", replace



exit 




