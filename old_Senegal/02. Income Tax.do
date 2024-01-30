/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
 Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
 Author: Julieth Pico 
 Date: June 2020
 
 Modifications: 
		Daniel Valderrma August 17 2022: 
		- Add minimum income tax (previously ignored)
		- Eliminated imputation model because it was not being enforce in the code
		- Change regime codes to a more accurate definition, using 4 digit codes when necessary
		- Fixed RGU_raw3 in the excel sheet, bracket codes where using as inputs RGU2 values: Total direct taxes after this change goes from 257blln to 261blln, where 3 of those 4 blln are capture from the top quintile
		- Create RGU123_raw which loads all tax parameters in one excel sheet rhater than 6 that it was set before (reduce loading time by a half (today my computer is slow from 100 to 50 segs)
		- Eliminate the first part of computations
 Pending: 
		- Ask about why the imputation model was discarded, Not enforce because of replace inclab=inc_a  // !!! Notice here we ignore all previous steps on  inc_A!!! (DV)
		- THe taxes of CGU are over factured activities, so does not discount production cost !!!???
		
		Article 143. La contribution globale unique est établie chaque année en considération de la totalité du chiffre d’affaires réalisé du 1er janvier au 31 décembre de
		l’année précédente. (here: http://www.jo.gouv.sn/spip.php?article9554)
	
* Version: 1.0
*--------------------------------------------------------------------------------*/



use  "$presim/02_Income_tax_input.dta", replace 
sort hhid s01q00a
*cf _all using "C:\Users\WB419055\OneDrive - WBG\SenSim Tool\Senegal_tool\senCEQ\04. Dev-data\03-presim\02_Income_tax_input.dta"

/**********************************************************************************/
noi dis as result " 1. Régime de la Contribution Global Unique                     "
/**********************************************************************************/

{

** Rates vary by sector or regime (these condition are exhaustive for self employed : test ta s04q39 regime_g, m

/* The definition of regime was substantially chenged
*/
gen regime_g=(s04q39==9|s04q39==10) // 4.39. Quel est la catégorie  socioprofessionnelle de  %rostertitle% dans cet emp: 9 Travailleur pour compte propre & 10:Patron  & also it selects the rest of the sector not selected by the two lines below
replace regime_g=2 if regime_g==1 & (s04q30c>=55 & s04q30c!=.)	// DV: I included hotels as a service AGV: I excluded commerce, and moved them to other retailers and producers
replace regime_g=3 if regime_g==1 & ( (s04q30d>=521 & s04q30d<=523) | s04q30d==552 | s04q30d==263 | s04q30d==264 | s04q30d==553 ) // DV: Now includes retail of food, restaurants and cement 
//Before was food and hotels and restaurantes AND self-employed (s04q30c==15 | s04q30c==16 | s04q30c==55 ). 

replace regime_g=0 if s04q30d==701 | s04q30d==702 //AGV: La CGU ne s'applique pas aux personnes physiques réalisant des operations de vente, lotissement, location d'immeubles et gestion immobilière

recode regime_g (2=1) (3=2) (1=3), gen (aux_regime_g)  // This line of code fix comments that were in the following lines and therefore I delte them
replace regime_g=aux_regime_g


/* Before regime 2 was services, and regime 3 food,hotels and cigarettes , therfore regime one was the other manufacturing products. THe recode above change this 
*/
gen double inctax_self=.

//RGU1 
foreach t of global tholdsRGU1 {
	local min =${RGU1min`t'}
	local max =${RGU1max`t'}
	local rate=${RGU1rate`t'}
	local plus=${RGU1plus`t'}
	
	replace inctax_self=((inclab-`min')*`rate')+`plus' if inclab>=`min' & inclab<=`max' & regime_g==1 // (DV) services goes here!
}

//RGU2 
foreach t of global tholdsRGU2 {
	local min =${RGU2min`t'}
	local max =${RGU2max`t'}
	local rate=${RGU2rate`t'}
	local plus=${RGU2plus`t'}

	replace inctax_self=((inclab-`min')*`rate')+`plus' if inclab>=`min' & inclab<=`max' & regime_g==2 // (DV) food and cement resellers here
}

//RGU3 applied 
foreach t of global tholdsRGU3 {
	local min =${RGU3min`t'}
	local max =${RGU3max`t'}
	local rate=${RGU3rate`t'}
	local plus=${RGU3plus`t'}

	replace inctax_self=((inclab-`min')*`rate')+`plus' if inclab>=`min' & inclab<=`max' & regime_g==3 // (DV) rest of manufacturing and resellers here
}

**Minimum tax (NEW!!)
	replace inctax_self=${RGU1_floor} if regime_g==1 & inctax_self<${RGU1_floor} //services
	replace inctax_self=${RGU2_floor} if regime_g==2 & inctax_self<${RGU2_floor} //food & cement resellers
	replace inctax_self=${RGU3_floor} if regime_g==3 & inctax_self<${RGU3_floor} //traders & producers
	
gen regime_CGU = (inctax_self!=.)
}

/* TESTS TO FIND THE CORRECT FORMULA FOR THE PRETAX GROSSED-UP INCOME IN PRESIM (DELETE LATER)
*dirtax inclab if regime_g ==1, rates(4 5 6 7 8 8) tholds(0 500000 3000000 10000000 37000000 50000000) gross gen(CGU1_gross)

gen inc_postax = inclab-inctax_self
br inclab inctax_self inc_postax if regime_g ==1
*SUpongamos que inc_postax es el ingreso de la encuesta, y queremos hacer gross up para encontrar el pretax
dirtax inc_postax if regime_g ==1, rates(4 5 6 7 8 8) tholds(0 500000 3000000 10000000 37000000 50000000) net gen(CGU1_grossnet)
*Para los menores del threshold, obvio no da igual que inclab inicial
gen tax_implicit = CGU1_grossnet-inc_postax
replace CGU1_grossnet=inc_postax+30000 if tax_implicit<30000

scatter inctax_self tax_CGU1 if inctax_self<200000 &  regime_g ==1, msize(tiny)

dirtax CGU1_gross if regime_g ==1, rates(4 5 6 7 8 8) tholds(0 500000 3000000 10000000 37000000 50000000) net gen(CGU1_grossnet)

dirtax inclab if regime_g ==1, rates(0 20 30 35 37 40) tholds(0 630000 1500000 4000000 8000000 13500000) gross gen(CGU1_gross)
dirtax inclab if regime_g ==1, rates(0 20 30 35 37 40) tholds(0 630000 1500000 4000000 8000000 13500000) net gen(CGU1_net)
gen taxCGU1_gross = inclab-CGU1_gross
gen taxCGU1_net = -inclab+CGU1_net

0 0.2 0.3 0.35 0.37 0.4
50000000
*/

/**********************************************************************************/
noi dis as result " 2. Régimes du Bénéfice réel normal et du réel simplifié        "
/**********************************************************************************/

*Taxable income for self employed
gen double inclab_s=inclab if (s04q39==9|s04q39==10)

*Reduction of 15% for reel simplifie, leave as is for reel normal
replace inclab_s=inclab_s-(inclab_s*${RSimpRate}) if inclab<${min_reelnormal} & (s04q39==9|s04q39==10)

gen inctax_self_aux=.
foreach t of global tholdsIR {
	local min =${IRmin`t'}
	local max =${IRmax`t'}
	local rate=${IRrate`t'}
	local plus=${IRplus`t'}
	replace inctax_self_aux=((inclab_s-`min')*`rate')+`plus' if inclab_s>`min' & inclab_s<=`max' 
}

/* TESTS TO FIND THE CORRECT FORMULA FOR THE PRETAX GROSSED-UP INCOME IN PRESIM (DELETE LATER)
Determined Tax (using the progressive rates as wage earners)
*Those who fall outside the range of the CGU (or work in gestion immobilière) are subject to these regimes:
replace inctax_self=inctax_self_aux if inctax_self==. & (s04q39==9|s04q39==10) & inclab!=.
*drop inctax_self_aux

br inclab inclab_s inctax_self_aux
gen inc_postax = inclab-inctax_self_aux
*Supongamos que inc_postax es el ingreso de la encuesta, y queremos hacer gross up para encontrar el pretax
*replace inc_postax = inc_postax/(1-0.15)
dirtax inc_postax, rates(0 20 30 35 37 40) tholds(0 630000 1500000 4000000 8000000 13500000) net gen(inc_pretax_gu)
*Para los menores del threshold, obvio no da igual que inclab inicial
gen tax_implicit = inc_pretax_gu-inc_postax
gen error_rate = inc_pretax_gu/inclab
replace CGU1_grossnet=inc_postax+30000 if tax_implicit<30000
*/



/*-------------------
 **Tax credits ***
Note: reduction using number of parts (this applies to self employed and wage earners)
*-------------------*/

*--> Parts due to civil status	
gen nom_part1=$part_P1 if inlist(s01q07,1,5,6,7)  // single, divorced, widow and separée
replace nom_part1=$part_P5 if inlist(s01q07,2,3,4) // Mariée ou Union Libre
replace nom_part1=$part_P3 if inlist(s01q07,1,5,6,7) & pension_invalidite_widow==1


*--> Parts due to infants in charge (infants in the household)
gen nom_part2=${part_P6}*chi_h
replace nom_part2=${Cap_P6} if nom_part2>${Cap_P6} & nom_part2!=.

*--> Parts due to having one income apportant 
gen nom_part3=$part_P9 if total_income_apportant==1 // Le contribuable est le seul conjoint a disposer de revenus imposables, ajoutez un demi-part 

*--> Parts due to being Veuf avec des enfants à charge
gen nom_part4=$part_P8 if s01q07==5 & chi_h>0 

*--> Total number of parts 
egen nom_part_total=rowtotal(nom_part1 nom_part2 nom_part3 nom_part4)	
replace nom_part_total=$part_Max_part if nom_part_total>$part_Max_part



/*-------------------
 **Applying tax credits to self-employed ***
*-------------------*/

{
gen inctaxself_r=.

foreach t of global tholdsNombreParts {

	local min =${Partsmin`t'}
	local max =${Partmax`t'}
	local rate=${Partrate`t'}
	local part=${Part_nombre`t'}

	replace inctaxself_r=inctax_self*`rate' if nom_part_total==`part'
	replace inctaxself_r=`min' if inctaxself_r< `min' & nom_part_total==`part'
	replace inctaxself_r=`max' if inctaxself_r> `max' & nom_part_total==`part'
	}
	
// Apply the tax reduction to those self-employed not in CGU
replace inctax_self=inctax_self-inctaxself_r if regime_CGU==0 & (s04q39==9|s04q39==10) & inclab!=.

// Replace taxes to zero to all informal enterprises
replace inctax_self=0 if formal==0

// Negative tax is equalized to zero
replace inctax_self=0 if inctax_self<0
}

/**********************************************************************************/
noi dis as result " 3. Impôt sur le Revenu des salariés                            "
/**********************************************************************************/

/*-------------------
 **Salaried workers 
Note: Evasion Assumptions.  The same as Self Employed. 
	-Work for public or NGO
	-Have a payslip
	- Pay social secutiry 
	Old text: "Those without a contract did not pay Income Tax. Also,  those who do not report payment method.  "
 *-------------------*/
 
*---> Define if pay taxes
gen payment_taxes=1 if s04q38==1 // contribution to IPRES, FNR or Supplemental Pension 
*replace payment_taxes=1 if inlist(s04q31,2,3,6) 
replace payment_taxes=1 if inlist(s04q31,1,2,6) //work for public or international organizations 
replace payment_taxes=1 if s04q42==1 // Receives a payslip
recode payment_taxes .=0

*---> Define taxable income 
gen double incsal_y=inclab if inlist(s04q39,1,2,3,4,5) // Job categories defined as salaried 
replace incsal_y=0 if incsal_y==.

*<--save "$data_sn\survey_salary.dta"    , replace
replace incsal_y=int((incsal_y/1000))*1000  //it was rounded, because law said://"For the calculation of the tax, the taxable income, rounded to thousands of lower franc"

//Apply 30% of tax credit or 900000 at most 	for taxable income 
gen reduction_incsal= incsal_y* $IR_nonrate_Moyenne // IR=0.3
replace reduction_incsal=$IR_nonmax_Moyenne if reduction_incsal>$IR_nonmax_Moyenne
replace reduction_incsal=$IR_nonmin_Moyenne if reduction_incsal<$IR_nonmin_Moyenne

gen impossable_income=incsal_y-reduction_incsal

//Article 164. Sont également imposables à cet impôt, les pensions et rentes viagères. Toutefois, il est fait application d'un abattement égal à 40 % des pensions et rentes viagères, sans être inférieur à 1.800.000 de FCFA.
//167. Sont exonérés 9. les rentes viagères et indemnités temporaires attribuées aux victimes d'accidents du travail
recode s05q02 s05q04 s05q08 (.=0)
gen pension_base = s05q02+s05q04+s05q08 //s05q06 is for accidents du travail
gen pension_abatt = pension_base * $IR_nonrate_Pensions
replace pension_abatt=$IR_nonmax_Pensions if pension_abatt>$IR_nonmax_Pensions
replace pension_abatt=$IR_nonmin_Pensions if pension_abatt<$IR_nonmin_Pensions
*Apply reduction
replace pension_base = pension_base - pension_abatt if pension_base!=0
replace pension_base = 0 if pension_base <0

*Add base taxable of pension to the rest of the taxable income

replace impossable_income = impossable_income + pension_base


*---> Define taxes taxable income 
	
gen inctax_sal=. 
gen deduc_ratio=.

foreach t of global tholdsIR {
	local min =${IRmin`t'}
	local max =${IRmax`t'}
	local rate=${IRrate`t'}
	local plus=${IRplus`t'}
	local thedec=${deduc`t'}
	replace inctax_sal=((impossable_income-`min')*`rate')+`plus' if impossable_income>`min' & impossable_income<=`max' 
	replace deduc_ratio=`thedec'                                 if impossable_income>`min' & impossable_income<=`max' // not being used for now because of excel file is full of ones
}

*---> Define tax credit over taxes 

gen incsal_r=.

foreach t of global tholdsNombreParts {
	local min =${Partsmin`t'}
	local max =${Partmax`t'}
	local rate=${Partrate`t'}
	local part=${Part_nombre`t'}
	replace incsal_r=inctax_sal*`rate' if nom_part_total==`part'
	replace incsal_r=`min' if incsal_r< `min' & nom_part_total==`part'
	replace incsal_r=`max' if incsal_r> `max' & nom_part_total==`part'
}

replace incsal_r=incsal_r*deduc_ratio 	

*---> Taxes paid
gen 	inctax_sal_f=inctax_sal-incsal_r
replace inctax_sal_f=0 if inctax_sal_f<0
replace inctax_sal_f=0 if payment_taxes==0 // no taxes for informal workers


*---> Total taxes paid 
egen income_tax=rowtotal(inctax_sal_f inctax_self)

*Try to add discount due to parts
*Descuento efectivamente aplicado (The amount of tax credits that is actually reduce by the tax credit rules and not by other rules)
	*self employed
	gen sample_self=1 if  inclab>=50000000 & (s04q39==9|s04q39==10) & inclab!=.
	gen inctaxself_r_corr=inctaxself_r if sample_self==1
	replace inctaxself_r_corr=inctax_self if inctax_self<inctaxself_r & sample_self==1 & inctax_self!=0 & inctaxself_r!=.
	replace inctaxself_r_corr=0 if inctax_self<0 | formal==0 // it was going to e reduced anyway so not due to parts
	
	*wage earners
	gen incsal_r_corr=incsal_r
	replace incsal_r_corr=inctax_sal if inctax_sal<incsal_r & inctax_sal!=0 & incsal_r!=.
	replace incsal_r_corr=0 if payment_taxes==0 // it was going to e reduced anyway so not due to parts
	

	egen income_tax_reduc=rowtotal(inctaxself_r_corr incsal_r_corr)
	replace income_tax_reduc=. if income_tax_reduc==0


/**********************************************************************************/
noi dis as result " 4. Taxe Représentative de l'Impôt du Minimum fiscal            "
/**********************************************************************************/

gen double trimf = .

foreach t of global tholdsTRIMF {
	dis "`t'"
	local min =${TRIMFmin`t'}
	local max =${TRIMFmax`t'}
	local tarif=${TRIMFtarif`t'}
	replace trimf=`tarif' if incsal_y>`min' & incsal_y<=`max'
}

tab trimf, mis

recode trimf (.=0)
replace trimf=0 if payment_taxes==0 // no taxes for informal workers


*NOte: Eduard!!!!!!!!!!
* I excluded the use of if $devmode== 1 {  } else { } ///
*  because it may not work (already happened to me) unless I guarantee that everytime I use a tempfile I put the devmod option . Sin ce I am not sure I leave it like this
if $devmode== 1 {
	save "$tempsim/Direct_taxes_complete_Senegal.dta", replace
}


tempfile Direct_taxes_complete_Senegal
save `Direct_taxes_complete_Senegal'


*Tax data collapsed 
collapse (sum) income_tax income_tax_reduc trimf hhweight (mean) hhsize , by(hhid)
label var income_tax "Household Income Tax payment"
label var trimf "Tax Rep. de l'Impot Min. Fiscal"

if $devmode== 1 {
    save "$tempsim/income_tax_collapse.dta", replace
}

tempfile income_tax_collapse
save `income_tax_collapse'

