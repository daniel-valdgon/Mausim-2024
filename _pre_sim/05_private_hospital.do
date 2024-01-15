

/*===============================================================================
// Senegal Master Simulation Tool
// Author: Daniel V
// Date: Sept 2022
// Note: Not incorporated as part of presim, only a do-file store as backup
*===============================================================================*/
/*
macro drop _all
set more off
clear all

//User 	
	if "`c(username)'"=="WB419055" {
		global path     	"C:\Users\WB419055\OneDrive - WBG\SenSim Tool\Senegal_tool\Senegal_tool"
		global data_sn     	= "$path/01. Data"
		global data_dev    	= "$path/01. Data"
	}
	if "`c(username)'"=="danielsam" {
		global path     "C:\Users\danielsam\Box\World_Bank\Senegal_tool"
	}

//dta paths	
global presim     	"$data_dev/2_pre_sim"
global tempsim      "$data_dev/3_temp_sim"
global out      	"$data_dev/4_sim_ouput"

//code and excel 
global xls_sn       "$path/03. Tool/SN_Sim_tool_V.xlsx"
global thedo        "$path/02. Dofile" 
global theado       "$thedo/ado" 
global thedo_pre    "$thedo/_pre_sim" 
*/


*******************************************************************************
* Use of private medical services
*******************************************************************************

*Compute if household goes to private hospital 
use "$data_sn/s03_me_SEN2018.dta", clear 

	recode s03q07 (1/6=0) (7/12=1), gen(private_hosp)
	
	egen med_spend=rowtotal(s03q13 s03q14 s03q15 s03q16 s03q17 s03q18)  
	gen med_spend_priv=med_spend if private_hosp==1
	
	bysort hhid: egen med_spend_hh=total(med_spend)
	bysort hhid: egen med_spend_priv_hh=total(med_spend_priv)
	
	
	gen sh_priv_med=med_spend_priv_hh/med_spend_hh if med_spend_hh!=0
	
	keep if med_spend_hh!=.
	duplicates drop hhid , force 
	keep hhid sh_priv_med med_spend_hh 
	
	label var med_spend_hh "Spending on medical appintments, exams and drugs in last 3 months"
	label var sh_priv_med  "Share of private medical spending"	
	
save "$thedo_pre/priv_med_serv.dta", replace
