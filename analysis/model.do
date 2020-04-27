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

*Univariate models can be run in parallel Stata instances for speed
*Command is "do an_univariable_cox_models <OUTCOME> <VARIABLE(s) TO RUN>
*The following breaks down into 4 batches, 
*  which can be done in separate Stata instances
*Can be broken down further but recommend keeping in alphabetical order
*   because of the ways the resulting log files are named

*UNIVARIATE MODELS BATCH 1
do "an_univariable_cox_models.do" cpnsdeath ///
	agegroupsex							///
	agesplsex							///
	asthmacat							///
	cancer_exhaem_cat					///
	cancer_haem_cat						///
	chronic_cardiac_disease 			

*UNIVARIATE MODELS BATCH 2
do "an_univariable_cox_models.do" cpnsdeath ///
	chronic_kidney_disease				///
	chronic_liver_disease 				///
	chronic_respiratory_disease 		///
	diabcat								///
	ethnicity 

*UNIVARIATE MODELS BATCH 3
do "an_univariable_cox_models.do" cpnsdeath ///
	htdiag_or_highbp					///
	 bpcat 								///
	 hypertension						///
	imd 								///
	obese4cat							///
	 bmicat 							///
	organ_transplant 					
	

*UNIVARIATE MODELS BATCH 4
do "an_univariable_cox_models.do" cpnsdeath ///
	other_immunosuppression				///
	other_neuro 						///
	ra_sle_psoriasis 					///  
	smoke  								///
	smoke_nomiss 						///
	spleen 								///
	stroke_dementia

*do "an_univariable_cox_models.do" onscoviddeath <VARLIST> 
*do "an_univariable_cox_models.do" ituadmission <VARLIST>

*MULTIVARIATE MODELS
do "an_multivariable_cox_models.do" cpnsdeath
*do "an_multivariable_cox_models.do" onscoviddeath 
*do "an_multivariable_cox_models.do" ituadmission 


************************************************************
*PARALLEL WORKING - THIS MUST BE RUN LAST (IT's VERY QUICK)*
************************************************************
do "an_tablecontent_HRtable.do"


**Experimental, to do at end (in case slow)
do "an_checkassumptions.do" cpnsdeath



