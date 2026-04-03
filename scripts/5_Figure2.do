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

sum , d


/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step 2 --  RF evidence in text and appendix

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/



eststo clear

*(1)
reg RMSE_reduction corr_N1_K_out corr_N1_N2_out corr_N2_L corr_N1_L corr_L_K corr_N2_K_out g_L g_n1 g_k g_n2 g_A sdA
eststo m1


*---- export with esttab ----*
esttab m1 using "$tables/app_tab_decomp.tex", replace ///
    title("RMSE Improvement Decomposition Growth vs. Natural Capital Growth") ///
    keep(corr_N1_K_out corr_N1_N2_out corr_N2_L corr_N1_L corr_L_K corr_N2_K_out g_L g_n1 g_k g_n2 g_A sdA) ///
    b(3) se(3) ///
    star(* 0.05) ///
    stats(R2 N, ///
          labels("R Squared" "N") ///
          fmt(3 3 0 3))
*---- export with esttab ----*


//correlations 
reg RMSE_reduction corr_N1_K_out corr_N1_N2_out, r
test corr_N1_K_out corr_N1_N2_out

reg RMSE_reduction corr_N1_K_out corr_N1_N2_out corr_N2_L corr_N1_L corr_L_K corr_N2_K_out g_L g_n1 g_k g_n2 g_A sdA
test corr_N1_K_out corr_N1_N2_out

cvlasso RMSE_reduction corr_N1_K_out corr_N1_N2_out corr_N2_L corr_N1_L corr_L_K corr_N2_K_out g_L g_n1 g_k g_n2 g_A sdA
cvlasso, lopt

/* 
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step  3 -- Make Figure 2

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
    ytitle("Estimated γ̃{sub:A} from Model 1", size(small)) ///
    legend(off) ///
    title("{bf:c}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_alt3.gph", replace) 

  //Figure d
twoway (lfit g_A_bar g_A_bar , color(grey%20)   lpattern(dash)) ///
(scatter g_tilde_A g_A_bar,   mcolor(red%100) msy(circle) msize(small)     ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average g{sub:A} from the PWT", size(small))  ///
    ytitle("Estimated γ̂{sub:A} from Model 2", size(small)) ///
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
    start(-0.2) width(0.1) ///
    xlabel(-0.2(0.1)0.9, nogrid labsize(small)) ///
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



/* 
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step  4 -- Make  12 panel appendix FWL figure

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/


*======================================*
* Frisch-Waugh-Lovell partial-regression plots
* with shaded 95% confidence intervals
* Outcome: RMSE_reduction
*======================================*

local yvar RMSE_reduction
local xvars corr_N1_K_out corr_N1_N2_out corr_N2_L corr_N1_L corr_L_K corr_N2_K_out g_L g_n1 g_k g_n2 g_A sdA
local letters a b c d e f g h i j k l

* Clean up old graphs / variables
capture graph drop _all
foreach x of local xvars {
    capture drop resid_`x'
    capture drop resid_y_`x'
    capture drop fit_`x'
    capture drop sefit_`x'
    capture drop lb_`x'
    capture drop ub_`x'
}

local i = 1
foreach x of local xvars {

    * All controls except focal regressor
    local controls : list xvars - x

    * Residualize outcome on all other regressors
    quietly reg `yvar' `controls'
    predict resid_y_`x', resid

    * Residualize focal regressor on all other regressors
    quietly reg `x' `controls'
    predict resid_`x', resid

    * Partial regression of residualized outcome on residualized regressor
    quietly reg resid_y_`x' resid_`x'

    * Fitted values and standard error of mean prediction
    predict fit_`x', xb
    predict sefit_`x', stdp

    * 95% confidence interval
    gen lb_`x' = fit_`x' - 1.96*sefit_`x'
    gen ub_`x' = fit_`x' + 1.96*sefit_`x'

    * Sort for clean line/rarea drawing
    gsort resid_`x'

    * Panel letter
    local panel : word `i' of `letters'

    * Graph
    twoway ///
        (rarea ub_`x' lb_`x' resid_`x', ///
            color(maroon%18) lcolor(maroon%18)) ///
        (line fit_`x' resid_`x', ///
            lcolor(maroon) lwidth(medthin)) ///
        (scatter resid_y_`x' resid_`x', ///
            mcolor(navy%100) msymbol(circle) msize(small)), ///
        yline(0, lpattern(dash) lcolor(gs10)) ///
        xline(0, lpattern(dash) lcolor(gs10)) ///
        xlabel(, nogrid labsize(small)) ///
        ylabel(, nogrid labsize(small)) ///
        xtitle("Residualized `x'", size(small)) ///
        ytitle("Residualized RMSE reduction", size(small)) ///
        legend(off) ///
        title("{bf:`panel'}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
        saving("$figs/overlay_alt`i'.gph", replace)

    local ++i
}

* Combine all 12 graphs
graph combine ///
    "$figs/overlay_alt1.gph" ///
    "$figs/overlay_alt2.gph" ///
    "$figs/overlay_alt3.gph" ///
    "$figs/overlay_alt4.gph" ///
    "$figs/overlay_alt5.gph" ///
    "$figs/overlay_alt6.gph" ///
    "$figs/overlay_alt7.gph" ///
    "$figs/overlay_alt8.gph" ///
    "$figs/overlay_alt9.gph" ///
    "$figs/overlay_alt10.gph" ///
    "$figs/overlay_alt11.gph" ///
    "$figs/overlay_alt12.gph", ///
    col(4) ///
    imargin(none) ///
    graphregion(color(white))

graph export "$figs/12_cases_app.png", replace 
graph export "$figs/12_cases_app.pdf", replace
