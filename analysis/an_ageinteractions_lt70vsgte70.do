cap log close
log using ./output/an_ageinteractions_lt70vsgte70, replace t

use cr_create_analysis_dataset_STSET_onscoviddeath.dta, clear

cap frame drop results
frame create results age70plus str30 variablename variablelevel hr lci uci pint /*post as we go*/
	
*PROG TO DEFINE THE BASIC COX MODEL WITH OPTIONS FOR HANDLING OF AGE, BMI, ETHNICITY:
cap prog drop basemodel
prog define basemodel
	syntax , age(string) bp(string) [ethnicity(real 0) interaction(string)] 

	if `ethnicity'==1 local ethnicity "i.ethnicity"
	else local ethnicity
timer clear
timer on 1
	 cap stcox 	`age' 					///
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



*Age spline model (not adj ethnicity)
basemodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(0)

gen age70plus = agegroup
recode age70plus 1/4=0 5/6=1

*Age interactions with binary vars
foreach intvar of varlist male chronic_respiratory_disease chronic_cardiac_disease chronic_liver_disease stroke_dementia other_neuro organ_transplant spleen ra_sle_psoriasis other_immunosuppression {
basemodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(0) interaction(1.age70plus#1.`intvar')
if _rc==0{
	testparm 1.age70plus#i.`intvar'
	local pint = r(p)
	di _n "`intvar' <70" _n "****************"
	lincom 1.`intvar', eform
	frame post results (0) ("`intvar'") (1) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	di "`intvar' 70+" _n "****************"
	lincom 1.`intvar' + 1.age70plus#1.`intvar', eform
	frame post results (1) ("`intvar'") (1) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	est save ./output/models/an_ageinteractions_lt70vsgte70_`intvar', replace
	}
	else frame post results (99) ("`intvar'") (99) (99) (99) (99) (99)
}
*Age interactions with 3-level vars
foreach intvar of varlist reduced_kidney_function_cat asthmacat  {
basemodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(0) interaction(1.age70plus#2.`intvar' 1.age70plus#3.`intvar')
if _rc==0{
	testparm 1.age70plus#i.`intvar'
	local pint = r(p)
	di _n "`intvar' <70" _n "****************"
	lincom 2.`intvar', eform
	frame post results (0) ("`intvar'") (2) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 3.`intvar', eform
	frame post results (0) ("`intvar'") (3) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	di "`intvar' 70+" _n "****************"
	lincom 2.`intvar' + 1.age70plus#2.`intvar', eform
	frame post results (1) ("`intvar'") (2) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 3.`intvar' + 1.age70plus#3.`intvar', eform
	frame post results (1) ("`intvar'") (3) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	est save ./output/models/an_ageinteractions_lt70vsgte70_`intvar', replace
	}
	else frame post results (99) ("`intvar'") (99) (99) (99) (99) (99)
}

*Age interactions with 4-level vars
foreach intvar of varlist obese4cat diabcat cancer_exhaem_cat cancer_haem_cat {
basemodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(0) interaction(1.age70plus#2.`intvar' 1.age70plus#3.`intvar' 1.age70plus#4.`intvar')
if _rc==0{
	testparm 1.age70plus#i.`intvar'
	local pint = r(p)
	di _n "`intvar' <70" _n "****************"
	lincom 2.`intvar', eform
	frame post results (0) ("`intvar'") (2) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 3.`intvar', eform
	frame post results (0) ("`intvar'") (3) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 4.`intvar', eform
	frame post results (0) ("`intvar'") (4) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	di "`intvar' 70+" _n "****************"
	lincom 2.`intvar' + 1.age70plus#2.`intvar', eform
	frame post results (1) ("`intvar'") (2) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 3.`intvar' + 1.age70plus#3.`intvar', eform
	frame post results (1) ("`intvar'") (3) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 4.`intvar' + 1.age70plus#4.`intvar', eform
	frame post results (1) ("`intvar'") (4) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	est save ./output/models/an_ageinteractions_lt70vsgte70_`intvar', replace
	}
	else frame post results (99) ("`intvar'") (99) (99) (99) (99) (99)
}

*Age interactions with 5-level vars
foreach intvar of varlist ethnicity {
basemodel, age("age1 age2 age3")  bp("i.htdiag_or_highbp") ethnicity(1) interaction(1.age70plus#2.`intvar' 1.age70plus#3.`intvar' 1.age70plus#4.`intvar' 1.age70plus#5.`intvar')
if _rc==0{
	testparm 1.age70plus#i.`intvar'
	local pint = r(p)
	di _n "`intvar' <70" _n "****************"
	lincom 2.`intvar', eform
	frame post results (0) ("`intvar'") (2) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 3.`intvar', eform
	frame post results (0) ("`intvar'") (3) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 4.`intvar', eform
	frame post results (0) ("`intvar'") (4) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 5.`intvar', eform
	frame post results (0) ("`intvar'") (5) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	di "`intvar' 70+" _n "****************"
	lincom 2.`intvar' + 1.age70plus#2.`intvar', eform
	frame post results (1) ("`intvar'") (2) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 3.`intvar' + 1.age70plus#3.`intvar', eform
	frame post results (1) ("`intvar'") (3) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 4.`intvar' + 1.age70plus#4.`intvar', eform
	frame post results (1) ("`intvar'") (4) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	lincom 5.`intvar' + 1.age70plus#4.`intvar', eform
	frame post results (1) ("`intvar'") (5) (r(estimate)) (r(lb)) (r(ub)) (`pint')
	est save ./output/models/an_ageinteractions_lt70vsgte70_ageint_`intvar', replace
	}
	else frame post results (99) ("`intvar'") (99) (99) (99) (99) (99)
}

frame change results

gen hrci = string(hr, "%5.2f") + " (" + string(lci, "%5.2f") + ", " + string(uci, "%5.2f") + ")"
drop hr lci uci
format %4.3f pint

reshape wide hrci pint, i(variablename variablelevel ) j(age70plus)

	gen order = .
	local i = 1
	foreach var of any male obese4cat smoke_nomiss ethnicity imd htdiag_or_highbp chronic_respiratory_disease asthmacat chronic_cardiac_disease diabcat cancer_exhaem_cat cancer_haem_cat reduced_kidney_function_cat chronic_liver_disease stroke_dementia other_neuro organ_transplant spleen ra_sle_psoriasis other_immunosuppression{
	replace order = `i' if variablename=="`var'"
	local i = `i'+1
	}
	sort order variablelevel

outsheet variablename variablelevel hrci0 hrci1 pint0 using ./output/an_ageinteractions_lt70vsgte70_TABLE.txt, replace
	
log close
