/*=============================================================================
===============================================================================
	Project:		Subsidies - Figures Scenarios
	Author:			Gabriel 
	Creation Date:	Oct 1, 2024
	Modified:		
	
	Section: 		1. Names
					2. Relative Incidence
					3. Absolute Incidence
					4. Marginal Contributions
					5. Poverty and Inequality - Compare Scenarios
					6. Map
					
	Note:
===============================================================================
==============================================================================*/

clear all
macro drop _all

local dirtr			"dirtransf_total am_prog_1 am_prog_2 am_prog_3 am_prog_4"
local dirtax		"dirtax_total income_tax_1 income_tax_2 income_tax_3"
local sub			"subsidy_total subsidy_elec_direct subsidy_elec_indirect subsidy_emel subsidy_emel_direct subsidy_emel_indirect"
local indtax		"indtax_total excise_taxes Tax_TVA TVA_direct TVA_indirect"
local inktr			"inktransf_total"

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mausim_2024"
	*global report 		"${path}/04. Reports/7. Summary/2. Presentation/Figures"
	global report 		"${path}/03. Tool"	
	global thedo     	"${path}/02. Scripts"

	global xls_out		"${report}/General_Results.xlsx"
	global xls_sn    	"${path}/03. Tool/SN_Sim_tool_VI_`c(username)'.xlsx"
	
	* Set Parameters
	global numscenarios	1
	
	global proj_1		"v1_agric_MRT" 
	global proj_2		"OnlySinGoods"
	global proj_3		"DoubleSinGoods"  
	global proj_4		"RevRecSinGoods"
	global proj_5		"DoubleSinGoodsBR"

	global policy		"subsidy_agric_direct subsidy_agric_indirect"	
	
	global income		"yd" // ymp, yn, yd, yc, yf
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

/*-------------------------------------------------------/
	0. Validation and Assumptions
/-------------------------------------------------------*/

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

* Check why so many poor households are receivinf the subsidy
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




/*-------------------------------------------------------/
	1. Names
/-------------------------------------------------------*/

*----- Scenarios
forvalues scenario = 1/$numscenarios {
	
	clear
	set obs 1
	
	gen scenario = `scenario'
	gen name = "${proj_`scenario'}"
	
	tempfile name_`scenario'
	save `name_`scenario'', replace
}

clear
forvalues scenario = 1/$numscenarios {
	append using `name_`scenario''
}

export excel "$xls_out", sheet(Scenarios) first(variable) sheetreplace cell(A1)

















