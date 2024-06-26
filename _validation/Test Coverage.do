

global path			"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mauritania/Mausim_2024"
global data_sn 		"${path}/01_data/1_raw/MRT"    
*global presim 		"${path}/01_data/2_pre_sim/MRT"    
global data_out    	"${path}/01_data/4_sim_output"
*global xls_out    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx"




use "$data_sn/Datain/individus_2019.dta", clear

forvalues i = 1/6 {
	gen prog_`i' = (PS4A == `i' | PS4B == `i' | PS4C == `i')
	gen prog_amount_`i' = PS7 if prog_`i' == 1
	
	egen hh_prog_`i' = max(prog_`i' == 1), by(hid)
	egen hh_prog_amount_`i' = total(prog_amount_`i'), by(hid)
}

ren hid hhid

egen tag = tag(hhid)


merge m:1 hhid using "$tempsim/Direct_transfers.dta", nogen keep(3) 

gen uno = 1

gen ben_tek = am_BNSF1>0
 
tab PS4A [iw = hhweight] if am_Cantine>0

sdgvbawrsdf
*/




merge m:1 hhid using "$data_out/output_V0_MRT_Test2.dta", nogen keep(3) keepusing(*deciles* ymp_pc yn_pc yd_pc yc_pc hhsize hhweight am*)

global progs "prog_1 prog_2 prog_3 prog_4 prog_5 prog_6"
global hh_progs "hh_prog_1 hh_prog_2 hh_prog_3 hh_prog_4 hh_prog_5 hh_prog_6"


*tabstat prog_1 prog_amount_1 [aw = hhweight], s(sum) by(deciles_pc)
tabstat hh_prog_1 hh_prog_amount_1 [aw = hhweight] if tag == 1, s(sum) by(deciles_pc)

_ebin ymp_pc [aw=hhweight], nq(10) gen(decile_ymp)

tabstat hh_prog_1 hh_prog_amount_1 [aw = hhweight] if tag == 1, s(sum) by(decile_ymp)

* Received Tekavoul
gen tekavoul = am_BNSF1 > 1

tab tekavoul hh_prog_1 [iw = hhweight] if tag == 1



*tabstat prog_1 prog_2 prog_3 prog_4 prog_5 prog_6 [aw = hhweight], s(sum) by(deciles_pc)





