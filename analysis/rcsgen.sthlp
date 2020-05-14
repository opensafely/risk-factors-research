{smcl}
{* 8Apr2013}{...}
{cmd:help rcsgen}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{hi: rcsgen} {hline 2}}Generate restricted cubic splines and derivatives{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:rcsgen }
{varname}
{ifin}
[{cmd:,} {it:{help rcsgen ##options:options}}]

{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Options}
{synopt :{opt g:en(stub)}}stubname for generated spline variables{p_end}
{synopt :{opt dg:en(stub)}}stubname for generated derivatives of spline variables{p_end}
{synopt :{opt k:nots(numlist)}}location of knots{p_end}
{synopt :{opt p:ercentiles(numlist)}}location of knots using percentiles{p_end}
{synopt :{opt df(#)}}degrees of freedom for knots{p_end}
{synopt :{opt bk:nots(numlist)}}location of boundary knots{p_end}
{synopt :{opt o:rthog}}orthogonalize generates spline variables{p_end}
{synopt :{opt rmat:rix(matname)}}use supplied matrix for orthogonalization{p_end}
{synopt :{opt if2(string)}}use extra condition when generating knots using {cmd:df} or {cmd:percentile} options{p_end}
{synopt :{opt fw(varname)}}name of variable containing weights when generating knots using the {cmd:df} or {cmd:percentile} options{p_end}
{synopt :{opt rev:erse}}derives the spline variables in reversed order{p_end}
{synopt :{opt sca:lar(#)}}a single value to calculate the spline basis for{p_end}
{synopt :{opt cent:er(#)}}a value to center the spline basis around{p_end}

	
{p 4 4 4}
One (and only one) of the {cmd:knots}, {cmd:percentiles} or {cmd:df} options should be specified. If they are not then only 1 variable is created which is a copy of {it:varname}.

{title:Description}

{pstd}
{cmd:rcsgen} generates basis functions for restricted cubic splines and (optionally) their derivatives. Restriced cubic spline
functions assume linearity beyond the two boundary knots. It is possible to specify knots on the original scale,
as default percentiles or user specified pecentiles. Orthogonalization can be peformed using Gram-Schmidt
orthogonalization. When orthogonalizing, a matrix is returned, which can be useful for regenerating the orthogonalized 	spline variables for 
out of sample predictions.

{title:Options}

{phang}
{opt gen(stub)} gives a stubname for the generated cubic splines variables. For example, {cmd:gen(rcs)} will create variable {it:rcs1, rcs2, ...}.

{phang}
{opt dgen(stub)} gives a stubname for the derivatives of the restricted cubic splines variables. For example, {cmd:dgen(drcs)} will create variable {it:drcs1, drcs2, ...}.

{phang}
{opt knots(numlist)} list of the location of the knots. The boundary knots are included in the {it: numlist}.

{phang}
{opt percentiles(numlist)} list of percentiles for the location of the knots. The boundary knots are included in the {it: numlist}.

{phang}
{opt df(#)}  sets the desired degrees of freedom (df). The number of knots is one less than the df. 
Knots are placed at equally spaced centiles of the distribution of {it:varname}. 
For example, for {cmd:df(5)} knots are placed at the 20th, 40th, 60th, 80th centiles of the distribution of {it:varname}. 
In addition boundary knots are placed at the maximum and minimum values of {it:varname} or those specified using the {cmd:bknots()} option.

{phang}
{opt bknots(numlist)} list of boundary knots when using the {cmd:df()} option. By default these are the minimum and maximum of the {it:varname}

{phang}
{opt orthog} will orthogonalize the generated spline variables using Gram-Schmidt orthogonalization.

{phang}
{opt rmatrix(matname)} will orthogonalize the generated spline variables using the supplied R matrix. If X is the N*p matrix of untransformed spline variables and Q is the N*(p+1) matrix of orthogonlized variables plus a column of ones, then X=QR.

{phang}
{opt if2(condition)} supplies a condition when generating the knots using the {cmd:df} or {cmd:percentile} options. 
For example in survival (time-to-event) data when using splines for the time scale it is common to calculate the knot locations based on the distribution of uncensored event times.

{phang}
{opt fw(weight)} gives the name of the variable containing weights when generating knots using {cmd:df} or {cmd:percentile} options.
 
{phang}
{opt reverse} will make the spline variables to be derived in reversed order, treating the last knot as the first and the first knot as the last. This can be used to add a constraint to a regression model for a constant effect after the last knot.  

{phang}
{opt scalar} will calculate the spline variables for a single value and store the results in a series of Stata scalars.
It is useful when obtaining in or out of sample predictions in large datasets and you want to predict at a certain value
of {it:varname}.

{phang}
{opt center} will center the spline variables around a single value.
This option is useful if you are using {cmd:rcsgen} to capture the non-linear effect
for a continuous covariate and would like to set a reference value, which will also
impact on the constant term.


{title:Example:}
{pstd} You can specify where to position the knots.

{cmd:. rcsgen x, knots(10 30 50 70 90) gen(rcs)}

{pstd}
Alternatively, you can generate the knots positions according to the distribution of {it: varname}. 
In the example below the {opt df(3)} option is used which means that 4 knots are used 
at 0th 33rd 67th and 100th centiles of {opt weight}. 

{cmd:. sysuse auto, clear}
{cmd:. rcsgen weight, gen(rcs) df(3)}
{cmd:. regress mpg rcs1-rcs3}
{cmd:. predictnl pred = xb(), ci(lci uci)}
{cmd:. twoway (rarea lci uci weight, sort) ///}
{cmd:         (scatter mpg weight, sort) ///}
{cmd:         (line pred weight, sort lcolor(black)), legend(off)}
         {it:({stata "rcsgen_example 1":click to run})}


{pstd}
Below is an example of the center option. A non linear effect of age is modelled in a Cox model using 
{cmd: stcox}. When generating the spline variables the center(60) option means that the 
reference age (when all spline variables are equal to zero) is 60 years.  The hazard ratio
as a function of age is obtained using the {help partpred} command available from SSC. 		 
		 
{cmd:. webuse brcancer, clear}
{cmd:. stset rectime, f(censrec==1)}
{cmd:. rename x1 age}
{cmd:. rcsgen age, gen(agercs) df(3) center(60)}
{cmd:. stcox agercs1-agercs3 hormon}
{cmd:. partpred hr, for(agercs*) ci(hr_lci hr_uci)}
{cmd:. twoway (rarea hr_lci hr_uci age, sort) ///}
{cmd:.        (line hr age, sort lcolor(black)) ///}
{cmd:.        , legend(off) yscale(log)}
         {it:({stata "rcsgen_example 2":click to run})}

		 
{title:Authors}

{p 2 2 2}
This command is based on {help rcs} written by Chris Nelson ({browse "mailto:cn46@le.ac.uk":cn46@le.ac.uk})
 that comes with the {help strsrcs} command available from SSC.

{p 2 2 2}
Paul Lambert ({browse "mailto:paul.lambert@le.ac.uk":paul.lambert@le.ac.uk}) added the percentile, rmatrix,
if2, fw and scalar options. He also wrote the mata code for the Gram-Schmidt orthogonalization (as opposed to using the {help orthog} command).

{p 2 2 2}
Mark Rutherford ({browse "mailto:mjr40@le.ac.uk":mjr40@le.ac.uk}) added the df, bknots and center options.

{p 2 2 2}
Therese Andersson ({browse "mailto:therese.m-l.andersson@ki.se":therese.m-l.andersson@ki.se}) added the reverse option.
{title:Also see}

{p 0 19}On-line:  help for {help splinegen}, {help mkspline}.
