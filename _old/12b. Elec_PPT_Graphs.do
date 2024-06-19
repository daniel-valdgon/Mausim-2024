
/*==============================================================================*\
 Senegal Mini Simulation Tool, indirect taxes (VAT) informality by Bacha's Method
 To do: Create presentation
 Authors: Madi Mangan and Gabriel Lombo
 Start Date: January 2024
 Update Date: 02nd April 2024
 
\*==============================================================================*/


    
	
	*******************************************************************
	***** GLOBAL PATHS ************************************************
	
	*global path "/Users/manganm/Documents/GitHub/Feb_2024/VAT_tool" // Madi		
	   
	*global data_sn 		"${path}/01_data/1_raw"
    *global tempsim      "${path}/01_data/3_temp_sim"
	*global Vat_sn       "${path}/03_Tool/VAT_mini.xlsx"
	
	
	*******************************************************************
	**// 1.  Composition of expenditure by VAT Rates and and deciles **
	*******************************************************************

	if "`c(username)'"=="gabriellombomoreno" {
		global path     	"/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool"
		
		global data_out    	"${path}/01_data/4_sim_output"
	
		global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
		global xls_out    	"${path}/03_Tool/Graphs_`c(username)'.xlsx" 
		
		global proj 		"V1_MRT_SubElec_Ref"
	}

    if "`c(username)'"=="manganm" {
		global path     	"/Users/manganm/Documents/GitHub/vat_tool_GMB"
		*global thedo     	"${path}/02_scripts"
		global country 		"GMB"
	
		global presim       "${path}/01_data/2_pre_sim/${country}"
		global data_out    	"${path}/01_data/4_sim_output"
	
		global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_${country}_2.xlsx" 

		* New Params
		global xls_out    	"${path}/03_Tool/Graphs_${country}.xlsx" 
		global sheetname "Ref_2019_GMB VAT_NoExempt_GMB INF_DES10_GMB"
		global nsim 3
	}
	
		
/// ---------------------------------------------------------------// 
** Absolute and relative incidence of VAT by deciles 

global policy	"subsidy_total subsidy_elec_direct subsidy_elec_indirect"
global policy2 	""

import excel "$xls_sn", sheet("all$proj") firstrow clear 

keep if measure=="benefits" 
gen keep = 0
foreach var in $policy {
	replace keep = 1 if variable == "`var'_pc"
	global policy2	"$policy2 v_`var'_pc_yd" 
}	
keep if keep ==1 

replace variable=variable+"_ymp" if deciles_pc!=.
replace variable=variable+"_yd" if deciles_pc==.

egen decile=rowtotal(yd_deciles_pc deciles_pc)

keep decile variable value
rename value v_

reshape wide v_, i(decile) j(variable) string
drop if decile ==0
keep decile *_yd

foreach var in $policy2 {
	egen ab_`var' = sum(`var')
	gen in_`var' = `var'*100/ab_`var'
}

*ren in_v_TVA_direct_pc_yd direct_absolute_inc 
*ren in_v_TVA_indirect_pc_yd indirect_absolute_inc
*ren [in_v_TVA_direct_pc_yd in_v_TVA_indirect_pc_yd] [direct_absolute_inc indirect_absolute_inc]
keep decile in_*

global cell = "A2"

putexcel set "${xls_out}", sheet("Incidence") modify
putexcel B1 = ("Effect Total") C1 = ("Effect Direct") D1 = ("Effect Indirect"), names

export excel using "$xls_out", sheet("Incidence", modify) first(variable) cell($cell ) keepcellfmt


*** relative 

import excel "$xls_sn", sheet("all$proj") firstrow clear 

keep if measure=="netcash" 
gen keep = 0
foreach var in $policy {
	replace keep = 1 if variable == "`var'_pc"
	global policy2	"$policy2 v_`var'_pc_yd" 
}	
keep if keep ==1 

replace variable=variable+"_ymp" if deciles_pc!=.
replace variable=variable+"_yd" if deciles_pc==.

egen decile=rowtotal(yd_deciles_pc deciles_pc)

keep decile variable value
replace value = value*(-100) if value < 0
replace value = value*(100) if value >= 0
rename value v_

reshape wide v_, i(decile) j(variable) string
drop if decile ==0
keep decile *_yd

global cell = "A21"

putexcel set "${xls_out}", sheet("Incidence") modify
putexcel B20 = ("Effect Total") C20 = ("Effect Direct") D20 = ("Effect Indirect"), names

export excel using "$xls_out", sheet("Incidence", modify) first(variable) cell($cell ) keepcellfmt



		
		
		
	