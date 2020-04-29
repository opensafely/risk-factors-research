*! version 1.1.6 PR 04jan2007
/*
History

1.1.6 04jan2007 e(micombine) returns micombine. e(cmd2) returns `cmd'.
1.1.5 01nov2006 Changed default names for impid and obsid to _mj and _mi resp.
1.1.4 26jul2006 Awkward bug in determination of nobs fixed (reported by Christina Gibson-Davis)
1.1.3 23jun2006 svy option: Stata 8/9 functionality sorted out.
		infgain (hidden option) added.
1.1.2 23may2006 svy option added, with svy options as argument.
		Minor bug affecting stpm fixed.
1.1.1 28nov2005 eform and eform() option styles now allowed.
		nowarning option to suppress warning message about supported regression cmds.
1.1.0 30sep2005 Generalization of supported commands (cmdchk.ado also modified).
		Version <=7 no longer supported.
1.0.9 18apr2005 Default rowid variable becomes _i.
		If not found, take from char _dta[MI_obsid] then char _dta[mi_id].
		Default impid variable is _j. If not found, take from _dta[MI_impid].
		These changes are for future compatibility with MItools.
1.0.8 04mar2005 Fixed problem with eform on redisplay
1.0.7 28jan2005 Fixed problem with null model estimation
		Fixed bug with noconstant option
1.0.6 25jan2005 e(sample) now correct for all imputations, via ereturn post.
		Add d.f. quantities from Barnard & Rubin (1999) Biometrika 86:948-955 eq (3)-(5).
		Minor additions to ereturn quantities for compatibility with misw.
		Allow null model and model only with constant for benefit of misw.
1.0.5 16nov2004 Update calculations of quantities stored for Li et al (1991) F test.
1.0.4 13oct2004 Change e(cmd) to `cmd', make e(cmd2)="micombine" (for use after mfx).
		Implementation of mean log likelihood and chisquare statistic saved
		(note undocumented -noclear- but v. useful option to ereturn post/estimates post).
*/
program define micombine, eclass

if _caller()<=7 {
	di as error "version 7 and earlier not supported"
	exit 9
}

if replay() {
	if `"`e(micombine)'"'!="micombine" {
		error 301
	}
	syntax[, EForm EForm2(string)]
	if "`eform2'"!="" {
		if "`eform'"!="" di as err "[eform ignored]"
		local eform eform(`eform2')
	}
	else if "`eform'"!="" local eform eform("exp(b)")
	di as text _n "Multiple imputation parameter estimates (" as res e(m) as text " imputations)"
	capture ereturn  display, `eform'
	local rc=_rc
	if `rc'>0 {
		* Null model, or model with cc() only
		if `"`e(cmd)'"'!="stcox" {
			`e(cmd)' `0'
		}
		else di as text "[Null model - no estimates]"
	}
	else ereturn  display, `eform'
	di as result e(N) as text " observations."
	exit
}

gettoken cmd 0 : 0
if "`cmd'"=="stpm" {
	local dist 7
	local cmdnotknown 0
}
else {
	cmdchk `cmd'
	local cmdnotknown `s(bad)'
	/*
		dist=0 (normal), 1 (binomial), 2 (poisson), 3 (cox), 4 (glm),
		5 (xtgee), 6(ereg/weibull).
	*/
	local dist `s(dist)'
}
syntax [anything] [if] [in] [aw fw pw iw] , [ IMPid(string) BR CC(varlist) noCONStant ///
 DEAD(varname) DETail EForm EForm2(string) GENxb(string) INFgain LRR noWARning OBSid(string) ///
 SVYalone svy(string) * ]
 
if `cmdnotknown' & "`warning'"!="nowarning" {
	di as err _n "Warning: " as inp "`cmd'" as err " is not a certified regression command for micombine."
	di as err "micombine will continue mechanically, but correct results are not guaranteed."
	di as err "You must take responsibility that Rubin's rules are appropriate here." _n
}

if "`eform2'"!="" {
	if "`eform'"!="" di as err "[eform ignored]"
	local eform eform(`eform2')
}
else if "`eform'"!="" local eform eform("exp(b)")

* Check impid
if "`impid'"=="" local impid _mj
cap confirm var `impid'
if _rc {
	di as err "imputation identifier `impid' not found"
	exit 601
}

* Check obsid
if "`obsid'"=="" {
	local I: char _dta[mi_id]
	if "`I'"=="" local I _mi
}
else local I `obsid'
cap confirm var `I'
if _rc {
	di as err "observation identifier `I' not found"
	exit 601
}

if "`detail'"!="" {
	local detail noisily
}
else local detail

if "`svyalone'"!="" {
	if _caller()>=9 local svy svy:
	else local svy svy
}
else if `"`svy'"'!="" {
	if _caller()>=9 local svy svy, `svy':
	else {
		local svy svy
		local options `"`options' `svy'"'
	}
	else local svy svy, `svy':
}
*Change here 11/15/05, commenting out the line below !! PR DELETED XIAO CHEN'S EDIT, NOV 05
frac_cox "`dead'" `dist'

if "`constant'"=="noconstant" {
	if "`cmd'"=="fit" | "`cmd'"=="stcox" | "`cmd'"=="cox" {
		di as error "noconstant invalid with `cmd'"
		exit 198
	}
}

*Change here 11/15/05, `dist' could be null....  !! PR DELETED XIAO CHEN'S EDIT, NOV 05
*if "`dist'" =="7" {	/* stcox, streg, stpm */
if `dist'==7 {
	local y
	local yname _t
	local xvars `anything'
}
else {
	 gettoken y xvars : anything
	 gettoken xvars left: xvars, parse("(")
	 local yname `y'
}

tempvar touse
quietly {
/*
	Getting n for each imputation is not straightforward, since `anything'
	may give problems with marksample. Try to work around this issue.
*/
	marksample touse, novarlist
	local revise_touse 0
	capture markout `touse' `y' `xvars' `left' `dead' `cc'
	if _rc {
		markout `touse' `y' `xvars' `dead' `cc'	// I assume this can't fail!
		local revise_touse 1
	}
	if "`dead'"!="" {
		local dead "dead(`dead')"
	}

* Deal with weights.
	frac_wgt `"`exp'"' `touse' `"`weight'"'
	local wgt `r(wgt)'

	tempvar J
	* Important (compatibility with mitools): ignore rows for which impid=0
	egen int `J'=group(`impid') if `touse'==1 & `impid'>0 & !missing(`impid')
	sum `J', meanonly
	local m=r(max)
	if `m'<2 {
		di as error "there must be at least 2 imputations"
		exit 198
	}

	local nxvar: word count `xvars'
/*
	if `nxvar'<1 {
		di as err "there must be at least one covariate"
		exit 198
	}
*/
	local ncc: word count `cc'		/* could legitimately be zero */
	local nvar=`nxvar'+`ncc'		/* number of covariates in model */

	count if `touse'==1 & `J'==1
	local nobs=r(N)

* Null Cox model (or model with only ccvars): fit on final imputation only, and quit
	if "`xvars'"=="" & ("`cmd'"=="cox" | "`cmd'"=="stcox") {
		if "`cmd'"=="stcox" & "`cc'"=="" {
			local options `options' estimate
		}
		`detail' `svy'`cmd' `y' `cc' if `touse'==1 & `J'==`m' `wgt', `options' `dead' `constant'
		noi `cmd'
		di as result `nobs' as text " observations."
		ereturn  scalar m=`m'
		ereturn  local impid `impid'
		ereturn  local cmd `cmd'
		ereturn  local cmd2 micombine
		exit
	}

* Fit model on original data - get Wald chisquare
	if "`infgain'"!="" {
		tempname chi2_1 chi2_0 df_1 df_0 nold
		`detail' `svy'`cmd' `y' `xvars' `cc' `left' if `touse'==1 & `impid'==0 `wgt', `options' `dead' `constant'
		scalar `nold'=e(N)
		test `xvars' `cc' `left'
		scalar `df_0'=r(df)
		if missing(r(chi2)) scalar `chi2_0'=r(F)*`df_0'
		else scalar `chi2_0'=r(chi2)
	}

* Compute model over m imputations
	tempname W Q B T QQ
	if "`genxb'"!="" {
		tempvar xb xbtmp
		gen `xb'=.
	}
	* Estimate mean LR chisquare statistic (where possible)
	tempname chi2 ell ell0 nucom
	scalar `chi2'=0
	scalar `ell'=0
	scalar `ell0'=0
	forvalues i=1/`m' {
		tempname Q`i'
		`detail' `svy'`cmd' `y' `xvars' `cc' `left' if `touse'==1 & `J'==`i' `wgt', ///
		 `options' `dead' `constant'
		if `revise_touse' {
			* Deal with `left' that gave problems in markout.
			* Cautious approach is to replace `touse'; may not always be necessary,
			* but it is safe and costs little.
			replace `touse'=e(sample) if `J'==`i'
			if `i'==1 local nobs=e(N)
		}
		if e(N)!=`nobs' {
			noi di as txt "[Note: sample size in imputation `i' is " e(N) ", different from " `nobs' " in imp. 1]"
		}
		scalar `nucom'=e(df_r)	// complete-data residual degrees of freedom
		if `nucom'==. {
			scalar `nucom'=100000
		}
		scalar `ell'=`ell'+e(ll)
		scalar `ell0'=`ell0'+e(ll_0)
		scalar `chi2'=`chi2'-2*(e(ll_0)-e(ll))
		if "`genxb'"!="" {
			predict `xbtmp' if `touse'==1 & `J'==`i', xb
			replace `xb'=`xbtmp' if  `touse'==1 & `J'==`i'
			drop `xbtmp'
		}
		matrix `Q`i''=e(b)
		if `i'==1 {
			matrix `Q'=e(b)
			matrix `W'=e(V)
		}
		else {
			matrix `Q'=`Q'+e(b)
			matrix `W'=`W'+e(V)
		}

	}
	if "`genxb'"!="" {
		sort `touse' `I' `J'
		by `touse' `I': gen `genxb'=sum(`xb')/`m' if `touse'==1
		by `touse' `I': replace `genxb'=`genxb'[_N] if _n<_N
		lab var `genxb' "Mean Linear Predictor (`m' imputations)"
	}
	matrix `Q'=`Q'/`m'		/* MI param estimates */
	matrix `W'=`W'/`m'
	scalar `chi2'=`chi2'/`m'
	scalar `ell'=`ell'/`m'
	scalar `ell0'=`ell0'/`m'
	local k=colsof(`Q')
	matrix `B'=J(`k',`k',0)
	forvalues i=1/`m' {
		matrix `QQ'=`Q`i''-`Q'
		if `i'==1 {
			matrix `B'=`QQ''*`QQ'
		}
		else matrix `B'=`B'+`QQ''*`QQ'
	}
	matrix `B'=`B'/(`m'-1)
	matrix `T'=`W'+(1+1/`m')*`B'	/* estimated VCE matrix */
	/*
		Relative increase in variance due to missing information (r) for
		each variable, and df and lambda, the fraction of missing information.
		All measures are unstable for low m. See Schafer (1997) p. 110.

		Note that BIF = sqrt(T/W) = sqrt(1 + (B/W)*(1+1/m)) = sqrt(1+r)
		is the between-imputation imprecision factor, i.e. the ratio
		of the SE derived from T to the SE derived from W,
		ignoring between-imputation variation in parameter estimates.
	*/
	tempname r t lambda nu BIF
	matrix `r'=J(1,`k',0)
	matrix `lambda'=J(1,`k',0)
	matrix `nu'=J(1,`k',0)
	matrix `BIF'=J(1,`k',0)
	scalar `t'=`m'-1
	* Next few lines assign quantities for tests of individual (1 df) components of Q (=beta)
	forvalues j=1/`k' {
		matrix `r'[1,`j']=(1+1/`m')*`B'[`j',`j']/`W'[`j',`j']
		matrix `nu'[1,`j']=cond(`t'>4, 4+(`t'-4)*(1+(1-2/`t')/`r'[1,`j'])^2, `t'*(1+1/`r'[1,`j'])^2)
		matrix `lambda'[1,`j']=(`r'[1,`j']+2/(`nu'[1,`j']+3))/(`r'[1,`j']+1)
		matrix `BIF'[1,`j']=sqrt(1+`r'[1,`j'])	/* = sqrt(`T'[`j',`j']/`W'[`j',`j']) */
	}
	* Next few lines assign quantities for d.f. from Barnard & Rubin 1999 B'ka 86(4): 948-955.
	tempname nutilde num nuobs gamma
	matrix `nutilde'=J(1,`k',0)
	matrix `num'=J(1,`k',0)
	matrix `nuobs'=J(1,`k',0)
	matrix `gamma'=J(1,`k',0)
	forvalues j=1/`k' {
		matrix `gamma'[1,`j']=(1+1/`m')*`B'[`j',`j']/`T'[`j',`j']
		matrix `nuobs'[1,`j']=((`nucom'+1)/(`nucom'+3))*`nucom'*(1-`gamma'[1,`j'])
		matrix `num'[1,`j']=(`m'-1)*`gamma'[1,`j']^-2
		matrix `nutilde'[1,`j']=1/((1/`num'[1,`j']+1/`nuobs'[1,`j']))
	}
	* use all varnames
	local names: colnames(`Q1')
	matrix colnames `r'=`names'
	matrix colnames `nu'=`names'
	matrix colnames `lambda'=`names'
	matrix colnames `BIF'=`names'

	matrix colnames `gamma'=`names'
	matrix colnames `nuobs'=`names'
	matrix colnames `num'=`names'
	matrix colnames `nutilde'=`names'

	* Li, Raghunathan & Rubin (1991) estimates of T and nu1
	* for F test of Q=0 on k,nu1 degrees of freedom
	tempname r1 t1 BW TLRR
	matrix `BW'=`B'*syminv(`W')
	scalar `r1'=trace(`BW')*(1+1/`m')/`k'
	matrix `TLRR'=`W'*(1+`r1')
	scalar `t1'=`k'*(`m'-1)
	matrix colnames `Q'=`names'
	matrix rownames `T'=`names'
	matrix colnames `T'=`names'
	matrix rownames `B'=`names'
	matrix colnames `B'=`names'
	matrix rownames `TLRR'=`names'
	matrix colnames `TLRR'=`names'
}
di as text _n "Multiple imputation parameter estimates (`m' imputations)"
if "`lrr'"!="" {
	di as text "[Using Li-Raghunathan-Rubin (LRR) estimate of VCE matrix]"
	ereturn  post `Q' `TLRR', depname(`yname') obs(`nobs') esample(`touse') noclear
	ereturn  matrix T `T'
}
else {
	ereturn  post `Q' `T', depname(`yname') obs(`nobs') esample(`touse') noclear
	ereturn  matrix TLRR `TLRR'
}
if "`br'"=="" {
	ereturn  display, `eform'
	di as result `nobs' as text " observations (imputation 1)."
}
if "`infgain'"!="" {
	qui test `xvars' `cc' `left'
	scalar `df_1'=r(df)
	if missing(r(chi2)) scalar `chi2_1'=r(F)*`df_1'
	else scalar `chi2_1'=r(chi2)
	if reldif(`df_0',`df_1')>.001 di as txt _n "[cannot compute information gain, models have different dimension]"
	else di as txt _n "MI information gain = " as res %7.3f 100*(`chi2_1'-`chi2_0')/`chi2_0' as txt " percent." ///
	 " Sample size increase = " as res %7.3f 100*(`nobs'-`nold')/`nold' as txt " percent."
}
ereturn  matrix B `B'
ereturn  matrix W `W'
ereturn  matrix r `r'
ereturn  matrix nu `nu'
ereturn  matrix lambda `lambda'
ereturn  matrix BIF `BIF'

* Quantities for calculating df `nutilde' according to Barnard & Rubin (1999)
ereturn  matrix gamma `gamma'
ereturn  matrix nuobs `nuobs'
ereturn  matrix num `num'
ereturn  matrix nutilde `nutilde'

ereturn  scalar r1=`r1'
ereturn  scalar nu1=cond(`t1'>4, 4+(`t1'-4)*(1+(1-2/`t1')/`r1')^2, 0.5*`t1'*(1+1/`k')*(1+1/`r1')^2)
ereturn  scalar m=`m'
ereturn  scalar chi2=`chi2'
ereturn  scalar ll=`ell'
ereturn  scalar ll_0=`ell0'
ereturn  local eform `eform'
ereturn  local impid `impid'
ereturn  local cmd `cmd'
ereturn  local cmd2 `cmd'
ereturn  local micombine micombine
if "`br'"!="" {
	display_t
	di as result `nobs' as text " observations."
}
end

program define display_t
* Display results with t-statistics estimated according to Barnard & Rubin (1999)
	tempname V Q nu
	matrix `V'=e(V)
	matrix `Q'=e(b)
	matrix `nu'=e(nutilde)
	local yname `e(depvar)'
	local xs: colnames `Q'
	local k=colsof(`Q')
	di as text _n "Intervals and inference based on d.f. from Barnard & Rubin (1999)"
	di as txt "{hline 13}{c TT}{hline 64}"
	local t0 = abbrev("`yname'",12)
	if `"`e(eform)'"'!="" {
		local tt "Odds Ratio"
	}
	else {
		local tt "     Coef."
	}

	#delimit ;
	di as text
	%12s "`t0'" _col(14)"{c |}`tt'  Std. Err.     t   P>|t|  [$S_level% Conf. Intvl]     MI.df"
	_n "{hline 13}{c +}{hline 64}" ;
	#delimit cr
	tempname df mn se t p invt l u
	forvalues i=1/`k' {
		local x: word `i' of `xs'
		if "`x'"!="_cons" {
			local fmt : format `x'
			if substr("`fmt'",-1,1)=="f" {
				local fmt="%8."+substr("`fmt'",-2,2)
			}
			else if substr("`fmt'",-2,2)=="fc" {
				local fmt="%8."+substr("`fmt'",-3,3)
			}
			else local fmt "%8.0g"
			local fmt`i' `fmt'
		}
		else local fmt "%8.0g"
	        scalar `df' =`nu'[1,`i']
	        scalar `mn' = `Q'[1,`i']
	        scalar `se' = sqrt(`V'[`i',`i'])
	        scalar `t' = `mn'/`se'
	        scalar `p' = 2* ttail(`df', abs(`t'))
	        scalar `invt' = invttail(`df', (1-$S_level/100)/2)
	        scalar `l' = `mn' - `invt'*`se'
	        scalar `u' = `mn' + `invt'*`se'
	        if `"`e(eform)'"'!="" {
	        	scalar `mn' = exp(`mn')
	        	scalar `se' = `mn'*`se'
	        	scalar `l' = exp(`l')
	        	scalar `u' = exp(`u')
	        }
		if `df'>99999 {
			local fmtdf %9.2e
		}
		else local fmtdf %9.2f
		di as text /*
			*/  %12s abbrev("`x'",12)  _col(14) "{c |}" /*
			*/ _col(17)  as res `fmt'   `mn'	  /*
			*/ _col(27)  `fmt'  `se' /*
			*/ _col(36)   %7.2f	`t'  /*
			*/ _col(42)   %7.3f	`p'  /*
			*/ _col(52)  `fmt'  `l'  /*
			*/ _col(61)  `fmt'  `u'  /*
			*/ _col(70)  `fmtdf'   `df'
	}
	di as text "{hline 13}{c BT}{hline 64}"
end

program define chkrowid, sclass
local I: char _dta[mi_id]
if "`I'"=="" {
	di as error "no row-identifier variable found - data may have incorrect format"
	exit 198
}
cap confirm var `I'
local rc=_rc
if `rc' {
	di as error "row-identifier variable `I' not found"
	exit `rc'
}
sret local I `I'
end
