/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: 	JuanP. Baquero
* Date: 		11 Nov 2020
* Title: 	Generate Output for Simulation
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
*Note: Each output goes in long format  to a hidden sheet call all_`sheetnm'

Version 2. 
	- Change the refrence income for marginal contributions for all categories
	- Minor: commenting do-file and Making comments and Pendent
	- Added a new category for subsidies (before were together with transfers, not correct because their marginal contributions are measured differently

	
Pendent : 
_---------------------------------------------------------------------------------*/

if $save_scenario == 1 {	
	global sheetname "${scenario_name_save}"
}
if $save_scenario == 0 & $load_scenario == 1 {	
	global sheetname "${scenario_name_load}"
}
if $load_scenario == 0 & $save_scenario == 0 {	
	global sheetname "User_def_sce"
}

*Macros for household values 
	
	local tax dirtax_total income_tax trimf /*csp_ipr csp_fnr*/ csh_css csh_ipm csh_mutsan new_poor old_poor sscontribs_total
	local indtax indtax_total excise_taxes TVA_direct TVA_indirect Tax_TVA
	local inkind education_inKind Sante_inKind am_sesame am_moin5 am_cesarienne am_CMU_progs inktransf_total
	local transfer dirtransf_total am_bourse am_Cantine am_BNSF am_subCMU income_tax_reduc
	local subsidies subsidy_total subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_fuel subsidy_eau subsidy_eau_direct subsidy_eau_indirect subsidy_agric subsidy_elec
	*local list_item_stats " rice water_elect hosp exempted aliment_exem aliment_exem_infor non_aliment_exem non_aliment_exem_infor" // we repeat this line in order to make this do-file independent 

	local income ymp yn yd yc yf /*depan*/ // before I have a local here but it presented some problems 
	local concs `tax' `indtax' `transfer' `inkind' `income' `subsidies'
	
	*sum `tax' `indtax' `transfer' `inkind' `subsidies'

*Macros at per-capita values 
	foreach x in tax indtax inkind transfer income concs subsidies {
		local `x'_pc
		foreach y of local `x' {
			local `x'_pc ``x'_pc' `y'_pc 	
		}
	}
*Other macros 
	*local rank ymp_pc
	local pline zref line_1 line_2 line_3
	
	
*===============================================================================
		*Produce Concentration by centile_pc
*===============================================================================

foreach rank in ymp yn yd yc yf {
	use "$data_out\output", clear

	foreach x of local concs_pc {
		covconc `x' [aw=pondih] , rank(`rank'_pc)	//gini and concentration coefficients
		local _`x' = r(conc)
	}
	
	groupfunction [aw=pondih], sum(`concs_pc') by(`rank'_centile_pc) norestore
	qui count
	local _1 =r(N)
	local nnn=`_1'+ 1  //add one more obs, the total obs goes from 100 to 101
	set obs `nnn'
	replace `rank'_centile_pc = 0 in `nnn'
	
	sort `rank'_centile_pc
	putmata x = (`concs_pc') if `rank'_centile_pc!=0, replace 
	mata: x = J(1,cols(x),0) \ x  //generate a constant row, add to the top
	mata: x = x:/quadcolsum(x)  //divide each element by the column total
	mata: for(i=1; i<=cols(x);i++) x[.,i] = quadrunningsum(x[.,i])  //replace exisiting matrix by new elements
	
	getmata (`concs_pc') = x, replace
	
	qui count
	local _1 =r(N)
	local nnn=`_1'+ 1 //add one more obs, the total obs goes to 102
	set obs `nnn'
	
	replace `rank'_centile_pc = 999 in `nnn'
	foreach x of local concs_pc {
		replace `x' = `_`x'' in `nnn'  //replace the last observation with gini/concentration coefficient
	}	
	order `rank'_centile_pc, first
	
	export excel using "$xls_sn", sheet("conc`rank'_${sheetname}") sheetreplace first(variable)
	*export excel using "$xls_sn", sheet("concentration") sheetreplace first(variable)
	
}

*===============================================================================
		*Netcash Position
*===============================================================================

{
* net cash ymp

	use "$data_out\output", clear
	
	foreach x in `tax' `indtax'  {
		gen share_`x'_pc= -`x'_pc/ymp_pc
	}		
	
	foreach x in `transfer' `inkind' `subsidies' {
		gen share_`x'_pc= `x'_pc/ymp_pc
	}
		
	*replace share_snit_hh_ae = - share_snit_hh_ae
	keep deciles_pc share* pondih	
		
	groupfunction [aw=pondih], mean (share*) by(deciles_pc) norestore
	
	reshape long share_, i(deciles_pc) j(variable) string
		gen measure = "netcash" 
		rename share_ value
	
	tempfile netcash_ymp
	save `netcash_ymp'

* net cash yd 	
	
	use "$data_out\output", clear
	
	foreach x in `tax' `indtax'  {
		gen share_`x'_pc= -`x'_pc/yd_pc
	}		
	
	foreach x in `transfer' `inkind' `subsidies' {
		gen share_`x'_pc= `x'_pc/yd_pc
	}
	
	*replace share_snit_hh_ae = - share_snit_hh_ae
	keep yd_deciles_pc share* pondih	
		
	groupfunction [aw=pondih], mean (share*) by(yd_deciles_pc) norestore
	
	reshape long share_, i(yd_deciles_pc) j(variable) string
		gen measure = "netcash" 
		rename share_ value
	
	tempfile netcash_yd
	save `netcash_yd'
}		

*===============================================================================
		*Distributional indicators Gini, Theil, and FGT measures
		*Generate Income Concepts for Marginal Contribution
*===============================================================================

*run "$theado\sp_groupfunction.ado"

use "$data_out\output",  clear
		
		*Gabriela's 2022 suggestions for marginal contribution calculations:
		// (DV) For taxes ymp_pc is the counterfactual withouth the policy
		// (DV) For indirect taxes yd_pc is the counterfactual withouth the policy
		// (DV) For direct transfers ymp_pc is the counterfactual withouth the policy 
		// (DV) For subsidies yd_pc is the counterfactual withouth the policy 
		// (DV) For in-kind yc_pc is the counterfactual withouth the policy 
		
		//(AGV) I will generate all possible combinations, and fix these suggestions in Excel (allowing us to change them easily there)

*List of all new marginal contributinos store in income
local income2 ""

local aux1 `tax' `indtax'
foreach var of local aux1{
	replace `var' = -`var'
	replace `var'_pc = -`var'_pc
}

local aux2 `tax' `indtax' `transfer' `subsidies' `inkind'
foreach inc in ymp yn yd yc {   //(AGV) I'm excluding final income because it does not make sense contributing to that
	foreach var of local aux2 {
		gen `inc'_inc_`var'=`inc'_pc+`var'_pc
		local income2 `income2' `inc'_inc_`var'   // Store incomes to marignal contribution calculation
	}
}

foreach var of local aux1{
	replace `var' = -`var'
	replace `var'_pc = -`var'_pc
}

sp_groupfunction [aw=pondih], gini(`income_pc' `income2') theil(`income_pc' `income2') poverty(`income_pc' `income2') povertyline(`pline')  by(all) 
tempfile poverty
save `poverty'

*===============================================================================
		*Mobility matrix:Trans. Matrix (with respect to the baseline) 
*===============================================================================
	
use "$data_out\output_ref",  clear	
	
// we have to manually generate percentiles 

sort yc_pc yc_deciles_pc

drop if yc_deciles_pc==.

*br  yc_pc yc_deciles_pc

gen here=1  if  yc_deciles_pc[_n] != yc_deciles_pc[_n-1]

gen here_II=1  if  yc_deciles_pc[_n] != yc_deciles_pc[_n+1]

*gen pctiles_II=here*yc_pc

*replace pctiles_II=0 in 1

gen pctiles_III=here_II*yc_pc

*bys yc_deciles_pc: egen pctiles_l=max(pctiles_II)
bys yc_deciles_pc: egen double pctiles_u=max(pctiles_III) 

drop here* pctiles_II pctiles_III

preserve 

collapse (max) yc_deciles_pc , by ( pctiles_u)
replace pctiles_u=pctiles_u+0.05

gen double pctiles_l=pctiles_u[_n-1]
replace pctiles_l=0 if  pctiles_l==.


levelsof pctiles_u , local(scalarsU)
levelsof pctiles_l , local(scalarsL)

restore 

// done with the percentiles

keep hhid yc_deciles_pc  

rename yc_deciles_pc yc_deciles_pc_ref

// merge simu base 

merge 1:1 hhid using "$data_out\output" , keepusing(pondih yc_pc) nogen

// clasify in baseline percentiles 

tokenize `scalarsL'
local j=1
gen yc_deciles_pc=.
foreach ii of local scalarsU {

replace yc_deciles_pc=`j'   if    yc_pc>``j''  & yc_pc<=`ii'

local j=`j'+1 

}


gen value=1

collapse (sum) value [iw=pondih], by(yc_deciles_pc_ref yc_deciles_pc)

tempfile transm

save `transm'

mata: A=(1,2,3,4,5,6,7,8,9,10)'

mata: S=(J(10,1,A),sort(J(10,1,A),1))

mata: st_matrix("S",S)

clear 

svmat S 

rename S1 yc_deciles_pc_ref

rename S2 yc_deciles_pc

merge 1:1 yc_deciles_pc_ref yc_deciles_pc  using `transm' , nogen

replace value=0 if value==.


gen concat= "transition" + 	string(yc_deciles_pc_ref) +"_" + string(yc_deciles_pc)
	
keep concat value	
	
tempfile trans	
	
save `trans'	

*===============================================================================
		*SP Indicators 
*===============================================================================

	
	* All 
* benefits, coverage beneficiaries by all	
	use "$data_out\output",  clear	

	sp_groupfunction [aw=pondih], benefits(`concs_pc') mean(`concs_pc') coverage(`concs_pc') beneficiaries(`concs_pc')  by(all)
	gen deciles_pc=0
	tempfile theall
	save `theall'

* benefits, coverage beneficiaries by deciles (ymp)	
	use "$data_out\output",  clear
	
	sp_groupfunction [aw=pondih], benefits(`concs_pc') mean(`concs_pc') coverage(`concs_pc') beneficiaries(`concs_pc')  by(deciles_pc)
*adding previous ones 	
	append using `poverty'
	append using `netcash_ymp'
	append using `theall'	
		
	gen concat = variable +"_"+ measure+"_" +reference+"_ymp_"+string(deciles_pc)
	order concat, first
	
	tempfile aux1
	save `aux1'
* benefits, coverage beneficiaries by yd
	use "$data_out\output",  clear	
	
	
	sp_groupfunction [aw=pondih], benefits(`concs_pc') mean(`concs_pc') coverage(`concs_pc') beneficiaries(`concs_pc')  by(yd_deciles_pc)
	
	
	append using `netcash_yd'
	
	gen concat = variable +"_"+ measure+"_"+"_yd_"+string(yd_deciles_pc)
	order concat, first
	
	append using `aux1'
	append using `trans'
	
	
	export excel "$xls_sn", sheet("all${sheetname}" ) sheetreplace first(variable)
	*export excel "$xls_sn", sheet("all" ) sheetreplace first(variable)


noi dis "{opt .......... Scenario ${sheetname} processed and saved! }"
