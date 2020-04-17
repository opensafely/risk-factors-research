********************************************************************************
*
*	Do-file:		an_descriptive_plots.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		egdata.dta
*
*	Data created:	None
*
*	Other output:	Kaplan-Meier plots 
*							km_age_sex.png (intended for publication)
*
*							(others later)   (for data checking)
*
********************************************************************************
*
*	Purpose:		This do-file creates Kaplan-Meier plots for each risk
*					factor of interest.
*  
********************************************************************************
*	
*	Stata routines needed:	grc1leg	
*
********************************************************************************



use egdata, clear


****************************
*  KM plot by age and sex  *
****************************

*** Intended for publication

* Set max/gap for ylabels eventually

foreach outvar of varlist died hosp itu {

	* Declare survival outcome
	stset stime_`outvar', fail(`outvar') 			///
		id(patient_id) enter(enter_date) origin(enter_date)

	* KM plot for females by age		
	sts graph if male==0, title("Female") 			///
		failure by(agegroup) 						///
		xline(25, lpattern(dash) lcolor(maroon))	///
		yscale(range(0, 0.1)) 						///
		ylabel(0 (0.025) 0.1, angle(0))				///
		xtitle("Days since 1 Feb 2020")				///
		legend(order(1 2 3 4 5 6)					///
		subtitle("Age group", size(small)) 			///
		label(1 "18-<40") label(2 "40-<50") 		///
		label(3 "50-<60") label(4 "60-<70")			///
        label(5 "70-<80") label(6 "80+")			///
		col(2) size(small))							///
		saving(female, replace)
	* KM plot for males by age		
	sts graph if male==1, title("Male") 			///
		failure by(agegroup)						///
		xline(25, lpattern(dash) lcolor(maroon))	///
		yscale(range(0, 0.1)) 						///
		ylabel(0 (0.025) 0.1, angle(0))				///
		xtitle("Days since 1 Feb 2020")				///
		legend(order(1 2 3 4 5 6)					///
		subtitle("Age group", size(small)) 			///
		label(1 "18-<40") label(2 "40-<50") 		///
		label(3 "50-<60") label(4 "60-<70")			///
        label(5 "70-<80") label(6 "80+") 			///
		col(2) size(small))							///
		saving(male, replace)
	* KM plot for males and females 
	grc1leg female.gph male.gph, 					///
		t1("Composite: ITU admission or death") 	///
		saving(both_`outvar', replace)
	* Delete unneeded graphs
	erase female.gph
	erase male.gph
}

* Combine graphs  (change to grc1leg eventually)
grc1leg both_died.gph	///
		both_itu.gph	///
		both_hosp.gph	///
		, col(1) 
graph display, xsize(3)
* Export graph
graph export "output/km_age_sex.eps", as(eps) replace

* Delete unneeded graphs
erase both_died.gph
erase both_itu.gph
erase both_hosp.gph





********************************************************
*  KM plots for each factor, adjusted for sex and age  *
********************************************************
/*
* Loop over outcomes
foreach outvar of varlist died hosp itu {
					
	* Declare survival outcome
	stset stime_`outvar', fail(`outvar') 					///
		id(patient_id) enter(enter_date) origin(enter_date)
		
	* Loop over risk factors
	foreach rf of varlist 	imd 							///
							ethnicity						///	
							bmicat 							///
							obese40 						///
							smoke		 					///
							currentsmoke 					///
							chronic_respiratory_disease 	///
							asthma 							///
							chronic_cardiac_disease 		///
							diabetes 						///
							cancer_lastyr					///
							chronic_liver_disease 			///
							neurological_condition 			///
							chronic_kidney_disease 			///
							organ_transplant 				///	
							spleen 							///
							immunosuppressed	 			///
							ra_sle_psoriasis { 

		* Kaplan-Meier graph, adjusted for age and sex
		sts graph, by(`rf') adjustfor(c_age c_male) 		
		graph export "output/km_adj_`rf'_`outvar'.eps", replace as(eps)
	}
}

*/

	
****************************************************************
*  KM plots for each factor, stratified by sex and binary age  *
****************************************************************

* TO be added






		
************************************************************************
*  KM plots for each factor, adjusted for sex, age, IMD and ethnicity  *
************************************************************************

* In subsample with ethnicity measured 
* NB: this code assumes missing is a missing value code

*stset stime_died, fail(died) 	///
*		id(patient_id) enter(enter_date) origin(enter_date)

*sts graph, adjustfor(c_age c_male c_imd c_ethnicity) 		




	