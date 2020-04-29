*! v 1.4.1 PR/IW/ACL/TPM 07feb2014
program define ice_, rclass
version 9.2
syntax varlist(min=1 numeric) [if] [in] [aweight fweight pweight iweight], ///
 [ BOot clear DEbug DROPmissing dryrun ESTstore(passthru) INITialonly PERsist m(int 1) m1 ///
 MATch MATch2(varlist) MATCHPool(int 10) ORDerasis nopp SAVing(string) replace Seed(int 0) noWARNing noVERbose ///
 UVISopts(passthru) * ]
if ("`initialonly'" == "initialonly") local dryrun
if ("`m1'" == "m1") local m 1
if `"`saving'"'!="" {
	tokenize `"`saving'"', parse(",")
	if `"`2'"'!="" {
		if `"`2'"'!="," | `"`4'"'!="" error 198
		if `"`3'"'!="" {
			if `"`3'"'!="replace" error 198
			local replace replace
		}
	}
	local using `1'
}
* Check if there are variables called boot and/or match
if "`boot'"=="boot" {
	cap confirm var boot
	if _rc local options `options' boot(`varlist')
	else local options `options' boot(boot)
}
if ("`match'" == "match") & !missing("`match2'") {
	di as err "both match and match2() not allowed"
	exit 198
}
if "`match'"=="match" {
	cap confirm var match
	if _rc local options `options' match(`varlist')
	else local options `options' match(match)
	local options `options' matchpool(`matchpool')
}
if !missing("`match2'") {
	if "`match'"=="match" di as err "[match ignored, using match(`match')]"
	local options `options' match(`match2')
	local options `options' matchpool(`matchpool')
}
if `seed'>0 set seed `seed'
local first first
tempname fn erules
if "`dryrun'"!="" {
	if `"`using'"'=="" {
		local using `fn'
	}
	_ice `varlist' `if' `in' [`weight' `exp'] using `using', `options' `orderasis' `uvisopts' first dryrun
	di as text _n "End of dry run. No imputations were done, no files were created."
	return local neq 0
	exit
}

if `m'<1 {
	di as err "number of imputations must be 1 or more"
	exit 198
}

if `"`using'"'=="" {
	if "`dryrun'"=="" & "`clear'"=="" {
		di as err "saving() and/or clear required"
		exit 100
	}
}
else if "`replace'"=="" {
	if substr(`"`using'"', -4, .) != ".dta" confirm new file `"`using'.dta"'
	else confirm new file `"`using'"'
}

preserve
if "`dropmissing'"!="" {
	* Drop obs not in the estimation sample i.e. that would not be imputed
	marksample touse, novarlist
	if "`cc'`on'"!="" {
		markout `touse' `cc' `on'
	}
	tempvar rmiss
	egen long `rmiss'=rmiss(`varlist') if `touse'
	local nv: word count `varlist'	// #covariates
	qui count if `rmiss'==`nv' | `touse'==0
	if r(N)>0 {
		di as txt _n "[dropping " r(N) " observations not in the estimation sample]"
		drop if `rmiss'==`nv' | `touse'==0
	}
	drop `touse' `rmiss'
}
// Save original data, and create and save m imputed datasets
local original original
forvalues i=0/`m' {
	tempfile fn`i'
	_ice `varlist' `if' `in' [`weight' `exp'] using `"`fn`i''"', ///
	 `options' `orderasis' `first' `original' `warning' `pp' inum(`i') ///
	 `uvisopts' `nbregopts' `debug' `persist' `verbose' `eststore' `initialonly'
	 * option inum(`i') above added by ACL. It records the imputation number.
	local original
	if `i'>0 {
		local first
		if "`debug'" == "debug" di as txt _n "- completed _mj = " as res `i' _n
		else if ("`verbose'" != "noverbose") {
			if ("`initialonly'" == "") di as text `i' _cont
			else di as text `i', _cont
		}
	}
	if (`i' == `m') {
		// store equations etc. returned by -ice_-
		local neq `r(neq)'
		forvalues r = 1 / `neq' {
			local cmd`r' `r(cmd`r')'
			local x`r' `r(x`r')'
			local eq`r' `r(eq`r')'
			local cond`r' `r(cond`r')'
		}
	}
}
// Join files of imputations vertically. Include original data as _mj=0
quietly {
	local J _mj
	forvalues j=0/`m' {
		* could automate this part
		use `"`fn`j''"', clear
		chkrowid
		local I `s(I)'
		if "`I'"=="" {
			* create row number
			local I _mi
			cap drop `I'
			gen long `I'=_n
			lab var `I' "obs. number"
		}
		cap drop `J'
		gen int `J'=`j'
		lab var `J' "imputation number"
		save `"`fn`j''"', replace
	}
	use `"`fn0'"', clear	// load original data plus impid and obsid variables
	forvalues j=1/`m' {
		append using `"`fn`j''"'
	}
	char _dta[mi_id] `I'
}
if `"`using'"'!="" {
	di
	save `"`using'"', `replace'
}
if "`clear'"!="" {
	di as txt _n "[note: imputed dataset now loaded in memory]"
	if `"`using'"'=="" & "`warning'"!="nowarning" ///
	 di as err _n "Warning: imputed dataset has not (yet) been saved to a file"
	restore, not	// Keep the imputed dataset in memory
}
// store equations etc.
if `neq' > 0 {
	forvalues r = 1 / `neq' {
		return local cmd`r' `cmd`r''
		return local x`r' `x`r''
		return local eq`r' `eq`r''
		return local cond`r' `cond`r''
	}
}
return local neq `neq'
end

program define chkrowid, sclass
version 9.2
local I: char _dta[mi_id]
if "`I'"=="" exit
cap confirm var `I'
if _rc exit
sret local I `I'
end

program define _ice, rclass
version 9.2
syntax varlist(min=1 numeric) [if] [in] [aw fw pw iw] using/, ///
 [ ALLmissing BIgdump BOot(varlist) by(varlist) CC(varlist) CMd(string) CYcles(int 0) noCONStant match(varlist) MATCHPool(int 3) ///
 CONDitional(string) DEbug dryrun EQ(string) EQDrop(string) ESTstore(string) first Genmiss(string) Id(string) INum(int 0) ///
 INTerval(string) MONOtone noWARNing ON(varlist) ORDerasis original PASsive(string) PERsist nopp REStrict(passthru) ///
 ROUnd(string) noSHoweq SUBstitute(string) TRace(string) UVISopts(string) NBREGopts(string) vce(passthru) ///
 noVERbose INITialonly ] 
* inum() option: Added by ACL to record the imputation number

quietly if "`original'"!="" {
	* Save original data
	save `"`using'"', replace
	exit
}

local nvar: word count `varlist'
if "`id'"!="" {
	confirm new var `id'
}
else local id _mi

if "`monotone'" != "" {
	if `"`eq'"' != "" {
		di as err "cannot have monotone missingness and define equations via eq()"
		exit 198
	}
	// impose order as given for monotone imputation equations and set cycles(1)
	local orderasis orderasis
	if `cycles' <= 0 local cycles 1
}

/*
	PR 29oct10: allow negative cycles() to mean FORCE cycling even in univariate missingness (uvis) cases.
	Requested by IRW to deal with some special situations in ice.
*/
local cycles_user `cycles'
if `cycles' <= 0 {
	if `cycles'==0 local cycles 10
	else local cycles = -`cycles'
}

preserve
tempvar touse order
quietly {
	marksample touse, novarlist
	if "`cc'`on'"!="" {
		markout `touse' `cc' `on'
	}
	// `by' may have missing values - exclude these
	if "`by'" != "" {
		count if `touse' == 1
		local before = r(N)
		markout `touse' `by'
		count if `touse' == 1
		local mby = `before' - r(N)
		if `mby' > 0 & "`warning'" != "nowarning" {
			noi di as err _n "[warning - `by' has `mby' missing values - no imputation for these observations]"
		}
		local by by(`by')
	}

* Record sort order
	gen long `order'=_n
	lab var `order' "obs. number"
/*
	For standard operation (no `on' list and `allmissing' option not used),
	disregard any completely missing rows in original varlist, among marked obs.
*/
	if "`on'"=="" {
		tempvar rmis
		local uvl: char _dta[mi_uniqvl]
		if "`uvl'"=="" local uvl `varlist'	// in case ice_ called direct rather than via ice.ado
		local nuvl : word count `uvl' // no. of unique vars, ignoring effects of i., o. and m.
		egen long `rmis'=rmiss(`uvl') if `touse'==1
		count if `rmis'==0
		// `allmissing' option allows obs with all-missing covariates to be imputed
		if ("`allmissing'" == "") {
			replace `touse'=0 if `rmis'==`nuvl'
			replace `rmis'=. if `rmis'==`nuvl'
		}
		lab var `rmis' "#missing values"
		if "`first'"!="" & "`showeq'"!="noshoweq" noisily tabulate `rmis', missing
		drop `rmis'
	}
/*
	Check if any variables prefixed by "i." (if they exist) have missing values in the
	estimation sample. If so, flag error and stop.
*/
	local i_varlist : char _dta[mi_ivl]
	if "`i_varlist'" != "" {
		local haserr 0
		tokenize `i_varlist'
		while "`1'" != "" {
			count if (`touse'==1) & missing(`1')
			if r(N) > 0 {
				di as err _n r(N) " missing values of variable `1' found in the estimation sample"
				local ++haserr
			}
			mac shift
		}
		if `haserr' > 0 {
			di as err _n "variables with an i. prefix must be complete in the estimation sample"
			di as err "you can use an m. or o. prefix to impute incomplete variables of this type"
			di as err _n `haserr' " specification error(s) found"
			exit 198
		}
	}

* Deal with weights
	frac_wgt `"`exp'"' `touse' `"`weight'"'
	local wgt `r(wgt)'

* Sort out cmds (not checking if each cmd is valid - any garbage may be entered)
	if "`cmd'"!="" {
		* local cmds "regress logistic logit ologit mlogit"
		detangle "`cmd'" cmd "`varlist'"
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				local cmd`i' ${S_`i'}
			}
		}
	}

* Rounding of imputed values
	if "`round'"!="" {
		detangle "`round'" round "`varlist'"
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				local round`i' ${S_`i'}
				confirm num `round`i''
			}
		}
	}

* Default for all uvis operations is nomatch, meaning draw
	if "`match'"!="" {
		tokenize `match'
		while "`1'"!="" {
			ChkIn `1' "`varlist'"
			if `s(k)'>0 {
				local match`s(k)' match
			}
			mac shift
		}
	}

	if "`boot'"!="" {
		tokenize `boot'
		while "`1'"!="" {
			ChkIn `1' "`varlist'"
			if `s(k)'>0 {
				local boot`s(k)' boot
			}
			mac shift
		}
	}
	local anyerr 0
	if `"`passive'"'!="" {
		tempvar passmiss
		/*
		   Defines vars that are functions or transformations of others in varlist.
		   They are (may be) "passively imputed". "\" is an expression separator.
		   Default is comma.
		   Comma may not always be appropriate (i.e. may appear in an expression).
		*/
		detangle "`passive'" passive "`varlist'" \
		local haserr 0
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				local exp`i' ${S_`i'}
				ParsExp `exp`i''
				local exclude `s(result)'
				if "`exclude'"!="" {
					* Count missingness of this passive variable
					egen int `passmiss'=rmiss(`exclude') if `touse'
					count if `passmiss'>0 & `touse'==1
					local nimp`i'=r(N)
					if `nimp`i''==0 {
						local v: word `i' of `varlist'
						noi di as err "passive definition `v' = (${S_`i'}) redundant: `exclude' has no missing data."
						local ++haserr
					}
					local excl`i' `exclude'	// could be a varlist
					drop `passmiss'
				}
			}

		}
		if `haserr'>0 {
			di as err "`haserr' error(s) found in option " as inp "passive(`passive')"
			local anyerr 1
		}
	}
	if "`substitute'"!="" {
		* defines vars that are to be substituted in the recalc context
		detangle "`substitute'" substitute "`varlist'"
		local haserr 0
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				local sub`i' ${S_`i'}
				local v: word `i' of `varlist'
				count if missing(`v') & `touse'==1
				if r(N)==0 {
					noi di as err "substitute for variable `v' redundant: `v' has no missing data."
					local ++haserr
				}
				* check for elements of sub`i' being already defined as passive
				unab sub`i': `sub`i''
				tokenize `sub`i''
				while "`1'"!="" {
					ChkIn `1' "`varlist'"
					local pass `s(k)'
					if "`exp`pass''"=="" {	// not a passive var yet: define it as such
						sum `v' if `1'>0 & !missing(`1') & `touse'==1, meanonly
						local min=r(min)
						local max=r(max)
						if r(min)==r(max) local exp`pass' (`v'==`min')
						else local exp`pass' (`v'>=`min')&(`v'<=`max')
						local excl`pass' `v'
					}
					mac shift
				}
			}
		}
		if `haserr'>0 {
			noi di as err "`haserr' error(s) found in option " as inp "substitute(`substitute')"
			local anyerr 1
		}
	}
	if "`conditional'"!="" {
		* defines vars that are to be conditioned on
		if ("`warning'" != "nowarning") & ("`orderasis'" != "") ///
		 noi di as err "[Warning: imposing orderasis with conditional() may produce inconsistent results]"
		detangle "`conditional'" conditional "`varlist'" \
		local haserr 0
		local eef if
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				local v: word `i' of `varlist'
				count if missing(`v') & `touse'==1
				local m1=r(N)
				if `m1'==0 {
					noi di as err _n "conditioning for variable `v' redundant - no missing data."
					local ++haserr
				}
				local cond`i' : list global(S_`i') - eef
				capture count if (`cond`i'') & (`touse' == 1)
				local rc = c(rc)
				if `rc' > 0 {
					noi di as err _n "expression" as inp " `cond`i''" as err ///
					 " is invalid - raises error " `rc'
					local ++haserr
				}
				else if r(N) < 2 {
					noi di as err _n "subset" as inp " `cond`i''" as err ///
					 " is too small - contains " as inp r(N) as err " cases"
					local ++haserr
				}
				else {
					ParsExp `cond`i''
					local condlist`i' `s(result)'
/*
	condlist`i' is the list of vars known to be in the dataset (but not
	necessarily in mainvarlist) that appear in the expression cond`i'
*/
					if "`condlist`i''" != "" unab condlist`i' : `condlist`i''
				}
			}
		}
		if `haserr'>0 {
			if `haserr'>1 local s s
			else local s
			noi di as err _n "`haserr' error`s' found relating to option " as inp "conditional(`conditional')"
			local anyerr 1
		}
	}
	if "`interval'"!="" {
		* defines interval censored vars in threes: ll, ul, y
		detangle "`interval'" interval "`varlist'"
		local haserr 0
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				local int`i' ${S_`i'}
				gettoken ll ul:int`i'
				count if `ll'>`ul' & !missing(`ll') & !missing(`ul') & `touse'==1
				if r(N)>0 {
					noi di as err "invalid interval(), some values of `ll' > `ul'"
					exit 198
				}
				local cmd`i' intreg
				* Mark ll and ul as interval limits
				ChkIn `ll' "`varlist'"
				local ll `s(k)'
				local islimit`ll' yes
				ChkIn `ul' "`varlist'"
				local ul `s(k)'
				local islimit`ul' yes
			}
		}
		// At present, next statement is redundant, but may be used later.
		if `haserr'>0 {
			noi di as err _n "`haserr' error(s) found in option " as inp "interval(`interval')"
			local anyerr 1
		}
	}
	if `"`eq'"'!="" {
		* defines equations specified vars.
		if ("`initialonly'" == "") {
			detangle "`eq'" equation "`varlist'"
			forvalues i=1/`nvar' {
				if ("${S_`i'}" != "") {
					if ("${S_`i'}" != "_cons") {
						cap unab Eq`i': ${S_`i'} // could be something created by xi:
						if _rc {
							di as err _n "${S_`i'} is not a valid varlist"
							exit 198
						}
						* Check that eq vars are in mainvarlist
						tokenize `Eq`i''
						while "`1'"!="" {
							ChkIn `1' "`varlist'"
							mac shift
						}
					}
					else local Eq`i' _cons
				}
			}
		}
	}
	if `"`eqdrop'"'!="" {
		* defines variables to drop from equations.
		detangle "`eqdrop'" "equation drop" "`varlist'"
		forvalues i=1/`nvar' {
			if "${S_`i'}"!="" {
				cap unab eqdrop`i' : ${S_`i'}
				if _rc {
					di as err _n "${S_`i'} is not a valid varlist"
					exit 198
				}
				* Check that eqdrop vars are in mainvarlist
				tokenize `eqdrop`i''
				while "`1'"!="" {
					ChkIn `1' "`varlist'"
					mac shift
				}
			}
		}
	}
	if `anyerr' {
		di as err _n "specification error(s) found."
		exit 198
	}
	count if `touse'
	local n=r(N)
/*
	Count potentially imputable missing values for each variable,
	and where necessary create an equation for each
*/
	local to_imp 0	// actual number of vars with missing values to be imputed
	local recalc 0	// number of passively imputed vars to be recalculated
	tempvar xtmp	// temporary holding area
	local nimp	// list of number of missing values for each variable
	if "`monotone'" != "" & "`first'"!="" {
		local mono_vl ""	// build up predictor list for monotone missingness
		local xvar0 ""	// previous variable in varlist
		local nonmono 0	// total non-monotone values in neighbouring pairs of variables
		local denom 0	// total denominator for relevant values in neighbouring pairs of variables
		local xvar0 : word 1 of `varlist'
		forvalues i = 2 / `nvar' {
			local xvar: word `i' of `varlist'
/*
			Count number of observations for which second var is observed and first is missing.
			Number > 0 is inadmissible for a truly monotone missingness pattern.
*/
			if `"`exp`i''"'=="" & "`islimit`i''"=="" {
				count if missing(`xvar0') & !missing(`xvar') & `touse' == 1
				local nonmono = `nonmono' + r(N)
				count if !missing(`xvar') & `touse' == 1
				local denom = `denom' + r(N)
				local xvar0 `xvar'
			}
		}
	}
	forvalues i=1/`nvar' {
		local xvar: word `i' of `varlist'
		local x`i' `xvar'
		if "`int`i''"!="" {
			gettoken ll ul: int`i'
			local ismissing ((`ll'<`ul') | missing(`ll') | missing(`ul')) & `touse'==1
			local labmissing 1 if `xvar' missing or `ll'<`ul', 0 otherwise
		}
		else {
			local ismissing missing(`xvar') & `touse'==1
			local labmissing 1 if `xvar' missing, 0 otherwise
		}
		if "`genmiss'"!="" {
			tempvar mvar`i'
			gen byte `mvar`i''=`ismissing'
			lab var `mvar`i'' "`labmissing'"
		}
		* Create prediction equation for each active variable
		count if `ismissing'
		if r(N)>0 & `"`exp`i''"'=="" & "`islimit`i''"=="" {
			local nimp`i'=r(N)
			* active var: has missing obs or is interval censored, not passive
			local ++to_imp
			local main`i' 1
			* Keep missingness of the original variable
			tempvar miss`i'
			if "`genmiss'"!="" gen byte `miss`i''=`mvar`i''
			else gen byte `miss`i''=`ismissing'
			* Define equation for this variable - user definition from Eq() takes precedence
			if "`monotone'" != "" {
				local eq`i' `mono_vl'	// all variables in list so far
				local mono_vl `mono_vl' `xvar'
			}
			else {
				if "`Eq`i''"!="" {
					if "`Eq`i''" == "_cons" local eq`i'
					else local eq`i' `Eq`i''
				}
				else {
					* Remove variable from mainvarlist
					local eq`i': list varlist - xvar
				}
			}
			if "`cmd`i''"=="" {
/*
	Assign default cmd for vars not so far accounted for.
	cmd is relevant only for vars requiring imputation, i.e. with >=1 missing values.
	Use logit if 2 distinct values, mlogit if 3-5, otherwise regress.
*/
				inspect `xvar' if `touse'
				local nuniq=r(N_unique)
				if `nuniq' == 0 {
					noi di as err _n "no non-missing observations of `xvar' found"
					exit 2000
				}					
				if `nuniq'==1 {
					noi di as err _n "only 1 distinct value of `xvar' found"
					exit 2001
				}
				if `nuniq'==2 {
					count if `xvar'==0 & `touse'==1
					if r(N)==0 {
						noi di as err "variable `xvar' unsuitable for imputation,"
						noi di as err "binary variables must include at least one 0 and one non-missing value"
						exit 198
					}
					local cmd`i' logit
				}
				else if `nuniq'<=5 {
					local cmd`i' mlogit
				}
				else local cmd`i' regress
			}
			if "`cmd`i''"=="mlogit" {
				* With mlogit, if xvar carries a score label,
				* drop it since it causes prediction problems
				local xlab: value label `xvar'
				capture label drop `xlab'
			}
			if "`on'"=="" {
				* Initially fill missing obs
				if "`int`i''"!="" {
					replace `xvar'=.
					replace `xvar'=`ll' if !missing(`ll') &  missing(`ul')
					replace `xvar'=`ul' if  missing(`ll') & !missing(`ul')
					replace `xvar'=(`ll'+`ul')/2 if !missing(`ul') & !missing(`ll')
				}
				sampmis `xtmp'=`xvar'
*				replace `xvar'=cond(`touse'==0, ., `xtmp')
				replace `xvar' = `xtmp' if `ismissing'
				drop `xtmp'
			}
			else replace `xvar'=. if `touse'==0
			local lab`i' `xvar' imput.`suffix' (`nimp`i'' values)
		}
		else {
			local main`i' 0
			if "`nimp`i''"=="" {	// may have been set earlier by consideration of ParsExp
				local nimp`i'=r(N)
			}
			if (`"`exp`i''"' != "") {
				if ("`Eq`i''" != "") & (`"`eq'"' != "none") {
					noi di as err "equation" as input " `xvar':`Eq`i'' " ///
					 as err "invalid, `xvar' is passively imputed"
					exit 198
				}
				local ++recalc
			}
			if "`monotone'" != "" {
				local mono_vl `mono_vl' `xvar'
			}
		}
		local nimp `nimp' `nimp`i''
	}
	if `to_imp'==0 {
		noi di as err _n "All relevant cases are complete, no imputation required."
		return scalar N=`n'
		return scalar imputed=0
		exit 2000
	}
* Remove passivevars, intvars and conditionalvars from equations as necessary
	forvalues i=1/`nvar' {
		if `"`exp`i''"'!="" {
			ParsExp `exp`i''
			local exclude `s(result)'
			* remove current passivevar from each relevant equation
			local passive `x`i''
			tokenize `exclude'
			while "`1'"!="" {
/*
	Identify which variable in mainvarlist we are looking at.
	Alternatively, if a variable is not found, ignore it!
	This is an experimental feature which allows passive imputation
	to include variables not in mainvarlist.
*/
				capture ChkIn `1' "`varlist'"
				if c(rc) local index 0
				else local index `s(k)'
				* Remove `passive' from equation of variable
				* whose index in mainvarlist is `index'
				* (only allowed to be done if there is no
				* user equation Eq`' for var #`index')
				if "`eq`index''"!="" & "`Eq`index''"=="" ///
				 local eq`index': list eq`index' - passive
/*
	`1' with index `index' is identified as a source variable for `passive'.
	Is it cond on anything? If so, remove passive variable from equation for that something.
*/
				if "`cond`index''"!="" {
					local ncond : word count `condlist`index''
					forvalues ii = 1 / `ncond' {
						local cond : word `ii' of `condlist`index''
						cap ChkIn `cond' "`varlist'"
						local cond `s(k)'
						if "`cond'" != "0" & "`eq`cond''"!="" & "`Eq`cond''"=="" ///
						 local eq`cond': list eq`cond' - passive
					}
				}
				mac shift
			}
		}
		if `"`cond`i''"'!="" {
			* Remove variables from prediction equations as appropriate
			local ncond : word count `condlist`i''
			forvalues ii = 1 / `ncond' {
				local cond : word `ii' of `condlist`i''
				// Provided the conditioning var (`cond') has only one distinct value under
				// condition cond`i', remove `cond' from equation for conditioned var (`x`i'')
				if "`eq`i''"!="" & "`Eq`i''"=="" {
					sum `cond' if (`cond`i'') & (`touse' == 1), meanonly
					if r(max) == r(min) local eq`i': list eq`i' - cond
				}
				// identify conditioning var in mainvarlist, if it's there
				cap ChkIn `cond' "`varlist'"
				local index `s(k)'
				// Remove conditioned var from equation for conditioning var
				if "`index'" != "0" & "`eq`index''"!="" & "`Eq`index''"=="" {
					local eq`index': list eq`index' - x`i'
				}
			}
		}
		if "`int`i''"!="" {
			* remove ll and ul from each relevant prediction equation
			forvalues j=1/`nvar' {
				if "`Eq`j''"=="" & "`eq`j''"!="" {
					local eq`j': list eq`j' - int`i'
				}
			}
			* Remove equations for ll and ul
			gettoken ll ul: int`i'
			ChkIn `ll' "`varlist'"
			local ll `s(k)'
			if "`Eq`ll''"=="" local eq`ll' "[Lower bound for `x`i'']"
			ChkIn `ul' "`varlist'"
			local ul `s(k)'
			if "`Eq`ul''"=="" local eq`ul' "[Upper bound for `x`i'']"
		}
	}
	if "`substitute'"!="" {
		forvalues i=1/`nvar' {
			if `main`i'' & "`sub`i''"!="" {
				* substitute for this variable in all equations where it is a covariate
				forvalues j=1/`nvar' {
					if `main`j'' & (`j'!=`i') & "`Eq`j''"=="" {
						local res: list eq`j' - x`i'
/*
						* substitute sub`i' if necessary i.e. if not already there
						tokenize `sub`i''
						while "`1'"!="" {
							cap ChkIn `1' "`res'"
							if "`s(k)'"=="0" {
								local res `res' `1'
							}
							mac shift
						}
*/
						local eq`j' `res'
					}
				}
			}
		}
	}
/*
	Drop variable(s) from current equation, if required.
	eqdrop`i' contains a list of variables to drop.
*/
	forvalues i = 1 / `nvar' {
		if "`eqdrop`i''"!="" {
			if `main`i'' == 0 {
				noi di as txt _n "[ignoring eqdrop(`x`i'':`eqdrop`i''), no equation needed for `xvar']"
			}
			else {
				tokenize `eqdrop`i''
				while "`1'" != "" {
					local eq`i' : list eq`i' - 1
					mac shift
				}
			}
		}
	}
/*
	Sort variables on number of missing values, from low to high numbers.
	Of benefit to the mice algorithm since vars with less missingness get imputed first.
*/
	if "`orderasis'"!="" {
		// Use vars in order entered by user
		forvalues i=1/`nvar' {
			local r`i' `i'
		}
	}
	else {
		listsort3 "`nimp'"
		forvalues i=1/`nvar' {
			local r`i' `s(index`i')'
		}
	}
	* Show prediction equations at first imputation
	if "`first'"!="" {
		local errs 0
		local longstring 55	// max display length of variables in equation
		local off 13		// blanks to col 13 on continuation lines
		if "`showeq'"=="" {
			if ("`initialonly'" == "initialonly") {
				noi di as txt _n "[Note: with the -initialonly- option, the following equations are not actually used:]"
			}
			noi di as text _n "   Variable {c |} Command {c |} Prediction equation" _n ///
			 "{hline 12}{c +}{hline 9}{c +}{hline `longstring'}"
		}
		forvalues r=1/`nvar' {
			local i `r`r''
			if "`on'"!="" {
				local eq `on'
				local formatoutput 1
			}
			else if "`exp`i''"!="" & `nimp`i''>0 {
				local eq "[Passively imputed from `exp`i'']"
				local formatoutput 0
			}
			else if "`eq`i''"=="" {
				if `main`i'' == 0 {
					local eq "[No missing data in estimation sample]"
				}
				else local eq "[Empty equation]"
				local formatoutput 0
			}
			else {
				local eq `eq`i''
				if "`cond`i''" != "" local eq `eq' if `cond`i''
				local formatoutput 1
			}
			if "`showeq'"=="" {
				if `formatoutput' {
					formatline, n(`eq') maxlen(`longstring')
					local nlines=r(lines)
					forvalues j=1/`nlines' {
						if `j'==1 noi di as text %11s abbrev("`x`i''",11) ///
						 " {c |} " %-8s "`cmd`i''" "{c |} `r(line`j')'"
						else noi di as text _col(`off') ///
						 "{c |}" _col(23) "{c |} `r(line`j')'"
					}
				}
				else noi di as text %11s abbrev("`x`i''",11) ///
				 " {c |} " %-8s "`cmd`i''" "{c |} `eq'"
			}
			// Check for invalid equation - xvar on both sides
			if "`eq`i''"!="" {
				if `: list x`i' in eq`i'' {
					noi di as err "Error!" as inp " `x`i''" ///
					 as err " found on both sides of prediction equation"
					local ++errs
				}
			}
		}
		if "`showeq'"=="" {
			noi di as text "{hline 12}{c BT}{hline 9}{c BT}{hline `longstring'}"
		}
		if "`on'"!="" noi di as text "Note: on() option selected"
		if "`monotone'" != "" {
			noi di as txt _n "Non-monotonicity score = " as res `nonmono' ///
			 as txt "/" as res `denom' as txt " (" as res %3.1f 100 * `nonmono' / `denom' "%" as txt ")"
			if `nonmono' > 0 noi di as txt "Warning: these data do not conform to a monotonic missingness pattern!"
		}
		if `errs' {
			di as err _n `errs' " error(s) found"
			exit 198
		}
		if "`dryrun'"!="" {
			exit
		}
		if missing("`debug'") noi di as text _n "Imputing " _cont
		else noi di
	}
	if (`to_imp'==1 & `cycles_user'>=0) | ("`on'"!="") {
		local cycles 1
	}
* Update recalculated variables
	if `"`passive'"'!="" & `recalc'>0 {
		forvalues i=1/`nvar' {
			if "`exp`i''"!="" {
				replace `x`i''=`exp`i''
			}
		}
	}
* Impute sequentially `cycles' times by regression switching (van Buuren et al)
	tempvar y imputed
	if `"`trace'"'!="" {
		tempname tmp
		* create names
		local postvl cycle
		forvalues r=1/`nvar' {
			local i `r`r''	// antirank: vars with small #missing come first
			if `main`i'' local postvl `postvl' `x`i''_mean
		}
		postfile `tmp' `postvl' using `"`trace'"', replace
	}

	if !missing("`debug'") {
		tempname dbg
		postfile `dbg' cycle varno str8 cmd str12 varname r2 using _ice_debug, replace
	}

	if "`conditional'"!="" tempvar imputed2

	// Check for and remove collinearities for each x qua dependent variable
	// (but not interval-censored variables)
	forvalues r = 1 / `nvar' {
		local i `r`r''
		if (`main`i''==1) & ("`int`i''"=="") {
			if "`on'"=="" local vars `eq`i''
			else local vars `on'
/*
	!! Note that if e(cmd) is set but estimation results are not available, 
	_rmdcoll exits with error 301 "last estimates not found". This is a known issue
	with gam.ado, maybe other improper estimation commands.
	Could do "ereturn clear" or "capture _rmdcoll ... " or some other fix.

	NOT FIXED.
*/
			_rmdcoll `x`i'' `vars' if !`miss`i'' & (`touse' == 1)
			local vars2 `r(varlist)'
			local dropped: list vars - vars2
			if "`dropped'"!="" {
				local eq`i' : list eq`i' - dropped
				if "`warning'"!="nowarning" ///
				 noi di as err "[Note: in regression for " ///
				 as inp "`x`i''" as err ", permanently removing " ///
				 as inp "`dropped'" as err " due to collinearity]"
			}
		}
	}
	local neststore 0
	// Main imputation loop (run when initialonly is not set - otherwise, just save initialised variables)
	if ("`initialonly'" == "") {
		forvalues j=1/`cycles' {
			if "`debug'" == "debug" noi di as res `j', _cont
			if `"`trace'"'!="" {
				local posts (`j')
			}
			local ppwarnings 0
			* ACL/IRW: perfect prediction warning is only displayed during the first cycle of the first imputation
			forvalues r=1/`nvar' {
				local i `r`r''
				if `main`i'' {
					* Each var is reimputed based on imputed values of other vars
					local type: type `x`i''
					gen `type' `y'=`x`i'' if `miss`i''==0 & `touse'==1
					if "`on'"=="" local vars `eq`i''
					else local vars `on'
					if "`int`i''"!="" local yvarlist `int`i''
					else local yvarlist `y'
					if "`cond`i''" != "" {
						*local condand (`Cond`i'' == 1) &
						local condand (`cond`i'') &
					}
					else local condand
					if "`cmd`i''" == "nbreg" & `"`nbregopts'"' != "" local nbr `nbregopts'
					else local nbr
					if ("`match`i''" == "match") {
						local Match match
						if (`matchpool' > 0) local Matchpool matchpool(`matchpool')
						else local Matchpool
					}
					else {
						local Match
						local Matchpool
					}
					if "`debug'" == "debug" noi di as txt _col(4) "`cmd`i''" _col(14) abbrev("`x`i''", 12) _cont
*noi di in red `"uvis `cmd`i'' `yvarlist' `vars' `wgt' if `condand' `touse' == 1, `uvisopts' gen(`imputed') `boot`i'' `Match' `Matchpool' `constant' `pp' `vce' `restrict' `by' `nbr'"'
					cap uvis `cmd`i'' `yvarlist' `vars' `wgt' if `condand' `touse' == 1, `uvisopts' ///
					 gen(`imputed') `boot`i'' `Match' `Matchpool' `constant' `pp' `vce' `restrict' `by' `nbr'
					local R2 = r(r2) // Nagelkerke, evaluated by -uvis-
					local haserr=_rc
					if `haserr' == 1 error 1
					local errmess `r(errmess)'
					local pp_cmd `r(pp_cmd)'
					if "`pp_cmd'"!="" & "`warning'"!="nowarning" & `j'==1 & `inum'==1 {
						* ACL/IRW: Perfect prediction warning for all variables but only in cycle 1 of imputation 1
						if `ppwarnings'==0 noi di as txt _n "[Perfect prediction detected:" _c
						if "`pp'"!="nopp" {
							if `ppwarnings'>0 noi di as txt ";" _c
							noi di as txt " using aug`pp_cmd' to impute " as res "`x`i''" _c
						}
						else if `ppwarnings'==0 noi di as txt " no action taken" _c
						local ++ppwarnings
					}
					if `haserr' {
						if "`persist'" == "persist" {
							noi di as err _n "[persist option: ignoring error #`haserr', not updating `x`i'' in cycle `j']"
							cap drop `y'
							cap drop `imputed'
							*continue, break
							continue
						}
						noi di as err _n "Error #`haserr' encountered while running -uvis-"
						noi di as err "I detected a problem with running uvis with command `cmd`i'' on response `x`i''"
						noi di as err "and covariates `vars'."
						noi di as err _n "The offending command resembled:"
						noi di as err `"uvis `cmd`i'' `x`i'' `vars' `wgt', gen([imputed]) `boot`i'' `match`i'' `constant' `pp' `vce' `restrict' `by' `uvisopts' `nbr'"' _n
						if "`cmd`i''"=="mlogit" {
							noi di as inp "With mlogit, try combining categories of `x`i'', or if appropriate, use ologit" _n
						}
						if `"`errmess'"'!="" {
							noi di as err "Further information reported by uvis:"
							noi di as err `"`errmess'"'
						}
						noi di as err "you may wish to try the -persist- option to persist beyond this error."
						noi di as err "dumping current data to ./_ice_dump.dta"
						save _ice_dump, replace
						error `haserr'
					}
					if "`cond`i''" != "" { 
					/* 
					Change by ACL : Moved this "if" condition here (it was right after Nagelkerke
					was computed) so that uvis convergence errors do not stop ice if the persist
					option is used.
					*/
						// Replace conditioned var with its mean value outside the conditioned subset
						sum `y' if !`condand' `touse' == 1, meanonly 
						/*
						Edited by ACL.  Replaced yvarlist with y so that upper and lower 
						bounds are not used. 
						*/
						if r(max) > r(min) {
							noi di as err "Error: variable `x`i'' has >1 value outside subgroup `cond`i''"
							exit 499
						}
						replace `imputed' = r(mean) if !`condand' `touse' == 1
					}
					if "`debug'" == "debug" {
						noi di as txt _col(26) "R2% = " %6.2f `R2'
						post `dbg' (`j') (`i') ("`cmd`i''") ("`x`i''") (`R2')
					}
					if "`round`i''"!="" replace `imputed'=round(`imputed',`round`i'') if missing(`y') & `touse'==1
					if `"`trace'"'!="" {
						summarize `imputed' if `touse'==1
						local mean=r(mean)
						local posts `posts' (`mean')
					}
					replace `x`i'' = `imputed' if `miss`i''
					count if `condand' `touse' == 1 & missing(`imputed')
					if r(N)>0 {
						if "`debug'" == "debug" {
							noi di as err _n(2) "Warning: while I was executing the following command:"
							noi di as err `"uvis `cmd`i'' `x`i'' `vars' `wgt' if `touse', gen([imputed]) `boot`i'' `match`i'' `constant' `pp' `vce' `restrict' `by'"'
							noi di as err "I found that " r(N) " missing value(s) of `x`i'' that should have been"
							noi di as err "imputed were missing at cycle " as inp `j'
							noi di as err "debug mode: dumping current data to /._ice_dump.dta and continuing."
							save _ice_dump, replace
							/* ACL: Missing values do not stop ice if debug option is used.	*/
						}
						if "`cmd'" == "regress" {
							sum `imputed' if `condand' `touse' == 1 
							* ACL: added `condand' in if stmt - In case of conditional imputation, condition has to be considered when replacing observations that were not imputed.
							replace `x`i''=r(mean) if `touse'==1 & missing(`imputed')
						}
						else {
							sum `imputed' if `condand' `touse' == 1, detail 
							* ACL: added `condand' in if stmt - In case of conditional imputation, condition has to be considered when replacing observations that were not imputed.
							replace `x`i''=r(p50) if `touse'==1 & missing(`imputed')
						}
					}
					drop `y' `imputed'
					if `recalc'>0 {	// update passive covariates where necessary
						forvalues l=1/`nvar' {
							if "`exp`l''"!="" & `nimp`l''>0 {
								local nex: word count `excl`l''
								forvalues l2=1/`nex' {
									local exclude: word `l2' of `excl`l''
									if "`x`i''"=="`exclude'" {
										replace `x`l''=`exp`l''
										continue, break
									}
								}
							}
						}
					}
					if !missing("`eststore'") & ("`eststore'" == "`x`i''") {
						// store current estimates
						local ++neststore
						estimates store `eststore'`neststore'
					}
				}
			}
			if `ppwarnings'>0 noi di as txt "]" 
			if `"`trace'"'!="" post `tmp' `posts'
			// !! next line may need checking - should it include & ("`on'"!="")?
			if (`to_imp'==1) & (`cycles_user'>=0) & ("`first'"!="") & ("`warning'"!="nowarning") {
				noi di as text _n "[Only 1 variable to be imputed, therefore no cycling needed]"
			}
			if ("`debug'" != "debug") & ("`verbose'" != "noverbose") noi di as txt "." _cont
			if "`bigdump'"=="bigdump" save _imp`inum'_cycle`j', replace
			/*
			added by ACL - a file is saved (at the working directory) at the end of each cycle/imputation.
			These files could potentially be used for post imputation convergence tests
			*/
		}
	}
}
if `"`trace'"'!="" postclose `tmp'
if "`debug'" != "" postclose `dbg'
if (`neststore' > 0) {
	di as txt _n "[`neststore' sets of estimates for variable `eststore' stored]"
}
* Save to file with cases in original order
quietly {
	local impvl	/* list of newvars containing imputations */
	sort `order'
	forvalues i=1/`nvar' {
		return scalar ni`i'=`nimp`i''
		if "`genmiss'"!="" {
			cap drop `genmiss'`x`i''
			rename `mvar`i'' `genmiss'`x`i''
		}
		local impvl `impvl' `x`i''
		if `main`i'' {
			lab var `x`i'' "`lab`i''"
			cap drop `miss`i''
		}
	}
	// Save imputation model to char _dta[mi_ivar]
	char _dta[mi_ivar] `impvl'
	// char _dta[mi_id] `id'
	rename `order' `id'
	drop `touse'
	save `"`using'"', replace
}
return local impvl `impvl'
return scalar imputed=`to_imp'
// Store commands, y-vars and equations
local neq 0			// no. of non-null equations
forvalues r = 1 / `nvar' {
*	local i `r`r''
local i `r'
	if !missing("`eq`i''") {
		local ++neq
		return local cmd`neq' `cmd`i''
		return local x`neq' `x`i''
		return local eq`neq' `eq`i''
		return local cond`neq' `cond`i''
	}
}
return local neq `neq'
end

program define sampmis, sortpreserve
version 9.2
* Duplicates nonmissing obs of `exp' into missing ones, in random order.
* This routine always reproduces the same sort order among the missings.
* Note technique to avoid Stata creating arbitrary sort order for missing
* observations of `exp'; affects entire reproducibility of mvi sampling.
syntax newvarname =/exp
quietly {
	tempvar u
	* Sort non-missing data at random, sort missing data systematically
	gen double `u' = cond(missing(`exp'), _n, uniform())
	sort `u'
	count if !missing(`exp')
	local nonmis = r(N)
	drop `u'
	local type: type `exp'
	gen `type' `varlist' = `exp'
	local blocks=int( (_N - 1) / `nonmis' )
	forvalues i = 1 / `blocks' {
		local j = `nonmis'*`i'
		local j1 = `j' + 1
		local j2 = min(`j' + `nonmis', _N)
		replace `varlist' = `exp'[_n - `j'] in `j1' / `j2'
	}
}
end

program define ChkIn, sclass
version 9.2
* Returns s(k) = index # of target variable v in varlist, or 0 if not found.
args v varlist
sret clear
local k: list posof "`v'" in varlist
sret local k `k'
if `s(k)' == 0 {
   	di as err "`v' is not a valid covariate"
   	exit 198
}
end

program define ParsExp, sclass
version 9.2
tokenize `"`*'"', parse(" +-/^()[]{}.*=<>!$%&|~`',")
local vl
while ("`1'" != "") {
	cap confirm var `1'
	if (_rc == 0) & ("`1'" != ",") {
		if index("`vl'", "`1'")==0 {
			local vl `vl' `1'
		}
	}
	mac shift
}
sreturn local result `vl'
end

program define detangle
version 9.2
/*
	Disentangle varlist:string clusters---e.g. for DF.
	Returns values in $S_*.
	If `4' is null, `3' is assumed to contain rhs
	and lowest and highest value checking is disabled.
	Heavily based on frac_dis.ado, but "=" disallowed as separator
	and "\" allowed (for use by passive()).
*/
args target tname rhs separator
if "`separator'"=="" {
	local separator ","
}
unab rhs:`rhs'
local nx: word count `rhs'
forvalues j=1/`nx' {
	local n`j': word `j' of `rhs'
}
tokenize "`target'", parse("`separator'")
local ncl 0 			/* # of separator-delimited clusters */
while "`1'"!="" {
	if "`1'"=="`separator'" {
		mac shift
	}
	local ncl=`ncl'+1
	local clust`ncl' "`1'"
	mac shift
}
if "`clust`ncl''"=="" {
	local --ncl
}
if `ncl'>`nx' {
	di as err "too many `tname'() values specified"
	exit 198
}
/*
	Disentangle each varlist:string cluster
*/
forvalues i=1/`ncl' {
	tokenize "`clust`i''", parse(":")
	if "`2'"!=":" {
		if `i'>1 {
			noi di as err "invalid `clust`i'' in `tname'() (syntax error)"
			exit 198
		}
		local 2 ":"
		local 3 `1'
		local 1
		forvalues j=1/`nx' {
			local 1 `1' `n`j''
		}
	}
	local arg3 `3'
	unab arg1:`1'
	tokenize `arg1'
	while "`1'"!="" {
		ChkIn `1' "`rhs'"
		local v`s(k)' `arg3'
		mac shift
	}
}
forvalues j=1/`nx' {
	if "`v`j''"!="" {
		global S_`j' `v`j''
	}
	else global S_`j'
}
end

* Based on artformatnos.ado v 1.0.0 PR 26Feb2004
program define formatline, rclass
version 9.2
syntax, N(string) Maxlen(int) [ Format(string) Leading(int 1) Separator(string) ]

if `leading'<0 {
	di as err "invalid leading()"
	exit 198
}

if "`separator'"!="" {
	tokenize "`n'", parse("`separator'")
}
else tokenize "`n'"

local n 0
while "`1'"!="" {
	if "`1'"!="`separator'" {
		local ++n
		local n`n' `"`1'"'
	}
	macro shift
}
local j 0
local length 0
forvalues i=1/`n' {
	if "`format'"!="" {
		capture local out: display `format' `n`i''
		if _rc {
			di as err "invalid format attempted for: " `"`n`i''"'
			exit 198
		}
	}
	else local out `"`n`i''"'
	if `leading'>0 {
		local out " `out'"
	}
	local l1=length("`out'")
	local l2=`length'+`l1'
	if `l2'>`maxlen' {
		local ++j
		return local line`j'="`line'"
		local line "`out'"
		local length `l1'
	}
	else {
		local length `l2'
		local line "`line'`out'"
	}
}
local ++j
return local line`j'="`line'"
return scalar lines=`j'
end

program define listsort3, sclass sortpreserve
version 9.2
gettoken p 0 : 0, parse(" ,")
if `"`p'"'=="" exit
sret clear
syntax , [ Reverse Lexicographic ]
local lex="`lexicographic'"!=""
if "`reverse'"!="" local comp <
else local comp >
/*
	Need to ensure that we always get the same ranking of
	amounts of missingness. To do this, add (i-1)/(#missings)
	to each amount.
*/
local np: word count `p'
local n1 = _N + 1
if (`np' > _N) {
	set obs `np'
}
tempvar c rank
*qui gen `c'=.
qui gen double `c'=. // PR bug fix 20sep2010.

forvalues i=1/`np' {
	local pi: word `i' of `p'
	if !`lex' confirm number `pi'
	qui replace `c'=`pi'+(`i'-1)/`np' in `i'
}
qui egen long `rank'=rank(`c') // Large numbers of missing values caused problems with ordering `c' correctly.
forvalues i=1/`np' {
/*
	Find original position (antirank) of each rank
*/
	local j 0
	while `j'<`np' {
		local ++j
		if `i'==`rank'[`j'] {
			local index`i' `j'
			local j `np'
		}
	}
}
drop `c' `rank'
if (`np' >= `n1') drop in `n1' / `np'
forvalues i=1/`np' {
	sret local index`i' `index`i''
	local index `index' `index`i''
}
sret local index `index'
end
exit

History (1.2.2 on)
1.4.1 07feb2014 Changed default to matchpool(10)
1.3.1	13apr2011	Fixed bug whereby R2 not reported if conditional() option used
1.2.6	20sep2010	Fixed bug in S/R listsort3 whereby sort ordering could go wrong with v. large #s of imputed values
1.2.2	25may2010	Fixed bug in ParsExp whereby did not parse a comma correctly
