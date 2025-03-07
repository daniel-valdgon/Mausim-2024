/*======================================================
 =======================================================

	Project:		Read Data used in presim
	Author:			Gabriel 
	Creation Date:	Apr 21, 2023
	Modified:		
	
	Note:
	Data input: 	1. Informality Bachas
					2. EPCV2019_income
					3. pivot2019

	Data output: 	1. 01_menages
					2. 05_purchases_hhid_codpr
					3. IO_Matrix
========================================================
=======================================================*/


*ssc install gtools
*ssc install ereplace
*net install gr0034.pkg

set seed 123456789


*----- IO Matrix
import excel "$data_sn/IO_Matrix.xlsx", sheet("IO_matrix") firstrow clear
	 
local thefixed 		"8 9" 
local sect_elec  	"8"
local sect_emel 	"1"

 	
gen fixed=0
foreach var of local thefixed {
	replace fixed=1  if  sector==`var'
}

gen elec_sec=0
foreach var of local sect_elec {
	replace elec_sec=1  if  sector==`var'
}

gen emel_sec = 0
foreach var of local sect_emel {
	replace emel_sec=1  if  sector==`var'
}

	
save "$presim/IO_Matrix.dta", replace




