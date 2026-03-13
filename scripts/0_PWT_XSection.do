clear all
set maxvar 32000
set seed 1234

*===============================*
* Paths / globals
*===============================*
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"

//make directories
capture mkdir quantities
capture mkdir tables
capture mkdir figs
capture mkdir simulations
capture mkdir processed
global root "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
global figs   "$root/figs"
global tables "$root/tables"
global raw "$root/raw"
global processed "$root/processed"
set scheme plotplain


/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step 1 -- Read Data

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/



use "$raw/pwt100.dta", clear

//make GDP per capita
gen gdp_pc = rgdpna/pop
//keep 2019
keep if year==2019
keep gdp_pc rgdpna hc statcap country countrycode

//save out
save "$processed/pwt100_xsection.dta", replace
