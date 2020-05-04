********************************************************************************
*
*	Do-file:		an_checkassumptions_3b.do
*
*	Project:		Risk factors for poor outcomes in Covid-19; Ethnicity MNAR
*
*	Programmed by:	Elizabeth Williamson
*
*	Data used:		imputed_i.dta  (i=1,2,...,9, one per region, imputed data)
*
*	Data created:	imputed.dta  (all imputed data)
*
*	Other output:	Log file output/an_checkassumptions_MI_combine
*
********************************************************************************
*
*	Purpose:		This do-file fits a sensitivity analysis for missing 
*					ethnicity, using multiple imputation incorporating 
*					information from external data sources (e.g. census)
*					about the marginal proportions of ethnic groups 
*					within broad geographical regions. 
*  
********************************************************************************




* Open a log file
capture log close
log using "output/an_checkassumptions_MI_combine", text replace



********************************   NOTES  **************************************

*  Assumes region is string, taking  values: 
*    East, East Midlands, London, North East, North West, South East, 
*    South West, West Midlands, and Yorkshire and The Humber
*
*  Assumes ethnicity is numeric, taking values: 
*	1, 2, 3, 4, 5, (missing: . or .u)
*	in the order White, Black, Asian, Mixed, Other
*	with value labels exactly as above. 
*	(NB: this is now intially recoded from ordering: 
*      White, Mixed, Asian, Black, Other)	
*
*
*  Assumes a complete case sample other than ethnicity
*
********************************************************************************




**************************
*  Combine imputed data  *
**************************

* Put imputed data together (across regions)
use imputed_1.dta, clear
forvalues k= 2 (1) 9	{
append using imputed_`k'
}
save imputed, replace
forvalues k= 1 (1) 9	{
*erase imputed_`k'.dta
}


log close




	