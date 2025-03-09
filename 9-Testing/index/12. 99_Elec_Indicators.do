/*=============================================================================
===============================================================================
	Project:		Direct Taxes - Figures Scenarios
	Author:			Gabriel 
	Creation Date:	Oct 9, 2024
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
	global thedo     	"${path}/02. Scripts"

	global xls_out		"${path}/03. Tool/99_Elec.xlsx"
	global xls_sn    	"${path}/03. Tool/SN_Sim_tool_VI_`c(username)'.xlsx"
	
	* Set Parameters
	global numscenarios	3
	
	global proj_1		"v1_RefElec" 
	global proj_2		"v1_ReformElec2"
	global proj_3		"v1_ReformElecCM"  
	global proj_4		""
	global proj_5		""

	global policy		"subsidy_elec subsidy_elec_direct subsidy_elec_indirect"	
	
	global income		"yd" // ymp, yn, yd, yc, yf
	global income2		"yc"
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

/*-------------------------------------------------------/
	A. Reference Scenario
/-------------------------------------------------------*/


*------ Load Data
local scenario 1
use "$data_out/output_${proj_`scenario'}.dta", clear 

merge 1:1 hhid using "$presim/08_subsidies_elect.dta", nogen 

*------ Boxplot: HH size
tabstat hhsize [aw = hhweight], s(min p25 p50 p75 max mean) by(yd_deciles_pc) save

forvalues i = 1/10 {
	mat s`i' = r(Stat`i')'
	mat rownames s`i' = `r(name`i')' 
}
mat s = s1\s2\s3\s4\s5\s6\s7\s8\s9\s10
mat A1 = s

*------ Boxplot: Bimonthly consumption_electricite
tabstat consumption_electricite [aw = hhweight], s(p10 p25 p50 p75 p90 mean) by(yd_deciles_pc) save

forvalues i = 1/10 {
	mat s`i' = r(Stat`i')'
	mat rownames s`i' = `r(name`i')' 
}
mat s = s1\s2\s3\s4\s5\s6\s7\s8\s9\s10
mat A2 = s

*------ Export results

putexcel set "${xls_out}", sheet("Boxplot") modify
putexcel A1 = matrix(A1), names
putexcel A15 = matrix(A2), names

/*-------------------------------------------------------/
	B. All scenarios
/-------------------------------------------------------*/

*------ Data preparation: Index

forvalues scenario = 1/$numscenarios {

	*local scenario 1
	use "$data_out/output_${proj_`scenario'}.dta", clear 

	keep hhid subsidy_elec_direct am_prog_1

	ren * v`scenario'_*
	ren (v`scenario'_hhid) (hhid)

	* Payers and subsidized
	gen netsub_`scenario' = v`scenario'_subsidy_elec_direct > 0 
	gen netpay_`scenario' = v`scenario'_subsidy_elec_direct < 0 
	
	gen tek_`scenario' = v`scenario'_am_prog_1 > 0 
	
	tempfile tab_`scenario'
	save `tab_`scenario'', replace
}

clear
use `tab_1', clear
forvalues scenario = 2/$numscenarios {
	merge 1:1 hhid using `tab_`scenario'', nogen
}

merge 1:1 hhid using "$presim/08_subsidies_elect.dta", nogen keepusing(hh_elec type_client prepaid_woyofal consumption_electricite)

merge 1:1 hhid using "$data_out/output_${proj_1}.dta", nogen keepusing(hhweight hhsize ${income}_pc)

_ebin ${income}_pc [aw=hhweight], nq(10) gen(decile)


* Social and Domestic
gen social = type_client == 1
gen domestic = type_client == 2

* Bottom 40 vs Top 20
gen rich = inrange(decile, 9, 10)
gen poor = inrange(decile, 1, 4)

* Indicators
forvalues i = 1/$numscenarios {
	gen netsubsoc_`i' = netsub_`i' * social
	gen netsubdom_`i' = netsub_`i' * domestic

	gen netpaysoc_`i' = netpay_`i' * social
	gen netpaydom_`i' = netpay_`i' * domestic	
	
	gen netsubrich_`i' = netsub_`i' * rich
	gen netsubpoor_`i' = netsub_`i' * poor

	gen netpayrich_`i' = netpay_`i' * rich
	gen netpaypoor_`i' = netpay_`i' * poor
	
	gen tekrich_`i' = tek_`i' * rich
	gen tekpoor_`i' = tek_`i' * poor
}

*------ Results

* Payers and Subsidized and cash transfers
forvalues i = 1/$numscenarios {
	tabm netsub*`i' netpay*`i' [iw = hhweight] if hh_elec == 1, matcell(B`i')
	tabm tek*`i' [iw = hhweight] if hh_elec == 1, matcell(C`i')
}

mat T = (B1, B2, B3) \ (C1, C2, C3)

mat rownames T = Subsidized Social Domestic Top20 Bottom40 Payer Social Domestic Top20 Bottom40 CashTransf Top20 Bottom40 
mat colnames T = No Yes No Yes No Yes
matlist T

putexcel set "${xls_out}", sheet("HHImpact") modify
putexcel A1 = matrix(T), names


/*-------------------------------------------------------/
	B. Reference scenario vs Sim scenarios
/-------------------------------------------------------*/

	local relec 0.05
	
forvalues scenario = 2/$numscenarios {

	gen dif_`scenario' = ((v`scenario'_subsidy_elec_direct - v1_subsidy_elec_direct)/v1_subsidy_elec_direct) * 100

	* 1 = looser, 2 = indif, 3 = winner
	gen st_lose_`scenario' = v`scenario'_subsidy_elec_direct < v1_subsidy_elec_direct
	gen st_win_`scenario' = v`scenario'_subsidy_elec_direct > v1_subsidy_elec_direct

	* Reasonable change
	gen st_pos_`scenario' =  v`scenario'_subsidy_elec_direct > v1_subsidy_elec_direct * 1.0001 & v`scenario'_subsidy_elec_direct <= v1_subsidy_elec_direct * (1 + `relec')
	
	gen st_neg_`scenario' =  v`scenario'_subsidy_elec_direct < v1_subsidy_elec_direct * 0.9999 & v`scenario'_subsidy_elec_direct >= v1_subsidy_elec_direct * (1 - `relec') 

	gen st_tek_`scenario' = tek_`scenario' - tek_1
	gen st_teklose_`scenario' = v`scenario'_am_prog_1 < v1_am_prog_1 
	gen st_tekwin_`scenario' = v`scenario'_am_prog_1 > v1_am_prog_1 
}

*------ Export results
forvalues i = 2/$numscenarios {
	tabm st*`i' [iw = hhweight] if hh_elec == 1, matcell(D`i')
}

mat D = D2, D3
mat rownames D = Lose Win Ch_pos Ch_neg Ch_cashtr Ch_pos Ch_neg
mat colnames D = No Yes No Yes
matlist D

putexcel set "${xls_out}", sheet("HHImpact") modify
putexcel C20 = matrix(D), names





