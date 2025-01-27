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
	
	global proj_1		"EU_v4" 
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


/*-------------------------------------------------------/
	0. Data
/-------------------------------------------------------*/

*----- Read Data
use "$data_sn/Datain/individus_2019.dta", clear
		
ren hid hhid

*keep hhid A1 A2 A3 C4*

merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize decile_expenditure)

tab wilaya [iw = hhweight]


merge m:1 hhid using "$data_out/output_${proj_1}.dta", nogen keep(3) keepusing(*deciles* ymp_pc yn_pc yd_pc yc_pc hhsize hhweight am*)










