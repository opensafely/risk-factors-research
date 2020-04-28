********************************************************************************
*
*	Do-file:		Calibration_parameter_estimation.do
*
*	Project:		Risk factors for poor outcomes in Covid-19; Ethnicity MNAR
*
*	Programmed by:	Fizz
*
*	Data used:		None
*
*	Data created:	None
*
*	Other output:	User-written programs:  count_missing and prop_ethnicity
*
********************************************************************************
*
*	Purpose:		This do-file creates programs which count the proportion 
*					of missing ethnicity data, and the proportion in each group
*					in the complete case data. 
*
*					It then draws these parameters from their posterior 
*					predictive distributions. 
*
*	ASSUMPTIONS:	This is a complete case sample, other than ethnicity.
*					Ethnicity is White, Black, Asian, Mixed, other
*					(same order, coding (1, 2, 3, 4, 5), labelling)
*  
********************************************************************************




***************************************************
*  Observed and drawn proportions of missingness  *
***************************************************


capture program drop count_missing
program define count_missing, rclass
	syntax varname
	
	
	/* 	Number of patients with missing ethnicity  */

	* Overall
	qui count if `varlist' == 0 
	local Nmis = r(N)
	qui count if `varlist' == 1
	local Nobs = r(N)

	
	/*  Draw probability of observing ethnicity  */


	* Sample proportion of observed ethnicity
	qui count if `varlist' == 0
	local r0 = r(N)/_N
	local se_r0 = sqrt((`r0'*(1-`r0'))/_N)

	** Draw probability from the normal approximation
	** whose mean is the sample proportion of observed ethnicities
	local r0star = rnormal(`r0', `se_r0')
	local r1star = 1-`r0star'


	/*  Return probabilities  */
	
	* Observed proportions
	return scalar Nmis = `Nmis'
	return scalar Nobs = `Nobs'
	
	* Drawn probabilities 
	return scalar r0star = `r0star'
	return scalar r1star = `r1star'

	
	/*  Display results  */
	
	noi di _n "Observed proportions:"
	
	noi di _col(10) "Number Missing:   " `Nmis'
	noi di _col(10) "Number Observed:  " `Nobs'
	
	noi di _n "Drawn probabilities:"
	
	noi di _col(10)  "P(Missing):        " `r0star'
	noi di _col(10)  "P(Observed):       " `r1star'
	
end
	
	
	
	
***************************************************************
*  Observed and drawn proportions of each ethnicity category  *
***************************************************************


capture program drop prop_ethnicity
program define prop_ethnicity, rclass
	syntax varname
	
	* Check there are 4 categories
	assert inlist(`varlist', 1, 2, 3, 4, 5, ., .u)
	
	* Count number of observations
	qui count if `varlist'<.
	local nobs = r(N)
	
	/*  Draw probability of each ethnicity category  */ 

	* Pick up observed proportions of each ethnicity (in complete cases)
	prop `varlist'	
	mat def Eth_m = r(table)

	** Draw probability from the normal approximation
	** whose mean is the corresponding observed proportion of each category
	forvalues i = 2 (1) 5 {
	    local j = `i' - 1
		local Eth`j'obs = Eth_m[1,`i']
		local se_Eth`j'obs = sqrt((`Eth`j'obs'*(1-`Eth`j'obs'))/(`nobs'))
		local Eth`j'obsstar = rnormal(`Eth`j'obs', `se_Eth`j'obs')
	}
	matrix drop Eth_m
	

	/*  Return probabilities  */
	
	* Observed proportions
	return scalar Eth1obs = `Eth1obs'
	return scalar Eth2obs = `Eth2obs'
	return scalar Eth3obs = `Eth3obs'
	return scalar Eth4obs = `Eth4obs'
	
	* Drawn probabilities 
	return scalar Eth1obsstar = `Eth1obsstar'
	return scalar Eth2obsstar = `Eth2obsstar'
	return scalar Eth3obsstar = `Eth3obsstar'
	return scalar Eth4obsstar = `Eth4obsstar'

	
	/*  Display results  */
	
	noi di _n "Observed proportions of each ethnic group:"
	
	noi di _col(10) "Proportion Black:   " `Eth1obs'
	noi di _col(10) "Proportion Asian:   " `Eth2obs'
	noi di _col(10) "Proportion Mixed:   " `Eth3obs'
	noi di _col(10) "Proportion Other:   " `Eth4obs'
	
	noi di _n "Drawn probabilities of each ethnic group:"
	
	noi di _col(10)  "P(Black | r=1):  " `Eth1obsstar'
	noi di _col(10)  "P(Asian | r=1):  " `Eth2obsstar'
	noi di _col(10)  "P(Mixed | r=1):  " `Eth3obsstar'
	noi di _col(10)  "P(Other | r=1):  " `Eth4obsstar'

end



