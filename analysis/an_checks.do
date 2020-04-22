********************************************************************************
*
*	Do-file:		an_checks.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		egdata.dta
*
*	Data created:	None
*
*	Other output:	Graphs (cumulative events by time in study):
*						output/events_died.svg
*						output/events_cpns.svg
*						output/events_itu.svg
*
*					Log file: output/an_checks
*
********************************************************************************
*
*	Purpose:		This do-file runs a series of checks and creates a log 
*					file to record them:
*						- check variables take expected values/ranges
*						- cross-check logical relationships
*						- explore expected relationships
*						- check stsettings
*  
********************************************************************************



* Open a log file
capture log close
log using "output/an_checks", text replace

* Open Stata dataset
use egdata, clear



******************************************
*  Check variables take expected values  *
******************************************

* Age
datacheck age<., nol
*assert inrange(age, 18, 105)
datacheck inlist(agegroup, 1, 2, 3, 4, 5, 6), nol
datacheck inlist(age70, 0, 1), nol

* Sex
datacheck inlist(male, 0, 1), nol

* BMI 
* assert inrange(bmi, 10, 200) | bmi==.
datacheck inlist(obese40, 0, 1), nol
datacheck inlist(bmicat, 1, 2, 3, 4, 5, 6, .u), nol

* IMD
datacheck inlist(imd, 1, 2, 3, 4, 5, .u), nol

* Ethnicity
datacheck inlist(ethnicity, 1, 2, 3, 4, 5, .u), nol

* Smoking
datacheck inlist(smoke, 1, 2, 3, .u), nol
datacheck inlist(currentsmoke, 0, 1), nol

* Blood pressure
datacheck inlist(bpcat, 1, 2, 3, 4, .u), nol





***************************************
*  Cross-check logical relationships  *
***************************************


* BMI
bysort bmicat: summ bmi
tab bmicat obese40, m

* Age
bysort agegroup: summ age
tab agegroup age70, m

* Smoking
tab smoke currentsmoke, m

* Blood pressure
tab bpcat bphigh, m



*********************
*  Summarise dates  *
*********************

* BMI
*summ bmi_date_measured, format
/*
* Dates of comorbidities  
foreach var of varlist 	chronic_respiratory_disease 	///
						chronic_cardiac_disease 		///
						diabetes 						///
						chronic_liver_disease 			///
						organ_transplant 				///	
						ra_sle_psoriasis  {

	summ `var'_date, format
	bysort `var': summ `var'_date
}
*/


* Outcome dates
*****??? 
summ stime_ituadmission stime_cpnsdeath stime_onscoviddeath,   format
summ itu_date died_date_ons died_date_cpns died_date_onscovid, format





****************************************
*  Cross-check expected relationships  *
****************************************


/*  Relationships between demographic/lifestyle variables  */

tab agegroup bmicat, 	col
tab agegroup smoke, 	col
tab agegroup ethnicity, col
tab agegroup imd, 		col
tab agegroup bpcat, 	col

tab bmicat smoke, 		col
tab bmicat ethnicity, 	col
tab bmicat imd, 		col
tab bmicat bpcat, 		col

tab smoke ethnicity, 	col
tab smoke imd, 			col
tab smoke bpcat, 		col

tab ethnicity imd, 		col
tab ethnicity bpcat, 	col

tab imd bpcat, 			col



/*  Relationships with demographic/lifestyle variables  */

* Relationships with age
foreach var of varlist 	chronic_respiratory_disease 	///
						asthma 							///
						chronic_cardiac_disease 		///
						diabetes 						///
						cancer_exhaem_lastyr 			///
						haemmalig_aanaem_bmtrans_lastyr ///
						chronic_liver_disease 			///
						other_neuro			 			///
						chronic_kidney_disease			///
						organ_transplant 				///	
						spleen							///
						ra_sle_psoriasis  				{
	tab agegroup `var', r
}


* Relationships with sex
foreach var of varlist 	chronic_respiratory_disease 	///
						asthma 							///
						chronic_cardiac_disease 		///
						diabetes 						///
						cancer_exhaem_lastyr 			///
						haemmalig_aanaem_bmtrans_lastyr ///
						chronic_liver_disease 			///
						other_neuro			 			///
						chronic_kidney_disease			///
						organ_transplant 				///	
						spleen							///
						ra_sle_psoriasis   				{
	tab male `var', r
}


/*  Relationships between conditions  */


* Respiratory
tab chronic_respiratory_disease asthma 

* Cardiac
tab diabetes chronic_cardiac_disease
tab chronic_cardiac_disease bpcat







********************************************
*  Cross-check logical date relationships  *
********************************************

* Cross check dates of hosp/itu/death??






* Close log file 
log close


