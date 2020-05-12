
*an_tablecontent_HRtable
*************************************************************************
*Purpose: Create content that is ready to paste into a pre-formatted Word 
* shell table containing minimally and fully-adjusted HRs for risk factors
* of interest, across 4 outcomes (hosp, death, itu, death/itu composite)
*
*Requires: final analysis dataset (cr_analysis_dataset.dta)
*
*Coding: Krishnan Bhaskaran
*
*Date drafted: 18/4/2020
*************************************************************************



***********************************************************************************************************************
*Generic code to ouput the HRs across outcomes for all levels of a particular variables, in the right shape for table
cap prog drop outputHRsforvar
prog define outputHRsforvar
syntax, variable(string) min(real) max(real) 
forvalues i=`min'/`max'{
local endwith "_tab"

	*put the varname and condition to left so that alignment can be checked vs shell
	file write tablecontents ("`variable'") _tab ("`i'") _tab
	
	foreach outcome of any /*ituadmission*/ cpnsdeath /*onscoviddeath*/ {
	
	foreach modeltype of any minadj fulladj {
	
		local noestimatesflag 0 /*reset*/

*CHANGE THE OUTCOME BELOW TO LAST IF BRINGING IN MORE COLS
		if "`outcome'"=="cpnsdeath" & "`modeltype'"=="fulladj" local endwith "_n"

		***********************
		*1) GET THE RIGHT ESTIMATES INTO MEMORY
		
		if "`modeltype'"=="minadj" & "`variable'"!="agegroup" & "`variable'"!="male" {
			cap estimates use ./output/models/an_univariable_cox_models_`outcome'_AGESEX_`variable'
			if _rc!=0 local noestimatesflag 1
			}

		*FOR AGEGROUP - need to use the separate univariate/multivariate model fitted with age group rather than spline
		*FOR ETHNICITY - use the separate complete case multivariate model
		*FOR REST - use the "main" multivariate model
		if "`variable'"=="agegroup" {
			if "`modeltype'"=="minadj" {
				cap estimates use ./output/models/an_univariable_cox_models_`outcome'_AGESEX_agegroupsex
				if _rc!=0 local noestimatesflag 1
				}
			if "`modeltype'"=="fulladj" {
				cap estimates use ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agegroup_bmicat_noeth
				if _rc!=0 local noestimatesflag 1
				}
			}
		else if "`variable'"=="male" {
			if "`modeltype'"=="minadj" {
				cap estimates use ./output/models/an_univariable_cox_models_`outcome'_AGESEX_agesplsex
				if _rc!=0 local noestimatesflag 1			
				}
			if "`modeltype'"=="fulladj" {
				cap estimates use ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_noeth  
				if _rc!=0 local noestimatesflag 1
				}
			}
		else if "`variable'"=="ethnicity" {
			if "`modeltype'"=="fulladj" {
				cap estimates use ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_CCeth  
				if _rc!=0 local noestimatesflag 1
				}
			}			
		else {
			if "`modeltype'"=="fulladj" {
				cap estimates use ./output/models/an_multivariate_cox_models_`outcome'_MAINFULLYADJMODEL_agespline_bmicat_noeth  
				if _rc!=0 local noestimatesflag 1
				}
		}
		
		***********************
		*2) WRITE THE HRs TO THE OUTPUT FILE
		
		if `noestimatesflag'==0{
			cap lincom `i'.`variable', eform
			if _rc==0 file write tablecontents %4.2f (r(estimate)) (" (") %4.2f (r(lb)) ("-") %4.2f (r(ub)) (")") `endwith'
				else file write tablecontents %4.2f ("ERR IN MODEL") `endwith'
			}
			else file write tablecontents %4.2f ("DID NOT FIT") `endwith' 
			
		*3) Save the estimates for plotting
		if `noestimatesflag'==0{
			if "`modeltype'"=="fulladj" {
				local hr = r(estimate)
				local lb = r(lb)
				local ub = r(ub)
				cap gen `variable'=.
				testparm i.`variable'
				post HRestimates ("`outcome'") ("`variable'") (`i') (`hr') (`lb') (`ub') (r(p))
				drop `variable'
				}
		}	
		} /*min adj, full adj*/
		
	} /*outcomes*/
} /*variable levels*/

end
***********************************************************************************************************************
*Generic code to write a full row of "ref category" to the output file
cap prog drop refline
prog define refline
file write tablecontents _tab _tab ("1.00 (ref)") _tab ("1.00 (ref)")  _n
*post HRestimates ("`outcome'") ("`variable'") (`refcat') (1) (1) (1) (.)
end
***********************************************************************************************************************

*MAIN CODE TO PRODUCE TABLE CONTENTS

cap file close tablecontents
file open tablecontents using ./output/an_tablecontents_HRtable.txt, t w replace 

tempfile HRestimates
cap postutil clear
postfile HRestimates str10 outcome str27 variable level hr lci uci pval using `HRestimates'

*Age group
outputHRsforvar, variable("agegroup") min(1) max(2)
refline
outputHRsforvar, variable("agegroup") min(4) max(6)
file write tablecontents _n 

*Sex 
refline
outputHRsforvar, variable("male") min(1) max(1)
file write tablecontents _n

*BMI
refline
outputHRsforvar, variable("obese4cat") min(2) max(4)
file write tablecontents _n

*Smoking
refline
outputHRsforvar, variable("smoke_nomiss") min(2) max(3)
file write tablecontents _n

*Ethnicity
refline
outputHRsforvar, variable("ethnicity") min(2) max(5)
file write tablecontents _n

*IMD
refline
outputHRsforvar, variable("imd") min(2) max(5)
file write tablecontents _n 

*BP/hypertension
refline
outputHRsforvar, variable("htdiag_or_highbp") min(1) max(1)
file write tablecontents _n
outputHRsforvar, variable("chronic_respiratory_disease") min(1) max(1)
file write tablecontents _n			
outputHRsforvar, variable("asthmacat") min(2) max(3)			
outputHRsforvar, variable("chronic_cardiac_disease") min(1) max(1)
file write tablecontents _n	
outputHRsforvar, variable("diabcat") min(2) max(4)
file write tablecontents _n		
outputHRsforvar, variable("cancer_exhaem_cat") min(2) max(4)
file write tablecontents _n		
outputHRsforvar, variable("cancer_haem_cat") min(2) max(4)			
file write tablecontents _n
outputHRsforvar, variable("reduced_kidney_function_cat") min(2) max(3)			
outputHRsforvar, variable("chronic_liver_disease") min(1) max(1)			
outputHRsforvar, variable("stroke_dementia") min(1) max(1)			
outputHRsforvar, variable("other_neuro") min(1) max(1)			
outputHRsforvar, variable("organ_transplant") min(1) max(1)			
outputHRsforvar, variable("spleen") min(1) max(1)
outputHRsforvar, variable("ra_sle_psoriasis") min(1) max(1)
outputHRsforvar, variable("other_immunosuppression") min(1) max(1)			


file close tablecontents

postclose HRestimates

use `HRestimates', clear

gen varorder = 1 
local i=2
foreach var of any male obese4cat smoke_nomiss ethnicity imd  diabcat ///
	cancer_exhaem_cat cancer_haem_cat reduced_kidney_function_cat asthmacat chronic_respiratory_disease ///
	chronic_cardiac_disease htdiag_or_highbp chronic_liver_disease ///
	stroke_dementia other_neuro organ_transplant ///
	spleen ra_sle_psoriasis other_immunosuppression {
replace varorder = `i' if variable=="`var'"
local i=`i'+1
}
sort varorder level
drop varorder

gen obsorder=_n
expand 2 if variable!=variable[_n-1], gen(expanded)
for var hr lci uci: replace X = 1 if expanded==1

sort obsorder
drop obsorder
replace level = 0 if expanded == 1
replace level = 1 if expanded == 1 & (variable=="obese4cat"|variable=="smoke_nomiss"|variable=="ethnicity"|variable=="imd"|variable=="asthmacat"|variable=="diabcat"|substr(variable,1,6)=="cancer"|variable=="reduced_kidney_function_cat")
replace level = 3 if expanded == 1 & variable=="agegroup"

gen varorder = 1 if variable!=variable[_n-1]
replace varorder = sum(varorder)
sort varorder level


drop expanded
expand 2 if variable!=variable[_n-1], gen(expanded)
replace level = -1 if expanded==1
drop expanded
*expand 3 if variable=="htdiag_or_highbp" & level==-1, gen(expanded)
*replace level = -99 if variable=="htdiag_or_highbp" & expanded==1
expand 2 if level == -1, gen(expanded)
replace level = -99 if expanded==1

for var hr lci uci pval : replace X=. if level<0
sort varorder level

gen varx = 0.07
gen levelx = 0.071
gen lowerlimit = 0.15

*Names
gen Name = variable if (level==-1&!(level[_n+1]==0&variable!="male"))|(level==1&level[_n-1]==0&variable!="male")
replace Name = subinstr(Name, "_", " ", 10)
replace Name = upper(substr(Name,1,1)) + substr(Name,2,.)
replace Name = "Age group" if Name=="Agegroup"
replace Name = "Sex" if Name=="Male"
replace Name = "Obesity" if Name=="Obese4cat"
replace Name = "Smoking status" if Name=="Smoke nomiss"
replace Name = "Deprivation (IMD) quintile" if Name=="Imd"
replace Name = "Hypertension/high bp" if Name=="Htdiag or highbp"
replace Name = "Asthma" if Name=="Asthmacat"
replace Name = "Diabetes" if Name=="Diabcat"
replace Name = "Cancer (non-haematological)" if Name=="Cancer exhaem cat"
replace Name = "Haematological malignancy" if Name=="Cancer haem cat"
replace Name = "Stroke or dementia" if Name=="Stroke dementia"
replace Name = "Other neurological" if Name=="Other neuro"
replace Name = "Rheumatoid arthritis/Lupus/Psoriasis" if Name=="Ra sle psoriasis"
replace Name = "Reduced kidney function" if Name=="Reduced kidney function cat"
replace Name = "Conditions with splenic dysfunction" if Name=="Spleen"

*Levels
gen leveldesc = ""
replace leveldesc = "18-39" if variable=="agegroup" & level==1
replace leveldesc = "40-49" if variable=="agegroup" & level==2
replace leveldesc = "50-59 (ref)" if variable=="agegroup" & level==3
replace leveldesc = "60-69" if variable=="agegroup" & level==4
replace leveldesc = "70-79" if variable=="agegroup" & level==5
replace leveldesc = "80+" if variable=="agegroup" & level==6

replace leveldesc = "Female (ref)" if variable=="male" & level==0
replace leveldesc = "Male" if variable=="male" & level==1

replace leveldesc = "Not obese (ref)" if variable=="obese4cat" & level==1
replace leveldesc = "Obese class I" if variable=="obese4cat" & level==2
replace leveldesc = "Obese class II" if variable=="obese4cat" & level==3
replace leveldesc = "Obese class III" if variable=="obese4cat" & level==4

replace leveldesc = "Never (ref)" if variable=="smoke_nomiss" & level==1
replace leveldesc = "Ex-smoker" if variable=="smoke_nomiss" & level==2
replace leveldesc = "Current" if variable=="smoke_nomiss" & level==3

replace leveldesc = "White (ref)" if variable=="ethnicity" & level==1
replace leveldesc = "Mixed" if variable=="ethnicity" & level==2
replace leveldesc = "Asian/Asian British" if variable=="ethnicity" & level==3
replace leveldesc = "Black" if variable=="ethnicity" & level==4
replace leveldesc = "Other" if variable=="ethnicity" & level==5

replace leveldesc = "1 (least deprived, ref)" if variable=="imd" & level==1
replace leveldesc = "2" if variable=="imd" & level==2
replace leveldesc = "3" if variable=="imd" & level==3
replace leveldesc = "4" if variable=="imd" & level==4
replace leveldesc = "5 (most deprived)" if variable=="imd" & level==5

replace leveldesc = "No diabetes (ref)" if variable=="diabcat" & level==1
replace leveldesc = "Controlled (HbA1c <58mmol/mol)" if variable=="diabcat" & level==2
replace leveldesc = "Uncontrolled (HbA1c >=58mmol/mol) " if variable=="diabcat" & level==3
replace leveldesc = "Unknown HbA1c" if variable=="diabcat" & level==4

replace leveldesc = "No asthma (ref)" if variable=="asthmacat" & level==1
replace leveldesc = "With no recent OCS use" if variable=="asthmacat" & level==2
replace leveldesc = "With recent OCS use" if variable=="asthmacat" & level==3

replace leveldesc = "Never (ref)" if substr(variable,1,6)=="cancer" & level==1
replace leveldesc = "<1 year ago" if substr(variable,1,6)=="cancer" & level==2
replace leveldesc = "1-4.9 years ago" if substr(variable,1,6)=="cancer" & level==3
replace leveldesc = "5+ years ago" if substr(variable,1,6)=="cancer" & level==4

replace leveldesc = "None (ref)" if variable=="reduced_kidney_function_cat" & level==1
replace leveldesc = "eGFR 30-60 ml/min/1.73m2" if variable=="reduced_kidney_function_cat" & level==2
replace leveldesc = "eGFR <30 ml/min/1.73m2" if variable=="reduced_kidney_function_cat" & level==3


*replace leveldesc = "Absent" if level==0
*replace leveldesc = "Present" if level==1 & leveldesc==""
drop if level==0 & variable!="male"


gen obsorder=_n
gsort -obsorder
gen graphorder = _n
sort obsorder

*merge 1:1 variable level using c:\statatemp\tptemp, update replace

gen displayhrci = "<<< HR = " + string(hr, "%3.2f") + " (" + string(lci, "%3.2f") + "-" + string(uci, "%3.2f") + ")" if lci<0.15

scatter graphorder hr if lci>=.15, mcol(black)	msize(small)		///										///
	|| rcap lci uci graphorder if lci>=.15, hor mcol(black)	lcol(black)			///
	|| scatter graphorder lowerlimit, m(i) mlab(displayhrci) mlabcol(black) mlabsize(tiny) ///
	|| scatter graphorder varx , m(i) mlab(Name) mlabsize(tiny) mlabcol(black) 	///
	|| scatter graphorder levelx, m(i) mlab(leveldesc) mlabsize(tiny) mlabcol(gs8) 	///
		xline(1,lp(dash)) 															///
		xscale(log) xlab(0.25 0.5 1 2 5 10) xtitle("Hazard Ratio & 95% CI") ylab(none) ytitle("")						/// 
		legend(off)  ysize(8) 

graph export ./output/an_tablecontent_HRtable_HRforest.svg, as(svg) replace
