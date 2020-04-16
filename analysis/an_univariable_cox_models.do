********************************************************************************
*
*	Do-file:		an_univariable_cox_models.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		egdata.dta
*
*	Data created:	None
*
*	Other output:	Log file: an_univariable_cox_models.log 
*
*
********************************************************************************
*
*	Purpose:		This do-file is a very initial draft of Stata code to 
*					do poor outcomes analysis.
*  
********************************************************************************



* Open a log file
capture log close
log using "an_univariable_cox_models", text replace



*****************
*  Age and sex  *
*****************


/* Death  */

stset stime_died, fail(died) enter(enter_date) origin(enter_date) id(patient_id) 

* Cox model for age
stcox age1 age2 age3 male, strata(stp) 
est store base
estat ic

stcox i.agegroup male, strata(stp) 
estat ic



/* ITU  */

stset stime_itu, fail(itu) enter(enter_date) origin(enter_date) id(patient_id) 

* Cox model for age
stcox age1 age2 age3 male, strata(stp) 
est store base
estat ic

stcox i.agegroup male, strata(stp) 
estat ic





*********************************
*  Age, sex, IMD and ethnicity  *
*********************************


/* Death  */

stset stime_died, fail(died) enter(enter_date) origin(enter_date) id(patient_id) 

* Cox model for age
stcox age1 age2 age3 male, strata(stp) 
est store base
estat ic

stcox i.agegroup male, strata(stp) 
estat ic



/* ITU  */

stset stime_itu, fail(itu) enter(enter_date) origin(enter_date) id(patient_id) 

* Cox model for age
stcox age1 age2 age3 male, strata(stp) 
est store base
estat ic

stcox i.agegroup male, strata(stp) 
estat ic






************************
*  Other risk factors  *
************************

* To be added



chronic_respiratory_disease 	///
						chronic_cardiac_disease 		///
						diabetes lung_cancer 			///
						haem_cancer						///
						other_cancer 					///
						bone_marrow_transplant 			///
						chemo_radio_therapy 			///
						chronic_liver_disease 			///
						neurological_condition 			///
						chronic_kidney_disease 			///
						organ_transplant 				///	
						spleen 							///
						sickle_cell 					///
						aplastic_anaemia 				///
						hiv 							///
						genetic_immunodeficiency 		///
						immunosuppression_nos 			///
						ra_sle_psoriasis 


* Close log file
log close
