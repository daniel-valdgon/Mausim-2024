/*============================================================================*\
 Internal validation figures - CEQ Mauritania
 Authors: Gabriel Lombo
 Start Date: January 2024
 Update Date: April 2025
\*============================================================================*/
  
clear all
macro drop _all

global all_bypolicy "dirtax_total income_tax_1 income_tax_3 ss_contribs_total dirtransf_total am_prog_1 am_prog_2 am_prog_3 am_prog_4 ss_ben_sa indtax_total excise_taxes CD_direct Tax_TVA TVA_direct TVA_indirect subsidy_total subsidy_elec subsidy_fuel subsidy_emel_direct inktransf_educ am_educ_1 am_educ_2 am_educ_3 am_educ_4 inktransf_health"


* Gabriel - Personal Computer
if "`c(username)'"=="gabriellombomoreno" {			
	global pathdata     "/Users/gabriellombomoreno/Documents/WorldBank/Data/DATA_MRT" 
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 MRT Fiscal Incidence Analysis"
	
	global tool         "${path}/03-Outputs/`c(username)'/Tool" 	
	global thedo     	"${path}/02-Scripts/`c(username)'/1-Specials"
	
}
	
	*----- Figures parameters
	global numscenarios	1
	global proj_1		"MRT_Ref_2019_v2" 
	global proj_2		""
	global proj_3		""
	
	global policy		"subsidy_f1_direct subsidy_f2_direct subsidy_f3_direct"
	
	global income		"yd" // ymp, yn, yd, yc, yf
	global income2		"yc"
	global reference 	"zref" // Only one	
	
	*----- Data
	global data_sn 		"${pathdata}/MRT_2019_EPCV/Data/STATA/1_raw"
    global data_other   "${dathdata}/MRT_FIA_OTHER"

	global presim       "${path}/01-Data/2_pre_sim"
	global tempsim      "${path}/01-Data/3_temp_sim"
	global data_out    	"${path}/01-Data/4_sim_output"

	*----- Tool
	global xls_sn 		"${tool}/MRT_Sim_tool_VI.xlsx"
	global xls_out    	"${tool}/Figures_validation.xlsx"	
	
	*----- Ado	
	global theado       "$thedo/ado"

	scalar t1 = c(current_time)
	
/*
Policies:

Social Protection: am_prog_1 am_prog_2 am_prog_3 am_prog_4 subsidy_emel_direct

Direct Transfers: am_prog_1 am_prog_2 am_prog_3 am_prog_4

Direct Tax: income_tax_1 income_tax_2 income_tax_3

Subsidies: subsidy_total subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_f1_direct subsidy_f2_direct subsidy_f3_direct subsidy_emel_direct subsidy_inag_direct*

Indirect Taxes: indtax_total excise_taxes CD_direct TVA_direct TVA_indirect

All policies: dirtax_total income_tax_1 income_tax_3 ss_contribs_total dirtransf_total am_prog_1 am_prog_2 am_prog_3 am_prog_4 ss_ben_sa indtax_total excise_taxes CD_direct Tax_TVA TVA_direct TVA_indirect subsidy_total subsidy_elec subsidy_fuel subsidy_emel_direct inktransf_educ am_educ_1 am_educ_2 am_educ_3 am_educ_4 inktransf_health
*/	
	
*==============================================================================
// Run necessary ado files
*==============================================================================

cap run "$theado//_ebin.ado"	

*==============================================================================
// Policies - Internal Validation
*==============================================================================

*-------------------------------------
// 1. Social Security Contributions
*-------------------------------------

*-------------------------------------
// 02. Direct Taxes
*-------------------------------------


use "$data_sn/Datain/individus_2019.dta", clear
		
ren hid hhid
	
merge m:1 hhid using "$presim/01_menages.dta", nogen keep(3) keepusing(hhweight hhsize)
merge 1:1 idind using "$presim/02_Income_tax_input.dta", nogen


*-------- Wages and Salaries
tab E11 E18B [iw = hhweight], m

gen worker = inrange(E11, 1, 9)
gen soc_sec = E18B == 1

gen pos = E20A2>0 & E20A2!=. & worker == 1 
gen pos_soc_sec = E20A2>0 & E20A2!=. & soc_sec == 1 

tabstat an_income_1 [aw = hhweight] if pos_soc_sec == 1, s(mean)


gen aux_income_1 = an_income_1/1000/10


twoway  (kdensity aux_income_1 [aw = hhweight] if B2 == 1) ///
		(kdensity aux_income_1 [aw = hhweight] if B2 == 2) ///
		(kdensity aux_income_1 [aw = hhweight]), ///
		xtitle("MRU (000)") ytitle("Density") ///
		legend( label (1 "Male annual labor income") label (2 "Female annual labor income") label (3 "Annual labor income") position(1))  

graph export "$report/income.png", width(1500) height(900) replace


gen aux_income_21 = inc_imp/1000/10
gen aux_income_2 = inc_imp2/1000/10

twoway  (kdensity aux_income_2 [aw = hhweight]), ///
		xtitle("MRU (000)") ytitle("Density") 

graph export "$report/income_imp.png", width(1500) height(900) replace

drop aux_income_1 aux_income_2

*-------- Property tax

keep hhid hhweight wilaya G0 F1 G12B G10 an_income_3 tax_ind_3
gduplicates drop 

gen owner = F1 == 1

tab G0 owner [iw = hhweight], col nofreq

* Values to impute multiplied by 12

tabstat an_income_3 [aw = hhweight] if tax_ind_3 == 1, s(mean) by(wilaya)

collapse (mean) income = an_income_3 [aw = hhweight] if tax_ind_3 == 1, by(wilaya)

tostring wilaya, gen(name)
gen len = length(name)
replace name = "0" + name if len == 1
keep name income

tempfile map
save `map', replace



*-------------------------------------
// 03. Direct Transfers
*-------------------------------------

	
use "$data_sn/individus_2019.dta", clear

forvalues i = 1/6 {
	gen prog_`i' = (PS4A == `i' | PS4B == `i' | PS4C == `i')
	gen prog_amount_`i' = PS7 if prog_`i' == 1
	
	egen hh_prog_`i' = max(prog_`i' == 1), by(hid)
	egen hh_prog_amount_`i' = total(prog_amount_`i'), by(hid)
}

ren hid hhid
egen tag = tag(hhid)
gen uno = 1	
	
* Result data	
merge m:1 hhid using "$data_out/output_${proj_1}.dta", nogen keep(3) keepusing(*deciles* ymp_pc yn_pc yd_pc yc_pc hhsize hhweight am*)

* Programs
global progs "prog_1 prog_2 prog_3 prog_4 prog_5 prog_6"
global hh_progs "hh_prog_1 hh_prog_2 hh_prog_3 hh_prog_4 hh_prog_5 hh_prog_6"
global hh_progs_am "hh_prog_amount_1 hh_prog_amount_2 hh_prog_amount_3 hh_prog_amount_4 hh_prog_amount_5 hh_prog_amount_6"


_ebin ymp_pc [aw=hhweight], nq(10) gen(decile_ymp)
_ebin yn_pc [aw=hhweight], nq(10) gen(decile_yn)
_ebin yd_pc [aw=hhweight], nq(10) gen(decile_yd)
_ebin yc_pc [aw=hhweight], nq(10) gen(decile_yc)


* Coverage Table. Slide 11
tabm $progs [iw = hhweight] 
tabm $hh_progs if tag == 1 [iw = hhweight] 


* Individuals
tab uno [iw = hhweight] if prog_1==1 | prog_2==1 | prog_3==1 | prog_4==1 | prog_5==1 | prog_6==1
tab uno [iw = hhweight] if prog_1==1 | prog_2==1 | prog_3==1

* Households
tab uno [iw = hhweight] if (hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1 | hh_prog_4==1 | hh_prog_5==1 | hh_prog_6==1) & tag == 1
tab uno [iw = hhweight] if (hh_prog_1==1 | hh_prog_2==1 | hh_prog_3==1) & tag == 1

* Coverage - SLides 12 and 13
tab uno [iw = hhweight] if tag == 1 // All households

tabstat $hh_progs [aw = hhweight] if tag == 1, s(sum) by(decile_yc) save

return list


mat A = r(Stat1) \ r(Stat2) \ r(Stat3) \ r(Stat4) \ r(Stat5) \ r(Stat6) \ r(Stat7) \ r(Stat9) \ r(Stat9) \ r(Stat10)

mat rownames A = 1 2 3 4 5 6 7 8 9 10

*putexcel set "$xls_out", modify sheet(Fig_1)
*putexcel A1 = matrix(A), names

*export excel "$xls_out", sheet(Fig_2) first(variable) sheetmodify 


tabstat hh_prog_1 hh_prog_2 [aw = hhweight] if tag == 1, s(sum) by(decile_ymp)
tabstat hh_prog_1 hh_prog_2 [aw = hhweight] if tag == 1, s(sum) by(wilaya)


*-------------------------------------
// 04. Indirect Taxes
*-------------------------------------

*----- VAT
import delimited using "$mapping", sheet("Master")

agbs

	use "$presim/01_menages.dta", clear
	
	keep hhsize hhid hhweight

	merge 1:m hhid using "$tempsim/FinalConsumption_verylong.dta"


	*---------- 4. Products less consumed by the poor ​
	use "$presim/05_purchases_hhid_codpr.dta", clear

	gen poor = inrange(decile, 1, 4)
	
	gen quintil = 0
	replace quintil = 1 if inrange(decile, 1, 2)
	replace quintil = 2 if inrange(decile, 3, 4)
	replace quintil = 3 if inrange(decile, 5, 6)
	replace quintil = 4 if inrange(decile, 7, 8)
	replace quintil = 5 if inrange(decile, 9, 10)
	
	gen bottom40 = 0
	replace bottom40 = 1 if inrange(decile, 1, 4)
	replace bottom40 = 2 if inrange(decile, 10, 10)

	
	gcollapse (sum) sum=depan (mean) value = depan (p50) median = depan, by(codpr bottom40)
	
	keep codpr bottom40 value
	reshape wide value, i(codpr) j(bottom40)
	
	*egen bottom40 = rowtotal(value1 value2 value3 value4)
	
	*gen ratio2 = value10 / bottom40
	
	gen ratio = value2/value1
	
	*tab coicop quintil [iw = mean]
	

*----- Agriculture

local scenario 1
use "$data_out/output_${proj_`scenario'}.dta", clear

keep hhid hhweight hhsize subsidy_inagr* subsidy_emel* yn_pc yd_pc yc_pc yf_pc yd_deciles_pc poor_ref

merge 1:1 hhid using "$presim/08_subsidies_agric.dta", nogen keepusing(A1 A2 A3 fert pest d_fert d_pest mr_com d_sub ha_pos fert_kg fert_val F3 max_eleg_1) keep(3)

gen uno = 1


tabstat yn_pc yd_pc yc_pc yf_pc [aw = hhweight], s(mean) by(yd_deciles_pc)


tabstat subsidy_emel_direct subsidy_inagr_direct [aw = hhweight], s(sum) by(yd_deciles_pc)

tab uno [iw = hhweight] if subsidy_emel_direct>0 , m

tab yd_deciles_pc [iw = hhweight] if subsidy_inagr_direct>0 , m

tab yd_deciles_pc [iw = hhweight]

_ebin yd_pc [aw=hhweight], nq(10) gen(decile_yd)

tab decile_yd [iw = hhweight], matcell(A)
tab decile_yd [iw = hhweight] if subsidy_inagr_direct>0 , m matcell(B)

mat C = A, B
matlist C

tabstat yd_pc subsidy_inagr_direct [aw = hhweight], s(sum) by(decile_yd)

* Check why so many poor households are receive inf the subsidy
* Check the amount of land by decile

tab decile_yd [iw = hhweight], matcell(A)
tab decile_yd [iw = hhweight] if subsidy_inagr_direct>0 , m matcell(B)
tab decile_yd [iw = hhweight] if d_fert == 1 , m matcell(B)

tab A1 d_fert [iw = hhweight], row m nofreq

* Farmers by land
tabstat F3 [aw = hhweight], s(mean sum) by(decile_yd)

tabstat F3 [aw = hhweight] if F3>0, s(mean sum) by(decile_yd)

gen fert_use = F3 * 24.4
gen fert_val2 =  fert_use * 106.76157

tabstat F3 fert_use fert_val [aw = hhweight], s(sum mean) by(decile_yd)

tab decile_yd [iw = hhweight] if F3>0 

tab decile_yd [iw = hhweight] if d_fert==1, matcell(A1)
tab decile_yd [iw = hhweight] if d_pest==1, matcell(A2)
tab decile_yd [iw = hhweight] if d_fert==1 | d_pest==1, matcell(A3)

mat A = A1, A2, A3
matlist A

tab d_fert d_pest [iw = hhweight], cell nofreq



*------- Community data

use "$data_sn/Datain/data_communaitaire_EPCV2019.dta", clear

gunique US_ORDRE A_01

duplicates tag US_ORDRE A_01, gen(dup) // Duplicates by school, D category

keep US_ORDRE A* B1 B2 B5 B6 NOM_DE_LA_OCALITE C1 C1A C1B C1C C9 C10 F* dup
drop AUTEC

gduplicates drop

gunique US_ORDRE A_01

* Check 
gen uno = 1
tab A1 uno

tabstat B1 B2 F17 F18, s(sum) by(A1)


*----- custom duties
import excel using "$mapping", sheet("Master") firstrow clear

sum *

tab Tariff_min_4dig Tariff_min_6dig, row m
tab IOMatrix_4dig

*ren (Tariff_CD2 Imported) (custom_rate imported) 

keep codpr Tariff* IOMatrix_4dig

tempfile custom
save `custom', replace

*----- 1. 
use "$presim/05_purchases_hhid_codpr.dta", clear

merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize) nogen

merge m:1 codpr using `custom' , keep(3) nogen


tabstat depan [aw = hhweight] if IOMatrix_4dig == 1, s(p50 mean min max sum) by(Tariff_min_4dig)

tabstat depan [aw = hhweight] if IOMatrix_4dig == 1, s(p50 mean min max sum) by(Tariff_min_6dig)





*----- 1. Test all purcgase
use "$presim/05_purchases_hhid_codpr.dta", clear

merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize) nogen

tabstat depan [aw = hhweight], s(sum)


*-------------------------------------
// 05. Indirect Subsidies
*-------------------------------------


*-------------------------------------
// 06. In-Kind Transfers
*-------------------------------------





* End of do-file



















