/*==============================================================================*\
 Simulation Tool - Mauritania
 Authors: Gabriel Lombo, Madi Mangan, Andrés Gallegos, Daniel Valderrama
 Start Date: January 2024
 Update Date: March 2025
 
\*==============================================================================*/
  
*scalar t1_pre = c(current_time)
 
*-------------------------------------
// A. Auxiliar Data
*-------------------------------------

if (1) qui: do "${thedo_pre}/A. Auxiliar Data.do"

*-------------------------------------
// B. EPCV
*-------------------------------------

if (1) qui: do "${thedo_pre}/B1. EPCV.do"

if (1) qui: do "${thedo_pre}/B2. EPCV - PMT.do"

*-------------------------------------
// C. Policies
*-------------------------------------

if (1) qui: do "${thedo_pre}/C1. Direct Taxes - Income Tax.do" 

if (1) qui: do "${thedo_pre}/C1. Direct Taxes - SSC.do" 

if (1) qui: do "${thedo_pre}/C2. Direct Transfers.do" 

if (1) qui: do "${thedo_pre}/C4. Indirect Subsidies - Agriculture.do" 

if (1) qui: do "${thedo_pre}/C4. Indirect Subsidies - Electricity.do"

if (1) qui: do "${thedo_pre}/C4. Indirect Subsidies - Fuel.do"

if (1) qui: do "${thedo_pre}/C5. In-Kind Transfers.do"

*-------------------------------------
// D. Netting Down
*-------------------------------------

if (1) qui: do "${thedo_pre}/D1. Pullglobals.do"

if (1) qui: do "${thedo_pre}/D2. Consumption Netting Down.do"


noi di "You run the pre simulation do files"


*scalar t2_pre = c(current_time)


*display "Running the pre-sim tool took " (clock(t2_pre, "hms") - clock(t1_pre, "hms")) / 1000 " seconds"




	
	
	
	
	
	