******************************************************************************
*** PROGRAM:     NHANES Home Food Availablity                              ***
*** PROJECT:     Rocking Home Food Availablity Dissertation                ***
*** PURPOSE:     To create the NHANES analysis dataset for this project    ***
***              using data from 2 continuous surveys 2007-2008, 2009-2010 ***
***             				                                           ***
*** INPUT:     From 2007-2008: DEMO.XPT CBQ_E.XPT DR1TOT_E.XPT FSQ_E.XPT   *** 
               From 2007-2008: DEMO.XPT CBQ_F.XPT DR1TOT_F.XPT FSQ_F.XPT   ***
                 													       ***
*** OUTPUT:                                                                ***
*** PROGRAMMER:  Amy Roberts                                               ***
*** DATE:       7/31/13                                                    ***
******************************************************************************;
FOOTNOTE "NHANES Home Food Avaiablity Dataset &sysdate at &systime";
TITLE1 'RHFAD - NHANES 2007-2010';


LIBNAME A1  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\DEMO_E.XPT';
LIBNAME A2  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\CBQ_E.XPT';
LIBNAME A3  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\DR1TOT_E.XPT';
LIBNAME A4  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\FSQ_E.XPT';
LIBNAME A5  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\BMX_E.XPT';

LIBNAME B1  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\DEMO_F.XPT';
LIBNAME B2  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\CBQ_F.XPT';
LIBNAME B3  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\DR1TOT_F.XPT';
LIBNAME B4  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\FSQ_F.XPT';
LIBNAME B5  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\BMX_F.XPT';


LIBNAME IN1       'C:\Users\aroberts\Desktop\NHANES07-10';
LIBNAME IN2       'C:\Users\aroberts\Dropbox\Dissertation\NHANES';

* Add variable to each year dataset to define when data collected;
DATA DEMO07; SET A1.DEMO_E;   DCYR = '07-08'; RUN;
DATA DEMO09; SET B1.DEMO_F; DCYR = '09-10'; RUN;

proc contents data= DEMO07; run;
proc contents data= DEMO09; run;

**** merge the data sets ****;

DATA in1.combine;
      MERGE 
		A1.DEMO_E A2.CBQ_E A3.DR1TOT_E A4.FSQ_E A5.BMX_E
		B1.DEMO_F B2.CBQ_F B3.DR1TOT_F B4.FSQ_F B5.BMX_F;
       
BY SEQN;

WTMEC4YR = (1/2) * WTMEC2YR; 
AGE 	 = RIDAGEYR;
hFruits  = CBQ020;
hGreens  = CBQ030;
hSnacks  = CBQ040;
hMilk    = CBQ050;
hSoda    = CBQ060;
DINNERS  = CBD160;


* Setting up program according to instructions on the CDC website;
AGEMOS   = RIDAGEMN;
SEX      = RIAGENDR;
HEIGHT   = BMXHT;
RECUMBNT = 0;
WEIGHT   = BMXWT;
HEADCIR  = .;
run;
* 2 programs that were downloaded were used to calculate BMI percentiles
  gc-setup.sas and gc-calculate-BIV.sas;
* The dataset TOTAL_MULT1 was created from these programs;

%let datalib='C:\Users\aroberts\Desktop\NHANES07-10';   *subdirectory for your existing dataset;
%let datain=COMBINE;     *the name of your existing SAS dataset;
%let dataout=COMBINE_Z;    *the name of the dataset you wish to put the results into;
%let saspgm='C:\Users\aroberts\Desktop\NHANES\gc-calculate-BIV.sas'; *subdirectory for the downloaded program gc-calculate-BIV.sas;

Libname mydata &datalib;

data _INDATA; set mydata.&datain;

%include &saspgm;

data mydata.&dataout; set _INDATA;

run;

proc contents data= IN1.COMBINE_Z;run; 
proc univariate data= IN1.COMBINE_Z; where RIDAGEYR <18; var BMIPCT; run;
proc freq data=in1.combine_z; tables _bivht _bivwt _bivwht _bivbmi; run;
PROC SORT DATA=in1.COMBINE_Z; BY SEQN; RUN;

** Create the 5 analysis datasets;
DATA EXCLUDE1;
SET IN1.COMBINE_Z;

* There were 9459 children in NHANES 1999-2004 exams.;
* Note: After the January 12th, 2011 meeting and looking at collinearity, we decided
  that we would drop thigh circumference, calf circumference and upper arm circumference.
  We will no longer include those variables in the exclusion list;
IF      BMIWT    = 3 THEN EXCLUDE = 3;  * Weight comment - clothing;
ELSE IF BMIHT    = 3 THEN EXCLUDE = 4;  * Height comment - not straight;
ELSE IF BMXWT    = . THEN EXCLUDE = 5;  * missing weight;
ELSE IF BMXHT    = . THEN EXCLUDE = 6;  * missing height;
ELSE IF _BIVHT   = 1 THEN EXCLUDE = 7;  * BIV for height for age (too low); 
ELSE IF _BIVHT   = 2 THEN EXCLUDE = 8;  * BIV for height for age (too high);
ELSE IF _BIVWT   = 2 THEN EXCLUDE = 9;  * BIV for weight for age (too high);
ELSE IF _BIVBMI  = 2 THEN EXCLUDE = 10; * BIV for BMI for age (too high);
ELSE                      EXCLUDE = 0;

PROC FREQ; TABLES EXCLUDE; RUN;
PROC UNIVARIATE data = exclude1; var BMIPCT; run;

PROC FREQ DATA=EXCLUDE1; TABLES EXCLUDE * SEX/NOPERCENT NOROW; RUN;

* Determine the percent that are overweight;
Data A1; set EXCLUDE1;
IF 5 LT BMIPCT LT 85      THEN BMICAT = 1; * Normal weight;
ELSE IF BMIPCT LT 95      THEN BMICAT = 2; * Overweight;
ELSE IF BMIPCT >= 95      THEN BMICAT = 3; * Obese;
ELSE 						   BMICAT = 0; * Underweight;
 
if 2=< age < 6 then ageCat = 1;
	else if 6 =< age < 12 then ageCat = 2;
	else if 12=< age < 18 then ageCat = 3;
	else ageCat= 99;

label
	WTMEC4YR = 'Full sample 4y weight'
	AGE      = 'age in years'
	DINNERS  = '# of times someone cooked dinner at home'
	hFruits  = 'Fruits available at home'
	hGreens  = 'Dark green vegetables available at home'
	hSnacks  = 'Salty snacks available at home'
	hMilk    = 'Fat-free/low fat milk available at home'
	hSoda    = 'Soft drinks available at home';
	
if . < ageCat <99 and exclude = 0 then eligible = 1; else eligible =2;

PROC FREQ; TABLES eligible*AgeCat; RUN;

data in1.HFE_Data; set A1; run;
