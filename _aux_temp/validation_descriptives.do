


use "C:\Users\danielsam\Box\World_Bank\Senegal_tool\01. Data\income_tax_collapse__pol_pros.dta" , clear 
ren income_tax income_tax_pol
ren income_tax_reduc income_tax_reduc_pol
merge 1:1 hhid using "C:\Users\danielsam\Box\World_Bank\Senegal_tool\01. Data\income_tax_collapse_.dta"
br
compare income_tax_reduc_pol income_tax_reduc
*gen iweights= hhsize* hhweight

collapse (sum) income_tax_pol income_tax_reduc_pol income_tax income_tax_reduc [iw= hhweight]
format income* %25.5f



***Taxes
use "C:\Users\danielsam\Box\World_Bank\Senegal_tool\01. Data\Final_TVA_Tax__pol_pros.dta" , clear 

merge 1:1 hhid using "C:\Users\danielsam\Box\World_Bank\Senegal_tool\01. Data\income_tax_collapse_.dta", keepusing(hhweight)


collapse (sum) Tax_TVA depan [iw= hhweight]
format Tax_TVA  depan %25.5f
 
 
 
 *** Hospitalization 
 
 use "C:\Users\danielsam\Box\World_Bank\Senegal_tool\01. Data\s03_me_SEN2018.dta" , clear 
 
 duplicates report hhid s01q00a
 
 gen 		private=1 if s03q23>=7 & s03q23!=.
 replace 	private=0 if s03q23<7
 
 
 gen depan= s03q24
 drop if depan==0
 collapse (sum) depan , by (hhid private)
 
 bysort hhid: egen total_hosp=total(depan)
 gen sh_depan_hosp=depan/total_hosp
 
 keep if private==1
 
 collapse (mean) sh_depan_hosp total_hosp  , by (hhid) // (sd) sd= sh_depan_hosp
 
 gen codpr=691
 save "C:\Users\danielsam\Box\World_Bank\Senegal_tool\01. Data\hospit", replace 