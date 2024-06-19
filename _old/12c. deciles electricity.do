


* Purchases Data
use "$data_sn/s_pivot2019.dta" , clear
rename depan depan2

gen elec=0
replace elec= depan2 if codpr==376

collapse (sum) depan2 elec [aw=hhweight], by(hhid hhsize)

gen share_elec = elec/depan2

tempfile elec_share
save `elec_share'


use "$data_out/output_AndresTest3.dta", clear

merge 1:1 hhid using `elec_share', keep(3)


*Necesito incidencia relativa (cond e incond) y share de consumo (cond e incond) por deciles. 

gen incidence_elec     = subsidy_elec_pc/yd_pc
gen incidence_elec_dir = subsidy_elec_direct_pc/yd_pc
gen incidence_elec_ind = subsidy_elec_indirect_pc/yd_pc

gen cincidence_elec = incidence_elec if incidence_elec>0
gen cincidence_elec_dir = incidence_elec_dir if incidence_elec_dir>0
gen cincidence_elec_ind = incidence_elec_ind if incidence_elec_ind>0

gen cshare_elec = share_elec if share_elec>0

gen coverage = (elec>0)

gen yd = yd_pc*hhsize
sum yd depan depan2

table yd_deciles_pc [aw=hhweight], stat(mean share_elec)

collapse (mean) *incidence* *share_elec coverage [iw=hhweight], by(yd_deciles_pc)

sum share_elec yd_deciles_pc







coverage tener electricity, conditional RI, undonditional RI, MRT y SEN


