********************************************************************************
*
*	Do-file:		an_smoking_exploration_cox_models.do
*
*	Project:		Risk factors for poor outcomes in Covid-19
*
*	Programmed by:	Fizz & Krishnan
*
*	Data used:		cr_create_analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Log file: an_smok_exp_cox_models.log 
*
*
********************************************************************************
*
*	Purpose:		Fit age/sex adjusted Cox models for smoking, 
* 					adjusted for each other risk factor indivivually
*				(Post hoc analysis to explore drivers of confounding 
*				of smoking effect)
*  
********************************************************************************

*PARSE DO-FILE ARGUMENTS (first should be outcome, rest should be variables)
local arguments = wordcount("`0'") 
local outcome `1'
local varlist
forvalues i=2/`arguments'{
	local varlist = "`varlist' " + word("`0'", `i')
	}
local firstvar = word("`0'", 2)
local lastvar = word("`0'", `arguments')
	

* Open a log file
capture log close
log using "./output/an_smoking_exploration_cox_models_`outcome'_`firstvar'TO`lastvar'", text replace

* Open dataset and fit specified model(s)
use "cr_create_analysis_dataset_STSET_`outcome'.dta", clear


foreach var of any `varlist' {

	*General form of model
	local model "age1 age2 age3 i.male i.`var' i.smoke"

	*Fit and save model
	cap erase ./output/models/an_smok_exp_cox_models_`outcome'_AGESEX_`var'.ster
	capture stcox `model' , strata(stp) 
	if _rc==0 {
		estimates
		estimates save ./output/models/an_smoking_exploration_cox_models_`outcome'_AGESEX_`var', replace
		}
	else di "WARNING - `var' vs `outcome' MODEL DID NOT SUCCESSFULLY FIT"

}


* Close log file
log close
