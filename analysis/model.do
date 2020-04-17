import delimited `c(pwd)'/analysis/input.csv

set more off
cd  `c(pwd)'/analysis



/*  Pre-analysis data manipulation  */

do "cr_create_analysis_dataset.do"



/*  Run analyses  */

do " an_checks.do"
do "an_descriptive_tables.do"
do "an_descriptive_plots.do"
do "an_univariable_cox_models.do"
*do "an_multivariable_cox_models.do"


