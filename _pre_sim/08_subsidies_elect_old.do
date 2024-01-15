

global development_elec "yes"

/**********************************************************************************
*            			1. Electricty subsidies
**********************************************************************************/
 
use "$data_sn/s12_me_SEN2018.dta", clear
 
/*------------------------------------------------
* Defining energy supplier based on assets
------------------------------------------------*/
 
keep if inlist(s12q01,14,16,20,23,37) //  14=Robot de cuisine, 16=REfrigerateur, 20=Appareil TV, 23=Lave-lige, seche linge, 37=Ordinateur
recode s12q02 2=0 // has an article: =1 Oui =0 Non

keep s12q01 s12q02 hhid grappe
bysort hhid: ereplace grappe=mean(grappe)

rename s12q02 article
drop if article!=0 & article!=1

reshape wide article, i(hhid) j(s12q01)

merge 1:1 hhid using "$data_sn/s11_me_SEN2018.dta", nogen
 
gen prix_electricite=s11q37a 	// 11.37a. Quel est le montant de la dernière facture d'électricité ? 
gen periodicite=s11q37b  		// 11.37b. Périodicité de la dernière facture
gen prepaid_woyofal=s11q36==2 | s11q36==3 if s11q36!=. // s11q36 Prepayment (Distribution of 18-19 is very different to 21

*Define monthly spending. We minimize missing data 
bysort grappe: egen aux_per=mode(periodicite)
replace periodicite=aux_per if periodicite==. & prix_electricite!=. & prix_electricite!=0 // 69 observations more


gen aux_pelec=prix_electricite 		*(30/7)		if  periodicite==1 
replace aux_pelec=prix_electricite  *1	 		if  periodicite==2 
replace aux_pelec=prix_electricite 	*0.5		if  periodicite==3 
replace aux_pelec=prix_electricite 	*0.33333			if  periodicite==4 

*Proxy to define type of energy supplier for household with electricity 
gen DGP= ((article37==1 | article14==1)  & s11q34 !=4 ) // 14=Robot de cuisine and 37=Ordinateur codes from s11q34
gen DMP= ((article16==1 | article20==1 | article23==1) & s11q34!=4 & DGP!=1) // 16=REfrigerateur, 20=Appareil TV, 23=Lave-lige, seche linge
gen DPP=  (s11q34!=4 & DMP!=1 & DGP!=1) // Rest of households withouth the assets mentioned above


gen a_type_client=.
replace a_type_client =1 if DPP==1 & aux_pelec!=. & aux_pelec!=0
replace a_type_client =2 if DMP==1 & aux_pelec!=. & aux_pelec!=0
replace a_type_client =3 if DGP==1 & aux_pelec!=. & aux_pelec!=0

*One nationwide calibration to match stats from IMF-2021

/*	 # Customers	%share of domestique clients
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
DMP=0.0034+0.0060 = 0.009544666
DGP= 0.009544666/2.27= 0.004189452, where  2.27=Kwh DMP/ Kwh DGP
DPP= 1- DMP - DGP ~ 0.4101+0.580 = 0.9862
*/

*Score of type of expected connection by grappe-cluster
merge 1:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta", keepusing (hhweight hhsize)

bysort grappe : egen  grappe_type=mean(a_type_client)
replace grappe_type=. if aux_pelec==. | aux_pelec==0

gen all=1
bysort all (grappe_type a_type_client): gen aux_s=sum(hhweight) if aux_pelec!=. & aux_pelec!=0
egen aux_stot=total(hhweight) if aux_pelec!=. & aux_pelec!=0
gen cum_grappe=aux_s/aux_stot

gen type_client=1 if cum_grappe<0.9897
replace  type_client=2 if cum_grappe<0.9993 & type_client==.
replace  type_client=3 if cum_grappe<=1 & type_client==.

drop  cum_grappe aux_stot aux_s all grappe_type _merge hhsize  

*to elimnate the previous adjustment uncomment the two lines below 
	*drop type_client
	*ren a_type_client type_client
*To simplify and make everybody a DPP
	*replace type_client=1 if type_client!=.  // this assumption assigns perfectly the 95% of domestique consumers according to  consumption and 98.6 % of consumer by number of users 

/*------------------------------------------------
* Backing out consumption from electricity spending (not clear how the hardcode numbers were written)
Note: The ideal parameters that go here is the ones were prevalent in 2018-19
*Simulations can simulate a baseline and also current expectatives
------------------------------------------------*/

*Measuring consumption for DPP= Pequenios supplier 
*Sur les taxes, la taxe communale (Tco) de 2,5% sur les tarifs pour toutes les trois tranches de consommation	
*la Taxe sur la valeur (Tva) de 18% uniquement sur les tarifs de la troisième tranche. 
*Et sur la redevance, un somme de 429 francs hors taxes est automatiquement déduite une seule fois lors du premier achat de chaque mois. 

  global price1_DPP=91.17*1.025   			// JP: 92.73  Tool:90.47  Tax 
  global price2_DPP=112.5*1.025  			// JP: 104.68 Tool: 101.64
  global price3_DPP=124.62*1.18*1.025  		// JP: 136 	  Tool: 112.65
	
  global price1_DMP=96.72*1.025  			// JP: 98.4		Tool: 96.02
  global price2_DMP=113.38*1.025 			// JP: 105.01 	Tool: 102.44
  global price3_DMP=123.92*1.025*1.18 		// JP:135.49	Tool: 112.02

  global price3_DGP=95.63*1.025*1.18 		// JP: 103 = Tool 103
  
  
/*------------------------------------------------
* Backing out consumption from electricity spending (not clear how the hardcode numbers were written)
------------------------------------------------*/

*Measuring consumption for DPP= Small suppliers ranges 150,250,+

	gen consumption_DPP3= ((aux_pelec - ((100*${price2_DPP})+(150*${price1_DPP})))/${price3_DPP}) if type_client==1
		replace consumption_DPP3=0 if consumption_DPP3<0 & type_client==1
	gen consumption_DPP2= ((aux_pelec - (150*${price1_DPP}))/${price2_DPP}) if type_client==1
		replace consumption_DPP2=0 if consumption_DPP2<0 & type_client==1
		replace consumption_DPP2=100 if consumption_DPP2!=. & consumption_DPP2>100 & type_client==1
	gen consumption_DPP1= aux_pelec/${price1_DPP} if type_client==1
		replace consumption_DPP1=150 if consumption_DPP1!=. & consumption_DPP1>150 & type_client==1
	
*Measuring consumption for DMP= Medium suppliers 50,300,+

	gen consumption_DMP3 = ((aux_pelec - ((250*${price2_DMP})+(50*${price1_DMP})))/${price3_DMP}) if type_client==2
		replace consumption_DMP3=0 if consumption_DMP3<0 & type_client==2
	gen consumption_DMP2= ((aux_pelec - (50*${price1_DMP}))/${price2_DMP}) if type_client==2
		replace consumption_DMP2=0 if consumption_DMP2<0 & type_client==2
		replace consumption_DMP2=250 if consumption_DMP2!=. & consumption_DMP2>250 & type_client==2
	gen consumption_DMP1= aux_pelec/${price1_DMP} if type_client==2
		replace consumption_DMP1=50 if consumption_DMP1!=. & consumption_DMP1>50 & type_client==2

*Measuring consumption for  DGP = Grande suppliers 
	gen consumption_DGP= (aux_pelec-956.13)/${price3_DGP} if type_client==3 // 956 is a fixed consumption 
	
	egen consumption_electricite=rowtotal(consumption_DMP* consumption_DPP* consumption_DGP)
	

/*------------------------------------------------
* Assigning consumption in each bracket 
------------------------------------------------*/
egen tranche1= rowtotal(consumption_DPP1 consumption_DMP1)
egen tranche2= rowtotal(consumption_DPP2 consumption_DMP2)
egen tranche3= rowtotal(consumption_DPP3 consumption_DMP3 )	// we are excluding consumption_DGP from tranche 3

note: electricity quantities and total spending are in monthly values (2018-19)

save "$presim/08_subsidies_elect.dta", replace



if "$development_elec"=="yes" {

*How many of households have a monthly/bill consumption of tranche 3 
gen tranche3_sh=consumption_electricite>250 

*VAT Kwh taxed 
egen kwh_vat_exempt_post=rowtotal(tranche1 tranche2) if  prepaid_woyofal==0
replace kwh_vat_exempt_post=0 if tranche3==0 

egen kwh_vat_exempt=rowtotal(tranche1 tranche2)
replace kwh_vat_exempt=0 if tranche3==0 

collapse (sum) consumption_electricite kwh_vat_exempt_post kwh_vat_exempt  (mean)  tranche3_sh [iw=hhweight]
replace consumption_electricite=consumption_electricite*12/1000000
replace kwh_vat_exempt=kwh_vat_exempt*12/1000000
replace kwh_vat_exempt_post=kwh_vat_exempt_post*12/1000000


list

dis as err " please remember to change the global of development_elec when finished"
}


exit 

