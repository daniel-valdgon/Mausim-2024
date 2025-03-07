

/*

Author     : Madi Mangan
Start date : 16 May 2024
Last Update: 20 May 2024 

*/


// Note codpr_elec = 326 in our expenditure by product data. 

/**********************************************************************************
*            			1. Preparing data 
**********************************************************************************/ 
 
/*------------------------------------------------
* Loading data
------------------------------------------------*/

*----- Data on connectivity to electricity using housing data 

use "$data_sn/housing.dta" , clear
		gen use_elec = s8aq12 ==1
		keep hid use_elec
		ren hid hhid 

		tempfile elec 
save `elec', replace 



/*------------------------------------------------
* Electricity data 
------------------------------------------------*/

use "$presim/05_purchases_hhid_codpr.dta", clear
		ren hhid hid 
		merge m:1 hid using "$data_sn/GMB_IHS2020_E_hhsize.dta" , nogen keepusing(wta_hh_c nfdelec lga district) assert(matched)
		ren (wta_hh_c hid lga nfdelec) (hhweight hhid region depan1)
		merge m:1 hhid using `elec', nogen

		
		replace depan = depan1 if codpr == 326
		gen codpr_elec = codpr == 326 // Electricity product
		gen domestic = 1

		drop hsize 

		keep if codpr_elec == 1 
		drop if hhweight == . 

		*----- HH Coverage
		gen hh_elec = depan > 0                         // Option 1: Positive expenses on depan
		replace hh_elec = 1 if use_elec ==1 & depan ==0 // Option 2: HH principal source of electricity

/*------------------------------------------------
* Allocation of domestic and social users
------------------------------------------------*/

* Set parameters
		local vat = 1.15
		local tarif_s = 10.14*`vat' 
		local prime_fix_s = 0*`vat'

		local tarif_d = 10.14*`vat' // 5.9 MRU
		local prime_fix_d = 0*`vat'

		local redevance = 0*`vat'

* Test consumption: All HH are social users
		gen kwh_test = ((depan - (`prime_fix_s' * 12) - (`redevance' * 12)) / `tarif_s' ) / 12 if depan>0 // this includes VAT assuming everybody pay it  
		assert kwh_test>0 // You did have values lower than zero because you apply the formula when depan==0
		tabstat kwh_test [aw = hhweight], s(p50 mean sum) by(hh_elec) 



* Allocate household based on consumption 
       bysort hh_elec (kwh_test): gen cum_hhs=sum(hhweight) if hh_elec==1


* Expenditure and consumption
		gen tarif = `tarif_d' if domestic == 1 
		replace tarif = `tarif_s' if domestic == 0  
		gen prime_fix = `prime_fix_d' if domestic == 1 
		replace prime_fix = `prime_fix_s' if domestic == 0   

* Get annual kWh
		gen kwh = (depan - (prime_fix * 12) - (`redevance' * 12)) / (tarif) if depan>0 // Assumes everybody pay VAT, underestimate the consumption of Kwh

		replace kwh = 0 if kwh < 0 

		gen kwh_bi = round(kwh / 6, 1) // Bi-Monthly kwh

/*------------------------------------------------
* Define type of client
------------------------------------------------*/

		gen type_client = 1 if domestic == 0
		replace type_client = 2 if domestic == 1

		mvencode type_client, mv(0) // @do we need type_client==0 ? No to the tool but it will be needed in the figures dofile

		gen prepaid_woyofal = 0
		gen tranche = 1 // Not needed in the tool but needed in the figures data

		ren kwh_bi consumption_electricite

		keep hhid codpr type_client consumption_electricite prepaid_woyofal hh_elec* codpr_elec depan

		* Label
		label define type_client 0 "No Elec." 1 "Social" 2 "Domestic" 
		label values type_client type_client

		label define prepaid_woyofal 0 "Prepaid" 1 "Postpaid"
		label values prepaid_woyofal prepaid_woyofal

		label define hh_elec 0 "No" 1 "Yes"
		label values hh_elec hh_elec

		label var type_client				"Type of subscriber"
		label var consumption_electricite	"KWh consummed by household (Bi-Monthly)"
		label var prepaid_woyofal			"Type of facture (prepaid or postpaid)"
		label var codpr_elec				"Electricity product"
		label var hh_elec					"Household has access to electricity" 
*hh_elec1,2,3 are no needed, only for comparison purposes on the figures dofile


save "$presim/08_subsidies_elect.dta", replace




