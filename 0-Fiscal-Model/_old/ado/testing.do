
*===============================================================================	
//Macro preamble
*===============================================================================	
local _ee_ssc      $emp_ssc_ee
local _ee_health   $emp_health_ee
local _er_ssc      $emp_ssc_er
local _er_health   $emp_health_er
local _self_ssc    $self_ssc_ee
local _self_health $self_health_ee

local _fixed       $fixed
local _spousal     $spousal
local _dependent   $dependentemployee
local _child       $perchild
local _autonomo    $autonomous
  
local _trates      $rates
local _mintholds   $minholds

tokenize `_mintholds'
local _maxthold1 = `2'

local _ctrans  = $trans
local _ramt = $amt

local mygross g_inc_l_3 g_inc_l_2 g_inc_l_1 g_inc_l_4 g_inc_l_5 g_inc_ol_1 ///
g_inc_ol_2 g_inc_ol_3 g_inc_ol_4 g_inc_nl_1 g_inc_nl_2 g_inc_nl_5 ///
g_inc_nl_6 g_inc_nl_7

*===============================================================================	
// Bring in data
*===============================================================================	

use "$data_tool\EPH_2017.dta", clear
merge 1:1 hhid componente using "$data_tool\EPH_2017_gross.dta"
	drop if _m==2
	drop _m
	
	drop gross_wage gross_market_income_* 
	drop if pondih==0
	
*===============================================================================	
// Get self employment income and dependent labor income
*===============================================================================	
	gen double t_wage_inc     = g_inc_l_3 if retiree_discount==1
	replace t_wage_inc    = 0 if missing(t_wage_inc)
	
	gen double nt_wage_inc    = g_inc_l_3 if retiree_discount!=1
	replace nt_wage_inc   = 0 if missing(nt_wage_inc)
	
	egen double t_self_inc    = rsum(g_inc_l_1 g_inc_l_2) if health_pami==1
	replace t_self_inc    = 0 if missing(t_self_inc)

	egen double nt_self_inc = rsum(g_inc_l_1 g_inc_l_2) if health_pami!=1
	replace nt_self_inc    = 0 if missing(nt_self_inc)
		
		

*===============================================================================	
//	SSC 
*===============================================================================
	gen double c_ssc     = 0
	gen double c_health  = 0
	
	
	foreach x in ssc health{
		replace c_`x' = t_wage_inc*(`_ee_`x''+`_er_`x'') if !missing(t_wage_inc)
		replace c_`x' = c_`x' + t_self_inc*(`_self_`x'') if !missing(t_self_inc)
	}
	
	foreach x in t_wage_inc t_self_inc{
		replace `x' = `x' - c_ssc    if !missing(c_ssc)
		replace `x' = `x' - c_health if !missing(c_health)
	}

*===============================================================================	
//	Indentify potential deductions
*===============================================================================
	gen dep_emp    = t_wage_inc!=0 & !missing(t_wage_inc)
	gen autonomous = t_self_inc!=0 & !missing(t_self_inc)
	gen spousal    = partner!=0 & partner!=999 & !missing(partner)
	
	//identify richest person in family, this person will claim kids
	egen double richest  = max(t_wage_inc+t_self_inc+(1e-8)*componente), by(hhid fam_id)
	replace richest      = (richest==(t_wage_inc+t_self_inc+(1e-8)*componente))
	
	//Numkids for the richest...
	egen numkids    = sum(age<18), by(hhid fam_id)
	replace numkids = 0 if richest!=1
	
	
*===============================================================================	
//	Deductions
*===============================================================================
	gen double deduction = `_fixed' + `_spousal'*[spousal==1] + `_child'*[numkids] + ///
	`_autonomo'*[autonomous==1] + `_dependent'*[dep_emp==1]		
	
*===============================================================================	
//	Taxes
*===============================================================================
	
	egen double tax_inc = rsum(t_wage_inc t_self_inc)
	
	dirtax tax_inc, grossinput rates(`_trates') tholds(`_mintholds') gen(net_labor_inc) taxfree(deduction) ///
		
	gen double tax_paid = tax_inc - net_labor_inc
	
*===============================================================================
//Simulate universal cash transfer
*===============================================================================
	
tempfile _base
save `_base'
	
	//Unemployed
	gen _1 = lfstat==2
	//Salaried with retiree discount, no domestic service
	gen _2 = salaried_iw==1 & domestic_emp!=1
	//Self employed no health pami
	gen _3 = health_pami!=1 & self_emp==1
	//Informal domestic workers
	gen _4 = domestic_emp==1 & retiree_discount==0
	//Family worker, no pay
	gen _5 = occupation==4
	//Inactive no pension
	gen _6 = lfstat==3 & (inc_nl_1==0 | !missing(inc_nl_1))
	//To self employed
	gen _7 = occupation==2 & tax_inc<`_maxthold1' 

	gen eligible2 = (_1==1|_2==1|_3==1|_4==1|_5==1|_6==1|_7==1) & age>=18
		
	gen exclusion1 = lfstat==1 & occupation==3 & retiree_discount==1 & age>=18
	
		groupfunction, max(eligible2 exclusion1) first(fam_kids fam_size pondih) by(fam_id hhid) norestore

	//Indicate beneficiary
	gen beneficiary_family  = eligible2==1 & exclusion1!=1 & fam_kids>0 & fam_kids!=.
	
	//Randomly sample until we hit target...
	wsample beneficiary_family if beneficiary_family==1 [aw=pondih], value(`_ramt') newvar(_x)
	replace beneficiary_family = _x
	drop _x

	//Benefit per CAPITA
	gen double benefit_ctrans = (fam_kids*(beneficiary_family)*`_ctrans')/fam_size
	
	keep hhid fam_id beneficiary_family benefit_ctrans
	
	merge 1:m hhid fam_id using `_base'
		drop if _m==1
		drop _m
		

*===============================================================================
//Generate income concepts
*===============================================================================
	egen double gross_mkt_inc = rsum(g_inc_l_3 g_inc_l_2 g_inc_l_1 g_inc_l_4
		



