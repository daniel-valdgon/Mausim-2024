
use "$data_sn/s10_2_me_SEN2018.dta", clear

/* Income of Enterprise owners */

*=====================
*=====================
 *Measuring firm cost 
*=====================
*=====================

{
*---> cos1 to 6 (Inputs)
gen double cos_1=s10q47*s10q59 // 10.47 Combien avez-vous dépensé pour  l'achat de ces marchandises revendues en l X  10.59 Pendant combien de mois l'entreprise a-t-elle été en activité au cours des (How many months has the company been in operation in the last 12 months?)

gen double cos_2=s10q49*s10q59 // 10.49 Combien avez-vous dépensé en achat de matières premières pour les produits X  10.59 
gen double cos_3=s10q51*s10q59 // 10.51 Combien avez-vous dépensé en autres consommations intermédiaires (téléphone, transport, fournitures, etc.) au cours des 30 derniers jours ou durant le dernier mois où l'entreprise a fonctionné?  )  X  10.59 ^
gen double cos_4=s10q52*s10q59 // 10.52 Combien avez-vous dépensé en frais de loyer, eau et électricité au cours d X  10.59 ^
gen double cos_5=s10q53*s10q59 // 10.53 Combien avez-vous dépensé en frais de services pour utiliser ou louer des X  10.59 ^
gen double cos_6=s10q54*s10q59 // 10.54 Combien avez-vous dépensé en autres frais et services au cours des 30 dern X  10.59 ^

*---> cos-7 to cos-9 (License, other taxes, administrative expenses)
gen double cos_7=s10q55 // 10.55 Quel est le montant de la patente payée par l'entreprise au cours des 12 d 
gen double cos_8=s10q56 // 10.56 Quel est le montant des autres impôts et taxes payés par l'entreprise au c
gen double cos_9=s10q57 //10.57 Quel est le montant des frais administratifs non réglementaires payés par 

*---> cos-10: Salaries of people working at the firm 

recode s10q62d_1 s10q62d_2 s10q62d_3 s10q62d_4 (9999=.)

*AGV: I changed this because I think we should multiply the average wage by the number of employees
*ORIGINALLY: egen double cos_10=rowtotal(s10q62d_1 s10q62d_2 s10q62d_3 s10q62d_4)
gen wages1 = s10q62d_1*s10q62a_1
gen wages2 = s10q62d_2*s10q62a_2
gen wages3 = s10q62d_3*s10q62a_3
gen wages4 = s10q62d_4*s10q62a_4
egen double cos_10=rowtotal(wages1 wages2 wages3 wages4)
replace cos_10=cos_10*s10q59

*---> Suming up all previous cost 
egen costot=rsum(cos_1 cos_2 cos_3 cos_4 cos_5 cos_6 cos_7 cos_8 cos_9 cos_10)
replace costot=costot*-1

*-------------------
 *Measuring firm net income 
*-------------------

egen double ingtot=rsum(s10q46 s10q48 s10q50) //
replace ingtot=ingtot*s10q59

*---> Net income 
egen double inc3_a=rsum(ingtot costot)
*replace inc3_a=0 if inc3_a<0

*-------------------
 *Measuring formality
*-------------------

gen double formal=1 if s10q31==1 //Cette entreprise est-elle enregistrée au Registre de Commerce (RC)?
replace formal=1 if s10q32==1 //Les personnes qui travaillent dans cette entreprise sont-elles enregistrées à la Caisse de Sécurité Sociale (CSS)?
replace formal=1 if s10q30==1 //Cette entreprise dispose-t-elle d'un numéro d'identification fiscal (NIF) ou d'un NINEA?
replace formal=1 if s10q29==1 //Est-ce que cette entreprise tient une comptabilité écrite?


*-------------------
 *Organizing and adding to household level dataset 
*-------------------

egen formal_definitivo=rowtotal(formal)
replace formal_definitivo=1 if formal_definitivo!=0

*(AGV) WE WERE COLLAPSING THIS AT A HOUSEHOLD LEVEL AND THEN DUPLICATING IT IN THE MERGES BELOW! THIS IS WRONG!
/*{
collapse (sum) inc3_a ingtot costot formal_definitivo , by(hhid) // gross income, net income , cost and formality of bussiness 

tempfile income_enterprise
save `income_enterprise' // save "$dta/income_enterprise.dta", replace
}*/

*(AGV) CORRECTED VERSION!
{
	gen perc_au_menage = 1
	replace perc_au_menage = .875 if s10q22==4 //Plus de 75%
	replace perc_au_menage = .625 if s10q22==3 //Entre 50 & 75%
	replace perc_au_menage = .375 if s10q22==2 //Entre 25 & 50%
	replace perc_au_menage = .125 if s10q22==1 //Moins de 25%
	replace inc3_a = inc3_a*perc_au_menage
	destring s10q15__0, force gen(s01q00a1)
	destring s10q15__1, force gen(s01q00a2)
	recode s01q00a* (-999999999=.)
	*replace s01q00a2 = .					// OJO: Assign profits to only one individual per firm/household
	recode s01q00a1 (.=1)                   //If the firm has no individual associated, we will give it to individual 1 in each household
	replace inc3_a=inc3_a/2 if s01q00a2!=. 	//If there are 2 owners in the household, we will assume they share profits equally. Problem: We cannot see if there are 3+ owners
	reshape long s01q00a , i(hhid s10q12a_1 inc3_a) j(member)
	keep hhid inc3_a s01q00a formal_definitivo
	drop if s01q00a==.
	recode s01q00a (20=21) if hhid==40003 //correcting by hand some mismatches
	recode s01q00a (10=1) if hhid==122006 //correcting by hand some mismatches
	recode s01q00a (4=1) if hhid==164007  //correcting by hand some mismatches
	recode s01q00a (16=2) if hhid==264007 //correcting by hand some mismatches
	recode s01q00a (7=8) if hhid==275012  //correcting by hand some mismatches
	recode s01q00a (7=2) if hhid==281007  //correcting by hand some mismatches
	recode s01q00a (4=5) if hhid==283001  //correcting by hand some mismatches
	recode s01q00a (2=6) if hhid==290001  //correcting by hand some mismatches
	recode s01q00a (7=6) if hhid==411001  //correcting by hand some mismatches
	recode s01q00a (4=1) if hhid==412010  //correcting by hand some mismatches
	recode s01q00a (2=5) if hhid==527006  //correcting by hand some mismatches
	recode s01q00a (1=2) if inlist(hhid,6010,36001,49011,62003,79002,85007,130001,130007,132001,178012,183003,197002,214006,268005,270007,289010,295012,301012,312001,321003,358003,366011,380006,382006,382008,462005,463001,472003,489008,489009,508007,519004,525005,539011)
	recode s01q00a (1=3) if inlist(hhid,91010,215011,446002,450010)
	recode s01q00a (1=4) if inlist(hhid,97003,121012)
	recode s01q00a (1=5) if hhid==16010   //correcting by hand some mismatches
	recode s01q00a (1=10) if hhid==227002 //correcting by hand some mismatches
	
	collapse (sum) inc3_a (mean) formal_definitivo , by(hhid s01q00a)
	
	*Should we ignore losses? If yes, then we will do:										<-- Replace firm losses with 0
	*replace inc3_a=0 if inc3_a<0
	
	tempfile income_enterprise
	save `income_enterprise'
}

use "$data_sn/s02_me_SEN2018.dta", clear
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s04_me_SEN2018.dta", gen(merged4)
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s01_me_SEN2018.dta", gen(merged1)
merge 1:1 interview__key interview__id id_menage grappe vague s01q00a using "$data_sn/s05_me_SEN2018.dta", gen(merged5)
merge n:1 hhid using "$data_sn/ehcvm_conso_SEN2018_menage.dta", gen(merged_consumption)
merge 1:1 hhid s01q00a using `income_enterprise', gen(income_enterprise)							// If Andres
*merge n:1 hhid using `income_enterprise', gen(income_enterprise)									// If Julieth

	recode inc3_a formal_definitivo (.=0)
	
	*replace inc3_a = inc3_a*hhsize
	*CHECK: Cometer el error de Julieth de que todos los miembros del hogar tienen mismo firm income
	*bys hhid: ereplace inc3_a = total(inc3_a)
	
}

*====================================================================================
*====================================================================================
 *Wage income and imputation method (blocked)
*====================================================================================
*====================================================================================

*-------------------
 *Preparing variables 
 *for consumption/mincer equations 
*-------------------

{

*--> Type of worker
gen wage_earner=(s04q39>=1 & s04q39<=6)
gen self_employ=(s04q39>=9 & s04q39<=10)

*--> Age 

replace s01q03a=. if s01q03a==999 | s01q03a==9999
replace s01q03b=. if s01q03b==999 | s01q03b==9999
replace s01q03c=. if s01q03c==999 | s01q03c==9999
gen date_survey_started = date(s00q23a,"YMD#hms")
gen age = date_survey_started-mdy(s01q03b,s01q03a,s01q03c)
replace age=floor(age/365.25)
replace age= s01q04a if age==.
replace age=2018-s01q03c if vague==1 & age==.
replace age=2019-s01q03c if vague==2 & age==.
replace age=0 if age==-1

*--> Years of education

gen yearsedu=s02q31 if s02q29==1
replace yearsedu=s02q31+3 if s02q29==2
replace yearsedu=s02q31+8 if s02q29==3
replace yearsedu=s02q31+8 if s02q29==4
replace yearsedu=s02q31+12 if s02q29==5
replace yearsedu=s02q31+12 if s02q29==6
replace yearsedu=s02q31+15 if s02q29==7
replace yearsedu=s02q31+15 if s02q29==8
replace yearsedu=0 if yearsedu==.

*--> step function for wage and self employed  
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

* Main activity Labor income (cash + In-Kind) 

gen double impa=s04q43 if s04q43_unite==4 //(4.43)	 Quel a été le salaire de  [NOM] pour cet emploi (pour la période de temps considérée)? (Main salary)
replace impa=s04q43*4 if s04q43_unite==3
replace impa=s04q43*12 if s04q43_unite==2
replace impa=s04q43*52 if s04q43_unite==1

recode s04q45 s04q47 s04q49 (9999=0)

gen double impap=s04q45 if s04q45_unite==4 //(4.45)	 A combien évaluez-vous les primes ( uniquement celles qui ne sont pas incluses dans le salaire)?  (Primes)
replace impap=s04q45*4 if s04q45_unite==3
replace impap=s04q45*12 if s04q45_unite==2
replace impap=s04q45*52 if s04q45_unite==1

gen double impaes=s04q47 if s04q47_unite==4 // (4.46) [NOM] bénéficie-t-il d'autres avantages quelconques ( indemnités de transport, indemnités de logement, etc. autres que la nourriture) non inclus dans le salaire dans le cadre de cet emploi? (Other payments)
replace impaes=s04q47*4 if s04q47_unite==3
replace impaes=s04q47*12 if s04q47_unite==2
replace impaes=s04q47*52 if s04q47_unite==1

gen double impaN=s04q49 if s04q49_unite==4 // (4.46) [NOM] reçoit-il de la nourriture dans le cadre de cet emploi ? (In-kind food payments)
replace impaN=s04q49*4 if s04q49_unite==3
replace impaN=s04q49*12 if s04q49_unite==2
replace impaN=s04q49*52 if s04q49_unite==1

egen impa_f=rowtotal(impa impap impaes impaN) //AGV: I included impap, it was not considered before //AGV: I also include food (impaN) which is inkind

*(AGV) WE ARE NOW IGNORING THE FACT THAT PEOPLE MAY HAVE NOT WORKED THE WHOLE YEAR IN THEIR LAST JOB, BECAUSE THAT WOULD MEAN THAT THEY WERE UNEMPLOYED THE REST OF THE YEAR.
*replace s04q32=1 if s04q32==0 //(AGV) If the person has worked for less than a month, but still received income, we should not turn it into 0
*gen double inc1_a=impa_f*s04q32 // s04q32 Months with the jobs 
*replace inc1_a=impa_f*12 if inc1_a==.
gen double inc1_a=impa_f

* Secondary Employment Labor Income  (cash + In-Kind) 

gen double isa=s04q58 if s04q58_unite==4
replace isa=s04q58*4 if s04q58_unite==3
replace isa=s04q58*12 if s04q58_unite==2
replace isa=s04q58*52 if s04q58_unite==1

recode s04q60 s04q62 s04q64 (9999=0)

gen double isap=s04q60 if s04q60_unite==4
replace isap=s04q60*4 if s04q60_unite==3
replace isap=s04q60*12 if s04q60_unite==2
replace isap=s04q60*52 if s04q60_unite==1

gen double isaes=s04q62 if s04q62_unite==4
replace isaes=s04q62*4 if s04q62_unite==3
replace isaes=s04q62*12 if s04q62_unite==2
replace isaes=s04q62*52 if s04q62_unite==1

gen double isaN=s04q64 if s04q64_unite==4
replace isaN=s04q64*4 if s04q64_unite==3
replace isaN=s04q64*12 if s04q64_unite==2
replace isaN=s04q64*52 if s04q64_unite==1

egen isa_f=rowtotal(isa isap isaes isaN) //AGV: I included impap, it was not considered before //AGV: I also include food (impaN) which is inkind

*(AGV) WE ARE NOW IGNORING THE FACT THAT PEOPLE MAY HAVE NOT WORKED THE WHOLE YEAR IN THEIR LAST JOB, BECAUSE THAT WOULD MEAN THAT THEY WERE UNEMPLOYED THE REST OF THE YEAR.
*replace s04q54=1 if s04q54==0 //(AGV) If the person has worked for less than a month, but still received income, we should not turn it into 0
*gen double inc2_a=(isa+isap+isaes)*s04q54 //AGV: I included isa and isaes, they were not considered before
*replace inc2_a=(isa+isap+isaes)*12 if inc2_a==.
gen double inc2_a=isa_f

recode inc3_a inc2_a inc1_a (.=0)
egen inc_a=rsum(inc1_a inc2_a inc3_a) // adding main job, secondary job and enterpreneur income 

* Working population 

recode s04q06 2=0
recode s04q07 2=0
recode s04q08 2=0
recode s04q09 2=0
egen working=rowtotal(s04q06 s04q07 s04q08 s04q09)
replace working=1 if working!=0


*$$ylab = \beta_{0} + \beta_{1}\left( 1 = urban \right) + \beta_{1}\left( 1 = 1\ or\ more\ employed\ in\ public\ sector \right) + \ \beta_{2}\left( \text{Quantity\ of\ wage\ earners} \right) + \beta_{3}\left( \text{average\ education\ of\ wage\ earners} \right) + \ \beta_{4}\left( \text{average\ age\ of\ wage\ earners} \right) + \ \beta_{5}\left( \text{Quantity\ of\ wage\ earners} \right) + \beta_{6}\left( \text{average\ education\ of\ wage\ earners} \right) + \ \beta_{7}\left( \text{average\ age\ of\ wage\ earners} \right)$$

//ON

}




*-------------------
 *Estimating labor income 
*-------------------

{



/***
Estimation of Labor Income
--------------------------

Because household survey does not report income appropiately, we follow the recommendatios of CEQ Handbook (Lustig & Higgins, forthcoming) to estimate labor  income using consumption.
We estimatea regression of consumption using as an explanatory 
variables: place of residence (urban/rural), if the household has a public employee, number of wage earners,
average education of wage earners, average age of wage earners, number of self-employed, average education of wage earners, average age of wage earners.

- $$ ylab = \beta_{0}+\beta_{1}*(1=urban)+ \beta_{2}*(1=emp.p.sector)+ \beta_{3}*(qty.wage.earners)+ \beta_{4}*(qty.self.employed) + \beta_{5}*(educ.wage.earners) $$

***/

**Regression to estimate labor income
*(AGV) After talking with Gabriela, we believe that the dependent variable should be total consumption per worker
egen occupied = rowmax(working wage_earner self_employ) 
bys hhid: egen workers = total(occupied)
gen dtotlab = dtot/workers
regress dtotlab urban sector_public num_w num_s hedu_w hedu_s  hage_w hage_s hage_w2 //dtot from s01_me_SEN2018 

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


replace inclab=inc_a  // !!! Notice here we ignore all previous steps on  inc_A!!! (DV)

replace inclab=0 if inclab<0
*replace inclab=0 if working==0

label var inclab "Estimated Labor Income"
format %16.2fc inclab
}

if $devmode == 2{
	bys hhid:egen sinclab=total(inclab)
	bys hhid:egen sinc_lab1=total(inc1_a)
	bys hhid:egen sinc_lab2=total(inc2_a)
	bys hhid:egen sinc_ent=total(inc3_a)
	gen linc=ln(sinclab+1)
	gen lincl1=ln(sinc_lab1+1)
	gen lincl2=ln(sinc_lab2+1)
	gen lincent=ln(sinc_ent+1)
	gen sincl1=ln(sinc_lab1+sqrt(sinc_lab1^2 +1))
	gen sincl2=ln(sinc_lab2+sqrt(sinc_lab2^2 +1))
	gen sincent=ln(sinc_ent+sqrt(sinc_ent^2 +1))
	gen inctot = inc1_a+inc2_a+inc3_a
	bys hhid:egen finctot=total(inctot)
	gen sinctot=ln(finctot+sqrt(finctot^2 +1))
	gen ldt=ln(dtot+1)
	gen sdt=ln(dtot+sqrt(dtot^2 +1))
	twoway (scatter linc ldt, msize(vtiny)) (line ldt ldt, sort) /*(lfit linc ldt [aw=hhweight])*/, ytitle(Estimated Labor Income) xtitle(Total Consumption) ///
	legend(ring(0) position(10) order(2 3) label(2 "45°")) ///
	xlabel(12.2 "200K" 13.1 "500K" 13.8 "1M" 14.5 "2M" 15.4 "5M" 16.1 "10M" 16.8 "20M" 17.7 "50M") ///
	ylabel(0 "0" 0.69 "1" 2.4 "10" 4.6 "100" 6.9 "1K" 9.2 "10K" 11.5 "100K" 13.8 "1M" 16.1 "10M" 18.4 "100M" 20.7 "1B")
	graph export "$tempsim/estimated_income_cons_comp.png", replace
	histogram linc if linc>0 [fw=hhweight], xlabel(6.9 "1K" 9.2 "10K" 11.5 "100K" 13.8 "1M" 16.1 "10M" 18.4 "100M") percent
	histogram linc [fw=hhweight], xlabel(0 "0" 0.69 "1" 2.4 "10" 4.6 "100" 6.9 "1K" 9.2 "10K" 11.5 "100K" 13.8 "1M" 16.1 "10M" 18.4 "100M") percent
	graph bar sinclab [aw=hhweight], over(ndtet) ytitle(Mean of labor income) //xtitle("Deciles of per capita Consumption")
	gen savings = sinclab-dtot
	gen savings_rate = savings/sinclab
	graph bar savings [aw=hhweight], over(ndtet)
	graph bar savings_rate [aw=hhweight], over(ndtet)
	histogram savings_rate [fw=hhweight]
	
	twoway (hist lincl1 [fw=hhweight] if lincl1!=0, frac) (hist lincent [fw=hhweight] if lincent!=0, color(stc2%50) frac), xlabel(6.9 "1K" 9.2 "10K" 11.5 "100K" 13.8 "1M" 16.1 "10M" 18.4 "100M" 18.4 "100M" /*20.72 "1B"*/) legend(label(1 "Wage") label(2 "Entrepr.") ring(0) pos(10))
	
	global lnvals = ""
	foreach var in /*-1000000 -10000 -100 -10*/ 0 10 100 1000 10000 100000 200000 500000 1000000 2000000 5000000 10000000 20000000 100000000{
		*local lnv = round(ln(`var'),0.001)
		local lnv = round(ln(`var'+sqrt((`var')^2 +1)),0.001)
		global lnvals `"$lnvals `lnv' "`var'" "'
	}
	twoway (hist sincl1 [fw=hhweight], frac) (hist sincent [fw=hhweight], color(stc2%50) frac), xlabel(0 "0" 2.998 "10" 5.298 "100" 7.601 "1,000" 9.903 "10,000" 12.206 "100,000" 14.509 "1M" 16.811 "10M" 19.114 "100M") legend(label(1 "Wage") label(2 "Entrepr.") ring(0) pos(10))
	twoway (hist sinctot [fw=hhweight], freq), xlabel($lnvals ) //legend(label(1 "Wage") label(2 "Entrepr.") ring(0) pos(10))
	
	recode s05q02 s05q04 s05q06 s05q08 s05q10 s05q12 s05q14 (.=0)
	gen inc_cons = inctot + s05q02 + s05q04 + s05q06 + s05q08 + s05q10 + s05q12 + s05q14
	bys hhid:egen finc_cons=total(inc_cons)
	gen sinc_cons=ln(finc_cons+sqrt(finc_cons^2 +1))
	hist sinc_cons [fw=hhweight], freq
	twoway (hist sinc_cons [fw=hhweight], frac) (hist sdt [fw=hhweight], color(stc2%50) width(.26090728) frac), xlabel(0 "0" 2.998 "10" 5.298 "100" 7.601 "1,000" 9.903 "10,000" 12.206 "100,000" 14.509 "1M" 16.811 "10M" 19.114 "100M" ) legend(label(1 "Household income") label(2 "Household consumption") ring(0) pos(10))
	graph export "$tempsim/distribs_present_sept2023.png", replace
	twoway (scatter sinc_cons sdt, msize(vtiny)) (line sdt sdt, sort) /*(lfit sinc_cons sdt [aw=hhweight])*/, ytitle(Household Income) xtitle(Total Consumption) legend(ring(0) position(10) order(2 3) label(2 "45°")) ylabel(0 "0" 2.998 "10" 5.298 "100" 7.601 "1,000" 9.903 "10,000" 12.206 "100,000" 14.509 "1M" 16.811 "10M" 19.114 "100M" ) xlabel(12.899 "200,000"  13.816 "500,000" 14.509 "1M" 15.202 "2M"  16.118 "5M" 16.811 "10M" 17.504 "20M")
	
	
	drop sinclab - sinc_cons
}

*====================================================================================
*====================================================================================
* Personal Income Tax
*====================================================================================
*====================================================================================

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

The next step was to calculate income tax according to respective scheme.
We didn't find income above 50 million CFA. 

We estimate income tax for Global Contribution Regime for self-employed.  Farm income was not included also as a part of personal income tax and was treated as non-payer. 

	In the first case, when labor income was below 50 million CFA, we estimate tax 
	benefits using _Global Regime_ according to rates of traders and producers.

In _Global Regime_, rates are different according to economic sector. So, we select
self-income employed according to activities reported in hhd.

## Simplified Regime

For those who earn between 50 million and 100 million CFA.  Reduction of 15% according to article 171. We apply the same rates as Income Tax on Salaries

## Simplified Regime

 
## Evasion Assumptions
 
 - Those who are classified as informal, i.e. don't participate in any system of social 
 security, don't work in government, administration, private companies, international organistations, or do not have a bulletin de salaire
 - Agriculture workers
 - Self employed without Registre de commerce ou CSC pour les travailleurs ou Número d'identification fiscal.
 Others...
 check...
  
 
  
***/

//OFF

*--->Creating variables to measure parts for tax credits  

{

*Number of dependents childs (<25) & studying Article 177 of CGI
gen chi25=age<25 if s01q02!=1  	   //children under 25 years not household head
	replace chi25=0 if s02q12!=1 // & studying 

bysort hhid:egen chi_h=sum(chi25)  // # children at househld level 
label var chi_h "Number of studying children less than 25 YO"

*Pension
gen pension_invalidite_widow=1 if s05q03==1
replace pension_invalidite_widow=1 if s05q05==1

*Total income earners 
global other_income s05q01 s05q03 s05q05 s05q07 s05q09 s05q11 s05q13

foreach var of global other_income{
	recode `var' 2=0
	}

egen other_income= rowtotal( $other_income)	
	
gen some_income=1 if other_income!=0
replace some_income=1 if inclab!=0
bys hhid: egen total_income_apportant=total(some_income)

}

sort hhid s01q00a
cap drop __000*
save "$presim/02_Income_tax_input.dta", replace 

