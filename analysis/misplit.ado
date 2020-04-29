*! version 1.0.1 PR 01oct2004.
program define misplit, rclass
version 7
syntax, CLEAR [ IMPid(string) m(int 5) ]
cap assert `m'>1
if _rc {
	di "{err}more than one imputation is required"
	exit 198
}
if "`impid'"=="" {
	local impid _j
}
cap confirm var `impid'
if _rc {
	di as err "imputation identifier `impid' not found in file `using'"
	exit 601
}
tempvar J
egen int `J'=group(`impid')
sum `J', meanonly
local m=r(max)
if r(max)<2 {
	di as error "more than one imputation is required"
	exit 198
}
if r(max)<`m' {
	local m=r(max)
	di as text "[note: data for only `m' imputations found in file]"
}
preserve
quietly {
	forvalues j=1/`m' {
		keep if `J'==`j'
		drop `J'
		cap erase "_mitemp`j'.dta"
		save "_mitemp`j'.dta"
		restore, preserve
		*egen int `J'=group(`impid')
	}
	global mi_uf `using'
	global mi_sf _mitemp
	global mimps `m'

	use _mitemp1.dta, clear
}
if $mimps==2 {
	di "{p}{txt}data for $mimps imputations have been copied to _mitemp1.dta and _mitemp$mimps.dta"
}
else {
	di _n "{p}{txt}Data for $mimps imputations have been copied to ${mi_sf}1.dta to $mi_sf$mimps.dta"
}
restore, not
end
