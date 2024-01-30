
qui{
noi dis "{hi: {c TLC}{dup 57:{c -}}{c TRC}}"
noi dis "{hi: {c |} If you are reading this, the pre-simulation is running! {c |}}"
noi dis "{hi: {c |} This should be done just once.                          {c |}}"
noi dis "{hi: {c BLC}{dup 57:{c -}}{c BRC}}"
}


*02 Taxes

include "$thedo_pre/02_Income_tax_input.do"

*05 Indirect taxes

include "$thedo_pre/05_elasticities.do"

include "$thedo_pre/05a_spend_dta_purchases.do"

include "$thedo_pre/05d_water.do"

*06 Excises

include "$thedo_pre/06_excises_dataset.do"


*08 Indirect taxes

include "$thedo_pre/08_ag_subsidies.do"

include "$thedo_pre/08_subsidies_elect.do"


*I do not know why, but these pre_sim files were not included in the original version from Daniel:
include "$thedo_pre/05_private_hospital.do"

*if "$xls_sn" == "$path/03. Tool/SN_Sim_tool_VI_grossup.xlsx" {
	*We want to set the random seeds only when doing the gross up, so they don't have the opportunity to change when running the main tool
	include "$thedo_pre/07_dir_trans_PMT.do"
	include "$thedo_pre/08_fuel_subsidies.do"
	include "$thedo_pre/05. Consumption_NetDown.do"
*}


