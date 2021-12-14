libname pmlr '/home/u59219963/Project';
/*
backgroud of the data:
The develop data set is a retail-banking example.
the data set has 32264 cases (banking customers) and 47 input variables;
The binary target variable Ins indicates whether the customer has an
insurance product.
The 47 input variables represent other product usage and demographics
prior to their acquiring the insurance product

/* 1. explore the data 
***********************
***********************
**************************/

/* 	copy to working library */
data develop;
   set pmlr.develop;
run;

/*use proc contents to check the data first*/
proc contents data=develop;
run;
/*we can copy the result to Excel to track and document in the future*/


/*then we found there are numeric and categorical variales*/

/*1.1 explore numeric variables
*********************************/

/* in SAS we use proc mean to generate descriptive statistics for the numeric
variables, for example: */ 
proc means data=develop n nmiss mean min max;
	var acctage;
run;

/* let check 2 more variables: dda ddabal */
proc means data=develop n nmiss mean min max;
	var acctage dda ddabal;
run;

/*I want to check all numeric variables - there are so many and i do not want to
type all variables one by one*/
/*Use Excel and txt editor to improve efficiency*/
proc means data=develop n nmiss mean min max;
	var
ATM
ATMAmt
AcctAge
Age
CC
CCBal
CCPurc
CD
CDBal
CRScore
CashBk
Checks
DDA
DDABal
Dep
DepAmt
DirDep
HMOwn
HMVal
ILS
ILSBal
IRA
IRABal
InArea
Income
Ins
Inv
InvBal
LOC
LOCBal
LORes
MM
MMBal
MMCred
MTG
MTGBal
Moved
NSF
NSFAmt
POS
POSAmt
Phone
SDB
Sav
SavBal
Teller

;
run;

proc means data=develop n nmiss mean min max;
	var
ATM	ATMAmt	AcctAge	Age	CC	CCBal	CCPurc	CD	CDBal	CRScore	CashBk	Checks	DDA	DDABal
MMBal	MMCred	MTG	MTGBal	Moved	NSF	NSFAmt	POS	POSAmt	Phone	SDB	Sav	SavBal	Teller
Dep	DepAmt	DirDep	HMOwn	HMVal	ILS	ILSBal	IRA	IRABal	InArea	Income	Ins	Inv	InvBal
LOC	LOCBal	LORes	MM;
run;										

/*but what if in the following step, i need to use all these numeric
variables again. I need to reduce the amount of text I enter or even copy again
and again in my other codes*/
/*Let us use macro variable to solve this:
Recall: the %Let statement enables you to define a macro variable Inputs */

%let inputs=ACCTAGE DDA DDABAL DEP DEPAMT CASHBK 
			CHECKS DIRDEP NSF NSFAMT PHONE TELLER 
			SAV SAVBAL ATM ATMAMT POS POSAMT CD 
			CDBAL IRA IRABAL LOC LOCBAL INV 
			INVBAL ILS ILSBAL MM MMBAL MMCRED MTG 
			MTGBAL CC CCBAL CCPURC SDB INCOME 
			HMOWN LORES HMVAL AGE CRSCORE MOVED 
			INAREA;

/*then use input in proc means*/
proc means data=develop n nmiss mean min max;
   var &inputs;
run;

/*key findings from proc meanns:
--several variables have missing values - we need to clean the data first!
--several variables are probably binary*/
	
/*1.1 explore categorical(nominal) variables
*********************************/
/*use proc freq to examines categorical variables and target variables*/

proc freq data=develop;
   tables ins branch res;
run;

proc freq data = develop;
tables ins*res;
run;

/*key findings from proc freq:
-- 34.6% of observations have acquired the insurance product
-- 19 levels of Branch and 3 levels under Res (R=rural, S=suburb, U=urban)
	



/* 2. Introduction to the Logistic Procedure
***********************
***********************
**************************/
/*
--The LOGGISTIC procedure fits a binary logistic regression model.*/

/*try out a basic logistic regression first*/

proc logistic data=develop; 
   model ins = CDBAL IRA IRABAL LOC LOCBAL;
run;


/*2.1 sometimes, we need to put classification variables into the model:

--The Class statement names the classsification variables to be used in the analysis
  The Class statement must precede the Model statement
  The PARAM option in the Class statement specifies the parameterization method for the
  classification variables
  Ref option specifies the reference level - in this example, the parameterization method is 
  reference cell coding the reference level is S*/
  
proc logistic data=develop; 
   class res (param=ref ref='S');
   model ins = dda ddabal dep depamt 
               cashbk checks res;
run;




/*Key points:

-- Use the DES option to reverse the order so that PROC LOGISTIC 
	models the probability that Ins=1;
   Otherwise, the PROC LOGISTIC will model the probabily that Ins=0
*/

proc logistic data=develop DES; 
   class res (param=ref ref='S');
   model ins = dda ddabal dep depamt 
               cashbk checks res;             
run;

/*2.1 The odds ratio  is defined as the ratio of the odds for those with the risk factor () 
to the odds for those without the risk factor ():

The odds ratio measures the effect of the input variable on the target adjusted for the effect of the other
input variables. For example, the odds of acquiring an insurance product for DDA (checking account)
customers is .379 times the odds for non-DDA customers. Equivalently, the odds of acquiring an
insurance product is 1/.379 or 2.64 times more likely for non-DDA customers compared to DDA
customers. Therefore odds raio is useful for baniry variables*/


/*-- For continuous variables, it may be useful to convert the odds ratio to a percentage increase or decrease in
odds.
The UNITS statement enables you to obtain an odds ratio estimate for a specified change in an input
variable. In this example, let us use UNITS Statement to estimate the change in odds for a 1000-unit
change in DDABal and DepAmt.*/

proc logistic data=develop DES; 
   class res (param=ref ref='S');
   model ins = dda ddabal dep depamt 
               cashbk checks res;  
	unit    ddabal=1000 depamt=1000;        
run;

/*
the odds ratio for a 1000-unit change in DDABal is 1.074. Consequently, the odds of
acquiring the insurance product increases 7.4% (calculated as 100(1.07-1)) for every thousand-dollar
increase in the checking balance, assuming that the other variables do not change.
*/
/*
The four rank correlation indexes (Somer’s D, Gamma, Tau-a, and c) are computed from the numbers of
concordant and discordant pairs of observations. In general, a model with higher values for these indexes
(the maximum value is 1) has better predictive ability than a model with lower values for these indexes.
*/


/* 3. Score the dataset
***********************
***********************
**************************/

/*no target variable in the new dataset, which is normal*/

/*3.1 Use score statement to score the dataset*/
proc logistic data=develop des;
model ins=dda ddabal dep depamt cashbk;
score data = pmlr.new out=scored;
run;

/*run proc contents to check what scored data look like*/


proc print data=scored(obs=20);
var P_1 dda ddabal dep depamt cashbk;
run;

/*3.2 OUTEST= Option and use the SCORE Procedure*/

/* -- The LOGISTIC procedure outputs the final parameter estimates to a data set using the OUTEST= option.*/
proc logistic data=develop des outest=betas1;
model ins=dda ddabal dep depamt cashbk;
run;
proc print data=betas1;
run;
/*
The output data set contains one observation and a variable for each parameter estimate. The estimates are
named corresponding to their input variable*/


/*
The SCORE procedure multiplies values from two SAS data sets, 
-- one containing coefficients (SCORE=)
   and the other containing the data to be scored (DATA=). 
-- Typically, the data set to be scored would not
   have a target variable. 
-- The OUT= option specifies the name of the scored data set created by PROC
   SCORE. 
-- The TYPE=PARMS option is required for scoring regression models.*/

proc score data=pmlr.new
out=scored
score=betas1
type=parms;
var dda ddabal dep depamt cashbk;
run;

/*Key finding:
Different from SCORE statement in PROC Logistic Procedure
,the linear combination produced by PROC SCORE (the variable Ins) estimates the logit, not the
posterior probability. The logistic function (inverse of the logit) needs to be applied to compute the
posterior probability.*/
data scored;
set scored;
p=1/(1+exp(-ins));
run;
proc print data=scored(obs=20);
var p ins dda ddabal dep depamt cashbk;
run;

/*Data can also be scored directly in PROC LOGISTIC using the OUTPUT statement, which is a better way*/

