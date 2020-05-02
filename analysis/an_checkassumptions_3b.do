********************************************************************************
*
*	Do-file:		an_checkassumptions_3b.do
*
*	Project:		Risk factors for poor outcomes in Covid-19; Ethnicity MNAR
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		cr_create_analysis_dataset.dta
*
*	Data created:	imputed.dta  (imputed data)
*
*	Other output:	Log file output/an_checkassumptions_3
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
*	
*	Stata routines required:		ice (ssc install ice),  and 
*									user-written programs in the do files 
*									in the first two lines below
*
********************************************************************************




* Open a log file
capture log close
log using "output/an_checkassumptions_3b", text replace

* Load user written functions
do Calibration_parameter_nlsolution.do  
do Calibration_parameter_estimation.do  



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




* Open a log file
capture log close
log using "output/an_checkassumptions_MI_combine", text replace



**************************
*  Combine imputed data  *
**************************

* Put imputed data together (across regions)
use imputed_1.dta, clear
forvalues k= 1 (1) 9	{
append using imputed_`k'
}
save imputed, replace
forvalues k= 1 (1) 9	{
*erase imputed_`k'.dta
}

* Add imputations to the full dataset
use cr_create_analysis_dataset.dta, clear
merge 1:1 patient_id using imputed.dta

* Create ID version for exportation into Stata mi impute
gen _mi = _n


/*  Import into -mi- format  */

mi import wide, imputed(ethnicity = ethnicity1 ethnicity2 	///
ethnicity3 ethnicity4 ethnicity5) drop clear




**************************
*  Analyse imputed data  *
**************************



// Analysis model

mi stset stime_cpnsdeath, fail(cpnsdeath) enter(enter_date)	///
	origin(enter_date) id(patient_id)

	
// Check if the MI distribution of ethnicity matches that in the census
mi estimate: prop ethnicity 
tab ethnicity
	
* "Analysis" Cox model  (without STP stratification and age splines)
mi estimate, eform: 							///
	stcox 	agegroup_*  						///
			male 								///
			obese4cat_*							///
			smoke_nomiss_*						///
			imd_*								///
			htdiag_or_highbp					///
			chronic_respiratory_disease 		///
			asthmacat_* 						///
			chronic_cardiac_disease 			///
			diabcat_* 							///
			cancer_exhaem_cat_* 				///
			cancer_haem_cat_*  					///
			chronic_liver_disease 				///
			stroke_dementia		 				///
			other_neuro							///
			chronic_kidney_disease 				///
			organ_transplant 					///
			spleen 								///
			ra_sle_psoriasis  					///
			other_immunosuppression 			///
			, strata(stp)

log close




	