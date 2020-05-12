********************************************************************************
*
*	Do-file:		cr_create_analysis_dataset.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		Data in memory (from input.csv)
*
*	Data created:	cr_create_analysis_dataset.dta
*
*	Other output:	None
*
********************************************************************************
*
*	Purpose:		This do-file creates the variables required for the 
*					main analysis and saves into a Stata dataset.
*  
********************************************************************************



* Open a log file
cap log close
log using ./output/cr_analysis_dataset, replace t

di "STARTING COUNT FROM IMPORT:"
cou


**************************   INPUT REQUIRED   *********************************

* Censoring dates for each outcome (largely, last date outcome data available)
*global ecdseventcensor 		= "21/04/2020"
global ituadmissioncensor 	= "20/04/2020"
global cpnsdeathcensor 		= "25/04/2020"
global onscoviddeathcensor 	= "06/04/2020"


*******************************************************************************





****************************
*  Create required cohort  *
****************************

* Age: Exclude children
noi di "DROPPING AGE<18:" 
drop if age<18


* Age: Exclude those with implausible ages
assert age<.
noi di "DROPPING AGE<105:" 
drop if age>105

* Sex: Exclude categories other than M and F
assert inlist(sex, "M", "F", "I", "U")
noi di "DROPPING GENDER NOT M/F:" 
drop if inlist(sex, "I", "U")




******************************
*  Convert strings to dates  *
******************************

* To be added: dates related to outcomes
foreach var of varlist 	bp_sys_date 					///
						bp_dias_date 					///
						hba1c_percentage_date			///
						hba1c_mmol_per_mol_date			///
						hypertension					///
						bmi_date_measured				///
						chronic_respiratory_disease 	///
						chronic_cardiac_disease 		///
						diabetes 						///
						lung_cancer 					///
						haem_cancer						///
						other_cancer 					///
						bone_marrow_transplant 			///
						chemo_radio_therapy 			///
						chronic_liver_disease 			///
						stroke							///
						dementia		 				///
						other_neuro 					///
						organ_transplant 				///	
						dysplenia						///
						sickle_cell 					///
						aplastic_anaemia 				///
						hiv 							///
						permanent_immunodeficiency 		///
						temporary_immunodeficiency		///
						ra_sle_psoriasis  dialysis 	{
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

rename bmi_date_measured_date      bmi_date_measured
rename bp_dias_date_measured_date  bp_dias_date
rename bp_sys_date_measured_date   bp_sys_date
rename hba1c_percentage_date_date  hba1c_percentage_date
rename hba1c_mmol_per_mol_date_date  hba1c_mmol_per_mol_date



*******************************
*  Recode implausible values  *
*******************************


* BMI 

* Only keep if within certain time period? using bmi_date_measured ?
* NB: Some BMI dates in future or after cohort entry

* Set implausible BMIs to missing:
replace bmi = . if !inrange(bmi, 15, 50)




**********************
*  Recode variables  *
**********************

* Sex
assert inlist(sex, "M", "F")
gen male = (sex=="M")
drop sex


* Smoking
label define smoke 1 "Never" 2 "Former" 3 "Current" .u "Unknown (.u)"

gen     smoke = 1  if smoking_status=="N"
replace smoke = 2  if smoking_status=="E"
replace smoke = 3  if smoking_status=="S"
replace smoke = .u if smoking_status=="M"
label values smoke smoke
drop smoking_status


* Ethnicity 
replace ethnicity = .u if ethnicity==.

label define ethnicity 	1 "White"  					///
						2 "Mixed" 					///
						3 "Asian or Asian British"	///
						4 "Black"  					///
						5 "Other"					///
						.u "Unknown"
label values ethnicity ethnicity


* STP 
rename stp stp_old
bysort stp_old: gen stp = 1 if _n==1
replace stp = sum(stp)
drop stp_old




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

label define bmicat 1 "Underweight (<18.5)" 	///
					2 "Normal (18.5-24.9)"		///
					3 "Overweight (25-29.9)"	///
					4 "Obese I (30-34.9)"		///
					5 "Obese II (35-39.9)"		///
					6 "Obese III (40+)"			///
					.u "Unknown (.u)"
label values bmicat bmicat

* Create more granular categorisation
recode bmicat 1/3 .u = 1 4=2 5=3 6=4, gen(obese4cat)

label define obese4cat 	1 "No record of obesity" 	///
						2 "Obese I (30-34.9)"		///
						3 "Obese II (35-39.9)"		///
						4 "Obese III (40+)"		
label values obese4cat obese4cat
order obese4cat, after(bmicat)



/*  Smoking  */


* Create non-missing 3-category variable for current smoking
recode smoke .u=1, gen(smoke_nomiss)
order smoke_nomiss, after(smoke)
label values smoke_nomiss smoke



/*  Asthma  */


* Asthma  (coded: 0 No, 1 Yes no OCS, 2 Yes with OCS)
rename asthma asthmacat
recode asthmacat 0=1 1=2 2=3
label define asthmacat 1 "No" 2 "Yes, no OCS" 3 "Yes with OCS"
label values asthmacat asthmacat

gen asthma = (asthmacat==2|asthmacat==3)





/*  Blood pressure   */

* Categorise
gen     bpcat = 1 if bp_sys < 120 &  bp_dias < 80
replace bpcat = 2 if inrange(bp_sys, 120, 130) & bp_dias<80
replace bpcat = 3 if inrange(bp_sys, 130, 140) | inrange(bp_dias, 80, 90)
replace bpcat = 4 if (bp_sys>=140 & bp_sys<.) | (bp_dias>=90 & bp_dias<.) 
replace bpcat = .u if bp_sys>=. | bp_dias>=. | bp_sys==0 | bp_dias==0

label define bpcat 1 "Normal" 2 "Elevated" 3 "High, stage I"	///
					4 "High, stage II" .u "Unknown"
label values bpcat bpcat

recode bpcat .u=1, gen(bpcat_nomiss)
label values bpcat_nomiss bpcat

* Create non-missing indicator of known high blood pressure
gen bphigh = (bpcat==4)
order bpcat bphigh, after(bp_dias_date)




/*  IMD  */

* Group into 5 groups
rename imd imd_o
egen imd = cut(imd_o), group(5) icodes
replace imd = imd + 1
replace imd = .u if imd_o==-1
drop imd_o

* Reverse the order (so high is more deprived)
recode imd 5=1 4=2 3=3 2=4 1=5 .u=.u

label define imd 1 "1 least deprived" 2 "2" 3 "3" 4 "4" 5 "5 most deprived" .u "Unknown"
label values imd imd 




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




**************************************************
*  Create binary comorbidity indices from dates  *
**************************************************

* Comorbidities ever before
foreach var of varlist	chronic_respiratory_disease_date 	///
						chronic_cardiac_disease_date 		///
						diabetes 							///
						bone_marrow_transplant_date 		///
						chemo_radio_therapy_date			///
						chronic_liver_disease_date 			///
						stroke_date							///
						dementia_date						///
						other_neuro_date					///
						organ_transplant_date 				///
						aplastic_anaemia_date				///
						hypertension 						///
						dysplenia_date 						///
						sickle_cell_date 					///
						hiv_date							///
						permanent_immunodeficiency_date		///
						temporary_immunodeficiency_date		///
						ra_sle_psoriasis_date dialysis_date {
	local newvar =  substr("`var'", 1, length("`var'") - 5)
	gen `newvar' = (`var'< d(1/2/2020))
	order `newvar', after(`var')
}






***************************
*  Grouped comorbidities  *
***************************


/*  Neurological  */

* Stroke and dementia
egen stroke_dementia = rowmax(stroke dementia)
order stroke_dementia, after(dementia_date)


/*  Spleen  */

* Spleen problems (dysplenia/splenectomy/etc and sickle cell disease)   
egen spleen = rowmax(dysplenia sickle_cell) 
order spleen, after(sickle_cell)



/*  Cancer  */

label define cancer 1 "Never" 2 "Last year" 3 "2-5 years ago" 4 "5+ years"

* Haematological malignancies
gen     cancer_haem_cat = 4 if inrange(haem_cancer_date, d(1/1/1900), d(1/2/2015))
replace cancer_haem_cat = 3 if inrange(haem_cancer_date, d(1/2/2015), d(1/2/2019))
replace cancer_haem_cat = 2 if inrange(haem_cancer_date, d(1/2/2019), d(1/2/2020))
recode  cancer_haem_cat . = 1
label values cancer_haem_cat cancer


* All other cancers
gen     cancer_exhaem_cat = 4 if inrange(lung_cancer_date,  d(1/1/1900), d(1/2/2015)) | ///
								 inrange(other_cancer_date, d(1/1/1900), d(1/2/2015)) 
replace cancer_exhaem_cat = 3 if inrange(lung_cancer_date,  d(1/2/2015), d(1/2/2019)) | ///
								 inrange(other_cancer_date, d(1/2/2015), d(1/2/2019)) 
replace cancer_exhaem_cat = 2 if inrange(lung_cancer_date,  d(1/2/2019), d(1/2/2020)) | ///
								 inrange(other_cancer_date, d(1/2/2019), d(1/2/2020))
recode  cancer_exhaem_cat . = 1
label values cancer_exhaem_cat cancer


* Put variables together
order cancer_exhaem_cat cancer_haem_cat, after(other_cancer_date)



/*  Immunosuppression  */

* Immunosuppressed:
* HIV, permanent immunodeficiency ever, OR 
* temporary immunodeficiency or aplastic anaemia last year
gen temp1  = max(hiv, permanent_immunodeficiency)
gen temp2  = inrange(temporary_immunodeficiency_date, d(1/2/2019), d(1/2/2020))
gen temp3  = inrange(aplastic_anaemia_date, d(1/2/2019), d(1/2/2020))

egen other_immunosuppression = rowmax(temp1 temp2 temp3)
drop temp1 temp2 temp3
order other_immunosuppression, after(temporary_immunodeficiency)




/*  Hypertension  */

gen htdiag_or_highbp = bphigh
recode htdiag_or_highbp 0 = 1 if hypertension==1 




************
*   eGFR   *
************

* Set implausible creatinine values to missing (Note: zero changed to missing)
replace creatinine = . if !inrange(creatinine, 20, 3000) 
	
* Divide by 88.4 (to convert umol/l to mg/dl)
gen SCr_adj = creatinine/88.4

gen min=.
replace min = SCr_adj/0.7 if male==0
replace min = SCr_adj/0.9 if male==1
replace min = min^-0.329  if male==0
replace min = min^-0.411  if male==1
replace min = 1 if min<1

gen max=.
replace max=SCr_adj/0.7 if male==0
replace max=SCr_adj/0.9 if male==1
replace max=max^-1.209
replace max=1 if max>1

gen egfr=min*max*141
replace egfr=egfr*(0.993^age)
replace egfr=egfr*1.018 if male==0
label var egfr "egfr calculated using CKD-EPI formula with no eth"

* Categorise into ckd stages
egen egfr_cat = cut(egfr), at(0, 15, 30, 45, 60, 5000)
recode egfr_cat 0=5 15=4 30=3 45=2 60=0, generate(ckd)
* 0 = "No CKD" 	2 "stage 3a" 3 "stage 3b" 4 "stage 4" 5 "stage 5"
label define ckd 0 "No CKD" 1 "CKD"
label values ckd ckd
label var ckd "CKD stage calc without eth"

* Convert into CKD group
*recode ckd 2/5=1, gen(chronic_kidney_disease)
*replace chronic_kidney_disease = 0 if creatinine==. 
	
recode ckd 0=1 2/3=2 4/5=3, gen(reduced_kidney_function_cat)
replace reduced_kidney_function_cat = 1 if creatinine==. 
label define reduced_kidney_function_catlab 1 "None" 2 "Stage 3a/3b egfr 30-60	" 3 "Stage 4/5 egfr<30"
label values reduced_kidney_function_cat reduced_kidney_function_catlab 
 
	
************
*   Hba1c  *
************
	

/*  Diabetes severity  */

* Set zero or negative to missing
replace hba1c_percentage   = . if hba1c_percentage<=0
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol<=0


* Only consider measurements in last 15 months
replace hba1c_percentage   = . if hba1c_percentage_date   < d(1/11/2018)
replace hba1c_mmol_per_mol = . if hba1c_mmol_per_mol_date < d(1/11/2018)



/* Express  HbA1c as percentage  */ 

* Express all values as perecentage 
noi summ hba1c_percentage hba1c_mmol_per_mol 
gen 	hba1c_pct = hba1c_percentage 
replace hba1c_pct = (hba1c_mmol_per_mol/10.929)+2.15 if hba1c_mmol_per_mol<. 

* Valid % range between 0-20  
replace hba1c_pct = . if !inrange(hba1c_pct, 0, 20) 
replace hba1c_pct = round(hba1c_pct, 0.1)


/* Categorise hba1c and diabetes  */

* Group hba1c
gen 	hba1ccat = 0 if hba1c_pct <  6.5
replace hba1ccat = 1 if hba1c_pct >= 6.5  & hba1c_pct < 7.5
replace hba1ccat = 2 if hba1c_pct >= 7.5  & hba1c_pct < 8
replace hba1ccat = 3 if hba1c_pct >= 8    & hba1c_pct < 9
replace hba1ccat = 4 if hba1c_pct >= 9    & hba1c_pct !=.
label define hba1ccat 0 "<6.5%" 1">=6.5-7.4" 2">=7.5-7.9" 3">=8-8.9" 4">=9"
label values hba1ccat hba1ccat
tab hba1ccat

* Create diabetes, split by control/not
gen     diabcat = 1 if diabetes==0
replace diabcat = 2 if diabetes==1 & inlist(hba1ccat, 0, 1)
replace diabcat = 3 if diabetes==1 & inlist(hba1ccat, 2, 3, 4)
replace diabcat = 4 if diabetes==1 & !inlist(hba1ccat, 0, 1, 2, 3, 4)

label define diabcat 	1 "No diabetes" 			///
						2 "Controlled diabetes"		///
						3 "Uncontrolled diabetes" 	///
						4 "Diabetes, no hba1c measure"
label values diabcat diabcat

* Delete unneeded variables
drop hba1c_pct hba1c_percentage hba1c_mmol_per_mol



********************************
*  Outcomes and survival time  *
********************************


/*  Cohort entry and censor dates  */

* Date of cohort entry, 1 Feb 2020
gen enter_date = date("01/02/2020", "DMY")

* Date of study end (typically: last date of outcome data available)
gen ituadmissioncensor_date 	= date("$ituadmissioncensor", 	"DMY") 
gen cpnsdeathcensor_date		= date("$cpnsdeathcensor", 		"DMY")
gen onscoviddeathcensor_date 	= date("$onscoviddeathcensor", 	"DMY")

* Format the dates
format 	enter_date					///
		cpnsdeathcensor_date 		///
		onscoviddeathcensor_date 	///
		ituadmissioncensor_date  %td


/*   Outcomes   */

* Dates of: ITU admission, CPNS death, ONS-covid death
foreach var of varlist 	died_date_ons died_date_cpns		///
						icu_date_admitted  {
	confirm string variable `var'
	rename `var' `var'_dstr
	gen `var' = date(`var'_dstr, "YMD")
	drop `var'_dstr
}
rename icu_date_admitted itu_date

* Date of Covid death in ONS
gen died_date_onscovid = died_date_ons if died_ons_covid_flag_any==1

* Binary indicators for outcomes
gen cpnsdeath 		= (died_date_cpns		< .)
gen onscoviddeath 	= (died_date_onscovid 	< .)
gen ituadmission 	= (itu_date 			< .)



/*  Create survival times  */

* For looping later, name must be stime_binary_outcome_name

* Survival time = last followup date (first: end study, death, or that outcome)
gen stime_ituadmission 	= min(ituadmissioncensor_date, 	itu_date, 		died_date_ons)
gen stime_cpnsdeath  	= min(cpnsdeathcensor_date, 	died_date_cpns, died_date_ons)
gen stime_onscoviddeath = min(onscoviddeathcensor_date, 				died_date_ons)

* If outcome was after censoring occurred, set to zero
replace ituadmission 	= 0 if (itu_date			> ituadmissioncensor_date) 
replace cpnsdeath 		= 0 if (died_date_cpns		> cpnsdeathcensor_date) 
replace onscoviddeath 	= 0 if (died_date_onscovid	> onscoviddeathcensor_date) 

* Format date variables
format stime* %td 
format	stime* 				///
		itu_date 			///
		died_date_onscovid 	///
		died_date_ons 		///
		died_date_cpns %td 



*********************
*  Label variables  *
*********************

* Demographics
label var patient_id					"Patient ID"
label var age 							"Age (years)"
label var agegroup						"Grouped age"
label var age70 						"70 years and older"
label var male 							"Male"
label var bmi 							"Body Mass Index (BMI, kg/m2)"
label var bmicat 						"Grouped BMI"
label var bmi_date  					"Body Mass Index (BMI, kg/m2), date measured"
label var obese4cat						"Evidence of obesity (4 categories)"
label var smoke		 					"Smoking status"
label var smoke_nomiss	 				"Smoking status (missing set to non)"
label var imd 							"Index of Multiple Deprivation (IMD)"
label var ethnicity						"Ethnicity"
label var stp 							"Sustainability and Transformation Partnership"
label var region 						"Geographical region"

label var hba1ccat						"Categorised hba1c"
label var egfr_cat						"Calculated eGFR"
	
label var bp_sys 						"Systolic blood pressure"
label var bp_sys_date 					"Systolic blood pressure, date"
label var bp_dias 						"Diastolic blood pressure"
label var bp_dias_date 					"Diastolic blood pressure, date"
label var bpcat 						"Grouped blood pressure"
label var bphigh						"Binary high (stage 1/2) blood pressure"
label var htdiag_or_highbp				"Diagnosed hypertension or high blood pressure"

label var age1 							"Age spline 1"
label var age2 							"Age spline 2"
label var age3 							"Age spline 3"
label var c_age							"Centred age"
label var c_male 						"Centred sex (code: -1/+1)"
label var c_imd							"Centred Index of Multiple Deprivation (values: -2/+2)"
label var c_ethnicity					"Centred ethnicity (values: -2/+2)"

* Comorbidities
label var chronic_respiratory_disease	"Respiratory disease (excl. asthma)"
label var asthmacat						"Asthma, grouped by severity (OCS use)"
label var asthma						"Asthma"
label var chronic_cardiac_disease		"Heart disease"
label var diabetes						"Diabetes"
label var diabcat						"Diabetes, grouped"
label var cancer_exhaem_cat				"Cancer (exc. haematological), grouped by time since diagnosis"
label var cancer_haem_cat				"Haematological malignancy, grouped by time since diagnosis"
label var chronic_liver_disease			"Chronic liver disease"
label var stroke_dementia				"Stroke or dementia"
label var other_neuro					"Neuro condition other than stroke/dementia"	
label var reduced_kidney_function_cat	"Reduced kidney function" 
label var organ_transplant 				"Organ transplant recipient"
label var dysplenia						"Dysplenia (splenectomy, other, not sickle cell)"
label var sickle_cell 					"Sickle cell"
label var spleen						"Spleen problems (dysplenia, sickle cell)"
label var ra_sle_psoriasis				"RA, SLE, Psoriasis (autoimmune disease)"
label var chemo_radio_therapy			"Chemotherapy or radiotherapy"
label var aplastic_anaemia				"Aplastic anaemia"
label var hiv 							"HIV"
label var permanent_immunodeficiency 	"Permanent immunodeficiency"
label var temporary_immunodeficiency 	"Temporary immunosuppression"
label var other_immunosuppression		"Immunosuppressed (combination algorithm)"
label var chronic_respiratory_disease_date	"Respiratory disease (excl. asthma), date"
label var chronic_cardiac_disease_date	"Heart disease, date"
label var diabetes_date					"Diabetes, date"
label var lung_cancer_date				"Lung cancer, date"
label var haem_cancer_date				"Haem. cancer, date"
label var other_cancer_date				"Any cancer, date"
label var bone_marrow_transplant_date	"Organ transplant, date"
label var chronic_liver_disease_date	"Liver, date"
label var stroke_date					"Stroke, date"
label var dementia_date					"Dementia, date"
label var other_neuro_date				"Neuro condition other than stroke/dementia, date"	
label var organ_transplant_date			"Organ transplant recipient, date"
label var dysplenia_date				"Splenectomy etc, date"
label var sickle_cell_date 				"Sickle cell, date"
label var ra_sle_psoriasis_date			"RA, SLE, Psoriasis (autoimmune disease), date"
label var chemo_radio_therapy_date		"Chemotherapy or radiotherapy, date"
label var aplastic_anaemia_date			"Aplastic anaemia, date"
label var hiv_date 						"HIV, date"
label var permanent_immunodeficiency_date "Permanent immunodeficiency, date"
label var temporary_immunodeficiency_date "Temporary immunosuppression, date"
label var dialysis						"Dialysis"
	
* Outcomes and follow-up
label var enter_date					"Date of study entry"
label var ituadmissioncensor_date 		"Date of admin censoring for itu admission (icnarc)"
label var cpnsdeathcensor_date 			"Date of admin censoring for cpns deaths"
label var onscoviddeathcensor_date 		"Date of admin censoring for ONS deaths"

label var ituadmission					"Failure/censoring indicator for outcome: ITU admission"
label var cpnsdeath						"Failure/censoring indicator for outcome: CPNS covid death"
label var onscoviddeath					"Failure/censoring indicator for outcome: ONS covid death"

* Survival times
label var  stime_ituadmission			"Survival time (date); outcome ITU admission"
label var  stime_cpnsdeath 				"Survival time (date); outcome CPNS covid death"
label var  stime_onscoviddeath 			"Survival time (date); outcome ONS covid death"




***************
*  Tidy data  *
***************

* REDUCE DATASET SIZE TO VARIABLES NEEDED
keep patient_id imd stp region enter_date  									///
	ituadmission itu_date ituadmissioncensor_date stime_ituadmission		///
	cpnsdeath died_date_cpns cpnsdeathcensor_date stime_cpnsdeath			///
	onscoviddeath onscoviddeathcensor_date died_date_ons died_date_onscovid ///
	stime_onscoviddeath														///
	age agegroup age70 age1 age2 age3 male bmi smoke   						///
	smoke smoke_nomiss bmicat bpcat_nomiss obese4cat ethnicity 				///
	bpcat bphigh htdiag_or_highbp hypertension 								///
	chronic_respiratory_disease asthma asthmacat chronic_cardiac_disease 	///
	diabetes diabcat hba1ccat cancer_exhaem_cat cancer_haem_cat 			///
	chronic_liver_disease organ_transplant spleen ra_sle_psoriasis 			///
	reduced_kidney_function_cat stroke dementia stroke_dementia other_neuro		///
	other_immunosuppression   												///
	creatinine egfr egfr_cat ckd  dialysis



***************
*  Save data  *
***************

sort patient_id
label data "Analysis dataset for the poor outcomes in Covid project"
save "cr_create_analysis_dataset.dta", replace

* Save a version set on CPNS survival outcome
stset stime_cpnsdeath, fail(cpnsdeath) 				///
	id(patient_id) enter(enter_date) origin(enter_date)
	
save "cr_create_analysis_dataset_STSET_cpnsdeath.dta", replace


log close

