use "$tempsim/FinalConsumption_verylong.dta", clear

gen 	spending_exempted = achats_avec_VAT
replace spending_exempted = 0 if exempted==0

gen 	spending_elec = achats_avec_VAT
replace spending_elec = 0 if codpr!=334

gen 	spending_fuels = achats_avec_VAT
replace spending_fuels = 0 if !inlist(codpr, 202, 208, 209, 303, 304)

egen 	spending_health_excises = rowtotal(ex_alc ex_nal ex_fat1 ex_fat2 ex_tab)

gen 	spending_informal = achats_avec_VAT
replace spending_informal = 0 if informal_purchase==0

collapse (sum) achat_gross achats_net_VAT achats_net_excise achats_net_subind achats_net achats_sans_subs_dir achats_sans_subs achats_avec_excises achats_avec_VAT spending_exempted spending_elec spending_fuels spending_health_excises spending_informal (mean) hhweight, by(hhid)

tempfile cons_aftertool
save `cons_aftertool'


use "$data_sn/Senegal_consumption_all_by_product.dta", clear
gen Achat=depan * (modep==1)
gen Autoconso=depan * (modep==2)
gen Don=depan * (modep==3)
gen Valeur_usage_BD=depan * (modep==4)
gen Loyer_imputee=depan * (modep==5)

collapse (sum) depan Achat Autoconso Don Valeur_usage_BD Loyer_imputee , by(grappe menage)

merge 1:1 grappe menage using  "$data_sn/ehcvm_conso_SEN2018_menage.dta", nogen

merge 1:1 hhid using `cons_aftertool' , nogen 

merge 1:1 hhid using "$data_out\output" , nogen 

collapse (sum) depan Achat Autoconso Don Valeur_usage_BD Loyer_imputee dtot spending_exempted spending_elec spending_fuels spending_health_excises spending_informal [iw=hhweight], by(deciles_pc)

format depan %15.0f

foreach val in exempted elec fuels health_excises informal{
	gen share_`val'=spending_`val'*100/depan
}
gen share_nonmarket=(Autoconso + Don + Valeur_usage_BD + Loyer_imputee)*100/depan

br share_*




