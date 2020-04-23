
use egdata, clear

replace ituadmission = (uniform()<0.20)

replace cpnsdeath = (uniform()<0.20)

replace onscoviddeath = (uniform()<0.20)

replace bmicat = 1+(floor(6*uniform())) if bmicat==.u

replace cancer_exhaem_lastyr = (uniform()<.2)
replace haemmalig_aanaem_bmtrans_lastyr = (uniform()<.2)

replace organ_transplant = uniform()<.05

replace smoke = 1 if smoke == .u & uniform()<.5
drop currentsmoke
recode smoke 3=1 1/2 .u=0, gen(currentsmoke)
order currentsmoke, after(smoke)

*FIZZ TO ADD STHG ON GEOG AREA HERE TOO

save egdata, replace
