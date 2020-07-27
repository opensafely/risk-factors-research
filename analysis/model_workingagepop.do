	
	
*UNIVARIATE MODELS BATCH 1
winexec "c:\program files\stata16\statamp-64.exe" do "an_univariable_cox_models_workingagepop.do" onscoviddeath ///
		agegroupsex							///
		agesplsex							///
		asthmacat							///
		cancer_exhaem_cat					///
		cancer_haem_cat						///
		chronic_cardiac_disease 			

*UNIVARIATE MODELS BATCH 2
winexec "c:\program files\stata16\statamp-64.exe" do "an_univariable_cox_models_workingagepop.do" onscoviddeath ///
		reduced_kidney_function_cat				///
		dialysis							///
		chronic_liver_disease 				///
		chronic_respiratory_disease 		///
		diabcat								///
		ethnicity 

*UNIVARIATE MODELS BATCH 3
winexec "c:\program files\stata16\statamp-64.exe" do "an_univariable_cox_models_workingagepop.do" onscoviddeath ///
		htdiag_or_highbp					///
		 bpcat 								///
		 hypertension						///
		imd 								///
		obese4cat							///
		 bmicat 							///
		organ_transplant 					
		

*UNIVARIATE MODELS BATCH 4
winexec "c:\program files\stata16\statamp-64.exe" do "an_univariable_cox_models_workingagepop.do" onscoviddeath ///
		other_immunosuppression				///
		other_neuro 						///
		ra_sle_psoriasis 					///  
		smoke  								///
		smoke_nomiss 						///
		spleen 								///
		stroke_dementia
		
		
winexec "c:\program files\stata16\statamp-64.exe" do "an_multivariable_cox_models_workingagepop" onscoviddeath

do an_ageinteractions_lt70vsgte70

***************AT END
do an_tablecontent_HRtable_workingagepop.do onscoviddeath