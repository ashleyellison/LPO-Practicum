capture log close
log using "logistic.log",replace

/* PhD Practicum, Spring 2020 */
/* Regression models for binary data*/
/* Will Doyle*/
/* 2020-04-08 */

clear

set more off

set scheme s1color

graph drop _all

global ddir "../../data/"

use ${ddir}attend, clear

describe

/* Missing data*/

foreach myvar of varlist stu_id-f1psepln{ /* Start outer loop */
              foreach i of numlist -3 -4 -8 -9 { /* Start inner loop */
                     replace `myvar'=. if `myvar'== `i'
                                            }  /* End inner loop */
                                          } /* End outer loop */


/* Recodes */
 

recode byrace (1=1 "Native American") ///
				(2=2 "Asian/ Pacific Islander") ///
				(3=3 "African-American") ///
				(4/5=4 "Hispanic") ///
				(6=5 "Multiracial") ///				
				(7=6 "White"), ///
gen(byrace2) 

recode bysex (1=0 "Non-Female") ///
			  (2=1 "Female"), ///
			  gen(female)


/* Set locals */

local y f2evratt

local ses byses1

local demog ib(freq).byrace2 ib(freq).female

local tests bynels2m bynels2r

local gtype pdf

/* Linear Probability Model */

reg `y' `ses' `demog' `tests'

graph twoway (scatter `y' `ses',jitter(.1)   msize(tiny) ) ///
			(lfit `y' `ses' )
					
predict e, resid

reg `y' bynels2m

predict yhat_pr 

graph twoway scatter yhat_pr bynels2m, msize(vtiny) mcolor(%20) name(prob1)

predict e1, resid

graph twoway scatter e1 bynels2m, msize(vtiny) mcolor(%20) name(resid1)

sum yhat_pr

replace yhat_pr=.9999 if yhat_pr>1

replace yhat_pr=.0001 if yhat_pr<0

// Can always use robust ses
reg `y' `ses' `demog' `tests', vce(robust)

// Save this for later
estimates store lpm

/* Generate predicted probabilites over range of ses*/

local x byses1

sum `x', detail

local no_steps=20

local mymin=r(min)
local mymax=r(max)
local diff=`mymax'-`mymin'
local step=`diff'/`no_steps'
    
margins , predict(xb) ///
    at((mean) _continuous ///
        (base) _factor ///
        `x'=(`mymin'(`step')`mymax') ///          
       ) ///
      post

// Grab results for plotting    

marginsplot

marginsplot, recastci(rarea) ciopts(color(gray%10)) ///
			recast(line)  plotopts(color(blue)) ///
			xlabel(-2(.3)2) xtitle("SES") ytitle(Linear Prediction) title("") name("LPM")

			
graph export lpm.pdf, replace name("LPM")

/*Logistic Function*/

graph drop _all

local k=.25 /*Scale*/
local x0=0 /*Location*/

graph twoway function y=1/(1+exp((-`k')*(x-`x0'))),range(-2 2) name("Logit")

graph twoway function y=(1/(1+exp((-`k')*(x-`x0')))),range(-2 2) name("Logit_s")


/*Logistic Regression */

// Most general: glm
glm `y' `ses' `demog' `tests', family(binomial) link(logit) /*Logit model */

// Can also use probit, uses cdf of normal dist    
glm `y' `ses' `demog' `tests', family(binomial) link(probit) /*Probit Model */

// Simpler version of logit model 
logit `y' `ses' `demog' `tests' 

est store full_model

gen mysample=e(sample)

/* Generating marginal effects */

estimates restore full_model

margins, dydx(*) /*for all coefficients, default is to hold others at mean */

/*Margins for range of ses */

estimates restore full_model

margins , predict(pr) ///
    at((mean) _continuous ///
        (base) _factor ///
        `x'=(`mymin'(`step')`mymax') ///          
       ) ///
      post
	  
//Marginsplot


marginsplot, recastci(rarea) ciopts(color(gray%10)) ///
			recast(line)  plotopts(color(blue)) ///
			xlabel(-2(.3)2) xtitle("SES") ytitle(Linear Prediction) title("") name("logit_basic")
			
graph export logit_basic.pdf, replace name("logit_basic")
    
/* Margins for range of ses, all races */

estimates restore full_model

quietly margins , predict(pr) ///
    at((mean) _continuous ///
        (base) _factor ///
        `x'=(`mymin'(`step')`mymax') ///
        byrace2=(1(1)6) ///
       ) ///
      post


marginsplot, recastci(rarea) ciopts(color(%10)) ///
				recast(line) ///
              xlabel(-2(.3)2) xtitle("SES") ytitle("Pr(Attend)") title("") ///
              name("logit_race")
			
graph export logit_race.pdf, replace name("logit_race")
	
estimates restore full_model			

quietly margins , predict(pr) ///
    at((mean) _continuous ///
        (base) _factor ///
        `x'=(`mymin'(`step')`mymax') ///
        byrace2=(3 4 6) ///
       ) ///
      post
	  

	  
marginsplot, recastci(rarea) ciopts(color(%10)) ///
				recast(line) ///
				xlabel(-2(.3)2) xtitle("SES") ytitle(Linear Prediction) title("") ///
				legend(cols(1))

				
// Another option

//estimates restore full_model

//marginscontplot2 byses1, at1(-2(.2)2) ci				

//mcp2 byses1, at1(-2(.1)2) ci

//mcp2 byses1 byrace2, at1(-2(.1)2) ci				

estimates restore full_model

local x byses1

sum `x', detail

local no_steps=20

local mymin=r(min)
local mymax=r(max)
local diff=`mymax'-`mymin'
local step=`diff'/`no_steps'
    
local z bynels2m

sum `z', detail

local low_z=r(p25)
local mid_z=r(p50)
local hi_z=r(p75)

quietly margins , predict(pr) ///
    at((mean) _continuous ///
        (base) _factor ///
		 byrace2=6 ///
		 female=1 ///
        `x'=(`mymin'(`step')`mymax') ///
		`z'=(`low_z' `mid_z' `hi_z') ///
       ) ///
      post

marginsplot ,name(step1, replace)

marginsplot, recastci(rarea) name(step2, replace)


marginsplot, recastci(rarea) ciopts(color(%10)) name(step3, replace)


marginsplot, recastci(rarea) ciopts(color(%10)) ///
				recast(line) ///
				name(step4, replace)


marginsplot, recastci(rarea) ciopts(color(%10)) ///
				recast(line) ///
				ytitle("Pr(College)") ///
				xtitle("SES") ///
				xlabel(-2(.3)2) ///
				legend(order(4 "25th percentile, Math Test" ///
							5 "Median, Math Test"  ///
							6 "75th percentile, Math Test")) ///
				legend(cols(1)) ///		
				title("") ///
				name(step5, replace)				
	  
	  

estimates restore full_model

local x byses1

sum `x', detail

local no_steps=20

local mymin=r(min)
local mymax=r(max)
local diff=`mymax'-`mymin'
local step=`diff'/`no_steps'
    
local z bynels2m

sum `z', detail

local low_z=r(p25)
local mid_z=r(p50)
local hi_z=r(p75)

local race_levels "Native_American" "Asian_Pacific_Islander" "African-American"  "Hispanic"  "Multiracial"  "White"

local i=1

foreach race of local race_levels{ 

estimates restore full_model

quietly margins , predict(pr) ///
    at((mean) _continuous ///
        (base) _factor ///
		 byrace2=`i' ///
		 female=1 ///
        `x'=(`mymin'(`step')`mymax') ///
		`z'=(`low_z' `mid_z' `hi_z') ///
       ) ///
      post

marginsplot, recastci(rarea) ciopts(color(%10)) ///
				recast(line) ///
				ytitle("Pr(College)") ///
				xtitle("SES") ///
				xlabel(-2(.3)2) ///
				legend(order(4 "25th percentile, Math Test" ///
							5 "Median, Math Test"  ///
							6 "75th percentile, Math Test")) ///
				legend(cols(1)) ///		
				title(`race') 
				
graph save "prob_`i'.gph", replace				
		
local i=`i'+1				
}	  



// Other functions

estimates restore full_model

listcoef /*Display odds ratios from model in memory */

logistic `y' `ses' `demog' `tests'  /*Works too */

exit 
 
/* Measures of model fit: all imperfect */

// Built in methods

estimates restore full_model

fitstat

/* Likelihood ratio test for nested models */
quietly logit `y' `ses' if mysample==1

est store ses

lrtest full_model ses

quietly logit `y'  `demog' if mysample==1

est store demog

lrtest full_model demog

quietly logit `y' `tests' if mysample==1

est store tests

lrtest full_model tests

estimates restore full_model

/* Percent Correctly Predicted  */

estat classification

// Sensitivity/Specificity trafeoff

estimates restore full_model

lsens, genprob(pr) genspec(spec) gensens(sens) replace

browse pr spec sens

/*Area under Receiver/Operator Characteristic Curve */

lroc, name("lroc1")

/*comparing two models */

est restore ses

predict xb_ses, xb

est restore full_model

predict xb_full, xb
 
roccomp f2evratt xb_full xb_ses, graph summary name("roc2")

graph export roc_curve.pdf , replace name("roc2")  ///

exit
