clear all
macro drop _all

* Gabriel
if "`c(username)'"=="gabriellombomoreno" {
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool"
	global path_out		"/Users/gabriellombomoreno/Documents/WorldBank/VAT_tool/QER"
	global thedo     	"${path}/02_scripts"

	global xls_out    	"${path}/03_Tool/Test.xlsx"
	global xls_sn    	"${path}/03_Tool/SN_Sim_tool_VI_`c(username)'.xlsx" 
	
	global numscenarios	6
	global coutryscen	"MRT MRT MRT SEN SEN SEN"	// Fill with the country of each simulation
	global proj_1		"RC_MRT_Ref" 
	global proj_2		"RC_MRT_NoExem"  
	global proj_3		"RC_MRT_NoExemVAT16" 
	global proj_4		"RC_SEN_Ref" 
	global proj_5		"RC_SEN_NoExem"  
	global proj_6		"RC_SEN_NoExemVAT18" 

}

	global data_sn       "${path}/01_data/1_raw/${country}"
	*global presim       "${path}/01_data/2_pre_sim/${country}"
	global data_out    	"${path}/01_data/4_sim_output"
	global theado       "$thedo/ado"
	
	
	/*-------------------------------------------------------/
		1. Subsidies spending on electricity
	/-------------------------------------------------------*/

	global presim       "${path}/01_data/2_pre_sim/MRT"

	* Purchases 
	use "$presim/05_purchases_hhid_codpr.dta", clear
	*use "$data_sn/pivot2019.dta", clear
	
	merge m:1 hhid using "$presim/01_menages.dta", keepusing(hhweight) keep(3) nogen

	gen codpr_elec = codpr == 376 // Electricity product

	gen consum_elec = depan if codpr_elec==1

	collapse (sum) consum_elec depan, by(hhid hhweight)

	gen share = consum_elec/depan
	
	sum share

	
	merge 1:1 hhid using "$presim/08_subsidies_elect.dta", keepusing(type_client consumption_electricite prepaid_woyofal codpr_elec hh_elec)
	
	tabstat share [aw = hhweight], s(mean count) by(type_client)

		
	
	/*-------------------------------------------------------/
		2. VAT - Relative Incidence and spending for MRT and SEN
	/-------------------------------------------------------*/
	* Incidence
	global policy		"Tax_TVA TVA_direct TVA_indirect"
	
forvalues scenario = 1/$numscenarios {

	*-----  Absolute Incidence
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="benefits" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_yd" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	keep decile *_yd

	foreach var in $policy2 {
		egen ab_`var' = sum(`var')
		gen in_`var' = `var'*100/ab_`var'
	}

	keep decile in_*

	tempfile abs
	save `abs', replace

	*-----  Relative Incidence
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="netcash" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_yd" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	replace value = value * (-100) if value < 0
	replace value = value * (100) if value >= 0
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	keep decile *_yd

	order decile $policy2

	merge 1:1 decile using `abs', nogen
	
	gen scenario = `scenario'
	order scenario, first
	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace

}

clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}

export excel "$xls_out", sheet(Tab) first(variable) sheetreplace 
	

	* Split disposable income into formal purchases, informal purchases and gifts 
	* Mauritania
	
	global presim       "${path}/01_data/2_pre_sim/MRT"
	global data_sn       "${path}/01_data/1_raw/MRT"

	use "$data_sn/pivot2019.dta", clear
	ren hid hhid
	merge m:1 hhid using "$presim/01_menages.dta", keepusing(hhweight) keep(3) nogen
	
	tab source [iw = dep*hhweight], m

	
	* Run output disposable Income and compare to formal and informal purchases
	use "${data_out}/output_${proj_1}.dta", clear
	
	keep hhid hhweight yd_pc depan
	gunique hhid 
	
	merge 1:m hhid using "${presim}/05_netteddown_expenses_SY.dta", keep(3)
	
	collapse (firstnm) yd_pc depan (mean) achat*,  by(hhid hhweight informal_purchase)
	
	tabstat yd_pc depan achat* [aw = hhweight], s(mean) by(informal_purchase)

	
	* Senegal
	global presim       "${path}/01_data/2_pre_sim/SEN/original"
	
	use "$presim/Senegal_consumption_all_by_product.dta", clear
	merge n:1  grappe menage using "$presim/ehcvm_conso_SEN2018_menage.dta" , nogen keepusing (hhid hhweight)

	*drop if inlist(modep,2,3,4,5)

	tab modep [iw = depan*hhweight], m

	global presim       "${path}/01_data/2_pre_sim/SEN"

	use "${presim}/05_netteddown_expenses_SY.dta", clear
	
	merge m:1 hhid using "$presim/01_menages.dta", keepusing(hhweight) keep(3) nogen

	collapse (mean) achat*,  by(hhid hhweight informal_purchase)
	
	tabstat achat* [aw = hhweight], s(mean) by(informal_purchase)

	
	

	
	
	*----- Purchases Data
	* Mauritania
	global presim       "${path}/01_data/2_pre_sim/MRT"
	global data_sn       "${path}/01_data/1_raw/MRT"

	use "$data_sn/s_pivot2019.dta" , clear

	drop hhweight hhsize

	* Merge data 
	merge m:1 hhid using "$presim/01_menages.dta", nogen keepusing(decile_expenditure hhweight hhsize) keep(3)
	merge m:1 decile_expenditure coicop using "$presim/bachas.dta", nogen keepusing(informal_purchase) keep(1 3) 
	merge m:1 hhid using "${data_out}/output_${proj_1}.dta", keepusing(yd_deciles_pc) keep(3) nogen

	gen formal_purchase = 1-informal_purchase
		
	collapse (sum) depan, by(hhid hhweight codpr informal_purchase formal_purchase yd_deciles_pc)
	
	collapse (mean) formal_purchase informal_purchase [iw = hhweight],  by(yd_deciles_pc)

	* Senegal
	global presim       "${path}/01_data/2_pre_sim/SEN/original"
	
	use "$presim/Senegal_consumption_all_by_product.dta", clear
merge m:1  grappe menage using "$presim/ehcvm_conso_SEN2018_menage.dta" , nogen keepusing (hhid hhweight)
		
	collapse (sum) depan, by(hhid hhweight codpr)

	merge m:1 codpr using "$presim/correlation_COICOP_senegal.dta" ,  keepusing(coicop) keep(matched) nogen

	merge n:1 hhid using "$presim/ehcvm_conso_SEN2018_menage.dta" ,  keepusing(ndtet) nogen

	rename  (ndtet coicop) (decile_expenditure product_code)

	merge n:1 decile_expenditure product_code using "$presim/informality_final_senegal.dta", assert(matched using) keep(master matched) keepusing(pc_non_market_purchase pc_market_purchase product_name consumption_informal consumption_all share_informal_consumption informality_purchases) nogen

	merge m:1 hhid using "${data_out}/output_${proj_4}.dta", keepusing(yd_deciles_pc) keep(3) nogen
	
	
	tab codpr if informality_purchases ==.
	*All these seem to be formal
	bys codpr: egen mean_inf = mean(informality_purchases)	
	replace informality_purchases=mean_inf if informality_purchases==.
	drop mean_inf

	gen formal_purchase = 1-informality_purchases

	
	collapse (mean) formal_purchase informality_purchases [iw = hhweight],  by(yd_deciles_pc)

	
	
	
	
	
	
	
	
	
	
	
	
	