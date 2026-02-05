clear all
set maxvar 32000
set seed 1234

*===============================*
* Paths / globals
*===============================*


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

encode countrycode, gen(country_byte)	
xtset country_byte year
//lkeep care abouts
// PWT variables for growth within countries over time
gen log_tfp       = ln(rtfp)
gen log_K         = ln(rkna)
gen log_L         = ln(emp)

gen g_A = d.log_tfp
gen g_K = d.log_K
gen g_L = d.log_L
gen N = 1 
keep if countrycode=="USA"

collapse (sum) N (mean) g_A g_K g_L (sd) sd_A = g_A sd_K = g_K sd_L = g_L, by(country_byte)


save "$processed/usa_growth_accounting.dta", replace 
