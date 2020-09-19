/*import delimited `c(pwd)'/input.csv, clear

set more off
cd  `c(pwd)'/analysis


do "_cr_create_analysis_dataset_1daysooner.do"*/
log using ./output/1daysooner, replace t
use cr_create_analysis_dataset_inc_children.dta, clear

egen agecat = cut(age), at(0,10,20,30,40,50,60,70,120)
recode cancer_exhaem_cat 1=0
recode cancer_haem_cat 1=0
recode reduced_kidney_function_cat 1=0

gen comorbidity = 0
***Comorbidities
* To be added: dates related to outcomes
foreach var of varlist 	diabetes cancer_exhaem_cat cancer_haem_cat reduced_kidney_function_cat asthma chronic_respiratory_disease chronic_cardiac_disease htdiag_or_highbp chronic_liver_disease stroke_dementia other_neuro organ_transplant spleen ra_sle_psoriasis other_immunosuppression 	{
	replace comorbidity = 1 if `var' > 0
}

bysort male: tab agecat onscoviddeath

drop if comorbidity == 1
bysort male: tab agecat onscoviddeath

drop if bmicat > 2
bysort male: tab agecat onscoviddeath

log close
