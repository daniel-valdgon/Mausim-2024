/*============================================================================================
 ======================================================================================

	Project:		Subsidies - Tables and Figures
	Author:			Gabriel 
	Creation Date:	Apr 21, 2023
	Modified:		
	
	Note:			This do-file produces all the fugures and tables on subsidies. 
					It is  for several simulations with the excel file Figures_Sub_MRT.xlsx. 
					It works independently of the tool and uses the SN_Sim_tool_VI.xlsx, output data and presim data
					The 4,5,6 fiugres supports several simulations 
					Figure 5 can support n consumers (type of clients) with (prepaid or postpaid)
					With minimal changes on the figures 4,5,6 it should be easy to adapt for several policies.
					
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
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool"
	global path_out		"/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool/QER"
	global thedo     	"${path}/02_scripts"

	global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
	global xls_out    	"${path_out}/Figures_Sub_MRT.xlsx"

	global numscenarios	2
	global proj_1		"AA_MRT_Sub_Ref" 
	global proj_2		"AA_SEN_Sub_Ref"  
}

* Daniel
if "`c(username)'"=="wb419055" {
	
	global path     	"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024\00_Workshop\Feb_2024\VAT_tool" 
	global path_out 	"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024\00_Workshop\QER"	
	global thedo     	"${path}/gitrepo\daniel"

	global xls_out    	"${path_out}/Figures_Sub_MRT.xlsx"
	global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
	
	* Simulations to run
	global numscenarios	2	// Update
	global proj_1		"" 	// Update
	global proj_2		"" 	// Update
}

	global policy		"subsidy_total subsidy_elec_direct subsidy_elec_indirect"
	global data_out    	"${path}/01_data/4_sim_output"
	global presim       "${path}/01_data/2_pre_sim/MRT"
	global theado       "$thedo/ado"

	*global policy "Tax_TVA TVA_direct TVA_indirect subsidy_total subsidy_elec_direct subsidy_elec_indirect"
	*global policy "Tax_TVA TVA_direct TVA_indirect"

	
	
/*-------------------------------------------------------/
	5. Electricity coverage per decile
/-------------------------------------------------------*/
* Test for Senegal, multiple users and prepaid...

*-----  Coverage and consumption
forvalues scenario = 1/$numscenarios {
	
	local scenario 1
	* Purcases 
	use "$presim/05_purchases_hhid_codpr.dta", clear
	rename depan depan2
	
	merge m:1 hhid using "$presim/01_menages.dta", keepusing(hhweight) keep(3) nogen
	merge 1:1 hhid codpr using "$presim/08_subsidies_elect.dta", keepusing(codpr_elec) nogen

	gen elec=0
	replace elec= depan2 if codpr_elec==1

	collapse (sum) depan2 elec [aw=hhweight], by(hhid)

	gen share_elec = elec/depan2
	gen cshare_elec = share_elec if share_elec>0
	gen coverage = (elec>0)
	
	tempfile elec_share
	save `elec_share'
	
	* Output
	use "$data_out/output_${proj_`scenario'}.dta", clear

	keep hhid depan yd_deciles_pc hhsize hhweight
	
	merge 1:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(type_client consumption_electricite prepaid_woyofal) keep(3) nogen
	
	merge 1:1 hhid using `elec_share', keep(3) nogen

	qui: sum type_client
	local n_type_client = r(max)
	
	forvalues i = 0/1 { 
		forvalues j = 1/`n_type_client' { 
				gen a_user_`i'_`j' = prepaid_woyofal == `i' & type_client==`j' 
				gen a_c_user_`i'_`j' = consumption_electricite/hhsize if prepaid_woyofal == `i' & type_client==`j' 
		}
	}

	collapse (mean) *user_* *share_elec coverage [aw=hhweight], by(yd_deciles_pc) fast

	foreach v of varlist a_user* *share_elec coverage {
		replace `v'=100*`v'
	}
		
	gen scenario = `scenario'
	order scenario yd_deciles_pc a_user* a_c_user*, first
	
	tempfile elec1_`scenario'
	save `elec1_`scenario'', replace

}

clear
forvalues scenario = 1/$numscenarios {
	append using `elec1_`scenario''
}

export excel "$xls_out", sheet(Fig_3) first(variable) sheetreplace 






