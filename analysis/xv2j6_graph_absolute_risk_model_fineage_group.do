********************************************************************************
*
*	Do-file:		xv2j6_graph_absolute_risk_model_fineage_group.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		output/abs_risks_fineage_`ethnicity'.dta for ethnicity=1,2,...,5
*
*	Data created:	
*
*	Other output:	Graphs: output/abs_risk_`i', for i=1,2,...,8
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


local outcome `1'
noi di "`outcome'"


* Open data 
use "output/abs_risks_fineage_group_`outcome'.dta", clear
drop if age>80

label define male 0 "Female" 1 "Male" 
label values male male

label define ethnicity  1 "White"	///
						2 "Mixed"	///
						3 "Asian"	///
						4 "Black" 	///
						5 "Other"
label values ethnicity ethnicity

capture drop risk_age_65
qui summ risk80_cons if age==65 & male==0 & ethnicity==1
gen risk_age_65 = r(mean) if male==0
qui summ risk80_cons if age==65 & male==1 & ethnicity==1
replace risk_age_65 = r(mean) if male==1



* White
sort age
twoway 	(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )			///
		(rarea risk80_comorbid_2_lci risk80_comorbid_2_uci age, color(gs14) )	///
		(rarea risk80_comorbid_3_lci risk80_comorbid_3_uci age, color(gs14) )	///
		(line risk_age_65 age, lpattern(dot) lcolor(gs10))				///
		(line risk80_comorbid_2			 		age, lcolor(green)) ///
		(line risk80_comorbid_3	 				age, lcolor(orange)) ///
		(line risk80_cons 						age, lcolor(navy)) ///
		if ethnicity==1						///
	, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80)  ///
		by(male, note("") subtitle("Ethnicity White")) 				///
		legend(order(5 6 7 4) 				///
		label(5 "1 comorbidity")			///
		label(6 "2+ comorbidities")			///
		label(7 "No comborbidity")			///
		label(4 "Ref (Age 65, White)")		///
		colfirst) 
graph export output/abs_risk_comorbid_white_`outcome'.svg, as(svg) replace width(1600)
		

		
* Asian
sort age
twoway 	(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )			///
		(rarea risk80_comorbid_2_lci risk80_comorbid_2_uci age, color(gs14) )	///
		(rarea risk80_comorbid_3_lci risk80_comorbid_3_uci age, color(gs14) )	///
		(line risk_age_65 age, lpattern(dot) lcolor(gs10))				///
		(line risk80_comorbid_2			 		age, lcolor(green)) ///
		(line risk80_comorbid_3	 				age, lcolor(orange)) ///
		(line risk80_cons 						age, lcolor(navy)) ///
		if ethnicity==3						///
	, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) ///
		by(male, note("") subtitle("Ethnicity Asian")) 				///
		legend(order(5 6 7 4) 				///
		label(5 "1 comorbidity")			///
		label(6 "2+ comorbidities")			///
		label(7 "No comborbidity")			///
		label(4 "Ref (Age 65, White)")		///
		colfirst) 
graph export output/abs_risk_comorbid_asian_`outcome'.svg, as(svg) replace width(1600)
		
	
* Black
sort age
twoway 	(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )			///
		(rarea risk80_comorbid_2_lci risk80_comorbid_2_uci age, color(gs14) )	///
		(rarea risk80_comorbid_3_lci risk80_comorbid_3_uci age, color(gs14) )	///
		(line risk_age_65 age, lpattern(dot) lcolor(gs10))				///
		(line risk80_comorbid_2			 		age, lcolor(green)) ///
		(line risk80_comorbid_3	 				age, lcolor(orange)) ///
		(line risk80_cons 						age, lcolor(navy)) ///
		if ethnicity==4						///
	, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) ///
		by(male, note("") subtitle("Ethnicity Black")) 				///
		legend(order(5 6 7 4) 				///
		label(5 "1 comorbidity")			///
		label(6 "2+ comorbidities")			///
		label(7 "No comborbidity")			///
		label(4 "Ref (Age 65, White)")		///
		colfirst) 
graph export output/abs_risk_comorbid_black_`outcome'.svg, as(svg) replace width(1600)
		

* Mixed
sort age
twoway 	(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )			///
		(rarea risk80_comorbid_2_lci risk80_comorbid_2_uci age, color(gs14) )	///
		(rarea risk80_comorbid_3_lci risk80_comorbid_3_uci age, color(gs14) )	///
		(line risk_age_65 age, lpattern(dot) lcolor(gs10))				///
		(line risk80_comorbid_2			 		age, lcolor(green)) ///
		(line risk80_comorbid_3	 				age, lcolor(orange)) ///
		(line risk80_cons 						age, lcolor(navy)) ///
		if ethnicity==2						///
	, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) ///
		by(male, note("") subtitle("Ethnicity Mixed")) 				///
		legend(order(5 6 7 4) 				///
		label(5 "1 comorbidity")			///
		label(6 "2+ comorbidities")			///
		label(7 "No comborbidity")			///
		label(4 "Ref (Age 65, White)")		///
		colfirst) 
graph export output/abs_risk_comorbid_mixed_`outcome'.svg, as(svg) replace width(1600)
		
* Other
sort age
twoway 	(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )			///
		(rarea risk80_comorbid_2_lci risk80_comorbid_2_uci age, color(gs14) )	///
		(rarea risk80_comorbid_3_lci risk80_comorbid_3_uci age, color(gs14) )	///
		(line risk_age_65 age, lpattern(dot) lcolor(gs10))				///
		(line risk80_comorbid_2			 		age, lcolor(green)) ///
		(line risk80_comorbid_3	 				age, lcolor(orange)) ///
		(line risk80_cons 						age, lcolor(navy)) ///
		if ethnicity==5						///
	, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) ///
		by(male, note("") subtitle("Ethnicity Other")) 				///
		legend(order(5 6 7 4) 				///
		label(5 "1 comorbidity")			///
		label(6 "2+ comorbidities")			///
		label(7 "No comborbidity")			///
		label(4 "Ref (Age 65, White)")		///
 		colfirst)

graph export output/abs_risk_comorbid_other_`outcome'.svg, as(svg) replace width(1600)
		
		
		
* All
sort age
twoway  (line risk_age_65 age, lpattern(dot) lcolor(gs10))		///
		(line risk80_cons age if ethnicity==1, lcolor(navy)) 	///
		(line risk80_cons age if ethnicity==3, lcolor(gold)) 	///
		(line risk80_cons age if ethnicity==4, lcolor(green)) 	///
		(line risk80_cons age if ethnicity==2, lcolor(red)) 	///
		(line risk80_cons age if ethnicity==5, lcolor(orange)) 	///
	, ylab(0 (0.0005) 0.002, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) ///
	by(male, note("") subtitle("No comorbidities")) 				///
		legend(order(2 3 4 5 6 1) 				///
		label(2 "White")			///
		label(3 "Asian")			///
		label(4 "Black")			///
		label(5 "Mixed")			///
		label(6 "Other")			///
		label(1 "Ref (Age 65, White)")		///
		colfirst) 
		
graph export output/abs_risk_comorbid_all_eth_`outcome'.svg, as(svg) replace width(1600)

		