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




use "$sim_dir/bias_rmse.dta", clear
preserve
drop country_string 
decode country_byte, gen (country_string)
drop if country_string=="EST"
export delimited using "$sim_dir/bias_rmse.csv", replace 
restore 

  //Figure 
twoway (lpoly RMSE_reduction g_n1 , color(orange%80)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_reduction g_n1,   mcolor(navy%100) msy(circle) msize(small)     ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("g{sub:N{sub:1}}", size(small))  ///
    ytitle("Reduction in RMSE", size(small)) ///
    legend(off) ///
 saving("$figs/overlay_alt1.gph", replace) 


 //Figure 
twoway (lpoly RMSE_reduction g_n2 , color(orange%80)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_reduction g_n2,   mcolor(navy%100) msy(circle) msize(small)     ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("g{sub:N{sub:2}}", size(small))  ///
    ytitle("Reduction in RMSE", size(small)) ///
    legend(off) ///
 saving("$figs/overlay_alt2.gph", replace) 


//Figure 
twoway (lpoly RMSE_reduction corr_N1_N2_out , color(orange%80)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_reduction corr_N1_N2_out,   mcolor(navy%100) msy(circle) msize(small)     ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("ρ(g{sub:N{sub:1}},g{sub:N{sub:2}})", size(small))  ///
  ytitle("Reduction in RMSE", size(small)) ///
    legend(off) ///
 saving("$figs/overlay_alt3.gph", replace) 
 
 
 twoway (lpoly RMSE_reduction corr_N1_K_out , color(orange%80)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_reduction corr_N1_K_out,   mcolor(navy%100) msy(circle) msize(small)     ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("ρ(g{sub:N{sub:1}},g{sub:K})", size(small))  ///
    ytitle("Reduction in RMSE", size(small)) ///
    legend(off) ///
 saving("$figs/overlay_alt4.gph", replace) 
 
 



graph combine "$figs/overlay_alt1.gph" "$figs/overlay_alt2.gph" "$figs/overlay_alt3.gph" "$figs/overlay_alt4.gph" ,  ///
col(2) imargin(none) 
graph export  "$figs/four_cases_overlay.png", replace 
graph export  "$figs/four_cases_overlay.pdf", replace 


 