********************************************************************************
*
*	Do-file:		an_checkassumptions_3c.do
*
*	Project:		Risk factors for poor outcomes in Covid-19; Ethnicity MNAR
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		cr_create_analysis_dataset.dta
*					imputed.dta (imputed data, combined across regions)
*
*	Data created:	None. Models on screen.
*
*	Other output:	Log file output/an_checkassumptions_MI_estimate
*
********************************************************************************
*
*	Purpose:		This do-file fits a sensitivity analysis for missing 
*					ethnicity, using multiple imputation incorporating 
*					information from external data sources (e.g. census)
*					about the marginal proportions of ethnic groups 
*					within broad geographical regions. 
*  
********************************************************************************




* Open a log file
capture log close
log using "output/an_checkassumptions_MI_estimate", text replace



********************************   NOTES  **************************************

*  Assumes region is string, taking  values: 
*    East, East Midlands, London, North East, North West, South East, 
*    South West, West Midlands, and Yorkshire and The Humber
*
*  Assumes ethnicity is numeric, taking values: 
*	1, 2, 3, 4, 5, (missing: . or .u)
*	in the order White, Black, Asian, Mixed, Other
*	with value labels exactly as above. 
*	(NB: this is now intially recoded from ordering: 
*      White, Mixed, Asian, Black, Other)	
*
*
*  Assumes a complete case sample other than ethnicity
*
********************************************************************************



* Add imputations to the full dataset
use cr_create_analysis_dataset.dta, clear
merge 1:1 patient_id using imputed.dta



/*   Prepare data to be imported   */


* Create ID version for exportation into Stata mi impute
gen _mi = _n

* Change imputed ethnicity to the original coding (switch mixed and black)
label define ethnicity 	1 "White"  					///
						2 "Mixed" 					///
						3 "Asian or Asian British"	///
						4 "Black"  					///
						5 "Other"					///
						.u "Unknown", replace
label values ethnicity ethnicity

forvalues i = 1 (1) 5 {
	recode ethnicity`i' 2=4 4=2
	label values ethnicity`i' ethnicity
}


recode ethnicity .u=.

/*  Import into -mi- format  */


mi import wide, imputed(ethnicity = ///
						ethnicity1  ///
						ethnicity2 	///
						ethnicity3 	///
						ethnicity4 	///
						ethnicity5) drop clear





**************************
*  Analyse imputed data  *
**************************


// Declare imputed data as survival

mi stset stime_cpnsdeath, fail(cpnsdeath) enter(enter_date)	///
	origin(enter_date) id(patient_id)

	
// Check if the MI distribution of ethnicity matches that in the external data
mi estimate: prop ethnicity 
tab ethnicity



* Primary analysis using imputed data
mi estimate, eform: 							///
	stcox 	i.ethnicity							///
			age1 age2 age3						///
			i.male 								///
			i.obese4cat							///
			i.smoke_nomiss						///
			i.imd								///
			i.htdiag_or_highbp					///
			i.chronic_respiratory_disease 		///
			i.asthmacat 						///
			i.chronic_cardiac_disease 			///
			i.diabcat 							///
			i.cancer_exhaem_cat 				///
			i.cancer_haem_cat	  				///
			i.chronic_liver_disease 			///
			i.stroke_dementia		 			///
			i.other_neuro						///
			i.reduced_kidney_function_cat		///
			i.organ_transplant 					///
			i.spleen 							///
			i.ra_sle_psoriasis  				///
			i.other_immunosuppression 			///
			, strata(stp)
			
estimates save ./output/models/an_checkassumptions_3c_cpnsdeath_MAINFULLYADJMODEL_agespline_bmicat_MIeth, replace			
			

* Primary analysis using imputed data, with grouped age
mi estimate, eform: 							///
	stcox 	i.ethnicity							///
			ib3.agegroup							///
			i.male 								///
			i.obese4cat							///
			i.smoke_nomiss						///
			i.imd								///
			i.htdiag_or_highbp					///
			i.chronic_respiratory_disease 		///
			i.asthmacat 						///
			i.chronic_cardiac_disease 			///
			i.diabcat	 						///
			i.cancer_exhaem_cat 				///
			i.cancer_haem_cat	  				///
			i.chronic_liver_disease 			///
			i.stroke_dementia		 			///
			i.other_neuro						///
			i.reduced_kidney_function_cat		///
			i.organ_transplant 					///
			i.spleen 							///
			i.ra_sle_psoriasis  				///
			i.other_immunosuppression 			///
			, strata(stp)
			
estimates save ./output/models/an_checkassumptions_3c_cpnsdeath_MAINFULLYADJMODEL_agegroup_bmicat_MIeth, replace			
			
log close

