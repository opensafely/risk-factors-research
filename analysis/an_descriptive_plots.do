********************************************************************************
*
*	Do-file:		an_descriptive_plots.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		cr_create_analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Kaplan-Meier plots (intended for publication)
*							output/km_age_sex_cpnsdeath.svg 	
*							
*					To be added later: 
*							output/km_age_sex_onscoviddeath.svg 
*							output/km_age_sex_ituadmission.svg	 
*					Line plots of cumulative deaths
*							output/events_onscoviddeath.svg
*							output/events_cpnsdeath.svg
*							output/events_ituadmission.svg
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



use "cr_create_analysis_dataset_STSET_cpnsdeath.dta", clear


****************************
*  KM plot by age and sex  *
****************************

*** Intended for publication


* KM plot for females by age		
sts graph if male==0, title("Female") 				///
	failure by(agegroup) 							///
	xtitle("Days since 1 Feb 2020")					///
	yscale(range(0, 0.012)) 						///
	ylabel(0 (0.0025) 0.01, angle(0) format(%5.4f))	///
	xscale(range(30, 84)) 							///
	xlabel(30 (10) 80)								///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	plot1opts(lcolor(red)) 							///
	plot2opts(lcolor(blue)) 						///
	plot3opts(lcolor(orange) lpattern(dash)) 		///
	plot4opts(lcolor(green)  lpattern(dash)) 		///
	plot5opts(lcolor(pink)   lpattern(dash_dot)) 	///
	plot6opts(lcolor(sienna) lpattern(dash_dot))  	///
	saving(female, replace)
* KM plot for males by age		
sts graph if male==1, title("Male") 				///
failure by(agegroup) 								///
	xtitle("Days since 1 Feb 2020")					///
	yscale(range(0, 0.012)) 						///
	ylabel(0 (0.0025) 0.01, angle(0) format(%5.4f))	///
	xscale(range(30, 84)) 							///
	xlabel(30 (10) 80)								///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	plot1opts(lcolor(red)) 							///
	plot2opts(lcolor(blue)) 						///
	plot3opts(lcolor(orange) lpattern(dash)) 		///
	plot4opts(lcolor(green)  lpattern(dash)) 		///
	plot5opts(lcolor(pink)   lpattern(dash_dot)) 	///
	plot6opts(lcolor(sienna) lpattern(dash_dot))  	///
	saving(male, replace)	
* KM plot for males and females 
grc1leg female.gph male.gph, 						///
	t1(" ") l1title("Cumulative probability" "hospital COVID-19 death", size(medsmall))
graph export "output/km_age_sex_cpnsdeath.svg", as(svg) replace

* Delete unneeded graphs
erase female.gph
erase male.gph

	










****************************
*  KM plot by age and sex  *
****************************

/*
*** Intended for publication

* Set max/gap for ylabels 
foreach outvar of varlist onscoviddeath cpnsdeath ituadmission {
	qui summ `outvar'
	local max_`outvar' = r(mean) + 0.05
}



* Titles for graphs
local t_onscoviddeath = "ONS Covid-19 death"
local t_cpnsdeath     = "CPNS Covid-19 death"
local t_ituadmission  = "ITU admission"

foreach outvar of varlist onscoviddeath cpnsdeath ituadmission {

	* Declare survival outcome
	stset stime_`outvar', fail(`outvar') 			///
		id(patient_id) enter(enter_date) origin(enter_date)

	* KM plot for females by age		
	sts graph if male==0, title("Female") 			///
		failure by(agegroup) 						///
		xtitle("Days since 1 Feb 2020")				///
		yscale(range(0, `max_outvar')) 				///
		ylabel(#4, angle(0))						///
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
		xtitle("Days since 1 Feb 2020")				///
		yscale(range(0, `max_outvar')) 				///
		ylabel(#4, angle(0))						///
		legend(order(1 2 3 4 5 6)					///
		subtitle("Age group", size(small)) 			///
		label(1 "18-<40") label(2 "40-<50") 		///
		label(3 "50-<60") label(4 "60-<70")			///
        label(5 "70-<80") label(6 "80+") 			///
		col(2) size(small))							///
		saving(male, replace)
	* KM plot for males and females 
	grc1leg female.gph male.gph, 					///
		t1(`"`t_`outvar''"'') 	
	graph export "output/km_age_sex_`outvar'.svg", as(svg) replace

	* Delete unneeded graphs
	erase female.gph
	erase male.gph
	
	

	* Line graph of events 
	sort _t
	gen cum_`outvar' = sum(_d)
	line cum_`outvar' _t if 	///
		!(_t==_t[_n-1] & cum_`outvar'==cum_`outvar'[_n-1]), sort(_t) 
	graph export "output/events_`outvar'.svg", replace as(svg)
	
}

*/



****************************
*  KM plot by age and sex  *
****************************
/*
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




	