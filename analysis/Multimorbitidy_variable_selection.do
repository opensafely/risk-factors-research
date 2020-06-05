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
log using "output/Multimorbidity_variable_selection", text replace

use "cr_create_analysis_dataset.dta", clear

* Keep cases and randomly sample controls
set seed 8842
sample 15000, by(onscoviddeath) count



* All pairwise interactions (full model)
timer clear 1
timer on 1
lasso logit onscoviddeath i.(agegroup 								///
							ethnicity 								///
							male 									///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression)##i.(agegroup 	///
							male 									///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression), 				///
							selection(plugin)
lassocoef, display(coef, postselection)
timer off 1
timer list 1

						


* All pairwise interactions (full model with cross-validation, 50 times slower)
timer clear 1
timer on 1
lasso logit onscoviddeath i.(agegroup 								///
							ethnicity 								///
							male 									///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression)##i.(agegroup 	///
							male 									///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression) 			
lassocoef, display(coef, postselection)
timer off 1
timer list 1




/*   

		IF THE ABOVE FAILS TO CONVERGE: TRY...


* All pairwise interactions (full model)
timer clear 1
timer on 1
lasso logit onscoviddeath i.(agegroup male ethnicity)##i.(agegroup 	///
							male 									///
							ethnicity								///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression), 				///
							selection(plugin)
lassocoef, display(coef, postselection)
timer off 1
timer list 1

						


* All pairwise interactions (full model with cross-validation, 50 times slower)
timer clear 1
timer on 1
lasso logit onscoviddeath i.(agegroup 								///
							ethnicity 								///
							male)##i.(agegroup 						///
							male 									///
							obese4cat								///
							smoke_nomiss							///
							imd										///
							htdiag_or_highbp						///
							chronic_respiratory_disease 			///
							asthmacat 								///
							chronic_cardiac_disease 				///
							diabcat 								///
							cancer_exhaem_cat 						///
							cancer_haem_cat	  						///
							chronic_liver_disease 					///
							stroke_dementia		 					///
							other_neuro								///
							reduced_kidney_function_cat				///
							organ_transplant 						///
							spleen 									///
							ra_sle_psoriasis  						///
							other_immunosuppression) 			
lassocoef, display(coef, postselection)
timer off 1
timer list 1


*/


* Close the log file
log close

