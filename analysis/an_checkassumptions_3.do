********************************************************************************
*
*	Do-file:		an_checkassumptions_3.do
*
*	Project:		Risk factors for poor outcomes in Covid-19; Ethnicity MNAR
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		cr_create_analysis_dataset.dta
*
*	Data created:	imputed.dta  (imputed data)
*
*	Other output:	Log file output/an_checkassumptions_3
*
********************************************************************************
*
*	Purpose:		This do-file fits a sensitivity analysis for missing 
*					ethnicity, using multiple imputation incorporating 
*					information from external data sources (e.g. census)
*					about the marginal proportions of ethnic groups 
*					within broad geographical regions. 
*  
********************************************************************************
*	
*	Stata routines required:		ice (ssc install ice),  and 
*									user-written programs in the do files 
*									in the first two lines below
*
********************************************************************************


local region `1' 


* Open a log file
capture log close
log using "output/an_checkassumptions_MI_`region'", text replace

local k = `region'
noi di `region'

* Load user written functions
do Calibration_parameter_nlsolution.do  
do Calibration_parameter_estimation.do  



********************************   NOTES  **************************************

*  Assumes region is string, taking  values: 
*    East, East Midlands, London, North East, North West, South East, 
*    South West, West Midlands, and Yorkshire and The Humber
*
*  Assumes ethnicity is numeric, taking values: 
*	1, 2, 3, 4, 5, (missing: . or .u)
*	in the order White, Black, Asian, Mixed, Other
*	with value labels exactly as above. 
*	(NB: this is now intially recoded from ordering: 
*      White, Mixed, Asian, Black, Other)	
*
*
*  Assumes a complete case sample other than ethnicity
*
********************************************************************************




			
*******************************************************
*  Perform imputations within each region separately  *
*******************************************************

* List of regions
global region1 = "East"
global region2 = "East Midlands"	
global region3 = "London" 
global region4 = "North East" 
global region5 = "North West" 
global region6 = "South East" 
global region7 = "South West" 
global region8 = "West Midlands" 
global region9 = "Yorkshire and The Humber"  




* Open data 
use cr_create_analysis_dataset.dta, clear
tab region, m


* Only keep data from one region
keep if region=="${region`k'}"
tab region, m	
	
* Change ordering of ethnicity
label define ethnicity 1 "White" 2 "Black" 3 "Asian" 4 "Mixed" 5 "Other", modify
recode ethnicity 1=1 2=4 3=3 4=2 5=5


* Only keep required variables
keep patient_id stp region ethnicity				///
	stime_cpnsdeath cpnsdeath enter_date 			///
	agegroup male obese4cat							///
	smoke_nomiss imd htdiag_or_highbp				///
	chronic_respiratory_disease 					///
	asthmacat 										///
	chronic_cardiac_disease 						///
	diabcat 										///
	cancer_exhaem_cat 								///
	cancer_haem_cat					  				///
	chronic_liver_disease 							///
	stroke_dementia		 							///
	other_neuro										///
	chronic_kidney_disease 							///
	organ_transplant 								///
	spleen 											///
	ra_sle_psoriasis 								///
	other_immunosuppression

		
* Create complete case sample (except for ethnicity) 
drop if imd>=. 

* Set as survival
stset stime_cpnsdeath, fail(cpnsdeath) enter(enter_date)	///
	origin(enter_date) id(patient_id)

* Generate the Nelson-Aalen estimate of the cumulative hazard
sts generate cumh = na 
egen cumhgp = cut(cumh), group(5) 
replace cumhgp = cumhgp+1

* Gene missingness indicator
gen r = 1 - missing(ethnicity)

* Create dummy variables for categorical predictors
foreach var of varlist agegroup obese4cat smoke_nomiss imd  ///
	asthmacat diabcat cancer_exhaem_cat cancer_haem_cat		///
	stp cumhgp {
		egen ord_`var' = group(`var')
		qui summ ord_`var'
		local max=r(max)
		forvalues i = 1 (1) `max' {
			gen `var'_`i' = (`var'==`i')
		}	
		drop ord_`var'
		drop `var'_1
}



forvalues m = 1 (1) 5	{

	/* 	Number of patients with missing ethnicity  */

	count_missing r
	global Nmis = r(Nmis)
	global Nobs = r(Nobs)


	/*  Draw probability of observing ethnicity  */

	global r0star = r(r0star)
	global r1star = r(r1star)


	/*  Draw probability of each ethnicity category  */ 

	prop_ethnicity ethnicity
	forvalues j = 1 (1) 4 {
		global Eth`j'obsstar = r(Eth`j'obsstar)
	}

		
		
	*******************************************************************
	*  External parameters needed to estimate calibration parameters  *
	*******************************************************************
		
	/*  	External data distribution of ethnicity  	*/

	if `k'==1 {	// East
		global Eth1 = 0.02252
		global Eth2 = 0.048303
		global Eth3 = 0.016971
		global Eth4 = 0.009791 	
	}
	else if `k'==2 {	// East Midlands
		global Eth1 = 0.019259
		global Eth2 = 0.062222
		global Eth3 = 0.012698
		global Eth4 = 0.008254
	}
	else if `k'==3 {	// London
		global Eth1 = 0.124872
		global Eth2 = 0.183715
		global Eth3 = 0.037176
		global Eth4 = 0.060554
	}		
	else if `k'==4 {	// North East
		global Eth1 = 0.006447	
		global Eth2 = 0.029579
		global Eth3 = 0.005309
		global Eth4 = 0.006826
	}	
	else if `k'==5 {	// North West
		global Eth1 = 0.018688	
		global Eth2 = 0.06423
		global Eth3 = 0.012458
		global Eth4 = 0.011766
	}	
	else if `k'==6 {	// South East
		global Eth1 = 0.01665
		global Eth2 = 0.053826
		global Eth3 = 0.01722
		global Eth4 = 0.012544
	}	
	else if `k'==7 {	// South West
		global Eth1 = 0.009425	
		global Eth2 = 0.021388
		global Eth3 = 0.010332
		global Eth4 = 0.008519
	}	
	else if `k'==8 {	// West Midlands
		global Eth1 = 0.033207	
		global Eth2 = 0.121129
		global Eth3 = 0.015657
		global Eth4 = 0.014109
	}	
	else if `k'==9 {	// Yorkshire and the Humber
		global Eth1 = 0.015112
		global Eth2 = 0.066532
		global Eth3 = 0.014191
		global Eth4 = 0.011426
	}	
			





	***********************************************************************
	*  Obtain linear predictor needed to estimate calibration parameters  *
	***********************************************************************


	/*   Fit imputation model for ethnicity   */

	* 4th region only has one STP so exclude from model
	if `k'!=4 { 
		local stp_text = "stp_*"
	}
	else {
		local stp_text = ""
	}

	* Fit imputation model for ethnicity
	capture drop temp
	noi uvis mlogit ethnicity 				///
		`stp_text'							///
		cumhgp_* cpnsdeath 					///
		agegroup_*  						///
		male 								///
		obese4cat_*							///
		smoke_nomiss_*						///
		imd_*								///
		htdiag_or_highbp					///
		chronic_respiratory_disease 		///
		asthmacat_* 						///
		chronic_cardiac_disease 			///
		diabcat_* 							///
		cancer_exhaem_cat_* 				///
		cancer_haem_cat_*  					///
		chronic_liver_disease 				///
		stroke_dementia		 				///
		other_neuro							///
		chronic_kidney_disease 				///
		organ_transplant 					///
		spleen 								///
		ra_sle_psoriasis  					///
		other_immunosuppression, 			///
		gen(temp) baseoutcome(1)
	drop temp
	
	* Obtain linear predictor, for P(eth=j | r=1)
	local eth_text_1 = "Black"
	local eth_text_2 = "Asian"
	local eth_text_3 = "Mixed"
	local eth_text_4 = "Other"

	forvalues j = 1 (1) 4 {
		qui gen lp`j' = [`eth_text_`j'']_b[_cons]
		foreach var of varlist 					///
			`stp_text'							///
			cumhgp_* cpnsdeath					///
			agegroup_*  						///
			male obese4cat_*					///
			smoke_nomiss_*						///
			imd_*								///
			htdiag_or_highbp					///
			chronic_respiratory_disease 		///
			asthmacat_* 						///
			chronic_cardiac_disease 			///
			diabcat_* 							///
			cancer_exhaem_cat_* 				///
			cancer_haem_cat_*  					///
			chronic_liver_disease 				///
			stroke_dementia		 				///
			other_neuro							///
			chronic_kidney_disease 				///
			organ_transplant 					///
			spleen 								///
			ra_sle_psoriasis  					///
			other_immunosuppression  			///
			 {
			 capture  di [`eth_text_`j'']_b[`var'] 
			 if _rc==0 {
				qui replace lp`j' = lp`j' + [`eth_text_`j'']_b[`var']*(`var'==1)
			}
		}
	}

		
	* Create variable to house estimation results
	noi summ lp?
	nlnle2_wrap
	global gamma1 = r(rr1) 
	global gamma2 = r(rr2) 
	global gamma3 = r(rr3) 
	global gamma4 = r(rr4) 


	noi di "Weight for Black: " $gamma1
	noi di "Weight for Asian: " $gamma2
	noi di "Weight for Mixed: " $gamma3
	noi di "Weight for Other: " $gamma4
	
	
	* Delete variables no longer needed
	drop lp1 lp2 lp3 lp4
	
	

	**********************
	*  Impute ethnicity  *
	**********************


	/*  Use calibration parameters to generate probability weights (P(obs))  */

	* Missing ethnicities, assign a small weight
	* Observed ethnicities, weight = the RR from above (for non-ref groups)
	cap drop caldelw
	gen     caldelw = 0.0001 
	replace caldelw = 1	      if ethnicity == 1
	replace caldelw = $gamma1 if ethnicity == 2
	replace caldelw = $gamma2 if ethnicity == 3
	replace caldelw = $gamma3 if ethnicity == 4
	replace caldelw = $gamma4 if ethnicity == 5

	noi tab caldelw ethnicity, m
	noi di "Manual replacements to avoid crashes:"
	replace caldelw = 0.1 if caldelw==0 & ethnicity<. // To avoid crashes


	/*  Fit imputation model in weighted population */
	
	uvis mlogit ethnicity 					///
		`stp_text'							///
		cumhgp_* cpnsdeath 					///
		agegroup_*  						///
		male 								///
		obese4cat_*							///
		smoke_nomiss_*						///
		imd_*								///
		htdiag_or_highbp					///
		chronic_respiratory_disease 		///
		asthmacat_* 						///
		chronic_cardiac_disease 			///
		diabcat_* 							///
		cancer_exhaem_cat_* 				///
		cancer_haem_cat_*  					///
		chronic_liver_disease 				///
		stroke_dementia		 				///
		other_neuro							///
		chronic_kidney_disease 				///
		organ_transplant 					///
		spleen 								///
		ra_sle_psoriasis  					///
		other_immunosuppression 			///
		[pw=caldelw], 						///
		baseoutcome(1)						///
		gen(ethnicity`m') 
	drop caldelw
	
}

* Keep the imputed data and patient ID for each region
keep patient_id region ethnicity*

* Save the data
save imputed_`k', replace


log close


