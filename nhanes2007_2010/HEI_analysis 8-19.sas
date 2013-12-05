
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

LIBNAME IN1       'C:\Users\aroberts\Desktop\NHANES07-10';
LIBNAME IN2       'C:\Users\aroberts\Dropbox\Dissertation\NHANES';

Data A1; IN1.HFE_Data; 
proc format;
	value hfa 1  = "always"
			  2  = "most of the time"
			  3  = "sometimes"
			  4  = "rarely"
			  5  = "never"
			  77 = "refused"
			  99 = "I don't know"
;
run;
%let hFood= hMilk;
%let Nutrient = DR1TCALC;

%macro sMeans(hFood= ,Nutrient= );
proc surveymeans data= A1;
	Domain eligible*&hFood;
	ClASS &hFood;
	CLUSTER SDMVPSU;
	STRATA SDMVSTRA;
	var &Nutrient;
	WEIGHT WTMEC4YR;
	ods output domain(match_all)=domain;
	run;
data all;
	set domain ;
	 if eligible= 1 ;
	run; 

proc print data= all; 
	var &hFood N Mean StdErr LowerCLMean UpperCLMean;
	format &hFood hfa. ;
run;
 %mend sMeans;

ods rtf;

ods rtf close;
%sMeans(hFood=hMilk ,Nutrient=DR1TCALC); quit;
%sMeans(hFood=hMilk, Nutrient=DR1TCAFF); quit;
%sMeans(hFood=hMilk, Nutrient=DR1TKCAL); quit;


%sMeans(hFood=hSoda ,Nutrient=DR1TCALC); quit;
%sMeans(hFood=hSoda, Nutrient=DR1TCAFF); quit;
%sMeans(hFood=hSoda, Nutrient=DR1TKCAL); quit;



%sMeans(hFood=hFruits ,Nutrient=DR1TFIBE); quit;
%sMeans(hFood=hFruits, Nutrient=DR1TKCAL); quit;

%sMeans(hFood=hGreens ,Nutrient=DR1TFIBE); quit;
%sMeans(hFood=hGreens, Nutrient=DR1TKCAL); quit;



Proc freq data =A1; 
	tables hFruits hGreens hSnacks hMilk hSoda;
run;

proc freq data=A1; tables age*ageCat ageCat*eligible; run;

proc contents data= A1; run;

proc surveyfreq data =A1;
where eligible =1;
CLUSTER SDMVPSU;
STRATA SDMVSTRA;
tables FSDCH*hFruits;
WEIGHT WTMEC4YR;
RUN;


proc surveymeans data= A1;
Domain eligible eligible*hMilk;
ClASS hMilk;
CLUSTER SDMVPSU;
STRATA SDMVSTRA;
var DR1TCALC;
WEIGHT WTMEC4YR;
ods output domain(match_all)=domain;
run;
data all;
set domain domain1;
if eligible= 1 ;
run; 
proc print; 
	var hMilk N Mean StdErr LowerCLMean UpperCLMean;
	format hMilk hfa. ;
 title "Mean calcium by Milk Availablity";
run;

proc surveymeans data= A1;
Domain eligible*hSoda;
CLASS hSoda;
CLUSTER SDMVPSU;
STRATA SDMVSTRA;
var DR1TCAFF DR1TCALC DR1TKCAL DR1TFIBE DR1TIRON DR1TPHOS DR1TSUGR;
WEIGHT WTMEC4YR;
ods output domain(match_all)=domain;
run;

PROC SURVEYREG DATA=A1 ; 
Domain eligible;
CLUSTER SDMVPSU;
STRATA SDMVSTRA;
MODEL bmicat = hFruits;
WEIGHT WTMEC4YR;
RUN; 
