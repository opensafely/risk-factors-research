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
*	Other output:	Log file: output/an_descriptive_tables.log
*
********************************************************************************
*
*	Purpose:		This do-file runs some basic tabulations on the analysis
*					dataset.
*  
********************************************************************************



* Open a log file
capture log close
log using "output/an_descriptive_tables", text replace

use egdata, clear

**********************************
*  Distribution in whole cohort  *
**********************************


* Demographics
summ age
tab agegroup
tab male
tab bmicat
tab bmicat, m
tab smoke
tab smoke, m

* Comorbidities
tab chronic_respiratory_disease
tab asthma
tab chronic_cardiac_disease
tab diabetes
tab lung_cancer
tab haem_cancer
tab other_cancer
tab cancer
tab chronic_liver_disease
tab neurological_condition
tab chronic_kidney_disease
tab organ_transplant
tab dysplenia
tab sickle_cell
tab spleen
tab ra_sle_psoriasis
tab immuno_condition

summ bp_sys,  detail
summ bp_dias, detail

* Adjustment variables 
tab imd 
*tab ethnicity
tab ethnicity, m
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
	tab agegroup 							`outvar', row
	tab male 								`outvar', row
	tab bmicat 								`outvar', row m 
	tab smoke 								`outvar', row m

	* Comorbidities
	tab chronic_respiratory_disease 		`outvar', row
	tab asthma 								`outvar', row
	tab chronic_cardiac_disease 			`outvar', row
	tab diabetes 							`outvar', row
	tab lung_cancer 						`outvar', row
	tab haem_cancer 						`outvar', row
	tab other_cancer 						`outvar', row
	tab cancer 								`outvar', row
	tab chronic_liver_disease 				`outvar', row
	tab neurological_condition 				`outvar', row
	tab chronic_kidney_disease 				`outvar', row
	tab organ_transplant 					`outvar', row
	tab dysplenia 							`outvar', row
	tab sickle_cell 						`outvar', row
	tab spleen 								`outvar', row
	tab immuno_condition					`outvar', row
	tab ra_sle_psoriasis					`outvar', row
	
	* Adjustment variables 
	tab imd  								`outvar', row
	*tab ethnicity 							`outvar', row m
	*tab urban 								`outvar', row
}



* Close the log file
log close


