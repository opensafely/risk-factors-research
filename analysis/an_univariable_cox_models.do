********************************************************************************
*
*	Do-file:		an_univariable_cox_models.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Fizz & Krishnan
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
log using "./output/an_univariable_cox_models", text replace

use egdata, clear



**************************
*  Age and sex - no STP  *
**************************

/*
stset stime_died, fail(died) enter(enter_date) origin(enter_date) id(patient_id) 

timer on 1

* Cox model for age and sex
stcox age1 age2 age3 i.male
timer off 1
*/





*****************
*  Age and sex  *
*****************


foreach outcome of any ecdsevent ituadmission cpnsdeath onscoviddeath{

	stset stime_`outcome', fail(`outcome') enter(enter_date) origin(enter_date) id(patient_id) 

	* Cox model for age
	stcox age1 age2 age3 i.male, strata(stp) 
	estimates save ./output/models/an_univariable_cox_models_`outcome'_AGESPLSEX_, replace
	est store base
	estat ic

	stcox i.agegroup i.male, strata(stp) 
	estimates save ./output/models/an_univariable_cox_models_`outcome'_AGEGROUPSEX_`var', replace
	estat ic
	
	foreach var of varlist 	bmicat 							///
							obese40							///
							smoke 							///
							currentsmoke					///
							ethnicity 						///
							imd 							///
							bpcat 							///
							bphigh 							///
							chronic_respiratory_disease 	///
							asthma 							///
							chronic_cardiac_disease 		///
							diabetes 						///
							cancer_exhaem_lastyr 			///
							haemmalig_aanaem_bmtrans_lastyr ///
							chronic_liver_disease 			///
							stroke_dementia		 			///
							other_neuro					 	///
							chronic_kidney_disease 			///
							organ_transplant 				///
							spleen							/// 
							ra_sle_psoriasis  				///
							/*endocrine?*/					///
							/*immunosuppression?*/			///
							{		
		local b
		if "`var'"=="bmicat" local b "b2" /*group 2 is the baseline for BMI, baseline for all others is lowest level*/
		timer clear
		timer on 1
		stcox age1 age2 age3 male i`b'.`var', strata(stp) 
		estimates save ./output/models/an_univariable_cox_models_`outcome'_AGESPLSEX_`var', replace
		timer off 1
		timer list
		} /*end of looping round vars for 1 var at a time models*/

} /*end of looping round outcomes*/




* Close log file
log close
