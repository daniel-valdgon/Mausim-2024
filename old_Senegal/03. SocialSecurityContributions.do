*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico 
* Date: June 2020
* Version: 1.0
*--------------------------------------------------------------------------------

********************************************************************************

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

if $devmode ==0 {
use `Direct_taxes_complete_Senegal', clear
}
if $devmode ==1 {
use "$tempsim/Direct_taxes_complete_Senegal.dta", clear 

}


/**********************************************************************************/
noi dis as result " 1. Risque Maladie et L'Allocation Familiale                    "
/**********************************************************************************/

*AGV: The maximum was misinterpreted before, it is not the maximum contribution, is the maximum base over which the contribution is calculated
gen inclab_AFAS=inclab
gen inclab_AAT1=inclab
gen inclab_AAT2=inclab
gen inclab_AAT3=inclab

replace inclab_AFAS=$AFAS_Max if $AFAS_Max !=. & inclab_AFAS>$AFAS_Max & inclab_AFAS<.
replace inclab_AAT1=$AAT_R1_Max if $AAT_R1_Max !=. & inclab_AAT1>$AAT_R1_Max & inclab_AAT1<.
replace inclab_AAT2=$AAT_R2_Max if $AAT_R2_Max !=. & inclab_AAT2>$AAT_R2_Max & inclab_AAT2<.
replace inclab_AAT3=$AAT_R3_Max if $AAT_R3_Max !=. & inclab_AAT3>$AAT_R3_Max & inclab_AAT3<.

gen cssh_css=inclab_AFAS*($AFAS_Rate) + inclab_AAT1*($AAT_R1_Rate) if payment_taxes==1  // AFAS=7% + AAT_R1_Rate=1% to AAT_R2_Rate=3% (risk adjusted), we select 1% for all in general 

**risk sectors
gen risk_css=2 if s04q30c==5 | s04q30c==15 | (s04q30c>=17 & s04q30c<=22) | s04q30c==25 | s04q30c==26 | s04q30c==33 | s04q30c==35 | s04q30c==36 | s04q30c==40  ///
					| s04q30c==41 | s04q30c==50 | s04q30c==51 | s04q30c==52 | s04q30c==60 | s04q30c==63  
replace risk_css=3 if (s04q30c>=10 & s04q30c<=14) | s04q30c==16 | s04q30c==23 | s04q30c==24 | (s04q30c>=27 & s04q30c<=32) | s04q30c==34 | s04q30c==45  ///
					| s04q30c==61 | s04q30c==62 
		
replace cssh_css=inclab_AFAS*($AFAS_Rate) + inclab_AAT2*($AAT_R2_Rate) if cssh_css>0 & cssh_css<. & risk_css==2
replace cssh_css=inclab_AFAS*($AFAS_Rate) + inclab_AAT3*($AAT_R3_Rate) if cssh_css>0 & cssh_css<. & risk_css==3

replace cssh_css=0 if payment_taxes==0 & cssh_css!=.
*replace cssh_css=0 if formal==0 & cssh_css!=. //formal==0 is for sure not formal, but other not formal may have one (few but some)
*(AGV) I comment formal because that only applies to enterprise owners and many salaried workers were being assigned 0 because they are formal=0


/**********************************************************************************/
*noi dis as result " 2. Pension de vieillesse                                       "
/**********************************************************************************/
/*
gen inclab_IPRES1=inclab
gen inclab_IPRES2=inclab
gen inclab_FNR=inclab

replace inclab_IPRES1=$IPRES_R1_Max if $IPRES_R1_Max !=. & inclab_IPRES1>$IPRES_R1_Max & inclab_IPRES1<.
replace inclab_IPRES2=$IPRES_R2_Max if $IPRES_R2_Max !=. & inclab_IPRES2>$IPRES_R2_Max & inclab_IPRES2<.
replace inclab_FNR=$FNR_Max if $FNR_Max !=. & inclab_FNR>$FNR_Max & inclab_FNR<.


* ----------------IPRES ----------------
*T2
gen cssp_ipres=inclab_IPRES1*$IPRES_R1_Rate if payment_taxes==1 & age>=18 & age<=60

*T3
replace cssp_ipres=inclab_IPRES2*$IPRES_R2_Rate if payment_taxes==1 & age>=18 & age<=60 & (s04q39==1| s04q39==2) // (DV)	 this may be a mistake and they mean ==2 
*(AGV) I changed it to 2 to include intermediate managers

*Exclusiong (DV) alert because formal is a wrong variable!!!!! we are excluding less 
replace cssp_ipres=0 if payment_taxes==0
*replace cssp_ipres=0 if formal==0
*(AGV) I comment formal because that only applies to enterprise owners and many salaried workers were being assigned 0 because they are formal=0

* ---------------- FNR ----------------

gen cssp_fnr=inclab_FNR*$FNR_Rate if payment_taxes==1 & age>=18 & age<=60
replace cssp_fnr=0 if payment_taxes==0
*replace cssp_fnr=0 if formal==0 // (DV) again it may be wrong 
*(AGV) I comment formal because that only applies to enterprise owners and many salaried workers were being assigned 0 because they are formal=0

*----------------Dont pay FNR and IPRES ------------------
replace cssp_fnr=0    if inlist(s04q31,3,4,5,6)
replace cssp_ipres=0  if inlist(s04q31,1,2)
*/
*(AGV) (2023-10-03) Pension contributions are excluded, as we use the PDI approach
gen cssp_fnr =0
gen cssp_ipres =0

/**********************************************************************************/
noi dis as result " 2. Santé des travailleurs salariés                             "
/**********************************************************************************/

gen inclab_IPM=inclab

replace inclab_IPM=$IPM_Max if $IPM_Max !=. & inclab_IPM>$IPM_Max & inclab_IPM<.

gen cssh_ipm=inclab_IPM*$IPM_Rate if payment_taxes==1

replace cssh_ipm=0 if !inlist(s04q31,1,2,3,4,6)
replace cssh_ipm=0 if cssh_ipm==.


*******************************************************************************
* Re-organization
*******************************************************************************

drop inclab_AFAS inclab_AAT1 inclab_AAT2 inclab_AAT3 inclab_IPM //inclab_IPRES1 inclab_IPRES2 inclab_FNR

rename cssh_css    csh_css
rename cssp_fnr    csp_fnr
rename cssp_ipres  csp_ipr
rename cssh_ipm	   csh_ipm

label var csh_css  "Contrib. Health - CSS (labor risk & family)"
label var csp_fnr  "Contrib. Pensions - FNR (not included in PDI)"
label var csp_ipr  "Contrib. Pensions - IPRES (not included in PDI)"
label var csh_ipm  "Contrib. Health salaried workers"


cap drop __000000 
cap drop __000001 


collapse (sum) csh_css csp_fnr csp_ipr csh_ipm hhweight (mean) hhsize , by(hhid)


if $devmode== 1 {
    save "$tempsim/social_security_contribs.dta", replace
}

tempfile social_security_contribs

save `social_security_contribs'




