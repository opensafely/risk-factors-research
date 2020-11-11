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





capture program drop get_coefs
program define get_coefs
	syntax , coef_matrix(string) dataname(string) [eqname(string)]

	global terms: colfullnames `coef_matrix'
	tokenize $terms 
	
	
	local i = 1
	while "``i''" != "" {

		* Remove eqname prefix, e.g. "onscoviddeath:
		local length_prefix = length("`eqname'") + 1
		local term_`i' = substr("``i''", `length_prefix', .)			
			
		* Save the value of coefficient
		if substr("`term_`i'''", 1, 7)!=":_d_rcs"  { 	
			local coef_`i' = _b["`term_`i''"]
		}
		else {
			local coef_`i' = 99999
		}
	local ++i
	}

	
	
	* Save coefficients and variable expressions into a temporary dataset
	tempname coefs_pf
	postfile `coefs_pf' str50(term) coef str50(varexpress) ///
		using `dataname', replace
		local max = `i' - 1
		forvalues k = 1 (1) `max' {
				post `coefs_pf' ("`term_`k''") (`coef_`k'') ("`varexpress_`k''")
	}		

			
	postclose `coefs_pf'
	
end







capture program drop get_ses
program define get_ses
	syntax , se_matrix(string) dataname(string) [eqname(string)]

	global terms: colfullnames `se_matrix'
	tokenize $terms 
	
	
	local i = 1
	while "``i''" != "" {

		* Remove eqname prefix, e.g. "onscoviddeath:
		local length_prefix = length("`eqname'") + 1
		local term_`i' = substr("``i''", `length_prefix', .)			
			
		* Save the value of coefficient
		if substr("`term_`i'''", 1, 7)!=":_d_rcs"  { 	
			local coef_`i' = _se["`term_`i''"]
		}
		else {
			local coef_`i' = 99999
		}
	local ++i
	}

	
	
	* Save coefficients and variable expressions into a temporary dataset
	tempname coefs_pf
	postfile `coefs_pf' str50(term) se  ///
		using `dataname', replace
		local max = `i' - 1
		forvalues k = 1 (1) `max' {
				post `coefs_pf' ("`term_`k''") (`coef_`k'') 
	}		

			
	postclose `coefs_pf'
	
end






*************************************************
*   Use a complete case analysis for ethnicity  *
*************************************************

use "../../hiv-research/analysis/cr_create_analysis_dataset.dta", replace

drop if ethnicity>=.
drop ethnicity_*
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


tab hosp
tab death




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





************************************
*   Change variables to fit model  *
************************************

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





********************************
*   Fit Royston-Parmar model   *
********************************


/*  Death  */

stset stime_death, fail(death) 				///
		id(patient_id) enter(enter_date) origin(enter_date)




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
	


* Pick up coefficient matrix
matrix b = e(b)
matrix V = e(V)

get_coefs, coef_matrix(b) dataname(output/hrs_death) eqname("xb:")

matrix a = vecdiag(V)
get_ses, se_matrix(a) dataname(output/hrs_se_death) eqname("xb:")



/*  Hospitalisation  */


stset stime_hosp, fail(hosp) 				///
		id(patient_id) enter(enter_date) origin(enter_date)




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
	


* Pick up coefficient matrix
matrix b = e(b)
matrix V = e(V)

get_coefs, coef_matrix(b) dataname(output/hrs_hosp) eqname("xb:")

matrix a = vecdiag(V)
get_ses, se_matrix(a) dataname(output/hrs_se_hosp) eqname("xb:")




log close

