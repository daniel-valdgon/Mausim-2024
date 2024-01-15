
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms
* Author: Julieth Pico 
* Date: August 2019
* Version: 1.0
*--------------------------------------------------------------------------------


*set more off
*clear all

*global root = "C:\Users\wb521296\OneDrive - WBG\Desktop\Senegal\CEQ 2020"


********************************************************************************

*global xls_sn      = "$path\03. Tool\SN_Sim_tool - Copy.xlsx"

*===============================================================================
*====================              Taxes 						================
*===============================================================================

// 1.1. Contribution Globale Unique //


preserve
import excel "$xls_sn", sheet(Taxe_directe_raw_ref) first clear

keep if Regime=="RGU1"
levelsof threshold, local(tholds)
global tholdsRGU1 `tholds'
foreach z of local tholds {
	levelsof min  if threshold=="`z'", local(RGU1min`z')
	global RGU1min`z' `RGU1min`z''
    levelsof max  if threshold=="`z'", local(RGU1max`z') 
	global RGU1max`z' `RGU1max`z''
	levelsof rate if threshold=="`z'", local(RGU1rate`z')
	global RGU1rate`z' `RGU1rate`z''
	levelsof plus if threshold=="`z'", local(RGU1plus`z')	
	global RGU1plus`z' `RGU1plus`z''
	
}
restore

preserve
import excel "$xls_sn", sheet(Taxe_directe_raw_ref) first clear

keep if Regime=="RGU2"
levelsof threshold, local(tholds)
global tholdsRGU2 `tholds'
foreach z of local tholds {
	levelsof min  if threshold=="`z'", local(RGU2min`z')
	global RGU2min`z' `RGU2min`z''
    levelsof max  if threshold=="`z'", local(RGU2max`z') 
	global RGU2max`z' `RGU2max`z''
	levelsof rate if threshold=="`z'", local(RGU2rate`z')
	global RGU2rate`z' `RGU2rate`z''
	levelsof plus if threshold=="`z'", local(RGU2plus`z')	
	global RGU2plus`z' `RGU2plus`z''
	
}
restore

preserve
import excel "$xls_sn", sheet(Taxe_directe_raw_ref) first clear

keep if Regime=="RGU3"
levelsof threshold, local(tholds)
global tholdsRGU3 `tholds'
foreach z of local tholds {
	levelsof min  if threshold=="`z'", local(RGU3min`z')
	global RGU3min`z' `RGU3min`z''
    levelsof max  if threshold=="`z'", local(RGU3max`z') 
	global RGU3max`z' `RGU3max`z''
	levelsof rate if threshold=="`z'", local(RGU3rate`z')
	global RGU3rate`z' `RGU3rate`z''
	levelsof plus if threshold=="`z'", local(RGU3plus`z')	
	global RGU3plus`z' `RGU3plus`z''
	
}
restore

preserve
import excel "$xls_sn", sheet(Parts_raw_ref) first clear

levelsof threshold, local(tholds)
global tholdsParts `tholds'
foreach z of local tholds {
	levelsof Part  if threshold=="`z'", local(part_`z')
	global part_`z' `part_`z''
  	
}
restore

preserve
import excel "$xls_sn", sheet(Parts_reduction_ref) first clear

levelsof threshold, local(tholds)
global tholdsNombreParts `tholds'
foreach z of local tholds {
	levelsof Minimum  if threshold=="`z'", local(Partsmin`z')
	global Partsmin`z' `Partsmin`z''
    levelsof Maximum  if threshold=="`z'", local(Partmax`z') 
	global Partmax`z' `Partmax`z''
	levelsof Taux if threshold=="`z'", local(Partrate`z')
	global Partrate`z' `Partrate`z''
	levelsof Nombre_parts if threshold=="`z'", local(Part_nombre`z')	
	global Part_nombre`z' `Part_nombre`z''
		
}
restore

preserve
import excel "$xls_sn", sheet(Taxe_directe_raw_ref) first clear

keep if Regime=="IR"
levelsof threshold, local(tholds)
global tholdsIR `tholds'
foreach z of local tholds {
	levelsof min  if threshold=="`z'", local(IRmin`z')
	global IRmin`z' `IRmin`z''
    levelsof max  if threshold=="`z'", local(IRmax`z') 
	global IRmax`z' `IRmax`z''
	levelsof rate if threshold=="`z'", local(IRrate`z')
	global IRrate`z' `IRrate`z''
	levelsof plus if threshold=="`z'", local(IRplus`z')	
	global IRplus`z' `IRplus`z''
	
}
restore

preserve
import excel "$xls_sn", sheet(Taxe_directe_raw_ref) first clear

keep if Regime=="IR_non"
levelsof threshold, local(tholds)
global tholdsIR_non `tholds'
foreach z of local tholds {
	levelsof max  if threshold=="`z'", local(IR_nonmax_`z')
	global IR_nonmax_`z' `IR_nonmax_`z''
	levelsof rate  if threshold=="`z'", local(IR_nonrate_`z')
	global IR_nonrate_`z' `IR_nonrate_`z''
  	
}
restore



*==================================================================================
*==============       Social Security Contributions						===========
*==================================================================================

preserve
import excel "$xls_sn", sheet(Sante_raw_ref) first clear

keep if Contribution_nom=="AFAS"
levelsof Threshold, local(tholds)
global tholdsAFAS `tholds'
foreach z of local tholds {
	levelsof Taux  if Threshold=="`z'", local(AFASRate`z')
	global AFASRate`z' `AFASRate`z''
  	
}
restore

preserve
import excel "$xls_sn", sheet(Sante_raw_ref) first clear

keep if Contribution_nom=="AAT"
levelsof Threshold, local(tholds)
global tholdsAAT `tholds'
foreach z of local tholds {
	levelsof Taux  if Threshold=="`z'", local(AATRate`z')
	global AATRate`z' `AATRate`z''
  	
}
restore

preserve
import excel "$xls_sn", sheet(Sante_raw_ref) first clear

keep if Contribution_nom=="Maximum"
levelsof Threshold, local(tholds)
global tholdsMaximum `tholds'
foreach z of local tholds {
	levelsof Taux  if Threshold=="`z'", local(MaximumRate`z')
	global MaximumRate`z' `MaximumRate`z''
  	
}
restore

preserve
import excel "$xls_sn", sheet(Retraite_raw_ref) first clear

keep if Regime=="FNR"
levelsof Type, local(tholds)
global tholdsFNR `tholds'
foreach z of local tholds {
	levelsof Taux  if Type=="`z'", local(FNRRate`z')
	global FNRRate`z' `FNRRate`z''
	levelsof Maximum  if Type=="`z'", local(FNRMAx`z')
	global FNRMax`z' `FNRMAx`z''
  	
}
restore

preserve
import excel "$xls_sn", sheet(Retraite_raw_ref) first clear

keep if Regime=="IPRES"
levelsof Type, local(tholds)
global tholdsIPRES `tholds'
foreach z of local tholds {
	levelsof Taux  if Type=="`z'", local(IPRESRate`z')
	global IPRESRate`z' `IPRESRate`z''
	levelsof Maximum  if Type=="`z'", local(IPRESMAx`z')
	global IPRESMax`z' `IPRESMAx`z''
  	
}
restore


*==================================================================================
*==============                Excises Taxes         					===========
*==================================================================================


preserve
import excel "$xls_sn", sheet(Excise_taxes_ref) first clear

keep if Produit=="Alcohol"
levelsof Taux, local(tholds)
global taux_alcohol `tholds'

restore

preserve
import excel "$xls_sn", sheet(Excise_taxes_ref) first clear

keep if Produit=="Boissons"
levelsof Taux, local(tholds)
global taux_boissons `tholds'

restore

preserve
import excel "$xls_sn", sheet(Excise_taxes_ref) first clear

keep if Produit=="Cafe"
levelsof Taux, local(tholds)
global taux_cafe `tholds'

restore

preserve
import excel "$xls_sn", sheet(Excise_taxes_ref) first clear

keep if Produit=="Te"
levelsof Taux, local(tholds)
global taux_te `tholds'

restore

preserve
import excel "$xls_sn", sheet(Excise_taxes_ref) first clear

keep if Produit=="Beurre"
levelsof Taux, local(tholds)
global taux_beurre `tholds'

restore

preserve
import excel "$xls_sn", sheet(Excise_taxes_ref) first clear

keep if Produit=="Autres_corps"
levelsof Taux, local(tholds)
global taux_autres_corps `tholds'

restore


preserve
import excel "$xls_sn", sheet(Excise_taxes_ref) first clear

keep if Produit=="Cigarettes"
levelsof Taux, local(tholds)
global taux_cigarettes `tholds'

restore

*==================================================================================
*==============                Direct Transfers     					===========
*==================================================================================

**** Programme National de Bourses de Sécurité Familiale 


preserve
import excel "$xls_sn", sheet(PNBSF_raw_ref) first clear

levelsof departement, local(departement)
global departementPNBSF `departement'
foreach z of local departement {
	levelsof Beneficiaires if departement==`z', local(PNBSF_Beneficiaires`z')
	global PNBSF_Beneficiaires`z' `PNBSF_Beneficiaires`z''
	levelsof Montant if departement==`z', local(PNBSF_montant`z')
	global PNBSF_montant`z' `PNBSF_montant`z''
  	
}
restore

**** Cantine Scolaire

preserve
import excel "$xls_sn", sheet(Cantine_scolaire_raw_ref) first clear

levelsof Region, local(region)
global regionCantine `region'
foreach z of local region {
	levelsof nombre_elevees if Region==`z', local(Cantine_Elevee`z')
	global Cantine_Elevee`z' `Cantine_Elevee`z''
	levelsof montant_cantine if Region==`z', local(Cantine_montant`z')
	global Cantine_montant`z' `Cantine_montant`z''
  	
}
restore


**** Bourse Universitaire

preserve
import excel "$xls_sn", sheet(Bourse_universitaire_ref) first clear

levelsof Type, local(type) clean
global TypeBourseUniv `type'
foreach z of local type {
	levelsof Beneficiaires if Type=="`z'", local(Bourse_Beneficiaire`z')
	global Bourse_Beneficiaire`z' `Bourse_Beneficiaire`z''
	levelsof montant if Type=="`z'", local(Bourse_montant`z')
	global Bourse_montant`z' `Bourse_montant`z''
  	
}
restore



**** Education

preserve
import excel "$xls_sn", sheet(education_raw_ref) first clear

levelsof Niveau, local(Niveau) clean
global Education `Niveau'
foreach z of local Niveau {
	levelsof Montant if Niveau=="`z'", local(Edu_montant`z')
	global Edu_montant`z' `Edu_montant`z''
  	
}
restore

*==================================================================================
*==============                Subvention Electricité  					===========
*==================================================================================


preserve
import excel "$xls_sn", sheet(Subvention_electricite_raw_ref) first clear

keep if Type=="DPP"
levelsof Threshold, local(tholds)
global tholdsDPP `tholds'
foreach z of local tholds {
	levelsof Max  if Threshold=="`z'", local(Max`z')
	global Max`z' `Max`z''
    levelsof Subvention  if Threshold=="`z'", local(Subvention`z') 
	global Subvention`z' `Subvention`z''

}
restore


preserve
import excel "$xls_sn", sheet(Subvention_electricite_raw_ref) first clear

keep if Type=="DMP"
levelsof Threshold, local(tholds)
global tholdsDPP `tholds'
foreach z of local tholds {
	levelsof Max  if Threshold=="`z'", local(Max`z')
	global Max`z' `Max`z''
    levelsof Subvention  if Threshold=="`z'", local(Subvention`z') 
	global Subvention`z' `Subvention`z''

}
restore

preserve
import excel "$xls_sn", sheet(Subvention_electricite_raw_ref) first clear

keep if Type=="DGP"
levelsof Threshold, local(tholds)
global tholdsDPP `tholds'
foreach z of local tholds {
	levelsof Max  if Threshold=="`z'", local(Max`z')
	global Max`z' `Max`z''
    levelsof Subvention  if Threshold=="`z'", local(Subvention`z') 
	global Subvention`z' `Subvention`z''

}
restore



*==================================================================================
*==============                Subvention Electricité  					===========
*==================================================================================


preserve 

import excel "$xls_sn", sheet(settingshide) first clear
mkmat value ,  mat(settings)
 
restore 




