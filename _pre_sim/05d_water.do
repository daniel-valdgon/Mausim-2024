
/* Note: 

Source: https://www.facebook.com/seneau.sn/posts/201475668025626/
https://m.facebook.com/seneau.sn/posts/231994184973774/

Il faut noter que le tarif de l’eau n’a pas connu de hausse depuis l’année 2015. Ce tarif est fixé par arrêté ministériel. Donc, depuis l’arrivée de SEN’EAU le prix de l’eau n’a pas connu de modification.
 A noter qu’il existe 3 tranches pour la facturation de l’eau potable des clients Domestiques-Particuliers:
 
•La tranche sociale qui est de 202 FCFA le m3 pour les villes assainies et 188,5 FCFA le m3 pour les villes non assainies pour un volume compris entre 1 et 20 m3 pour 60 jours de consommation. 
•La tranche pleine qui est de 697,97 FCFA le m3 pour les villes assainies et 636.34 FCFA le m3 pour les villes non assainies pour un volume compris entre 21 et 40 m3 pour 60 jours de consommation. 
•La tranche dissuasive qui est de 878,35 FCFA le m3 pour les villes assainies et 778,87 FCFA le m3 pour les villes non assainies pour un volume supérieur à 40 m3 pour 60 jours de consommation. 
- Une consommation en hausse peut donc engendrer une augmentation de la facture d’eau. 
- Fuite sur le réseau interne (dans la maison après le compteur). 
* La fuite peut être visible (apparente) ou invisible. 
* Si vous soupçonnez une fuite, faites rapidement recours aux service d’un plombier pour la vérification de votre installation intérieure. 
* Vous pouvez également faire la vérification en prenant le soin de fermer tous les robinets de la maison et de voir si le compteur continue à tourner ou pas. Si oui c’est le signal d’une fuite sur votre installation. 


*/

*---------------------Water= eau --------
/*Backward engineer M3: since spending is already annualized (DV verified with water variable from raw dataa) we first estimate the bi-monthly*/ 

use "$presim/05_purchases_hhid_codpr.dta", replace

gen eau_depbim=depan/6 if codpr==332 // bi-monthly spending 

collapse (sum) eau_depbim, by(hhid)

/*(AGV) Can we use this measure as a proxy of sanitized cities?
preserve
	merge 1:1 hhid using "$data_sn/s11_me_SEN2018.dta", nogen keepusing(s11q58)
	merge 1:1 hhid using "$data_sn/s00_me_SEN2018.dta", nogen keepusing(s00q01 s00q02 s00q03 s00q05)
	merge 1:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta", nogen keepusing(hhweight)
	gen assainie = (s11q58==1)
	gen pop=1
	collapse (sum) pop (mean) assainie [iw=hhweight], by(s00q01 s00q02 s00q03 s00q05)
	histogram assainie [fw=pop], bin(30)
	gen villes_assainies = (assainie>=0.3)
	tempfile villes_assainies
	save `villes_assainies', replace
restore
merge 1:1 hhid using "$data_sn/s00_me_SEN2018.dta", nogen keepusing(s00q01 s00q02 s00q03 s00q05)
merge m:1 s00q01 s00q02 s00q03 s00q05 using `villes_assainies', nogen
*/


*Tariffs are fixed since nove 2014. This tariffs seems to include already VAT, Surtaxe Hydraulique and Surtaxes Municipale. They are 99% of the value of several receipts in google 
*https://www.facebook.com/photo?fbid=1401808223332587&set=pcb.1401808256665917

*villes non assainies 
global price_t1 188.5
global price_t2 636.34
global price_t3 778.87 

* villes assainies (we assume this prices to be conservative abut quantities consumed and therefore about subsidy, but also impies conservative about the effect of VAT exemptions incidence since everybody is with lower consumption)
*Match with facebook receipt: First 20 mt 4K, second 20 mts 14K rest of 47 meters 42K
/*
global price_t1 201.95
global price_t2 697.97
global price_t3 878.3528  */

*We will use the prices of 

//Consumption for bracket >40 (DV)
	gen eau_quantity1=(eau_depbim+($price_t3-$price_t2)*20+($price_t3-$price_t1)*20)/$price_t3  // adding a fixed spending and dividing by "price", not sure where price is coming from 
	
	replace eau_quantity1=0 if  eau_quantity1<=40  // eau_quantity does not exist!!!!! it should be eau_quantity1 (DV)
	replace eau_quantity1=eau_quantity1-40 if eau_quantity1>40
	
//Consumption for bracket 20-40, which is even less consumption between 20 and 40 (DV)
	gen eau_quantity2=(eau_depbim+(($price_t2-$price_t1)*20))/$price_t2
	
	*br if hhid==3001
	
	replace eau_quantity2=0  if eau_quantity2<=20  
	replace eau_quantity2=20 if eau_quantity2>=40 
	replace eau_quantity2=eau_quantity2-20 if eau_quantity2>20 & eau_quantity2<40

//Consumption for bracket <20.2
	gen eau_quantity3=(eau_depbim)/$price_t1
	replace eau_quantity3=20 if eau_quantity3>=20 

//aggregating consumption variable 	
egen eau_quantity=rowtotal(eau_quantity1 eau_quantity2 eau_quantity3), missing // (DV) i use rowtotal instead of several lines adding up each tranche

/*Test */

gen value= eau_quantity3*$price_t1 +   eau_quantity2*$price_t2 +   eau_quantity1*$price_t3
compare value eau_depbim

*The numbering is confusing, 3-2-1 and 1-2-3
rename eau_quantity1 eau_quantityd
rename eau_quantity3 eau_quantity1
rename eau_quantityd eau_quantity3

save "$presim/05_water_quantities.dta", replace


exit 

Note: Original code 

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

