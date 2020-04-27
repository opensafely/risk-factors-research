
use cr_create_analysis_dataset, clear

replace ituadmission = (uniform()<0.20)

replace cpnsdeath = (uniform()<0.20)

replace onscoviddeath = (uniform()<0.20)

replace bmicat = 1+(floor(6*uniform())) if bmicat==.u
replace obese4cat = 2 if bmicat==4
replace obese4cat = 3 if bmicat==5
replace obese4cat = 4 if bmicat==6 

replace organ_transplant = uniform()<.05

replace ckd = uniform()<.1

replace other_immunosuppression = uniform()<.1

replace cancer_exhaem = 2 + (uniform()>0.5) if uniform()<.2
replace cancer_exhaem = 4 if cancer_exhaem ==1 & uniform()<.1
replace cancer_haem = 2 + (uniform()>0.5) if uniform()<.2

replace asthmacat = 2 + (uniform()>.5) if uniform()<.2

replace ethnicity = 1+(floor(5*uniform())) 

*FIZZ TO ADD STHG ON GEOG AREA HERE TOO

save cr_create_analysis_dataset, replace
