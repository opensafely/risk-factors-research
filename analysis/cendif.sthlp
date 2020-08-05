{smcl}
{hline}
help for {hi:cendif}{right:(SJ6-4: snp15_7; SJ6-3: snp15_6; SJ5-3: snp15_5; SJ3-3: snp15_4;}
{right:STB-61: snp15_3; STB-58: snp15_2; STB-57: snp15)}
{hline}

{title:Robust confidence intervals for median and other percentile differences}

{p 8 21 2}
{cmd:cendif} {it:depvar} [{cmd:using} {it:filename}] {weight} {ifin}{cmd:,}
{cmd:by(}{it:groupvar}{cmd:)}
[{cmdab:ce:ntile}{cmd:(}{it:numlist}{cmd:)} {cmdab:l:evel}{cmd:(}{it:#}{cmd:)} {cmdab:ef:orm}
{cmdab:ys:targenerate}{cmd:(}{help newvarlist:{it:newvarlist}}{cmd:)}
{cmdab:cl:uster}{cmd:(}{it:varname}{cmd:)}
{cmdab:cfw:eight}{cmd:(}{it:expression}{cmd:)}
{cmdab:fu:ntype}{cmd:(}{it:functional_type}{cmd:)}
{cmdab:td:ist} {cmdab:tr:ansf}{cmd:(}{it:transformation_name}{cmd:)}
{cmdab:sa:ving}{cmd:(}{it:filename}[{cmd:,replace}]{cmd:)} no{cmd:hold} ]

{pstd}
where {it:transformation_name} is one of

{p 8 21 2}
{cmd:iden} | {cmd:z} | {cmd:asin}

{pstd}
and {it:functional_type} is one of

{p 8 21 2}
{cmdab:w:cluster} | {cmdab:b:cluster} | {cmdab:v:onmises}

{pstd}
{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see
{help weight}.

{pstd}
{opt bootstrap}, {opt by}, {opt jackknife}, and {opt statsby}
are allowed; see {help prefix}.{p_end}


{title:Description}

{pstd}
{cmd:cendif} calculates confidence intervals for generalized Hodges-Lehmann
median differences, and other percentile differences, between values of a
Y-variable in {it:depvar} for a pair of observations chosen at random
from two groups A and B, defined by the {it:groupvar} in the
{cmd:by()} option. These confidence intervals are robust to the possibility
that the population distributions in the two groups are different in ways
other than location. This might happen if, for example, the two populations
had different variances. For positive-valued variables, {cmd:cendif} can be
used to calculate confidence intervals for median ratios or other percentile
ratios. {cmd:cendif} is part of the {helpb somersd} package and requires the
{helpb somersd} program to work.  The parameters estimated by
{cmd:cendif} are a subset of those estimated by {helpb censlope}, which is also
part of the {helpb somersd} package.  However, {cmd:cendif} may be more easy to
use than {helpb censlope} and more time-efficient for small sample numbers.


{title:Options for use with cendif}

{p 4 8 2}
{cmd:by(}{it:groupvar}{cmd:)} is not optional. It specifies the name of the
grouping variable. This variable must have exactly two possible values.  The
lower value indicates group A, and the higher value indicates group B.

{p 4 8 2}
{cmd:centile(}{it:numlist}{cmd:)} specifies a list of percentile differences
to be reported and defaults to {cmd:centile(50)} (median only) if not
specified. Specifying {cmd:centile(25 50 75)} will produce the 25th, 50th, and
75th percentile differences.

{p 4 8 2}
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a percentage, for
confidence intervals; see {helpb level}.

{p 4 8 2}
{cmd:eform} specifies that exponentiated percentile differences be
given. This option is used if {it:depvar} is the log of a positive-valued
variable.  In this case, confidence intervals are calculated for percentile
ratios between values of the original positive variable instead of for
percentile differences.

{p 4 8 2}
{cmd:ystargenerate(}{help newvarlist:{it:newvarlist}}{cmd:)} specifies a list
of variables to be generated, corresponding to the percentile differences,
containing the differences {hi:Y*(theta)=Y-group1*theta}, where {hi:group1} is
a binary variable indicating membership of group 1 and {hi:theta} is the
percentile difference.  The variable names in the
{help newvarlist:{it:newvarlist}} are matched to the list of percentiles
specified by the {cmd:centile()} option, sorted in ascending order of
percentage.  If the two lists have different lengths, {cmd:cendif} generates
a number {it:nmin} of new variables equal to the minimum length of the two
lists, matching the first {it:nmin} percentiles with the first {it:nmin} new
variable names.  Usually, there is only one percentile difference (the median
difference) and one new {cmd:ystargenerate()} variable.

{p 4 8 2}
{cmd:cluster(}{it:varname}{cmd:)} specifies the variable that defines
sampling clusters.
If {cmd:cluster()} is defined, then the confidence
intervals are calculated assuming that the data are a sample of clusters from
a population of clusters rather than a sample of observations from a
population of observations.

{p 4 8 2}
{cmd:cfweight(}{it:expression}{cmd:)} specifies an expression giving the
cluster frequency weights.  These cluster frequency weights must have the same
value for all observations in a cluster.  If {cmd:cfweight()} and
{cmd:cluster()} are both specified, then each cluster in the dataset is
assumed to represent a number of identical clusters equal to the cluster
frequency weight for that cluster. If {cmd:cfweight()} is specified and
{cmd:cluster()} is unspecified, then each observation in the dataset is
treated as a cluster, and assumed to represent a number of identical
one-observation clusters equal to the cluster frequency weight.
For more details on the interpretation of weights,
see {hi:Interpretation of weights} in the help for {helpb somersd}.
Note that the observation frequency weights are used by {cmd:cendif}
for tabulating the group frequencies.

{p 4 8 2}
{cmd:funtype(}{it:functional_type}{cmd:)} specifies
whether the percentile differences estimated are between-cluster, within-cluster
or Von Mises percentile differences.
These three functional types are specified by the
options {cmd:funtype(bcluster)}, {cmd:funtype(wcluster)} or
{cmd:funtype(vonmises)}, respectively,
and correspond to the functional types of the same names used by {helpb somersd}.
If {cmd:funtype()} is not specified, then {cmd:funtype(bcluster)} is assumed,
and between-cluster percentile differences are estimated.
If the clusters are pairs of observations,
and if the {cmd:by()} option specifies an indicator variable
indicating whether the observation is the first or second member of its pair,
then the within-cluster median difference is the parameter
corresponding to the {help signrank:sign test},
and the Von Mises median difference is the conventional Hodges-Lehmann median difference
between the group of first members and the group of second members,
with confidence limits adjusted for clustering.
For further details, see the manual {hi:cendif.pdf}, distributed with
{helpb somersd} as an ancillary file.

{p 4 8 2}
{cmd:tdist} specifies that the standardized Somers' {it:D} estimates are
assumed to be sampled from a t distribution with n-1 degrees of
freedom, where n is the number of clusters or the number of observations
if {cmd:cluster()} is not specified.
If {cmd:tdist} is not specified,
then the standardized Somers' {it:D} estimates are assumed to be sampled from a standard Normal distribution.
Simulation study data suggest that the {cmd:tdist} option should be recommended.

{p 4 8 2}
{cmd:transf(}{it:transformation_name}{cmd:)} specifies that the Somers' {it:D}
estimates are to be transformed, defining a standard error for the transformed
population value, from which the confidence limits for the percentile
differences are calculated.  {cmd:z} (the default) specifies Fisher's z
(the hyperbolic arctangent), {cmd:asin} specifies Daniels' arcsine, and
{cmd:iden} specifies identity or untransformed.

{p 4 8 2}
{cmd:saving(}{it:filename}[{cmd:,replace}]{cmd:)} specifies a dataset to be
created, whose observations correspond to the observed values of differences
between a value of {it:depvar} in group A and a value of {it:depvar} in
group B.  {cmd:replace} instructs Stata to replace any existing dataset
of the same name.  The saved dataset can then be reused if {cmd:cendif} is
called later with {cmd:using} to save the long processing times
used to calculate the set of observed differences.  The {cmd:saving()} option
and the {cmd:using} qualifier are provided mainly for programmers to use, at
their own risk.

{p 4 8 2}
{cmd:nohold} indicates that any existing estimation results be
overwritten with a new set of estimation results for the use of programmers.
By default, any existing estimation results are restored after execution of
{cmd:cendif}.


{marker cendif_remarks}{...}
{title:Remarks}

{pstd}
{cmd:cendif} is part of the {helpb somersd} package and uses the program
{helpb somersd}, which calculates confidence intervals for Somers' {it:D}.  A
100{hi:q}th percentile difference is defined as a value of {hi:theta}
satisfying the equation

{pstd}
{hi:D[ystar(theta)|group_A] = 1-2q}

{pstd}
where {hi:D[.|.]} represents Somers' {it:D}, {hi:group_A} is an indicator
variable for membership of group A instead of group B, and
{hi:ystar(theta)} is a variable equal to {it:depvar} for observations in group
A and equal to {it:depvar}{hi:+theta} for observations in group B.
If {hi:q}=0.5, then the value of {hi:theta} is the Hodges-Lehmann median
difference. In this case, {cmd:cendif y, by(group)} gives the same median
difference as {cmd:npshift y, by(group)}, although the confidence limits may
be different. (The program {helpb npshift} calculates confidence intervals for
the Hodges-Lehmann minimum difference, assuming that the two group
distributions differ only in location. It is available from Stata Technical
Bulletin (STB) in STB-52: sg123.)

{pstd}
For extreme percentiles and/or very small sample numbers, {cmd:cendif}
sometimes calculates infinite positive upper confidence limits or infinite
negative lower confidence limits.  These are represented by
{hi:+/-}{cmd:c(maxdouble)}, where {cmd:c(maxdouble)} is the
{help creturn:c-class value} specifying the largest positive number that can
be stored in a {help data_types:double}.

{pstd}
With very large sample numbers, {cmd:cendif} may be slow, as it must calculate
every possible paired difference between values in the two samples to
calculate the median difference. A possible remedy is to reduce the number of
possible differences by grouping the Y variable. For instance, if {cmd:income}
is a measure of income in dollars, and {cmd:group} is a binary variable
indicating membership of one of two groups, then the user might type

{p 4 8 2}{cmd:. gene incomegp=100*(int(income/100)+1)}{p_end}
{p 4 8 2}{cmd:. cendif incomegp, by(group) tdist}{p_end}

{pstd}
to calculate the median difference in income between the two groups to the
nearest 100 dollars. This process would probably take less time than if the
user typed

{p 4 8 2}{cmd:. cendif income, by(group) tdist}{p_end}

{pstd}
Full documentation of the {helpb somersd} package (including methods and
formulas) is provided in the files {hi:somersd.pdf}, {hi:censlope.pdf}, and
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

{p 4 8 2}{cmd:. cendif weight, tdist by(foreign)}{p_end}

{p 4 8 2}{cmd:. cendif weight, tdist by(foreign) ce(0(25)100)}{p_end}

{p 4 8 2}{cmd:. gene logwt=log(weight)}{p_end}
{p 4 8 2}{cmd:. cendif logwt, tdist by(foreign) ce(0(25)100) eform}{p_end}

{p 4 8 2}{cmd:. cendif mpg, by(foreign) saving(trash1, replace)}{p_end}
{p 4 8 2}{cmd:. cendif mpg using trash1, by(foreign) tr(asin) tdist}{p_end}

{pstd}
The following example uses the {cmd:funtype()} option to estimate median differences between paired data.
It uses the {helpb dta_examples:bplong} dataset,
distributed with Stata and accessible using the {helpb sysuse} command,
with one observation for each of 2 blood pressure measurements (before and after treatment)
for each of a sample of patients.
The option {cmd:funtype(wcluster)} specifies the median difference
between measurements on the same patient before and after treatment,
which is equal to zero under the null hypothesis tested by the {help signrank:sign test}.
The option {cmd:funtype(vonmises)} specifies the conventional Hodges-Lehmann median difference
between the group of before-treatment measures and the group of after-treatment measurements,
with estimates calculated as if the two groups were two independent samples,
but with confidence limits adfjusted for clustering by patient.
This Von Mises parameter is zero under the null hypothesis tested by the clustered ranksum test
presented in Rosner {it:et al.} (2006).

{p 4 8 2}{cmd:. sysuse bplong, clear}{p_end}
{p 4 8 2}{cmd:. describe, simple}{p_end}
{p 4 8 2}{cmd:. cendif bp, by(when) tdist cluster(patient) funtype(wcluster)}{p_end}
{p 4 8 2}{cmd:. cendif bp, by(when) tdist cluster(patient) funtype(vonmises)}{p_end}


{title:Saved results}

{pstd}
{cmd:cendif} saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(N_clust)}}number of clusters{p_end}
{synopt:{cmd:r(N_1)}}first sample  size{p_end}
{synopt:{cmd:r(N_2)}}second sample  size{p_end}
{synopt:{cmd:r(df_r)}}residual degrees of freedom (if {cmd:tdist} present){p_end}
{synopt:{cmd:r(level)}}confidence level{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}name of {it:Y}-variable{p_end}
{synopt:{cmd:r(by)}}name of {cmd:by()} variable defining groups{p_end}
{synopt:{cmd:r(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:r(cfweight)}}{cmd:cfweight()} expression{p_end}
{synopt:{cmd:r(funtype)}}{cmd:funtype()} option{p_end}
{synopt:{cmd:r(tdist)}}{cmd:tdist} if specified{p_end}
{synopt:{cmd:r(wtype)}}weight type{p_end}
{synopt:{cmd:r(wexp)}}weight expression{p_end}
{synopt:{cmd:r(centiles)}}list of percents for percentiles{p_end}
{synopt:{cmd:r(Dslist)}}list of D-star values for percentiles{p_end}
{synopt:{cmd:r(transf)}}transformation specified by {cmd:transf()}{p_end}
{synopt:{cmd:r(tranlab)}}transformation label in output{p_end}
{synopt:{cmd:r(eform)}}{cmd:eform} if specified{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(cimat)}}confidence intervals for differences or ratios{p_end}
{synopt:{cmd:r(Dsmat)}}upper and lower limits for D-star values{p_end}
{p2colreset}{...}

{pstd}
The D-star value for a percentile {hi:theta} is the value of {hi:D[ystar(theta)|group_A]},
as defined in {helpb cendif##cendif_remarks:Remarks} above.


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
Rosner, B., R. J. Glynn and M-L. T. Lee.  2006.
Extension of the rank-sum test for clustered data:
Two-group comparisons with group membership defined at the subunit level.
{it:Biometrics} 62(4): 1251-1259.

{title:Also see}

{psee}
Manual: {hi:[R] spearman}, {hi:[R] ranksum}, {hi:[R] signrank}, {hi:[R] centile}
{p_end}

{psee}
STB:  STB-52: sg123, STB-55: snp15, STB-57: snp15.1, STB-58: snp15.2,
          STB-58: snp16; STB-61: snp15.3; STB-61: snp16.1.

{psee}
Online: {helpb ktau}, {helpb ranksum}, {helpb signrank}, {helpb centile}{break}
         {helpb cid}, {helpb npshift}, {helpb somersd}, {helpb censlope} (if installed)
{p_end}
