


import delimited input.csv, clear
set more off


set seed 21478


* Creatinine
gen creatinine = runiform()*35

* Diagnosis of hypertension, string
gen hypertension_temp = 1960 + rnormal(0, 1000) 
replace hypertension_temp = . if uniform()<0.8
gen hypertension = string(year(hyper))		 	///
				+ "-" + string(month(hyper)) 
replace hypertension = " " if hypertension==".-." 
drop hypertension_temp


* Hba1c 
gen hba1c_percentage   = rnormal(2, 10)
gen hba1c_mmol_per_mol = rnormal(15, 90)

replace hba1c_percentage = . if uniform()<0.95
replace hba1c_mmol_per_mol = . if uniform()<0.2

gen hba1c_percentage_date_temp = 1960 + rnormal(0, 1000) 
gen hba1c_percentage_date = string(year(hba1c_percentage_date_temp)) 			///
					+ "-" + string(month(hba1c_percentage_date_temp)) 
replace hba1c_percentage_date = " " if hba1c_percentage_date==".-." 
drop hba1c_percentage_date_temp

gen hba1c_mmol_per_mol_date_temp = 1960 + rnormal(0, 1000) 
gen hba1c_mmol_per_mol_date = string(year(hba1c_mmol_per_mol_date_temp)) 			///
					+ "-" + string(month(hba1c_mmol_per_mol_date_temp))
replace hba1c_mmol_per_mol_date = " " if hba1c_mmol_per_mol_date==".-." 
drop hba1c_mmol_per_mol_date_temp

replace hba1c_percentage_date = ""   if hba1c_percentage==.
replace hba1c_mmol_per_mol_date = "" if hba1c_mmol_per_mol==.


* STP
rename geographic_area stp


* Region
gen region = "North East" if uniform()<0.1 
replace region = "North West" if uniform()<0.2 & region==""
replace region = "Yorkshire and The Humber" if uniform()<0.3 & region==""
replace region = "East Midlands" if uniform()<0.4 & region==""
replace region = "West Midlands" if uniform()<0.5 & region==""
replace region = "East" if uniform()<0.6 & region==""
replace region = "London" if uniform()<0.7 & region==""
replace region = "South East" if uniform()<0.8 & region==""
replace region = "South West" if region==""

