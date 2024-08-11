**** PROJECT: Create presentation with figures - Example
**** TO DO: Ensure reproducibility with few changes
**** MADE BY: Gabriel Lombo 
**** LAST UPDATE: July 23, 2024

* Packages



* Setup

	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/Mauritania/Mausim_2024"
	global output 		"${path}/03_Tool/_test"
	global data_sn 		"${path}/01_data/1_raw/MRT"    
	global presim       "${path}/01_data/2_pre_sim/MRT"

	
	
* Content
use "$presim/01_menages.dta", clear

gen uno = 1 

line uno decile_expenditure, xtitle("") title("Observations")

graph export "${output}/graph1.png", replace

save graph1, replace


* Render 
.d = .deck.new "${output}/dfsslides.pptx"
