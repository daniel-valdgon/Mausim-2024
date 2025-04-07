/*==============================================================================*\
 Simulation Tool - Mauritania
 Authors: Gabriel Lombo, Madi Mangan, Andrés Gallegos, Daniel Valderrama
 Start Date: January 2024
 Update Date: March 2025
 
\*==============================================================================*/
   	
*-------------------------------------
// 00. Set up
*-------------------------------------

if (1) qui: do "${thedo_pre}/01. Pullglobals.do"

*-------------------------------------
// 00. Auxiliar 
*-------------------------------------




*-------------------------------------
// 00. EPCV files
*-------------------------------------

if (1) qui: do "${thedo_pre}/05. Spend_dta_purchases.do"

*-------------------------------------
// 00. PMT
*-------------------------------------

if (1) qui: do "${thedo_pre}/07. PMT.do"


*-------------------------------------
// 00. Policies
*-------------------------------------

if (1) qui: do "${thedo_pre}/01. Social_Security.do"

if (1) qui: do "${thedo_pre}/02. Income_tax.do"



if (1) qui: do "${thedo_pre}/07. Direct_transfer.do"

if (1) qui: do "${thedo_pre}/08. Subsidies_elect.do"

if (1) qui: do "${thedo_pre}/08. Subsidies_agric.do"

if (1) qui: do "${thedo_pre}/08. Subsidies_fuel.do"

if (1) qui: do "${thedo_pre}/09. Inkind Transfers.do"


*-------------------------------------
// 00. Net down
*-------------------------------------


if (1) qui: do "${thedo_pre}/Consumption_NetDown.do"


noi di "You run the pre simulation do files"


scalar t2_pre = c(current_time)


display "Running the pre-sim tool took " (clock(t2_pre, "hms") - clock(t1_pre, "hms")) / 1000 " seconds"




	
	
	
	
	
	