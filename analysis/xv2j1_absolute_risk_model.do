********************************************************************************
*
*	Do-file:		xj1_absolute_risk_model.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		cr_create_analysis_dataset_STSET_onscoviddeath.dta
*
*	Data created:	output/abs_risks_`ethnicity'.dta, for ethnicity = 1,2,..,5
*
*	Other output:	Log file:  xj1_absolute_risk_model_`ethnicity'.log
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using Royston-Parmar
*					flexible hazard modelling. 
*
*					These analyses will be helpful in considering how 
*					comorbidities and demographic factors affect risk, 
*					comparatively.
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************



local ethnicity `1' 
noi di "`ethnicity'"

local outcome `2'
noi di "`outcome'"


* Open a log file
capture log close
log using "./output/xv2j1_absolute_risk_model_`ethnicity'_`outcome'", text replace



*************************************************
*   Use a complete case analysis for ethnicity  *
*************************************************


* Stset for outcome of interest
if "`outcome'"=="death" {
	use "../hiv-research/analysis/cr_create_analysis_dataset_STSET_onsdeath_fail1.dta", replace
}
else if "`outcome'"=="hosp" {
	use "../hiv-research/analysis/cr_create_analysis_dataset.dta", replace
	qui summ stime_covidadmission
	global covid_admissiondeathcensor = r(max)
	gen newstime_covidadmission 	= min($covid_admissiondeathcensor, covid_admission_date)
	gen byte new_covidadmission = (covid_admission_date < .)
	replace covidadmission 	= 0 if (newstime_covidadmission > $covid_admissiondeathcensor) 
}

drop if ethnicity>=.
drop ethnicity_*



********************************************
*   Comorbidity counts for assessing risk  *
********************************************

* Create absent/present for categorical comorbidities
recode asthma 				1=0 2/3=1, gen(asthmabin)
recode diabcat 				1=0 2/4=1, gen(diabbin)
recode cancer_exhaem_cat 	1=0 2/4=1, gen(cancer_exhaem_bin)
recode cancer_haem_cat 		1=0 2/4=1, gen(cancer_haem_bin)
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
			other_imm_except_hiv	 		///
			hiv								///
			)
drop asthmabin diabbin cancer_exhaem_bin cancer_haem_bin kidneybin

recode comorbidity_count 1/max=1 0=0, gen(comorbidity_any)


* Create numerical region variable
encode region, gen(region_new)
drop region
rename region_new region





********************************
*   Fit Royston-Parmar model   *
********************************

* Shorten variable names where necessary
rename reduced_kidney_function_cat 	red_kidney_cat
rename chronic_respiratory_disease 	respiratory_disease
rename chronic_cardiac_disease 		cardiac_disease
rename other_imm_except_hiv 		immunosuppression


* Create dummy variables for categorical predictors 
foreach var of varlist obese4cat smoke_nomiss imd  		///
	asthmacat diabcat cancer_exhaem_cat cancer_haem_cat ///
	red_kidney_cat region ethnicity						///
	{
		egen ord_`var' = group(`var')
		qui summ ord_`var'
		local max=r(max)
		forvalues i = 1 (1) `max' {
			gen `var'_`i' = (ord_`var'==`i')
		}	
		drop ord_`var'
		drop `var'_1
}


timer clear 1
timer on 1
stpm2  age1 age2 age3 male 					///
			ethnicity_*						///
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
			hiv								///
			region_*,						///
			scale(hazard) df(5) eform
estat ic
timer off 1
timer list 1








*****************************************************
*   Survival predictions from Royston-Parmar model  *
*****************************************************

* Predict absolute risk at 80 days
gen time80 = 80
predict surv80_royp, surv timevar(time80)
gen risk80_royp = 1-surv80_royp
drop surv80_royp

/*  Quantiles of predicted 30, 60 and 80 day risk   */

centile risk80_royp, c(50 70 80 90)

global p50 = r(c_1) 
global p70 = r(c_2) 
global p80 = r(c_3) 
global p90 = r(c_4) 




*************************************
*   Split age more finely in 60-80  *
*************************************

drop agegroup 

recode age  min/39	= 1 	///
			40/49 	= 2 	///
			50/59 	= 3 	///
			60/64 	= 4 	///
			65/69 	= 5 	///
			70/74 	= 6 	///
			75/79 	= 7 	///
			80/max	= 8, gen(agegroup)

label define agegroup_fine  ///
				1  "18-<40"	///
				2  "40-<50"	///
				3  "50-<60"	///
				4  "60-<65"	///
				5  "65-<70"	///
				6  "70-<75"	///
				7  "75-<80" ///
				8  "80+"  

label values agegroup agegroup_fine
tab agegroup, m



*********************************************************
*   Obtain predicted risks by comorbidity with 95% CIs  *
*********************************************************

* Collapse data to one row per age-group, with age set to the median within the group
bysort agegroup (age): gen order 	= _n
bysort agegroup (age): gen revorder = _N - _n
gen diff = abs(order-revord)
keep if diff<=1
bysort agegroup: keep if _n==1

* Keep only variables needed for the risk prediction
keep agegroup age? _rcs1- _d_rcs5  _st _d _t _t0

* Create two rows per agegroup (male and female)
expand 2
bysort agegroup: gen male = _n-1

* Set time to 80 days (for the risk prediction period)
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
gen hiv 						= 0

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

* Ethnicity - default white
gen ethnicity_2 =0
gen ethnicity_3 =0 
gen ethnicity_4 =0 
gen ethnicity_5 =0 
if `ethnicity'==2 {
	replace ethnicity_2 =1
}
else if `ethnicity'==3 {
	replace ethnicity_3 =1	
}
else if `ethnicity'==4 {
	replace ethnicity_4 =1	
}
else if `ethnicity'==5 {
	replace ethnicity_5 =1	
}



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
		hiv									///
		{
				
	* Reset that value to "yes"
	replace `var' = 1
	
	* Predict under that comorbidity (age and sex left at original values)
	predict pred80_`var', surv timevar(time80) ci
	
	* Change to risk, not survival
	gen risk80_`var' = 1 - pred80_`var'
	gen risk80_`var'_lci = 1 - pred80_`var'_uci
	gen risk80_`var'_uci = 1 - pred80_`var'_lci
	drop pred80_`var' pred80_`var'_uci  pred80_`var'_lci
	
	* Reset that value back to "no"
	replace `var' = 0
}

keep agegroup male risk*


* Save relevant percentiles
gen p50 = $p50 
gen p70 = $p70 
gen p80 = $p80 
gen p90 = $p90 


* Save data
save "output/abs_risks_`ethnicity'_`outcome'", replace



log close

