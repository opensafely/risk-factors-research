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



/* Loop through other outcomes */






************************
*  Other risk factors  *
************************

* To be added




* Close log file
log close
