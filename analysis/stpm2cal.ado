*! version 1.0.0 PR 30nov2015
program define stpm2cal, rclass
version 12.1
// Time-dependent calibration plot and tests for predicted probabilities from RP model
syntax [if] [in] , TImes(numlist >0) ///
 [ ADDcons(string) noGRaph RESiduals SAVing(string) test TRend * ]

if "`e(cmd)'" != "stpm2" error 301

if "`addcons'" != "" {
	confirm number `addcons'
	local addcons `addcons'+
}
local scale `e(scale)'

// Store stpm2 estimates
tempname ests
estimates store `ests'
quietly {
	marksample touse
	preserve
	keep if `touse'==1
	drop `touse'

	// Predict event probs at selected times.
	tempvar tt
	gen double `tt' = .
	local j 0
	foreach time of local times {
		local ++j
		Drop _hF`j'
		Drop _F`j'
		replace `tt' = `time'
		predict double _F`j', failure timevar(`tt')
		if "`scale'" == "hazard" {
			gen double _hF`j' = `addcons' cloglog(_F`j')
			if "`addcons'"!="" replace _F`j' = invcloglog(_hF`j')
			local link cloglog
		}
		else if "`scale'" == "odds" {
			gen double _hF`j' = `addcons' logit(_F`j')
			if "`addcons'"!="" replace _F`j' = invlogit(_hF`j')
			local link logit
		}
		else if "`scale'" == "normal" {
			gen double _hF`j' = `addcons' invnormal(_F`j')
			if "`addcons'"!="" replace _F`j' = normal(_hF`j')
			local link probit
		}
	}

	// Predict pseudovalues on validation
	stpsurv, at(`times') gen(_f) failure
	local nt : word count `times'
	if `nt' < 2 rename _f _f1

	// Reshape data for analysis and plotting
	Drop _id
	Drop _times
	gen long _id = _n
	reshape long _f _F _hF, i(_id) j(_times)
	if "`test'`trend'" != "" {
		// Estimate overall calibration slope and intercept on pseudovalues
		local glmopt link(`link') vce(cluster _id) irls noheader nolog

		// Test constants with slope constrained to 1
		capture noisily glm _f ibn._times, noconstant offset(_hF) `glmopt'
		if c(rc)==0 {
			noi di as txt _n "[Test 1: intercepts (gamma0) = 0 with slope (gamma1) constrained to 1]"
			noi testparm i._times
			local P0 = chi2tail(r(df), r(chi2))
		}
		else {
			di as err "[could not fit constrained GLM to estimate constant on pseudovalues]"
		}
		capture noisily glm _f _hF ibn._times, noconstant `glmopt'
		if c(rc)==0 {
			noi di as txt _n "[Test 2: slope (gamma1) = 1 with constants (gamma0) estimated]"
			noi test _hF = 1
			local P1 = chi2tail(1, r(chi2))
			local gamma1 = _b[_hF]
			local gamma1_se = _se[_hF]
			noi di as txt _n "[Test 3: joint test of slope (gamma1) = 1 and all constants (gamma0) = 0]"
			testparm i._times
			noi test _hF = 1, accum
			local P01 = chi2tail(r(df), r(chi2))
		}
		else {
			di as err "[could not fit GLM to estimate constant and slope on pseudovalues]"
		}
		// Checking for change in calibration slope with time point (interaction)
		if `nt' > 1 {
			if "`trend'" == "" {
				capture noisily glm _f i._times##c._hF, `glmopt'
				if c(rc)==0 {
					noi di as txt _n "[Test 4: interaction between slopes (gamma1) and times]"
					noi testparm _times#c._hF
					local Pint = chi2tail(r(df), r(chi2))
				}
				else {
					di as err "[could not fit GLM to estimate slope x time interaction]"
				}
			}
			else {
				capture noisily glm _f c._times##c._hF, `glmopt'
				if c(rc)==0 {
					noi di as txt _n "[Test 4: interaction between slope (gamma1) and scores for times]"
					noi test c._times#c._hF
					local Pint = chi2tail(r(df), r(chi2))
				}
				else {
					di as err "[could not fit GLM to estimate slope x time trend]"
				}
			}
			tempvar fitted
			predict `fitted'
		}
	}
	if "`graph'" != "nograph" {
		if "`residuals'" != "" {
			tempvar diff
			gen `diff' = _f - _F
			if "`fitted'" != "" replace `fitted' = `fitted' - _F
		}
		// Running line plots of pseudovalues on predicted event probs
		local j 0
		local gs
		foreach time of local times {
			local ++j
			if "`residuals'" != "" {
				if "`fitted'" == "" {
					running `diff' _F if _times==`j', ///
					 title("t = `time'") ci leg(off) name(g`j',replace) xtitle("") ytitle("") ///
					 xlabel(0(.25)1) yline(0) nopts nodraw `options'
				}
				else {
					running `diff' _F if _times==`j', ///
					 addplot(line `fitted' _F if _times==`j', sort lp(-) lwidth(medthick ..)) ///
					 title("t = `time'") ci leg(off) name(g`j',replace) xtitle("") ytitle("") ///
					 xlabel(0(.25)1) yline(0) nopts nodraw `options'
				}
			}
			else {
				running _f _F if _times==`j', ///
				 addplot(line _F `fitted' _F if _times==`j', sort lp(l -) lwidth(medthick ..)) ///
				 title("t = `time'") ci leg(off) name(g`j',replace) xtitle("") ytitle("") ///
				 xlabel(0(.25)1) nopts nodraw `options'
			}				
			local gs `gs' g`j'
		}
		if "`residuals'" != "" local ltitle "Observed minus predicted event probability"
		else local ltitle "Observed event probability"
		graph combine `gs', imargin(small) b2title("Predicted event probability") ///
		 l1title("`ltitle'") xcommon ycommon name(_g, replace)
	}
	if `"`saving'"' != "" {
		if "`fitted'" != "" {
			cap drop _fitted
			rename `fitted' _fitted
			local fitted _fitted
		}
		keep _f _F `fitted' _hF _times _id
		save `"`saving'"', replace
	}
}
foreach thing in Pint Pinta P01 P01a P1 P1a P0 P0a gamma1_se gamma1 {
	if "``thing''" != "" return scalar `thing' = ``thing''
}
quietly estimates restore `ests'
end

program define Drop
version 12.1
args var
capture confirm var `var', exact
if c(rc)==0 drop `var'
end
