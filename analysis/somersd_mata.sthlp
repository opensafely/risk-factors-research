{smcl}
{* 23sep2008}{...}
{cmd:help somersd_mata}
{hline}

{title:Title}

{p 4 4 2}
{bf:somersd_mata -- Mata functions used by somersd}


{title:Contents}

{col 5}  {bf:Online}
{col 5}{bf:help entry{col 22}Function{col 40}Purpose}
{col 5}{hline}

{col 5}{bf:{help mf_blncdtree:blncdtree()}}{...}
{col 24}{cmd:blncdtree()}{...}
{col 44}create balanced binary search tree
{col 24}{cmd:_blncdtree()}{...}
{col 44}create balanced binary search subtree
{col 24}{cmd:tidottree()}{...}
{col 44}concordance-discordance difference totals
{col 24}{cmd:tidot()}{...}
{col 44}concordance-discordance difference totals
{col 44}(inefficiently)

{col 5}{bf:{help mf_u2jackpseud:_u2jackpseud()}}{...}
{col 24}{cmd:_u2jackpseud()}{...}
{col 44}jackknife pseudovalues for degree-2 U statistics
{col 24}{cmd:_v2jackpseud()}{...}
{col 44}jackknife pseudovalues for degree-2 V statistics

{col 5}{bf:{help mf_somdtransf:_somdtransf()}}{...}
{col 24}{cmd:_somdtransf()}{...}
{col 44}transformations used by {helpb somersd}

{col 5}{bf:{help mf_bcsf_bracketing:_bcsf_bracketing()}}{...}
{col 24}{cmd:_bcsf_bracketing()}{...}
{col 44}bracketing a value of a monotonic bounded step function
{col 24}{cmd:_bcsf_bisect()}{...}
{col 44}bracket convergence by bisection method
{col 24}{cmd:_bcsf_regula()}{...}
{col 44}bracket convergence by regula falsi method
{col 24}{cmd:_bcsf_ridders()}{...}
{col 44}bracket convergence by Ridders' method

{col 5}{hline}


{title:Description}

{p 4 4 2}
The functions above are used by {helpb somersd} to calculate jackknife
pseudovalues for sample means, Hoeffding U statistics and Von Mises V
statistics, and by {helpb censlope} to carry out bracket convergence in the
iterative estimation of percentile slopes.  The pseudovalues are based on
concordance-discordance difference totals, which can be calculated efficiently
using balanced binary search trees.  The program {helpb somersd} uses these
pseudovalues to calculate delta-jackknife confidence intervals for
Somers' {it:D} or for Kendall's tau-a.


{title:Author}

{p 4 4 2}
Roger Newson, Imperial College London, UK.{break}
Email: {browse "mailto:r.newson@imperial.ac.uk":r.newson@imperial.ac.uk}


{title:Also see}

{p 4 13 2}
Online:  {helpb mata}, {break}
         {helpb somersd}, if installed
{p_end}
