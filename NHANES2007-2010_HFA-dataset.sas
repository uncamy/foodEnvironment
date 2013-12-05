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

LIBNAME B1  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\DEMO_F.XPT';
LIBNAME B2  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\CBQ_F.XPT';
LIBNAME B3  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\DR1TOT_F.XPT';
LIBNAME B4  XPORT 'C:\Users\aroberts\Desktop\NHANES 2007-2010\FSQ_F.XPT';

LIBNAME IN1       'C:\Users\aroberts\Desktop\NHANES 2007-2010';
LIBNAME IN2       'C:\Users\aroberts\Dropbox\Dissertation\NHANES';

* Add variable to each year dataset to define when data collected;
DATA DEMO07; SET A1.DEMO_E;   DCYR = '07-08'; RUN;
DATA DEMO09; SET B1.DEMO_F; DCYR = '09-10'; RUN;

proc contents data= DEMO07; run;
proc contents data= DEMO09; run;

**** merge the data sets ****;

DATA in1.combine;
      MERGE 
		A1.DEMO_E A2.CBQ_E A3.DR1TOT_E A4.FSQ_E
		B1.DEMO_F B2.CBQ_F B3.DR1TOT_F B4.FSQ_F;;
       
BY SEQN;

WTMEC4YR = (1/2) * WTMEC2YR; 
AGE 	 = RIDAGEYR;
hFruits  = CBQ020;
hGreens  = CBQ030;
hSnacks  = CBQ040;
hMilk    = CBQ050;
hSoda    = CBQ060;
DINNERS  = CBD160;


label
	WTMEC4YR = 'Full sample 4y weight'
	AGE      = 'age in years'
	DINNERS  = '# of times someone cooked dinner at home'
	hFruits  = 'Fruits available at home'
	hGreens  = 'Dark green vegetables available at home'
	hSnacks  = 'Salty snacks available at home'
	hMilk    = 'Fat-free/low fat milk available at home'
	hSoda    = 'Soft drinks available at home';

PROC CONTENTS; RUN;

Data A1; set in1.combine; 
if 2 =< age < 6 then agecat = 1;
	else if 6 =< age < 12 then agecat = 2;
	else if 12 =< age < 16 then agecat = 3;
	else agecat= 0;

/*exclusions */
if CBQ020 = .				then exclude = 1; *missing fruit availbilty;
	else if CBQ030 = . 		then exclude = 2; *missing dark green availablity;
	else if DR1DRSTZ ne 1 	then exclude = 3; * consumed breast milk, or has unrealiable diet data (codes 2, 4,5);
	else if DRQSDIET ne 2 	then exclude = 4; * on a special diet;
							else exclude = 0; 

if exclude = 0 && agecat > 0 then eligible = 0; 
	else eligible =1; 
run; 

proc freq data = A1; tables exclude*eligible; run;

Proc freq data =A1; 
	tables hFruits hGreens hSnacks hMilk hSoda;
run;


