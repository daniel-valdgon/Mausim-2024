clear all
set mem 1g
set more off
version 10

global 	data "C:\Users\\`c(username)'\Dropbox\ENPH\Datos\" //Andrés y Susana 
if "`c(username)'" == "german.gallegos"{
	global 	data "D:\Users\\`c(username)'\Dropbox\ENPH\Datos\" //Andrés y Susana 
}
	
cd 		"$data"


glo NEQN = 9   /* Número de ecuaciones = Núm. de gastos */
glo NM=$NEQN-1

***********************************************************************************

*cd "D:\Users\\`c(username)'\Dropbox\ReplicaciónLES\" 

use "Base_Est_LES.dta", clear

keep if muestra_sincolas==1
keep if ciudad_nombre==5

*Hay 87.188 hogares en la base, y 8 categorías de gasto que se tendrán en cuenta:

sum indice*
sum gasto*
sum share*

*Arreglar bien la fusión de Educación y Cultura
/*
replace gasto_mensual5 = gasto_mensual5+gasto_mensual6
drop gasto_mensual6

foreach num in 7 8 9{
	local men = `num'-1
	rename share`num' share`men'
	rename indice`num' indice`men'
	rename gasto_mensual`num' gasto_mensual`men'
}*/

**************************************************************************
* 1. Reducir la escala de los precios para que sean cercanos a 1         *
* 2. Reducir la escala de los gastos para que estén expresados en miles  *
**************************************************************************

forvalues i = 1/9{
	gen precio`i' = indice`i'/100
	rename gasto_mensual`i' gasto`i'
	gen gastocero`i' = 0
	replace gastocero`i' =1 if gasto`i'==0
}

egen ceros = rsum(gastocero*)

forvalues i = 1/9{
	replace gasto`i' =. if gasto`i'==0 /*& ceros > 2*/
	replace share`i' =. if share`i'==0 /*& ceros > 2*/
}


foreach x of varlist gasto* {
	replace `x' = `x'/1000
}

*forvalues i = 1/8{
*	drop if share`i' ==. 
*}

*Rural 0, Urbano 1
*keep if sector==0

*keep if gastocero == 0

*drop if DOMINIO==1|DOMINIO==3|DOMINIO==7|DOMINIO==14|DOMINIO==15|DOMINIO==18|DOMINIO==19|DOMINIO==26|DOMINIO==29|DOMINIO==32|DOMINIO==35|DOMINIO==36|DOMINIO==40|DOMINIO==41

********************************************************************
* 3. Especificación del LES para poderlo estimar con nlsur         *
********************************************************************


global subs "precio1*{gamma1=10}"
forvalues i=2(1)$NEQN {
global subs "$subs + precio`i'*{gamma`i'=10}"
}
global com ""
* loop hasta $NM porque debe omitirse una ecuación
forvalues i=1(1)$NM {
global com "$com (share`i' = precio`i'*{gamma`i'=10}/gasto_total + {beta`i'} * (1 - ($subs)/gasto_total) )"
}



nlsur $com [pw=FEX_C], variables(share* precio* gasto_total) ifgnls initial(gamma1 10 gamma2 10 gamma3 10 gamma4 10 gamma5 10 gamma6 10 gamma7 10 gamma8 10/* gamma9 10*/ ///
beta1 0 beta2 0 beta3 0 beta4 0 beta5 0 beta6 0 beta7 0) vce(robust) 

estat sum
est store lesmini
est save les2019mini, replace

forvalues i=1(1)$NM {
cap drop res`i'
predict res`i', resid equation(#`i')
} 



*keep if e(sample)

********************************************************************
* 4. Generación de todas las matrices necesarias                   *
********************************************************************

global gastos "Alimentos Vivienda Vestuario Salud Educacion Diversion Comunicaciones Transporte Otros"
global matrices "B GAMMA SGAMMA SB ELGMEAN ELGMED ELPHMEAN ELPHMED ELPXMEAN ELPXMED SELGMEAN SELPHMEAN SELPXMEAN"
foreach x in $matrices {
matrix `x'=J($NEQN,1,0)
matrix rownames `x'=$gastos
}

est restore lesmini //Completar la matriz de varianza covarianza
matrix v=e(V)
matrix vnew=v[1..${NEQN}+1,1],v[1..${NEQN}+1,3...]
matrix vgamma=vnew[1,1..${NEQN}]\vnew[3...,1..${NEQN}]
matrix vnew2=v[1...,2],v[1...,${NEQN}+2...]
matrix vbeta=vnew2[2,1...]\vnew2[${NEQN}+2...,1...]
matrix var=J(2*${NEQN},2*${NEQN} ,0)
matrix var[1,1]=vgamma
matrix var[(${NEQN}+1),(${NEQN}+1)]=vbeta
lincom 1 - [beta1]_cons - [beta2]_cons - [beta3]_cons - [beta4]_cons - [beta5]_cons - [beta6]_cons - [beta7]_cons - [beta8]_cons  
matrix var[2*${NEQN},2*${NEQN}]=r(se)^2
*Las primeras 8 celdas son las SE de las Gamma, y luego de las 8 Beta

forvalues i=1(1)$NM {
matrix B[`i',1]=[beta`i']_cons
matrix GAMMA[`i',1]=[gamma`i']_cons
}
lincom 1 - [beta1]_cons - [beta2]_cons - [beta3]_cons - [beta4]_cons - [beta5]_cons - [beta6]_cons - [beta7]_cons - [beta8]_cons
matrix B[$NEQN,1]=r(estimate)
matrix GAMMA[$NEQN,1]=[gamma$NEQN]_cons
matrix TB=J($NEQN,1,0)
matrix TGAMMA=J($NEQN,1,0)
forvalues i=1(1)$NEQN {
matrix TB[`i',1]= sqrt(var[`i',`i'])
}
forvalues i=1(1)$NEQN {
matrix SGAMMA[`i',1]= sqrt(var[(`i'),(`i')])
matrix SB[`i',1]= sqrt(var[($NEQN+`i'),($NEQN+`i')])
}


* Elasticidades

* Elasticidad ingreso: ely_i= \mu * \beta_i * y / v_i=\beta_i^* * y / v_i
* Calculo de medias y medianas
matrix mean=J($NEQN,1,0)
matrix med=J($NEQN,1,0)
global gasto2 ""
forvalues i=1(1)$NEQN {
global gasto2 "$gasto2 gasto`i'"
}

forvalues i=1(1)$NEQN {
	quietly mean gasto`i' /*[pw=factor]*/
	matrix mean[`i',1] = e(b)
	_pctile gasto`i' /*[pw=factor]*/, p(50)
	matrix med[`i',1] = r(r1)

	* Elasticidad gasto: elg_i= \beta_i * v / v_i = beta_i/w_i

	* Calculo media y mediana gasto total, participaciones, precios
	quietly mean gasto_total /*[pw=factor]*/
	matrix aaa=e(b)
	scalar vmean=el(aaa,1,1)
	_pctile gasto_total /*[pw=factor]*/, p(50)
	scalar vmed=r(r1)
	forvalues j=1(1)$NEQN {
		quietly mean precio`j' /*[pw=factor]*/
		matrix bbb=e(b)
		scalar pmean`j'=el(bbb,1,1)
	}
	* Cálculo en la media
	matrix ELGMEAN[`i',1] = B[`i',1]* vmean / mean[`i',1] 

	* Cálculo en la mediana
	matrix ELGMED[`i',1] = B[`i',1]* vmed / med[`i',1] 

	* Elasticidad precio propio de la hicksiana: eph_i= -(1-\beta_i)(1-\alpha_i/v_i)

	* Cálculo en la media
	matrix ELPHMEAN[`i',1] = -(1-B[`i',1])*(1-((pmean`i'*GAMMA[`i',1]) / mean[`i',1] ))

	* Cálculo en la mediana
	matrix ELPHMED[`i',1] = -(1-B[`i',1])*(1-((pmean`i'*GAMMA[`i',1])/ med[`i',1] ))

	* Elasticidad precio propio de la marshalliana LES: epx_i= (1- beta_i) (\alpha_i / v_i) -1

	* Cálculo en la media
	matrix ELPXMEAN[`i',1] = (1-(B[`i',1]))*((pmean`i'*GAMMA[`i',1])/ mean[`i',1] ) - 1  
	* Cálculo en la mediana
	matrix ELPXMED[`i',1] = (1-(B[`i',1]))*((pmean`i'*GAMMA[`i',1]) / med[`i',1] ) - 1  
}

* Errores estándar

forvalues i=1(1)$NEQN {
matrix mean`i'=mean[`i',1]
scalar mean`i'=det(mean`i')
}
* Elasticidad gasto
est restore lesmini

forvalues i=1(1)$NM {
lincom [beta`i']_cons*vmean/mean`i'
matrix SELGMEAN[`i',1] = r(se)
}
lincom (1 - [beta1]_cons - [beta2]_cons - [beta3]_cons - [beta4]_cons - [beta5]_cons - [beta6]_cons - [beta7]_cons - [beta8]_cons)*vmean/mean9
matrix SELGMEAN[$NEQN,1] = r(se)
* Elasticidad precio no compensada
forvalues i=1(1)$NM {
est restore lesmini
nlcom (1-[beta`i']_cons)*pmean`i'*([gamma`i']_cons)/mean`i' - 1, post
*dis _se[_nl_1]
matrix SELPXMEAN[`i',1] = _se[_nl_1]
}
est restore lesmini
nlcom (1-(1 - [beta1]_cons - [beta2]_cons - [beta3]_cons - [beta4]_cons - [beta5]_cons - [beta6]_cons - [beta7]_cons - [beta8]_cons))*pmean9*([gamma9]_cons)/mean9 - 1, post
matrix SELPXMEAN[$NEQN,1] = _se[_nl_1]
* Elasticidad precio compensada
forvalues i=1(1)$NM {
est restore lesmini
nlcom -1*(1-[beta`i']_cons)*(1-pmean`i'*[gamma`i']_cons/mean`i'), post
matrix SELPHMEAN[`i',1] = _se[_nl_1]
}
est restore lesmini
nlcom -1*(1-(1 - [beta1]_cons - [beta2]_cons - [beta3]_cons - [beta4]_cons - [beta5]_cons - [beta6]_cons - [beta7]_cons - [beta8]_cons))*(1-pmean9*[gamma9]_cons/mean9), post
matrix SELPHMEAN[$NEQN,1] = _se[_nl_1]

* Pegar todo en una sola matriz y exportar
matrix TOTAL = B
matrix TOTALELAST = B
global matrices "B GAMMA SGAMMA ELGMEAN SELGMEAN ELPHMEAN SELPHMEAN ELPXMEAN SELPXMEAN"
global matrices2 "GAMMA SGAMMA ELGMEAN SELGMEAN ELPHMEAN SELPHMEAN ELPXMEAN SELPXMEAN"
global matelast "B GAMMA ELGMEAN ELPHMEAN ELPXMEAN"
global matelast2 "GAMMA ELGMEAN ELPHMEAN ELPXMEAN"

foreach x in $matelast2 {
matrix TOTALELAST= TOTALELAST,`x'
}
foreach x in $matrices2 {
matrix TOTAL= TOTAL,`x'
}
matrix rownames TOTALELAST=$gastos
matrix colnames TOTALELAST=$matelast
matrix rownames TOTAL=$gastos
matrix colnames TOTAL=$matrices

mat list TOTALELAST
mat list TOTAL

global matricespval "ZGAMMA PGAMMA ZB PB ZELGMEAN PELGMEAN ZELPHMEAN PELPHMEAN ZELPXMEAN PELPXMEAN"
global matrixnames "B GAMMA ELGMEAN ELPHMEAN ELPXMEAN"
foreach x in $matricespval {
matrix `x'=J($NEQN,1,0)
matrix rownames `x'=$gastos
}

foreach x in $matrixnames {
	forvalues i=1(1)$NEQN {
		matrix Z`x'[`i',1]=`x'[`i',1]/S`x'[`i',1]
		matrix P`x'[`i',1]=2*ttail( 1000000 , abs(Z`x'[`i',1]))
	}
}

global gastos "Alimentos Vivienda Vestuario Salud Educ-Rest-Cult. Transporte Comunicaciones Otros"
local ind = 1
foreach name in $gastos{
	global nombre`ind' "`name'"
	foreach x in $matrixnames {
		global `x'`ind' : di %9.3f `x'[`ind',1]
		foreach mat in S Z P{
			global `mat'`x'`ind' : di %9.3f `mat'`x'[`ind',1]
		}
	}
	local ind = `ind'+1
}

est restore lesmini
global nobs : dis e(N)

********************************************************************
* 5. Generación de las tablas en LaTeX                             *
********************************************************************

cap texdoc close
texdoc init "tablas/LES_coeficientesR.tex", replace force
	tex \begin{tabular}{r c | c c c c}
        tex \hline
        tex \multicolumn{2}{c}{Ecuación} & Coeficiente & Error estándar & z & P$ >$ z \\
		tex \hline
		forvalues i=1(1)$NEQN {
			tex ${nombre`i'} & $ \gamma_`i' $ & ${GAMMA`i'} & ${SGAMMA`i'} & ${ZGAMMA`i'} & ${PGAMMA`i'} \\
			tex                & $ \beta_`i' $  & ${B`i'} & ${SB`i'} & ${ZB`i'} & ${PB`i'} \\
			tex \hline
		}
		tex \multicolumn{6}{l}{\scriptsize  Sistema estimado usando el comando \texttt{nlsur} de Stata 15.} \\
		tex \multicolumn{6}{l}{Número de observaciones: ${nobs}.}
    tex \end{tabular}
texdoc close

cap texdoc close
texdoc init "tablas/LES_elasticidadesR.tex", replace force
	tex \begin{tabular}{c r | c c c c}
        tex \hline
        tex \multicolumn{2}{c |}{Ecuación} & Valor & Error estándar & z & P$ >$ z \\
		tex \hline
		forvalues i=1(1)$NEQN {
			tex               & Gasto                & ${ELGMEAN`i'}  & ${SELGMEAN`i'}  & ${ZELGMEAN`i'}  & ${PELGMEAN`i'} \\
			tex  ${nombre`i'} & Precio Compensada    & ${ELPHMEAN`i'} & ${SELPHMEAN`i'} & ${ZELPHMEAN`i'} & ${PELPHMEAN`i'} \\
			tex               & Precio no Compensada & ${ELPXMEAN`i'} & ${SELPXMEAN`i'} & ${ZELPXMEAN`i'} & ${PELPXMEAN`i'} \\
			tex \hline
		}
		tex \multicolumn{6}{l}{Valores y errores estándar calculados usando los comandos \texttt{lincom} y \texttt{nlcom} de Stata.}
    tex \end{tabular}
texdoc close

* 5.1. Tabla de descriptivas de shares de gasto

preserve

keep if ceros==0

local ind = 1
forvalues i=1(1)$NEQN{
	sum share`i'
	global mshare`ind' : di %9.2f r(mean)
	global sshare`ind' : di %9.2f r(sd)
	global ishare`ind' : di %9.2f r(min)
	global ashare`ind' : di %9.2f r(max)
	global nshare : di %9.0f r(N)
	sum share`i' if sector == 0
	global msharer`ind' : di %9.2f r(mean)
	global ssharer`ind' : di %9.2f r(sd)
	global isharer`ind' : di %9.2f r(min)
	global asharer`ind' : di %9.2f r(max)
	global nsharer : di %9.0f r(N)
	sum share`i' if sector == 1
	global mshareu`ind' : di %9.2f r(mean)
	global sshareu`ind' : di %9.2f r(sd)
	global ishareu`ind' : di %9.2f r(min)
	global ashareu`ind' : di %9.2f r(max)
	global nshareu : di %9.0f r(N)
	local ind = `ind'+1
}

cap texdoc close
texdoc init "tablas/LES_sharesDescriptives.tex", replace force
	tex \begin{tabular}{c | c c /*c */c | c c /*c */c | c c /*c */c}
        tex & \multicolumn{3}{c|}{Nacional} & \multicolumn{3}{c|}{Urbano} & \multicolumn{3}{c}{Rural} \\
		tex \hline
		tex Rubro & Media & D. E. /*& Mín.*/ & Máx. & Media & D. E. /*& Mín.*/ & Máx. & Media & D. E. /*& Mín.*/ & Máx. \\
		tex \hline
		forvalues i=1(1)$NEQN {
			tex  ${nombre`i'} & ${mshare`i'} & ${sshare`i'} /*& ${ishare`i'}*/ & ${ashare`i'} & ${mshareu`i'} & ${sshareu`i'} /*& ${ishareu`i'}*/ & ${ashareu`i'} & ${msharer`i'} & ${ssharer`i'} /*& ${isharer`i'}*/ & ${asharer`i'} \\
		}
	tex \hline
	tex  Observaciones & \multicolumn{3}{c|}{${nshare}} & \multicolumn{3}{c|}{${nshareu}} & \multicolumn{3}{c}{${nsharer}} \\
	tex \hline
    tex \end{tabular}
texdoc close


restore






















