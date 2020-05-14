{smcl}
{* *! version 1.0.0 PR 30nov2015}{...}
{cmd:help stpm2cal}{right: Patrick Royston}
{hline}


{title:Title}

{p2colset 5 17 20 2}{...}
{p2col :{hi:stpm2cal} {hline 2}}Calibration plots and tests for Royston-Parmar models{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 12 2}
{cmd:stpm2cal} [if] [in], {it:options} [ {it:running_options graph_twoway_options} ]


{synoptset 20}{...}
{marker stpm2cal_options}{...}
{synopthdr :options}
{synoptline}
{synopt :{opt ti:mes(# [# ...])}}(required) time-points at which to assess calibration{p_end}
{synopt :{opt add:cons(#)}}recalibrate predictions by adding {it:#} to the linear predictor{p_end}
{synopt :{opt nogr:aph}}suppress graph{p_end}
{synopt :{opt res:iduals}}plot smoothed residuals (observed minus predicted event probabilities){p_end}
{synopt :{opt sav:ing(filename)}}save created variables to file {it:filename}{p_end}
{synopt :{opt test}}test the overall calibration slope and factorial interaction of calibration slope with time{p_end}
{synopt :{opt tr:end}}test the overall calibration slope and linear interaction of calibration slope with integer scores for time{p_end}
{synopt :{opt val(exp)}}evaluate calibration in independent data indicated by {cmd:(}{it:exp}{cmd:)} ~= 0{p_end}
{synopt :{it:graph_twoway_options}}options for {cmd:graph twoway}{p_end}
{synopt :{it:running_options}}options for {cmd:running}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
You must have installed {cmd:stpm2}, {cmd:running} and {cmd:stpsurv} before
using {cmd:stpm2cal}. {cmd:stpm2} and {cmd:running} are available from
the Statistical Software Components (SSC) archive, see help {helpb ssc}.
{cmd:stpsurv} can be installed from the Stata Journal archive via the command
{cmd:net install st0202_1}.


{title:Description}

{pstd}
{cmd:stpm2cal} is a tool for examining the time-dependent calibration of
a Royston-Parmar (flexible parametric) model whose predicted
event probabilities are used to assess the adequacy of the model in a
dataset defined by the {ifin} filter. The dataset could be the one used
to derive the model or an independent one to be used for external validation.

{pstd}
A 'well-calibrated' model is one which accurately predicts survival or event
probabilities at all relevant follow-up times. A model which includes
covariates whose effects change (e.g. dwindle) over time may show poor
calibration. Such a model will give more or less biased prediction of
survival probabilities. {cmd:stpm2cal} is designed to detect and display
lack of calibration graphically. It also includes tests of good calibration
and of time-dependent trends of miscalibration - see Royston (2014)
for further information in the context of the Cox model. The concepts and
interpretation are identical to the Cox case.


{title:Options}

{phang}
{opt times(numlist)} is not optional. {it:numlist} is a list of times at
which model calibration is to be assessed.

{phang}
{opt addcons(#)} adds {it:#} to the linear predictor from the Royston-Parmar
model. This is a way of assessing whether '(re)calibration in the large' can
compensate adequately for a miscalibrated model.

{phang}
{opt nograph} suppresses the production of calibration plots.

{phang}
{opt residuals} plots the smoothed residuals (difference between observed
and predicted event probabilities) against the predicted event probabilities.
The default is to plot smoothed observed against predicted event
probabilities.

{phang}
{opt saving(filename)} saves five variables in the validation dataset
to file {it:filename}:

        {cmd:_id}    observation number in the original data
        {cmd:_times} integer scores (levels) 1, 2, ... of times specified in {opt times()}
        {cmd:_f}     pseudo-values for event probabilities
        {cmd:_F}     event probabilities predicted from Royston-Parmar model
        {cmd:_clogF} complementary log-log transformation of {cmd:_F}
    
{pmore}
These variables can be used by an expert to create their own plots
and further analyse model calibration. The data are held in long
format, with a complete set of values for each level of {cmd:_times}.

{phang}
{opt test} tests whether the slope (on the log cumulative hazard scale)
of the regression of pseudo-values for event probabilities on predicted
event probabilities over all time-points in {opt times()} equals 1. A 
on-significant P-value suggests good overall calibration, sometimes called
'calibration in the large'. {opt test} also provides a test of interaction
between the slopes and the times specified in {opt times()}. A significant
P-value suggests that calibration changes over time. Typically it gets
worse as follow-up time increases.

{phang}
{opt trend} tests whether the slope (on the scale of the Royston-Parmar
model) of the regression of pseudo-values for event probabilities on predicted
event probabilities over all time-points in {opt times()} equals 1
(same as for {opt test}). {opt trend} also provides a test of linear
interaction between the slopes and the integer scores for the times
specified in {opt times()}. This may be more powerful than the interaction
test provided by {opt test}.

{phang}
{it:graph_twoway_options} are options of {cmd:graph twoway}. These may
be used to customise the appearance of the calibration plots.

{phang}
{it:running_options} are options of {cmd:running}. These may be
used to customise the smoothing of pseudo-values. The most relevant
option is likely to be {opt span(#)}. See help {helpb running} for further
information.


{title:Examples}

{phang}{stata ". webuse brcancer, clear"}{p_end}
{phang}{stata ". stset rectime, failure(censrec) scale(365.24)"}{p_end}
{phang}{stata ". fp generate x1^(-2 -0.5)"}{p_end}
{phang}{stata ". fp generate x6^(0.5), scale"}{p_end}
{phang}{stata ". stpm2 x1_1 x1_2 x4a x4b x5e x6_1 hormon, df(3) scale(hazard)"}{p_end}
{phang}{stata ". stpm2cal, times(1(1)6) test"}{p_end}
{phang}{stata ". stpm2cal, times(1(1)6) trend"}{p_end}

{phang}{stata ". set seed 3143"}{p_end}
{phang}{stata ". gen byte random_half = (runiform() < 0.5)"}{p_end}
{phang}{stata ". stpm2 x1_1 x1_2 x4a x4b x5e x6_1 hormon if random_half==0, df(3) scale(h)"}{p_end}
{phang}{stata ". stpm2cal if random_half==1, times(1(1)6) test"}{p_end}


{title:Stored quantities}

{cmd:stpm2cal} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(gamma1)}}Estimate of gamma1 with gamma0 also estimated{p_end}
{synopt:{cmd:r(gamma1_se)}}s.e. of gamma1{p_end}
{synopt:{cmd:r(P0)}}P-value for test 1, of gamma0 = 0 given gamma1 = 1{p_end}
{synopt:{cmd:r(P1)}}P-value for test 2, of gamma1 = 1 with gamma0 estimated{p_end}
{synopt:{cmd:r(P01)}}P-value for test 3, joint test of (gamma0, gamma1) = (0, 1){p_end}
{synopt:{cmd:r(Pint)}}P-value for test 4, of interaction of gamma1 with time{p_end}
{p2colreset}{...}
 

{title:Author}

{phang}Patrick Royston{p_end}
{phang}MRC Clinical Trials Unit at UCL{p_end}
{phang}London, UK{p_end}
{phang}j.royston@ucl.ac.uk{p_end}


{title:References}

{phang}
P. Royston. 2014. Tools for checking calibration of a Cox model in
external validation: Approach based on individual event probabilities.
{bf:Stata Journal}, 14(4): 738-755.


{title:Also see}

{psee}
Online:  {helpb running}, {helpb stpsurv}, {helpb stpm2}{p_end}
