
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
