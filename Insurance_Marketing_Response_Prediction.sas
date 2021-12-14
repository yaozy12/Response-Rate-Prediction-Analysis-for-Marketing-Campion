libname pmlr '/home/u59219963/Project';
/*
backgroud of the data:
The develop data set is a retail-banking example.
the data set has 32264 cases (banking customers) and 87 input variables;
The binary target variable Ins indicates whether the customer has an
insurance product.
The 87 input variables represent other product usage and demographics
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
proc contents data=pmlr.pva_raw_data;
run;
proc print data=pmlr.pva_raw_data (firstobs=5 obs=10);
run;
data pva(drop=Control_number);
   set pmlr.pva_raw_data;
run;


%let ex_inputs= MONTHS_SINCE_ORIGIN 
DONOR_AGE IN_HOUSE INCOME_GROUP PUBLISHED_PHONE
MOR_HIT_RATE WEALTH_RATING MEDIAN_HOME_VALUE
MEDIAN_HOUSEHOLD_INCOME PCT_OWNER_OCCUPIED
PER_CAPITA_INCOME PCT_MALE_MILITARY 
PCT_MALE_VETERANS PCT_VIETNAM_VETERANS 
PCT_WWII_VETERANS PEP_STAR RECENT_STAR_STATUS
FREQUENCY_STATUS_97NK RECENT_RESPONSE_PROP
RECENT_AVG_GIFT_AMT RECENT_CARD_RESPONSE_PROP
RECENT_AVG_CARD_GIFT_AMT RECENT_RESPONSE_COUNT
RECENT_CARD_RESPONSE_COUNT LIFETIME_CARD_PROM 
LIFETIME_PROM LIFETIME_GIFT_AMOUNT
LIFETIME_GIFT_COUNT LIFETIME_AVG_GIFT_AMT 
LIFETIME_GIFT_RANGE LIFETIME_MAX_GIFT_AMT
LIFETIME_MIN_GIFT_AMT LAST_GIFT_AMT
CARD_PROM_12 NUMBER_PROM_12 MONTHS_SINCE_LAST_GIFT
MONTHS_SINCE_FIRST_GIFT;

/*Check the mean, minimum, maximum, and count of missing for each numeric input*/

proc means data=pva n nmiss mean std min max;
   var &ex_inputs;
run;


/*check frequency for character variables*/
proc freq data=pva;
   tables _character_ target_b / missing;
run;


/*Create missing value indicators for inputs that have missing values.*/
/*
missing columns are: DONOR_AGE INCOME_GROUP WEALTH_RATING;
*/

data pva(drop=i);
   set pva;
   /* name the missing indicator variables */
   array mi{*} mi_DONOR_AGE mi_INCOME_GROUP 
               mi_WEALTH_RATING;
   /* select variables with missing values */
   array x{*} DONOR_AGE INCOME_GROUP WEALTH_RATING;
   do i=1 to dim(mi);
      mi{i}=(x{i}=.);
   end;
run;


/*Impute missing value to a new dataset pva1*/

proc stdize data=pva 
		  method=median  /* or MEAN, MINIMUM, MIDRANGE, etc. */
          reponly  /* only replace; do not standardize */
          out=pva1;
   var DONOR_AGE INCOME_GROUP WEALTH_RATING;  /* you can list multiple variables to impute */
run;

/*
Split the imputed data set into training and test data sets. 
Use 70% of the data for each data
set role. Stratify on the target variable.*/
proc sort data=pva1 out=pva1;
   by target_b;
run;

proc surveyselect noprint
                  data=pva1
                  samprate=.7 
                  out=pva2
                  seed=27513
                  outall;
   strata target_b;
run;

data pva_train pva_test;
   set pva2;
   if selected then output pva_train;
   else output pva_test;
run;

/* use proc freq to check whether train is 70% and 30% for test, and response rate is the same*/
proc freq data=pva_train;
table target_b;
run;

proc freq data=pva_test;
table target_b;
run;





/*create macro variable which has all the independent variables we need*/

%let ex_screened=
LIFETIME_CARD_PROM       LIFETIME_MIN_GIFT_AMT   PER_CAPITA_INCOME
mi_INCOME_GROUP   
RECENT_RESPONSE_COUNT    PCT_MALE_MILITARY
DONOR_AGE                PCT_VIETNAM_VETERANS    MOR_HIT_RATE
PCT_OWNER_OCCUPIED       PCT_MALE_VETERANS       PUBLISHED_PHONE
WEALTH_RATING MONTHS_SINCE_LAST_GIFT   RECENT_STAR_STATUS      LIFETIME_GIFT_RANGE
INCOME_GROUP             IN_HOUSE  
RECENT_AVG_GIFT_AMT     PCT_WWII_VETERANS
LIFETIME_GIFT_AMOUNT     PEP_STAR                mi_DONOR_AGE
RECENT_AVG_CARD_GIFT_AMT RECENT_CARD_RESPONSE_PROP
;

/*Use the Spearman correlation coefficients to screen the inputs with the
least evidence of a relationship with the target*/
proc corr data=pva_train spearman rank;
   var &ex_screened;
   with target_b;
run;


/*
Fit a logistic regression model with the FAST BACKWARD method. Use the macro variable
ex_screened to represent all independent variables*/

proc logistic data=pva_train des;
   model target_b = &ex_screened
   /selection=backward fast;
run;

/*
Fit a logistic regression model with the FAST Stepwise method. Use the macro variable
ex_screened to represent all independent variables*/

proc logistic data=pva_train des;
   model target_b = &ex_screened
   /selection=stepwise fast best=1;
run;

/*let's assume the final variable you select are:
MONTHS_SINCE_LAST_GIFT: months since most recent donation
INCOME_GROUP: income bracket, from 1 to 7
RECENT_AVG_GIFT_AMT: average donation amount
PEP_STAR: flag to identify consecutive donors
RECENT_CARD_RESPONSE_PROP: proportion of responses to promotions

Let's check ROC curve for this model and use this model to score
pva_test
Also, check average of p_1 in scored_test
*/
proc logistic data=pva_train des outest=betas1 plots=ROC;
model target_b = 
MONTHS_SINCE_LAST_GIFT
INCOME_GROUP
RECENT_AVG_GIFT_AMT
PEP_STAR
RECENT_CARD_RESPONSE_PROP;
run;


proc logistic data=pva_train des plots=ROC;
model target_b = 
MONTHS_SINCE_LAST_GIFT
INCOME_GROUP
RECENT_AVG_GIFT_AMT
PEP_STAR
RECENT_CARD_RESPONSE_PROP;
score data = pva_test out=scored_test;
run;

proc means data=scored_test;
var p_1;
run;

/* check the performance on Test dataset*/

proc logistic data=scored_test des plots=ROC;
model target_b = p_1;
run;


proc contents data=car_insurance;
run;
proc freq data=car_insurance;
		table Response;
		run;

/*Step Two - Customer and Segmentation analysis:
When we are reporting and tracking the progress of marketing efforts,
we typically would want to dive deeper into the data and
break down the customer base into multiple segments
and compute KPIs for individual segments*/

/*  Analyze how these response varies by different EmploymentStatus?
       get the response rate by each EmploymentStatus group*/
/*       first converte the response into numberic by creating res_flag */
data car_insurance;
set car_insurance;
if response='Yes' then res_flag=1;
else res_flag=0;
run;

proc sql;
select EmploymentStatus, sum(res_flag)/count(*)
from car_insurance
group by 1;
quit;

/*  Analyze how these response varies by different Marital Status*/

proc freq data=car_insurance;
tables res_flag*MaritalStatus;
run;

/* Analyze how these response varies by different SalesChannel*/
proc sql;
select SalesChannel, sum(res_flag)/count(*)
from car_insurance
group by 1;
quit;

/* Get response rate by sales channel and vehicle size */

proc sql;
select SalesChannel, vehiclesize, sum(res_flag)/count(*)
from car_insurance
group by 1,2;
quit;

/*  Let's segment our customer base by Customer Lifetime Value
 */
	/*we are going to define those customers with
	a Customer Lifetime Value higher than the median as
	high-CLV customers
	and those with a CLV below the median as low-CLV customers*/

proc means data=car_insurance n median;
 var customerlifetimevalue;
 run;

data car_insurance;
set car_insurance;
if customerlifetimevalue >= 5780.18 then clv_seg=2;
else clv_seg=1;
run;

/* Let's Get response rate by clv_seg
 */
proc sql;
select clv_seg, sum(res_flag)/count(*)
from car_insurance
group by 1;
quit;

/* Create 3 flags for:
Marital Status=Divorced
EmploymentStatus=Retired
SalesChannel=Agent
Baed on previous analysis, do you think that make sense?*/
data car_insurance;
set car_insurance;
if MaritalStatus='Divorced' then Divorced_flag=1; else Divorced_flag=0;
if EmploymentStatus='Retired' then Retired_flag=1; else Retired_flag=0;
if SalesChannel='Agent' then Agent_flag=1; else Agent_flag=0;
run;

/*  check missing rate for numberical variables */

proc means data=car_insurance n nmiss mean std min max;
   var _numeric_;
run;



/* Step Three - model build: */
/*  Split the data into train(70%) and test(30%) and check average response rate
 */

proc sort data=car_insurance out=car_insurance;
   by res_flag;
run;

proc surveyselect noprint
                  data=car_insurance
                  samprate=.7
                  out=car_insurance2
                  seed=27513
                  outall;
   strata res_flag;  
run;

data car_train car_test;
   set car_insurance2;
   if selected then output car_train;
   else output car_test;
run;

proc freq data=car_test;
table res_flag;
run;

proc freq data=car_train;
table res_flag;
run;

/* Build a logistic model by using variables:
Retired_flag
Divorced_flag
Income
TotalClaimAmount
MonthlyPremiumAuto
MonthsSincePolicyInception

Use stepwise to decide the best model*/
proc logistic data=car_train des plots=ROC;
model res_flag = Agent_flag
Retired_flag
Divorced_flag
Income
TotalClaimAmount
MonthlyPremiumAuto
MonthsSincePolicyInception
/selection=stepwise fast best=1;
run;



proc logistic data=car_train des plots=ROC;
model res_flag = Agent_flag
Retired_flag
Divorced_flag
Income;
run;

/* Score the model on Test data:*/

proc logistic data=car_train des plots=ROC;
model res_flag = Agent_flag
Retired_flag
Divorced_flag
Income;
score data = car_test out=scored_test;
run;


proc logistic data=scored_test des plots(only)=ROC;
model res_flag = P_1;
run;