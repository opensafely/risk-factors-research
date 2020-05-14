program define rcsgen_example
	version 10.1
	args eg
	if `eg' == 1 {
		preserve
		sysuse auto, clear
		rcsgen weight, gen(rcs) df(3)
		regress mpg rcs1-rcs3
		predictnl pred = xb(), ci(lci uci)
		twoway (rarea lci uci weight, sort) (scatter mpg weight, sort) (line pred weight, sort lcolor(black)), legend(off)
		restore
	}
	if `eg' == 2 {
		preserve
		webuse brcancer, clear
		stset rectime, f(censrec==1)
		rename x1 age
		rcsgen age, gen(agercs) df(3) center(60)
		stcox agercs1-agercs3 hormon
		partpred hr, for(agercs*) ci(hr_lci hr_uci) eform
		twoway (rarea hr_lci hr_uci age, sort) (line hr age, sort lcolor(black)), legend(off) yscale(log) yline(1)
		restore
	}
end
