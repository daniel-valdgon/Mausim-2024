
/* 
	Code when testing electricity tariffs
	global reference_period "nmonthly" // nmonthly: means that tresholds are independent of periodicity. monthly means that thresholds are not independent of periodicity , so first we need to normalize everything to monthly
	
*/
global development_elec "no"
/**********************************************************************************
*            			1. Preparing data 
**********************************************************************************/
 
/*------------------------------------------------
* Loading data
------------------------------------------------*/

use "$data_sn/s12_me_SEN2018.dta", clear
 
keep if inlist(s12q01,14,16,20,23,37) //  14=Robot de cuisine, 16=REfrigerateur, 20=Appareil TV, 23=Lave-lige, seche linge, 37=Ordinateur
recode s12q02 2=0 // has an article: =1 Oui =0 Non

keep s12q01 s12q02 hhid 

rename s12q02 article
drop if article!=0 & article!=1

reshape wide article, i(hhid) j(s12q01)

merge 1:1 hhid using "$data_sn/s11_me_SEN2018.dta", nogen

*Spending,  periodicity and pre-payment status
gen prix_electricite=s11q37a 	// 11.37a. Quel est le montant de la dernière facture d'électricité ? 
gen periodicite=s11q37b  		// 11.37b. Périodicité de la dernière facture
gen prepaid_woyofal=s11q36==2 | s11q36==3 if s11q36!=. // s11q36 Prepayment (Distribution of 2018-19 is very different to 2021

/*------------------------------------------------
* Type of energy power (petite, Moyenne, Grande) 
------------------------------------------------*/
 
*Proxy to define type of energy supplier for household with electricity 
gen DGP= ((article37==1 | article14==1)  & s11q34 !=4 ) // 14=Robot de cuisine and 37=Ordinateur codes from s11q34
gen DMP= ((article16==1 | article20==1 | article23==1) & s11q34!=4 & DGP!=1) // 16=REfrigerateur, 20=Appareil TV, 23=Lave-lige, seche linge
gen DPP=  (s11q34!=4 & DMP!=1 & DGP!=1) // Rest of households withouth the assets mentioned above


gen a_type_client=.
replace a_type_client =1 if DPP==1 & prix_electricite!=. & prix_electricite!=0
replace a_type_client =2 if DMP==1 & prix_electricite!=. & prix_electricite!=0
replace a_type_client =3 if DGP==1 & prix_electricite!=. & prix_electricite!=0

/*	 # Customers	%share of domestique clients
*One nationwide calibration to match stats from IMF-2021
 P_DPP 	634286	0.410110285
 P_DMP 	5350	0.003459149
 P_PPP 	127457	
 P_PMP 	15340	
 W_DPP 	897575	0.580345049
 W_DMP 	9412	0.006085517
 W_PPP 	238640	
 W_PMP 	17730
 P_DGP 	1027 
Only Domestique	1546623	

Notice Wofoyal vs Post-paid distribution is very different 
*/

*Score of type of expected connection by grappe-cluster
merge 1:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta", keepusing (hhweight hhsize grappe)

bysort grappe : egen  grappe_type=mean(a_type_client)
replace grappe_type=. if prix_electricite==. | prix_electricite==0

gen all=1
sort hhid, stable
bysort all (grappe_type a_type_client): gen aux_s=sum(hhweight) if prix_electricite!=. & prix_electricite!=0
egen aux_stot=total(hhweight) if prix_electricite!=. & prix_electricite!=0
gen cum_grappe=aux_s/aux_stot

gen type_client=1 if cum_grappe<0.9897
replace  type_client=2 if cum_grappe<0.9993 & type_client==.
replace  type_client=3 if cum_grappe<=1 & type_client==.

/*------------------------------------------------
* Imputations for periodicity and pre-paid 
------------------------------------------------*/

bysort grappe: egen aux_per=mode(periodicite)
replace periodicite=aux_per if periodicite==. & prix_electricite!=. & prix_electricite!=0 // 69 observations more

// impute pre-paid using country knowledge 
replace prepaid_woyofal=0 if  periodicite==3 & prepaid_woyofal==.

// impute pre-paid using based on mode 
bysort grappe: egen aux_pre=mode(prepaid_woyofal)
replace prepaid_woyofal=aux_pre if prepaid_woyofal==. & prix_electricite!=. & prix_electricite!=0 // 105 observations

*mdesc prepaid_woyofal periodicite

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


drop  cum_grappe aux_stot aux_s all grappe_type _merge hhsize  

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

*note: electricity quantities and total spending are in bi-monthly values (2018-19)!!!


/*------------------------------------------------
* Projecting pre-paid distribution to 2022 (60 vs 40%)
Note: this goes at the end of the do-file because we assume consumption is the same but the tag pre-paid vs postpaid is different. 
This implies that even under 2018 parameters I will have a different depan because pre-paid tariffs will be applied to origianlly post paid people 
------------------------------------------------*/

/*
logit prepaid_woyofal  prix_electricite i.a_type_client i.s00q01 i.s00q02 i.s00q04
predict prepaid_woyofal_hat2,

cap gen all=1
recode prepaid_woyofal (1=-1) , gen(temp_prepaid_woyofal)
bysort all (temp_prepaid_woyofal prepaid_woyofal_hat2): gen aux_pre2=sum(hhweight) if prix_electricite!=. & prix_electricite!=0
egen aux_stot_pre2=total(hhweight) if prix_electricite!=. & prix_electricite!=0
gen cum_pre2=aux_pre2/aux_stot_pre2


replace temp_prepaid_woyofal=-1 if cum_pre2<0.5955 // distribution of pre-paid in 2021 from here https://www.senelec.sn/chiffres-cls , could be updated to 2022 or restrcited to hosuehold but the important gains are from here because we jump from 25 to 60 percent 
recode temp_prepaid_woyofal (-1=1) , gen(prepaid_woyofal2)

clonevar prepaid_or=prepaid_woyofal
replace prepaid_woyofal=prepaid_woyofal2
*/

*-----------------------------

keep hhid aux_pelec_m aux_pelec  prix_electricite periodicite consumption_electricite tranche1 tranche2 tranche3 consumption_DGP prepaid_woyofal type_client consumption_D* s11q24a  consumption_electricite_yr tranche1_yr tranche2_yr tranche3_yr consumption_DGP_yr hhweight a_type_client s00q01 s00q02 s00q04
order hhid
sort hhid 
save "$presim/08_subsidies_elect.dta", replace

****************Test for monthly to bimonthly 


if "$development_elec"=="yes" {

replace consumption_electricite=consumption_electricite*1.27
*How many of households have a monthly/bill consumption of tranche 3 
gen tranche3_sh=consumption_electricite>250 if prepaid_woyofal==0
replace tranche3_sh=consumption_electricite>500 if prepaid_woyofal==1

*VAT Kwh taxed 
egen kwh_vat_exempt_post=rowtotal(tranche1 tranche2) if  prepaid_woyofal==0
replace kwh_vat_exempt_post=0 if tranche3==0 


egen kwh_vat_exempt=rowtotal(tranche1 tranche2)
replace kwh_vat_exempt=0 if tranche3==0 

collapse (sum) kwh_vat_exempt kwh_vat_exempt_post consumption_electricite (mean)  tranche3_sh [iw=hhweight]
replace consumption_electricite=consumption_electricite*6/1000000
replace kwh_vat_exempt=kwh_vat_exempt*6/1000000
replace kwh_vat_exempt_post=kwh_vat_exempt_post*6/1000000


list

noi dis as err " Remember to turn-off the global of development_elec when finish to debug the file"
}







exit 
********************************
********************************
********************************
********************************
********************************

comprobacion

use "$presim/08_subsidies_elect.dta", clear

gen redevance = 872 if prepaid_woyofal==0			//postpaid
replace redevance = 429 if prepaid_woyofal==1		//prepaid

gen gasto_tranche1 = tranche1/1
replace gasto_tranche1 = gasto_tranche1*90.47  if type_client==1 & prepaid_woyofal==0
replace gasto_tranche1 = gasto_tranche1*96.02  if type_client==2 & prepaid_woyofal==0
replace gasto_tranche1 = gasto_tranche1*90.47  if type_client==1 & prepaid_woyofal==1
replace gasto_tranche1 = gasto_tranche1*96.02  if type_client==2 & prepaid_woyofal==1

gen gasto_tranche2 = tranche2/1
replace gasto_tranche2 = gasto_tranche2*101.64 if type_client==1 & prepaid_woyofal==0
replace gasto_tranche2 = gasto_tranche2*102.44 if type_client==2 & prepaid_woyofal==0
replace gasto_tranche2 = gasto_tranche2*101.64 if type_client==1 & prepaid_woyofal==1
replace gasto_tranche2 = gasto_tranche2*102.44 if type_client==2 & prepaid_woyofal==1

gen gasto_tranche3 = tranche3/1
replace gasto_tranche3 = gasto_tranche3*112.65 if type_client==1 & prepaid_woyofal==0
replace gasto_tranche3 = gasto_tranche3*112.02 if type_client==2 & prepaid_woyofal==0
replace gasto_tranche3 = gasto_tranche3*101.64 if type_client==1 & prepaid_woyofal==1
replace gasto_tranche3 = gasto_tranche3*102.44 if type_client==2 & prepaid_woyofal==1

gen taxe_communale = 0.025*(gasto_tranche1+gasto_tranche2+gasto_tranche3)

gen tva = 0.18*gasto_tranche3

gen factura_bimonthly = redevance+gasto_tranche1+gasto_tranche2+gasto_tranche3+taxe_communale+tva

*br factura prix_electricite

scatter factura_bimonthly prix_electricite
scatter factura_bimonthly aux_pelec, msize(tiny)
br factura_bimonthly aux_pelec type_client if factura_bimonthly != aux_pelec
gen dif = factura_bimonthly-aux_pelec

scatter factura prix_electricite if type_client==1 & prepaid_woyofal==0

merge 1:1 hhid using "$data_sn\ehcvm_conso_SEN2018_menage.dta" , nogen keepusing (grappe menage hhweight)
merge 1:m grappe menage using "$data_sn/Senegal_consumption_all_by_product.dta", 
tab modep if codpr==334
keep if codpr==334
scatter depan factura_bimonthly

use "$data_sn/Senegal_consumption_all_by_product.dta", clear


/**************************


Note: Tariffs before the change in 2019 

  global price1_DPP=90.47*1.025   					// JP: 92.73  Tool: 90.47  Tax 
  global price2_DPP=101.64*1.025  					// JP: 104.68 Tool: 101.64
  global price3_DPP=112.65*1.18*1.025  				// JP: 136 	  Tool: 112.65 1stdraf IMF: 124.62
	
  global price1_DMP=96.02*1.025  					// JP: 98.4		Tool: 96.02
  global price2_DMP=102.44*1.025 					// JP: 105.01 	Tool: 102.44 1st draft IMF: 113.38
  global price3_DMP=112.02*1.025*1.18 				// JP:135.49	Tool: 112.02

  global price3_DGP=(86.3+120.81)*0.5*1.025*1.18 		// JP: 103 = Tool 103
  



*The code below is made for statistis not needed to be run in the tool so I added an exit 
merge 1:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta", keepusing (hhweight hhsize)

gen all=1

*Annual spending 
gen aux_pelec_annual=aux_pelec*12 // aux_pelec is already harmonized to monthly 

collapse (sum) aux_pelec_annual	tranche1 tranche2 tranche3 consumption_DPP1 consumption_DMP1 consumption_DPP2 consumption_DMP2 consumption_DPP3 consumption_DMP3 consumption_DGP  consumption_electricite all [iw=hhweight]

replace aux_pelec_annual=aux_pelec_annual/1000000000 // bllns of annual CFA
format %20.3g aux_pelec_annual
foreach v in  tranche1 tranche2 tranche3 consumption_DPP1 consumption_DMP1 consumption_DPP2 consumption_DMP2 consumption_DPP3 consumption_DMP3 consumption_DGP  consumption_electricite  {
format %20.3g `v'
replace `v'=12*`v'/1000000
}

order consumption_electricite all tranche1 tranche2 tranche3
br

/*
*----------------------------------------------------------
*----------------------------------------------------------
*----------------------------------------------------------



 Test to validate the backward enginerr of Kwh consumed
*----------------------------------------------------------
*----------------------------------------------------------
*----------------------------------------------------------

 - This test creates simulated data on monthly Kwh consumption and electricity bill 
 - We assume we do not know the Kwh consume by each household and using the price parameters we back out consumption 
 - The latest laines test if the way we backout consumption was correct.  */
*DPP  150,250,+
*DMP  50,300,+


/*------------------------------------------------
* Defining energy supplier based on assets same as original do'file 
------------------------------------------------*/
	use "$data_sn/s12_me_SEN2018.dta", clear
	
	keep if inlist(s12q01,37,14,20,16,23) //  14=Robot de cuisine, 16=REfrigerateur, 20=Appareil TV, 23=Lave-lige, seche linge, 37=Ordinateur
	recode s12q02 2=0 // has an article: =1 Oui =0 Non
	
	keep s12q01 s12q02 hhid
	rename s12q02 article
	drop if article!=0 & article!=1
	
	reshape wide article, i(hhid) j(s12q01)
	
	merge 1:1 hhid using "$data_sn/s11_me_SEN2018.dta", nogen
	
	
	*Proxy to define type of energy supplier for household with electricity 
	gen DGP= ((article37==1 |article14==1)  & s11q34 ==1) // see article labels above, s11q34
	gen DMP= ((article16==1 | article20==1 | article23==1) & s11q34==1 & DGP!=1) // refrig & tv & lavadora 5 & robot10
	gen DPP=(s11q34==1 & DMP!=1) //
	gen type_client=.
	replace type_client =1 if DPP==1
	replace type_client =2 if DMP==1
	replace type_client =3 if DGP==1

/*------------------------------------------------
* Simulated consumption: TOtal and by tranche
------------------------------------------------*/

	generate kw_sim = runiformint(0, 400) if type_client!=.
	gen tanche1_sim=0
	gen tanche2_sim=0
	gen tanche3_sim=0
	
	*trance 1 in Kwh
	replace tanche1_sim=150 if type_client==1 & kw_sim>=150
		replace tanche1_sim=kw_sim if type_client==1 & kw_sim<150
	replace tanche1_sim=50 if type_client==2 & kw_sim>=50
		replace tanche1_sim=kw_sim if type_client==2 & kw_sim<50
	
	*trance 2
	replace  tanche2_sim=100 if type_client==1 & kw_sim>=250
		replace tanche2_sim=kw_sim-150 if type_client==1 & kw_sim>150 & kw_sim<250
	replace  tanche2_sim=250 if type_client==2 & kw_sim>=300
		replace tanche2_sim=kw_sim-50 if type_client==2 & kw_sim>50 & kw_sim<300
	
	
	*trance 3
	replace  tanche3_sim=kw_sim-250 if type_client==1 & kw_sim>=250
	replace tanche3_sim=kw_sim-300 if type_client==2 & kw_sim>=300
	
	replace tanche3_sim=kw_sim if type_client==3

/*------------------------------------------------
* Simulated electricity bill 
------------------------------------------------*/

	
  global  cost = 150
  global price1_DPP=90.47   
  global price2_DPP=101.64 
  global price3_DPP=112.65 
	
  global price1_DMP=96.02  
  global price2_DMP=102.44 
  global price3_DMP=112.02 

  global price3_DGP=103.55

   gen spending_sim=tanche1_sim*${price1_DPP} + tanche2_sim* ${price2_DPP} + tanche3_sim *${price3_DPP} if type_client==1
   replace spending_sim=tanche1_sim*${price1_DMP} + tanche2_sim* ${price2_DMP} + tanche3_sim *${price3_DMP} if type_client==2
   replace spending_sim=tanche3_sim*${price3_DGP}  if type_client==3

/*------------------------------------------------
* Backing out consumption from electricity spending (not clear how the hardcode numbers were written)
------------------------------------------------*/


*Measuring consumption for DPP= Small suppliers ranges 150,250,+

	gen consumption_DPP3= ((spending_sim - ((100*${price2_DPP})+(150*${price1_DPP})))/${price3_DPP}) if type_client==1
		replace consumption_DPP3=0 if consumption_DPP3<0 & type_client==1
	gen consumption_DPP2= ((spending_sim - (150*${price1_DPP}))/${price2_DPP}) if type_client==1
		replace consumption_DPP2=0 if consumption_DPP2<0 & type_client==1
		replace consumption_DPP2=100 if consumption_DPP2!=. & consumption_DPP2>100 & type_client==1
	gen consumption_DPP1= spending_sim/${price1_DPP} if type_client==1
		replace consumption_DPP1=150 if consumption_DPP1!=. & consumption_DPP1>150 & type_client==1
	
*Measuring consumption for DMP= Medium suppliers 50,300,+

	gen consumption_DMP3 = ((spending_sim - ((250*${price2_DMP})+(50*${price1_DMP})))/${price3_DMP}) if type_client==2
		replace consumption_DMP3=0 if consumption_DMP3<0 & type_client==2
	gen consumption_DMP2= ((spending_sim - (50*${price1_DMP}))/${price2_DMP}) if type_client==2
		replace consumption_DMP2=0 if consumption_DMP2<0 & type_client==2
		replace consumption_DMP2=250 if consumption_DMP2!=. & consumption_DMP2>250 & type_client==2
	gen consumption_DMP1= spending_sim/${price1_DMP} if type_client==2
		replace consumption_DMP1=50 if consumption_DMP1!=. & consumption_DMP1>50 & type_client==2

*Measuring consumption for  DGP = Grande suppliers 
	gen consumption_DGP= spending_sim/${price3_DGP} if type_client==3
	
	egen consumption_electricite=rowtotal(consumption_DMP* consumption_DPP* consumption_DGP)
		

/*------------------------------------------------
* Assigning consumption in each bracket 
------------------------------------------------*/
	egen tranche1= rowtotal(consumption_DPP1 consumption_DMP1)
	egen tranche2= rowtotal(consumption_DPP2 consumption_DMP2)
	egen tranche3= rowtotal(consumption_DPP3 consumption_DMP3 consumption_DGP)	

/*------------------------------------------------
------------------------------------------------*/
/*------------------------------------------------
* TEST: Kwh computed with our methodology are the same as Kwh simulated by tranche and in total
------------------------------------------------*/
/*------------------------------------------------
------------------------------------------------*/

	compare kw_sim consumption_electricite
	compare tranche1 tanche1_sim
	compare tranche2 tanche2_sim
	compare tranche3 tanche3_sim
