


/*
Slides for Transfers 



*/





import excel "$xls_sn", sheet(allRef_2020_trans_pmt) firstrow clear 


// Marginal contributions

** effects on poverty - Poverty Prevalence
preserve
 // total
		sum value if concat=="ymp_pc_fgt0_zref_ymp_."
		assert r(N)==1
		local pre = r(mean)
		sum value if concat=="ymp_inc_dirtransf_total_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_1 = round(100*(`post'-`pre'),0.0001)
 
 // Cantines
		sum value if concat=="ymp_inc_am_Cantine_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_2 = round(100*(`post'-`pre'),0.0001) 
 
 // NAFA (Social transfers - BNSF for Senegal)
		sum value if concat=="ymp_inc_am_BNSF_fgt0_zref_ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_3 = round(100*(`post'-`pre'),0.0001)  
 
** effect on inequality - GINI
 // total
		sum value if concat=="ymp_pc_gini__ymp_."
		assert r(N)==1
		local pre = r(mean)
		sum value if concat=="ymp_inc_dirtransf_total_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_4 = round(100*(`post'-`pre'),0.0001)
 
 // Cantines
		sum value if concat=="ymp_inc_am_Cantine_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_5 = round(100*(`post'-`pre'),0.0001) 
 
 // NAFA (Social transfers - BNSF for Senegal)
		sum value if concat=="ymp_inc_am_BNSF_gini__ymp_."
		assert r(N)==1
		local post = r(mean)
		local effect_6 = round(100*(`post'-`pre'),0.0001)  
		
	// Create a matrix with the locals created	
		clear 
		set obs 6
		gen mar =.
		forval n=1/6{
			replace mar = `effect_`n'' in `n'
		}
		
	* export to excel 
		global cell = "A5"
		export excel using "$xls_out", sheet("Transfers", modify) first(variable) cell($cell) keepcellfmt
restore




// Absolute incidence

preserve
		keep if measure=="benefits" 
		gen keep = 0
		foreach var in am_Cantine am_BNSF dirtransf_total {
			replace keep = 1 if variable == "`var'_pc"
		}	
		keep if keep ==1 

		replace variable=variable+"_ymp" if deciles_pc!=.
		replace variable=variable+"_yd" if deciles_pc==.

		egen decile=rowtotal(yd_deciles_pc deciles_pc)

		keep decile variable value
		rename value v_

		reshape wide v_, i(decile) j(variable) string
		drop if decile ==0
		keep decile *_yd

		foreach var in v_am_Cantine_pc_yd v_am_BNSF_pc_yd v_dirtransf_total_pc_yd {
			egen ab_`var' = sum(`var')
			gen in_`var' = `var'*100/ab_`var'
		}

		ren (in_v_am_Cantine_pc_yd in_v_am_BNSF_pc_yd in_v_dirtransf_total_pc_yd) (Abs_Cantine Abs_BNSF Abs_total)
		*ren in_v_dirtransf_total_pc_yd Absolute_inc 
		keep Abs_*  

		global cell = "B19"
		export excel using "$xls_out", sheet("Transfers", modify) first(variable) cell($cell) keepcellfmt
restore

// Relative incidence
preserve 
			keep if measure=="netcash" 
			gen keep = 0
			foreach var in am_Cantine am_BNSF dirtransf_total {
				replace keep = 1 if variable == "`var'_pc"
			}	
			keep if keep ==1 

			replace variable=variable+"_ymp" if deciles_pc!=.
			replace variable=variable+"_yd" if deciles_pc==.

			egen decile=rowtotal(yd_deciles_pc deciles_pc)


			keep decile variable value
			replace value = value*(100)
			rename value v_

			reshape wide v_, i(decile) j(variable) string
			drop if decile ==0
			keep *_yd
			ren (v_am_Cantine_pc_yd v_am_BNSF_pc_yd v_dirtransf_total_pc_yd) (Rel_Cantine Rel_BNSF Rel_total)
			*ren v_dirtransf_total_pc_yd Relative

			global cell = "B33"
			export excel using "$xls_out", sheet("Transfers", modify) first(variable) cell($cell ) keepcellfmt

restore





// Total expenses

global sheetname "Ref_2020_trans_pmt"
	global nsim 1		
		
		
		
	* Gen macro for results organization

	global letters "a b c d e f g h i j k l"
	
	gen nsim = length("${sheetname}") - length(subinstr("${sheetname}", " ", "", .)) + 1
	qui sum nsim
	global nsim "`r(mean)'"
	drop nsim
	
	
	* Import and save simulation results
	forvalues i=1/$nsim {	
		
		global var : word `i' of $sheetname
		import excel "$xls_sn", sheet("all${var}") firstrow clear
		global label : word `i' of $letters
		gen sim = `i'
		gen sim_s = "${var}"
		tempfile Sim`i'
		save `Sim`i''	
	}


	* Append simulation results
	use `Sim1', clear

	forvalues i = 2/$nsim {
		append using `Sim`i''
	}

	
	save "$data_out/AllSim.dta", replace

		
	use "$data_out/AllSim.dta", clear

	* Names
	global variable "dirtransf_total_pc"
	global quintil "1 2 3 4 5"

	replace variable = "a_" + variable if variable == "dirtransf_total_pc"

	* Filters
	keep if inlist(variable, "a_dirtransf_total_pc")
	keep if measure == "benefits"

	* 1. Grouping by quintil
	recode deciles_pc (1=1) (2=1) (3=2) (4=2) (5=3) (6=3) (7=4) (8=4) (9=5) (10=5), generate(quintil)

	collapse (sum) value, by(sim variable quintil)

	drop if quintil == 0

	replace value = value/1000000000

	* Generate matrix
	global count ""
	global rownames ""
	mat R = J(1,5,.)

	forvalues i=1/$nsim {	
		
		global count "$count A`i' \"
		
		local sim : word `i' of $sheetname
		global rownames "$rownames `sim'_$variable"
		
		tab variable quintil [iw = value] if sim == `i', matcell(A`i')
		
		sum value if sim == `i' & variable == "c_dirtransf_total_pc"		
		if (r(max) == 0) mat A`i' = A`i' \ R
	}	

	global count = substr("$count", 1, length("$count")-1)
	
	mat A = $count
	mat colnames A = $quintil 
	*mat rownames A = $rownames

	matlist A

	* Print 
	putexcel set "${xls_out}", sheet("Transfers") modify
	putexcel A52 = ("Revenue") A53 = matrix(A), names

	shell ! "$xls_out"

		
		
		
	* 2. Comparison reforms on principal indicators
	use "$data_out/AllSim.dta", clear

	keep concat yd_deciles_pc measure value _population variable deciles_pc all reference sim*

	labmask sim, values(sim_s)

	global variable "ymp_pc yn_pc yd_pc yc_pc yf_pc"
	global reference "zref line_1 line_2 line_3"
	global measure "fgt0 fgt1 fgt2 gini theil"

	gen income = ""
	
	forvalues i = 1/5 {
		local l : word `i' of $letters
		local v : word `i' of $variable
		replace income = "`l'_" + variable if variable == "`v'"
		di "`l' - `v'"
	}
	

	* Filter indicators of interest
	gen test = .
	foreach i in $variable {
		foreach j in $measure {
			replace test = 1 if (variable == "`i'" &  measure == "`j'") 
		}
	}
	tab test

	keep if test == 1

	
	* Generate matrix
	global count ""
	global rownames ""
	forvalues i=1/$nsim {	
		
		global count "$count B0`i', A`i' \"
		
		local sim : word `i' of $sheetname
		global rownames "$rownames `sim'_$variable"
		
		tab income measure [iw = value] if sim == `i' & reference == "", matcell(A`i')
		tab income measure [iw = value] if sim == `i' & reference == "zref", matcell(B0`i')
		
	}	
		
	global count = substr("$count", 1, length("$count")-1)
		
	mat A = $count
	mat colnames A = $measure 
	mat rownames A = $rownames
	
	matlist A
	 
	putexcel set "${xls_out}", sheet("Transfers") modify
	putexcel A57 = ("Principal indicators - Simulations") A58 = matrix(A), names
			
		
	**** --------------------------------------- END --------------------- ---- ***	
		

// Simulation 
