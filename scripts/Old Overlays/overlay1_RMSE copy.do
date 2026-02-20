clear all	
set maxvar 32000
set seed 1234
// set scheme plotplain
set scheme stcolor




use "$sim_dir/RMSE_case1.dta", clear
 
 //reformat
 format MSE_difference %9.2e

label var MSE_difference  "Reduction in Absolute Bias


sum  MSE_difference

scalar scale_max = max(abs(r(max)),abs(r(min)))
scalar factor = (1/8)*1.0001
local ub1 =  1*factor*scale_max
local ub2 =  2*factor*scale_max
local ub3 =  3*factor*scale_max
local ub4 =  4*factor*scale_max
local ub5 =  5*factor*scale_max
local ub6 =  6*factor*scale_max
local ub7 =  7*factor*scale_max
local ub8 =  8*factor*scale_max

local lb8 = -1*factor*scale_max
local lb7 = -2*factor*scale_max
local lb6 = -3*factor*scale_max
local lb5 = -4*factor*scale_max
local lb4 = -5*factor*scale_max
local lb3 = -6*factor*scale_max
local lb2 = -7*factor*scale_max
local lb1 = -8*factor*scale_max

append using "$processed/CWON_data.dta"

keep if  MSE_difference!=.  | (g_n1>0  & g_n2>0)



//Figure 
twoway (contour MSE_difference  corr_N1_K_out corr_N1_N2_out if MSE_difference!=. ,  ccuts(`lb1' `lb2' `lb3' `lb4' `lb5' `lb6' `lb7' `lb8' 0 0 `ub1' `ub2' `ub3' `ub4' `ub5' `ub6' `ub7' `ub8') ///
  zlabel(, format(%9.1e) labsize(tiny)) ///
  xlabel(, format(%9.1f)) ///
  ylabel(, format(%9.1f)) ///
ccolors(blue  blue*0.9  blue*0.8  blue*0.7  blue*0.6  blue*.5  blue*.4  blue*.3  ///
blue*.2  ///
green*.2 green*.3 green*.4 green*.5 green*.6 green*.8 green*.9 green)  ) ///
( line corr_N1_K_out corr_N1_N2_out if  corr_N1_N2_out==0, lcolor(black) lpattern(dash)  legend(off) ) ///
( line corr_N1_K_out corr_N1_N2_out if  corr_N1_K_out==0, lcolor(black) lpattern(dash)  legend(off) )  ///
( scatter corr_N1_K_out corr_N1_N2_out if g_n1!=. , mlabel(country_byte)    mlabcolor(black) mlabsize(tiny)  msymbol(none)) , /// 
xlabel(-0.9(0.45)0.9, labsize(tiny)) ///
ylabel(-0.9(0.45)0.9, labsize(tiny)) ///
title("Case 1: g{sub:N{sub:1}}>0 and g{sub:N{sub:2}}>0") ///
 ytitle("ρ(g{sub:N{sub:1}},g{sub:K})" , size(vsmall) )  ///
  xtitle("ρ(g{sub:N{sub:1}},g{sub:N{sub:2}})", size(vsmall))  ///
  ztitle("Reduction in Expected Squared Error", size(vsmall)) ///
legend(order(1 "" 2 "" 3 "" 4 "")  size(tiny) )  ///
 saving("$figs/overlay1_bias.gph", replace) 






//interpolations

duplicates r corr_N1_K_out corr_N1_N2_out


gen corr_N1_N2_adjust = corr_N1_N2_out*100
gen corr_N1_K_adjust = corr_N1_K_out*100
format corr_N1_N2_adjust %9.0g
format corr_N1_K_adjust %9.0g
duplicates r corr_N1_K_adjust corr_N1_N2_adjust
replace corr_N1_N2_adjust = int(corr_N1_N2_adjust) 
replace corr_N1_K_adjust = int(corr_N1_K_adjust) 


npregress kernel MSE_difference corr_N1_K_adjust corr_N1_N2_adjust if MSE_difference!=. ,     estimator(constant) predict(oos_mean_np,  replace noderivatives) noderivatives 

sort corr_N1_N2_adjust corr_N1_K_adjust 
by corr_N1_N2_adjust corr_N1_K_adjust: egen oos_means = max(oos_mean_np)
keep if g_n1!=.

save "$sim_dir/RMSE_oos_means1.dta", replace 
