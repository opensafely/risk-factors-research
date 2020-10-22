{smcl}
{cmd:help mata _bcsf_bracketing}
{hline}

{title:Title}

{p 4 4 2}
{bf:_bcsf_bracketing() -- Bracketing and bracket convergence functions used by censlope}


{title:Syntax}

{p 8 8 2}
{it:real scalar}{bind:   }
{cmd:_bcsf_bracketing(}{it:yfun}{cmd:,}
{it:y}{cmd:,}
{it:yfarleft}{cmd:,}
{it:yfarright}{cmd:,}
{it:mbracket}{cmd:,}
{it:scalefactor}{cmd:,}
{it:bracketmat}{cmd:,}
{it:leftindex}{cmd:,}
{it:rightindex}{cmd:)}

{p 8 8 2}
{it:real scalar}{bind:   }
{cmd:_bcsf_bisect(}{it:objfun}{cmd:,}
{it:x0}{cmd:,}
{it:x1}{cmd:,}
{it:y0}{cmd:,}
{it:y1}{cmd:,}
{it:itcount}{cmd:,}
{it:iterate}{cmd:,}
{it:tolerance} [{cmd:,}
{it:log}]{cmd:)}

{p 8 8 2}
{it:real scalar}{bind:   }
{cmd:_bcsf_regula(}{it:objfun}{cmd:,}
{it:x0}{cmd:,}
{it:x1}{cmd:,}
{it:y0}{cmd:,}
{it:y1}{cmd:,}
{it:itcount}{cmd:,}
{it:iterate}{cmd:,}
{it:tolerance} [{cmd:,}
{it:log}]{cmd:)}

{p 8 8 2}
{it:real scalar}{bind:   }
{cmd:_bcsf_ridders(}{it:objfun}{cmd:,}
{it:x0}{cmd:,}
{it:x1}{cmd:,}
{it:y0}{cmd:,}
{it:y1}{cmd:,}
{it:itcount}{cmd:,}
{it:iterate}{cmd:,}
{it:tolerance} [{cmd:,}
{it:log}]{cmd:)}

{p 4 4 2}
where

                 {it:yfun}:  {it:pointer (real scalar function) scalar}
                    {it:y}:  {it:real scalar}
             {it:yfarleft}:  {it:real scalar}
            {it:yfarright}:  {it:real scalar}
             {it:mbracket}:  {it:real scalar}
          {it:scalefactor}:  {it:real scalar}
           {it:bracketmat}:  {it:real matrix}
            {it:leftindex}:  {it:real scalar}
           {it:rightindex}:  {it:real scalar}
               {it:objfun}:  {it:pointer (real scalar function) scalar}
                   {it:x0}:  {it:real scalar}
                   {it:x1}:  {it:real scalar}
                   {it:y0}:  {it:real scalar}
                   {it:y1}:  {it:real scalar}
              {it:itcount}:  {it:real scalar}
              {it:iterate}:  {it:real scalar}
            {it:tolerance}:  {it:real scalar}
                  {it:log}:  {it:real scalar}


{title:Description}

{p 4 4 2}
The prefix {cmd:_bcsf} stands for "bracket convergence for step functions".
The program {helpb censlope} uses these Mata functions for the numerical
solution of inequalities involving step functions.  If a scalar object
function {hi:G()} is a step function (instead of being a continuous function),
then there may not be a unique solution to the equation {hi:G(}{it:x}{hi:)=0}.
Instead, there may be either no solution or a nonempty interval of solutions.
However, if {hi:G()} is monotonically nonincreasing, then there may be a
supremum for the set of values of {it:x} such that {hi:G(}{it:x}{hi:)} is
positive (or nonnegative), which is also the infimum for values of {it:x} such
that {hi:G(}{it:x}{hi:)} is nonpositive (or negative).  Similarly, if {hi:G()}
is monotonically nondecreasing, then there may be a supremum for the set of
values of {it:x} such that {hi:G(}{it:x}{hi:)} is negative (or nonpositive),
which is also the infimum for values of {it:x} such that {hi:G(}{it:x}{hi:)}
is nonnegative (or positive).  Examples of such step functions {hi:G()}
include functions derived as continuous monotonic transformation of cumulative
distribution functions (CDFs). The suprema and infima will then be
percentiles, percentile differences, percentile ratios, or percentile slopes.
The function {cmd:_bcsf_bracketing()} is used to find pairs of X values
that bracket the suprema and infima.  When such a pair of X values is
found, the functions {cmd:_bcsf_bisect()}, {cmd:_bcsf_regula()}, and
{cmd:_bcsf_ridders()} can be used to redefine these X brackets
progressively, until the relative difference between the upper and lower
{it:x}-brackets has been reduced to a level at or below a user-defined
tolerance level. The brackets are then said to have
converged.  Bracket convergence is achieved using variants of standard
numerical methods used to find solutions for scalar equations involving
continuous functions, such as the methods described in chapter 9 of Press et
al. (1992).  All the {cmd:_bcsf} functions return an integer-valued scalar
return code, indicating the outcome of their attempts to carry out their
bracketing or convergence tasks.

{p 4 4 2}
{cmd:_bcsf_bracketing(}{it:yfun}{cmd:,} {it:y}{cmd:,} {it:yfarleft}{cmd:,}
{it:yfarright}{cmd:,} {it:mbracket}{cmd:,} {it:scalefactor}{cmd:,}
{it:bracketmat}{cmd:,} {it:leftindex}{cmd:,} {it:rightindex}{cmd:)} inputs a
Y value and finds a pair of X values whose corresponding
Y values bracket the input Y value.  The arguments {it:yfun},
{it:y}, {it:yfarleft}, {it:yfarright}, {it:mbracket}, and {it:scalefactor} are
input, the arguments {it:leftindex} and {it:rightindex} are output, and the
argument {it:bracketmat} is a two-column bracket matrix, which must have at
least two rows on input and may be extended with additional rows on output.  A
bracket matrix is a two-column matrix whose first column is assumed to contain
a set of X values in ascending order and whose second column is assumed
to contain the corresponding Y values.  The argument {it:yfun} contains a
{help m2_pointers:pointer} to a scalar function, which is used to calculate a
Y value from the corresponding X value, and is assumed to be bounded
and monotonically nonincreasing or nondecreasing.  The argument {it:y}
contains the Y value to be bracketed.  The arguments {it:yfarleft} and
{it:yfarright} are assumed to contain the limits of (*{it:yfun})({it:x}) as
{it:x} tends to minus infinity and to plus infinity, respectively.  The
argument {it:mbracket} contains the maximum number of rows that the bracket
matrix is allowed to have at the end of execution.  The argument
{it:scalefactor} contains a scale factor, which must be nonmissing and
strictly greater than 1, and is used to calculate X values for additional
rows of the bracket matrix.  It is assumed that the lowest X value in the
bracket matrix is negative and that the highest X value in the bracket
matrix is positive, so that an additional X value on the left (or right)
can be calculated by multiplying the lowest (or highest) existing X value
by {it:scalefactor}.  The output arguments {it:leftindex} and {it:rightindex}
are set during execution to contain the highest index of the bracket matrix
that brackets {it:y} on the left and the lowest index of the bracket matrix
that brackets {it:y} on the right.  This bracketing must be strict, except if
{it:y} {cmd:==} {it:yfarleft} (in which case the left bracket may be partial)
or if {it:y} {cmd:==} {it:yfarleft} (in which case the right bracket may be
partial).  The assumptions mentioned are assumed and are not necessarily
tested.  The terminology is detailed in {hi:Definitions and methods} below.

{p 4 4 2}
{cmd:_bcsf_bisect(}{it:objfun}{cmd:,} {it:x0}{cmd:,} {it:x1}{cmd:,}
{it:y0}{cmd:,} {it:y1}{cmd:,} {it:itcount}{cmd:,} {it:iterate}{cmd:,}
{it:tolerance} {cmd:,} {it:log}{cmd:)} carries out bracket convergence by using
a revised version (for step functions) of the bisection method, described in
Press et al. (1992).  The argument {it:objfun} is input and contains a
{help m2_pointers:pointer} to a scalar object function, assumed to be a
monotonically nonincreasing or nondecreasing step function.  The arguments
{it:x0} and {it:x1} contain two X values on entry, which are assumed to
be boundaries for an interval containing the supremum or infimum X value
that we need to estimate, and will be revised inward during each iteration
to contain boundaries for another smaller interval containing the same
supremum or infimum.  The arguments {it:y0} and {it:y1} are assumed to
contain, on entry, the values {it:&objfun(x0)} and {it:&objfun(x1)},
respectively, and, if so, then they will still be equal to
{it:&objfun(x0)} and {it:&objfun(x1)} on output.  The argument {it:itcount}
contains a running total of iterations and will be increased on exit by the
number of iterations carried out by {cmd:bcsf_bisect()}.  The argument
{it:iterate} contains the maximum number of iterations that
{cmd:bcsf_bisect()} may carry out.  The argument {it:tolerance} is input and
specifies that no more iterations are to be carried out after the value of
{cmd:reldif(}{it:x0}{cmd:,}{it:x1}{cmd:)} is equal to or less than the value
of {it:tolerance}.  The argument {it:log} is input, and, if it is not equal to
zero, then {cmd:bcsf_bisect()} will output an iteration log, giving the values
of {it:x0}, {it:x1}, {it:y0}, and {it:y1} at the end of each iteration.  The
arguments {it:y0} and {it:y1} must partially bracket a Y value of zero on
entry if iterations are to proceed, with {it:y0} as the partial bracket and
{it:y1} as the strict bracket.  If this is the case on entry, then it will
also be the case for the revised values of {it:y0} and {it:y1} on exit.  The
terminology is detailed in {hi:Definitions and methods} below.

{p 4 4 2}
{cmd:_bcsf_regula(}{it:objfun}{cmd:,} {it:x0}{cmd:,} {it:x1}{cmd:,}
{it:y0}{cmd:,} {it:y1}{cmd:,} {it:itcount}{cmd:,} {it:iterate}{cmd:,}
{it:tolerance} {cmd:,} {it:log}{cmd:)} carries out bracket convergence by using
a revised version (for step functions) of the regula falsi (or false position)
method, described in Press et al. (1992).  The arguments have the same
names and functions as those for {cmd:bcsf_bisect()}.

{p 4 4 2}
{cmd:_bcsf_ridders(}{it:objfun}{cmd:,} {it:x0}{cmd:,} {it:x1}{cmd:,} {it:y0}{cmd:,} {it:y1}{cmd:,} {it:itcount}{cmd:,} {it:iterate}{cmd:,} {it:tolerance} {cmd:,} {it:log}{cmd:)}
carries out bracket convergence by using a revised version (for step functions)
of the Ridders method, described in Press et al. (1992).  The arguments
have the same names and functions as those for {cmd:bcsf_bisect()}.


{title:Definitions and methods}

{p 4 4 2}
A real number value {it:y} is said to be strictly bracketed by two other
values {it:y0} and {it:y1} if and only if

                ({it:y0} - {it:y}) * ({it:y1} - {it:y}) < 0

{p 4 4 2}
or (in other words) if ({it:y0} - {it:y}) and ({it:y1} - {it:y}) have opposite
nonzero signs.  If the Y values are defined using a step function, then
we may use a more relaxed definition of bracketing.  If we define

                sign0 = sign({it:y0} - {it:y})
                sign1 = sign({it:y1} - {it:y})

{p 4 4 2}
then we say that {it:y} is partially bracketed by {it:y0} and {it:y1} if and
only if

                sign1!=0 & sign1!=sign0

{p 4 4 2}
This definition implies that {it:y0} may be equal to {it:y} but {it:y1} may
not. We then say that {it:y1} is the strict bracket and {it:y0} is the partial
bracket.

{p 4 4 2}
Whether the bracketing is strict or partial, there may be a
function {hi:F()} such that {hi:F(}{it:x0}{hi:)} = {it:y0} and
{hi:F(}{it:x1}{hi:)} = {it:y1} for some {it:x0} and {it:x1}.  We then say that
the {it:y}-bracket associated with the lower X value is the left bracket
and that the {it:y}-bracket associated with the higher X value is the
right bracket.

{p 4 4 2}
The function {cmd:_bcsf_bracketing()} finds a pair of {it:y}-brackets for a
Y value using a bracket matrix, which is a matrix {it:bracketmat} with two 
columns and at least two rows, sorted in ascending order of the first column,
with the property that, for each index {it:i},

                {it:bracketmat}[{it:i},2] = (*{it:yfun})({it:bracketmat}[{it:i},1])

{p 4 4 2}
In other words, the first column contains an ascending series of
X values, and the second column contains the corresponding Y values.
{cmd:_bcsf_bracketing()} aims to identify a pair of indices {it:leftindex} and
{it:rightindex}, having the property that {it:bracketmat}[{it:leftindex},2]
and {it:bracketmat}[{it:rightindex},2] bracket the input value {it:y}. This
bracketing must be strict, except if {it:y}=={it:yfarleft} (in which case the
left bracket may be partial) or if {it:y}=={it:yfarright} (in which case the
right bracket may be partial).  If the first row of {it:bracketmat} does not
contain a potential left bracket, then {it:bracketmat} is extended by adding
additional rows before the first row, until the first row of the extended
matrix contains a potential left bracket.  If the last row of {it:bracketmat}
does not contain a potential right bracket, then {it:bracketmat} is extended
by adding additional rows after the last row, until the last row of the
extended matrix contains a potential right bracket.  In both cases, an
additional row is defined by multiplying the X value in the existing end
row by the factor {it:scalefactor} to derive a new X value {it:xnew}, and
by defining the corresponding Y value as

                {it:ynew}=(*{it:yfun})({it:xnew})

{p 4 4 2}
and defining the new row as ({it:xnew},{it:ynew}). The argument
{it:scalefactor} is usually set to 2, implying successive doubling of the
outermost X value in {it:bracketmat}.  This method requires
that the first X value and the last X value in {it:bracketmat} are
initialized to have opposite signs.  When {it:bracketmat} is known to contain
at least one potential left bracket and one potential right bracket,
{cmd:_bcsf_bracketing()} returns the highest possible index for a left bracket
in {it:leftindex} and returns the lowest possible index for a right bracket
in {it:rightindex}.

{p 4 4 2}
The functions {cmd:_bcsf_bisect()}, {cmd:_bcsf_regula()}, and
{cmd:_bcsf_ridders()} input a pointer {it:objfun}, assumed to point to a
nonmonotonically increasing or decreasing function, and aim to estimate the
supremum (or infimum) of the set of X values with positive (or negative)
values of (*{it:objfun})({it:x}).  The functions start with a pair of
X values {it:x0} and {it:x1}, with corresponding Y values
{it:y0}=(*{it:objfun})({it:x0}) and {it:y1}=(*{it:objfun})({it:x1}), which
partially bracket a Y value of zero, with {it:y1} as the strict bracket
and {it:y0} as the partial bracket.  The functions then carry out a sequence
of iterations whose maximum number is given by the argument {it:iterate}, in
which one or the other of the ({it:x},{it:y}) pairs is replaced with a new
({it:x},{it:y}) pair, reducing the difference abs({it:x0}-{it:x1}) but
preserving the bracketing properties.  The aim of the iterations is to reach a
point where the relative difference reldif({it:x0},{it:x1}) is no more than
the value of the {it:tolerance} argument, and therefore either of the
X values can be used as the estimate of the supremum or infimum that we
aim to estimate.  The methods used by the functions are versions of those
described in Press et al. (1992), modified for use with step functions.
The function {cmd:_bcsf_bisect()} uses a bisection method.  The function
{cmd:_bcsf_regula()} uses the bisection method if the value of {it:y0} is zero
at the start of the iteration and otherwise uses the regula falsi method.
The function {cmd:_bcsf_ridders()} uses the bisection method if the value of
{it:y0} is zero at the start of the iteration and otherwise uses the method
of Ridders (1979).


{title:Return codes}

{p 4 4 2}
{cmd:_bcsf_bracketing()} returns one of the following return codes:

{ralign 6:0:}  {lalign 80:Bracketing successful}
{ralign 6:1:}  {lalign 80:Invalid row number for {it:bracketmat} on input}
{ralign 6:2:}  {lalign 80:Missing values in input arguments or in {it:bracketmat} on input}
{ralign 6:3:}  {lalign 80:First and last X values in {it:bracketmat} do not have opposite signs}
{ralign 6:4:}  {lalign 80:{it:scalefactor} <= 1 on input}
{ralign 6:5:}  {lalign 80:Left-extension of {it:bracketmat} unsuccessful}
{ralign 6:6:}  {lalign 80:Right-extension of {it:bracketmat} unsuccessful}
{ralign 6:7:}  {lalign 80:Left bracket index could not be located}
{ralign 6:8:}  {lalign 80:Right bracket index could not be located}

{p 4 4 2}
{cmd:_bcsf_bisect()}, {cmd:_bcsf_regula()}, and {cmd:_bcsf_ridders()} return
one of the following return codes:

{ralign 6:0:}  {lalign 80:Convergence successful}
{ralign 6:1:}  {lalign 80:Maximum iterations completed without convergence}
{ralign 6:2:}  {lalign 80:Missing X value calculated}
{ralign 6:3:}  {lalign 80:Missing Y value calculated}
{ralign 6:4:}  {lalign 80:Missing value for {it:iterate} on input}
{ralign 6:5:}  {lalign 80:{it:y0} and {it:y1} do not partially bracket zero on input}


{title:Conformability}

{pstd}
    {cmd:_bcsf_bracketing(}{it:yfun}{cmd:,} {it:y}{cmd:,} {it:yfarleft}{cmd:,} {it:yfarright}{cmd:,} {it:mbracket}{cmd:,} {it:scalefactor}{cmd:,} {it:bracketmat}{cmd:,} {it:leftindex}{cmd:,} {it:rightindex}{cmd:)}:{p_end}
	     {it:yfun}:  1 {it:x} 1
	        {it:y}:  1 {it:x} 1
	 {it:yfarleft}:  1 {it:x} 1
	{it:yfarright}:  1 {it:x} 1
	 {it:mbracket}:  1 {it:x} 1
      {it:scalefactor}:  1 {it:x} 1
       {it:bracketmat}:  {it:M x} 2 where {it:M} >= 2
	{it:leftindex}:  1 {it:x} 1
       {it:rightindex}:  1 {it:x} 1

    {cmd:_bcsf_bisect(}{it:objfun}{cmd:,} {it:x0}{cmd:,} {it:x1}{cmd:,} {it:y0}{cmd:,} {it:y1}{cmd:,} {it:itcount}{cmd:,} {it:iterate}{cmd:,} {it:tolerance} {cmd:,} {it:log}{cmd:)},
    {cmd:_bcsf_regula(}{it:objfun}{cmd:,} {it:x0}{cmd:,} {it:x1}{cmd:,} {it:y0}{cmd:,} {it:y1}{cmd:,} {it:itcount}{cmd:,} {it:iterate}{cmd:,} {it:tolerance} {cmd:,} {it:log}{cmd:)},
    {cmd:_bcsf_ridders(}{it:objfun}{cmd:,} {it:x0}{cmd:,} {it:x1}{cmd:,} {it:y0}{cmd:,} {it:y1}{cmd:,} {it:itcount}{cmd:,} {it:iterate}{cmd:,} {it:tolerance} {cmd:,} {it:log}{cmd:)}:
	   {it:objfun}:  1 {it:x} 1
	       {it:x0}:  1 {it:x} 1
	       {it:x1}:  1 {it:x} 1
	       {it:y0}:  1 {it:x} 1
	       {it:y1}:  1 {it:x} 1
	  {it:itcount}:  1 {it:x} 1
	  {it:iterate}:  1 {it:x} 1
	{it:tolerance}:  1 {it:x} 1
	      {it:log}:  1 {it:x} 1


{title:Diagnostics}

{p 4 4 2}
{cmd:_bcsf_bracketing(}{it:yfun}{cmd:,} {it:y}{cmd:,} {it:yfarleft}{cmd:,} {it:yfarright}{cmd:,} {it:mbracket}{cmd:,} {it:scalefactor}{cmd:,} {it:bracketmat}{cmd:,} {it:leftindex}{cmd:,} {it:rightindex}{cmd:)}
can fail only if the function indicated by {it:yfun} fails.

{p 4 4 2}
{cmd:_bcsf_bisect(}{it:objfun}{cmd:,} {it:x0}{cmd:,} {it:x1}{cmd:,} {it:y0}{cmd:,} {it:y1}{cmd:,} {it:itcount}{cmd:,} {it:iterate}{cmd:,} {it:tolerance} {cmd:,} {it:log}{cmd:)},
{cmd:_bcsf_regula(}{it:objfun}{cmd:,} {it:x0}{cmd:,} {it:x1}{cmd:,} {it:y0}{cmd:,} {it:y1}{cmd:,} {it:itcount}{cmd:,} {it:iterate}{cmd:,} {it:tolerance} {cmd:,} {it:log}{cmd:)}
and
{cmd:_bcsf_ridders(}{it:objfun}{cmd:,} {it:x0}{cmd:,} {it:x1}{cmd:,} {it:y0}{cmd:,} {it:y1}{cmd:,} {it:itcount}{cmd:,} {it:iterate}{cmd:,} {it:tolerance} {cmd:,} {it:log}{cmd:)}
can fail only if the function indicated by {it:objfun} fails.


{title:Source code}

{p 4 4 2}
{view _bcsf_bracketing.mata, adopath asis:_bcsf_bracketing.mata},
{view _bcsf_bisect.mata, adopath asis:_bcsf_bisect.mata},
{view _bcsf_regula.mata, adopath asis:_bcsf_regula.mata},
{view _bcsf_ridders.mata, adopath asis:_bcsf_ridders.mata}


{title:Author}

{p 4 4 2}
Roger Newson, Imperial College London, UK.{break}
Email: {browse "mailto:r.newson@imperial.ac.uk":r.newson@imperial.ac.uk}


{title:References}

{p 4 8 2}
Press, W. H., S. A. Teukolsky, W. T. Vetterling, and B. P. Flannery.  1992.
{it:Numerical Recipes in C:  The Art of Scientific Computing}.  2nd ed.
Cambridge, UK: Cambridge University Press.

{p 4 8 2}
Ridders, C. J. F.  1979.
A new algorithm for computing a single root of a real continuous function.
{it:IEEE Transactions on Circuits and Systems}, vol. CAS-26(11): 979-980.


{title:Also see}

{p 4 13 2}
Manual:  {hi:[M-0] intro}

{p 4 13 2}
Online:  {helpb mata}, {break}
         {helpb somersd} (if installed)
{p_end}
