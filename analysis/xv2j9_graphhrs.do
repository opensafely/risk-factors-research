********************************************************************************
*
*	Do-file:		xv2j9_graphhrs.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		cr_create_analysis_dataset_STSET_onscoviddeath.dta
*
*	Data created:	output/abs_risks_`ethnicity'.dta, for ethnicity = 1,2,..,5
*
*	Other output:	Log file:  xj1_absolute_risk_model_`ethnicity'.log
*
********************************************************************************
*
*	Purpose:		This do-file performs survival analysis using Royston-Parmar
*					flexible hazard modelling. 
*
*					These analyses will be helpful in considering how 
*					comorbidities and demographic factors affect risk, 
*					comparatively.
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************



use output/hrs_death, clear
rename coef coef_death_sd
merge 1:1 term using output/hrs_hosp, nogen
rename coef coef_hosp_sd
merge 1:1 term using output/hrs_se_hosp, nogen
rename se se_hosp_sd
merge 1:1 term using output/hrs_se_death, nogen
rename se se_death_sd

merge 1:1 term using output/hrs_death_cs, nogen
rename coef coef_death_cs
merge 1:1 term using output/hrs_hosp_cs, nogen
rename coef coef_hosp_cs

drop if regex(term, "rcs")
drop if term=="hiv"
drop if term=="_cons"
drop if regex(term, "region")

twoway 	(scatter coef_death_sd coef_hosp_sd)		///
		(function y=x, range(-0.5 1.5))	, 			///
		ytitle("HR for COVID death")				///
		xtitle("HR for COVID admission")			///
		xlabel(-0.5 "0.61" 0 "1" 0.5 "1.65" 1 "2.72" 1.5 "4.48") ///
		ylabel(-0.5 "0.61" 0 "1" 0.5 "1.65" 1 "2.72" 1.5 "4.48") ///
		legend(off)
graph export output/hr_by_hr.svg, as(svg) replace width(1600)


*scatter coef_death_cs coef_hosp_cs
*scatter coef_hosp_sd coef_hosp_cs
*scatter coef_death_sd coef_death_cs





* Comorbidity names
rename term name
gen Name = ""
replace Name = "No comorbidity"							if name=="cons"
replace Name = "Age"									if substr(name, 1, 3)=="age"
replace Name = "Male"									if name=="male"
replace Name = "IMD"									if substr(name, 1, 3)=="imd"
replace Name = "Ethnicity"								if substr(name, 1, 9)=="ethnicity"
replace Name = "BMI"									if substr(name, 1, 5)=="obese"
replace Name = "Smoking"								if substr(name, 1, 5)=="smoke"
replace Name = "Hypertension/high bp" 					if name=="htdiag_or_highbp" 
replace Name = "Chronic respiratory disease" 			if name=="respiratory_disease"
replace Name = "Asthma" 								if substr(name, 1, 9)=="asthmacat"
replace Name = "Chronic cardiac disease" 				if name=="cardiac_disease"
replace Name = "Diabetes"								if substr(name, 1, 7)=="diabcat"
replace Name = "Cancer (non-haematological)" 			if substr(name, 1, 17)=="cancer_exhaem_cat"
replace Name = "Haematological malignancy" 				if substr(name, 1, 15)=="cancer_haem_cat"
replace Name = "Chronic liver disease"	 				if name=="chronic_liver_disease"
replace Name = "Stroke or dementia"						if name=="stroke_dementia"
replace Name = "Other neurological" 					if name=="other_neuro"
replace Name = "Reduced kidney function" 				if substr(name, 1, 14)=="red_kidney_cat"
replace Name = "Organ transplant" 						if name=="organ_transplant"
replace Name = "Asplenia" 								if name=="spleen"
replace Name = "Rheumatoid arthritis/Lupus/Psoriasis" 	if name=="ra_sle_psoriasis"
replace Name = "Other immunosuppression" 				if name=="immunosuppression"
replace Name = "HIV"					 				if name=="hiv"




* Levels
gen leveldesc = " "

replace leveldesc = "Controlled (HbA1c <58mmol/mol)" 		if name == "diabcat_2"
replace leveldesc = "Uncontrolled (HbA1c >=58mmol/mol) " 	if name == "diabcat_3"
replace leveldesc = "Unknown HbA1c" 						if name == "diabcat_4"

replace leveldesc = "With no recent OCS use" 				if name ==  "asthmacat_2"
replace leveldesc = "With recent OCS use" 					if name ==  "asthmacat_3"

replace leveldesc = "<1 year ago" 							if name == "cancer_exhaem_cat_2"
replace leveldesc = "1-4.9 years ago" 						if name == "cancer_exhaem_cat_3"
replace leveldesc = "5+ years ago" 							if name == "cancer_exhaem_cat_4"

replace leveldesc = "<1 year ago" 							if name == "cancer_haem_cat_2"
replace leveldesc = "1-4.9 years ago" 						if name == "cancer_haem_cat_3"
replace leveldesc = "5+ years ago" 							if name == "cancer_haem_cat_4"

replace leveldesc = "eGFR 30-60 ml/min/1.73m2" 				if name == "red_kidney_cat_2" 
replace leveldesc = "eGFR <30 ml/min/1.73m2" 				if name == "red_kidney_cat_3" 

replace leveldesc = "Obese I (30-34.9)" 					if name == "obese4cat_2"
replace leveldesc = "Obese II (35-39.9)" 					if name == "obese4cat_3"
replace leveldesc = "Obese III (40+)" 						if name == "obese4cat_4"

replace leveldesc = "Former" 								if name == "smoke_nomiss_2"
replace leveldesc = "Current" 								if name == "smoke_nomiss_3"

replace leveldesc = "Spline 1" 								if name == "age1"
replace leveldesc = "Spline 2" 								if name == "age2"
replace leveldesc = "Spline 3" 								if name == "age3"


replace leveldesc = "Mixed" 								if name == "ethnicity_2"
replace leveldesc = "Asian" 								if name == "ethnicity_3"
replace leveldesc = "Black" 								if name == "ethnicity_4"
replace leveldesc = "Other" 								if name == "ethnicity_5"

replace leveldesc = "2" 									if name == "imd_2"
replace leveldesc = "3" 									if name == "imd_3"
replace leveldesc = "4" 									if name == "imd_4"
replace leveldesc = "5" 									if name == "imd_5"





* Levels
gen catorder = .

replace catorder = 1 	if name == "diabcat_2"
replace catorder = 2 	if name == "diabcat_3"
replace catorder = 3	if name == "diabcat_4"

replace catorder = 1 	if name ==  "asthmacat_2"
replace catorder = 2 	if name ==  "asthmacat_3"

replace catorder = 1 	if name == "cancer_exhaem_cat_2"
replace catorder = 2	if name == "cancer_exhaem_cat_3"
replace catorder = 3	if name == "cancer_exhaem_cat_4"

replace catorder = 1	if name == "cancer_haem_cat_2"
replace catorder = 2	if name == "cancer_haem_cat_3"
replace catorder = 3	if name == "cancer_haem_cat_4"

replace catorder = 1	if name == "red_kidney_cat_2" 
replace catorder = 2	if name == "red_kidney_cat_3" 

replace catorder = 1	if name == "obese4cat_2"
replace catorder = 2	if name == "obese4cat_3"
replace catorder = 3 	if name == "obese4cat_4"

replace catorder = 1	if name == "smoke_nomiss_2"
replace catorder = 2 	if name == "smoke_nomiss_3"

replace catorder = 1 	if name == "age1"
replace catorder = 2	if name == "age2"
replace catorder = 3	if name == "age3"

replace catorder = 3 	if name == "ethnicity_2"
replace catorder = 1 	if name == "ethnicity_3"
replace catorder = 2 	if name == "ethnicity_4"
replace catorder = 4	if name == "ethnicity_5"

replace catorder = 1 	if name == "imd_2"
replace catorder = 2 	if name == "imd_3"
replace catorder = 3 	if name == "imd_4"
replace catorder = 4 	if name == "imd_5"






gen hr_death = exp(coef_death_sd)
gen hr_hosp  = exp(coef_hosp_sd)

gen hr_cu_death = exp(coef_death_sd + se_hosp_sd*1.96)
gen hr_cl_death = exp(coef_death_sd - se_hosp_sd*1.96)
gen hr_cu_hosp  = exp(coef_hosp_sd + se_hosp_sd*1.96)
gen hr_cl_hosp  = exp(coef_hosp_sd - se_hosp_sd*1.96)




gen varorder = 1 if Name=="Age" 
replace varorder = 2 if Name=="Male"
replace varorder = 3 if Name=="Ethnicity" 
replace varorder = 4 if Name=="IMD" 
replace varorder = 5 if Name=="BMI"  
replace varorder = 6 if Name=="Smoking" 
replace varorder = 7 if Name=="Asthma"  
replace varorder = 8 if Name=="Chronic respiratory disease" 
replace varorder = 9 if Name=="Hypertension/high bp" 
replace varorder = 10 if Name=="Diabetes" 
replace varorder = 11 if Name=="Chronic cardiac disease"  
replace varorder = 12 if Name=="Stroke or dementia" 
replace varorder = 13 if Name=="Other neurological" 
replace varorder = 14 if Name=="Cancer (non-haematological)"  
replace varorder = 15 if Name=="Haematological malignancy"
replace varorder = 16 if Name=="Chronic liver disease"  
replace varorder = 17 if Name=="Reduced kidney function" 
replace varorder = 18 if Name=="Organ transplant" 
replace varorder = 19 if Name=="Asplenia"  
replace varorder = 20 if Name=="Rheumatoid arthritis/Lupus/Psoriasis" 
replace varorder = 21 if Name=="Other immunosuppression" 


sort varorder catorder


order Name level hr*death hr*hosp
keep Name leveldesc hr*death hr*hosp


gen death = string(round(hr_death, 0.01)) + "  (" +  ///
			string(round(hr_cl_death, 0.01))  + ",  " + ///
			string(round(hr_cu_death, 0.01)) +  ")"
			
gen hosp = 	string(round(hr_hosp, 0.01)) + "  (" +  ///
			string(round(hr_cl_hosp, 0.01))  + ",  " + ///
			string(round(hr_cu_hosp, 0.01)) +  ")"

outsheet using "output/hrs_table", replace

