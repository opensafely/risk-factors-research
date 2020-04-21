
*an_tablecontent_HRtable
*************************************************************************
*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell table containing minimally and fully-adjusted HRs for risk factors
* of interest, across 4 outcomes (hosp, death, itu, death/itu composite)
*
*Requires: final analysis dataset (cr_analysis_dataset.dta)
*
*Coding: Krishnan Bhaskaran
*
*Date drafted: 18/4/2020
*************************************************************************



***********************************************************************************************************************
*Generic code to ouput the HRs across outcomes for all levels of a particular variables, in the right shape for table
cap prog drop outputHRsforvar
prog define outputHRsforvar
syntax, variable(varname) min(real) max(real) 
forvalues i=`min'/`max'{
local endwith "_tab"

	foreach outcome of any hosp itu died composite {
	
	foreach modeltype of any minadj fulladj {

		if "`outcome'"=="composite" & "`modeltype'"=="fulladj" local endwith "_n"

		***********************
		*1) GET THE RIGHT ESTIMATES INTO MEMORY
		
		if "`modeltype'"=="minadj" & "`variable'"!="agegroup" & "`variable'"!="male" estimates use ./output/models/an_univariable_cox_models_`outcome'_AGESPLSEX_`variable'

		*FOR AGEGROUP - need to use the separate univariate/multivariate model fitted with age group rather than spline
		*FOR ETHNICITY - use the separate complete case multivariate model
		*FOR REST - use the "main" multivariate model
		if "`variable'"=="agegroup" {
			if "`modeltype'"=="minadj" estimates use ./output/models/an_univariable_cox_models_`outcome'_AGEGROUPSEX_
			if "`modeltype'"=="fulladj" estimates use ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agegroup_bmicat_noeth  
			}
		else if "`variable'"=="male" {
			if "`modeltype'"=="minadj" estimates use ./output/models/an_univariable_cox_models_`outcome'_AGESPLSEX_
			if "`modeltype'"=="fulladj" estimates use ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agegroup_bmicat_noeth  
			}
		else if "`variable'"=="ethnicity" {
			if "`modeltype'"=="fulladj" estimates use ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_CCeth  
			}			
		else {
			if "`modeltype'"=="fulladj" estimates use ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_noeth  
		}
		
		***********************
		*2) WRITE THE HRs TO THE OUTPUT FILE
		
		lincom `i'.`variable', eform
		file write tablecontents %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
		
		} /*min adj, full adj*/
		
	} /*outcomes*/
} /*variable levels*/

end
***********************************************************************************************************************
*Generic code to write a full row of "ref category" to the output file
cap prog drop refline
prog define refline
file write tablecontents ("1.00 (ref)") _tab ("1.00 (ref)") _tab ("1.00 (ref)") _tab ("1.00 (ref)") _tab ("1.00 (ref)") _tab ("1.00 (ref)") _tab ("1.00 (ref)") _tab ("1.00 (ref)") _n
end
***********************************************************************************************************************

*MAIN CODE TO PRODUCE TABLE CONTENTS

cap file close tablecontents
file open tablecontents using ./output/an_tablecontents_HRtable.txt, t w replace 

*Age group
refline
outputHRsforvar, variable(agegroup) min(2) max(6)
file write tablecontents _n _n

*Sex 
refline
outputHRsforvar, variable(male) min(1) max(1)
file write tablecontents _n _n

*BMI
outputHRsforvar, variable(bmicat) min(1) max(1)
refline
outputHRsforvar, variable(bmicat) min(3) max(6)
file write tablecontents _n _n

*Smoking
refline
outputHRsforvar, variable(smoke) min(2) max(3)
file write tablecontents _n _n


*Ethnicity
refline
outputHRsforvar, variable(ethnicity) min(2) max(5)
file write tablecontents _n _n

*IMD
refline
outputHRsforvar, variable(imd) min(2) max(5)
file write tablecontents _n _n

*BPCAT
refline
outputHRsforvar, variable(bpcat) min(2) max(4)
file write tablecontents _n _n

*COMORBIDITIES
foreach comorb of varlist 	chronic_respiratory_disease 	///
							asthma 							///
							chronic_cardiac_disease 		///
							diabetes 						///
							cancer_exhaem_lastyr 			///
							haemmalig_aanaem_bmtrans_lastyr ///
							chronic_liver_disease 			///
							stroke_dementia		 			///
							other_neuro					 	///
							chronic_kidney_disease 			///
							organ_transplant 				///
							spleen ra_sle_psoriasis  		///
							/*endocrine?*/					///
							/*immunosuppression?*/			///
							{
	outputHRsforvar, variable(`comorb') min(1) max(1)							
	}

file close tablecontents
