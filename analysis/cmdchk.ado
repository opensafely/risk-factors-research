*! version 1.0.4 PR 30sep2005
* Based on private version 6.1.4 of frac_chk, PR 25aug2004
program define cmdchk, sclass
	version 7
	local cmd `1'
	mac shift
	local cmds `*'
	sret clear
	if substr("`cmd'",1,3)=="reg" {
		local cmd regress
	}
	if "`cmds'"=="" {
		tokenize clogit cnreg cox ereg fit glm logistic logit poisson probit /*
		*/ qreg regress rreg weibull xtgee streg stcox stpm stpmrs /*
		*/ ologit oprobit mlogit nbreg
	}
	else tokenize `cmds'
	sret local bad 0
	local done 0
	while "`1'"!="" & !`done' {
		if "`1'"=="`cmd'" {
			local done 1
		}
		mac shift
	}
	if !`done' {
		sret local bad 1
		*exit
	}
	/*
		dist=0 (normal), 1 (binomial), 2 (poisson), 3 (cox), 4 (glm),
		5 (xtgee), 6 (ereg/weibull), 7 (stcox, streg, stpm, stpmrs).
	*/
	if "`cmd'"=="logit" | "`cmd'"=="probit" /*
 	*/ |"`cmd'"=="clogit"| "`cmd'"=="logistic" /*
 	*/ |"`cmd'"=="mlogit"| "`cmd'"=="ologit" | "`cmd'"=="oprobit" {
						sret local dist 1
	}
	else if "`cmd'"=="poisson" {
						sret local dist 2
	}
	else if "`cmd'"=="cox" {
						sret local dist 3
	}
	else if "`cmd'"=="glm" {
						sret local dist 4
	}
	else if "`cmd'"=="xtgee" {
						sret local dist 5
	}
	else if "`cmd'"=="cnreg" | "`cmd'"=="ereg" | "`cmd'"=="weibull" | "`cmd'"=="nbreg" {
						sret local dist 6
	}
	else if "`cmd'"=="stcox" | "`cmd'"=="streg" | "`cmd'"=="stpm" | "`cmd'"=="stpmrs" {
						sret local dist 7
	}
	else if substr("`cmd'",1,2)=="st" {
						sret local dist 7
	}
	else					sret local dist 0

	sret local isglm  = (`s(dist)'==4)
	sret local isqreg = ("`cmd'"=="qreg")
	sret local isxtgee= (`s(dist)'==5)
	sret local isnorm = ("`cmd'"=="regress"|"`cmd'"=="fit"|"`cmd'"=="rreg") 
end
