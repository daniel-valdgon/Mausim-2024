

*Load behavioral responses (THis is not part of the tool so that it the reasons we read from TVA_Raw and are part of pre_sim)
import excel using "$xls_sn", sheet(TVA_raw) clear first
drop if codpr==.
tempfile tmp
save `tmp'

* All codeprod available in the data 
use "$data_sn/Senegal_consumption_all_by_product.dta", clear
collapse (sum) depan , by(codpr)
gen poor=1 in 1
replace  poor=0 in 2
fillin poor codpr
drop _fillin depan

*adding elasticities 
merge m:1 codpr using `tmp', keep(master matched) // same elasticities for poor an non-poor 

clonevar factor_behavioral= elasticities

/* Validity test 
*Manual elasticities to double check 
gen factor_behavioral=.
replace factor_behavioral=0.92188 if codpr==1
replace factor_behavioral=0.92188 if codpr==2
replace factor_behavioral=0.92188 if codpr==3
replace factor_behavioral=0.92188 if codpr==4
replace factor_behavioral=0.92188 if codpr==5
replace factor_behavioral=0.92188 if codpr==6
replace factor_behavioral=0.92188 if codpr==7
replace factor_behavioral=0.92188 if codpr==8
replace factor_behavioral=0.92188 if codpr==9
replace factor_behavioral=0.92188 if codpr==10
replace factor_behavioral=0.92188 if codpr==11
replace factor_behavioral=0.88552 if codpr==23
replace factor_behavioral=0.88552 if codpr==24
replace factor_behavioral=0.88552 if codpr==25
replace factor_behavioral=0.88552 if codpr==26
replace factor_behavioral=0.88552 if codpr==27
replace factor_behavioral=0.88552 if codpr==28
replace factor_behavioral=0.88552 if codpr==29
replace factor_behavioral=0.88552 if codpr==30
replace factor_behavioral=0.88552 if codpr==31
replace factor_behavioral=0.88552 if codpr==32
replace factor_behavioral=0.88552 if codpr==33
replace factor_behavioral=0.88552 if codpr==34
replace factor_behavioral=0.86698 if codpr==35
replace factor_behavioral=0.86698 if codpr==36
replace factor_behavioral=0.86698 if codpr==37
replace factor_behavioral=0.86698 if codpr==38
replace factor_behavioral=0.86698 if codpr==39
replace factor_behavioral=0.86698 if codpr==40
replace factor_behavioral=0.86698 if codpr==41
replace factor_behavioral=0.87382 if codpr==44
replace factor_behavioral=0.87382 if codpr==52
replace factor_behavioral=0.90658 if codpr==72
replace factor_behavioral=0.90658 if codpr==73
replace factor_behavioral=0.90658 if codpr==74
replace factor_behavioral=0.90658 if codpr==75
replace factor_behavioral=0.90658 if codpr==76
replace factor_behavioral=0.90658 if codpr==77
replace factor_behavioral=0.90658 if codpr==78
replace factor_behavioral=0.90658 if codpr==79
replace factor_behavioral=0.90658 if codpr==80
replace factor_behavioral=0.90658 if codpr==81
replace factor_behavioral=0.90658 if codpr==82
replace factor_behavioral=0.90658 if codpr==83
replace factor_behavioral=0.90658 if codpr==84
replace factor_behavioral=0.90658 if codpr==85
replace factor_behavioral=0.90658 if codpr==86
replace factor_behavioral=0.90658 if codpr==87
replace factor_behavioral=0.90658 if codpr==88
replace factor_behavioral=0.90658 if codpr==89
replace factor_behavioral=0.90658 if codpr==90
replace factor_behavioral=0.90658 if codpr==92
replace factor_behavioral=0.90658 if codpr==93
replace factor_behavioral=0.90658 if codpr==94
replace factor_behavioral=0.90658 if codpr==95
replace factor_behavioral=0.90658 if codpr==96
replace factor_behavioral=0.90658 if codpr==97
replace factor_behavioral=0.90658 if codpr==98
replace factor_behavioral=0.90658 if codpr==99
replace factor_behavioral=0.90658 if codpr==101
replace factor_behavioral=0.90658 if codpr==102
replace factor_behavioral=0.90658 if codpr==103
replace factor_behavioral=0.90658 if codpr==104
replace factor_behavioral=0.90658 if codpr==105
replace factor_behavioral=0.90658 if codpr==106
replace factor_behavioral=0.90658 if codpr==107
replace factor_behavioral=0.90658 if codpr==108
replace factor_behavioral=0.90658 if codpr==109
replace factor_behavioral=0.90658 if codpr==110
replace factor_behavioral=0.75628 if codpr==205
replace factor_behavioral=0.683308 if codpr==210
replace factor_behavioral=0.683308 if codpr==211
replace factor_behavioral=0.683308 if codpr==212
replace factor_behavioral=0.683308 if codpr==213
replace factor_behavioral=0.683308 if codpr==214
replace factor_behavioral=0.683308 if codpr==215
replace factor_behavioral=0.678934 if codpr==216
replace factor_behavioral=0.756928 if codpr==303
replace factor_behavioral=0.678934 if codpr==315
replace factor_behavioral=0.756928 if codpr==331
replace factor_behavioral=0.662914 if codpr==408
replace factor_behavioral=0.683308 if codpr==629
replace factor_behavioral=0.683308 if codpr==630
replace factor_behavioral=0.692758 if codpr==642
replace factor_behavioral=0.692758 if codpr==643
replace factor_behavioral=0.73774  if codpr==649
replace factor_behavioral=0.73774  if codpr==650
replace factor_behavioral=0.73774  if codpr==651
replace factor_behavioral=0.692758 if codpr==661
replace factor_behavioral=0.692758 if codpr==664
replace factor_behavioral=0.692758 if codpr==667
replace factor_behavioral=0.692758 if codpr==670
replace factor_behavioral=0.699382 if codpr==686
replace factor_behavioral=0.699382 if codpr==692
replace factor_behavioral=0.756928 if codpr==810


replace factor_behavioral=0.96634 if inlist(codpr, 681, 682, 683, 684, 685, 691) & poor==1
replace factor_behavioral=0.98578 if inlist(codpr, 681, 682, 683, 684, 685, 691) & poor==0

replace factor_behavioral=0.756928 if codpr==332
replace factor_behavioral=0.94096 if codpr==334 & poor==1
replace factor_behavioral=0.94969 if codpr==334 & poor==0

gen factor_behavioral_t=round((-100*(1-factor_behavioral)/18), 0.001) if factor_behavioral!=.

compare factor_behavioral_t elasticities if codpr!=681 & codpr!=682 & codpr!=683 & codpr!=684 & codpr!=685 & codpr!=691 & codpr!=334

*/

*Initial codes have elasticity multiplied by 18> this is wrong because ex-ante the price may increase more than 18 due to cascading effects or less due to exempted products so now commented and fixed 
	
	if "$new_behavioral"=="yes" {
		replace factor_behavioral=(factor_behavioral/100)
		recode factor_behavioral .=0

		*Elasticities that vary across poor and non-poor people (poverty defined ex-ante)
		replace factor_behavioral=(0.96634-1)/0.18 if inlist(codpr, 681, 682, 683, 684, 685, 691) & poor==1
		replace factor_behavioral=(0.98578-1)/0.18 if inlist(codpr, 681, 682, 683, 684, 685, 691) & poor==0
		
		replace factor_behavioral=(0.94096-1)/0.18 if codpr==334 & poor==1
		replace factor_behavioral=(0.94969-1)/0.18 if codpr==334 & poor==0
	}
	else {
		replace factor_behavioral=1-(18*factor_behavioral/(-100)) // this formula convert a elasticity of 0.4% to 1- (18% X 0.4) =0.92
		
		
		*Elasticities that vary across poor and non-poor people (poverty defined ex-ante)
		replace factor_behavioral=0.96634 if inlist(codpr, 681, 682, 683, 684, 685, 691) & poor==1
		replace factor_behavioral=0.98578 if inlist(codpr, 681, 682, 683, 684, 685, 691) & poor==0
		
		replace factor_behavioral=0.94096 if codpr==334 & poor==1
		replace factor_behavioral=0.94969 if codpr==334 & poor==0
	}
	

keep poor codpr factor_behavioral

save "$presim/05_elasticities.dta", replace 