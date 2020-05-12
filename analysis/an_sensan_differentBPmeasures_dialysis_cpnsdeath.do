*an_sensan_differentBPmeasures_cpnsdeath
*KB 1/5/2020

cap log close
log using "./output/an_sensan_differentBPmeasures_cpnsdeath", replace t

use "cr_create_analysis_dataset_STSET_cpnsdeath.dta", clear


******************************
*  Multivariable Cox models  *
******************************

*************************************************************************************
*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basecoxmodel
prog define basecoxmodel
	syntax , age(string) bp(string) [ethnicity(real 0) dialysis(real 0) if(string)] 

	if `ethnicity'==1 local ethnicity "i.ethnicity"
	else local ethnicity

	if `dialysis'==1 local dialysis "i.dialysis"
	else local dialysis

	
timer clear
timer on 1
	capture stcox 	`age' 					///
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
			`dialysis'						///
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


 
*Model with coded hypertension 
basecoxmodel, age("age1 age2 age3") bp("i.hypertension") ethnicity(0) dialysis(0)
if _rc==0{
estimates
estimates save ./output/models/an_sensan_differentBPmeasures_dialysis_cpnsdeath_MAINFULLYADJMODEL_agespline_bmicat_noeth_HTN, replace
*estat concordance /*c-statistic*/
 }
 else di "WARNING coded htn model DID NOT FIT (OUTCOME `outcome')"
 


*Model with categorised bp
basecoxmodel, age("age1 age2 age3") bp("i.bpcat_nomiss") ethnicity(0) dialysis(0)
if _rc==0{
estimates
estimates save ./output/models/an_sensan_differentBPmeasures_dialysis_MAINFULLYADJMODEL_agespline_bmicat_noeth_BPCAT, replace
*estat concordance /*c-statistic*/
 }
 else di "WARNING bp cat model DID NOT FIT (OUTCOME `outcome')"
 

 *Model with original bp, adds dialysis
basecoxmodel, age("age1 age2 age3") bp("i.htdiag_or_highbp") ethnicity(0) dialysis(1)
if _rc==0{
estimates
estimates save ./output/models/an_sensan_differentBPmeasures_dialysis_MAINFULLYADJMODEL_agespline_bmicat_noeth_dialysis, replace
*estat concordance /*c-statistic*/
 }
 else di "WARNING dialysis model DID NOT FIT (OUTCOME `outcome')"

 


log close
