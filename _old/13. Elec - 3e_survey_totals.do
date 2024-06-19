/*============================================================================================
 ======================================================================================

	Project:		Subsidies - All Figures
	Author:			Gabriel 
	Creation Date:	Apr 21, 2023
	Modified:		
	
	Note: 			Extra tables and graphs
============================================================================================
============================================================================================*/

if "`c(username)'"=="wb419055" {

global path     	"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024\00_Workshop\Feb_2024\VAT_tool"

global path_out		"C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\03_MauSim\Mausim_2024\00_Workshop\QER"

global data_out    	"${path}/01_data/4_sim_output"
global presim       "${path}/01_data/2_pre_sim/MRT"

global proj 		"output_Ref_2018b" // Name of the output data
global namexls		"SN_Sim_tool_sub_elec" // Name of excel file 
global numscenarios 1

}

else {

global path     	"/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool"
global path_out		".../03_MauSim/Mausim_2024/00_Workshop/QER"

global data_out    	"${path}/01_data/4_sim_output"
global presim       "${path}/01_data/2_pre_sim/MRT"

global proj 		"output_V1_MRT_SubElec_Ref" // Name of the output data
global namexls		"SN_Sim_tool_sub_elec" // Name of excel file 
global numscenarios 1

}


*Coverage per decile 

use "$data_out/${proj}.dta", clear
cap drop type_client
cap drop consumption_electricite
ren depan depan_o
merge 1:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(type_client consumption_electricite prepaid_woyofal depan)

ta type_client [aw=pondih]

/*-------------------------------------------------------/
	1. Coverage of Households per decile
/-------------------------------------------------------*/

preserve 
	gen sociale=type_client==1
	gen domestique=type_client==2
	gen no_cone=type_client==0
	
	collapse (mean) sociale domestique no_cone [aw=pondih], by(yd_deciles_pc) fast

restore 

/*-------------------------------------------------------/
	2. Consumption per decile
/-------------------------------------------------------*/

preserve 
	gen sociale=consumption_electricite/hhsize if type_client==1
	gen domestique=consumption_electricite/hhsize if type_client==2
	gen no_cone=consumption_electricite/hhsize if type_client==0 // it should be zero 
	
	collapse (mean) sociale domestique no_cone [aw=pondih], by(yd_deciles_pc) fast

restore 


/*-------------------------------------------------------/
	3. Percetage of spending
/-------------------------------------------------------*/
preserve 
	gen elect_s=depan/depan_o if depan>0 & depan!=.
	
	recode yd_deciles_pc (1 2=1) (3 4=2) (5 6=3) (7 8=4) (9 10=5), gen (yd_quintiles)
	
	collapse (mean) elect_s  [aw=pondih], by(yd_quintiles) fast
restore 


/*-------------------------------------------------------/
	1. Coverage of Households per decile
/-------------------------------------------------------*/

/****************************************
Table/graph of tranches per decile 
******************************************/


foreach scenario in $numscenarios {

	use "$data_out/${proj}.dta", clear

	merge 1:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(type_client consumption_electricite prepaid_woyofal)

	gen tranche1 = inlist(type_client, 1, 2)
	gen tranche2 = 0
	gen tranche3 = 0
	gen tranche_sociale = 0
	gen tranche_gdp = 0 //DGP

	collapse (mean) tranche_sociale tranche1 tranche2 tranche3 tranche_gdp [aw=pondih], by(yd_deciles_pc) fast
	
	gen no_electr_sp=1-(tranche_sociale + tranche1 + tranche2 + tranche3 + tranche_gdp)

	foreach v in no_electr_sp tranche_sociale tranche1  tranche2  tranche3  tranche_gdp {
		replace `v'=100*`v'
	}
	
	gen scenario = `scenario'
	
	tempfile elec1_`scenario'
	save `elec1_`scenario'', replace
	
}

clear
foreach scenario in $numscenarios {
	append using `elec1_`scenario''
}

export excel "$path_out/${namexls}.xlsx", sheet(tab_elec_tranches) first(variable) sheetreplace 


/****************************************
Table/graph of cons groups per decile 
******************************************/

foreach scenario in $numscenarios{

	use "$data_out/${proj}.dta", clear

	merge 1:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(type_client consumption_electricite prepaid_woyofal)
	
	gen DPP_prep  = (type_client==1 & prepaid==1)
	gen DPP_postp = (type_client==1 & prepaid==0)
	gen DMP_prep  = (type_client==2 & prepaid==1)
	gen DMP_postp = (type_client==2 & prepaid==0)
	gen DGP       = 0

	collapse (mean) DPP_prep DPP_postp DMP_prep DMP_postp DGP [aw=pondih], by(yd_deciles_pc) fast
	
	gen no_electr_sp=1-(DPP_prep + DPP_postp + DMP_prep + DMP_postp + DGP)

	foreach v in no_electr_sp DPP_prep DPP_postp DMP_prep DMP_postp DGP {
		replace `v'=100*`v'
	}

	gen scenario = `scenario'
	
	tempfile elec2_`scenario'
	save `elec2_`scenario'', replace
}

clear
foreach scenario in $numscenarios{
	append using `elec2_`scenario''
}

export excel "$path_out/${namexls}.xlsx", sheet(tab_elec_cons_groups) first(variable) sheetreplace 




/*-------------------------------------------------------/
	2. Consumption of Households per decile
/-------------------------------------------------------*/

/****************************************
Table/graph of tranches per decile 
******************************************/

foreach scenario in $numscenarios{

	use "$data_out/${proj}.dta", clear

	merge 1:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(type_client consumption_electricite prepaid_woyofal)

	keep if inlist(type_client, 1, 2)
	
	gen double pc_consumption_electricite = round(consumption_electricite/hhsize,0.01)

	gen tranche1 = inlist(type_client, 1, 2) * pc_consumption_electricite // Multiply all
	gen tranche2 = 0 
	gen tranche3 = 0
	gen tranche_sociale = 0
	gen tranche_gdp = 0 //DGP
	
	collapse (mean) tranche_sociale tranche1 tranche2 tranche3 tranche_gdp [aw=hhweight], by(yd_deciles_pc) fast
	
	gen scenario = `scenario'
	
	tempfile elec1_`scenario'
	save `elec1_`scenario'', replace
	
}

clear
foreach scenario in $numscenarios{
	append using `elec1_`scenario''
}

export excel "$path_out/${namexls}.xlsx", sheet(tab_elec_consum_tranches) first(variable) sheetreplace 


/****************************************
Table/graph of cons groups per decile 
******************************************/

foreach scenario in $numscenarios{

	use "$data_out/${proj}.dta", clear

	merge 1:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(type_client consumption_electricite prepaid_woyofal)
	
	keep if inlist(type_client, 1, 2)
	
	gen double pc_consumption_electricite = round(consumption_electricite/hhsize,0.01)
	
	gen DPP_prep  = (type_client==1 & prepaid==1) * pc_consumption_electricite
	gen DPP_postp = (type_client==1 & prepaid==0) * pc_consumption_electricite
	gen DMP_prep  = (type_client==2 & prepaid==1) * pc_consumption_electricite
	gen DMP_postp = (type_client==2 & prepaid==0) * pc_consumption_electricite
	gen DGP       = 0

	collapse (mean) DPP_prep DPP_postp DMP_prep DMP_postp DGP [aw=pondih], by(yd_deciles_pc) fast

	gen scenario = `scenario'
	
	tempfile elec2_`scenario'
	save `elec2_`scenario'', replace
}

clear
foreach scenario in $numscenarios{
	append using `elec2_`scenario''
}

export excel "$path_out/${namexls}.xlsx", sheet(tab_elec_consum_cons_groups) first(variable) sheetreplace 

/*-------------------------------------------------------/
	3. Incidence 
/-------------------------------------------------------*/


