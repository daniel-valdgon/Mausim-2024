

use "C:\Users\wb419055\OneDrive - WBG\West Africa\The_Gambia\01_GamSim\Gamsim_2024\01_data\01_raw\VAT_informality_imputation\Tool\01.Data\01.pre-simulation\aux_cons_informality/informality Bachas.dta", clear 

keep if product_level==2

collapse (mean) c_inf_mean=share_informal_consumption (p10) c_inf_p10=share_informal_consumption (p25) c_inf_p25=share_informal_consumption (p50) c_inf_p50=share_informal_consumption (p75) c_inf_p75=share_informal_consumption (p90) c_inf_p90=share_informal_consumption, by( decile_expenditure product_level product_name)

save "C:\Users\wb419055\OneDrive - WBG\West Africa\The_Gambia\01_GamSim\Gamsim_2024\01_data\01_raw\VAT_informality_imputation\Tool\01.Data\01.pre-simulation\aux_cons_informality/informality Bachas_mean.dta", replace 