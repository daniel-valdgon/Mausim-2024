
/*==============================================================================*\
 Multiplie simulations
 Authors: Madi Mangan, Gabriel Lombo, Daniel Valderrama
 Start Date: January 2024
 Update Date: March 2024
 
\*==============================================================================*/

*----- Set globals
cap program drop set_global
program define set_global

* Define length of loops
local var_names "prep user tranch"
forvalues i = 1/3 {
	local v : word `i' of `var_names'
	local n_`v' 0
	foreach j of global `v' {
		local n_`v' = `n_`v'' + 1
	}
	global n_`v' `n_`v''
}

* Create matrix with params
forvalues i=1/$n_prep {
	forvalue j=1/$n_user {
		mat User_`i'_`j' = J($n_tranch, 3 , .)
		 
		forvalues k=1/$n_tranch {
			mat User_`i'_`j'[`k',1] = Max_User_`i'_`j'[1,`k']
			mat User_`i'_`j'[`k',2] = Sub_User_`i'_`j'[1,`k']
			mat User_`i'_`j'[`k',3] = Tar_User_`i'_`j'[1,`k']

		}
		
		mat colnames User_`i'_`j' = Max Subvention Tariff
		mat rownames User_`i'_`j' = $tranch
	}
}

* Assign matrix values to a global 
forvalues i = 1/$n_prep {
	local t1 : word `i' of $prep
	forvalues j = 1/$n_user {
		local t2 : word `j' of $user
		local names: rownames User_`i'_`j'
		forvalues k = 1/$n_tranch {
			local z : word `k' of `names'
			global Max`z'_`t1'`t2' User_`i'_`j'[`k', 1] 
			global Subvention`z'_`t1'`t2' User_`i'_`j'[`k', 2]	
			global Tariff`z'_`t1'`t2' User_`i'_`j'[`k', 3]
		}
	}	
}

* Display parameters	
noi di "You have $n_user users with $n_tranch tranches for $n_prep types of users (prep and post)"
noi di "The following are the parameters you are running"

forvalues i = 1/$n_prep {
	local t1 : word `i' of $prep
	forvalues j = 1/$n_user {
		local t2 : word `j' of $user
		noi di "`t1'`t2'"
		matlist User_`i'_`j'
	}	
}

end
	
	
*----- Run tool
cap program drop run_tool
program define run_tool

* Save new params	
if $save_scenario ==1{
	global c:all globals

	macro list c

	clear
	gen globalname=""
	gen globalcontent=""
	local n=1
	foreach glob of global c{
		dis `"`glob' = ${`glob'}"'
		set obs `n'
		replace globalname="`glob'" in `n'
		replace globalcontent=`"${`glob'}"' in `n'
		local ++n
	}

	foreach gloname in c thedo_pre theado thedo xls_sn data_out tempsim presim data_dev data_sn path S_4 S_3 S_level S_ADO S_StataSE S_FLAVOR S_OS S_OSDTL S_MACH save_scenario load_scenario devmode asserts_ref2018{
		cap drop if globalname=="`gloname'"
	}

	export excel "$xls_out", sheet("p_${scenario_name_save}") sheetreplace first(variable)
	noi dis "{opt All the parameters of scenario ${scenario_name_save} have been saved to Excel.}"
	
	*Add saved scenario to list of saved scenarios
	import excel "$xls_out", sheet(legend) first clear cellrange(AH1)
	drop if Scenario_list==""
	expand 2 in -1
	replace Scenario_list="${scenario_name_save}" in -1
	duplicates drop
	gen ord=2
	replace ord=1 if Scenario_list=="Ref_2018"
	replace ord=3 if Scenario_list=="User_def_sce"
	sort ord, stable
	drop ord
	
	export excel "$xls_out", sheet(legend, modify) cell(AH2)
}
 

* Run policies
	qui: include "$thedo/06. Subsidies.do"

	qui: include "$thedo/07. Excise_taxes.do"

	qui: include "$thedo/08. Indirect_taxes_newest.do"

	qui: include "$thedo/09. DirTransfers.do"

	qui: include "$thedo/10. Income_Aggregate_cons_based.do"

	qui: include "$thedo/11. Output_scenarios.do"


end

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	