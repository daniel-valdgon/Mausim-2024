*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: Julieth Pico 
* Date: June 2020
* Version: 1.0
*--------------------------------------------------------------------------------

*set more off
*clear all

*global root = "C:\Users\wb521296\OneDrive - WBG\Desktop\Senegal\CEQ 2020"


********************************************************************************

*global dataout = "$root/SENEGAL_ECVHM_final/Dataout"
*global datain  = "$root/SENEGAL_ECVHM_final/Datain"

**********************************************************************

/* Enterprise owners */


use "$datain/s10_2_me_SEN2018.dta", clear

gen double cos_1=s10q47*s10q59 
gen double cos_2=s10q49*s10q59
gen double cos_3=s10q51*s10q59
gen double cos_4=s10q52*s10q59
gen double cos_5=s10q53*s10q59
gen double cos_6=s10q54*s10q59
gen double cos_7=s10q55
gen double cos_8=s10q56
gen double cos_9=s10q57

egen double cos_10=rowtotal(s10q62d_1 s10q62d_2 s10q62d_3 s10q62d_4)
replace cos_10=cos_10*s10q59

egen costot=rsum(cos_1 cos_2 cos_3 cos_4 cos_5 cos_6 cos_7 cos_8 cos_9 cos_10)
replace costot=costot*-1
egen double ingtot=rsum(s10q46 s10q48 s10q50)
replace ingtot=ingtot*s10q59

egen double inc3_a=rsum(ingtot costot)
replace inc3_a=0 if inc3_a<0

gen double formal=1 if s10q31==1
replace formal=1 if s10q32==1
replace formal=1 if s10q30==1
replace formal=1 if s10q29==1


egen formal_definitivo=rowtotal(formal)
replace formal_definitivo=1 if formal_definitivo!=0

collapse (sum) inc3_a ingtot costot formal_definitivo , by(hhid)

*save "$dta/income_enterprise.dta", replace

tempfile income_enterprise
save `income_enterprise'

use "$datain/s02_me_SEN2018.dta", clear
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$datain/s04_me_SEN2018.dta", gen(merged4)
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$datain/s01_me_SEN2018.dta", gen(merged1)
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$datain/s05_me_SEN2018.dta", gen(merged5)
merge n:1 hhid using "$dataout/ehcvm_conso_SEN2018_menage.dta", gen(merged_consumption)
merge n:1 hhid using "$dta/income_enterprise.dta", gen(income_enterprise)

/***
Personal Income Tax
===================

***/
* Defining the type of worker
gen wage_earner=(s04q39>=1 & s04q39<=6)
gen self_employ=(s04q39>=9 & s04q39<=10)

* Defining the age 
recode s01q03c 9999=.
gen age=2018-s01q03c

* Defining years of education

gen yearsedu=s02q31 if s02q29==1
replace yearsedu=s02q31+3 if s02q29==2
replace yearsedu=s02q31+8 if s02q29==3
replace yearsedu=s02q31+8 if s02q29==4
replace yearsedu=s02q31+12 if s02q29==5
replace yearsedu=s02q31+12 if s02q29==6
replace yearsedu=s02q31+15 if s02q29==7
replace yearsedu=s02q31+15 if s02q29==8
replace yearsedu=0 if yearsedu==.

*gen contrac=(e9<4)

* Defining years of education and age for employees and self=employed

gen edu_w=yearsedu if wage_earner==1
gen edu_s=yearsedu if self_employ==1
gen age_w=age if wage_earner==1
gen age_s=age if self_employ==1
replace edu_w=. if wage_earner!=1
replace edu_s=. if self_employ!=1
replace age_w=. if wage_earner!=1
replace age_s=. if self_employ!=1

* Computing the average per household

cap drop _*
sort id_menage
by id_menage:egen hedu_s=mean(edu_s) 
bysort id_menage:egen hedu_w=mean(edu_w) 
bysort id_menage:egen hage_w=mean(age_w) 
bysort id_menage:egen hage_s=mean(age_s) 
bysort id_menage:egen num_w=sum(wage_earner) 
bysort id_menage:egen num_s=sum(self_employ) 
recode num_s num_w hage_s hage_w hedu_s hedu_w (.=0)
gen hage_w2=hage_w^2

* Urban and Rural

tabulate s00q04, gen(urban)
drop urban2
rename urban1 urban
lab var urban "=1 urban"

* Working sector: public or private


gen sector_public=1 if inlist(s04q31, 1,2)
gen sector_prive=1 if inlist(s04q31,3)
gen sector_pri_associative=1 if inlist(s04q31,4)
gen sector_pri_menage=1 if inlist(s04q31,5)
gen sector_pri_international=1 if inlist(s04q31,6)
clonevar months_w=s04q32
recode months (.=0)

gen double impa=s04q43 if s04q43_unite==2
replace impa=s04q43*4 if s04q43_unite==1
replace impa=s04q43/3 if s04q43_unite==3
replace impa=s04q43/12 if s04q43_unite==4

gen double impaes=s04q47 if s04q47_unite==2
replace impaes=s04q47*4 if s04q47_unite==1
replace impaes=s04q47/3 if s04q47_unite==3
replace impaes=s04q47/12 if s04q47_unite==4

egen impa_f=rowtotal(impa impaes)

gen double inc1_a=impa_f*s04q32


gen double isa=s04q60 if s04q60_unite==2
replace isa=s04q60*4 if s04q60_unite==1
replace isa=s04q60/3 if s04q60_unite==3
replace isa=s04q60/12 if s04q60_unite==4

gen double inc2_a=isa*s04q54
replace inc2_a=isa*12 if s04q60_unite==. & isa!=.

recode inc3_a inc2_a inc1_a (.=0)
egen inc_a=rsum(inc1_a inc2_a inc3_a)

* Working population 

recode s04q06 2=0
recode s04q07 2=0
recode s04q08 2=0
recode s04q09 2=0
egen working=rowtotal(s04q06 s04q07 s04q08 s04q09)
replace working=1 if working!=0


*$$ylab = \beta_{0} + \beta_{1}\left( 1 = urban \right) + \beta_{1}\left( 1 = 1\ or\ more\ employed\ in\ public\ sector \right) + \ \beta_{2}\left( \text{Quantity\ of\ wage\ earners} \right) + \beta_{3}\left( \text{average\ education\ of\ wage\ earners} \right) + \ \beta_{4}\left( \text{average\ age\ of\ wage\ earners} \right) + \ \beta_{5}\left( \text{Quantity\ of\ wage\ earners} \right) + \beta_{6}\left( \text{average\ education\ of\ wage\ earners} \right) + \ \beta_{7}\left( \text{average\ age\ of\ wage\ earners} \right)$$

//ON
/***
Estimation of Labor Income
--------------------------

Because household survey does not report income appropiately, we follow the
recommendatios of CEQ Handbook (Lustig & Higgins, forthcoming) to estimate labor 
income using consumption. We estimatea regression of consumption using as an explanatory 
variables: place of residence (urban/rural), if the household has a public employee, number of wage earners,
average education of wage earners, average age of wage earners, number of self-employed,
average education of wage earners, average age of wage earners.

- $$ ylab = \beta_{0}+\beta_{1}*(1=urban)+ \beta_{2}*(1=emp.p.sector)+ \beta_{3}*(qty.wage.earners)+ \beta_{4}*(qty.self.employed) + \beta_{5}*(educ.wage.earners) $$

***/

**Regression to estimate labor income
regress dtot urban sector_public num_w num_s hedu_w hedu_s  hage_w hage_s hage_w2

/***
We use the coefficients of the regression to estimate labor income for each individual 
and  also estimate an annual measure of income based on answers contained in 
household survey. Then, we compare estimated labor income against total consumption 
of household and we select as a measure of labor income the closest of two options: 
estimated labor income or annualized labor income reported in hhd. 

***/

//OFF

**Using coefficient to estimate labor income
gen eylab=_b[_cons]+_b[urban]*urban+_b[sector_pub]*sector_pub+ ///
_b[num_w]*wage_earner+_b[num_s]*self_employ+wage_earner*_b[hedu_w]*yearsedu+ ///
self_employ*_b[hedu_s]*yearsedu+wage_earner*_b[hage_w]*age+self_employ*_b[hage_s]*age

replace eylab=0 if working==0 & s04q50!=1

*replace eylab=0 if e10==.

format dtot inc_a eylab s04q43 s04q58 %14.0fc

tempvar dif_e dif_i

bysort hhid:egen seylab=sum(eylab) 
bysort hhid:egen sinc_a=sum(inc_a) 


gen `dif_e'=abs(seylab-dtot)/dtot //desviation of estimated labor income from consumption
gen `dif_i'=abs(sinc_a-dtot)/dtot //desviation of reported labor income from consumption

gen mdif_i=(`dif_i'<`dif_e')   // if desviation of reported labor income is lower than estimated 
gen mdif_e=(`dif_e'<`dif_i') // if desviation of estimated labor income is lower than reported

*Substitution of labor income
gen inclab=inc_a 	 if mdif_i==1  //if the desviation of reported income is lower, we use this figure
replace inclab=eylab if mdif_e==1  //Estimated labor income if the desviaton is lower
replace inclab=inc_a if mdif_e==0 & mdif_i==0 //few cases with income reported 
replace inclab=inc_a

replace inclab=0 if inclab<0
replace inclab=0 if working==0

label var inclab "Estimated Labor Income"


*******************************************************************************
* Personal Income Tax
*******************************************************************************
**Benefices Industriels et Commerciaux
*1. Regime du benefice reel normal
*2. Regime du benefice reel simplifie
*3. Regime de la contribution globale unique
*4. Traitments, salaires, indemnites, emoluments, avantages en natura, pensions

scalar lim1=100000000
scalar lim2=50000000

**http://www.ansd.sn/ressources/series/serie-ihpc-annuel.xlsx

//ON

/***

##Profits of commerce and industry, Agricultural Benefits & Professional benefits

The next step was to calculate income tax according to respective scheme. We didn't
find income above 50 million CFA. We estimate income tax for Global Contribution
Regime for self-employed.  Farm income was not included also as a part of personal income 
tax and was treated as non-payer. 

In the first case, when labor income was below 50 million CFA, we estimate tax 
benefits using _Global Regime_ according to rates of traders and producers.

In _Global Regime_, rates are different according to economic sector. So, we select
self-income employed according to activities reported in hhd.

## Simplified Regime

For those who earn between 50 million and 100 million CFA.  Reduction of 15% according to article 171. We apply the same rates as Income Tax on 
Salaries

 
## Evasion Assumptions
 
 - Those who are classified as informal, i.e. don't participate in any system of social 
 security, don't work in government, administration, private companies, international organistations, or do not have a bulletin de salaire
 - Agriculture workers
 - Self employed without Registre de commerce ou CSC pour les travailleurs ou Número d'identification fiscal.
 Others...
 check...
  
 
  
***/

//OFF


**rates 
gen regime_g=(s04q39==9|s04q39==10) // traders and producers
replace regime_g=2 if regime_g==1 & (s04q30c>=60 & s04q30c!=.)	//services
replace regime_g=3 if regime_g==1 & (s04q30c==15 | s04q30c==16 | s04q30c==55) //food retailers
	
gen inctax_self=.

foreach t of global tholdsRGU1{

local min =${RGU1min`t'}
local max =${RGU1max`t'}
local rate=${RGU1rate`t'}
local plus=${RGU1plus`t'}

replace inctax_self=((inclab-`min')*`rate')+`plus' if inclab>`min' & inclab<=`max' & regime_g==1

}

foreach t of global tholdsRGU2{

local min =${RGU2min`t'}
local max =${RGU2max`t'}
local rate=${RGU2rate`t'}
local plus=${RGU2plus`t'}

replace inctax_self=((inclab-`min')*`rate')+`plus' if inclab>`min' & inclab<=`max' & regime_g==3

}

foreach t of global tholdsRGU3{

local min =${RGU3min`t'}
local max =${RGU3max`t'}
local rate=${RGU3rate`t'}
local plus=${RGU3plus`t'}

replace inctax_self=((inclab-`min')*`rate')+`plus' if inclab>`min' & inclab<=`max' & regime_g==2

}


/* Me falta poner en el excel el impuesto minimo que paga cada regimen!!!

**Minimum
replace inctax_self=30000 if regime_g==2 & inctax_self<30000 //services
replace inctax_self=25000 if regime_g==1 & inctax_self<25000 //traders & producers
replace inctax_self=25000 if regime_g==3 & inctax_self<25000 //food retailers
*/

**Regime du benefice reel normal & reel simplifie

**Reduction of 15% for reel simplifie		 
gen double inclab_s=inclab if (s04q39==9|s04q39==10)
replace inclab_s=inclab_s -(inclab_s*0.15) if inclab>50000000 & inclab<100000000 & (s04q39==9|s04q39==10)

*Determined Tax (using the progressive rates as wage earners) Only highest income bracket
replace inctax_self=4359000+(inclab_s-13500000)*0.40 if  inclab>50000000 & (s04q39==9|s04q39==10) & inclab!=.

*Reduction using number of parts (this applies also to wage earners)

gen chi25=age<25 if s01q02!=1  	   //children under 25 years
bysort hhid:egen chi_h=sum(chi25)  // # children household

gen pension_invalidite_widow=1 if s05q03==1
replace pension_invalidite_widow=1 if s05q05==1

global other_income s05q01 s05q03 s05q05 s05q07 s05q09 s05q11 s05q13

foreach var of global other_income{
	recode `var' 2=0
	}

egen other_income= rowtotal( $other_income)	
	
gen some_income=1 if other_income!=0
replace some_income=1 if inclab!=0
bys hhid: egen total_income_apportant=total(some_income)
	
gen nom_part1=$part_P1 if inlist(s01q07,1,5,6,7)  // single,divorced,widow and separée
replace nom_part1=$part_P5 if inlist(s01q07,2,3,4) // Mariée ou Union Libre
replace nom_part1=$part_P3 if inlist(s01q07,1,5,6,7) & pension_invalidite_widow==1

gen nom_part2=${part_P6}*chi_h
gen nom_part3=$part_P7 if total_income_apportant==1 

egen nom_part_total=rowtotal(nom_part1 nom_part2 nom_part3)	
replace nom_part_total=$part_Max_part if nom_part_total>$part_Max_part


*Reduction according to number of parts

gen inctaxself_r=.

foreach t of global tholdsNombreParts{

	local min =${Partsmin`t'}
	local max =${Partmax`t'}
	local rate=${Partrate`t'}
	local part=${Part_nombre`t'}

	replace inctaxself_r=inctax_self*`rate' if nom_part_total==`part'
	replace inctaxself_r=`min' if inctaxself_r< `min' & nom_part_total==`part'
	replace inctaxself_r=`max' if inctaxself_r> `max' & nom_part_total==`part'
	}
	

replace inctax_self=inctax_self-inctaxself_r if inclab>=50000000 & (s04q39==9|s04q39==10) & inclab!=.

** Replace taxes to zero to all informal enterprises
replace inctax_self=0 if formal==0

*Negative tax is equalized to zero
replace inctax_self=0 if inctax_self<0


/*## Evasion Assumptions
 The same as Self Employed. Those without a contract did not pay Income Tax. Also, 
 those who do not report payment method.  
 */
 

**Tax on salaries
*Determined Tax

gen payment_taxes=1 if s04q38==1 
*replace payment_taxes=1 if inlist(s04q31,2,3,6) 
replace payment_taxes=1 if inlist(s04q31,1,2,6) 
replace payment_taxes=1 if s04q42==1 
recode payment_taxes .=0

gen double incsal_y=inclab if inlist(s04q39,1,2,3,4,5)
replace incsal_y=0 if incsal_y==.
replace incsal_y=int((incsal_y/1000))*1000  //it was rounded, because law said:

//"For the calculation of the tax, the taxable income, rounded to thousands of lower franc"
	
gen reduction_incsal= incsal_y* $IR_nonrate_Moyenne
replace reduction_incsal=900000 if reduction_incsal>$IR_nonmax_Moyenne

gen impossable_income=incsal_y-reduction_incsal
	
gen inctax_sal=. 
	
foreach t of global tholdsIR{

local min =${IRmin`t'}
local max =${IRmax`t'}
local rate=${IRrate`t'}
local plus=${IRplus`t'}

replace inctax_sal=((impossable_income-`min')*`rate')+`plus' if impossable_income>`min' & impossable_income<=`max' 
}

*Reduction according to number of parts

gen incsal_r=.

foreach t of global tholdsNombreParts{

	local min =${Partsmin`t'}
	local max =${Partmax`t'}
	local rate=${Partrate`t'}
	local part=${Part_nombre`t'}

	replace incsal_r=inctax_sal*`rate' if nom_part_total==`part'
	replace incsal_r=`min' if incsal_r< `min' & nom_part_total==`part'
	replace incsal_r=`max' if incsal_r> `max' & nom_part_total==`part'
	}


gen inctax_sal_f=inctax_sal-incsal_r
replace inctax_sal_f=0 if inctax_sal_f<0
replace inctax_sal_f=0 if payment_taxes==0

egen income_tax=rowtotal(inctax_sal_f inctax_self)

tempfile Direct_taxes_complete_Senegal
save `Direct_taxes_complete_Senegal'
*save "$dta/Direct_taxes_complete_Senegal.dta", replace

preserve
collapse (sum) income_tax hhweight (mean) hhsize , by(hhid)
label var income_tax "Household Income Tax payment"
*save "$dta/income_tax_collapse.dta", replace
tempfile income_tax_collapse
save `income_tax_collapse'
restore





