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
log using "an_univariable_cox_models", text replace

use egdata, clear
************************************************************************************************************
*!!!! TEMP FIX FOR DODGY DUMMY DATA 
noi di in red _n "*************************************************************************************" ///
	_n "NOTE TEMPORARY DATA MANIP PRESENT FOR TESTING: DELETE FROM DOFILE BEFORE RUNNING LIVE" ///
	_n "*************************************************************************************"
by patient_id: keep if _n==1
replace chronic_kidney_disease=1 if uniform()<0.01
replace neurological_condition=1 if uniform()<0.01
************************************************************************************************************

************************************
*Get composite outcome (nb this may be better added to cr_...;)
gen stime_composite = min(stime_itu, stime_died)
gen composite = (died|itu)
************************************


*****************
*  Age and sex  *
*****************


foreach outcome of any hosp died itu composite{

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
							smoke 							///
							ethnicity 						///
							imd 							///
							bpcat 							///
							chronic_respiratory_disease 	///
							asthma 							///
							chronic_cardiac_disease 		///
							diabetes 						///
							cancer 	/*NB UPDATE*/			///
							chronic_liver_disease 			///
							neurological_condition 			///
							chronic_kidney_disease 			///
							organ_transplant 				///
							spleen ra_sle_psoriasis  		///
							/*endocrine?*/					///
							/*immunosuppression?*/			///
							{
		local b
		if "`var'"=="bmicat" local b "b2"
		stcox age1 age2 age3 male i`b'.`var', strata(stp) 
		estimates save ./output/models/an_univariable_cox_models_`outcome'_AGESPLSEX_`var', replace
		} /*end of looping round vars for 1 var at a time models*/

} /*end of looping round outcomes*/




* Close log file
log close
