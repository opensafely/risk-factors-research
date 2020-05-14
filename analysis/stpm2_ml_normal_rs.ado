program stpm2_ml_normal_rs
	version 10.0
	args lnf xb dxb xb0
	tempvar ht st st0 

	local del_entry = 0
	qui summ _t0 , meanonly
	if r(max)>0 local del_entry = 1

	local st normal(-`xb')
	local ht $ML_y + 1/_t *`dxb'*normalden(`xb')/normal(-`xb')


	qui replace `lnf' = _d*ln(`ht')+ln(`st')

	if `del_entry' == 1 {
		local st0 normal(-`xb0')
		qui replace `lnf' = `lnf' - ln(`st0') if _t0>0
	}
end

