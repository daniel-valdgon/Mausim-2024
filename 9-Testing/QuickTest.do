/*=============================================================================
	Project:		
	Author:			Gabriel 
	Creation Date:	
	Modified:		
	
	Section: 		
	Note:
==============================================================================*/


clear all
macro drop _all


* Gabriel - Personal Computer
if "`c(username)'"=="gabriellombomoreno" {			
	global pathdata     	"/Users/gabriellombomoreno/Documents/WorldBank/Data/DATA_MRT" 
	global path     		"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 MRT Fiscal Incidence Analysis"
}

	* Policy
	local allpolicy	"dirtax_total sscontribs_total dirtransf_total subsidy_total indtax_total inktransf_total"

	* Figures parameters
	global numscenarios	2
	global proj_1		"MRT_Ref_2019_v1" 
	global proj_2		"MRT_Ref_2024_v2"
	
	global policy		"am_proj_1 am_proj_2 am_proj_3 am_proj_4 subsidy_emel_direct"	
	global income		"yc" // ymp, yn, yd, yc, yf
	global income2		"yf"
	global reference 	"zref" // Only one	
	
	* Data
	global data_sn 		"${pathdata}/MRT_2019_EPCV/Data/STATA/1_raw"
    global data_other   "${pathdata}/MRT_FIA_OTHER"

	global presim       "${path}/1-Cleaned_data/2_pre_sim"
	global tempsim      "${path}/1-Cleaned_data/3_temp_sim"
	global data_out    	"${path}/1-Cleaned_data/4_sim_output"

	* Tool
	global xls_sn 		"${path}/3-Outputs/`c(username)'/Tool/SN_Sim_tool_VI.xlsx"
	global xls_out    	"${path}/Figures_print.xlsx"	
	
	* Ado	
	global theado       "$thedo/ado"

	
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










