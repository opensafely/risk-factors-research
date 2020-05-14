*! version 1.5.7 25jun2015
* Added various options + use mata for orthogonalisation
* Based on an original program by Chris Nelson
* Chris Nelson 24/APR/2006
* Paul Lambert 28/AUG/2008
* Mark Rutherford 05/DEC/2008
* Patrick royston 16/OCT2009 - allow numlist for knots to be in non-ascending order
* Therese Andersson 01/FEB/2010 - add an option to calculate the spline variables backwards, to use for cure estimation in stpm2
* Paul Lambert 13/APR/2011 - added scalar option. (fixed for cure models 24/6/2011 & 28/6/2011).
* Therese Andersson 17Jan2012, adding options for relaxing the constraints of continuous first * 
*							  and second derivative at the first knot (last if reversed splines)  
* Paul Lambert 8/4/2013 - correct incorrect error message when using df(1)
* Mark Rutherford 25/July/2014  - allow a center option & make percentiles code more efficient
* Patrick Royston 31/7/2014 -  return macros for rcslist varlists
* Paul Lambert 25/6/2015 - when using percentiles, r(knots) were not in numerical order

program define rcsgen, rclass
	version 10.0
	syntax  [varlist(default=none)] [if] [in] ///
		,	[Gen(string) DGen(string) Knots(numlist) BKnots(numlist max=2) Orthog Percentiles(numlist ascending) RMATrix(name) ///
			DF(int 0)  IF2(string) FW(varname)  REVerse SCAlar(string) NOSecondder NOFirstder CENTer(string)]      

	marksample touse
	
// sort knots
	if "`knots'" != "" {
		numlist "`knots'", sort
		local knots `r(numlist)'
	}
    
/* Error checks */
	if "`scalar'"  != "" {
		if "`varlist'" != "" {
			display as error "You can't specify both a varname and the scalar option"
			exit 198
		}
		if "`df'" != "0" {
			display as error "You can't specify the df option with the scalar option"
			exit 198
		} 
		if "`percentiles'" != "" {
			display as error "You can't specify the percentiles option with the scalar option"
			exit 198
		} 
		if "`orthog'" != "" {
			display as error "You can't specify the orthog option with the scalar option"
			exit 198
		}
		if "`fw'" != "" {
			display as error "You can't specify the fw option with the scalar option"
			exit 198
		}
	}

	if "`knots'" != "" & "`percentiles'" != "" {
		display as err "Only one of the knots, df and percentiles options can be used"
		exit 198
	}
        
	if "`knots'" != "" & "`df'" != "0" {
		display as err "Only one of the knots, df and percentiles options can be used"
		exit 198
	}
	
	if "`df'" != "0" & "`percentiles'" != "" {
		display as err "Only one of the knots, df and percentiles options can be used"
		exit 198
	} 

	if "`bknots'" != "" & "`df'" == "0" {
		display as err "Boundary knots can only be defined with the degrees of freedom option"
		exit 198
	} 

	if "`orthog'" != "" & "`rmatrix'" != "" {
		display as error "Only one of the orthog and rmatrix options  can be specified"
		exit 198
	}
	
	if "`center'" != "" & "`reverse'" != "" {
		display as error "The center option cannot be used when using the reverse option"
		exit 198
	}
		
	if "`nofirstder'" != "" & "`nosecondder'" != "" {
		display as error "Only one of the nofirstder and nosecondder can be specified"
		exit 198
	}
		
	if "`gen'" == "" {
		di in red "Must specify name for cubic splines basis"
		exit 198
	}
    
/* percentiles option */             
	if "`percentiles'" != "" {
		if "`fw'" != "" {
			local fw [fw=`fw']
		}
		if "`if2'" != "" {
			local aif & `if2'
		}
		local knots

		local percentilesm
			foreach ptile in `percentiles' {
               summ `varlist' if `touse' `aif', meanonly
               if `ptile' == 0 {
					local knots `r(min)'
				}
                else if `ptile' == 100 {
					local knots `knots' `r(max)'
                }
                else {
					local percentilesm `percentilesm' `ptile'
                }
			}			
	
		local dfp: word count `percentilesm'
				
		_pctile `varlist' if `touse' `aif' `fw', p(`percentilesm')
				
		forvalues i= 1/`dfp' {
			local knots `knots' `r(r`i')'
		}
		local knots : list sort knots
	}

/* Find knot locations if df option is used */
	if "`df'" > "1" {
		if "`fw'" != "" {
			local fw [fw=`fw']
		}
		if "`if2'" != "" {
			local aif & `if2'
		}
		if "`bknots'"!="" {
			local lowerknot: word 1 of `bknots'
			local upperknot: word 2 of `bknots'
		}
		else {
			quietly summ `varlist' if `touse' `aif', meanonly
			local lowerknot `r(min)'
			local upperknot `r(max)'
		}
		local dfm1=`df'-1        

		forvalues y= 1/`dfm1' {
			local centile=(100/`df')*`y'
			local centilelist `centilelist' `centile'
		}

		local intknots
		
		_pctile `varlist' if `touse' `aif' `fw', p(`centilelist')

		forvalues i= 1/`dfm1' {
			local intknots `intknots' `r(r`i')'
		}
		if real(word("`intknots'",1))<=`lowerknot' {
			display as err "Lowest internal knot is not greater than lower boundary knot"
			exit 198
		}
		if real(word("`intknots'",`dfm1'))>=`upperknot' {
			display as err "Highest internal knot is not greater than upper boundary knot"
			exit 198
		}
	 	local knots
		local knots  `lowerknot' `intknots' `upperknot'
	}


	
/*Derive the spline variables in the default way (not backwards)*/
		
	if "`reverse'" == "" & "`nosecondder'"  == "" & "`nofirstder'" == "" {
	/* Start to derive spline variables */

		if "`scalar'" == "" {
			quietly gen double `gen'1 = `varlist' if `touse'
		}
		else {
			scalar `gen'1 = `scalar'
		}	
		
		if "`center'"!= "" {
			tempname center1
			scalar `center1' = `center'
		}		

	/* generate first derivative if dgen option is specified */
		if "`dgen'" != "" {
			if "`scalar'" == "" {
				quietly gen double `dgen'1 = 1 if `touse'
			}
			else {
				scalar `dgen'1 = 1
			}			
		}
		local rcslist `gen'1 
		local drcslist `dgen'1
	
		local nk : word count `knots'
		if "`knots'" == "" {
			local interior  = 0
		}
		else {
			local interior  = `nk' - 2
		}
		local nparams = `interior' + 1
	
		if "`knots'" != "" {
			local i = 1 
			tokenize "`knots'"
			while "``i''" != "" {
				local k`i' ``i''
				local i = `i' + 1
			}
	
			local kmin = `k1'
			local kmax = `k`nk''
	
			forvalues j=2/`nparams' {
				local lambda = (`kmax' - `k`j'')/(`kmax' - `kmin')
		
				if "`scalar'" == "" {
					quietly gen double `gen'`j' = ((`varlist'-`k`j'')^3)*(`varlist'>`k`j'') - ///
								`lambda'*((`varlist'-`kmin')^3)*(`varlist'>`kmin') - ///
								(1-`lambda')*((`varlist'-`kmax')^3)*(`varlist'>`kmax')  if `touse'					
				}	
				else {
					scalar `gen'`j' = ((`scalar'-`k`j'')^3)*(`scalar'>`k`j'') - ///
								`lambda'*((`scalar'-`kmin')^3)*(`scalar'>`kmin') - ///
								(1-`lambda')*((`scalar'-`kmax')^3)*(`scalar'>`kmax')  
				}
				
				if "`center'"!= "" {
						tempname center`j'
						scalar `center`j'' = ((`center'-`k`j'')^3)*(`center'>`k`j'') - ///
						`lambda'*((`center'-`kmin')^3)*(`center'>`kmin') - ///
						(1-`lambda')*((`center'-`kmax')^3)*(`center'>`kmax')
				}	
				
				local rcslist `rcslist' `gen'`j'
	
	/* calculate derivatives */
				if "`dgen'"!="" {
					if "`scalar'" == "" {
						quietly gen double `dgen'`j' = (3*(`varlist'- `k`j'')^2)*(`varlist'>`k`j'') - ///
									`lambda'*(3*(`varlist'-`kmin')^2)*(`varlist'>`kmin') - ///
									(1-`lambda')*(3*(`varlist'-`kmax')^2)*(`varlist'>`kmax') 
					}
					else {
						scalar `dgen'`j' = (3*(`scalar'- `k`j'')^2)*(`scalar'>`k`j'') - ///
									`lambda'*(3*(`scalar'-`kmin')^2)*(`scalar'>`kmin') - ///
									(1-`lambda')*(3*(`scalar'-`kmax')^2)*(`scalar'>`kmax') 
					}
					local drcslist `drcslist' `dgen'`j'
				}       
			}
		}
	}
	



/*Derive the spline variables in reversed order */		/*ADDED: 2010-02-02 by Therese Andersson*/
		
	else if "`reverse'" != "" & "`nosecondder'" == "" & "`nofirstder'" == "" {
		local rcslist  
		local drcslist

		local nk : word count `knots'
		if "`knots'" == "" {
			local interior  = 0
		}
		else {
			local interior  = `nk' - 2
		}
		local nparams = `interior' + 1

		if "`knots'" != "" {
			local i = 1 
			tokenize "`knots'"
			while "``i''" != "" {
				local k`i' ``i''
				local i = `i' + 1
			}

			local kmin = `k1'
			local kmax = `k`nk''

			forvalues j=1/`interior' {
				local h = `nk'-`j'
				local lambda = (`k`h''-`kmin')/(`kmax' - `kmin')
				if "`scalar'" == "" {
					quietly gen double `gen'`j' = ((`k`h''-`varlist')^3)*(`k`h''>`varlist') - ///
								`lambda'*((`kmax'-`varlist')^3)*(`kmax'>`varlist') - ///
								(1-`lambda')*((`kmin'-`varlist')^3)*(`kmin'>`varlist')  if `touse'
				}
				else {
					scalar `gen'`j' = ((`k`h''-`scalar')^3)*(`k`h''>`scalar') - ///
								`lambda'*((`kmax'-`scalar')^3)*(`kmax'>`scalar') - ///
								(1-`lambda')*((`kmin'-`scalar')^3)*(`kmin'>`scalar') 
				}
				local rcslist `rcslist' `gen'`j'

/* calculate derivatives */
				if "`dgen'"!="" {
					if "`scalar'" == "" {
						quietly gen double `dgen'`j' = (-3*(`k`h''-`varlist')^2)*(`k`h''>`varlist') - ///
									`lambda'*(-3*(`kmax'-`varlist')^2)*(`kmax'>`varlist') - ///
									(1-`lambda')*(-3*(`kmin'-`varlist')^2)*(`kmin'>`varlist')  if `touse'
					}
					else {
						scalar `dgen'`j' = (-3*(`k`h''-`scalar')^2)*(`k`h''>`scalar') - ///
									`lambda'*(-3*(`kmax'-`scalar')^2)*(`kmax'>`scalar') - ///
									(1-`lambda')*(-3*(`kmin'-`scalar')^2)*(`kmin'>`scalar') 

					}
					local drcslist `drcslist' `dgen'`j'
				}       
			}
/* Derive last spline variable */
			if "`scalar'" == "" {
				quietly gen double `gen'`nparams' = `varlist' if `touse'
			}
			else {
				scalar `gen'`nparams' = `scalar' 
			}
			local rcslist `rcslist' `gen'`nparams'

/* generate first derivative if dgen option is specified */
			if "`dgen'" != "" {
				if "`scalar'" == "" {
					quietly gen double `dgen'`nparams' = 1 if `touse'
				}
				else {
					scalar `dgen'`nparams' = 1 
				}
				local drcslist `drcslist' `dgen'`nparams'
			}
		}
	}

//  no second derivative
		
	else if "`nosecondder'" != "" & "`reverse'" == "" & "`nofirstder'" == "" {
		/* Start to derive spline variables */
		if "`scalar'" == "" {
			quietly gen double `gen'1 = `varlist' if `touse'
		}
		else {
			scalar `gen'1 = `scalar'
		}
		if "`center'"!= "" {
			tempname center1
			scalar `center1' = `center'
		}	

        /* generate first derivative if dgen option is specified */
		if "`dgen'" != "" {
			if "`scalar'" == "" {
				quietly gen double `dgen'1 = 1 if `touse'
			}
			else {
				scalar `dgen'1 = 1
			}	                       
		}
		local rcslist `gen'1 
		local drcslist `dgen'1

		local nk : word count `knots'
		if "`knots'" == "" {
			local interior  = 0
		}
		else {
			local interior  = `nk' - 2
		}
		local nparams = `interior' + 2
		local npar = `interior' + 1

		if "`knots'" != "" {
			local i = 1 
			tokenize "`knots'"
			while "``i''" != "" {
				local k`i' ``i''
				local i = `i' + 1
			}

			local kmin = `k1'
			local kmax = `k`nk''

			forvalues j=2/`npar' {
				local lambda = (`kmax' - `k`j'')/(`kmax' - `kmin')
				if "`scalar'" == "" {
					quietly gen double `gen'`j' = ((`varlist'-`k`j'')^3)*(`varlist'>`k`j'') - ///
						`lambda'*((`varlist'-`kmin')^3)*(`varlist'>`kmin') - ///
						(1-`lambda')*((`varlist'-`kmax')^3)*(`varlist'>`kmax') if `touse'
				}
				else {
					scalar `gen'`j' = ((`scalar'-`k`j'')^3)*(`scalar'>`k`j'') - ///
						`lambda'*((`scalar'-`kmin')^3)*(`scalar'>`kmin') - ///
						(1-`lambda')*((`scalar'-`kmax')^3)*(`scalar'>`kmax')  
				}
 
				if "`center'"!= "" {
					tempname center`j'
					scalar `center`j'' = ((`center'-`k`j'')^3)*(`center'>`k`j'') - ///
						`lambda'*((`center'-`kmin')^3)*(`center'>`kmin') - ///
						(1-`lambda')*((`center'-`kmax')^3)*(`center'>`kmax')  
				}
								
				local rcslist `rcslist' `gen'`j'
        
/* calculate derivatives */
				if "`dgen'"!="" {
					if "`scalar'" == "" {
						quietly gen double `dgen'`j' = (3*(`varlist'- `k`j'')^2)*(`varlist'>`k`j'') - ///
							`lambda'*(3*(`varlist'-`kmin')^2)*(`varlist'>`kmin') - ///
							(1-`lambda')*(3*(`varlist'-`kmax')^2)*(`varlist'>`kmax') 
					}
					else {
						scalar `dgen'`j' = (3*(`scalar'- `k`j'')^2)*(`scalar'>`k`j'') - ///
							`lambda'*(3*(`scalar'-`kmin')^2)*(`scalar'>`kmin') - ///
							(1-`lambda')*(3*(`scalar'-`kmax')^2)*(`scalar'> `kmax') 
					}
					local drcslist `drcslist' `dgen'`j'
				}       
			}
				
/* Derive last spline variable */
			local c=(1/(3*(`kmax' - `kmin')))						
			if "`scalar'" == "" {
				quietly gen double `gen'`nparams' = (`varlist'-`kmin')^2*(`varlist'>`kmin') - ///
					`c'*((`varlist'-`kmin')^3)*(`varlist'>`kmin') + ///
					`c'*((`varlist'-`kmax')^3)*(`varlist'>`kmax') if `touse'
			}
			else {
				scalar `gen'`nparams' = (`scalar'-`kmin')^2*(`scalar'>`kmin') - ///
					`c'*((`scalar'-`kmin')^3)*(`scalar'>`kmin') + ///
					`c'*((`scalar'-`kmax')^3)*(`scalar'>`kmax') 
			}
						
			if "`center'"!= "" {
				tempname center`nparams'
				scalar `center`nparams'' = (`center'-`kmin')^2*(`center'>`kmin') - ///
					`c'*((`center'-`kmin')^3)*(`center'>`kmin') + ///
					`c'*((`center'-`kmax')^3)*(`center'>`kmax') 
			}						
						
			local rcslist `rcslist' `gen'`nparams'

/* generate first derivative if dgen option is specified */
			if "`dgen'" != "" {
				if "`scalar'" == "" {
					quietly gen double `dgen'`nparams' = 2*(`varlist'-`kmin')*(`varlist'>`kmin') - ///
						3*`c'*((`varlist'-`kmin')^2)*(`varlist'>`kmin') + ///
						3*`c'*((`varlist'-`kmax')^2)*(`varlist'>`kmax') if `touse' 
				}
				else {
					scalar `dgen'`nparams' = 2*(`scalar'-`kmin')*(`scalar'>`kmin') - ///
						3*`c'*((`scalar'-`kmin')^2)*(`scalar'>`kmin') + ///
						3*`c'*((`scalar'-`kmax')^2)*(`scalar'>`kmax') 
				}
				local drcslist `drcslist' `dgen'`nparams'
			}
		}
	}
 
 ****************************!!!*********************			
		
	else if "`nosecondder'" != "" & "`reverse'" != "" & "`nofirstder'" == ""{
                			
		local nk : word count `knots'
		if "`knots'" == "" {
			local interior  = 0
		}
		else {
			local interior  = `nk' - 2
		}
		local nparams = `interior' + 2
		local npar = `interior' + 1

		if "`knots'" != "" {
			local i = 1 
			tokenize "`knots'"
			while "``i''" != "" {
				local k`i' ``i''
				local i = `i' + 1
			}

			local kmin = `k1'
			local kmax = `k`nk''

/* Derive first spline variable */
			local c=(1/(3*(`kmax' - `kmin')))						
			if "`scalar'" == "" {
				quietly gen double `gen'1 = (`kmax'-`varlist')^2*(`kmax'>`varlist') - ///
					`c'*((`kmax'-`varlist')^3)*(`kmax'>`varlist') + ///
					`c'*((`kmin'-`varlist')^3)*(`kmin'>`varlist') if `touse'
			}
			else {
				scalar `gen'1 = (`kmax'-`scalar')^2*(`kmax'>`scalar') - ///
					`c'*((`kmax'-`scalar')^3)*(`kmax'>`scalar') + ///
					`c'*((`kmin'-`scalar')^3)*(`kmin'>`scalar') 
			}
			local rcslist `gen'1

/* generate first derivative if dgen option is specified */
			if "`dgen'" != "" {
				if "`scalar'" == "" {
					quietly gen double `dgen'1 = -2*(`kmax'-`varlist')*(`kmax'>`varlist') - ///
						(-3)*`c'*((`kmax'-`varlist')^2)*(`kmax'>`varlist') + ///
						(-3)*`c'*((`kmin'-`varlist')^2)*(`kmin'>`varlist') if `touse' 
				}
				else {
					scalar `dgen'1 = -2*(`kmax'-`scalar')*(`kmax'>`scalar') - ///
						(-3)*`c'*((`kmax'-`scalar')^2)*(`kmax'>`scalar') + ///
						(-3)*`c'*((`kmin'-`scalar')^2)*(`kmin'>`scalar')
				}
				local drcslist `dgen'1
			}

			forvalues j=2/`npar' {
				local h = `nk'-(`j'-1)
				local lambda = (`k`h''-`kmin')/(`kmax' - `kmin')
				if "`scalar'" == "" {
					quietly gen double `gen'`j' = ((`k`h''-`varlist')^3)*(`k`h''>`varlist') - ///
						`lambda'*((`kmax'-`varlist')^3)*(`kmax'>`varlist') - ///
						(1-`lambda')*((`kmin'-`varlist')^3)*(`kmin'>`varlist') if `touse'
				}
				else {
					scalar `gen'`j' = ((`k`h''-`scalar')^3)*(`k`h''>`scalar') - ///
						`lambda'*((`kmax'-`scalar')^3)*(`kmax'>`scalar') - ///
						(1-`lambda')*((`kmin'-`scalar')^3)*(`kmin'>`scalar') 
				}
				local rcslist `rcslist' `gen'`j'

/* calculate derivatives */
				if "`dgen'"!="" {
					if "`scalar'" == "" {
						quietly gen double `dgen'`j' = (-3*(`k`h''-`varlist')^2)*(`k`h''>`varlist') - ///
							`lambda'*(-3*(`kmax'-`varlist')^2)*(`kmax'>`varlist') - ///
							(1-`lambda')*(-3*(`kmin'-`varlist')^2)*(`kmin'>`varlist')  if `touse'
					}
					else {
						scalar `dgen'`j' = (-3*(`k`h''-`scalar')^2)*(`k`h''>`scalar') - ///
							`lambda'*(-3*(`kmax'-`scalar')^2)*(`kmax'>`scalar') - ///
							(1-`lambda')*(-3*(`kmin'-`scalar')^2)*(`kmin'>` scalar') 
					}
					local drcslist `drcslist' `dgen'`j'
				}       
			}
/* Derive last spline variable */
			if "`scalar'" == "" {
				quietly gen double `gen'`nparams' = `varlist' if `touse'
			}
			else {
				scalar `gen'`nparams' = `scalar' 
			}
			local rcslist `rcslist' `gen'`nparams'

/* generate first derivative if dgen option is specified */
			if "`dgen'" != "" {
				if "`scalar'" == "" {
					quietly gen double `dgen'`nparams' = 1 if `touse'
				}
				else {
					scalar `dgen'`nparams' = 1 
				}
				local drcslist `drcslist' `dgen'`nparams'
			}
		}
	}
 
**************************** !!!! ************************************ 

******** ADDED 2012-01-10 Relax assumption of continuous first and second derivative at the first knot (or the last knot if reverse option is used)

****************************!!!*********************	
		
	else if "`nosecondder'" == "" & "`reverse'" == "" & "`nofirstder'" != "" {
 /* Start to derive spline variables */
		if "`scalar'" == "" {
			quietly gen double `gen'1 = `varlist' if `touse'
		}
		else {
			scalar `gen'1 = `scalar'
		}
				
		if "`center'"!= "" {
			tempname center1
			scalar `center1' = `center'
		}	

        /* generate first derivative if dgen option is specified */
		if "`dgen'" != "" {
			if "`scalar'" == "" {
				quietly gen double `dgen'1 = 1 if `touse'
			}
			else {
				scalar `dgen'1 = 1
			}                       
		}
		local rcslist `gen'1 
		local drcslist `dgen'1

		local nk : word count `knots'
		if "`knots'" == "" {
			local interior  = 0
		}
		else {
			local interior  = `nk' - 2
		}
		local nparams = `interior' + 3
		local npar = `interior' + 1
		local par = `interior' + 2

		if "`knots'" != "" {
			local i = 1 
			tokenize "`knots'"
			while "``i''" != "" {
				local k`i' ``i''
				local i = `i' + 1
			}

			local kmin = `k1'
			local kmax = `k`nk''

			forvalues j=2/`npar' {
				local lambda = (`kmax' - `k`j'')/(`kmax' - `kmin')
				if "`scalar'" == "" {
					quietly gen double `gen'`j' = ((`varlist'-`k`j'')^3)*(`varlist'>`k`j'') - ///
						`lambda'*((`varlist'-`kmin')^3)*(`varlist'>`kmin') - ///
						(1-`lambda')*((`varlist'-`kmax')^3)*(`varlist'>`kmax') if `touse'
				}
				else {
					scalar `gen'`j' = ((`scalar'-`k`j'')^3)*(`scalar'>`k`j'') - ///
						`lambda'*((`scalar'-`kmin')^3)*(`scalar'>`kmin') - ///
						(1-`lambda')*((`scalar'-`kmax')^3)*(`scalar'>`kmax')  
				}
								
				if "`center'"!= "" {
					tempname center`j'
					scalar `center`j'' = ((`center'-`k`j'')^3)*(`center'>`k`j'') - ///
						`lambda'*((`center'-`kmin')^3)*(`center'>`kmin') - ///
						(1-`lambda')*((`center'-`kmax')^3)*(`center'>`kmax')  
				}									
                                
				local rcslist `rcslist' `gen'`j'
        
/* calculate derivatives */
				if "`dgen'"!="" {
					if "`scalar'" == "" {
						quietly gen double `dgen'`j' = (3*(`varlist'- `k`j'')^2)*(`varlist'>`k`j'') - ///
							`lambda'*(3*(`varlist'-`kmin')^2)*(`varlist'>`kmin') - ///
							(1-`lambda')*(3*(`varlist'-`kmax')^2)*(`varlist'>`kmax') 
					}
					else {
						scalar `dgen'`j' = (3*(`scalar'- `k`j'')^2)*(`scalar'>`k`j'') - ///
							`lambda'*(3*(`scalar'-`kmin')^2)*(`scalar'>`kmin') - ///
							(1-`lambda')*(3*(`scalar'-`kmax')^2)*(`scalar'> `kmax') 
					}
					local drcslist `drcslist' `dgen'`j'
				}       
			}
				
/* Derive the first extra spline variable */
			local c=(1/(3*(`kmax' - `kmin')))						
			if "`scalar'" == "" {
				quietly gen double `gen'`par' = (`varlist'-`kmin')^2*(`varlist'>`kmin') - ///
					`c'*((`varlist'-`kmin')^3)*(`varlist'>`kmin') + ///
					`c'*((`varlist'-`kmax')^3)*(`varlist'>`kmax') if `touse'
			}
			else {
				scalar `gen'`par' = (`scalar'-`kmin')^2*(`scalar'>`kmin') - ///
					`c'*((`scalar'-`kmin')^3)*(`scalar'>`kmin') + ///
					`c'*((`scalar'-`kmax')^3)*(`scalar'>`kmax') 
			}
						
			if "`center'"!= "" {
				scalar center`par' = (`center'-`kmin')^2*(`center'>`kmin') - ///
					`c'*((`center'-`kmin')^3)*(`center'>`kmin') + ///
					`c'*((`center'-`kmax')^3)*(`center'>`kmax') 
			}							
						
			local rcslist `rcslist' `gen'`par'

/* generate first derivative if dgen option is specified */
			if "`dgen'" != "" {
				if "`scalar'" == "" {
					quietly gen double `dgen'`par' = 2*(`varlist'-`kmin')*(`varlist'>`kmin') - ///
						3*`c'*((`varlist'-`kmin')^2)*(`varlist'>`kmin') + ///
						3*`c'*((`varlist'-`kmax')^2)*(`varlist'>`kmax') if `touse' 
				}
				else {
					scalar `dgen'`par' = 2*(`scalar'-`kmin')*(`scalar'>`kmin') - ///
						3*`c'*((`scalar'-`kmin')^2)*(`scalar'>`kmin') + ///
						3*`c'*((`scalar'-`kmax')^2)*(`scalar'>`kmax') 
				}
				local drcslist `drcslist' `dgen'`par'
			}
/* Derive the last spline variable */
			if "`scalar'" == "" {
				quietly gen double `gen'`nparams' = (`varlist'-`kmin')*(`varlist'>`kmin') if `touse'
			}
			else {
				scalar `gen'`nparams' = (`scalar'-`kmin')*(`scalar'>`kmin')  
			}
			if "`center'"!= "" {
				tempname center`nparams'
				scalar center`nparams' = (`center'-`kmin')*(`center'>`kmin')  
			}						
						
			local rcslist `rcslist' `gen'`nparams'

/* generate first derivative if dgen option is specified */
			if "`dgen'" != "" {
				if "`scalar'" == "" {
					quietly gen double `dgen'`nparams' = 1*(`varlist'>`kmin')  if `touse' 
				}
				else {
					scalar `dgen'`nparams' = 1*(`scalar'>`kmin')
				}
				local drcslist `drcslist' `dgen'`nparams'
			}
		}
	}
 
 ****************************!!!*********************			
		
	else if "`nosecondder'" == "" & "`reverse'" != "" & "`nofirstder'" != ""{
		local nk : word count `knots'
		if "`knots'" == "" {
			local interior  = 0
		}
		else {
			local interior  = `nk' - 2
		}
		local nparams = `interior' + 3
		local npar = `interior' + 1
		local par = `interior' + 2

		if "`knots'" != "" {
		local i = 1 
		tokenize "`knots'"
		while "``i''" != "" {
			local k`i' ``i''
			local i = `i' + 1
		}

		local kmin = `k1'
		local kmax = `k`nk''
/* Derive first spline variable */
		if "`scalar'" == "" {
			quietly gen double `gen'1 = (`kmax'-`varlist')*(`kmax'>`varlist')  if `touse'
		}
		else {
			scalar `gen'1 = (`kmax'-`scalar')*(`kmax'>`scalar')  
		}

		if "`center'"!= "" {
			tempname center1
				scalar `center1' = (`kmax'-`center')*(`kmax'>`center')   
		}						
						
		local rcslist `gen'1

/* generate first derivative if dgen option is specified */
		if "`dgen'" != "" {
			if "`scalar'" == "" {
				quietly gen double `dgen'1 = -1*(`kmax'>`varlist') if `touse' 
			}
			else {
				scalar `dgen'1 = -1
			}
			local drcslist `dgen'1
		}

/* Derive second spline variable */
		local c=(1/(3*(`kmax' - `kmin')))						
		if "`scalar'" == "" {
			quietly gen double `gen'2 = (`kmax'-`varlist')^2*(`kmax'>`varlist') - ///
				`c'*((`kmax'-`varlist')^3)*(`kmax'>`varlist') + ///
				`c'*((`kmin'-`varlist')^3)*(`kmin'>`varlist') if `touse'
		}
		else {
			scalar `gen'2 = (`kmax'-`scalar')^2*(`kmax'>`scalar') - ///
				`c'*((`kmax'-`scalar')^3)*(`kmax'>`scalar') + ///
				`c'*((`kmin'-`scalar')^3)*(`kmin'>`scalar') 
		}
						
		if "`center'"!= "" {
			scalar center2 = (`kmax'-`center')^2*(`kmax'>`center') - ///
				`c'*((`kmax'-`center')^3)*(`kmax'>`center') + ///
				`c'*((`kmin'-`center')^3)*(`kmin'>`center') 
		}	
						
		local rcslist `rcslist' `gen'2

/* generate first derivative if dgen option is specified */
		if "`dgen'" != "" {
			if "`scalar'" == "" {
				quietly gen double `dgen'2 = -2*(`kmax'-`varlist')*(`kmax'>`varlist') - ///
					(-3)*`c'*((`kmax'-`varlist')^2)*(`kmax'>`varlist') + ///
					(-3)*`c'*((`kmin'-`varlist')^2)*(`kmin'>`varlist') if `touse' 
			}
			else {
				scalar `dgen'2 = -2*(`kmax'-`scalar')*(`kmax'>`scalar') - ///
					(-3)*`c'*((`kmax'-`scalar')^2)*(`kmax'>`scalar') + ///
					(-3)*`c'*((`kmin'-`scalar')^2)*(`kmin'>`scalar')
			}
			local drcslist `drcslist' `dgen'2
		}

		forvalues j=3/`par' {
			local h = `nk'-(`j'-2)
			local lambda = (`k`h''-`kmin')/(`kmax' - `kmin')
			if "`scalar'" == "" {
				quietly gen double `gen'`j' = ((`k`h''-`varlist')^3)*(`k`h''>`varlist') - ///
					`lambda'*((`kmax'-`varlist')^3)*(`kmax'>`varlist') - ///
					(1-`lambda')*((`kmin'-`varlist')^3)*(`kmin'>`varlist') if `touse'
				}
				else {
					scalar `gen'`j' = ((`k`h''-`scalar')^3)*(`k`h''>`scalar') - ///
						`lambda'*((`kmax'-`scalar')^3)*(`kmax'>`scalar') - ///
						(1-`lambda')*((`kmin'-`scalar')^3)*(`kmin'>`scalar') 
				}
						
				if "`center'"!= "" {
					tempname center`j'
					scalar `center`j'' = ((`k`h''-`center')^3)*(`k`h''>`center') - ///
						`lambda'*((`kmax'-`center')^3)*(`kmax'>`center') - ///
						(1-`lambda')*((`kmin'-`center')^3)*(`kmin'>`center') 						
				}									
								
				local rcslist `rcslist' `gen'`j'

/* calculate derivatives */
				if "`dgen'"!="" {
					if "`scalar'" == "" {
						quietly gen double `dgen'`j' = (-3*(`k`h''-`varlist')^2)*(`k`h''>`varlist') - ///
							`lambda'*(-3*(`kmax'-`varlist')^2)*(`kmax'>`varlist') - ///
							(1-`lambda')*(-3*(`kmin'-`varlist')^2)*(`kmin'>`varlist')  if `touse'
					}
					else {
						scalar `dgen'`j' = (-3*(`k`h''-`scalar')^2)*(`k`h''>`scalar') - ///
							`lambda'*(-3*(`kmax'-`scalar')^2)*(`kmax'>`scalar') - ///
							(1-`lambda')*(-3*(`kmin'-`scalar')^2)*(`kmin'>` scalar') 
					}
					local drcslist `drcslist' `dgen'`j'
				}       
			}
/* Derive last spline variable */
			if "`scalar'" == "" {
				quietly gen double `gen'`nparams' = `varlist' if `touse'
			}
			else {
				scalar `gen'`nparams' = `scalar' 
			}

			if "`center'"!= "" {
				tempname center`nparams'
				scalar `center`nparams'' = `center' 
			}
						
			local rcslist `rcslist' `gen'`nparams'

/* generate first derivative if dgen option is specified */
			if "`dgen'" != "" {
				if "`scalar'" == "" {
					quietly gen double `dgen'`nparams' = 1 if `touse'
				}
				else {
					scalar `dgen'`nparams' = 1 
				}
				local drcslist `drcslist' `dgen'`nparams'
			}
		}
	}
 
**************************** !!!! ************************************  
 
/* orthogonlise */      
	if "`orthog'" != "" {
		tempname R Rinv cons
		mata: orthgs("`rcslist'","`touse'") 
		matrix `Rinv' = inv(`R')
		if "`dgen'" != "" {
			gen `cons' = 1 if `touse'
			mata st_store(.,tokens(st_local("drcslist")), /// 
							"`touse'",st_data(.,tokens(st_local("drcslist")), ///
							"`touse'")*st_matrix("`Rinv'")[1..`nparams',1..`nparams'])
		}
	}
	else if "`rmatrix'" != "" {
		tempname Rinv cons
		matrix `Rinv' = inv(`rmatrix')
		if "`scalar'" == "" {
			gen `cons' = 1 if `touse'
			mata st_store(.,tokens(st_local("rcslist")), ///  
					"`touse'",(st_data(.,   tokens(st_local("rcslist") + " `cons'"), ///
					"`touse'"))*st_matrix("`Rinv'")[,1..`nparams'])	
			if "`dgen'" != "" {
				mata st_store(.,tokens(st_local("drcslist")), ///
					"`touse'",st_data(.,tokens(st_local("drcslist")), ///
					"`touse'")*st_matrix("`Rinv'")[1..`nparams',1..`nparams'])
		
			}
		}
		else {
			tempname scalarmatrix
			matrix `scalarmatrix' = `gen'1
			forvalues i = 2/`nparams'{
				matrix `scalarmatrix' = `scalarmatrix',`gen'`i'
			}
			matrix `scalarmatrix' = `scalarmatrix',1
			mata st_matrix("`scalarmatrix'",st_matrix("`scalarmatrix'")*st_matrix("`Rinv'")[,1..`nparams']) 
			forvalues i = 1/`nparams'{
				scalar `gen'`i' = el(`scalarmatrix',1,`i')
			}
			if "`dgen'" != "" {
				tempname dscalarmatrix
				matrix `dscalarmatrix' = `dgen'1
				forvalues i = 2/`nparams'{
					matrix `dscalarmatrix' = `dscalarmatrix',`dgen'`i'
				}
				mata st_matrix("`dscalarmatrix'",st_matrix("`dscalarmatrix'")*st_matrix("`Rinv'")[1..`nparams',1..`nparams'])
				forvalues i = 1/`nparams'{
					scalar `dgen'`i' = el(`dscalarmatrix',1,`i')
				}
			}
		}
	}
	
	/*subtract the value at the last knot, so that there is an interpretable baseline*/ 		/*ADDED: 2010-04-14 by Therese Andersson*/
	if ("`orthog'" != "" | "`rmatrix'" != "") & "`reverse'" != "" {					/*2010-04-28 TA, also make this work with rmatrix*/

		tempname rcsvaluevector
		local rcsvaluelist
		
		if "`knots'" != "" {
			local i = 1 
			tokenize "`knots'"
			while "``i''" != "" {
				local k`i' ``i''
				local i = `i' + 1
			}

			local kmin = `k1'
			local kmax = `k`nk''

			if "`nosecondder'" == "" & "`nofirstder'" == "" {
				forvalues j=1/`interior' {
					local h = `nk'-`j'
					local lambda = (`k`h''-`kmin')/(`kmax' - `kmin')
					local rcsvalue`j' = ((`k`h''-`kmax')^3)*(`k`h''>`kmax') - ///
						`lambda'*((`kmax'-`kmax')^3)*(`kmax'>`kmax') - ///
						(1-`lambda')*((`kmin'-`kmax')^3)*(`kmin'>`kmax')
					local rcsvaluelist `rcsvaluelist' `rcsvalue`j''
				}
			}
			if "`nosecondder'" != "" & "`nofirstder'" == "" {
				local c=(1/(3*(`kmax' - `kmin')))						
				local rcsvalue1 = (`kmax'-`kmax')^2*(`kmax'>`kmax') - ///
					`c'*((`kmax'-`kmax')^3)*(`kmax'>`kmax') + ///
					`c'*((`kmin'-`kmax')^3)*(`kmin'>`kmax') 
				local rcsvaluelist `rcsvalue1'
							
				forvalues j=2/`npar' {
					local h = `nk'-(`j'-1)
					local lambda = (`k`h''-`kmin')/(`kmax' - `kmin')
					local rcsvalue`j' = ((`k`h''-`kmax')^3)*(`k`h''>`kmax') - ///
						`lambda'*((`kmax'-`kmax')^3)*(`kmax'>`kmax') - ///
						(1-`lambda')*((`kmin'-`kmax')^3)*(`kmin'>`kmax') 
					local rcsvaluelist `rcsvaluelist' `rcsvalue`j''
				}
			}
						
			if "`nosecondder'" == "" & "`nofirstder'" != "" {
				local rcsvalue1 = (`kmax'-`kmax')*(`kmax'>`kmax')
				local rcsvaluelist `rcsvalue1'
							
				local c=(1/(3*(`kmax' - `kmin')))
				local rcsvalue2 = (`kmax'-`kmax')^2*(`kmax'>`kmax') - ///
					`c'*((`kmax'-`kmax')^3)*(`kmax'>`kmax') + ///
					`c'*((`kmin'-`kmax')^3)*(`kmin'>`kmax') 
				local rcsvaluelist `rcsvaluelist' `rcsvalue2'
							
				forvalues j=3/`par' {
					local h = `nk'-(`j'-2)
					local lambda = (`k`h''-`kmin')/(`kmax' - `kmin')
					local rcsvalue`j' = ((`k`h''-`kmax')^3)*(`k`h''>`kmax') - ///
						`lambda'*((`kmax'-`kmax')^3)*(`kmax'>`kmax') - ///
						(1-`lambda')*((`kmin'-`kmax')^3)*(`kmin'>`kmax')
					local rcsvaluelist `rcsvaluelist' `rcsvalue`j''
				}
			}
		}
/* Derive last spline variable */
		local rcsvaluelist `rcsvaluelist' `kmax'
		
		matrix input rcsvaluevector=(`rcsvaluelist' 1)
		matrix rcsvalueorthog=rcsvaluevector*`Rinv'
		
		if "`scalar'" == "" {
			forvalues j=1/`nparams' {
				qui replace `gen'`j' = `gen'`j' - rcsvalueorthog[1,`j']
			}
		}
		else {
			forvalues j=1/`nparams' {
				scalar `gen'`j' = `gen'`j' - rcsvalueorthog[1,`j']
			}
		}
	}
	
	***Orthogonalise the centred scalars**
	if ("`orthog'" != "" | "`rmatrix'"!= "") & "`center'"!="" {
		tempname centermatrix
		matrix `centermatrix' = `=`center1''
		forvalues i = 2/`nparams'{
			matrix `centermatrix' = `centermatrix',`=`center`i'''
		}
		matrix `centermatrix' = `centermatrix',1
		mata st_matrix("`centermatrix'",st_matrix("`centermatrix'")*st_matrix("`Rinv'")[,1..`nparams']) 
		forvalues i = 1/`nparams'{
			scalar `center`i'' = el(`centermatrix',1,`i')
		}	
	}
		
		
**Centre the spline variables if center specified***
	if "`center'"!= "" {
		if "`scalar'" == "" {
			forvalues j=1/`nparams' {
				qui replace `gen'`j' = `gen'`j' - `=`center`j'''
			}
		}
		else {
			forvalues j=1/`nparams' {
				scalar `gen'`j' = `gen'`j' - `=`center`j'''
			}
		}
	}
	
/* report new variables created */        
	if "`scalar'" != "" {
		local type Scalars
	}
	else {
		local type Variables
	}
	if "`dgen'"!="" {
		di in green "`type' `gen'1 to `gen'`nparams' and `dgen'1 to `dgen'`nparams' were created"
	}
	else {
		di in green "`type' `gen'1 to `gen'`nparams' were created"
	}
	if "`knots'" == "" {
		di in green "Warning: Only `gen'1 has been created as you did not specifiy any the knots, df or percentile options"
	}
	
	if "`orthog'" != "" {
		return matrix R = `R'
	}
	return local knots `knots'
	return local rcslist `rcslist'
	if "`dgen'" != ""  return local drcslist `drcslist'   	
end

/* Gram-Schmidt orthogonalization in Mata */        
mata:
void orthgs(string scalar varlist, |string scalar touse) 
{
	x = st_data(.,tokens(varlist),touse)
	meanx = mean(x)
	v = x :- meanx ,J(rows(x),1,1) 
	q = J(rows(v),0,.)
	R = J(cols(v),cols(v),0)
	R[cols(v),] = (meanx,1)
	for (i=1;i<=cols(x);i++){
		r = norm(v[,i])/sqrt(rows(v))
		q = q, (v[,i]:/ r)
		R[i,i] = r
		for (j = i + 1; j<=cols(x); j++){
			r = (q[,i]' * v[,j])/rows(v)
			v[,j] = v[,j] - r*q[,i]
			R[i,j] = r 
		}
	}
	st_store(.,tokens(varlist),touse,q)
	st_local("R",Rname=st_tempname())
	st_matrix(Rname,R)
}
end
	
