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

*Set up output file
cap file close tablecontent
file open tablecontent using an_tablecontent_PublicationDescriptivesTable.txt, write text replace



use egdata,clear

*Total


*Age


*Sex


*BMI


*Smoking


*Ethnicity


*IMD


**COMORBIDITIES
foreach comorb of varlist... {


}

*Immunosuppression
