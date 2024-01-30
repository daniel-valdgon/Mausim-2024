


*===============================================================================
*					Parametric estimates of informality share 
*===============================================================================

if "$model"=="parametric" {

/*---- Load and save coefficients --------------*/
// Note: this do-file loads coefficients from model 4, The PE is free to choose from different models 

	use  "$data/01.Data/01.pre-simulation/aux_cons_informality/coef_allcountries.dta", clear  //path of datasets  shared in one drive 
	
		keep country_code year n results4 legend_b4
		keep if n>=1 & n<= 8 // the model 4 has 8 coefficients. This line changes with the model selected 
		
		//The matching with similar countries could be based on GDP per-capita, VAT C-Efficiency ratio or other variables
		keep if ${countries_group}
		
		//This save the means of each of the coefficients. Also changes with the model selected 
		sum results4 if legend_b4 == "log_income_pp"	
		scalar coef_log_income = `r(mean)' 	
		sum results4 if legend_b4 == "_cons"	
		scalar cons = `r(mean)' 
		sum results4 if legend_b4 == "hh_size"	
		scalar coef_hhsize = `r(mean)' 
		sum results4 if legend_b4 == "2.head_sex" | legend_b4 =="1.head_sex"	
		scalar coef_male = `r(mean)' 	
		sum results4 if legend_b4 == "head_age"	
		scalar coef_age = `r(mean)' 	
		sum results4 if legend_b4 == "1.COICOP_1dig"	
		scalar coef_food = `r(mean)' 	

/*---- Load consumption data --------------*/
	
	use "${data}/01.Data/Example_FiscalSim_exp_data_raw_no_informality.dta", clear  // see do-file 0_rundo for details 
	merge m:1 hh_id using `dta_covariates', nogen keepusing(hh_size  hh_male hh_head_age exp_value_pc ) assert(matched) 
	
		// Convert income in the same way it was done in the regressions (To improve over this we would need coefficients to be re-estimated). See 0_rundo for details on how conversion rates were obtained
		gen log_income_pp = log($income_measure/$conversion_rate) 
		gen food = exp_type<=40
		label var food "=1 food consumption"
		
		// Check all variables are properly defined 
		sum log_income_pp hh_size  hh_male hh_head_age food 		
		
		// Predict informality share (We do not add noise in this step yet)
		gen pred_inf_share = log_income_pp * coef_log_income + hh_size * coef_hhsize +  hh_male* coef_male  +  hh_head_age * coef_age + food*coef_food + cons
		
		// Winsorize: Replace extreme values with P-1 and P-99 of the unconditional distribution (assumes p1 and p99 are in the 0-100 range will be revised later). One could initially make this imputation stricter 
			sum pred_inf_share, detail
			replace pred_inf_share=r(p1) if pred_inf_share<=0 & pred_inf_share!=.
			replace pred_inf_share=r(p99) if pred_inf_share>=100 & pred_inf_share!=.
			
			assert pred_inf_share>0 & pred_inf_share<100 // Check new distribution
			
		
		label var pred_inf_share "Informal share at the product-household level" 
		label var log_income_pp  "log of welfare aggregate deflate to PPP of survey year" 
	
	/* SAVE OUTPUT DATASET */
	tempfile parametric 
	save `parametric', replace 
}
else if "$model"=="nonparametric" {
	
	/* -------------- Clean consumption data ------------------*/
	use "$data/01.Data/01.pre-simulation/aux_cons_informality/informality Bachas.dta", clear 
			
		ren country_code country 
		keep if product_level==${p_product_level} // this keeps the data at two digit level. It is just for the purposes of the example 
		keep if ${countries_group}
		
		gen pred_inf_share= 100*share_informal_consumption // to guarantee that informality has the same format as the parametric method 
		
		collapse (mean) pred_inf_share, by(decile_expenditure product_code product_name)
		
	tempfile data_inf_pred
	save `data_inf_pred', replace 
	
	//Load crosswalk from HS-Codes to COICOP 
	preserve 
		import excel using "${data}/01.Data/01.pre-simulation/aux_cons_informality/Xwalk_hhs_coicop1d.xlsx", sheet(Xwalk) clear first
		label var product_code "COICOP classification from Bachas et al (2021) dataset"
		keep product_code code_hhs
		ren code_hhs exp_type
		label var exp_type "product codes in hhs"
		
		tempfile Xwalk
		save `Xwalk', replace
	restore
	
	/* -------------- Add informality predictions to household survey  ------------------*/
	
	// Load household-item data 
	use "${data}/01.Data/Example_FiscalSim_exp_data_raw_no_informality.dta", clear  
	
		// Adding deciles of consumption 
		merge m:1 hh_id using `dta_covariates', keepusing (decile_expenditure weight) nogen 
		
		//adding coicop codes 
		merge m:1 exp_type using `Xwalk', keepusing (product_code) nogen 
		
		//Adding non-parametric estimates of informality 
		merge m:1 decile_expenditure product_code using `data_inf_pred', nogen keepusing(pred_inf_share)
	
}

*===============================================================================
*					Reshaping the data 
*===============================================================================

// Define the adjusted informality share, Consumption data from Bachas includes non-market purchases as informal consumption
	merge 1:1 hh_id exp_type using "${data}/01.Data/Example_FiscalSim_exp_data_raw_no_informality.dta", keepusing(share_non_mkt) nogen
		
	// Test 
	preserve 
		// net install ftools, from("https://github.com/sergiocorreia/ftools/raw/master/src/")
		// ssc install reghdfe
		reg pred_inf_share decile_expenditure i.exp_type
		local b=e(b)[1,1]
		assert `b'<0 // we want informality share to be inversely correlated with deciles of expenditure
		dis `b'
	restore 	
	
	gen inf_share_corr=pred_inf_share-share_non_mkt
	replace inf_share_corr=0 if inf_share_corr<0 //censoring cases where it does not match
	
// Transform dataset to split each dollar spend into formal and informal spending : exp_value here refers to total consumption that is the reason it needs to be corrected 

	gen informal_spending=(inf_share_corr/100)*exp_value 
	gen formal_spending=(1-(pred_inf_share/100))*exp_value
	keep hh_id exp_type  informal_spending formal_spending


preserve
	drop informal_spending 
	gen place_purchase=1
	ren formal_spending exp_value
	
	tempfile aux_place_purchase
	save `aux_place_purchase', replace 
restore 

	drop formal_spending 
	gen place_purchase=2
	ren informal_spending exp_value
	
	append using `aux_place_purchase'
	
	label define place 1 "formal place of purchase: store, supermarket" 2 "informal place of purchase: farmer's market, private sales'"
	label value place_purchase place

// validation check 
ren exp_value exp_value_place_purchase
merge m:1 	hh_id exp_type using "${data}/01.Data/Example_FiscalSim_exp_data_raw_no_informality.dta", nogen keepusing(exp_value)

bysort hh_id exp_type: egen exp_value_test=total(exp_value_place_purchase)
gen r=exp_value_test/exp_value
replace r=1 if exp_value==0
assert r>0.99 & r<1.01

save "${data}/01.Data/Example_FiscalSim_exp_data_raw_informality_imputed.dta", replace 