********************************************************************************
*
*	Do-file:			Multimorbidity_cluster_analysis.do
*
*	Written by:			Fizz
*
*	Data used:			cr_create_analysis_dataset.dta
*
*	Data created:		output/cluster_desc (spreadsheet, tab delimited)
*						output/cluster.dta 
*							(the latter not to be extracted from server, 
*							  just there in case of data checking needed)
*
*	Other output:		None
*
********************************************************************************
*
*	Purpose:			This do-file runs a simple cluster analysis by age-group
*						sex and ethnic group, to identify commonly co-occurring
*						comorbidities.
*
********************************************************************************



local numcluster = 10


* Open a log file
capture log close
log using "output/Multimorbidity_cluster_analysis", text replace



* Separately inspect subgroups of a particular age, sex and ethnic group
forvalues i = 1 (1) 6 {
	forvalues j = 0 (1) 1 {
		forvalues k = 1 (1) 5 {
		    
			use "cr_create_analysis_dataset.dta", clear
			keep if agegroup==`i'
			keep if male==`j'
			keep if ethnicity==`k'

			* Sub-sample (take whole subgroup or 20,000 whichever is biggest)
			qui count
			if r(N) > 20000 {
				set seed 17248
				sample 20000, count
			}


			* Create dummy variables for categorical predictors
			foreach var of varlist obese4cat smoke_nomiss imd  ///
				asthmacat diabcat cancer_exhaem_cat cancer_haem_cat		///
				reduced_kidney_function_cat		 {
					egen ord_`var' = group(`var')
					qui summ ord_`var'
					local max=r(max)
					forvalues l = 1 (1) `max' {
						gen `var'_`l' = (`var'==`l')
					}	
					drop ord_`var'
					drop `var'_1
			}



			* Cluster analysis of binary characteristics
			set seed 123789
			cluster kmeans 	obese4cat_*							///
							smoke_nomiss_*						///
							imd_*								///
							htdiag_or_highbp					///
							chronic_respiratory_disease 		///
							asthmacat_* 						///
							chronic_cardiac_disease 			///
							diabcat_* 							///
							cancer_exhaem_cat_* 				///
							cancer_haem_cat_*	  				///
							chronic_liver_disease 				///
							stroke_dementia		 				///
							other_neuro							///
							reduced_kidney_function_cat_*		///
							organ_transplant 					///
							spleen 								///
							ra_sle_psoriasis  					///
							other_immunosuppression 			///
					,  k(`numcluster') measure(Jaccard) 		///
					name(group_`numcluster')
			
			preserve
			keep patient_id agegroup male ethnicity group_`numcluster'
			save cluster_`i'_`j'_`k', replace
			restore
			
			* Summarise characteristics by group
			tempname temp
			postfile `temp' agegroup male ethnicity group str30(var) pc ///
				using cluster_desc_`i'_`j'_`k', replace

				forvalues l = 1 (1) 10 {
					* Size of group 
					qui count
					local N=r(N)
					qui count if group_`numcluster'==`l' 
					local pgp = r(N)/`N'
				
					post `temp' (`i') (`j') (`k') (`l') ("N") (`pgp')
										
					foreach var of varlist obese4cat_*			///
							smoke_nomiss_*						///
							imd_*								///
							htdiag_or_highbp					///
							chronic_respiratory_disease 		///
							asthmacat_* 						///
							chronic_cardiac_disease 			///
							diabcat_* 							///
							cancer_exhaem_cat_* 				///
							cancer_haem_cat_*	  				///
							chronic_liver_disease 				///
							stroke_dementia		 				///
							other_neuro							///
							reduced_kidney_function_cat_*		///
							organ_transplant 					///
							spleen 								///
							ra_sle_psoriasis  					///
							other_immunosuppression {
							
							qui summ `var' if group_`numcluster'==`l'	
							post `temp' (`i') (`j') (`k') (`l') ("`var'") (r(mean))
						}	
				}

			postclose `temp'
		}
	}
}

* Combine clustering (in case useful for later)
forvalues i = 1 (1) 6 {
	forvalues j = 0 (1) 1 {
		forvalues k = 1 (1) 5 {
			if `i'==1 & `j'==0 & `k'==1 {
				use cluster_`i'_`j'_`k'.dta, clear
			}
			else {
				append using cluster_`i'_`j'_`k'.dta
			}
			erase cluster_`i'_`j'_`k'.dta
		}
	}
}
save "output/cluster.dta", replace


* Combine descriptions
use cluster_desc_1_1_1, clear

* Combine descriptions of clusters
forvalues i = 1 (1) 6 {
	forvalues j = 0 (1) 1 {
		forvalues k = 1 (1) 5 {
			if `i'==1 & `j'==0 & `k'==1 {
				use cluster_desc_`i'_`j'_`k'.dta, clear
			}
			else {
				append using cluster_desc_`i'_`j'_`k'.dta
			}
			erase cluster_desc_`i'_`j'_`k'.dta
		}
	}
}
reshape wide pc, i( agegroup ethnicity male var) j(group)
save "output/cluster_desc", replace


use "output/cluster_desc", clear
outsheet using "output/cluster_desc", replace
erase "output/cluster_desc.dta"



	
* Close the log file
log close


