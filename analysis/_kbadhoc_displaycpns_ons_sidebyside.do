
*PASTE IN RESULTS SIDE BY SIDE FROM HR TABLE, DROP MIDDLE LABEL COLS
replace var3 = subinstr(var3, "(", " ", 1)
replace var3 = subinstr(var3, ")", " ", 1)
replace var3 = subinstr(var3, "-", " ", 1)
for var var4 var7 var8: replace X = subinstr(X, "(", " ", 1)
for var var4 var7 var8: replace X = subinstr(X, ")", " ", 1)
for var var4 var7 var8: replace X = subinstr(X, "-", " ", 1)

gen hrcpns = word(var3,1)
gen lcicpns = word(var3,2)
gen ucicpns = word(var3,3)
rename hrcpns hr_as_cpns
rename lcicpns lci_as_cpns
rename ucicpns uci_as_cpns

gen hr_fa_cpns = word(var4,1)
gen lci_fa_cpns = word(var4,2)
gen uci_fa_cpns = word(var4,3)

gen hr_as_ons = word(var7,1)
gen lci_as_ons = word(var7,2)
gen uci_as_ons = word(var7,3)

gen hr_fa_ons = word(var8,1)
gen lci_fa_ons = word(var8,2)
gen uci_fa_ons = word(var8,3)

drop var3 var4 var5 var6 var7 var8

gen myn = 62-_n

reshape long hr_as_ lci_as_ uci_as_ hr_fa_ lci_fa_ uci_fa_, i(myn) string

gsort -myn
gen myn2 = myn
replace myn2 = myn2+0.2 if _j=="ons"

foreach var of varlist hr* uci* lci*{
     rename `var' _`var'
	 gen `var' = real(_`var')
	 drop _`var'
}

gen label = 0.2
scatter myn2 hr_as if _j=="cpns"|| rcap lci_as uci_as myn2 if _j=="cpns", hor ///
|| scatter myn2 hr_as if _j=="ons"|| rcap lci_as uci_as myn2 if _j=="ons", hor  ///
|| if !(var1=="agegroup" & var2==1) & var2!=., xscale(log) ysize(12) || scatter myn2 label if var1!=var1[_n-1], m(i) mlab(var1) ///
legend(order(1 3) label(1 "cpns") label(3 "ons")) xline(1, lp(dash)) title("AGE SEX ADJUSTED")
graph export cpns_ons_sidebyside_agesex.svg, as(svg)

scatter myn2 hr_fa if _j=="cpns"|| rcap lci_fa uci_fa myn2 if _j=="cpns", hor ///
|| scatter myn2 hr_fa if _j=="ons"|| rcap lci_fa uci_fa myn2 if _j=="ons", hor  ///
|| if !(var1=="agegroup" & var2==1) & var2!=., xscale(log) ysize(12) || scatter myn2 label if var1!=var1[_n-1], m(i) mlab(var1) ///
legend(order(1 3) label(1 "cpns") label(3 "ons")) xline(1, lp(dash)) title("FULLY ADJUSTED")
graph export cpns_ons_sidebyside_fullyadj.svg, as(svg)
