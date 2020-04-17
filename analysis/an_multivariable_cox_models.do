********************************************************************************
*
*	Do-file:		an_multivariable_cox_models.do
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		egdata.dta
*
*	Data created:	None
*
*	Other output:	Log file:  an_multivariable_cox_models.log
*
********************************************************************************
*
*	Purpose:		This do-file performs multivariable (fully adjusted) 
*					Cox models. 
*  
********************************************************************************
*	
*	Stata routines needed:	stbrier	  
*
********************************************************************************




* Open a log file
capture log close
log using "an_multivariable_cox_models", text replace

use egdata, clear

******************************
*  Multivariable Cox models  *
******************************



/* Death  */

stset stime_died, fail(died) enter(enter_date) origin(enter_date) id(patient_id) 


stcox 	age1 age2 age3 male i.bmicat i.smoke							///
		resp asthma heart diabetes cancer liver neuro_dis kidney_dis 	///
		transplant spleen immunosup hypertension autoimmune sle 		///
		endocrine														///
		, strata(stp) 

		
* Obtain C-statistic
estat concordance



* Add IBS 

* Calculate at 60 days
stbrier, bt(60) efron

/*
stbrier age1 age2 age3 male i.bmicat i.smoke							///
		resp asthma heart diabetes cancer liver neuro_dis kidney_dis 	///
		transplant spleen immunosup hypertension autoimmune sle 		///
		endocrine														///
		, shared(stp) bt(60) 											///
		ipcw(age1 age2 age3 male i.bmicat i.smoke						///
		resp asthma heart diabetes cancer liver neuro_dis kidney_dis 	///
		transplant spleen immunosup hypertension autoimmune sle 		///
		endocrine)
*/

* Simple model just to try:
stbrier age1 age2 age3 male 											///
		, shared(stp) bt(60) 											///
		ipcw(age1 age2 age3 male)



* Close log file  (bootstrapping likely to take a while)
log close





/*   Add bootstrapping to correct C-statistic for overoptimism     */

* ADD BOOTSTRAP HERE!



