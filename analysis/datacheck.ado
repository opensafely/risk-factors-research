// Updated 17/03/2005: flag can now be used along with nol
// Updated 17/01/2005: by option added
// Updated 16/05/2007: SJ reviewer broke next option - bug corrected
// Updated 08/11/2010: verified for ssc 

program datacheck
	version 8.2
	syntax anything(name=cond)           ///
	[if] [in],                           ///
	[                                    ///
	by(varlist)                          ///
	Flag                                 /// 
	Message(string asis)                 ///
	Varshow(varlist)                     ///
	Previous                             ///
	Next                                 ///
	noList                               ///
	sepby(varlist) * ]

// Preparation   

	if "`by'" != "" {
		if "`sepby'" == "" local options "`options' sepby(`by')"
		local by "by `by':"
	}	

	if "`varshow'" == "" unab varshow : _all 

	cap drop _contra

// Assert condition 

	cap `by' assert `cond' `if' `in' 

// No errors: generate flag if needed, and then bail out 	

	if _rc == 0 { 
		if "`flag'" != "" gen byte _contra = 0 
		exit 0 
	}

// Errors: flag if needed 	

	tempvar viol 
	qui `by' gen byte `viol' = !(`cond') `if' `in' 
	if "`flag'" != "" gen byte _contra = `viol' == 1 
	
	qui count if `viol'==1

	di _n as txt `"`message' (`r(N)'"' ///
	      as txt plural(`r(N)', " contradiction") ")" 

	if "`list'" != "" exit 0   

// Full output required (i.e. nolist not specified) 
	
	tempvar pre
	tempvar nex
	gen `pre'=0
	gen `nex'=0
	qui if "`previous'" != "" {
		`by' replace `pre' = 1 if `viol'[_n + 1] == 1
	}	
	qui if "`next'" != "" { 
		`by' replace `nex' = 1 if `viol'[_n - 1] == 1
	}	

	list `varshow' if `viol' == 1|`pre'==1 | `nex'==1, `options' 
end
