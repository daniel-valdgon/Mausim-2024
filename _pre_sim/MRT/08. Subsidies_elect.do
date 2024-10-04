
/**********************************************************************************
*            			1. Preparing data 
**********************************************************************************/ 
 
/*------------------------------------------------
* Loading data
------------------------------------------------*/

set seed 123456789


*----- Data on household location 
use "$data_sn/menage_2019.dta", clear
 
    * Creating the household id
    tostring US_ORDRE A7, replace
    gen len = length(A7)
    replace A7 = "0" + A7 if len == 1
    gen hhid = US_ORDRE + A7
    destring hhid, replace  
    
    * Relevant variables  
    keep hhid A1 A2 A3 A42 A5 A6 A10*

tempfile grape 
save `grape', replace 

*----- Data on connectivity to electricity 
use "$data_sn/Capital_Social_2019.dta", clear // I
 
 * Creating the household id
   
    tostring US_ORDRE A7, replace
    gen len = length(A7)
    replace A7 = "0" + A7 if len == 1
    gen hhid = US_ORDRE + A7
    destring hhid, replace  
 
    gunique US_ORDRE A7
 
    * Standardize / Filter
    keep if I0 == 4
    keep hhid I*

tempfile capital_social 
save `capital_social', replace 

*----- Articles
use "$data_sn/menage_2019.dta", clear 

    * hhid
    tostring US_ORDRE A7, replace
    gen len = length(A7)
    replace A7 = "0" + A7 if len == 1
    gen hhid = US_ORDRE + A7
    destring hhid, replace
    
    * Unicity
    keep hhid G7

tempfile elec 
save `elec', replace 

/*------------------------------------------------
* Electricity data 
------------------------------------------------*/

use "$presim/05_purchases_hhid_codpr.dta", clear

merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight) assert (matched)
merge m:1 hhid using `grape', nogen keep(1 3)
merge m:1 hhid using `capital_social', nogen
merge m:1 hhid using `elec', nogen

drop hhsize 

gen codpr_elec = codpr == 376 // Electricity product

keep if codpr_elec == 1 
drop if hhweight == . 

*----- HH Coverage
gen hh_elec_1 = I8 == 1 // Option 1: HH uses electricity
gen hh_elec_2 = G7 == 1 // Option 2: HH principal source of electricity
gen hh_elec_3 = depan > 0 // Option 3: Positive expenses on depan 

gen hh_elec = depan > 0 & I8 == 1

*if ($hh_coverage == 1) gen hh_elec = depan > 0 & I8 == 1
*if ($hh_coverage == 2) gen hh_elec = depan > 0 & G7 == 1 // Djibril Option

/*------------------------------------------------
* Allocation of domestic and social users
------------------------------------------------*/

* Set parameters
	local vat = 1.16
	local tarif_s = 24.6*`vat' // 2.46 MRU
	local prime_fix_s = 279.9*`vat'

	local tarif_d = 59*`vat' // 5.9 MRU
	local prime_fix_d = 1650.7*`vat'

	local redevance = 404*`vat'

* Test consumption: All HH are social users
    gen kwh_test = ((depan - (`prime_fix_s' * 12) - (`redevance' * 12)) / `tarif_s' ) / 12 if depan>0 // this includes VAT assuming everybody pay it  
    assert kwh_test>0 // You did have values lower than zero because you apply the formula when depan==0
    tabstat kwh_test [aw = hhweight], s(p50 mean sum) by(hh_elec) 

/* Second rule - by grape
	* Average consumption by grape (A42)
    gen all = 1
    egen kwh_com = total(kwh_test), by(A42)
    egen aux_all = total(all * hhweight), by(A42)
    egen aux_yes = total(hh_elec * hhweight), by(A42)
    gen per_yes = round(aux_yes / aux_all, 0.00001)

    //Grape with more than 90% of HH with electricity
    egen tag = tag(A42)
    tabstat per_yes if tag == 1 & hh_elec == 1, s(p1 p10 p25 p50 p75 p90 p99 mean sum) save
    mat total = r(StatTotal) 
    gen grape_elec = per_yes >= total[4,1] 

* Allocate households with grappe
    set seed 123
    bysort hh_elec A42 (grape_elec kwh_test hhid): gen j = _n
	gsort -hh_elec kwh_test hhid
    gen sum = sum(hhweight)
*/

* Allocate household based on consumption 

	gen rand = uniform()
	
    bysort hh_elec (kwh_test rand): gen cum_hhs=sum(hhweight) if hh_elec==1

* Social: 52% of LV users,  Domestic: 42% of LV users
	local dist_social = 52 / (52 + 42) // Re-scale distribution of social and domestic
	
    qui: sum hh_elec [iw = hhweight] if hh_elec == 1
    local hh_social = r(sum_w) * `dist_social' 
    
    gen social =  cum_hhs <= `hh_social' if hh_elec == 1
    recode social (1=0) (0=1), gen(domestic)
   
    tab domestic [iw = hhweight]

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




