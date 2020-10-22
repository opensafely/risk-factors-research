#delimit ;
program define somersd, eclass byable(onecall) sortpreserve prop(svyj svyb mi);
version 16.0;
/*
 Take, as input, 2 or more variables in varlist,
 comprising 1 x-variate and 1 or more y-variates,
 and, optionally, a flag asking for Kendall's tau-a instead of Somers' D.
 Create, as output, a maximum-likelihood mlout structure,
 with the vector of estimates equal to the vector
 of (possibly transformed) Somers' D's (or Kendall's tau-a's)
 of each y-variate with respect to the x-variate,
 and the vce matrix equal to their deltajackknife variance-covariance estimates.
 This program allows fweights, iweights or pweights.
*! Author: Roger Newson
*! Date: 15 April 2020
*/

if(replay()){;
*
 Beginning of replay section (not indented)
*;

if "`e(cmd)'"!="somersd"{;error 301;};
if _by() {;error 190;};
syntax [, Level(cilevel) CImatrix(passthru)];

*
 Display output
*;
_somersdplay, level(`level') `cimatrix';

*
 End of replay section (not indented)
*;
};
else{;
*
 Beginning of non-replay section (not indented)
*;

syntax varlist(min=2 max=9999 numeric) [if] [in] [fweight iweight pweight]
  [,
  TAua TDist TRansf(string)
  CEnind(string) CLuster(varname) CFWeight(string asis)
  FUntype(string) WStrata(varlist) BStrata(string)
  noTREe
  Level(cilevel)
  CImatrix(passthru)
  ];
/*
taua indicates that Kendall's tau-a is to be estimated instead of Somers' D
tdist specifies that we will assume a t-distribution
  for the Studentized estimate,
  with degrees of freedom equal to number of clusters minus one.
transf() specifies a transformation of Somers' D or Kendall's tau-a,
  for which estimates, standard errors and confidence limits are calculated.
cenind() specifies a list of left and/or right censorship indicators,
  which can be either varnames or zeros.
  Zero values indicate no censorship, negative values indicate left censorship,
  and positive values indicate right censorship.
cluster() specifies a clustering variable.
cfweight() specifies an expression for cluster frequency weights
  (used if each cluster represents multiple identical clusters).
funtype() specifies the functional type
  for the Somers' D and Kendall's tau-a parameters,
  and can be wcluster, bcluster or vonmises.
wstrata() specifies a list of variables whose combinations define the W-strata.
bstrata() specifies a list of variables whose combinations define the B-strata.
tree indicates that a search tree algorithm will be used.
level() specifies a confidence level.
cimatrix() specifies the name of a matrix to store the confidence limits
  (which may be asymmetric).
*/

*
 Set default tree algorithm setting
 and evaluate tree algorithm indicator
*;
local treeind="`tree'"!="notree";

*
 Initialise local macros to be used again and again
*;
local nvar: word count `varlist';
local nvarp=`nvar'+1;local nvarm=`nvar'-1;
local x: word 1 of `varlist';
* Y-variates (including the X-variate) *;
local i1=0;
while(`i1'<`nvar'){;local i1=`i1'+1;
  local y`i1': word `i1' of `varlist';
};
* List of y-variates (other than the X-variate) *;
local i1=1;local nxvlist "";
while(`i1'<`nvar'){;local i1=`i1'+1;
  local nxvlist "`nxvlist' `y`i1''";
};
* B-strata *;
local bstrata=trim(`"`bstrata'"');
if `"`bstrata'"'!="" & `"`bstrata'"'!="_n" {;
  cap confirm var `bstrata';
  if _rc!=0 {;
    disp as error "Invalid bstrata()";
    error 498;
  };
};
* Functional type *;
if `"`funtype'"'=="" {;local funtype="bcluster";};
local funtype=lower(`"`funtype'"');
foreach FT in wcluster bcluster vonmises {;
  if strpos("`FT'",`"`funtype'"')==1 {;
    local funtype="`FT'";
  };
};
if !inlist(`"`funtype'"',"bcluster","wcluster","vonmises") {;
  disp as error "Invalid funtype()";
  error 498;
};

*
 Evaluate weight expressions
*;
if "`_byvars'"!="" {;
  local bybyvars "by `_byvars' `_byrc0':";
};
tempvar wexpval cfwexpval;
* Ordinary weights *;
if `"`exp'"'=="" {;
  qui `bybyvars' gene byte `wexpval'=1;
};
else if "`weight'"=="fweight" {;
  qui `bybyvars' gene long `wexpval'`exp';
};
else {;
  qui `bybyvars' gene double `wexpval'`exp';
};
* Cluster frequency weights *;
if `"`cfweight'"'=="" {;
  qui `bybyvars' gene byte `cfwexpval'=1;
};
else {;
  cap qui `bybyvars' gene long `cfwexpval'=`cfweight';
  if _rc!=0 {;
    disp as error "Invalid cfweight()";
    error 498;
  };
};

* Create to-use variable *;
marksample touse;
if "`cluster' `wstrata' `bstrata'"!="" {;
  foreach X in `cluster' `bstrata' `wstrata' {;
    cap conf var `X';
    if !_rc {;
      markout `touse' `X', strok;
    };
  };
};

*
 Create final list of censorship indicator variables
*;
local ncenind: word count `cenind';
if `ncenind'<`nvar' {;
  local ncenindp=`ncenind'+1;
  forv i1=`ncenindp'(1)`nvar' {;local cenind `"`cenind' 0"';};
};
tempvar zero;
qui gene byte `zero'=0 if `touse';
local cenindvars "";
forv i1=1(1)`nvar' {;
  local cenindcur: word `i1' of `cenind';
  cap confirm numeric variable `cenindcur';
  if _rc==0 {;
    local cenindvars "`cenindvars' `cenindcur'";
  };
  else if `"`cenindcur'"'=="0" {;
    local cenindvars "`cenindvars' `zero'";
  };
  else {;
    disp as error "Invalid option cenind()";
    error 498;
  };
};
local xcen: word 1 of `cenindvars';
* Exclude all observations with missing censorship indicators *;
foreach X of var `cenindvars' {;
  qui replace `touse'=0 if missing(`X');
};

*
 Define variables containing cluster frequency weights,
 observation frequency weights and importance weights.
 Importance weights are the w_hi in the formulae.
 Observation frequency weights are summed over all observations
 to evaluate the returned result e(N),
 and are used for nothing else.
 Cluster frequency weights (f_i for the i'th cluster)
 must be the same for all observations in the same cluster,
 and signify that the i'th cluster in the data set stands
 for f_i identical clusters in the true sample.
 If cfweight() is specified,
 then it is interpreted as cluster frequency weights,
 and fweights, iweights and pweights are all interpreted
 as importance weights.
 If cfweight() is unspecified and cluster() is specified,
 then fweights, iweights and pweights are all interpreted
 as importance weights,
 and cluster frequency weights are set to one.
 If cfweight() and cluster() are both unspecified,
 then fweights are interpreted as cluster frequency weights
 (and all importance weights are set to one),
 and iweights and pweights are interpreted as importance weights
 (and all cluster frequency weights are set to one).
 Therefore, if cweight() is unspecified,
 then this protocol is equivalent to the standard Stata practice
 of treating iweights and pweights as importance weights
 and treating fweights by doing the calculations
 as if there were multiple identical observations in the data set.
*;
tempvar cfwei ofwei iwei;
if `"`cfweight'"'!="" {;
  * Cluster frequency weights supplied by user *;
  qui gene long `cfwei'=`cfwexpval' if `touse';
  if "`weight'"=="" {;
    qui gene long `ofwei'=`cfwexpval' if `touse';
    qui gene byte `iwei'=1 if `touse';
  };
  else if "`weight'"=="fweight" {;
    qui gene long `ofwei'=`cfwexpval'*`wexpval' if `touse';
    qui gene long `iwei'=`wexpval' if `touse';
  };
  else {;
    qui gene long `ofwei'=`cfwexpval' if `touse';
    qui gene double `iwei'=`wexpval' if `touse';
  };
};
else if "`cluster'"!="" {;
  * Clusters specified without cfweights *;
  qui gene byte `cfwei'=1 if `touse';
  if "`weight'"=="" {;
    qui gene byte `ofwei'=1 if `touse';
    qui gene byte `iwei'=1 if `touse';
  };
  else if "`weight'"=="fweight" {;
    qui gene long `ofwei'=`wexpval' if `touse';
    qui gene long `iwei'=`wexpval' if `touse';
  };
  else {;
    qui gene byte `ofwei'=1 if `touse';
    qui gene double `iwei'=`wexpval' if `touse';
  };
};
else {;
  * No cfweights or clusters *;
  if "`weight'"=="" {;
    qui gene byte `cfwei'=1 if `touse';
    qui gene byte `ofwei'=1 if `touse';
    qui gene byte `iwei'=1 if `touse';
  };
  else if "`weight'"=="fweight" {;
    qui gene long `cfwei'=`wexpval' if `touse';
    qui gene long `ofwei'=`wexpval' if `touse';
    qui gene byte `iwei'=1 if `touse';
  };
  else {;
    qui gene byte `cfwei'=1 if `touse';
    qui gene byte `ofwei'=1 if `touse';
    qui gene double `iwei'=`wexpval' if `touse';
  };
};
* Exclude observations with missing or zero weights *;
foreach X of varlist `ofwei' `cfwei' `iwei' {;
  qui replace `touse'=0 if missing(`X') | (`X'==0);
};

*
 Generate product of weights
 (for use when calculating vidot and tidot variables)
*;
tempvar prodwei;
qui gene double `prodwei'=`cfwei'*`iwei' if `touse';

*
 Abort if all by-groups are empty
*;
qui summ `touse';
if r(sum)<=0 {;
  error 2000;
};

*
 Create by-group and cluster sequence variables
 and check that cluster frequency weights are constant within clusters
*;
tempvar bygp clseq cfwei2;
qui {;
  gsort `touse' `_byvars', gene(`bygp');
  if "`cluster'"=="" {;
    gsort `bygp' `_sortindex', gene(`clseq');
  };
  else {;
    gsort `bygp' `cluster', gene(`clseq');
  };
  by `clseq': egen long `cfwei2'=max(`cfwei') if `touse';
};
cap assert `cfwei'==`cfwei2' if `touse';
if _rc!=0 {;
  disp as error "Cluster frequency weights are not constant within clusters";
  error 498;
};
drop `cfwei2';

*
 Initialise tidotw, tidot, vidotw and vidot variables
 and tidotw and tidot variable lists,
 and set tempnames for stratum variables
*;
tempvar stratum vidotw vidot dvidot dtidot;
foreach X of new `vidotw' `vidot' `dtidot' {;
  qui gene double `X'=0 if `touse';
};
local tidotwlist "";
local tidotlist "";
forv i1=1(1)`nvar' {;
  tempvar tidotw`i1' tidot`i1';
  local tidotwlist "`tidotwlist' `tidotw`i1''";
  local tidotlist "`tidotlist' `tidot`i1''";
  qui gene double `tidotw`i1''=0 if `touse';
  qui gene double `tidot`i1''=0 if `touse';
};

*
 Calculate within-cluster vidots and tidots if required
 and update summary vidotw and tidotws
*;
if inlist("`funtype'","wcluster","bcluster","vonmises") {;
  qui {;
    gsort `bygp' `clseq' `wstrata', gene(`stratum');
    by `stratum': egen `dvidot' = total(`iwei') if `touse';
    replace `vidotw' = `vidotw' + `iwei'*`dvidot' if `touse';
    if "`tree'"!="notree" {;sort `stratum' `x';};
    forv i1=1(1)`nvar' {;
      local y: word `i1' of `varlist';
      local ycen: word `i1' of `cenindvars';
      mata: tidotforsomersd("`dtidot'","`touse'","`stratum'","`x'","`y'","`iwei'","`xcen'","`ycen'",`treeind');
      replace `tidotw`i1'' = `tidotw`i1'' + `iwei'*`dtidot' if `touse';
    };
    drop `stratum' `dvidot';
  };
};

*
 Calculate within-cluster within-B-stratum vidots and tidots if required
 and update summary vidotw and tidotws
*;
if ("`bstrata'"!="") & inlist("`funtype'","wcluster","bcluster","vonmises") {;
  qui {;
    if "`bstrata'"=="_n" {;
      gsort `bygp' `clseq' `wstrata' `_sortindex', gene(`stratum');
    };
    else {;
      gsort `bygp' `clseq' `wstrata' `bstrata', gene(`stratum');
    };
    by `stratum': egen `dvidot' = total(`iwei') if `touse';
    replace `vidotw' = `vidotw' - `iwei'*`dvidot' if `touse';
    if "`tree'"!="notree" {;sort `stratum' `x';};
    forv i1=1(1)`nvar' {;
      local y: word `i1' of `varlist';
      local ycen: word `i1' of `cenindvars';
      mata: tidotforsomersd("`dtidot'","`touse'","`stratum'","`x'","`y'","`iwei'","`xcen'","`ycen'",`treeind');
      replace `tidotw`i1'' = `tidotw`i1'' - `iwei'*`dtidot' if `touse';
    };
    drop `stratum' `dvidot';
  };
};

*
 Calculate within-W-stratum vidots and tidots if required
 and update summary vidots and tidots
*;
if inlist(`"`funtype'"',"vonmises","bcluster") {;
  qui {;
    gsort `bygp' `wstrata', gene(`stratum');
    by `stratum': egen `dvidot' = total(`prodwei') if `touse';
    replace `vidot' = `vidot' + `iwei'*`dvidot' if `touse';
    if "`tree'"!="notree" {;sort `stratum' `x';};
    forv i1=1(1)`nvar' {;
      local y: word `i1' of `varlist';
      local ycen: word `i1' of `cenindvars';
      mata: tidotforsomersd("`dtidot'","`touse'","`stratum'","`x'","`y'","`prodwei'","`xcen'","`ycen'",`treeind');
      replace `tidot`i1'' = `tidot`i1'' + `iwei'*`dtidot' if `touse';
    };
    drop `stratum' `dvidot';
  };
};

*
 Calculate within-W-stratum within-B-stratum vidots and tidots if required
 and update summary vidots and tidots
*;
if ("`bstrata'"!="") & inlist(`"`funtype'"',"vonmises","bcluster") {;
  qui {;
    if "`bstrata'"=="_n" {;
      gsort `bygp' `wstrata' `_sortindex', gene(`stratum');
    };
    else {;
      gsort `bygp' `wstrata' `bstrata', gene(`stratum');
    };
    by `stratum': egen `dvidot' = total(`prodwei') if `touse';
    replace `vidot' = `vidot' - `iwei'*`dvidot' if `touse';
    if "`tree'"!="notree" {;sort `stratum' `x';};
    forv i1=1(1)`nvar' {;
      local y: word `i1' of `varlist';
      local ycen: word `i1' of `cenindvars';
      mata: tidotforsomersd("`dtidot'","`touse'","`stratum'","`x'","`y'","`prodwei'","`xcen'","`ycen'",`treeind');
      replace `tidot`i1'' = `tidot`i1'' - `iwei'*`dtidot' if `touse';
    };
    drop `stratum' `dvidot';
  };
};

*
 Initialise estimation results that are the same
 for all by-groups
*;
* Estimates and covariance matrices (initialised to zero) *;
tempname b vce;
if "`taua'"=="" {;
  * Somers' D *;
  local param "somersd";local parmlab "Somers' D";
  bVzinit `nxvlist', b(`b') v(`vce');
};
else {;
  * Kendall's tau-a *;
  local param "taua";local parmlab "Kendall's tau-a";
  bVzinit `varlist', b(`b') v(`vce');
};
ereturn post `b' `vce', depname("`x'") properties("b V");
ereturn local param "`param'";
ereturn local parmlab "`parmlab'";
ereturn local tdist "`tdist'";
ereturn local depvar "`x'";
ereturn local clustvar "`cluster'";
ereturn local vcetype "Jackknife";
ereturn local wtype "`weight'";
ereturn local wexp "`exp'";
ereturn local cfweight `"`cfweight'"';
ereturn local funtype "`funtype'";
ereturn local wstrata "`wstrata'";
ereturn local bstrata "`bstrata'";
ereturn local predict "somers_p";
ereturn local cmdline `"somersd `0'"';
ereturn local cmd "somersd";

*
 Input vidots and tidots for each by-group
 and generate estimation results and possibly output
*;
sort `_byvars' `clseq' `_sortindex';
`bybyvars' _somersdby if `touse',
  namevars(`vidot' `varlist')
  uidotwvars(`vidotw' `tidotwlist') uidotvars(`vidot' `tidotlist')
  transf(`transf')
  clseq(`clseq') cfwei(`cfwei') ofwei(`ofwei')
  level(`level') `cimatrix';

*
 End of non-replay section (not indented)
*;
};

end;

program define _somersdby, byable(recall) eclass;
version 16.0;
*
 Process a by-group for somersd.
 (We can assume that the data are already sorted
 by by-group and cluster sequence number.)
*;

syntax [if] [,
  namevars(varlist numeric min=2)
  uidotwvars(varlist numeric min=2) uidotvars(varlist numeric min=2)
  TRansf(string)
  CLSeq(varname) CFWei(varname) OFWei(varname)
  Level(cilevel)
  CImatrix(passthru)
  ];
/*
namevars() indicates a list of variables to label the output matrices e(b) and e(V).
uidotwvars() indicates a list of variables containing vidotw and tidotws
  for input into the formulas for Somers' D and Kendall's tau-a.
  for which estimates, standard errors and confidence limits are calculated,
  and should have the same length as namevars.
uidotvars() indicates a list of variables containing vidot and tidots
  for input into the formulas for Somers' D and Kendall's tau-a.
  for which estimates, standard errors and confidence limits are calculated,
  and should have the same length as namevars.
transf() specifies a transformation for Somers' D or KJendall's tau-a.
clseq() specifies a cluster sequence number variable.
cfwei() specifies cluster frequency weights,
  used if each cluster represents multiple identical clusters.
ofwei() specifies observation frequency weights
  used only for summing to derive a value for e(N).
level() specifies a confidence level.
cimatrix() specifies the name of a matrix to store the confidence limits
  (which may be asymmetric).
*/

marksample touse;

*
 Sum observation frequency weights
 (to be saved as e(N))
*;
qui summ `ofwei' if `touse', meanonly;
local nobs=r(sum);

*
 Abort if no observations
 (to be consistent with the rest of Stata)
*;
if `nobs'<=0 {;error 2000;};

*
 Create Mata-format string vectors namevec, uidotwvec and uidouvec
 from varlists namevars, uidotwvars and uidotvars, respectively
*;
local nuidotw: word count `uidotwvars';
local nuidot: word count `uidotvars';
local nname: word count `namevars';
if `nname'!=`nuidotw' | `nname'!=`nuidot' {;
  disp as error "Unequal lengths of uidotwvars, uidotvars and namevars";
  error 498;
};
local namecur: word 1 of `namevars';
local uidotwcur: word 1 of `uidotwvars';
local uidotcur: word 1 of `uidotvars';
local namevec `"("`namecur'""';
local uidotwvec `"("`uidotwcur'""';
local uidotvec `"("`uidotcur'""';
forv i1=2(1)`nname' {;
  local namecur: word `i1' of `namevars';
  local uidotwcur: word `i1' of `uidotwvars';
  local uidotcur: word `i1' of `uidotvars';
  local namevec `"`namevec',"`namecur'""';
  local uidotwvec `"`uidotwvec',"`uidotwcur'""';
  local uidotvec `"`uidotvec',"`uidotcur'""';
};
local namevec `"`namevec')"';
local uidotwvec `"`uidotwvec')"';
local uidotvec `"`uidotvec')"';

*
 Compute number of clusters, estimates and variance matrix
 for original parameters V and T(XY),
 whose ratios will be the Somers' D or Kendall's tau-a parameters
*;
if "`e(funtype)'"=="wcluster" {;
  mata: estvar1forsomersd("`touse'","`clseq'","`cfwei'",`namevec',`uidotwvec');
};
else if "`e(funtype)'"=="bcluster" {;
  mata: estvar1forsomersd("`touse'","`clseq'","`cfwei'",`namevec',`uidotwvec',`uidotvec',0);
};
else if "`e(funtype)'"=="vonmises" {;
  mata: estvar1forsomersd("`touse'","`clseq'","`cfwei'",`namevec',`uidotwvec',`uidotvec',1);
};
tempname nclust b vce;
scal `nclust'=r(N_clust);
matr def `b'=r(b);
matr def `vce'=r(V);

*
 Compute number of variables in the original varlist
*;
local nvar=colsof(`b')-1;
if `nvar'<1 {;
  disp as error "Original estimates matrix has too few columns";
  error 498;
};

*
 Convert V and T(XY) to Kendall's tau-a or Somers' D
 (setting matrices to zero if they are undefined,
 as Stata 6.0 does not permit missing values in matrices)
*;
if "`e(param)'"=="taua" {;
  * Kendall's tau-a *;
  tempname V invV invsqV transm transm1 transm2;
  matr `V'=`b'[1,1];scal `V'=trace(`V');
  if(`V'==0){;
    * Sum total of weights is zero, so set matrices to zero *;
    matr `vce'=0*`vce'[2...,2...];
    matr `b'=0*`b'[1,2...];
  };
  else{;
    * Some nonzero weights, so transform matrices *;
    scal `invV'=1/`V';scal `invsqV'=`invV'*`invV';
    matr `transm1'=(`b'[1,2...])';
    matr `transm1'=-`invsqV'*`transm1';
    matr `transm2'=`invV'*I(`nvar');
    matr `transm'=`transm1',`transm2';
    matr `vce'=`transm'*`vce'*`transm'';
    matr `vce'=0.5*(`vce'+`vce'');
    matr `b'=`invV'*`b'[1,2...];
  };
};
else{;
  * Somers' D *;
  tempname T invT invsqT transm transm0 transm1 transm2;
  matr `T'=`b'[1,2];scal `T'=trace(`T');
  if(`T'==0){;
    * All valid x-pairs are equal, so set matrices to zero *;
    matr `vce'=0*`vce'[3...,3...];
    matr `b'=0*`b'[1,3...];
  };
  else{;
    * Some valid unequal x-pairs, so transform matrices *;
    scal `invT'=1/`T';scal `invsqT'=`invT'*`invT';
    matr `transm1'=(`b'[1,3...])';
    matr `transm0'=0*`transm1';
    matr `transm1'=-`invsqT'*`transm1';
    matr `transm2'=`invT'*I(`nvar'-1);
    matr `transm'=`transm0',`transm1',`transm2';
    matr `vce'=`transm'*`vce'*`transm'';
    matr `vce'=0.5*(`vce'+`vce'');
    matr `b'=`invT'*`b'[1,3...];
  };
};

* Post estimation results *;
if("`e(tdist)'"==""){;
  *
   Normal distribution assumed
  *;
  ereturn repost b=`b' V=`vce', esample(`touse');
};
else{;
  *
   Student's t-distribution with df one less than number of clusters
  *;
  local nclustm=`nclust'-1;
  ereturn repost b=`b' V=`vce', esample(`touse');
  ereturn scalar df_r=`nclustm';
};
ereturn scalar N=`nobs';
ereturn scalar N_clust=`nclust';
if "`e(param)'"=="taua" {;
  ereturn scalar denominator=`V';
};
else {;
  ereturn scalar denominator=`T';
};
ereturn local transf "";
ereturn local tranlab "";
* Add sum of dependent variable *;
local edepvar "`e(depvar)'";
if "`e(wtype)'"=="fweight" {;
  qui summ `edepvar' [`e(wtype)'`e(wexp)'] if e(sample), meanonly;
};
else {;
  qui summ `edepvar' if e(sample), meanonly;
};
ereturn scalar depvarsum=r(sum);

* Transform if necessary *;
if "`transf'"=="" {;local transf="iden";};
capture corrtran, transf(`transf');
if _rc==0 {;
  matr  `b'=r(b);matr `vce'=r(V);
  ereturn repost b=`b' V=`vce';
  ereturn local transf "`r(transf)'";
  ereturn local tranlab "`r(tranlab)'";
};
else {;
  disp as error "Requested transformation transf(`transf') could not be performed";
  error 498;
};

*
 Display output
*;
_somersdplay, level(`level') `cimatrix';

end;

program define _somersdplay;
version 16.0;
*
 Display output
*;

syntax [,Level(cilevel) CImatrix(passthru)];
/*
level() specifies a confidence level.
cimatrix() specifies the name of a matrix to store the confidence limits
  (which may be asymmetric).
*/

* Check that confidence level is within range *;
if((`level'<10)|(`level'>99)){;
  disp as error "Level must be between 10 and 99 inclusive";
  exit 198;
};

* Functional type prefix *;
if "`e(funtype)'"=="wcluster" {;
  local funtypepref "Within-cluster ";
};
else if "`e(funtype)'"=="vonmises" {;
  local funtypepref "Von Mises ";
};

* CI label *;
local transf "`e(transf)'";
if(("`transf'"=="z")|("`transf'"=="asin")){;
  local cilab "Symmetric `level'% CI for transformed `e(parmlab)'";
};
else if("`transf'"=="zrho"){;
  local cilab "Symmetric `level'% CI for transformed Greiner's rho";
};
else if ("`transf'"=="c") | ("`transf'"=="roc") | ("`transf'"=="auroc") {;
  local cilab "Symmetric `level'% CI for Harrell's c";
};
else {;
  local cilab "Symmetric `level'% CI";
};

* Display symmetric CI *;
disp as text "`funtypepref'`e(parmlab)' with variable: " as result "`e(depvar)'";
disp as text "Transformation: " as result "`e(tranlab)'";
if "`e(wstrata)'"!="" {;
disp as text "Within strata defined by: " as result "`e(wstrata)'";
};
if "`e(bstrata)'"!="" {;
disp as text "Between strata defined by: " as result "`e(bstrata)'";
};
disp as text "Valid observations: " as result e(N);
if("`e(clustvar)'"!=""){;
  disp as text "Number of clusters: " as result e(N_clust);
};
if("`e(tdist)'"!=""){;
  disp as text "Degrees of freedom: " as result e(df_r);
};
disp as text _n "`cilab'";
ereturn display, level(`level');

* Back-transformed parameters if appropriate *;
parmtran, level(`level') `cimatrix';

end;

program define bVzinit;
version 16.0;
syntax varlist(min=1 max=9999) [, B(string) V(string) ];
*
 Take varlist as input
 and create, as output, matrices `b' and `v',
 with row and column names as for regression coefficients
 and covariance matrix respectively,
 but initialized to zero.
*;

local y:word 1 of `varlist';
local nvar:word count `varlist';

* Create "regression coefficient matrix" *;
if("`b'"!=""){;
  matr def `b'=J(1,`nvar',0);
  matr rownames `b'="y1";matrix colnames `b'=`varlist';
};
* Create "covariance matrix" *;
if("`v'"!=""){;
  matr `v'=J(`nvar',`nvar',0);
  matr rownames `v'=`varlist';matrix colnames `v'=`varlist';
};

end;

program define corrtran, rclass;
version 16.0;
*
 Transform a vector of correlation coefficients from e(b)
 and its dispersion matrix in e(V)
 using the transformation specified in transf
*;
syntax [, TRansf(string) ];

*
 List of possible transformations
*;
local tranlst "iden z asin rho zrho c";

*
 Identify transformation
*;
local tlen = length("`transf'");
if "`transf'" == "" | "`transf'" == substr("identity", 1, max(1, `tlen')) {;
   local transf "iden";
};
else if inlist("`transf'", "z", "c") {;
  local transf "`transf'";
};
else if "`transf'" == substr("arctanh", 1, max(4, `tlen')) {;
  local transf "z";
};
else if "`transf'" == substr("atanh", 1, max(2, `tlen')) {;
  local transf "z";
};
else if "`transf'" == substr("arcsin", 1, max(4, `tlen')) {;
  local transf "asin";
};
else if "`transf'" == substr("arsin", 1, max(3, `tlen')) {;
  local transf "asin";
};
else if "`transf'" == substr("asin", 1, max(2, `tlen')) {;
  local transf "asin";
};
else if "`transf'" == substr("rho", 1, max(2, `tlen')) {;
  local transf "rho";
};
else if "`transf'" == substr("sinph", 1, max(1, `tlen')) {;
  local transf "rho";
};
else if "`transf'" == substr("zsinph", 1, max(1, `tlen')) {;
  local transf "zrho";
};
else if "`transf'" == substr("zrho", 1, max(1, `tlen')) {;
  local transf "zrho";
};
else if "`transf'" == substr("roc", 1, max(2, `tlen')) {;
  local transf "c";
};
else if "`transf'" == substr("auroc", 1, max(2, `tlen')) {;
  local transf "c";
};
else {;
  disp as error "Unrecognized transformation";
  error 498;
};

*
 Identify transformation label
*;
local tlab1 "Untransformed";
local tlab2 "Fisher's z";
local tlab3 "Daniels' arcsine";
local tlab4 "Greiner's rho";
local tlab5 "z-transform of Greiner's rho";
local tlab6 "Harrell's c";
local ntran: word count `tranlst';
forval i1 = 1/`ntran' {;
  local transfi1: word `i1' of `tranlst';
  if "`transf'" == "`transfi1'" local tranlab "`tlab`i1''";
};

* Abort if no estimation results *;
if("`e(cmd)'"==""){;
  disp as error "No estimation results present";
  error 301;
};

* Get matrices *;
tempname b vce;matr `b'=e(b);matrix `vce'=e(V);

* Transform matrices *;
mata: _somdtransfforsomersd("`transf'","`b'","`vce'");

* Return values *;
return local transf "`transf'";
return local tranlab "`tranlab'";
return matrix b `b';
return matrix V `vce';

end;

program define parmtran;
version 16.0;
*
 Take confidence level and estimation output as input
 and create, as results output,
 a matrix containing asymmetric CIs for the untransformed parameters
 (which will be listed if appropriate)
*;
syntax [, Level(cilevel) CImatrix(string) ];
local transf="`e(transf)'";

* Create matrices containing estimates and standard errors *;
tempname btran sebtran se;
matr `btran'=(e(b))';matr `sebtran'=(vecdiag(e(V)))';
local nparam=rowsof(`btran');
local i1=0;
while(`i1'<`nparam'){;local i1=`i1'+1;
  scal `se'=`sebtran'[`i1',1];
  matr `sebtran'[`i1',1]=sqrt(`se');
};

* Define multiplier for creation of confidence intervals *;
tempname mult clfloat;
scal `clfloat'=`level'/100;
if("`e(tdist)'"!=""){;
  * Student's t-distribution *;
  local dof=e(df_r);
  scal `mult'=invttail(`dof',0.5*(1-`clfloat'));
};
else{;
  * Normal distribution *;
  scal `mult'=invnormal(0.5*(1+`clfloat'));
};

* Create upper and lower confidence limits *;
tempname hwid min max ci;
matr `hwid'=`mult'*`sebtran';
matr `min'=`btran'-`hwid';
matr `max'=`btran'+`hwid';
matr `ci'=`btran',`min',`max';
if(("`transf'"=="rho")|("`transf'"=="zrho")){;
  matr colnames `ci'=Rho Minimum Maximum;
};
else if("`e(param)'"=="somersd"){;
  matr colnames `ci'=Somers_D Minimum Maximum;
};
else if("`e(param)'"=="taua"){;
  matr colnames `ci'=Tau_a Minimum Maximum;
};
else{;
  matr colnames `ci'=Estimate Minimum Maximum;
};

* Carry out inverse transformation if appropriate *;
local ncci=colsof(`ci');tempname r halfpi;
scal `halfpi'=_pi/2;
local i1=0;
while(`i1'<`nparam'){;local i1=`i1'+1;
  local i2=0;
  while(`i2'<`ncci'){;local i2=`i2'+1;
    scal `r'=`ci'[`i1',`i2'];
    if(("`transf'"=="z")|("`transf'"=="zrho")){;
      scal `r'=exp(2*`r');scal `r'=(`r'-1)/(`r'+1);
    };
    else if("`transf'"=="asin"){;
      * Convert out-of-range arcsines to + or - pi/2 *;
      if(`r'<-`halfpi'){;scal `r'=-`halfpi';};
      else if(`r'>`halfpi'){;scal `r'=`halfpi';};
      scal `r'=sin(`r');
    };
    matr `ci'[`i1',`i2']=`r';
  };
};  

* CI label *;
if(("`transf'"=="z")|("`transf'"=="asin")){;
  local cilab "Asymmetric `level'% CI for untransformed `e(parmlab)'";
};
else if("`transf'"=="zrho"){;
  local cilab "Asymmetric `level'% CI for untransformed Greiner's rho";
};
else{;
  local cilab "`level'% CI";
};

* Save confidence interval to output matrix if appropriate *;
if("`cimatrix'"!=""){;matr def `cimatrix'=`ci';};

* List confidence interval if appropriate *;
if(("`transf'"=="z")|("`transf'"=="asin")|("`transf'"=="zrho")){;
  disp as text _n "`cilab'";
  matlist `ci', noheader noblank nohalf lines(none) names(all) format(%10.0g);
};

end;

#delim cr
version 16.0
/*
  Private Mata programs used by somersd
*/
mata:

void tidotforsomersd(string scalar tidotv, string scalar tousev, string scalar bygpv,
  string scalar xv, string scalar yv,
  string scalar weightv, string scalar xcenv, string scalar ycenv,
  real scalar tree)
{
/*
  Return weighted concordance-discordance difference counts (calculated using tidot)
  in a named concordance-discordance counts variable,
  between a named X-variable and a named Y-variable (both possibly censored),
  restricted to observations with a nonzero value of a named to-use variable,
  within by-groups defined by a named by-group variable,
  selecting observations with a nonzero value for a to-use variable.
  tidotv is the concordance-discordance count variable name.
  tousev is the to-use variable name.
  bygpv is the by-group variable name.
  xv is the X-variable name.
  yv is the Y-variable name.
  weightv is the weight variable name.
  xcenv is the x-variable censoring indicator variable name.
  ycenv is the y-variable censoring indicator variable name.
  tree is indicator that the search tree algorithm should be used.
*/
real matrix datmat, bygppanel, bygpstats
real colvector x, y, weight, xcen, ycen, tidotby
real scalar i1

/*
  Check that all parameters are names of existing variables
*/
if(missing(_st_varindex(tidotv))) {
  exit(error(111))
}
if(missing(_st_varindex(tousev))) {
  exit(error(111))
}
if(missing(_st_varindex(bygpv))) {
  exit(error(111))
}
if(missing(_st_varindex(xv))) {
  exit(error(111))
}
if(missing(_st_varindex(yv))) {
  exit(error(111))
}
if(missing(_st_varindex(weightv))) {
  exit(error(111))
}
if(missing(_st_varindex(xcenv))) {
  exit(error(111))
}
if(missing(_st_varindex(ycenv))) {
  exit(error(111))
}

/*
  Define main view and panel setup matrix
*/
st_view(datmat,.,(bygpv,xv,yv,weightv,xcenv,ycenv,tidotv),tousev)
datmat[.,7]=J(rows(datmat),1,.)
bygppanel=panelsetup(datmat,1)
bygpstats=panelstats(bygppanel)

/*
  Call tidot() for each by-group
*/
for(i1=1;i1<=bygpstats[1];i1++) {
  st_subview(x,datmat,bygppanel[i1,.],2)
  st_subview(y,datmat,bygppanel[i1,.],3)
  st_subview(weight,datmat,bygppanel[i1,.],4)
  st_subview(xcen,datmat,bygppanel[i1,.],5)
  st_subview(ycen,datmat,bygppanel[i1,.],6)
  st_subview(tidotby,datmat,bygppanel[i1,.],7)
  if (tree) {;tidotby[.,.]=tidottree(x,y,weight,xcen,ycen);}
  else {;tidotby[.,.]=tidot(x,y,weight,xcen,ycen);};
}

}


void estvar1forsomersd(string scalar tousev, string scalar clusterv, string scalar cfweightv,
  string rowvector namevars, string rowvector uidotwvars,
  | string rowvector uidotvars, real scalar vonmises)
{
/*
  Return estimates, jackknife estimates and variances
  of sample means, degree-2 U-statistics or degree-2 Von Mises functionals
  in returned results.e(b), e(b_jk) and e(V), respectively,
  based on pseudovalues created from uidots in uidotvars
  and within-cluster uidots in uidotwvars,
  and with row and column names from namevars.
  tousev is the to-use variable name.
  clusterv is the cluster variable name.
  cfweightv is the cluster frequency weights variable name.
  namevars contains the variable names with which the output matrices will be labelled.
  uidotwvars contains the within-cluster uidot variable name.
  uidotvars contains the uidot variable name.
  vonmises is nonzero if we are jackknifing Von Mises functionals.
*/
real matrix clustmat, uidotwmat, uidotmat,
  clustpanel, cluststats, cfweights, pseudmat, phiiimat,
  cfweicur, uidotwcur, uidotcur, b, b_jk, V
real scalar narg, wcluster, i1, N_clust
string matrix rcstripe


/*
  Fill in absent parameters
  and evaluate wcluster
  indicating sample means of within-cluster totals
*/
narg=args()
if(narg<7) {;vonmises=0;}
if(narg<6) {;
  wcluster=1;
  uidotvars=uidotwvars;
}
else {
  wcluster=0
}


/*
  Conformability checks
*/
if(cols(uidotwvars)!=cols(namevars)) {
  exit(error(3200))
}
if(cols(uidotvars)!=cols(namevars)) {
  exit(error(3200))
}


/*
  Check that all parameters are names of existing variables
*/
if(missing(_st_varindex(tousev))) {
  exit(error(111))
}
if(missing(_st_varindex(clusterv))) {
  exit(error(111))
}
if(missing(_st_varindex(cfweightv))) {
  exit(error(111))
}
if(missing(_st_varindex(namevars))) {
  exit(error(111))
}
if(missing(_st_varindex(uidotwvars))) {
  exit(error(111))
}
if(missing(_st_varindex(uidotvars))) {
  exit(error(111))
}


/*
  Define main views and panel setup matrix
*/
st_view(clustmat,.,(clusterv,cfweightv),tousev)
st_view(uidotwmat,.,uidotwvars,tousev)
if(!wcluster){;st_view(uidotmat,.,uidotvars,tousev);}
clustpanel=panelsetup(clustmat,1)
cluststats=panelstats(clustpanel)


/*
  Create matrices cfweights containing cluster frequency weights,
  N_clust containing total number of clusters,
  b containing estimates,
  and pseudmat containing pseudovalues
*/
cfweights=J(cluststats[1],1,.)
pseudmat=J(cluststats[1],cols(namevars),.)
if(!wcluster) {;phiiimat=J(cluststats[1],cols(namevars),.);}
for(i1=1;i1<=cluststats[1];i1++) {
  st_subview(cfweicur,clustmat,clustpanel[i1,.],2)
  cfweights[i1,.]=colmax(cfweicur)
  st_subview(uidotwcur,uidotwmat,clustpanel[i1,.],.)
  if(wcluster) {
    pseudmat[i1,.]=quadcolsum(uidotwcur)
  }
  else {
    st_subview(uidotcur,uidotmat,clustpanel[i1,.],.)
    phiiimat[i1,.]=quadcolsum(uidotwcur)
    pseudmat[i1,.]=quadcolsum(uidotcur)
  }
}
N_clust=quadcolsum(cfweights)
if(wcluster) {
    b = mean(pseudmat,cfweights)
    if(N_clust<=0) {;b=J(rows(b),cols(b),0);}
}
else if(vonmises) {
  b = mean(pseudmat,cfweights) :/ N_clust
  if(N_clust<=0) {;b=J(rows(b),cols(b),0);}
  _v2jackpseud(pseudmat,phiiimat,cfweights)
}
else {
  b = mean((pseudmat-phiiimat),cfweights) :/ (N_clust-1)
  if(N_clust<=1) {;b=J(rows(b),cols(b),0);}
  _u2jackpseud(pseudmat,phiiimat,cfweights)
}


/*
  Calculate jackknife estimate and variance
*/
V=quadmeanvariance(pseudmat,cfweights)
b_jk=V[1,.]
V=V[|2,1 \ .,.|] :/ N_clust
if(N_clust<=1) {
  V=J(rows(V),cols(V),0)
  if(N_clust<=0) {
    b_jk=J(rows(b_jk),cols(b_jk),0)
  }
}


/*
  Return estimation results
*/
rcstripe=J(cols(V),1,""),(namevars')
st_numscalar("r(N_clust)",N_clust)
st_matrix("r(b)",b)
st_matrix("r(b_jk)",b_jk)
st_matrix("r(V)",V)
st_matrixcolstripe("r(b)",rcstripe)
st_matrixcolstripe("r(b_jk)",rcstripe)
st_matrixcolstripe("r(V)",rcstripe)
st_matrixrowstripe("r(V)",rcstripe)

}


void _somdtransfforsomersd(string scalar transf, string scalar b, string scalar V)
{
/*
  Transform the Stata matrices named in b and V
  with a transformation named in transf,
  using the Mata program _somdtransf.
  transf is the transformation name.
  b is the name of the Stata estimates vector.
  V is the name of the Stata covariance matrix.
*/
real matrix estimates, dispersion, deriv
string matrix estlabs
/*
 estimates is the Mata matrix containing the estimates.
 dispersion is the Mata matrix containing the variances and covariances.
 deriv is the Mata matrix containing the derivatives.
 estrlabs is the row labels matrix for the estimates.
 estclabs is the column labels matrix for the estimates.
 disprlabs is the row labels matrix for the dispersion.
 dispclabs is the column labels matrix for the dispersion.
*/

estimates=st_matrix(b)
estrlabs=st_matrixrowstripe(b)
estclabs=st_matrixcolstripe(b)
dispersion=st_matrix(V)
disprlabs=st_matrixrowstripe(V)
dispclabs=st_matrixcolstripe(V)
_somdtransf(transf,estimates,estimates,deriv)
deriv=diag(deriv)
dispersion=deriv*dispersion*deriv
st_matrix(b,estimates)
st_matrixrowstripe(b,estrlabs)
st_matrixcolstripe(b,estclabs)
st_matrix(V,dispersion)
st_matrixrowstripe(V,disprlabs)
st_matrixcolstripe(V,dispclabs)

}

end
