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




use "cr_create_analysis_dataset_STSET_onscoviddeath.dta", clear


****************************
*  KM plot by age and sex  *
****************************

*** Intended for publication


* KM plot for females by age		
sts graph if male==0, title("Female") 				///
	failure by(agegroup) 							///
	xtitle(" ")					///
	yscale(range(0, 0.008)) 						///
	ylabel(0 (0.002) 0.008, angle(0) format(%4.3f))	///
	xscale(range(30, 100)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 91 "1 May 20")	 			///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	plot1opts(lcolor(gs11) lpattern(dot))			///
	plot2opts(lcolor(gs11) 	lpattern(shortdash))	///
	plot3opts(lcolor(gs9) lpattern(shortdash_dot)) 	///
	plot4opts(lcolor(gs6)  lpattern(longdash)) 		///
	plot5opts(lcolor(gs3)   lpattern(longdash_dot)) ///
	plot6opts(lcolor(gs0) lpattern(solid))  		///
	saving(female, replace)
* KM plot for males by age		
sts graph if male==1, title("Male") 				///
failure by(agegroup) 								///
	xtitle(" ")										///
	yscale(range(0, 0.008)) 						///
	ylabel(0 (0.002) 0.008, angle(0) format(%4.3f))	///
	xscale(range(30, 100)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 91 "1 May 20")	 			///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	plot1opts(lcolor(gs11) lpattern(dot))			///
	plot2opts(lcolor(gs11) 	lpattern(shortdash))	///
	plot3opts(lcolor(gs9) lpattern(shortdash_dot)) 	///
	plot4opts(lcolor(gs6)  lpattern(longdash)) 		///
	plot5opts(lcolor(gs3)   lpattern(longdash_dot)) ///
	plot6opts(lcolor(gs0) lpattern(solid))  		///
	saving(male, replace)	
* KM plot for males and females 
grc1leg female.gph male.gph, 						///
	t1(" ") l1title("Cumulative probability" "of COVID-19 death", size(medsmall))
graph export "output/km_age_sex_onscoviddeath.svg", as(svg) replace

* Delete unneeded graphs
erase female.gph
erase male.gph


*********************


use "cr_create_analysis_dataset_STSET_cpnsdeath.dta", clear


****************************
*  KM plot by age and sex  *
****************************

*** Intended for publication


* KM plot for females by age		
sts graph if male==0, title("Female") 				///
	failure by(agegroup) 							///
	xtitle(" ")										///
	yscale(range(0, 0.005)) 						///
	ylabel(0 (0.001) 0.005, angle(0) format(%4.3f))	///
	xscale(range(30, 84)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 84 "25 Apr 20")	 			///
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
	yscale(range(0, 0.005)) 						///
	ylabel(0 (0.001) 0.005, angle(0) format(%4.3f))	///
	xscale(range(30, 84)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 84 "25 Apr 20")	 			///
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

	




	