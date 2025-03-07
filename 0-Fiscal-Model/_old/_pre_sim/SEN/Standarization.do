
/*==============================================================================*\
 Senegal Standardization
 Authors: Gabriel
 Start Date: February 2024
 Update Date: February 2024
 
\*==============================================================================*/
   
* User - Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	global pathdata     "/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool"
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool"
	global thedo     	"${path}/02_scripts"
	global presim       "${path}/01_data/2_pre_sim/SEN"

}

* Data Standardization
*----- Household
	use "$presim/original/ehcvm_welfare_SEN2018.dta", clear

	gunique hhid
	gsort hhid
	keep hhid hhweight hhsize dtot zref pcexp
	
	* To check and agree
	gen all = 1
	tab all [iw=hhweight*hhsize]

	gen double yd_pre=round(dtot/hhsize,0.01)
	
	foreach var in dtot pcexp yd_pre {
		gen test=1 if `var'<=zref
		recode test .= 0
		noi tab test [iw=hhweight*hhsize]
		drop test
	}
	
	drop all yd_pre  
	
	*replace dtot = pcexp*hhsize
		
	save "$presim/01_menages.dta", replace
 
 
	* Senegal data with informality as a dummy
 	use "$presim/original/05_netteddown_expenses_SY.dta", clear
	
	/*
	gunique codpr hhid informal_purchase Secteur
	
	gduplicates tag codpr hhid informal_purchase, gen(dup)
	egen tag = tag(codpr hhid informal_purchase)
	
	tab dup tag
	tab dup pourcentage
	
	drop dup tag
	*/
	
	ren Secteur sector
	
	gsort hhid codpr informal_purchase sector
		
	save "$presim/05_netteddown_expenses_SY.dta", replace
	
	
*----- Purchases
	use "$presim/original/05_purchases_hhid_codpr.dta", clear

	save "$presim/05_purchases_hhid_codpr.dta", replace


*----- Poverty lines
	use "$presim/original/s02_me_SEN2018.dta", clear

	save "$presim/s_s02.dta", replace
	
	
*----- Electricity subsidies
	use "$presim/original/08_subsidies_elect_Adjusted.dta", clear

	gen codpr_elec = 1
	gen codpr = 334
	
 	keep hhid type_client consumption_electricite prepaid_woyofal codpr*

	save "$presim/08_subsidies_elect.dta", replace
	
	
*----- IO Matrix
	import excel "$presim/IO_Matrix.xlsx", sheet("IO_matrix") firstrow clear
		 
	local thefixed 		"22 32 33 34 13" 
	local sect_elec  	"22"
			
	gen fixed=0
	foreach var of local thefixed {
		replace fixed=1  if  sector==`var'
	}

	gen elec_sec=0
	foreach var of local sect_elec {
		replace elec_sec=1  if  sector==`var'
	}
		
	save "$presim/IO_Matrix.dta", replace
	
	
	
	
	
	