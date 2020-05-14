program define sumby
/*
Date: 15/9/95  
New version: 24/9/95 with better heading of Table.
New version: 23/11/97 with varlist instead of one var and nobytot.
New version: 25/11/98 width of column labels shortened if less than 
            width required for display of values.
3/4/2001: test() option added for P-values
Author: Wim van Putten, ErasmusMC, Rotterdam
Creates formatted table of summary statistics of one variable by another variable (optional).
*/

version 4.0
quietly {
  local varlist "req ex min(1) "
  # delimit ;
  local options "BY(string) STat(string) Dec(string) Label(string) 
        Mis Width(int 10) Head noBYTot START(int 12) TEst(string) " ;
  #delimit cr      
  local if "opt"
  local in "opt"
  parse `"`0'"' 
  preserve
  if `"`if'`in'"'~="" { keep `if' `in' }
  if _N==0 {
    noisily display `"`if' `in' : no observations"'
    exit
    }
  tempvar x  NNN colnr _blb
*tempvar _blb _vlab _val NN  NNN SNN CAT  rownr NR
  
if index(upper("`test'"),"KW")>0        { local test K-W }
else if index(upper("`test'"),"K-W")>0  { local test K-W }
else if index(upper("`test'"),"WIL")>0  { local test K-W }
else if index(upper("`test'"),"RANK")>0 { local test K-W }
else if index(upper("`test'"),"TR")>0   { local test trend }
else if index(upper("`test'"),"SP")>0   { local test Spear }
  
  parse "`by'",parse(" ,")
  local by "`1'"             /* Only first string counts as by-variable */
  keep `varlist' `by'
  local nby 1
  if "`by'"~="" {
    unabbrev `by'
    local byname : variable label `by'
        local bytype : type  `by'
    if index("`bytype'","str")>0 {
        replace `by'=trim(`by')
        compress `by'
    }
    if "`byname'"=="" { local byname "`by'" }
    if "`mis'"=="" {     /* Exclude observations missing on by-variable 
                                unless the missing are included as category */
       if index("`bytype'","str")>0 { drop if `by'=="" }
       else { drop if `by'==. }
       if _N==0 {
        noisily display "no observations with `by' non-missing"
            exit
       }
    }
        sort `by' 
        quietly by `by' : gen int `NNN'=1 if _n==1
        gen int `colnr'=sum(`NNN')

    local blb : value label `by'
    if "`blb'"~="" {
       capture label list `blb'
       if _rc>0 {   /* value label not defined */
        local blb 
       }
    }
    if index("`bytype'","str")>0 {
     local w=max(`width',2)
     gen str`w' `_blb' = `by' 
    }
        else {
     if "`blb'"~="" {  decode `by' ,gen(`_blb') }
     else           {  gen str8 `_blb'=string(`by') }
     replace `_blb'=string(`by') if `_blb'==""
    }
    local byby "by(`by')" 
 
       *Create labels for head of Table, if requested
        tab `by',mis
        local nby=_result(2)
        sort `NNN' `colnr'
        local j=1 
        while `j'<=`nby' {
            local bylab`j'= `_blb'[`j']
            local j=`j'+1 
        }
        drop  `NNN' 
  }

  parse "`stat'" ,parse(" ,")
  
  if "`stat'"~="" {
   local i=1
   while "``i''"~="" {
    while "``i''"=="," { macro shift }
    if "``i''"~="" {
     local ST= upper("``i''")
     if "`ST'"=="ALL"|"`ST'"=="_ALL" {
     local ST ="ALL" 
     local i=100 }
     else if "`ST'"=="MEAN"   {  local r`i' 3  }     /*  _result(3)= mean */
     else if "`ST'"=="M"      {  local r`i' 3  }     /*  _result(3)= mean */
     else if "`ST'"=="MED"    {  local r`i' 10  }    /*  _result(10)= median */
     else if "`ST'"=="MEDIAN" {  local r`i' 10  }    /*  _result(10)= median */
     else if "`ST'"=="Q2"     {  local r`i' 10  }    /*  _result(10)= median */
     else if "`ST'"=="N"      {  local r`i' 1  }     /*  _result(1)= number of observations */
     else if "`ST'"=="NR"     {  local r`i' 1  }     /*  _result(1)= number of observations */
     else if "`ST'"=="SD"     {  local r`i' 4  }     /*  _result(4)= variance !! */
     else if "`ST'"=="R"      {  local r`i' 56  }    /*  range to be derived from _results 5 and 6 */
     else if index("`ST'","RA")==1 { local r`i' 56  } /*  range to be derived from _results 5 and 6 */
     else if "`ST'"=="MSD" {     local r`i' 34  }     /*  mean+/-sd to be derived from from _results 3 and 4 */
     else if "`ST'"=="MIN" {     local r`i' 5  }      /*  _result(5)= min */
     else if "`ST'"=="MAX" {     local r`i' 6  }      /*  _result(6)= max */
     else if "`ST'"=="Q1"  {     local r`i' 9  }      /*  _result(9)= Q1 25th percentile */
     else if "`ST'"=="Q3"  {     local r`i' 11  }     /*  _result(11)= Q3 75th percentile */
     else if "`ST'"=="P5"  {     local r`i' 7  }      /*  _result(7)= 5th percentile */
     else if "`ST'"=="P05" {     local r`i' 7  }      /*  _result(7)= 5th percentile */
     else if "`ST'"=="P95" {     local r`i' 13  }     /*  _result(13)= 95th percentile */
     else if "`ST'"=="P1"  {     local r`i' 16  }     /*  _result(16)= 1th percentile */
     else if "`ST'"=="P01"  {    local r`i' 16  }     /*  _result(16)= 1th percentile */
     else if "`ST'"=="P99"  {    local r`i' 17  }     /*  _result(17)= 99th percentile */
     else if "`ST'"=="P10"  {    local r`i' 8  }      /*  _result(8)= 10th percentile */
     else if "`ST'"=="P90"  {    local r`i' 12  }     /*  _result(12)= 90th percentile */
     else  {
     noisily display "Program stopped. ``i'' is not a valid statistics abbreviation."
     exit  
     }
     local i=`i'+1 
    }
   }
   local ns= `i'-1     /* Number of different statistics */
  
   if "`ST'"=="ALL" {
     local r1 1
     local r2 34
     local r3 56
     local r4 7
     local r5 9
     local r6 10
     local r7 11
     local r8 13
     /* for date formatted variables: */
     local rr1d 1
     local rr2d 5
     local rr3d 7
     local rr4d 9
     local rr5d 10
     local rr6d 11
     local rr7d 13
     local rr8d 6
     global l1d "Number"
     global l2d "Minimum"
     global l3d " 5 %"
     global l4d "Q1"
     global l5d "Median"
     global l6d "Q3"
     global l7d "95 %"
     global l8d "Maximum"
     local ns = 8 
   }
  }
  else if "`stat'"=="" {
     local r1 34
     local r2 56
     local r3 10
     local r4 1
     /* for date formatted variables: */
     local rr1d 5
     local rr2d 10
     local rr3d 6
     local rr4d 1
     global l1d "Minimum"
     global l2d "Median"
     global l3d "Maximum"
     global l4d "Number"
     local ns = 4 
  }
  local i=1
  while `i'<=`ns' {
    local rr`i' `r`i''
    local i=`i'+1
  }

  parse "`dec'" ,parse(" ,")   /* Number of decimals per statistic */
  local i=1
  while `i'<=`ns' {
   while "``i''"=="," { macro shift }
   if `r`i''== 1 {  /* Number of observations always without decimals */
    local dec`i' = 0 
    local date`i'  
   }
   else if "``i''"=="."|"``i''"=="" { local dec`i' . } 
   else {   local dec`i' ``i'' }
   local i=`i'+1 
  }
  
  
  parse "`label'" ,parse(" ,")   /* Specifies labels */
  local i=1
  while `i'<=`ns' {
   if "``i''"=="," { macro shift }
   if "``i''"=="."|"``i''"=="" {
    if `r`i''==3       { global l`i' "Mean" }
    else if `r`i''==1  { global l`i' "Number" }
    else if `r`i''==4  { global l`i' "SD"      }
    else if `r`i''==5  { global l`i' "Minimum" }
    else if `r`i''==16 { global l`i' " 1 %"      }
    else if `r`i''==7  { global l`i' " 5 %"      }
    else if `r`i''==8  { global l`i' "10 %"      }
    else if `r`i''==9  { global l`i' "Q1"      }
    else if `r`i''==10 { global l`i' "Median" }
    else if `r`i''==11 { global l`i' "Q3"      }
    else if `r`i''==12 { global l`i' "90 %"      }
    else if `r`i''==13 { global l`i' "95 %"      }
    else if `r`i''==17 { global l`i' "99 %"      }
    else if `r`i''==6  { global l`i' "Maximum" }
    else if `r`i''==56 { global l`i' "Range"  }
    else if `r`i''==34 { global l`i' "Mean;SD" }
   }
   else                { global l`i'  "``i''" }
   local rtot `rtot' `r`i''
   local i=`i'+1 
  }
  *Increase width if specified width<=8 on the basis of the width that
  * would be required to display statistics for the max of the variables.
  * In case of variables with date-format, the width will be made sufficient 
  * to display the maximum date in the chosen date format
  parse "`varlist'",parse(" ")
  while "`1'"!=""&`width'<=8 {
    local format:format `1'
    local format =subinstr("`format'","td","d",1)  /* 14/1/2004 %td is equivalent to %d in Stata 8 */
    if substr("`format'",2,1)~="d" {
      su `1'
      if _result(1)>0 {
        local mean=length(string(int(_result(3))))
        if _result(3)<0&`mean'==1 {local mean=2 }
        local min=length(string(int(_result(5))))
        if _result(5)<0&`min'==1 {local min=2 }
        local max=length(string(int(_result(6))))
        local sd =length(string(int((_result(4))^.5)))
        if index("`rtot'","56")>0 {local width =max(`width',`min'+`max'+1)}
        if index("`rtot'","34")>0 {local width =max(`width',`mean'+`sd'+1)}
        local width =max(`width',`max')
        if index("`rtot'","1")>0  {local width =max(`width',length(string(_result(1))))}
      }
    }
    else {  /* In case of date-format */
      su `1'
      if _result(1)>0 {
        local max=_result(6)
        fns a `max' ,date(`format') width(`width')
        global a $a
        local width =max(`width',length("$a"))
      }
    }
    macro shift
  }

}/* end quietly */  

local Ppos=`start'+`nby'*`width' /* Pos for P value */

local start1=`start'-1
*Display header if requested
if "`head'"~="" &"`by'"~="" {
        local maxl=`width'
        display _col(`start') "|  `byname' " 
        display _col(`start') "|"   _continu
              local j=1 
              while `j'<=`nby' {
            local bylab`j'=substr("`bylab`j''",1,`width')
            local skip=`maxl'-length("`bylab`j''")
            display _skip(`skip') "`bylab`j'' " _contin
            local j= `j'+1 }
    if "`bytot'"==""|"`by'"=="" {
            display "|" _cont  
            local skip=max(0,`maxl'-length("Total"))
            display  _skip(`skip') "Total " 
    }      
    else {display " " }
    display _dup(`start1') "-" _dup(1) "+" _continue 
        local j=`nby'*(`maxl'+1)
    if "`bytot'"==""|"`by'"=="" { display _dup(`j') "-" "+" _dup(`maxl') "-" }
    else  {
        local j=`j'-1
        display _dup(`j') "-" 
    }
}          

local w8=`width'
local w4=int((`w8'-2)/2)

*Loop over varlist
parse "`varlist'" ,parse(" ,")
while "`1'"~="" {
  quietly {
   local type: type `1'
   if index("`type'","str")==0 { /* no statistics for string variables */
    if "`type'"=="int"|"`type'"=="long"|"`type'"=="byte" { local type int }
    global varlab : variable label `1'
    if "$varlab"=="" {  global varlab `1'}
    local format:format `1'
    local format =subinstr("`format'","td","d",1)  /* 14/1/2004 %td is equivalent to %d in Stata 8 */
    if substr("`format'",2,1)=="d" {
        local date `format' 
        local format = 0 
    }
    else {
     local date  
     local p= index("`format'",".")
     if `p'>0 { local format=int(real(substr("`format'",`p'+1,1))) }
     /*Default number of decimals*/
     else { local format =0 }
    }

    *Modify the requested statistics in case of date format
    local d
    if "`date'"~=""&"`rr1d'"~="" { local d d }
    local i=1
    while `i'<=`ns' {
        local r`i' `rr`i'`d''
    local i=`i'+1
    }
    /* Number of decimals per statistic adapted to variable*/
    local i=1
    while `i'<=`ns' {
      while "``i''"=="," {  macro shift }
      if `dec`i''== . { local d`i' = `format'} 
      else            { local  d`i' `dec`i'' }
      if "`date'"~="" {
    if `r`i''~=4&`r`i''~=1  {local date`i' date(`date') }
    else          {
        local date`i' 
    }
      }
      else {
    local date`i'
    if "`type'"=="int"&index("34","`r`i''")==0 {local d`i' 0 }
    /* All percentiles of integer variables are rounded and
       given without decimals */
      }
      local i=`i'+1 
    }
        

    *Statistics for total-column if requested or no by-groups
    su `1',det
    global nobs=_result(1) /* if no observations calculations not required!!*/

    if $nobs>0&("`bytot'"==""|"`by'"=="") {
        local i=1
        while `i'<=`ns' {
            if `r`i''~=34&`r`i''~=4&`r`i''~=56 {
              local x1 =_result(`r`i'')
              fns  a `x1' ,w(`w8') d(`d`i'') `date`i''
            }
            else if `r`i''==4 {
              local x1 =(_result(4))^.5
              fns  a `x1' ,w(`w8') d(`d`i'')  
            }
            else if `r`i''==34 {
              local x1 =(_result(3))
              local x2 =(_result(4))^.5
              fns  a `x1' ,w(`w4') d(`d`i'') `date`i''  
              fns  b `x2' ,w(`w4') d(`d`i'')   
              global a "${a};${b}" 
                }
            else if `r`i''==56 {
              local x1 =(_result(5))
              local x2 =(_result(6))
              fns  a `x1' ,w(`w4') d(`d`i'') `date`i''  
              fns  b `x2' ,w(`w4') d(`d`i'') `date`i''  
              global a "${a}-${b}" 
                }
                global s`i'="$a"
                local i=`i'+1 
        }
    }   /* end Statistics for total-column */
    
    *Statistics within by-groups (if by defined)
    if "`by'"~=""&$nobs>0 {
        local pval 
        if "`test'"=="K-W" {
            kwallis `1',by(`by') 
            local chi2=r(chi2_adj)            /* 20/8/2004 adapted WvP analoog aan tabby */
            if `chi2'==. { local chi2=r(chi2)}
            local pval=chi2tail(r(df),`chi2')
            *   local pval=chi2tail(r(df),r(chi2))  voorheen unadjusted
        }
        else if "`test'"=="trend" {
                nptrend `1',by(`by')
                local pval =r(p)
        }
        else if "`test'"=="Spear" {
                spearman `1' `by'
                local pval = r(p)
        }
            
         local j=1 
         while `j'<=`nby'{
           su `1' if `colnr'==`j',det
           local i=1
           while `i'<=`ns' {
             if _result(1)==0&`r`i''~=1     {  global a  - }
             else if _result(1)==0&`r`i''==1{  global a  0 }
             else if `r`i''~=34&`r`i''~=4&`r`i''~=56 {
              local x1 =_result(`r`i'')
              fns  a `x1' ,w(`w8') d(`d`i'') `date`i''
             }
             else if `r`i''==4 {
              if _result(1)>1 {
                local x1 =(_result(4))^.5
                fns  a `x1' ,w(`w8') d(`d`i'')  
          }
              else { global a "--" }    /* SD only if at least 2 observations */
             }
             else if `r`i''==34 {
              local x1 =(_result(3))
              fns  a `x1' ,w(`w4') d(`d`i'')   `date`i''
              local x2 =(_result(4))^.5
              if _result(1)>1 {
                local x2 =(_result(4))^.5
                fns  b `x2' ,w(`w4') d(`d`i'')   
          }
              else { global b "--" }     /* SD only if at least 2 observations */
              global a "$a;$b"
             }
             else if `r`i''==56 {
              local x1 =(_result(5))
              local x2 =(_result(6))
              fns  a `x1' ,w(`w4') d(`d`i'')   `date`i''
              fns  b `x2' ,w(`w4') d(`d`i'')   `date`i''
              global a "$a-$b"
             }
             global s`i'_`j'="$a"
             local i=`i'+1
           }  /* end while i */
           local j= `j'+1
         } /* end while j */
    } /* end if by:  Statistics within by-groups */
    
    *Adapt max column width of all numeric strings to be displayed.
    local maxl=`width'
    local i=1
    while `i'<=`ns' {
    if "`bytot'"==""|"`by'"=="" {local maxl =max(`maxl',length("${s`i'}")) }
        if "`by'"~="" {
          local j = 1
          while `j'<=`nby' {
            local maxl =max(`maxl',length("${s`i'_`j'}"))
            local j=`j'+1 
          }
        }
        local i= `i'+1 
    }
   }
  } /* end quietly */

  if index("`type'","str")==0 { /* no statistics for string variables */
   if $nobs==0 { display "$varlab : no observations "}
   else {
    if "`pval'"!="" {
      display "$varlab" _col(`Ppos') "(P=" %5.3f `pval' ", `test')"
    }
    else { display "$varlab" }
    
    local i=1
    while `i'<=`ns' {
        if "`date'"~=""&"`rr1d'"~="" { 
            display _col(3) "${l`i'd}" _col(`start')   _continu
    }
    else {  display _col(3) "${l`i'}" _col(`start')   _continu }
        if "`by'"~="" {
          display     "|"      _continu
          local j=1 
          while `j'<=`nby' {
            local skip=`maxl'-length("${s`i'_`j'}")
            display _skip(`skip') "${s`i'_`j'} " _contin
            local j= `j'+1 
      }
      if "`bytot'"=="" {
              display "|" _cont  
              local skip=`maxl'-length("${s`i'}")
              display  _skip(`skip') "${s`i'} " 
      }
      else {display " "}
        }
        else {
          display  _skip(1) "|" _cont  
          local skip=1+`maxl'-length("${s`i'}")
          display  _skip(`skip') "${s`i'} " 
        }
        local i= `i'+1 
    }
   }
   display " "
  }
  macro shift
} /* end while loop over varlist */
end
