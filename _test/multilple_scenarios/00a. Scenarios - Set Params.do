
/*==============================================================================*\
 Multiplie simulations
 Authors: Madi Mangan, Gabriel Lombo, Daniel Valderrama
 Start Date: January 2024
 Update Date: March 2024
 
\*==============================================================================*/

*clear all 
*macro drop _all 

*-------------------------------------
// 1. Reference
*-------------------------------------

/*
global scenario_name_save = "Reference"
 
global prep "P"
global user "DPP DMP"
global tranch "T1 T2"

mat Max_User_1_1 = (300) // First value is prep, second is user 
mat Sub_User_1_1 = (140.3, 140.3) 	
mat Tar_User_1_1 = (24.6, 24.6) 	

mat Max_User_1_2 = (300) 
mat Sub_User_1_2 = (105.9, 105.9) 	
mat Tar_User_1_2 = (59, 59) 		

global UBI_montant 0
global pub_student_montant 0

set_global 	
run_tool
*/	
*-------------------------------------
// 2. Simulation 1
*-------------------------------------

global scenario_name_save = "Sim1_NoSubs"
 
global prep "P"
global user "DPP DMP"
global tranch "T1 T2"

mat Max_User_1_1 = (300) // First value is prep, second is user 
mat Sub_User_1_1 = (0, 0) 	
mat Tar_User_1_1 = (164.9, 164.9) 	

mat Max_User_1_2 = (300) 
mat Sub_User_1_2 = (0, 0) 	
mat Tar_User_1_2 = (164.9, 164.9) 		

global tariff_elec_prof 164.9

set_global 
run_tool

*-------------------------------------
// 3. Simulation 2
*-------------------------------------

global scenario_name_save = "Sim2_UBI"

global UBI_montant 11056.36
global pub_student_montant 0

run_tool


*-------------------------------------
// 3. Simulation 2
*-------------------------------------

global scenario_name_save = "Sim3_PubSchool"

global UBI_montant 0
global pub_student_montant 56806,11

run_tool





END
