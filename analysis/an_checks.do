********************************************************************************
*
*	Do-file:		an_checks.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		egdata.dta
*
*	Data created:	None
*
*	Other output:	Graphs (cumulative events by time in study):
*						events_died.png
*						events_hosp.png
*						events_itu.png
*
********************************************************************************
*
*	Purpose:		This do-file runs a series of checks and creates a log 
*					file to record them:
*						- check variables take expected values/ranges
*						- cross-check logical relationships
*						- explore expected relationships
*						- check stsettings
*  
********************************************************************************



* Open a log file
capture log close
log using "an_checks", text replace



******************************************
*  Check variables take expected values  *
******************************************

* Age
assert age<.
*assert inrange(age, 18, 105)
assert inlist(agegroup, 1, 2, 3, 4, 5, 6)
assert inlist(age70, 0, 1)

* Sex
assert inlist(sex, "M", "F")

* BMI 
* assert inrange(bmi, 10, 200) | bmi==.
assert inlist(obese40, 0, 1)
assert inlist(bmicat, 1, 2, 3, 4, 5, 6, .u)
* IMD
assert inlist(imd, 1, 2, 3, 4, 5)

* Ethnicity
assert inlist(ethnicity, 1, 2, 3, 4, 5, .u)

* Smoking
assert inlist(smoke, 1, 2, 3, .u)
assert inlist(currentsmoke, 0, 1)




***************************************
*  Cross-check logical relationships  *
***************************************


* BMI
bysort bmicat: summ bmi
tab bmicat obese40, m

* Age
bysort agegroup: summ age
tab agegroup age70, m

* Smoking
tab smoke currentsmoke, m



*********************
*  Summarise dates  *
*********************

* BMI
summ bmi_date_measured, format

* Dates of comorbidities  * Add asthma date
foreach var of varlist 	chronic_respiratory_disease 	///
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

	summ `var'_date, format
	bysort `var': summ `var'_date
}



* Outcome dates
*****??? 




****************************************
*  Cross-check expected relationships  *
****************************************

* everything vs each demographic/lifestyle
* (i.e. vs age, sex, smoke, bmi cat, imd)

* resp vs asthma
* heart vs diabetes
* heart vs hypertension (bp cat)
* transplant vs immunosup
* ?any others you can think of where we’d expect certain relationships?


tab chronic_respiratory_disease
chronic_respiratory_disease 	///
						chronic_cardiac_disease 		///
						diabetes lung_cancer 			///
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
						ra_sle_psoriasis  




********************************************
*  Cross-check logical date relationships  *
********************************************

* Cross check dates of hosp/itu/death??






*****************************
*  Check survival settings  *
*****************************

* Death
stset stime_died, fail(died) enter(enter_date) origin(enter_date) id(patient_id) 
sort _t
gen cum_died = sum(_d)
line cum_died _t, sort(_t
graph export events_died.png, replace as(png)

* Hospitalised for Covid
stset stime_hosp, fail(hosp) enter(enter_date) origin(enter_date) id(patient_id) 
sort _t
gen cum_hosp = sum(_d)
line cum_hosp _t, sort(_t
graph export events_hosp.png, replace as(png)


* ITU admission for Covid
stset stime_itu, fail(itu) enter(enter_date) origin(enter_date) id(patient_id) 
sort _t
gen cum_itu = sum(_d)
line cum_itu _t, sort(_t
graph export events_itu.png, replace as(png)





* Close log file 
log close


