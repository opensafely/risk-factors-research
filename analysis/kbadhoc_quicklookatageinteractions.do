cap log close
log using ./output/kbadhoc_quicklookatageinteractions, replace t

use cr_create_analysis_dataset_STSET_onscoviddeath.dta, clear

set seed 20984

keep if _d==1 | (uniform()<0.003)

gen pw = 1 if _d==1
replace pw = 1/0.003 if _d==0

* Save a version set on ONS covid death outcome
stset stime_onscoviddeath [pweight=pw], fail(onscoviddeath) 				///
	id(patient_id) enter(enter_date) origin(enter_date)
	
	
*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basemodel
prog define basemodel
	syntax , age(string) bp(string) [ethnicity(real 0) interaction(string)] 

	if `ethnicity'==1 local ethnicity "i.ethnicity"
	else local ethnicity
timer clear
timer on 1
	 stcox 	`age' 					///
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
			`interaction'							///
			, strata(stp)
	timer off 1
timer list
end
*************************************************************************************



*Age spline model (not adj ethnicity)
basemodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(0)

gen age70plus = agegroup
recode age70plus 1/4=0 5/6=1

*Age interactions with binary vars
foreach intvar of varlist  chronic_respiratory_disease chronic_cardiac_disease chronic_liver_disease stroke_dementia other_neuro organ_transplant spleen ra_sle_psoriasis other_immunosuppression {
basemodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(0) interaction(1.age70plus#1.`intvar')
testparm 1.age70plus#i.`intvar'
di _n "`intvar' <70" _n "****************"
lincom 1.`intvar', eform
di "`intvar' 70+" _n "****************"
lincom 1.`intvar' + 1.age70plus#1.`intvar', eform
est save ./output/models/_temp_ageint_`intvar', replace
}
*Age interactions with 3-level vars
foreach intvar of varlist reduced_kidney_function_cat asthmacat  {
basemodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(0) interaction(1.age70plus#2.`intvar' 1.age70plus#3.`intvar')
testparm 1.age70plus#i.`intvar'
di _n "`intvar' <70" _n "****************"
lincom 2.`intvar', eform
lincom 3.`intvar', eform
di "`intvar' 70+" _n "****************"
lincom 2.`intvar' + 1.age70plus#2.`intvar', eform
lincom 3.`intvar' + 1.age70plus#3.`intvar', eform
est save ./output/models/_temp_ageint_`intvar', replace
}

*Age interactions with 4-level vars
foreach intvar of varlist obese4cat diabcat cancer_exhaem_cat cancer_haem_cat {
basemodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(0) interaction(1.age70plus#2.`intvar' 1.age70plus#3.`intvar' 1.age70plus#4.`intvar')
testparm 1.age70plus#i.`intvar'
di _n "`intvar' <70" _n "****************"
lincom 2.`intvar', eform
lincom 3.`intvar', eform
lincom 4.`intvar', eform
di "`intvar' 70+" _n "****************"
lincom 2.`intvar' + 1.age70plus#2.`intvar', eform
lincom 3.`intvar' + 1.age70plus#3.`intvar', eform
lincom 4.`intvar' + 1.age70plus#4.`intvar', eform
est save ./output/models/_temp_ageint_`intvar', replace
}

basemodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(0) interaction(1.chronic_cardiac_disease#i.diabcat)
testparm 1.chronic_cardiac_disease#i.diabcat

log close