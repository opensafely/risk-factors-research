*KB 2/6/2020

local outcome `1'

use "cr_create_analysis_dataset_STSET_`outcome'.dta", clear

* Generate failure variable with 1 indicating the outcome and 2 death due 
* to other causes (the competing risk)

*Leave those with competing deaths in the risk set to admin censoring date
replace stime_`outcome' = td($`outcome'censor) if `outcome'==0 & stime_`outcome'<td($`outcome'censor)

*Re-stset
stset stime_`outcome', fail(`outcome') 				///
	id(patient_id) enter(enter_date) origin(enter_date)

*Get data for plot
sts gen surv = s, by(agegroup male)
gen ci = 1-surv

*Thin
bysort agegroup male _t: keep if _n==1

*Plot
*Women
graph twoway line ci _t if male==0 & agegroup==1, sort c(stair) lc(red) ///
	|| line ci _t if male==0 & agegroup==2, sort c(stair) lc(blue) ///
	|| line ci _t if male==0 & agegroup==3, sort c(stair) lc(orange) lp(dash) ///
	|| line ci _t if male==0 & agegroup==4, sort c(stair) lc(green) lp(dash) ///
	|| line ci _t if male==0 & agegroup==5, sort c(stair) lc(pink) lp(dash_dot) ///
	|| line ci _t if male==0 & agegroup==6, sort c(stair) lc(sienna) lp(dash_dot) ///
	|| , title("Female") 							///
	xtitle(" ")					///
	ytitle("")										///
	yscale(range(0, 0.008)) 						///
	ylabel(0 (0.002) 0.008, angle(0) format(%4.3f))	///
	xscale(range(30, 100)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
	60 "1 Apr 20" 91 "1 May 20")	 				///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))					///
	saving(female, replace)

*Men
graph twoway line ci _t if male==1 & agegroup==1, sort c(stair) lc(red) ///
	|| line ci _t if male==1 & agegroup==2, sort c(stair) lc(blue) ///
	|| line ci _t if male==1 & agegroup==3, sort c(stair) lc(orange) lp(dash) ///
	|| line ci _t if male==1 & agegroup==4, sort c(stair) lc(green) lp(dash) ///
	|| line ci _t if male==1 & agegroup==5, sort c(stair) lc(pink) lp(dash_dot) ///
	|| line ci _t if male==1 & agegroup==6, sort c(stair) lc(sienna) lp(dash_dot) ///
	|| , title("Male") 								///
	xtitle(" ")					///
	ytitle("")										///
	yscale(range(0, 0.008)) 						///
	ylabel(0 (0.002) 0.008, angle(0) format(%4.3f))	///
	xscale(range(30, 100)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
	60 "1 Apr 20" 91 "1 May 20")	 				///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))					///
	saving(male, replace)	

if "`outcome'"=="cpnsdeath" local hospital "hospital "
* KM plot for males and females 
grc1leg female.gph male.gph, 						///
	t1(" ") l1title("Cumulative probability" "of `hospital'COVID-19 death", size(medsmall))
graph export "output/an_descriptiveplots_cr_manualmethod_`outcome'.svg", as(svg) replace

* Delete unneeded graphs
erase female.gph
erase male.gph

