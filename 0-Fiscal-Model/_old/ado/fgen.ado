/*====================================================================
project:       Fast egen function
Author:        Andres Castaneda, Paul Corral (for now....)
Dependencies:  The World Bank
----------------------------------------------------------------------
Creation Date:    30 Jun 2017 - 08:53:17
Modification Date:   
Do-file version:    01
References:          
Output:             
====================================================================*/

/*====================================================================
0: Program set up
====================================================================*/
version 14.0
cap program drop fgen
	program define fgen, sortpreserve 
		syntax anything(name=cmd equalok) [if] [in] [aw fw/] [, ///
		BY(varlist) TYPEs(string) quad                          ///
		]
		
		marksample touse
		qui {		
			/*====================================================================
			1: 		consistency errors
			====================================================================*/
			
			*-----------------1.1: equal sign
			tokenize "`cmd'", parse("=")
			if ("`2'"!="=") {
				noi disp as err "equal sign required"
				error 198
			}
			
			*-----------------1.2: new var
			local newvar = strtrim("`1'")
			
			*-----------------1.3: function
			tokenize "`3'", parse("()")
			if ("`2'" != "(" | "`4'"!= ")") {
				noi disp as err "you must follow the syntax  fgen {it:[type] newvar = fcn(arguments)}"
				error 198
			}
			local func "`1'"
			
			*-----------------1.4: arguments
			local var "`3'"
			confirm numeric var `var'
			
			
			//  Consistency between Numer of new vars and arguments
			if ( wordcount("`newvar'") == wordcount("`var'") ) {
				confirm new var `newvar'
				local newvars "`newvar'"
			}
			else if (wordcount("`newvar'") == 1 & wordcount("`var'") > 1) {
				foreach v of local var {
					confirm new var `newvar'_`v'
					local newvars "`newvars' `newvar'_`v'"
				}
			}
			else {
				noi disp as err "in the syntax fgen {it:[type] newvar = fcn(arguments)}, the number of {it:newvar} must be equal to 1 or to the number {it:arguments}"
				error 198
			}
			
			*-----------------1.5: Types
			if ("`types'" == "") {
				foreach v of local var {
					local newvartype "`newvartype' `: type `v''"
				}
			}
			else {
				if (wordcount("`types'") == wordcount("`var'")) {
					local newvartype "`types'"
				}
				else {
					noi disp as err "the number of types must be the same as the number of arguments"
					error 198
				}
			}
			*-----------------1.6: Weights
			if ("`weight'"=="") {
				tempvar wt
				qui gen `wt' = 1
				local wtvar "`wt'"
			}
			else local wtvar "`exp'"
			
			/*===============================================================
			2: arguments to MATA
			=================================================================*/
			
			*-----------------2.1: fgen function
			if (inlist("`func'", "max", "min")) local func "`quad'col`func'"
			if ("`func'" == "sum") local func "_msum"
			cap mata: func=&`func'()
			if (_rc!=0) {
				noi di as error "`func' is not a MATA function"
				error _rc
			}
			
			*----------------2.2: sort data and create groups
			tempvar g
			sort `touse' `by'
			quietly by `touse' `by': gen `type' `g'=1 if _n==1 & `touse'
			replace `g'=sum(`g')
			replace `g'=. if `touse'!=1
			
			*---------------2.3:  Send data to MATA
			mata: Vars  = st_data(., tokens("`var'"), "`touse'")
			mata: Byvar = st_data(., "`g'", "`touse'")
			mata: WTs   = st_data(., "`wtvar'", "`touse'")
			
			
			*---------------2.4:  Ran MATA functions
			* local newvars    = strtrim("`newvars'")
			* local newvartype = strtrim("`newvartype'")
			mata: _fgen(Vars, Byvar, WTs, func)
			
		}		
	end
	
	
	/*====================================================================
	3: MATA
	====================================================================*/
	
	mata:
	mata drop _fgen*()
	void _fgen(real matrix Vars, real colvector Byvar, real colvector WTs,
	pointer(function) scalar func) {
		
		// function using loops. (there should be a faster way)
		info = panelsetup(Byvar, 1)
		NewVars = J(rows(Vars), cols(Vars), .)
		hh=rows(info)
		
		for (i = 1; i<=hh; i++ ) {
			pp = info[i, 1],. \ info[i, 2], .
			rr = rows(Vars[|pp|])
			
			// Apply corresponding function
			if (regexm(st_local("func"), "sum")) {
				NewVars[|pp|] = J(rr, 1, (*func)(Vars[|pp|]:*WTs[|pp|]))	
			}
			else if (regexm(st_local("func"), "mean")) {
				NewVars[|pp|] = J(rr, 1, (*func)(Vars[|pp|], WTs[|pp|]))
			}
			else  NewVars[|pp|] = J(rr, 1, (*func)(Vars[|pp|]))
		}
		
		type   = tokens(st_local("newvartype"))
		nvarnames = tokens(st_local("newvars"))
	  
		obs = st_nobs() - rows(NewVars) + 1
		
		nvar = st_addvar(type, nvarnames)
		st_store((obs,.), nvar, NewVars)
	}
	
	function _msum(numeric matrix Z) {
		if (regexm(st_local("quad"), "quad")) {
			return(quadcolsum(Z))
		}
		else return(colsum(Z))
	} 
end

*--------------------3.1:


*--------------------3.2:

// , string scalar newvar, string scalar type
exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:

*************************
* create sample database
*************************
drop _all
set obs 1000000
gen b1    = round(runiform(0,3)) 
gen b2    = round(runiform(0,5)) 
gen b3    = round(runiform(0,7))
gen touse = round(runiform(0,1))

gen c1 = cond(b1==0, "hola",      /*
*/ cond(b1==1, "como estas",      /*
*/ cond(b1==2, "muy bien", "chao")))

gen c2 = cond(b2==0, "hola",      /*
*/ cond(b2==1, "como estas",      /*
*/ cond(b2==2, "muy bien", /*
*/ cond(b2==3, "que bueno", /*
*/ cond(b2==4, "si, muy bueno", "nos vemos")))))

gen var1 =  runiform(-10,100)
gen var2 =  runiform(-10,100)
gen var3 =  runiform(-10,100)
gen wt   =  runiform(0,13)

**************************************
//  Multiple variables
**************************************
timer on 1
fgen a b c  = mean(var1 var2 var3) if (b3 < 5) [w = wt] , by(b1 b2 b3) // Different names
timer off 1

timer on 2
forval x=1/3{
	egen new`x' = mean(var`x') if (b3 < 5), by(b1 b2 b3)
}

timer off 2

timer list
fgen fmean  = mean(var1 var2 var3) if (b3 < 5) [w = wt] , by(b1 b2 b3) // same prefix
exit

egen emaxvar = max(var), by(b1 b2 b3)

// using strings in by
fgen fsmaxvar = max(var), by(c1 c2 b3)
egen esmaxvar = max(var), by(c1 c2 b3)


