cap log close
log using ./output/an_ageinteractions_full, replace t

use cr_create_analysis_dataset_STSET_onscoviddeath.dta, clear

frame change default
cap frame drop results
frame create results agegroup str30 variablename variablelevel hr lci uci pint /*post as we go*/
	
*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basemodel
prog define basemodel
	syntax , age(string) bp(string) [ethnicity(real 0) interaction(string)] 

	if `ethnicity'==1 local ethnicity "i.ethnicity"
	else local ethnicity
timer clear
timer on 1
	  stcox 	`age' 					///
			i.male 							///
			i.obese4cat						///
			i.smoke_nomiss					///
			`ethnicity'						///
			i.imd 							///
			`bp'							///
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
			`interaction'							///
			, strata(stp)
	timer off 1
timer list
end
*************************************************************************************

gen agegrouporig = agegroup

*Age interactions 
foreach intvar of varlist 									///
							male 							///
							obese4cat						///
							smoke_nomiss					///
							ethnicity						///
							imd 							///
							htdiag_or_highbp				///
							chronic_respiratory_disease 	///
							asthmacat						///
							chronic_cardiac_disease 		///
							diabcat							///
							cancer_exhaem_cat	 			///
							cancer_haem_cat  				///
							chronic_liver_disease 			///
							stroke_dementia		 			///
							other_neuro						///
							reduced_kidney_function_cat		///
							organ_transplant 				///
							spleen 							///
							ra_sle_psoriasis  				///
							other_immunosuppression		{

replace agegroup = agegrouporig
local agegroup_startpost = 2
if ("`intvar'"=="organ_transplant"|"`intvar'"=="spleen"|"`intvar'"=="stroke_dementia"|"`intvar'"=="cancer_exhaem_cat"|"`intvar'"=="cancer_haem_cat") { 
	recode agegroup 2=1
	local agegroup_startpost = 3
	}

local ethnicityflag 0
if ("`intvar'"=="ethnicity") local ethnicityflag 1

	qui levelsof `intvar', local(intvarlevels)
	local intvarlevelsexbase = substr("`intvarlevels'", 3, .)
	di "`intvarlevelsexbase'"

	*get interaction terms
	local interactionterms
	foreach intlevel of numlist `intvarlevelsexbase'{
	forvalues agegroup=2/6 {
		local interactionterms `interactionterms' `agegroup'.agegroup#`intlevel'.`intvar'
	}
	}
	
	*fit model
	basemodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(`ethnicityflag') interaction(`interactionterms')

	*post results
	if _rc==0{
	est save ./output/models/an_ageinteractions_full_`intvar', replace
	testparm `interactionterms'
	local pint=r(p)
	foreach intvarlevel of numlist `intvarlevelsexbase' {
		lincom `intvarlevel'.`intvar', eform
		frame post results (1) ("`intvar'") (`intvarlevel') (r(estimate)) (r(lb)) (r(ub)) (`pint')
		forvalues agelevel=`agegroup_startpost'/6 {
			lincom `intvarlevel'.`intvar' + `agelevel'.agegroup#`intvarlevel'.`intvar', eform
			frame post results (`agelevel') ("`intvar'") (`intvarlevel') (r(estimate)) (r(lb)) (r(ub)) (`pint')
			}
		}
	}
	else frame post results (99) ("`intvar'") (99) (99) (99) (99) (99)	
}

*Tidy up results
frame change results

gen hrci = string(hr, "%5.2f") + " (" + string(lci, "%5.2f") + ", " + string(uci, "%5.2f") + ")"
drop hr lci uci
format %4.3f pint

reshape wide hrci pint, i(variablename variablelevel ) j(agegroup)
gen pint = pint1
drop pint1 pint2 pint3 pint4 pint5 pint6

	gen order = .
	local i = 1
	foreach var of any male obese4cat smoke_nomiss ethnicity imd htdiag_or_highbp chronic_respiratory_disease asthmacat chronic_cardiac_disease diabcat cancer_exhaem_cat cancer_haem_cat reduced_kidney_function_cat chronic_liver_disease stroke_dementia other_neuro organ_transplant spleen ra_sle_psoriasis other_immunosuppression{
	replace order = `i' if variablename=="`var'"
	local i = `i'+1
	}
	sort order variablelevel

outsheet variablename variablelevel hrci0 hrci1 pint0 using ./output/an_ageinteractions_lt70vsgte70_TABLE.txt, replace
	
log close
