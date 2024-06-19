* Senegal Comparison: SEN_tool, VAT_tool
clear all

global path_SEN     "/Users/gabriellombomoreno/Documents/WorldBank/Senegal_tool"
global path_VAT     "/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool"

global raw_SEN       "${path_SEN}/01. Data/1_raw"
global presim_SEN       "${path_SEN}/01. Data/2_pre_sim"
global tempsim_SEN      "${path_SEN}/01. Data/3_temp_sim"

global presim_VAT       "${path_VAT}/01_data/2_pre_sim/SEN"
global tempsim_VAT      "${path_VAT}/01_data/3_temp_sim"

global var "SEN VAT"

* Check Subsidies
foreach i of global var {
	
	cap frame drop `i'_data
	frame create `i'_data
	frame change `i'_data
 
	use "${tempsim_`i'}/Subsidies_verylong.dta", clear	
	
}

frame SEN_data: sum hhid achats*
frame VAT_data: sum hhid achats*

frame SEN_data: sum achats_sans_subs, d
frame VAT_data: sum achats_sans_subs, d

frame VAT_data: desc *


frame change SEN_data

ren Secteur sector
keep hhid codpr sector informal_purchase achats_sans_subs
*ren achats_sans_subs achats_sans_subs_SEN

frlink 1:1 hhid codpr sector informal_purchase, frame(VAT_data)

frame change VAT_data


clear all
* Check Excises
foreach i of global var {
	
	frame create `i'_data
	frame change `i'_data
 
	use "${tempsim_`i'}/Excises_verylong.dta", clear	
	
}

frame SEN_data: sum hhid achats*
frame VAT_data: sum hhid achats*

frame SEN_data: sum achats_sans_subs, d
frame VAT_data: sum achats_sans_subs, d

clear all
* Check Excises 2
foreach i of global var {
	
	frame create `i'_data
	frame change `i'_data
 
	use "${tempsim_`i'}/Excise_taxes.dta", clear	
	
}

frame SEN_data: sum hhid dep*
frame VAT_data: sum hhid dep*

frame SEN_data: sum hhid ex*
frame VAT_data: sum hhid ex*

frame SEN_data: sum achats_sans_subs, d
frame VAT_data: sum achats_sans_subs, d


***

Excise_taxes



frames dir


frame create SEN_data
frame change SEN_data

use "${raw_SEN}/IO_percentage3.dta", clear

frame create VAT_data
frame change VAT_data

use "${presim_VAT}/IO_percentage.dta", clear









codpr	hhid	sector	informal_purchase	achats_sans_subs	VAT_data
78	30001	2	1	79110.55	51117
