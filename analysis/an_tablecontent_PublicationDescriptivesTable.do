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

	cou if  ecdsevent==1 & `variable' `condition'
	local pct = 100*(r(N)/`rowdenom') 
	file write tablecontent (r(N)) (" (") %3.1f (`pct') (")") _tab

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
syntax, variable(varname) min(real) max(real) [missing]

	forvalues varlevel = `min'/`max'{ 
		generaterow, variable(`variable') condition("==`varlevel'")
	}
	if "`missing'"!="" generaterow, variable(`variable') condition(">=.")

end

*******************************************************************************

*Set up output file
cap file close tablecontent
file open tablecontent using ./output/an_tablecontent_PublicationDescriptivesTable.txt, write text replace


use egdata,clear


gen byte cons=1
tabulatevariable, variable(cons) min(1) max(1) 
file write tablecontent _n _n

tabulatevariable, variable(agegroup) min(1) max(6) 
file write tablecontent _n _n

tabulatevariable, variable(male) min(0) max(1) 
file write tablecontent _n _n

tabulatevariable, variable(bmicat) min(1) max(6) missing
file write tablecontent _n _n

tabulatevariable, variable(smoke) min(1) max(3) missing 
file write tablecontent _n _n

tabulatevariable, variable(ethnicity) min(1) max(5) missing 
file write tablecontent _n _n

tabulatevariable, variable(imd) min(1) max(5) missing
file write tablecontent _n _n

tabulatevariable, variable(bpcat) min(1) max(4) missing
file write tablecontent _n _n

file write tablecontent _n 

**COMORBIDITIES
foreach comorb of varlist 	chronic_respiratory_disease 	///
							asthma 							///
							chronic_cardiac_disease 		///
							diabetes 						///
							cancer_exhaem_lastyr 			///
							haemmalig_aanaem_bmtrans_lastyr  ///
							chronic_liver_disease 			///
							stroke_dementia		 			///
							other_neuro						///
							chronic_kidney_disease 			///
							organ_transplant 				///
							spleen 							///
							ra_sle_psoriasis 				///
							/*endocrine?*/					///
							/*immunosuppression?*/			///
							{
generaterow, variable(`comorb') condition("==1")
generaterow, variable(`comorb') condition("==0")
file write tablecontent _n
}


file close tablecontent
