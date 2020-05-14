********************************************************************************
*
*	Do-file:		rp_logistic_regression_models.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		cr_create_analysis_dataset_STSET_CPNS.dta
*
*	Data created:	abs_risks_logistic.dta (Stata dataset containing 
*					table of absolute risks)
*
*	Other output:	Log file:  rp_logistic_regression_models.log
*					Model estimates: rp_logistic_regression_models.ster
*
********************************************************************************
*
*	Purpose:		This do-file selects series of case-control samples moving
*					across time to perform logistic regression to obtain 
*					absolute risk estimates. 
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************


* Sampling fraction for controls - take as an input
global sampling_frac `1' 
* 0.003 for real data; 0.2 for dummy data



* Open a log file
capture log close
log using "./output/rp_logistic_regression_models", text replace
cap erase ./output/models/rp_logistic_regression_models.ster




*************************
*  Parameters required  *
*************************


set seed 37873
noi di "Sampling fraction for controls = " $sampling_frac
 


****************************
*  Open and select sample  *
****************************

use "cr_create_analysis_dataset_STSET_cpnsdeath.dta", clear
tab cpnsdeath 


* Identify all deaths occurring over the next month, starting each two-week
* period (i.e. overlapping 28-day periods) 
* In each two-week period: Select a sample comprising all cases and a random
* selection of controls (people at risk at start of period)
forvalues t = 1 (1) 6 {
		local lb = (`t' - 1)*14 
		local ub = `lb' + 28
		gen case`t' = (cpnsdeath==1 & inrange(_t, `lb', `ub'))
		gen atrisk`t' = _t>`lb'
		gen control`t' = (uniform()<$sampling_frac) if atrisk`t'==1
}

* Delete people who are neither case nor control
egen case = rowtotal(case?)
tab case
egen control = rowtotal(control?)
tab control
drop if case==0 & control==0  

* Combine separate case-control samples
forvalues t = 1 (1) 6 {
	preserve 
	keep if case`t'==1 | control`t'==1
	gen outcome = 1 if case`t'==1
	replace outcome = 0 if outcome==.
	drop case* control* atrisk* _* stime*
	gen time = `t'
	save time`t'.dta, replace
	restore
}
use time1.dta, clear
forvalues t = 2 (1) 6 {
	append using time`t'.dta	
}
forvalues t = 1 (1) 6 {
	erase time`t'.dta
}




*******************************
*  Create variables required  *
*******************************


/*   Comorbidity counts for assessing risk  */

* Create absent/present for categorical comorbidities
recode asthma 1=0 2/3=1, gen(asthmabin)
recode diabcat 1=0 2/4=1, gen(diabbin)
recode cancer_exhaem_cat 1=0 2/4=1, gen(cancer_exhaem_bin)
recode cancer_haem_cat 1=0 2/4=1, gen(cancer_haem_bin)
recode reduced_kidney_function_cat 1=0 2/3=1, gen(kidneybin)

* Count comorbidities present
egen comorbidity_count = rowtotal(			///
			htdiag_or_highbp				///
			chronic_respiratory_disease 	///
			asthmabin 						///
			chronic_cardiac_disease 		///
			diabbin 						///
			cancer_exhaem_bin 				///
			cancer_haem_bin 				///
			chronic_liver_disease 			///
			stroke_dementia		 			///
			kidneybin		 				///
			other_neuro						///
			organ_transplant 				///
			spleen 							///
			ra_sle_psoriasis  				///
			other_immunosuppression 		///
			)
drop asthmabin diabbin cancer_exhaem_bin cancer_haem_bin kidneybin

recode comorbidity_count 1/max=1 0=0, gen(comorbidity_any)


* Create numerical region variable
encode region, gen(region_new)
drop region
rename region_new region






**************************
*   Logistic regression  *
**************************


* At present: no ethnicity
timer clear 1
timer on 1
logit outcome age1 age2 age3 i.male 		///
			i.obese4cat						///
			i.smoke_nomiss					///
			i.imd 							///
			i.htdiag_or_highbp				///
			i.chronic_respiratory_disease 	///
			i.asthmacat						///
			i.chronic_cardiac_disease 		///
			i.diabcat						///
			i.cancer_exhaem_cat	 			///
			i.cancer_haem_cat  				///
			i.chronic_liver_disease 		///
			i.stroke_dementia		 		///
			i.other_neuro					///
			i.reduced_kidney_function_cat	///
			i.organ_transplant 				///
			i.spleen 						///
			i.ra_sle_psoriasis  			///
			i.other_immunosuppression		///
			i.region						///
			i.time, cluster(patient_id)
timer off 1
timer list 1

estimates
estimates save ./output/models/rp_logistic_regression_models.ster, replace


* Obtain absolute predictions, correcting the intercept for the control sampling
predict xb, xb
replace xb = xb + log($sampling_frac) 
gen risk28 = exp(xb)/(1 + exp(xb))



/*  Quantiles of predicted 28 day risk   */

centile risk28, c(20 40 60 80)




*************************************
*   Summarise risks by comorbidity  *
*************************************


/*  Post into dataset   */

tempname temprf 

postfile `temprf' str30(rf) rfcat sex age risk28 using abs_risks_logistic, replace

	* Binary risk factors
	foreach var of varlist 						///
				htdiag_or_highbp				///
				chronic_respiratory_disease 	///
				chronic_cardiac_disease 		///
				chronic_liver_disease 			///
				stroke_dementia		 			///
				other_neuro						///
				organ_transplant 				///
				spleen 							///
				ra_sle_psoriasis  				///
				other_immunosuppression    {
					
		forvalues i = 1 (1) 6 {
			forvalues j = 0 (1) 1 {
				forvalues k = 0 (1) 1 {

					* Mean risk of event among age and sex group
					qui summ risk28 if  `var'==`k' 
					local r28 = r(mean)
					
					post `temprf'  ("`var'") (`k') (`j') (`i') (`r28')
				}
			}
		}
	}

	* Categorical risk factors
	local max_obese4cat 			= 4
	local max_smoke_nomiss			= 3	
	local max_imd 					= 5	
	local max_asthmacat				= 3	
	local max_diabcat				= 4	
	local max_cancer_exhaem_cat		= 4	 
	local max_cancer_haem_cat  		= 4 
	local max_reduced_kidney_function_cat = 3
					
	foreach var of varlist 						///
				obese4cat						///
				smoke_nomiss					///
				imd 							///
				asthmacat						///
				diabcat							///
				cancer_exhaem_cat	 			///
				cancer_haem_cat  				///
				reduced_kidney_function_cat    {
					
		forvalues i = 1 (1) 6 {
			forvalues j = 0 (1) 1 {	
				forvalues k = 1 (1) `max_`var'' {
					
					* Mean risk of event among age and sex group
					qui summ risk28 if  `var'==`k'
					local r28 = r(mean)
							
					post `temprf'  ("`var'") (`k')  (`j') (`i') (`r28') 
				}
			}
		}
	}
	
	
	/*  Grouped comorbidity  */
	
	* Smoking with no other disease vs other disease 
	forvalues i = 1 (1) 6 {
		forvalues j = 0 (1) 1 {	
			forvalues k = 1 (1) `max_smoke_nomiss' {
				forvalues l = 0 (1) 1 {
					
					* Mean risk of event among age and sex group
					qui summ risk28 if  smoke_nomiss==`k' & comorbidity_any==`l'
					local r28 = r(mean)
					
					post `temprf'  ("Smoking, comorb=`l'") (`k')  (`j') (`i') (`r28') 
				}
			}
		}
	}
	
	
	* Other comorbidity groups?
	
	
postclose `temprf'








