/*==============================================================================
	Project:		CEQ Mauritania
	To do:			Read Parameters
	Author:			Gabriel Lombo
	Creation Date:	Aug 27, 2024
	Modified:		
	
	Note: 				
===============================================================================*/


/*-------------------------------------------------------/
	0. Settings
/-------------------------------------------------------*/

	*------ Settings
	import excel "$xls_sn", sheet(AuxParams_raw) first clear

	levelsof globalname, local(params)
	foreach z of local params {
		levelsof globalvalue if globalname=="`z'", local(val)
		global `z' `val'
	}
		
	destring globalvalue, force replace
	mkmat globalvalue,  mat(settings)


	noi di "$scenario_name_save"

	global c:all globals
	macro list c	
	
/*-------------------------------------------------------/
	0. Policy Names
/-------------------------------------------------------*/

	*------ Policy
	import excel "$xls_sn", sheet("Policy") firstrow clear

	keep if varname != "."

	* Policy names
	levelsof varname, local(params)
	foreach z of local params {
		levelsof varlabel if varname=="`z'", local(val)
		global `z'_lab `val'
	}
	
	* Policy categories
	gen order = _n
	bysort category (order): gen count = _n
	
	keep category varname count
	ren varname v_	
	
	reshape wide v_, i(category) j(count)		
		
	egen v = concat(v_*), punct(" ")	
	gen globalvalue = strltrim(v)
		
	levelsof category, local(params)
	foreach z of local params {
		levelsof globalvalue if category=="`z'", local(val)
		global `z'_A `val'
	}
	
	drop v_1 v globalvalue
	
	egen v = concat(v_*), punct(" ")	
	gen globalvalue = strltrim(v)
		
	levelsof category, local(params)
	foreach z of local params {
		levelsof globalvalue if category=="`z'", local(val)
		global `z' `val'
	}

	
/*-------------------------------------------------------/
	2. Direct Taxes
/-------------------------------------------------------*/
	
	import excel "$xls_sn", sheet(DirTax_raw) first clear
	

	drop if rate=="."
	destring rate min max plus, replace
	
	global n_DirTax 3
	
	gen pol_name = name + "_" + regime
	
	levelsof pol_name, local(types)
	
	global names_DirTax ""

	replace min = 0 if min == .
	replace plus = 0 if plus == .
	replace max = 10000000000 if max == .

	foreach t of local types {
		global names_DirTax "$names_DirTax `t'"
		levelsof threshold if pol_name=="`t'", local(tholds)
		global tholds`t' "`tholds'"
		
		foreach z of local tholds {
			levelsof max if threshold=="`z'" & pol_name=="`t'", local(Max`z')
			global max`z'_`t' `Max`z''

			levelsof min if threshold=="`z'" & pol_name=="`t'", local(Min`z')
			global min`z'_`t' `Min`z''
			
			levelsof rate if threshold=="`z'" & pol_name=="`t'", local(Rate`z')
			global rate`z'_`t' `Rate`z''
			
			levelsof plus if threshold=="`z'" & pol_name=="`t'", local(Plus`z')
			global plus`z'_`t' `Plus`z''
		}
	}	
	
/*-------------------------------------------------------/
	3. Direct Transfers
/-------------------------------------------------------*/

	import excel "$xls_sn", sheet(Aux_direct_transfers_raw) first clear
		
	split cat, p("_")
	*destring cat2, replace
		
	levelsof cat2, local (programs)
	foreach p of local programs {						
				
		levelsof prog_label if cat2=="`p'", local(tholds_`p')
		global pr_label_`p' `tholds_`p''	
		
		levelsof division if cat2=="`p'", local(tholds_`p')
		global pr_div_`p' `tholds_`p''
			
		levelsof type if cat2=="`p'", local(tholds_`p')
		global pr_type_`p' `tholds_`p''
	}
		
	destring cat2, replace
	sum cat2  
	global n_progs "`r(max)'"
		
	forvalues i = 1/ $n_progs {
		
		if "${pr_div_`i'}" == "departement"  | "${pr_div_`i'}" == "region"  {
			*local i = 1
			import excel "$xls_sn", sheet(prog_`i'_raw) first clear
			drop if location ==.		
			
			destring beneficiaires, replace	
			destring montant, replace		

			ren location ${pr_div_`i'}
			
			keep ${pr_div_`i'} beneficiaires montant
			
			*save `department'
			save "$tempsim/${pr_div_`i'}_`i'.dta", replace 
		}
	}	
					
	
/*-------------------------------------------------------/
	4. Indirect Taxes
/-------------------------------------------------------*/
	
	*---------- Auxiliar - Sector - Product
	import excel "$xls_sn", sheet("IO_percentage") firstrow clear
	save "$presim/IO_percentage.dta", replace
		
	
	*---------- VAT
	if $TVA_simplified == 0 {
		
		import excel "$xls_sn", sheet("TVA_raw") firstrow clear
		drop produit
		drop if codpr==.
		recode elasticities (.=0)
		
		levelsof codpr, local(products)
		foreach z of local products {
			*dis `z'
			levelsof TVA          if codpr==`z', local(vatrate)
			global vatrate_`z' `vatrate'
			levelsof formelle     if codpr==`z', local(vatform)
			global vatform_`z' `vatform'
			levelsof exempted     if codpr==`z', local(vatexem)
			global vatexem_`z' `vatexem'
			levelsof elasticities if codpr==`z', local(vatelas)
			global vatelas_`z' `vatelas'
		}
	}

	*---------- Custom Duties

	import excel "$xls_sn", sheet("CustomDuties_raw") firstrow clear
	drop produit
	drop if codpr==.
	recode elasticities (.=0)
	*tempfile VAT_original
	*save `VAT_original'
	
	levelsof codpr, local(products)
	global products "`products'"
	foreach z of local products {
		
		levelsof rate          if codpr==`z', local(rate)
		global cdrate_`z' `rate'
		
		*levelsof formelle     if codpr==`z', local(vatform)
		*global vatform_`z' `vatform'
		
		levelsof imported     if codpr==`z', local(imported)
		global cdimp_`z' `imported'
		*levelsof elasticities if codpr==`z', local(vatelas)
		*global vatelas_`z' `vatelas'
	}

	
	*----------- Excises
		
	import excel "$xls_sn", sheet(Excises_raw) first clear
		
	keep Produit cat Taux codpr_read elas ref
		
	*replace Produit=lower(Produit)
	levelsof cat, local (products)
	foreach p of local products {
							
		levelsof Taux if cat=="`p'", local(tholds_`p')
		global taux_`p' `tholds_`p''
			
		levelsof codpr_read if cat=="`p'", local(tholds_`p')
		global codpr_read_`p' `tholds_`p''
		
		levelsof elas if cat=="`p'", local(tholds_`p')
		global elas_`p' `tholds_`p''
		
		levelsof ref if cat=="`p'", local(tholds_`p')
		global ref_`p' `tholds_`p''		
		
		levelsof Produit if cat=="`p'", local(tholds_`p')
		global prod_label_`p' `tholds_`p''		
	}	
		
	split cat, p("_")
	destring cat2, replace force
	sum cat2 if cat1 == "ex"
	global n_excises_taux "`r(max)'"
	
	
	

	
/*-------------------------------------------------------/
	5. Subsidies
/-------------------------------------------------------*/

	*--------- Electricity

	import excel "$xls_sn", sheet(Subvention_electricite_raw) first clear
	
	drop if Tariff=="."

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
		
	*--------- Fuels
	
	*--------- Water


	
/*-------------------------------------------------------/
	9. Inkind Transfers
/-------------------------------------------------------*/

	import excel "$xls_sn", sheet(qhealth_raw) first clear
		
	levelsof location, local(category)
	foreach z of local category {
		*di `z'
		levelsof q_indexh          if location==`z', local(index)
		global ink_qh_`z' `index'
	}
	
	

	/*
	import excel "$xls_sn", sheet(qeduc_raw) first clear
		
	levelsof location, local(category)
	*global products "`products'"
	foreach z of local category {
		*di `z'
		levelsof q_indexh          if location==`z', local(index)
		global ink_qh_`z' `index'
	}
	*/
	
/*
	*==================================================================================
	dis "=================   Social Security Contributions	==============="
	*==================================================================================
																			  
	qui {

	import excel "$xls_sn", sheet(SecSocial_raw) first clear
	tempfile sante_raaw_dta
	save `sante_raaw_dta', replace 


		levelsof Regime, local(tholds)
		global tholdsAFAS "`tholds'"
		foreach z of local tholds {
			levelsof Rate if Regime=="`z'", local(AFASRate`z')
			global `z'_Rate `AFASRate`z''
			levelsof Max if Regime=="`z'", local(AFASMax`z')
			global `z'_Max `AFASMax`z''
		}

		  
	}
*/

