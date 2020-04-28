*an_tablecontent_PublicationDescriptivesTable
*************************************************************************
*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell "Table 1" (main cohort descriptives) for the Risk Factors paper
*
*Requires: final analysis dataset (cr_analysis_dataset.dta)
*
*Coding: Krishnan Bhaskaran
*
*Date drafted: 17/4/2020
*************************************************************************


*******************************************************************************
*Generic code to output one row of table
cap prog drop generaterow
program define generaterow
syntax, variable(varname) condition(string) 
	
	cou
	local overalldenom=r(N)
	
	cou if `variable' `condition'
	local rowdenom = r(N)
	local colpct = 100*(r(N)/`overalldenom')
	file write tablecontent (`rowdenom')  (" (") %3.1f (`colpct') (")") _tab

	cou if ituadmission==1<. & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom')
	file write tablecontent (r(N)) (" (") %3.1f  (`pct') (")") _tab

	cou if cpnsdeath==1 & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom')
	file write tablecontent (r(N)) (" (") %3.1f  (`pct') (")") _tab

	cou if onscoviddeath==1 & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom')
	file write tablecontent (r(N)) (" (") %3.1f (`pct') (")") _n
end

*******************************************************************************
*Generic code to output one section (varible) within table (calls above)
cap prog drop tabulatevariable
prog define tabulatevariable
syntax, variable(varname) start(real) end(real) [missing]

	foreach varlevel of numlist `start'/`end'{ 
		generaterow, variable(`variable') condition("==`varlevel'")
	}
	if "`missing'"!="" generaterow, variable(`variable') condition(">=.")

end

*******************************************************************************

*Set up output file
cap file close tablecontent
file open tablecontent using ./output/an_tablecontent_PublicationDescriptivesTable.txt, write text replace


use cr_create_analysis_dataset,clear


gen byte cons=1
tabulatevariable, variable(cons) start(1) end(1) 
file write tablecontent _n _n

tabulatevariable, variable(agegroup) start(1) end(6) 
file write tablecontent _n _n

tabulatevariable, variable(male) start(0) end(1) 
file write tablecontent _n _n

tabulatevariable, variable(bmicat) start(1) end(6) missing
file write tablecontent _n _n

tabulatevariable, variable(smoke) start(1) end(3) missing 
file write tablecontent _n _n

tabulatevariable, variable(ethnicity) start(1) end(5) missing 
file write tablecontent _n _n

tabulatevariable, variable(imd) start(1) end(5) missing
file write tablecontent _n _n

tabulatevariable, variable(bpcat) start(1) end(4) missing
file write tablecontent _n 
tabulatevariable, variable(htdiag_or_highbp) start(1) end(1) 			
file write tablecontent _n _n

file write tablecontent _n 

**COMORBIDITIES
*RESPIRATORY
tabulatevariable, variable(chronic_respiratory_disease) start(1) end(0)
file write tablecontent _n
*ASTHMA
tabulatevariable, variable(asthmacat) start(3) end(1)
file write tablecontent _n
*CARDIAC
tabulatevariable, variable(chronic_cardiac_disease) start(1) end(0)
file write tablecontent _n
*DIABETES
tabulatevariable, variable(diabcat) start(3) end(2) /*uncontrolled, then controlled*/
tabulatevariable, variable(diabcat) start(4) end(4) /*no a1c measure*/
tabulatevariable, variable(diabcat) start(1) end(1) /*no diabetes*/
file write tablecontent _n
*CANCER EX HAEM
tabulatevariable, variable(cancer_exhaem_cat) start(2) end(4) /*<1, 1-4.9, 5+ years ago*/
tabulatevariable, variable(cancer_exhaem_cat) start(1) end(1) /*never*/
file write tablecontent _n
*CANCER HAEM
tabulatevariable, variable(cancer_haem_cat) start(2) end(4) /*<1, 1-4.9, 5+ years ago*/
tabulatevariable, variable(cancer_haem_cat) start(1) end(1) /*never*/
file write tablecontent _n
*LIVER
tabulatevariable, variable(chronic_liver_disease) start(1) end(0)
file write tablecontent _n
*STROKE/DEMENTIA
tabulatevariable, variable(stroke_dementia) start(1) end(0)
file write tablecontent _n
*OTHER NEURO
tabulatevariable, variable(other_neuro) start(1) end(0)
file write tablecontent _n
*CKD
tabulatevariable, variable(chronic_kidney_disease) start(1) end(0)
file write tablecontent _n
*ORGAN TRANSPLANT
tabulatevariable, variable(organ_transplant) start(1) end(0)
file write tablecontent _n
*SPLEEN
tabulatevariable, variable(spleen) start(1) end(0)
file write tablecontent _n
*RA_SLE_PSORIASIS
tabulatevariable, variable(ra_sle_psoriasis) start(1) end(0)
file write tablecontent _n
*OTHER IMMUNOSUPPRESSION
tabulatevariable, variable(other_immunosuppression) start(1) end(0)
file write tablecontent _n



file close tablecontent
