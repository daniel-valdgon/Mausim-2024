
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms
* Author: Julieth Pico 
* Date: August 2019
* Version: 1.0
*--------------------------------------------------------------------------------


*set more off
*clear all

*global root = "C:\Users\wb521296\OneDrive - WBG\Desktop\Senegal\CEQ 2020"


********************************************************************************

global dataout = "$root/SENEGAL_ECVHM_final/Dataout"
global datain  = "$root/SENEGAL_ECVHM_final/Datain"


********************************************************************************

 * Electricty subsidies
 
use "$datain/s12_me_SEN2018.dta", clear
 
keep if inlist(s12q01,37,14,20,16,23)
recode s12q02 2=0
 

keep s12q01 s12q02 hhid
rename s12q02 article
drop if article!=0 & article!=1

reshape wide article, i(hhid) j(s12q01)

merge 1:1 hhid using "$datain/s11_me_SEN2018.dta", nogen
 
gen prix_electricite=s11q37a 
gen periodicite=s11q37b

gen DGP= ((article37==1 |article14==1)  & s11q34 ==1) //ordinateur 449 lavadora 5 robot10
gen DMP= ((article16==1 | article20==1 | article23==1) & s11q34==1 & DGP!=1) // refrig & tv & lavadora 5 & robot10
gen DPP=(s11q34==1 & DMP!=1)
gen type_client=.
replace type_client =1 if DPP==1
replace type_client =2 if DMP==1
replace type_client =3 if DGP==1

 
gen consumption_DPP1= ((prix_electricite - 25349.68)/136.25)+250 if prix_electricite!=0
gen consumption_DPP2= ((prix_electricite -14775.8)/104.684)+150 if  prix_electricite!=0
gen consumption_DPP3= (prix_electricite -866)/92.73 if  prix_electricite!=0

gen consumption_electricite= consumption_DPP1 if  consumption_DPP1>250 & type_client==1
replace consumption_electricite= consumption_DPP2 if consumption_DPP1<=250 & consumption_DPP2>150 & type_client==1
replace consumption_electricite= consumption_DPP3 if consumption_DPP2<=150 & consumption_DPP3>0 & type_client==1

gen consumption_DMP1= ((prix_electricite -32193.18)/135.49)+300 if prix_electricite!=0
gen consumption_DMP2= ((prix_electricite -5787.025)/105.01)+50 if  prix_electricite!=0
gen consumption_DMP3= (prix_electricite -866)/98.42 if  prix_electricite!=0

replace consumption_electricite= consumption_DMP1 if consumption_DMP1>300 & type_client==2
replace consumption_electricite= consumption_DMP2 if consumption_DMP1<=300 & consumption_DMP2>50 & type_client==2
replace consumption_electricite= consumption_DMP3 if consumption_DMP2<=50 & consumption_DMP3>0 & type_client==2

replace consumption_electricite= prix_electricite/103.55 if type_client==3

*** Subsidies 

gen tranche1= consumption_electricite if consumption_DPP2<=150 & consumption_DPP3>0 & type_client==1
replace tranche1 = 150 if consumption_DPP2>150 & type_client==1
replace tranche1= consumption_electricite if consumption_DMP2<=50 & consumption_DMP3>0 & type_client==2
replace tranche1 = 50 if consumption_DMP1<=300 & consumption_DMP2>50 & type_client==2

gen tranche2= consumption_electricite-150 if consumption_DPP1<=250 & consumption_DPP2>150 & type_client==1
replace tranche2= 0 if consumption_DPP2<=150 & consumption_DPP3>0 & type_client==1
replace tranche2= 100 if consumption_DPP1>250 & type_client==1
replace tranche2= 0 if consumption_DMP2<=50 & consumption_DMP3>0 & type_client==2
replace tranche2= consumption_electricite-50 if consumption_DMP1<=300 & consumption_DMP2>50 & type_client==2
replace tranche2= 250 if consumption_DMP1>300 & type_client==2

gen tranche3= consumption_electricite-250 if consumption_DPP1>250 & type_client==1
replace tranche3=0 if consumption_DPP1<=250 & consumption_DPP2>150 & type_client==1
replace tranche3=0 if consumption_DPP2<=150 & consumption_DPP3>0 & type_client==1
replace tranche3= consumption_electricite-300 if consumption_DMP1>300 & type_client==2
replace tranche3=0 if consumption_DMP1<=300 & consumption_DMP2>50 & type_client==2
replace tranche3=0 if consumption_DMP2<=50 & consumption_DMP3>0 & type_client==2

gen subsidy1=${SubventionT1_DPP}*tranche1 if type_client==1
gen subsidy2=${SubventionT2_DPP}*tranche2 if type_client==1
gen subsidy3=${SubventionT3_DPP}*tranche3 if type_client==1

replace subsidy1=${SubventionT1_DMP}*tranche1 if type_client==2
replace subsidy2=${SubventionT2_DMP}*tranche2 if type_client==2
replace subsidy3=${SubventionT3_DMP}*tranche3 if type_client==2

replace subsidy1=${SubventionT1_DGP}*consumption_electricite if type_client==3

egen subsidy_elec=rowtotal(subsidy1 subsidy2 subsidy3)

tempfile Electricity_subsidies

save `Electricity_subsidies'

*save "$dta/Electricity_subsidies.dta", replace


 * Agricultural subsidies
 
use "$datain/s16b_me_SEN2018.dta", clear

global total_agriculture 61000000000
keep if inlist(s16bq01, 11,12,13,17,18,20,21)
keep if inlist(s16bq04, 1,2,6,7,8,.)
keep if s16bq09c!=.

collapse (sum) s16bq09c , by(hhid)
merge 1:1 hhid using "$dataout/ehcvm_conso_SEN2018_menage.dta", nogen keepusing(hhweight)
drop if s16bq09c==.

egen total_intrat_achete=total(s16bq09c*hhweight)
gen pourc_subvention=s16bq09c/total_intrat_achete
gen subvention_agric=${total_agriculture}*pourc_subvention

tempfile Agricultural_subsidies
save `Agricultural_subsidies'

*save "$dta/Agricultural_subsidies.dta", replace

 
 