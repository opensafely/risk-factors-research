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
*	Purpose:		Calculates c-statistic for primary model
*
********************************************************************************
*	
*	Stata routines required:		Somers d to create weighted C-statistics
*
********************************************************************************


* Add the required ado files to the adopath
adopath ++  "`c(pwd)'\somersd"



****************************************************
*   EXPERIMENTAL - PLACING AT END OF RUN IN CASE V SLOW
*   Later, incorporate into main modelling do-files
*****************************************************

local outcome `1' 

* Open a log file
capture log close
log using "./output/an_checkassumptions_`outcome'", text replace


use "cr_create_analysis_dataset_STSET_`outcome'.dta", clear


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
			i.reduced_kidney_function_cat 	///
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



* Set as survival outcome
stset stime_`outcome', fail(`outcome') enter(enter_date) origin(enter_date) id(patient_id) 


			
* Age spline model (not adj ethnicity)
basecoxmodel, age("age1 age2 age3")  ethnicity(0)
if _rc==0 {
	
	estimates
	predict hr
	generate invhr=1/hr
	gen censind= 1-_d if _st==1
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
	
	qui count if `outcome'==0
	local N0 = r(N)
	local p0 = 5000/`N0'
	qui count if `outcome'==1
	local N1 = r(N)
	local p1 = 5000/`N1'	
	
	noi di "Fraction of controls to be used" `p0'
	noi di "Fraction of cases to be used" `p1'
	local csum = 0
	forvalues i = 1 (1) 10 {
		gen     rsample`i' = uniform()<`p0' if `outcome'==0
		replace rsample`i' = uniform()<`p1' if `outcome'==1
		gen     weight =  1/`p0' if  `outcome'==0 & rsample`i'==1
		replace weight =  1/`p1' if  `outcome'==1 & rsample`i'==1
		
		somersd _t invhr if _st==1 & weight<. [iweight=weight], cenind(censind) tdist transf(c)
		matrix b = r(table)
		local cstat`i' = b[1,1]
		noi di "C-statistic in `i' th sample = " `cstat`i''
		local csum = `csum' + `cstat`i''
		drop rsample`i' weight
	}
	local csum = `csum'/10
	noi di "Average C-statistic = " `csum'
	timer off 2
	timer list	
	
	
}
else di "WARNING AGE SPLINE MODEL DID NOT FIT (OUTCOME `outcome')"





log close
