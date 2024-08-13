/*============================================================================================
 ======================================================================================

	Project:		Subsidies - Tables and Figures
	Author:			Gabriel 
	Creation Date:	Apr 21, 2023
	Modified:		
	
	Note:			This do-file produces all the fugures and tables on subsidies. 
					It supports several simulations with the excel file Figures_Sub_MRT.xlsx. 
					It works independently of the tool and uses as input the tool SN_Sim_tool_VI, output data and presim data
					The 4,5,6 figgres supports several simulations and countries
					Figure 4 and 6 supports several policies with global policy
					Figure 5 can support n consumers (type of clients), n tranches and (prepaid or postpaid)
					
	Section: 		1. AdminData: Tariff Structure
					2. AdminData: Consumption and Coverage
					3. AdminData: Indirect effects: Impact of subsidy
					4. Absolute and Relative Incidence
					5. Electricity coverage per decile
					6. Povery results
============================================================================================
============================================================================================*/

clear all
macro drop _all

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mauritania/Mausim_2024"
	global thedo     	"${path}/02_scripts"

	*global xls_out    	"${path}/03_Tool/Figures_Sub_Coverage_MRT.xlsx"
	global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
	
	*global presim       "${path}/01_data/2_pre_sim/MRT"

	global numscenarios	2
	global coutryscen	"MRT MRT MRT MRT"	// Fill with the country of each simulation
	global proj_1		"V2_MRT_Rand44" 
	global proj_2		"V2_MRT_Rand76"  
	global proj_3		"" 
	global proj_4		"" 
}



	global policy		"subsidy_total subsidy_elec_direct subsidy_elec_indirect"
	
	global data_sn       "${path}/01_data/1_raw/MRT"

	global presim       "${path}/01_data/2_pre_sim/MRT"
	global data_out    	"${path}/01_data/4_sim_output"
	global theado       "$thedo/ado"
	scalar t1 = c(current_time)

*===============================================================================
// Run necessary ado files
*===============================================================================

cap run "$theado//costpush.ado"

use "$data_sn/Datain/individus_2019.dta", clear
		
ren hid hhid
	
merge m:1 hhid using "$presim/01_menages.dta", nogen keep(3) keepusing(hhweight hhsize)

gen uno = 1

egen tag = tag(hhid)

tab tag [iw = hhweight]

gadgbd
* All var
gen agri = F3>0

sum F3 F4 F5 F6 PS12 agri [iw = hhweight]



tab1 PS12 agri [iw = hhweight], m

* All hh production


* Credit - Agriculture
tab PS12 [iw = hhweight]




















