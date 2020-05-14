{smcl}
{* *! version 1.0.1  15oct2015}{...}
{cmd:help stpm2grp}
{hline}


{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{hi:stpm2grp} {hline 2}}Compute population-averaged survival probabilities from a Royston-Parmar model{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{cmd:stpm2grp}
{ifin}
[{cmd:,}
{it:options}]


{synoptset 24}{...}
{marker stpm2grp_options}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt by(by_varlist)}}stratify results by variables in {it:by_varlist}{p_end}
{synopt :{opt km(km_stub)}}store Kaplan-Meier estimates of survival probabilities in new variables {it:km_stub}*{p_end}
{synopt :{opt mean(mean_stub)}}store model-based estimates of mean survival probabilities in new variables {it:mean_stub}*{p_end}
{synopt :{opt t:imevar(varname)}}times at which to estimate observed and predicted survival probabilities{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:stpm2grp} calculates population-averaged survival curves. A predicted
survival curve is obtained for each subject in the dataset. The survival
curves are averaged wthin subsamples defined by {it:by_varlist}, or across
the entire dataset if {opt by()} is not specified.

{pstd}
Survival curves are predicted from the Royston-Parmar (RP) model most
recently fitted using {help stpm2}. The model must have exactly one
covariate. Typically (but not necessarily) the covariate is the prognostic
index from a multivariable RP model fitted earlier, whose calibration is to
be examined.

{pstd}
If the optional variable {it:timevar} is supplied, survival functions are
calculated for the time-to-event values in {it:timevar}. This feature
conveniently provides 'out of sample' prediction of mean survival
probabilities at user-specified time points.

{pstd}
Note that the population-averaged survival curve differs from the survival
curve predicted at the mean of the covariates in the model.

{pstd}
Note also that {cmd:stpm2grp} does not support Royston-Parmar models with
time-dependent effects of the covariate.

{pstd}
Related techniques for external validation of Cox models are described by
Royston and Altman (2014). A program for Cox models closely related to
{cmd:stpm2grp} is described by Royston (2015).


{title:Options}

{phang}
{opt by(by_varlist)} provides estimates for subsets representing
all possible combinations of values of variables in {it:by_varlist}.

{phang}
{opt km(km_stub)} stores Kaplan-Meier estimates of survival probabilities
in new variables called {it:km_stub}{cmd:1}, {it:km_stub}{cmd:2}, ....
Also, lower and upper bounds of 95% confidence intervals are stored in
variables {it:km_stub}{cmd:_lb1}, {it:km_stub}{cmd:lb2}, ... and
{it:km_stub}{cmd:_ub1}, {it:km_stub}{cmd:ub2}, respectively.
The numbering 1, 2, ... corresponds to the enumeration of subsets defined
by {it:by_varlist}, or is 1 if the {cmd:by()} option has not been used.

{phang}
{opt mean(mean_stub)} is not optional. It stores RP model-based estimates of
population-averaged survival probabilities in new variables called
{it:mean_stub}{cmd:1}, {it:mean_stub}{cmd:2}, .... The numbering
1, 2, ... corresponds to the enumeration of subsets defined by
{it:by_varlist}, or is 1 if the {cmd:by()} option has not been used.

{phang}
{opt timevar(varname)} defines times at which observed and predicted
survival probabilities are to be estimated. Default {it:varname} is {cmd:_t}.


{title:Examples}

{phang}
Use and {cmd:stset} the German breast cancer dataset:

{phang}{cmd:. webuse brcancer, clear}{p_end}
{phang}{cmd:. stset rectime, failure(censrec) scale(365.24)}{p_end}

{pstd}
A simple example on a single dataset, comparing predicted and Kaplan-Meier
survival curves for a Cox model including only the variable {cmd:x4}
(tumor grade). Plot the population-averaged and Kaplan-Meier survival curves
for the model with x4 fit as a factor variable against {cmd:_t}:

{phang}{cmd:. stpm2 i.x4, df(3) scale(hazard)}{p_end}
{phang}{cmd:. predict xb, xbnobaseline}{p_end}
{phang}{cmd:. stpm2 xb, df(3) scale(hazard)}{p_end}
{phang}{cmd:. range t 0 6 13}{p_end}
{phang}{cmd:. stpm2grp xb t, mean(m) km(k) by(x4)}{p_end}
{phang}{cmd:. line m1 m2 m3 k1 k2 k3 _t, sort lpattern(l l l - ..) connect(l l l J ..)}{p_end}

{pstd}
The pattern of survival curves suggests non-proportional hazards may be present
for {cmd:x4}.

{pstd}
A second example on the same dataset, examining predictions within 
subgroups defined by cut-points placed on a multivariable prognostic index.
The model is based on fractional polynomial transformations of the covariates:

{phang}{cmd:. fracpoly: stpm2 x1 -2 -0.5 x4a x5e x6 0.5 hormon, df(3) scale(hazard)}{p_end}
{phang}{cmd:. predict xb, xbnobaseline}{p_end}
{phang}{cmd:. xtile group = xb, nquantiles(3)}{p_end}
{phang}{cmd:. stpm2 xb, df(3) scale(hazard)}{p_end}
{phang}{cmd:. stpm2grp, mean(s) by(group) km(km)}{p_end}
{phang}{cmd:. line s1 km1 km_lb1 km_ub1 s2 km2 km_lb2 km_ub2 s3 km3 km_lb3 km_ub3 _t, sort connect(l J J J l J J J l J J J) lpattern(l - - - l - - - l - - -) legend(off)}{p_end}


{title:Author}

{phang}Patrick Royston{p_end}
{phang}MRC Clinical Trials Unit at UCL{p_end}
{phang}London, UK{p_end}
{phang}j.royston@ucl.ac.uk{p_end}


{title:References}

{phang}Royston, P., and D. G. Altman. 2013. External validation of a Cox
prognostic model: principles and methods. {it:BMC Medical Research Methodology},
{bf:13}:33.

{phang}Royston, P. 2015. Tools for checking calibration of a Cox model in
external validation: Prediction of population-averaged survival curves based
on risk groups. {it:Stata  Journal}, 15(1): 275-291.


{title:Also see}

{psee}
Manual:  {hi:[R] fracpoly}, {hi:[R] fp}, {hi:[R] stcox}{p_end}

{psee}
Online:  {helpb fracpoly}, {helpb fp}, {helpb stcox}, {helpb stpm2}, {helpb stcoxgrp} (if installed){p_end}
