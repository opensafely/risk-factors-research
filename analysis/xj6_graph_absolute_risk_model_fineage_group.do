********************************************************************************
*
*	Do-file:		xj4_graph_absolute_risk_model_fineage.do
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



* Open data 
use "output/abs_risks_fineage_group.dta", clear

label define male 0 "Female" 1 "Male" 
label values male male

label define ethnicity  1 "White"	///
						2 "Mixed"	///
						3 "Asian"	///
						4 "Black" 	///
						5 "Other"
label values ethnicity ethnicity


* White
sort age
twoway 	(scatter risk80_cons 						age) ///
		(scatter risk80_comorbid_2			 		age) ///
		(scatter risk80_comorbid_3	 				age) ///
		(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )			///
		(rarea risk80_comorbid_2_lci risk80_comorbid_2_uci age, color(gs14) )	///
		(rarea risk80_comorbid_3_lci risk80_comorbid_3_uci age, color(gs14) )	///
		(line risk_age_65 age, lpattern(dot) lcolor(gs10))				///
		if ethnicity==1						///
		, ylab(0 (0.001) 0.005)  by(male) 	///
		legend(order(1 2 3 7) 				///
		label(1 "No comborbidity")			///
		label(2 "1 comorbidity")			///
		label(3 "2+ comorbidities")			///
		label(4 "Ref (age 65, white)")		///
		) ///
		subtitle("Ethnicity White")
graph export output/abs_risk_comorbid_white.svg, as(svg) replace width(1600)
		

		
* Asian
sort age
twoway 	(scatter risk80_cons 						age) ///
		(scatter risk80_comorbid_2			 		age) ///
		(scatter risk80_comorbid_3	 				age) ///
		(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )			///
		(rarea risk80_comorbid_2_lci risk80_comorbid_2_uci age, color(gs14) )	///
		(rarea risk80_comorbid_3_lci risk80_comorbid_3_uci age, color(gs14) )	///
		(line risk_age_65 age, lpattern(dot) lcolor(gs10))				///
		if ethnicity==3						///
		, ylab(0 (0.001) 0.005)  by(male) 	///
		legend(order(1 2 3 7) 				///
		label(1 "No comborbidity")			///
		label(2 "1 comorbidity")			///
		label(3 "2+ comorbidities")			///
		label(4 "Ref (age 65, white)")		///
		) ///
		subtitle("Ethnicity Asian")
graph export output/abs_risk_comorbid_asian.svg, as(svg) replace width(1600)
		
	
* Black
sort age
twoway 	(scatter risk80_cons 						age) ///
		(scatter risk80_comorbid_2			 		age) ///
		(scatter risk80_comorbid_3	 				age) ///
		(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )			///
		(rarea risk80_comorbid_2_lci risk80_comorbid_2_uci age, color(gs14) )	///
		(rarea risk80_comorbid_3_lci risk80_comorbid_3_uci age, color(gs14) )	///
		(line risk_age_65 age, lpattern(dot) lcolor(gs10))				///
		if ethnicity==4						///
		, ylab(0 (0.001) 0.005)  by(male) 	///
		legend(order(1 2 3 7) 				///
		label(1 "No comborbidity")			///
		label(2 "1 comorbidity")			///
		label(3 "2+ comorbidities")			///
		label(4 "Ref (age 65, white)")		///
		) ///
		subtitle("Ethnicity Black")
graph export output/abs_risk_comorbid_black.svg, as(svg) replace width(1600)
		

* Mixed
sort age
twoway 	(scatter risk80_cons 						age) ///
		(scatter risk80_comorbid_2			 		age) ///
		(scatter risk80_comorbid_3	 				age) ///
		(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )			///
		(rarea risk80_comorbid_2_lci risk80_comorbid_2_uci age, color(gs14) )	///
		(rarea risk80_comorbid_3_lci risk80_comorbid_3_uci age, color(gs14) )	///
		(line risk_age_65 age, lpattern(dot) lcolor(gs10))				///
		if ethnicity==2					///
		, ylab(0 (0.001) 0.005)  by(male) 	///
		legend(order(1 2 3 7) 				///
		label(1 "No comborbidity")			///
		label(2 "1 comorbidity")			///
		label(3 "2+ comorbidities")			///
		label(4 "Ref (age 65, white)")		///
		) ///
		subtitle("Ethnicity Mixed")
graph export output/abs_risk_comorbid_mixed.svg, as(svg) replace width(1600)
		
* Other
sort age
twoway 	(scatter risk80_cons 						age) ///
		(scatter risk80_comorbid_2			 		age) ///
		(scatter risk80_comorbid_3	 				age) ///
		(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )			///
		(rarea risk80_comorbid_2_lci risk80_comorbid_2_uci age, color(gs14) )	///
		(rarea risk80_comorbid_3_lci risk80_comorbid_3_uci age, color(gs14) )	///
		(line risk_age_65 age, lpattern(dot) lcolor(gs10))				///
		if ethnicity==5								///
		, ylab(0 (0.001) 0.005)  by(male) 	///
		legend(order(1 2 3 7) 				///
		label(1 "No comborbidity")			///
		label(2 "1 comorbidity")			///
		label(3 "2+ comorbidities")			///
		label(4 "Ref (age 65, white)")		///
		)		///
		subtitle("Ethnicity Other")
graph export output/abs_risk_comorbid_other.svg, as(svg) replace width(1600)
		