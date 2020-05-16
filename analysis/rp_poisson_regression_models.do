********************************************************************************
*
*	Do-file:		rp_poisson_regression_models.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		cr_create_analysis_dataset_STSET_CPNS.dta
*
*	Data created:	output/abs_risks_poisson.out (table of absolute risks)
*					output/abs_risks_weibull.out
*
*	Other output:	Log file:  rp_poisson_regression_models.log
*					Model estimates: rp_poisson_regression_models.ster
*
********************************************************************************
*
*	Purpose:		This do-file selects series of case-control samples moving
*					across time to perform Poisson regression to obtain 
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
log using "./output/rp_poisson_regression_models", text replace
cap erase ./output/models/rp_poisson_regression_models.ster




*************************
*  Parameters required  *
*************************


set seed 37873
noi di "Sampling fraction for controls = " $sampling_frac
 


***************
*  Open data  *
***************

use "cr_create_analysis_dataset_STSET_cpnsdeath.dta", clear
tab cpnsdeath 


*************************************************
*   Use a complete case analysis for ethnicity  *
*************************************************

drop if ethnicity>=.



*******************
*  Select sample  *
*******************

* Identify all deaths occurring over the next month, starting each two-week
* period (i.e. overlapping 28-day periods) 
* In each two-week period: Select a sample comprising all cases and a random
* selection of controls (people at risk at start of period)
forvalues t = 2 (1) 5 {
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
forvalues t = 2 (1) 5 {
	preserve 
	keep if case`t'==1 | control`t'==1
	gen outcome = 1 if case`t'==1
	replace outcome = 0 if outcome==.
	gen time = `t'
	gen days_fup = min(28, (_t - (`t'-1)*14))
	replace days_fup = 0.5 if days_fup==0
	drop case* control* atrisk* _* stime*
	save time`t'.dta, replace
	restore
}
use time2.dta, clear
forvalues t = 3 (1) 5 {
	append using time`t'.dta	
}
forvalues t = 2 (1) 5 {
	erase time`t'.dta
}

tab outcome time  
 



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






*************************
*   Poisson regression  *
*************************

gen pw = 1 if outcome==1
replace pw = 1/$sampling_frac if outcome==0

* At present: no ethnicity
timer clear 1
timer on 1
poisson outcome age1 age2 age3 i.male 		///
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
			i.time [pweight=pw],			///
			cluster(patient_id) exposure(days_fup)
timer off 1
timer list 1
estat ic

estimates
estimates save ./output/models/rp_poisson_regression_models.ster, replace
poisson, irr
 

* Obtain absolute predictions, correcting the intercept for the control sampling
gen days_fup_old = days_fup
replace days_fup = 28
predict pr0, pr(0,0)
gen risk28 = 1 - pr0
replace days_fup = days_fup_old
drop days_fup_old



/*  Quantiles of predicted 28 day risk   */

centile risk28, c(10 20 30 40 50 60 70 80 90)




*************************************
*   Summarise risks by comorbidity  *
*************************************


/*  Post into dataset   */

tempname temprf 

postfile `temprf' str30(rf) rfcat sex age risk28 using ///
	output/abs_risks_poisson, replace

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


preserve
use "output/abs_risks_poisson", clear
outsheet using "output/abs_risks_poisson", replace
erase "output/abs_risks_poisson.dta"
restore







*************************
*   Weibull regression  *
*************************



rename reduced_kidney_function_cat red_kidney_cat
rename chronic_respiratory_disease respiratory_disease
rename chronic_cardiac_disease cardiac_disease
rename other_immunosuppression immunosuppression



stset days_fup [pweight=pw], fail(outcome)

* At present: no ethnicity
timer clear 1
timer on 1
streg       age1 age2 age3 i.male 			///
			i.obese4cat						///
			i.smoke_nomiss					///
			i.imd 							///
			i.htdiag_or_highbp				///
			i.respiratory_disease 			///
			i.asthmacat						///
			i.cardiac_disease 				///
			i.diabcat						///
			i.cancer_exhaem_cat	 			///
			i.cancer_haem_cat  				///
			i.chronic_liver_disease 		///
			i.stroke_dementia		 		///
			i.other_neuro					///
			i.red_kidney_cat				///
			i.organ_transplant 				///
			i.spleen 						///
			i.ra_sle_psoriasis  			///
			i.immunosuppression				///
			i.region 						///
			i.time,							///
			cluster(patient_id) dist(weibull) 
timer off 1
timer list 1
estat ic

estimates
estimates save ./output/models/rpweibull_regression_models.ster, replace
streg, hr
 

* Obtain absolute predictions, correcting the intercept for the control sampling
capture drop risk28
gen told = _t
replace _t = 28
predict risk28, surv
replace _t = told
drop told



/*  Quantiles of predicted 28 day risk   */

centile risk28, c(10 20 30 40 50 60 70 80 90)




*************************************
*   Summarise risks by comorbidity  *
*************************************


/*  Post into dataset   */

tempname temprf 

postfile `temprf' str30(rf) rfcat sex age risk28 using ///
	output/abs_risks_weibull, replace

	* Binary risk factors
	foreach var of varlist 						///
				htdiag_or_highbp				///
				respiratory_disease 			///
				cardiac_disease 				///
				chronic_liver_disease 			///
				stroke_dementia		 			///
				other_neuro						///
				organ_transplant 				///
				spleen 							///
				ra_sle_psoriasis  				///
				immunosuppression    {
					
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
	local max_red_kidney_cat = 3
					

	foreach var of varlist 						///
				obese4cat						///
				smoke_nomiss					///
				imd 							///
				asthmacat						///
				diabcat							///
				cancer_exhaem_cat	 			///
				cancer_haem_cat  				///
				red_kidney_cat    {
					
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


preserve
use "output/abs_risks_weibull", clear
outsheet using "output/abs_risks_weibull", replace
erase "output/abs_risks_weibull.dta"
restore




log close




