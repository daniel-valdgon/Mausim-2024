/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
 Program: CEQ Mauritania
 Author: Gabriel
 Date: 2024
 

*--------------------------------------------------------------------------------*/

use  "$presim/01_social_security.dta", replace 

keep hhid ss_ben* ss_cont*

replace ss_contrib_pub = 0 if ss_contrib_pub == .
replace ss_contrib_pri = 0 if ss_contrib_pri == .

sum * 

replace ss_contrib_pub = 840000 if ss_contrib_pub > 840000
replace ss_contrib_pri = 840000 if ss_contrib_pri > 840000

sum *

collapse (sum) ss_ben* ss_contrib_pub ss_contrib_pri, by(hhid)

sum *

if $devmode== 1 {
    save "$tempsim/social_security_contribs.dta", replace
}



