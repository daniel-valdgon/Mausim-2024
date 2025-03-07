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

*----- Household Data
use "$data_sn/EPCV2019_income.dta" , clear

* Standardization
keep hid idp wgt hhsize pcc

ren hid hhid
ren wgt hhweight

* Disposable Income
collapse (sum) dtot = pcc, by(hhid hhweight hhsize)

ren hhid hid
merge 1:1 hid using "$data_sn/menage_pauvrete_2019.dta", keep(matched) keepusing(hhweight hhsize zref pcexp) nogen

gen pcc = dtot/hhsize

gen pondih = hhweight*hhsize
_ebin pcc [aw=pondih], nq(10) gen(decile_expenditure)

drop pondih
ren hid hhid
/**** Create poverty lines

* MRT: i2017 - 1.05, i2018 - 0.65, i2019 - 0.98. ccpi_a
* MRT: i2017 - 3.0799999,	i2018 - 4.2035796. fcpi_a
* MRT: i2017 - 2.269, i2018 - 3.07. hcpi_a
* MRT Inflation according to WorldBank Data Dashboard. 2017 - 2.3, 2018 - 3.1
* Country specific...

local ppp17 = 12.4452560424805
local inf17 = 2.3
local inf18 = 3.1
local inf19 = 2.3
cap drop line_1 line_2 line_3
gen line_1=2.15*365*`ppp17'*`inf17'*`inf18'*`inf19'
gen line_2=3.65*365*`ppp17'*`inf17'*`inf18'*`inf19'
gen line_3=6.85*365*`ppp17'*`inf17'*`inf18'*`inf19'

foreach var in /*line_1 line_2 line_3*/ yd_pc yc_pc  {
	gen test=1 if `var'<=zref
	recode test .= 0
	noi tab test [iw=hhweight*hhsize]
	drop test
}
*/

save "$presim/01_menages.dta", replace

