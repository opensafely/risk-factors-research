********************************************************************************
*
*	Do-file:		xv2j5_absolute_risk_model_fineage_group.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		cr_create_analysis_dataset_STSET_onscoviddeath.dta
*
*	Data created:	abs_risks_fineage_`ethnicity', for ethnicity=1,2,...,5
*
*	Other output:	Log file:  xj5_absolute_risk_model_fineage_group_`ethnicity'.log
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
log using "./output/xv2j5_absolute_risk_model_fineage_group_`outcome'", text replace



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

	
	
stset stime_`outcome', fail(`outcome') 				///
	id(patient_id) enter(enter_date) origin(enter_date)


drop if ethnicity>=.
drop ethnicity_*




********************************************
*   Comorbidity counts for assessing risk  *
********************************************

recode asthma 3=1 1/2=0, gen(asthmasev)
recode diabcat 2/4=1 1=0, gen(anydiab)
recode cancer_exhaem_cat 2=1 1 3/4=0,  gen(recentCancEx)
recode cancer_haem_cat 		1=0 2/4=1, gen(cancer_haem_bin)
recode reduced_kidney_function_cat 1=0 2/3=1, gen(kidneybin)


* Count comorbidities present
egen comorbidity_count = rowtotal(			///
			chronic_respiratory_disease 	///
			asthmasev						///
			chronic_cardiac_disease 		///
			anydiab 						///
			recentCancEx 					///
			cancer_haem_bin 				///
			chronic_liver_disease 			///
			stroke_dementia		 			///
			kidneybin		 				///
			organ_transplant 				///
			spleen 							///
			other_imm_except_hiv	 		///
			hiv								///			
			)

recode comorbidity_count 2/max=2 1=1 0=0, gen(comorbid)
label define comorb 0 "None" 1 "One" 2 "2+"
label values comorbid comorb


* Create numerical region variable
encode region, gen(region_new)
drop region
rename region_new region





********************************
*   Fit Royston-Parmar model   *
********************************


* Create dummy variables for categorical predictors 
foreach var of varlist obese4cat smoke_nomiss imd region ethnicity comorbid ///
	{
		egen ord_`var' = group(`var')
		qui summ ord_`var'
		local max=r(max)
		local min=r(min)
		forvalues i = `min' (1) `max' {
			gen `var'_`i' = (ord_`var'==`i')
		}	
		drop ord_`var'
		drop `var'_`min'
}


timer clear 1
timer on 1
stpm2  age1 age2 age3 male 					///
			ethnicity_*						///
			obese4cat_*						///
			smoke_nomiss_*					///
			imd_* 							///
			comorbid_*						///
			region_*,						///
			scale(hazard) df(10) eform lininit
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




*********************************************************
*   Obtain predicted risks by comorbidity with 95% CIs  *
*********************************************************

* Collapse data to one row per age, with age set to the median within the group
bysort age: keep if _n==1

* Keep only variables needed for the risk prediction
keep age age? _rcs1- _d_rcs5  _st _d _t _t0

* Create two rows per agegroup (male and female)
expand 2
bysort age: gen male = _n-1

* Create two rows per agegroup (male and female)
expand 5
bysort age male: gen ethnicity = _n

* Set time to 80 days (for the risk prediction period)
gen time80 = 80



/*  Initially set values to "no comorbidity"  */
		
gen comorbid_2 =0
gen comorbid_3 =0

gen ethnicity_2 = (ethnicity==2)
gen ethnicity_3 = (ethnicity==3)
gen ethnicity_4 = (ethnicity==4)
gen ethnicity_5 = (ethnicity==5)

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



/*  Predict survival at 80 days under each comorbidity separately   */

* Set age and sex to baseline values
gen cons = 0

foreach var of varlist cons 				///
		comorbid_2 comorbid_3				///
		{
				
	* Reset that value to "yes"
	replace `var' = 1
	
	* Predict under that comorbidity (age and sex left at original values)
	predict pred80_`var', surv timevar(time80) ci
	
	* Change to risk, not survival
	gen risk80_`var' = 1 - pred80_`var'
	gen risk80_`var'_uci = 1 - pred80_`var'_lci
	gen risk80_`var'_lci = 1 - pred80_`var'_uci
	drop pred80_`var' pred80_`var'_lci pred80_`var'_uci
	
	* Reset that value back to "no"
	replace `var' = 0
}

keep age male ethnicity risk*


* Save relevant percentiles
gen p50 = $p50 
gen p70 = $p70 
gen p80 = $p80 
gen p90 = $p90 

* Save risk of white 65 year old
summ risk80_cons if age==65 & ethnicity==1
gen risk_age_65 = r(mean)

* Save data
save "output/abs_risks_fineage_group_`outcome'", replace



log close

