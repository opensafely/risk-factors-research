*! version 1.9.7 PR/IW 25oct2014. For history, see end of this file.
program define ice, rclass
version 9.2
local cmdline `0'
syntax [anything] [if] [in] [aweight fweight pweight iweight], ///
 [clear cmd(string) CONDitional(string) dry dryrun eq(string) INITialonly ///
  nofatal SAVing(string) stepwise SUBstitute(string) SWopts(string) *]

// Check version numbers of ice_ and uvis
vercheck ice_ 1.4.1 `fatal'
vercheck uvis 1.7.1 `fatal'

if (`"`anything'"' == "") {
	foreach thing in eq cmd stepwise swopts {
		if (`"``thing''"' != "") {
			di as err `"invalid `thing', variables and equations will be input from global macros ice_*"'
			exit 198
		}
	}
	local stored_eq 1
}
else local stored_eq 0
if ("`dry'" != "") {
	local dryrun dryrun
	local cmdline : list cmdline - dry
	local dry
}
if ("`stepwise'" == "stepwise") {
	// remove clear if present, add back later on.
	local cmdline : list cmdline - clear

	// Remove `saving' and `dryrun' for the purposes of stepwise; add back later on
	if (`"`saving'"' != "") {
		foreach thing in sav savi savin saving {
			// This operation will pick up and remove from cmdline exactly one abbrevation of the -saving()- option
			local stuff `thing'(`saving')
			local cmdline : list cmdline - stuff
		}
	}
	if ("`dryrun'" == "dryrun") local cmdline : list cmdline - dryrun
/*
	Remove stepwise. About to run ice to generate one imputation.
	Then run ice_eq to do stepwise selection of equations.
	The `m1' option forces m = 1, irrespective of m()
*/
	local cmdline : list cmdline - stepwise
*noi di in red `"qui ice `cmdline' initialonly m1 nowarning clear"'

 	// stepwise needs clear.
 	qui ice `cmdline' initialonly m1 nowarning clear
 
	ice_eq, `swopts'
	local stored_eq 1
	global ice_main `anything'
}
if `stored_eq' {
/*
	if !missing("`conditional'") {
		di as txt "note: conditional() ignored, forms part of the stored equations"
	}
*/
	local anything $ice_main
	confirm integer number $ice_neq
	local conditional
	forvalues i = 1 / $ice_neq {
		if missing("${ice_cmd`i'}") {
			di as err "macro ${ice_cmd`i'} not found"
			exit 198
		}
		if missing("${ice_x`i'}") {
			di as err "macro ${ice_x`i'} not found"
			exit 198
		}
		if missing(`"${ice_eq`i'}"') {
			di as err `"macro ${ice_x`i'} not found"'
			exit 198
		}
		local Eq  ${ice_x`i'}:${ice_eq`i'}
		local Cmd ${ice_x`i'}:${ice_cmd`i'}
		if !missing(`"${ice_cond`i'}"') {
			local Cond ${ice_x`i'}:${ice_cond`i'}
			if missing("`conditional'") local conditional `Cond'
			else local conditional `conditional' \ `Cond'
		}
		if (`i' == 1) {
			local eq `Eq'
			local cmd `Cmd'
			
		}
		else {
			local eq `eq', `Eq'
			local cmd `cmd', `Cmd'
		}
	}
	cap mitidy
	di as txt _n "[Using equations stored in global macros ice_*.]" _n
}
else {
	cap confirm var _mi
	local ismi = (r(rc) == 0)
	cap confirm var _mj
	local ismj = (r(rc) == 0)
	if `ismi' | `ismj' {
		di as err "_mi or _mj are already present in the data"
		exit 198
	}
}
local nvars : word count `anything'
tokenize `anything'
/*
	Determine variable type.

	Also compute "uniq_varlist", list of the original variables, for use
	by ice_.ado to determine the true number of missing values
	without repeats caused by dummy variables.
*/
local uniq_varlist
local i_varlist	// list of variables prefixed by i.
forvalues i=1/`nvars' {
	local prefix = substr("``i''",1,2)
	if "`prefix'"=="i." | "`prefix'"=="m." | "`prefix'"=="o." {
		local type`i' = substr("``i''",1,1)
		local var`i'  = substr("``i''",3,.)
		local xi xi:
	}
	else {
		local type`i' .
		local var`i' ``i''
	}
	cap unab var`i': `var`i''
	if _rc {
		di as err "invalid variable or varlist, `var`i''"
		exit 198
	}
	local uniq_varlist `uniq_varlist' `var`i''
	if "`prefix'"=="i." local i_varlist `i_varlist' `var`i''
}
/*
	Var type "i" gets passed to xi: without invoking substitute()
	and without repeating varname. Types m and o get repeat varname
	and invoke substitute.
*/
forvalues i=1/`nvars' {
	if "`type`i''"=="." local varlist `varlist' `var`i''
	else if "`type`i''"=="i" local varlist `varlist' i.`var`i''
	else {
		local varlist `varlist' `var`i'' i.`var`i''
		if "`substitute'"!="" local substitute `substitute',
		local substitute `substitute' `var`i'':i.`var`i''
		if !`stored_eq' local cmd`type`i''logit `cmd`type`i''logit' `var`i''
	}
}
// Prepend commands indicated by o. or m. to existing cmd - this forces overwriting of o. m. induced commands if var occurs more than once
if !`stored_eq' {
	local cmd0 `cmd'
	local cmd
	foreach type in m o {
		if "`cmd`type'logit'"!="" {
			if "`cmd'"!="" local cmd `cmd',
			local cmd `cmd' `cmd`type'logit':`type'logit
		}
	}
	if "`cmd0'" != "" {
		if "`cmd'" != "" local cmd `cmd', `cmd0'
		else local cmd `cmd0'
	}
}
// scan for "i." anywhere in eq
if "`eq'"!="" {
	local eq eq(`eq')
	if strpos("`eq'", "i.")>0 local xi xi:
}

// Build command line for ice_.ado
local Cmd `varlist'
if `"`if'"'!="" local Cmd `Cmd' `if'
if "`in'"!=""   local Cmd `Cmd' `in'
if `"`weight'"'!="" local Cmd `Cmd' [`weight'`exp']
local Cmd `Cmd',
foreach thing in cmd conditional saving substitute {
	if (`"``thing''"' != "") local Cmd `Cmd' `thing'(``thing'')
}
foreach thing in clear dryrun eq initialonly options {
	if (`"``thing''"' != "") local Cmd `Cmd' ``thing''
}

global F9 `xi' ice `Cmd'
* if "`xi'" != "" di as txt _n "=> $F9" _n
char _dta[mi_uniqvl] "`uniq_varlist'"
char _dta[mi_ivl] "`i_varlist'"
// $S_ICE may contain a number such as "2". Typically, it is blank.
`xi' ice${S_ICE}_ `Cmd'

// Tidy up utility S_* macros
cap macro drop S_*

// store equations etc. from ice_
local neq `r(neq)'
if `neq' > 0 {
	forvalues i = 1 / `neq' {
		// Identify type of variable on LHS of prediction equation
		local xx `r(x`i')'
		forvalues j = 1 / `nvars' {
			if ("`xx'" == "`var`j''") {
				local t `type`j''
				continue, break
			}
		}
		return local cmd`i' `r(cmd`i')'
		return local x`i' `xx'
		return local eq`i' `r(eq`i')'
		return local cond`i' `r(cond`i')'
		return local type`i' `t' // . meaning regular, o/i/m meaning categorical
	}
}
return local neq `neq'
return local if `if'
return local in `in'
if (`"`weight'"' != "") return local weight [`weight'`exp']
end

program define ice_eq
version 9.2
*confirm var _mi
*confirm var _mj
local neq `r(neq)'
confirm integer number `neq'
local if `r(if)'
local in `r(in)'
local weight `r(weight)'
syntax [, pe(real 0) pr(real 0) FORWard GRoup(string) LOck(string) SHow]

cap confirm var _mj
if (c(rc) > 0) {
	di as err "variable _mj not found - data must include at least one imputation"
	exit 198
}
if (`pe' <= 0) {
	if (`pr' > 0) local pe
	else local pe pe(0.05)
}
else local pe pe(`pe')
if (`pr' <= 0) local pr
else local pr pr(`pr')

forvalues i = 1 / `neq' {
	local x`i' `r(x`i')'
	local eq`i' `r(eq`i')'
	local Eq`i' `eq`i''
	local cmd`i' `r(cmd`i')'
	local cond`i' `r(cond`i')'
	local type`i' `r(type`i')'
}
quietly {
	preserve
	keep if _mj == 1
	if !missing(`"`if'`in'"') keep `if' `in'
	if ("`lock'" != "") {
		// Expand var names in lock
		tokenize "`lock'"
		local lock
		local nlock 0
		while ("`1'" != "") {
			xi_unab `1'
			local lock `lock' `s(vn)'
			local ++nlock
			mac shift
		}
	}
	if ("`group'" != "") {
		tokenize "`group'", parse(",")
		local ngroup 0
		while ("`1'" != "") {
			if ("`1'" != ",") {
				// unabbreviate var name, respecting "i."
				xi_unab `1'
				local 1 `s(vn)'
				// Check if group var `1' is in lock list
				if ("`lock'" != "") {
					forvalues j = 1 / `nlock' {
						local lj : word `j' of `lock'
						if ("`1'" == "`lj'") {
							noi di as err "not allowed to have a variable (`1') in both lock() and group()"
							exit 198
						}
					}
				}
				local ++ngroup
				local Group`ngroup' `1'
			}
			mac shift
		}
		forvalues j = 1 / `ngroup' {
			// Initialise strings to contain grouped variables between parentheses
			forvalues i = 1 / `neq' {
				local group`i'
			}
			tokenize "`Group`j''"
			while ("`1'" != "") {
				// identify which variable `1' is
				local igroup 0
				forvalues i = 1 / `neq' {
					if "`1'" == "`x`i''" {
						local igroup `i'
						continue, break
					}
				}
				if (`igroup' == 0) {
					// variable has no missing data: exclude from all equations and add it to group list
					if (substr("`1'", 1, 2) == "i.") {
						xi `1'
						local xx : char _dta[__xi__Vars__To__Drop__]
						local nxx : word count `xx'
						forvalues i = 1 / `neq' {
							forvalues j = 1 / `nxx' {
								local xy : word `j' of `xx'
								local k: list posof "`xy'" in eq`i'
								if (`k' > 0) {
									local eq`i' : list eq`i' - xy
									local group`i' `group`i'' `xy'
								}
							}
						}
					}
					else {
						forvalues i = 1 / `neq' {
							local k: list posof "`1'" in eq`i'
							if (`k' > 0) {
								local eq`i' : list eq`i' - 1
								local group`i' `group`i'' `1'
							}
						}
					}
				}
				else {
					forvalues i = 1 / `neq' {
						if (`i' != `igroup') {
							// grouped var is not on LHS, so may be on the RHS
							if "`type`igroup''" == "." {
								// grouped var is of regular type (not dummies)
								local k: list posof "`1'" in eq`i'
								if (`k' > 0) {
									local eq`i' : list eq`i' - 1
									local group`i' `group`i'' `1'
								}
							}
							else {
								xi i.`1'
								local xx : char _dta[__xi__Vars__To__Drop__]
								local nxx : word count `xx'
								forvalues j = 1 / `nxx' {
									local xy : word `j' of `xx'
									local k: list posof "`xy'" in eq`i'
									if (`k' > 0) {
										local eq`i' : list eq`i' - xy
										local group`i' `group`i'' `xy'
									}
								}
							}
						}
					}
				}
				mac shift
			}
			forvalues i = 1 / `neq' {
				if ("`group`i'" != "") local eq`i' `eq`i'' (`group`i'')
			}
		}
	}
/*
	Reformulate equation for each locked variable
*/
	if ("`lock'" != "") {
		tokenize `lock'
		while ("`1'" != "") {
			// identify which variable `1' is
			local ilock 0
			forvalues i = 1 / `neq' {
				if "`1'" == "`x`i''" {
					local ilock `i'
					continue, break
				}
			}
			if (`ilock' == 0) {
				// variable has no missing data: exclude from all equations and add it to locked list
				if (substr("`1'", 1, 2) == "i.") {
					xi `1'
					local xx : char _dta[__xi__Vars__To__Drop__]
					local nxx : word count `xx'
					forvalues i = 1 / `neq' {
						forvalues j = 1 / `nxx' {
							local xy : word `j' of `xx'
							local k: list posof "`xy'" in eq`i'
							if (`k' > 0) {
								local eq`i' : list eq`i' - xy
								local lock`i' `lock`i'' `xy'
							}
						}
					}
				}
				else {
					forvalues i = 1 / `neq' {
						local k: list posof "`1'" in eq`i'
						if (`k' > 0) {
							local eq`i' : list eq`i' - 1
							local lock`i' `lock`i'' `1'
						}
					}
				}
			}
			else {
				forvalues i = 1 / `neq' {
					if (`i' != `ilock') {
						// locked var is not on LHS, so may be on the RHS
						if "`type`ilock''" == "." {
							// locked var is of regular type (not dummies)
							local k: list posof "`1'" in eq`i'
							if (`k' > 0) {
								local eq`i' : list eq`i' - 1
								local lock`i' `lock`i'' `1'
							}
						}
						else {
							xi i.`1'
							local xx : char _dta[__xi__Vars__To__Drop__]
							local nxx : word count `xx'
							forvalues j = 1 / `nxx' {
								local xy : word `j' of `xx'
								local k: list posof "`xy'" in eq`i'
								if (`k' > 0) {
									local eq`i' : list eq`i' - xy
									local lock`i' `lock`i'' `xy'
								}
							}
						}
					}
				}
			}
			mac shift
		}
		forvalues i = 1 / `neq' {
			if ("`lock`i'" != "") {
				local eq`i' (`lock`i'') `eq`i''
				local lock`i' lockterm1
			}
		}
	}
	// Display equations before stepwise selection
	noi di as txt _n "Equations before stepwise selection" _n "{hline 35}"
	local longstring 55	// max display length of variables in equation
	local off 13		// blanks to col 13 on continuation lines
	noi di as text _n "   Variable {c |} Command {c |} Prediction equation" _n ///
	 "{hline 12}{c +}{hline 9}{c +}{hline `longstring'}"
	forvalues i = 1 / `neq' {
		local xy "()"
		local k: list posof "`xy'" in eq`i'
		if (`k' > 0) {
			local eq`i' : list eq`i' - xy
		}
		local eq `eq`i''
		if "`cond`i''" != "" local eq `eq' if `cond`i''
		formatline, n(`eq') maxlen(`longstring')
		local nlines=r(lines)
		forvalues j=1/`nlines' {
			if `j'==1 noi di as text %11s abbrev("`x`i''",11) ///
			 " {c |} " %-8s "`cmd`i''" "{c |} `r(line`j')'"
			else noi di as text _col(`off') ///
			 "{c |}" _col(23) "{c |} `r(line`j')'"
		}
	}
	noi di as text "{hline 12}{c BT}{hline 9}{c BT}{hline `longstring'}"
	// Do stepwise
	restore
	preserve
	keep if _mj == 1
	if ("`show'" == "show") local show noisily
	forvalues i = 1 / `neq' {
		if missing("`cond`i''") {
			local If `if'
		}
		else {
			if missing(`"`if'"') local If if `cond`i''
			else local If `if' & (`cond`i'')
		}
		if ("`show'" != "") noi di as txt _n "Developing prediction equation for `x`i'':" _n
		`show' stepwise, `forward' `pe' `pr' `lock`i'' : `cmd`i'' `x`i'' `eq`i'' `If' `in' `weight'
		// determine and store remaining predictors
		tokenize `Eq`i'' // original, before adding lockterm1 stuff
		local eq`i'
		while !missing("`1'") {
			cap local b = _b[`1']
			if (c(rc) == 0) local eq`i' `eq`i'' `1'
			mac shift
		}
	}
}
cap macro drop ice_*
forvalues i = 1 / `neq' {
	global ice_cmd`i' `cmd`i''
	global ice_x`i' `x`i''
	if missing("`eq`i''") {
		global ice_eq`i' _cons
	}
	else {
		global ice_eq`i' `eq`i''
	}
	if !missing("`cond`i''") global ice_cond`i' `cond`i''
	else global ice_cond`i'
}
global ice_neq `neq'
end

program define xi_unab, sclass
version 9.2
* Unabbreviate varname in `vn', retaining prefix "i." if present.
args vn
sreturn clear
if (substr("`vn'", 1, 2) == "i.") {
	local vn = substr("`vn'", 3, .)
	unab vn : `vn'
	local vn i.`vn'
}
else unab vn : `vn'
sreturn local vn `vn'
end

program define mitidy
version 9.2
* Removes observations with _mj > 0 and deletes _mi and _mj.
confirm var _mj
confirm var _mi
keep if _mj == 0
drop _mi _mj
cap drop _mim_e
di as txt "[successfully tidied]"
end

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

program define vercheck, sclass
version 9.2
local progname `1'
local vermin `2'
local not_fatal `3'
// If arg `not_fatal' is set to anything, program exits without an error.
if missing("`not_fatal'") local exitcode 498
tempname fh
qui findfile `progname'.ado
local filename `r(fn)'
file open `fh' using `"`filename'"', read
local stop 0
while `stop'==0 {
	file read `fh' line
	if r(eof) continue, break
	tokenize `"`line'"'
	if "`1'" != "*!" continue, break
	while "`1'" != "" {
		mac shift
		if inlist("`1'","version","ver","v") {
			local vernum `2'
			local stop 1
			continue, break
		}
	}
	if "`vernum'"!="" continue, break
}

sreturn local version `vernum'

if "`vermin'" != "" {
	if "`vernum'"=="" local match nover
	else {
		local vermin2 = subinstr("`vermin'","."," ",.)
		local vernum2 = subinstr("`vernum'","."," ",.)
		local words = max(wordcount("`vermin2'"),wordcount("`vernum2'"))
		local match equal
		forvalues i=1/`words' {
			if word("`vermin2'",`i') == word("`vernum2'",`i') continue
			if word("`vermin2'",`i') > word("`vernum2'",`i') local match old
			if word("`vermin2'",`i') < word("`vernum2'",`i') local match new
			continue, break
		}
	}
	if "`match'"=="old" {
		di as error `"`filename' is version `vernum' which is older than target `vermin'"'
		exit `exitcode'
	}
	if "`match'"=="nover" {
		di as error `"`filename' has no version number found"'
		exit `exitcode'
	}
	if "`match'"=="new" {
		di `"`filename' is version `vernum' which is newer than target `vermin'"'
	}
}
else {
	if "`vernum'"!="" di as text `"`filename' is version `vernum'"'
	else di as text `"`filename' has no version number found"'
}

end

exit

History of ice

1.9.6 13aug2012 Various small but significant changes to ice_.ado by A Loumiotis et al.
1.9.5 15apr2011 Fixed Stata 9.2 incompatibility bug in line 4.
1.9.4 20dec2010 Added check (vercheck) of versions of uvis and ice_ (IRW).
1.9.3 02dec2010 Added -allmissing- option to impute observations with all-missing values.
                Added undocumented feature that negative cycles value forces iteration even when one cycle would normally suffice.
                Fixed bug which accidentally implemented the -allmissing- option when o., i. or m. prefixes were specified.
1.9.2 20sep2010 Fixed long-standing issue which manifested only in datasets with v. large numbers of missing values (bug in ice_\listsort3 routine).
1.9.1 20aug2010 Fixed problem with -stepwise- (Rainer Siegers) - option -clear- not working as expected with it.
1.9.0 11jul2010 Major addition to functionality - stepwise selection of prediction equations (-stepwise- option).
1.8.0 11jun2010 Changes to how -match- works. Included matchpool() option in -ice- and -uvis-.
                Significant improvements to the -conditional()- option.
1.7.8 15mar2010 Fixed up bug in -ice_- whereby imputing an interval-censored variable inappropriately
                failed collinearity check when variable to be imputed started completely missing.
1.7.7 01dec2009 Allow right-hand-side variables not in mainvarlist to appear in passive() statements.
1.7.6 28nov2009 Issue error message if _mi or _mj variables exist in the data
                Fix problem with imputing categorical variables when mean imputation used
1.7.5 17nov2009 Fixed problems with detecting, reporting and fixing collinearities. This was not working at all.
                Added a facility for defining blank equations (as _cons).
                Improved and documented the -debug- option.
1.7.4 12nov2009 Fixed obscure bug in ice_.ado, routine listsort3, when could try to store in non-existent observations.
1.7.3 07sep2009 -persist- option altered to skip regression with error and go to next variable
                (rather than skip to the end of the current cycle)
1.7.2 27aug2009 -noverbose- option added
1.7.1 24jun2009 Fixed minor bug related to conditional() - left behind one or more __* temporary variables
                undocumented nbregopts() option added (for Jocelyn Andrel)
1.7.0 01jun2009 Added display of uvis activity in "debug" model
                Made explicit cmd() overwrite implicit cmd() from o. and m. prefixes when same variables specified more than once
1.6.8 11may2009 Fixed bug when using if/in in ice_ - incorrectly set values outside estimation sample to missing.
1.6.7 10may2009 Fixed bug in by() in ice_ - did not allow for missing values of by() vars.
1.6.6 05may2009 Fixed bug in cond() in ice_ - sometimes picked incorrect subset to impute.
1.6.5 17apr2009 Added -persist- option to ignore errors raised by uvis
1.6.4 30mar2009 Fixed bug when cond() and intreg are used together
1.6.3 07feb2009 Added eqdrop() option to remove predictors from equations
                Added monotone option for imputing assuming monotone missingness pattern
1.6.2 23jan2009 Removed check for "=" as separator in detangle - passive() sometimes failing
1.6.1 01dec2008 Checking for missing values of "i." variables implemented
                undocumented uvisopts() option added (for IRW)
1.6.0 02oct2008 conditional() option changed to impute on subsets of observations
                Shortcut o. and m. prefixes for ologit, mlogit; generates substitute() and cmd().
                Added by() option to ice and uvis.
                Corrected bug which reported multiple missing values caused by dummy variables.
1.5.1 11jun2008 Added restrict() option to ice and uvis.
1.5.0 17may2008 Fixed bug in listsort3 which gave arbitrary ranks to numbers of
                missing values when there were ties - major effect on reproducibility.
                Ties now broken in order of presentation of variables in mainvarlist.
                -sortpreserve- added to sampmis to keep same order of observations
1.4.6 14may2008 Removed warning about use of xi:
                Fixed bug in check of whether saving() file exists
                -clear- option added
1.4.5 01apr2008 dumping dta to _ice_dump.dta when a fatal error is encountered.
                fixed bug in ice warning message.
1.4.4 09nov2007 -vce()- option added
1.4.3 10oct2007 Update to perfect prediction (implemented in -uvis-)
                nopp option added to suppress avoidance of perfect prediction bug.
                nowarning option added to suppress warning messages.
1.4.2 03aug2007 Change to syntax for saving file (old syntax still works).
1.4.1 27mar2007 Checking for perfect prediction in logistic regression moved to -uvis-.
1.4.0 16mar2007 Handling of `using' filename simplified.
1.3.3 15nov2006 Check for collinearity among covariates when running -uvis- added.
                Ian White's -auglogit- fix for logistic models with perfect prediction added.
                orderasis option added.
1.3.2 01nov2006 mitools functionality removed, not needed with mim.
                Default impid and obsid changed from _j, _i to _mj, _mi (for mim).
1.3.1 11sep2006 Bug in interval censoring, affecting left censoring, fixed.
1.3.0 05jul2006 Interval censoring implemented via interval() option.
                Conditional imputation extended to include imputation for subpopulation.
                Dumping data when errror found in number of missing values on output.
                dropmissing option implemented.
                svy option removed (would require much care to implement correctly).
1.2.2 05jun2006 substitute() option improved by allowing implicit passive()
1.2.1 31may2006 round() option added
                listsort found to have obscure bug and replaced with listsort3
                (Julie Siebens reported problem).
1.2.0 24may2006 Conditional imputation implemented (conditional() option).
                Survey regression imputation implemented (svy option).
1.1.4 21feb2006 Compound quotes needed around all temporary filenames
1.1.3 01feb2006 Saving original data to output file of imputations as _j = 0.
1.1.2 16jan2006 List of variables in on() option not displayed on output - fixed.
1.1.1 00nov2005 RELEASED IN SJ 5-4
1.1.1 23sep2005 Better error trapping for passive() and substitute() options.
1.1.0 23aug2005 Replace -draw- option with -match-. Default becomes draw.
                Trace option documented, now has argument for filename.
                Report number of rows with 0, 1, 2, ... missing values.
                Arrange variables in increasing order of missingness when imputing.
                Split ties at random when more than one observation satisfies the
                prediction matching criterion
1.0.4 21jul2005 Trap and report error when running uvis
1.0.3 08jun2005 Tidy up display of equations when have multiple lines (long equations)
1.0.3 03jun2005 Silence file load/save
1.0.2 20may2005 Changed files containing imputations to tempfiles (standalone mode)
                (Angela Wood reported problem).
1.0.1 04may2005 Added a trace to a file (undocumented in help file).
1.0.0 18apr2005 First release, based on mice.
	
History of mice
1.0.3 13apr2005 Minor tidying up, including recode of ChkIn and deletion of strdel.
                Check if prediction equations have a variable on both sides.
1.0.2 17feb2005 Added code to take care of inherited missingness of passive variables robustly.
1.0.1 21jan2005 Added display of regression command in showing prediction equations.
1.0.0 20jan2005 First release, based on mvis2/_mvis2.
	
History of mvis
1.1.0 18jan2005 categoric() option removed.
                New options dryrun, passive(), substitute(), eq() added.
                Improvements to output showing actual prediction equations.
1.0.5 19nov2004 Delete dummy variables for categoric() variables with no missing data from output file
                Found problem with bsample in Stata 7 with "if" clause and boot option.
                Revert to Stata 8 for mvis, _mvis and uvis.
1.0.4 18nov2004 Weights not working (syntax error), fixed.
1.0.3 16nov2004 Categoric() option added to deal with unordered categoric
                covariates, updated default handling of such variables
1.0.2 16oct2004 Saving, using etc of file safest with compound quotes, fixed.
