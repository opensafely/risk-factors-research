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
use cr_create_analysis_dataset, clear


*Duplicate patient check
datacheck _n==1, by(patient_id) nol


******************************************
*  Check variables take expected values  *
******************************************

* Age
datacheck age<., nol
datacheck inlist(agegroup, 1, 2, 3, 4, 5, 6), nol
datacheck inlist(age70, 0, 1), nol

* Sex
datacheck inlist(male, 0, 1), nol

* BMI 
datacheck inlist(obese4cat, 0, 1), nol
datacheck inlist(bmicat, 1, 2, 3, 4, 5, 6, .u), nol

* IMD
datacheck inlist(imd, 1, 2, 3, 4, 5, .u), nol

* Ethnicity
datacheck inlist(ethnicity, 1, 2, 3, 4, 5, .u), nol

* Smoking
datacheck inlist(smoke, 1, 2, 3, .u), nol
datacheck inlist(smoke_nomiss, 1, 2, 3), nol

* Blood pressure
datacheck inlist(bpcat, 1, 2, 3, 4, .u), nol





***************************************
*  Cross-check logical relationships  *
***************************************


* BMI
bysort bmicat: summ bmi
tab bmicat obese4cat, m

* Age
bysort agegroup: summ age
tab agegroup age70, m

* Smoking
tab smoke smoke_nomiss, m

* Blood pressure
tab bpcat bphigh, m

* Asthma
tab asthma asthmacat, m

* Diabetes
tab diabetes diabcat, m



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

summ stime_ituadmission stime_cpnsdeath stime_onscoviddeath,   format
summ itu_date died_date_ons died_date_cpns died_date_onscovid, format





****************************************
*  Cross-check expected relationships  *
****************************************


/*  Relationships between demographic/lifestyle variables  */

tab agegroup bmicat, 	col row
tab agegroup smoke, 	col row
tab agegroup ethnicity, col row 
tab agegroup imd, 		col row
tab agegroup bpcat, 	col row

tab bmicat smoke, 		col row 
tab bmicat ethnicity, 	col row
tab bmicat imd, 		col row
tab bmicat bpcat, 		col row

tab smoke ethnicity, 	col row 
tab smoke imd, 			col row 
tab smoke bpcat, 		col row

tab ethnicity imd, 		col row
tab ethnicity bpcat, 	col row

tab imd bpcat, 			col row



/*  Relationships with demographic/lifestyle variables  */

* Relationships with age
foreach var of varlist 	chronic_respiratory_disease 	///
						asthma 							///
						asthmacat						///
						chronic_cardiac_disease 		///
						diabetes 						///
						diabcat	 						///
						cancer_exhaem_cat				///
						cancer_haem_cat 				///
						chronic_liver_disease 			///
						other_neuro			 			///
						chronic_kidney_disease			///
						organ_transplant 				///	
						spleen							///
						ra_sle_psoriasis  				///
						other_immunosuppression	{
	tab agegroup `var', row col
}


* Relationships with sex
foreach var of varlist 	chronic_respiratory_disease 	///
						asthma 							///
						asthmacat						///
						chronic_cardiac_disease 		///
						diabetes 						///
						diabcat	 						///
						cancer_exhaem_cat				///
						cancer_haem_cat 				///
						chronic_liver_disease 			///
						other_neuro			 			///
						chronic_kidney_disease			///
						organ_transplant 				///	
						spleen							///
						ra_sle_psoriasis   				///
						other_immunosuppression {
	tab male `var', row col
}

* Relationships with smoking
foreach var of varlist chronic_respiratory_disease 	///
						asthma 							///
						asthmacat						///
						chronic_cardiac_disease 		///
						diabetes 						///
						diabcat	 						///
						cancer_exhaem_cat				///
						cancer_haem_cat 				///
						chronic_liver_disease 			///
						other_neuro			 			///
						chronic_kidney_disease			///
						organ_transplant 				///	
						spleen							///
						ra_sle_psoriasis   				///
						other_immunosuppression  				{
	tab smoke `var', row col
}



/*  Relationships between conditions  */


* Respiratory
tab chronic_respiratory_disease asthma, row col
tab chronic_respiratory_disease asthmacat, row col

* Cardiac
tab diabetes chronic_cardiac_disease, row col
tab chronic_cardiac_disease bpcat, row col

* Liver
tab chronic_liver_disease organ_transplant, row col





********************************************
*  Cross-check logical date relationships  *
********************************************

* Cross check dates of hosp/itu/death??

tab onscoviddeath cpnsdeath, row col





* Close log file 
log close


