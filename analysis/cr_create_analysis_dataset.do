********************************************************************************
*
*	Do-file:		cr_create_analysis_dataset.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		Data in memory (from input.csv)
*
*	Data created:	egdata.dta
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		This do-file creates the variables required for the 
*					main analysis and saves into a Stata dataset.
*  
********************************************************************************




***********************************
*  Generate some extra variables  *
***********************************

*** This section won't be needed once real data is fully available

import delimited input.csv, clear

set seed 123489

* Death
gen died = uniform()<0.1
gen hosp = uniform()<0.20
gen itu  = uniform()<0.05


* Smoking status (assuming input is called smoking_status)
gen     smoking_status = "N" if uniform()<0.3
replace smoking_status = "E" if uniform()<0.6 & smoking_status==""
replace smoking_status = "S" if uniform()<0.6 & smoking_status==""

* Ethnicity 
gen     ethnicity = "W" if uniform()<0.3
replace ethnicity = "B" if uniform()<0.2 & ethnicity==""
replace ethnicity = "A" if uniform()<0.1 & ethnicity==""
replace ethnicity = "M" if uniform()<0.1 & ethnicity==""
replace ethnicity = "O" if uniform()<0.1 & ethnicity==""
replace ethnicity = "U" if ethnicity==""


* Additional risk factors
gen asthma = .
gen chronic_kidney_disease = .

* BMI
replace bmi = rnormal(30, 15)
replace bmi = . if bmi<= 15


* SBP and DBP  **********
replace bp_sys   = rnormal(110, 15)
replace bp_dias  = rnormal(80, 15)

* Gen STP
gen stp_temp = runiform()
egen stp = cut(stp_temp), group(40)
drop stp_temp


****** THIS NEXT LITTLE SECTION WILL BE NEEDED FOR THE REAL DATA ******
* Dates   
gen enter_date = date("01/02/2020", "DMY")
format enter_date %td

gen end_study_date = enter_date + 64
format end_study_date %td

****** END OF SECTION NEEDED FOR THE REAL DATA ******


*** Generate fake outcome dates

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




****************************
*  Create required cohort  *
****************************

* Age: Exclude children
drop if age<18

* Age: Exclude those with implausible ages
assert age<.
drop if age>105

* Sex: Exclude categories other than M and F
assert inlist(sex, "M", "F", "I", "U")
drop if inlist(sex, "I", "U")





******************************
*  Convert strings to dates  *
******************************

* To be added: dates related to outcomes
foreach var of varlist 	bp_sys_date 					///
						bp_dias_date 					///
						bmi_date_measured				///
						chronic_respiratory_disease 	///
						asthma							///
						chronic_cardiac_disease 		///
						diabetes 						///
						lung_cancer 					///
						haem_cancer						///
						other_cancer 					///
						bone_marrow_transplant 			///
						chemo_radio_therapy 			///
						chronic_liver_disease 			///
						neurological_condition 			///
						chronic_kidney_disease 			///
						organ_transplant 				///	
						dysplenia						///
						sickle_cell 					///
						aplastic_anaemia 				///
						hiv 							///
						genetic_immunodeficiency 		///
						immunosuppression_nos 			///
						ra_sle_psoriasis  {
	capture confirm string variable `var'
	if _rc!=0 {
		assert `var'==.
		rename `var' `var'_date
	}
	else {
		replace `var' = `var' + "-15"
		rename `var' `var'_dstr
		replace `var'_dstr = " " if `var'_dstr == "-15"
		gen `var'_date = date(`var'_dstr, "YMD") 
		order `var'_date, after(`var'_dstr)
		drop `var'_dstr
	}
	format `var'_date %td
}

rename bmi_date_measured_date bmi_date_measured
rename bp_dias_date_measured_date  bp_dias_date
rename bp_sys_date_measured_date   bp_sys_date

* NB: Some BMI dates in future or after cohort entry



**************************************************
*  Create binary comorbidity indices from dates  *
**************************************************

* Comorbidities ever before
foreach var of varlist	chronic_respiratory_disease_date 	///
						chronic_cardiac_disease_date 		///
						diabetes 							///
						lung_cancer_date 					///
						haem_cancer_date					///
						other_cancer_date 					///
						bone_marrow_transplant_date 		///
						chemo_radio_therapy_date			///
						chronic_liver_disease_date 			///
						neurological_condition_date 		///
						chronic_kidney_disease_date 		///
						organ_transplant_date 				///	
						dysplenia_date 						///
						sickle_cell_date 					///
						aplastic_anaemia_date 				///
						hiv_date							///
						genetic_immunodeficiency_date 		///
						immunosuppression_nos_date 			///
						ra_sle_psoriasis_date   {
	local newvar =  substr("`var'", 1, length("`var'") - 5)
	gen `newvar' = (`var'<date("1feb2020", "DMY"))
	order `newvar', after(`var')
}

* Grouped comorbidities
egen cancer = rowmax(lung_cancer haem_cancer other_cancer)
order cancer, after(other_cancer)

* Spleen problems (dysplenia and sicke cell)   ************************************************
egen spleen = rowmax(dysplenia sickle_cell) 
order spleen, after(sickle_cell)


* Immunosuppressed conditions
egen immuno_condition = rowmax(aplastic_anaemia 			///
								hiv							///
								genetic_immunodeficiency 	///
								immunosuppression_nos) 
order immuno_condition, after(immunosuppression_nos)
						

						

********************************
*  Recode and check variables  *
********************************

* Sex
assert inlist(sex, "M", "F")
gen male = sex=="M"
drop sex

* BMI 
* Only keep if within certain time period?
* bmi_date_measured
* Set implausible BMIs to missing? 


* Smoking 
assert inlist(smoking_status, "N", "E", "S", "")
gen     smoke = 1 if smoking_status=="N"
replace smoke = 2 if smoking_status=="E"
replace smoke = 3 if smoking_status=="S"
replace smoke = .u if smoking_status==""
label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Unknown (.u)"
label values smoke smoke
drop smoking_status


* Ethnicity
rename ethnicity ethnicity_o
assert inlist(ethnicity, "A", "B", "W", "M", "O", "U")
gen     ethnicity = 1 if ethnicity_o=="W"
replace ethnicity = 2 if ethnicity_o=="B"
replace ethnicity = 3 if ethnicity_o=="A"
replace ethnicity = 4 if ethnicity_o=="M"
replace ethnicity = 5 if ethnicity_o=="O"
replace ethnicity = .u if ethnicity_o=="U"
label define ethnicity 1 "White" 2 "Black" 3 "Asian" 4 "Mixed" 5 "Other" .u "Unknown (.u)"
label values ethnicity ethnicity
drop ethnicity_o




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
replace bmicat = .u if bmi>=.

label define bmicat 1 "Underweight (<18)" 		///
					2 "Normal (15.4-24.9)"		///
					3 "Overweight (25-29.9)"	///
					4 "Obese I (30-34.9)"		///
					5 "Obese II (35-39.9)"		///
					6 "Obese III (40+)"			///
					.u "Unknown (.u)"
label values bmicat bmicat

* Create binary BMI (NB: watch for missingness; add 7=0)
recode bmicat 6=1 . 1/5=0, gen(obese40)
order obese40, after(bmicat)



/*  Smoking  */

* Create binary smoking
recode smoke 3=1 1/2 .u=0, gen(currentsmoke)
order currentsmoke, after(smoke)



/*  IMD  */

* Group into 5 groups
rename imd imd_o
egen imd = cut(imd), group(5) icodes
replace imd = imd + 1
drop imd_o
*** Some IMD values are -1 ****************************************



/*  Centred age, sex, IMD, ethnicity (for adjusted KM plots)  */ 

* Centre age (linear)
summ age
gen c_age = age-r(mean)

* "Centre" sex to be coded -1 +1 
recode male 0=-1, gen(c_male)

* "Centre" IMD
gen c_imd = imd - 3

* "Centre" ethnicity
gen c_ethnicity = ethnicity - 3




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
label var bmi_date  		"Body Mass Index (BMI, kg/m2), date measured"
label var obese40 			"Severely obese (cat 3)"
label var smoke		 		"Smoking status"
label var currentsmoke	 	"Current smoker"
label var imd 				"Index of Multiple Deprivation (IMD)"
label var ethnicity			"Ethnicity"
label var stp 				"Sustainability and Transformation Partnership"

label var bp_sys 			"Systolic blood pressure"
label var bp_sys_date 		"Systolic blood pressure, date"
label var bp_dias 			"Diastolic blood pressure"
label var bp_dias_date 		"Diastolic blood pressure, date"

label var age1 				"Age spline 1"
label var age2 				"Age spline 2"
label var age3 				"Age spline 3"
label var c_age				"Centred age"
label var c_male 			"Centred sex (code: -1/+1)"
label var c_imd				"Centred Index of Multiple Deprivation (values: -2/+2)"
label var c_ethnicity		"Centred ethnicity (values: -2/+2)"

* Comorbidities
label var chronic_respiratory_disease	"Respiratory disease (excl. asthma)"
label var asthma						"Asthma"
label var chronic_cardiac_disease		"Heart disease"
label var diabetes						"Diabetes"
label var lung_cancer					"Lung cancer"
label var haem_cancer					"Haem. cancer"
label var other_cancer					"Any cancer"
label var cancer						"Cancer"
label var bone_marrow_transplant		"Organ transplant"
label var chronic_liver_disease			"Liver"
label var neurological_condition		"Neurological disease"
label var chronic_kidney_disease 		"Kidney disease"
label var organ_transplant 				"Organ transplant recipient"
label var dysplenia						"Dysplenia"
label var sickle_cell 					"Sickle cell"
label var spleen						"Spleen problems (dysplenia, sickle cell)"
label var ra_sle_psoriasis				"RA, SLE, Psoriasis (autoimmune disease)"
label var chemo_radio_therapy			"Chemotherapy or radiotherapy"
label var aplastic_anaemia				"Aplastic anaemia"
label var hiv 							"HIV"
label var genetic_immunodeficiency 		"Genetic immunodeficiency"
label var immunosuppression_nos 		"Other immunosuppression"
label var immuno_condition				"Any immunocondition"
 
label var chronic_respiratory_disease_date	"Respiratory disease (excl. asthma), date"
label var asthma_date					"Asthma, date"
label var chronic_cardiac_disease_date	"Heart disease, date"
label var diabetes_date					"Diabetes, date"
label var lung_cancer_date				"Lung cancer, date"
label var haem_cancer_date				"Haem. cancer, date"
label var other_cancer_date				"Any cancer, date"
label var bone_marrow_transplant_date	"Organ transplant, date"
label var chronic_liver_disease_date	"Liver, date"
label var neurological_condition_date	"Neurological disease, date"
label var chronic_kidney_disease_date 	"Kidney disease, date"
label var organ_transplant_date			"Organ transplant recipient, date"
label var dysplenia_date				"Dysplenia, date"
label var sickle_cell_date 				"Sickle cell, date"
label var ra_sle_psoriasis_date			"RA, SLE, Psoriasis (autoimmune disease), date"
label var chemo_radio_therapy_date		"Chemotherapy or radiotherapy, date"
label var aplastic_anaemia_date			"Aplastic anaemia, date"
label var hiv_date 						"HIV, date"
label var genetic_immunodeficiency_date "Genetic immunodeficiency, date"
label var immunosuppression_nos_date 	"Other immunosuppression, date"
label var bp_sys_date					"Systolic blood pressure, date"
label var bp_dias_date					"Diastolic blood pressure, date"


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


