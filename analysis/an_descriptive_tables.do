********************************************************************************
*
*	Do-file:		an_descriptive_tables.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		cr_create_analysis_dataset.dta
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

use cr_create_analysis_dataset, clear


**********************************
*  Distribution in whole cohort  *
**********************************


* Demographics
summ age
tab agegroup
tab male
tab bmicat
tab bmicat, m
tab obese4cat
tab smoke
tab smoke, m
tab bpcat
tab bpcat, m
tab htdiag_or_highbp


* Comorbidities
tab chronic_respiratory_disease
tab asthma
tab asthmacat
tab chronic_cardiac_disease
tab diabetes
tab diabcat
tab cancer_exhaem_cat
tab cancer_haem_cat
tab chronic_liver_disease
tab dementia
tab stroke
tab stroke_dementia
tab other_neuro
tab reduced_kidney_function_cat
tab dialysis
tab organ_transplant
tab spleen
tab ra_sle_psoriasis
tab other_immunosuppression

tab imd 
tab imd, m
tab ethnicity
tab ethnicity, m
*tab urban
tab region


* Outcomes
tab onscoviddeath
tab cpnsdeath
tab ituadmission
* tab ecds





**********************************
*  Number (%) with each outcome  *
**********************************

foreach outvar of varlist onscoviddeath cpnsdeath /*ituadmission*/ {

*** Repeat for each outcome

	* Demographics
	tab agegroup 							`outvar', col
	tab male 								`outvar', col
	tab bmicat 								`outvar', col m 
	tab smoke 								`outvar', col m
	tab obese4cat							`outvar', col m 

	* Comorbidities
	tab chronic_respiratory_disease 		`outvar', col
	tab asthma 								`outvar', col
	tab asthmacat							`outvar', col
	tab chronic_cardiac_disease 			`outvar', col
	tab diabetes 							`outvar', col
	tab diabcat 							`outvar', col
	tab cancer_exhaem_cat					`outvar', col
	tab cancer_haem_cat						`outvar', col
	tab chronic_liver_disease 				`outvar', col
	tab stroke 								`outvar', col
	tab dementia 							`outvar', col
	tab stroke_dementia 					`outvar', col
	tab other_neuro 						`outvar', col
	tab reduced_kidney_function_cat			`outvar', col
	tab dialysis							`outvar', col
	tab organ_transplant 					`outvar', col
	tab spleen 								`outvar', col
	tab ra_sle_psoriasis					`outvar', col
	tab other_immunosuppression				`outvar', col
	
	tab imd  								`outvar', col m
	tab ethnicity 							`outvar', col m
	*tab urban 								`outvar', col
	tab region 								`outvar', col
}


********************************************
*  Cumulative incidence of ONS COVID DEATH *
********************************************

use "cr_create_analysis_dataset_STSET_onscoviddeath.dta", clear

sts list , at(0 80) by(agegroup male) fail

***************************************
*  Cumulative incidence of CPNS DEATH *
***************************************

use "cr_create_analysis_dataset_STSET_cpnsdeath.dta", clear

sts list , at(0 80) by(agegroup male) fail



* Close the log file
log close


