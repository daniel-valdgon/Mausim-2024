*-----------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico
* Date: June 2020
* Version: 1.0

*Version 2: 
*Oct 2022: 
	
	// 1. Definition of beneficiaries as user of public hospitals in q07 and q23 omitted some public hospital categories for Q23: 4 Poste de santé, 5	Case de santé,  6	Autre public (y compris maternité rurale).
	
	// Note: 
		//  To be decided if use eligibility vs use approach. 
			// Eligibility approach needs adm data on coverage because coverage of CMU is relatively low  
			// Use approach does no capture household who did not suffer from illness during the period asked for the survey
*Version 3: 


*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------

/********** Education *******/

global run_qeduc = 0
global run_qhealth = 0

use "$presim/inkind_transfers2.dta", clear 

merge m:1 hhid using "$presim/01_menages.dta", assert(3) keepusing(hhweight hhsize) nogen

*----- Values
local tot_1 	1591417508
local tot_2 	17175917502
local tot_3 	5385512447
local tot_4 	2928263675
local tot_7		4605851859
local tot_8 	4373212362
*local tot_11 	2094254648
*local tot_13 	1700723018

local policy 1 2 3 4 7 8

gen uno = 1

foreach i of local policy {
	qui sum level_`i' [iw=hhweight]
	
	local level_`i' `r(sum)' 
	di `level_`i''
	
	gen am_educ_`i' = `tot_`i'' / `level_`i'' if level_`i' == 1
}


gen bened = am_educ_2 > 0
	
* Add Quality only to primary
if $run_qeduc == 1{
	
	local index1_r 0.84765 
	local index1_u 1.21619

	gen index = .
	replace index = `index1_u' if milieu == 1
	replace index = `index1_r' if milieu == 2
	
	ren am_educ_2 am_educ_2_prev
	gen am_educ_2 = am_educ_2_prev * index

	tabstat am_*_2* uno [aw = hhweight], s(mean sum) by(milieu)

}

collapse (sum) am_educ*, by(hhid)

egen education_inKind=rowtotal(am*)

egen education_general=rowtotal(am_educ_1 am_educ_2 am_educ_3 am_educ_4 am_educ_8)

tempfile Transfers_InKind_Education
save `Transfers_InKind_Education'


global educ_var am_educ_1 am_educ_2 am_educ_3 am_educ_4 am_educ_8

/********** Health *******/


global mont_health_pc 20220

use "$presim/inkind_transfers.dta", clear 
 
merge 1:1 hhid using "$presim/01_menages.dta", assert(3) keepusing(hhweight hhsize) nogen
 
 
sum ht_use [iw=hhweight]
*local beneficiaries `r(sum)' // dis "`sante_beneficiare'"

* Insurance
gen aux_use = ht_use > 0
gen aux_cnam = cnam > 0

tab aux_use aux_cnam [iw = hhweight], m row
tab ht_use aux_cnam [iw = hhweight], m col

gen am_health = $mont_health_pc if ht_use > 0
gen am_health2 = $mont_health_pc if aux_cnam > 0 
gen am_health3 = $mont_health_pc if aux_cnam > 0 & inlist(ht_dist, 1, 2, 3, 4, 5) 

di $mont_health_pc
sum am_health, d
 
gen benhe = am_health > 0 & am_health != .
 
 
* Add Quality
if $run_qhealth == 1{

	gen index=.

	* Assign Params
	levelsof location, local(category)
	foreach z of local category {
		replace index      = ${ink_qh_`z'} if location == `z'
	}
	
	ren am_health am_health_prev
	gen am_health = am_health_prev * index

	tabstat am_health_prev am_health benhe [aw = hhweight], s(mean sum) by(location)
		
}


collapse (sum) am_health*, by(hhid)

egen health_inKind=rowtotal(am_health)

merge 1:1 hhid using `Transfers_InKind_Education', keep(3) nogen

if $devmode== 1 {
    save "$tempsim/Transfers_InKind.dta", replace
}

tempfile Transfers_InKind
save `Transfers_InKind'


