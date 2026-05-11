*===============================*
* Paths / globals
*===============================*
clear all
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts"

global root "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
global figs   "$root/figs"
global tables "$root/tables"
global raw "$root/raw"
global processed "$root/processed"
global sim_dir "$root/simulations"

set scheme plotplain




/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step 1 -- Read Data

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/


use "$sim_dir/bias_rmse.dta", clear
drop country_string 
decode country_byte, gen (country_string)
export delimited using "$sim_dir/bias_rmse.csv", replace 
keep if sdA!=.


count

/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step 2 --  make histogram after topcoding RMSE reductions 

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/

//rescale to BPS
replace RMSE_reduction = RMSE_reduction*10000


sum RMSE_reduction, d
local p90 = r(p90)
count if RMSE_reduction > `p90'

//topcode at 90th percentile 
gen RMSE_topcode = min(RMSE_reduction,`p90'+ 1)
local p90_d: display %4.0f r(p90)


// Figure 1
twoway ( hist RMSE_topcode if RMSE_topcode>0, color(green%50)  lcolor(olive%80) freq width(5) start(-5) ) ///
(hist RMSE_topcode if RMSE_topcode<0 , color(blue%50)  lcolor(navy%80) freq width(5) start(-5) ) , ///
	xline(0, lpattern(dash) lcolor(grey%80) ) ///
	    xlabel(-5 0 25 50 75 `p90_d'  , nogrid labsize(small)) ///
	    ylabel(0(10)50, nogrid labsize(small)) ///
    ylabel(, nogrid labsize(small)) ///
    ytitle("Number of Countries") ///
    xtitle("Reduction in RMSE (basis points)") ///
	text(12 92 "{&Delta}RMSE > 90 bps", size(vsmall)) ///
    legend(off) 

graph export  "$figs/fig1.pdf", replace 

