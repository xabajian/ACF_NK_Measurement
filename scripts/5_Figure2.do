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

/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step  2 -- Make Figure

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/


  //Figure a
twoway  ///
(scatter RMSE_reduction g_n1,   mcolor(navy%100) msy(circle) msize(small)     ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average Growth in Non-Renewable Resource Use (g{sub:N{sub:1}}), 1996-2019", size(small))  ///
    ytitle("Reduction in RMSE", size(small)) ///
    legend(off) ///
    title("{bf:a}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_alt1.gph", replace) 



 //Figure b
twoway ///
(scatter RMSE_reduction g_n2,   mcolor(navy%100) msy(circle) msize(small)     ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average Growth in Renewable Resource Use (g{sub:N{sub:2}}), 1996-2019", size(small))  ///
    ytitle("Reduction in RMSE", size(small)) ///
    legend(off) ///
    title("{bf:b}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_alt2.gph", replace) 


 
 //Figure c
twoway (lfit g_A_bar g_A_bar , color(grey%20)   lpattern(dash)) ///
(scatter g_hat_A g_A_bar,   mcolor(red%100) msy(circle) msize(small)     ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average g{sub:A} from the PWT", size(small))  ///
    ytitle("Estimated ĝ{sub:A} from Model 1", size(small)) ///
    legend(off) ///
    title("{bf:c}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_alt3.gph", replace) 

  //Figure d
twoway (lfit g_A_bar g_A_bar , color(grey%20)   lpattern(dash)) ///
(scatter g_tilde_A g_A_bar,   mcolor(red%100) msy(circle) msize(small)     ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average g{sub:A} from the PWT", size(small))  ///
    ytitle("Estimated g̃{sub:A} from Model 2", size(small)) ///
    legend(off) ///
    title("{bf:d}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_alt4.gph", replace) 

	 
  
  //Figure e
twoway (lfit RMSE_baseline_NK RMSE_baseline_NK , color(grey%20)   lpattern(dash)) ///
(scatter RMSE_baseline RMSE_baseline_NK,   mcolor(red%100) msy(circle) msize(small)     ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("RMSE when Omitting Non-Renewables", size(small))  /// 
    ytitle("RMSE when Including Non-Renewables", size(small)) ///
    legend(off) ///
    title("{bf:e}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
  saving("$figs/overlay_alt5.gph", replace) 
    

	// Figure f
twoway hist RMSE_reduction_share, freq ///
    start(-0.3) width(0.1) ///
    xlabel(-0.3(0.1)0.9, nogrid labsize(small)) ///
	xline(0, lpattern(dash) lcolor(gray%40) ) ///
    ylabel(, nogrid labsize(small)) ///
    xtitle("Share of RMSE Reduced Going from Model 1 to 2", size(small)) ///
    ytitle("Number of Countries") ///
    legend(off) ///
    title("{bf:f}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
    saving("$figs/overlay_alt6.gph", replace)


graph combine "$figs/overlay_alt1.gph" "$figs/overlay_alt2.gph" "$figs/overlay_alt3.gph" "$figs/overlay_alt4.gph" "$figs/overlay_alt5.gph" "$figs/overlay_alt6.gph" ,  ///
col(2) imargin(none) 
graph export  "$figs/four_cases_overlay.png", replace 
graph export  "$figs/four_cases_overlay.pdf", replace 

sum RMSE* ,d

count if g_n1>0 
count if g_n2>0
