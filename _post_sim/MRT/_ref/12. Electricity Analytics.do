


use "$tempsim/05_Electricity_Adjusted.dta", clear



use "$tempsim/Elec_subsidies_direct_hhid.dta", clear

merge 1:1 hhid using "$data_out\output", nogen

cap drop hsize_cat yd_quintiles_pc cat lc

gen hsize_cat = "Small"

replace hsize_cat = "Large" if hhsize>=8

gen yd_quintiles_pc = floor((yd_deciles_pc+1)/2)

gen cat = string(yd_quintiles_pc) + " - " + hsize_cat

*graph box consumption_electricite, over(cat)
tab hsize_cat  yd_quintiles_pc [aw=hhweight], col

gen lc=ln(consumption_electricite)

graph box lc [aw=hhweight], over(cat, relabel(1 "Large" 2 "Q1-Small")) ylabel(.693 "2" 1.6094 "5" 2.3025851 "10" 2.9957 "20" 3.91 "50" 4.6051702 "100" 5.298 "200" 6.214 "500" 6.907 "1,000" 7.6 "2,000" 8.517 "5,000"/*9.21 "10,000"*/) ytitle("Bimonthly consumption, Kwh (log scale)")  


gen cons0 = (lc==.)
tab cat  cons0 [aw=hhweight]



gen lc_small = lc if hsize_cat == "Small"
gen lc_large = lc if hsize_cat == "Large"
*graph box lc_small lc_large [aw=hhweight], over(yd_quintiles_pc, relabel(1 "Large")) ylabel(.693 "2" 1.6094 "5" 2.3025851 "10" 2.9957 "20" 3.91 "50" 4.6051702 "100" 5.298 "200" 6.214 "500" 6.907 "1,000" 7.6 "2,000" 8.517 "5,000"/*9.21 "10,000"*/) ytitle("Bimonthly consumption, Kwh (log scale)")  
*xtitle("Per capita disposable income quintiles - Household Size")


tab tranche_elec_max prepaid_woyofal  [iw=hhweight ], mis


bys yd_deciles_pc: sum consumption_electricite [iw=hhweight] if consumption_electricite >0

* Average consumption by household size
collapse (mean) consumption_electricite [iw=pondih] if consumption_electricite>0, by(yd_deciles_pc hsize_cat)
rename consumption_electricite con_
reshape wide con_, i(yd_deciles_pc) j(hsize_cat) string


*Boxplots in Excel for Moritz
collapse (min) min=lc (p25) p25=lc (p50) p50=lc (p75) p75=lc (max) max=lc [iw=pondih], by(yd_deciles_pc)


gen consumed_elec = (consumption_electricite >0)

bys yd_deciles_pc: sum consumed_elec [aw=pondih]



*************************************************
* Assets

use "$rawdata/s12_me_sen_2021.dta", clear
 
keep if inlist(s12q01,16,27,28,29,40) //  16=Refrigerateur, 27=Groupe electrogéne, 28=voiture, 29=moto, 40=pirogue
recode s12q02 2=0 // has an article: =1 Oui =0 Non

keep s12q01 s12q02 grappe menage

rename s12q02 article

reshape wide article, i(grappe menage) j(s12q01)

egen carmopiro = rowmax(article28 article29 article40)

merge 1:1 grappe menage using "$data_out\output", nogen

collapse (mean) carmopiro article16 [iw=pondih], by(yd_deciles_pc)









*************************************************
* Gender, UR analyses and other things


use "$data_out\output",  clear

tab deciles_pc [iw=pondih]
tab milieu chef_menage [iw=pondih]
gen milsex = milieu + 5*(chef_menage -1)
tab milsex
tab deciles_pc milsex [iw=pondih]

bys milsex deciles_pc: sum hhsize [iw=pondih]





*************************************************
* Moritz plots

*1/ By decile, the quantity of electricity consumed (in kWh) within each slab of the tariff structure (stacked bard chart).

use "$tempsim/Elec_subsidies_direct_hhid.dta", clear

merge 1:1 hhid using "$data_out\output", nogen

collapse (sum) tranche1_tool tranche2_tool tranche3_tool [iw=hhweight], by(yd_deciles_pc)


*2/ By decile, the share of households which own appliances that use electricity (summary statistics).

use "$rawdata/s12_me_sen_2021.dta", clear

keep if inlist(s12q01,7,9,11,12,14,16,17,18,19,20,21,22,23,24,25,27,31,32,33,34,35,36,37,38,39) //  16=Refrigerateur, 27=Groupe electrogéne, 28=voiture, 29=moto, 40=pirogue
recode s12q02 2=0 // has an article: =1 Oui =0 Non

keep s12q01 s12q02 grappe menage

rename s12q02 article

reshape wide article, i(grappe menage) j(s12q01)

merge 1:1 grappe menage using "$data_out\output", nogen

collapse (mean) article* [iw=pondih], by(yd_deciles_pc)


*3/ By decile, the share of households which are covered under the main social safety net program (bar chart).

use "$data_out\output", clear
gen unos=1
collapse (sum) recu_PNBSF unos [iw=hhweight], by(yd_deciles_pc)
gen share_hh_pnbsf = recu_PNBSF/unos


*5/ By decile, the mean, median, p10-25-75-90 of household size.

use "$data_out\output", clear
collapse (min) min=hhsize (p25) p25=hhsize (p50) p50=hhsize (p75) p75=hhsize (max) max=hhsize (mean) prom=hhsize [iw=pondih], by(yd_deciles_pc)


*6/ A complete list of all data required for the next steps of the analysis.




*````````````````````````''''''''''''''''''''''''
*************************************************
* Moritz statistics from September 10
*************************************************
*````````````````````````''''''''''''''''''''''''

********||********
* share of the population connected (by group)
********==********

use "$tempsim/Elec_subsidies_direct_hhid.dta", clear
merge 1:1 hhid using "$data_out\output", nogen

gen connected=(consumption_electricite>0)
collapse (mean) connected [iw=pondih], by(yd_deciles_pc milieu)
mi unset, asis
reshape wide connected, i(yd_deciles_pc) j(milieu)


********||********
* ownership of appliances (binary and count) that consume electricity (by group)
********==********

use "$rawdata/s12_me_sen_2021.dta", clear

keep if inlist(s12q01,7,9,11,12,14,16,17,18,19,20,21,22,23,24,25,27,31,32,33,34,35,36,37,38,39) //  16=Refrigerateur, 27=Groupe electrogéne, 28=voiture, 29=moto, 40=pirogue
recode s12q02 2=0 // has an article: =1 Oui =0 Non

*Exclude radios, cellphones
drop if s12q01==19 | s12q01==35

keep s12q01 s12q02 grappe menage

collapse (max) has_appliance=s12q02 (sum) num_appliance=s12q02, by(grappe menage)

merge 1:1 grappe menage using "$data_out\output", nogen

collapse (mean) has_appliance num_appliance [iw=pondih], by(yd_deciles_pc milieu)
mi unset, asis
reshape wide has_appliance num_appliance, i(yd_deciles_pc) j(milieu)

order has_appliance1 has_appliance2 num_appliance1 num_appliance2, after(yd_deciles_pc)


********||********
* we must also show density plots of electricity consumption by decile
********==********

use "$tempsim/Elec_subsidies_direct_hhid.dta", clear
merge 1:1 hhid using "$data_out\output", nogen
replace consumption_electricite=0 if consumption_electricite<0
recode consumption_electricite prix_electricite (0=.)
collapse (min) min_c=consumption_electricite min_s=prix_electricite (p25) p25_c=consumption_electricite p25_s=prix_electricite ///
         (p50) p50_c=consumption_electricite p50_s=prix_electricite (p75) p75_c=consumption_electricite p75_s=prix_electricite ///
		 (max) max_c=consumption_electricite max_s=prix_electricite (mean) avg_c=consumption_electricite avg_s=prix_electricite [iw=pondih], by(yd_deciles_pc)

order yd_deciles_pc *_c *_s


********||********
* Highlight the share of each group (decile, urban/rural) that only uses the 60kWh block (by group); note: threshold could be adjusted. 
********==********

use "$tempsim/Elec_subsidies_direct_hhid.dta", clear
merge 1:1 hhid using "$data_out\output", nogen
replace consumption_electricite=0 if consumption_electricite<0
gen tranches_tool = tranche1_tool if tranche1_tool<60
replace tranches_tool = 60 if tranche1_tool>60 & tranche1_tool!=.
replace tranche1_tool=tranche1_tool-60
replace tranche1_tool=0 if tranche1_tool<0
collapse (sum) tranches_tool tranche1_tool tranche2_tool tranche3_tool [iw=hhweight], by(yd_deciles_pc milieu)
mi unset, asis
reshape wide tranches_tool tranche1_tool tranche2_tool tranche3_tool, i(yd_deciles_pc) j(milieu)

use "$tempsim/Elec_subsidies_direct_hhid.dta", clear
merge 1:1 hhid using "$data_out\output", nogen
*replace tranche1_tool=min(150,tranche3_tool) if type_client==3
*replace tranche3_tool=0 if type_client==3
replace consumption_electricite=0 if consumption_electricite<0
gen tranches_tool = tranche1_tool if tranche1_tool<60
replace tranches_tool = 60 if tranche1_tool>60 & tranche1_tool!=.
replace tranche1_tool=tranche1_tool-60
replace tranche1_tool=0 if tranche1_tool<0
replace tranche_elec_max = 0.5 if tranches_tool>0 & tranche1_tool
bys tranche_elec_max: sum tranche*_tool



