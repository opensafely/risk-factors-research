********************************************************************************
*
*	Do-file:		an_univariable_cox_models.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		egdata.dta
*
*	Data created:	None
*
*	Other output:	Log file: an_univariable_cox_models.log 
*
*
********************************************************************************
*
*	Purpose:		This do-file is a very initial draft of Stata code to 
*					do poor outcomes analysis.
*  
********************************************************************************


local outcome `1'

*DEFINE VARIABLE LIST FOR USE THROUGH LOOPS
local listofvars 	bmicat 							///
					obese40							///
					smoke 							///
					currentsmoke					///
					ethnicity 						///
					imd 							///
					bpcat 							///
					bphigh 							///
					chronic_respiratory_disease 	///
					asthma 							///
					chronic_cardiac_disease 		///
					diabetes 						///
					cancer_exhaem_lastyr 			///
					haemmalig_aanaem_bmtrans_lastyr ///
					chronic_liver_disease 			///
					stroke_dementia		 			///
					other_neuro					 	///
					chronic_kidney_disease 			///
					organ_transplant 				///
					spleen							/// 
					ra_sle_psoriasis  				///
					/*endocrine?*/					///
					/*immunosuppression?*/			

************************************************************************************
*First clean up all old saved estimates for this outcome
*This is to guard against accidentally displaying left-behind results from old runs
************************************************************************************
	cap erase ./output/models/an_univariable_cox_models_`outcome'_AGESPLSEX_.ster
	cap erase./output/models/an_univariable_cox_models_`outcome'_AGEGROUPSEX_.ster
foreach var of any `listofvars' {
	cap erase ./output/models/an_univariable_cox_models_`outcome'_AGESPLSEX_`var'.ster
	}

* Open a log file
capture log close
log using "./output/an_univariable_cox_models_`outcome'", text replace

use egdata, clear

***************************
*  Run Age and sex  models*
***************************

	stset stime_`outcome', fail(`outcome') enter(enter_date) origin(enter_date) id(patient_id) 

	* Cox model for age
	capture stcox age1 age2 age3 i.male, strata(stp) 
	if _rc==0 {
		estimates
		estimates save ./output/models/an_univariable_cox_models_`outcome'_AGESPLSEX_, replace
		est store base
		estat ic
	}	
	else di "WARNING - AGESPL SEX vs `outcome' MODEL DID NOT SUCCESSFULLY FIT"


	capture stcox ib3.agegroup i.male, strata(stp) 
	if _rc==0 {
		estimates
		estimates save ./output/models/an_univariable_cox_models_`outcome'_AGEGROUPSEX_, replace
		estat ic
	}
	else di "WARNING - AGEGROUP SEX vs `outcome' MODEL DID NOT SUCCESSFULLY FIT"


*****************************************
*  Loop through Age, sex  + 1 VAR models*
*****************************************

	foreach var of any `listofvars'	{		
		local b
		if "`var'"=="bmicat" local b "b2" /*group 2 is the baseline for BMI, baseline for all others is lowest level*/
		timer clear
		timer on 1
		capture stcox age1 age2 age3 male i`b'.`var', strata(stp) 
		if _rc==0 {
			estimates
			estimates save ./output/models/an_univariable_cox_models_`outcome'_AGESPLSEX_`var', replace
		}
		else di "WARNING - `var' vs `outcome' MODEL DID NOT SUCCESSFULLY FIT"
		timer off 1
		timer list
		} /*end of looping round vars for 1 var at a time models*/




* Close log file
log close
