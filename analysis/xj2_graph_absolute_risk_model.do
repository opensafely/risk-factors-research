********************************************************************************
*
*	Do-file:		xj2_graph_absolute_risk_model.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		output/abs_risks_`ethnicity'.dta
*
*	Data created:	
*
*	Other output:	Graphs: output/abs_risk_`i'_eth`j', for i=1,2,...,8, j=1,..5
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
use "output/abs_risks_`ethnicity'.dta", clear


* Create baselines for categorical variables
foreach var in 	asthmacat_1 		///
				diabcat_1 			///
				cancer_exhaem_cat_1 ///
				cancer_haem_cat_1	///
				red_kidney_cat_1	{
	gen risk80_`var'     = .
	gen risk80_`var'_lci = .
	gen risk80_`var'_uci = .
}

* Rename variables to enable reshaping
local i = 1
foreach var in cons 						///
		htdiag_or_highbp 					///
		respiratory_disease 				///
		asthmacat_1  				 		///
		asthmacat_2  				 		///
		asthmacat_3   				 		///	
		cardiac_disease 					///
		diabcat_1 		 					///
		diabcat_2 		 					///
		diabcat_3 		 					///
		diabcat_4 			 				///	
		cancer_exhaem_cat_1  				///
		cancer_exhaem_cat_2  				///
		cancer_exhaem_cat_3  				///
		cancer_exhaem_cat_4  				///
		cancer_haem_cat_1  				 	///
		cancer_haem_cat_2  				 	///
		cancer_haem_cat_3  				 	///
		cancer_haem_cat_4  					///
		chronic_liver_disease 				///
		stroke_dementia 		 			///
		other_neuro							///
		red_kidney_cat_1					///
		red_kidney_cat_2					///
		red_kidney_cat_3  					///
		organ_transplant  					///
		spleen 								///
		ra_sle_psoriasis   					///
		immunosuppression  					///
		 {
		    
	rename risk80_`var'	 		risk80_`i'
	rename risk80_`var'_lci 	risk80_lci_`i'
	rename risk80_`var' 		risk80_uci_`i'

	local name`i' = "`var'"
	local i = `i'+1
}

* Put data in long format
reshape long risk80_ risk80_lci_ risk80_uci_, i(agegroup male) j(comorbidity)
sort comorbidity male age 

rename risk80_ risk80
rename risk80_lci_ risk80_cl
rename risk80_uci_ risk80_cu


* No comorbidity
bysort agegroup male (comorbidity): gen base_risk = risk80[1]

* Label different comorbidity groups
gen name = ""
forvalues i = 1 (1) 29 {
    replace name = 	"`name`i''" if comorbidity==`i'
}


* Comorbidity names
gen Name = ""
replace Name = "No comorbidity"							if name=="cons"
replace Name = "Hypertension/high bp" 					if name=="htdiag_or_highbp" 
replace Name = "Chronic respiratory disease" 			if name=="respiratory_disease"
replace Name = "Asthma" 								if substr(name, 1, 9)=="asthmacat"
replace Name = "Chronic cardiac disease" 				if name=="cardiac_disease"
replace Name = "Diabetes"								if substr(name, 1, 7)=="diabcat"
replace Name = "Cancer (non-haematological)" 			if substr(name, 1, 17)=="cancer_exhaem_cat"
replace Name = "Haematological malignancy" 				if substr(name, 1, 15)=="cancer_haem_cat"
replace Name = "Chronic liver diseaser" 				if name=="chronic_liver_disease"
replace Name = "Stroke or dementia"						if name=="stroke_dementia"
replace Name = "Other neurological" 					if name=="other_neuro"
replace Name = "Reduced kidney function" 				if substr(name, 1, 14)=="red_kidney_cat"
replace Name = "Organ transplant" 						if name=="organ_transplant"
replace Name = "Asplenia" 								if name=="spleen"
replace Name = "Rheumatoid arthritis/Lupus/Psoriasis" 	if name=="ra_sle_psoriasis"
replace Name = "Other immunosuppression" 				if name=="immunosuppression"


* Numerical levels
bysort agegroup male Name (comorbidity): gen level = _n



* Levels
gen leveldesc = " "

replace leveldesc = "Controlled (HbA1c <58mmol/mol)" 		if Name == "Diabetes" & level==2
replace leveldesc = "Uncontrolled (HbA1c >=58mmol/mol) " 	if Name == "Diabetes" & level==3
replace leveldesc = "Unknown HbA1c" 						if Name == "Diabetes" & level==4

replace leveldesc = "With no recent OCS use" 				if Name ==  "Asthma"  & level==2
replace leveldesc = "With recent OCS use" 					if Name ==  "Asthma"  & level==3

replace leveldesc = "<1 year ago" 							if Name == "Cancer (non-haematological)"  & level==2
replace leveldesc = "1-4.9 years ago" 						if Name == "Cancer (non-haematological)"  & level==3
replace leveldesc = "5+ years ago" 							if Name == "Cancer (non-haematological)"  & level==4

replace leveldesc = "<1 year ago" 							if Name == "Haematological malignancy"  & level==2
replace leveldesc = "1-4.9 years ago" 						if Name == "Haematological malignancy"  & level==3
replace leveldesc = "5+ years ago" 							if Name == "Haematological malignancy"  & level==4

replace leveldesc = "eGFR 30-60 ml/min/1.73m2" 				if Name == "Reduced kidney function" & level==2
replace leveldesc = "eGFR <30 ml/min/1.73m2" 				if Name == "Reduced kidney function" & level==3




************************************
*  Variables to make graph pretty  *
************************************

* Names
bysort agegroup male Name (level): gen drawname = (_n==1)


* Order of the graphs
sort comorbidity male agegroup
bysort agegroup male (comorbidity): gen rev_graphorder = _n
qui summ rev_graphorder
bysort agegroup male:  gen graphorder = _N - rev_graphorder







*****************
*  Draw graphs  *
*****************

* Pick up overall percentiles
foreach p of numlist 50 70 80 90 {
	qui summ p`p'
	global p`p' = r(mean)
	noi di `p`p''
}



/*  18-<40  */ 

capture drop zero1
gen zero1 =  -0.00002

* Females
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero1 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero1 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==0 & agegroup==1 																	///
		, xlab(0 (0.00002) 0.00004) xtitle(" ") ysc(off) ylab(none) ytitle("")						/// 
		legend(off)  ysize(8)  subtitle("Female, 18-<40")  graphregion(color(white))  fxsize(100)  	///
		xline($p50, lpattern(dot) lcolor(green)) 
graph save m0_1.gph, replace


* Males
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero1 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero1 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==1 & agegroup==1 																	///
		, xlab(0 (0.00002) 0.00004) xtitle(" ") xtitle(" ") ysc(off) ylab(none) ytitle("")			///
		legend(off)  ysize(8)  subtitle("Male, 18-<40") graphregion(color(white)) fxsize(100)   	///
		xline($p50, lpattern(dot) lcolor(green))	
graph save m1_1.gph, replace

	

graph combine m0_1.gph m1_1.gph, ycommon xcommon col(3) graphregion(color(white))	///
		b1title("80-day risks & 95% CI", size(small)) 
graph export output/abs_risk_1_eth`ethnicity'.svg, as(svg) replace width(1600)
erase m0_1.gph 
erase m1_1.gph



/*  40-<50  */ 

capture drop zero2
gen zero2 =  -0.0001

* Females
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13))									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero2 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero2 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==0 & agegroup==2 																	///
		, xlab(0 (0.00005) 0.00015) xtitle(" ") ysc(off) ylab(none) ytitle("")						/// 
		legend(off)  ysize(8)  subtitle("Female, 40-<50")  graphregion(color(white))  fxsize(100)  	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))			
graph save m0_2.gph, replace


* Males
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero2 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero2 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==1 & agegroup==2 																	///
		, xlab(0 (0.00005) 0.00015) xtitle(" ") xtitle(" ") ysc(off) ylab(none) ytitle("")			///
		legend(off)  ysize(8)  subtitle("Male, 40-<50") graphregion(color(white)) fxsize(100)   	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))			
graph save m1_2.gph, replace

graph combine m0_2.gph m1_2.gph, ycommon xcommon col(3) graphregion(color(white))	///
		b1title("80-day risks & 95% CI", size(small)) 
graph export output/abs_risk_2_eth`ethnicity'.svg, as(svg) replace width(1600)
erase m0_2.gph 
erase m1_2.gph





/*  50-<60  */ 

capture drop zero3
gen zero3 =  -0.0002

* Females
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero3 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero3 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==0 & agegroup==3 																	///
		, xlab(0 (0.0001) 0.0004) xtitle(" ") ysc(off) ylab(none) ytitle("")						/// 
		legend(off)  ysize(8)  subtitle("Female, 50-<60")  graphregion(color(white))  fxsize(100)  	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))												
graph save m0_3.gph, replace


* Males
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero3 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero3 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==1 & agegroup==3 																	///
		, xlab(0 (0.0001) 0.0004) xtitle(" ") xtitle(" ") ysc(off) ylab(none) ytitle("")			///
		legend(off)  ysize(8)  subtitle("Male, 50-<60") graphregion(color(white)) fxsize(100)	   	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))	
graph save m1_3.gph, replace

graph combine m0_3.gph m1_3.gph, ycommon xcommon col(3) graphregion(color(white))	///
		b1title("80-day risks & 95% CI", size(small)) 
graph export output/abs_risk_3_eth`ethnicity'.svg, as(svg) replace width(1600)
erase m0_3.gph 
erase m1_3.gph





/*  60-<65  */ 

capture drop zero4
gen zero4 =  -0.0006

* Females
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero4 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero4 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==0 & agegroup==4 																	///
		, xlab(0 (0.0005) 0.001) xtitle(" ") ysc(off) ylab(none) ytitle("")							/// 
		legend(off)  ysize(8)  subtitle("Female, 60-<65")  graphregion(color(white))  fxsize(100)  	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))													///
		xline($p90, lpattern(dot) lcolor(red))	
graph save m0_4.gph, replace


* Males
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero4 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero4 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==1 & agegroup==4 																	///
		, xlab(0 (0.0005) 0.001) xtitle(" ") xtitle(" ") ysc(off) ylab(none) ytitle("")				///
		legend(off)  ysize(8)  subtitle("Male, 60-<65") graphregion(color(white)) fxsize(100)   	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))													///
		xline($p90, lpattern(dot) lcolor(red))
graph save m1_4.gph, replace

graph combine m0_4.gph m1_4.gph, ycommon xcommon col(3) graphregion(color(white))	///
		b1title("80-day risks & 95% CI", size(small)) 
graph export output/abs_risk_4_eth`ethnicity'.svg, as(svg) replace width(1600)
erase m0_4.gph 
erase m1_4.gph





/*  65-<70  */ 

capture drop zero5
gen zero5 =  -0.0006

* Females
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero5 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero5 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==0 & agegroup==5 																	///
		, xlab(0 (0.0005) 0.001) xtitle(" ") ysc(off) ylab(none) ytitle("")							/// 
		legend(off)  ysize(8)  subtitle("Female, 65-<70")  graphregion(color(white))  fxsize(100)  	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))													///
		xline($p90, lpattern(dot) lcolor(red))	
graph save m0_5.gph, replace


* Males
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero5 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero5 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==1 & agegroup==5																	///
		, xlab(0 (0.0005) 0.001) xtitle(" ") xtitle(" ") ysc(off) ylab(none) ytitle("")				///
		legend(off)  ysize(8)  subtitle("Male, 65-<70") graphregion(color(white)) fxsize(100)   	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))													///
		xline($p90, lpattern(dot) lcolor(red))
graph save m1_5.gph, replace

graph combine m0_5.gph m1_5.gph, ycommon xcommon col(3) graphregion(color(white))	///
		b1title("80-day risks & 95% CI", size(small)) 
graph export output/abs_risk_5_eth`ethnicity'.svg, as(svg) replace width(1600)
erase m0_5.gph 
erase m1_5.gph



/*  70-<75 */ 

capture drop zero6
gen zero6 =  -0.0015

* Females
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero6 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero6 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==0 & agegroup==6																	///
		, xlab(0 (0.001) 0.002) xtitle(" ") ysc(off) ylab(none) ytitle("")							/// 
		legend(off)  ysize(8)  subtitle("Female, 70-<75")  graphregion(color(white))  fxsize(100)  	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))													///
		xline($p90, lpattern(dot) lcolor(red))
graph save m0_6.gph, replace


* Males
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13))									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero6 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero6 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==1 & agegroup==6 																	///
		, xlab(0 (0.001) 0.002) xtitle(" ") xtitle(" ") ysc(off) ylab(none) ytitle("")				///
		legend(off)  ysize(8)  subtitle("Male, 70-<75") graphregion(color(white)) fxsize(100)   	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))													///
		xline($p90, lpattern(dot) lcolor(red))
graph save m1_6.gph, replace

graph combine m0_6.gph m1_6.gph, ycommon xcommon col(3) graphregion(color(white))	///
		b1title("80-day risks & 95% CI", size(small)) 
graph export output/abs_risk_6_eth`ethnicity'.svg, as(svg) replace width(1600)
erase m0_6.gph 
erase m1_6.gph



/*  75-<80 */ 

capture drop zero7
gen zero7 =  -0.0015

* Females
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero7 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero7 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==0 & agegroup==7																	///
		, xlab(0 (0.001) 0.002) xtitle(" ") ysc(off) ylab(none) ytitle("")							/// 
		legend(off)  ysize(8)  subtitle("Female, 75-<80")  graphregion(color(white))  fxsize(100)  	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))													///
		xline($p90, lpattern(dot) lcolor(red))
graph save m0_7.gph, replace


* Males
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13))									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero7 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero7 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==1 & agegroup==7																	///
		, xlab(0 (0.001) 0.002) xtitle(" ") xtitle(" ") ysc(off) ylab(none) ytitle("")				///
		legend(off)  ysize(8)  subtitle("Male, 75-<80") graphregion(color(white)) fxsize(100)   	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))													///
		xline($p90, lpattern(dot) lcolor(red))
graph save m1_7.gph, replace

graph combine m0_7.gph m1_7.gph, ycommon xcommon col(3) graphregion(color(white))	///
		b1title("80-day risks & 95% CI", size(small)) 
graph export output/abs_risk_7_eth`ethnicity'.svg, as(svg) replace width(1600)
erase m0_7.gph 
erase m1_7.gph



/*  80+ */ 

capture drop zero8
gen zero8 =  -0.004

* Females
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero8 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero8 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8))	///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==0 & agegroup==8 																	///
		, xlab(0 (0.001) 0.005) xtitle(" ") ysc(off) ylab(none) ytitle("")							/// 
		legend(off)  ysize(8)  subtitle("Female, 80+")  graphregion(color(white))  fxsize(100)  	///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))													///
		xline($p90, lpattern(dot) lcolor(red))
graph save m0_8.gph, replace


* Males
twoway  (line graphorder base_risk, lpattern(dash) lcolor(gs13)) 									///
		(rcap risk80_cl risk80_cu graphorder, hor mcol(black) lcol(black))							///
		(scatter graphorder zero8 if drawname==1, m(i) mlab(Name) mlabsize(tiny) mlabcol(black)) 	///
		(scatter graphorder zero8 if drawname!=1, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8)) ///
		(scatter graphorder risk80, mcolor(teal)) 													/// 	
		if male==1 & agegroup==8 																	///
		, xlab(0 (0.001) 0.005) xtitle(" ") xtitle(" ") ysc(off) ylab(none) ytitle("")				///
		legend(off)  ysize(8)  subtitle("Male, 80+") graphregion(color(white)) fxsize(100)   		///
		xline($p50, lpattern(dot) lcolor(green))													///
		xline($p70, lpattern(dot) lcolor(sand))														///
		xline($p80, lpattern(dot) lcolor(orange))													///
		xline($p90, lpattern(dot) lcolor(red))
graph save m1_8.gph, replace

graph combine m0_8.gph m1_8.gph, ycommon xcommon col(3) graphregion(color(white))	///
		b1title("80-day risks & 95% CI", size(small)) 
graph export output/abs_risk_8_eth`ethnicity'.svg, as(svg) replace width(1600)
erase m0_8.gph 
erase m1_8.gph


