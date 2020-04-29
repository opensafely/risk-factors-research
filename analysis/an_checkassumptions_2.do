********************************************************************************
*
*	Do-file:		an_checkassumptions_2.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		cr_create_analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Kaplan-Meier plots (for data checking)
*							output/{LOTS OF KM PLOTS}.svg 	
*							
*					
*
********************************************************************************
*
*	Purpose:		This do-file creates Kaplan-Meier plots by age and sex. 
*  
********************************************************************************
*	
*	Stata routines needed:	grc1leg	
*
********************************************************************************



use cr_create_analysis_dataset, clear




********************************************************
*  KM plots for each factor, adjusted for sex and age  *
********************************************************



/*  Centred age, sex, IMD, ethnicity (for adjusted KM plots)  */ 

* Centre age (linear)
summ age
gen c_age = age-r(mean)

* "Centre" sex to be coded -1 +1 
recode male 0=-1, gen(c_male)


* Declare survival outcome
stset stime_cpnsdeath, fail(cpnsdeath) 			///
	id(patient_id) enter(enter_date) origin(enter_date)


sts graph, by(male) adjustfor(c_age) 						///
			failure yscale(range(0, 0.012)) 				///
			ylabel(0 (0.0025) 0.01, angle(0) format(%5.4f))	///
			noorigin										///
			xscale(range(30, 84)) 							///
			xlabel(30 (10) 80)							
	
graph export "output/km_adj_male.svg", replace as(svg)

			
* Loop over risk factors
foreach rf of varlist 	region							///
						imd 							///
						ethnicity						///	
						bmicat 							///
						bpcat 							///
						htdiag_or_highbp				///
						smoke		 					///
						chronic_respiratory_disease 	///
						asthmacat						///
						chronic_cardiac_disease 		///
						diabetes 						///
						cancer_exhaem_cat				///
						cancer_haem_cat`'				///
						chronic_liver_disease 			///
						dementia						///
						stroke							///
						stroke_dementia					///
						other_neuro 					///
						chronic_kidney_disease 			///
						organ_transplant 				///	
						spleen 							///
						ra_sle_psoriasis				///
						other_immunosuppression { 


		* Kaplan-Meier graph, adjusted for age and sex
		sts graph, by(`rf') adjustfor(c_age c_male) 		///
			failure yscale(range(0, 0.012)) 				///
			ylabel(0 (0.0025) 0.01, angle(0) format(%5.4f))	///
			noorigin										///
			xscale(range(30, 84)) 							///
			xlabel(30 (10) 80)							

		graph export "output/km_adj_`rf'.svg", replace as(svg)
}





