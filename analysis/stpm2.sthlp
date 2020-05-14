{smcl}
{* *! version 1.2.2 27jul2009}{...}
{cmd:help stpm2} {right: ({browse "http://www.stata-journal.com/article.html?article=st0165":SJ9-2: st0165})}
{hline}

{title:Title}

{p2colset 5 14 16 2}{...}
{p2col :{hi:stpm2} {hline 2}}Flexible parametric survival models{p_end}
{p2colreset}{...}


{title:Syntax}


{p 8 16 2}{cmd:stpm2} [{varlist}] {ifin}, {opt sc:ale(scalename)} [{it:options}]


{marker options}{...}
{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt scale(scalename)}}specify scale on which survival model is to be fit{p_end}
{synopt :{opt df(#)}}specify degrees of freedom for baseline hazard function{p_end}
{synopt :{opt knots(numlist)}}specify knot locations for baseline hazard{p_end}
{synopt :{opt tvc(varlist)}}specify varlist of time-dependent effects{p_end}
{synopt :{opt dft:vc(df_list)}}specify degrees of freedom for each time-dependent effect{p_end}
{synopt :{opt knotst:vc(numlist)}}specify knot locations for time-dependent effects{p_end}
{synopt :{opt knscale(scale)}}specify scale for user-defined knots; default scale is {cmd:time}){p_end}
{synopt :{opt bk:nots(knotslist)}}specify boundary knots{p_end}
{synopt :{opt noorth:og}}do not use orthogonal transformation of spline variables{p_end}
{synopt :{opt bhaz:ard(varname)}}invoke relative survival models where {it:varname} holds expected mortality rate (hazard) at time of death{p_end}
{synopt :{opt nocons:tant}}suppress constant term{p_end}
{synopt :{opt st:ratify(varlist)}}for backward compatibility with {cmd:stpm}{p_end}
{synopt :{cmdab:th:eta(}{cmd:est}|{it:#}{cmd:)}}for backward compatibility with {cmd:stpm}{p_end}

{syntab:Reporting}
{synopt :{opt alleq}}report all equations used by {cmd:ml}{p_end}
{synopt :{opt ef:orm}}report exponentiated coefficients{p_end}
{synopt :{opt keepc:ons}}do not drop constraints used in {cmd:ml} routine{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt showc:ons}}list constraints in output{p_end}

{syntab:Max options}
{synopt :{opt const:heta(#)}}constrain value of theta{p_end}
{synopt :{opt initt:heta(#)}}specify initial value of theta{p_end}
{synopt :{opt lin:init}}obtain initial values by first fitting a linear function of ln(time); seldom used{p_end}
{synopt :{it:{help streg##maximize_options:maximize_options}}}control maximization process; seldom used{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {cmd:stset} your data before using {cmd:stpm2}; see {manhelp stset ST}.{p_end}


{title:Description}

{pstd}
{cmd:stpm2} fits flexible parametric survival models (Royston-Parmar models). {cmd:stpm2} 
can be used with single- or multiple-record or single- or multiple-failure {cmd:st} data.
Survival models can be fit on the log cumulative hazard scale, the log cumulative
odds scale, the standard normal deviate (probit) scale, or on a scale defined by the
value of theta using the Aranda-Ordaz family of link functions.

{pstd}
{cmd:stpm2} can fit the same models as can {cmd:stpm}, but {cmd:stpm2} is more flexible in that it does
not force the knots for time-dependent effects to be the same as those used
for the baseline distribution function. Also, {cmd:stpm2} can fit relative survival
models by use of the {cmd:bhazard()} option. Postestimation commands have been extended
over what is available in {cmd:stpm}. {cmd:stpm2} is noticeably faster than {cmd:stpm}.

{pstd}
See {manhelp streg ST} for other (standard) parametric survival models.


{title:Options}

{dlgtab:Model}

{phang}
{opt scale(scalename)} specifies on which scale the survival model is to be
fit.

{pmore}
{cmd:scale({ul:h}azard)} fits a model on the log cumulative hazard scale,
i.e., the scale of ln[-ln{S(t)}]. If no time-dependent effects are specified,
the resulting model has proportional hazards.

{pmore}
{cmd:scale({ul:o}dds)} fits a model on the log cumulative odds scale,
i.e., ln[{1 - S(t)}/S(t)]. If no time-dependent effects
are specified, then this is a proportional-odds model.

{pmore}
{cmd:scale({ul:n}ormal)} fits a model on the normal equivalent deviate
scale, i.e., a probit link for the survival function invnorm{1 - S(t)}.

{pmore}
{cmd:scale({ul:t}heta)} fits a model on a scale defined by the value of theta
for the Aranda-Ordaz family of link functions, i.e.,
ln[{S(t)^(-theta) - 1}/theta]. theta = 1 corresponds to a
proportional-odds model, and theta = 0 corresponds to a proportional
cumulative-hazard model.

{phang} {opt df(#)} specifies the degrees of freedom (df) for the restricted cubic
spline function used for the baseline hazard rate. {it:#} must be between 1
and 10, but a value between 1 and 5 is usually sufficient.
The {cmd:knots()} option is not applicable if the {cmd:df()}
option is specified. The knots are placed at the following centiles of the
distribution of the uncensored log survival times:

        {hline 60}
        df  knots  Centile positions
        {hline 60}
         1    0    (no knots)
         2    1    50
         3    2    33 67
         4    3    25 50 75
         5    4    20 40 60 80
         6    5    17 33 50 67 83
         7    6    14 29 43 57 71 86
         8    7    12.5 25 37.5 50 62.5 75 87.5
         9    8    11.1 22.2 33.3 44.4 55.6 66.7 77.8 88.9
        10    9    10 20 30 40 50 60 70 80 90
        {hline 60}

{pmore}
These are internal knots and there are also boundary knots
placed at the minimum and maximum of the distribution of uncensored survival
times.

{phang}
{opt knots(numlist)} specifies knot locations for the baseline distribution
function, as opposed to the default locations set by {cmd:df()}. The locations of the knots are placed on the scale defined by {cmd:knscale()}.
However, the scale used by the restricted cubic spline function is always
log time. Default knot positions are determined by the {opt df()} option.

{phang}
{opt tvc(varlist)} specifies the names of the variables that are time dependent.
Time-dependent effects are fit using restricted cubic splines.
The df is specified using the {opt dftvc()} option.

{phang} {opt dftvc(df_list)} specifies the df for time-dependent
effects. The potential df is between 1 and 10. With 1 df, a linear effect of log time is fit.  If there is more than one
time-dependent effect and a different df is required for each
time-dependent effect, then the following syntax can be used:
{cmd:dftvc(x1:3 x2:2 1)}, where {cmd:x1} has 3 df, {cmd:x2} has 2 df, and any
remaining time-dependent effects have 1 df.

{phang} {opt knotstvc(numlist)} specifies the location of the internal knots for
any time-dependent effects. If different knots are required for different
time-dependent effects, then this option can be specified as follows:
{cmd:knotstvc(x1 1 2 3 x2 1.5 3.5)}.

{phang} {opt knscale(scale)} sets the scale on which user-defined knots are
specified.  {cmd:knscale(time)} denotes the original time scale,
{cmd:knscale(log)} denotes the log time scale, and {cmd:knscale(centile)}
specifies that the knots are taken to be centile positions in the distribution
of the uncensored log survival times.  The default is {cmd:knscale(time)}.  The default is {cmd:knscale(time)}.

{phang}
{opt bknots(knotslist)} is a two-element list giving
the boundary knots. By default, these are located at the minimum and maximum
of the uncensored survival times. They are specified on the scale defined
by {cmd:knscale()}.

{phang}
{cmd: noorthog} suppresses orthogonal transformation of spline variables.

{phang} {opt bhazard(varname)} is used when fitting relative survival models.
{it:varname} gives the expected mortality rate at the time of death or censoring.
{cmd:stpm2} gives an error message when there are missing values of
{it:varname}, because this usually indicates that an error has occurred when
merging the expected mortality rates.

{phang}
{opt noconstant};
see {helpb st estimation options##noconstant:[R] estimation options}.

{phang}
{opt stratify(varlist)} is provided for backward compatibility with {helpb stpm}.
Members of {it:varlist} are modeled with time-dependent effects. See
the {opt tvc()} and {opt dftvc()} options for {cmd:stpm2}'s way of
specifying time-dependent effects.

{phang}
{cmd:theta(}{cmd:est}|{it:#}{cmd:)} is provided for backward compatibility with
{helpb stpm}. {cmd:est} requests that theta be estimated, whereas {it:#}
fixes theta to {it:#}. See {opt constheta()} and {opt inittheta()} for
{cmd:stpm2}'s way of specifying theta.


{dlgtab:Reporting}

{phang}
{opt alleq} reports all equations used by {cmd:ml}. The models are fit using
various constraints for parameters associated with the derivatives of the
spline functions. These parameters are generally not of interest and thus
are not shown by default. Also, an extra equation is used when fitting
delayed-entry models; again, this is not shown by default.

{phang}
{opt eform} reports the exponentiated coefficients. For models on the log
cumulative-hazard scale, {cmd:scale(hazard)}, this gives hazard ratios if
the covariate is not time dependent. Similarly, for models on the log
cumulative-odds scale, {cmd:scale(odds)}, this option will give odds ratios
for non-time-dependent effects.

{phang}
{opt keepcons} prevents the constraints imposed by {cmd:stpm2} on the
derivatives of the spline function when fitting delayed-entry models from
being dropped. By default, the constraints are dropped.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence
intervals.  The default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt showcons} lists the output the constraints used by {cmd:stpm2} for the derivatives of the spline function and when fitting delayed-entry models; the default is to not list them. 

{marker maximize_options}{...}
{dlgtab:Max options}
 
{phang}
{opt constheta(#)} constrains the value of theta; i.e., it is treated as a known
constant.

{phang}
{opt inittheta(#)} specifies an initial value for theta in the Aranda-Ordaz
family of link functions.

{phang}
{opt lininit} obtains initial values by fitting only the first spline
basis function (i.e., a linear function of log survival time).
This option is seldom needed.

{phang}
{it:maximize_options}: {opt dif:ficult}, {opt tech:nique(algorithm_spec)}, 
{opt iter:ate(#)}, [{cmdab:no:}]{opt lo:g}, {opt tr:ace}, {opt grad:ient}, 
{opt showstep}, {opt hess:ian}, {opt shownr:tolerance}, {opt tol:erance(#)}, 
{opt ltol:erance(#)}, {opt gtol:erance(#)}, {opt nrtol:erance(#)}, 
{opt nonrtol:erance}, {opt from(init_specs)}; see {manhelp maximize R}.  These 
options are seldom used, but the {opt difficult} option may be useful if there
are convergence problems when fitting models that use the Aranda-Ordaz family of link
functions.


{title:Remarks}

{pstd}
Let t denote time. {cmd:stpm2} works by first calculating the survival function
after fitting a Cox proportional hazards model. The procedure is
illustrated for proportional hazards models, specified by the
{cmd:scale(hazard)} option. S(t) is converted to an estimate of the log cumulative hazard
function, Z(t), by the formula

{pin}
	Z(t) = ln[-ln{S(t)}]

{pstd}
This estimate of Z(t) is then smoothed on ln(t) by using regression splines with
knots placed at certain quantiles of the distribution of t. The knot positions
are chosen automatically if the spline complexity is specified by the {cmd:df()}
option, or manually by way of the {cmd:knots()} option. (The knots
are placed on values of ln(t), not t.) Denote the predicted values of the log cumulative
hazard function by Z_hat(t). The density function, f(t), is

{pin}
	f(t) = -dS(t)/dt = dS/dZ_hat dZ_hat/dt = S(t) exp(Z_hat) dZ_hat(t)/dt

{pstd}
dZ_hat(t)/dt is computed from the regression coefficients of the fitted spline
function. The estimated survival function is calculated as

{pin}
	S_hat(t) = exp{-exp Z_hat(t)}

{pstd}
The hazard function is calculated as f(t)/S_hat(t).

{pstd}
If {it:varlist} is specified, the baseline survival function (i.e., at zero values
of the covariates) is used instead of the survival function of the raw
observations. With {cmd:df(1)}, a Weibull model is fit.

{pstd}
With {cmd:scale(normal)}, smoothing is of the normal quantile function,
invnorm{1 - S(t)}, instead of the log cumulative-hazard function. With
{cmd:df(1)}, a lognormal model is fit.

{pstd}
With {cmd:scale(odds)}, smoothing is of the log odds-of-failure function,
ln[{1 - S(t)}/S(t)], instead of the log cumulative-hazard function. With
{cmd:df(1)}, a loglogistic model is fit.

{pstd}
Estimation is performed by maximum likelihood. Optimization uses the
default technique, {cmd:nr} (meaning Stata's version of Newton-Raphson
iteration).


{title:Examples}

{pstd}Setup{p_end}

{phang2}{stata "webuse brcancer"}{p_end}
{phang2}{stata "stset rectime, failure(censrec = 1)"}{p_end}

{pstd}Proportional hazards model{p_end}

{phang2}{stata "stpm2 hormon, scale(hazard) df(4) eform"}{p_end}

{pstd}Proportional odds model{p_end}

{phang2}{stata "stpm2 hormon, scale(odds) df(4) eform"}{p_end}

{pstd}Time-dependent effects on cumulative hazard scale{p_end}

{phang2}{stata "stpm2 hormon, scale(hazard) df(4) tvc(hormon) dftvc(3)"}{p_end}

{pstd}User-defined knots at centiles of uncensored event times{p_end}

{phang2}{stata "stpm2 hormon, scale(hazard)  knots(20 50 80) knscale(centile)"}{p_end}


{title:Author}

{pstd}Paul C. Lambert{p_end}
{pstd}Centre for Biostatistics and Genetic Epidemiology{p_end}
{pstd}Department of Health Sciences{p_end}
{pstd}University of Leicester, UK{p_end}
{pstd}paul.lambert@le.ac.uk{p_end}


{title:Also see}

{psee}
Article: {it:Stata Journal}, volume 9, number 2: {browse "http://www.stata-journal.com/article.html?article=st0165":st0165}

{psee}
Online:  {helpb stpm2_postestimation}; {manhelp stset ST}, {helpb stpm} (if
installed)
{p_end}
