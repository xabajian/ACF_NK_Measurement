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
Run analytical solutions
*/

do 3_sim_bias_program.do
sum bias_reduction RMSE_reduction, d
//0.0022 and 0.0006
/*
Bias case
*/



do "overlay1_bias.do"
do "overlay2_bias.do"
do "overlay3_bias.do"
do "overlay4_bias.do"



graph combine "$figs/overlay1_bias.gph" "$figs/overlay2_bias.gph" "$figs/overlay3_bias.gph" "$figs/overlay4_bias.gph", ///
col(2) imargin(none)
graph export  "$figs/bias_reduction.png", replace 
graph export  "$figs/bias_reduction.pdf", replace 



/*
Combine sub figures for RMSE case
*/


do "overlay1_RMSE.do"
do "overlay2_RMSE.do"
do "overlay3_RMSE.do"
do "overlay4_RMSE.do"


graph combine "$figs/overlay1.gph" "$figs/overlay2.gph" "$figs/overlay3.gph" "$figs/overlay4.gph", ///
col(2) imargin(none)
graph export  "$figs/four_cases_overlay.png", replace 
graph export  "$figs/four_cases_overlay.pdf", replace 



use "$sim_dir/bias_rmse.dta", clear

drop corr_N1_N2_CWON corr_N1_K_CWON

drop country_string
decode country_byte, gen(country_string)
label var country_string "ISO3 Code"
label var g_n1 "$g_{N_1}$"
label var g_n2 "$g_{N_2}$"
label var corr_N1_K_out  "$\rho(g_{N_1},g_K)$"
label var corr_N1_N2_out "$\rho(g_{N_1},g_{N_2})$"
label var bias_reduction "Bias Reduction"
label var RMSE_reduction "RMSE Reduction"
label var dlog_tfp "$g_A$"


 format g_n1 %4.2f
 format g_n2 %4.2f
 format corr_N1_K_out %4.2f
 format corr_N1_N2_out %4.2f
 format bias_reduction %9.2e
  format RMSE_reduction %9.2e
 format dlog_tfp %4.2f

texsave country_string g_n1 g_n2 corr_N1_K_out corr_N1_N2_out  bias_reduction RMSE_reduction dlog_tfp using "$tables/country_tab.tex", replace varlabels
