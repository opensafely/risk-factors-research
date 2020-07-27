********************************************************************************
*
*	Do-file:		an_multivariable_cox_models.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		egdata.dta
*
*	Data created:	None
*
*	Other output:	Log file:  an_multivariable_cox_models.log
*
********************************************************************************
*
*	Purpose:		This do-file performs multivariable (fully adjusted) 
*					Cox models. 
*  
********************************************************************************
*	
*	Stata routines needed:	stbrier	  
*
********************************************************************************

local outcome `1' 


************************************************************************************
*First clean up all old saved estimates for this outcome
*This is to guard against accidentally displaying left-behind results from old runs
************************************************************************************
cap erase ./output/models/an_multivariate_cox_models_workingagepop_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_noeth.ster
cap erase ./output/models/an_multivariate_cox_models_workingagepop_`outcome'_MAINFULLYADJMODEL_agegroup_bmicat_noeth.ster
cap erase ./output/models/an_multivariate_cox_models_workingagepop_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_CCeth.ster
cap erase ./output/models/an_multivariate_cox_models_workingagepop_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_CCnoeth.ster


* Open a log file
capture log close
log using "./output/an_multivariable_cox_models_workingagepop_`outcome'", text replace

use "cr_create_analysis_dataset_STSET_`outcome'.dta", clear


******************************
*  Multivariable Cox models  *
******************************

*************************************************************************************
*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basecoxmodel
prog define basecoxmodel
	syntax , age(string) bp(string) [ethnicity(real 0) if(string)] 

	if `ethnicity'==1 local ethnicity "i.ethnicity"
	else local ethnicity
timer clear
timer on 1
	cap stcox 	`age' 							///
			i.male 							///
			i.obese4cat						///
			i.smoke_nomiss					///
			`ethnicity'						///
			i.imd 							///
			`bp'							///
			i.chronic_respiratory_disease 	///
			i.asthmacat						///
			i.chronic_cardiac_disease 		///
			i.diabcat						///
			i.cancer_exhaem_cat	 			///
			i.cancer_haem_cat  				///
			i.chronic_liver_disease 		///
			i.stroke_dementia		 		///
			i.other_neuro					///
			i.reduced_kidney_function_cat	///
			i.organ_transplant 				///
			i.spleen 						///
			i.ra_sle_psoriasis  			///
			i.other_immunosuppression			///
			`if'							///
			, strata(stp)
timer off 1
timer list
end
*************************************************************************************



*Age spline model (not adj ethnicity)
basecoxmodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(0) if("if agegroup<=4")
if _rc==0{
estimates
estimates save ./output/models/an_multivariate_cox_models_workingagepop_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_noeth, replace
*estat concordance /*c-statistic*/
}
else di "WARNING AGE SPLINE MODEL DID NOT FIT (OUTCOME `outcome')"
 
*Age group model (not adj ethnicity)
basecoxmodel, age("ib3.agegroup") bp("i.htdiag_or_highbp") ethnicity(0) if("if agegroup<=4")
if _rc==0{
estimates
estimates save ./output/models/an_multivariate_cox_models_workingagepop_`outcome'_MAINFULLYADJMODEL_agegroup_bmicat_noeth, replace
*estat concordance /*c-statistic*/
}
else di "WARNING GROUP MODEL DID NOT FIT (OUTCOME `outcome')"

*Complete case ethnicity model
basecoxmodel, age("age1 age2 age3") bp("i.htdiag_or_highbp") ethnicity(1) if("if agegroup<=4")
if _rc==0{
estimates
estimates save ./output/models/an_multivariate_cox_models_workingagepop_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_CCeth, replace
*estat concordance /*c-statistic*/
 }
 else di "WARNING CC ETHNICITY MODEL WITH AGESPLINE DID NOT FIT (OUTCOME `outcome')"
 


log close





