
/*==============================================================================*\
 West Africa Mini Simulation Tool for indirect taxes (VAT)
 Authors: Madi Mangan, Gabriel Lombo, Daniel Valderrama
 Start Date: January 2024
 Update Date: March 2024
 
\*==============================================================================*/
clear 

set obs 1
  
gen n = length("${multiple_scenarios}") - length(subinstr("${multiple_scenarios}", " ", "", .)) + 1
qui sum n
local n "`r(mean)'"
drop n  
di `n'
  
forvalues i=1/`n' { 
   
   local scenario_read : word `i' of ${multiple_scenarios}
   
   di "`scenario_read'"


	*==================================================================================
	dis "==============            Subvention Electricité  					==========="
	*==================================================================================

	import excel "$xls_sn", sheet(M_Subvention_electricite_raw) first clear
		
	keep Sim2 Autresname Autresvalue
	keep if Sim2 == "`scenario_read'"
		
	levelsof Autresname, local(params)
	foreach z of local params {
	levelsof Autresvalue  if Autresname=="`z'", local(val)
		global `z' `val'
	}
		
	import excel "$xls_sn", sheet(M_Subvention_electricite_raw) first clear
		
	keep Sim Type Threshold Tariff Max Subvention
	keep if Sim == "`scenario_read'"
		
	drop if Tariff=="."
		
	*gen namevar = Threshold+"_"+Type
	tempfile electricite_raw_dta
	save `electricite_raw_dta', replace 

	levelsof Type, local(types)
	global typesElec "`types'"
	foreach t of local types {
		levelsof Threshold if Type=="`t'", local(tholds)
		global tholdsElec`t' "`tholds'"
		foreach z of local tholds {
			levelsof Max  if Threshold=="`z'" & Type=="`t'", local(Max`z')
			global Max`z'_`t' `Max`z''
			levelsof Subvention  if Threshold=="`z'" & Type=="`t'", local(Subvention`z') 
			global Subvention`z'_`t' `Subvention`z''
			levelsof Tariff  if Threshold=="`z'" & Type=="`t'", local(Tariff`z') 
			global Tariff`z'_`t' `Tariff`z''
		}
	}
		
noi di "$scenario_name_save"
	
global save_scenario 1	
	
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
 
   

* Policies
	qui: include "$thedo/06. Subsidies.do"

	qui: include "$thedo/07. Excise_taxes.do"

	qui: include "$thedo/08. Indirect_taxes_newest.do"

	qui: include "$thedo/09. DirTransfers.do"

	qui: include "$thedo/10. Income_Aggregate_cons_based.do"

	qui: include "$thedo/11. Output_scenarios.do"

}



if "`sce_debug'"=="yes" dis as error  "You have not turned off the debugging phase in ind tax dofile !!!"

*===============================================================================
// Launch Excel
*===============================================================================

shell ! "$xls_out"

noi scalar t2 = c(current_time)
noi display "Running the complete tool took " (clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds"

End



	
	
	
	
	
	