*! v 1.0.0 PR 16oct2015
program define stpm2grp, rclass sortpreserve
version 10
st_is 2 full
syntax [if] [in] , mean(string) [ by(varlist) km(string) Timevar(varname) ]
if "`e(cmd)'" != "stpm2" error 302
if "`e(tvc)'" != "" {
	di as err "models with time-dependent terms not supported"
}
local xbeta `e(varlist)'
local nv : word count `xbeta'
if `nv' > 1 {
	di as err "only one variable allowed in Royston-Parmar model"
	exit 198
}
quietly {
	tempvar ggroup covpat s
	marksample touse
	markout `touse' `by'
	
	if "`timevar'" == "" local t _t
	else local t `timevar'

	// Create `at' from `t' for use by -sts list- with km() option
	if "`km'" != "" & "`timevar'" != "" {
		count if !missing(`t')
		local nt = r(N)
		sort `t'
		local at
		forvalues i = 1 / `nt' {
			local t_i = `t'[`i']
			local at `at' `t_i'
		}
	}

	// Code for creating grouping variable taken from_ggroup.ado
	sort `touse' `by'
	by `touse' `by': gen int `ggroup' = 1 if _n==1 & `touse'==1
	replace `ggroup' = sum(`ggroup')
	replace `ggroup' = . if `touse'!=1
	sum `ggroup' if `touse'==1, meanonly
	local ngroups = r(max)

	// Create covariate patterns from xbeta
	covpat `xbeta' if `touse', gen(`covpat')
	sum `covpat', meanonly
	local ncovpat = r(max)

	// Compute mean survival curves in groups defined by `by'
	forvalues j = 1 / `ngroups' {
		tempvar surv`j'
		tempname n`j'
		scalar `n`j'' = 0
		gen double `surv`j'' = 0 if !missing(`t')
	}
	tempname f
	noi di as text "Processing " `ncovpat' " distinct values of " as res "`xbeta'" as txt " ... " _cont
	forvalues i = 1 / `ncovpat' {
		if mod(`i',100)==0 {
			noi di as txt `i', _cont
		}
		sum `xbeta' if `covpat'==`i' & `touse'==1
		local XB = r(mean)
		predict double `s', survival at(`xbeta' `XB') timevar(`t')
		forvalues j = 1 / `ngroups' {
			count if `covpat'==`i' & `ggroup'==`j'
			scalar `f' = r(N)
			if `f'>0 {
				replace `surv`j'' = `surv`j''+`f'*`s'
				scalar `n`j'' = `n`j''+`f'
			}
		}
		drop `s'
	}
	forvalues j = 1 / `ngroups' {
		if (`n`j'' > 0) replace `surv`j'' = `surv`j'' / `n`j''
	}
	noi di as text "done."

	// Store mean survival curves to mean*
	forvalues j = 1 / `ngroups' {
		cap drop `mean'`j'
		if `n`j'' > 0 {
			rename `surv`j'' `mean'`j'
		}
	}
	if "`km'"!="" {
		// Store kaplan-meier curves and CI to km*, km_lb* and km_ub*
		forvalues j = 1 / `ngroups' {
			cap drop `km'`j'
			cap drop `km'_lb`j'
			cap drop `km'_ub`j'
		}
		if "`timevar'" == "" { // using time = _t
			tempvar tmp lb ub
			sts gen `tmp' = s if `touse', by(`ggroup')
			sts gen `lb' = lb(s) if `touse', by(`ggroup')
			sts gen `ub' = ub(s) if `touse', by(`ggroup')
			forvalues j = 1 / `ngroups' {
				if `n`j'' > 0 {
					gen `km'`j' = `tmp' if `ggroup'==`j'
					gen `km'_lb`j' = `lb' if `ggroup'==`j'
					gen `km'_ub`j' = `ub' if `ggroup'==`j'
				}
			}
		}
		else { // using time = `timevar'
			// Using sts list, save to file and reshape
			tempfile newvars
			sts list if `touse', at(`at') by(`by') saving(`"`newvars'"', replace)
			preserve
			use `"`newvars'"', replace
			drop begin fail std_err
			rename survivor `km'
			rename lb `km'_lb
			rename ub `km'_ub
			tempvar group
			egen byte `group' = group(`by')
			replace `km'_lb = 1 if time == 0
			replace `km'_ub = 1 if time == 0
			reshape wide `by' `km' `km'_lb `km'_ub, i(time) j(`group')
			drop time
			// Extract, store and drop original group codes
			forvalues j = 1 / `ngroups' {
				local code`j'
				local remaining "`by'"
				while "`remaining'" != "" {
					gettoken i remaining : remaining
					sum `i'`j', meanonly
					local code`j' `code`j'' `i' `r(mean)'
					drop `i'`j'
				}
				lab var `km'`j' "KM `code`j''"
				lab var `km'_lb`j' "KM lower bound `code`j''"
				lab var `km'_ub`j' "KM upper bound `code`j''"
			}
			save `"`newvars'"', replace
			restore
			sort `t'
			merge 1:1 _n using `"`newvars'"', nogenerate noreport
			forvalues j = 1 / `ngroups' {
				lab var `mean'`j' "S() `code`j''"
			}
		}
	}
}
end

* version 1.0.1 PR 26Sep2002
* Based on PR 9-Jan-94. Based on covariate-pattern counter in lpredict.ado.
program define covpat, sortpreserve
version 7
syntax varlist(min=1) [if] [in], Generate(string)
confirm new var `generate'
tempvar keep
quietly {
	marksample keep
	sort `keep' `varlist'
	gen long `generate' = .
	by `keep' `varlist': replace `generate'=cond(_n==1 & `keep',1,.)
	replace `generate' = sum(`generate')
	replace `generate'=. if `generate'==0
	label var `generate' "covariate pattern"
}
end
