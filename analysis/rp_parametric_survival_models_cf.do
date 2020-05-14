********************************************************************************
*
*	Do-file:		rp_parametric_survival_models_cf.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		cr_create_analysis_dataset_STSET_CPNS.dta
*
*	Data created:	None
*
*	Other output:	Log file:  	rp_parametric_survival_models_cf.log
*					Graph:		output/survival.svg
*
********************************************************************************
*
*	Purpose:		This do-file compares simple survival models.
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************




* Open a log file
capture log close
log using "./output/rp_parametric_survival_models_cf", text replace

use "cr_create_analysis_dataset_STSET_cpnsdeath.dta", clear




***************************************
*   Kaplan Meier vs unadjusted gamma  *
***************************************


* KM survival 
sts graph, by(male)
graph save a.gph, replace
sts gen surv_km_male = s


* Generalised gamma
streg i.male, dist(ggamma) 
predict surv_gg_male, surv
estat ic


* Royston Parmar
stpm2 male,	scale(hazard) df(5) eform
predict surv_rp_male, surv
estat ic



* Graph survival curves
twoway 	(line surv_km_male _t if male==1, sort) ///
		(line surv_km_male _t if male==0, sort), yscale(range(0 1)) title("Kaplan-Meier")
graph save b.gph, replace

twoway 	(line surv_gg_male _t if male==1, sort) ///
		(line surv_gg_male _t if male==0, sort), yscale(range(0 1)) title("Generalised Gamma")
graph save c.gph, replace
	
twoway 	(line surv_rp_male _t if male==1, sort) ///
		(line surv_rp_male _t if male==0, sort), yscale(range(0 1)) title("Royston-Parmar")
graph save d.gph, replace

* Combine survival curves
graph combine a.gph b.gph c.gph d.gph, col(4)
graph export "output/survival.svg", as(svg) replace

erase a.gph
erase b.gph
erase c.gph
erase d.gph




log close





