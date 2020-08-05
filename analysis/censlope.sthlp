{smcl}
{hline}
help for {hi:censlope}{right:(SJ6-4: snp15_7; SJ6-3: snp15_6; SJ5-3: snp15_5; SJ3-3: snp15_4;}
{right:STB-61: snp15_3; STB-58: snp15_2; STB-57: snp15)}
{hline}

{title:Robust confidence intervals for median and other percentile slopes}

{p 8 21 2}
{cmd:censlope} {it:yvarname} {it:xvarname} {weight} {ifin}{cmd:,}
[{cmdab:ce:ntile}{cmd:(}{it:numlist}{cmd:)} {cmdab:ef:orm}
{cmdab:ys:targenerate}{cmd:(}{help newvarlist:{it:newvarlist}}{cmd:)} {cmdab:esta:ddr}
{help somersd:{it:somersd_options}} {help censlope_iteration:{it:iteration_options}}]

{pstd}
where {it:yvarname} and {it:xvarname} are variable names.

{pstd}
{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see
{help weight}.  They are interpreted as for {helpb somersd}.

{pstd}
{opt bootstrap}, {opt by}, {opt jackknife}, and {opt statsby}
are allowed; see {help prefix}.{p_end}


{title:Description}

{pstd}
{cmd:censlope} calculates confidence intervals for generalized Theil-Sen
median slopes and other percentile slopes of a Y variable specified by
{it:yvarname} with respect to an X variable specified by {it:xvarname}.
These confidence intervals are robust to the possibility that the population
distributions of the Y variable, conditional on different values of the
X variable, are different in ways other than location.  This might happen
if, for example, the conditional distributions had different variances.  For
positive-valued Y variables, {cmd:censlope} can be used to calculate
confidence intervals for median per-unit ratios or other percentile per-unit
ratios associated with a unit increment in the X variable.  If the
X variable is binary with values 0 and 1, then the generalized Theil-Sen
percentile slopes are the generalized Hodges-Lehmann percentile differences
between the group of observations whose X value is 1 and the group of
observations whose X value is 0.  {cmd:censlope} is part of the
{helpb somersd} package and requires the {helpb somersd} program to
work.  It executes the {helpb somersd} command,

{p 8 21 2}
{cmd:somersd} {it:xvarname} {it:yvarname} {weight} {ifin} [{cmd:,}
{help somersd:{it:somersd_options}}]

{pstd}
and then estimates the percentile slopes.  The estimates and confidence limits
for the percentile slopes are evaluated using an
{help censlope_iteration:iterative numerical method}, which the user may
change from the default by using the
{help censlope_iteration:{it:iteration_options}}.


{title:Options}

{p 4 8 2}
{cmd:centile(}{it:numlist}{cmd:)} specifies a list of percentile slopes to be
reported and defaults to {cmd:centile(50)} (median only) if not specified.
Specifying {cmd:centile(25 50 75)} will produce the 25th, 50th, and 75th
percentile differences.

{p 4 8 2}
{cmd:eform} specifies that exponentiated percentile slopes be given.
This option is used if {it:yvarname} specifies the log of a positive-valued
variable.  In this case, confidence intervals are calculated for percentile
ratios or per-unit ratios between values of the original positive variable,
instead of for percentile differences or per-unit differences.

{p 4 8 2}
{cmd:ystargenerate(}{help newvarlist:{it:newvarlist}}{cmd:)} specifies a list
of variables to be generated, corresponding to the percentile slopes,
containing the differences {hi:Y*(beta)=Y-X*beta}, where {hi:beta} is the
percentile slope.  The variable names in the {help newvarlist:{it:newvarlist}}
are matched to the list of percentiles specified by the {cmd:centile()}
option, sorted in ascending order of percent.  If the two lists have different
lengths, then {cmd:censlope} generates a number {it:nmin} of new variables
equal to the minimum length of the two lists, matching the first {it:nmin}
percentiles with the first {it:nmin} new variable names.  Usually, there is
only one percentile slope (the median slope), and one new
{cmd:ystargenerate()} variable, whose median can be used as the intercept when
drawing a straight line through the data points on a scatterplot.

{p 4 8 2}
{cmd:estaddr} specifies that the results saved in {cmd:r()} also be saved
in {cmd:e()} (see {hi:Saved results} below).  This option makes it easier to
use {cmd:censlope} with {helpb parmby}, to create an output dataset
(or results set) with one observation per by-group and data on confidence
intervals for Somers' {it:D} and median slopes.  {helpb parmby} is part of the
package {helpb parmest}, downloadable from {help ssc:SSC}.

{phang}
{it:somersd_options} are any of the options available with
{helpb somersd}.

{phang}
{it:iteration_options} are any of the options described in 
  {help censlope_iteration}.


{title:Remarks}

{pstd}
{cmd:censlope} is part of the {helpb somersd} package and uses the program
{helpb somersd}, which calculates confidence intervals for Somers' {it:D} and
Kendall's tau-a.  Given two random variables Y and X, a 100{hi:q}th
percentile slope of Y with respect to X is defined as a value of
{hi:beta} satisfying the equation

{phang}
{hi:theta( Y-beta*X , X ) = 1 - 2q}

{pstd}
where {hi:theta(U,V)} represents either {hi:D(U|V)} (Somers' {it:D}) or
{hi:tau_a(U,V)} (Kendall's tau-a) between the variables U and V.
(For definitions of Somers' {it:D} and Kendall's tau-a, see {helpb somersd}.) If
{hi:q}=0.5, then the value of {hi:beta} is a Theil-Sen median slope.  If in
addition X is a binary variable, with possible values 0 and 1, then the
value of {hi:beta} is a Hodges-Lehmann median difference between Y values
in the subpopulation in which X==1 and Y values in the
subpopulation in which X==0.  An alternative program for calculating
Hodges-Lehmann median (and other percentile) differences is {helpb cendif},
which is also distributed as part of the {helpb somersd} package.

{pstd}
For extreme percentiles and/or very small sample numbers,
{cmd:censlope} sometimes calculates infinite positive upper confidence limits
or infinite negative lower confidence limits.  These are represented by
{hi:+/-}{cmd:c(maxdouble)}, where {cmd:c(maxdouble)} is the
{help creturn:c-class value} specifying the largest positive number that can
be stored in a {help data_types:double}.

{pstd}
{cmd:censlope} can use all the options used by {helpb somersd},
to use any of the extended versions of Somers' {it:D} or Kendall's tau-a
in the definition of percentile slopes, differences, and ratios.  In
particular, we may use the {cmd:wstrata()} option of {helpb somersd} to
estimate within-stratum median differences and slopes, based on comparisons
between observations between the same stratum.  This method allows us to
estimate median differences in an outcome variable, associated with an
exposure, within strata defined by grouping a confounder, or by grouping a
propensity score for the exposure based on multiple confounders.  Therefore,
rank parameters (such as median differences) can be adjusted for confounders,
just as regression parameters can be adjusted for confounders.  However,
regression methods are required to define propensity scores.

{pstd}
The program {helpb cendif} is also part of the {helpb somersd} package and
calculates confidence intervals for a restricted subset of the parameters
estimated by {cmd:censlope}, assuming a binary X variable and a
restricted range of {help somersd:{it:somersd_options}}.  {helpb cendif} does
not use an iterative method but instead calculates all possible differences
between Y values in the two groups defined by the binary X variable.
In large samples, this method is more time-consuming than the iterative method
used by {cmd:censlope}.  However, in small samples (such as the
{helpb dta_examples:auto} data), {helpb cendif} can be much faster than
{cmd:censlope}.

{pstd}
Full documentation of the {helpb somersd} package (including Methods and
Formulas) is provided in the files {hi:somersd.pdf}, {hi:censlope.pdf}, and
{hi:cendif.pdf}, which are distributed with the {helpb somersd} package as
ancillary files (see {helpb net}).  They can be viewed using the Adobe
Acrobat Reader, which can be downloaded from

    {browse "http://www.adobe.com/products/acrobat/readermain.html":http://www.adobe.com/products/acrobat/readermain.html}

{pstd}
For a comprehensive review of Kendall's tau-a, Somers' {it:D}, and median
differences, see Newson (2002).
The definitive reference for the statistical and computational methods of {cmd:censlope}
is Newson (2006).


{title:Examples}

{p 8 12 2}{cmd:. censlope weight length}{p_end}

{p 8 12 2}{cmd:. censlope weight length, transf(z)}{p_end}

{p 8 12 2}{cmd:. censlope weight length, transf(z) centile(25(25)75)}{p_end}

{p 8 12 2}{cmd:. censlope weight foreign}{p_end}

{p 8 12 2}{cmd:. censlope weight foreign, transf(z)}{p_end}

{p 8 12 2}{cmd:. censlope weight foreign, transf(z) centile(0(25)100)}{p_end}

{pstd}
The following example estimates percentile weight ratios between non-U.S. and
U.S. cars:

{p 8 12 2}{cmd:. gene logweight=log(weight)}{p_end}
{p 8 12 2}{cmd:. censlope logweight foreign, transf(z) centile(0(25)100) eform}{p_end}

{pstd}
The following example uses the {cmd:wstrata} option of {helpb somersd} to
calculate median differences in fuel efficiency between non-U.S. and U.S. cars in
the same weight quintile.  We find that non-U.S. cars typically travel 2 to 7
more miles per gallon than U.S. cars, but 0 to 4 fewer miles per gallon
than U.S. cars in the same weight quintile:

{p 8 12 2}{cmd:. xtile weightgp=weight, nquantiles(5)}{p_end}
{p 8 12 2}{cmd:. tab weightgp foreign}{p_end}
{p 8 12 2}{cmd:. censlope mpg foreign, transf(z)}{p_end}
{p 8 12 2}{cmd:. censlope mpg foreign, transf(z) wstrata(weightgp)}{p_end}

{pstd}
The following example creates a scatterplot of car weight in U.S. pounds
against car length in U.S. inches with a straight line through the data points,
whose slope is the median slope and whose intercept is the median of the
variable {cmd:resi} generated by the {cmd:ystargenerate()} option:

{p 8 12 2}{cmd:. censlope weight length, transf(z) tdist ystargenerate(resi)}{p_end}
{p 8 12 2}{cmd:. egen intercept=median(resi)}{p_end}
{p 8 12 2}{cmd:. gene what=weight-resi+intercept}{p_end}
{p 8 12 2}{cmd:. lab var what "Predicted weight"}{p_end}
{p 8 12 2}{cmd:. scatter weight length || line what length, sort}{p_end}

{pstd}
The following example uses the {cmd:estaddr} option
together with {helpb parmby} (part of the {helpb parmest} package) to produce
an output dataset (or resultsset) in the memory, with one observation per
by-group, and data on confidence intervals for Somers' {it:D} and median slopes.
This dataset is then input to the {helpb eclplot} command to produce a
confidence interval plot of Somers' {it:D} parameters and a confidence interval
plot of median slopes.  The packages {helpb parmest} and {helpb eclplot} can
be downloaded from {help ssc:SSC}.

{p 8 12 2}{cmd:. parmby "censlope weight length, tdist estaddr", by(foreign) norestore ecol(cimat) rename(ec_1_1 percent ec_1_2 pctlslope ec_1_3 minimum ec_1_4 maximum)}{p_end}
{p 8 12 2}{cmd:. list}{p_end}
{p 8 12 2}{cmd:. eclplot estimate min95 max95 foreign, hori ylabel(0 1) xtitle("Somers' D (95% CI)")}{p_end}
{p 8 12 2}{cmd:. eclplot pctlslope minimum maximum foreign, hori ylabel(0 1) xtitle("Percentile slope (95% CI)")}{p_end}

{pstd}
The following example illustrates the use of the {helpb bootstrap} prefix command
to generate bootstrap confidence limits for the median slope,
as recommended by Wilcox (1998).
Note the use of the {cmd:nolimits} option, described in the help for 
{help censlope_iteration:{it:iteration_options}}.
This approximately halves the computation time used by the bootstrap,
because no confidence limits are calculated for the individual bootstrap subsamples.

{p 8 12 2}{cmd:.set seed 987654321}{p_end}
{p 8 12 2}{cmd:.bootstrap medslope=el(r(cimat),1,2), reps(399): censlope weight length, nolimits}{p_end}
{p 8 12 2}{cmd:.estat bootstrap, all}{p_end}


{title:Saved results}

{pstd}
{cmd:censlope} saves the following results in {cmd:r()}:

{p2colset 5 21 25 2}{...}
{p2col:Scalars}{p_end}
{p2col:{cmd:r(level)}}confidence level{p_end}
{p2col:{cmd:r(fromabs)}}value of the {cmd:fromabs()} option{p_end}
{p2col:{cmd:r(tolerance)}}value of the {cmd:tolerance()} option{p_end}

{p2col:Macros}{p_end}
{p2col:{cmd:r(yvar)}}name of the Y variable{p_end}
{p2col:{cmd:r(xvar)}}name of the X variable{p_end}
{p2col:{cmd:r(eform)}}{cmd:eform} if specified{p_end}
{p2col:{cmd:r(centiles)}}list of percentages for the percentiles{p_end}
{p2col:{cmd:r(technique)}}list of techniques from the {cmd:technique()} option{p_end}
{p2col:{cmd:r(tech_steps)}}list of step numbers for the techniques{p_end}

{p2col:Matrices}{p_end}
{p2col:{cmd:r(cimat)}}confidence intervals for percentile differences or ratios{p_end}
{p2col:{cmd:r(rcmat)}}return codes for entries of {cmd:r(cimat)}{p_end}
{p2col:{cmd:r(bracketmat)}}bracket matrix{p_end}
{p2col:{cmd:r(techstepmat)}}column vector of step numbers for the techniques{p_end}
{p2colreset}{...}

{pstd}
The matrix {cmd:r(cimat)} has one row per percentile, as well as columns containing
the percentages, percentile estimates, lower and upper
confidence limits (labeled {hi:Percent}, {hi:Pctl_Slope}, {hi:Minimum}, and
{hi:Maximum} if {cmd:eform} is not specified, or {hi:Percent},
{hi:Pctl_Ratio}, {hi:Minimum}, and {hi:Maximum} if {cmd:eform} is specified).
The matrix {cmd:r(rcmat)} has the same numbers of rows and columns as
{cmd:r(cimat)} with the same labels, and the first column contains the
percentages, but the other entries contain return codes for the estimation of the
corresponding entries of {cmd:r(cimat)}.  These return codes are equal to 0 if
the beta-value was estimated successfully (or not requested by the user),
1 if the corresponding zetastar-value could not be calculated,
2 if the corresponding zetastar-value could not be bracketed,
3 if the beta-brackets failed to converge,
and 4 if the beta-value could not be calculated from the converged beta-brackets.
The matrix {cmd:r(bracketmat)} is the final version of the bracket matrix
described in help for the
{help censlope_iteration:fromabs() and brackets() options} of {cmd:censlope}
and has one row per beta-bracket, as well as two columns, labeled {hi:Beta} and
{hi:Zetastar}, containing the beta-brackets and the corresponding
zetastar-values.  The matrix {cmd:r(techstepmat)} is a column vector with one
row for each of the techniques listed in the
{help censlope_iteration:technique() option}, with a row label equal to the
name of the technique and a value equal to the number of steps for that
technique.  The {cmd:fromabs()}, {cmd:brackets()}, {cmd:tolerance()}, and
{cmd:technique()} options are described in 
{help censlope_iteration:{it:iteration_options}}.

{pstd}
{cmd:censlope} also saves in {cmd:e()} a full set of
{help ereturn:estimation results} for the {helpb somersd} command.
If {cmd:estaddr} is specified, this set of estimation results is expanded by
adding a set of {cmd:e()} results with the same names and contents as the
{cmd:r()} results.  This option allows the user to pass a {cmd:censlope}
command to {helpb parmest:parmby}, producing an output dataset (or results set)
with one observation per by-group and data on confidence intervals for Somers'
D and for the median slope.


{title:Author}

{pstd}
Roger Newson, Imperial College London, UK.{break}
Email: {browse "mailto:r.newson@imperial.ac.uk":r.newson@imperial.ac.uk}


{title:References}

{phang}
Newson, R.  2002.
Parameters behind "nonparametric" statistics:
Kendall's tau, Somers' {it:D} and median differences.
{it:Stata Journal} 2: 45-64.
Download from
{browse "http://www.stata-journal.com/article.html?article=st0007":the {it:Stata Journal} website}.

{phang}
Newson, R.  2006.
Confidence intervals for rank statistics:
Percentile slopes, differences, and ratios.
{it:Stata Journal} 6: 497-520.
Download from
{browse "http://www.stata-journal.com/article.html?article=snp15_7":the {it:Stata Journal} website}.

{phang}
Wilcox, R. R.  1998.
A note on the Theil-Sen regression estimator when the regressor is random and the error term is heteroscedastic.
{it:Biometrical Journal} 40: 261-268.


{title:Also see}

{psee}
Manual: {hi:[R] spearman}, {hi:[R] ranksum}, {hi:[R] signrank}, {hi:[R] centile}
{p_end}

{psee}  STB:  STB-52: sg123, STB-55: snp15, STB-57: snp15.1, STB-58: snp15.2,
          STB-58: snp16; STB-61: snp15.3; STB-61: snp16.1{p_end}

{psee}
Online: {helpb ktau}, {helpb ranksum}, {helpb signrank}{break}
          {helpb cid}, {helpb npshift}, {helpb somersd}, {helpb cendif},
	  {helpb parmest}, {helpb eclplot} (if installed)
{p_end}
