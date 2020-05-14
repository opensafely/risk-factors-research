********************************************************************************
*
*	Do-file:		rp_parametric_survival_models_gamma.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		cr_create_analysis_dataset_STSET_CPNS.dta
*
*	Data created:	abs_risks_gamma.dta (absolute risks by comorbidity)
*
*	Other output:	Log file:  an_parametric_survival_models_cpnsdeath.log
*
********************************************************************************
*
*	Purpose:		This do-file performs generalized gamma survival models (AFT). 
*  
********************************************************************************


* Open a log file
capture log close
log using "./output/rp_parametric_survival_models_gamma", text replace

use "cr_create_analysis_dataset_STSET_cpnsdeath.dta", clear


********************************************
*   Comorbidity counts for assessing risk  *
********************************************

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




*******************************
*   Generalized gamma models  *
*******************************


* At present: no ethnicity
timer clear 1
timer on 1
streg age1 age2 age3 i.male 				///
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
			i.region,						///
			dist(ggamma) 
timer off 1
timer list 1

estat ic

streg, tratio


/*  Wald tests to compare against other distributions  */

* Null: Weibull distribution (i.e. kappa=1)
test _b[/kappa] = 1

* Null: lognormal distribution (i.e. kappa=0)
test _b[/kappa] = 0




/*  Survival predictions from gamma model  */

* Survival at t
predict surv, surv

* Survival at 30 days
gen told = _t
replace _t = 30
predict surv30, surv

* Survival at 60 days
replace _t = 60
predict surv60, surv

* Survival at 80 days
replace _t = 60
predict surv80, surv
replace _t = told

* Absolute risk at 30, 60 and 80 days
gen risk = 1-surv
gen risk30 = 1-surv30
gen risk60 = 1-surv60
gen risk80 = 1-surv80




/*  Quantiles of predicted 30, 60 and 80 day risk   */

centile risk30, c(20 40 60 80)
centile risk60, c(20 40 60 80)
centile risk80, c(20 40 60 80)




*************************************
*   Summarise risks by comorbidity  *
*************************************


/*  Post into dataset   */

tempname temprf 

postfile `temprf' str30(rf) rfcat sex age risk30 risk60 risk80 using abs_risks_gamma, replace

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

					* Mean risk of event at 30 days among age and sex group
					qui summ risk30 if  `var'==`k'
					local r30 = r(mean)								
					
					* Mean risk of event at 60 days among age and sex group
					qui summ risk60 if  `var'==`k'
					local r60 = r(mean)
					
					* Mean risk of event at 80 days among age and sex group
					qui summ risk80 if  `var'==`k' 
					local r80 = r(mean)
										
					post `temprf'  ("`var'") (`k') (`j') (`i') (`r30') (`r60') (`r80')
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

					* Mean risk of event at 30 days among age and sex group
					qui summ risk30 if  `var'==`k' 
					local r30 = r(mean)		
					
					* Mean risk of event at 60 days among age and sex group
					qui summ risk60 if  `var'==`k' 
					local r60 = r(mean)					
					
					* Mean risk of event at 80 days among age and sex group
					qui summ risk80 if  `var'==`k'
					local r80 = r(mean)

					post `temprf'  ("`var'") (`k')  (`j') (`i') (`r30') (`r60') (`r80')
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

					* Mean risk of event at 30 days among age and sex group
					qui summ risk30 if  smoke_nomiss==`k' & comorbidity_any==`l'
					local r30 = r(mean)
					
					* Mean risk of event at 80 days among age and sex group
					qui summ risk80 if  smoke_nomiss==`k' & comorbidity_any==`l'
					local r80 = r(mean)
					
					* Mean risk of event at 60 days among age and sex group
					qui summ risk60 if smoke_nomiss==`k' & comorbidity_any==`l'
					local r60 = r(mean)
					
					post `temprf'  ("Smoking, comorb=`l'") (`k')  (`j') (`i') (`r30') (`r60') (`r80')
				}
			}
		}
	}
	
	
	* Other comorbidity groups?
	
	
postclose `temprf'






************************
*  Accounting for STP  *
************************


* Modelling ancillary parameter by STP
timer clear 1
timer on 1
streg age1 age2 age3 i.male 				///
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
			i.other_immunosuppression,		///
			dist(ggamma)  ancillary(i.stp)
timer off 1
timer list 1



log close






