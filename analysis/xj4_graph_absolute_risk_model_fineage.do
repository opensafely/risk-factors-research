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



local ethnicity `1' 
noi di "`ethnicity'"


* Open data 
use "output/abs_risks_fineage_`ethnicity'.dta", clear
drop if age>80


label define male 0 "Female" 1 "Male" 
label values male male

qui summ risk80_cons if age==65 & male==0
gen risk_age_65 = r(mean) if male==0
qui summ risk80_cons if age==65 & male==1
replace risk_age_65 = r(mean) if male==1

* Respiratory and asthma
sort age
twoway 	(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )							///
		(rarea risk80_respiratory_disease_lci risk80_respiratory_disease_uci age, color(gs14) )	///
		(rarea risk80_asthmacat_2_lci risk80_asthmacat_2_uci 		age, color(gs14) )			///
		(rarea risk80_asthmacat_3_lci risk80_asthmacat_3_uci 		age, color(gs14) )			///
		(line risk80_respiratory_disease 		age, lcolor(red)) 								///
		(line risk80_asthmacat_2 				age, lcolor(green)) 							///
		(line risk80_asthmacat_3			 	age, lcolor(gold)) 								///
		(line risk80_cons 						age, lcolor(navy)) 								///
		(line risk_age_65 						age, lpattern(dot) lcolor(black))				///
	, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) by(male, note("")) 				///
		legend(order(5 6 7 8) 				///
		label(5 "Respiratory disease")		///
		label(6 "Asthma, mild")				///
		label(7 "Asthma, severe")			///
		label(8 "No comborbidity")			///
		)
graph export output/abs_risk_resp_eth`ethnicity'.svg, as(svg) replace width(1600)


* Hypertension, cardiac disease and diabetes
sort age
twoway 	(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )						///
  		(rarea risk80_htdiag_or_highbp_lci risk80_htdiag_or_highbp_uci age, color(gs14) )	///
		(rarea risk80_cardiac_disease_lci risk80_cardiac_disease_uci 		age, color(gs14) )	///
		(rarea risk80_diabcat_2_lci risk80_diabcat_2_uci 		age, color(gs14) )			///
		(rarea risk80_diabcat_3_lci risk80_diabcat_3_uci 		age, color(gs14) )			///
		(rarea risk80_diabcat_4_lci risk80_diabcat_4_uci 		age, color(gs14) )			///
		(line risk80_htdiag_or_highbp 			age, lcolor(red)) 							///
		(line risk80_cardiac_disease 			age, lcolor(green)) 						///
		(line risk80_diabcat_2			 		age, lcolor(gold)) 							///
		(line risk80_diabcat_3			 		age, lcolor(orange)) 						///
		(line risk80_diabcat_4			 		age, lcolor(brown)) 						///
		(line risk80_cons 						age, lcolor(navy)) 							///
		(line risk_age_65 						age, lpattern(dot) lcolor(black))			///
		, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) by(male, note("")) 		///
		legend(order(7 8 9 10 11 12) 		///
		label(7 "High BP/hypertension")		///
		label(8 "Cardiac disease")			///
		label(9 "Diabetes, controlled")		///
		label(10 "Diabetes, uncontrolled")	///
		label(11 "Diabetes, unknown")		///
		label(12 "No comborbidity")			///
		)
graph export output/abs_risk_cardiac_eth`ethnicity'.svg, as(svg) replace width(1600)
		
			
	
* Liver, kidney and organ transplant	
sort age
twoway 	(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )									///
		(rarea risk80_chronic_liver_disease_lci risk80_chronic_liver_disease_uci age, color(gs14) )		///
		(rarea risk80_red_kidney_cat_2_lci risk80_red_kidney_cat_2_uci 		age, color(gs14) )			///
		(rarea risk80_red_kidney_cat_3_lci risk80_red_kidney_cat_3_uci 		age, color(gs14) )			///
		(rarea risk80_organ_transplant_lci risk80_organ_transplant_uci 		age, color(gs14) )			///
		(line risk80_chronic_liver_disease 		age, lcolor(red))  						///
		(line risk80_red_kidney_cat_2 			age, lcolor(gold))  					///
		(line risk80_red_kidney_cat_3 			age, lcolor(orange))  					///
		(line risk80_organ_transplant			age, lcolor(green))  					///
		(line risk80_cons 						age, lcolor(navy)) 						///
		(line risk_age_65 						age, lpattern(dot) lcolor(black))		///
		, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) by(male, note("")) 	///
		legend(order(6 7 8 9 10) 			///
		label(6 "Liver disease")			///
		label(7 "Reduced kidney function")	///
		label(8 "Poor kidney function")		///
		label(9 "Organ transplant")			///
		label(10 "No comborbidity")			///
		)
graph export output/abs_risk_organ_eth`ethnicity'.svg, as(svg) replace width(1600)
					

		
* Stroke/dementia or neurological	
sort age
twoway 	(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )						///
		(rarea risk80_stroke_dementia_lci risk80_stroke_dementia_uci age, color(gs14) )		///
		(rarea risk80_other_neuro_lci risk80_other_neuro_uci 		age, color(gs14) )		///
		(line risk80_stroke_dementia 			age, lcolor(green)) 						///
		(line risk80_other_neuro 				age, lcolor(orange)) 	 					///
		(line risk80_cons 						age, lcolor(navy)) 	 						///
		(line risk_age_65 						age, lpattern(dot) lcolor(black))			///
		, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) by(male, note("")) 	///
		legend(order(4 5 6) 				///
		label(4 "Stroke/dementia")			///
		label(5 "Other neurological")		///
		label(6 "No comborbidity")			///
		)
graph export output/abs_risk_stroke_eth`ethnicity'.svg, as(svg) replace width(1600)
		
		
		
* Cancer 
sort age	
twoway 	(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )								///
		(rarea risk80_cancer_exhaem_cat_2_lci risk80_cancer_exhaem_cat_2_uci age, color(gs14) )		///
		(rarea risk80_cancer_exhaem_cat_3_lci risk80_cancer_exhaem_cat_3_uci age, color(gs14) )		///
		(rarea risk80_cancer_exhaem_cat_4_lci risk80_cancer_exhaem_cat_4_uci age, color(gs14) )		///
		(rarea risk80_cancer_haem_cat_2_lci risk80_cancer_haem_cat_2_uci age, color(gs14) )			///
		(rarea risk80_cancer_haem_cat_3_lci risk80_cancer_haem_cat_3_uci age, color(gs14) )			///
		(rarea risk80_cancer_haem_cat_4_lci risk80_cancer_haem_cat_4_uci age, color(gs14) )			///
		(line risk80_cancer_exhaem_cat_2 	age, lcolor(green)) 	 		///
		(line risk80_cancer_exhaem_cat_3 	age, lcolor(forest_green)) 	 	///
		(line risk80_cancer_exhaem_cat_4	age, lcolor(lime)) 	 			///
		(line risk80_cancer_haem_cat_2 		age, lcolor(gold)) 				///
		(line risk80_cancer_haem_cat_3 		age, lcolor(orange)) 			///
		(line risk80_cancer_haem_cat_4		age, lcolor(brown)) 			///
		(line risk80_cons 					age, lcolor(navy)) 	 			///
		(line risk_age_65 					age, lpattern(dot) lcolor(black))						///
		, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) by(male, note("")) 	///
		legend(order(8 9 10 11 12 13 14) colfirst	///
		label(8 "Other cancer (<1yr)")		///
		label(9 "Other cancer (2-5yr)")		///
		label(10 "Other cancer (>5yr)")		///
		label(11 "Haem. cancer (<1yr)")		///
		label(12 "Haem. cancer (2-5yr)")	///
		label(13 "Haem. cancer (>5yr)")		///
		label(14 "No comborbidity")			///
		)		
graph export output/abs_risk_cancer_eth`ethnicity'.svg, as(svg) replace width(1600)
	
		
* Spleen, RA, immuno
sort age
twoway 	(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )								///
		(rarea risk80_spleen_lci risk80_spleen_uci age, color(gs14) )								///
		(rarea risk80_ra_sle_psoriasis_lci risk80_ra_sle_psoriasis_uci 		age, color(gs14) )		///
		(rarea risk80_immunosuppression_lci risk80_immunosuppression_uci 	age, color(gs14) )		///
		(line risk80_spleen 					age, lcolor(green)) 								///
		(line risk80_ra_sle_psoriasis 			age, lcolor(red)) 	  								///
		(line risk80_immunosuppression			age, lcolor(gold)) 	  								///
		(line risk80_cons 						age, lcolor(navy)) 	  								///
		(line risk_age_65 					age, lpattern(dot) lcolor(black))						///
		, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) by(male, note("")) 	///
		legend(order(5 6 7 8) 				///
		label(5 "Spleen")					///
		label(6 "RA/SLE/Psoriasis")			///
		label(7 "Immunosuppression")		///
		label(8 "No comborbidity")			///
		)
graph export output/abs_risk_immuno_eth`ethnicity'.svg, as(svg) replace width(1600)
				
			
			
			
			
			
* All comorbidities
sort age
twoway 	(line risk80_respiratory_disease 		age, lwidth(vthin) lcolor(eltblue)) 			///
		(line risk80_asthmacat_2 				age, lwidth(vthin) lcolor(blue)) 				///
		(line risk80_asthmacat_3			 	age, lwidth(vthin) lcolor(midblue)) 			///
		(line risk80_htdiag_or_highbp 			age, lwidth(vthin) lcolor(olive_teal)) 		///
		(line risk80_cardiac_disease 			age, lwidth(vthin) lcolor(mint)) 				///
		(line risk80_diabcat_2			 		age, lwidth(vthin) lcolor(midgreen)) 			///
		(line risk80_diabcat_3			 		age, lwidth(vthin) lcolor(green)) 			///
		(line risk80_diabcat_4			 		age, lwidth(vthin) lcolor(dkgreen)) 			///
		(line risk80_chronic_liver_disease 		age, lwidth(vthin) lcolor(olive))  			///
		(line risk80_red_kidney_cat_2 			age, lwidth(vthin) lcolor(stone))  			///
		(line risk80_red_kidney_cat_3 			age, lwidth(vthin) lcolor(sand))  			///
		(line risk80_organ_transplant			age, lwidth(vthin) lcolor(sienna))  			///
		(line risk80_stroke_dementia 			age, lwidth(vthin) lcolor(red)) 				///
		(line risk80_other_neuro 				age, lwidth(vthin) lcolor(maroon)) 	 			///
		(line risk80_cancer_exhaem_cat_2 		age, lwidth(vthin) lcolor(gs3)) 	 			///
		(line risk80_cancer_exhaem_cat_3 		age, lwidth(vthin) lcolor(gs5)) 	 			///
		(line risk80_cancer_exhaem_cat_4		age, lwidth(vthin) lcolor(gs7)) 	 			///
		(line risk80_cancer_haem_cat_2 			age, lwidth(vthin) lcolor(sandb)) 				///
		(line risk80_cancer_haem_cat_3 			age, lwidth(vthin) lcolor(gold)) 				///
		(line risk80_cancer_haem_cat_4			age, lwidth(vthin) lcolor(yellow)) 				///
		(line risk80_spleen 					age, lwidth(vthin) lcolor(orange_red)) 			///
		(line risk80_ra_sle_psoriasis 			age, lwidth(vthin) lcolor(magenta)) 	  		///
		(line risk80_immunosuppression			age, lwidth(vthin) lcolor(red)) 		///
		(line risk80_cons 						age, lwidth(vthin) lcolor(black)) 	  		///
		(line risk_age_65 					age, lpattern(dot) lcolor(black))	///
		, ylab(0 (0.001) 0.005, angle(0)) xlab(20 (20) 80) xmtick(20 (5) 80) by(male, note("")) ///
		legend(order(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24) ///
		size(tiny) col(4)					///
		label(1 "Respiratory") 				///
		label(2 "Asthma mild") 				///
		label(3 "Asthma sev") 				///
		label(4 "Hypertension") 			///
		label(5 "Cardiac") 					///
		label(6 "Diab, control") 			/// 
		label(7 "Diab, uncontrol")  		///
		label(8 "Diab, unknown")  			///
		label(9 "Liver")  					///
		label(10 "Red kidney")  			///
		label(11 "Poor kidney")  			///
		label(12 "Transplant")  			///
		label(13 "Stroke/dementia") 		///
		label(14 "Neuro") 	 				///
		label(15 "Canc. Oth (<1yr)") 		///
		label(16 "Canc. Oth (2-4yr)") 		///
		label(17 "Canc. Oth (5+yr)") 		///
		label(18 "Canc. Haem (<1yr)") 		///
		label(19 "Canc. Haem (2-4yr)") 		///
		label(20 "Canc. Haem (5+yr)") 		///
		label(21 "Spleen") 					///
		label(22 "RA/SLE/psoriasis") 		///
		label(23 "Immunosuppression") 		///
		label(24 "No comorbidity") 	  		///
		colfirst) 
graph export output/abs_risk_ALL_eth`ethnicity'.svg, as(svg) replace width(1600)
			

			
			