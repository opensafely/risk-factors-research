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




*************************************************
*   Use a complete case analysis for ethnicity  *
*************************************************

foreach outcome in death hosp {



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




	* Pick up coefficient matrix
	matrix b = e(b)
	mat list b

	local cols = (colsof(b) + 1)/2
	local cols2 = `cols' +3
	mat c = b[1,`cols2'..colsof(b)]
	mat list c

	*  Save coefficients to Stata dataset  
	do "analysis/0000_pick_up_coefficients.do"

	* Save coeficients needed for prediction models
	get_coefs, coef_matrix(c) eqname("xb0:") ///
		dataname("output/hrs_`outcome'")
		
		
	
}

use output/hrs_death, clear
gen outcome = "death"
append using output/hrs_hosp.dta







log close

