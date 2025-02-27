/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
 Program: CEQ Mauritania
 Author: Gabriel
 Date: 2024
 

*--------------------------------------------------------------------------------*/

use  "$presim/01_social_security.dta", replace 

*keep hhid ss_ben* ss_cont*

*---- Social Contributions
gen ss_contrib_pub = an_income * ${ap_public} * public
gen ss_contrib_pri = an_income * ${ap_private} * (1 - public)

replace ss_contrib_pub = 0 if ss_contrib_pub == .
replace ss_contrib_pri = 0 if ss_contrib_pri == .
replace ss_contrib_pub = 840000 if ss_contrib_pub > 840000
replace ss_contrib_pri = 840000 if ss_contrib_pri > 840000

egen ss_contrib =  rowtotal(ss_contrib_pub ss_contrib_pri)

*---- Pensions
gen ss_ben_old = ${soc_cont} * ${pen_old} * pen_old
gen ss_ben_other = ${soc_cont} * ${pen_other} * pen_other

egen ss_ben =  rowtotal(ss_ben_old ss_ben_other)

/*
if $run_ss == 0 {
	
	foreach i of varlist ss_contrib_pub-ss_ben {
		replace `i' = 0
	}
}
*/

collapse (sum) ss_ben* ss_contrib_pub ss_contrib_pri, by(hhid)

sum *

if $devmode== 1 {
    save "$tempsim/social_security_contribs.dta", replace
}



