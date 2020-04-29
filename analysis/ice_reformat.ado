*! version 1.0.0 Pr 04feb2007
program define ice_reformat

syntax using/ , replace

confirm file `"`using'"'

preserve

quietly {
	use `"`using'"', clear
	foreach ij in i j {
		cap confirm var _m`ij'
		if _rc==0 {
			noi di as err "variable _m`ij' already exists"
			exit 198
		}
		rename _`ij' _m`ij'
	}
	char _dta[mi_id] "_mi"
	save `"`using'"', replace
}
di as txt "file `using' successfully reformatted to ice 1.4.0+ and mim format"
restore
end
