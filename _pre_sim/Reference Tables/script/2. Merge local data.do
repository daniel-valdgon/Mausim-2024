** PROYECT: CEQ Mauritania
** TO DO: Get local correspondance tables needed - CN, ISIC, COICOP, 
** BY: Gabriel Lombo
** LAST UPDATE: 1/29/2024


global path2 "C:\Users\wb621266\OneDrive - WBG\Mausim_2024\03. Tool"
global path "C:\Users\wb621266\OneDrive - WBG\Documents\GitHub\WorldBank\Reference Tables"

* Local Data
* TVA 
import excel using "$path2/SN_Sim_tool_Gabriel_raw.xlsx", sheet("TVA") firstrow clear

ren coicop COICOP
keep COICOP
gduplicates drop

* String
local i COICOP
cap tostring `i', replace
gen len = length(`i')
tab len
replace `i' = "0" + `i' if len == 3
drop len

merge 1:m COICOP using "$path/output/All_Correspondance_Table.dta", gen(mr_TVA) keep(1 3)

* CIIU
gsort COICOP
keep COICOP Section ISIC4
gduplicates drop 
gen uno = 1
egen count = count(uno), by (COICOP Section)

*Sector
drop ISIC4
gduplicates drop 

gsort COICOP Section -count
egen tag = tag(COICOP)
gduplicates tag COICOP, gen(dup)
tab count dup if tag == 1
tab dup if tag ==1

* Stay with the sector that has more CIIU associated and the first letter
keep if tag == 1 
keep COICOP Section
tab Section

save "$path/output/local_COICOP_ISIC4.dta", replace // Pasted on the excel

* Exempted - CPC21
import excel using "$path2/SN_Sim_tool_Gabriel_raw.xlsx", sheet("Exempted") firstrow clear

gen CN23 = substr(code, 1, 8)
keep CN23 cruce
egen cruce2 = max(cruce), by(CN23)
drop cruce
gduplicates drop

merge 1:m CN23 using "$path/output/All_Correspondance_Table.dta", gen(mr1) keep(1 3)

keep CN23 CPC21 COICOP cruce2 
tab COICOP cruce2 // Should be Exempted by COICOP
tab CPC21 cruce2 // Should be Exempted by CPC21







