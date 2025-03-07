



use "$dta\output_ref",  clear	

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

merge 1:1 hhid using "$dta\output"  , keepusing(pondih yc_pc) nogen

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
