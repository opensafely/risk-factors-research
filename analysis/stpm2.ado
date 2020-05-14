*! version 1.2.2 27jul2009

/*
*! 12 March09: made it possible for varlist for time varying covariates to be greater than 244 characters.
*! PR 09mar09: added e(aic) and e(bic)
*! stpm2 now reports same likelihood as stpm and other parametric models
*! PR 16apr08: -verbose- option added;
*! Added -showcons- option as constraints are not shown by default
*! 11/12/2008 Changed to using rcsgen for spline functions.
*! 23/4/2009 correct waldtest - this is no longer reported
*! 27/4/2009 changed e(aic) and e(bic) to e(AIC) and e(BIC) so can be used with estimates table
*/

program stpm2, eclass byable(onecall)
	version 10.0

	if strpos("`0'","oldstpm") >0 {
		local 0:subinstr local 0 "oldstpm" ""
		stpm `0'
		exit
	}
	if _by() {
		local by "by `_byvars'`_byrc0':"
	}
	if replay() {
		syntax  [, DF(string) KNOTS(numlist ascending) BKNOTS(numlist ascending min=2 max=2) *]
		if "`df'`knots'`bknots'" != "" {
			`by' Estimate `0'
		}
		else {
			if "`e(cmd)'" != "stpm2" {
				error 301
			}
			if _by() {
				error 190
				}
			Replay `0' 
		}	
		exit
	}
	`by' Estimate `0'
	ereturn local cmdline `"stpm2 `0'"'
end

program Estimate, eclass byable(recall)
	st_is 2 analysis	
	syntax  [varlist(default=empty)] [if] [in] ///
	[, DF(string) TVC(varlist) DFTvc(string) KNOTS(numlist ascending) KNOTSTvc(string) ///
		BKnots(numlist ascending min=2 max=2) KNSCALE(string) noORTHog SCale(string) noCONStant ///
		INITTheta(real 1) CONSTheta(string) EForm ALLEQ KEEPCons BHAZard(varname) ///
		LINinit STratify(varlist) THeta(string) OFFset(varname) ///
		/* !! PR */ STPMDF(int 0) VERBose SHOWCons ///
		ALL RMAT ] ///
	[                               ///
	noLOg                           /// -ml model- options
	noLRTEST                        /// 
	Level(integer `c(level)')       /// -Replay- option
	*                               /// -mlopts- options
	]

// !! PR - note that stpmdf() overrides df() if both specified.
if `stpmdf'>0 local df `stpmdf'

/* Check rcsgen is installed */
	capture which rcsgen
	if _rc >0 {
		display in yellow "You need to install the command rcsgen. This can be installed using,"
		display in yellow ". {stata ssc install rcsgen}"
		exit  198
	}

	
/* Temporary variables */	
	tempvar Z xb lnt lnt0 coxindex S Sadj cons touse2 touse_t0 cons
	tempname initmat Rinv_bh R_bh rmatrix
	
/* Marksample and mlopts */	
	marksample touse
	qui replace `touse' = 0  if _st==0
	mlopts mlopts, `options'
	local extra_constraints `s(constraints)'

/* collinear option not allowed */
	if `"`s(collinear)'"' != "" {
		di as err "option collinear not allowed"
		exit 198
	}
	
/* use of all option to calculate spline variables out of sample */
	if `"all"' != "" {
		gen `touse2' = 1
	}
	else {
		gen `touse2' = `touse'
	}

/* Drop previous created _rcs and _d_rcs variables */
	capture drop _rcs* 
	capture drop _d_rcs*    
	capture drop _s0_rcs*
	
/* Check time origin for delayed entry models */
	local del_entry = 0
	qui summ _t0 if `touse' , meanonly
	if r(max)>0 {
		display in green  "note: delayed entry models are being fitted"
		local del_entry = 1
	}
	
/* Orthogonal retricted cubic splines */
	if "`orthog'"=="noorthog" {
		local orthog
	}
	else {
		local orthog orthog
	}	
	
/* generate log time */
	qui gen `lnt' = ln(_t) if `touse2'

/* Ignore options associated with time-dependent effects if specified without the tvc option */
	if "`tvc'" == "" {
		foreach opt in dftvc knotstvc {
			if "``opt''" != "" {
				display as txt _n "[`opt'() used without specifying tvc(), option ignored]"
				local `opt'
			}
		}
	}	

/* use no orthogonalization if rmat option specified */
/* add checks for no tvc etc */
	if "`rmat'" != "" {
		if "`tvc'" != "" {
			display as error "tvc option not available when using rmat option"
			exit 198
		}
		local orthog
		matrix `rmatrix' = e(R_bh)
		local rmatrixopt rmatrix(`rmatrix')
	}
	
/* Old stpm options */
/* Stratify */
	if "`stratify'" != "" {
		if "`tvc'" != "" {
			display as error "You can not specify both the stratify and tvc options"
			exit 198
		}
		local tvc `stratify'
		local dftvc `df'
	}
	
/* if bhazard option not specifed make it a column of zeros */
	if "`bhazard'" != "" {
		if `touse' & missing(`bhazard') == 1 {
			display as err "baseline hazard contains missing values"
			exit
		}
		local rs _rs
	}
	
/* set up spline variables */
	tokenize `knots'
	local nbhknots : word count `knots'

/* Only one of df and knots can be specified */
	if "`df'" != "" & `nbhknots'>0 {
		display as error "Only one of DF OR KNOTS can be specified"
		exit
	}
	
/* df must be specified */
	if `nbhknots' == 0 & "`df'" == "" {
		display as error "Use of either the df or knots option is compulsory"
		exit 198
	}
	
/* df for time-dependent variables */

	if "`tvc'"  != "" {
		if "`dftvc'" == "" & "`knotstvc'" == "" {
			display as error "The dftvc option is compulsory if you use the tvc option"
			exit 198
		}
		local ntvcdf: word count `dftvc'
		tokenize "`dftvc'"
		forvalues i = 1/`ntvcdf' {
			local tvcdflist`i' ``i''
			local wordtvcdflist: word count tvcdflist`i'
			if `wordtvcdflist' == 1 {
				local defaulttvcdf `tvcdflist`i''
			}
		}

		foreach tvcvar in  `tvc' {
			local `tvcvar'_df `defaulttvcdf'
		}

		forvalues i = 1/`ntvcdf' {
			tokenize "`tvcdflist`i''", parse(":")
			local `1'_df `3'
		}
	}

/* knotstvc option */
	if "`knotstvc'" != "" {
		if "`dftvc'" != "" {
			display as error "You can not specify the dftvc and knotstvc options"
			exit 198
		}
		tokenize `knotstvc'
		while "`2'"!="" {
			cap confirm var `1'
			if _rc == 0 {
				if `"`: list posof `"`1'"' in tvc'"' == "0" {				
					display as error "`1' is not listed in the tvc option"
					exit 198
				}
				local tmptvc `1'
				local `tmptvc'_df 1
			}
			cap confirm num `2'
			if _rc == 0 {
				local tvcknots_`tmptvc'_user `tvcknots_`tmptvc'_user' `2' 
				local `tmptvc'_df = ``tmptvc'_df' + 1
			}
			else {
				cap confirm var `2'
				if _rc {
					display as error "`2' is not a variable"
					exit 198
				}
			}
			macro shift 1
		}
	}
	
/* Check scale options specified */
	if "`scale'" =="" {
		display as error "The scale must be specified"
		exit
	}

/* define scale */
	if substr("`scale'", 1, 1)=="h" {
		local scale "hazard"
	}
	else if substr("`scale'", 1, 1)=="o" {
		local scale "odds"
	}
	else if substr("`scale'", 1, 1)=="n" {
		local scale "normal"
	}
	else if substr("`scale'", 1, 1)=="t" {
		local scale "theta"
	}	
	else {
		display as error "The scale must be specified as either hazard, odds, normal or theta"
		exit
	}

/* Ensure only certain options used with scale(theta) */	
	if "`scale'" != "theta" {
		foreach thetaopt in constheta {
			if "``thetaopt''" != "" {
				display as err "`thetaopt' should only be used with the scale(theta) option"
				exit 198
			}
		}
	}
	
	if "`scale'" == "odds" & "`theta'" != "" {
		local scale theta
		if "`theta'" != "est" {
			local constheta `theta'
		}
	}

/* knots given on which scale */
	if "`knscale'" == "" {
		local knscale time
	}
	
/* Boundary Knots */
	if "`bknots'" == "" {
		summ `lnt' if `touse' & _d == 1, meanonly
		local lowerknot `r(min)'
		local upperknot `r(max)'
	}
	else if substr("`knscale'",1,1) == "t" {
		local lowerknot = ln(real(word("`bknots'",1)))
		local upperknot = ln(real(word("`bknots'",2)))
	}
	else if substr("`knscale'",1,1) == "l" {
		local lowerknot = word("`bknots'",1)
		local upperknot = word("`bknots'",2)
	}
	else if substr("`knscale'",1,1) == "c" {
		qui centile `lnt' if `touse' & _d==1, centile(`bknots') 
		local lowerknot = `r(c_1)'
		local upperknot = `r(c_2)'
	}
	
	/* Knot placement for baseline hazard */
	if `nbhknots' == 0 {
		if `df' == 1 {
			qui rcsgen `lnt' if `touse2', gen(_rcs) dgen(_d_rcs) `orthog' `rmatrixopt'
			if "`orthog'" != "" {
				matrix `R_bh' =  r(R)
			}
		}
		else if `df' == 2 {
			qui centile `lnt' if `touse' & _d==1, centile(50) 
			local bhknots  `lowerknot' `r(c_1)' `upperknot'
		}
		else if `df' == 3 {
			qui centile `lnt' if `touse' & _d==1, centile(33 67) 
			local bhknots  `lowerknot' `r(c_1)' `r(c_2)' `upperknot'
		}
		else if `df' == 4 {
			qui centile `lnt' if `touse' & _d==1, centile(25 50 75) 
			local bhknots  `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `upperknot'
		}
		else if `df' == 5 {
			qui centile `lnt' if `touse' & _d==1, centile(20 40 60 80) 
			local bhknots  `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `upperknot'
		}
		else if `df' == 6 {
			qui centile `lnt' if `touse' & _d==1, centile(17 33 50 67 83) 
			local bhknots  `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `r(c_5)' `upperknot'
		}
		else if `df' == 7 {
			qui centile `lnt' if `touse' & _d==1, centile(14 29 43 57 71 86) 
			local bhknots `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `r(c_5)' `r(c_6)' `upperknot'
		}
		else if `df' == 8 {
			qui centile `lnt' if `touse' & _d==1, centile(12.5 25 37.5 50 62.5 75 87.5) 
			local bhknots `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `r(c_5)' `r(c_6)' `r(c_7)' `upperknot'
		}
		else if `df' == 9 {
			qui centile `lnt' if `touse' & _d==1, centile(11.1 22.2 33.3 44.4 55.6 66.7 77.8 88.9) 
			local bhknots `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `r(c_5)' `r(c_6)' `r(c_7)' `r(c_8)' `upperknot'
		}
		else if `df' == 10 {
			qui centile `lnt' if `touse' & _d==1, centile(10 20 30 40 50 60 70 80 90) 
			local bhknots `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `r(c_5)' `r(c_6)' `r(c_7)' `r(c_8)' `r(c_9)' `upperknot'
		}		
		else {
			display as error "DF must be between 1 and 10"
			exit
		}
	}
	

/* knot placement for time-varying covariates */
	if "`tvc'" != "" {
		foreach tvcvar in  `tvc' {
			if "`tvcknots_`tvcvar'_user'" == "" {
				if ``tvcvar'_df' == 1 {
					qui rcsgen `lnt' if `touse2', gen(_rcs_`tvcvar') dgen(_d_rcs_`tvcvar') `orthog'
					if "`orthog'" != "" {
						tempname R_`tvcvar' Rinv_`tvcvar'
						matrix `R_`tvcvar'' =  r(R)
					}
				}
				else if ``tvcvar'_df'==2 {
					qui centile `lnt' if `touse' & _d==1, centile(50) 
					local tvcknots_`tvcvar'  `lowerknot' `r(c_1)' `upperknot'
				}
				else if ``tvcvar'_df'==3 {
					qui centile `lnt' if `touse' & _d==1, centile(33 67) 
					local tvcknots_`tvcvar' `lowerknot' `r(c_1)' `r(c_2)' `upperknot'
					}
				else if ``tvcvar'_df'==4 {
					qui centile `lnt' if `touse' & _d==1, centile(25 50 75) 
					local tvcknots_`tvcvar' `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `upperknot'
				}
				else if ``tvcvar'_df'==5 {
					qui centile `lnt' if `touse' & _d==1, centile(20 40 60 80) 
					local tvcknots_`tvcvar' `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `upperknot'
				}
				else if ``tvcvar'_df'==6 {
					qui centile `lnt' if `touse' & _d==1, centile(17 33 50 67 83) 
					local tvcknots_`tvcvar' `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `r(c_5)' `upperknot'
				}
				else if ``tvcvar'_df'==7 {
					qui centile `lnt' if `touse' & _d==1, centile(14 29 43 57 71 86) 
					local tvcknots_`tvcvar' `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `r(c_5)' `r(c_6)' `upperknot'
				}
				else if ``tvcvar'_df'==8 {
					qui centile `lnt' if `touse' & _d==1, centile(12.5 25 37.5 50 62.5 75 87.5) 
					local tvcknots_`tvcvar' `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `r(c_5)' `r(c_6)' `r(c_7)' `upperknot'
				}
				else if ``tvcvar'_df'==9 {
					qui centile `lnt' if `touse' & _d==1, centile(11.1 22.2 33.3 44.4 55.6 66.7 77.8 88.9) 
					local tvcknots_`tvcvar' `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `r(c_5)' `r(c_6)' `r(c_7)' `r(c_8)' `upperknot'
				}
				else if ``tvcvar'_df'==10 {
					qui centile `lnt' if `touse' & _d==1, centile(10 20 30 40 50 60 70 80 90) 
					local tvcknots_`tvcvar' `lowerknot' `r(c_1)' `r(c_2)' `r(c_3)' `r(c_4)' `r(c_5)' `r(c_6)' `r(c_7)' `r(c_8)' `r(c_9)' `upperknot'
				}
				else {
					display as error "DF for time-dependent effects must be between 1 and 10"
					exit
				}		
			}
		}
	}

/* Generate splines for baseline hazard */
	/* !! PR */ if "`verbose'"=="verbose" display as txt "Generating Spline Variables"
	if `nbhknots'>0 {
		local bhknots `lowerknot'

		forvalues i=1/`nbhknots' {
			if substr("`knscale'",1,1) == "t" {
				local addknot = ln(real(word("`knots'",`i')))
			}
			else if substr("`knscale'",1,1) == "l" {
				local addknot = word("`knots'",`i')
			}
			else if substr("`knscale'",1,1) == "c" {
				local tmpknot = word("`knots'",`i')
				qui centile `lnt' if `touse' & _d==1, centile(`tmpknot') 
				local addknot = `r(c_1)'
			}
			local bhknots `bhknots' `addknot'
		}
		local bhknots `bhknots' `upperknot'
	}

	if "`df'" != "1" {
		qui rcsgen `lnt' if `touse2', knots(`bhknots') gen(_rcs) dgen(_d_rcs) `orthog'  `rmatrixopt'
		if "`orthog'" != "" {
			matrix `R_bh' = r(R)
		}
	}
	
/* Generate splines for time-dependent effects */	
	if "`tvc'" != "" {
		foreach tvcvar in  `tvc' {
			if ``tvcvar'_df' != 1 {
				if "`tvcknots_`tvcvar'_user'" != "" {
					local n_`tvcvar': word count `tvcknots_`tvcvar'_user'
					local tvcknots_`tvcvar' `lowerknot'
 
					forvalues i=1/`n_`tvcvar'' {
						if substr("`knscale'",1,1) == "t" {
							local addknot = ln(real(word("`tvcknots_`tvcvar'_user'",`i')))
						}
						else if substr("`knscale'",1,1) == "l" {
							local addknot = word("`tvcknots_`tvcvar'_user'",`i')
						}
						else if substr("`knscale'",1,1) == "c" {
							local tmpknot = word("`tvcknots_`tvcvar'_user'",`i')
							qui centile `lnt' if `touse' & _d==1, centile(`tmpknot') 
							local addknot = `r(c_1)'
						}
						local tvcknots_`tvcvar' `tvcknots_`tvcvar'' `addknot'
					}
					local tvcknots_`tvcvar' `tvcknots_`tvcvar'' `upperknot'
 				}
				qui rcsgen `lnt' if `touse2', knots(`tvcknots_`tvcvar'') gen(_rcs_`tvcvar') dgen(_d_rcs_`tvcvar')  `orthog' 
				if "`orthog'" != "" {
					tempname R_`tvcvar' Rinv_`tvcvar'
					matrix `R_`tvcvar'' = r(R)
				}
			}
		}
	}
	
	/* Added so R matrix is returned when using rmat option */
	if "`rmat'" != "" {
			local orthog orthog		
			matrix `R_bh' = `rmatrix'
	}



/* Generate splines for delayed entry */
	if `del_entry' == 1 {
		qui gen `lnt0' = ln(_t0) if `touse' & _t0>0
		if "`df'" == "1" {
			qui rcsgen `lnt0' if `touse2' & _t0>0, gen(_s0_rcs1) 
		}
		else if "`df'" != "1" {
			qui rcsgen `lnt0' if `touse2' & _t0>0, knots(`bhknots') gen(_s0_rcs) 
		}
		foreach tvcvar in  `tvc' {
			if ``tvcvar'_df' == 1 {
				qui rcsgen `lnt0' if `touse2' & _t0>0,  gen(_s0_rcs_`tvcvar') 
			}
			else if ``tvcvar'_df' != 1 {
				qui rcsgen `lnt0' if `touse2' & _t0>0, knots(`tvcknots_`tvcvar'') gen(_s0_rcs_`tvcvar')
			}
		}		
	}
	
	local nk : word count `bhknots'
	if "`df'" == "1" {
		local df = 1
	}
	else {
		local df = `nk' - 1
	}
/* create list of spline terms and their derivatives for use when orthogonalizing and in model equations */
	forvalues i = 1/`df' {
		local rcsterms_base "`rcsterms_base' _rcs`i'"
		local drcsterms_base "`drcsterms_base' _d_rcs`i'"
	}

	local rcsterms `rcsterms_base'
	local drcsterms `drcsterms_base'
	if "`tvc'" != "" {
		foreach tvcvar in  `tvc' {
			forvalues i = 1/``tvcvar'_df' {
				local rcsterms_`tvcvar' "`rcsterms_`tvcvar'' _rcs_`tvcvar'`i'"
				local drcsterms_`tvcvar' "`drcsterms_`tvcvar'' _d_rcs_`tvcvar'`i'"
				local rcsterms "`rcsterms' _rcs_`tvcvar'`i'"
				local drcsterms "`drcsterms' _d_rcs_`tvcvar'`i'"
			}
		}
	}
	
/* Orthogonalisation of delayed entry terms */
	if "`orthog'" != "" {
		qui gen `touse_t0' = `touse2'*(_t0>0)
		if `del_entry' == 1 {
			qui gen `cons' = 1 if `touse2' & _t0>0
			matrix `Rinv_bh' = inv(`R_bh')
			local s0_rcsterms : subinstr local rcsterms_base "_rcs" "_s0_rcs", all 
			
			mata st_store(.,tokens(st_local("s0_rcsterms")),"`touse_t0'",(st_data(.,(tokens(st_local("s0_rcsterms")),"`cons'"),"`touse_t0'")*st_matrix("`Rinv_bh'"))[,1..`df'])	

			if "`tvc'" != "" {
				foreach tvcvar in  `tvc' {
					matrix `Rinv_`tvcvar'' = inv(`R_`tvcvar'')
					local s0_rcsterms_`tvcvar' : subinstr local rcsterms_`tvcvar' "_rcs" "_s0_rcs", all
					mata st_store(.,tokens(st_local("s0_rcsterms_`tvcvar'")),"`touse_t0'",(st_data(.,(tokens(st_local("s0_rcsterms_`tvcvar'")),"`cons'"),"`touse_t0'")*st_matrix("`Rinv_`tvcvar''"))[,1..``tvcvar'_df'])	
				}
			}
		}
	}

/* multiply time-dependent _rcs and _drcs terms by time-dependent covariates */
	if "`tvc'" != "" {
		foreach tvcvar in  `tvc' {
			forvalues i = 1/``tvcvar'_df' {
				qui replace _rcs_`tvcvar'`i' = _rcs_`tvcvar'`i'*`tvcvar' if `touse2'
				qui replace _d_rcs_`tvcvar'`i' = _d_rcs_`tvcvar'`i'*`tvcvar' if `touse2'
				if `del_entry' == 1 {
					qui replace _s0_rcs_`tvcvar'`i' = _s0_rcs_`tvcvar'`i'*`tvcvar' if `touse2' & _t0>0
				}
			}
		}
	}

/* replace missing values for delayed entry with -99 as ml will omit these cases. -99 is not included in the likelihood calculation */
	if `del_entry' == 1 {
		forvalues i = 1/`df' {
			qui replace _s0_rcs`i' = -99 if `touse2' & _t0 == 0
		}
		foreach tvcvar in `tvc' {
			forvalues i = 1/``tvcvar'_df' {
				qui replace _s0_rcs_`tvcvar'`i' = -99 if `touse2' & _t0 == 0
			}
		}
	}

/* variable labels */
	forvalues i = 1/`df' {
		label var _rcs`i' "restricted cubic spline `i'"
		label var _d_rcs`i' "derivative of restricted cubic spline `i'"
		if `del_entry' == 1 {
			label var _s0_rcs`i' "restricted cubic spline `i' (delayed entry)"
		}
	}

	if "`tvc'" != "" {
		foreach tvcvar in  `tvc' {
			forvalues i = 1/``tvcvar'_df' {
				label var _rcs_`tvcvar'`i' "restricted cubic spline `i' for tvc `tvcvar'"
				label var _d_rcs_`tvcvar'`i' "derivative of restricted cubic spline `i' for tvc `tvcvar'"
				if `del_entry' == 1 {
					label var _s0_rcs_`tvcvar'`i' "restricted cubic spline `i' for tvc `tvcvar' (delayed entry)"
				}
			}	
		}
	}

/* Remove collinearity. */
	if "`varlist'" != "" {
		local colvarlist (`varlist')
	}
	_rmcollright (`rcsterms') `colvarlist' if `touse', `constant'
	local varlist `r(block2)'

/* Define Offset */
	if "`offset'" != "" {
		local offopt offset(`offset')
		local addoff +`offset'
	}
	
/* initial values fit a Cox model with (linear time-dependent covariates) */
/* Taken from Patrick Roystons stpm code */	
		
	/* !! PR */ if "`verbose'"=="verbose" display as txt "Obtaining Initial Values"
	if "`lininit'" == "" {
		if "`tvc'" != "" {
			local tvcterms tvc(`tvc') texp(ln(_t))
		}
		qui stcox `varlist' if `touse', estimate 
		qui predict `coxindex' if `touse', xb
		qui sum `coxindex' if `touse'
		qui replace `coxindex'=`coxindex'-r(mean) if `touse'
		qui stcox `coxindex' if `touse', basechazard(`S') 
		if "`bhazard'" != "" {
			qui replace `S' = `S' - 0.1*`bhazard'*_t if `touse'
		}
		qui replace `S'=exp(-`S') if `touse'
		qui predict double `Sadj' if `touse', hr
		qui replace `Sadj'=`S'^`Sadj' if `touse'
		if "`scale'" == "hazard" {
			qui gen double `Z' = ln(-ln(`Sadj')) `addoff' if `touse'
		}
		else if "`scale'" == "odds" {
			qui gen double `Z' = ln((1-`Sadj')/`Sadj')  `addoff'  if `touse'
		}
		else if "`scale'" == "normal" {
			qui count if `touse'
			local nobs=r(N)
			qui gen double `Z' = invnormal((`nobs'*(1-`Sadj')-3/8)/(`nobs'+1/4))  `addoff' if `touse'
		}
		else if "`scale'" == "theta" {
			qui gen double `Z' = ln((`Sadj'^(-`inittheta') - 1)/(`inittheta'))  `addoff' if `touse'
		}
		qui regress `Z' `varlist' `rcsterms'  if `touse' & _d == 1 , `constant'
		matrix `initmat' = e(b)

	/* initial values for theta */
		if "`scale'" == "theta" {
			local thetaeq (ln_theta:)
			if "`constheta'"  == "" {
				local lntheta = ln(`inittheta')
				matrix `initmat' = `initmat' , `lntheta'
			}
			else {
				local lntheta = ln(`constheta')
				matrix `initmat' = `initmat' , `lntheta'
			}
		}	
	
		local ncopy : word count `rcsterms'
		local nstart : word count `varlist'
		local nstart = `nstart' + 1
		local ncopy = `nstart' + `ncopy' -1
		matrix `initmat' = `initmat', `initmat'[1,`nstart'..`ncopy']
	}

/* Fit linear term to log(time) for initial values. */
	else {
		if inlist("`scale'","hazard","odds","normal") {
			local initrcslist _rcs1
			local initdrcslist _d_rcs1
			constraint free
			constraint `r(free)' [xb][_rcs1] = [dxb][_d_rcs1]
			local initconslist `r(free)'
			if "`tvc'" != "" {
				foreach tvcvar in `tvc' {
					local initrcslist `initrcslist' _rcs_`tvcvar'1
					local initdrcslist `initdrcslist' _d_rcs_`tvcvar'1
					constraint free
					constraint `r(free)' [xb][_rcs_`tvcvar'1] = [dxb][_d_rcs_`tvcvar'1]
					local initconslist `initconslist' `r(free)'
				}
			}
			if `del_entry' == 1 {
				local xb0 `"(xb0: `varlist' `:subinstr local initrcslist "_rcs" "_s0_rcs",all' ,`constant' `offopt')"'

				if "`constant'" == "" {
					local addconstant _cons
				}
				foreach var in `initrcslist' `varlist' `addconstant' {
					constraint free
					if substr("`var'",1,4) == "_rcs" {
						constraint `r(free)' [xb][`var'] = [xb0][_s0`var']
					}
					else {
						constraint `r(free)' [xb][`var'] = [xb0][`var']
					}
					local initconslist `initconslist' `r(free)'
				}
			}
			/* !! PR */ if "`verbose'"=="verbose" display as txt "Obtaining Initial Values"
			
			qui ml model d1 stpm2_ml_`scale'`rs' ///
					(xb: `bhazard' =  `varlist' `initrcslist', `constant' `offopt') ///
					`thetaeq' ///
					(dxb: `initdrcslist', nocons)  ///
					`xb0' ///
					if `touse', ///
					`mlopts' ///
					`collinear' ///
					constraints(`initconslist') ///
					search(norescale) ///
					maximize

			display in green "Initial Values Obtained"
			matrix `initmat' = e(b)
			constraint drop `initconslist'
		}
	}
	
	
/* Define constraints */					
	local conslist
	local fplist
	local dfplist

/* constraints for theta if option constheta(#) is specified */	
	if "`scale'" == "theta" & "`constheta'" !="" {
		constraint free
		constraint `r(free)' [ln_theta][_cons] = `constheta'
		local conslist `conslist' `r(free)'
	}

/* constraints for baseline */
	forvalues k = 1/`df' {
		constraint free
		constraint `r(free)' [xb][_rcs`k'] = [dxb][_d_rcs`k']
		local conslist `conslist' `r(free)'
	}

/* constraints for time-dependent effects */
	if "`tvc'" != "" {
		foreach tvcvar in  `tvc' {
			forvalues k = 1/``tvcvar'_df' {
				constraint free
				constraint `r(free)' [xb][_rcs_`tvcvar'`k'] = [dxb][_d_rcs_`tvcvar'`k']
				local conslist `conslist' `r(free)'
			}
		}
	}

/* constraints for extra equation if delayed entry models are being fitted */	
	if `del_entry' == 1 {
		local xb0: subinstr local rcsterms "_rcs" "_s0_rcs", all

		local xb0 (xb0: `varlist' `xb0', `constant' `offopt')
		
		local xbvarlist `varlist' `rcsterms' 
		if "`constant'" == "" {
			local xbvarlist `xbvarlist' _cons
		}
		foreach term in `xbvarlist' {
			constraint free
			if substr("`term'",1,4) == "_rcs" {
				local addterm = "_s0" + "`term'"
			}
			else {
				local addterm `term'
			}
			constraint free
			constraint `r(free)' [xb][`term'] = [xb0][`addterm']
			local conslist `conslist' `r(free)'
		}

		if "`lininit'" == "" {
			local nxbterms: word count `xbvarlist'
			matrix `initmat' = `initmat', `initmat'[1,1..`nxbterms']
		}
	}

/* If further constraints are listed stpm2 then remove this from mlopts and add to conslist */
	if "`extra_constraints'" != "" {
*		local mlopts = subinstr("`mlopts'","constraints(`extra_constraints')","",1)
		local mlopts : subinstr local mlopts "constraints(`extra_constraints')" "",word
		local dropconslist `conslist'
		local conslist `conslist' `extra_constraints'
	}
		
/* Fit Model */
	if "`lininit'" == "" {
		local initopt "init(`initmat',copy)"
	}
	else {
		local initopt "init(`initmat')"
	}

	/* !! PR */ if "`verbose'"=="verbose" display as txt "Starting to Fit Model"
	if inlist("`scale'","hazard","odds","normal") {
		local mlmethod d2
	}
	else {
		local mlmethod lf
	}
	if "`scale'" == "normal" & "`rs'" != "" {
		local mlmethod lf
	}
	
	
	ml model `mlmethod' stpm2_ml_`scale'`rs' ///
		(xb: `bhazard' = `varlist' `rcsterms', `constant' `offopt') ///
		`thetaeq' ///
		(dxb: `drcsterms', nocons)  ///
		`xb0' ///
		if `touse', ///
		`mlopts' ///
		collinear ///
		constraints(`conslist') ///
		`initopt'  ///	
		search(off) ///
		waldtest(0) ///
		`log' ///
		maximize 


	ereturn local predict stpm2_pred
	ereturn local cmd stpm2
	ereturn local depvar "_d _t"
	ereturn local varlist `varlist'
	ereturn local tvc `tvc'
	ereturn local constant `noconstant'
	local exp_lowerknot = exp(`lowerknot')
	local exp_upperknot = exp(`upperknot')
	ereturn local boundary_knots "`exp_lowerknot' `exp_upperknot'"
	if `df' >1 {
		forvalues i = 2/`df' {
			local addknot = exp(real(word("`bhknots'",`i')))
			local exp_bhknots `exp_bhknots' `addknot' 
		}
		ereturn local bhknots `exp_bhknots'
	}
	ereturn local ln_bhknots `bhknots'
	ereturn local rcsterms_base `rcsterms_base'
	ereturn local drcsterms_base `drcsterms_base'
	ereturn scalar dfbase = `df'
	ereturn scalar nxbterms = e(rank) - ("`scale'" == "theta")
	foreach tvcvar in  `tvc' {
		ereturn scalar df_`tvcvar' = ``tvcvar'_df'
		ereturn local rcsterms_`tvcvar' `rcsterms_`tvcvar''
		ereturn local drcsterms_`tvcvar' `drcsterms_`tvcvar''
		if ``tvcvar'_df'>1 {
			local exp_knots
			forvalues i = 2/``tvcvar'_df' {
				local addknot = exp(real(word("`tvcknots_`tvcvar''",`i')))
				local exp_knots `exp_knots' `addknot' 
			}
			ereturn local tvcknots_`tvcvar' `exp_knots'
			ereturn local ln_tvcknots_`tvcvar' `tvcknots_`tvcvar''
		}
		if "`orthog'" != "" {
			ereturn matrix R_`tvcvar' = `R_`tvcvar''
		}
	}
	if "`orthog'" != "" {
		ereturn matrix R_bh = `R_bh'
	}
	ereturn local noconstant `constant'
	ereturn local scale `scale'
	ereturn local orthog  `orthog'
	ereturn local bhazard `bhazard'
	ereturn scalar del_entry = `del_entry'
	ereturn scalar dev = -2*e(ll)
	ereturn scalar AIC = -2*e(ll) + 2 * e(rank) 
	qui count if `touse' == 1 & _d == 1
	ereturn scalar BIC = -2*e(ll) + ln(r(N)) * e(rank) 
	
	if "`keepcons'" == "" {
		constraint drop `dropconslist'
	}
	Replay, level(`level') `alleq' `eform' `showcons'
end

program Replay
	syntax [, EFORM ALLEQ SHOWCons Level(int `c(level)') ]
	if "`alleq'" == "" {
		local neq neq(1)
		if "`e(scale)'" == "theta" {
			local neq neq(2)
		}
	}

/* Don't show constraints unless cnsreport option is used */
	if "`showcons'" == "" {
		local showcons nocnsreport
	}
	else {
		local showcons
	}

	ml display, `eform' `neq' `showcons' level(`level')
end



