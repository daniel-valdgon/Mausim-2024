
global path "C:\Users\WB419055\OneDrive - WBG\SenSim Tool\Senegal_tool\Senegal_tool"
global sim_programs "C:\Users\WB419055\OneDrive - WBG\SenSim Tool\Senegal_tool\Senegal_tool\01. Data\3_temp_sim\PSIA\CMU_expansion"

*Needs to be run after using original values in the tool 

*include "$path/02. Dofile/01.Pullglobals.do"

use "$sim_programs/output_low.dta", clear 

foreach v in am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc {

	rename 	`v' low_`v'
	replace low_`v'=low_`v'!=0

}


keep hhid low_*
merge 1:1 hhid using "$sim_programs/output_high.dta", keepusing (am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc )

foreach v in am_bourse_pc am_Cantine_pc am_BNSF_pc am_subCMU_pc am_sesame_pc am_moin5_pc am_cesarienne_pc {

	replace `v'=`v'!=0

	ta low_`v' `v' 
}

