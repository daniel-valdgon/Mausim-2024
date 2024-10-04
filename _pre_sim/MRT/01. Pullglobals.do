
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms
* Author: Julieth Pico 
				
 * Date: August 2019
* Version: 2.0 Daniel Valderrama 
	*- Reduce the reading of direct taxes from 40 sect to 2 secs by loading only one sheet
	*- Added a cap in the amount of childs from which a househodl can receive tax credits
	
*--------------------------------------------------------------------------------

	*==================================================================================
	dis "=================  Indirect Taxes 	==============="
	*==================================================================================


		if ("$country" == "MRT") {
			global sect_fixed "8 9" // 8 9
			*global sect_elec "8"
		}
	
		import excel "$xls_sn", sheet("IO_percentage") firstrow clear
		save "$presim/IO_percentage.dta", replace
	
	
		import excel "$xls_sn", sheet("TVA_ref_raw") firstrow clear
		drop produit
		drop if codpr==.
		*recode elasticities (.=0)
		tempfile VAT_original
		save `VAT_original'
		levelsof codpr, local(products)
		global products "`products'"
		foreach z of local products {
			*dis `z'
			levelsof TVA          if codpr==`z', local(vatrate)
			global vatrate_`z' `vatrate'
			levelsof formelle     if codpr==`z', local(vatform)
			global vatform_`z' `vatform'
			levelsof exempted     if codpr==`z', local(vatexem)
			global vatexem_`z' `vatexem'
			*levelsof elasticities if codpr==`z', local(vatelas)
			*global vatelas_`z' `vatelas'
		}
	

	*==================================================================================
	dis "==============              Excises Taxes         					==========="
	*==================================================================================
	
		import excel "$xls_sn", sheet(Excises_ref_raw) first clear
		
		keep Produit cat Taux codpr_read
		
		*replace Produit=lower(Produit)
		levelsof cat, local (products)
		foreach p of local products {
								
			levelsof Taux if cat=="`p'", local(tholds_`p')
			global taux_`p' `tholds_`p''
			
			levelsof codpr_read if cat=="`p'", local(tholds_`p')
			global codpr_read_`p' `tholds_`p''
			
			*levelsof Produit if cat=="`p'", local(tholds_`p')
			*global prod_label_`p' `tholds_`p''		
		}	
		
		split cat, p("_")
		destring cat2, replace force
		sum cat2 if cat1 == "ex"
		global n_excises_taux "`r(max)'"
	
