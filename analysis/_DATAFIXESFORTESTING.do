
use cr_create_analysis_dataset, clear

replace ituadmission = (uniform()<0.20)

*give cpns death realistic dates, and lots of events
replace cpnsdeath = (uniform()<0.20)
replace died_date_cpns = d(1/2/2020)+floor(80*uniform()) if cpnsdeath==1
replace stime_cpnsdeath  	= min(cpnsdeathcensor_date, 	died_date_cpns, died_date_ons)
replace cpnsdeath 		= 0 if (died_date_cpns		> cpnsdeathcensor_date) 

replace cpns_died_date 
replace onscoviddeath = (uniform()<0.20)

replace bmicat = 1+(floor(6*uniform())) if bmicat==.u
replace obese4cat = 2 if bmicat==4
replace obese4cat = 3 if bmicat==5
replace obese4cat = 4 if bmicat==6 

replace organ_transplant = uniform()<.05

replace chronic_kidney_disease = uniform()<.1

replace other_immunosuppression = uniform()<.1

replace cancer_exhaem = 2 + (uniform()>0.5) if uniform()<.2
replace cancer_exhaem = 4 if cancer_exhaem ==1 & uniform()<.1
replace cancer_haem = 2 + (uniform()>0.5) if uniform()<.2

replace asthmacat = 2 + (uniform()>.5) if uniform()<.2

replace ethnicity = 1+(floor(5*uniform())) 


save cr_create_analysis_dataset, replace

* Save a version set on CPNS survival outcome
stset stime_cpnsdeath, fail(cpnsdeath) 				///
	id(patient_id) enter(enter_date) origin(enter_date)
	
save "cr_create_analysis_dataset_STSET_cpnsdeath.dta", replace
