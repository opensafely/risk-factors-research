{smcl}
{...}
{hline}
help for {hi:somersd}{right:(SJ6-3: snp15_6; SJ5-3: snp15_5; SJ3-3: snp15_4;}
{right:STB-61: snp15_3; STB-58: snp15_2; STB-57: snp15)}
{hline}

{title:Somers' {it:D} or Kendall's tau-a with confidence intervals}

{p 8 21 2}
{cmd:somersd} {varlist} {weight} {ifin}
[{cmd:,} {cmdab:ta:ua} {cmdab:tr:ansf}{cmd:(}{it:transformation_name}{cmd:)} {cmdab:td:ist}
{cmdab:ce:nind}{cmd:(}{it:cenind_list}{cmd:)}
{cmdab:cl:uster}{cmd:(}{it:varname}{cmd:)}
{cmdab:cfw:eight}{cmd:(}{it:expression}{cmd:)}
{cmdab:fu:ntype}{cmd:(}{it:functional_type}{cmd:)}
{cmdab:ws:trata}{cmd:(}{it:varlist}{cmd:)}
{cmdab:bs:trata}{cmd:(}{it:varlist} | {cmd:_n}{cmd:)}
{cmdab::no}{cmdab:tre:e}
{cmdab:l:evel}{cmd:(}{it:#}{cmd:)}
{cmdab:ci:matrix}{cmd:(}{it:new_matrix}{cmd:)} ]

{pstd}
where {it:transformation_name} is one of

{p 8 21 2}
{cmd:iden} | {cmd:z} | {cmd:asin} | {cmd:rho} | {cmd:zrho} | {cmd:c}

{pstd}
and {it:functional_type} is one of

{p 8 21 2}
{cmdab:w:cluster} | {cmdab:b:cluster} | {cmdab:v:onmises}

{pstd}
and {it:cenind_list} is a list of variable names and/or zeros.

{pstd}
{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see
{help weight}.

{pstd}
{opt bootstrap}, {opt by}, {opt jackknife}, {opt statsby}, {opt mi estimate},
{opt svy jackknife}, {opt svy bootstrap}, {opt svy brr} and {opt svy sdr}
are allowed; see {helpb prefix}.{p_end}


{title:Description}

{pstd}
{cmd:somersd} computes confidence intervals for a wide range of rank
statistics.  It includes 3 component modules, each with a .pdf manual, which
is distributed with the {cmd:somersd} package as an ancillary file.  The
modules are as follows:

{p2colset 4 28 32 2}{...}
{p2col:Module{space 4}File}Calculates confidence intervals for{p_end}
{p2line}
{p2col:{cmd:somersd}{space 3}{hi:somersd.pdf}}Kendall's tau-a and Somers'
D{p_end}
{p2col:{helpb censlope}{space 2}{hi:censlope.pdf}}Theil-Sen median (and other percentile) slopes{p_end}
{p2col:{helpb cendif}{space 4}{hi:cendif.pdf}}Hodges-Lehmann median (and other percentile) differences{p_end}
{p2colreset}{...}

{pstd}
The modules {helpb censlope} and {helpb cendif} require the module
{cmd:somersd} in order to work and use a lot of the same options.

{pstd}
The module {cmd:somersd} calculates values of Somers' {it:D} or Kendall's tau-a
for the first variable of {it:varlist} as a predictor of each of the other
variables in {it:varlist}, with estimates and jackknife variances and
confidence intervals output as if for the parameters of a maximum likelihood
fit. It is possible to use {helpb lincom} to output confidence limits for
differences between the population Somers' {it:D} or tau-a values.


{title:Options for use with somersd}

{p 4 8 2}
{cmd:taua} causes {cmd:somersd} to calculate Kendall's tau-a. If {cmd:taua} is
absent, then Somers' {it:D} is calculated.

{p 4 8 2}
{cmd:transf(}{it:transformation_name}{cmd:)} specifies that the estimates are to be transformed,
defining a confidence level for the transformed population value. {cmd:iden}
(identity or untransformed) is the default. {cmd:z} specifies Fisher's z (the
hyperbolic arctangent), {cmd:asin} specifies Daniels' arcsine, {cmd:rho}
specifies Greiner's rho (Pearson correlation estimated using Greiner's
relation), {cmd:zrho} specifies the {cmd:z}-transform of Greiner's rho, and
{cmd:c} specifies Harrell's c.  If the first variable of the {it:varlist}
is a binary indicator of a disease and the other variables are quantitative
predictors for that disease, then Harrell's c is the area under the
receiver operating characteristic (ROC) curve.  {cmd:somersd} recognizes the
transformation names {cmd:arctanh} and {cmd:atanh} as synonyms for {cmd:z},
{cmd:arcsin} and {cmd:arsin} as synonyms for {cmd:asin}, {cmd:sinph} as a
synonym for {cmd:rho}, {cmd:zsinph} as a synonym for {cmd:zrho}, and {cmd:roc}
and {cmd:auroc} as synonyms for {cmd:c}.  It also recognizes unambiguous
abbreviations for transformation names, such as {cmd:id} for {cmd:iden} or
{cmd:aur} for {cmd:auroc}.  The transformations are calculated using a
{help somersd_mata:Mata function}.

{p 4 8 2}
{cmd:tdist} specifies that the estimates are assumed to have a
t distribution with {hi:N-1} degrees of freedom, where {hi:N} is the number of
clusters if {cmd:cluster()} is specified, or the number of observations
if {cmd:cluster()} is not specified.
If {cmd:tdist} is not specified,
then the standardized Somers' {it:D} estimates are assumed to be sampled from a standard Normal distribution.
Simulation study data suggest that the {cmd:tdist} option should be recommended.

{p 4 8 2}
{cmd:cenind(}{it:cenind_list}{cmd:)} specifies a list of left- or
right-censorship indicators, corresponding to the variables mentioned in the
{it:varlist}. Each censorship indicator is either a variable name or a zero.
If the censorship indicator corresponding to a variable is the name of a
second variable, then this second variable is used to indicate the censorship
status of the first variable, which is assumed to be left-censored (at or
below its stated value) in observations in which the second variable is
negative, right-censored (at or above its stated value) in observations in
which the second variable is positive, and uncensored (equal to its stated
value) in observations in which the second variable is zero. If the censorship
indicator corresponding to a variable is a zero, then the variable is assumed
to be uncensored.  If {cmd:cenind()} is unspecified, then all variables in the
{cmd:varlist} are assumed to be uncensored. If the list of censorship
indicators specified by {cmd:cenind()} is shorter than the list of variables
specified in the {it:varlist}, then the list of censorship indicators is
completed with the required number of zeros on the right.

{p 4 8 2}
{cmd:cluster(}{it:varname}{cmd:)} specifies the variable which defines
sampling clusters.  If {cmd:cluster()} is specified, then the variances and
confidence limits are calculated assuming that the data represent a sample of
clusters from a population of clusters, rather than a sample of observations
from a population of observations.

{p 4 8 2}
{cmd:cfweight(}{it:expression}{cmd:)} specifies an expression giving the
cluster frequency weights.  These cluster frequency weights must have the same
value for all observations in a cluster.  If {cmd:cfweight()} and
{cmd:cluster()} are both specified, then each cluster in the dataset is
assumed to represent a number of identical clusters equal to the cluster
frequency weight for that cluster. If {cmd:cfweight()} is specified and
{cmd:cluster()} is unspecified, then each observation in the dataset is
treated as a cluster, and assumed to represent a number of identical
one-observation clusters equal to the cluster frequency weight.  For more
details on the interpretation of weights, see {hi:Interpretation of weights}
below.

{p 4 8 2}
{cmd:funtype(}{it:functional_type}{cmd:)} specifies whether the Somers' {it:D}
or Kendall's tau-a functionals estimated are between-cluster, within-cluster
or Von Mises functionals.  These three functional types are specified by the
options {cmd:funtype(bcluster)}, {cmd:funtype(wcluster)} or
{cmd:funtype(vonmises)}, respectively. If {cmd:funtype()} is not specified,
then {cmd:funtype(bcluster)} is assumed, and between-cluster functionals are
estimated. The within-cluster Somers' {it:D} is a generalization of the
confidence interval corresponding to the {help signrank:sign test}.  The Gini
coefficient is a special case of the clustered Von Mises Somers' {it:D}.  For
further details, see the manual {hi:somersd.pdf}, distributed with
{cmd:somersd} as an ancillary file.

{p 4 8 2}
{cmd:wstrata(}{it:varlist}{cmd:)} specifies a list of variables whose value
combinations are the W strata. If {cmd:wstrata()} is specified, then
{cmd:somersd} estimates stratified Somers' {it:D} or Kendall's tau-a
parameters, applying only to pairs of observations within the same W
stratum. These parameters can be used to measure associations within strata,
such as associations between an outcome and an exposure within groups defined
by values of a confounder, or by values of a propensity score based on
multiple confounders.

{p 4 8 2}
{cmd:bstrata(}{it:varlist} | {cmd:_n}{cmd:)} specifies the B strata.  If
{cmd:bstrata()} is specified, then {cmd:somersd} estimates Somers' {it:D} or
Kendall's tau-a parameters specific to pairs of observations from different
B strata.  These B strata are either combinations of values of a
list of variables (if {it:varlist} is specified) or the individual
observations (if {cmd:_n} is specified).  B strata will not often be
required. However, if we are estimating the within-cluster Kendall's tau-a
(using the options {cmd:taua funtype(wcluster)}), then the additional option
{cmd:bstrata(_n)} will ensure that the within-cluster Kendall's tau-a can take
the whole range of values from -1 (in the case of complete discordance within
clusters) to +1 (in the case of complete concordance within clusters).

{p 4 8 2}
{cmd:notree} specifies that {cmd:somersd} does not use the default
{help somersd_mata:search tree algorithm} based on Newson (2006a), but instead
uses a trivial algorithm, which compares every pair of observations and
requires much more time with large datasets. This option is rarely used except
to compare performance.  Both algorithms are implemented in {help mata:Mata},
using a set of {help somersd_mata:Mata functions}, whose source code is
distributed with the {cmd:somersd} package.

{p 4 8 2}
{cmd:level(}{it:#}{cmd:)} specifies the confidence level, as a percentage, for
confidence intervals of the estimates; see {helpb level}.

{p 4 8 2}
{cmd:cimatrix(}{it:new_matrix}{cmd:)} specifies an output matrix to be
created, containing estimates and confidence limits for the untransformed
Somers' {it:D}, Kendall's tau-a or Greiner's rho parameters. If {cmd:transf()}
is specified, then the confidence limits will be asymmetric and based on
symmetric confidence limits for the transformed parameters. This option (like
{cmd:level()} may be used in replay mode as well as in nonreplay mode.


{title:Remarks}

{pstd}
For uncensored variables X and Y, Kendall's tau-a is defined as

{phang2}
{hi:tau_a(X,Y) = E[sign(X1-X2)*sign(Y1-Y2)]}

{pstd}
where (X1,Y1) and (X2,Y2) are sampled from the bivariate
distribution of X and Y.  In the case of censored variables X
and Y, with censorship indicators R and S, respectively, which
are negative for left-censorship, positive for right-censorship, and zero for
noncensorship, we define Kendall's tau-a as

{phang2}
{hi:tau_a(X,Y) = E[csign(X1,R1,X2,R2)*csign(Y1,S1,Y2,S2)]}

{pstd}
where the function

{phang2}
{hi:csign(U,P,V,Q)}

{pstd}
is defined as 1 if U>V and P>=0>=Q, -1 if U<V,
P<=0<=Q, and 0 otherwise.

{pstd}
Somers' {it:D} is defined as

{phang2}
{hi:D(Y|X) = tau_a(X,Y)/tau_a(X,X)}

{pstd}
In the case of a binary X-variable, Somers' {it:D} is the parameter
tested for a zero value by the Mann-Whitney U test. If X is a
disease indicator and Y is a quantitative diagnostic measure, then
Somers' {it:D} is related to the area A under the ROC curve by the
formula

{phang2}
{hi:A=[D(Y|X)+1]/2}

{pstd}
and confidence limits for A can be calculated by specifying the option
{cmd:transf(c)}.  The covariance matrix is estimated by jackknifing the
underlying U statistics and using Taylor polynomials. Confidence
intervals for differences and other contrasts can be calculated using
{helpb lincom}. Confidence intervals for Theil-Senn median (and other
percentile) slopes (or per-unit ratios) can be calculated using 
{helpb censlope}, which is distributed as part of the {cmd:somersd} package.
Confidence intervals for Hodges-Lehmann median (and other percentile)
differences (and ratios) between two groups can be calculated using
{helpb cendif}, which is also distributed as part of the {cmd:somersd}
package.

{pstd}
Full documentation of the {cmd:somersd} package (including methods and
formulas) is provided in the files {hi:somersd.pdf}, {hi:censlope.pdf}, and
{hi:cendif.pdf}, which are distributed with the {hi:somersd} package (see
{helpb net}). They can be viewed using the Adobe Acrobat Reader, which can be
downloaded from
{browse "http://www.adobe.com/products/acrobat/readermain.html":the Adobe Acrobat website}.
{cmd:somersd} uses a library of {help somersd_mata:Mata functions},
and the source code for these functions is distributed with {cmd:somersd} as
installation files.

{pstd}
For a comprehensive review of Kendall's tau-a, Somers' {it:D} and median
differences, see Newson (2002).
The statistical and computational methods used by the {cmd:somersd} package
are described in detail in Newson (2006a), Newson (2006b), Newson (2006c)
and Newson (2010).


{title:Interpretation of weights}

{pstd}
{cmd:somersd} inputs up to two weight expressions, which are the ordinary
{help weight:Stata weights} given by the {it:weight} and the cluster frequency
weights given by the {cmd:cfweight()} option.  Internally, {cmd:somersd}
defines and uses three distinct sets of weights, which are the cluster
frequency weights, the observation frequency weights, and the importance
weights.

{pstd}
The cluster frequency weights must be the same for different observations in a
cluster, and imply that each cluster in the input dataset represents a number
of identical clusters equal to the cluster frequency weight in that cluster.
If {cmd:cluster()} is not specified, then the individual observations are
clusters, and the cluster frequency weight implies that each one-observation
cluster represents a number of identical one-observation clusters equal to the
cluster frequency weight. The cluster frequency weights are given by
{cmd:cfweight()} if that option is specified; are set to 1 if {cmd:cfweight()}
is unspecified and {cmd:cluster()} is specified; are equal to the ordinary
Stata weights if neither {cmd:cluster()} nor {cmd:cfweight()} is specified and
the ordinary Stata weights are {helpb weight:fweight}s; and are equal to 1
otherwise.

{pstd}
The observation frequency weights are summed over all observations in the
input dataset to produce the number of observations reported by {cmd:somersd}
and returned in the estimation result {hi:e(N)}, and are not used in any other
way. They are set by {cmd:cfweight()} if that option is specified and the
ordinary Stata weights are not {helpb weight:fweight}s, are equal to the
ordinary Stata weights if {cmd:cfweight()} is unspecified and the ordinary
Stata weights are {helpb weight:fweight}s, are equal to the product of the
{cmd:cfweight()} expression and the ordinary Stata weights if
{cmd:cfweight()} is specified and the ordinary Stata weights are
{helpb weight:fweight}s, and are equal to 1 otherwise.

{pstd}
The importance weights are used as described in the {hi:Methods and Formulas}
section of the file {hi:somersd.pdf} distributed with the {cmd:somersd}
package.  They are equal to the ordinary Stata weights if these are specified
and either {cmd:cluster()} or {cmd:cfweight()} is specified, are equal to the
ordinary Stata weights if neither of these two options is specified and the
ordinary Stata weights are specified as {helpb weight:pweight}s or
{helpb weight:iweight}s, and are equal to 1 otherwise.


{title:Examples}

{p 8 12 2}{cmd:. somersd foreign mpg weight, tr(z)}{p_end}

{p 8 12 2}{cmd:. somersd us gpm weight}{p_end}
{p 8 12 2}{cmd:. lincom (weight-gpm)/2}{p_end}

{p 8 12 2}{cmd:. somersd us gpm weight, tr(c)}{p_end}
{p 8 12 2}{cmd:. lincom weight-gpm}{p_end}

{p 8 12 2}{cmd:. somersd mpg weight displ, taua tr(z) cluster(manuf)}{p_end}

{pstd}
The following example demonstrates the {cmd:cenind()} option:

{p 8 12 2}{cmd:. use http://www.stata-press.com/data/r9/drugtr, clear}{p_end}
{p 8 12 2}{cmd:. gene youth=100-age}{p_end}
{p 8 12 2}{cmd:. gene byte censind=1-died}{p_end}
{p 8 12 2}{cmd:. somersd studytime drug youth, tr(c) cenind(censind)}{p_end}
{p 8 12 2}{cmd:. lincom drug-youth}{p_end}
{p 8 12 2}{cmd:. sts test drug, wilcoxon}{p_end}
{p 8 12 2}{cmd:. somersd drug studytime, tr(z) cenind(0 censind)}{p_end}


{title:Saved results}

{pstd}
{cmd:somersd} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(denominator)}}common denominator{p_end}
{synopt:{cmd:e(depvarsum)}}sum of {it:X}-variable in estimation sample{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:somersd}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(param)}}parameter ({cmd:somersd} or {cmd:taua}){p_end}
{synopt:{cmd:e(parmlab)}}parameter label in output{p_end}
{synopt:{cmd:e(tdist)}}{cmd:tdist} if specified{p_end}
{synopt:{cmd:e(depvar)}}name of {it:X}-variable{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(vcetype)}}title used to label standard error{p_end}
{synopt:{cmd:e(wtype)}}weight type{p_end}
{synopt:{cmd:e(wexp)}}weight expression{p_end}
{synopt:{cmd:e(cfweight)}}{cmd:cfweight()} expression{p_end}
{synopt:{cmd:e(funtype)}}{cmd:funtype()} option{p_end}
{synopt:{cmd:e(wstrata)}}{cmd:wstrata()} option{p_end}
{synopt:{cmd:e(bstrata)}}{cmd:bstrata()} option{p_end}
{synopt:{cmd:e(predict)}}program called by {cmd:predict} ({cmd:somers_p}){p_end}
{synopt:{cmd:e(transf)}}transformation specified by {cmd:transf()}{p_end}
{synopt:{cmd:e(tranlab)}}transformation label in output{p_end}
{synopt:{cmd:e(properties)}}{hi:b V}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{pstd}
Note that (confusingly) {cmd:e(depvar)} is the {it:X}-variable, or predictor variable,
in the conventional terminology for defining Somers' {it:D}.
{cmd:somersd} is also different from most estimation commands
in that its results are not designed to be used by {cmd:predict}.
If the user tries to do so, then the program {cmd:somers_p} is called,
and tells the user that {cmd:predict} should not be used after {cmd:somersd}.
The scalar {cmd:e(denominator)} contains the common denominator used in calculating
the Somers' {it:D} or Kendall's tau-a statistics.


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
Newson, R.  2006a.
Efficient calculation of jackknife confidence intervals for rank statistics.
{it:Journal of Statistical Software} 15: 1-10.
Download from
{browse "http://www.jstatsoft.org/v15/i01":the {it:Journal of Statistical Software} website}.

{phang}
Newson, R.  2006b.
Confidence intervals for rank statistics:
Somers' {it:D} and extensions.
{it:Stata Journal} 6: 309-334.
Download from
{browse "http://www.stata-journal.com/article.html?article=snp15_6":the {it:Stata Journal} website}.

{phang}
Newson, R.  2006c.
Confidence intervals for rank statistics:
Percentile slopes, differences, and ratios.
{it:Stata Journal} 6: 497-520.
Download from
{browse "http://www.stata-journal.com/article.html?article=snp15_7":the {it:Stata Journal} website}.

{phang}
Newson, R. B.  2010.
Comparing the predictive powers of survival models using Harrell's {it:C} or Somers' {it:D}.
{it:Stata Journal} 10: 339-358.
Download from
{browse "http://www.stata-journal.com/article.html?article=st0198":the {it:Stata Journal} website}.


{title:Also see}

{p 4 13 2}
{bind: }Manual: {hi:[R] spearman}, {hi:[R] ranksum}, {hi:[R] signrank}, {hi:[R] roc}
{p_end}
{p 4 13 2}
{bind:   }STB:  STB-52: sg123, STB-55: snp15, STB-57: snp15.1, STB-58: snp15.2,
          STB-58: snp16; STB-61: snp15.3; STB-61: snp16.1.
{p_end}
{p 4 13 2}
Online:  {helpb ktau}, {helpb ranksum}, {helpb signrank}, {helpb roc},
         {helpb lincom}, {helpb jknife},{break}
         {helpb cendif}, {helpb censlope}, if installed
{p_end}
