
************************************************************************************/
noi dis as result " UBI and Transfer to public students                          "
************************************************************************************

if ("$country" == "MRT") {


	use "$data_sn/Datain/individus_2019.dta", clear


	* globals UBI_montant and pub_student_montant are created in 00 master. Beware!!!

	gen UBI = $UBI_montant

	tab C8, mis

	gen pub_student_transfer = $pub_student_montant
	replace pub_student_transfer =0 if C8!=1

	collapse (sum) UBI pub_student_transfer, by(idmen)
	rename idmen hhid

	drop if inlist(hhid,9801,10707,13503)  //These 3 were not in the 9910 definitive


	if $devmode== 1 {
		save "$tempsim/DirTransfers.dta", replace
	}
	tempfile DirTransfers
	save `DirTransfers'


}

if ("$country" == "SEN") {
	
	use  "$presim/01_menages.dta", clear 
	
	keep hhid
	
	gen UBI = $UBI_montant
	gen pub_student_transfer = $pub_student_montant
	
	if $devmode== 1 {
		save "$tempsim/DirTransfers.dta", replace
	}
	tempfile DirTransfers
	save `DirTransfers'
}


