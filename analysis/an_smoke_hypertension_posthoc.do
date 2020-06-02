
local outcome `1'

* Open a log file
capture log close
log using "./output/an_smoke_hypertension_posthoc_`outcome'", text replace


***************************************
*Smoking adjusted for demographics only

use "cr_create_analysis_dataset_STSET_`outcome'.dta", clear

cap stcox age1 age2 age3 i.male i.ethnicity i.imd i.smoke_nomiss, strata(stp)
if _rc==0{
estimates 
estimates save ./output/models/an_smoke_hypertension_posthoc_`outcome'_smokeadjdemog, replace	
}

**********************************
*Hypertension with age interaction

stcox ib3.agegroup 	///
			i.male 							///
			i.obese4cat						///
			i.smoke_nomiss					///
			`ethnicity'						///
			i.imd 							///
			i.chronic_respiratory_disease 	///
			i.asthmacat						///
			i.chronic_cardiac_disease 		///
			i.diabcat						///
			i.cancer_exhaem_cat	 			///
			i.cancer_haem_cat  				///
			i.chronic_liver_disease 		///
			i.stroke_dementia		 		///
			i.other_neuro					///
			i.reduced_kidney_function_cat	///
			i.organ_transplant 				///
			i.spleen 						///
			i.ra_sle_psoriasis  			///
			i.other_immunosuppression			///
			ib3.agegroup i.htdiag_or_highbp ///
			1.agegroup#1.htdiag_or_highbp 2.agegroup#1.htdiag_or_highbp 4.agegroup#1.htdiag_or_highbp  5.agegroup#1.htdiag_or_highbp 6.agegroup#1.htdiag_or_highbp ///
			, strata(stp)
			
estimates save ./output/models/an_smoke_hypertension_posthoc_`outcome'_ht_byage, replace	

lincom 1.htdiag_or_highbp + 1.agegroup#1.htdiag_or_highbp, eform
lincom 1.htdiag_or_highbp + 2.agegroup#1.htdiag_or_highbp, eform
lincom 1.htdiag_or_highbp , eform
lincom 1.htdiag_or_highbp + 4.agegroup#1.htdiag_or_highbp, eform
lincom 1.htdiag_or_highbp + 5.agegroup#1.htdiag_or_highbp, eform
lincom 1.htdiag_or_highbp + 6.agegroup#1.htdiag_or_highbp, eform

log close
