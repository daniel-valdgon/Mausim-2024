*===============================================================================
// Senegal Master Simulation Tool
// Author: Julieth Pico based on the Paraguay Master Simulation Tool
// Date: June 2020
// Version: 1.0
*===============================================================================

macro drop _all
set more off
clear all

//if (upper("`c(username)'")!="WB378870"){
	global path "C:\Users\WB521296\OneDrive - WBG\Desktop\SN_Simtool\"
//}
//else{
	//global path "C:\Users\WB378870\Documents\PySimTool\"
//}
	if "`c(username)'"=="wb547455" {
		global path     "C:\Users\wb547455\WBG\Julieth Carolina Pico Mejia - SN_Simtool"
		global root     "C:\Users\wb547455\WBG\Julieth Carolina Pico Mejia - Senegal\CEQ 2020"  
		global root_vat "C:\Users\wb547455\WBG\Julieth Carolina Pico Mejia - VAT_senegal"
	}
*===============================================================================
//------------------------------------------------------------------------------
// DO NOT MODIFY BEYOND THIS POINT
//------------------------------------------------------------------------------
*===============================================================================
global data_sn     = "$path\01. Data"
*global xls_sn      = "$path\03. Tool\TVA exemption scenarios\SN_Sim_tool_II__aliment.xlsx"
global xls_sn      = "$path\03. Tool\SN_Sim_tool_III.xlsx"
global thedo       = "$path\02. Dofile" 
global theado      = "$path\05. Adofiles" 
global dta         = "$path\04. dta"     
global dataout     = "$root/SENEGAL_ECVHM_final/Dataout"
global datain      = "$root/SENEGAL_ECVHM_final/Datain"

*===============================================================================
// Run necessary ado files
*===============================================================================
*import excel using "$xls_pry", sheet(nonprog_tax) first clear
*levelsof _ref, local(_ref)
*global doref_ `_ref'

local files : dir "$theado" files "*.ado"
foreach f of local files{
	qui:cap run "$theado\\`f'"
}

*qui {
*===============================================================================
// 0. Pull Macros
*===============================================================================
run "$thedo\01.Pullglobals_ref"

*===============================================================================
// 0.1 Top Incomes...
*===============================================================================
*if ($addtop==1) run "$thedo\01 - topincs.do" => Not available for Colombia

*===============================================================================
// 1. Call data & Apply tax system
*===============================================================================

include "$thedo\02. Income Tax_III.do"

*===============================================================================
// 2. Call data & Apply Social Security Contributions
*===============================================================================

include "$thedo\03. SocialSecurityContributions.do"

*===============================================================================
// 3. VAT and Excise Taxes
*===============================================================================

* Expanded IO- Matrix 
include "$thedo\04.Expanded_IO_Matrix.do"


include "$thedo\Indirect_taxes_IV.do"


* Excise Taxes
include "$thedo\06. Excise_taxes.do"

*===============================================================================
// 4. Transfers and social programs
*===============================================================================

include "$thedo\07. Direct_transfers.do"

*===============================================================================
// 5. Subsidies
*===============================================================================

include "$thedo\08. Subsidies.do"

*===============================================================================
// 6. Education and Health
*===============================================================================

include "$thedo\09. InKind_Transfers.do"

*===============================================================================
// 7. Final income aggregation
*===============================================================================

include "$thedo\10. Income_Aggregate_ref.do"


