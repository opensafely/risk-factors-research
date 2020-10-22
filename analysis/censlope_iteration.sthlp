{smcl}
{...}
{cmd:help censlope_iteration}
{hline}

{title:Iteration options used by censlope}

{title:Syntax}

{phang}Percentile slope estimation

{p 8 20 2}
{help censlope:{cmd:censlope}}
{it:...} [{cmd:,} {it:options}]

{phang}Set default maximum iterations

{p 8 20 2}
{cmd:set} {cmd:maxiter} {it:#} [{cmd:,} {opt perm:anently}]

{synoptset 27}
{synopthdr}
{synoptline}
{synopt:{opt from:abs(#)}}initial estimate for absolute magnitude of slopes{p_end}
{synopt:{opt brac:kets(#)}}maximum number of rows for the bracket matrix{p_end}
{synopt:{opt tech:nique(algorithm_spec)}}iterative numerical solution technique{p_end}
{synopt:{opt iter:ate(#)}}perform maximum of {it:#} iterations; default is
	{cmd:iterate(16000)}{p_end}
{synopt:{opt tol:erance(#)}}tolerance for the percentile slopes{p_end}
{synopt:{opt log}}display an iteration log of the brackets during bracket convergence{p_end}
{synopt:{cmd:no}{opt lim:its}}do not calculate confidence limits{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
where {it:algorithm_spec} is

{p 8 8 2}
{it:algorithm} [ {it:#} [ {it:algorithm} [{it:#}] ] ... ]

{p 4 6 2}
and {it:algorithm} is {c -(} {opt bisect} {c |} {opt regula} {c |} {opt ridders} {c )-}


{title:Description}

{pstd}
The {helpb censlope} command calculates estimates and confidence limits for a
median or other percentile slope {hi:beta} by solving numerically a scalar
equation in {hi:beta}, using an iterative method.  The options controlling the
exact iterative method will probably not be used often, because
{helpb censlope} is intended to have sensible defaults.  However, users who
wish to change the default method may do so, using a set of options similar to
the {help maximize:maximization options} used by Stata maximum likelihood
estimation commands.

{pstd}
{cmd:set} {cmd:maxiter} specifies the default maximum number of iterations for
estimation commands that iterate.  The initial value is {cmd:16000}, and
{it:#} can be {cmd:0} to {cmd:16000}.  To change the maximum number of
iterations performed by a particular estimation command, you need not reset
{cmd:maxiter}; you can specify the {opt iterate(#)} option.  When
{opt iterate(#)} is not specified, the {cmd:maxiter} value is used.


{title:Iteration options}

{phang}
{opt fromabs(#)} specifies an initial estimate of the typical absolute
magnitude of a percentile slope.  If {cmd:fromabs()} is not specified, it
defaults to the aspect ratio {it:(ymax-ymin)/(xmax-xmin)} (where {it:xmax} and
{it:xmin} are the maximum and minimum X values, and {it:ymax} and
{it:ymin} are the maximum and minimum Y values) if that ratio is defined
and nonzero, and to 1 otherwise.  This magnitude is used in constructing the
bracket matrix.  Candidate bracket beta-values will have values of 0 or of
+/-{it:fromabs}*2^K, where K is a nonnegative integer.  The bracket matrix is
a matrix with two columns and three or more rows, each row containing a
candidate beta-value in column 1 and the corresponding zetastar-value in
column 2.  It is used to find an initial pair of beta-values for input into
the iterative numerical solution method, which attempts to find a solution in
beta between the two initial beta-values.  The bracket matrix is initialized
to have beta-values -{it:fromabs}, 0 and +{it:fromabs}, and zetastar-values
corresponding to these beta-values.  If a target zeta-value is outside the
range of the zetastar-values of the bracket matrix, then the bracket matrix is
extended by adding new rows before the first row by successively doubling the
beta-value in the first row, or by adding new rows after the last row by
successively doubling the beta-value in the last row, until there is a
zetastar-value in the second column on each side of the target zeta-value.
For an explanation of this terminology, see {hi:Methods} below.

{phang}
{opt brackets(#)} specifies a maximum number of rows for the bracket matrix.
The minimum is {cmd:brackets(3)}.  The default is {cmd:brackets(1000)}.

{phang}
{opt technique(algorithm_spec)} specifies an iterative solution method for
finding a solution in {hi:beta} to the equation to be solved.  The following
algorithms are currently implemented in {helpb censlope}.

{pmore}
	{cmd:technique(bisect)} specifies an adapted version of the bisection
	method for step functions.

{pmore}
	{cmd:technique(regula)} specifies an adapted version of the regula
	falsi (or false position) method for step functions.

{pmore}
	{cmd:technique(ridders)} specifies an adapted version of the method of
	Ridders (1979) for step functions.

{pmore}The default is {cmd:technique(ridders 5 bisect }{it:iterate}{cmd:)},
where {it:iterate} is the value of the {cmd:iterate()} option.  The bisection
method is guaranteed to converge in a number of iterations similar to the
binary logarithm of the {cmd:tolerance()} option.  The regula falsi and
Ridders methods are usually faster if the zetastar function is very nearly
continuous but may sometimes be slower if the zetastar function is a 
discrete step function.  All methods are modified versions, for step
functions, of the methods of the same names described in Press et al. (1992).

{pmore}
You can switch between algorithms by specifying more than one in the
{opt technique()} option.  By default, {helpb censlope} will use an algorithm
for five iterations before switching to the next algorithm.  To specify a
different number of iterations, include the number after the technique in the
option.  For example, specifying {cmd:technique(ridders 10 bisect 1000)}
requests that {helpb censlope} perform 10 iterations by using the Ridders
algorithm, perform 1000 iterations by using the bisection algorithm, and then
switch back to Ridders for 10 iterations, and so on.  The process continues
until convergence or until the maximum number of iterations is reached.

{phang}
{opt iterate(#)} specifies the maximum number of iterations.  When the number
of iterations equals {cmd:iterate()}, the iterative solution program stops and
records failure to converge.  If convergence is declared before this threshold
is reached, it will stop when convergence is declared.  The default value of
{opt iterate(#)} is the current value of {helpb set maxiter}, which is
{cmd:iterate(16000)} by default.

{phang}
{cmd:tolerance(#)} specifies the tolerance for the
percentile differences.
When the relative difference between the current beta-brackets
is less than or equal to {opt tolerance()}, the
{opt tolerance()} convergence criterion is satisfied.
{cmd:tolerance(1e-6)} is the default.

{phang}
{opt log} specifies that an iteration log showing the progress of the
numerical solution method is to be displayed.  If an iteration log
is displayed, then there will be four separate iteration sequences per
percentile, estimating the left estimate, the right estimate, the lower
confidence limit, and the upper confidence limit, respectively.  For this
reason, the default is not to produce an iteration log.  However, if
{helpb censlope} is expected to be slow (as for large datasets), then an
iteration log can be specified to reassure the user that progress is being
made.

{phang}
{opt nolimits} specifies that lower and upper confidence limits will not be calculated.
This will save computational time if the user plans to calculate confidence limits
using a resampling prefix command, such as {helpb bootstrap} or {helpb jackknife}.


{title:Methods}

{pstd}
The program {helpb censlope} uses iterative numerical methods to solve an
equation involving a monotonically nonincreasing step function.  Given two
variables Y and X, we attempt to solve in beta an equation

    {hi:zetastar(beta) - zetatarget = 0}

{pstd}
where we define

    {hi:zetastar(beta) = zeta( theta( Y - beta*X , X ) )}

{pstd}
where {hi:theta(U,V)} may be either {hi:D(U|V)} (Somers' {it:D}) or
{hi:tau_a(U,V)} (Kendall's tau-a) as defined in {helpb somersd},
{hi:zeta()} is any one of the transformations used by the {cmd:transf()}
option of {helpb somersd}, and {hi:zetatarget} is a target zeta-value.  This
target zeta-value may be {hi:zeta(1-2q)} if we are trying to estimate the
100{it:q}th percentile slope or {hi:zeta(1-2q) +/- multiplier*standard_error}
if we are trying to calculate confidence limits for the 100{it:q}th percentile
slope.  In either case, the left-hand side of the equation to be solved is a
step function, and therefore a unique solution may not exist, as there may be
no exact solution or an interval of exact solutions.  We therefore have to
find either a left solution (defined as the supremum value of {hi:beta} such
that {hi:zetastar(beta)-zetatarget} is positive), or a right solution (defined
as the infimum value of {hi:beta} such that {hi:zetastar(beta)-zetatarget} is
negative).  For a given 100{it:q}th percentile slope, the estimate of the
percentile is defined as the mean of the left and right solutions, the lower
confidence limit is defined as a left solution, and the upper confidence limit
is defined as a right solution.  Therefore, each percentile slope to be
estimated requires four iteration sequences, solving the left estimate, the
right estimate, the lower confidence limit, and the upper confidence limit,
respectively.  This requirement implies many evaluations of the
object function {hi:zetastar(beta)-zetatarget}, each of which in turn involves
calculating Somers' {it:D} or Kendall's tau-a.  It is therefore important to be
able to calculate Somers' {it:D} and/or Kendall's tau-a efficiently, if
{helpb censlope} is to be used for large samples.  Fortunately,
{helpb somersd} uses the algorithm of Newson (2006), which calculates Somers'
D and/or Kendall's tau-a in a time of order N*log(N), where N is the number of
observations.

{pstd}
Initial beta-value estimates for the iterative methods are stored in the
bracket matrix, which is a matrix with two columns.  The first column contains a
sequence of beta-values in ascending order, and the second column contains the
corresponding zetastar-values.  As the function {hi:zetastar()} is
nonincreasing, it follows that a pair of zetastar-values from the bracket
matrix, one on each side of the target zetastar-value, will correspond to a
pair of beta-values, one on each side of the left or right solution to the
equation in {hi:beta}.  The bracket matrix is initialized, and extended if
necessary, as described in the help for the {cmd:fromabs()} and
{cmd:brackets()} options.

{pstd}
The methods used by {helpb censlope} and {helpb somersd} are implemented using
a library of {help somersd_mata:Mata functions}, whose code is distributed
with the {helpb somersd} package in accordance with the open-source principle.


{title:Author}

{p 4 4 2}
Roger Newson, Imperial College London, UK.{break}
Email: {browse "mailto:r.newson@imperial.ac.uk":r.newson@imperial.ac.uk}


{title:References}

{phang}
Newson, R.  2006.
Efficient calculation of jackknife confidence intervals for rank statistics.
{it:Journal of Statistical Software} 15: 1-10.
Download from
{browse "http://www.jstatsoft.org/v15/i01":the {it:Journal of Statistical Software} website}.

{p 4 8 2}
Press, W. H., S. A., Teukolsky, W. T. Vetterling, and B. P. Flannery.  1992.
{it:Numerical Recipes in C:  The Art of Scientific Computing}.  2nd ed.
Cambridge, UK: Cambridge University Press.

{p 4 8 2}
Ridders, C. J. F.  1979.
A new algorithm for computing a single root of a real continuous function.
{it:IEEE Transactions on Circuits and Systems}, vol. CAS-26(11): 979-980.


{title:Also see}

{psee}
Manual:  {bf:[R] maximize}

{psee}
Online:  
{helpb lrtest},
{helpb ml},
{helpb test},
{break}
{helpb somersd}, {helpb censlope}, {helpb cendif} (if installed)
{p_end}
