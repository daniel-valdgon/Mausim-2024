/*===================================================================================
project:       Colombia Simulation Tool
Author:        Juan P. Baquero
url:           
Dependencies:  World Bank

------------------------------------------------------------------------------------
Creation Date:    21 Nov 2021 
Modification Date:   

Do-file version:  02, August 2022, Daniel Valderrama
				- Elasticities are softcoded 
Do-file version:  02, September 2022, Daniel Valderrama
				- **Added alternative scenarios withouth creating VAT sheets in excel file (Pendent to change old scenarios to this structure). This would clean excel file and allow to easily read predetermined scenarios. However it breaks the idea of a tool. So we need to create new sheet call TVA scenarios 
				- Important changes in private vs public VAT:
					-Change the way VAT to private schools and hospitals is included (pendent: split private and public consumption in the microdata and the crosswalk so simulations with those are easier to implement)
					- Corrected how behavioral elasticities were applied when the VAT was collected from private vs public (if only private increase, behavioral response should happen in consumers of private health)
					- Corrected the order when VAT rate is applied (pendent to split consumption in the microdata so this procedure is cleaner)

		Pendent: Create water and electricity policy in softcode. Social tranche is important VAT policy, we may want to give better flexibility in the tool to this. It will imply more parameters: VAT to each tranche of consumption for each tranche of consumer and may be also changes to the threshold of each tranche 
		
		Split private and public consumption of health and education in the microdata and assign different exemptions. Therefore no exempted productss have much more indierct effect
		 DO we apply indirect effects to only exempted products or to all products... answer to all but exempted suffer much more (the entire supply channel), non exempted suffer if they use as input .....

		Two health activities linked to sector 14 (Drugs and vacciness). When we defined all sector health as subject to VAT we also eliminate the indirect effect of VAT on sector's inputs. This is correct if we do not split by private and public. 

		*For Private and public allocations, we want spending splitted for direct effects easier. Right now modified below. Also IO-splitted or at least multiplied by a share of private within total spending 
		
		*Here star a new way. Now we have specific combinations of policies and a user customize policy that we will need to introduce in the list and will be linked to TVA.
		
		*Use villes non assainies  and villes assainies to define the consumption of water units Not necesarily high impact unless we will focus on subsidies as well 
		
===================================================================================*/

*This was done to debug the program. It will be deleted once we finish the development stage
 local sce_debug "no"

 if "`sce_debug'"== "yes" {
	local sce_debug_par 13
	mat settings[3,1]=`sce_debug_par' 	
 }


/*==================================================================
-------------------------------------------------------------------*
				1. Computing indirect price effects 
-------------------------------------------------------------------*
===================================================================*/

*****   Load TVA Scenario

// 1  Baseline 
// 13 Electricity

// 23 Private hospitalization 0.15

// 24 Private hospitalization 0.15
// 25 Private hospitalization 0.25

{

	local vat_str 
	
	if (settings[3,1]==0) {
	local vat_str ""
	}
	if (settings[3,1]==1) {
	local vat_str "_ref"
	}
	
	if (settings[3,1]==14) { // All goods see below the list 
	local vat_str "_ref"
	}
	if (settings[3,1]==15) {
	local vat_str "_pol_pros"
	}
	
	*Utilities 
	if (settings[3,1]==8) {
	local vat_str "_gaz"
	}
	if (settings[3,1]==13) { // Electricity
	local vat_str "_ref" 
	local tool "inlist(codpr,334)" 
	}
		
	*Luxury/non-staple food 
	if (settings[3,1]==2) {
	local vat_str "_aliment"
	}
	if (settings[3,1]==3) {
	local vat_str "_aliment_basket"
	}
	if (settings[3,1]==4) {
	local vat_str "_aliment_25"
	}
	if (settings[3,1]==17) { // meat
	local sheetnm "_ref"
	local tool "inrange(codpr, 23, 32)"
	}
	if (settings[3,1]==18) { // rice
	local sheetnm "_ref"
	local tool "inlist(codpr, 4)"
	}
	
	
	*Health 
	if (settings[3,1]==12) { // All health 
	local vat_str "_sante"
	}
	if (settings[3,1]==16) { // Private hospitalization (see below why _ref)
	local sheetnm "_ref"
	local tool "inlist(codpr, 691)"
	}
	
	if (settings[3,1]==19) { // Private medical services (see below why _ref) 
	local sheetnm "_ref"
	local tool "inlist(codpr,681,682,683,684,685)"
	}
	
	if (settings[3,1]==24) { // Private hospitalization (see below why _ref)
	local sheetnm "_ref"
	local tool "inlist(codpr, 691)"
	local non_medical_serv 0.15
	}
	if (settings[3,1]==25) { // Private hospitalization (see below why _ref)
	local sheetnm "_ref"
	local tool "inlist(codpr, 691)"
	local non_medical_serv	 0.25
	}
	
	*Education scenarios 
	if (settings[3,1]==10)  { 	// _education because we want to affect the input-output. 
	local vat_str "_education"
	local tool "inlist(codpr,642,643,661,664,667,670)"
	}
	*--> This sim private education, since IO is not split we do not want to modify this sector at all (see pendent)
	if  (settings[3,1]==11) {
	local vat_str "_ref" //  education _ref rather than _education_private because we do not want all indirect effects of public education to dissapear (anyway those are small)
	local tool "inlist(codpr,642,643,661,664,667,670)"
	}
	if (settings[3,1]==20) { // Adult education 
	local sheetnm "_ref"
	local tool "inlist(codpr,642,643)"
	}
	if (settings[3,1]==21) { // Education primary
	local sheetnm "_ref"
	local tool "inlist(codpr,661)"
	}
	if (settings[3,1]==22) { // Education secondary
	local sheetnm "_ref"
	local tool "inlist(codpr,664, 667)"
	}
	if (settings[3,1]==23) { // Education tertiary
	local sheetnm "_ref"
	local tool "inlist(codpr,670)"
	}
	
	*Other: Transport , journaux, loyer 
	if (settings[3,1]==5) {
	local vat_str "_transport"
	}
	if (settings[3,1]==6) {
	local vat_str "_transport_selec"
	}
	if (settings[3,1]==7) {
	local vat_str "_jornaux"
	}
	
	if (settings[3,1]==9) {
	local vat_str "_loyer"
	}
	
}

*-------------------------------------------------------------------------------                 
** Step 1.1 Load TVA policy and define exempted sector that need to be expanded 
*-------------------------------------------------------------------------------
{

import excel "$xls_sn", sheet("TVA_raw`vat_str'") firstrow clear     // Load  TVA rates and formality. NOTICE that the TVA_raw_`vat_str' of other policies do not have the column of exemption, so it needs to be check if the hidden sheet has them or not 
keep codpr TVA formelle exempted
drop if codpr==.


//Notice adding VAT to health and education for private providers assumes that private providers are not large enough to offset the fact that health and education are fixed 

if (settings[3,1]==17) | (settings[3,1]==18)  {  // Meat and Rice 
	replace TVA=18 		if `tool'
	replace exempted=0 	if `tool'
}

//Scenario of all exemptions at once
if (settings[3,1]==14) {
	
	levelsof codpr if exempted==1, local (list_noexemp)
	
	foreach l of local list_noexemp {
		replace TVA=18 		if codpr==`l'
		replace exempted=0 	if codpr==`l'
	}
}

***** Merge the IO mapping, item to sector 

merge 1:m codpr using "$data_sn/IO_percentage2_clean.dta", nogen // Before product  647 was not split correctly among its four sectors 

// one specific error in the IO_percentage  file 


rename Secteur  sector
rename exempted Excluido
rename TVA IVA
tempfile data

save `data'

collapse (mean) IVA , by(sector Exc)

*****   Create local of sectors that do not have a mixed case of exemption 

//  first we keep the sectors that have a mixed case of exemption   

collapse (mean) Excluido (max) IVA, by(sector)

drop if sector==.

tempfile tasas
save `tasas'

levelsof sector if Excluido!=0 , local(excluded)

keep if Excluido!=0 & Excluido!=1
*}

*-------------------------------------------------------------------------------                 
** Step 1.2  create the extended matrix For mixed sectors (those with exempted and non exempted articles)
*-------------------------------------------------------------------------------

*{

// we store the sectors that have exempted and non exempted items 

levelsof sector ,  local(noncollsecs)     

// we store the sectors that do not have mixed cases 

local collsecs      

 foreach ii of numlist 1/35 { // notice if number of sectors change this needs to be change, it should not be 
 
 local  macname : list ii in noncollsecs
 
 dis(`macname')
 
 if (`macname')==0 {
 
 local  collsecs  `collsecs' `ii' // will be used to keep only sectors that have both exempted and non-exempted sectors 
 }
 
 }
 
 dis("`collsecs'")
 
 
 *****   Create the extented IO only extending the Mixed sectors 
 
/// Import IO 

import excel "$data_sn\IO_Matrix.xlsx", sheet("Sheet1") firstrow clear
drop if Secteur==.

// Store the IO in Mata 

mata: io=st_data(., "C1-C35",.) // (.) returns in stata all observations,  for  variables between (C1-C35), (.) no conditions on the observations that should be excluded

// Matrix of ceros 

mata: extended=J(35*2,35*2,0)   // square matrix of 35X2 filled of zeros


// First we extended all the sectors 
	mata: 
	for(n=1; n<=35; n++)  {
	
		jj=2*n-1
		kk=jj+1
	
		for(i=1; i<=35; i++)  {
		j=2*i-1
		k=j+1
		
		extended[jj::kk,j::k]=J(2,2,io[n,i])/2
		
		}
	}
	
	st_matrix("extended",extended)
	
	end

clear

svmat extended // from mata to stata : extended is 70X (35+70)

rename extended* sector_* // index extended sectors 

gen sector=ceil(_n/2) // rename sectors with ceiling name

// Second we collapse sectors that do not extend 


gen aux=.

foreach ii of local  collsecs {
	replace  aux=1    if  sector==`ii'       // sectors that collapse 
}

replace aux=0 if aux==.

preserve 

keep if aux==0

tempfile nocollapse

save `nocollapse'

restore 

// Third we keep the sectors that collapse and then append the sectors that do not collapse 

keep if aux==1    

collapse (sum) sector_1-sector_70 if aux==1 , by(sector)

append using `nocollapse'

sort sector


// Fourth and finnaly we remove columns of the sectors that do not collapse 

drop aux

foreach var of local collsecs {

local ii =  `var'*2

drop sector_`ii'

}

//Now the matrix is a square matrix that only expanded sectors that include both exempted and non-exempted products

// we identify excluded sectors 

gen exempted=0

foreach var of local excluded {

replace exempted=1   if   sector==`var'

}

bys sector:  gen aux_size=_n
replace exempted=0  if aux_size==2
drop aux_size

}


*-------------------------------------------------------------------------------                 
** Step 1.3 Cost push 
*-------------------------------------------------------------------------------

{
// we identify the fixed sectors: we follow the previous CEQ on this 

local thefixed 22 32 33 34

gen fixed=0

foreach var of local thefixed {

replace fixed=1  if  sector==`var'

}


merge m:1 sector using `tasas'

replace IVA=0  if exempted==1

replace IVA=0 if IVA==.

gen cp=1-fixed

gen vatable=1-fixed-exempted

replace IVA=IVA/100

gen shock= - IVA/(1+IVA)

replace shock=0  if shock==.


gen indirect_effect_iva=0

// cost push replication   
*replace exempted=1 

*replace vatable=1

mata : st_view(YY=., ., "indirect_effect_iva",.)
mata: XX=st_data(., "sector_1-sector_69",.)
mata: cp=st_data(., "cp",.)'
mata: shock=st_data(., "shock",.)'
mata: vatable=st_data(., "vatable",.)'		
mata: exempt=st_data(., "exempted",.)'


*costpush sector_1-sector_69 ,fixed(fixed) priceshock(shock) genptot(ptot_ivashock) ///
*	 genpind(pind_ivashock) 


mata:  YY[.,.]=indirect(XX,cp,shock,vatable,exempt)'

replace indirect_effect_iva=0   if cp==0

keep sector indirect_effect_iva exempted

sum indirect_effect_iva

replace indirect=-indirect

tempfile indirect

save `indirect'


// Here we use the percentage shares of each IO sectors 

use `data' , clear

rename Excluido exempted

merge m:1 sector exempted using  `indirect' , nogen

drop if codpr==.

replace indirect_effect_iva=0  if indirect_effect_iva==.

replace  indirect_effect_iva=indirect_effect_iva*pourcentage // computing codpr weighted average for the indirect effect 

ren exempted exempt_codpr

collapse (sum) indirect_effect_iva (max) exempt_codpr formelle (mean) IVA , by(codpr)

rename indirect_effect_iva aux_effect_indirect
rename IVA TVA

tempfile ieffects_vat_SN

save `ieffects_vat_SN'

}


/*==================================================================
-------------------------------------------------------------------*
				2. Computing welfare effects 
-------------------------------------------------------------------*
===================================================================*/

/*-------------------------------------------------------------------*
*	2.1 Loading the Expenditure data and applying particular VAT cases. example: privatevs public, tranches, hosp 	services 
*-------------------------------------------------------------------*/


use "$presim/05_purchases_hhid_codpr.dta", clear 
merge m:1 codpr using `ieffects_vat_SN' , assert(matched using) keep(matched) nogen  

gen depan_tva=depan // depan_tva corresponds to spending that is affected by direct taxes when TVA is not enoug info (see below TVA_formal). Examples: tranche_3 of electricity, private hosp or priv education + all  products that pay tva

/*---------------------------------------------------------------------
	Water
*---------------------------------------------------------------------*/

merge m:1 hhid  using "$presim/05_water_quantities.dta", keepusing( eau_quantity eau_depbim) // we change the dataset in pre_sim 

	if  (settings[3,1]==15)    { // (settings[3,1]==13) | Those above 40mts - i.e. trance 3 pay VAT over the whole bill (This is also the new 15) 
		replace depan_tva=eau_depbim*6 if  eau_quantity>40 & codpr==332
		replace depan_tva=0 if eau_quantity<=40 & codpr==332
	}
	else { // reference policy 
		*Consumption below 40 is exempted from VAT
		gen eau_quantity_no_TVA=-40 if codpr==332 & eau_quantity>40
		replace eau_quantity_no_TVA= -eau_quantity if codpr==332 &  eau_quantity<=40 // - consumption in order to obtain eau_quantity_TVA=0 in the following line
		egen eau_quantity_TVA=rowtotal(eau_quantity eau_quantity_no_TVA)
	
		* Third we replace the amount payed by the household on the water and sewage bill for the quantities that pay VAT*/
		replace depan_tva=((eau_quantity_TVA)*(739.96))*6 if eau_quantity>40 & codpr==332
		replace depan_tva=0 if eau_quantity<=40 & codpr==332
	}

/*---------------------------------------------------------------------
	Electricity
*---------------------------------------------------------------------*/

merge n:1 hhid using "$presim/08_subsidies_elect.dta", keepusing( consumption_DGP_yr tranche1_yr tranche2_yr tranche3_yr  periodicite prix_electricite s11q24a prepaid_woyofal prepaid_or consumption_electricite_yr consumption_electricite type_client) gen(merged_electricity ) // all tranches to consider all possible policies 

*Electricity spending is recomputed based on new parameters of prices and thresholds 
qui {

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


	replace _tariff1=0 if consumption_DGP!=0
	replace _tariff2=0 if consumption_DGP!=0
	replace _tariff3=0 if consumption_DGP!=0
	
	gen redevance =872 if prepaid_woyofal==0
	replace  redevance =429*2 if prepaid_woyofal==1

}	


if (settings[3,1]==13)  { //Households who consume in tranche 3 & DGP will pay VAT over all their consumption. Rest of households do not pay VAT  

	replace depan_tva=0 if tranche3_tool==0 & consumption_DGP_yr==0 & codpr==334 
	replace depan_tva=depan if consumption_DGP_yr!=0 & codpr==334
	replace depan_tva=6*((tranche1_tool*_tariff1*1.025)+(tranche2_tool*_tariff2*1.025)+(tranche3_tool*_tariff3*1.18*1.025)+(redevance))  if codpr==334 & (tranche3_tool!=0) //872 is redevance 

} 
else { // reference policy
	
	*Tariffs here should be at 2019 prices. Currently we deflate by inflation and input the value in real terms in the tool 
	* VAT exemptions for tranche 1 & 2
	*//872 is the bimonthly redevance 
	replace depan_tva=0 if tranche3_tool==0 & consumption_DGP_yr==0 & codpr==334 
	replace depan_tva=depan if consumption_DGP_yr!=0 & codpr==334
	replace depan_tva=6*((tranche3_tool*_tariff3*1.18*1.025)+(redevance))  if codpr==334 & (tranche3_tool!=0) //872 is redevance 
	
	/* Before was completely wrong because the use of periodicite and the definition of tranche 3 itself + the non-consideration of pre-paid. MOreover the tranche 3 was hardcoded now is endogenous to the policy 
		replace depan=((tranche3*112.65)+866)*12 	if codpr==334 & tranche3!=0 & periodicite==1
		replace depan=((tranche3*112.65)+866)*6 	if codpr==334 & tranche3!=0 & periodicite==2
		replace depan=((tranche3*112.65)+866)*4 	if codpr==334 & tranche3!=0 & periodicite==3
		replace depan=((tranche3*112.65)+866)*3 	if codpr==334 & tranche3!=0 & periodicite==4
		replace depan=0 if tranche3==0 & codpr==334
	*/
	
}


*---------------------School fees Private --------

/* Exclude from taxable purchases private and create TVA only for private (the later will be modified when IO is expanded or we use a share for private sector */

if (settings[3,1]==11) | (settings[3,1]==20) | (settings[3,1]==21) | (settings[3,1]==22) | (settings[3,1]==23) {
	merge n:1 hhid using "$data_sn/public_school.dta", gen(merged_public)
	replace TVA=18 if  `tool' &  pub_school!=1 
	
	// NOTE:  If the share of private education spending on the corresponding IO sector was large we will have a problem by adding the TVA and the exemption at this stage because the indirect effects for all sectors that use education as input will be wrong: 
		// However, that is not the case at this stage because education is still defined as fixed so exempted or not there is not indirect effects and also because private education is small within total education spending --> actual TVA of the IO sector is zero. Third reasons, nothing use education as input
}

*--------------------- Medical services Private healthcare
if (settings[3,1]==19)  {

	merge m:1 hhid using "$data_sn/priv_med_serv.dta",  keep(master matched) nogen
	replace TVA=18 if `tool' // See in the education section why this would be wrong if public health is not regulated (adding non-existent indirect effects) and private spending is not a small share of IO-health sector. 
	
	replace sh_priv_med=0 if sh_priv_med==. // this should not be necessary if survey is well harmonized, and it has an implicit assumption (sh_priv_med=0) for those cases either badly harmonize or where we can not identify the hospital 
	
	replace depan_tva=depan_tva*sh_priv_med   if `tool' 
	// NOTE: We exclude the share that is spent on Public hospitals, most of  sh_priv_med==0
	//		 The `tool' list  had drugs and vaccines, this was complicated because adding only up to here the TVA implied having indirect effects from inputs use by IO-sector 14)
}

*---------------------Hospitalization fees Private : Hospitalization Private hospitals 

if  (settings[3,1]==16)  | (settings[3,1]==24) | (settings[3,1]==25)   { // hosp services and pol_pros
	drop if hhid==. & codpr==.
	merge 1:1 hhid codpr using "$data_sn/hospit", keepusing( sh_depan_hosp ) keep(master matched)  gen(m_hosp)
	replace sh_depan_hosp=0 if sh_depan_hosp==.
	
	replace TVA=18 if codpr==691 & sh_depan_hosp!=. & sh_depan_hosp!=0 // See note in education spending about the assumption about indirect effects of eliminating the exemption for private spending
	
	replace depan_tva=depan_tva*sh_depan_hosp if codpr==691
	
	if (settings[3,1]==24) | (settings[3,1]==25) {
	
		replace depan_tva=depan_tva*`non_medical_serv' if codpr==691
	
	}
}



*=============================================================================*
*				2.2	Introduce Behavioral Responses 							  *
*=============================================================================*
{ // bracket to close code
	// prepare elasticities 
	*call it above with all the merges... merge m:1 hhid using "$data_sn\poor.dta" , keepusing(poor) nogen
	merge m:1 codpr poor using "$presim/05_elasticities.dta",  keep(matched master) nogen
	recode factor_behavioral .=1
	
	// Only add elasticities to goods for which exemptions are eliminated so we start with factor_behavioral_f=1
	gen factor_behavioral_f=1 
	
	if (settings[3,1]==2) {
		replace factor_behavioral_f=factor_behavioral  if   codpr>=1 & codpr<=138    // aliment 
	}
	if (settings[3,1]==3) {
		replace factor_behavioral_f=factor_behavioral   if   (codpr>=1 & codpr<=138) & !inlist(codpr,17,35,648,114,58,1,23,48,38,7,83,129,56	,2,130,29,30,18,25,73,74,6,121,45,16,77,41,53,91,104,95,119	,84	,98	,85,140,109,100,37,79,81,44,36,107,4,26,55,52,39,78)	// basket 
	}
	if (settings[3,1]==4) {
		replace factor_behavioral_f=factor_behavioral  if   (codpr>=1 & codpr<=138) & !inlist(codpr, 17 ,35 , 648,114,58,1,23,48,38,7,83,129,56,2,130,29,30,18,25,73,74,6,121,45,16)   // basket 25
	}
	if (settings[3,1]==5) {
		replace factor_behavioral_f=factor_behavioral    if inlist(codpr,210,211,212,213,214,215,629)   // transport 
	}
	if (settings[3,1]==6) {
		replace factor_behavioral_f=factor_behavioral if inlist(codpr,210,214,629)    // transport select
	}
	if (settings[3,1]==7) {
		replace factor_behavioral_f=factor_behavioral if inlist(codpr,216)
	}
	if (settings[3,1]==8) {
		replace factor_behavioral_f=factor_behavioral if inlist(codpr,303)
	}
	if (settings[3,1]==9) {
		replace factor_behavioral_f=factor_behavioral if inrange(codpr,23,32) // THis was done before the mission to do not change the list of the excel tool , now instead of Rent is the Meat scenario
	}
	if (settings[3,1]==12) {
		replace factor_behavioral_f=factor_behavioral if inlist(codpr,681,682,683,684,685) //sante
	}
	if (settings[3,1]==13) { // water and electricity 
		replace factor_behavioral_f=factor_behavioral if `tool'  // only tranche 3 pay, no need to limit behavioral effect to them because hh in tranche 1 and 2 have 0 indirect effects of VAT because sector is regulated 
	}
	if (settings[3,1]==14) {
		foreach l of local list_noexemp {
	
			replace factor_behavioral_f=factor_behavioral	if codpr==`l'
		}	
	}
	
	
	if (settings[3,1]==17) | (settings[3,1]==18)  {
		replace factor_behavioral_f=factor_behavioral if `tool' 
	}
	
	*Health Education 
	if (settings[3,1]==19) | (settings[3,1]==16) |  (settings[3,1]==24) |  (settings[3,1]==25)  {
		replace factor_behavioral_f=factor_behavioral if `tool' // Not needed to use share of private spending on health because we exclude already spending from public hospitals. So behavioral will be applied only over total
	}
	*Education 
	if (settings[3,1]==10) |  (settings[3,1]==11) | (settings[3,1]==20) | (settings[3,1]==21) | (settings[3,1]==22) | (settings[3,1]==23 ) {
		replace factor_behavioral_f=factor_behavioral if `tool' 
		// Not needed public!=1 here for 11,20,...23 because we exclude already public spending from the taxable base 
	}	

}
*=================================================================================================*
*	2.3	Applying elasticities, Exemptions effects and informality to the computation of welfare *
*=================================================================================================*

qui {

// Reduce consumption by the elasticity X Price! (Dv this is the main change here) 
// Cost of TVA: formal is actual TVA, informal is indirect effects when the good was formal in its inputs

if "$new_behavioral"=="yes" {
	
	// behaviroal respo: price X elasticity, so:
			// (P_d + P_ind) X behavioral for formal consumption 
			// (P_ind) X behavioral for info 
	
	gen beh_dir=((TVA/100)/(1+(TVA/100)))*factor_behavioral_f
	gen beh_indir=aux_effect_indirect
}
else {



	dis "The following line is temporal and needs to be fixed once we include the elasticities properly)"
	
	replace factor_behavioral_f=1 // this line overwrites previous code on behavioral effects because there is still a mistake with that code that needs to be fixed 
	replace depan=depan*factor_behavioral_f
	replace depan_tva=depan_tva*factor_behavioral_f
	
	// formal and informal spending 
	gen formal_tva= depan_tva*(1-informality_purchases) // depan_tva is VAT base. Therefore exclude subsets of spending that are exempted (ex medical services from hosp are not taxed)
	gen formal= depan*(1-informality_purchases) // Spending that matters for cascading effects. Since cascading effects are over the price of the products it affects all spending
	gen informal= depan*informality_purchases  // depan has all spending, and informal taxes care about all
	
	
	/// Here start some changes from JPablo with respect to JPico
	gen direct_TVA= formal_tva*((TVA/100)/(1+(TVA/100))) // TVA for non exempted spending. Sometimes TVA variable is not enough because within a produc some spending is taxable and other is not (example:  private-health, private-educ, social tranche spending on utilities. Other way to obtain this would be to splitting private, non-medical and tranche spending in the original household survey as pre-simulation do-file. This would also change the IO-sector crosswalk and ideally is automatically store in the do-files
	
	gen indirect_TVA= formal*aux_effect_indirect // Cascading for all spending. This variable is at the product-exemption level because cascading of exempted is different than cascading for non-exempted products 
	
	gen Tax_TVA_informal1=informal*0
	gen Tax_TVA_informal2=informal*aux_effect_indirect
	gen Tax_TVA_informal3=informal*0 if formelle==0
	replace Tax_TVA_informal3=informal*aux_effect_indirect  if formelle==1 //* Cacading if formelle . HOwever this assumes TVA has no effect on products!!!. replace Tax_TVA_informal3=informal*((TVA/100)/(1+(TVA/100)))*0.3  if formelle==1
}

	egen Tax_TVA1=rowtotal(direct_TVA indirect_TVA Tax_TVA_informal1)
	egen Tax_TVA2=rowtotal(direct_TVA indirect_TVA Tax_TVA_informal2)
	egen Tax_TVA3=rowtotal(direct_TVA indirect_TVA Tax_TVA_informal3)
	
	gen efective_VAT= Tax_TVA1/ depan
	gen efective_VAT2= Tax_TVA2/ depan
	gen efective_VAT3= Tax_TVA3/ depan

	rename Tax_TVA3 Tax_TVA // (DV) before we have a local here, I dropped because the current decision is to use the Tax_TVA3

}
	
	gen rice= Tax_TVA 			if codpr==4
	gen water_elect= Tax_TVA 	if codpr==334 | codpr==332
	gen hosp= Tax_TVA			if codpr==691
	
	gen exempted_potential=0.18*depan*(1-informality_purchases) if TVA==0
	
	gen exempted=depan if TVA==0
	
	gen aliment=1 if codpr>=1 & codpr<=138
	
	gen aliment_exem=depan                                           if  aliment==1  & TVA==0
	
	gen aliment_exem_infor=depan*informality_purchases               if  aliment==1  & TVA==0
	
	gen non_aliment_exem=depan                                       if  aliment==.  & TVA==0
	
	gen non_aliment_exem_infor=depan*informality_purchases           if  aliment==.  & TVA==0
	
	
	local list_item_stats " rice water_elect hosp exempted aliment_exem aliment_exem_infor non_aliment_exem non_aliment_exem_infor"

	
	
* tool to debug we want to observe a specific VAT spending 
if "`sce_debug'"== "yes" {
			gen item_TVA=Tax_TVA if codpr==334
			local addss item_TVA
}


collapse (sum) Tax_TVA direct_TVA indirect_TVA Tax_TVA_informal3 depan  `list_item_stats' `addss'  , by(hhid) // variable to debug medici medici_dir medici_indir medici_inf exempted_potential item_TVA

* tool to debug we want to compute aggregate stats 
 if "`sce_debug'"== "yes" {
	
	merge 1:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta", keepusing (hhweight)
	collapse (sum) Tax_TVA direct_TVA indirect_TVA item_TVA [iw=hhweight] //
	foreach v in Tax_TVA direct_TVA indirect_TVA item_TVA { 
	replace `v'=`v'/1000000000
	}

	list
	exit 

}


if $devmode== 1 {
sort hhid
save "${tempsim}/Final_TVA_Tax.dta", replace 
}
tempfile Final_TVA_Tax
save `Final_TVA_Tax' 



exit 

*XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
