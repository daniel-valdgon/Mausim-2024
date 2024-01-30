

global path "C:\Users\wb419055\OneDrive - WBG\West Africa\Mauritania\MauSim\01_data\01_raw\EPCV_2019\Datain"


use "$path/pivot2019.dta" , clear 


gen depan_communic=dep if Prod==365 /// SM card
			| Prod==449 | Prod==450 | Prod==451 /// mobile phones 
			| Prod==367 | Prod==368 | Prod==369 | Prod==370 | Prod==371 /// internet
				
gen share_com=depan_communic




collapse (sum) dep share_com, by(hid)
replace share_com=share_com/dep



merge 1:1 hid using "$path/menage_pauvrete_2019.dta", keep(matched)

/*Test of how different is consumption, seems to be because of the deflator*/
gen con_pc=dep/hhsize
gen t=con_pc/pcexp
replace t=round(t,0.0001)

apoverty pcexp [aw= hhweight*hhsize],varpl(zref)

sum share_com, d
*replace share_com=`r(p99)' if share_com>`r(p99)'
gen pc_exp_com=pcexp*share_com
	

preserve 	
	
	quantiles pcexp [aw=hhweight*hhsize], n(5) gen(q) 
	
	gen d_com=pc_exp_com>0
	gen share_com_cond=share_com if pc_exp_com>0
	
	collapse (mean) share_com_cond share_com d_com [aw=hhweight*hhsize], by(q)

restore 

*Compute VAT taxes under baseline 
gen baseline_VAT=(-1)*0.16*pc_exp_com/(1.16)

*Compute new taxes
gen impact2=0.18*pc_exp_com/(1.16)
gen impact3=.23*pc_exp_com/(1.16)


*Compute the difference, additional taxes paid
egen cost2=rowtotal(impact2 baseline_VAT)
egen cost3=rowtotal(impact3 baseline_VAT)


*compute new consumption 
gen pcexp2=pcexp-cost2
gen pcexp3=pcexp-cost3

apoverty pcexp [aw= hhweight*hhsize],varpl(zref)
apoverty pcexp2 [aw= hhweight*hhsize],varpl(zref)
apoverty pcexp3 [aw= hhweight*hhsize],varpl(zref)


ainequal pcexp [aw= hhweight*hhsize]

ainequal pcexp2 [aw= hhweight*hhsize],
ainequal pcexp3 [aw= hhweight*hhsize],



gen d=pcexp>zref
gen d2=pcexp2>zref
gen d3=pcexp3>zref
ta d d3 


gen r2=100*(pcexp2/pcexp-1)
gen r3=100*(pcexp3/pcexp-1)

quantiles pcexp [aw=hhweight*hhsize], n(5) gen(q) 
	
collapse (mean) r2 r3  [aw=hhweight*hhsize], by(q)
