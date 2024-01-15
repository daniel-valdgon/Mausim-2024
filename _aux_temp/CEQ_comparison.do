//Users (change this according to your own folder location)	
if "`c(username)'"=="wb419055" {
	global path     	"C:\Users\wb419055\OneDrive - WBG\West Africa\Senegal\Senegal_tool\Senegal_tool"
}
if "`c(username)'"=="andre" {
	global path     	"C:\Users\andre\Dropbox\Energy_Reform\Senegal_tool"
}

//dta paths
global data_dev    	"$path/01. Data"
global data_sn      "$data_dev/1_raw"
global presim     	"$data_dev/2_pre_sim"
global tempsim      "$data_dev/3_temp_sim"
global data_out    	"$data_dev/4_sim_output"

**************************************************************************************************************

use "$data_out\output", clear

local Directaxes 		"income_tax trimf"
local Contributions 	"csh_css csh_ipm"
local DirectTransfers   "am_bourse am_Cantine am_BNSF am_subCMU"
local subsidies         "subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_eau_direct subsidy_eau_indirect" 
local Indtaxes 			"excise_taxes TVA_direct TVA_indirect"
local Education 		"education_inKind" 
local Health			"Sante_inKind am_sesame am_moin5 am_cesarienne"
local taxcs 			`Directaxes' `Indtaxes' `Contributions'
local transfers         `DirectTransfers' `subsidies' `Education' `Health'

foreach var in `taxcs' `transfers'{
    replace `var'=`var'_pc
	replace `var'=0 if `var'==.
}


* reemplazar valores para llevar todo a un mes base y ahí sí calcular todo lo de acá abajo
/*
ceqdes [pw=hhweight] using "$data_out\CEQ_commands.xlsx", mpluspensions(ymp_pc) netmarket(yn_pc) disposable(yd_pc) consumable(yc_pc) final(yf_pc) hsize(hhsize) dtransfers(`DirectTransfers') dtaxes(`Directaxes') contribs(`Contributions') subsidies(`subsidies') indtaxes(`Indtaxes') health(`Health') education(`Education')

ceqfiscal [pw=hhweight] using "$data_out\CEQ_commands.xlsx", mpluspensions(ymp_pc) netmarket(yn_pc) disposable(yd_pc) consumable(yc_pc) final(yf_pc) hsize(hhsize) dtransfers(`DirectTransfers') dtaxes(`Directaxes') contribs(`Contributions') subsidies(`subsidies') indtaxes(`Indtaxes') health(`Health') education(`Education')

ceqconc [pw=hhweight] using "$data_out\CEQ_commands.xlsx", mp(ymp_pc) n(yn_pc) d(yd_pc) c(yc_pc) f(yf_pc) hsize(hhsize) open

ceqextend [pw=hhweight] using "$data_out\CEQ_commands.xlsx", mp(ymp_pc) netmarket(yn_pc) disposable(yd_pc) consumable(yc_pc) final(yf_pc) hsize(hhsize) dtransfers(`DirectTransfers') dtaxes(`Directaxes') contribs(`Contributions') subsidies(`subsidies') indtaxes(`Indtaxes') health(`Health') education(`Education')

ceqmarg [pw=hhweight] using "$data_out\CEQ_commands.xlsx", mp(ymp_pc) netmarket(yn_pc) disposable(yd_pc) consumable(yc_pc) final(yf_pc) hsize(hhsize) dtransfers(`DirectTransfers') dtaxes(`Directaxes') contribs(`Contributions') subsidies(`subsidies') indtaxes(`Indtaxes') health(`Health') education(`Education') pl1(188161.78) pl2(319437.45) pl3(599492.19) ppp(1) cpisurvey(100) cpibase(100)
*/

*wbopendata, country(SEN) indicator("PA.NUS.PRVT.PP") clear
global ppp 238.5777

*wbopendata, country(SEN) indicator("FP.CPI.TOTL") clear
global cpi_2017 106.87056
global cpi_2018 107.36322



global pathE "C:\Users\andre\Dropbox\Energy_Reform\CEQ_MWB\MWB2017_E_March_2018"

*ceqdes [pw=hhweight] using "$pathE\MWB2018_E1_March29_2018.xlsx", mpluspensions(ymp_pc) netmarket(yn_pc) disposable(yd_pc) consumable(yc_pc) final(yf_pc) hsize(hhsize) dtransfers(`DirectTransfers') dtaxes(`Directaxes') contribs(`Contributions') subsidies(`subsidies') indtaxes(`Indtaxes') health(`Health') education(`Education') psu(hhid)

*ceqlorenz [pw=hhweight] using "$pathE\MWB2018_E3_March29_2018.xlsx", mp(ymp_pc) n(yn_pc) disposable(yd_pc) consumable(yc_pc) final(yf_pc) hsize(hhsize) open psu(hhid) cut1(2.15) cut2(3.65) cut3(6.85) ppp(${ppp}) cpibase(${cpi_2017}) cpisurvey(${cpi_2018}) yearly pl1(2.15) pl2(3.65) pl3(6.85) nationalmoderatepl(333440.5)

*ceqconc [pw=hhweight] using "$pathE\MWB2018_E10_March29_2018.xlsx", mp(ymp_pc) n(yn_pc) d(yd_pc) c(yc_pc) f(yf_pc) hsize(hhsize) open psu(hhid) cut1(2.15) cut2(3.65) cut3(6.85) ppp(${ppp}) cpibase(${cpi_2017}) cpisurvey(${cpi_2018}) yearly

*ceqfiscal [pw=hhweight] using "$pathE\MWB2018_E11_March29_2018.xlsx", mp(ymp_pc) n(yn_pc) d(yd_pc) c(yc_pc) f(yf_pc) hsize(hhsize) dtransfers(`DirectTransfers') dtaxes(`Directaxes') contribs(`Contributions') subsidies(`subsidies') indtaxes(`Indtaxes') health(`Health') education(`Education') open psu(hhid) cut1(2.15) cut2(3.65) cut3(6.85) ppp(${ppp}) cpibase(${cpi_2017}) cpisurvey(${cpi_2018}) yearly

*ceqextend [pw=hhweight] using "$pathE\MWB2018_E12_March29_2018.xlsx", mp(ymp_pc) n(yn_pc) d(yd_pc) c(yc_pc) f(yf_pc) hsize(hhsize) dtransfers(`DirectTransfers') dtaxes(`Directaxes') contribs(`Contributions') subsidies(`subsidies') indtaxes(`Indtaxes') health(`Health') education(`Education') open psu(hhid) cut1(2.15) cut2(3.65) cut3(6.85) ppp(${ppp}) cpibase(${cpi_2017}) cpisurvey(${cpi_2018}) yearly

*ceqmarg [pw=hhweight] using "$pathE\MWB2018_E13_March29_2018.xlsx", mp(ymp_pc) n(yn_pc) d(yd_pc) c(yc_pc) f(yf_pc) hsize(hhsize) dtransfers(`DirectTransfers') dtaxes(`Directaxes') contribs(`Contributions') subsidies(`subsidies') indtaxes(`Indtaxes') health(`Health') education(`Education') open psu(hhid) cut1(2.15) cut2(3.65) cut3(6.85) ppp(${ppp}) cpibase(${cpi_2017}) cpisurvey(${cpi_2018}) yearly pl1(2.15) pl2(3.65) pl3(6.85) nationalmoderatepl(333440.5)

*ceqefext [pw=hhweight] using "$pathE\MWB2018_E14_March29_2018.xlsx", mp(ymp_pc) n(yn_pc) d(yd_pc) c(yc_pc) f(yf_pc) hsize(hhsize) dtransfers(`DirectTransfers') dtaxes(`Directaxes') contribs(`Contributions') subsidies(`subsidies') indtaxes(`Indtaxes') health(`Health') education(`Education') open psu(hhid) cut1(2.15) cut2(3.65) cut3(6.85) ppp(${ppp}) cpibase(${cpi_2017}) cpisurvey(${cpi_2018}) yearly pl1(2.15) pl2(3.65) pl3(6.85) nationalmoderatepl(333440.5)

ceqcoverage [pw=hhweight] using "$pathE\MWB2018_E18_March29_2018.xlsx", mp(ymp_pc) n(yn_pc) d(yd_pc) c(yc_pc) f(yf_pc) hsize(hhsize) dtransfers(`DirectTransfers') dtaxes(`Directaxes') contribs(`Contributions') subsidies(`subsidies') indtaxes(`Indtaxes') health(`Health') education(`Education') open psu(hhid) cut1(2.15) cut2(3.65) cut3(6.85) ppp(${ppp}) cpibase(${cpi_2017}) cpisurvey(${cpi_2018}) yearly


