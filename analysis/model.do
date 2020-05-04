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

*UNIVARIATE MODELS (these fit the models needed for age/sex adj col of Table 2)
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

*MULTIVARIATE MODELS (this fits the models needed for fully adj col of Table 2)
do "an_multivariable_cox_models.do" cpnsdeath


*SENSITIVITY ANALYSES / POST HOC ANALYSES

*SMOKING EXPLORATION COX MODELS BATCH 1
do "an_smoking_exploration_cox_models.do" cpnsdeath ///
	asthmacat							///
	cancer_exhaem_cat					///
	cancer_haem_cat						///
	chronic_cardiac_disease 			///
	chronic_kidney_disease				

*SMOKING EXPLORATION COX MODELS BATCH 2
do "an_smoking_exploration_cox_models.do" cpnsdeath ///
	chronic_liver_disease 				///
	chronic_respiratory_disease 		///
	diabcat								///
	ethnicity 							///
	htdiag_or_highbp					

*SMOKING EXPLORATION COX MODELS BATCH 3
do "an_smoking_exploration_cox_models.do" cpnsdeath ///
	imd 								///
	obese4cat							///
	organ_transplant 					///
	other_immunosuppression				///
	other_neuro 						
	

*SMOKING EXPLORATION COX MODELS BATCH 4
do "an_smoking_exploration_cox_models.do" cpnsdeath ///
	ra_sle_psoriasis 					///  
	smoke  								///
	smoke_nomiss 						///
	spleen 								///
	stroke_dementia	

	
*THE NEXT 3 INCLUDE ALL THE MODELLING FOR THE SENS AN APPX TABLE	
*SENS AN AMONG ETHNICITY CCs	
do "an_sensan_CCethnicity_cpnsdeath.do"
	
*SENS AN WITH EARLIER ADMIN CENSORING AT 6th APRIL PRE EFFECT OF LOCKDOWN
do "an_sensan_earlieradmincensoring_cpnsdeath.do"

*SENS AN AMONG THOSE WITH RECORDED BMI AND SMOKING ONLY
do "an_sensan_CCbmiandsmok_cpnsdeath.do"	

*SENS AN USING DIFFERENT BP MEASURES
do "an_sensan_differentBPmeasures_cpnsdeath"
	
************************************************************
*PARALLEL WORKING - THESE MUST BE RUN AFTER THE 
*MAIN AN_UNIVARIATE.. AND AN_MULTIVARIATE... 
*and AN_SENS... DO FILES HAVE FINISHED
*(THESE ARE VERY QUICK)*
************************************************************
do "an_tablecontent_HRtable_HRforest.do"
do "an_tablecontent_SENSANtable.do"
do "an_agesplinevisualisation.do"

**Experimental, to do at end (in case slow)
do "an_checkassumptions.do" cpnsdeath /*calculates c-stat and Schoenfeld PH test */
*do "an_checkassumptions_2.do" /*KM curves by each variable, slow*/

/**************************************
** MI for ethnicity - run these in parallel
do "an_checkassumptions_3.do" 1
do "an_checkassumptions_3.do" 2
do "an_checkassumptions_3.do" 3
do "an_checkassumptions_3.do" 4
do "an_checkassumptions_3.do" 5
do "an_checkassumptions_3.do" 6
do "an_checkassumptions_3.do" 7
do "an_checkassumptions_3.do" 8
do "an_checkassumptions_3.do" 9
**************************************
do an_checkassumptions_3b /*run at end, combines imputations and analyses)*/
**************************************/


