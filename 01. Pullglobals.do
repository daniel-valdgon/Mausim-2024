
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
dis "=================  Settings 	==============="
*==================================================================================

//Note: This implies  a change with respect the tool was designed so we are just inserting this change for certain sheets at a time: 
	// sheet CMU_raw (NONE but coming)
	
import excel "$xls_sn", sheet(settingshide) first clear

levelsof cat, local(params)
foreach z of local params {
	levelsof value  if cat=="`z'", local(val)
	global `z' `val'
}

destring value , force replace
mkmat value ,  mat(settings)


if $load_scenario ==1{
	import excel "$xls_sn", sheet("p_${scenario_name_load}") first clear
	levelsof globalname, local(globales)
	foreach z of local globales {
		levelsof globalcontent if globalname=="`z'", local(val)
		global `z' `val'
	}
	
	if "${scenario_name_save}"=="Ref_2018"{
		global asserts_ref2018 = 1
	}
	noi dis "{opt All the parameters of scenario ${scenario_name_load} have been loaded.}"
}
else {
	noi dis "{opt Loading the parameters from the tool. This may take some seconds...}"
	if "${scenario_name_save}"=="Ref_2018"{
		global asserts_ref2018 = 1
	}
	
	*==================================================================================
	dis "=================  Indirect Taxes 	==============="
	*==================================================================================
	
	import excel "$xls_sn", sheet("TVA_aux_params") firstrow clear
	levelsof globalname, local(globales)
	foreach z of local globales {
		levelsof globalcontent if globalname=="`z'", local(val)
		global `z' `val'
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
	
	if $TVA_simplified == 1{
		import excel "$xls_sn", sheet("TVA_ref_raw") firstrow clear
		drop produit
		drop if codpr==.
		recode elasticities (.=0)
		
		replace TVA      = $tva_TOUS    if $overwrite_TOUS == 1
		replace exempted = $exempt_TOUS if $overwrite_TOUS == 1
		
		if $overwrite_TOUS == 0 {
			replace TVA      = $tva_otherfood    if $overwrite_otherfood == 1 & inlist(codpr,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,151,152)
			replace exempted = $exempt_otherfood if $overwrite_otherfood == 1 & inlist(codpr,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,151,152)
			
			replace TVA      = $tva_meat    if $overwrite_meat == 1 & inlist(codpr,23,24,25,26,27,28,29,30,31,32,33,34)
			replace exempted = $exempt_meat if $overwrite_meat == 1 & inlist(codpr,23,24,25,26,27,28,29,30,31,32,33,34)
			
			replace TVA      = $tva_educ    if $overwrite_educ == 1 & inlist(codpr,642,643,661,663,664,666,667,669,670,672)
			replace exempted = $exempt_educ if $overwrite_educ == 1 & inlist(codpr,642,643,661,663,664,666,667,669,670,672)
			
			replace TVA      = $tva_gas    if $overwrite_gas == 1 & inlist(codpr,303)
			replace exempted = $exempt_gas if $overwrite_gas == 1 & inlist(codpr,303)
			
			replace TVA      = $tva_journals    if $overwrite_journals == 1 & inlist(codpr,216,315)
			replace exempted = $exempt_journals if $overwrite_journals == 1 & inlist(codpr,216,315)
			
			replace TVA      = $tva_housing    if $overwrite_housing == 1 & inlist(codpr,331)
			replace exempted = $exempt_housing if $overwrite_housing == 1 & inlist(codpr,331)
			
			replace TVA      = $tva_health    if $overwrite_health == 1 & inlist(codpr,681,682,683,684,685,686,691,692)
			replace exempted = $exempt_health if $overwrite_health == 1 & inlist(codpr,681,682,683,684,685,686,691,692)
			
			replace TVA      = $tva_transp    if $overwrite_transp == 1 & inlist(codpr,210,211,212,213,214,215,405,406,407,629,630,631)
			replace exempted = $exempt_transp if $overwrite_transp == 1 & inlist(codpr,210,211,212,213,214,215,405,406,407,629,630,631)
		}
		
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
	dis "==============              Excises Taxes         					==========="
	*==================================================================================
		
	qui {

		import excel "$xls_sn", sheet(Excises_raw) first clear
		
		replace Produit=lower(Produit)
		levelsof Produit, local (products)
		
		foreach p of local products {
								
			levelsof Taux if Produit=="`p'", local(tholds_`p')
			global taux_`p' `tholds_`p''
		}							  
		
		
	}


	*==================================================================================
	dis "==============                Direct Transfers     				==========="
	*==================================================================================

	qui {

		**** Programme National de Bourses de Sécurité Familiale 

		import excel "$xls_sn", sheet(PNBSF_raw) first clear
								  
									 

		levelsof departement, local(departement)
		global departementPNBSF `departement'
		foreach z of local departement {
			levelsof Beneficiaires if departement==`z', local(PNBSF_Beneficiaires`z')
			global PNBSF_Beneficiaires`z' `PNBSF_Beneficiaires`z''
			levelsof Montant if departement==`z', local(PNBSF_montant`z')
			global PNBSF_montant`z' `PNBSF_montant`z''
		}

		**** Cantine Scolaire

		import excel "$xls_sn", sheet(Cantine_scolaire_raw) first clear
												
																				   

		levelsof Region, local(region)
		global regionCantine `region'
		foreach z of local region {
			levelsof nombre_elevees if Region==`z', local(Cantine_Elevee`z')
			global Cantine_Elevee`z' `Cantine_Elevee`z''
			levelsof montant_cantine if Region==`z', local(Cantine_montant`z')
			global Cantine_montant`z' `Cantine_montant`z''
		}		   
																				   

		**** Bourse Universitaire
		
		import excel "$xls_sn", sheet(Bourse universitaire_raw) first clear

		levelsof Type, local(type) clean
		global TypeBourseUniv `type'
		foreach z of local type {
			levelsof Beneficiaires if Type=="`z'", local(Bourse_Beneficiaire`z')
			global Bourse_Beneficiaire`z' `Bourse_Beneficiaire`z''
			levelsof montant if Type=="`z'", local(Bourse_montant`z')
			global Bourse_montant`z' `Bourse_montant`z''
		}

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

		
		

		*==================================================================================
		dis "==============            Subvention Electricité  					==========="
		*==================================================================================

		

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
	
	
	
		*==================================================================================
		dis "==============            Subvention Eau         					==========="
		*==================================================================================

		

		import excel "$xls_sn", sheet(Subvention_eau_raw) first clear
		
		levelsof Autresname, local(params)
		foreach z of local params {
			levelsof Autresvalue  if Autresname=="`z'", local(val)
			global `z' `val'
		}
		
		drop if Tariff=="."
		
		*gen namevar = Threshold+"_"+Type
		tempfile eau_raw_dta
		save `eau_raw_dta', replace 

		levelsof Type, local(types)
		global typesEau "`types'"
		foreach t of local types {
			levelsof Threshold if Type=="`t'", local(tholds)
			global typesEau`t' "`tholds'"
			foreach z of local tholds {
				levelsof Max  if Threshold=="`z'" & Type=="`t'", local(Max`z')
				global Max`z'_`t' `Max`z''
				levelsof Subvention  if Threshold=="`z'" & Type=="`t'", local(Subvention`z') 
				global Subvention`z'_`t' `Subvention`z''
				levelsof Tariff  if Threshold=="`z'" & Type=="`t'", local(Tariff`z') 
				global Tariff`z'_`t' `Tariff`z''
			}
		}
	}
	

	*==================================================================================
	dis "==============            Subvention Carburants  					==========="
	*==================================================================================

		

		import excel "$xls_sn", sheet(Subvention_fuel_raw) first clear
		levelsof fuels, local(fuels)
		global typesFuels "`fuels'"
		foreach z of local fuels {
			levelsof market_price  if fuels=="`z'" , local(Mp`z')
			global mp_`z' `Mp`z''
			levelsof subsidized_price  if fuels=="`z'" , local(sub`z')
			global sp_`z' `sub`z''
			levelsof subsidy_perc  if fuels=="`z'" , local(sr`z')
			global sr_`z' `sr`z''
			levelsof initial_price  if fuels=="`z'" , local(ip`z')
			global ip_`z' `ip`z''
			levelsof pond_men_  if fuels=="`z'" , local(pmen`z')
			global pond_men_`z' `pmen`z''
			levelsof pond_ent_  if fuels=="`z'" , local(pent`z')
			global pond_ent_`z' `pent`z''
		}

		
		
		
	*AG: There are no sources on this policy. I did some research and it seems like the whole budget of the Dept. of Agriculture was 53 milliards.  Check this at the end.
	*global total_agriculture 53260000000 // this needs to be change and include in the excel 
	*(AGV) I included this parameter in the Excel tool. 
}

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

	export excel "$xls_sn", sheet("p_${scenario_name_save}") sheetreplace first(variable)
	noi dis "{opt All the parameters of scenario ${scenario_name_save} have been saved to Excel.}"
	
	*Add saved scenario to list of saved scenarios
	import excel "$xls_sn", sheet(legend) first clear cellrange(AH1)
	drop if Scenario_list==""
	expand 2 in -1
	replace Scenario_list="${scenario_name_save}" in -1
	duplicates drop
	gen ord=2
	replace ord=1 if Scenario_list=="Ref_2018"
	replace ord=3 if Scenario_list=="User_def_sce"
	sort ord, stable
	drop ord
	
	export excel "$xls_sn", sheet(legend, modify) cell(AH2)
}

 

