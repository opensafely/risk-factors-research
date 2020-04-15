********************************************************************************
*
*	Do-file:		cr_create_analysis_dataset.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		None
*
*	Data created:	egdata.dta
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		This do-file creates a fake dataset to test first code
*					draft on and creates the variables required for the 
*					main analysis.
*  
********************************************************************************




*************************************
*  Assumed structure of input data  *
*************************************

* Variables: 
* age (cts) 
* sex (string, M/F/I/U)
* chronic_cardiac_disease (string, date: YYYY-MM; NB numeric . if no obs) 
* chronic_liver_disease (string, date: YYYY-MM; NB numeric . if no obs) 
* bmi (cts)
* bmi_date_measured (string, date: YYYY-MM)


* Variables (fake) added below:





***********************************
*  Generate some extra variables  *
***********************************


*** This section won't be needed once real data is fully available

set seed 123489

* Death
gen died = uniform()<0.1
gen hosp = uniform()<0.20
gen itu  = uniform()<0.05


* Smoking status 
gen smoke = uniform()<0.3


* Additional risk factors
forvalues i = 1 (1) 15 {
	gen x`i' = uniform()<0.07
}
rename x1  resp
rename x2  asthma
rename x3  heart
rename x4  diabetes
rename x5  cancer
rename x6  liver
rename x7  neuro_dis
rename x8  kidney_dis
rename x9  transplant
rename x10 spleen
rename x11 immunosup
rename x12 hypertension
rename x13 autoimmune
rename x14 sle
rename x15 endocrine


* IMD
gen imd_temp = runiform()
egen imd = cut(imd_temp), group(5)
drop imd_temp
replace imd = imd + 1

* Gen STP
gen stp_temp = runiform()
egen stp = cut(stp_temp), group(40)
drop stp_temp



* Dates
gen enter_date = date("01/02/2020", "DMY")
format enter_date %td

gen end_study_date = enter_date + 64
format end_study_date %td


* Date of death
gen death_date = enter_date + runiform()*42 if died==1
replace death_date = . if died==0
format death_date %td

* Hospitalisation
gen lag = min(death_date, end_study_date) - enter_date

gen hosp_date = enter_date + runiform()*lag
replace hosp_date = . if hosp==0
format hosp_date %td

gen itu_date = enter_date + runiform()*lag
replace itu_date = . if itu==0
format itu_date %td
drop lag




******************************
*  Convert strings to dates  *
******************************

foreach var of varlist chronic_cardiac_disease chronic_liver_disease {
	capture confirm string variable `var'
	if _rc!=0 {
		assert `var'==.
		rename `var' `var'_date
	}
	else {
		replace `var' = `var' + "-15"
		rename `var' `var'_date_str
		replace `var'_date_str = " " if `var'_date_str == "-15"
		gen `var'_date = date(`var'_date, "YMD") 
		order `var'_date, after(`var'_date_str)
		drop `var'_date_str
	}
	format `var'_date %td
}



**************************************************
*  Create binary comorbidity indices from dates  *
**************************************************

* Comorbidities ever before
foreach var in chronic_cardiac_disease chronic_liver_disease {
	assert `var'_date>=. | 	`var'_date<= date("1feb2020", "DMY")
	gen `var' = (`var'_date<.)
	order `var', after(`var'_date)
}







********************************
*  Recode and check variables  *
********************************

* Age
assert age<.
*assert inrange(age, 18, 130)
* Exclude those with implausible ages/truncate? 
drop if age>105
drop if age<18

* Sex
assert inlist(sex, "M", "F", "I", "U")
drop if inlist(sex, "I", "U")
assert inlist(sex, "M", "F")
gen male = sex=="M"
drop sex

* BMI 
* Only keep if within certain time period?
drop bmi_date_measured
* assert inrange(bmi, 10, 200) | bmi==.
* Set implausible BMIs to missing? 
* FOR NOW:
replace bmi = rnormal(30, 15)
replace bmi = . if bmi<= 15





**************************
*  Categorise variables  *
**************************


/*  Age variables  */ 

* Create categorised age
recode age 18/39.9999=1 40/49.9999=2 50/59.9999=3 ///
	60/69.9999=4 70/79.9999=5 80/max=6, gen(agegroup) 

label define agegroup 	1 "18-<40" ///
						2 "40-<50" ///
						3 "50-<60" ///
						4 "60-<70" ///
						5 "70-<80" ///
						6 "80+"
label values agegroup agegroup


* Create binary age
recode age min/69.999=0 70/max=1, gen(age70)

* Check there are no missing ages
assert age<.
assert agegroup<.
assert age70<.

* Create restricted cubic splines fir age
mkspline age = age, cubic nknots(4)


/*  Body Mass Index  */

* BMI (NB: watch for missingness)
gen 	bmicat = .
recode  bmicat . = 1 if bmi<18.5
recode  bmicat . = 2 if bmi<25
recode  bmicat . = 3 if bmi<30
recode  bmicat . = 4 if bmi<35
recode  bmicat . = 5 if bmi<40
recode  bmicat . = 6 if bmi<.

label define bmicat 1 "Underweight (<18)" 		///
					2 "Normal (15.4-24.9)"		///
					3 "Overweight (25-29.9)"	///
					4 "Obese I (30-34.9)"		///
					5 "Obese II (35-39.9)"		///
					6 "Obese III (40+)"	
label values bmicat bmicat

* Create binary BMI (NB: watch for missingness; add 7=0)
recode bmicat 6=1 . 1/5=0, gen(obese40)



/*  Smoking  */

* Create binary smoking
*recode smoke 3=1 1/2 4=0, gen(currentsmoke)
*rename smoking_status smoke



/*  Centred age and sex (for adjusted KM plots)  */ 

* Centre age (linear)
summ age
gen c_age = age-r(mean)

* "centre" sex to be coded -1 +1 
recode male 0=-1, gen(c_male)











********************************
*  Outcomes and survival time  *
********************************

* Create composite outcome



/*  Create survival times  */

* For looping later, name must be stime_binary_outcome_name)

gen stime_died  = min(end_study_date, death_date)
gen stime_hosp  = min(end_study_date, death_date, hosp_date)
gen stime_itu   = min(end_study_date, death_date, itu_date)







*********************
*  Label variables  *
*********************

* Demographics
label var patient_id		"Patient ID"
label var age 				"Age (years)"
label var agegroup			"Grouped age"
label var age70 			"70 years and older"
label var male 				"Male"
label var bmi 				"Body Mass Index (BMI, kg/m2)"
label var bmicat 			"Grouped BMI"
label var obese40 			"Severely obese (cat 3)"
label var smoke			 	"Smoking status"
label var imd 				"Index of Multiple Deprivation (IMD)"
label var stp 				"Sustainability and Transformation Partnership"

label var age1 				"Age spline 1"
label var age2 				"Age spline 2"
label var age3 				"Age spline 3"
label var c_age				"Centred age"
label var c_male 			"Centred sex (code: -1/+1)"

* Comorbidities
label var resp				"Respiratory disease (excl. asthma)"
label var asthma			"Asthma"
label var heart				"Heart disease"
label var diabetes			"Diabetes"
label var cancer			"Cancer"
label var liver				"Liver"
label var neuro_dis			"Neurological disease"
label var kidney_dis		"Kidney disease"
label var transplant		"Organ transplant"
label var spleen			"Spleen problems"
label var immunosup			"Immunosuppressed"
label var hypertension		"Hypertension"
label var autoimmune		"Autoimmune disease"
label var sle				"SLE"
label var endocrine			"Endocrine disease"
label var chronic_cardiac_disease_date 	"CHD, date"
label var chronic_cardiac_disease  		"CHD"
label var chronic_liver_disease_date 	"Liver disease, date"
label var chronic_liver_disease			"Liver disease"

* Outcomes and follow-up
label var enter_date		"Date of study entry"
label var end_study_date	"Date of end of study"
label var death_date		"Date of death"
label var died 				"Death from Covid-19"
label var hosp_date			"Date of hospitalisation"
label var hosp 				"Hospitalised for Covid-19"
label var itu_date			"Date of hospitalisation"
label var itu 				"Admitted to ITU for Covid-19"

* Survival times
label var  stime_died		"Survival time; outcome death"
label var  stime_hosp  		"Survival time; outcome hospitalisation"
label var  stime_itu   		"Survival time; outcome ITU admission"




***************
*  Save data  *
***************

sort patient_id
label data "Poor factors dummy analysis dataset"
save "egdata", replace


