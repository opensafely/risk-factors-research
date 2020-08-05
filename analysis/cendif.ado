#delim ;
program define cendif, rclass byable(recall);
version 16.0;
/*
 Robust confidence limits for median difference
 and other percentile differences
 between two sub-populations.
*! Author: Roger Newson
*! Date: 16 April 2020
*/
syntax varname(numeric) [using/] [in] [if] [fweight iweight pweight]
  ,BY(varname)
  [CEntile(numlist >=0 <=100 sort)
  Level(cilevel) EForm YStargenerate(string asis)
  CLuster(varname) CFWeight(string asis) FUntype(string)
  TDist TRansf(string)
  SAving(string) noHOLD];
local yvar "`varlist'";
if("`transf'"==""){;local transf="z";};

*
 Check for options that cannot be combined with the by: prefix
*;
if _by() {;
  if `"`ystargenerate'"'!="" {;
    disp as error "Option ystargenerate() may not be combined with the by: prefix";
    error 498;
  };
};

*
 Set default functional type
*;
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
 Set centile list  to default if absent,
 and then count centile list
*;
if("`centile'"==""){;local centile "50";};
local ncent:word count `centile';

*
 Create list of target Dstar values
 corresponding to centile list
*;
local Dslist "";
local i1=0;
while(`i1'<`ncent'){;local i1=`i1'+1;
  local q: word `i1' of `centile';
  local Ds=(100 - 2*`q')/100;
  if("`Dslist'"==""){;local Dslist "`Ds'";};
  else{;local Dslist "`Dslist' `Ds'";};
};

* Display headings *;
local yvlab:variable label `yvar';
local byvlab:variable label `by';
if("`yvlab'"==""){;disp as text "Y-variable: " as result "`yvar'";};
else{;disp as text "Y-variable: " as result "`yvar' (`yvlab')";};
if("`byvlab'"==""){;disp as text "Grouped by: " as result "`by'";};
else{;disp as text "Grouped by: " as result "`by' (`byvlab')";};

*
 Mark sample for analysis
 and create first version of group indicator variable
 and record any estimation results useful to non-programmers
*;
marksample touse;
tempvar group1;
capture confirm string variable `by';
if(_rc==0){;
  qui encode `by' if(`touse'), gene(`group1');
  lab val `group1';
};
else{;
  qui gene double `group1'=`by' if(`touse');
};
tempname oldest;
cap esti hold `oldest';
qui somersd `group1' `yvar' [`weight'`exp'] if `touse',
  tr(`transf') `tdist' cluster(`cluster') cfweight(`cfweight') funtype(`funtype');
tempname N;
scal `N'=e(N);
local transf "`e(transf)'";
if("`transf'"!=""){;
  local tranlab "`e(tranlab)'";
};
local tdist "`e(tdist)'";
if("`tdist'"!=""){;
 local tdist "`e(tdist)'";
 tempname df_r;scal `df_r'=e(df_r);
};
if("`cluster'"!=""){;
  local clustva "`e(clustvar)'";
  tempname N_clust;scal `N_clust'=e(N_clust);
};
qui replace `touse'=e(sample);
eretu clear;
cap esti unhold `oldest';

*
 Create temporary variable tswexp
 containing value of frequency weight expression
 to be passed to summarize and tabulate.
*;
tempvar tswexp;
if "`weight'"=="fweight" {;
  qui gene double `tswexp'`exp' if `touse';
};
else {;
  qui gene double `tswexp'=1 if `touse';
};
if `"`cfweight'"'!="" {;
  qui replace `tswexp'=`tswexp'*(`cfweight') if `touse';
};
qui compress `tswexp';

*
 Tabulate by-variable
 and check that it is binary
*;
disp as text "Group numbers:";
tab `by' [fwei=`tswexp'] if `touse';
tempname ngrp;
scal `ngrp'=r(r);
if `N'<=0 {;
  error 2000;
};
else if `ngrp'<2 {;
  disp as error "Less than 2 groups found, 2 required";
  error 420;
};
else if `ngrp'>2 {;
  disp as error "More than 2 groups found, only 2 allowed";
  error 420;
};

*
 Create second version of indicator variable for group 1
 and count group numbers
*;
qui {;
  tempname vgroup1 N_1 N_2;
  summ `group1' [fwei=`tswexp'] if `touse', meanonly;
  scal `vgroup1'=r(min);
  replace `group1'=`group1'==`vgroup1' if `touse';
  compress `group1';
  summ `group1' [fwei=`tswexp'] if `touse' & `group1', meanonly;
  scal `N_1'=r(N);
  scal `N_2'=`N'-`N_1';
};

*
 Create data set of differences
 (unless using is specified
 in which case import data set of differences)
*;
tempname diffdset;
if("`using'"!=""){;
  * Input data set of differences *;
  frame create `diffdset';
  frame `diffdset' {;
    local dds `"`using'"';
    use "`dds'",clear;
    * Check that it is a valid data set of differences *;
    capture{;
      confirm numeric variable diff;
      confirm numeric variable Dstar;
      confirm numeric variable weight;
      tempvar valid;
      assert diff!=.;
      assert ((Dstar>-1)&(Dstar<1));
      assert ((_n==_N)|(Dstar>Dstar[_n+1]));
      assert ((Dstar_r>=-1)&(Dstar_r<1));
        assert ((_n==_N)|(Dstar_r>Dstar_r[_n+1]));
      assert Dstar>Dstar_r;
      assert ((_n==_N)|(diff<diff[_n+1]));
    };
    if(_rc!=0){;
      disp as error
       "Data set `using' is not a valid difference data set";
      error 498;
    };
  };
};
else {;
  * Create data set of differences *;
  frame create `diffdset';
  frame copy `c(frame)' `diffdset', replace;
  frame `diffdset' {;
    diffds `yvar' `group1' if[`touse'] [`weight'`exp'],
      cluster(`cluster') cfweight(`cfweight') funtype(`funtype');
  };
};


*
 Save difference dataset if requested
*;
frame `diffdset' {;
  if("`saving'"!=""){;
    save `saving';
  };
};


*
 Create first version of CI matrix
*;
tempname cimat Dstar0;
frame `diffdset' {;
  matrix define `cimat'=J(`ncent',4,0);
  matr colnames `cimat'=Percent Pctl_Dif Minimum Maximum;
  local i1=0;
  while(`i1'<`ncent'){;local i1=`i1'+1;
    local ci1:word `i1' of `centile';
    matr def `cimat'[`i1',1]=`ci1';
    local Ds0: word `i1' of `Dslist';
    scal `Dstar0'=`Ds0';
    finddiff, ds(`Dstar0') pr(centre);
    matr def `cimat'[`i1',2]=r(diff0);
  };
};


*
 Create ystar variables,
 equal to y-variable for observations in Group 1
 and to y-variable plus percentile differences
 for observations in Group 2
*;
tempname pd;
local i1=0;
local yslist "";
while(`i1'<`ncent'){;
  local i1=`i1'+1;
  scal `pd'=`cimat'[`i1',2];
  tempvar ys`i1';
  qui gene double `ys`i1''=`yvar'+(!`group1')*`pd' if(`touse');
  qui compress `ys`i1'';
  if("`yslist'"==""){;
    local yslist "`ys`i1''";
  };
  else {;
    local yslist "`yslist' `ys`i1''";
  };
};


*
 Hold any estimation results (unless asked not to do so)
*;
tempname oldest;
if("`hold'"!="nohold"){;
  capture esti hold `oldest';
};


*
 Calculate Somers' D with confidence limits
 between group 1 indicator and y-star variables
*;
capture noisily {;
  esti clear;
  tempname somdci;
  qui somersd `group1' `yslist' [`weight'`exp'] if(`touse'),
    tr(`transf') `tdist' cluster(`cluster') cfweight(`cfweight') funtype(`funtype') level(`level');
  capture noisily altest, ne(`Dslist') de(`yvar');
  if((_rc!=0)&("`hold'"!="nohold")){;
    esti clear;
    capture esti unhold `oldest';
    error 498;
  };
  qui somersd, ci(`somdci') level(`level');
};
local rc=_rc;
if(`rc'!=0){;error `rc';};


*
 Restore old estimation results (unless asked not to)
*;
if("`hold'"!="nohold"){;
    esti clear;
    capture esti unhold `oldest';
};


*
 Finalize output matrices
 containng confidence limits for percentile differences
 and for dstar ranges for percentile differences
*;
tempname Dsmat;
frame `diffdset' {;
  *
   Calculate lower and upper CI limits
   for percentile differences
  *;
  tempname Dstar0;
  local i1=0;
  while(`i1'<`ncent'){;
    local i1=`i1'+1;
    scal `Dstar0'=`somdci'[`i1',3];
    finddiff, ds(`Dstar0') pr(left);
    matr def `cimat'[`i1',3]=r(diff0);
    scal `Dstar0'=`somdci'[`i1',2];
    finddiff, ds(`Dstar0') pr(right);
    matr def `cimat'[`i1',4]=r(diff0);
  };
  *
   Create matrix dsmat
   containing dstar ranges for percentile differences
  *;
  matr def `Dsmat'=`cimat';
  matr def `Dsmat'[1,2]=`somdci';
  matr colnames `Dsmat'=Percent Dstar Minimum Maximum;
};


*
 Drop difference dataset to save space
*;
frame drop `diffdset';


*
 Exponentiate CI matrix if eform is specified
*;
* Define infinity to prevent overflow *;
tempname infty;
scal `infty'=c(maxdouble);
if("`eform'"!=""){;
  matr colnames `cimat'=Percent Pctl_Rat Minimum Maximum;
  tempname pr;
  local i1=0;
  while(`i1'<`ncent'){;local i1=`i1'+1;
    local i2=1;
    while(`i2'<4){;local i2=`i2'+1;
      scal `pr'=`cimat'[`i1',`i2'];
      if !missing(`pr') {;
        if(`pr'<=-`infty'){;scal `pr'=0;};
        else if(`pr'>=`infty'){;scal `pr'=`infty';};
        else{;
          scal `pr'=exp(`pr');
          if missing(`pr'){;scal `pr'=`infty';};
        };
      };
      matr def `cimat'[`i1',`i2']=`pr';
    };
  };
};


*
  Create ystargenerate variables if requested.
*;
if `"`ystargenerate'"'!="" {;
  _ystargenerate `ystargenerate' if `touse', cimat(`cimat') yvar(`yvar') xvar(`group1');
};


* Functional type prefix *;
if "`funtype'"=="wcluster" {;
  local funtypepref "within-cluster ";
};
else if "`funtype'"=="vonmises" {;
  local funtypepref "Von Mises ";
};


*
 List confidence limits for percentile differences
*;
disp as text "Transformation: " as result "`tranlab'";
if("`tdist'"!=""){;
  disp as text "Degrees of freedom: " as result `df_r';
};
if("`cluster'"!=""){;
  disp as text "Number of clusters (`clustva') = " as result `N_clust';
};
if("`eform'"==""){;
  disp as text "`level'% confidence interval(s) for `funtypepref'percentile difference(s)";
  disp as text "between values of `yvar' in first and second groups:";
};
else{;
  disp as text "`level'% confidence interval(s) for percentile ratio(s)";
  disp as text "between values of exp(`yvar') in first and second groups:";
};
matlist `cimat', noheader noblank nohalf lines(none) names(columns) format(%10.0g);

*
 Return saved results
*;
return matrix cimat `cimat';
return matrix Dsmat `Dsmat';
return scalar N=`N';
return scalar N_1=`N_1';
return scalar N_2=`N_2';
if("`tdist'"!=""){;return scalar df_r=`df_r';};
if("`cluster'"!=""){;
  return scalar N_clust=`N_clust';
};
return scalar level=`level';
return local depvar "`yvar'";
return local by "`by'";
return local wtype "`weight'";
return local wexp "`exp'";
return local centiles "`centile'";
return local Dslist "`Dslist'";
return local eform "`eform'";
return local tdist "`tdist'";
return local transf "`transf'";
return local tranlab "`tranlab'";
return local funtype "`funtype'";
if `"`cfweight'"'!="" {;
  return local cfweight `"`cfweight'"';
};
return local clustvar "`clustva'";


end;


program define diffds, rclass;
version 16.0;
*
 Take, as input, a data set with a y-variable
 and a binary x-variable.
 Replace this with a data set with 1 obs per between-cluster difference
 between values of y-variable for obs where x-variable is true
 and values of y-variable for obs where x-variable is false. 
*;
syntax varlist(numeric min=2 max=2) [if] [in] [fweight iweight pweight]
  [, CLuster(string) CFWeight(string asis) FUntype(string) ];
local y:word 1 of `varlist';
local x:word 2 of `varlist';

*
 Calculate temporary variables wei and cfwei,
 which start life as weights and cfweights
 but later evolve into other things.
*;
tempvar wei cfwei;
if("`exp'"==""){;qui gene byte `wei'=1;};
else{;qui gene double `wei'`exp';};
if `"`cfweight'"'!="" {;
  qui gene double `cfwei' = `cfweight';
};
else {;
  qui gene byte `cfwei'=1;
};
qui compress `wei' `cfwei';

* Keep only vital data *;
marksample touse;
qui replace `touse'=0 if missing(`wei') | (`wei'==0);
qui replace `touse'=0 if missing(`cfwei') | (`cfwei'==0);
qui keep if(`touse');
keep `cluster' `y' `x' `wei' `cfwei';

* Calculate cluster sequence *;
tempvar clseq;
if("`cluster'"==""){;qui gene long `clseq'=_n;};
else{;
  tempvar seqnum;qui gene long `seqnum'=_n;
  sort `cluster' `seqnum';
  qui by `cluster':gene long `clseq'=_n==1;
  qui replace `clseq'=sum(`clseq');
  sort `seqnum';drop `seqnum';
  drop `cluster';
};

* Collapse data if possible *;
if "`cluster'"!="" & inlist("`funtype'","wcluster","bcluster") {;
  *
    Cluster variable used in calculations, so sum wei and preserve cfwei.
  *;
  tempvar mincfwei;
  sort `x' `y' `clseq', stable;
  qui collapse (sum) `wei' (max) `cfwei' (min) `mincfwei'=`cfwei', by(`x' `y' `clseq') fast;
  cap assert `mincfwei'==`cfwei';
  if _rc!=0 {;
    disp as error "Cluster frequency weights are not constant within clusters";
    error 498;
  };
  drop `mincfwei';
};
else {;
  *
    No cluster variable used in calculations,
    so incorporate cfweights into weights and then sum weights.   
  *;
  sort `x' `y' `clseq', stable;
  qui replace `wei'=`wei'*`cfwei';
  qui collapse (sum) `wei', by (`x' `y') fast;
  qui gene byte `cfwei'=1;
  qui gene long `clseq'=_n;
};

* Find minimum and maximum obs where `x' and !`x' are true *;
qui {;
  tempvar seqnum;gene long `seqnum'=_n;
  summ `seqnum' if(!`x'),meanonly;
  local nx0=r(N);local minx0=r(min);local maxx0=r(max);
  summ `seqnum' if(`x'),meanonly;
  local nx1=r(N);local minx1=r(min);local maxx1=r(max);
  drop `seqnum';
};
if((`nx1'<1)|(`nx0'<1)) {;
  disp as error "X-variable not binary";
  error 420;
};

*
 Create first version of output data set
*;
tempname fdiffds;
frame create `fdiffds' diff weight;
tempname wi1wi2;
local i1=`minx1'-1;
* Create dataset for specified functional type *;
if "`funtype'"=="bcluster" {;
  * Between-cluster differences only *;
  qui replace `wei'=`wei'*`cfwei';
  while(`i1'<`maxx1'){;local i1=`i1'+1;
    local i2=`minx0'-1;
    while(`i2'<`maxx0'){;local i2=`i2'+1;
      if(`clseq'[`i1']!=`clseq'[`i2']){;
        scal `wi1wi2'=`wei'[`i1']*`wei'[`i2'];
        frame post `fdiffds' (`y'[`i1']-`y'[`i2']) (`wi1wi2');
      };
    };
  };
};
else if "`funtype'"=="wcluster" {;
  * Within-cluster differences only *;
  while(`i1'<`maxx1'){;local i1=`i1'+1;
    local i2=`minx0'-1;
    while(`i2'<`maxx0'){;local i2=`i2'+1;
      if(`clseq'[`i1']==`clseq'[`i2']){;
        scal `wi1wi2'=`cfwei'[`i1']*`wei'[`i1']*`wei'[`i2'];
        frame post `fdiffds' (`y'[`i1']-`y'[`i2']) (`wi1wi2');
      };
    };
  };
};
else if "`funtype'"=="vonmises" {;
  * Between-cluster and within-cluster differences *;
  while(`i1'<`maxx1'){;local i1=`i1'+1;
    local i2=`minx0'-1;
    while(`i2'<`maxx0'){;local i2=`i2'+1;
        scal `wi1wi2'=`wei'[`i1']*`wei'[`i2'];
        frame post `fdiffds' (`y'[`i1']-`y'[`i2']) (`wi1wi2');
    };
  };
};

*
 Input first version of output data set into memory
 and create second version of output data set
 with 1 obs per difference value
*;
frame copy `fdiffds' `c(frame)', replace;
cap count if missing(diff);
if r(N)>0 {;
  disp as error r(N) " between-group pairwise differences missing";
  error 498;
};
qui compress diff;
qui collapse (sum) weight, by(diff) fast;
lab var diff "Difference";
lab var weight "Sum of product weights";
* Create variable Dstar *;
qui {;
  tempname totwgt;
  summ weight, meanonly;
  scal `totwgt'=r(sum);
  gene double sdle=sum(weight);
  gene double sdg=`totwgt'-sdle;
  gene double sdl=sdle-weight;
  gene double Dstar=(sdg-sdl)/`totwgt';
  gene double Dstar_r=-1;
  replace Dstar_r=(sdg-sdle)/`totwgt' if(_n<_N);
  keep diff weight Dstar Dstar_r;
  compress;
  lab var Dstar "D-star for difference";
  lab var Dstar_r "D-star to right of difference";
};

end;


program define finddiff,rclass;
version 16.0;
*
 Find difference corresponding to dstar0 value
 (assuming the data set in memory
 is of the kind created by diffds),
 preferring to left, right or centre
 according to value of prefer
*;
syntax, DStar0(name) PRefer(string);
local prefer=upper(substr("`prefer'",1,1));

*
 Define "+infinity" and "-infinity"
 in case of infinite confidence limits
*;
tempname infty minfty;
scal `infty'=c(maxdouble);
scal `minfty'=c(mindouble);

tempname diff0;

*
 Find value for `diff0' corresponding to `dstar0'
*;
if((`dstar0'<=-1)&("`prefer'"=="R")){;scal `diff0'=`infty';};
else if((`dstar0'<=-1)&("`prefer'"!="R")){;scal `diff0'=diff[_N];};
else if((`dstar0'>=1)&("`prefer'"=="L")){;scal `diff0'=`minfty';};
else if((`dstar0'>=1)&("`prefer'"!="L")){;scal `diff0'=diff[1];};
else if(`dstar0'<Dstar[_N]){;scal `diff0'=diff[_N];};
else if(`dstar0'>Dstar[1]){;scal `diff0'=diff[1];};
else{;
  * diff0 can be found in range of values of diff *;
  tempname Dmid;
  local stop=0;local ileft=1;local iright=_N;
  while(!`stop'){;
    local imid=int((`ileft'+`iright')/2);
    scal `Dmid'=Dstar[`imid'];
    if(`Dmid'<=`dstar0'){;local iright=`imid';};
    if(`Dmid'>=`dstar0'){;local ileft=`imid';};
    if(`iright'<=`ileft'+1){;
      * Initiate termination sequence *;
      local stop=1;
      if(Dstar[`ileft']==`dstar0'){;local iright=`ileft';};
      if(Dstar[`iright']==`dstar0'){;local ileft=`iright';};
    };  
  };
  * Final difference *;
  if(Dstar[`ileft']==`dstar0'){;scal `diff0'=diff[`ileft'];};
  else if(Dstar[`iright']==`dstar0'){;scal `diff0'=diff[`iright'];};
  else if(Dstar_r[`ileft']<`dstar0'){;scal `diff0'=diff[`ileft'];};
  else if(Dstar_r[`ileft']>`dstar0'){;scal `diff0'=diff[`iright'];};
  else if("`prefer'"=="L"){;scal `diff0'=diff[`ileft'];};
  else if("`prefer'"=="R"){;scal `diff0'=diff[`iright'];};
  else{;scal `diff0'=(diff[`ileft']+diff[`iright'])/2;};
};

return scalar diff0=`diff0';

end;

program define altest, eclass;
version 16.0;
syntax, NEwb(numlist) DEpvar(string);
*
 Replace estimates in e(b) with numbers in `newb',
 and replace rownames and colnames of e(b) and e(V)
 with names not referring to temporary variables,
 and replace e(depvar) with `depvar',
 while leaving other parts of e() the same
*;

local transf "`e(transf)'";
tempname newbmat newVmat bi1;
matr def `newbmat'=e(b);
matr def `newVmat'=e(V);
local nrowb=colsof(`newbmat');
local i1=0;local yslist "";
while(`i1'<`nrowb'){;local i1=`i1'+1;
  local ysi1 "ys`i1'";
  if("`yslist'"==""){;local yslist "`ysi1'";};
  else{;local yslist "`yslist' `ysi1'";};
  local ni1:word `i1' of `newb';
  scal `bi1'=`ni1';
  matr def `newbmat'[1,`i1']=`bi1';
};
* Transform Somers' D *;
if inlist(`"`transf'"',"asin","iden","z") {;
  mata: _somdtransfforcendif("`transf'","`newbmat'","`newbmat'");
};
else {;
  disp as error "Invalid transformation - `transf'";
  error 498;
};
matr colnames `newbmat'=`yslist';
matr colnames `newVmat'=`yslist';matr rownames `newVmat'=`yslist';
ereturn local depvar "`depvar'";
ereturn repost b=`newbmat' V=`newVmat',rename;

end;


prog def _ystargenerate;
version 16.0;
/*
  Create ystar variables
  corresponding to a matrix of Theil-Sen median slopes.
*/

syntax newvarlist(numeric) [if] , cimat(name) xvar(varname) yvar(varname);
/*
  cimat() specifies the name of the confidence interval matrix.
  yvar() specifies the name of the Y-variable.
  xvar() specifies the name of the X-variable.
*/

cap confirm matrix `cimat';
if _rc!=0 {;
  disp as error `"`cimat' is not a matrix"';
  error 498;
};
local npctl=rowsof(`cimat');
local nystar: word count `varlist';
local nystar=min(`nystar',`npctl');

marksample touse, novarlist;

tempname xicur;
forv i1=1(1)`nystar' {;
  local pctcur=`cimat'[`i1',1];
  local typecur: word `i1' of `typlist';
  local ystarcur: word `i1' of `varlist';
  scal `xicur'=`cimat'[`i1',2];
  gene `typecur' `ystarcur'=`yvar'-`xicur'*`xvar' if `touse';
  lab var `ystarcur' "Ystar for percentile `pctcur'";
};

end;


#delim cr
version 16.0
/*
  Private Mata programs used by cendif
*/
mata:

void _somdtransfforcendif(string scalar transf,string scalar inmatname,string scalar outmatname)
{
/*
 Use the transformation in transf
 to transform the Stata matrix named in inmatname
 to the Stata matrix named in outmatname
*/
real matrix nummat

nummat=st_matrix(inmatname)
_somdtransf(transf,nummat,nummat)
st_matrix(outmatname,nummat)

}

end
