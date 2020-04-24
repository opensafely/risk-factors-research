import delimited `c(pwd)'/analysis/input.csv


set more off
cd  `c(pwd)'/analysis


/*  Pre-analysis data manipulation  */

**********************************************
*IF PARALLEL WORKING - THIS MUST BE RUN FIRST*
**********************************************
do "cr_create_analysis_dataset.do"


/*  Run analyses  */

*********************************************************************
*IF PARALLEL WORKING - FOLLOWING CAN BE RUN IN ANY ORDER/IN PARALLEL*
*       PROVIDING THE ABOVE CR_ FILE HAS BEEN RUN FIRST				*
*********************************************************************
do "an_tablecontent_PublicationDescriptivesTable.do"

do "an_checks.do"
do "an_descriptive_tables.do"
do "an_descriptive_plots.do"


*do "an_univariable_cox_models.do" ecdsevent /*not currently avail*/
do "an_univariable_cox_models.do" cpnsdeath
do "an_univariable_cox_models.do" onscoviddeath 
do "an_univariable_cox_models.do" ituadmission 

*do "an_multivariable_cox_models.do" ecdsevent /*not currently avail*/
do "an_multivariable_cox_models.do" cpnsdeath
do "an_multivariable_cox_models.do" onscoviddeath 
do "an_multivariable_cox_models.do" ituadmission 


************************************************************
*PARALLEL WORKING - THIS MUST BE RUN LAST (IT's VERY QUICK)*
************************************************************
do "an_tablecontent_HRtable.do"



