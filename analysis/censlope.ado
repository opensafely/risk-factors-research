#delim ;
program define censlope, rclass byable(recall);
version 16.0;
/*
  Confidence intervals for Theil-Sen percentile slopes.
  Input 2 variables (a Y-variable and an X-variable)
  and output a matrix with one row per percentile
  and data on confidence intervals for percentile slopes,
  which may be exponentiated to provide percentile ratios.
*! Author: Roger Newson
*! Date: 15 April 2020
*/

syntax varlist(min=2 max=2 numeric) [if] [in] [fweight iweight pweight]
  [ , CEntile(numlist >=0 <=100 sort) EForm YStargenerate(string asis)
  ESTAddr
  LOG TECHnique(string)
  BRACkets(numlist min=1 max=1 integer >=3) ITERate(numlist min=1 max=1 integer >=0)
  FROMabs(numlist min=1 max=1 >0) TOLerance(numlist min=1 max=1 >0)
  noLIMits
  Level(cilevel) CImatrix(passthru) * ];
/*
centile() specifies a list of percents, for which percentile slopes will be estimated.
eform specifies that percentile slopes will be exponentiated,
  to give percentile ratios if the Y-variable is logged.
ystargenerate() specifies a list of new variables to be generated,
  containing ystar(xi_i) = Y - X*xi_i,
  where xi_i is the ith percentile slope requested.
estaddr specifies that the r() results will be added
  to the e() results created by somersd,
  mainly for use by parmby.
log specifies that the iterations for finding percentile slopes will be logged.
technique() specifies the iterative technique sequence used
  to estimate percentile slopes and their confidence limits.
brackets() specifies the maximum number of brackets.
iterate() specifies the maximum number of iterations.
fromabs() specifies a preliminary estimate of the magnitude of the slope,
  used to calculate the first positive and negative brackets,
  and doubled repeatedly if necessary to calculate additional brackets.
tolerance() specifies the tolerance,
  which is the minimum relative difference between bounds for a percentile slope,
  below which the iterative method is said to have converged.
nolimits specifies that confidence limits will not be calculated,
  and is intended to save time when the bootstrap or other subsampling methods are used
  to generate confidence limits.
level() specifies a confidence level (passed to somersd).
cimatrix() specifies the name of a matrix to store the confidence limits for Somers' D
  (which may be asymmetric).
Other options are passed to somersd.
*/


/*
 Check for options that cannot be combined with the by: prefix
*/
if _by() {;
  if `"`ystargenerate'"'!="" {;
    disp as error "Option ystargenerate() may not be combined with the by: prefix";
    error 498;
  };
};


/*
  Extract local macros, scalars and matrices from syntax results.
*/
tempname cimat rcmat;
local yvar: word 1 of `varlist';
local xvar: word 2 of `varlist';
local wtexp `"[ `weight' `exp' ]"';
if("`centile'"==""){;local centile "50";};
local ncent:word count `centile';
local somdopts `"`options'"';
* Initialize confidence interval matrix for percentiles *;
matr def `cimat'=J(`ncent',4,.);
if "`eform'"=="" {;
  matr colnames `cimat' = "Percent" "Pctl_Slope" "Minimum" "Maximum";
};
else {;
  matr colnames `cimat' = "Percent" "Pctl_Ratio" "Minimum" "Maximum";
};
forv i1=1(1)`ncent' {;
  local cent: word `i1' of `centile';
  matr def `cimat'[`i1',1]=`cent';
};
matr def `rcmat'=`cimat';


/*
  Checks and defaults for iteration options.
*/
local ilog="`log'"!="";
if "`brackets'"=="" {;local brackets=1000;};
if "`iterate'"=="" {;local iterate=c(maxiter);};
if "`fromabs'"=="" {;local fromabs=.;};
if "`tolerance'"=="" {;local tolerance=1e-6;};
* Parse technique specification list *;
if `"`technique'"'=="" {;local technique "ridders 5 bisect `iterate'";};
* Add step numbers if these are absent. *;
local temptechnique "";
local techcur: word 1 of `technique';
local i1=1;
while `"`techcur'"'!="" {;
  local i1=`i1'+1;
  local lookahead: word `i1' of `technique';
  cap confirm number `lookahead';
  if _rc==0 {;
    local temptechnique `"`temptechnique' `techcur' `lookahead'"';
    local i1=`i1'+1;
    local techcur: word `i1' of `technique';
  };
  else {;
    local temptechnique `"`temptechnique' `techcur' 5"';
    local techcur `"`lookahead'"';
  };
};
* Separate techniques from step numbers, checking both. *;
local ntech: word count `temptechnique';
local ntech=int(`ntech'/2);
local technique "";
local tech_steps "";
forv i1=1(1)`ntech' {;
  local i3=`i1'+`i1';
  local i2=`i3'-1;
  local techcur: word `i2' of `temptechnique';
  local stepcur: word `i3' of `temptechnique';
  if !inlist(`"`techcur'"',"bisect","regula","ridders") {;
    disp as error `"Unknown technique - `techcur'"';
    error 498;
  };
  cap confirm integer number `stepcur';
  if _rc!=0 {;
    disp as error "Invalid technique step number - `stepcur'";
    error 498;
  };
  local technique `"`technique' `techcur'"';
  local tech_steps `"`tech_steps' `stepcur'"';
};
* Create technique step matrix. *;
tempname techstepmat;
matr def `techstepmat'=J(`ntech',1,.);
matr colnames `techstepmat'="Iterations";
matr rownames `techstepmat'=`technique';
forv i1=1(1)`ntech' {;
  local stepcur: word `i1' of `tech_steps';
  matr def `techstepmat'[`i1',1]=`stepcur';
};


/*
  Initialize temporary variables and scalars.
*/
marksample touse;
tempname zetatarget;
tempvar ystar;
qui gene double `ystar'=.;


/*
  Call somersd to calculate zeta for a beta of zero.
*/
disp as text "Outcome variable: " as result "`yvar'";
somersd `xvar' `yvar' if `touse' `wtexp' , `somdopts' level(`level') `cimatrix';
qui replace `touse'=e(sample);


/*
  Extract local macros, scalars and matrices from somersd estimation results.
*/
local transf "`e(transf)'";
local tdist "`e(tdist)'";
tempname beta0 bracketmat N df_r denominator;
scal `N'=e(N);
scal `df_r'=e(df_r);
scal `denominator'=e(denominator);
* Initialize bracket matrix *;
matr def beta0=e(b);
matr def `bracketmat'=(0 , .);
matr def `bracketmat'[1,2]=beta0[1,colsof(beta0)];
matr colnames `bracketmat' = "Beta" "Zetastar";


/*
  Store estimation results.
*/
tempname estzero;
_estimates hold `estzero';


/*
  Calculate minima and maxima of X- and Y-variable
  and store their minima, maxima and ranges.
*/
tempname xmin xmax ymin ymax sfromabs;
qui summ `xvar' if `touse';
scal `xmin'=r(min);scal `xmax'=r(max);
qui summ `yvar' if `touse';
scal `ymin'=r(min);scal `ymax'=r(max);
scal `sfromabs'=`fromabs';

/*
  Calculate confidence intervals if denominator is positive
*/
if missing(`denominator') | `denominator'<=0 {;
  disp _n as text "Note: denominator is nonpositive. Slopes are therefore all undefined.";
  matr def `rcmat'[1,2]=J(`ncent',3,1);
};
else {;
  mata: censlope_percentileslopes(`fromabs',`brackets',`iterate',`tolerance',`level');
};


/*
  Restore original estimation results.
*/
_estimates unhold `estzero';


/*
  Output confidence interval matrix.
*/
if("`eform'"==""){;
  disp _n as text "`level'% CI(s) for percentile slope(s)";
};
else{;
  disp _n as text "`level'% CI(s) for percentile ratio(s)";
};
matlist `cimat', noheader noblank nohalf lines(none) names(columns) format(%10.0g);


/*
  Create ystargenerate variables if requested.
*/
if `"`ystargenerate'"'!="" {;
  _ystargenerate `ystargenerate' if `touse', cimat(`cimat') yvar(`yvar') xvar(`xvar');
};


/*
  Return r() results to e() if requested.
*/
if "`estaddr'"!="" {;
  _estaddr `tolerance' `sfromabs' `level'
    `"`tech_steps'"' `"`technique'"' "`centile'" "`eform'" "`xvar'" "`yvar'"
    `techstepmat' `bracketmat' `rcmat' `cimat';
};


/*
  Return results in r().
*/
return scalar tolerance=`tolerance';
return scalar fromabs=`sfromabs';
return scalar level=`level';
return local tech_steps `"`tech_steps'"';
return local technique `"`technique'"';
return local centiles "`centile'";
return local eform "`eform'";
return local xvar "`xvar'";
return local yvar "`yvar'";
return matrix techstepmat=`techstepmat';
return matrix bracketmat=`bracketmat';
return matrix rcmat=`rcmat';
return matrix cimat=`cimat';


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


prog def _estaddr, eclass;
version 16.0;
/*
  Add r() results to e() results created by somersd
  (mainly for use by parmby).
*/

args tolerance fromabs level tech_steps technique centile eform xvar yvar techstepmat bracketmat rcmat cimat;

/*
  Return results in e().
*/
ereturn scalar tolerance=`tolerance';
ereturn scalar fromabs=`fromabs';
ereturn scalar level=`level';
ereturn local tech_steps `"`tech_steps'"';
ereturn local technique `"`technique'"';
ereturn local centiles "`centile'";
ereturn local eform "`eform'";
ereturn local xvar "`xvar'";
ereturn local yvar "`yvar'";
tempname TM;
foreach M in techstepmat bracketmat rcmat cimat {;
  matr def `TM'=``M'';
  ereturn matrix `M'=`TM';
};

end;


#delim cr
version 16.0
/*
  Private Mata programs used by censlope
*/
mata:


void censlope_percentileslopes(real scalar fromabs, real scalar brackets, real scalar iterate, real scalar tolerance, real scalar level)
{
/*
  Estimate percentile slopes and their confidence limits for censlope.
  fromabs stores the initial estimate of the absolute value of the percentile slopes.
  brackets stores the maximum number of brackets.
  iterate stores the maximum number of iterations.
  tolerance stores the relative difference between beta-brackets,
    at or below which the beta-brackets are said to have converged.
  level stores the confidence level.
*/


real matrix cimat, rcmat, bracketmat, techstepmat
string matrix cimat_cl, bracketmat_cl, techniques
real scalar pctcur, beta, betaleft, betaright, betafarleft, betafarright,
  zetaleft, zetaright, zetafarleft, zetafarright, zetacur, hwid, zetalower, zetaupper,
  b_l_zetacur, b_r_zetacur, b_c_zetacur, b_r_zetalower, b_l_zetaupper,
  pctlseq, tdist, df_r, eform, nolimits, xmin, xmax, ymin, ymax,
  leftindex, rightindex, subrc1, subrc2, cicol
string scalar transf
/*
  cimat is the Mata version of the confidence interval matrix.
  rcmat is the Mata version of the return code matrix.
  bracketmat is the Mata version of the brackets matrix.
  techstepmat is the Mata version of the column vector of technique step numbers.
  cimat_cl is the column labels of the Stata version of the confidence interval matrix.
  bracketmat_cl is the column labels of the Stata version of the brackets matrix.
    (set to the aspect ratio if nonpositive).
  techniques stores the iteration technique names specified
    by the technique() option of censlope.
  log indicates that log option is set.
  pctcur stores the current percent.
  beta stores a beta-value.
  betaleft stores left beta-brackets.
  betaright stores right beta-brackets.
  betafarleft stores the beta-value representing minus infinity.
  betafarright stores the beta-value representing plus infinity.
  zetaleft stores left zeta-brackets.
  zetaright stores right zeta-brackets.
  zetafarleft stores the maximum possible zeta-value.
  zetafarright stores the minimum possible zeta-value.
  zetacur stores the zeta-value for the percentile currently being estimated.
  hwid stores the half-width of the confidence interval for the zetastar estimate.
  zetalower stores the lower confidence limit
    for the zeta-value currently being estimated.
  zetaupper stores the upper confidence limit
    for the zeta-value currently being estimated.
  b_l_zetacur stores B_L(zetacur).
  b_r_zetacur stores B_R(zetacur).
  b_c_zetacur stores B_C(zetacur).
  b_l_zetaupper stores B_L(zetaupper).
  b_r_zetalower stores B_R(zetalower).
  pctlseq stores the sequence number of the percentile currently being estimated.
  tdist indicates that the tdist option is specified.
  df_r stores the degrees of freedom if the tdist option is specified.
  eform indicates that the eform option is specified.
  nolimits specifies that the nolimits option is specified.
  xmin stores minimum X-value
  xmax stores maximum x-value
  ymin stores minimum y-value
  ymax stores maximum y-value
  leftindex stores left index of bracket matrix (pointing to left bracket).
  righttindex stores right index of bracket matrix (pointing to right bracket).
  subrc1 and subrc2 store subroutine return codes.
  cicol stores a column index for cimat.
  transf stores the transformation name provided
    by the transf() option of somersd.
*/


/*
  Input Stata matrices into Mata matrices.
*/
cimat=st_matrix(st_local("cimat"))
rcmat=cimat
cimat_cl=st_matrixcolstripe(st_local("cimat"))
bracketmat=st_matrix(st_local("bracketmat"))
bracketmat_cl=st_matrixcolstripe(st_local("bracketmat"))
techstepmat=st_matrix(st_local("techstepmat"))
techniques=st_matrixrowstripe(st_local("techstepmat"))
techniques=techniques[.,2]


/*
  Initialize scalars
*/
log=st_local("log")!=""
transf = st_local("transf")
tdist = st_local("tdist")!=""
df_r = tdist ? st_numscalar(st_local("df_r")) : .
eform=st_local("eform")!=""
nolimits=st_local("limits")=="nolimits"
xmin=st_numscalar(st_local("xmin"))
xmax=st_numscalar(st_local("xmax"))
ymin=st_numscalar(st_local("ymin"))
ymax=st_numscalar(st_local("ymax"))
fromabs = missing(fromabs) ? abs((ymax-ymin)/(xmax-xmin)) : fromabs
fromabs = missing(fromabs) ? 1 : fromabs
_somdtransf(transf,1,zetafarleft)
_somdtransf(transf,-1,zetafarright)
betafarleft=st_numscalar("c(mindouble)")
betafarright=st_numscalar("c(maxdouble)")


/*
  Extend brackets matrix with first positive and negative beta-brackets
  and corresponding zeta-brackets
*/
zetaleft=censlope_zetastarval(-fromabs)
zetaright=censlope_zetastarval(fromabs)
bracketmat = (
    (-fromabs, zetaleft)
    \ bracketmat
    \ (fromabs, zetaright)
  )


/*
  Beginning of loop over percents.
*/
if(!missing(bracketmat)){
  for(pctlseq=1;pctlseq<=rows(cimat);pctlseq++){


    /*
       Initialize current percent and its zeta-value.
    */
    pctcur=cimat[pctlseq,1]
    _somdtransf(transf , ( 100 :- 2 :* pctcur ) :/ 100 , zetacur)
    if(_bcsf_bracketing(&censlope_zetastarval(),zetacur,zetafarleft,zetafarright,brackets,2,bracketmat,leftindex,rightindex)){
      /*
        Bracketing unsuccessful.
      */
      rcmat[pctlseq,2]=2
      rcmat[pctlseq,3]=1
      rcmat[pctlseq,4]=1
    }
    else{
      /*
        Bracketing successful, so converge brackets and evaluate percentile.
      */
      st_numscalar(st_local("zetatarget"),zetacur)
      subrc1=0
      subrc2=0
      /* Calculate b_l_zetacur */
      if(zetacur==zetafarleft){
        b_l_zetacur=betafarleft
      }
      else{
        betaleft=bracketmat[leftindex,1]
        betaright=bracketmat[rightindex,1]
        zetaleft=bracketmat[leftindex,2]
        zetaright=bracketmat[rightindex,2]
        if(log) printf("\n{txt}Bracket convergence iterations for left estimate for percentile: {res}%-8.0g\n",pctcur)
        subrc1=censlope_bcsf(techniques,techstepmat,betaright,betaleft,(zetaright-zetacur),(zetaleft-zetacur),iterate,tolerance,log)
        if(subrc1 & log) printf("{txt}Convergence not achieved")
        b_l_zetacur=betaleft
      }
      /* Calculate b_r_zetacur */
      if(zetacur==zetafarright){
        b_r_zetacur=betafarright
      }
      else{
        betaleft=bracketmat[leftindex,1]
        betaright=bracketmat[rightindex,1]
        zetaleft=bracketmat[leftindex,2]
        zetaright=bracketmat[rightindex,2]
        if(log) printf("\n{txt}Bracket convergence iterations for right estimate for percentile: {res}%-8.0g\n",pctcur)
        subrc2=censlope_bcsf(techniques,techstepmat,betaleft,betaright,(zetaleft-zetacur),(zetaright-zetacur),iterate,tolerance,log)
        if(subrc2 & log) printf("{txt}Convergence not achieved")
        b_r_zetacur=betaright
      }
      /* Calculate b_c_zetacur */
      if(subrc1|subrc2){
        b_c_zetacur=.
        rcmat[pctlseq,2]=3
        rcmat[pctlseq,3]=1
        rcmat[pctlseq,4]=1
      }
      else if(zetacur==zetafarright){
        b_c_zetacur=b_l_zetacur
      }
      else if(zetacur==zetafarleft){
        b_c_zetacur=b_r_zetacur
      }
      else{
        b_c_zetacur = 0.5*b_l_zetacur + 0.5*b_r_zetacur
      }
      cimat[pctlseq,2] = b_c_zetacur
      rcmat[pctlseq,2] = (subrc1|subrc2) ? 3 : ( missing(b_c_zetacur) ? 4 : 0 )
      if(nolimits){
        /*
          Limits not wanted, so assign them to missing
        */
        cimat[pctlseq,3]=.
        cimat[pctlseq,4]=.
        rcmat[pctlseq,3]=0
        rcmat[pctlseq,4]=0
      }
      else if(!missing(b_c_zetacur)){
        /*
          Percentile calculated, so try to calculate confidence limits.
        */
        if(censlope_zetastarcal(b_c_zetacur,.,hwid)){
          /*
            Standard error calculation unsuccessful.
          */
          rcmat[pctlseq,3]=1
          rcmat[pctlseq,4]=1
        }
        else{
          /*
            Standard error calculations successful, so try to calculate confidence limits.
          */
          hwid = hwid * ( tdist ? invttail(df_r,0.5:*(1:-level:/100)) : invnormal(0.5*(1:+level:/100)) )
          zetalower=zetacur-hwid
          if(nonmissing(zetalower)){
            zetalower = (zetalower>zetafarleft) ? zetafarleft : ( (zetalower<zetafarright) ? zetafarright : zetalower )
          }
          zetaupper=zetacur+hwid
          if(nonmissing(zetaupper)){
            zetaupper = (zetaupper<zetafarright) ? zetafarright : ( (zetaupper>zetafarleft) ? zetafarleft : zetaupper )
          }
          /*
            Calculate lower confidence limit.
          */
          if(missing(zetaupper)){
            /* Zeta could not be calculated. */
            rcmat[pctlseq,3]=1
          }
          else if(_bcsf_bracketing(&censlope_zetastarval(),zetaupper,zetafarleft,zetafarright,brackets,2,bracketmat,leftindex,rightindex)){
            /* Zeta could not be bracketed. */
            rcmat[pctlseq,3]=2
          }
          else if(zetaupper>=zetafarleft){
            /* Confidence limit is infinite. */
            cimat[pctlseq,3]=betafarleft
            rcmat[pctlseq,3]=0
          }
          else{
            /* Confidence limit is finite. */
            betaleft=bracketmat[leftindex,1]
            betaright=bracketmat[rightindex,1]
            zetaleft=bracketmat[leftindex,2]
            zetaright=bracketmat[rightindex,2]
            st_numscalar(st_local("zetatarget"),zetaupper)
            if(log) printf("\n{txt}Bracket convergence iterations for lower confidence limit for percentile: {res}%-8.0g\n",pctcur)
            if(censlope_bcsf(techniques,techstepmat,betaright,betaleft,(zetaright-zetaupper),(zetaleft-zetaupper),iterate,tolerance,log)){
              /* Convergence failed. */
              rcmat[pctlseq,3]=3
              if(log) printf("{txt}Convergence not achieved")
            }
            else{
              /* Convergence successful. */
              cimat[pctlseq,3]=betaleft
              rcmat[pctlseq,3]=0
            }
          }
          /*
            Calculate upper confidence limit.
          */
          if(missing(zetalower)){
            /* Zeta could not be calculated. */
            rcmat[pctlseq,4]=1
          }
          else if(_bcsf_bracketing(&censlope_zetastarval(),zetalower,zetafarleft,zetafarright,brackets,2,bracketmat,leftindex,rightindex)){
            /* Zeta could not be bracketed. */
            rcmat[pctlseq,4]=2
          }
          else if(zetalower<=zetafarright){
            /* Confidence limit is infinite. */
            cimat[pctlseq,4]=betafarright
            rcmat[pctlseq,4]=0
          }
          else{
            /* Confidence limit is finite. */
            betaleft=bracketmat[leftindex,1]
            betaright=bracketmat[rightindex,1]
            zetaleft=bracketmat[leftindex,2]
            zetaright=bracketmat[rightindex,2]
            st_numscalar(st_local("zetatarget"),zetalower)
            if(log) printf("\n{txt}Bracket convergence iterations for upper confidence limit for percentile: {res}%-8.0g\n",pctcur)
            if(censlope_bcsf(techniques,techstepmat,betaleft,betaright,(zetaleft-zetalower),(zetaright-zetalower),iterate,tolerance,log)){
              /* Convergence failed. */
              if(log) printf("{txt}Convergence not achieved")
              rcmat[pctlseq,4]=3
            }
            else{
              /* Convergence successful. */
              cimat[pctlseq,4]=betaright
              rcmat[pctlseq,4]=0
            }
          }
        }
      }
    }


  }
}
/*
  End of loop over percents.
*/


/*
  Exponentiate if eform is specified
*/
if(eform){
  for(pctlseq=1;pctlseq<=rows(cimat);pctlseq++){
    for(cicol=2;cicol<=4;cicol++){
      beta=cimat[pctlseq,cicol]
      cimat[pctlseq,cicol] = ( (beta==betafarleft) ? 0 : ( (beta==betafarright) ? betafarright : exp(beta) ) )
    }
  }
}


/*
  Output Mata scalars and matrices into Stata scalars and matrices.
*/
st_numscalar(st_local("sfromabs"),fromabs)
st_matrix(st_local("cimat"),cimat)
st_matrixcolstripe(st_local("cimat"),cimat_cl)
st_matrix(st_local("rcmat"),rcmat)
st_matrixcolstripe(st_local("rcmat"),cimat_cl)
st_matrix(st_local("bracketmat"),bracketmat)
st_matrixcolstripe(st_local("bracketmat"),bracketmat_cl)

}


real scalar censlope_bcsf(string colvector techniques, real colvector techsteps,
  real scalar x0, real scalar x1, real scalar y0, real scalar y1, real scalar iterate, real scalar tolerance,
  real scalar log)
{
/*
  Bracket convergence for step functions,
  using a user-specified technique sequence.
  The returned result is a return code,
    equal to zero if the brackets converged without error.
  techniques is a string vector of technique names,
    naming techniques to be used in sequence.
  techsteps is a vector of the corresponding iteration numbers
    for the techniques.
  x0 is the zero bracket for the object function,
    at which the object function may be zero,
    or may be of the opposite sign to the object function at the non-zero bracket.
  x1 is the non-zero bracket for the object function,
    at which the object function may not be zero.
  y0 stores the y-value corresponding to x0.
  y1 stores the y-value corresponding to x1.
  iterate is the maximum number of iterations.
  tolerance is the tolerance level for the relative difference.
  log is an indicator that the iterations must be logged,
    recording the brackets and the object functions at the brackets.  
*/


real scalar nitleft, nitsub, itcount, rcsub, ntech, techseq
string scalar technique
/*
  nitleft stores the number of iterations left.
  nitsub stores the number of iterations allowed for the current subroutine.
  itcount stores the iteration count.
  rcsub stores the return code from the current subroutine.
  ntech stores number of technique rows.
  techseq stores the sequential order of a technique.
  technique stores the name of the technique currently being used.
*/

ntech=rows(techniques)
if(ntech!=rows(techsteps)) _error("Inconsistent matrices techniques and techsteps")

/*
  Initialize object function values for iteration zero.
*/
itcount=0
if (log) printf("{txt}Iteration %8.0g:{res} x0 = %8.0g; x1 = %8.0g; y0 = %8.0g; y1 = %8.0g\n",itcount,x0,x1,y0,y1)

/*
  Execute iterations
  until convergence is achieved
  or an iteration cannot be completed
  or maximum iterations are completed without convergence.
*/
nitleft=iterate
while(nitleft>0){
  for(techseq=1;techseq<=ntech;techseq++){
    technique=techniques[techseq]
    nitsub=min((nitleft,techsteps[techseq]))
    if (technique=="bisect") {
      if (log) printf("{txt}(setting iterations to bisection)\n")
      rcsub=_bcsf_bisect(&censlope_zetastarobj(),x0,x1,y0,y1,itcount,nitsub,tolerance,log)
    }
    else if (technique=="regula") {
      if (log) printf("{txt}(setting iterations to regula falsi)\n")
      rcsub=_bcsf_regula(&censlope_zetastarobj(),x0,x1,y0,y1,itcount,nitsub,tolerance,log)
    }
    else if (technique=="ridders") {
      if (log) printf("{txt}(setting iterations to Ridders)\n")
      rcsub=_bcsf_ridders(&censlope_zetastarobj(),x0,x1,y0,y1,itcount,nitsub,tolerance,log)
    }
    else{
      _error("Unspecified technique: " + technique)
    }
    if (rcsub!=1) return(rcsub)
    nitleft=nitleft-nitsub
  }
}

/*
  Maximum iterations completed without convergence.
*/
return(1)

}


real scalar censlope_zetastarobj(real scalar beta)
{
/*
  Calculate and return object function zetastar(beta)-zetatarget,
  where zetatarget is a target zetastar value,
  stored in a temporary Stata scalar with tempname zetatarget.
  beta is the input candidate slope.
*/
real scalar subrc, zetastar, zetatarget
/*
  subrc stores subroutine return codes.
  zetastar stores zetastar(beta).
  zetatarget stores the value of the Stata scalar with that tempname.
*/

/*
  Initialize local matrices and evaluate result
*/
zetastar=censlope_zetastarval(beta)
if(missing(zetastar)){
  _error("Zeta-star could not be calculated")
}
zetatarget=st_numscalar(st_local("zetatarget"))
if(missing(zetatarget)){
  _error("Missing value for target zeta-star")
}
return(zetastar-zetatarget)

}


real scalar censlope_zetastarval(real scalar beta)
{
/*
  Calculate and return zetastar(beta).
  beta is the input candidate slope.
*/
real scalar subrc, zetastar
/*
  subrc stores subroutine return codes.
  zetastar stores zetastar(beta).
*/

/*
  Initialize local matrices and evaluate result
*/
zetastar=.
subrc=censlope_zetastarcal(beta,zetastar)
if(subrc!=0){
  _error("Zeta-star could not be calculated")
}
return(zetastar)

}


real scalar censlope_zetastarcal(real scalar beta, real scalar zetastar, | real scalar sezetastar)
{
/*
  Calculate zetastar(beta) and (optionally) its standard error,
  returning a return code, equal to zero if there are no detectable errors.
  beta is the input value of beta (a candidate percentile slope).
  zetastar is the output estimate of zetastar(beta).
  sezetastar is the output standard error of zetastar(beta).
*/
real scalar subrc
string scalar yvar, xvar, wtexp, touse, ystar
real colvector yvarview,xvarview,ystarview
real matrix b, V
/*
  subrc is the subroutine return code.
  yvar is the name of the Y-variable.
  xvar is the name of the X-variable.
  wtexp is the weight expression.
  touse is the name of the to-use variable.
  ystar is the name of a temporary variable storing values of Ystar=Y-X*beta,
    where Y is the Y-value and X is the X-value,
    and assumed to have been created before any call to censlope_zetastar.
  yvarview is a view of the Y-variable.
  xvarview is a view of the X-variable.
  ystarview is a view of the Ystar variable.
  b will contain the e(b) stored by somersd.
  V will contain the e(V) stored by somersd.
*/

/*
  Initialize local matrices
*/
zetastar=.
if(args()>2){
  sezetastar=.
}
yvar=st_local("yvar")
xvar=st_local("xvar")
wtexp=st_local("wtexp")
touse=st_local("touse")
ystar=st_local("ystar")
st_view(yvarview,.,yvar,touse)
st_view(xvarview,.,xvar,touse)
st_view(ystarview,.,ystar,touse)

/*
  Evaluate Ystar variable
*/
ystarview[.,.] = yvarview - beta * xvarview
if(missing(ystarview)){
  return(1)
}

/*
  Run somersd to evaluate zetastar
  and sezetastar if required
*/
subrc=_stata("somersd " + xvar + " " + ystar + " if " + touse + " " + wtexp + " , " + st_local("somdopts"),1)
if(subrc!=0){
  error(subrc)
  return(2)
}
b=st_matrix("e(b)")
zetastar=b[1,cols(b)]
if(args()>2){
  V=st_matrix("e(V)")
  sezetastar=sqrt(V[rows(V),cols(V)])
}

return(0)

}



end
