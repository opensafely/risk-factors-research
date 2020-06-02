********************************************************************************
*
*	Do-file:		an_descriptive_plots_cr.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		cr_create_analysis_dataset_STSET_`outcome'.dta
*
*	Data created:	None
*
*	Other output:	Kaplan-Meier plots (intended for publication)
*							output/km_age_sex_`outcome'_cr.svg 	
*							
*
********************************************************************************
*
*	Purpose:		This do-file creates Kaplan-Meier plots by age and sex, 
*					treating death by other causes as a competing risk. 
*  
********************************************************************************
*	
*	Stata routines needed:	grc1leg	
*
********************************************************************************

local outcome `1'


use "cr_create_analysis_dataset_STSET_`outcome'.dta", clear

* Generate failure variable with 1 indicating the outcome and 2 death due 
* to other causes (the competing risk)
gen fail = `outcome'
replace fail = 2 if fail==0 & stime_`outcome'<td($`outcome'censor)

* Set as competing risk data
stset stime_`outcome', fail(fail=1) 				///
	id(patient_id) enter(enter_date) origin(enter_date)

* Fit a competing risks model adjusting only for age and sex
stcrreg i.agegroup#i.male, compete(fail==2)


* KM plot for females 
* by age, treating death from other causes as a competing risk	
stcurve, cif outfile(output/cif_1, replace)	nodraw			///
	at1(male=0 agegroup=1) 	///
	at2(male=0 agegroup=2) 	///
	at3(male=0 agegroup=3) 	///
	at4(male=0 agegroup=4) 	///
	at5(male=0 agegroup=5) 	///
	at6(male=0 agegroup=6)	///
	lcolor(red blue orange green pink sienna)				///
	lpattern(solid solid dash dash dash_dot dash_dot) 		///
	xtitle(" ")												///
	yscale(range(0, 0.005)) 								///
	ylabel(0 (0.001) 0.005, angle(0) format(%4.3f))			///
	ytitle("")												///
	xscale(range(30, 84)) 									///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 						///
	60 "1 Apr 20" 84 "25 Apr 20")	 						///
	graphregion(margin(r+10))								///
	legend(order(1 2 3 4 5 6)								///
	subtitle("Age group", size(small)) 						///
	label(1 "18-<40") label(2 "40-<50") 					///
	label(3 "50-<60") label(4 "60-<70")						///
	label(5 "70-<80") label(6 "80+"))						///
	title("Female")											///
	saving(female, replace)	

* KM plot for males 
* by age, treating death from other causes as a competing risk	
stcurve,  cif outfile(output/cif_2, replace)	nodraw	 	///
	at1(male=1 agegroup=1) 	///
	at2(male=1 agegroup=2) 	///
	at3(male=1 agegroup=3) 	///
	at4(male=1 agegroup=4) 	///
	at5(male=1 agegroup=5) 	///
	at6(male=1 agegroup=6)	///
	lcolor(red blue orange green pink)						///
	lpattern(solid solid dash dash dash_dot dash_dot) 		///
	xtitle(" ")												///
	yscale(range(0, 0.005)) 								///
	ylabel(0 (0.001) 0.005, angle(0) format(%4.3f))			///
	ytitle("")												///
	xscale(range(30, 84)) 									///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 						///
	60 "1 Apr 20" 84 "25 Apr 20")	 						///
	graphregion(margin(r+10))								///
	legend(order(1 2 3 4 5 6)								///
	subtitle("Age group", size(small)) 						///
	label(1 "18-<40") label(2 "40-<50") 					///
	label(3 "50-<60") label(4 "60-<70")						///
	label(5 "70-<80") label(6 "80+"))						///
	title("Male")											///
	saving(male, replace)	
	
	
use output/cif_1,clear
duplicates drop
twoway 	(line ci2 _t, lcolor(red) 	 lpattern(solid)) 		///
		(line ci3 _t, lcolor(blue) 	 lpattern(solid)) 		///
		(line ci4 _t, lcolor(orange) lpattern(dash)) 		///
		(line ci5 _t, lcolor(green)  lpattern(dash)) 		///
		(line ci6 _t, lcolor(pink)   lpattern(dash_dot)) 	///
		(line ci7 _t, lcolor(sienna) lpattern(dash_dot)) 	///
		, xtitle(" ")										///
		yscale(range(0, 0.005)) 							///
		ylabel(0 (0.001) 0.005, angle(0) format(%4.3f))		///
		ytitle("")											///
		xscale(range(30, 84)) 								///
		xlabel(0 "1 Feb 20" 29 "1 Mar 20" 					///
		60 "1 Apr 20" 84 "25 Apr 20")	 					///
		graphregion(margin(r+10))							///
		legend(order(1 2 3 4 5 6)								///
		subtitle("Age group", size(small)) 						///
		label(1 "18-<40") label(2 "40-<50") 					///
		label(3 "50-<60") label(4 "60-<70")						///
		label(5 "70-<80") label(6 "80+"))						///
		title("Female")											///
		saving(female, replace)	

use output/cif_2,clear
duplicates drop
twoway 	(line ci2 _t, lcolor(red) 	 lpattern(solid)) 		///
		(line ci3 _t, lcolor(blue) 	 lpattern(solid)) 		///
		(line ci4 _t, lcolor(orange) lpattern(dash)) 		///
		(line ci5 _t, lcolor(green)  lpattern(dash)) 		///
		(line ci6 _t, lcolor(pink)   lpattern(dash_dot)) 	///
		(line ci7 _t, lcolor(sienna) lpattern(dash_dot)) 	///
		, xtitle(" ")										///
		yscale(range(0, 0.005)) 							///
		ylabel(0 (0.001) 0.005, angle(0) format(%4.3f))		///
		ytitle("")											///
		xscale(range(30, 84)) 								///
		xlabel(0 "1 Feb 20" 29 "1 Mar 20" 					///
		60 "1 Apr 20" 84 "25 Apr 20")	 					///
		graphregion(margin(r+10))							///
		legend(order(1 2 3 4 5 6)								///
		subtitle("Age group", size(small)) 						///
		label(1 "18-<40") label(2 "40-<50") 					///
		label(3 "50-<60") label(4 "60-<70")						///
		label(5 "70-<80") label(6 "80+"))						///
		title("Male")											///
		saving(male, replace)	

if "`outcome'"=="cpnsdeath" local hospital "hospital "
		
* Combine plots for males and females 
grc1leg female.gph male.gph, 											///
	t1(" ") l1title("Cumulative incidence of" "`hospital'COVID-19 death", ///
	size(medsmall)) col(3)
graph export "output/an_descriptive_plots_cr_thinned_`outcome'.svg", as(svg) replace

* Delete unneeded graphs
erase female.gph
erase male.gph

* Delete unneeded datasets
erase output/cif_2.dta
erase output/cif_1.dta


