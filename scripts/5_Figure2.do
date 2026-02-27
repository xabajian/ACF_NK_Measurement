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
drop country_string 
decode country_byte, gen (country_string)
drop if country_string=="EST"
export delimited using "$sim_dir/bias_rmse.csv", replace 



  //Figure 
twoway (lpoly RMSE_reduction g_n1 , color(orange%80)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_reduction g_n1,   mcolor(navy%100) msy(circle) msize(small)     ///
yline(0, lpattern(dash) lcolor(gray%40) ) ///
xline(0, lpattern(dash) lcolor(gray%40) ) ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average Growth in Renewable Resource Use (g{sub:N{sub:1}}), 1996-2019", size(small))  ///
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
  xtitle("Average Growth in Renewable Resource Use (g{sub:N{sub:2}}), 1996-2019", size(small))  ///
    ytitle("Reduction in RMSE", size(small)) ///
    legend(off) ///
 saving("$figs/overlay_alt2.gph", replace) 


//Figure 
// twoway (lpoly RMSE_reduction corr_N1_N2_out , color(orange%80)  lwidth(.6) lpattern(dash)) ///
// (scatter RMSE_reduction corr_N1_N2_out,   mcolor(navy%100) msy(circle) msize(small)     ///
// yline(0, lpattern(dash) lcolor(gray%40) ) ///
// xline(0, lpattern(dash) lcolor(gray%40) ) ///
// xlabel(, nogrid  labsize(small)) ///
// ylabel(, nogrid  labsize(small)) ), ///
//   xtitle("ρ(g{sub:N{sub:1}},g{sub:N{sub:2}})", size(small))  ///
//   ytitle("Reduction in RMSE", size(small)) ///
//     legend(off) ///
//  saving("$figs/overlay_alt3.gph", replace) 
// 
// 
//  twoway (lpoly RMSE_reduction corr_N1_K_out , color(orange%80)  lwidth(.6) lpattern(dash)) ///
// (scatter RMSE_reduction corr_N1_K_out,   mcolor(navy%100) msy(circle) msize(small)     ///
// yline(0, lpattern(dash) lcolor(gray%40) ) ///
// xline(0, lpattern(dash) lcolor(gray%40) ) ///
// xlabel(, nogrid  labsize(small)) ///
// ylabel(, nogrid  labsize(small)) ), ///
//   xtitle("ρ(g{sub:N{sub:1}},g{sub:K})", size(small))  ///
//     ytitle("Reduction in RMSE", size(small)) ///
//     legend(off) ///
//  saving("$figs/overlay_alt4.gph", replace) 
// 
 

  twoway (lfit g_A_bar g_A_bar , color(grey%20)   lpattern(dash)) ///
  (lpoly g_hat_A g_A_bar , color(navy%30)  lwidth(.6) lpattern(dash)) ///
(scatter g_hat_A g_A_bar,   mcolor(red%100) msy(circle) msize(small)     ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average g{sub:A} from the PWT", size(small))  ///
    ytitle("Estimated ĝ{sub:A} from Model 1", size(small)) ///
    legend(off) ///
 saving("$figs/overlay_alt3.gph", replace) 

   twoway (lfit g_A_bar g_A_bar , color(grey%20)   lpattern(dash)) ///
  (lpoly g_tilde_A g_A_bar , color(navy%30)  lwidth(.6) lpattern(dash)) ///
(scatter g_tilde_A g_A_bar,   mcolor(red%100) msy(circle) msize(small)     ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average g{sub:A} from the PWT", size(small))  ///
    ytitle("Estimated g̃{sub:A} from Model 2", size(small)) ///
	    legend(off) ///
	 saving("$figs/overlay_alt4.gph", replace) 

	 
  
 
 	  twoway (lfit RMSE_baseline_NK RMSE_baseline_NK , color(grey%20)   lpattern(dash)) ///
  (lpoly RMSE_baseline RMSE_baseline_NK , color(navy%30)  lwidth(.6) lpattern(dash)) ///
(scatter RMSE_baseline RMSE_baseline_NK,   mcolor(red%100) msy(circle) msize(small)     ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("RMSE when Omitting Non-Renewables", size(small))  /// 
    ytitle("RMSE when Including Non-Renewables", size(small)) ///
	    legend(off) ///
  saving("$figs/overlay_alt5.gph", replace) 
    

	
 
 
  twoway hist RMSE_reduction_share, freq ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small))  ///
    xtitle("Share of RMSE Reduced Going from Model 1 to 2", size(small)) ///
	ytitle("Number of Countries") ///
    legend(off) ///
 saving("$figs/overlay_alt6.gph", replace) 
 



graph combine "$figs/overlay_alt1.gph" "$figs/overlay_alt2.gph" "$figs/overlay_alt3.gph" "$figs/overlay_alt4.gph" "$figs/overlay_alt5.gph" "$figs/overlay_alt6.gph" ,  ///
col(2) imargin(none) 
graph export  "$figs/four_cases_overlay.png", replace 
graph export  "$figs/four_cases_overlay.pdf", replace 


 