/*=============================================================================
	Project:		Human Opportunity Index
	Author:			Gabriel 
	Creation Date:	Nov 26, 2024
	Modified:		
	
	Section: 		
	Note:
==============================================================================*/

clear all
macro drop _all

local dirtr			"dirtransf_total am_prog_1 am_prog_2 am_prog_3 am_prog_4"
local dirtax		"dirtax_total income_tax_1 income_tax_2 income_tax_3"
local sub			"subsidy_total subsidy_elec_direct subsidy_elec_indirect subsidy_emel subsidy_emel_direct subsidy_emel_indirect"
local indtax		"indtax_total excise_taxes Tax_TVA TVA_direct TVA_indirect"
local inktr			"inktransf_total education_inKind"

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mausim_2024"
	*global report 		"${path}/04. Reports/7. Summary/2. Presentation/Figures"
	global thedo     	"${path}/02. Scripts"

	global xls_out		"${path}/03. Tool/General_Results.xlsx"
	global xls_sn    	"${path}/03. Tool/SN_Sim_tool_VI_`c(username)'.xlsx"
	
	* Set Parameters
	global numscenarios	1
	
	global proj_1		"Ref_MRT_2019" 
	global proj_2		"v1_MRT_ElecReform"
	global proj_3		"v2_MRT_Elec_CM"  
	global proj_4		"RevRecSinGoods"
	global proj_5		"DoubleSinGoodsBR"

	global policy		"`inktr'"	
	
	global income		"yc" // ymp, yn, yd, yc, yf
	global income2		"yf"
	global reference 	"zref" // Only one
}

	global allpolicy	"dirtax_total sscontribs_total dirtransf_total subsidy_total indtax_total inktransf_total" 
	global data_sn 		"${path}/01. Data/1_raw/MRT"    
	global presim       "${path}/01. Data/2_pre_sim/MRT"
	global data_out    	"${path}/01. Data/4_sim_output"
	global theado       "$thedo/ado"	

	scalar t1 = c(current_time)
	
*==============================================================================
// Run necessary ado files
*==============================================================================

cap run "$theado//_ebin.ado"	

/*
Services/Opportunities

Housing

Indicator: Adequate access to water
Scope: Children 0 to 16 years old
Definition: This variable takes the value of one if the household has access to running water within the dwelling. Thus, access includes public network connections and all water pumped into the dwelling, even if it is not from the public network.


Indicator: Access to electricity
Scope: Children 0 to 16 years old
Definition: This variable takes the value of one if the dwelling has access to electricity from any source. Thus, sources can range from the electrical grid system to solar panels.

Indicator: Adequate access to sanitation
Scope: Children 0 to 16 years old
Definition: This variable takes the value of one if the dwelling has access to a flush toilet (either inside the dwelling or inside the property) that is connect- ed to any mechanism whereby household waste is allowed to flow away from the dwelling.

Education

Indicator: School attendance rate
Scope: Children 10 to 14 years old
Definition: This is measured as children aged 10–14 attend- ing school, independent of grade. This variable measures the gross attendance rate.


Indicator: Probability of completing sixth grade on time
Scope: Children 12 to 16 years old
Definition: This is measured by computing the probability of having ended sixth grade on time for all children ages 12 to 16. In most countries of the region, this means having completed primary educa- tion. Given that on average children start school at the age of 7, by age 13, students that have survived in the system without repetition should have completed six years of basic education.


Circumstances

1. Parents' education (to capture socioeconomic origin)
2. Family per capita income (to capture availability of resources)
3. Number of siblings (to capture the dependency ratio)
4. The presence of both parents (to capture family structure)
5. Gender of the child (to capture one direct form of discrimination)
6. Gender of the household head (to capture one indirect form of
discrimination)
7. Urban or rural location of residence (to capture spatial disparities)

*/

/*-------------------------------------------------------/
	0. H
/-------------------------------------------------------*/

*----- Read Data
use "$data_sn/Datain/individus_2019.dta", clear
		
ren hid hhid

*keep hhid A1 A2 A3 C4*

merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize decile_expenditure)

* Auxiliar
egen tag = tag(hhid)
gen uno = 1

*----- Service
* Children
gen age_10_16 = inrange(B4, 10, 16)
*egen hh_age_10_16 = total(age_10_16), by(hhid)

* Education: School Attendance
gen educ_lvl_2 = inrange(C7N, 4, 8) // Level in 2018/2019. General
*gen quality = inlist(C1, 1, 2)

tab C7N [iw = hhweight], m nol
tab age_10_16 educ_lvl_2 [iw = hhweight], m row // Coverage = 65%


*----- Definition of circumstances
gen female = B2 == 2
gen urban = milieu == 1

gen head_educ2 = C4N if B1 == 1
gen head_status2 = B5 if B1 == 1

mvencode head_educ2 head_status2, mv(0)

egen head_educ = max(head_educ2), by(hhid)
egen head_status = max(head_status2), by(hhid)
egen head_female = max(B2 == 2 & B1 == 1), by(hhid)

sum hhsize [aw = hhweight]
gen size = hhsize >= `r(mean)'


*----- Calculation
keep if age_10_16 == 1

sum educ_lvl_2  [iw = hhweight]
global ov_cov = `r(mean)' * 100

global circ_all head_female head_educ head_status female decile_expenditure size urban
global circ_all2 : list global(circ_all) - global(circ)
global service educ_lvl_2

logit $service $circ_all

gcollapse (sum) uno access = $service [iw = hhweight] , by($circ_all)

egen tot = total(uno)
gen pop = uno/tot*100

gen ov_cov = $ov_cov

gen cov = access / uno * 100

gen p_i = (ov_cov - cov) * pop / 100 

gen vuln = p_i > 0

*gen d_i = p_i * vuln / ov_cov * 100
*egen sum_DI = total(d_i)

egen penalty = total(p_i * vuln)

gen HOI = ov_cov - penalty


* loop for all circumstances
*global circ female 
foreach i of varlist $circ_all {
	
	egen gr_uno = sum(uno), by(`i')

	gen gr_pop = gr_uno / tot * 100

	egen gr_acc = sum(access), by(`i')

	gen gr_cov = gr_acc / gr_uno * 100

	gen gr_d_i = (ov_cov - gr_cov) * gr_pop / 100 

	gen gr_vuln = gr_d_i > 0

	egen DI_`i' = total(gr_d_i * gr_vuln), by($circ_all2)

	drop gr*

}

egen DI = rowtotal(DI*)



sum $circ_all ov_cov penalty HOI DI*

order $circ_all vuln ov_cov penalty HOI DI* , first


keep vuln ov_cov penalty HOI DI*
gduplicates drop



