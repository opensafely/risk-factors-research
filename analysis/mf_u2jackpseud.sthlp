{smcl}
{cmd:help mata _u2jackpseud}
{hline}

{title:Title}

{p 4 4 2}
{bf:_u2jackpseud() -- Jackknife pseudovalue functions used by somersd}


{title:Syntax}

{p 8 8 2}
{it:void}{bind:          }
{cmd:_u2jackpseud(}{it:phiidot} [{cmd:,} 
{it:phiii}{cmd:,}
{it:fweight}]{cmd:)}

{p 8 8 2}
{it:void}{bind:          }
{cmd:_v2jackpseud(}{it:phiidot} [{cmd:,} 
{it:phiii}{cmd:,}
{it:fweight}]{cmd:)}

{p 4 4 2}
where

              {it:phiidot}:  {it:numeric matrix}
                {it:phiii}:  {it:numeric matrix}
              {it:fweight}:  {it:numeric colvector}


{title:Description}

{p 4 4 2}
These functions are used by the {helpb somersd} package to calculate jackknife
pseudovalues for Hoeffding U statistics and von Mises V statistics
of degree 2, on the basis of kernel totals provided as input by the user.
Applications of these functions are discussed in the file {hi:somersd.pdf},
which is distributed with the {helpb somersd} package.
The theory of Hoeffding U statistics, von Mises V statistics, and
their kernel functions is presented in chapter 5 of Serfling (1980).

{p 4 4 2}
{cmd:_u2jackpseud(}{it:phiidot}{cmd:,} {it:phiii}{cmd:,} {it:fweight}{cmd:)}
inputs and modifies a matrix {it:phiidot}, with one column for each of a set
of degree-2 Hoffding U statistics.  On entry, the {it:i}th row of each
column of {it:phiidot} contains the {it:i}th kernel total of the corresponding
degree-2 Hoeffding U statistic.  This kernel total might be denoted as
{it:phi}_{it:i.} in the notation of (19) to (24) of the file
{hi:somersd.pdf}, which is distributed with the {helpb somersd} package.  On
exit, the {it:i}th row of each column of the matrix {it:phiidot} contains the
{it:i}th jackknife pseudovalue of the same degree-2 Hoeffding U
statistic.  This pseudovalue might be denoted as {it:psi}_{it:i} in the
notation of (19) to (24) of {hi:somersd.pdf}.  The input matrix
{it:phiii} contains, in the {it:i}th row of each column, the degree-2 kernel
function of the {it:i}th sampling unit with itself, which might be denoted
{it:phi_ii} in the notation of {hi:somersd.pdf}.  The input column vector
{it:fweight} contains frequency weights, implying that the {it:i}th rows of
{it:phiidot} and {it:phiii} represent a number of sampling units stored in the
{it:i}th row of {it:fweight}.  Both {it:phiii} and {it:fweight} are unchanged
on exit.  The matrix {it:phiii} may have one row and/or one column and is then
input into the calculation as if the row and/or column were duplicated as many
times as necessary for conformability with {it:phiidot}.  The column vector
{it:fweight} may have one row and is then input into the calculations as if
the row were duplicated as many times as necessary for conformability with
{it:phiidot}.  If {it:phiii} is absent, then it is set to a scalar with value
0.  If {it:fweight} is absent, then it is set to a scalar with value 1.  
{cmd:_u2jackpseud()} still works if {it:phiidot}, {it:phiii}, and
{it:fweight} are {help mf_st_view:views} onto the dataset in memory.

{p 4 4 2}
{cmd:_v2jackpseud(}{it:phiidot}{cmd:,} {it:phiii}{cmd:,} {it:fweight}{cmd:)}
inputs and modifies a matrix {it:phiidot}, using the additional input matrix
{it:phiii} and the additional input weight vector {it:fweight}.  The function
{cmd:_v2jackpseud()} is similar to the function {cmd:_u2jackpseud()}, except
that each column of {it:phiidot} contains on input the kernel totals and
contains on output the jackknife pseudovalues of a degree-2 von Mises V
statistic rather than a degree-2 Hoeffding U statistic.


{title:Remarks}

{p 4 4 2}
The use of the jackknife is discussed in Miller (1974).  The application of
the jackknife specifically to U statistics is discussed in Arvesen
(1969).  The {helpb somersd} package uses the delta-jackknife; that
is, it uses the jackknife to define standard errors for means, U
statistics or V statistics and then uses Taylor polynomials to define
standard errors for ratios of these means, U statistics, V
statistics, or transformations of these ratios.  The formulas used are given
in detail in the file {hi:somersd.pdf}, which is distributed with the
{helpb somersd} package.


{title:Conformability}

{pstd}
    {cmd:_u2jackpseud(}{it:phiidot}{cmd:,} {it:phiii}{cmd:,} {it:fweight}{cmd:)}, {cmd:_v2jackpseud(}{it:phiidot}{cmd:,} {it:phiii}{cmd:,} {it:fweight}{cmd:)}:{p_end}
	  {it:phiidot}:  {it:N x K}
	    {it:phiii}:  {it:N x K} or {it:N x} 1 or 1 {it:x K} or 1 {it:x} 1
	  {it:fweight}:  {it:N x} 1 or 1 {it:x} 1


{title:Diagnostics}

{p 4 4 2}
{cmd:_u2jackpseud()} and {cmd:_v2jackpseud()} carry out no checks for missing
values.  Therefore, an entry in the matrix {it:phiidot} on output will be
missing if any entry in the input matrices affecting its value is missing.


{title:Source code}

{p 4 4 2}
{view _u2jackpseud.mata, adopath asis:_u2jackpseud.mata},
{view _v2jackpseud.mata, adopath asis:_v2jackpseud.mata}


{title:Author}

{p 4 4 2}
Roger Newson, Imperial College London, UK.{break}
Email: {browse "mailto:r.newson@imperial.ac.uk":r.newson@imperial.ac.uk}


{title:References}

{p 4 4 2}
Arvesen, J. N.  1969.
Jackknifing U-statistics.
{it:Annals of Mathematical Statistics} 40: 2076-2100.

{p 4 4 2}
Miller, R. G.  1974.
The jackknife--a review.
{it:Biometrika} 61: 1-15.

{p 4 4 2}
Serfling, R.  1980.
{it:Approximation Theorems of Mathematical Statistics}.
New York: Wiley.


{title:Also see}

{p 4 13 2}
Manual:  {hi:[M-0] intro}

{p 4 13 2}
Online:  {helpb mata}, {break}
         {helpb somersd} (if installed)
{p_end}
