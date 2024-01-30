** PROYECT: CEQ Mauritania
** TO DO: Clean Correspondance tables and shape them the way needed 
** BY: Gabriel Lombo
** LAST UPDATE: 1/29/2024

* Import inofmration

global path "C:\Users\wb621266\OneDrive - WBG\Documents\GitHub\WorldBank\Reference Tables"

*ssc install tab_chi

*** ISIC
*** ISIC 3.0 - 3.1
import excel using "$path/Correspondance Tables.xlsx", sheet("ISIC3.0_ISIC3.1") firstrow clear

keep Rev3 Rev31
ren (Rev3 Rev31) (ISIC3 ISIC31)

* String
foreach i in ISIC3 ISIC31 {
	cap tostring `i', replace
	gen len = length(`i')
	tab len
	replace `i' = "0" + `i' if len == 3
	drop len
}

save "$path/output/ISIC3_ISIC31.dta", replace
 
*** ISIC 3.1 - 4.0
import excel using "$path/Correspondance Tables.xlsx", sheet("ISIC3.1_ISIC4.0") firstrow clear

keep ISIC31code ISIC4code
ren (ISIC31code ISIC4code) (ISIC31 ISIC4)

* String
foreach i in ISIC31 ISIC4 {
	cap tostring `i', replace
	gen len = length(`i')
	tab len
	replace `i' = "0" + `i' if len == 3
	drop len
}

save "$path/output/ISIC31_ISIC4.dta", replace

*** ISIC 3.0 - CPC 1.0
import excel using "$path/Correspondance Tables.xlsx", sheet("CPC1.0-ISICv3") firstrow clear

ren (CPCV10 ISICRev3) (CPC1 ISIC3)
keep CPC1 ISIC3

* CPC
local i CPC1
tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 4
drop len

* ISIC
local i ISIC3
cap tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 3
*drop if len==3
drop len

save "$path/output/ISIC3_CPC1.dta", replace

*** CPC 1.0 - COICOP
import excel using "$path/Correspondance Tables.xlsx", sheet("CPC1.0_COICOP") firstrow clear

ren (COICOP CPC10) (COICOP CPC1)
keep COICOP CPC1


* COICOP
local i COICOP
tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 3
drop len

* CPC
local i CPC1
cap tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 4
*drop if len==3
drop len

save "$path/output/CPC1_COICOP.dta", replace


*** CPC 1.0 - CPC 1.1
import excel using "$path/Correspondance Tables.xlsx", sheet("CPC1.1_CPC1.0") firstrow clear

ren (CPCv11code CPCV10code) (CPC11 CPC1)
keep CPC11 CPC1

* String
foreach i in CPC11 CPC1 {
	cap tostring `i', replace
	gen len = length(`i')
	tab len
	replace `i' = "0" + `i' if len == 4
	drop len
}

save "$path/output/CPC1_CPC11.dta", replace

*** CPC 1.1 - CPC 2.0
import excel using "$path/Correspondance Tables.xlsx", sheet("CPC2.0_CPC1.1") firstrow clear

ren (CPC2Code CPC11Code) (CPC2 CPC11)
keep CPC2 CPC11

* String
foreach i in CPC2 CPC11 {
	cap tostring `i', replace
	gen len = length(`i')
	tab len
	replace `i' = "0" + `i' if len == 4
	drop len
}

save "$path/output/CPC11_CPC2.dta", replace

*** CPC 2.0 - CPC 2.1
import excel using "$path/Correspondance Tables.xlsx", sheet("CPC2.1_CPC2.0") firstrow clear

ren (CPC21code CPC2code) (CPC21 CPC2)
keep CPC21 CPC2

* String
foreach i in CPC21 CPC2 {
	cap tostring `i', replace
	gen len = length(`i')
	tab len
	replace `i' = "0" + `i' if len == 4
	drop len
}

save "$path/output/CPC2_CPC21.dta", replace

*** CPC 2.1 - CPA 2.1
import excel using "$path/Correspondance Tables.xlsx", sheet("CPA2.1-CPC2.1") firstrow clear

*ren (CPC21code CPC2code) (CPC21 CPC2)
keep CPA21 CPC21

* String
foreach i in CPC21 {
	cap tostring `i', replace
	gen len = length(`i')
	tab len
	replace `i' = "0" + `i' if len == 4
	drop len
}

* String
foreach i in CPA21 {
	cap tostring `i', replace
	gen len = length(`i')
	tab len
	replace `i' = "0" + `i' if len == 5
	drop len
}

save "$path/output/CPC21_CPA21.dta", replace

* CN23 - CPA 2.1
import excel using "$path/Correspondance Tables.xlsx", sheet("CN23-CPA2.1") firstrow clear

ren (CPA_Ver2_1_CODE CN_2023_CODE) (CPA21 CN23)
keep CPA21 CN23


replace CPA21 = subinstr(CPA21, ".", "", .)
replace CN23 = subinstr(CN23, " ", "", .)

gen len1 = length(CPA21)
gen len2 = length(CN23)

tabm len*

drop if len1==1
drop len*

save "$path/output/CPA21_CN23.dta", replace



gab

*** ISIC 4.0
* Get the section
import excel using "$path/Correspondance Tables.xlsx", sheet("ISIC4.0") firstrow clear

keep Section Class
keep if length(Class) == 4

ren Class ISIC4

merge 1:m ISIC4 using "$path/output/ISIC31_ISIC4.dta", gen(mr_ISIC4)
merge m:m ISIC31 using "$path/output/ISIC3_ISIC31.dta", gen(mr_ISIC31)
merge m:m ISIC3 using "$path/output/ISIC3_CPC1.dta", gen(mr_ISIC3)
merge m:m CPC1 using "$path/output/CPC1_COICOP.dta", gen(mr_CPC1)
merge m:m CPC1 using "$path/output/CPC1_CPC11.dta", gen(mr_CPC1_v2)
merge m:m CPC11 using "$path/output/CPC11_CPC2.dta", gen(mr_CPC11)
merge m:m CPC2 using "$path/output/CPC2_CPC21.dta", gen(mr_CPC2)
merge m:m CPC21 using "$path/output/CPC21_CPA21.dta", gen(mr_CPC21)
merge m:m CPA21 using "$path/output/CPA21_CN23.dta", gen(mr_CPA21)

save "$path/output/All_Correspondance_Table.dta"







*** CPC - 5 digits
*** CPC1.1_CPC1.0
import excel using "$path/Correspondance Tables.xlsx", sheet("CPC1.1_CPC1.0") firstrow clear

ren (CPCv11code CPCV10code) (CPC11 CPC1)
keep CPC11 CPC1

gunique CPC11
gunique CPC1

* Variable
local i CPC11
tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 4
drop len

* CPC1
local i CPC1
*tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 4
drop if len==3
drop len

* Duplicates
local var CPC11 // Variable que quiero dejar única
gen uno = 1
egen count = count(uno), by (`var')
bysort `var': gen group = _n
egen tag = tag(CPC11)

* Check if is it worth to reshape / take divided categories
tab group
tab count if tag==1

*reshape wide CPC2, i(CPC11) j(group, string)

keep if group == 1
keep CPC11 CPC1

*tempfile CPC11_CPC1
*save `CPC11_CPC1'
save "$path/output/CPC11_CPC1.dta"

*** CPC2.0_CPC1.1
import excel using "$path/Correspondance Tables.xlsx", sheet("CPC2.0_CPC1.1") firstrow clear

ren (CPC2Code CPC11Code) (CPC2 CPC11)
keep CPC2 CPC11

gunique CPC2
gunique CPC11

* Variable
local i CPC2
tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 4
drop len

* CPC1
local i CPC11
*tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 4
drop if len==3
drop len

* Duplicates
local var CPC11 // Variable que quiero dejar única
gen uno = 1
egen count = count(uno), by (`var')
bysort `var': gen group = _n
tostring group, replace
replace group = "_" + group
egen tag = tag(`var')

* Check if is it worth to reshape / take divided categories
tab group
tab count if tag==1
drop uno tag

keep if inlist(group, "_1", "_2", "_3")

reshape wide CPC2, i(CPC11) j(group, string)

*keep CPC2 count CPC11 //CPC11_2
ren count countCPC2

*tempfile CPC2_CPC11
*save `CPC2_CPC11' // Unique by CPC2
save "$path/output/CPC2_CPC11.dta", replace


*** CPC2.1_CPC2.0
import excel using "$path/Correspondance Tables.xlsx", sheet("CPC2.1_CPC2.0") firstrow clear

ren (CPC21code CPC2code) (CPC21 CPC2)
keep CPC21 CPC2

gunique CPC21
gunique CPC2

* Variable
local i CPC21
tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 4
drop len

* CPC1
local i CPC2
tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 5
*drop if len==3
drop len

* Duplicates
local var CPC2 // Variable que quiero dejar única
gen uno = 1
egen count = count(uno), by (`var')
bysort `var': gen group = _n
tostring group, replace
replace group = "_" + group
egen tag = tag(`var')

* Check if is it worth to reshape / take divided categories
tab group
tab count if tag==1
drop uno tag

keep if inlist(group, "_1", "_2", "_3")

reshape wide CPC21, i(CPC2) j(group, string)

ren count countCPC21

*keep CPC21 CPC2

*tempfile CPC21_CPC2
*save `CPC21_CPC2' // Unique by CPC2 & CPC21
save "$path/output/CPC21_CPC2.dta", replace


* CPA2.1-CPC2.1
import excel using "$path/Correspondance Tables.xlsx", sheet("CPA2.1-CPC2.1") firstrow clear

gunique CPA21 CPC21

tab CountofCPA21 
tab CountofCPC21

drop H I Comment C F

* CPA
tostring CPA21, replace
gen len1 = length(CPA21)
replace CPA21 = "0" + CPA21 if len == 5

* CPC
gen len2 = length(CPC21)
drop if len2<5

drop len*

* Manage duplicates
tab CountofCPA21
tab CountofCPC21

drop Count*

gen uno = 1
egen count = count(uno), by (CPA21)
bysort CPA21: gen group = _n
tostring group, replace
replace group = "_" + group
egen tag = tag(CPA21)

* Check if is it worth to reshape / take divided categories
tab group
tab count if tag==1

drop tag uno

keep if inlist(group, "_1", "_2", "_3")

reshape wide CPC21, i(CPA21) j(group, string)

*order CPA21 count CPC211 CPC212 CPC213 CPC214 CPC215 CPC216 CPC217 CPC218 CPC219, first

ren count countCPC21

*tempfile CPA21_CPC21
*save `CPA21_CPC21'  // Unique by CPC21
save "$path/output/CPA21_CPC21.dta", replace


* CN23 - CPA 2.1
import excel using "$path/Correspondance Tables.xlsx", sheet("CN23-CPA2.1") firstrow clear

tab LINK_TYPE
drop if LINK_TYPE == "9"

gen CPA21 = subinstr(CPA_Ver2_1_CODE, ".", "", .)
gen CN23 = subinstr(CN_2023_CODE, " ", "", .)

gen len1 = length(CPA21)
gen len2 = length(CN23)

tabm len*

drop LINK_TYPE CPA_Ver2_1_CODE CN_2023_CODE len1 len2

* Duplicates
local var CPA21 // Variable que quiero dejar única
gen uno = 1
egen count = count(uno), by (`var')
bysort `var': gen group = _n
egen tag = tag(`var')

* Check if is it worth to reshape / take divided categories
tab group
tab count if tag==1

drop uno tag count group 

*tempfile CN23_CPA21
*save `CN23_CPA21'
save "$path/output/CN23_CPA21.dta"


* CPC1.0 - COICOP
import excel using "$path/Correspondance Tables.xlsx", sheet("CPC1.0_COICOP") firstrow clear

ren (COICOP CPC10) (COICOP CPC1)
keep COICOP CPC1

gunique COICOP
gunique CPC1

* Variable
local i COICOP
tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 3
drop len

/* CPC1
local i CPC1
cap tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 5
*drop if len==3
drop len
*/
* Duplicates
local var CPC1 // Variable que quiero dejar única
gen uno = 1
egen count = count(uno), by (`var')
bysort `var': gen group = _n
egen tag = tag(`var')
tostring group, replace
replace group = "_" + group

* Check if is it worth to reshape / take divided categories
tab group
tab count if tag==1

drop tag uno

keep if inlist(group, "_1", "_2", "_3")

reshape wide COICOP, i(CPC1) j(group, string)

*keep CPC21 CPC2 count
ren count countCOICOP

*tempfile CPC1_COICOP
*save `CPC1_COICOP' // Unique by CPC2 & CPC21
save "$path/output/CPC1_COICOP.dta"


*** CPC1.0 - ISICv3
import excel using "$path/Correspondance Tables.xlsx", sheet("CPC1.0-ISICv3") firstrow clear

ren (CPCV10 ISICRev3) (CPC1 ISICv3)
keep CPC1 ISICv3

gunique CPC1
gunique ISICv3

* CPC
local i CPC1
tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 4
drop len

* ISIC
local i ISICv3
cap tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 3
*drop if len==3
drop len

* Duplicates
local var CPC1 // Variable que quiero dejar única
gen uno = 1
egen count = count(uno), by (`var')
bysort `var': gen group = _n
egen tag = tag(`var')
tostring group, replace
replace group = "_" + group

* Check if is it worth to reshape / take divided categories
tab group
tab count if tag==1

drop tag uno

keep if inlist(group, "_1", "_2", "_3")

reshape wide ISICv3, i(CPC1) j(group, string)

*keep CPC21 CPC2 count
ren count countISIC

*tempfile CPC1_ISICv3
*save `CPC1_ISICv3' 
save "$path/output/CPC1_ISICv3.dta"




* COICOP and ISIC
use "$path/output/CPC1_COICOP.dta", clear
merge 1:1 CPC1 using "$path/output/CPC1_ISICv3.dta", gen(mr_CPC1_ISICv3)

reshape long COICOP_, i(CPC1) j(group)
keep if COICOP_ != ""
drop group
ren COICOP_ COICOP

save "$path/output/COICOP_ISICv3.dta", replace











