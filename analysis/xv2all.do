********************************************************************************
*
*	Do-file:		xv2all.do
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		
*
*	Data created:	
*
*	Other output:	
*
********************************************************************************
*
*	Purpose:		This do-file performs a number of analyses to look at 
*					absolute risks of COVID death and hospitalisation. 
*  
********************************************************************************
*	
*	Stata routines needed:	 stpm2 (which needs rcsgen)	  
*
********************************************************************************


* Graphs of absolute risk for each agegroup

* White, death 
do xv2j1_absolute_risk_model.do 1 death
do xv2j2_graph_absolute_risk_model.do 1 death

* White, hospitalisation
do xv2j1_absolute_risk_model.do 1 hosp
do xv2j2_graph_absolute_risk_model.do 1 hosp


* Graphs of absolute risk over age

* White, death
do xv2j3_absolute_risk_model_fineage.do 1 death
do xv2j4_graph_absolute_risk_model_fineage.do 1 death

* White, hospitalisation
do xv2j3_absolute_risk_model_fineage.do 1 hosp
do xv2j4_graph_absolute_risk_model_fineage.do 1 hosp


* Graphs of absolute risk by ethnicity/comorbidity count

* Death
do xv2j5_absolute_risk_model_fineage_group.do death
do xv2j6_graph_absolute_risk_model_fineage_group.do death

* Hospitalisation
do xv2j5_absolute_risk_model_fineage_group.do hosp
do xv2j6_graph_absolute_risk_model_fineage_group.do hosp


* Obtain HRs for death and hospitalisations

* HRs, White
do xv2j7_hrs.do 1



