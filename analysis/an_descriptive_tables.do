********************************************************************************
*
*	Do-file:		an_descriptive_tables.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		egdata.dta
*
*	Data created:	None
*
*	Other output:	Log file: an_descriptive_tables.log
*
********************************************************************************
*
*	Purpose:		This do-file runs some basic tabulations on the analysis
*					dataset.
*  
********************************************************************************



* Open a log file
capture log close
log using "an_descriptive_tables", text replace



**********************************
*  Distribution in whole cohort  *
**********************************


* Demographics
summ age
tab agegroup
tab male
tab bmicat
tab smoke

* Comorbidities
tab resp
tab asthma
tab heart
tab diabetes
tab cancer
tab liver
tab neuro_dis
tab kidney_dis
tab transplant
tab spleen
tab immunosup
tab hypertension
tab autoimmune
tab sle
tab endocrine

* Adjustment variables 
tab imd 
*tab ethnicity
*tab urban


* Outcomes
tab died
tab itu
tab hosp
* tab compoutcome



**********************************
*  Number (%) with each outcome  *
**********************************

foreach outvar of varlist died hosp itu {

*** Repeat for each outcome

	* Demographics
	tab agegroup 		`outvar', row
	tab male 			`outvar', row
	tab bmicat 			`outvar', row
	tab smoke 			`outvar', row

	* Comorbidities
	tab resp 			`outvar', row
	tab asthma 			`outvar', row
	tab heart 			`outvar', row
	tab diabetes 		`outvar', row
	tab cancer 			`outvar', row
	tab liver 			`outvar', row
	tab neuro_dis 		`outvar', row
	tab kidney_dis 		`outvar', row
	tab transplant 		`outvar', row
	tab spleen 			`outvar', row
	tab immunosup		`outvar', row
	tab hypertension	`outvar', row
	tab autoimmune		`outvar', row
	tab sle				`outvar', row
	tab endocrine		`outvar', row

	* Adjustment variables 
	tab imd  			`outvar', row
	*tab ethnicity 		`outvar', row
	*tab urban 			`outvar', row
}



* Close the log file
log close


