
*an_agesplinevisualisation
*KB 1/5/2020

use cr_create_analysis_dataset_STSET_cpnsdeath, clear

cap estimates use ./output/models/an_multivariate_cox_models_cpnsdeath_MAINFULLYADJMODEL_agespline_bmicat_noeth

if _rc==0{

	bysort age: keep if _n==1

	for var male obese4cat smoke_nomiss imd htdiag_or_highbp chronic_respiratory_disease ///
	asthmacat chronic_cardiac_disease diabcat cancer_exhaem_cat cancer_haem_cat /// 
	chronic_liver_disease stroke_dementia other_neuro chronic_kidney_disease organ_transplant ///
	spleen ra_sle_psoriasis other_immunosuppression: replace X = 0 

	predict xb, xb
	summ xb if age==5
	gen xb_c = xb-r(mean)
	gen hrcf55 = exp(xb_c)
	*line xb_c age, sort xtitle(Age in years) ytitle("Log hazard ratio (reference age 55 years)") yline(0, lp(dash))
	
	line hrcf55 age, sort xtitle(Age in years) ytitle("Hazard ratio compared to age 55 years (log scale)") yscale(log) ylab( 0.1 0.2 .1 .5 1 2 5 10 20) yline(0, lp(dash))

	graph export ./output/an_agesplinevisualisation_cpnsdeath.svg, as(svg) replace

}
