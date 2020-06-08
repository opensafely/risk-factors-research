********************************************************************************
*
*	Do-file:			Multimorbidity_variable_selection.do
*
*	Written by:			Fizz
*
*	Data used:			cr_create_analysis_dataset.dta
*
*	Data created:		None
*
*	Other output:		output/Multimorbidity_variable_selection
*
********************************************************************************
*
*	Purpose:			This do-file runs a simple lasso model on a sample of 
*						data (all cases, random sample of controls) to variable
*						select from all possible pairwise interactions.
*
********************************************************************************



* Open a log file
capture log close
log using "output/Multimorbidity_variable_selection_K_full", text replace

use "cr_create_analysis_dataset_STSET_onscoviddeath.dta", clear
*keep if _d==1| uniform()<0.003

stsplit timeband, at(60)

gen diedcovforpoisson = _d
gen exposureforpoisson = _t-_t0

* Keep cases and randomly sample controls
*set seed 8842
*sample 15000, by(onscoviddeath) count

for var male htdiag_or_highbp chronic_respiratory_disease chronic_cardiac_disease chronic_liver_disease stroke_dementia other_neuro organ_transplant spleen ra_sle_psoriasis other_immunosuppression: replace X = X+1

recode agegroup 1=18 2=40 3=1 4=60 5=70 6=80
label values agegroup

foreach var of varlist agegroup ethnicity male obese4cat smoke_nomiss imd htdiag_or_highbp	chronic_respiratory_disease asthmacat 	chronic_cardiac_disease diabcat cancer_exhaem_cat cancer_haem_cat chronic_liver_disease stroke_dementia other_neuro reduced_kidney_function_cat organ_transplant spleen ra_sle_psoriasis other_immunosuppression {
		local list "agegroup ethnicity male obese4cat smoke_nomiss imd htdiag_or_highbp	chronic_respiratory_disease asthmacat 	chronic_cardiac_disease diabcat cancer_exhaem_cat cancer_haem_cat chronic_liver_disease stroke_dementia other_neuro reduced_kidney_function_cat organ_transplant spleen ra_sle_psoriasis other_immunosuppression"
			local listexcept = subinstr("`list'", "`var'", " ", 1)
			local intlist "`intlist' io1.(`var')#io1.(`listexcept')"					
							}
di "`intlist'"

* All pairwise interactions (full model)
timer clear 1
timer on 1
lasso poisson diedcovforpoisson (i.agegroup 								///
							i.ethnicity 							///
							i.male 									///
							i.obese4cat								///
							i.smoke_nomiss							///
							i.imd									///
							i.htdiag_or_highbp						///
							i.chronic_respiratory_disease 			///
							i.asthmacat 							///
							i.chronic_cardiac_disease 				///
							i.diabcat 								///
							i.cancer_exhaem_cat 					///
							i.cancer_haem_cat	  					///
							i.chronic_liver_disease 				///
							i.stroke_dementia		 				///
							i.other_neuro							///
							i.reduced_kidney_function_cat			///
							i.organ_transplant 						///
							i.spleen 								///
							i.ra_sle_psoriasis  					///
							i.other_immunosuppression i.timeband) 	///
							`intlist'								///
							, selection(plugin) exp(exposureforpoisson)
lassocoef, display(coef, postselection eform)
timer off 1
timer list 1

						


* Close the log file
log close

