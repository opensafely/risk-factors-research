
cap log close

log using ./output/kbpwcorrs, replace t

use "cr_create_analysis_dataset.dta", clear
cou 
local overalln=r(N)
/*agegroup ethnicity male obese4cat smoke_nomiss imd htdiag_or_highbp	chronic_respiratory_disease asthmacat 	chronic_cardiac_disease diabcat cancer_exhaem_cat cancer_haem_cat chronic_liver_disease stroke_dementia other_neuro reduced_kidney_function_cat organ_transplant spleen ra_sle_psoriasis other_immunosuppression */

gen age70plus = agegroup
recode age70plus 1/4=0 5/6=1

gen nonwhite = ethnicity
recode nonwhite 1=0 2/5=1

gen obese = obese4cat
recode obese4cat 1=0 2/4=1

gen currsmok = smoke_nomiss
recode currsmok 1/2=0 3=1

gen deprived = imd
recode deprived 1/3=0 4/5=1

gen evercancer_exhaem = cancer_exhaem_cat
recode evercancer_exhaem 1=0 2/4=1

gen evercancer_haem = cancer_haem_cat
recode evercancer_haem 1=0 2/4=1

gen anyckd = reduced_kidney_function_cat
recode anyckd 1=0 2/3=1

*Pairwise comorbidity prevalences 
cap postutil clear
postfile comorbn str30 var1 str30 var2 nboth using ./output/kbpwcorr_prevalences, replace
local var1num = 1
foreach var1 of varlist obese htdiag_or_highbp	chronic_respiratory_disease asthma 	chronic_cardiac_disease diabetes evercancer_exhaem evercancer_haem chronic_liver_disease stroke_dementia other_neuro anyckd organ_transplant spleen ra_sle_psoriasis other_immunosuppression {
	local var2num = 1
	foreach var2 of varlist obese htdiag_or_highbp	chronic_respiratory_disease asthma 	chronic_cardiac_disease diabetes evercancer_exhaem evercancer_haem chronic_liver_disease stroke_dementia other_neuro anyckd organ_transplant spleen 	ra_sle_psoriasis other_immunosuppression  {
	if `var2num'>`var1num' {
		di "`var1' `var2'"
		cou if `var1'==1 & `var2'==1	
		post comorbn ("`var1'") ("`var2'") (r(N))
	}
	local var2num = `var2num' + 1
	}
	local var1num = `var1num' + 1
}
postclose comorbn



*Pairwise correlations
pwcorr age70plus nonwhite male obese currsmok deprived htdiag_or_highbp	chronic_respiratory_disease asthma 	chronic_cardiac_disease diabetes evercancer_exhaem evercancer_haem chronic_liver_disease stroke_dementia other_neuro anyckd organ_transplant spleen ra_sle_psoriasis other_immunosuppression 

matrix ALL = r(C)
svmat ALL, names(matcol)

pwcorr nonwhite male obese currsmok deprived htdiag_or_highbp	chronic_respiratory_disease asthma 	chronic_cardiac_disease diabetes evercancer_exhaem evercancer_haem chronic_liver_disease stroke_dementia other_neuro anyckd organ_transplant spleen ra_sle_psoriasis other_immunosuppression if age70plus==0

matrix U70 = r(C)
svmat U70, names(matcol)

pwcorr nonwhite male obese currsmok deprived htdiag_or_highbp	chronic_respiratory_disease asthma 	chronic_cardiac_disease diabetes evercancer_exhaem evercancer_haem chronic_liver_disease stroke_dementia other_neuro anyckd organ_transplant spleen ra_sle_psoriasis other_immunosuppression if age70plus==1

*Output correlations to dataset and keep only correlations
matrix O70 = r(C)
svmat O70, names(matcol)

keep ALL* U70* O70*
drop if ALLage70plus>=.

gen varname = ""
local i=1
foreach var of varlist ALLage70plus-ALLother_immunosuppression{
	replace varname = "`var'" in `i'
	local i=`i' + 1
}
replace varname = substr(varname,4,.)
order varname

outsheet using ./output/kbpwcorr.csv, c replace

**Graph results
for var ALL*: replace X = . if X==1

gen x=0
gen y=0
count
local nobs = r(N)
forvalues i = 1/`nobs'{
	*Headings
	graph twoway scatter y x  if _n==`i', m(i) mlab(varname) mlabpos(0) mlabsize(vhuge) xtitle("") ytitle("") xlab(none) ylab(none) name(heading`i', replace)
	*Correlations
	local j = 1
	foreach var of varlist ALLage70plus-ALLother_immunosuppression{
		graph bar (mean) `var' if _n==`i', yscale(r(-1 1)) ylab(-1 0 1) yline(0, lp(dash)) name(row`i'col`j', replace) ytitle("")
	local j = `j'+ 1		
	}
	}
*Blank	
graph twoway scatter y x  if _n==1, m(i) xtitle("") ytitle("") xlab(none) ylab(none) name(blank, replace)

*Combine
count
local nobs=r(N)
local combine "blank "
forvalues i = 1/`nobs'{
	local combine "`combine' heading`i'"
}
forvalues row=1/`nobs'{
	local combine "`combine' heading`row'"
	forvalues col=1/`nobs'{
		if `col'>=`row' local combine "`combine' blank"
		else local combine "`combine' row`row'col`col'"
	}
}
local ncols = `nobs'+1	
graph combine `combine', cols(`ncols')

graph export ./output/kbpwcorr.svg, as(svg)

**Display highest correlations
*Replace duplicates with missing (reversed pairs)
local i=1
foreach var of varlist ALLage70plus-ALLother_immunosuppression{
	replace `var'=. if _n<=`i'
	local i=`i'+1
}
foreach stem of any O70 U70{
local i=1
foreach var of varlist `stem'nonwhite-`stem'other_immunosuppression{
	replace `var'=. if _n<=`i'
	local i=`i'+1
}
}
*Reshape to help rank
reshape long ALL U70 O70, i(varname) j(var2) string
drop if ALL==. & U70==. & O70==.
*Ranking comorbidities not demographics
gen comorb = !(varname=="age70plus"|varname=="male"|varname=="currsmok"|varname=="deprived"|varname=="nonwhite"|var2=="age70plus"|var2=="male"|var2=="currsmok"|var2=="deprived"|var2=="nonwhite")
gsort -comorb -ALL 
*Display
noi di _n "Biggest correlations between comorbidities" _n "********************"_n
l varname var2 ALL in 1/20

*Display prevalence ranking
use ./output/kbpwcorr_prevalences, clear
gsort -nboth
*gen pct = 100*nboth/`overalln'
gen pct = 100*nboth/17278392
noi di _n "Most prevalent 2-way multimorbidities" _n "********************"_n
l in 1/30 
log close


	