********************************************************************************
*
*	Do-file:		Calibration_parameter_nlsolution.do
*
*	Project:		Risk factors for poor outcomes in Covid-19; Ethnicity MNAR
*
*	Programmed by:	Fizz
*
*	Data used:		None
*
*	Data created:	None
*
*	Other output:	User-written program:  nlnle2 and a wrapper, nlnle2_wrap
*
********************************************************************************
*
*	Purpose:		This do-file creates a program whose purpose is to solve
*					a specific set of non-linear equations.
*  
********************************************************************************
*	
*	Input parameters: The following globals need to be defined:
*
*		Number missing ethnicity, $Nmis 
*		Probability of missing/observing ethnicity, $r0star and $r1star
*		Probability of each ethnicity among observed, $Eth1obsstar, 
*						$Eth2obsstar, $Eth3obsstar, $Eth4obsstar
*		Marginal probability of ethnicity (external data), $Eth1, $Eth2, $Eth3, $Eth4
*
*	Input variables: The following variables need to be in memory:
*
*		r - indicator of Ethnicity being observed (1=yes, 0=no)
*		lp1 - linear predictor from mlogit model to impute ethnicity among r=1, Black
*		lp2 - linear predictor from mlogit model to impute ethnicity among r=1, Asian
*		lp3 - linear predictor from mlogit model to impute ethnicity among r=1, Mixed
*		lp4 - linear predictor from mlogit model to impute ethnicity among r=1, Other
*
*
*	ASSUMPTIONS:	This is a complete case sample, other than ethnicity.
*					Ethnicity is White, Black, Asian, Mixed, other
*					(same order, coding (1, 2, 3, 4, 5), labelling)
*  
********************************************************************************


********************************************************************************
*	
*	To run alone:	
*			matrix mat = (1,0,0,0)
*			nlnle2 y lp1 lp2 lp3 lp4 r, at(mat)
*
*	Use in MI process:
*			nl nle2 @ y lp1 lp2 lp3 lp4 ethnicity, ///
*					parameters(A B C D) initial(A 2 B 2 C 2 D 2)
*
********************************************************************************


*******************************************
*  Program to solve non-linear equations  *
*******************************************


cap prog drop nlnle2
program nlnle2
syntax varlist(min=6 max=6) [if], at(name)

	* Pick up inputs
	tokenize `varlist'
	local y   `1'
	local lp1 `2'
	local lp2 `3'
	local lp3 `4'
	local lp4 `5'
	local r   `6'
	
	* Pick up current parameter values (Black/Asian/Mixed/Other, respectively)
	tempname A B C D
	scalar `A' = `at'[1, 1]
	scalar `B' = `at'[1, 2]
	scalar `C' = `at'[1, 3]
	scalar `D' = `at'[1, 4]

	tempvar yh t1 t2 t3 t4 denom
	
	* Linear predictor among those missing ethnicity
	gen `denom' = 1 + exp(`A' + `lp1') + exp(`B' + `lp2') + exp(`C' + `lp3') + exp(`D' + `lp4')
	gen `t1' = exp(`A' + `lp1')/`denom'
	gen `t2' = exp(`B' + `lp2')/`denom'
	gen `t3' = exp(`C' + `lp3')/`denom'
	gen `t4' = exp(`D' + `lp4')/`denom'

	qui summ `t1' if `r'==0
	local t1sum=r(sum)
	qui summ `t2' if `r'==0
	local t2sum=r(sum)
	qui summ `t3' if `r'==0
	local t3sum=r(sum)
	qui summ `t4' if `r'==0
	local t4sum=r(sum)
	
	* Set equal to marginal expression (using external data)
	gen double 	`yh' = 	`t1sum'*$r0star/$Nmis + $Eth1obsstar*$r1star - $Eth1 + 1 in 1
	replace 	`yh' = 	`t2sum'*$r0star/$Nmis + $Eth2obsstar*$r1star - $Eth2 in 2
	replace 	`yh' = 	`t3sum'*$r0star/$Nmis + $Eth3obsstar*$r1star - $Eth3 in 3
	replace 	`yh' = 	`t4sum'*$r0star/$Nmis + $Eth4obsstar*$r1star - $Eth4 in 4

	* Return 4 equations evaluated at current versions of parameter	
	replace `y' = `yh'

end





*******************************
*  Wrapper for program above  *
*******************************


cap prog drop nlnle2_wrap
program nlnle2_wrap, rclass

	* Check inputs are there and print summary

	di _n "INPUTS:" 
	
	di _n "Missingness of ethnicity:"
	di _col(10) "Number missing ethnicity data:   " $Nmis 
	di _col(10) "Probability of missing  (drawn): " $r0star
	di _col(10) "Probability of observed (drawn): " $r1star


	di _n "Drawn proportions (among complete cases):"
	di _col(10)"Black (drawn): " $Eth1obsstar
	di _col(10)"Asian (drawn): " $Eth2obsstar
	di _col(10)"Mixed (drawn): " $Eth3obsstar
	di _col(10)"Other (drawn): " $Eth4obsstar

	di _n "External data:"
	di _col(10) "Black (external): " $Eth1
	di _col(10) "Asian (external): " $Eth2
	di _col(10) "Mixed (external): " $Eth3
	di _col(10) "Other (external): " $Eth4

	* Check linear predictor variables exist
	confirm numeric variable lp1
	confirm numeric variable lp2
	confirm numeric variable lp3
	confirm numeric variable lp4
	   

	* Create variable to house estimation results
	qui gen     y = 1 in 1
	qui replace y = 0 in 2
	qui replace y = 0 in 3
	qui replace y = 0 in 4

	qui nl nle2 @ y lp1 lp2 lp3 lp4 r, ///
		parameters(A B C D) initial(A 2 B 2 C 2 D 2)
	qui drop y 

	* Convert calibration parameters into RR for being observed among r=0 vs r=1
	mat def G = e(b)
	* On logged scale
	local delta1 = G[1,1]
	local delta2 = G[1,2]
	local delta3 = G[1,3]
	local delta3 = G[1,4]
	* On RR scale
	local gamma1 = exp(G[1,1])
	local gamma2 = exp(G[1,2])
	local gamma3 = exp(G[1,3])
	local gamma4 = exp(G[1,4])

	
	/*  Return parameters  */ 
	
	return scalar rr1 = `gamma1'
	return scalar rr2 = `gamma2'
	return scalar rr3 = `gamma3'
	return scalar rr4 = `gamma4'
	
	noi di _n "ESTIMATED CALIBRATION PARAMETERS:  "

	noi di _col(10) "Parameter (log scale):"
	noi di _col(10) "Black:  " `delta1'
	noi di _col(10) "Asian:  " `delta2'
	noi di _col(10) "Mixed:  " `delta3'
	noi di _col(10) "Other:  " `delta4'
	noi di _col(10) "Relative risk (for being this ethnicity (vs white)"
	noi di _col(15) "...in missing cf complete cases):"
	noi di _col(10) "Black:  " `gamma1'
	noi di _col(10) "Asian:  " `gamma2'
	noi di _col(10) "Mixed:  " `gamma3'
	noi di _col(10) "Other:  " `gamma4'
	
end


