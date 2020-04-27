****************************************************
*Assumption checks - ph test
*KB and Fizz
*27/4
*EXPERIMENTAL - PLACING AT END OF RUN IN CASE V SLOW
*Later, incorporate into main modelling do-files
*****************************************************

local outcome `1' 

* Open a log file
capture log close
log using "./output/an_checkassumptions_`1'", text replace

use cr_create_analysis_dataset, clear


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
			i.ckd					 		///
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


stset stime_`outcome', fail(`outcome') enter(enter_date) origin(enter_date) id(patient_id) 

*Age spline model (not adj ethnicity)
basecoxmodel, age("age1 age2 age3")  ethnicity(0)
if _rc==0{
estimates
estimates save ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_noeth, replace
*estat concordance /*c-statistic*/
timer clear 
timer on 1
estat phtest, d
timer off 1
timer list
}
else di "WARNING AGE SPLINE MODEL DID NOT FIT (OUTCOME `outcome')"
 
log close
