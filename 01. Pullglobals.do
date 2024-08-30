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


	import excel "$xls_sn", sheet(settingshide) first clear

	levelsof cat, local(params)
	foreach z of local params {
		levelsof value  if cat=="`z'", local(val)
		global `z' `val'
	}
		
	destring value , force replace
	mkmat value ,  mat(settings)
	
	noi di "$scenario_name_save"
	
	
/*-------------------------------------------------------/
	2. Direct Taxes
/-------------------------------------------------------*/
	
	import excel "$xls_sn", sheet(DirTax_raw) first clear
	
	levelsof Autresname, local(params)
	foreach z of local params {
		levelsof Autresvalue  if Autresname=="`z'", local(val)
		global `z' `val'
	}
			
	drop if rate=="."
				
	*gen namevar = Threshold+"_"+Type
	tempfile dt
	save `dt', replace 

	gen Type = name + "_" + regime
	
	levelsof concat, local(types)
	*global typesDirTax "`types'"
	
	foreach t of local types {
		levelsof threshold if Type=="`t'", local(tholds)
		global tholdsDirTax`t' "`tholds'"
		foreach z of local tholds {
			levelsof Max  if Threshold=="`z'" & Type=="`t'", local(Max`z')
			global Max`z'_`t' `Max`z''
			levelsof Subvention  if Threshold=="`z'" & Type=="`t'", local(Subvention`z') 
			global Subvention`z'_`t' `Subvention`z''
			levelsof Tariff  if Threshold=="`z'" & Type=="`t'", local(Tariff`z') 
			global Tariff`z'_`t' `Tariff`z''
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
	
	*---------- VAT
	import excel "$xls_sn", sheet("IO_percentage") firstrow clear
	save "$presim/IO_percentage.dta", replace

	
	import excel "$xls_sn", sheet("TVA_aux_params") firstrow clear
	levelsof globalname, local(globales)
	foreach z of local globales {
		levelsof globalcontent if globalname=="`z'", local(val)
		global `z' `val'
	}
	
	if ("$country" == "GMB") {
		global sect_fixed ""
	}
		
	if $TVA_simplified == 0{
		import excel "$xls_sn", sheet("TVA_raw") firstrow clear
		drop produit
		drop if codpr==.
		recode elasticities (.=0)
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
			levelsof elasticities if codpr==`z', local(vatelas)
			global vatelas_`z' `vatelas'
		}
	}

	*----------- Excises
		
	import excel "$xls_sn", sheet(Excises_raw) first clear
		
	keep Produit cat Taux codpr_read
		
	*replace Produit=lower(Produit)
	levelsof cat, local (products)
	foreach p of local products {
							
		levelsof Taux if cat=="`p'", local(tholds_`p')
		global taux_`p' `tholds_`p''
			
		levelsof codpr_read if cat=="`p'", local(tholds_`p')
		global codpr_read_`p' `tholds_`p''
			
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
			
	levelsof Autresname, local(params)
	foreach z of local params {
		levelsof Autresvalue  if Autresname=="`z'", local(val)
		global `z' `val'
	}
			
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
		
	*--------- Fuels
	
	*--------- Water



/*

	*==================================================================================
	dis "=================   Direct Taxes 	==============="
	*==================================================================================

	qui {

	// 1.1. Contribution Globale Unique //

	import excel "$xls_sn", sheet(DirTax_raw) first clear
	destring min max rate plus other, replace 
	replace min=-0.000001 if min<0
	tempfile RGU
	save `RGU', replace

	forval regime=1/3{ //There are 3 regimes de la Contribution Global Unique
		use `RGU', clear 
		drop if min==. & max==.
		drop if min==0 & max==0
		tostring max, replace // this is a trick to work with infinte value in the globals
		keep if Regime=="RGU`regime'"

		drop if min==.
		levelsof threshold, local(tholds)
		global tholdsRGU`regime' "`tholds'"
		foreach z of local tholds {
			levelsof min  if threshold=="`z'", local(RGU`regime'min`z')
			global RGU`regime'min`z' `RGU`regime'min`z''
			levelsof max  if threshold=="`z'", local(RGU`regime'max`z') 
			global RGU`regime'max`z' `RGU`regime'max`z''
			levelsof rate if threshold=="`z'", local(RGU`regime'rate`z')
			global RGU`regime'rate`z' `RGU`regime'rate`z''
			levelsof plus if threshold=="`z'", local(RGU`regime'plus`z')	
			global RGU`regime'plus`z' `RGU`regime'plus`z''
		}
		sum other
		global RGU`regime'_floor `r(mean)'
	}


	// 1.2. Impôt sur le Revenu (R. du Bénéf. Réel N & S) //

	use `RGU', clear 

	keep if Regime=="IR"
	replace max=. if max==0
	tostring max, replace // this is a trick to work with infinte value in the globals
	drop if min==.
	ren other deductions // this was created to be able to apply a discount rate to the tax credits received by income bracket

	levelsof threshold, local(tholds)
	global tholdsIR "`tholds'"
	foreach z of local tholds {
		levelsof min  if threshold=="`z'", local(IRmin`z')
		global IRmin`z' `IRmin`z''
		levelsof max  if threshold=="`z'", local(IRmax`z') 
		global IRmax`z' `IRmax`z''
		levelsof rate if threshold=="`z'", local(IRrate`z')
		global IRrate`z' `IRrate`z''
		levelsof plus if threshold=="`z'", local(IRplus`z')	
		global IRplus`z' `IRplus`z''
		levelsof deductions if threshold=="`z'", local(deduc`z')
		global deduc`z' `deduc`z''
	}

	use `RGU', clear 
	keep if Regime=="IR_reelnormal"
	levelsof min, local(min_reelnormal)	
	global min_reelnormal `min_reelnormal'
	levelsof rate, local(RSimpRate)
	global RSimpRate `RSimpRate'


	// 1.3. Parts points

	use `RGU', clear 
	keep if Regime=="Parts_raw"
	ren other Part
	tostring max, replace // this is a trick to work with infinte value in the globals
	ren max cap

	levelsof threshold, local(tholds)
	global tholdsParts "`tholds'"
	foreach z of local tholds {
		levelsof Part  if threshold=="`z'", local(part_`z')
		global part_`z' `part_`z''
		levelsof cap  if threshold=="`z'", local(cap_`z')
		global Cap_`z' `cap_`z''
	}



	use `RGU', clear 

	keep if Regime=="Parts_reduction" // since we integrate parts to the same excel file I am adjusting the name to previous names to do not mees up with the do-file 
	ren min Minimum
	ren max Maximum
	ren rate Taux
	ren other Nombre_parts 

	levelsof threshold, local(tholds)
	global tholdsNombreParts "`tholds'"
	foreach z of local tholds {
		levelsof Minimum  if threshold=="`z'", local(Partsmin`z')
		global Partsmin`z' `Partsmin`z''
		levelsof Maximum  if threshold=="`z'", local(Partmax`z') 
		global Partmax`z' `Partmax`z''
		levelsof Taux if threshold=="`z'", local(Partrate`z')
		global Partrate`z' `Partrate`z''
		levelsof Nombre_parts if threshold=="`z'", local(Part_nombre`z')
		global Part_nombre`z' `Part_nombre`z''
	}


	use `RGU', clear 

	keep if Regime=="IR_non"
	tostring max, replace
	levelsof threshold, local(tholds)
	global tholdsIR_non "`tholds'"
	foreach z of local tholds {
		levelsof max  if threshold=="`z'", local(IR_nonmax_`z')
		global IR_nonmax_`z' `IR_nonmax_`z''
		levelsof min  if threshold=="`z'", local(IR_nonmin_`z')
		global IR_nonmin_`z' `IR_nonmin_`z''
		levelsof rate  if threshold=="`z'", local(IR_nonrate_`z')
		global IR_nonrate_`z' `IR_nonrate_`z''
	}
	
	use `RGU', clear 
	
	keep if Regime=="TRIMF"
	replace max=. if max==0
	tostring max, replace // this is a trick to work with infinte value in the globals
	drop if min==.
	levelsof threshold, local(tholds)
	global tholdsTRIMF "`tholds'"
	foreach z of local tholds {
		levelsof max  if threshold=="`z'", local(TRIMFmax`z')
		global TRIMFmax`z' `TRIMFmax`z''
		levelsof min  if threshold=="`z'", local(TRIMFmin`z')
		global TRIMFmin`z' `TRIMFmin`z''
		levelsof rate  if threshold=="`z'", local(TRIMFtarif`z')
		global TRIMFtarif`z' `TRIMFtarif`z''
	}

	}


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





	*==================================================================================
	dis "==============                Direct Transfers     				==========="
	*==================================================================================


		****  CMU & Health
		
		import excel "$xls_sn", sheet(CMU_raw) first clear
		preserve
		drop if Programme =="Assurance_maladie"
		levelsof Programme, local(CMU) clean
		global Programme_CMU `CMU'
		foreach z of local CMU {
			levelsof Beneficiaires if Programme=="`z'", local(CMU_b_`z')
			global CMU_b_`z' `CMU_b_`z''
			levelsof Montant if Programme=="`z'", local(CMU_m_`z')
			global CMU_m_`z' `CMU_m_`z''
		}
		restore
		keep if Programme =="Assurance_maladie"
		levelsof Programme, local(Programme) clean
		global Sante `Programme'
		foreach z of local Programme{
			levelsof Montant if Programme=="`z'", local(Montant_`z')
			global Montant_`z' `Montant_`z''
			
		}

		**** Education

		preserve
		import excel "$xls_sn", sheet(education_raw) first clear

		levelsof Niveau, local(Niveau) clean
		global Education `Niveau'
		foreach z of local Niveau {
			levelsof Montant if Niveau=="`z'", local(Edu_montant`z')
			global Edu_montant`z' `Edu_montant`z''
			
		}
		restore

*/

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

 

