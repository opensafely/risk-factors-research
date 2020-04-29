*! version 1.0.3 PR 16oct2004.
* History
* 1.0.3 16oct2004 Saving, using etc of file safest with compound quotes, fixed.

program define mijoin, rclass
version 7

syntax [anything(name=filestub)], CLEAR [ IMPid(string) m(int 0) ]

if "`filestub'"=="" {
	capture assert "$mimps"!="" & "$mi_sf"!=""
	if _rc {
		di as error "please set up your data with -{help miset}-, or specify a filename stub"
		exit 198
	}
	local filestub $mi_sf
	if `m'>$mimps {
		di as err "m cannot exceed its -miset- value of $mimps"
		exit 198
	}
	if `m'==0 {
		local m $mimps
	}
}

if `m'<=0 {
	di as err "number of imputations m(), if specified, must be a positive integer"
	exit 198
}

if "`impid'"=="" {
	local J _j
}
else local J `impid'
preserve
quietly {
	forvalues j=1/`m' {
		use `"`filestub'`j'"', clear
		chkrowid
		local I `s(I)'
		if "`I'"=="" {
			* create row number
			local I _i
			cap drop `I'
			gen long `I'=_n
			lab var `I' "obs. number"
		}
		cap drop `J'
		gen int `J'=`j'
		lab var `J' "imputation number"
		tempfile tmp`j'
		save `"`tmp`j''"'
	}
	use `"`tmp1'"', clear
	forvalues j=2/`m' {
		append using `"`tmp`j''"'
	}
	char _dta[mi_id] `I'
}
restore, not
end

program define chkrowid, sclass
local I: char _dta[mi_id]
if "`I'"=="" {
	exit
}
cap confirm var `I'
if _rc {
	exit
}
sret local I `I'
end
