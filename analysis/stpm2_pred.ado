*! version 1.2.2 27jul2009

/*
*! with PR mods 14apr2008 & 09mar2009, indicated by !! PR.

*! 12March2009 - changed to using Newton-Raphson method for estimating centiles. 
*! 11March2009 - fixed problem with strings>244 characters for long varlists.
*! Added sdiff1 and sdiff2 options for difference in survival curves.
*! Added hdiff1 and hdiff2 options for difference in survival curves.

*! 23/8/2008 Fixed bug for some predictions involving time-dependent effects.
*! 11/12/2008 Changed to using rcsgen for spline functions.
*/

program stpm2_pred
	version 10.0
	syntax newvarname [if] [in], [Survival Hazard XB XBNOBaseline DXB DZDY HRNumerator(string) HRDenominator(string) MEANSurv ///
									CENtile(string) CUMHazard CUMOdds NORmal MARTingale DEViance DENSity AT(string) ZEROs ///
									noOFFset SDIFF1(string) SDIFF2(string) HDIFF1(string) HDIFF2(string) ///
									CI LEVel(real `c(level)') TIMEvar(varname) STDP PER(real 1) ///
									CENTOL(real 0.0001)]
	marksample touse, novarlist
	local newvarname `varlist'
	qui count if `touse'
	if r(N)==0 {
		error 2000          /* no observations */
	}
	
/* Check Options */
	
	if "`hrdenominator'" != "" & "`hrnumerator'" == "" {
		display as error "You must specifiy the hrnumerator option if you specifiy the hrdenominator option"
		exit 198
	}

	if "`sdiff2'" != "" & "`sdiff1'" == "" {
		display as error "You must specifiy the sdiff1 option if you specifiy the sdiff2 option"
		exit 198
	}

	if "`hdiff2'" != "" & "`hdiff1'" == "" {
		display as error "You must specifiy the hdiff1 option if you specifiy the hdiff2 option"
		exit 198
	}
	
	local hratiotmp = substr("`hrnumerator'",1,1)
	local sdifftmp = substr("`sdiff1'",1,1)
	local hdifftmp = substr("`hdiff1'",1,1)
	if wordcount(`"`survival' `hazard' `meansurv' `hratiotmp' `sdifftmp' `hdifftmp' `centile' `xb' `xbnobaseline' `dxb' `dzdy' `martingale' `deviance' `cumhazard' `cumodds' `normal' `density'"') > 1 {
		display as error "You have specified more than one option for predict"
		exit 198
	}
	if wordcount(`"`survival' `hazard' `meansurv' `hrnumerator' `sdiff1'  `hdifftmp' `centile' `xb' `xbnobaseline' `dxb' `dzdy' `martingale' `deviance' `cumhazard' `cumodds' `normal' `density'"') == 0 {
		display as error "You must specify one of the predict options"
		exit 198
	}
	
	if `per' != 1 & "`hazard'" == "" & "`hdiff1'" == "" {
		display as error "You can only use the per() option in combinaton with the hazard or hdiff1()/hdiff2() options."
		exit 198		
	}

	if "`stdp'" != "" & "`ci'" != "" {
		display as error "You can not specify both the ci and stdp options."
		exit 19
	}
	
	if "`stdp'" != "" & ///
		wordcount(`"`xb' `dxb' `xbnobaseline'"') == 0 {
		display as error "The stdp option can only be used with the xb, dxb and xbnobaseline prediction options."
		exit 198
	}

	if "`ci'" != "" & ///
		wordcount(`"`survival' `hazard' `hrnumerator' `sdiff1' `hdiff1' `centile' `xb' `dxb' `xbnobaseline'"') == 0 {
		display as error "The ci option can not be used with this predict option."
		exit 198
	}
	
	if "`zeros'" != "" & "`meansurv'" != "" {
		display as error "You can not specify the zero option with the meansurv option."
		exit 198
	}

	if "`zeros'" != "" & ("`hrnumerator'" != "" | "`hdiff1'" != "" | "`sdiff1'" != "") {
		display as error "You can not specify the zero option with the hrnumerator, hdiff or sdiff options."
		exit 198
	}

	
	if "`at'" != "" & "`hrnumerator'" != "" {
		display as error "You can not use the at option with the hrnumerator option"
		exit 198
	}

	if "`at'" != "" & "`sdiff1'" != "" {
		display as error "You can not use the at option with the sdiff1 and sdiff2 options"
		exit 198
	}
	
	if "`at'" != "" & "`hdiff1'" != "" {
		display as error "You can not use the at option with the hdiff1 and hdiff2 options"
		exit 198
	}
	
	if "`meansurv'" != "" & ("`ci'" != "") {
		display as error "You can not use the ci option with the meansurv option"
		exit 198
	}
	
/* call stmeancurve if meansurv option specified */
	if "`meansurv'" != "" {
		Stmeancurve `newvarname' if `touse', timevar(`timevar') at(`at') `offset'
		exit
	}

/* calculate midt for centile option */

	summ _t, meanonly
	local midt = (r(max) - r(min))/2
	
/* store time-dependent covariates */
	local etvc `e(tvc)'
		
/* dydx option of old version of stpm */
	if "`dzdy'" != "" {
		local dxb dxb
	}
/* generate ocons for use when orthogonalising splines */
	tempvar ocons
	gen `ocons' = 1
	
/* Use _t if option timevar not specified */
	tempvar t lnt 
	if "`timevar'" == "" {
		qui gen double `t' = _t if `touse'
		qui gen double `lnt' = ln(_t) if `touse'
	}
	else {
		qui gen double `t' = `timevar' if `touse'
		qui gen double `lnt' = ln(`timevar') if `touse'
	}
	
/* Check to see if nonconstant option used */
	if "`e(noconstant)'" == "" {
		tempvar cons
		qui gen `cons' = 1 if `touse'
	}	

/* Preserve data for out of sample prediction  */	
	tempfile newvars 
	tempname merge
	preserve

/* Calculate new spline terms if timevar option specified */
	if "`timevar'" != "" {
		capture drop _rcs* _d_rcs*
		qui rcsgen `lnt' if `touse', knots(`e(ln_bhknots)') gen(_rcs) dgen(_d_rcs)
		if "`e(orthog)'" != "" {
			mata st_store(.,tokens(st_global("e(rcsterms_base)")),"`touse'",(st_data(.,(tokens(st_global("e(rcsterms_base)") + " `ocons'" )),"`touse'")*luinv(st_matrix("e(R_bh)")))[,1..`e(dfbase)'])							
			mata st_store(.,tokens(st_global("e(drcsterms_base)")),"`touse'",(st_data(.,(tokens(st_global("e(drcsterms_base)"))),"`touse'")*luinv(st_matrix("e(R_bh)"))[1..`e(dfbase)',1..`e(dfbase)'])[,1..`e(dfbase)'])
		}
	}
	
/* calculate new spline terms if timevar option or hrnumerator option is specified */

	if "`timevar'" != "" | "`hrnumerator'" != "" | "`sdiff1'" != "" | "`hdiff1'" != "" {
		foreach tvcvar in `e(tvc)' {
			if ("`hrnumerator'" != "" | "`sdiff1'" != "" | "`hdiff1'" != "") & "`timevar'" == ""{
				capture drop _rcs_`tvcvar'* _d_rcs_`tvcvar'*
			}
			qui rcsgen `lnt' if `touse',  gen(_rcs_`tvcvar') knots(`e(ln_tvcknots_`tvcvar')') dgen(_d_rcs_`tvcvar')
			if "`e(orthog)'" != "" {
				mata st_store(.,tokens(st_global("e(rcsterms_`tvcvar')")),"`touse'",(st_data(.,(tokens(st_global("e(rcsterms_`tvcvar')") + " `ocons'" )),"`touse'")*luinv(st_matrix("e(R_`tvcvar')")))[,1..`e(df_`tvcvar')'])							
				mata st_store(.,tokens(st_global("e(drcsterms_`tvcvar')")),"`touse'",(st_data(.,(tokens(st_global("e(drcsterms_`tvcvar')"))),"`touse'")*luinv(st_matrix("e(R_`tvcvar')"))[1..`e(df_`tvcvar')',1..`e(df_`tvcvar')'])[,1..`e(df_`tvcvar')'])
			}

			if "`hrnumerator'" == "" & "`sdiff1'"  == "" & "`hdiff1'" == "" {
				forvalues i = 1/`e(df_`tvcvar')'{
					qui replace _rcs_`tvcvar'`i' = _rcs_`tvcvar'`i'*`tvcvar' if `touse'
					qui replace _d_rcs_`tvcvar'`i' = _d_rcs_`tvcvar'`i'*`tvcvar' if `touse'
				}
			}

		}
	}	
	
/* zeros */
	if "`zeros'" != "" {
		foreach var in `e(varlist)' {
			if `"`: list posof `"`var'"' in at'"' == "0" { 
				qui replace `var' = 0 if `touse'
				foreach tvcvar in `e(tvc)' {
					forvalues i = 1/`e(df_`tvcvar')' {
						qui replace _rcs_`tvcvar'`i' = 0 if `touse'
						qui replace _d_rcs_`tvcvar'`i' = 0 if `touse'
					}
				}
			}
		}
	}

/* Out of sample predictions using at() */
	if "`at'" != "" {
		tokenize `at'
		while "`1'"!="" {
			unab 1: `1'
			cap confirm var `2'
			if _rc {
				cap confirm num `2'
				if _rc {
					di in red "invalid at(... `1' `2' ...)"
					exit 198
				}
			}
			qui replace `1' = `2' if `touse'
			if `"`: list posof `"`1'"' in etvc'"' != "0" {
				local tvcvar `1'
				capture drop _rcs_`tvcvar'* _d_rcs_`tvcvar'*
				qui rcsgen `lnt' if `touse', knots(`e(ln_tvcknots_`tvcvar')') gen(_rcs_`tvcvar') dgen(_d_rcs_`tvcvar')
				if "`e(orthog)'" != "" {
					mata st_store(.,tokens(st_global("e(rcsterms_`tvcvar')")),"`touse'",(st_data(.,(tokens(st_global("e(rcsterms_`tvcvar')") + " `ocons'" )),"`touse'")*luinv(st_matrix("e(R_`tvcvar')")))[,1..`e(df_`tvcvar')'])							
					mata st_store(.,tokens(st_global("e(drcsterms_`tvcvar')")),"`touse'",(st_data(.,(tokens(st_global("e(drcsterms_`tvcvar')"))),"`touse'")*luinv(st_matrix("e(R_`tvcvar')"))[1..`e(df_`tvcvar')',1..`e(df_`tvcvar')'])[,1..`e(df_`tvcvar')'])
				}
				forvalues i = 1/`e(df_`tvcvar')'{
					qui replace _rcs_`tvcvar'`i' = _rcs_`tvcvar'`i'*`tvcvar' if `touse'
					qui replace _d_rcs_`tvcvar'`i' = _d_rcs_`tvcvar'`i'*`tvcvar' if `touse'
				}
			}
			mac shift 2
		}
	}
	
/* Add offset term if exists unless no offset option is specified */
	if "`e(offset1)'" !=  "" & /* !! PR */ "`offset'" != "nooffset" {
		local addoff "+ `e(offset1)'" 
	}

/* check ci and stdp options */
	if "`ci'" != "" & "`stdp'" != "" {
		display as error "Only one of the ci and se options can be specified"
		exit 198
	}
	
/* Deviance and Martingale Residuals */
	if "`deviance'" != "" | "`martingale'" != "" {
		tempvar cH res
		qui predict `cH' if `touse', cumhazard timevar(`t') /* !! pr */ `offset'
		gen double `res' = _d - `cH' if `touse'
		if "`deviance'" != "" {
			gen double `newvarname' = sign(`res')*sqrt( -2*(`res' + _d*(ln(_d -`res')))) if `touse'
        }
        else rename `res' `newvarname'
	}
	
/* Cumulative Hazard */
	else if "`cumhazard'" != "" {
		tempvar S
		predict `S' if `touse', s timevar(`t') /* !! pr */ `offset'
		gen `newvarname' = -ln(`S') if `touse'
	}

/* Cumulative Odds */
	else if "`cumodds'" != "" {
		tempvar S
		predict `S' if `touse', s timevar(`t') /* !! pr */ `offset'
		gen `newvarname' = (1 -`S')/`S' if `touse'
	}
	
/* Standard Normal Deviate */
	else if "`normal'" != "" {
		tempvar S
		predict `S' if `touse', s timevar(`t') /* !! pr */ `offset'
		gen `newvarname' = -invnormal(`S') if `touse'
	}
	
/* density */
	else if "`density'" != "" {
		tempvar S h
		predict  `S' if `touse', s timevar(`t') /* !! pr */ `offset'
		predict  `h' if `touse', h timevar(`t') /* !! pr */ `offset'
		gen `newvarname' = `S'*`h' if `touse'
	}	
	
/* linear predictor */	
	else if "`xb'" != "" {
		if "`ci'" != "" {
			local prednlopt ci(`newvarname'_lci `newvarname'_uci)
		}
		else if "`stdp'" != "" {
			local prednlopt se(`newvarname'_se)
		}
		qui predictnl double `newvarname' = xb(xb) `addoff' if `touse', `prednlopt' level(`level')
	}
			
/* derivative of linear predictor */	
	else if "`dxb'" != "" {
		if "`ci'" != "" {
			local prednlopt ci(`newvarname'_lci `newvarname'_uci)
		}
		else if "`stdp'" != "" {
			local prednlopt se(`newvarname'_se)
		}
		qui predictnl double `newvarname' = xb(dxb) if `touse', `prednlopt' level(`level')
	}
/* linear predictor exluding spline terms */
	else if "`xbnobaseline'" != "" {
		if "`ci'" != "" {
			local prednlopt ci(`newvarname'_lci `newvarname'_uci)
		}
		else if "`stdp'" != "" {
			local prednlopt se(`newvarname'_se)
		}
/* commented out for now - ignores the constant (gamma_0) - may be needed later
		if "`e(noconstant)'" == "" {	
			local xbnobhpred [xb][_cons]
		}	
*/
		// !! PR bug fix next 5 lines
		foreach var in `e(varlist)' {
			if "`xbnobhpred'" == "" local xbnobhpred [xb][`var']*`var'
			else local xbnobhpred `xbnobhpred' + [xb][`var']*`var'
			if `"`: list posof `"`var'"' in etvc'"' != "0" {
				forvalues i = 1/`e(df_`var')' {
					local xbnobhpred `xbnobhpred' + [xb][_rcs_`var'`i']*_rcs_`var'`i'
				}
			}
		}
*		if "`e(noconstant)'" != "" {	
*			local xbnobhpred = subinstr("`xbnobhpred'","+","",1) 
*		}
		predictnl double `newvarname' = `xbnobhpred' if `touse', `prednlopt' level(`level')
	}
		
/* Survival Function */
	else if "`survival'" != "" {
		tempvar sxb 
		if "`ci'" != "" {
			tempvar sxb_lci sxb_uci
			local prednlopt ci(`sxb_lci' `sxb_uci')
		}
		if "`e(scale)'" != "theta" {
			qui predictnl double `sxb' = xb(xb) `addoff' if `touse', `prednlopt' level(`level') 
		}
/* predict on ln(-ln S(t)) scale for theta */
		else if "`e(scale)'" == "theta" {
			qui predictnl double `sxb' = ln(ln(exp(xb(ln_theta))*exp(xb(xb)`addoff')+1)/exp(xb(ln_theta))) if `touse', `prednlopt'  level(`level') 		
		}
/* Transform back to survival scale */
		if "`e(scale)'" == "hazard" {
			qui gen double `newvarname' = exp(-exp(`sxb')) if `touse'
			if "`ci'" != "" {
				qui gen `newvarname'_lci = exp(-exp(`sxb_uci'))  if `touse'
				qui gen `newvarname'_uci =  exp(-exp(`sxb_lci')) if `touse'
			}
		}
		else if "`e(scale)'" == "odds" {
			qui gen double `newvarname' = (1 +exp(`sxb'))^(-1) if `touse'
			if "`ci'" != "" {
				qui gen `newvarname'_lci = (1 +exp(`sxb_uci'))^(-1) if `touse'
				qui gen `newvarname'_uci = (1 +exp(`sxb_lci'))^(-1) if `touse'
			}
		}
		else if "`e(scale)'" == "normal" {
			qui gen double `newvarname' = normal(-`sxb') if `touse'
			if "`ci'" != "" {
				qui gen `newvarname'_lci = normal(-`sxb_uci') if `touse'
				qui gen `newvarname'_uci = normal(-`sxb_lci') if `touse' 
			}
		}		
		else if "`e(scale)'" == "theta" {
			qui gen double `newvarname' = exp(-exp(`sxb')) if `touse'
			if "`ci'" != "" {
				qui gen `newvarname'_lci = exp(-exp(`sxb_lci')) if `touse'
				qui gen `newvarname'_uci = exp(-exp(`sxb_uci')) if `touse' 
			}
		}
	}

/* Hazard Function */

	else if "`hazard'" != "" {
		tempvar lnh 
		if "`ci'" != "" {
			tempvar lnh_lci lnh_uci
			local prednlopt ci(`lnh_lci' `lnh_uci')
		}
		if "`e(scale)'" == "hazard" {
			qui predictnl double `lnh' = -ln(`t') + ln(xb(dxb)) + xb(xb) `addoff'  if `touse', `prednlopt' level(`level') 
		}
		if "`e(scale)'" == "odds" {
			qui predictnl double `lnh' = -ln(`t') + ln(xb(dxb)) + (xb(xb)`addoff')  -ln(1+exp(xb(xb)`addoff'))   if `touse', `prednlopt' level(`level') 
		}		
		if "`e(scale)'" == "normal" {
			qui predictnl double `lnh' = -ln(`t') + ln(xb(dxb)) + ln(normalden(xb(xb)`addoff')) - ln(normal(-(xb(xb)`addoff')))   if `touse', `prednlopt' level(`level') 
		}		
		if "`e(scale)'" == "theta" {
			qui predictnl double `lnh' = -ln(`t') + ln(xb(dxb)) + xb(`xb') - ln(exp(xb(ln_theta))*exp(xb(xb)`addoff') + 1)  if `touse', `prednlopt' level(`level') 
		}		

/* Transform back to hazard scale */
		qui gen double `newvarname' = exp(`lnh')*`per' if `touse'
		if "`ci'" != "" {
			qui gen `newvarname'_lci = exp(`lnh_lci')*`per'  if `touse'
			qui gen `newvarname'_uci =  exp(`lnh_uci')*`per' if `touse'
		}
	}
	
/* Predict Hazard Ratio */
	else if "`hrnumerator'" != "" {
		tempvar lhr lhr_lci lhr_uci
		if `"`ci'"' != "" {
			local hazci "ci(`lhr_lci' `lhr_uci')"
		}
		forvalues i=1/`e(dfbase)' {
			local dxb1 `dxb1' [xb][_rcs`i']*_d_rcs`i' 
			local dxb0 `dxb0' [xb][_rcs`i']*_d_rcs`i'
			local xb1_plus `xb1_plus' [xb][_rcs`i']*_rcs`i'
			local xb0_plus `xb0_plus' [xb][_rcs`i']*_rcs`i'
			if `i' != `e(dfbase)' {
				local dxb0 `dxb0' + 
				local dxb1 `dxb1' + 
				local xb1_plus `xb1_plus' +
				local xb0_plus `xb0_plus' +
			}
		}
		tokenize `hrnumerator'
		while "`1'"!="" {
			unab 1: `1'
			cap confirm var `2'
			if _rc {
				if "`2'" == "." {
					local 2 `1'
				}
				else {
					cap confirm num `2'
					if _rc {
						di in red "invalid hrnumerator(... `1' `2' ...)"
						exit 198
					}
				}
			}
			if "`xb10'" != "" & "`2'" != "0" {
				local xb10 `xb10' +
			}
			if "`xb1_plus'" != "" & "`2'" != "0" {
				local xb1_plus `xb1_plus' +
			}
			if "`2'" != "0" {
				local xb10 `xb10' [xb][`1']*`2' 
				local xb1_plus `xb1_plus' [xb][`1']*`2' 
			}
			if `"`: list posof `"`1'"' in etvc'"' != "0" & "`2'" != "0" {
				local dxb1 `dxb1' +
				local xb10 `xb10' +
				local xb1_plus `xb1_plus' +

				forvalues i=1/`e(df_`1')' {
					local dxb1 `dxb1' [xb][_rcs_`1'`i']*_d_rcs_`1'`i'*`2' 
					local xb10 `xb10' [xb][_rcs_`1'`i']*_rcs_`1'`i'*`2'  
					local xb1_plus `xb1_plus' [xb][_rcs_`1'`i']*_rcs_`1'`i'*`2'  
					if `i' != `e(df_`1')' {
						local dxb1 `dxb1' +
						local xb10 `xb10' +
						local xb1_plus `xb1_plus' +
					}
				}
			}
			mac shift 2
		}			

		if "`hrdenominator'" != "" {
			tokenize `hrdenominator'
			while "`1'"!="" {
				unab 1: `1'
				cap confirm var `2'
				if _rc {
					if "`2'" == "." {
						local 2 `1'
					}
					else {
						cap confirm num `2'
						if _rc {
							di in red "invalid denominator(... `1' `2' ...)"
							exit 198
						}
					}
				}
				if "`2'" != "0" {
					local xb10 `xb10' - [xb][`1']*`2'
					local xb0_plus `xb0_plus' + [xb][`1']*`2' 
				}
				if `"`: list posof `"`1'"' in etvc'"' != "0" & "`2'" != "0" {
					local dxb0 `dxb0' +
					local xb10 `xb10' - 
					local xb0_plus `xb0_plus' + 
					forvalues i=1/`e(df_`1')' {
						local dxb0 `dxb0' [xb][_rcs_`1'`i']*_d_rcs_`1'`i'*`2'
						local xb10 `xb10' [xb][_rcs_`1'`i']*_rcs_`1'`i'*`2'
						local xb0_plus `xb0_plus' [xb][_rcs_`1'`i']*_rcs_`1'`i'*`2'
						if `i' != `e(df_`1')' {
							local dxb0 `dxb0' +
							local xb10 `xb10' -
							local xb0_plus `xb0_plus' +
						}
					}
				}
				mac shift 2
			}
		}
		if "`e(noconstant)'" == "" {
			local xb0_plus `xb0_plus' + [xb][_cons]
			local xb1_plus `xb1_plus' + [xb][_cons]
		}

	
		if "`e(scale)'" =="hazard" {
			qui predictnl double `lhr' = ln(`dxb1') - ln(`dxb0') + `xb10' if `touse', `hazci' level(`level')
		}
		else if "`e(scale)'" =="odds" {
			qui predictnl double `lhr' =  	ln(`dxb1') - ln(`dxb0') + `xb10' - ///
											ln(1+exp(`xb1_plus')) + ln(1+exp(`xb0_plus')) ///
											if `touse', `hazci' level(`level')
		}
		else if "`e(scale)'" =="normal" {
			qui predictnl double `lhr' =  	ln(`dxb1') - ln(`dxb0') + ///
											ln(normalden(`xb1_plus')) - ln(normalden(`xb0_plus')) - ///
											ln(normal(-(`xb1_plus'))) + ln(normal(-(`xb0_plus'))) ///
											if `touse', `hazci' level(`level')
		}
		else if "`e(scale)'" =="theta" {
			qui predictnl double `lhr' =  	ln(`dxb1') - ln(`dxb0') + `xb10' ///
											-ln(exp(xb(ln_theta))*exp(`xb1_plus') + 1) + ln(exp(xb(ln_theta))*exp(`xb0_plus') + 1) ///
											if `touse', `hazci' level(`level')
		}
		qui gen double `newvarname' = exp(`lhr') if `touse'
		if `"`ci'"' != "" {
			qui gen double `newvarname'_lci=exp(`lhr_lci')  if `touse'
			qui gen double `newvarname'_uci=exp(`lhr_uci')  if `touse'
		}
	}

/* Predict Difference in Hazard Functions */
	else if "`hdiff1'" != "" {
		if `"`ci'"' != "" {
			local hazci "ci(`newvarname'_lci `newvarname'_uci)"
		}
		forvalues i=1/`e(dfbase)' {
			local dxb1 `dxb1' [xb][_rcs`i']*_d_rcs`i' 
			local dxb0 `dxb0' [xb][_rcs`i']*_d_rcs`i'
			local xb1_plus `xb1_plus' [xb][_rcs`i']*_rcs`i'
			local xb0_plus `xb0_plus' [xb][_rcs`i']*_rcs`i'
			if `i' != `e(dfbase)' {
				local dxb0 `dxb0' + 
				local dxb1 `dxb1' + 
				local xb1_plus `xb1_plus' +
				local xb0_plus `xb0_plus' +
			}
		}
		tokenize `hdiff1'
		while "`1'"!="" {
			unab 1: `1'
			cap confirm var `2'
			if _rc {
				if "`2'" == "." {
					local 2 `1'
				}
				else {
					cap confirm num `2'
					if _rc {
						di in red "invalid hdiff1(... `1' `2' ...)"
						exit 198
					}
				}
			}
			if "`xb1_plus'" != "" & "`2'" != "0" {
				local xb1_plus `xb1_plus' +
			}
			if "`2'" != "0" {
				local xb1_plus `xb1_plus' [xb][`1']*`2' 
			}
			if `"`: list posof `"`1'"' in etvc'"' != "0" & "`2'" != "0" {
				local dxb1 `dxb1' +
				local xb10 `xb10' +
				local xb1_plus `xb1_plus' +

				forvalues i=1/`e(df_`1')' {
					local dxb1 `dxb1' [xb][_rcs_`1'`i']*_d_rcs_`1'`i'*`2' 
					local xb1_plus `xb1_plus' [xb][_rcs_`1'`i']*_rcs_`1'`i'*`2'  
					if `i' != `e(df_`1')' {
						local dxb1 `dxb1' +
						local xb1_plus `xb1_plus' +
					}
				}
			}
			mac shift 2
		}			

		if "`hdiff2'" != "" {
			tokenize `hdiff2'
			while "`1'"!="" {
				unab 1: `1'
				cap confirm var `2'
				if _rc {
					if "`2'" == "." {
						local 2 `1'
					}
					else {
						cap confirm num `2'
						if _rc {
							di in red "invalid hdiff2(... `1' `2' ...)"
							exit 198
						}
					}
				}
				if "`2'" != "0" {
					local xb0_plus `xb0_plus' + [xb][`1']*`2' 
				}
				if `"`: list posof `"`1'"' in etvc'"' != "0" & "`2'" != "0" {
					local dxb0 `dxb0' +
					local xb0_plus `xb0_plus' + 
					forvalues i=1/`e(df_`1')' {
						local dxb0 `dxb0' [xb][_rcs_`1'`i']*_d_rcs_`1'`i'*`2'
						local xb0_plus `xb0_plus' [xb][_rcs_`1'`i']*_rcs_`1'`i'*`2'
						if `i' != `e(df_`1')' {
							local dxb0 `dxb0' +
							local xb0_plus `xb0_plus' +
						}
					}
				}
				mac shift 2
			}
		}
		if "`e(noconstant)'" == "" {
			local xb0_plus `xb0_plus' + [xb][_cons]
			local xb1_plus `xb1_plus' + [xb][_cons]
		}

		if "`e(scale)'" =="hazard" {
			qui predictnl double `newvarname' = (1/`t' * (`dxb1')*exp(`xb1_plus') - 1/`t' * (`dxb0')*exp(`xb0_plus'))*`per' ///
												if `touse', `hazci' level(`level')
		}
		else if "`e(scale)'" =="odds" {
			qui predictnl double `newvarname' =  (1/`t' *(`dxb1')*exp(`xb1_plus')/((1 + exp(`xb1_plus'))) - ///
												1/`t' *(`dxb0')*exp(`xb0_plus')/((1 + exp(`xb0_plus'))))*`per' ///
												if `touse', `hazci' level(`level')
		}
		else if "`e(scale)'" =="normal" {
				qui predictnl double `newvarname' = (1/`t' *(`dxb1')*normalden(`xb1_plus')/normal(-(`xb1_plus')) - /// 
													1/`t' *(`dxb0')*normalden(`xb0_plus')/normal(-(`xb0_plus')))*`per' ///
													if `touse', `hazci' level(`level')
		}
		else if "`e(scale)'" =="theta" {
			qui predictnl double `newvarname' = (1/`t' *((`dxb1')*exp(`xb1_plus'))/((exp([ln_theta][_cons])*exp(`xb1_plus') + 1)) - ///
												1/`t' *((`dxb0')*exp(`xb0_plus'))/((exp([ln_theta][_cons])*exp(`xb0_plus') + 1)))*`per'
												if `touse', `hazci' level(`level')
		}
	}

/* Predict Difference in Survival Curves */
	else if "`sdiff1'" != "" {
		if `"`ci'"' != "" {
			local survdiffci "ci(`newvarname'_lci `newvarname'_uci)"
		}
		forvalues i=1/`e(dfbase)' {
			local xb1_plus `xb1_plus' [xb][_rcs`i']*_rcs`i'
			local xb0_plus `xb0_plus' [xb][_rcs`i']*_rcs`i'
			if `i' != `e(dfbase)' {
				local xb1_plus `xb1_plus' +
				local xb0_plus `xb0_plus' +
			}
		}
		tokenize `sdiff1'
		while "`1'"!="" {
			unab 1: `1'
			cap confirm var `2'
			if _rc {
				if "`2'" == "." {
					local 2 `1'
				}
				else {
					cap confirm num `2'
					if _rc {
						di in red "invalid sdiff1(... `1' `2' ...)"
						exit 198
					}
				}
			}
			if "`xb1_plus'" != "" & "`2'" != "0" {
				local xb1_plus `xb1_plus' +
			}
			if "`2'" != "0" {
				local xb1_plus `xb1_plus' [xb][`1']*`2' 
			}
			if `"`: list posof `"`1'"' in etvc'"' != "0" & "`2'" != "0" {
				local xb1_plus `xb1_plus' +

				forvalues i=1/`e(df_`1')' {
					local xb1_plus `xb1_plus' [xb][_rcs_`1'`i']*_rcs_`1'`i'*`2'  
					if `i' != `e(df_`1')' {
						local xb1_plus `xb1_plus' +
					}
				}
			}
			mac shift 2
		}			

		if "`sdiff2'" != "" {
			tokenize `sdiff2'
			while "`1'"!="" {
				unab 1: `1'
				cap confirm var `2'
				if _rc {
					if "`2'" == "." {
						local 2 `1'
					}
					else {
						cap confirm num `2'
						if _rc {
							di in red "invalid sdiff2(... `1' `2' ...)"
							exit 198
						}
					}
				}
				if "`2'" != "0" {
					local xb0_plus `xb0_plus' + [xb][`1']*`2' 
				}
				if `"`: list posof `"`1'"' in etvc'"' != "0" & "`2'" != "0" {
					local xb0_plus `xb0_plus' + 
					forvalues i=1/`e(df_`1')' {
						local xb0_plus `xb0_plus' [xb][_rcs_`1'`i']*_rcs_`1'`i'*`2'
						if `i' != `e(df_`1')' {
							local xb0_plus `xb0_plus' +
						}
					}
				}
				mac shift 2
			}
		}
		if "`e(noconstant)'" == "" {
			local xb0_plus `xb0_plus' + [xb][_cons]
			local xb1_plus `xb1_plus' + [xb][_cons]
		}

		if "`e(scale)'" =="hazard" {
			qui predictnl double `newvarname' = exp(-exp(`xb1_plus')) - exp(-exp(`xb0_plus')) if `touse', `survdiffci' level(`level')
		}
		else if "`e(scale)'" =="odds" {
			qui predictnl double `newvarname' =  	1/(exp(`xb1_plus')+1) - 1/(exp(`xb0_plus')+1) if `touse', `survdiffci' level(`level')
		}
		else if "`e(scale)'" =="normal" {
			qui predictnl double `newvarname' =  	normal(-(`xb1_plus')) - normal(-(`xb0_plus')) if `touse', `survdiffci' level(`level')
		}
		else if "`e(scale)'" =="theta" {
			qui predictnl double `newvarname' =  	(exp([ln_theta][_cons])*exp(`xb1_plus') + 1)^(-1/exp([ln_theta][_cons])) ///
											-(exp([ln_theta][_cons])*exp(`xb0_plus') + 1)^(-1/exp([ln_theta][_cons])) ///
											if `touse', `hazci' level(`level')
		}
	}

	
/* Predicted survival time for a given centile */
/* Estimated using Newton-Raphson alogorithm (updated from ridder method in version 1.2.2) */
	else if "`centile'" != "" {
/* transform to appropriate scale */
		tempvar transcent centilevar
		
		gen `centilevar' = 1 - `centile'/100 if `touse'
		if "`e(scale)'" == "hazard" {
			qui gen double `transcent' = ln(-ln(`centilevar')) if `touse'
		}
		else if "`e(scale)'" == "odds" {
			qui gen double `transcent' = ln(1/`centilevar'-1) if `touse'
		}
		else if "`e(scale)'" == "normal" {
			qui gen double `transcent' = -invnorm(`centilevar') if `touse'
		}
		else if "`e(scale)'" == "theta" {
			qui gen double `transcent' = ln((`centilevar'^(-exp([ln_theta][_cons]))-1)/exp([ln_theta][_cons])) if `touse'
		}
		
/* initial values */	
		
		tempvar tmpxb nr_time nr_time_old nr_xb nr_dxb maxerr 
		qui gen double `nr_time' = `midt'
		qui gen double `nr_time_old' = `nr_time' if `touse'
		
/* loop */
		local done 0
		while !`done' {
			qui predict `nr_xb' if `touse', xb timevar(`nr_time_old') `offset'
			qui predict `nr_dxb' if `touse', dxb timevar(`nr_time_old')
			qui replace `nr_time' = exp(ln(`nr_time_old') - (`nr_xb' - `transcent')/`nr_dxb') if `touse'
			qui gen double `maxerr' = abs(`nr_time' - `nr_time_old') if `touse'
			summ `maxerr' if `touse', meanonly
			if r(max)<`centol' {
				local done 1
			}
			else {
				drop `nr_xb' `nr_dxb' `maxerr'
				qui replace `nr_time_old' = `nr_time' if `touse'
			}
		}
		
		qui gen double `newvarname' = `nr_time' if `touse'


		if "`ci'" != "" {
			tempvar lnln_s lnln_s_se h tp_se
			drop _rcs*
			drop _d_rcs*
			tempvar ln_nr_time
			qui gen double `ln_nr_time' = ln(`nr_time') if `touse'
			qui rcsgen `ln_nr_time'  if `touse', knots(`e(ln_bhknots)') gen(_rcs) dgen(_d_rcs)
			unab rcsterms :_rcs*		
			unab drcsterms :_d_rcs*		
			if "`e(orthog)'" != "" {
				mata st_store(.,tokens(st_local("rcsterms")),"`touse'",(st_data(.,tokens(st_local("rcsterms") +" `ocons'"),"`touse'")*luinv(st_matrix("e(R_bh)")))[,1..`e(dfbase)'])
				mata st_store(.,tokens(st_local("drcsterms")),"`touse'",(st_data(.,tokens(st_local("drcsterms")),"`touse'")*luinv(st_matrix("e(R_bh)"))[1..`e(dfbase)',1..`e(dfbase)']))
			}

			foreach tvcvar in `e(tvc)' {
				if `e(df_`tvcvar')' == 1 {
					qui rcsgen `ln_nr_time' if `touse',   gen(_rcs_`tvcvar') dgen(_d_rcs_`tvcvar') 
				}
				else if `e(df_`tvcvar')' != 1 {
					qui rcsgen `ln_nr_time' if `touse', knots(`e(ln_tvcknots_`tvcvar')') gen(_rcs_`tvcvar') dgen(_d_rcs_`tvcvar')
				}

				unab rcsterms_`tvcvar' : _rcs_`tvcvar'*
				unab drcsterms_`tvcvar' : _d_rcs_`tvcvar'*		

				if "`e(orthog)'" != "" {		
					mata st_store(.,tokens(st_global("e(rcsterms_`tvcvar')")),"`touse'",(st_data(.,(tokens(st_global("e(rcsterms_`tvcvar')") + " `ocons'" )),"`touse'")*luinv(st_matrix("e(R_`tvcvar')")))[,1..`e(df_`tvcvar')'])							
					mata st_store(.,tokens(st_global("e(drcsterms_`tvcvar')")),"`touse'",(st_data(.,(tokens(st_global("e(drcsterms_`tvcvar')"))),"`touse'")*luinv(st_matrix("e(R_`tvcvar')"))[1..`e(df_`tvcvar')',1..`e(df_`tvcvar')'])[,1..`e(df_`tvcvar')'])
				}
				
				forvalues k = 1/`e(df_`tvcvar')' {
					qui replace _rcs_`tvcvar'`k' = _rcs_`tvcvar'`k' * `tvcvar' if `touse'
					qui replace _d_rcs_`tvcvar'`k' = _d_rcs_`tvcvar'`k' * `tvcvar' if `touse'
				}
			}	

			if "`e(scale)'" == "hazard" {
				qui predictnl double `lnln_s' = xb(xb)`addoff' if `touse', se(`lnln_s_se') 
			}
			else if "`e(scale)'" == "odds" {
				qui predictnl double `lnln_s' = ln(ln(1+exp(xb(xb)`addoff'))) if `touse', se(`lnln_s_se')
			}
			
			else if "`e(scale)'" == "normal" {
				qui predictnl double `lnln_s' = ln(-ln(normal(xb(xb)`addoff'))) if `touse', se(`lnln_s_se') 
			}
			
			else if "`e(scale)'" == "theta" {
				qui predictnl double `lnln_s' = ln(ln(exp(xb(ln_theta))*exp(xb(xb)`addoff')+1)/exp(xb(ln_theta))) if `touse', se(`lnln_s_se')
			}
			
			if "`e(scale)'" == "hazard" {
				qui predictnl double `h'=(1/(`newvarname'))*(xb(dxb))*exp(xb(xb)`addoff') if `touse' 
			}
			else if "`e(scale)'" == "odds" {
				qui predictnl double `h'=1/(`newvarname')*(xb(dxb))*exp(xb(xb)`addoff')/(1+exp(xb(xb)`addoff')) if `touse'
			}
			else if "`e(scale)'" == "normal" {
				qui predictnl double `h'=1/(`newvarname')*(xb(dxb))*normalden(xb(xb)`addoff')/(normal(-(xb(xb)`addoff'))) if `touse' 
			}
			else if "`e(scale)'" == "theta" {
				qui predictnl double `h'=1/(`newvarname')*(xb(dxb))*exp(xb(xb)`addoff')/(exp(xb(ln_theta))*exp(xb(xb)`addoff') + 1) if `touse' 
			}
			tempvar s_tp
			predict  `s_tp' if `touse', s `offset'
			qui replace `s_tp' = ln(`s_tp') if `touse'
			qui gen double `tp_se' = `s_tp'*`lnln_s_se'/`h' if `touse'

			qui gen double `newvarname'_lci = `newvarname' - invnormal(1-0.5*(1-`level'/100))*`tp_se' if `touse'
			qui gen double `newvarname'_uci = `newvarname' + invnormal(1-0.5*(1-`level'/100))*`tp_se' if `touse'
		}	
	}
	
/* restore original data and merge in new variables */
	local keep `newvarname'
	if "`ci'" != "" { 
		local keep `keep' `newvarname'_lci `newvarname'_uci
	}
	else if "`stdp'" != "" {
		local keep `keep' `newvarname'_se 
	}
	keep `keep'
	qui save `newvars'
	restore
	merge using `newvars', _merge(`merge')
end




/* meansurv added to stpm2_pred as sub program */
* 10March2009 - added averages for models on odds, probit or theta scales.

program Stmeancurve, sortpreserve 
	version 10.0
	syntax newvarname [if] [in],[TIMEvar(varname) AT(string) noOFFSET] 
	marksample touse, novarlist
	local newvarname `varlist'

	tempvar t lnt touse_time
		
	preserve
	
	/* use timevar option or _t */
	if "`timevar'" == "" {
		qui gen `t' = _t if `touse'
		qui gen double `lnt' = ln(_t) if `touse'
	}
		else {
		qui gen double `t' = `timevar' if `touse'
		qui gen double `lnt' = ln(`timevar') if `touse'
	}
	
	/* generate ocons for use when orthogonalising splines */
	tempvar ocons
	gen `ocons' = 1

	/* Calculate new spline terms */
	if "`timevar'" != "" {
		drop _rcs* _d_rcs*
		qui rcsgen `lnt' if `touse', knots(`e(ln_bhknots)') gen(_rcs)
		if "`e(orthog)'" != "" {
			mata st_store(.,tokens(st_global("e(rcsterms_base)")),"`touse'",(st_data(.,(tokens(st_global("e(rcsterms_base)") + " `ocons'" )),"`touse'")*luinv(st_matrix("e(R_bh)")))[,1..`e(dfbase)'])							
		}
	}
	
	if "`e(tvc)'" != "" {
         capture drop _rcs_* 
    }
 
	foreach tvcvar in `e(tvc)' {
		qui rcsgen `lnt' if `touse',  gen(_rcs_`tvcvar') knots(`e(ln_tvcknots_`tvcvar')')
		if "`e(orthog)'" != "" {
			mata st_store(.,tokens(st_global("e(rcsterms_`tvcvar')")),"`touse'",(st_data(.,(tokens(st_global("e(rcsterms_`tvcvar')") + " `ocons'" )),"`touse'")*luinv(st_matrix("e(R_`tvcvar')")))[,1..`e(df_`tvcvar')'])							
		}
	}
	
	/* index which time units are selected */
	gen `touse_time' = `t' != .
	
	/* Out of sample predictions using at() */
	if "`at'" != "" {
		tokenize `at'
		while "`1'"!="" {
			unab 1: `1'
			cap confirm var `2'
			if _rc {
				cap confirm num `2'
				if _rc {
					di in red "invalid at(... `1' `2' ...)"
					exit 198
				}
			}
			qui replace `1' = `2' if `touse'
			mac shift 2
		}
	}

	
	foreach tvcvar in `e(tvc)' {
		local rcstvclist `rcstvclist' `e(rcsterms_`tvcvar')'
	}

	if "`e(scale)'" == "theta" {
		local theta = exp([ln_theta][_cons])
	}
	
	mata: msurvpop("`newvarname'","`touse'","`touse_time'","`rcstvclist'")

/* restore original data and merge in new variables */
	local keep `newvarname'
	if "`ci'" != "" { 
		local keep `keep' `newvarname'_lci `newvarname'_uci
	}
	else if "`stdp'" != "" {
		local keep `keep' `newvarname'_se 
	}
	keep `keep'
	tempfile newvars
	qui save `newvars'
	restore
	tempvar merge
	merge using `newvars', _merge(`merge')
end


mata:
void msurvpop(string scalar newvar, string scalar touse, string scalar touse_time, string scalar tvcrcslist) 
{
/* Transfer data from Stata */
	rcsbase = st_data( ., tokens(st_global("e(rcsterms_base)")), touse_time)
	rcstvc = st_data( ., tokens(tvcrcslist), touse_time)
	x = st_data(.,tokens(st_global("e(varlist)")),touse)
	tvcvar = tokens(st_global("e(tvc)"))
	ntvc = cols(tvcvar)
	beta = st_matrix("e(b)")'[1..cols(rcsbase)+cols(rcstvc) + cols(tokens(st_global("e(varlist)"))) + 1,1]
	
	scale = st_global("e(scale)")
	if (scale == "theta") theta = strtoreal(st_local("theta"))

/*	check whether to include offset */
	offset_name = st_global("e(offset1)")
	if (offset_name != "" & st_local("offset") != "nooffset") offset = st_data(.,offset_name,touse)
	else offset = 0


	startstop = J(ntvc,2,.)
	tvcpos = J(ntvc,1,.)
	tmpstart = 1

/* Loop over number of time observations */
	for (i=1;i<=ntvc;i++){
		startstop[i,1] = tmpstart
		tmpntvc = cols(tokens(st_global("e(rcsterms_"+tvcvar[1,i]+")")))
		startstop[i,2] = tmpstart + tmpntvc - 1
		tmpstart = startstop[i,2] + 1

		pos = .	
		maxindex(tvcvar[1,i]:==tokens(st_global("e(varlist)")),1,pos,.)
		tvcpos[i,1] = pos
	}
		
	Nx = rows(x)
	Nt = rows(rcsbase)

/* Loop over all selected observations */	
	meansurv = J(Nt,1,0)
	for (i=1;i<=Nx;i++) {
		tmprcs = J(Nt,0,.)
		for (j=1;j<=ntvc;j++) {
			tmprcs = tmprcs, rcstvc[,startstop[j,1]..startstop[j,2]]:*	x[i,tvcpos[j,1]]
		}
		if (scale == "hazard")	meansurv = meansurv + exp(-exp((J(Nt,1,x[i,]),rcsbase, tmprcs,J(Nt,1,1))*beta :+ offset)):/Nx
		else if (scale == "odds")	meansurv = meansurv + ((1 :+ exp((J(Nt,1,x[i,]),rcsbase, tmprcs,J(Nt,1,1))*beta :+ offset)):^(-1)):/Nx
		else if (scale == "normal")	meansurv = meansurv + normal(-(J(Nt,1,x[i,]),rcsbase, tmprcs,J(Nt,1,1))*beta :+ offset):/Nx
		else if (scale == "theta")	meansurv = meansurv + ((theta:*exp((J(Nt,1,x[i,]),rcsbase, tmprcs,J(Nt,1,1))*beta :+ offset) :+ 1):^(-1/theta)):/Nx
	}

	(void) st_addvar("double",newvar)
	st_store(., newvar, touse_time,meansurv)
}	
end

	
