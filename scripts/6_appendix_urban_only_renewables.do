clear all
set maxvar 32000
set seed 1234

*===============================*
* Paths / globals
*===============================*
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/quantities"

global root "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
global figs   "$root/figs"
global tables "$root/tables"
global raw "$root/raw"
global processed "$root/processed"
global CWON_inputs "$root/CWON Data/FR_WLD_2024_195/Reproducibility package/Output/Latest"

set scheme plotplain


/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

//start -- read data for regressions

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/

use "$processed/tornqvist_panel.dta", clear


/* Merges in PWT */
merge 1:1 countrycode year using "$raw/pwt100.dta"
drop _merge
drop if country_byte == .
xtset country_byte year

// winsorize
replace g_Q_NonRenew_Tornquist   =  1 if g_Q_NonRenew_Tornquist   >  1 & g_Q_NonRenew_Tornquist   != .
replace alt_Renew_urban   =  1 if alt_Renew_urban   >  1 & alt_Renew_urban   != .



// PWT variables for growth within countries over time
// keep if year>1995
drop if country_byte == .
xtset country_byte year


// PWT variables for growth within countries over time
gen log_tfp       = ln(rtfp)
gen log_K         = ln(rkna)
gen log_L         = ln(emp)
gen log_HC        = ln(hc)
gen log_lab_share = ln(labsh)
gen log_y         = ln(rgdpna)
gen dlog_tfp = D.log_tfp

// rename for ease
gen g_n1      = g_Q_NonRenew_Tornquist 
gen g_n2      = alt_Renew_urban
gen g_k       = d.log_K if country_byte == country_byte[_n-1]
gen g_L  = d.log_L if country_byte == country_byte[_n-1]


xtset country_byte year

 
	
*============================================================*
* Country-level data out for simulations
*============================================================*
keep if year>1995 & year<2020
tab year
bysort country_byte: egen corr_N1_K      = corr(g_n1 g_k)
bysort country_byte: egen corr_N1_N2     = corr(g_n1 g_n2)
bysort country_byte: egen corr_N2_K     = corr(g_n2 g_k)
bysort country_byte: egen corr_N1_L      = corr(g_n1 g_L)
bysort country_byte: egen corr_N2_L      = corr(g_n2 g_L)
bysort country_byte: egen corr_L_K     = corr(g_L g_k)


collapse (mean) ///
    corr_N1_K corr_N1_N2 corr_N2_L corr_N1_L  corr_L_K corr_N2_K ///
    g_L g_n1 g_k g_n2 dlog_tfp g_A= dlog_tfp (sd) sdL = g_L sdn1 = g_n1 sdK = g_k sdn2 = g_n2 sdA = dlog_tfp , by(country_byte)

sum corr_N1_K corr_N1_N2 corr_N2_L corr_N1_L corr_N2_K ///
    g_n1 g_k g_n2  if g_n1 != .

// scatter g_n1 g_n1_CWON

count
keep if corr_N1_N2 != .
keep if g_k > 0 & g_k != .
count

rename corr_N1_K  corr_N1_K_out
rename corr_N1_N2 corr_N1_N2_out
rename corr_N2_K corr_N2_K_out

tostring country_byte, gen(country_string)
save "$processed/CWON_data_urban_only.dta", replace
save "$root/simulations/CWON_data_urban_only.dta", replace
