{smcl}
{* *! version 1.2 17mar2009}{...}
{cmd:help stpm2 postestimation} {right: ({browse "http://www.stata-journal.com/article.html?article=st0165":SJ9-2: st0165})}
{hline}

{title:Title}

{p2colset 5 29 31 2}{...}
{p2col :{hi:stpm2 postestimation} {hline 2}}Postestimation tools for stpm2{p_end}
{p2colreset}{...}


{title:Description}

{pstd}
The following standard postestimation commands are available after
{cmd:stpm2}:

{synoptset 13}{...}
{p2coldent :command}description{p_end}
{synoptline}
INCLUDE help post_adjust2
INCLUDE help post_estat
INCLUDE help post_estimates
INCLUDE help post_lincom
INCLUDE help post_lrtest
INCLUDE help post_nlcom
{p2col :{helpb stpm2 postestimation##predict:predict}}predictions, residuals, influence statistics, and other diagnostic measures{p_end}
INCLUDE help post_predictnl
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{marker predict}{...}
{title:Syntax for predict}


{p 8 16 2}
{cmd:predict} {newvar} {ifin} [{cmd:,} {it:statistic} ]

{synoptset 40 tabbed}{...}
{synopthdr :statistic}
{synoptline}
{syntab:Main}
{synopt :{cmd:at(}{it:varname #} [{it:varname #} ...]{cmd:)}}predict at values of specified covariates{p_end}
{synopt :{opt cen:tile(#|varname)}}request {it:#}th centile of survival distribution{p_end}
{synopt :{opt ci}}calculate confidence interval{p_end}
{synopt :{opt cumh:azard}}predict cumulative hazard{p_end}
{synopt :{opt cumo:dds}}predict cumulative odds{p_end}
{synopt :{opt dens:ity}}predict density function{p_end}
{synopt :{opt h:azard}}predict hazard function{p_end}
{synopt :{cmd:hdiff1(}{it:varname #} [{it:varname #} ...]{cmd:)}}predict first hazard function for
difference in hazard functions{p_end}
{synopt :{cmd:hdiff2(}{it:varname #} [{it:varname #} ...]{cmd:)}}predict second hazard function for
difference in hazard functions{p_end}
{synopt :{cmdab:hrd:enominator(}{it:varname #} [{it:varname #} ...]{cmd:)}}specify denominator for
(time-dependent) hazard ratio{p_end}
{synopt :{cmdab:hrn:umerator(}{it:varname #} [{it:varname #} ...]{cmd:)}}specify numerator for (time-dependent) hazard ratio{p_end}
{synopt :{opt mart:ingale}}calculate martingale residuals{p_end}
{synopt :{opt means:urv}}calculate population-averaged survival function{p_end}
{synopt :{opt nor:mal}}predict standard normal deviate of survival function{p_end}
{synopt :{cmd:sdiff1(}{it:varname #} [{it:varname #} ...]{cmd:)}}predict first survival curve for difference in survival functions{p_end}
{synopt :{cmd:sdiff2(}{it:varname #} [{it:varname #} ...]{cmd:)}}predict second survival curve for difference in survival functions{p_end}
{synopt :{opt stdp}}calculate standard error of predicted function{p_end}
{synopt :{opt s:urvival}}predict survival function{p_end}
{synopt :{opt time:var(varname)}}define time variable used for predictions (default is {cmd:timevar(_t)}){p_end}
{synopt :{opt xb}}predict the linear predictor{p_end}
{synopt :{opt xbnob:aseline}}predict the linear predictor, excluding the spline function{p_end}
{synopt :{opt zero:s}}set all covariates to zero (baseline prediction){p_end}

{syntab:Subsidiary}
{synopt :{opt centol(#)}}define tolerance level when estimating centile{p_end}
{synopt :{opt dev:iance}}calculate deviance residuals{p_end}
{synopt :{opt dxb}}calculate derivative of linear predictor{p_end}
{synopt :{opt lev:el(#)}}set confidence level{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2} 
Statistics are available both in and out of sample; type
{cmd:predict} {it:...} {cmd:if e(sample)} {it:...} if wanted only for the
estimation sample.{p_end}
{p 4 6 2} 


{title:Options for predict}

{pstd}
If a relative survival model has been fit by use of the
{cmd:bhazard()} option, then survival refers to relative
survival and hazard refers to excess hazard.

{dlgtab:Main}

{phang}
{cmd:at(}{it:varname #} [{it:varname #} ...]{cmd:)} requests that the covariates
specified by {it:varname} be set to {it:#}. This is a useful way to
obtain out-of-sample predictions. If {opt at()} is used together with 
{opt zeros}, then all covariates not listed in {opt at()} are set to zero. If
{opt at()} is used without {opt zeros}, then all covariates not listed in 
{opt at()} are set to their sample values. Also see {opt zeros}.

{phang}
{opt centile(#|varname)} requests the {it:#}th centile of the survival-time
distribution, calculated using the Newton-Raphson algorithm (or requests the
centiles stored in {it:varname}).

{phang}
{opt ci} calculates a confidence interval for the requested statistic and
stores the confidence limits in {it:newvar}{cmd:_lci} and
{it:newvar}{cmd:_uci}.

{phang}
{opt cumhazard} predicts the cumulative hazard function.

{phang}
{opt cumodds} predicts the cumulative odds-of-failure function.

{phang}
{opt density} predicts the density function.

{phang}
{opt hazard} predicts the hazard rate (or excess hazard rate if {cmd:stpm2}'s {cmd:bhazard()} option was used).

{phang}
{cmd:hdiff1(}{it:varname #} [{it:varname #} ...]{cmd:)} and {cmd:hdiff2(}{it:varname #} [{it:varname #} ...]{cmd:)} predict
the difference in hazard functions, with the first hazard function defined
by the covariate values listed for {opt hdiff1()} and the second, by
those listed for {opt hdiff2()}. By default, covariates not specified
using either option are set to zero. Setting the remaining values
of the covariates to zero may not always be sensible. If {it:#} is set to
missing ({cmd:.}), then {it:varname} has the values defined in the dataset.

{pmore}
Example: {cmd:hdiff1(hormon 1)} (without specifying {cmd:hdiff2()})
computes the difference in predicted hazard functions at {cmd:hormon}
= 1 compared with {cmd:hormon} = 0.

{pmore}
Example: {cmd:hdiff1(hormon 2) hdiff2(hormon 1)} computes the difference in
predicted hazard functions at {cmd:hormon} = 2 compared with {cmd:hormon} = 1.

{pmore}
Example: {cmd:hdiff1(hormon 2 age 50) hdiff2(hormon 1 age 30)}
computes the difference in predicted hazard functions at
{cmd:hormon} = 2 and {cmd:age} = 50 compared with {cmd:hormon} = 1
and {cmd:age} = 30.

{phang}
{cmd:hrdenominator(}{it:varname #} [{it:varname #} ...]{cmd:)} specifies the denominator of the hazard
ratio. By default, all covariates not specified using this option are set to zero. See the cautionary note in {opt hrnumerator()} below.
If {it:#} is set to missing ({cmd:.}), then {it:varname} has the values
defined 
in the dataset.

{phang}
{cmd:hrnumerator(}{it:varname #} [{it:varname #} ...]{cmd:)} specifies the
numerator of the  (time-dependent) hazard ratio. By default, all covariates
not specified using this option are set to zero. Setting the
remaining values of the covariates to zero may not always be sensible,
particularly with models other than those on the cumulative hazard scale, or when
more than one variable has a time-dependent effect. If {it:#} is set to missing
({cmd:.}), then {it:varname} has the values defined in the dataset.

{phang}
{opt martingale} calculates martingale residuals.

{phang}
{opt meansurv} calculates the population-averaged survival curve. This
differs from the predicted survival curve at the mean of all the covariates
in the model. A predicted survival curve is obtained for each subject, and all
the survival curves in a population are averaged. The process can be computationally intensive.
It is recommended that the {opt timevar()} option be used to reduce the number
of survival times at which the survival curves are averaged. Combining
{cmd:meansurv} with the {cmd:at()} option enables adjusted survival curves to be
estimated.

{phang}
{opt normal} predicts the standard normal deviate of the survival function.

{phang}
{cmd:sdiff1(}{it:varname #} [{it:varname #} ...]{cmd:)} and {cmd:sdiff2(}{it:varname #} [{it:varname #} ...]{cmd:)} predict
the difference in survival curves, with the first survival curve defined
by the covariate values listed for {opt sdiff1()} and the second, by
those listed for {opt sdiff2()}. By default, covariates not specified
using either option are set to zero. Setting the remaining values
of the covariates to zero may not always be sensible. If {it:#} is set to
missing ({cmd:.}), then {it:varname} has the values defined in the dataset.

{pmore}
Example: {cmd:sdiff1(hormon 1)} (without specifying {cmd:sdiff2()})
computes the difference in predicted survival curves at {cmd:hormon}
= 1 compared with {cmd:hormon} = 0.

{pmore}
Example: {cmd:sdiff1(hormon 2) sdiff2(hormon 1)} computes the difference in
predicted survival curves at {cmd:hormon} = 2 compared with {cmd:hormon} = 1.

{pmore}
Example: {cmd:sdiff1(hormon 2 age 50) sdiff2(hormon 1 age 30)}
computes the difference in predicted survival curves at
{cmd:hormon} = 2 and {cmd:age} = 50 compared with {cmd:hormon} = 1
and {cmd:age} = 30.

{phang}
{opt stdp} calculates the standard error of prediction and stores it in
{newvar}{cmd:_se}. {cmd:stdp} is available only with the {cmd:xb} and {cmd:dxb} options.

{phang}
{opt survival} predicts survival time (or relative survival if
the {cmd:bhazard()} option was used).

{phang}
{opt timevar(varname)} defines the variable used as time in the predictions.
The default is {cmd:timevar(_t)}. This is useful for large datasets where, 
for plotting purposes, predictions are needed for only 200 observations, for example. 
Some caution should be taken when using this option because predictions may be 
made at whatever covariate values are in the first 200 rows of data. This can be avoided by using the
{cmd:at()} option or the {cmd:zeros} option to define the covariate patterns for which you require
the predictions.

{phang}
{opt xb} predicts the linear predictor, including the spline function.

{phang}
{opt xbnobaseline} predicts the linear predictor, excluding the spline
function, i.e., only the time-fixed part of the model.

{phang}
{opt zeros} sets all covariates to zero (baseline prediction). For 
example, {cmd:predict s0, survival zeros} calculates the baseline
survival function. Also see {opt at()}.

{dlgtab:Subsidiary}

{phang}
{opt centol(#)} defines the  tolerance when searching for the predicted
survival time at a given centile of the survival distribution. The default is
{cmd:centol(0.0001)}.

{phang}
{opt deviance} calculates deviance residuals.

{phang}
{opt dxb} calculates the derivative of the linear predictor.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence
intervals. The default is {cmd:level(95)}
or as set by {helpb set level}.


{title:Examples}

{pstd}Setup{p_end}

{phang2}{stata "webuse brcancer"}{p_end}
{phang2}{stata "stset rectime, failure(censrec = 1)"}{p_end}

{pstd}Proportional hazards model{p_end}

{phang2}{stata "stpm2 hormon, scale(hazard) df(4) eform"}{p_end}
{phang2}{stata "predict h, hazard ci"}{p_end}
{phang2}{stata "predict s, survival ci"}{p_end}

{pstd}Time-dependent effects on cumulative hazard scale{p_end}

{phang2}{stata "stpm2 hormon, scale(hazard) df(4) tvc(hormon) dftvc(3)"}{p_end}
{phang2}{stata "predict hr, hrnumerator(hormon 1) ci"}{p_end}
{phang2}{stata "predict survdiff, sdiff1(hormon 1) ci"}{p_end}
{phang2}{stata "predict hazarddiff, hdiff1(hormon 1) ci"}{p_end}


{pstd}Use of the {cmd:at()} option{p_end}

{phang2}{stata "stpm2 hormon x1, scale(hazard) df(4) tvc(hormon) dftvc(3)"}{p_end}
{phang2}{stata "predict s60h1, survival at(hormon 1 x1 60) ci"}{p_end}


{title:Also see}

{psee}
Article: {it:Stata Journal}, volume 9, number 2: {browse "http://www.stata-journal.com/article.html?article=st0165":st0165}

{psee}
Online:  {help stpm2} (if installed)
{p_end}
