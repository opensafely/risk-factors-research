********************************************************************************
*
*	Do-file:		xv2j10_absolute_risk_table.do
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



local outcome `1'
noi di "`outcome'"


* Open a log file
capture log close
log using "./output/xv2j10_absolute_risk_table_`outcome'", text replace



*************************************************
*   Use a complete case analysis for ethnicity  *
*************************************************

use "../../hiv-research/analysis/cr_create_analysis_dataset.dta", replace


********* DEFAULT CENSORING IS MAX OUTCOME DATE MINUS 7 **********
foreach var of varlist 	ons_died_date covid_admission_date {
		*Set default censoring date as max observed minus 7 days
		local endofname = strpos("`var'", "_date")-1
		noi di "end `endofname'"
		local globstem = substr("`var'",1,`endofname')
		noi di "gob `globstem'"
		qui summ `var'
		global `globstem'deathcensor = r(max)-7
		noi di "`globstem'deathcensor"
}

gen stime_hosp = min($covid_admissiondeathcensor, covid_admission_date)
gen byte hosp = (covid_admission_date <= $covid_admissiondeathcensor)
	
gen covid_death = (onsdeath==1)
gen onscovid_date = ons_died_date if covid_death==1
gen stime_death   = min($ons_dieddeathcensor, onscovid_date)
gen byte death = (onscovid_date <= $ons_dieddeathcensor)

	
* Declare data as survival
stset stime_`outcome', fail(`outcome') 				///
	id(patient_id) enter(enter_date) origin(enter_date)

	
* Complete case for ethnicity
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
			scale(hazard) df(10) eform lininit
estat ic
timer off 1
timer list 1






*********************************************************************
*   Obtain predicted risks at 100 days by comorbidity with 95% CIs  *
*********************************************************************

* By
*	Outcome (hosp/death)
*	Age: 50/60/65/70/80
* 	For each ethnic group, no comorbidities

foreach a of numlist 50 60 65 70 80 {
	forvalues j = 2 (1) 3 {
		summ age`j' if age==`a'
		local age`j'_`a'  = r(mean)
	}
}

* Keep only variables needed for the risk prediction
keep _rcs1- _d_rcs5  _st _d _t _t0 

gen     age1 = 50 in 1
replace age1 = 60 in 2
replace age1 = 65 in 3
replace age1 = 70 in 4
replace age1 = 80 in 5

gen age2 = .
gen age3 = .
foreach a of numlist 50 60 65 70 80 {
	forvalues j = 2 (1) 3 {
		replace age`j' = `age`j'_`a'' if age1==`a'
	}
}


* Create two rows per agegroup (male and female)
expand 2
bysort age1: gen male = _n-1

* Create five rows per agegroup (5 ethnicity groups)
expand 2
bysort age1 male: gen ethnicity = _n

forvalues j = 2 (1) 5 {
	gen ethnicity_`j' = (ethnicity==`j')
}

* Set time to 100 days (for the risk prediction period)
gen time100 = 100



/*  No comorbidity  */
		
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


/*  Non smoker, non-obese, middle IMD, region 3  */


gen smoke_nomiss_2 = 0
gen smoke_nomiss_3 = 0 			 
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






******************************************************
*   Obtain predicted risks at 100 days with 95% CIs  *
******************************************************


/*  Predict survival at 100 days under each comorbidity separately   */


predict pred100, surv timevar(time100) ci
	
* Change to risk (per 100,000), not survival
gen risk100 	= (1 - pred100)*100000
gen risk100_lci = (1 - pred100_uci)*100000
gen risk100_uci = (1 - pred100_lci)*100000
drop pred100 pred100_uci pred100_lci


* Save data
save "output/abs_risks_table_`outcome'", replace


log close

