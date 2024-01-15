*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico 
* Date: June 2020
* Version: 1.0
*--------------------------------------------------------------------------------

*set more off
*clear all

*global root = "C:\Users\wb521296\OneDrive - WBG\Desktop\Senegal\CEQ 2020"


********************************************************************************

*global dataout = "$root/SENEGAL_ECVHM_final/Dataout"
*global datain  = "$root/SENEGAL_ECVHM_final/Datain"

/*

Social Security Contributions
=============================

CSS (Health)
------------
Estimated wage Income for those who report that are in this social security system. 
It is an employer contribution to social security, but we assume that the incidence
goes to employee.

*/

*******************************************************************************
* Social Security Contributions
*******************************************************************************
**Social Security Contributions (only for first job)
*css 7%+ 1 to 5% with ceilling

use "$dta/Direct_taxes_complete_Senegal.dta", clear

*******************************************************************************
* Sante et L'Allocation Familiale
*******************************************************************************

gen cssh_css=inclab*($AFASRateT1) + inclab*($AATRateT2) if payment_taxes==1  //7% +1% to 3% (risk adjusted)
**risk sectors
gen risk_css=2 if s04q30c==5 | s04q30c==15 | (s04q30c>=17 & s04q30c<=22) | s04q30c==25 | s04q30c==26 | s04q30c==33 | s04q30c==35 | s04q30c==36 | s04q30c==40  ///
					| s04q30c==41 | s04q30c==50 | s04q30c==51 | s04q30c==52 | s04q30c==60 | s04q30c==63  
replace risk_css=3 if (s04q30c>=10 & s04q30c<=14) | s04q30c==16 | s04q30c==23 | s04q30c==24 | (s04q30c>=27 & s04q30c<=32) | s04q30c==34 | s04q30c==45  ///
					| s04q30c==61 | s04q30c==62 
		
replace cssh_css=inclab*($AFASRateT1) + inclab*($AATRateT3) if cssh_css>0 & cssh_css<. & risk_css==2
replace cssh_css=inclab*($AFASRateT1) + inclab*($AATRateT4) if cssh_css>0 & cssh_css<. & risk_css==3
replace cssh_css=$MaximumRateT5 if cssh_css>$MaximumRateT5 & cssh_css!=.
replace cssh_css=0 if payment_taxes==0
replace cssh_css=0 if formal==0


*******************************************************************************
* Contribution à Pension
*******************************************************************************

* IPRES

gen cssp_ipres=inclab*$IPRESRateT2 if payment_taxes==1 & age>=18 & age<=50
replace cssp_ipres=$IPRESMaxT2 if cssp_ipres>$IPRESMaxT2 & cssp_ipres!=.
replace cssp_ipres=inclab*$IPRESRateT3 if payment_taxes==1 & age>=18 & age<=50 & (s04q39==1|s04q39==1)
replace cssp_ipres=$IPRESMaxT3 if payment_taxes==1 & age>=18 & age<=50 & (s04q39==1|s04q39==1) & cssp_ipres>9216000 & cssp_ipres!=.
replace cssp_ipres=0 if payment_taxes==0
replace cssp_ipres=0 if formal==0

*FNR

gen cssp_fnr=inclab*$FNRRateT1 if payment_taxes==1
replace cssp_fnr=0 if payment_taxes==0
replace cssp_fnr=0 if formal==0

replace cssp_fnr=0  if inlist(s04q31,3,4,5,6)
replace cssp_ipres=0  if inlist(s04q31,1,2)

rename cssh_css    csh_css
rename cssp_fnr    csp_fnr
rename cssp_ipres  csp_ipr

label var csh_css  "Contributions Health - css"
label var csp_fnr  "Contributions pensions - FNR"
label var csp_ipr  "Contributions pensions - IPRES"

capture rename __000000 somethingelse
capture drop __000000


collapse (sum) csh_css csp_fnr csp_ipr hhweight (mean) hhsize , by(hhid)

tempfile social_security_contributions

save `social_security_contributions'


*save "$dta/social_security_contributions.dta", replace



