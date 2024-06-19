


import excel "$presim/IO_Matrix.xlsx", sheet("IO_matrix") firstrow clear

*Define fixed sectors 
local thefixed $sect_fixed 

gen fixed=0
foreach var of local thefixed {
	replace fixed=1  if  sector==`var'
}

*Shock
gen shock=-0.1 if sector==8   //10% shock to electricity price 
replace shock=0  if shock==.

*Indirect effects 
des sect_*, varlist 
local list "`r(varlist)'"

costpush `list', fixed(fixed) priceshock(shock) genptot(elec_tot_shock) genpind(elec_ind_shock) fix
	
drop sect_*

export excel "$xls_out", sheet("ind_elec_10p", modify ) first(variable)







