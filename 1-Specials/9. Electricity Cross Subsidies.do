/*============================================================================*\
 Cross Subsidies Electricity - CEQ Mauritania
 Authors: Gabriel Lombo
 Start Date: January 2024
 Update Date: April 2025
\*============================================================================*/

clear all
macro drop _all

* Gabriel - Personal Computer
if "`c(username)'"=="gabriellombomoreno" {			
	global pathdata     "/Users/gabriellombomoreno/Documents/WorldBank/Data/DATA_MRT" 
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 MRT Fiscal Incidence Analysis"
	
	global tool         "${path}/03-Outputs/`c(username)'/Tool" 
	global thedoSim     "${path}/02-Scripts/`c(username)'/0-Fiscal-Model"
	global thedo     	"${path}/02-Scripts/`c(username)'/1-Specials"
	
}
	
	*----- Figures parameters
	global numscenarios	2
	global proj_1		"MRT_RefScen_2019" 
	global proj_2		"Sim6_CM_ElecTariff"
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
	global xls_out    	"${tool}/Specials/CrossSubsidies_Electricity.xlsx"	
	
	*----- Ado	
	global theado       "$thedoSim/ado"

	scalar t1 = c(current_time)
	
*==============================================================================
// Run necessary ado files
*==============================================================================

cap run "$theado//_ebin.ado"	

*==============================================================================
// Figures
*==============================================================================

*-------------------------------------
// A. Boxplot
*-------------------------------------

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

mat T = (B1, B2) \ (C1, C2)

mat rownames T = Subsidized Social Domestic Top20 Bottom40 Payer Social Domestic Top20 Bottom40 CashTransf Top20 Bottom40 
mat colnames T = No Yes No Yes
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

mat D = D2 //, D3
mat rownames D = Lose Win Ch_pos Ch_neg Ch_cashtr Ch_pos Ch_neg
mat colnames D = No Yes //No Yes
matlist D

putexcel set "${xls_out}", sheet("HHImpact") modify
putexcel C20 = matrix(D), names





