program stpm2_ml_theta
	version 10.0
	args lnf xb eq2 eq3 eq4
	
	local del_entry = 0
	qui summ _t0 , meanonly
	if r(max)>0 local del_entry = 1
	
	if `del_entry' == 0 {
		if $ML_n == 2 {
			local dxb `eq2'
		} 
		else if $ML_n == 3 {
			local theta = exp(`eq2')
			local dxb `eq3'
		}
	}
	else if `del_entry' == 1{
		if $ML_n == 3 {
			local dxb `eq2'
			local xb0 `eq3'
		} 
		else if $ML_n == 4 {
			local theta = exp(`eq2')
			local dxb `eq3'
			local xb0 `eq4'
		}	
		local xb0 = (`eq3')
		local theta = exp(`eq4')
	}

	
	local st (`theta'*exp(`xb') + 1 )^(-1/`theta')
	local ht (`dxb'*exp(`xb'))/((`theta'*exp(`xb') + 1)) 

	qui replace `lnf' = _d*ln(`ht')+ln(`st')

	if `del_entry' == 1 {
		local st0 (`theta'*exp(`xb0') + 1 )^(-1/`theta')
		qui replace `lnf' = `lnf' - ln(`st0') if _t0>0
	}
end
