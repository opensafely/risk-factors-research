
use egdata, clear

replace ituadmission = (uniform()<0.05)

replace cpnsdeath = (uniform()<0.05)

replace onscoviddeath = (uniform()<0.05)

replace bmicat = 1+(floor(6*uniform())) if bmicat==.u

*FIZZ TO ADD STHG ON GEOG AREA HERE TOO

save egdata, replace
