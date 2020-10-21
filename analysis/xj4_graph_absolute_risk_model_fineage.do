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

label define male 0 "Female" 1 "Male" 
label values male male


* Respiratory and asthma
twoway 	(scatter risk80_cons 						age) ///
		(scatter risk80_respiratory_disease 		age) ///
		(scatter risk80_asthmacat_2 				age) ///
		(scatter risk80_asthmacat_3			 		age) ///
		(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )							///
		(rarea risk80_respiratory_disease_lci risk80_respiratory_disease_uci age, color(gs14) )	///
		(rarea risk80_asthmacat_2_lci risk80_asthmacat_2_uci 		age, color(gs14) )			///
		(rarea risk80_asthmacat_3_lci risk80_asthmacat_3_uci 		age, color(gs14) )			///
		, ylab(0 (0.001) 0.005)  by(male) 	///
		legend(order(1 2 3 4) 				///
		label(1 "No comborbidity")			///
		label(2 "Respiratory disease")		///
		label(3 "Asthma, mild")				///
		label(4 "Asthma, severe")			///
		)
graph export output/abs_risk_resp_eth`ethnicity'.svg, as(svg) replace width(1600)
		

* Hypertension, cardiac disease and diabetes
twoway 	(scatter risk80_cons 						age) ///
		(scatter risk80_htdiag_or_highbp 			age) ///
		(scatter risk80_cardiac_disease 			age) ///
		(scatter risk80_diabcat_2			 		age) ///
		(scatter risk80_diabcat_3			 		age) ///
		(scatter risk80_diabcat_4			 		age) ///
		(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )						///
		(rarea risk80_htdiag_or_highbp_lci risk80_htdiag_or_highbp_uci age, color(gs14) )	///
		(rarea risk80_cardiac_disease_lci risk80_cardiac_disease_uci 		age, color(gs14) )	///
		(rarea risk80_diabcat_2_lci risk80_diabcat_2_uci 		age, color(gs14) )			///
		(rarea risk80_diabcat_3_lci risk80_diabcat_3_uci 		age, color(gs14) )			///
		(rarea risk80_diabcat_4_lci risk80_diabcat_4_uci 		age, color(gs14) )			///
		, ylab(0 (0.001) 0.005)  by(male)	///
		legend(order(1 2 3 4 5 6) 			///
		label(1 "No comborbidity")			///
		label(2 "High BP/hypertension")		///
		label(3 "Cardiac disease")			///
		label(4 "Diabetes, controlled")		///
		label(5 "Diabetes, uncontrolled")	///
		label(6 "Diabetes, unknown")		///
		)
graph export output/abs_risk_cardiac_eth`ethnicity'.svg, as(svg) replace width(1600)
		
			
	
* Liver, kidney and organ transplant	
	twoway 	(scatter risk80_cons 					age) ///
		(scatter risk80_chronic_liver_disease 		age) ///
		(scatter risk80_red_kidney_cat_2 			age) ///
		(scatter risk80_red_kidney_cat_3 			age) ///
		(scatter risk80_organ_transplant			age) ///
		(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )							///
		(rarea risk80_chronic_liver_disease_lci risk80_chronic_liver_disease_uci age, color(gs14) )		///
		(rarea risk80_red_kidney_cat_2_lci risk80_red_kidney_cat_2_uci 		age, color(gs14) )			///
		(rarea risk80_red_kidney_cat_3_lci risk80_red_kidney_cat_3_uci 		age, color(gs14) )			///
		(rarea risk80_organ_transplant_lci risk80_organ_transplant_uci 		age, color(gs14) )			///
		, ylab(0 (0.001) 0.005)  by(male)	///
		legend(order(1 2 3 4 5) 			///
		label(1 "No comborbidity")			///
		label(2 "Liver disease")			///
		label(3 "Reduced kidney function")	///
		label(4 "Poor kidney function")		///
		label(5 "Organ transplant")			///
		)
					
		
		
* Stroke/dementia or neurological	
twoway 	(scatter risk80_cons 						age) ///
		(scatter risk80_stroke_dementia 			age) ///
		(scatter risk80_other_neuro 				age) ///
		(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )						///
		(rarea risk80_stroke_dementia_lci risk80_stroke_dementia_uci age, color(gs14) )		///
		(rarea risk80_other_neuro_lci risk80_other_neuro_uci 		age, color(gs14) )		///
		, ylab(0 (0.001) 0.005)  by(male)	///
		legend(order(1 2 3) 				///
		label(1 "No comborbidity")			///
		label(2 "Stroke/dementia")			///
		label(3 "Other neurological")		///
		)
graph export output/abs_risk_stroke_eth`ethnicity'.svg, as(svg) replace width(1600)
		
		
		
* Cancer 	
twoway 	(scatter risk80_cons 					age) ///
		(scatter risk80_cancer_exhaem_cat_2 	age) ///
		(scatter risk80_cancer_exhaem_cat_3 	age) ///
		(scatter risk80_cancer_exhaem_cat_4		age) ///
		(scatter risk80_cancer_haem_cat_2 		age) ///
		(scatter risk80_cancer_haem_cat_3 		age) ///
		(scatter risk80_cancer_haem_cat_4		age) ///
		(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )								///
		(rarea risk80_cancer_exhaem_cat_2_lci risk80_cancer_exhaem_cat_2_uci age, color(gs14) )		///
		(rarea risk80_cancer_exhaem_cat_3_lci risk80_cancer_exhaem_cat_3_uci age, color(gs14) )		///
		(rarea risk80_cancer_exhaem_cat_4_lci risk80_cancer_exhaem_cat_4_uci age, color(gs14) )		///
		(rarea risk80_cancer_haem_cat_2_lci risk80_cancer_haem_cat_2_uci age, color(gs14) )	///
		(rarea risk80_cancer_haem_cat_3_lci risk80_cancer_haem_cat_3_uci age, color(gs14) )	///
		(rarea risk80_cancer_haem_cat_4_lci risk80_cancer_haem_cat_4_uci age, color(gs14) )	///
		, ylab(0 (0.001) 0.005)  by(male)	///
		legend(order(1 2 3 4 5 6 7) 		///
		label(1 "No comborbidity")			///
		label(2 "Haem. cancer (<1yr)")		///
		label(3 "Haem. cancer (2-5yr)")		///
		label(4 "Haem. cancer (>5yr)")		///
		label(5 "Other cancer (<1yr)")		///
		label(6 "Other cancer (2-5yr)")		///
		label(7 "Other cancer (>5yr)")		///
		)		
graph export output/abs_risk_cancer_eth`ethnicity'.svg, as(svg) replace width(1600)
	
		
* Spleen, RA, immuno
twoway 	(scatter risk80_cons 						age) ///
		(scatter risk80_spleen 						age) ///
		(scatter risk80_ra_sle_psoriasis 			age) ///
		(scatter risk80_immunosuppression			age) ///
		(rarea risk80_cons_lci risk80_cons_uci 		age, color(gs14) )								///
		(rarea risk80_spleen_lci risk80_spleen_uci age, color(gs14) )								///
		(rarea risk80_ra_sle_psoriasis_lci risk80_ra_sle_psoriasis_uci 		age, color(gs14) )		///
		(rarea risk80_immunosuppression_lci risk80_immunosuppression_uci 		age, color(gs14) )	///
		, ylab(0 (0.001) 0.005)  by(male)	///
			legend(order(1 2 3) 			///
		label(1 "No comborbidity")			///
		label(2 "Spleen")					///
		label(3 "RA/SLE/Psoriasis")			///
		)
graph export output/abs_risk_immuno_eth`ethnicity'.svg, as(svg) replace width(1600)
			
			