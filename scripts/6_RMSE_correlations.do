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


//read RMSE values
use "$sim_dir/bias_rmse.dta", clear
drop country_string 
decode country_byte, gen (countrycode)
	
//merge PWT
merge 1:1 countrycode using "$processed/pwt100_xsection.dta", nogen keep(3)
merge 1:1 countrycode using "$processed/wdi_resource_rents_2019.dta" , nogen keep(3)

replace gdp_pc = ln(gdp_pc) 

replace rgdpna = ln(rgdpna)



//Figure a
reg RMSE_reduction gdp_pc, r
lincom gdp_pc

local b: display %4.3f r(estimate)
local p: display %4.3f r(p)

twoway  ///
(lfit RMSE_reduction gdp_pc, lpattern(dash) lcolor(gray%60)) ///
(lpoly RMSE_reduction gdp_pc , color(orange%80)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_reduction gdp_pc,   mcolor(navy%100) msy(circle) msize(small) ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
xtitle("ln(GDP per Capita) in 2019", size(small))  ///
text(0.005 7.5 "{&beta} = `b', {it:p}: `p'.", size(vsmall))  ///
ytitle("Reduction in RMSE", size(small)) ///
legend(off) ///
title("{bf:a}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
saving("$figs/overlay_alt1.gph", replace) 


//Figure b
reg RMSE_reduction rgdpna, r
lincom rgdpna

local b: display %4.3f r(estimate)
local p: display %4.3f r(p)

twoway  ///
(lfit RMSE_reduction rgdpna, lpattern(dash) lcolor(gray%60)) ///
(lpoly RMSE_reduction rgdpna , color(orange%80)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_reduction rgdpna,   mcolor(navy%100) msy(circle) msize(small) ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
text(0.01 9 "{&beta} = `b', {it:p}: `p'.", size(vsmall))  ///
xtitle("ln(GDP) in 2019", size(small))  ///
ytitle("Reduction in RMSE", size(small)) ///
legend(off) ///
title("{bf:b}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
saving("$figs/overlay_alt2.gph", replace) 


 
//Figure c
reg RMSE_reduction hc, r
lincom hc

local b: display %4.3f r(estimate)
local p: display %4.3f r(p)

twoway  ///
(lfit RMSE_reduction hc, lpattern(dash) lcolor(gray%60)) ///
(lpoly RMSE_reduction hc , color(orange%80)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_reduction hc,   mcolor(navy%100) msy(circle) msize(small) ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
text(0.01 1.5 "{&beta} = `b', {it:p}: `p'.", size(vsmall))  ///
xtitle("Human Capital Index in 2019", size(small))  ///
ytitle("Reduction in RMSE", size(small)) ///
legend(off) ///
title("{bf:c}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_alt3.gph", replace) 


  
//Figure d
reg RMSE_reduction statcap, r
lincom statcap

local b: display %4.3f r(estimate)
local p: display %4.3f r(p)
reg RMSE_reduction statcap, r
lincom statcap

local b: display %4.3f r(estimate)
local p: display %4.3f r(p)


twoway  ///
(lfit RMSE_reduction statcap, lpattern(dash) lcolor(gray%60)) ///
(lpoly RMSE_reduction statcap , color(orange%80)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_reduction statcap,   mcolor(navy%100) msy(circle) msize(small) ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
xtitle("Statistical Capacity in 2019", size(small))  ///
text(0.01 30 "{&beta} = `b', {it:p}: `p'.", size(vsmall))  ///
ytitle("Reduction in RMSE", size(small)) ///
legend(off) ///
title("{bf:d}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_alt4.gph", replace) 




//figure e

reg RMSE_reduction resource_rents_gdp, r
lincom resource_rents_gdp

local b: display %4.3f r(estimate)
local p: display %4.3f r(p)

twoway  ///
(lfit RMSE_reduction resource_rents_gdp, lpattern(dash) lcolor(gray%60)) ///
(lpoly RMSE_reduction resource_rents_gdp , color(orange%80)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_reduction resource_rents_gdp,   mcolor(navy%100) msy(circle) msize(small) ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
xtitle("Resource Rents as Share of GDP in 2019", size(small))  ///
text(0.005 30 "{&beta} = `b', {it:p}: `p'.", size(vsmall))  ///
ytitle("Reduction in RMSE", size(small)) ///
legend(off) ///
title("{bf:e}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_alt5.gph", replace) 

 
 
 
//figure f

reg RMSE_reduction resource_depletion_gni, r
lincom resource_depletion_gni

local b: display %4.3f r(estimate)
local p: display %4.3f r(p)

twoway  ///
(lfit RMSE_reduction resource_depletion_gni, lpattern(dash) lcolor(gray%60)) ///
(lpoly RMSE_reduction resource_depletion_gni , color(orange%80)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_reduction resource_depletion_gni,   mcolor(navy%100) msy(circle) msize(small) ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
xtitle("Natural Resource Depletion as a Share of GNI in 2019", size(small))  ///
text(0.005 20 "{&beta} = `b', {it:p}: `p'.", size(vsmall))  ///
ytitle("Reduction in RMSE", size(small)) ///
legend(off) ///
title("{bf:f}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_alt6.gph", replace) 


graph combine "$figs/overlay_alt1.gph" "$figs/overlay_alt2.gph" "$figs/overlay_alt3.gph" "$figs/overlay_alt4.gph" "$figs/overlay_alt5.gph"  "$figs/overlay_alt6.gph" ,  ///
col(2) imargin(none) 
graph export  "$figs/RMSE_Correlations.png", replace 
graph export  "$figs/RMSE_Correlations.pdf", replace 




sureg ///
    (RMSE_reduction gdp_pc) ///
    (RMSE_reduction rgdpna) ///
    (RMSE_reduction hc) ///
    (RMSE_reduction statcap) 

	reg RMSE_reduction gdp_pc rgdpna hc resource_rents_gdp  resource_depletion_gni , r
	test  gdp_pc rgdpna hc resource_rents_gdp resource_depletion_gni
	