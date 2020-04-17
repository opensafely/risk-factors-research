*! 1.02 Ariel Linden 05August2017 // fixed touse statements, made btime() required
*! 1.01 Chuck Huber 26July2017 // fixed mean table output
*! 1.00 Ariel Linden 06June2017

program define stbrier, rclass 

version 13 

	syntax [varlist(default=none fv)] [if] [in] ,  	///
		BTime(numlist) 								/// desired timepoint for the estimation 
		[ Distribution(string)						/// distribution for -streg-
		COMPete(string)								/// competing risk for -stcreg-
		Ipcw(varlist fv)							/// varlist for IPCW
		Gen(string)  								/// generate brier score
		*											/// model options
		]
		
********************************************* points of interest *****************************************
// 1. St_i is the adjusted hazard (risk) probability at btime (can be estimated using any model)
// 2. Gt_i is the adjusted censoring probability at time _t. (always estimated using Cox for consistency)
// 3. Gt is the pooled censoring probability at btime. (always estimated using Cox for consistency)
**********************************************************************************************************

	// extract failure and failure value from stset
	local event "`_dta[st_bd]'"
	local event_val "`_dta[st_ev]'"

	marksample touse 
	quietly {
	count if `touse' 
	if r(N) == 0 error 2000
	local N = r(N) 
	replace `touse' = -`touse'
	} // end quietly
	
	// Check on model options
    if ("`distribution'" !="") & ("`compete'" != "") {
		 di as err "Only one model type can be specified"
    exit 198
    }

	tempvar Sh t_old xbi hazi hazti St_i xbC hazC Gt1 lasthazCi Gt Gt_i
	
quietly {	
	
	/**************** parametric regression for St_i ************************/

	if "`distribution'" !="" {	
	
		// check if specified btime is in the range
		sum _t if `touse', meanonly
		if `btime' < r(min) | `btime' > r(max) {
			di as err "The specified btime is beyond the range of the data:" ///
			" check timevar and respecify btime accordingly"
			exit 498
		}
								
		// Generate St_i = adjusted hazard probability at btime  //
		gsort _t -`event'
		streg `varlist' if `touse', dist(`distribution') `options'
		gen `t_old' = _t
		replace _t = `btime' if `touse'
		predict `Sh', surv  
		gen `St_i' = 1 - `Sh'
		replace _t = `t_old'
	
	}	// end St_i using streg	

	/**************** Cox regression for St_i ************************/

	else if ("`distribution'" == "") & ("`compete'" == "") {
	
		// check if btime exists within the data
		sum _t if `touse', meanonly
		if `btime' < r(min) | `btime' > r(max) {
			di as err "The specified btime is beyond the range of the data:" ///
			" check timevar and respecify btime accordingly"
			exit 498
		}
		else if `btime' > r(min) | `btime' < r(max) {
			count if _t == `btime' & `touse'
		}
		// if btime is not in data, reset btime to previous value of _t
		if r(N) == 0 {
			sum _t if _t < `btime' & `touse'
			local btime = r(max)
		}
		
		// Generate St_i = adjusted hazard probability at btime  //
		gsort _t -`event'
		stcox `varlist' if `touse', estimate `options'
		predict `xbi' if `touse', xb
		predict `hazi' if `touse', basechazard
		gen `hazti' = `hazi' if _t==`btime' & `touse'
		sum `hazti' if `touse', meanonly
		replace `hazti' = r(mean) if `touse'
		gen `St_i' = 1-(exp(-`hazti')^exp(`xbi')) if `touse'
	
	}	// end St_i using Cox
	
	/**************** Competing-risk regression for St_i ************************/

	else if "`compete'" != "" {
	
		// check if btime exists within the data
		sum _t if `touse', meanonly
		if `btime' < r(min) | `btime' > r(max) {
			di as err "The specified btime is beyond the range of the data:" ///
			" check timevar and respecify btime accordingly"
			exit 498
		}
		else if `btime' > r(min) | `btime' < r(max) {
			count if _t == `btime' & `touse'
		}
		// if btime is not in data, reset btime to previous value of _t
		if r(N) == 0 {
			sum _t if _t < `btime' & `touse'
			local btime = r(max)
		}
		
		// Generate St_i = adjusted hazard probability at btime  //
		gsort _t -`event'
		stcrreg `varlist' if `touse', compete(`compete') `options'
		predict `hazi' if `touse', basecif
		gen `hazti' = `hazi' if _t==`btime' & `touse'
		sum `hazti' if `touse', meanonly
		replace `hazti' = r(mean) if `touse'

		if "`varlist'" != "" {
			predict `xbi' if `touse', xb
			gen `St_i' = 1-(1-`hazti')^exp(`xbi') if `touse'
		}
		else {
			rename `hazti' `St_i'
		}	
		
		// get values used for competing risks
		local crvals "`e(crevent)'" 
		local crvals = substr("`crvals'", strpos("`crvals'", "==") + 3, .) 
		local crvals : subinstr local crvals " " ",", all 
	
	}	// end St_i using stcrreg
	
	/********************** Generate IPCW ******************************/	
		
	// Check if btime exists in the data. If not, reset btime to previous value of _t	
		count if _t == `btime' & `touse'
		if r(N) == 0 {
			sum _t if _t < `btime' & `touse'
			local btime = r(max)
		}
	
	// Generate Gt = the adjusted censoring probability at btime //
		stset _t if `touse', failure(`event'=0)
		stcox `ipcw' if `touse', estimate efron
		predict `xbC' if `touse', xb  
		predict `hazC' if `touse', basechazard
		gen `Gt1' = `hazC' if _t==`btime' & `touse'
		sum `Gt1' if `touse', meanonly
		replace `Gt1' = r(mean) if `touse'
		gen `Gt' = (exp(-`Gt1')^exp(`xbC')) if `touse'

	// Generate Gt_i = adjusted censoring probability at time _t //
		gen `lasthazCi' = `hazC'[_n-1] if _t > _t[_n-1]
		replace `lasthazCi' = `lasthazCi'[_n-1] if missing(`lasthazCi')
		gen `Gt_i' = (exp(-`lasthazCi')^exp(`xbC'))
		replace `Gt_i' = 1 in 1
	
	// reset failure in stset
		if "`event_val'" == "" {
			stset _t if `touse', failure(`event' = 1)
		}	
		else {
			stset _t if `touse', failure(`event' = `event_val')
		}
	
	/********************* Generate brier scores ****************************/
		tempvar brier
		gen `brier' = 0										if `touse'
		replace `brier' = (1/`Gt_i') * ((1 - `St_i')^2)		if _t <= `btime' & _d==1 & `touse'
		replace `brier' = (1/`Gt') * ((0 - `St_i')^2)			if _t > `btime' & `touse'

		if "`compete'" != "" { 
			replace `brier' = (1/`Gt_i') * ((0 - `St_i')^2)	if _t <= `btime' & inlist(`event',`crvals') & `touse'		
		}


} // end quietly

	// get mean brier score and save as scalar
		quietly mean `brier' if `touse'
		
		// display the results
		tempname meanout n mean se ll ul level
		local `level' = r(level)
		local `n' = e(N)
		matrix `meanout' = r(table)
		matrix colnames `meanout' = "brier"
		scalar `mean' = `meanout'[1,1]
		scalar `se'   = `meanout'[2,1]
		scalar `ll'   = `meanout'[5,1]
		scalar `ul'   = `meanout'[6,1]

		disp ""
		disp "Mean estimation                      Number of obs   = "  %9.0g as result  ``n''
		disp ""
		tempname mytab
		.`mytab' = ._tab.new, col(5) lmargin(0)
		.`mytab'.width    15   |12    12    12    12
		.`mytab'.titlefmt  .     .    . %24s   .
		.`mytab'.pad       .     2     3     3    3
		.`mytab'.numfmt    . %9.0g %9.0g %9.0g %9.0g
		.`mytab'.strcolor result  .  .  . . 
		.`mytab'.strfmt    %14s  .  .  . .
		.`mytab'.strcolor   text  .  .  . .
		.`mytab'.sep, top
		.`mytab'.titles " "           				/// 1
				"Mean"								/// 2
				"   Std. Err."                     	/// 3
				"[``level''% Conf. Interval]" ""  	//  4 5
		.`mytab'.sep, middle
		.`mytab'.row    "Brier score" 				///
			`mean'									///
			`se' 									///
			`ll'									///
			`ul'
		.`mytab'.sep, bottom
		
		
		matrix br  = e(b)
		return scalar brier = br[1,1]
		return matrix table = `meanout'

	// to save, or not to save, this is the question....
	quietly {
		if "`gen'" != "" {
			gen `gen' = `brier'
			label var `gen' "brier scores"
		}
	} // end gen quietly	
end 
