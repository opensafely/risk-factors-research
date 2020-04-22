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
tab dementia
tab stroke
tab stroke_dementia
* tab immunosuppressed
						    
tab bpcat

*summ bp_sys,  detail
*summ bp_dias, detail

tab imd 
tab imd, m
tab ethnicity
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
	tab agegroup 							`outvar', col
	tab male 								`outvar', col
	tab bmicat 								`outvar', col m 
	tab smoke 								`outvar', col m
	tab obese 								`outvar', col m 
	tab current								`outvar', col m

	* Comorbidities
	tab chronic_respiratory_disease 		`outvar', col
	tab asthma 								`outvar', col
	tab chronic_cardiac_disease 			`outvar', col
	tab diabetes 							`outvar', col
	tab cancer_exhaem_lastyr				`outvar', col

	tab haemmalig_aanaem_bmtrans_lastyr 	`outvar', col
	tab chronic_liver_disease 				`outvar', col
	tab other_neuro 						`outvar', col
	tab chronic_kidney_disease 				`outvar', col
	tab organ_transplant 					`outvar', col
	tab spleen 								`outvar', col
	tab ra_sle_psoriasis					`outvar', col
	
	tab imd  								`outvar', col
	tab ethnicity 							`outvar', col m
	*tab urban 								`outvar', col
}



* Close the log file
log close


