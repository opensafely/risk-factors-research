{smcl}
{* 18feb2014}{...}
{cmd:help for ice, uvis}{right:Patrick Royston}
{hline}


{title:Title}

{p2colset 5 12 14 2}{...}
{p2col :{hi:ice} {hline 2}}Multiple imputation by the MICE system of chained equations{p_end}
{p2colreset}{...}


{title:Syntax}

{phang2}
{cmd:ice}
[{it:mainvarlist}]
{ifin}
{weight}
[{cmd:,} {it:major_options less_used_options}]

{phang2}
{cmd:uvis}
{it:cmd}
{{it:yvar}|{it:llvar ulvar}}
{it:xvars}
{ifin}
{weight}
[{cmd:,} {it:options}]


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :{cmd:ice} {it:major_options}}
{synopt :{opt clear}}clears the original data from memory and loads the imputed dataset into memory{p_end}
{synopt :{opt dry:run}}reports the prediction equations - no imputations are done{p_end}
{synopt :{opt eq(eqlist)}}defines customised prediction equations{p_end}
{synopt :{opt m(#)}}defines the number of imputations{p_end}
{synopt :{opt ma:tch(varlist)}}predictive mean matching for each member of {it:varlist}{p_end}
{synopt :{opt pass:ive(passivelist)}}passive imputation{p_end}
{synopt :{cmdab:sav:ing(}{it:filename} [{opt ,replace}]{cmd:)}}imputed and non-imputed variables
are stored to {it:filename}{p_end}
{synopt :{opt stepwise}}constructs prediction equations by stepwise variable selection{p_end}
{synopt :{opt sw:opts(stepwise_options)}}options for {opt stepwise}{p_end}

{syntab :{cmd:ice} {it:stepwise_options}}
{synopt :{opt forward}}perform forward-stepwise selection{p_end}
{synopt :{opt gr:oup(group_list)}}create groups of variables for joint testing for addition or removal{p_end}
{synopt :{opt lo:ck(varlist)}}Variables to be kept in all models{p_end}
{synopt :{opt pe(#)}}significance level for addition to a model{p_end}
{synopt :{opt pr(#)}}significance level for removal from a model{p_end}
{synopt :{opt sh:ow}}show each stepwise regression{p_end}

{syntab :{cmd:ice} {it:less_used_options}}
{synopt :{opt allm:issing}}imputes in observations with all values in {it:mainvarlist} missing{p_end}
{synopt :{opt bo:ot(varlist)}}estimates regression coefficients
for {it:varlist} in a bootstrap sample{p_end}
{synopt :{opt by(varlist)}}imputation within the levels implied by {it:varlist}{p_end}
{synopt :{opt cc(varlist)}}prevents imputation of missing data in observations
in which {it:varlist} has a missing value{p_end}
{synopt :{opt cm:d(cmdlist)}}defines regression command(s) to be used for imputation{p_end}
{synopt :{opt cond:itional(condlist)}}conditional imputation{p_end}
{synopt :{opt cy:cles(#)}}determines number of cycles of regression switching{p_end}
{synopt :{opt de:bug}}assistance to debug individual regressions{p_end}
{synopt :{opt drop:missing}}omits from the output all observations
not in the estimation sample{p_end}
{synopt :{opt eqd:rop(eqdroplist)}}removes variables from prediction equations{p_end}
{synopt :{opt g:enmiss(string)}}creates missingness indicator variable(s){p_end}
{synopt :{opt i:d(varname)}}creates {it:varname} containing
the original sort order of the data{p_end}
{synopt :{opt init:ialonly}}impute by random sampling from distribution of non-missing values{p_end}
{synopt :{opt int:erval(intlist)}}imputes interval-censored variables{p_end}
{synopt :{opt matchp:ool(#)}}size of pool of potential matches for predictive mean matching{p_end}
{synopt :{opt mono:tone}}assumes pattern of missingness is monotone, and
creates relevant prediction equations{p_end}
{synopt :{opt nocons:tant}}suppresses the regression constant{p_end}
{synopt :{opt nopp}}suppresses special treatment of perfect prediction{p_end}
{synopt :{opt nosh:oweq}}suppresses presentation of prediction equations{p_end}
{synopt :{opt nover:bose}}suppresses messages showing the progress of the imputations{p_end}
{synopt :{opt nowarn:ing}}suppresses warning messages{p_end}
{synopt :{opt on(varlist)}}imputes each member of {it:mainvarlist} univariately{p_end}
{synopt :{opt ord:erasis}}enters the variables in the order given{p_end}
{synopt :{opt per:sist}}ignore errors when trying to impute "difficult" variables and/or models{p_end}
{synopt :{cmdab:res:trict(}[{varname}] [{it:{help if}}]{cmd:)}}fit
         models on a specified subsample, impute missing data for entire estimation sample{p_end}
{synopt :{opt se:ed(#)}}sets random number seed{p_end}
{synopt :{opt sub:stitute(sublist)}}substitutes dummy variables for
multilevel categorical variables{p_end}
{synopt :{opt tr:ace(trace_filename)}}monitors convergence of the imputation algorithm{p_end}

{syntab :{cmd:uvis} {it:options}}
{synopt :{opt g:en(newvarname)}}creates variable containing imputations. {opt Not optional}{p_end}
{synopt :{opt bo:ot}}estimates regression coefficients in a bootstrap sample{p_end}
{synopt :{opt by(varlist)}}imputation within the levels implied by {it:varlist}{p_end}
{synopt :{opt lrd}}imputes using local residual draws{p_end}
{synopt :{opt ma:tch}}does predictive mean matching{p_end}
{synopt :{opt matchp:ool(#)}}size of pool of potential matches for predictive mean matching{p_end}
{synopt :{opt matchtype(#)}}sets the method for identifying closest matches{p_end}
{synopt :{opt nopp}}suppresses special treatment of perfect prediction{p_end}
{synopt :{opt nover:bose}}suppresses information about the imputation process{p_end}
{synopt :{opt replace}}overwrites {it:newvarname} if it exists{p_end}
{synopt :{cmdab:res:trict(}[{varname}] [{it:{help if}}]{cmd:)}}fit
         models on a specified subsample, impute missing data for entire estimation sample{p_end}
{synopt :{opt se:ed(#)}}sets random number seed{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
where {it:cmd} (with {opt uvis}) may be
{help intreg},
{help logistic},
{help logit},
{help mlogit},
{help nbreg},
{help ologit},
or
{help regress}. {it:llvar} {it:ulvar} are required with {cmd:intreg}.

{pstd}
An element of {it:mainvarlist} for {cmd:ice} takes one of two forms:
{it:varname} or [{hi:i.}|{hi:m.}|{hi:o.}]{it:varname}.
Details are given in
{help ice##special:Special features for imputing categorical variables}.
If {it:mainvarlist} is omitted, variables and chained equations are input from
special global macros; see the {cmd:eq()} and {opt stepwise} options for
details.


{pstd}
All weight-types are supported.

{pstd}
{bf:{ul:Stata 11 users:}} Please see {help mi ice}, which does all that {cmd:ice}
does and a little bit more, and is conveniently integrated into the new
{help mi} system.


{title:Description}

{pstd}
{cmd:ice} imputes missing values
in {it:mainvarlist} by using switching regression, an iterative multivariable
regression technique. The abbreviation MICE means multiple imputation by
chained equations, and was apparently coined by Stef van Buuren. {cmd:ice}
implements MICE for Stata. Sets of imputed and non-imputed variables are
stored to a new file called {it:filename}. Any number of complete imputations
may be created. The original data are stored in {it:filename} as
"imputation number 0" and the new variable {cmd:_mj} is set to 0 for these
observations.

{pstd}
{cmd:uvis} ({cmd:u}ni{cmd:v}ariate {cmd:i}mputation {cmd:s}ampling) imputes
missing values in the single variable {it:yvar} based on multiple regression
on {it:xvars}. {cmd:uvis} is called repeatedly by {cmd:ice}
in a regression switching mode to perform multivariate imputation.

{pstd}
The missing observations are assumed to be "missing at random" (MAR) or
"missing completely at random" (MCAR), according to the jargon.
See for example van Buuren {it:et al}
(1999) for an explanation of these concepts.

{pstd}
Please note that {cmd:ice} and {cmd:uvis} require Stata 8.0 or higher.
There have been incompatibility issues with Stata 7 or lower.

{pstd}
{marker special}{...}
{ul:{hi:Special features for imputing categorical variables}}

{pstd}
The prefixes {hi:i.}, {hi:m.} and {hi:o.} for a variable in
{cmd:ice}'s {it:mainvarlist} are a convenience feature designed
to simplify specification of the imputation model for categorical
variables with three or more levels. You should hardly ever need to
use Stata's {cmd:xi} dummy variable and interaction creator directly with
{cmd:ice} commands, since dummy variables and more are adequately
handled by using the {hi:i.}, {hi:m.} and {hi:o.} prefixes.

{pstd}
The prefix {hi:i.} in {hi:i.}{it:varname} may be used only when
{it:varname} has no missing data. It applies {cmd:xi} to
{hi:i.}{it:varname} to create the corresponding dummy variables.
If {it:varname} has missing data, imputation is required; either
the {hi:m.} or the {hi:o.} prefix (see below) should be used with
such variables. See
{help ice##pitfalls:Pitfalls in using the {hi:i.} prefix}
for further information.

{pstd}
Use of {hi:m.}{it:varname} or {hi:o.}{it:varname} substitutes {hi:i.} for
{hi:m.} or {hi:o.} and applies
{cmd:xi:} to {hi:i.}{it:varname}, at the same time
telling {cmd:ice} to impute missing values of {it:varname}
using the {cmd:mlogit} or {cmd:ologit} commands,
respectively. Use of the {hi:m.} or {hi:o.} prefixes also ensures that the corresponding
dummy variables are used as predictors in imputation models for other
variables (see {help ice##substitute:substitute()})
and are 'passively' imputed (see {help ice##passive:passive()}).
Suppose that {hi:x} is a multilevel categorical variable.
Then {cmd:ice o.x}{it: varlist}{cmd:,}{it: options} is expanded to
{cmd:xi: ice x i.x}{it: varlist}{cmd:, substitute(x:i.x) cmd(x:ologit)}{it: options}.
Similary, {cmd:ice m.x}{it: varlist}{cmd:,}{it: options} is expanded to
{cmd:xi: ice x i.x}{it: varlist}{cmd:, substitute(x:i.x) cmd(x:mlogit)}{it: options}.

{pstd}
The resulting 'expanded' version of the {cmd:ice} command
is stored in the {cmd:$F9} global macro. It can be retrieved if desired by
pressing the F9 key.

{pstd}
Note that the {hi:i.}, {hi:m.} and {hi:o.} prefixes are also valid with binary
variables, although much less likely to be useful since one would not wish
to impute a binary variable using either {cmd:mlogit} or {cmd:ologit}.


{title:Options}

{dlgtab:ice (major options)}

{phang}
{opt clear} clears the original data from memory and loads the imputed dataset.
Unless the {opt saving()} option is also specified, the data in memory are
not permanently saved; this must then be done manually using the {help save}
or {help saveold} commands.

{phang}
{opt dryrun} causes {cmd:ice} to report the prediction equations
it has constructed from the various inputs, but no imputations
are done and no files are created. The option name ("dryrun")
may be abbreviated as {opt dry}. It is not mandatory to specify
an output file with {opt saving(filename)} for a dry run.
Sometimes the prediction equation set-up needs to be carefully
checked before running what may be a lengthy imputation process.
Note that stepwise selection of prediction equations ({opt stepwise}
option) still works when {opt dryrun} has been specified.

{phang}
{marker eq}{opt eq(eqlist)} allows one to define prediction
equations for any subset of variables in {it:mainvarlist}. The {opt eq()}
option, particularly when used with {cmd:passive()}, allows
great flexibility in the possible imputation schemes. Note that {cmd:eq()}
takes precedence over all default definitions and assumptions about 
the way a given variable in {it:mainvarlist} is to be imputed.
If the {cmd:passive()} and {cmd:substitute()} options are not invoked, 
the default set of equations is that each variable in {it:mainvarlist}
with any missing data is imputed from all other variables in {it:mainvarlist}.

{pmore}
When {opt eq()} is specified, the syntax of {it:eqlist} is
{it:varname1}{cmd::}{it:varlist1}
[{cmd:,}{it:varname2}{cmd::}{it:varlist2} ...] where each
{it:varname#} (or {it:varlist#})
is a member (or subset) of {it:mainvarlist}. Variable names
prefixed by {cmd:i.} are allowed, provided that the names
were prefixed by {hi:i.}, {hi:m.} or {hi:o.} in {it:mainvarlist}.
They are translated to the corresponding dummy variables created 
by {cmd:xi:}.

{pmore}
A 'blank' (null, constant-only) equation is specified as {cmd:_cons},
for example, {cmd:eq(x4 x5:_cons)}. Such equations are reported in the table
of prediction equations as "{cmd:[Empty equation]}". The prediction
model for variables with empty equations is simply {cmd:_cons}.

{pmore}
If {it:mainvarlist} is omitted, {cmd:ice} takes {it:mainvarlist}
from the global macro {cmd:$ice_main} and the equations, regression
commands and predicted variables from global macros {cmd:$ice_eq}{it:#},
{cmd:$ice_cmd}{it:#} and {cmd:$ice_x}{it:#}, respectively, for
{it:#} = 1, ..., {cmd:$ice_neq}. The number
of equations is stored in {cmd:$ice_neq}. These macros are created
automatically when {cmd:ice}'s {opt stepwise} option is used (see details
under {opt stepwise}). They may also be user-defined. The macros may be
inspected in Stata by using the command {cmd:macro list ice_*}.

{phang}
{opt m(#)} defines {it:#} as the number of imputations required
(minimum 1, no upper limit). The default {it:#} is 1.

{phang}
{marker match}{cmd:match}[{cmd:(}{it:varlist}{cmd:)}] instructs that each member of
{it:varlist} be imputed with the {cmd:match} option of {cmd:uvis}.
This provides predictive mean matching for each member of {it:varlist}.
If {cmd:(}{it:varlist}{cmd:)} is omitted then all relevant variables are
imputed with the {cmd:match} option of {cmd:uvis}. The default, if
{cmd:match()} is not specified, is to draw from the posterior
predictive distribution of each variable requiring imputation.

{marker passive}{...}
{phang}
{opt passive(passivelist)} allows the use of "passive" imputation
of variables that depend on other variables, some of which are imputed.
The syntax of {it:passivelist} is {it:varname}{cmd::}{it:exp}
[{cmd:\}{it:varname}{cmd::}{it:exp} ...]. Notice the requirement to use
"\" as a separator between items in {it:passivelist}, rather than the usual comma;
the reason is that a comma may be a valid part of an expression.
The option is most easily explained by example. Suppose x1 is a categorical variable
with 3 levels, and that two dummy variables x1a, x1b have been created by the commands

{pin}
     {cmd:. generate byte x1a=(x1==2)}{break}
     {cmd:. generate byte x1b=(x1==3)}

{pin}
Now suppose
that x1 is to be imputed by the {cmd:mlogit} command, and is to be treated
as the two dummy variables x1a and x1b when predicting other variables.
Use of {cmd:mlogit} is achieved by the option {cmd:cmd(x1:mlogit)}.
When x1 is imputed, we want x1a and x1b to be updated with new values
which depend on the imputed values of x1.
This may be achieved by specifying {cmd:passive(x1a:x1==2 \ x1b:x1==3)}. It
is necessary also to remove x1 from the list of predictors when variables
other than x1 are being imputed, and this is done by using the
{cmd:substitute()} option; in the present example, you would specify
{cmd:substitute(x1:x1a x1b)}.

{pin}
Note that although in this example x1a will take the (possibly
unintended) value of 0 when x1 is missing, {cmd:ice} is careful to
ensure that x1a (and x1b) inherit the missingness of x1, and are
passively imputed following active imputation of missing values
of x1. If this were not done, incorrect results could occur. The
responsibility of the user is to create x1a and x1b before running
{cmd:ice} such that their missing values are identical
to those of x1.

{pin}
A second example is multiplicative interactions between variables, for
example, between x1 and x2 (e.g. x12=x1*x2); this could be entered as
{cmd:passive(x12:x1*x2)}. It would cause the interaction term
x12 to be omitted when either x1 or x2 was being imputed, since it would
make no sense to impute x1 from its interaction with x2.
{cmd:substitute()} is not needed here.

{pin}
It should be stressed that variables to be imputed passively
must already exist and must be included in {it:mainvarlist}, otherwise they
are not recognised. Passive variables may be defined in terms
of variables in {it:mainvarlist} and variables not in {it:mainvarlist},
although it would of course make no sense not to involve at least one
variable in {it:mainvarlist}.

{phang}
{cmd:saving(}{it:filename} [{cmd:,replace}]{cmd:)} saves the imputation to
{it:filename}. {opt replace} allows {it:filename} to be overwritten
with new data. {cmd:replace} may not be abbreviated.

{phang}
{opt stepwise} constructs prediction equations by stepwise variable selection
among members of {it:mainvarlist}. There are 3 steps to the process. First,
{cmd:ice} creates a dataset with 1 imputation using a randomly drawn subset
of values from the distribution of each variable with missing values. (This is
the standard initialisation step for {cmd:ice}, and is invoked automatically
by the {opt initialonly} option.) Next, {cmd:ice} runs {helpb stepwise} to
select variables for each prediction equation. Binary dummy variables
are treated appropriately. By default, forward selection at a 5% significance
level is used; see the {opt swopts()} option for other possibilities. Finally,
{cmd:ice} retrieves the reduced equations and performs imputation with
them as usual.

{pmore}
Using {opt stepwise} also causes {cmd:ice} to store {it:mainvarlist}, the
selected equations, variables and commands in global macros called
{cmd:$ice_*}, as described under the {opt eq()} option.

{phang}
{opt swopts(stepwise_options)} allows the following {it:stepwise_options}
for use with {cmd:stepwise}:
{opt forward}, {opt group(group_list)}, {opt lock(varlist)},
{opt pe(#)}, {opt pr(#)} and {opt show}. Note that only
{opt pe(#)}, {opt pr(#)} and {opt forward} are standard options of Stata's
{cmd:stepwise} command; the remainder are used to group variables for
joint testing for inclusion or exclusion from the models, to construct a
list of variables formatted for use with {cmd:stepwise}'s {opt lockterm1}
option, and to show the output from {cmd:stepwise}. Further details of
individual options are given below under {cmd:ice} ({it:stepwise options}).

{pmore}
Specifying neither {opt pe(#)} nor {opt pr(#)} is equivalent to specifying
{cmd:pe(0.05)}, i.e. the default method is forward selection of variables
significant at the 5% level.

{pmore}
Note that variables in {it:mainvarlist} that have the prefix {cmd:i.},
indicating that they are categorical, are to be represented by their
dummy variables and have no missing data, should retain their
{cmd:i.} prefix when they are included in the {opt group()} or
{opt lock()} options.

{dlgtab:ice (stepwise options)}

{phang}
{opt forward} specifies the forward-stepwise method and may be specified
only when both {opt pr()} and {opt pe()} are also specified. Specifying
both {opt pr()} and {opt pe()} without {opt forward} results in
backward-stepwise selection. Specifying only {opt pr()} results in backward
selection, and specifying only {opt pe()} results in forward selection.

{phang}
{opt group(group_list)} specifies variables always to be tested jointly for
inclusion or exclusion from models. An element of {it:group_list}
is a {it:varlist}, and elements are separated by commas, for example
{cmd:group(x1 i.x2, y1 y2)}. Such groups of variables (or, in the case
of categorical variables prefixed with {cmd:i.}, their implied dummy variables)
are surrounded by parentheses when presented to {cmd:stepwise} for analysis.

{phang}
{opt lock(varlist)} specifies variables to be kept in all models. Such
variables are surrounded by parentheses when presented to {cmd:stepwise}
for analysis. The {opt lockterm1} option of {cmd:stepwise} is applied to them.

{phang}
{opt pe(#)} specifies the significance level for addition to the model;
terms with p < {opt pe()} are eligible for addition.

{phang}
{opt pr(#)} specifies the significance level for removal from the model;
terms with p >= {opt pr()} are eligible for removal.

{phang}
{opt show} displays the output from {cmd:stepwise} for each regression
analysis to develop the prediction equations used by {cmd:ice}.

{dlgtab:ice (less used options)}

{phang}
{opt allmissing} imputes missing values in observations in which all
variables in {it:mainvarlist} are missing. The default is to leave such values
as missing.

{phang}
{cmd:boot}[{cmd:(}{it:varlist}{cmd:)}] instructs that each member of {it:varlist},
a subset of {it:mainvarlist}, be imputed with the {cmd:boot} option of {cmd:uvis}
activated. If {cmd:(}{it:varlist}{cmd:)} is omitted then all members of {it:mainvarlist}
with missing observations are imputed using the {opt boot} option of {opt uvis}.

{phang}
{opt by(varlist)} performs multiple imputation separately for all combinations of
variables in {it:varlist}. Observations with missing values for any
members of {it:varlist} are excluded. May be combined with {opt restrict()}.

{phang}
{opt cc(varlist)} prevents imputation of missing data in {it:mainvarlist} for
cases in which any member of {it:varlist} has a missing value. "cc" signifies
"complete case". Note that members of {it:varlist} are used for imputation if they appear
in {it:mainvarlist}, but not otherwise. Use of this option is equivalent to entering
{cmd:if} {cmd:~missing(}{it:var1}{cmd:) &} {cmd:~missing(}{it:var2}{cmd:)} ..., where
{it:var1}, {it:var2}, ... denote the members of {it:varlist}.

{phang}
{marker cmd}{opt cmd(cmdlist)} defines the regression commands to be used
for each variable in {it:mainvarlist}, when it becomes the dependent variable in the
switching regression procedure used by {cmd:uvis}
(see {help ice##algorithm:Algorithm used by uvis}).
The first item in {it:cmdlist} may be a command such as {cmd:regress}
or may have the syntax {it:varlist}{cmd::}{it:cmd}, specifying that command {it:cmd}
applies to all the variables in {it:varlist}.  Subsequent items in {it:cmdlist}
must follow the latter syntax, and each item should be followed by a comma.

{pin}
The default {it:cmd} for a variable is {cmd:logit} when there are two distinct values,
{cmd:mlogit} when there ar 3-5 and {cmd:regress} otherwise.

{phang2} Example:  {cmd:cmd(regress)} specifies that all variables are 
to be imputed by {cmd:regress}, over-riding the defaults

{phang2} Example:  {cmd:cmd(x1 x2:logit, x3:regress)} specifies that {cmd:x1} and
{cmd:x2} are to be imputed by {cmd:logit}, {cmd:x3} by {cmd:regress} and all others
by their default choices

{pin}
{it:Advanced use}: If a {it:cmd} is implicitly defined for a variable by a {cmd:o.}
or {cmd:m.} prefix and the {cmd:cmd()} option is used explicitly for that
same variable then the explicit use takes precedence over the implicit use. For
example, the combination ... {cmd:o.x1, cmd(x1:regress)} would impute
{cmd:x1} with {cmd:regress} rather than with the implicit {cmd:ologit}. Used
with {cmd: match(x1)}, this would give a reasonable alternative to ordinal
logistic regression for imputing an ordered categorical variable {cmd:x1}.


{phang}
{opt conditional(condlist)} invokes conditional imputation. Each item of
{it:condlist} has the form {it:varlist}{cmd::} {it:condition}. Items are
separated by backslash ({hi:\}). The idea is that members of {it:varlist}
are only informative when {it:condition} is true, and that they take some
{it:pre-determined value} when {it:condition} is false.

{pmore} 
Important: This option was not correctly implemented in versions of {cmd:ice_}
before 1.2.2 – use {stata which ice_} to check your version.

{pmore} 
Conditional imputation requires that
(i) when any variable included in {it:condition} is missing, all variables in
{it:varlist} are missing, and (ii) when {it:condition} is false, each variable
in {it:varlist} takes only one value (the {it:pre-determined value}, which
might be 0 or a unique "not-applicable" code such as 99).

{pmore} 
In detail, members of {it:varlist}
are imputed in the usual way for the subset of observations for which
{cmd:if} {it:condition} is true (i.e. {it:condition} evaluates to a
non-zero quantity). For the subset of observations for which
{cmd:if} {it:condition} is false, the {it:pre-determined value} is identified
from the data for each member of {it:varlist} and is used to impute any
missing values for that variable. An example is given below.

{pmore}
{it:condition} is a Stata expression constructed so that {cmd:if}
{it:condition} can be evaluated for the current dataset. Variables
appearing in {it:condition} may be members of {it:mainvarlist} or merely
variables in the dataset. The only other situation in {cmd:ice} in
which variables that do not appear in {it:mainvarlist} may be used is
described under the {opt passive()} option.

{pin}
Consider a simple example, a dataset comprising three incomplete variables
{hi:age}, {hi:female}, and {hi:pregnant}, where {hi:female} is 1 for females, 0
for males, and {hi:pregnant} is 1 for pregnant, 0 for not pregnant. Since males
can't be pregnant, we wish to impute missing values of {hi:pregnant} using only
data from females. If we impute someone with missing gender as male, we
want their pregnancy status always to be imputed as non-pregnant.
If males are simply coded as non-pregnant then the {it:pre-determined value}
is the value of {hi:pregnant} denoting non-pregnant, i.e. 0; if instead males
are coded as pregnant=99 then the {it:pre-determined value} is 99. In either
case, we implement the conditional imputation as follows:

{phang2}{cmd:. ice age pregnant female, conditional(pregnant: female==1) clear}{p_end}

{pin}
Here, the prediction equation for {hi:age} is {hi:pregnant female}, that
for female is {hi:age} and that for {hi:pregnant} is {hi:age if female==1}.
Observations of {hi:pregnant} for originally missing observations of
{hi:female} now imputed as male (i.e. {hi:female} = 0) are assigned
the value 0 by {cmd:ice}.

{pin}
We can have dependent conditional imputation. For example,
suppose a fertility test {hi:fertile}, taking the value 1 for fertile and 0
for infertile, was available just for females. We might code this as follows:

{phang2}{cmd:. ice age pregnant female fertile, conditional(pregnant: female==1 & fertile==1 \ fertile: female==1) clear}

{pin}
which reflects that only fertile females can become pregnant, and only females
have a fertility test.

{phang}
{opt cycles(#)} determines the number of cycles of regression switching to be
carried out. Default {it:#} is 10.

{phang}
{opt debug} provides assistance for debugging individual regressions.
As {cmd:ice} runs, it
prints out, for each imputation and cycle, the name of the regression 
command, the variable being imputed and R2, the explained variation of the
model (Nagelkerke method). At the same time, the values from the last
cycle only are stored in a new file called {cmd:_ice_debug.dta}, in the
current working directory. A plot of R2 against cycle number may indicate
abnormalities; for example if R2 shows instability, the corresponding model
may have some features that need improving. The option is useful also for
detecting regression models that explain a negligible amount of variation;
such models are candidates for deletion.

{pin}
Because only the final cycle is stored, for debugging purposes it may be
most sensible to use the {opt debug} option with, say, {cmd:cycles(100)} and
{cmd:m(1)}.


{phang}
{opt dropmissing} is a feature designed to save memory when using
the file of imputed data created by {cmd:ice}. It omits from {it:filename} all
observations which are not in the estimation sample, that is for which either
(i) they are filtered out by {cmd:if} or {cmd:in}, or a non-positive
weight, or
(ii) the values of all variables in {it:mainvarlist} are missing.
This option provides a "clean" analysis file of imputations, with
no missing values. Note that the observations not in the
estimation sample are omitted also from
the original data, stored as imputation #0 in {it:filename}.

{phang}
{opt eqdrop(eqdroplist)} deletes variables from prediction equations.
The syntax of {it:eqdroplist} is {it:varname1}{cmd::}{it:varlist1}
[{cmd:,}{it:varname2}{cmd::}{it:varlist2} ...] where each
{it:varname#} (or {it:varlist#}) is a member (or subset) of {it:mainvarlist}.
One can only remove predictors from equations for variables with missing
values (although trying to remove predictors from non-existent equations
is not a fatal error - an information message is issued). Variable names
prefixed by {cmd:i.} are allowed, provided that the names
were prefixed by {hi:i.}, {hi:m.} or {hi:o.} in {it:mainvarlist}.
They are translated to the corresponding dummy variables created 
by {cmd:xi:}.

{phang}
{opt genmiss(string)} creates an indicator variable for the
missingness of data in any variable in {it:mainvarlist} for which at least one value
has been imputed. The indicator variable is
set to missing for observations excluded by {cmd:if}, {cmd:in}, etc.
The indicator variable for {it:xvar} is named {it:string}{it:xvar}.
The information on missingness is implicit in the original
data, which is stored as "imputation 0".

{phang}
{opt id(newvarname)} creates a variable called {it:newvarname} containing
the original sort order of the data. Default {it:newvarname}: {cmd:_mi}.

{phang}
{opt interval(intlist)} imputes interval-censored variables.
An interval-censored value is one which is known to lie in an interval [a,b]
where a and b are finite and a <= b, or in (-infinity,b] or in [a,infinity).
When either terminal is infinite we have left or right censoring, respectively.
{it:intlist} has the syntax {it:varname}{hi::}{it:llvar ulvar}
[{hi:,} {it:varname}:{it:llvar ulvar} ...],
where each {it:varname} is an interval-censored variable, each
{it:llvar} contains the lower bound (a) for {it:varname} and each
{it:ulvar} contains the upper bound (b) for {it:varname} (or a missing
value to represent plus or minus infinity).
The supplied values of {it:varname} are irrelevant since they will be
replaced anyway; it is only required that {it:varname} exist. Observations
with {it:llvar} missing and {it:ulvar} present are left-censored
for {it:varname}. Observations with {it:llvar} present and {it:ulvar}
missing are right-censored for {it:varname}. Observations with
{it:llvar} = {it:ulvar} are complete, and no imputation is done for
them. Observations with both {it:llvar} and {it:ulvar} missing
are imputed assuming an uncensored normal distribution.
See {help ice##interval:Interval censoring} for further information.

{phang}
{opt initialonly} imputes by random sampling from the distribution of
the non-missing values of each variable which has missing value(s).
This is the initialisation step of the MICE algorithm (see Remarks).
This option may be used to get a 'quick and dirty' set of multiple
imputations with which to explore initial impressions of the analysis
model, or to investigate possible prediction equations for
subsequent multiple imputation using the MICE method. The prediction
equations that are displayed are the ones that would be used by
default in a full MICE imputation run; with the {opt initialonly} option,
they are ignored when imputations are produced.

{phang}
{marker matchpool}{opt matchpool(#)} modifies the implementation of the
{cmd:match()} and {cmd:lrd} options. {cmd:match} performs predictive mean
matching in which a pool of potential
matches is constructed and one member of this pool is sampled (with equal
probabilities). {it:#} specifies the size of this pool. The default is 10.
Please note that older versions of {cmd:ice} used {it:#} = 1 and later 3.
Users are cautioned against using {it:#} = 1.

{phang}
{opt monotone} assumes the members of {it:mainvarlist} have a
monotone missingness pattern, that is, {cmd:ice} defines the prediction equations
appropriately. For variables x1, ..., xk the imputation equations
would be x1 on [nothing], x2 on x1, x3 on x1 x2, ... , xk
on x1 x2 ... x(k-1). When the missingness really is monotonic, only
one cycle of MICE is required, so the default here is {cmd:cycles(1)}.
There is no advantage in specifying more than one cycle.

{pmore}
With the {opt monotone} option,
{cmd:ice} reports a 'non-monotonicity score'. This is defined
as 100 * (sum of numerators) / (sum of denominators), where the sums
are taken over all adjacent pairs of variables in {it:mainvarlist}.
Consider two variables, x1 and x2. The numerator for x1 and x2, i.e the
non-monotonicity, is the number of observations in the estimation sample
for which x1 is missing and x2 is observed. If the numerator is
positive, x1 and x2 show a non-monotonic pattern. The denominator
for x1 and x2 is the the number of observations in the estimation sample
for which x2 is observed.

{pmore}
{cmd:ice} takes a relaxed view of runs in which the non-monotonicity
score is positive. It warns the user but goes ahead with the imputation
anyway - it assumes that the user knows what they are doing.

{phang}
{opt noshoweq} suppresses the presentation of the prediction equations.

{phang}
{opt noconstant} suppresses the regression constant in all regressions.

{phang}
{opt nopp} suppresses treatment of the perfect prediction bug
(see {help ice##pp:Avoiding the perfect prediction bug}).

{phang}
{opt noverbose} suppresses display of the imputation number (as {it:#})
and cycle number within imputations (as {cmd:.}) which show
the progress of the imputations.

{phang}
{opt nowarning} suppresses warning messages.

{phang}
{opt on(varlist)} changes the operation of {cmd:ice} in a major way.
With this option, {cmd:uvis} imputes each member of {it:mainvarlist} univariately
on {it:varlist}. This provides a convenient way of producing multiple imputations
when imputation for each variable in {it:mainvarlist} is to be done univariately
on a set of complete predictors.

{phang}
{opt orderasis} enters the variables in {it:mainvarlist} into the MICE
algorithm in the order given. The default is to order them according
to the number of missing values: the variable with least missingness
gets imputed first, and so on.

{phang}
{opt persist} causes {cmd:ice} to ignore errors raised by {cmd:uvis} when trying
to impute a "difficult" variable, or impute with a model that is difficult to fit
to the data to hand. Trying to impute a "difficult" variable using the
{cmd:ologit} or {cmd:mlogit} command is the most common cause of failure.
By default, {cmd:ice} stops with an error message. With {opt persist},
{cmd:ice} continues to the next variable to be imputed,
not updating the variable that raised an error. Often, by the play of chance, the 
"difficult" variable is successfully updated in a subsequent cycle, and no damage
is done to the imputation process.

{pin}
If the error for a given variable appears in every cycle, you should consider
changing the prediction equation for that variable, since its imputed values
are unlikely to be appropriate.

{pin}
We do not recommend the routine use of {opt persist}. Only use it when
it appears that there is sporadic failure to fit an imputation model.

{phang}
{cmd:restrict(}[{varname}] [{it:{help if}}]{cmd:)} specifies that imputation models
be computed using the subsample identified by {it:varname} and {it:if}.

{pmore}
The subsample is defined by the observations for which {it:varname}!=0 that
also meet the {it:if} conditions.  Typically, {it:varname}=1 defines the
subsample and {it:varname}=0 indicates observations not belonging to the
subsample.  For observations whose subsample status is uncertain, {it:varname}
should be set to a missing value; such observations are dropped from the
subsample.

{pmore}
By default {cmd:ice} fits imputation models and imputes missing
values using the sample of observations identified in the {ifin} options.
The {opt restrict()} option identifies a subset of this sample to be used
for model estimation. Imputation is restricted to the
sample identified in the {ifin} options. Thus, predictions and their
associated imputations are made 'out-of-sample' with respect to the subsample
defined by {opt restrict()}.

{pmore}
Be careful to avoid
restrictions that prevent prediction for all the relevant
observations. For example, models that involve {cmd:mlogit}
will fail to predict 'everywhere' if the {opt restrict()} option excludes
any of the levels of the target variable, as in the following example.
{cmd:school} is a four-level categorical variable coded 0, 1, 2, 3:

{phang2}
{cmd:. gen byte ok = (school > 0) if !missing(school)}{p_end}
{phang2}
{cmd:. ice school house age sex bcg, clear restrict(ok)}

{pmore}
By default, {cmd:school} is imputed using {cmd:mlogit}.
Predictions cannot be made for observations with {cmd:school==0}.
{cmd:ice} will halt with error #303 (equation not found).

{phang}
{opt seed(#)} sets the random number seed to {it:#}. In order
to reproduce a set of imputations, the same random number seed should be used.
See {help ice##reproducibility:Reproducibility of results from uvis and ice}
for further comments.
Default {it:#}: 0, meaning no seed is set by the program; depending
on the status of Stata's random number seed, different
sets of imputations should be obtained on each run.

{marker substitute}{...}
{phang}
{opt substitute(sublist)} is typically used with the 
{cmd:passive()} option to represent multilevel categorical variables
as dummy variables in models for predicting other variables. See
{cmd:passive()} for more details. The syntax of {it:sublist}
is {it:varname}{cmd::}{it:dummyvarlist} [{cmd:,}{it:varname}{cmd::}{it:dummyvarlist} ...]
where {it:varname} is the name of a variable to be substituted and
{it:dummyvarlist} is the list of dummy variables representing it.

{pin}
Note, however, the following important convenience feature:
{cmd:substitute()} may be used without corresponding expressions
in {cmd:passive()} to recreate dummy variables automatically.
If the values of variables in {it:dummyvarlist} are NOT defined
through expressions involving {it:varname} in the {cmd:passive()} option,
then the variables in {it:dummyvarlist} are calculated according to the
actual range of values of {it:varname}. For example, suppose the options
{cmd:passive(x1a:x1==2 \ x1b:x1==3)}
and {cmd:substitute(x1:x1a x1b)} were specified. Provided that all
the non-missing values of {cmd:x1} were 2 when {cmd:x1a}==1 and all
the non-missing values of {cmd:x1} were 3 when {cmd:x1b}==1, then
{cmd:passive(x1a:x1==2 \ x1b:x1==3)} is implied by {cmd:substitute(x1:x1a x1b)}
and can be omitted. The rule applied by {cmd:substitute(x:dummy1 [dummy2...])}
for defining dummy variables dummy1, dummy2, ... is as follows:

{phang2}
1. Determine the range of values [xmin, xmax] of x for which dummy1 > 0.

{phang2}
2a. If xmin < xmax, define dummy1 to be 1 if xmin <= x <= xmax and 0 otherwise.

{phang2}
2b. If xmin = xmax, define dummy1 to be 1 if x = xmin and 0 otherwise.

{phang2}
3. Repeat steps 1 and 2a,b for dummy2, dummy3, ... as necessary.

{pin}
With many such categorical variables this feature can save a lot of typing. 

{phang}
{opt trace(trace_filename)} monitors the convergence of the imputation
algorithm. For each original variable with missing values, the mean of the
imputed values is stored as a variable in {it:trace_filename}, together
with the cycle number at which that
mean was calculated. The results are stored only for the final imputation.
For diagnostic purposes, it is sensible to run {cmd:trace()}
with {cmd:m(1)} and a large number of cycles, such as {cmd:cycles(100)}.
When the run is complete, it is helpful to load {it:trace_filename}
into memory and plot the mean for each imputed
variable against the cycle number. If necessary, smoothing may be applied
to clarify any apparent pattern. Convergence is judged to have occurred
when the pattern of the imputed means is random.
It is usually obvious from the appearance
of the plot how many cycles are needed for convergence.


{dlgtab:uvis}

{phang}
{opt boot} invokes a bootstrap method for creating imputed values
(see {help ice##boot:bootstrap}).

{phang}
{opt by(varlist)} performs imputation separately for all combinations of
variables in {it:varlist}. Observations with missing values for any
members of {it:varlist} are excluded. May be combined with {opt restrict()}.

{phang}
{opt gen(newvar)} is not optional. {it:newvar} contains original
(non-missing) and imputed (originally missing) values of {it:yvar}.

{phang}
{opt lrd} creates imputations by local residual draws. This method is related
to predictive mean matching, but the {it:residual} is borrowed from one of the
closest non-missing observations, rather than the observed value.

{phang}
{opt match} creates imputations by predictive mean matching. The default is to
draw imputations at random from the posterior distribution of the
missing values of {it:yvar}, conditional on the observed values and the members
of {it:xvars}. See {help ice##match:match} for further details.

{phang}
{opt matchpool(#)} - see {help ice##matchpool:matchpool} for details.

{phang}
{opt matchtype(#)} defines how the uncertainty is represented in choosing the
closest matches for the {it:match} and {it:lrd} methods. Type 1 matches the
predictive mean for observed values to a {it:draw} of the predictive mean for missing
values. Type 2 uses a draw of the prediction for observed and missing values. Type 3
uses a different draw for observed and missing values. Type 1 is recommended.

{phang}
{opt noconstant} suppresses the regression constant in all regressions.

{phang}
{opt noverbose} suppresses non-error messages while {cmd:uvis} is running.

{phang}
{opt replace} permits {it:newvar} (see {cmd:gen(}{it:newvar}{cmd:)})
to be overwritten with new data. {cmd:replace} may not be abbreviated.

{phang}
{cmd:restrict(}[{varname}] [{it:{help if}}]{cmd:)} specifies that the imputation
model be computed using the subsample identified by {it:varname} and {it:if}.

{pmore}
The subsample is defined by the observations for which {it:varname}!=0 that
also meet the {it:if} conditions.  Typically, {it:varname}=1 defines the
subsample and {it:varname}=0 indicates observations not belonging to the
subsample.  For observations whose subsample status is uncertain, {it:varname}
should be set to a missing value; such observations are dropped from the
subsample.

{pmore}
By default {cmd:uvis} fits the imputation model using the
sample of observations identified in the {ifin} options.
The {opt restrict()} option identifies a subset of this sample.

{phang}
{opt seed(#)} sets the random number seed to {it:#}.
See {help ice##reproducibility:Reproducibility of results from uvis and ice}
for comments on how to ensure reproducible imputations
by using the {cmd:seed()} option.
Default {it:#}: 0, meaning no seed is set by the program.


{title:Remarks}

{marker algorithm}{...}
{pstd}
{hi:{ul:Algorithm used by uvis}}

{pstd}
When {it:cmd} is {cmd:regress},
{cmd:uvis} imputes {it:yvar} from {it:xvars} according to the following algorithm
(see van Buuren et al (1999) section 3.2 for further technical details):

{phang2}
1. Estimate the vector of coefficients (beta) and the residual variance
by regressing the non-missing values of {it:yvar} on the current "completed"
version of {it:xvars}. Predict the fitted values {it:etaobs} at the
non-missing observations of {it:yvar}.

{phang2}
2. Draw at random a value (sigma_star) from the posterior distribution of the residual
standard deviation.

{phang2}
3. Draw at random a value (beta_star) from the posterior distribution of beta,
conditional on sigma_star, thus allowing for uncertainty in beta.

{phang2}
4. Use beta_star to predict the fitted values {it:etamis}
at the missing observations of {it:yvar}.

{phang2}
5. The imputed values are predicted directly from beta_star, sigma_star and the
covariates. For imputation by linear regression,
this step assumes that {it:yvar} is Normally distributed, given the covariates.
For other types of imputation, samples are drawn from the appropriate
distribution.

{marker match}{...}
{pstd}
With the {cmd:match} option, step 5 is replaced by the following.
For each missing observation of {it:yvar} with prediction {it:etamis},
find the {it:k} non-missing observations (where {it:k} is the number in
{it:matchpool}(#)) of {it:yvar} whose prediction
({it:etaobs}) on observed data is closest to {it:etamis}. One of the closest
non-missing observations {it:yobs} is selected at random and used to impute the
missing value of {it:yvar}.

{pstd}
With the {cmd:lrd} option, the closest matches are selected using match. Again,
one of the {it:k} closest non-missing observations is selected at random. The
imputed value for a missing observation is {it:etamis} + ({it:yobs - etaobs}).

{pstd}
The default draw method is not robust to departures from Normality and
may produce implausible imputations. For example, if the original distribution
is skew and positive-valued, the imputed distribution will not necessarily
have the appropriate amount of skewness, nor will all the imputed values
necessarily be positive. Log transformation of positive variables may greatly
improve the appropriateness of the imputations.

{pstd}
The alternative {cmd:match} method is recommended only for continuous variables
when the Normality assumption is clearly untenable, even approximately.
It is not necessary, nor is it implemented, for binary, ordered categorical or
nominal variables. {cmd:match} may work well when the distribution of a
continuous variable is very non-Normal, but it may sometimes result in biased
imputations.

{marker boot}{...}
{pstd}
With the {cmd:boot} option, steps 2-4 are replaced by a bootstrap estimation of
beta_star and sigma_star, obtained by regressing {it:yvar} on {it:xvars}
after taking a bootstrap sample
of the non-missing observations. This has the advantage of robustness since the
distribution of beta is no longer assumed to be multivariate normal.

{pstd}
Note that {cmd:uvis} will not impute observations for which a value
of a variable in {it:xvars} is missing. However, all original
(missing or non-missing) observations of {it:yvar} will be copied
into {it:newvarname}
in such cases. This is a change from the first release
of {cmd:uvis} (with {cmd:mvis}). Previously, {it:newvarname} would
be set to missing whenever a value
of a variable in {it:xvars} was missing,
irrespective of the value of {it:yvar}.

{pstd}
Missing data for ordered (or unordered) categorical covariates should
be imputed by using the {cmd:ologit} (or {cmd:mlogit}) command. {cmd:match}
is neither required nor implemented in these cases.

{pstd}
{cmd:ice} carries out multivariate imputation in {it:mainvarlist} using regression
switching (van Buuren et al 1999) as follows:

{phang2}
1. Ignore any observations for which {it:mainvarlist} has only missing values, or 
   if the {cmd:cc(}{it:varlist}{cmd:)} option has been specified, for
   which any member of {it:varlist} has a missing value.

{phang2}
2. For each variable in {it:mainvarlist} with any missing data, randomly order that
   variable and replicate the observed values across the missing cases. This
   step initialises the iterative procedure by ensuing that no relevant values
   are missing.

{phang2}
3. For each variable in {it:mainvarlist} in turn, impute missing values by applying
   {cmd:uvis} with the remaining variables as covariates.

{phang2}
4. Repeat step 3 {cmd:cycles()} times, replacing the imputed values with updated
   values at the end of each cycle.

{pstd}
A single imputation sample is created for each variable with any relevant
missing values.

{pstd}
Van Buuren recommends {cmd:cycles(20)} but goes on to say that 10 or even 5
iterations are probably sufficient. We have chosen a compromise default of 10.

{pstd}
"Multiple imputation" (MI) implies the creation and analysis of several
imputed datasets. To do this, one would run {cmd:ice} with {it:m} set
to a suitable number, for example 5. To obtain final estimates
of the parameters of interest and their standard errors,
one would fit a model in 
each imputation and carry out the appropriate post-MI averaging procedure
on the results from the {it:m} separate imputations. A suitable
estimation tool for this purpose is {help mim}.

{pstd}
{hi:{ul:Handling the outcome variable}}

{pstd}
To avoid bias, the outcome variable must always be included in the
list of variables to be used for imputation. In survival analysis,
in particular, it is essential to include the censoring indicator 
as well as the survival time. van Buuren et al (1999) recommend a
log transformation of the survival time, apparently a heuristic
choice. We have shown (White & Royston 2008)
that for a single binary predictor and a proportional hazards analysis model,
the correct imputation model comprises the baseline
cumulative hazard, the censoring indicator and
the binary predictor. The theory remains approximately valid for a normally
distributed predictor with a weak effect. More complex cases have not
yet been investigated, but at least some guidance is now available.

{pstd}
{hi:{ul:Handling binary variables}}

{pstd}
Binary variables present no difficulty. By default, in the MICE
procedure, when such a variable is the response, it is
predicted from other variables by using logistic regression;
when it is a covariate, it is modelled in the only way possible, 
effectively as a single dummy variable.

{pstd}
Ensure that binary variables are coded 0/1.
Although, in theory, one could use {cmd:ologit} or {cmd:mlogit}
to model them, in practice there is no advantage in
doing so. Furthermore, do not use the {hi:i.} prefix with binary variables,
since there is a speed penalty in doing so. 

{pstd}
{hi:{ul:Handling categorical variables}}

{pstd}
Categorical variables with 3 or more levels may in principle be
treated in different ways. By default, in {cmd:ice} variables
with 3-5 levels are modelled using multinomial logistic regression
({cmd:mlogit} command) when the response, and as a single linear term
when a covariate. The same behaviour occurs with the ordered logistic model
({cmd:ologit} command). Our recommended strategy is to use the {hi:m.}
or {hi:o.} prefixes for variables to be imputed using unordered or ordered
logistic regression. This approach removes the need to define the 
{opt substitute()} and {opt passive()} options, both of which can be 
tedious and error-prone to type.

{pstd}
You should be aware that
unless the dataset is large, use of the {cmd:mlogit} command may produce
unstable estimates if the number of levels is too large, and
may compromise the accuracy of the imputations. It is hard to
predict when this will occur.

{marker interval}{...}
{pstd}
{hi:{ul:Interval censoring}}

{pstd}
Values of a variable y that are interval censored are imputed under the
assumption that y is normally distributed with unknown mean and variance.
The method, which is fast and efficient, is essentially as described
for right-censored variables in section 3.3 of Royston (2001).
A minor extension to allow left or interval censoring is employed.
For example, if A < y < B and A and B are both finite, the imputed
value for y will follow a truncated normal distribution with bounds
A and B, variance parameter estimated from the data and mean given by the
linear predictor for the imputation model for y. Stata's {cmd:intreg} command
is used to estimate the mean and variance of y. When A and B are both
missing (infinite), imputation of y simply assumes the normal
distribution just mentioned, but without bounds.

{pstd}
If you wish to impose range limits on the imputed values, the lower and upper
bound variables may be set accordingly. For example, to impute right-censored
(e.g. survival) data, you would set {it:llvar} equal to all
the observed times to event, whether censored or not, and {it:ulvar} to all
the uncensored event times and missing for the censored times.
This would cause the right-censored values to be imputed without restriction.
If you wanted to bound the imputed values above, say by 10,
you would specify {it:ulvar} to be 10 (rather than missing) for all
the censored observations.

{marker pp}{...}
{pstd}
{hi:{ul:Avoiding the perfect prediction bug}}

{pstd}
Perfect prediction may arise in {cmd:logistic}, {cmd:ologit} or
{cmd:mlogit} regression models when a (usually categorical) predictor
variable perfectly predicts success or failure in the outcome variable.
In {cmd:ice}, perfect prediction may occur without the user's knowledge
because a large number of regression models are run silently. Perfect
prediction may lead to entirely inappropriate imputations. To avoid
this, {cmd:uvis} checks for perfect prediction; if it is detected,
{cmd:uvis} temporarily augments the data with a small number of extra observations
with low weight, in such a way as to remove the perfect prediction.
A message is displayed noting the variable that has the
perfect prediction issue, and that the problem has been dealt with.
Such treatment of the perfect prediction bug
may be switched off, if desired, by using the {opt nopp} option.

{pstd}
{hi:{ul:Errors and diagnostics}}

{pstd}
{cmd:ice} may occasionally detect an anomaly when running
{cmd:uvis} with a particular variable as response and a particular
regression command. {cmd:ice} will then stop and report the {cmd:uvis}
command it was running and the error number returned.
Also, {cmd:ice} saves to a file called {hi:_ice_dump.dta}
in the working directory a snapshot of the data it was using
when the error occurred, while also reporting the {cmd:uvis}
command it was executing. Sometimes the problem
lies in a regression of a binary or categorical variable where the
estimation procedure fails to converge; this is usually caused by
sparse cell occupancy of the response variable. If you obtain this
error you should either omit the offending variable from the
imputation, or seek to combine a sparse category with another category.

{pstd}
Another possibility is that, again due to a defect in a particular
regression command in the chained equations structure, the number
of values imputed for a particular variable is less than expected.
This is a serious error and again may arise from estimation problems
involving a binary or categorical variable. In this situation, {cmd:ice}
again saves to a file called {hi:_ice_dump.dta} in the working directory
a snapshot of the data it was using in the attempted estimation,
while reporting the {cmd:uvis} command it was executing.
You can then investigate what may have gone
wrong with the command by loading the data in {hi:_ice_dump.dta} and
re-running the offending regression command.

{marker reproducibility}{...}
{pstd}
{hi:{ul:Reproducibility of results from {cmd:uvis} and {cmd:ice}}}

{pstd}
Use of the option {opt seed(#)} ensures that a set of
imputed values is reproduced identically for a given value of {it:#}.
This is true for both {cmd:uvis} and {cmd:ice}.

{pstd}
Please report to the author any instances where use of {cmd:ice} or {cmd:uvis}
with a fixed seed does not produce the same set of imputed values.

{marker pitfalls}{...}
{pstd}
{hi:{ul:Pitfalls in using the i. prefix}}

{pstd}
{cmd:ice} commands that include {hi:i.}{it:varname} in {it:mainvarlist}
need to be handled with awareness. If {it:varname} has no missing data
in the estimation sample, expected results are obtained. If {it:varname}
does have missing values in the estimation sample, an error message
is given and {cmd:ice} stops. The "estimation sample" here is the set of
observations for which at least one variable in {it:mainvarlist} 
has non-missing value(s).

{pstd}
The presence of {hi:i.} evokes {cmd:xi}, which expands {hi:i.}{it:varname}
in the usual way to create {hi:_I}{it:varname}{hi:_}{it:#} dummy
variables. Since {it:varname} has no missing data, the
dummy variables are included in the prediction equations for other variables in
{it:mainvarlist}, as required.

{pstd}
If {hi:i.}{it:varname} were allowed to have missing data in the
estimation sample,
{cmd:xi} expansion would occur as before, but each of the
{hi:_I}{it:varname}{hi:_}{it:#} dummy variables would become a
response variable in a prediction equation and would be predicted
individually (using logistic regression). Worse, the prediction
equation for each dummy variable would include the {it:other} dummy
variables from {cmd:i.}{it:varname}. That is clearly nonsense.

{pstd}
The advice, as always, is (a) to use {cmd:dryrun} before 'production'
runs if the {cmd:ice} command is at all complex, and then
(b) carefully to check that {cmd:ice}'s table of
prediction equations is both sensible and what you expected.

{pstd}
{hi:{ul:Further notes}}

{pstd}
{opt ice} saves all the variables in the current data to the output,
whether or not they are involved in the imputation procedure.
This can make the resulting dataset very large. It may
therefore be sensible to drop variables not subsequently needed 
for modelling before running {opt ice}.

{pstd}
{cmd:ice} determines the order of imputing variables in the cycle
of chained equations according to the amount of missing data.
Variables with the least missingness are imputed first. Variables
with the same amount of missingness are processed in an arbitrary
order, but always in the same order.
Note that if {opt ice} is run twice using identical variables
(at least two of which have the same amount of missingness) and the same
random number seed, but with the variables with equal missingness 
in a different order, slightly different imputations will be
generated. The differences will be purely random and will not produce
bias in subsequent parameter estimates. If the {opt boot()} option
is applied to all variables, the order of variables no longer affects
the results.

{pstd}
An important application of MI is to investigate possible models, for example
prognostic models, in which selection of influential variables is required
(Clark & Altman 2003). For example, the stability of the final model across the
imputation samples is of interest. This area of enquiry is in its infancy.

{pstd}
See also Van Buuren's website http://www.multiple-imputation.com for further
information and software sources.


{title:Examples}

{phang}
{cmd:. uvis regress y x1 x2 x3, gen(ym)}

{phang}
{cmd:. uvis logit y x1 x2 x3, gen(y) by(x4) restrict(x5) replace noverbose}

{phang}
{cmd:. uvis intreg ll ul x1 x2 x3, gen(y)}

{phang}
{cmd:. ice x1 x2 x3, saving(imputed) m(5)}

{phang}
{cmd:. ice x1 x2 x3, dropmissing monotone clear m(5)}

{phang}
{cmd:. ice x1 x2 i.x3, clear m(5)}{p_end}
{phang}
[Note that x3 must have no missing values in the estimation sample]

{phang}
{cmd:. ice x1 x2 x3, saving(imputed) m(5) cycles(20) cc(x4 x5)}

{phang}
{cmd:. ice m.x1 m.x2 o.x3 x4 x5, saving(imputed) m(10) boot(x1 x2 x3) match(x4 x5) id(pid) seed(101) genmiss(M_)}

{phang}
{cmd:. gen x23 = x2 * x3}{p_end}
{phang}
{cmd:. ice o.x1 x2 x3 x23 z1 z2, saving(imputed) m(5) passive(x23:x2*x3) conditional(z1: if z2==0)}

{phang}
{cmd:. ice y1 y2 y3 x1 x2 x3 x4, saving(imputed) m(5) eq(y1:x1 x2 y2, y2:y1 x3 x4, y3:y1 y2) match(y3)}

{phang}
{cmd:. ice y1 y2 y3 x1 x2 o.x3 i.x4, saving(imputed) m(5) stepwise swopts(pe(.10) pr(.15) group(x1 x2, y1 i.x4)lock(y2 x3)) match(x3)}

{phang}
{cmd:. ice x1-x99, clear debug m(1) cycles(100)}

{phang}
{cmd:. ice x1 x2 x3, saving(imputed) m(5) cmd(x1:ologit) eqdrop(x2:x3, x1:x2)}

{phang}
{cmd:. ice x1 x2 x3, saving(imputed) m(5) cmd(x1:ologit) match(x2) dropmissing}

{phang}
{cmd:. ice x1 ll2 ul2 x2 ll3 ul3 x3, saving(imputed) m(5) interval(x2:ll2 ul2, x3:ll3 ul3)}


{title:Author}

{pstd}
Patrick Royston, MRC Clinical Trials Unit, London.{break}
pr@ctu.mrc.ac.uk


{title:Further reading}

{phang}
van Buuren S., H. C. Boshuizen and D. L. Knook. 1999. Multiple imputation of
    missing blood pressure covariates in survival analysis.
    {it:Statistics in Medicine} {cmd:18}:681-694. 
    Also see http://www.multiple-imputation.com.

{phang}
Carlin  J. B., N. Li, P. Greenwood, and C. Coffey. 2003. Tools for analyzing
multiple imputed datasets. {it:Stata Journal} {cmd:3(3)}:226-244.

{phang}
Clark T. G. and D. G. Altman. 2003. Developing a prognostic model
in the presence of missing data: an ovarian cancer case-study.
{it:Journal of Clinical Epidemiology} {cmd:56}28-37.

{phang}
Royston P. 2001. The lognormal distribution as a model for survival
time in cancer, with an emphasis on prognostic factors.
{it:Statistica Neelandica} {cmd:55}:89-104.

{phang}
Royston P. 2004. Multiple imputation of missing values.
{it:Stata Journal} {cmd:4(3)}:227-241.

{phang}
Royston P. 2005a. Multiple imputation of missing values: update.
Stata Journal {cmd:5}: 188-201.

{phang}
Royston P. 2005b. Multiple imputation of missing values: update of {cmd:ice}.
Stata Journal {cmd:5}: 527-536.

{phang}
Royston P. 2007. Multiple imputation of missing values: further
update of ice, with an emphasis on interval censoring.
Stata Journal {cmd:7}: 445-464.

{phang}
White I. R. and P. Royston. 2009. Imputing missing covariate values for the Cox
model. Statistics in Medicine {cmd:28}: 1982-1998.

{phang}
White I. R., R. Daniel and P. Royston. 2010. Avoiding bias due to perfect
prediction in multiple imputation of incomplete categorical variables.
Computational Statistics and Data Analysis {cmd:54}: 2267-2275.


{title:Acknowledgements}

{pstd}
Ian White has made substantial contributions to the understanding and
practical use of multiple imputation, and to the programming of
{cmd:ice} and {cmd:uvis}. Ian wrote the guts of the {opt draw()} option;
the idea and code for coping with perfect prediction are essentially all his.
I am extremely grateful to him for his ongoing commitment to this project.

{pstd}
I am grateful also to Gillian Raab for pointing out certain issues with the prediction
matching approach, particularly that it is only useful with continuous variables.
As a result, the default imputation method has been
changed from matching to drawing from the predictive distribution. Gillian also
suggested imputing the variables in reverse order of the amount of missingness,
and selecting the imputed value at random from the set determined by the available
matching predictions. Both suggestions have been implemented. 


{title:Also see}

{psee}
On-line:  help for {help mim} (if installed), {help mi ice} (if installed, Stata 11 only).
