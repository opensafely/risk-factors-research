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
tab cancer_exhaem_lastyr
tab haemmalig_aanaem_bmtrans_lastyr
tab chronic_liver_disease
tab other_neuro
tab chronic_kidney_disease
tab organ_transplant
tab chronic_kidney_disease
tab organ_transplant
tab spleen
tab ra_sle_psoriasis
* tab immunosuppressed
						    
tab bpcat

summ bp_sys,  detail
summ bp_dias, detail

tab imd 
tab imd, m
*tab ethnicity
tab ethnicity, m
*tab urban


* Outcomes
tab onscoviddeath
tab cpnsdeath
tab ituadmission
* tab ecds



**********************************
*  Number (%) with each outcome  *
**********************************

foreach outvar of varlist onscoviddeath cpnsdeath ituadmission {

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
	tab cancer_exhaem_lastyr				`outvar', row

	tab haemmalig_aanaem_bmtrans_lastyr 	`outvar', row
	tab chronic_liver_disease 				`outvar', row
	tab other_neuro 						`outvar', row
	tab chronic_kidney_disease 				`outvar', row
	tab organ_transplant 					`outvar', row
	tab spleen 								`outvar', row
	tab ra_sle_psoriasis					`outvar', row
	
	tab imd  								`outvar', row
	*tab ethnicity 							`outvar', row m
	*tab urban 								`outvar', row
}



* Close the log file
log close


