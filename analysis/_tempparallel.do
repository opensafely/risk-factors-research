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
foreach outcome of any onscoviddeath cpnsdeath {
	do "an_tablecontent_PublicationDescriptivesTable.do" `outcome'
	}
	
do "an_checks.do"
do "an_descriptive_tables.do"
winexec "C:\Program Files\Stata16\StataMP-64.exe" do "an_descriptive_plots.do"

*Univariate models can be run in parallel Stata instances for speed
*Command is "do an_univariable_cox_models <OUTCOME> <VARIABLE(s) TO RUN>
*The following breaks down into 4 batches, 
*  which can be done in separate Stata instances
*Can be broken down further but recommend keeping in alphabetical order
*   because of the ways the resulting log files are named

*UNIVARIATE MODELS (these fit the models needed for age/sex adj col of Table 2)

foreach outcome of any onscoviddeath {

	*UNIVARIATE MODELS BATCH 1
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_univariable_cox_models.do" `outcome' ///
		agegroupsex							///
		agesplsex							///
		asthmacat							///
		cancer_exhaem_cat					///
		cancer_haem_cat						///
		chronic_cardiac_disease 			

	*UNIVARIATE MODELS BATCH 2
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_univariable_cox_models.do" `outcome' ///
		reduced_kidney_function_cat				///
		dialysis							///
		chronic_liver_disease 				///
		chronic_respiratory_disease 		///
		diabcat								///
		ethnicity 

	*UNIVARIATE MODELS BATCH 3
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_univariable_cox_models.do" `outcome' ///
		htdiag_or_highbp					///
		 bpcat 								///
		 hypertension						///
		imd 								///
		obese4cat							///
		 bmicat 							///
		organ_transplant 					
		

	*UNIVARIATE MODELS BATCH 4
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_univariable_cox_models.do" `outcome' ///
		other_immunosuppression				///
		other_neuro 						///
		ra_sle_psoriasis 					///  
		smoke  								///
		smoke_nomiss 						///
		spleen 								///
		stroke_dementia

************************************************************
	*MULTIVARIATE MODELS (this fits the models needed for fully adj col of Table 2)
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_multivariable_cox_models.do" `outcome'

************************************************************
	*SENSITIVITY ANALYSES / POST HOC ANALYSES
************************************************************
	*SMOKING EXPLORATION COX MODELS BATCH 1
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_smoking_exploration_cox_models.do" `outcome' ///
		asthmacat							///
		cancer_exhaem_cat					///
		cancer_haem_cat						///
		chronic_cardiac_disease 			///
		reduced_kidney_function_cat				

	*SMOKING EXPLORATION COX MODELS BATCH 2
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_smoking_exploration_cox_models.do" `outcome' ///
		chronic_liver_disease 				///
		chronic_respiratory_disease 		///
		diabcat								///
		ethnicity 							///
		htdiag_or_highbp					

	*SMOKING EXPLORATION COX MODELS BATCH 3
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_smoking_exploration_cox_models.do" `outcome' ///
		imd 								///
		obese4cat							///
		organ_transplant 					///
		other_immunosuppression				///
		other_neuro 						
		

	*SMOKING EXPLORATION COX MODELS BATCH 4
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_smoking_exploration_cox_models.do" `outcome' ///
		ra_sle_psoriasis 					///  
		smoke  								///
		smoke_nomiss 						///
		spleen 								///
		stroke_dementia	

************************************************************
	*bp EXPLORATION COX MODELS BATCH 1
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_bp_exploration_cox_models.do" `outcome' ///
		asthmacat							///
		cancer_exhaem_cat					///
		cancer_haem_cat						///
		chronic_cardiac_disease 			///
		reduced_kidney_function_cat				

	*bp EXPLORATION COX MODELS BATCH 2
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_bp_exploration_cox_models.do" `outcome' ///
		chronic_liver_disease 				///
		chronic_respiratory_disease 		///
		diabcat								///
		ethnicity 							
							

	*bp EXPLORATION COX MODELS BATCH 3
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_bp_exploration_cox_models.do" `outcome' ///
		imd 								///
		obese4cat							///
		organ_transplant 					///
		other_immunosuppression				///
		other_neuro 						
		

	*bp EXPLORATION COX MODELS BATCH 4
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_bp_exploration_cox_models.do" `outcome' ///
		ra_sle_psoriasis 					///  
		smoke  								///
		smoke_nomiss 						///
		spleen 								///
		stroke_dementia	

************************************************************
		
	*SMOKING ADJUSTED FOR DEMOGRAPHICS; HYPERTENSION-AGE INTERACTION
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_smoke_hypertension_posthoc.do" `outcome'

************************************************************
	*THE NEXT 3 INCLUDE ALL THE MODELLING FOR THE SENS AN APPX TABLE	
	*SENS AN AMONG ETHNICITY CCs	
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_sensan_CCethnicity.do" `outcome'
		
	*SENS AN WITH EARLIER ADMIN CENSORING AT 6th APRIL PRE EFFECT OF LOCKDOWN
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_sensan_earlieradmincensoring.do" `outcome'

	*SENS AN AMONG THOSE WITH RECORDED BMI AND SMOKING ONLY
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_sensan_CCbmiandsmok.do" `outcome'	
************************************************************
	*SENS AN USING DIFFERENT BP MEASURES
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_sensan_differentBPmeasures_dialysis.do" `outcome'
************************************************************
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_checkassumptions.do" `outcome' /*calculates c-stat and Schoenfeld PH test */
************************************************************

}

forvalues i = 1/120{
	sleep 60000
}	

foreach outcome of any cpnsdeath {

	*UNIVARIATE MODELS BATCH 1
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_univariable_cox_models.do" `outcome' ///
		agegroupsex							///
		agesplsex							///
		asthmacat							///
		cancer_exhaem_cat					///
		cancer_haem_cat						///
		chronic_cardiac_disease 			

	*UNIVARIATE MODELS BATCH 2
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_univariable_cox_models.do" `outcome' ///
		reduced_kidney_function_cat				///
		dialysis							///
		chronic_liver_disease 				///
		chronic_respiratory_disease 		///
		diabcat								///
		ethnicity 

	*UNIVARIATE MODELS BATCH 3
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_univariable_cox_models.do" `outcome' ///
		htdiag_or_highbp					///
		 bpcat 								///
		 hypertension						///
		imd 								///
		obese4cat							///
		 bmicat 							///
		organ_transplant 					
		

	*UNIVARIATE MODELS BATCH 4
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_univariable_cox_models.do" `outcome' ///
		other_immunosuppression				///
		other_neuro 						///
		ra_sle_psoriasis 					///  
		smoke  								///
		smoke_nomiss 						///
		spleen 								///
		stroke_dementia

************************************************************
	*MULTIVARIATE MODELS (this fits the models needed for fully adj col of Table 2)
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_multivariable_cox_models.do" `outcome'

}

forvalues i = 1/180{
	sleep 60000
}	

************************************************************
*PARALLEL WORKING - THESE MUST BE RUN AFTER THE 
*MAIN AN_UNIVARIATE.. AND AN_MULTIVARIATE... 
*and AN_SENS... DO FILES HAVE FINISHED
*(THESE ARE VERY QUICK)*
************************************************************
foreach outcome of any onscoviddeath cpnsdeath {
	do "an_tablecontent_HRtable_HRforest.do" `outcome'
	do "an_agesplinevisualisation.do" `outcome'
}

foreach outcome of any onscoviddeath {
do "an_tablecontent_SENSANtable.do" `outcome'
}


*CR CI curves (alt methods)
foreach outcome of any onscoviddeath {
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_descriptive_plots_cr_manualmethod" `outcome'
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_descriptive_plots_cr_thinned" `outcome'
}

**************************************
** MI for ethnicity - run these in parallel
foreach outcome of any onscoviddeath /*cpnsdeath*/ {
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_checkassumptions_3.do" `outcome' 1
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_checkassumptions_3.do" `outcome' 2
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_checkassumptions_3.do" `outcome' 3
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_checkassumptions_3.do" `outcome' 4
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_checkassumptions_3.do" `outcome' 5
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_checkassumptions_3.do" `outcome' 6
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_checkassumptions_3.do" `outcome' 7
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_checkassumptions_3.do" `outcome' 8
winexec "C:\Program Files\Stata16\StataMP-64.exe" 	do "an_checkassumptions_3.do" `outcome' 9
	}

forvalues i = 1/150{
	sleep 60000
}	

**************************************
*run at end, combines imputations and analyses)
foreach outcome of any onscoviddeath {
	do an_checkassumptions_3b `outcome' 
	do an_checkassumptions_3c `outcome'
	}
**************************************/

