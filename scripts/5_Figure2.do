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


preserve
eststo clear

*(1)
// Positive reduction: abs(bias0) - abs(bias1), consistent with the FWL plots and manuscript.
sum bias_reduction, d
reg bias_reduction corr_N1_K_out corr_N1_N2_out corr_N2_L corr_N1_L corr_L_K corr_N2_K_out g_L g_n1 g_k g_n2 g_A sdA
eststo m1


*---- export with esttab ----*
esttab m1 using "$tables/app_tab_decomp_bias.tex", replace ///
    title("Absolute Bias Reduction Decomposition") ///
    keep(corr_N1_K_out corr_N1_N2_out corr_N2_L corr_N1_L corr_L_K corr_N2_K_out g_L g_n1 g_k g_n2 g_A sdA) ///
    b(3) se(3) ///
    star(* 0.05) ///
    stats(R2 N, ///
          labels("R Squared" "N") ///
          fmt(3 3 0 3))
*---- export with esttab ----*
restore

//correlations 
reg bias_reduction corr_N1_K_out corr_N1_N2_out, r
test corr_N1_K_out 

reg bias_reduction corr_N1_K_out corr_N1_N2_out corr_N2_L corr_N1_L corr_L_K corr_N2_K_out g_L g_n1 g_k g_n2 g_A sdA
test corr_N1_K_out  g_n1 g_n2

cvlasso bias_reduction corr_N1_K_out corr_N1_N2_out corr_N2_L corr_N1_L corr_L_K corr_N2_K_out g_L g_n1 g_k g_n2 g_A sdA
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
(scatter bias_reduction g_n1,   mcolor(navy%100) msy(circle) msize(small)     ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average Growth in Non-Renewable Resource Use (g{sub:N{sub:1}}), 1996-2019", size(small))  ///
    ytitle("Reduction in absolute bias", size(small)) ///
    legend(off) ///
    title("{bf:a}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_bias_main1.gph", replace) 



 //Figure b
twoway ///
(scatter bias_reduction g_n2,   mcolor(navy%100) msy(circle) msize(small)     ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average Growth in Renewable Resource Use (g{sub:N{sub:2}}), 1996-2019", size(small))  ///
    ytitle("Reduction in absolute bias", size(small)) ///
    legend(off) ///
    title("{bf:b}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_bias_main2.gph", replace) 


 
 //Figure c
twoway (lfit g_A_bar g_A_bar , color(grey%20)   lpattern(dash)) ///
(scatter g_hat_A g_A_bar,   mcolor(red%100) msy(circle) msize(small)     ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average g{sub:A} from the PWT", size(small))  ///
    ytitle("Expected TFP, Model 1", size(small)) ///
    legend(off) ///
    title("{bf:c}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_bias_main3.gph", replace) 

  //Figure d
twoway (lfit g_A_bar g_A_bar , color(grey%20)   lpattern(dash)) ///
(scatter g_tilde_A g_A_bar,   mcolor(red%100) msy(circle) msize(small)     ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average g{sub:A} from the PWT", size(small))  ///
    ytitle("Expected TFP, Model 2", size(small)) ///
    legend(off) ///
    title("{bf:d}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_bias_main4.gph", replace) 

	 

  * Absolute biases relative to the observed average TFP growth.
  * Model 1 omits N1 and N2; Model 2 includes N1.
  capture drop abs_bias_model1 abs_bias_model2
  gen double abs_bias_model1 = abs(g_hat_A - g_A_bar) if !missing(g_hat_A, g_A_bar)
  gen double abs_bias_model2 = abs(g_tilde_A - g_A_bar) if !missing(g_tilde_A, g_A_bar)

  * Derive the corresponding fraction of absolute bias eliminated, if not supplied.
  capture confirm variable bias_reduction_share
  if _rc {
      gen double bias_reduction_share = bias_reduction / abs_bias_model1 ///
          if abs_bias_model1 > 0 & !missing(bias_reduction)
  }

  //Figure e
twoway (lfit abs_bias_model2 abs_bias_model2 , color(grey%20)   lpattern(dash)) ///
(scatter abs_bias_model1 abs_bias_model2,   mcolor(red%100) msy(circle) msize(small)     ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Absolute Bias, Model 2", size(small))  /// 
    ytitle("Absolute Bias, Model 1", size(small)) ///
    legend(off) ///
    title("{bf:e}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
  saving("$figs/overlay_bias_main5.gph", replace) 
    

	sum bias_reduction_share, d
	replace bias_reduction_share = max(bias_reduction_share, -0.09)
	// Figure f
twoway hist bias_reduction_share, freq ///
    start(-0.1) width(0.1) ///
    xlabel(-0.1(0.1)1.0, nogrid labsize(small)) ///
	xline(0, lpattern(dash) lcolor(gray%40) ) ///
    ylabel(, nogrid labsize(small)) ///
    xtitle("Share of absolute bias reduced (Model 1 to 2)", size(small)) ///
    ytitle("Number of Countries") ///
    legend(off) ///
    title("{bf:f}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
    saving("$figs/overlay_bias_main6.gph", replace)


graph combine "$figs/overlay_bias_main1.gph" "$figs/overlay_bias_main2.gph" "$figs/overlay_bias_main3.gph" "$figs/overlay_bias_main4.gph" "$figs/overlay_bias_main5.gph" "$figs/overlay_bias_main6.gph" ,  ///
col(2) imargin(none) 
graph export  "$figs/four_cases_overlay_bias.png", replace 
graph export  "$figs/four_cases_overlay_bias.pdf", replace 

sum bias_reduction, detail

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
* Outcome: bias_reduction
*======================================*

local yvar bias_reduction
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
        ytitle("Residualized absolute-bias reduction", size(small)) ///
        legend(off) ///
        title("{bf:`panel'}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
        saving("$figs/overlay_bias_fwl`i'.gph", replace)

    local ++i
}

* Combine all 12 graphs
graph combine ///
    "$figs/overlay_bias_fwl1.gph" ///
    "$figs/overlay_bias_fwl2.gph" ///
    "$figs/overlay_bias_fwl3.gph" ///
    "$figs/overlay_bias_fwl4.gph" ///
    "$figs/overlay_bias_fwl5.gph" ///
    "$figs/overlay_bias_fwl6.gph" ///
    "$figs/overlay_bias_fwl7.gph" ///
    "$figs/overlay_bias_fwl8.gph" ///
    "$figs/overlay_bias_fwl9.gph" ///
    "$figs/overlay_bias_fwl10.gph" ///
    "$figs/overlay_bias_fwl11.gph" ///
    "$figs/overlay_bias_fwl12.gph", ///
    col(4) ///
    imargin(none) ///
    graphregion(color(white))

graph export "$figs/12_cases_app_bias.png", replace 
graph export "$figs/12_cases_app_bias.pdf", replace
