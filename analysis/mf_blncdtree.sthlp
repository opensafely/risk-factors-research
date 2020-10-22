{smcl}
{cmd:help mata blncdtree}
{hline}

{title:Title}

{p 4 4 2}
{bf:blncdtree() -- Balanced search tree functions used by somersd}


{title:Syntax}

{p 8 8 2}
{it:real matrix}{bind:   }
{cmd:blncdtree(}{it:nnode}{cmd:)}

{p 8 8 2}
{it:void}{bind:          }
{cmd:_blncdtree(}{it:tree}{cmd:,} 
{it:imin}{cmd:,}
{it:imax}{cmd:)}

{p 16 16 2}
{it:tidot} = 
{cmd:tidottree(}{it:x}{cmd:,}
{it:y} [ {cmd:,}
{it:weight} [ {cmd:,}
{it:xcen} [ {cmd:,}
{it:ycen} ] ] ] {cmd:)}

{p 16 16 2}
{it:tidot} = 
{cmd:tidot(}{it:x}{cmd:,}
{it:y} [ {cmd:,}
{it:weight} [ {cmd:,}
{it:xcen} [ {cmd:,}
{it:ycen} ] ] ] {cmd:)}

{p 4 4 2}
where

                {it:nnode}:  {it:real scalar}
                 {it:tree}:  {it:real matrix}
                 {it:imin}:  {it:real scalar}
                 {it:imax}:  {it:real scalar}
                {it:tidot}:  {it:real colvector}
                    {it:x}:  {it:real colvector}
                    {it:y}:  {it:real colvector}
               {it:weight}:  {it:real colvector}
                 {it:xcen}:  {it:real colvector}
                 {it:ycen}:  {it:real colvector}


{title:Description}

{p 4 4 2}
These functions are used by the {helpb somersd} package to create balanced
binary search trees and to calculate {it:tidot} vectors as defined below
under {hi:Remarks}.  Applications of these functions are discussed in the
file {hi:somersd.pdf}, which is distributed with the {helpb somersd} package.

{p 4 4 2}
{cmd:blncdtree(}{it:nnode}{cmd:)} returns a balanced binary search tree
matrix, representing a balanced binary search tree whose nodes are the
positive integer indices from 1 to {it:nnode}.  The result is defined as an
{it:nnode} x 2 matrix, whose {it:i}th row contains, in column 1, the left
daughter index of the index {it:i} (or zero if {it:i} has no left daughter)
and contains, in column 2, the right daughter index of the index {it:i} (or
zero if {it:i} has no right daughter).  A balanced binary search tree has the
feature that, for any index {it:i}, the numbers of indices in the left and
right subtrees of {it:i} differ by no more than one.  The root node of the
returned balanced binary search tree matrix is the index given by the Mata
expresstion {cmd:trunc((1+}{it:nnode}{cmd:)/2)}.

{p 4 4 2}
{cmd:_blncdtree(}{it:tree}{cmd:,} {it:imin}{cmd:,} {it:imax}{cmd:)} inputs an
existing matrix in {it:tree} and reassigns columns 1 and 2 of rows {it:imin}
to {it:imax} of {it:tree}, so that these rows define a balanced binary search
tree whose nodes are the row indices {it:i} such that {it:imin} <= {it:i} <=
{it:imax}.  The root node of this search tree is the index given by the Mata
expression {cmd:trunc((}{it:imin}{cmd:+}{it:imax}{cmd:)/2)}.
{cmd:blncdtree()} works by calling {cmd:_blncdtree()}, which works by
assigning daughter indices to the root node and then calling itself
recursively to produce left and right subtrees for the root node.  
{cmd:_blncdtree()} is a fast program that performs no conformability or
consistency checks, although it will abort if the matrix {it:tree} has fewer
than two columns.

{p 4 4 2}
{cmd:tidottree(}{it:x}{cmd:,} {it:y}{cmd:,} {it:weight}{cmd:,}
{it:xcen}{cmd:,} {it:ycen}{cmd:)} inputs a vector of X values in {it:x}
and a parallel vector of Y values in {it:y}, and, optionally, other
parallel vectors in {it:weight}, {it:xcen}, and {it:ycen}, containing,
respectively, the weights, the censorship indicators for {it:x}, and the
censorship indicators for {it:y}.  A censorship indicator value is interpreted
as implying left-censorship if negative, right-censorship if positive, and
noncensorship if zero.  {cmd:tidottree()} assumes that {it:weight} is a vector
of ones and that {it:xcen} and {it:ycen} are vectors of zeros, if these
arguments are not provided by the user.  {cmd:tidottree()} returns, as output,
a new vector {it:tidot}, parallel to the input vectors, which will contain the
weighted sums of concordance-discordance differences corresponding to the
input vectors, assuming that the data matrix defined by these input vectors is
sorted in ascending order of {it:x}.  {cmd:tidottree()} performs no
checks that the input data matrix is indeed sorted by {it:x}.  However,
{cmd:tidottree()} uses a search tree algorithm, which calculates the
{it:tidot} values in a time proportional to {it:N}{cmd:*log(}{it:N}{cmd:)}. It
creates the search tree by calling {cmd:blncdtree()}.

{p 4 4 2}
{cmd:tidot(}{it:x}{cmd:,} {it:y}{cmd:,} {it:weight}{cmd:,} {it:xcen}{cmd:,}
{it:ycen}{cmd:)} inputs the same vectors as {cmd:tidottree()} and returns the
same output vector {it:tidot}, which in this case contains
concordance-discordance totals whether or not the input data matrix is sorted.
However, {cmd:tidot()} does not use the search tree algorithm and therefore
requires a time proportional to the square of {it:N}.  {cmd:tidot()} is
therefore less efficient than {cmd:tidottree()} for large datasets, even after
accounting for the time taken to sort the dataset before calling
{cmd:tidottree()}.


{title:Remarks}

{p 4 4 2}
The vector {it:tidot} calculated by {cmd:tidottree} and {cmd:tidot} is defined
as follows.  For scalars {it:u}, {it:p}, {it:v}, and {it:q}, define the
function

                csign({it:u},{it:p},{it:v},{it:q})

{p 4 4 2}
as 1 if {it:u}>{it:v} and {it:p}>=0>={it:q}, -1 if {it:u}<{it:v} and
{it:p}<=0<={it:q}, and 0 otherwise. For row indices {it:i} and {it:j}, define

{p 16 18 2}
                {it:T}_{it:ij} = csign({it:x_i},{it:xcen_i},{it:x_j},{it:xcen_j}) * csign({it:y_i},{it:ycen_i},{it:y_j},{it:ycen_j})

{p 4 4 2}
as the concordance-discordance difference between rows {it:i} and {it:j} of the input data vectors.
Then the vector {it:tidot}, returned by {cmd:tidottree} or {cmd:tidot}, is defined by

                          {it:N}
                {it:tidot_i} = Sum {it:weight_j} * {it:T}_{it:ij}
                          {it:j=1}

{p 4 4 2}
for each index {it:i}. The function {cmd:tidot()} calculates {it:tidot} by
calculating all the {it:T}_{it:ij} and summing them, taking a time
asymptotically proportional to the square of {it:N}.  The function
{cmd:tidottree()} uses a search tree algorithm to calculate {it:tidot} in a
time asymptotically proportional to {it:N}{cmd:*log(}{it:N}{cmd:)}.  The
algorithm used by {cmd:tidottree()} is a more advanced version of the one
presented in Newson (2006) and assumes that the input data vectors are sorted
in ascending order of the values of {it:x}.  {cmd:tidottree()} calls
{cmd:blncdtree()} to create a search tree with one row for each value of
{it:y} and uses this search tree to calculate {it:tidot} without calculating
the individual {it:T}_{it:ij}.

{p 4 4 2}
Applications of these functions are discussed in the manual {hi:somersd.pdf},
which is distributed with the {helpb somersd} package as an ancillary file.
Balanced binary search trees are discussed in Wirth (1976).


{title:Conformability}

    {cmd:blncdtree(}{it:nnode}{cmd:)}:
	    {it:nnode}:  1 {it:x} 1

    {cmd:_blncdtree(}{it:tree}{cmd:,} {it:imin}{cmd:,} {it:imax}{cmd:)}:
	     {it:tree}:  {it:M x K} where {it:K} >= 2
	     {it:imin}:  1 {it:x} 1
	     {it:imax}:  1 {it:x} 1

    {cmd:tidottree(}{it:x}{cmd:,} {it:y}{cmd:,} {it:weight}{cmd:,} {it:xcen}{cmd:,} {it:ycen}{cmd:)}:
	        {it:x}:  {it:N x} 1
	        {it:y}:  {it:N x} 1
	   {it:weight}:  {it:N x} 1
	     {it:xcen}:  {it:N x} 1
	     {it:ycen}:  {it:N x} 1

    {cmd:tidot(}{it:x}{cmd:,} {it:y}{cmd:,} {it:weight}{cmd:,} {it:xcen}{cmd:,} {it:ycen}{cmd:)}:
	        {it:x}:  {it:N x} 1
	        {it:y}:  {it:N x} 1
	   {it:weight}:  {it:N x} 1
	     {it:xcen}:  {it:N x} 1
	     {it:ycen}:  {it:N x} 1


{title:Diagnostics}

{p 4 4 2}
{cmd:blncdtree(}{it:nnode}{cmd:)} aborts with error if {it:nnode} < 0.

{p 4 4 2}
{cmd:_blncdtree(}{it:tree}{cmd:,} {it:imin}{cmd:,} {it:imax}{cmd:)} aborts with error if {cmd:cols(}{it:tree}{cmd:)} < 2.

{p 4 4 2}
{cmd:blncdtree(0)} can return a 0 {it:x} 2 result.


{title:Source code}

{p 4 4 2}
{view blncdtree.mata, adopath asis:blncdtree.mata},
{view _blncdtree.mata, adopath asis:_blncdtree.mata},
{view tidottree.mata, adopath asis:tidottree.mata},
{view tidot.mata, adopath asis:tidot.mata}


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
Wirth, N.  1976.
{it:Algorithms + Data Structures = Programs}.
Englewood Cliffs, NJ: Prentice-Hall.


{title:Also see}

{p 4 13 2}
Manual:  {hi:[M-0] intro}

{p 4 13 2}
Online:  {helpb mata}, {break}
         {helpb somersd} (if installed)
{p_end}
