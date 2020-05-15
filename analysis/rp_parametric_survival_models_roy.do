********************************************************************************
*
*	Do-file:		rp_parametric_survival_models_roy.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		cr_create_analysis_dataset_STSET_CPNS.dta
*
*	Data created:	output/abs_risks_roy.out (absolute risks)
*					output/abs_risks2_roy.out
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


*************************************************
*   Use a complete case analysis for ethnicity  *
*************************************************

drop if ethnicity>=.




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


rename reduced_kidney_function_cat red_kidney_cat
rename chronic_respiratory_disease respiratory_disease
rename chronic_cardiac_disease cardiac_disease
rename other_immunosuppression immunosuppression


* Create dummy variables for categorical predictors 
foreach var of varlist obese4cat smoke_nomiss imd  		///
	asthmacat diabcat cancer_exhaem_cat cancer_haem_cat ///
	red_kidney_cat	region					///
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
			respiratory_disease			 	///
			asthmacat_*						///
			cardiac_disease 				///
			diabcat_*						///
			cancer_exhaem_cat_*	 			///
			cancer_haem_cat_*  				///
			chronic_liver_disease 			///
			stroke_dementia		 			///
			other_neuro						///
			red_kidney_cat_*				///
			organ_transplant 				///
			spleen 							///
			ra_sle_psoriasis  				///
			immunosuppression				///
			region_*,						///
			scale(hazard) df(5) eform
estat ic
timer off 1
timer list 1





*****************************************************
*   Survival predictions from Royston-Parmar model  *
*****************************************************

gen time30 = 30
gen time60 = 60
gen time80 = 80


* Survival at t
predict surv_royp, surv timevar(_t)

* Survival at 30 days
predict surv30_royp, surv timevar(time30)

* Survival at 60 days
predict surv60_royp, surv timevar(time60)

* Survival at 80 days
predict surv80_royp, surv timevar(time80)


* Absolute risk at 30, 60 and 80 days
gen risk_royp   = 1-surv_royp
gen risk30_royp = 1-surv30_royp
gen risk60_royp = 1-surv60_royp
gen risk80_royp = 1-surv80_royp




/*  Quantiles of predicted 30, 60 and 80 day risk   */

centile risk30_royp, c(10 20 30 40 50 60 70 80 90)
centile risk60_royp, c(10 20 30 40 50 60 70 80 90)
centile risk80_royp, c(10 20 30 40 50 60 70 80 90)




*************************************
*   Summarise risks by comorbidity  *
*************************************


/*  Post into dataset   */

tempname temprf 

postfile `temprf' str30(rf) rfcat sex age risk30 risk60 risk80  ///
	using output/abs_risks_roy, replace

	* Binary risk factors
	foreach var of varlist 						///
				htdiag_or_highbp				///
				respiratory_disease			 	///
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

					* Mean risk of event at 30 days among age and sex group
					qui summ risk30 if  `var'==`k' & agegroup==`i' & male==`j'
					local r30 = r(mean)
					
					* Mean risk of event at 60 days among age and sex group
					qui summ risk60 if  `var'==`k' & agegroup==`i' & male==`j'
					local r60 = r(mean)
										
					* Mean risk of event at 80 days among age and sex group
					qui summ risk80 if  `var'==`k'  & agegroup==`i' & male==`j'
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
	local max_red_kidney_cat		= 3
					
	foreach var of varlist 						///
				obese4cat						///
				smoke_nomiss					///
				imd 							///
				asthmacat						///
				diabcat							///
				cancer_exhaem_cat	 			///
				cancer_haem_cat  				///
				red_kidney_cat    				{
					
		forvalues i = 1 (1) 6 {
			forvalues j = 0 (1) 1 {	
				forvalues k = 1 (1) `max_`var'' {
					
					* Mean risk of event at 30 days among age and sex group
					qui summ risk30 if  `var'==`k' & agegroup==`i' & male==`j' 
					local r30 = r(mean)
					
					* Mean risk of event at 60 days among age and sex group
					qui summ risk60 if  `var'==`k' & agegroup==`i' & male==`j'
					local r60 = r(mean)
										
					* Mean risk of event at 80 days among age and sex group
					qui summ risk80 if  `var'==`k' & agegroup==`i' & male==`j'
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
					qui summ risk30 if smoke_nomiss==`k'  & agegroup==`i' & male==`j' & comorbidity_any==`l'
					local r30 = r(mean)
					
					* Mean risk of event at 60 days among age and sex group
					qui summ risk60 if smoke_nomiss==`k'  & agegroup==`i' & male==`j' & comorbidity_any==`l'
					local r60 = r(mean)
					
					* Mean risk of event at 80 days among age and sex group
					qui summ risk80 if smoke_nomiss==`k'  & agegroup==`i' & male==`j' & comorbidity_any==`l'
					local r80 = r(mean)
					
					post `temprf'  ("Smoking, comorb=`l'") (`k')  (`j') (`i') (`r30') (`r60') (`r80')
				}
			}
		}
	}
	
	
	* Other comorbidity groups?
	
	
postclose `temprf'


preserve
use "output/abs_risks_roy", clear
outsheet using "output/abs_risks_roy", replace
erase "output/abs_risks_roy.dta"
restore






*********************************************************
*   Obtain predicted risks by comorbidity with 95% CIs  *
*********************************************************


bysort agegroup (age): gen order = _n
bysort agegroup (age): gen revorder = _N - _n
gen diff = abs(order-revord)
keep if diff<=1
bysort agegroup: keep if _n==1

keep agegroup age? _rcs1- _d_rcs5  _st _d _t _t0

expand 2
bysort agegroup: gen male = _n-1

gen time30 = 30
gen time60 = 60
gen time80 = 80


/*  Initially set values to "no comorbidity"  */
		
gen htdiag_or_highbp 			= 0	 
gen respiratory_disease			= 0
gen asthmacat_2  				= 0
gen asthmacat_3 				= 0
gen cardiac_disease 			= 0
gen diabcat_2 					= 0
gen diabcat_3					= 0
gen diabcat_4 					= 0
gen cancer_exhaem_cat_2  		= 0
gen cancer_exhaem_cat_3  		= 0	
gen cancer_exhaem_cat_4 		= 0
gen cancer_haem_cat_2 		 	= 0
gen cancer_haem_cat_3 		 	= 0
gen cancer_haem_cat_4  			= 0
gen chronic_liver_disease 		= 0
gen stroke_dementia 			= 0
gen other_neuro					= 0
gen red_kidney_cat_2 			= 0
gen red_kidney_cat_3 			= 0
gen organ_transplant  			= 0
gen spleen						= 0
gen ra_sle_psoriasis  			= 0
gen immunosuppression 			= 0

gen smoke_nomiss_2 = 0
gen smoke_nomiss_3 =0 			 
gen obese4cat_2 =0 
gen obese4cat_3 =0 
gen obese4cat_4 =0 					
gen imd_2 =0 
gen imd_3 =1 
gen imd_4 =0 
gen imd_5 =0 							
gen region_2= 0	
gen region_3= 0 
gen region_4= 0 
gen region_5= 1 				
gen region_6= 0 
gen region_7= 0 
gen region_8= 0 
gen region_9= 0			



/*  Predict survival at 80 days under each comorbidity separately   */

* Set age and sex to baseline values
gen cons = 0

foreach var of varlist cons 				///
		htdiag_or_highbp 					///
		respiratory_disease 				///
		asthmacat_2  				 		///
		asthmacat_3   				 		///	
		cardiac_disease 					///
		diabcat_2 		 					///
		diabcat_3 		 					///
		diabcat_4 			 				///	
		cancer_exhaem_cat_2  				///
		cancer_exhaem_cat_3  				///
		cancer_exhaem_cat_4  				///
		cancer_haem_cat_2  				 	///
		cancer_haem_cat_3  				 	///
		cancer_haem_cat_4  					///
		chronic_liver_disease 				///
		stroke_dementia 		 			///
		other_neuro							///
		red_kidney_cat_2					///
		red_kidney_cat_3  					///
		organ_transplant  					///
		spleen 								///
		ra_sle_psoriasis   					///
		immunosuppression  					///
		male {
				
	* Reset that value to "yes"
	replace `var' = 1
	
	* Predict under that comorbidity (age and sex left at original values)
	predict pred30_`var', surv timevar(time30) ci
	predict pred60_`var', surv timevar(time60) ci
	predict pred80_`var', surv timevar(time80) ci
				
	* Reset that value back to "no"
	replace `var' = 0
}

keep agegroup male pred*
outsheet using "output/abs_risks2_roy", replace





log close

