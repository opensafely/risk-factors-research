
use cr_create_analysis_dataset, clear

replace ituadmission = (uniform()<0.20)

*give death outcomes realistic dates, and lots of events
foreach outcome of any cpnsdeath onscoviddeath{
	if "`outcome'" == "cpnsdeath" local outcomeshort "cpns"
	else if "`outcome'" == "onscoviddeath" local outcomeshort "onscovid"

	replace `outcome' = (uniform()<0.20)
	replace died_date_`outcomeshort' = d(1/2/2020)+floor(80*uniform()) if `outcome'==1
	replace stime_`outcome'  	= min(`outcome'censor_date, 	died_date_`outcomeshort', died_date_ons)
	replace `outcome' 		= 0 if (died_date_`outcomeshort'		> `outcome'censor_date) 
}

*replace cpns_died_date 
*replace onscoviddeath = (uniform()<0.20)

replace bmicat = 1+(floor(6*uniform())) if bmicat==.u
replace obese4cat = 2 if bmicat==4
replace obese4cat = 3 if bmicat==5
replace obese4cat = 4 if bmicat==6 

replace organ_transplant = uniform()<.05

*replace chronic_kidney_disease = uniform()<.1
replace dialysis = uniform()<0.05

replace other_immunosuppression = uniform()<.1

replace cancer_exhaem = 2 + (uniform()>0.5) if uniform()<.2
replace cancer_exhaem = 4 if cancer_exhaem ==1 & uniform()<.1
replace cancer_haem = 2 + (uniform()>0.5) if uniform()<.2

replace asthmacat = 2 + (uniform()>.5) if uniform()<.2

replace ethnicity = 1+(floor(5*uniform())) 

replace ethnicity_16 = 1+(floor(16*uniform())) 


* Kidney function 
replace reduced_kidney_function_cat=.
replace reduced_kidney_function_cat  = 1 if uniform()<0.5
replace reduced_kidney_function_cat  = 2 if uniform()<0.5 & reduced_kidney_function_cat==.
replace reduced_kidney_function_cat  = 3 if reduced_kidney_function_cat==.




save cr_create_analysis_dataset, replace


* Save a version set on CPNS survival outcome
stset stime_cpnsdeath, fail(cpnsdeath) 				///
	id(patient_id) enter(enter_date) origin(enter_date)

save "cr_create_analysis_dataset_STSET_cpnsdeath.dta", replace

* Save a version set on ONS covid death outcome
stset stime_onscoviddeath, fail(onscoviddeath) 				///
	id(patient_id) enter(enter_date) origin(enter_date)
	
save "cr_create_analysis_dataset_STSET_onscoviddeath.dta", replace
	