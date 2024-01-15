
global path "C:\Users\WB419055\OneDrive - WBG\SenSim Tool\Senegal_tool\Senegal_tool"
global presim "C:\Users\WB419055\OneDrive - WBG\SenSim Tool\Senegal_tool\Senegal_tool/01. Data/2_pre_sim"

*Needs to be run after using original values in the tool 

*include "$path/02. Dofile/01.Pullglobals.do"



use "$presim/05_purchases_hhid_codpr.dta", clear 
gen depan_tva=depan // depan_tva corresponds to spending that is affected by direct taxes when TVA is not enoug info (see below TVA_formal). Examples: tranche_3 of electricity, private hosp or priv education + all  products that pay tva

/*---------------------------------------------------------------------
	Electricity
*---------------------------------------------------------------------*/

merge n:1 hhid using "$presim/08_subsidies_elect.dta", keepusing( consumption_DGP_yr tranche1 tranche2 tranche3 tranche1_yr tranche2_yr tranche3_yr  periodicite prix_electricite s11q24a prepaid_woyofal prepaid_or consumption_electricite_yr consumption_electricite type_client) gen(merged_electricity ) // all tranches to consider all possible policies 


* Define Thresholds endogenously using bimonthly consumption of electricity 

	//tranche 1
	*postpaid (prepaid==0)
		/*DPP*/ gen tranche1_tool=$MaxT1_DPP if consumption_electricite>=$MaxT1_DPP & type_client==1 & prepaid_woyofal==0
		replace tranche1_tool=consumption_electricite if consumption_electricite<$MaxT1_DPP & type_client==1 & prepaid_woyofal==0
		
		/*DMP*/ replace tranche1_tool=$MaxT1_DMP if consumption_electricite>=$MaxT1_DMP & type_client==2 & prepaid_woyofal==0
		replace tranche1_tool=consumption_electricite if consumption_electricite<$MaxT1_DMP & type_client==2 & prepaid_woyofal==0
		replace tranche1_tool=0 if tranche1_tool==. & prepaid_woyofal==0
	
	*prepaid 
		/*DPP*/ replace tranche1_tool=$MaxT1_WDPP if consumption_electricite>=$MaxT1_WDPP & type_client==1 & prepaid_woyofal==1
		replace tranche1_tool=consumption_electricite if consumption_electricite<$MaxT1_WDPP & type_client==1 & prepaid_woyofal==1
		
		/*DMP*/ replace tranche1_tool=$MaxT1_WDMP if consumption_electricite>=$MaxT1_WDMP & type_client==2 & prepaid_woyofal==1
		replace tranche1_tool=consumption_electricite if consumption_electricite<$MaxT1_WDMP & type_client==2 & prepaid_woyofal==1
		replace tranche1_tool=0 if tranche1_tool==. & prepaid_woyofal==1
	
	//tranche 2
	*postpaid (prepaid==0)
	
		/*DPP*/ gen tranche2_tool=$MaxT2_DPP-$MaxT1_DPP if consumption_electricite>=$MaxT2_DPP & type_client==1 & prepaid_woyofal==0
		replace tranche2_tool=consumption_electricite-$MaxT1_DPP if consumption_electricite<$MaxT2_DPP & consumption_electricite>$MaxT1_DPP & type_client==1 & prepaid_woyofal==0
		
		/*DMP*/ replace	tranche2_tool=$MaxT2_DMP-$MaxT1_DMP if consumption_electricite>=$MaxT2_DMP & type_client==2 & prepaid_woyofal==0
		replace tranche2_tool=consumption_electricite-$MaxT1_DMP if consumption_electricite<$MaxT2_DMP & consumption_electricite>$MaxT1_DMP & type_client==2 & prepaid_woyofal==0
		replace tranche2_tool=0 if tranche2_tool==. & prepaid_woyofal==0
		
	*prepaid 
	
		/*DPP*/ replace tranche2_tool=$MaxT2_WDPP-$MaxT1_WDPP if consumption_electricite>=$MaxT2_WDPP & type_client==1 & prepaid_woyofal==1
		replace tranche2_tool=consumption_electricite-$MaxT1_WDPP if consumption_electricite<$MaxT2_WDPP & consumption_electricite>$MaxT1_WDPP & type_client==1 & prepaid_woyofal==1
		
		/*DMP*/ replace	tranche2_tool=$MaxT2_WDMP-$MaxT1_WDMP if consumption_electricite>=$MaxT2_WDMP & type_client==2 & prepaid_woyofal==1
		replace tranche2_tool=consumption_electricite-$MaxT1_WDMP if consumption_electricite<$MaxT2_WDMP & consumption_electricite>$MaxT1_WDMP & type_client==2 & prepaid_woyofal==1
		replace tranche2_tool=0 if tranche2_tool==. & prepaid_woyofal==1
	
	//tranche 3
	*postpiad 
	
		/*DPP*/ gen tranche3_tool=consumption_electricite-$MaxT2_DPP if consumption_electricite>=$MaxT2_DPP & type_client==1 & prepaid_woyofal==0
		/*DMP*/ replace	tranche3_tool=consumption_electricite-$MaxT2_DMP if consumption_electricite>=$MaxT2_DMP & type_client==2 & prepaid_woyofal==0
		replace tranche3_tool=0 if tranche3_tool==. & prepaid_woyofal==0
	
	*prepaid 
	
		/*DPP*/ replace  tranche3_tool=consumption_electricite-$MaxT2_WDPP if consumption_electricite>=$MaxT2_WDPP & type_client==1 & prepaid_woyofal==1
		/*DMP*/ replace	tranche3_tool=consumption_electricite-$MaxT2_WDMP if consumption_electricite>=$MaxT2_WDMP & type_client==2 & prepaid_woyofal==1
		replace tranche3_tool=0 if tranche3_tool==. & prepaid_woyofal==1



*Define prices of Kwh for each tranche 
	
	gen _tariff1=.
	gen _tariff2=.
	gen _tariff3=.
	
	foreach tranche in 1 2 3 {
		foreach paid in 0 1 {
			
			if "`paid'"=="0" local lpaid ""
			if "`paid'"=="1" local lpaid "W"
			
			foreach tension in DPP DMP {
			
			if "`tension'"=="DPP" local ltension 1
			if "`tension'"=="DMP" local ltension 2
			
					replace  _tariff`tranche'= ${TariffT`tranche'_`lpaid'`tension'}    if codpr==334 & prepaid_woyofal==`paid' &  type_client==`ltension'
					replace  _tariff`tranche'= ${TariffT`tranche'_`lpaid'`tension'}    if codpr==334 & prepaid_woyofal==`paid' &  type_client==`ltension'
					replace  _tariff`tranche'= ${TariffT`tranche'_`lpaid'`tension'}    if codpr==334 & prepaid_woyofal==`paid' &  type_client==`ltension'
			} // end tension 
		} // end pre-paid
	} // end tranche
	gen redevance =872 if prepaid_woyofal==0
	replace  redevance =429*2 if prepaid_woyofal==1

	replace _tariff1=0 if 	consumption_DGP!=0
	replace _tariff2=0 if consumption_DGP!=0
	replace _tariff3=0 if consumption_DGP!=0
	
	replace depan_tva=. if codpr==334
	replace depan_tva=6*((tranche1_tool*_tariff1*1.025)+(tranche2_tool*_tariff2*1.025)+(tranche3_tool*_tariff3*1.18*1.025)+(redevance))  if codpr==334 & (tranche3_tool!=0) //872 is redevance 

	gen ratio=depan/depan_tva if codpr==334 & (tranche3_tool!=0) //872 is redevance 
	count if (ratio<0.99 | ratio>1.01 ) &  ratio!=.
	// About 14 obs outliers that may create inconsistencies because obs of large values for which we have to recompute total spending 
	count if   ratio!=.
	count if codpr==334 & (tranche3_tool!=0)
	
