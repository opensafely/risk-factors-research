*! version 1.7.1 PR/IRW/TPM 17jan2011.
// For history, see end of this file
program define uvis, rclass sortpreserve
version 9.2

if `"`0'"'=="" {
	di as err "command required"
	exit 198
}
gettoken cmd 0 : 0

if substr("`cmd'",1,3)=="reg" local cmd regress
local normal=("`cmd'"=="regress")|("`cmd'"=="rreg")|("`cmd'"=="intreg")
local binary=("`cmd'"=="logit")|("`cmd'"=="penlogit")|("`cmd'"=="auglogit")|("`cmd'"=="logistic")
local catcmd=("`cmd'"=="mlogit")|("`cmd'"=="augmlogit")|("`cmd'"=="ologit")|("`cmd'"=="augologit")
local countcmd=("`cmd'"=="nbreg")

if !`normal' & !`binary' & !`catcmd' & !`countcmd' {
	di as err "invalid or unrecognised command, `cmd'"
	exit 198
}

syntax varlist(min=1 numeric) [if] [in] [aweight fweight pweight iweight] , Gen(string) ///
 [ by(varlist) noCONStant Delta(string) BOot INTerval(varlist min=1 max=2) MAtch nopp noVERbose ///
 REPLACE REStrict(string) rn(int 0) SEed(int 0) TOTALweight(passthru) TIMESweight(passthru) ///
 matchtype(int 1) lrd MATCHPool(int 0) * ]
/*
	Option LRD added to perform Local Residual Draws. TPM 21/10/10 
	Option matchtype takes values 1 (default) to use b for observed regression,
	2 to use bstar and 3 to take a second bstar draw or boot estimate of b,
	0 to use b for observed regression with ado-code (match_normal) instead of mata.
*/
if (`matchpool' > 0) & missing("`match'") {
	di as txt "[match not specified, so matchpool(`matchpool') ignored]"
	local matchpool 0
}
if (`matchpool' <= 0) local matchpool
if ("`match'" == "match") {
	if !`normal' {
		di as err "match not allowed with binary, categorical or count data"
		exit 198
	}
	if missing("`matchpool'") local matchpool 3
}
if `"`weight'"' != "" & "`boot'"!="" {
	di as err "boot not allowed with weights"
	exit 198
}

if "`cmd'"=="intreg" & "`match'"!="" {  // interval censored response variables
	di as err "match not allowed with intreg"
	exit 198
}
capture confirm new var `gen'
local rc = c(rc)
if `rc' {
	if "`replace'"!="" drop `gen'
	else {
		di as err "`gen' already defined"
		exit 110
	}
}
if "`verbose'"!="noverbose" {
	local verbosely noi
	if "`match'"=="match" {
		di as text "[imputing by prediction matching" _cont
		if !missing("`matchpool'") di " with matchpool(`matchpool')" _cont
	}
	else di as text "[imputing by drawing from conditional distribution" _cont
	if "`boot'"=="" di as text " without bootstrap]"
	else di as text " with bootstrap]"
}
else local verbosely qui
if "`delta'"!="" & "`cmd'"!="mlogit" { /* IRW */
	capture confirm number `delta'
	if c(rc) {
		di as error "invalid delta(#)"
		exit 198
	}
}
if "`constant'"=="noconstant" {
	local options "`options' nocons"
}
if "`cmd'"=="intreg" {
	gettoken ll rest : varlist
	gettoken ul xvars: rest
	local rest
}
else gettoken y xvars : varlist
tempvar touse

// Set max number of ML iterations to 100 - more than enough for most problems
set maxiter 100

quietly {
	marksample touse, novarlist
	markout `touse' `xvars' /* note: does not include `y' */


	if "`restrict'"!="" {
/*
	-restrict()- becomes part of touse when
	running the estimation command.
*/
		tempvar touse_user
		gen byte `touse_user' = `touse'
		frac_restrict `touse' `restrict'    // `touse' is a subsample of `touse_user'
	}
	else    local touse_user `touse'

	tempvar bygroup
	if "`by'"!="" {
		// Sets up grouping variable corresponding to by-list
		markout `touse' `by', strok
		markout `touse_user' `by', strok
		egen int `bygroup' = group(`by') if `touse_user'
		sum `bygroup', meanonly
		local nby = r(max)
		if `nby'==0 {
			return local errmess "no valid observations"
			noisily error 2000
		}
	}
	else {
		gen byte `bygroup' = 1 if `touse_user'
		local nby 1
	}

	// Deal with weights
	frac_wgt `"`exp'"' `touse_user' `"`weight'"'
	local wgt `r(wgt)'

	if `seed'!=0 {
		set seed `seed'
	}

	if "`cmd'"=="intreg" {
		tempvar y
		gen `y' = cond(missing(`ll') & missing(`ul'), ., 0) if `touse_user'==1 // 0 is arbitrary
		local yvarlist `ll' `ul'
	}
	else local yvarlist `y'

	local type: type `y'
	tempvar obstype yimp Yimp xb u
	gen `type' `yimp' = .
	gen `type' `Yimp' = .
	gen byte `obstype' = .
	gen double `u' = .

	tempname b e V chol bstar

	local Nmis 0
	local Nobs 0

	forvalues g=1/`nby' {   // start of by-group loop
		local ifg if `bygroup'==`g' & `touse'==1
		local ifg_user if `bygroup'==`g' & `touse_user'==1

		// Code types of missings: 1=non-missing y, 2=missing y, 3=other missing
		replace `obstype' = ///
		   1*(`touse_user'==1 & !missing(`y')) ///
		 + 2*(`touse_user'==1 &  missing(`y')) ///
		 + 3*(`touse_user'==0)
		replace `obstype' = 3 if `bygroup'!=`g'

		count if `obstype'==1
		local nobs = r(N)
		if `nobs' <= 2 {
			if `nobs' == 0 {
				local errmess no
				local errno 2000
			}
			else {
				local errmess insufficient
				local errno 2001
			}
			local errmess "`errmess' observations on which to estimate model"
			if `nby' > 1 local errmess "`errmess' in subgroup `i'"
			return local errmess = `"`errmess'"'
			noisily di as err `"`return(errmess)'"'
			exit `errno'
		}
		count if `obstype'==2
		local nmis = r(N)
		local Nobs = `Nobs' + `nobs'
		local Nmis = `Nmis' + `nmis'

		// Fit imputation model and extract b and V
		capture `cmd' `yvarlist' `xvars' `wgt' `ifg', `options'
		local errno = c(rc)
		if `errno'>0 {
			if ("`cmd'"=="logit" | "`cmd'"=="logistic") & `errno'==2000 {
				local pp_cmd `cmd'
				return local errmess "error 2000 - may be caused by 100% perfect prediction of the response on`xvars'"
				noisily di as err `"`return(errmess)'"'
			}
			else if !(`errno'==430 & "`cmd'"=="ologit") error `errno'    // ignore non-convergence in ologit
		}
		nagelkerke2
		local r2 = r(r2)
/*
	In the case of categorical regression, perform checks
	and use auglogit/augologit/augmlogit if perfect prediction detected.
*/
		if `errno' != 2000 {
			pp_check `cmd'
			local pp_cmd `s(cmd)'
		}
		if "`pp_cmd'"!="" {
			`verbosely' di as txt "[perfect prediction detected: " _cont
			if "`pp'"!="nopp" {
				tempvar augvar wtvar
				`verbosely' di as txt "using aug`pp_cmd' to impute " as res "`yvarlist'" as txt "]"
				capture aug `yvarlist' `xvars' `wgt' `ifg', cmd(`pp_cmd') `options' ///
				 augvar(`augvar') wtvar(`wtvar') `totalweight' `timesweight'
				clean_aug `augvar' `wtvar'
				nagelkerke2
				local r2 = r(r2)
			}
			else `verbosely' di as text "no action taken]"
		}

		// !! not sure if this bit is in the right place - maybe after bootstrap fit
		if `catcmd' {
			if `g'==1 tempname cat
/*
	mlogit version 10 outputs no. of categories in e(out) and base category in e(baseout).
	mlogit version 9.x outputs these in both e(out) and e(cat), similarly for base category.
	Use e(out) and e(baseout) for compatibility with version 10.
	ologit version 9.x and 10 outputs only in e(cat) and e(basecat).
*/
			local cat_out = cond("`cmd'" == "mlogit", "out", "cat")
			local nclass = e(k_`cat_out')   // number of classes in (ordered) categoric variable
			matrix `cat' = e(`cat_out') // row vector giving actual category values
			local cuts = `nclass' - 1
		}

		if "`boot'" == "" {
			// Proper imputation of beta and rmse
			drawbeta, cmd(`cmd')
			matrix `b' = r(b)
			matrix `V' = r(V)
			local colsofb = r(colsofb)
			matrix `bstar' = r(bstar)
			if `normal' local rmsestar = r(rmsestar)
		}
		else {
			// Draw boot sample and refit model
			drawbeta, cmd(`cmd') nodraw
			matrix `b' = r(b)
			matrix `V' = r(V)
			local colsofb = r(colsofb)
			if `g'==1 {
				tempvar wt
				gen long `wt' = .
			}
			bsample if `obstype' == 1, weight(`wt')
			// If pp detected and fixed on original data, do same on boot sample
			if "`pp_cmd'" != "" & "`pp'" != "nopp" {
				drop if `augvar'
				capture aug `yvarlist' `xvars' `wgt' [fweight = `wt'] `ifg', cmd(`pp_cmd') `options' ///
				 augvar(`augvar') wtvar(`wtvar') `totalweight' `timesweight'
				clean_aug `augvar' `wtvar'
			}
			else {
				capture `cmd' `yvarlist' `xvars' [fweight = `wt'] `ifg', `options'
			}
			drawbeta, cmd(`cmd') nodraw
			matrix `bstar' = r(b)
			if `normal' local rmsestar = r(rmse)
		}
		if `binary' | `catcmd' {
			if ("`boot'" == "") & ("`cmd'" != "penlogit") {
				// Evaluate normal approximation in categorical case
				if `g'==1 tempname normapprox
				matrix `normapprox' = (`bstar' - `b') * syminv(`V') * (`bstar' - `b')'
				noisily catlik, b(`b')
				local llhat = r(loglik)
				noisily catlik, b(`bstar')
				local llstar = r(loglik)
				local diagnostic = `llstar' - `llhat' + `normapprox'[1, 1] / 2
				`verbosely' di as text "[true/approx likelihood = " %5.3f as res exp(`llstar' - `llhat') ///
				 as text "/" %5.3f as res exp(-`normapprox'[1,1]/2) ///
				 as text " = " %5.3f as res exp(`diagnostic') as text "]"
			}
			// Remove augmented observations, if perfect prediction has had to have been dealt with
			if "`augvar'" != "" {
				drop if `augvar'
				if `g' == `nby' drop `augvar' `wtvar'
			}
		}
		// Draw y, based on Ian White's code to implement van Buuren et al (1999).
		replace `u' = uniform()
		if `normal' | `binary' {
			// in normal or binary case, impute by sampling conditional distribution
			// or in normal case, by PMM
			if "`match'" == "match" | "`matchpool'"!="" {
				// predictive mean matching - only allowed for `normal' data
				if `g' == 1 {
					tempvar etaobs etamis
					if ("`lrd'" == "lrd") tempvar etaobsfull /* etaobsfull added by TPM 21/10/10 */
				}
				else {
					if ("`lrd'" == "lrd") drop `etaobsfull'
					drop `etaobs' `etamis'
				}
				matrix score `etamis' = `bstar' if `obstype' == 2
				// Include non-response location shift, delta.
				if "`delta'"!="" {
					replace `etamis' = `etamis' + `delta'
				}
				if `matchtype' <= 1 {   // default is 1
					// etaobsfull is required to use LRD option. TPM 21/10/10
					if ("`lrd'" == "lrd") matrix score `etaobsfull' = `b'
					matrix score `etaobs' = `b' if `obstype' == 1
				}
				else if `matchtype' == 2 {
					if ("`lrd'" == "lrd") matrix score `etaobsfull' = `bstar'       /* TPM 21/10/10 */
					matrix score `etaobs' = `bstar' if `obstype' == 1
				}
				else if `matchtype' == 3 {
					// take a new draw for etaobs
					if `g' == 1 tempname bstar2
					if "`boot'" == "" {
						drawbeta, cmd(`cmd')
						matrix `bstar2' = r(bstar)
					}
					else {
						bsample if `obstype' == 1, weight(`wt')
						capture `cmd' `yvarlist' `xvars' [fweight = `wt'] `ifg', `options'
						drawbeta, cmd(`cmd') nodraw
						matrix `bstar2' = r(b)
					}
					if ("`lrd'" == "lrd") matrix score `etaobsfull' = `bstar2'      /* TPM 21/10/10 */
					matrix score `etaobs' = `bstar2' if `obstype' == 1
				}
				sort `obstype' `etaobs', stable
				if `matchtype' == 0 & "`matchpool'"=="" {
					// use ado-code for pmm
					match_normal `obstype' `nobs' `nmis' `etaobs' `etamis' `yimp' `y'
				}
				else {
					// use Mata for pmm
					tempvar resimp
					gen `resimp' = .
					capture noi mata: _matchpool_normal_mata(`nmis', `matchpool')
					if c(rc) {
						noi di as err "_matchpool_normal_mata execution error"
						exit c(rc)
					}
					if ("`lrd'" == "lrd") { // Replaces PMM-imputed value with a LRD. TPM 21/10/10
						cap confirm var `resimp' // IRW 6dec2010
						if _rc di as error "LRD error: variable resimp does not exist" // IRW 6dec2010
						replace `yimp' = `etaobsfull' + `resimp' if `obstype' == 2  // IRW 6dec2010
					}
					if (`rn' > 0) replace `yimp' = `yimp' + sqrt(`rmsestar') * rnormal() if `obstype' == 2
				}
			}
			else {
				// sampling conditional distribution
				capture drop `xb'
				matrix score `xb' = `bstar' `ifg_user'
				if "`e(offset)'"!="" replace `xb' = `xb'+`e(offset)'
				if "`delta'"!="" {
					replace `xb' = `xb'+`delta' if `obstype'==2
				}
				if `normal' {
					if "`cmd'"=="intreg" {
						if `g'==1 tempvar PhiA PhiB
						else drop `PhiA' `PhiB'
						gen double `PhiA' = cond(missing(`ll'), 0, norm((`ll'-`xb')/`rmsestar'))
						gen double `PhiB' = cond(missing(`ul'), 1, norm((`ul'-`xb')/`rmsestar'))
						replace `yimp' = `xb'+`rmsestar'*invnormal(`u'*(`PhiB'-`PhiA')+`PhiA')
					}
					else replace `yimp' = `xb'+`rmsestar'*invnormal(`u')
				}
				else replace `yimp' = (`u'<invlogit(`xb')) if !missing(`xb')
			}
		}
		else if `countcmd' {
/*
	Negative binomial sampling.
	Ian White's reasoning for the negative binomial parameters:

	Set V = exp(2 * `bb'[1,1]) & B = exp(`xb').

	I had A = Gamma(1/V,V) (using Wikipedia's definition of shape and scale)
	and Yimp|A = Poisson(AB). A = Gamma(1/V,V) is the same as AB = Gamma(1/V,BV).

	Again from Wikipedia, rnbinomial(r,p) is the same as Poisson(lambda)
	where lambda~Gamma(r,(1-p)/p).

	So I set (r,(1-p)/p) = (1/V,BV), i.e. r = 1/V and p = 1/(1 + BV).
	In the case V->0, lambda->B.
*/
			matrix score `xb' = `bstar' `ifg'
			if "`e(offset)'"!="" replace `xb' = `xb'+`e(offset)'
			if `g'==1 {
				tempname bb variance
			}
			matrix `bb' = `bstar'[1,"lnalpha:_cons"]
			scalar `variance' = exp(2 * `bb'[1,1])
			drop `yimp'
			if `variance' > 0.00001 {
				local parm1 = 1 / `variance'
				local parm2 = 1 / (1 + exp(`xb') * `variance')
				if (`parm1' < 0.1) | (`parm1' > 100000) {
					di as err "First parameter out of range in rnbinomial(`parm1', `parm2')"
					exit 498
				}
				count if (`parm2' < 0.0001) | (`parm2' > 0.9999)
				if r(N) {
					di as error "Second parameter out of range in rnbinomial(`parm1', `parm2')"
					exit 498
				}
				gen `yimp' = rnbinomial(`parm1', `parm2')
			}
			else gen `yimp' = rpoisson(exp(`xb'))
			replace `yimp' = 0 `ifg' & missing( `yimp' )
			drop `xb'
		}
		else {  // catcmd
			// draw: sample conditional distribution
			replace `yimp' = `cat'[1,1]
			if "`cmd'"=="ologit" {
				// Predict index independent of cutpoints
				// (note use of forcezero option to circumvent missing _cut* vars)
				matrix score `xb' = `bstar' `ifg_user', forcezero
				if "`e(offset)'"!="" replace `xb' = `xb'+`e(offset)'
				if "`delta'"!="" {
					replace `xb' = `xb'+`delta' if `obstype'==2
				}
				forvalues k=1/`cuts' {
					// invlogit(...) is probability of being in category 1 or 2 or ... k
					local cutpt = `bstar'[1, `k'+`colsofb'-`cuts']
					replace `yimp' = `cat'[1,`k'+1]  if `u'>invlogit(`cutpt'-`xb')
				}
				drop `xb'
			}
			else {  // mlogit
				// care needed dealing with different possible base categories
				if `g'==1 tempvar cusump sumexp
				else drop `cusump' `sumexp'
				local basecat = e(baseout)    // actual basecategory chosen by Stata
				gen `sumexp' = 0 `ifg_user'
				if "`delta'"!="" {
					numlist "`delta'"
					local deltalist `r(numlist)'
					if word("`deltalist'",`nclass'+1)!="" {
						di as error "Length of delta() is greater than #categories"
						exit 198
					}
				}
				// mlogit counts equation numbers from 1 and excludes the basecat
				local eqno 0
				forvalues i=1/`nclass' {
					if `g'==1 tempvar xb`i'
					else drop `xb`i''
					local thiscat = `cat'[1,`i']
					if `thiscat'==`basecat' {
						gen `xb`i'' = 0 `ifg_user'
					}
					else {
						local ++eqno
						matrix score `xb`i'' = `bstar' `ifg_user', equation(#`eqno')
					}
					if "`delta'"!="" {
						local thisdelta: word `i' of `deltalist'
						capture confirm number `thisdelta'
						if _rc {
							di as error "Length of delta() is less than #categories"
							exit 198
						}
						replace `xb`i'' = `xb`i''+`thisdelta'
					}
					replace `sumexp' = `sumexp' + exp(`xb`i'')
				}
				gen `cusump' = exp(`xb1')/`sumexp'
				forvalues i=2/`nclass' {
					replace `yimp' = `cat'[1,`i']  if `u'>`cusump'
					replace `cusump' = `cusump'+exp(`xb`i'')/`sumexp'
					replace `yimp' = . if missing(`xb`i'')
				}
			}
		}
		replace `Yimp' = `yimp' if `bygroup'==`g'
	}   // end of by-group loop
	rename `Yimp' `gen'
	if "`cmd'"=="intreg" replace `gen' = `ll' if !missing(`ll') & `ll'==`ul'      // uncensored
	else replace `gen' = `y' if !missing(`y')
	lab var `gen' "imputed from `yvarlist'"
}
`verbosely' di _n as res `Nmis' as txt " missing observations on " as res "`yvarlist'" ///
 as txt " imputed from " as res `Nobs' as txt " complete observations."
return local pp_cmd `pp_cmd'
return matrix b = `b'
return matrix V = `V'
return matrix bstar = `bstar'
if `normal' return scalar rmsestar = `rmsestar'
return scalar r2 = `r2' * 100
end

program define _augment, rclass
version 9.2
syntax varlist [if] [in] [fweight pweight aweight iweight], [TOTALweight(real 0) TIMESweight(real 0) ///
noPREServe list wtvar(string) augvar(string) usevar(string) noequal]

if "`wtvar'"=="" local wtvar _weight
if "`augvar'"=="" local augvar _augment
capture confirm new var `wtvar'
if c(rc) drop `wtvar'
capture confirm new var `augvar'
if c(rc) drop `augvar'

marksample touse
gettoken y xlist: varlist

// Remove collinearities
_rmcoll `xlist' if `touse'
local xlist `r(varlist)'
local nx: word count `xlist'
if `nx' == 0 {
	local errmess "insufficient predictors to perform perfect prediction"
	noisily di as err `"`errmess'"'
	return local errmess = "`errmess'"
	exit 2001
}

tempvar augment wt
if "`weight'"!="" gen `wt' `exp'
else gen `wt' = 1

qui levelsof `y' if `touse', local(ylevels)
qui tab `y' if `touse' & `wt'>0                             /* IRW 12may2008 */
local nylevels = r(r)                                       /* IRW 12may2008 */
qui summ `y' if `touse' [iweight=`wt'], meanonly            /* IRW 12may2008 */
local totw = r(N)                                           /* IRW 12may2008 */
local Nold = _N

// Set total weight of added observations
if `totalweight'>0 & `timesweight'>0 {
	di as error "Can't specify totalweight() and timesweight()"
	exit 498
}
if `totalweight' == 0 {
	local totalweight = `nx' + 1                                /*IRW: matches Clogg++91 and Firth93 */
	if `timesweight'>0 local totalweight = `totalweight' * `timesweight'
}
/* global augmented `totalweight' */
// Number of added observations
local Nadd = `nx'*2*`nylevels'
local Nnew = `Nold'+`Nadd'

di as text "Adding " as result `Nadd' as text " pseudo-observations with total weight " as result `totalweight'

quietly {
	set obs `Nnew'
	gen `augment' = _n>`Nold'
	gen byte `usevar' = `touse' | `augment' // picks up augmented observations
	local thisobs `Nold'
	foreach x of var `xlist' {
		sum `x' [iweight=`wt'] if `touse' & !`augment'
		local mean = r(mean)
		local sd = r(sd) * sqrt((r(N) - 1) / r(N))
		replace `x' = `mean' if `augment'
		foreach yval in `ylevels' {
			sum `wt' if `y' == `yval' & `touse' & !`augment', meanonly
			local py = cond("`equal'" == "noequal", r(sum) / `totw', 1 / `nylevels')
			foreach xnewstd in -1 1 {
				local ++thisobs
				replace `x' = `mean' + (`xnewstd') * `sd' in `thisobs'
				replace `y' = `yval' in `thisobs'
				replace `wt' = `totalweight' * `py' / (2 * `nx') in `thisobs'
			}
		}
	}
	if "`e(offset)'"!="" {
		sum `e(offset)' if `touse'
		replace `e(offset)' = r(mean) if `augment'
	}
}

rename `wt' `wtvar'
rename `augment' `augvar'

if "`list'" == "list" {
	di as txt _newline "Listing of added records:"
	list `xlist' `y' `wtvar' if `augvar', sep(4)
}
// In case of collinearity, return the trimmed list of predictors
return local varlist `y' `xlist'
end

program define aug, rclass
syntax varlist [if] [in] [fweight pweight], cmd(string) [TOTALweight(passthru) ///
 TIMESweight(passthru) wtvar(string) augvar(string) equal *]
if "`wtvar'"=="" tempvar wtvar
if "`augvar'"=="" tempvar augvar
if "`weight'"!="" local weightexp [`weight'`exp']
tempvar touse
_augment `varlist' `if' `in' `weightexp', `totalweight' `timesweight' `equal' wtvar(`wtvar') augvar(`augvar') usevar(`touse')
local varlist `r(varlist)'          // old varlist minus collinear vars if present
local wttype=cond("`weight'"=="pweight","pw","iw")
`cmd' `varlist' if `touse' [`wttype'=`wtvar'], `options'  // `cmd' is logit, ologit or mlogit - returned in `s(cmd)' by pp_check
end

program define pp_check, sclass
version 9.2
/*
	Check for perfect prediction in logistic regression.
	If found, use aug to fit model.
*/
args cmd
sreturn clear
if "`cmd'"=="logit" | "`cmd'"=="logistic" {
	tempname erules
	// Check if rules invoked or perfect prediction found
	matrix `erules' = e(rules)
	local c = colsof(`erules')
	local nperfect = e(N_cdf)+e(N_cds)
	if missing(`nperfect') local nperfect 0
	forvalues nc = 1/`c' {
		local nperfect = `nperfect'+(`erules'[1, `nc'] > 0)
	}
	if `nperfect'>0 {
		// rules or perfect prediction found - will invoke auglogit
		sreturn local cmd logit
	}
}
else if "`cmd'"=="ologit" {
	// Check if perfect prediction found
	if e(N_cd)>0 {
		// perfect prediction found - will invoke augologit
		sreturn local cmd ologit
	}
}
else if "`cmd'"=="mlogit" {
	// Check if perfect prediction found
	levelsof `e(depvar)' if e(sample), local(ylevels)
	tempvar p
	foreach level in `ylevels' {
		predict `p', outcome(`level')
		sum `p', meanonly
		if r(min)<1E-9 {    // perfect prediction - will invoke augmlogit
			sreturn local cmd mlogit
			continue, break
		}
		drop `p'
	}
}
end

program define catlik, rclass
// Return log-likelihoods for logit/mlogit/ologit at a given parameter vector b
syntax, b(string)
local y `e(depvar)'
local cmd `e(cmd)'
tempvar wt
if "`e(wtype)'"!="" gen double `wt' `e(wexp)'
else gen double `wt'=1
/*
if "`e(offset)'"!="" {
	di as error "catlik: offset not allowed"
	exit 498
}
*/
quietly {
	if "`cmd'"=="mlogit" | "`cmd'"=="ologit" {
		tempname ecat
		local cat_out = cond("`cmd'" == "mlogit", "out", "cat")
		matrix `ecat' = e(`cat_out')
		local nylevels = e(k_`cat_out')
		tempvar ll xb psum
		gen double `ll' = .
	}
	if "`cmd'"=="mlogit" {
		gen double `psum' = 1
		local eqno 1
		forvalues i=1/`nylevels' {
			capture drop `xb'
			local yval = `ecat'[1,`i']
			if `yval'!=e(baseout) {
				matrix score `xb' = `b', eq(#`eqno')
				if "`e(offset)'"!="" replace `xb' = `xb'+`e(offset)'
				replace `psum' = `psum'+exp(`xb')
				replace `ll' = `xb' if `y' == `yval'
				local ++eqno
			}
			else gen double `xb' = 0
			replace `ll' = `xb' if `y'==`yval'
		}
		replace `ll' = `ll' - log(`psum')
	}
	else if "`cmd'"=="ologit" {
		tempvar p psumlag
		gen double `p' = .
		gen double `psumlag' = 0
		matrix score `xb' = `b'
		if "`e(offset)'"!="" replace `xb' = `xb'+`e(offset)'
		forvalues i = 1/`nylevels' {
			local yval = `ecat'[1,`i']
			if `i'<`nylevels' {
				local cut = `b'[1,colsof(`b')-`nylevels'+`i'+1]
				replace `p' = invlogit(`cut'-`xb')-`psumlag'
				replace `psumlag' = `psumlag'+`p'
			}
			else replace `p' = 1-`psumlag'
			replace `ll' = log(`p') if `y' == `yval'
		}
	}
	else if "`cmd'"=="logit" | "`cmd'"=="logistic" {
		tempvar ll xb
		matrix score `xb' = `b'
		if "`e(offset)'"!="" replace `xb' = `xb'+`e(offset)'
		gen double `ll' = (`y'!=0)*`xb'-log(1+exp(`xb'))
	}
	else {
		di as error "catlik doesn't work after regression command `cmd'"
		exit 498
	}
	replace `ll' = `wt'*`ll'
	sum `ll' if e(sample), meanonly
	return scalar loglik = r(sum)
}
end

program define drawbeta, rclass
version 9.2
//Taken from uvis.ado
syntax, cmd(string) [nodraw tweak(real 1E-12)]

local normal = ("`cmd'" == "regress") | ("`cmd'" == "rreg") | ("`cmd'" == "intreg")

tempname b V chol
matrix `b' = e(b)
matrix `V' = e(V)

// intreg tags the lnsigma model onto the end of e(b) and e(V) - must be stripped
if "`cmd'" == "intreg" {
	matrix `b' = `b'[1, "model:"]
	matrix `V' = `V'["model:", "model:"]
}
local p = colsof(`b')

return scalar colsofb = colsof(`b')

if "`draw'" == "nodraw" {
	if `normal' {
		tempname rmse
		if "`cmd'" == "intreg" {
			scalar `rmse' = exp([lnsigma]_b[_cons])
		}
		else {
			scalar `rmse' = e(rmse)
		}
		return scalar rmse = `rmse'
	}
}
else {
	capture matrix `chol' = cholesky(`V')
	local rc = c(rc)
	if `rc' == 506 {
		matrix `chol' = cholesky((`tweak' * trace(`V')/`p') * I(`p') + `V')
	}
	else if `rc' > 0 {
		di as err "Cholesky decomposition failed with error " `rc'
		exit `rc'
	}
	if `normal' {
		// draw rmse
		tempname rmse df chi2 rmsestar
		if "`cmd'" == "intreg" {
			scalar `rmse' = exp([lnsigma]_b[_cons])
			scalar `df' = e(N) - `p'
		}
		else {
			scalar `rmse' = e(rmse)
			scalar `df' = e(df_r)
		}
		scalar `chi2' = 2 * invgammap(`df' / 2, uniform())
		scalar `rmsestar' = `rmse' * sqrt(`df' / `chi2')
		matrix `chol' = `chol' * sqrt(`df' / `chi2')
		return scalar rmsestar = `rmsestar'
	}
	// draw beta
	tempname e bstar
	matrix `e' = J(1, `p', 0)
	forvalues i = 1 / `p' {
		matrix `e'[1, `i'] = invnormal(uniform())
	}
	matrix `bstar' = `b' + `e' * `chol''
	return matrix bstar = `bstar'
	return matrix chol = `chol'
}
return matrix b = `b'
return matrix V = `V'
end

program define match_normal
* Prediction matching, normal or binary case.
args obstype nobs nmis etaobs etamis yimp y
quietly {
	* For each missing obs j, find index of observation
	* whose etaobs is closest to etamis[j].
	tempvar sumgt
	tempname etamisi
	gen long `sumgt'=.
	* Sort etaobs within obstype
	sort `obstype' `etaobs', stable
	forvalues i=1/`nmis' {
		local j=`i'+`nobs'
		scalar `etamisi'=`etamis'[`j']
		replace `sumgt'=sum((`etamisi'>`etaobs')) in 1/`nobs'
		sum `sumgt', meanonly
		local j1=r(max)
		if `j1'==0 {
			local index 1
			local direction 1
		}
		else if `j1'==`nobs' {
			local index `nobs'
			local direction -1
		}
		else {
			local j2=`j1'+1
*           if (`etamisi'-`etaobs'[`j1'])<(`etaobs'[`j2']-`etamisi') {
			if (2*`etamisi') < (`etaobs'[`j1']+`etaobs'[`j2']) {    // slightly faster
				local index `j1'
				local direction -1
			}
			else {
				local index `j2'
				local direction 1
			}
		}
*       In case of tied etaobs values, add random offset to index in the appropriate direction
*       count if `obstype'==1 & reldif(`etaobs', `etaobs'[`index'])<1e-7 // counts as equality
		count if `obstype'==1 & `etaobs'==`etaobs'[`index'] // slightly faster
		if r(N)>1 {
			local index=`index'+`direction'*int(uniform()*r(N))
		}
		replace `yimp'=`y'[`index'] in `j'
	}
}
end

program define clean_aug
version 9.2
// Clean up after failed aug command
args augvar wtvar
local rc = c(rc)
if `rc' > 0 {
	drop if `augvar'
	drop `augvar' `wtvar'
	error `rc'
}
end

program define nagelkerke2, rclass
version 9.2
tempvar touse
cap gen byte `touse' = e(sample)
if c(rc) error 301
local cmd `e(cmd2)'
if missing("`cmd'") local cmd `e(cmd)'
if inlist("`cmd'", "stcox", "cox", "streg", "stpm") {
	qui count if (_d == 1) & (e(sample) == 1)
	local n = r(N)
	local obs events
}
else {
	qui count if (e(sample) == 1)
	local n = r(N)
	local obs observations
}
if missing(e(ll_0)) local r2 = 1 - exp(-1 * e(chi2) / `n')
else local r2 = 1 - exp(-2 * (e(ll) - e(ll_0)) / `n')
di as txt _n "Nagelkerke R-squared = " as res %9.6f `r2' as txt " (" as res `n' as txt " `obs')"
return scalar r2 = `r2'
return scalar  N = `n'
end

version 9.2
mata:
mata set matastrict on

void _matchpool_normal_mata(real scalar nmis, real scalar k)
{
	real colvector etaobs, etamis, y, index, dif, Wsum
	real matrix W
	real scalar i, i0, nobs, neta, ind, yimpind

	// get variable index of temporary variable yimp
	yimpind = st_varindex(st_local("yimp"))
	resimp = st_varindex(st_local("resimp")) // IRW 6dec2010
	// create views to store other variables
	st_view(etaobs=.,.,st_local("etaobs"))
	st_view(etamis=.,.,st_local("etamis"))
	st_view(y=.,.,st_local("y"))

	// select only nonmissing values of etaobs
	etaobs = select(etaobs, (etaobs:!=.))
	neta = rows(etaobs)
	if (neta==0) {
		errprintf("_matchpool_normal_mata(): missing predictions encountered\n")
		exit(498)
	}
	// nobs are the effective number of observations, ignoring obstype 3 ones
	nobs = neta + nmis
	i0 = neta + 1

	// looping over missing values
	for (i=i0; i<=nobs; i++) {
		if (etamis[i]==.) {
			errprintf("_matchpool_normal_mata(): missing predictions encountered\n")
			exit(498)
		}
		// find k predictions closest to etamis[i]
		dif = etaobs:-etamis[i]
		minindex(abs(dif), k, index, W)
		Wsum = runningsum(W[.,2])
		s = sum(Wsum:<=k)
		ind = trunc(k*uniform(1,1))+1
		// Start of Ian's new code to replace
		// if (ind>Wsum[s]) ind = Wsum[s] + trunc(W[s+1,2]*uniform(1,1)) + 1
		if (s>0) Wsums=Wsum[s]
		else Wsums=0
		unif=uniform(1,1)
		if (ind>Wsums)
		// End of Ian's new code
		ind = Wsums + trunc(W[s+1,2]*unif) + 1
		// store imputed values in temporary variable yimp
		_st_store(i, yimpind, y[index[ind]])
		// and store imputed residuals in temporary variable resimp, IRW 6dec2010
		_st_store(i, resimp, y[index[ind]]-etaobs[index[ind]]) // IRW 6dec2010
	}
}
end
exit
	History

1.7.1 17jan2011 Fixes to LRD with matchpool() (IRW).
				Removed match_normal_mata() - redundant.
1.7.0 02dec2010 Added undocumented option -lrd- to implement LRD (Tim Morris).
1.6.1 13jul2010 Bug in parsing/use of match/matchpool() fixed.
1.6.0 10jun2010 -matchpool()- improved.
1.5.9 26apr2010 Added support for PMM based on Schenker and Taylor 1996 algorithm (new -matchpool()- option).
1.5.8 02dec2009 Allowed any variable (not just in mainvarlist) in right hand side of passive() expressions.
	  Experimental option rn(#) to add random normal noise to match imputations
1.5.7 19nov2009 Added Nagelkerke R2 to -debug- option.
	  Improved support for -uvis penlogit-.
1.5.6 21oct2009 Added support for e(offset). Fixed bug in support for negative binomial.
1.5.5 13may2009 Fixed bug in by() with perfect prediction.
1.5.4 05may2009 Fixed bug in subprogram aug - missing `if' `in'.
1.5.3 21apr2009 Tidy up after perfect prediction - otherwise could get the augmented observations.
	  Issue with weights in augment sorted out.
1.5.2 16apr2009 Fixed bug with use of mlogit - sometimes failed to pick up correct equations.
1.5.1 14feb2009 Fixed bug in _match_normal_mata().  In the case of ties,
	  the command could perform a random shift in the wrong direction.
	  This was due to the inconsistent definition of ties used to
	  compute the number of ties ( reldif(a,b)<1e-7 is used) and to
	  determine the indices of ties (a==b was implied).  This has been
	  fixed.
1.5.0 11feb2009 Major code tidy-up.
1.4.4 19dec2008 Fixed precision issue that allowed uniform random numbers to be 0 or 1 in rare cases.
1.4.3 02oct2008 Minor bug fixes and refinements.
1.4.2 19sep2008 Further refinements to modelling perfect prediction
	Fixed bug in perfect prediction with by()
1.4.1 11sep2008 Fix bug in match option - Mata code did not allow missing observations (obstype=3)
	Add timesweight() and totalweight(); allowed penalogit (IRW).
	by() option added to do imputation within levels of a byvarlist
	(no)verbose option added to suppress messages
1.4.0 17jun2008 Add restrict() option to assist out-of-sample computations.
	Add cmd(nbreg) for count data (Ian White).
1.3.0 14may2008 Major speed improvements to match_normal, by recoding in Mata (thanks Yulia Marchenko).
1.2.8 12may2008 Minor speed improvements to match_normal, including remove unnecessary scalars count*.
	Bug in _augment when dealing with weights of different types fixed
1.2.7 04dec2007 Likelihood check for -logit-, -ologit- and -mlogit- from Ian White.
1.2.6 10nov2007 Updated version of -auglogit-, -augologit-, -augmlogit- from Ian White, changes # of augmented cases.
1.2.5 10oct2007 Updated version of -auglogit- from Ian White, also including -augologit-, -augmlogit-.
	nopp option added to suppress avoidance of perfect prediction bug.
1.2.4 31jul2007 Improved version of -auglogit- from Ian White.
1.2.3 30mar2007 Minor changes to -auglogit- and -pp_check- from Ian White.
1.2.2 27mar2007 Check for perfect prediction in logistic regression; new routine pp_check.
	Replace log(p/(1-p)) with logit(p), similarly for invlogit.
1.2.1 15dec2006 Allow -auglogit- to deal with perfect prediction in logistic regression.
1.2.0 30jun2006 Interval censoring implemented via interval() option.
1.1.0 03aug2005 Replace -draw- option with -match-. Default becomes draw.
	With prediction matching, randomly sort observations with identical predictions.
	Order variables in chained equations in order of increasing missingness.
1.0.4 21jun2005 Add sort, stable to enable reproducibility imputations with given seed
