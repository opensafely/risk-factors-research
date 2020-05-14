********************************************************************************
*
*	Do-file:		rp_parametric_survival_models_roy.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		cr_create_analysis_dataset_STSET_CPNS.dta
*
*	Data created:	abs_risks_roy.dta (absolute risks)
*
*	Other output:	Log file:  rp_parametric_survival_models_roy.log
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using the Royston-Parmar
*					flexible hazard modelling. 
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************



* Open a log file
capture log close
log using "./output/rp_parametric_survival_models_roy", text replace

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





*********************
*   Royston-Parmar  *
*********************

* Create dummy variables for categorical predictors 
foreach var of varlist obese4cat smoke_nomiss imd  		///
	asthmacat diabcat cancer_exhaem_cat cancer_haem_cat ///
	reduced_kidney_function_cat	region					///
	{
		egen ord_`var' = group(`var')
		qui summ ord_`var'
		local max=r(max)
		forvalues i = 1 (1) `max' {
			gen `var'_`i' = (`var'==`i')
		}	
		drop ord_`var'
		drop `var'_1
}

timer clear 1
timer on 1
stpm2  age1 age2 age3 male 					///
			obese4cat_*						///
			smoke_nomiss_*					///
			imd_* 							///
			htdiag_or_highbp				///
			chronic_respiratory_disease 	///
			asthmacat_*						///
			chronic_cardiac_disease 		///
			diabcat_*						///
			cancer_exhaem_cat_*	 			///
			cancer_haem_cat_*  				///
			chronic_liver_disease 			///
			stroke_dementia		 			///
			other_neuro						///
			reduced_kidney_function_cat_*	///
			organ_transplant 				///
			spleen 							///
			ra_sle_psoriasis  				///
			other_immunosuppression			///
			region_*,						///
			scale(hazard) df(5) eform
estat ic
timer off 1
timer list 1





*****************************************************
*   Survival predictions from Royston-Parmar model  *
*****************************************************


* Survival at t
predict surv_royp, surv

* Survival at 30 days
gen told = _t
replace _t = 30
predict surv30_royp, surv

* Survival at 60 days
replace _t = 60
predict surv60_royp, surv

* Survival at 80 days
replace _t = 60
predict surv80_royp, surv
replace _t = told
drop told

* Absolute risk at 30, 60 and 80 days
gen risk_royp = 1-surv_royp
gen risk30_royp = 1-surv30_royp
gen risk60_royp = 1-surv60_royp
gen risk80_royp = 1-surv80_royp




/*  Quantiles of predicted 30, 60 and 80 day risk   */

centile risk30_royp, c(20 40 60 80)
centile risk60_royp, c(20 40 60 80)
centile risk80_royp, c(20 40 60 80)




*************************************
*   Summarise risks by comorbidity  *
*************************************


/*  Post into dataset   */

tempname temprf 

postfile `temprf' str30(rf) rfcat sex age risk30 risk60 risk80  ///
	using abs_risks_roy, replace

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
					
					* Mean risk of event at 60 days among age and sex group
					qui summ risk60 if smoke_nomiss==`k' & comorbidity_any==`l'
					local r60 = r(mean)
					
					* Mean risk of event at 80 days among age and sex group
					qui summ risk80 if  smoke_nomiss==`k' & comorbidity_any==`l'
					local r80 = r(mean)
					
					post `temprf'  ("Smoking, comorb=`l'") (`k')  (`j') (`i') (`r30') (`r60') (`r80')
				}
			}
		}
	}
	
	
	* Other comorbidity groups?
	
	
postclose `temprf'





log close





