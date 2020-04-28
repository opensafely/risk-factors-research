********************************************************************************
*
*	Do-file:		an_checkassumptions.do
*
*	Project:		Risk factors for poor outcomes in Covid-19; Ethnicity MNAR
*
*	Programmed by:	Krishnan & Fizz
*
*	Data used:		cr_create_analysis_dataset.dta
*
*	Data created:	
*
*	Other output:	
*
********************************************************************************
*
*	Purpose:		This do-file f
*
********************************************************************************
*	
*	Stata routines required:		???
*
********************************************************************************



****************************************************
*   EXPERIMENTAL - PLACING AT END OF RUN IN CASE V SLOW
*   Later, incorporate into main modelling do-files
*****************************************************

local outcome `1' 

* Open a log file
capture log close
log using "./output/an_checkassumptions_`1'", text replace

use cr_create_analysis_dataset, clear
replace cpnsdeath = uniform()<0.3     // ****************************************** REMOVE

******************************
*  Multivariable Cox models  *
******************************

*************************************************************************************
*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basecoxmodel
prog define basecoxmodel
	syntax , age(string) [ethnicity(real 0) if(string)] 

	if `ethnicity'==1 local ethnicity "i.ethnicity"
	else local ethnicity
timer clear
timer on 1
	capture stcox 	`age' 					///
			i.male 							///
			i.obese4cat						///
			i.smoke_nomiss					///
			`ethnicity'						///
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
			i.chronic_kidney_disease 		///
			i.organ_transplant 				///
			i.spleen 						///
			i.ra_sle_psoriasis  			///
			other_immunosuppression			///
			`if'							///
			, strata(stp)
timer off 1
timer list
end
*************************************************************************************


local outcome = "cpnsdeath"

* Set as survival outcome
stset stime_`outcome', fail(`outcome') enter(enter_date) origin(enter_date) id(patient_id) 



/*   Proportional Hazards test  */
/*
stcox age1 age2 age3					///
		i.male 							///
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
		i.chronic_kidney_disease 		///
		i.organ_transplant 				///
		i.spleen 						///
		i.ra_sle_psoriasis  			///
		other_immunosuppression			///
		, strata(stp)
			
		*/	
			
* Age spline model (not adj ethnicity)
capture basecoxmodel, age("age1 age2 age3")  ethnicity(0)
if _rc==0 {
	
	estimates
	* estimates save ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_noeth, replace

	/*  Proportional Hazards test  */
	
	* Based on Schoenfeld residuals
	timer clear 
	timer on 1
	if e(N_fail)>0 estat phtest, d
	timer off 1
	timer list
	
	
	/*  Concordance statistic  */
	
	timer clear 
	timer on 2
	set seed 12437
	qui count
	local N = r(N)
	local p = 10000/`N'
	local csum = 0
	forvalues i = 1 (1) 10 {
	    gen rsample`i' = uniform()<`p'
		estat concordance if rsample`i'==1
		local cstat`i' =  r(C)
		noi di "C-statistic in `i' th sample = " `cstat`i''
		local csum = `csum' + `cstat`i''
		drop rsample`i'
	}
	local csum = `csum'/10
	noi di "Average C-statistic = " `csum'
	timer off 2
	timer list	
	
	
	/*  Brier score  */
	
	timer clear 
	timer on 3

	* Calculate at 60 days
	
	* Unadjusted
	capture stbrier, bt(60) efron
	if _rc==0 {
	    noi di "Brier score, unadjusted"
		estimates
	}

	* Fully adjusted
	capture stbrier age1 age2 age3		///
		i.male 							///
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
		i.chronic_kidney_disease 		///
		i.organ_transplant 				///
		i.spleen 						///
		i.ra_sle_psoriasis  			///
		other_immunosuppression			///
		, shared(stp) bt(60) 			///
		ipcw(age1 age2 age3				///
		i.male 							///
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
		i.chronic_kidney_disease 		///
		i.organ_transplant 				///
		i.spleen 						///
		i.ra_sle_psoriasis  			///
		other_immunosuppression)
	if _rc==0 {
	    noi di "Brier score, fully adjusted"
		estimates
	}

	timer off 3
	timer list
	
}
else di "WARNING AGE SPLINE MODEL DID NOT FIT (OUTCOME `outcome')"





log close
