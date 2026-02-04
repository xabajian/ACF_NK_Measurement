
*===============================*
* Paths / globals
*===============================*
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts"

global root "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
global figs   "$root/figs"
global tables "$root/tables"
global raw "$root/raw"
global processed "$root/processed"
global sim_dir "$root/simulations"

set scheme plotplain

/*
Run simulations for each case
*/

do "RMSE Program Case1.do"
do "RMSE Program Case2.do"
do "RMSE Program Case3.do"
do "RMSE Program Case4.do"

/*
Generate Sub Figures
*/


do "overlay1.do"
do "overlay2.do"
do "overlay3.do"
do "overlay4.do"

/*
Combine sub figures
*/


graph combine "$figs/overlay1.gph" "$figs/overlay2.gph" "$figs/overlay3.gph" "$figs/overlay4.gph", ///
col(2) imargin(none)
graph export  "$figs/four_cases_overlay.png", replace 
graph export  "$figs/four_cases_overlay.pdf", replace 

use "$sim_dir/oos_means1.dta", clear
append using "$sim_dir/oos_means2.dta"
append using "$sim_dir/oos_means3.dta"
append using "$sim_dir/oos_means4.dta"

drop country_string
decode country_byte, gen(country_string)

label var country_string "ISO3 Code"
label var g_n1 "$g_{N_1}$"
label var g_n2 "$g_{N_2}$"
label var corr_N1_K_adjust "$\rho(g_{N_1},g_K)$"
label var corr_N1_N2_adjust "$\rho(g_{N_1},g_{N_2})$"
label var oos_means "TFP Error Improvement"


sort oos_means
replace corr_N1_N2_out = corr_N1_N2_out/100
replace corr_N1_K_adjust = corr_N1_K_adjust/100


gen countrycode=country_string
merge 1:1 countrycode using "$processed/pwt100_xsection.dta", keep(3)
drop _merge

replace oos_means = oos_means/dlog_TFP

texsave country_string g_n1 g_n2 corr_N1_K_adjust corr_N1_N2_adjust  oos_means dlog_TFP using "$tables/country_tab.tex", replace varlabels
