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

							
program define solve_bias_variance, rclass 


version 12.1
syntax [,  number_periods(integer 25) corr_N1_K(real 0.01) corr_N1_N2(real 0.01) corr_N2_K(real 0.01) gn1(real 0.01)  gn2(real 0.01)   gK(real 0.01) sdK(real 0.01) sdA(real 0.01) sdn1(real 0.01) sdn2(real 0.01) gA(real 0.01)  gL(real 0.01) sdL(real 0.01) corr_N1_L(real 0.01) corr_N2_L(real 0.01)   corr_L_K(real 0.01)  ] 

		
//gammas 
scalar gamma_1 = 0.05
scalar gamma_2 = 0.05

//make covariances

//------------------------------
// 1) Covariances
//------------------------------
scalar cov_N1_K = `corr_N1_K' * `sdK' * `sdn1'
scalar cov_N1_N2 = `corr_N1_N2'  * `sdn1' * `sdn2'
scalar cov_K_N2 = `corr_N2_K'  * `sdK' * `sdn2'
scalar cov_L_K    = `corr_L_K'   * `sdL'  * `sdK'
scalar cov_L_N1   = `corr_N1_L'  * `sdL'  * `sdn1'
scalar cov_L_N2   = `corr_N2_L'  * `sdL'  * `sdn2'



// variances
scalar var_K  = (`sdK')^2
scalar var_N1 = (`sdn1')^2
scalar var_N2 = (`sdn2')^2
scalar var_L  = (`sdL')^2

//====================================================
// Estimator 1: regressing output on {K, L} omitting {N1, N2}
// Bias = gamma1*(gn1 - b_N1K*gK - b_N1L*gL) + gamma2*(gn2 - b_N2K*gK - b_N2L*gL)
// where kappas = Var([gK,gL])^{-1} Cov([gK,gL], gN)
//====================================================

// Build Var([K L]) and its inverse
matrix VKL = ( var_K , cov_L_K \ ///
               cov_L_K , var_L )
matrix iVKL = invsym(VKL)

// Cov([K L], N1) and Cov([K L], N2)
matrix cKL_N1 = ( cov_N1_K \ cov_L_N1 )
matrix cKL_N2 = ( cov_K_N2  \ cov_L_N2 )

// Projection coefficients (kappas)
matrix bKL_N1 = iVKL * cKL_N1   // [b_N1K, b_N1L]'
matrix bKL_N2 = iVKL * cKL_N2   // [b_N2K, b_N2L]'


// Bias term for estimator A (two omitted stocks, now partialling out K and L)
scalar tfp_bias_NK = ///
      gamma_1 * ( `gn1' - bKL_N1[1,1]*`gK' - bKL_N1[2,1]*`gL' ) ///
    + gamma_2 * ( `gn2' - bKL_N2[1,1]*`gK' - bKL_N2[2,1]*`gL' )

scalar g_hat = `gA' + tfp_bias_NK

//====================================================
// Estimator 2: regressing output on {K, L, N1} omitting {N1}
// Bias = gamma2*(gn2 - [lambdaK*gK + lambdaN1*gn1 + lambdaL*gL])
// where lambda = Var([gK gn1 gL])^{-1} Cov([gK gn1 gL], gn2) w
//====================================================

// Build E([K N1 L]'[K N1 L])^-1
matrix VKN1L = ( var_K    , cov_N1_K , cov_L_K  \ ///
                 cov_N1_K , var_N1   , cov_L_N1 \ ///
                 cov_L_K  , cov_L_N1 , var_L    )

matrix iVKN1L = invsym(VKN1L)

// Build Cov([K N1 L], N2)
matrix cKN1L_N2 = ( cov_K_N2 \ cov_N1_N2 \ cov_L_N2 )

// Projection coefficients (lambdas)
matrix lambda = iVKN1L * cKN1L_N2   // [lambdaK, lambdaN1, lambdaL]'


// Bias term for estimator 2
scalar tfp_bias_1K = gamma_2 * ( `gn2' - lambda[1,1]*`gK' - lambda[2,1]*`gn1' -  lambda[3,1]*`gL' )
scalar g_tilde = `gA' + tfp_bias_1K


//create outputs
scalar TFP_square_bias_1K = sqrt(tfp_bias_1K^2) 
scalar TFP_square_bias_NK = sqrt(tfp_bias_NK^2)
scalar abs_difference_TFP = TFP_square_bias_NK-TFP_square_bias_1K


//repeat for RMSE
scalar var_no_NK = (`sdA'^2 + gamma_1 ^2 * `sdn1'^2 + gamma_2 ^2 * `sdn2'^2 + 2*gamma_1*gamma_2*cov_N1_N2) / `number_periods'
scalar var_1_NK = (`sdA'^2 + gamma_2 ^2 * `sdn1'^2  ) / `number_periods'
scalar MSE_NK = sqrt(var_no_NK + tfp_bias_NK^2)
scalar MSE_1K = sqrt(var_1_NK + tfp_bias_1K^2)
scalar MSE_difference = MSE_NK - MSE_1K


//kick last things out out
return scalar abs_difference_TFP_out = abs_difference_TFP
return scalar MSE_difference_out = scalar(MSE_difference)
return scalar MSE_NK_out = scalar(MSE_NK)
return scalar MSE_1K_out = scalar(MSE_1K)
return scalar reduction_share = scalar((MSE_NK-MSE_1K)/MSE_NK)
return scalar g_hat_out   = scalar(g_hat)
return scalar g_tilde_out = scalar(g_tilde)

//new updates
return scalar bias0_out = scalar(tfp_bias_NK)
return scalar bias1_out = scalar(tfp_bias_1K)
return scalar var0_out = scalar(var_no_NK)
return scalar var1_out = scalar(var_1_NK)
 
 end
 
 
local periodlist early late 



foreach sample_period of local periodlist {

qui{

local read_string = "$processed/CWON_data_" + "`sample_period'" + ".dta"

use "`read_string'", clear
							

							
gen bias_reduction = .
gen RMSE_reduction = .
gen RMSE_baseline = .
gen RMSE_baseline_NK = .
gen RMSE_reduction_share = .
gen g_A_bar = .
gen g_hat_A = .
gen g_tilde_A = .
gen bias0 = .
gen bias1 = .
gen var0 = .
gen var1 = .

count
quietly {
    forvalues i = 1/`r(N)' {
        
        * country-specific values
        local corr_N1_K_in = corr_N1_K_out[`i'] 
        local corr_N1_N2_in = corr_N1_N2_out[`i']
        local corr_N2_K_in = corr_N2_K_out[`i']
		local corr_L_K_in =   corr_L_K[`i'] 
        local corr_L_N1_in = corr_N1_L[`i']
        local corr_L_N2_in = corr_N2_L[`i']
		local g1_in = g_n1[`i']
        local g2_in = g_n2[`i']
		local gk_in = g_k[`i']
		local ga_in = g_A[`i']
		local gl_in = g_L[`i']
		local sd1_in = sdn1[`i']
        local sd2_in = sdn2[`i']
		local sdK_in = sdK[`i']
		local sdA_in = sdA[`i']
		local sdL_in = sdL[`i']
		
		
		
        * Run simulation
		solve_bias_variance, number_periods(25) corr_N1_K(`corr_N1_K_in') corr_N1_N2(`corr_N1_N2_in') corr_N2_K(`corr_N2_K_in')  gn1(`g1_in')  gn2(`g2_in')  gK(`gk_in') sdK(`sdK_in') sdA(`sdA_in') sdn1(`sd1_in') sdn2(`sd2_in') gA(`ga_in')  gL(`gl_in') sdL(`sdL_in') corr_N1_L(`corr_L_N1_in')  corr_N2_L(`corr_L_N2_in')  corr_L_K(`corr_L_K_in') 
			
		//  number_periods(integer 70) corr_N1_K(real 0.01) corr_N1_N2(real 0.01) corr_N2_K(real 0.01) gn1(real 0.01)  gn2(real 0.01)   gK(real 0.01) sdK(real 0.01) sdA(real 0.01) sdn1(real 0.01) sdn2(real 0.01) gA(real 0.01)  gL(real 0.01) sdL(real 0.01) corr_N1_L(real 0.01) corr_N2_L(real 0.01)   corr_L_K(real 0.01)  ] 


        * Store returned results
        replace bias_reduction = r(abs_difference_TFP_out) in `i'
        replace RMSE_reduction = r(MSE_difference_out) in `i'
        replace RMSE_baseline = r(MSE_1K_out) in `i'
        replace RMSE_baseline_NK = r(MSE_NK_out) in `i'
        replace RMSE_reduction_share = r(reduction_share) in `i'
        replace g_hat_A = r(g_hat_out) in `i'
        replace g_tilde_A = r(g_tilde_out) in `i'
		replace g_A_bar = `ga_in' in `i'
		replace bias0 = r(bias0_out)  in `i'
		replace bias1 = r(bias1_out)  in `i' 
		replace var0 = r(var0_out)  in `i'
		replace var1 = r(var1_out)  in `i'
    }
}
keep if sdA!=.
}
//summary stats
local newline = char(10)
display "`newline' `sample_period' PERIOD `newline'"
sum RMSE_reduction, d
count if RMSE_reduction<0



/* 
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

//Alternative Figure 2s

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/

qui{
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
    start(-0.5) width(0.1) ///
    xlabel(-0.5(0.1)0.9, nogrid labsize(small)) ///
	xline(0, lpattern(dash) lcolor(gray%40) ) ///
    ylabel(, nogrid labsize(small)) ///
    xtitle("Share of RMSE Reduced Going from Model 1 to 2", size(small)) ///
    ytitle("Number of Countries") ///
    legend(off) ///
    title("{bf:f}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
    saving("$figs/overlay_alt6.gph", replace)


graph combine "$figs/overlay_alt1.gph" "$figs/overlay_alt2.gph" "$figs/overlay_alt3.gph" "$figs/overlay_alt4.gph" "$figs/overlay_alt5.gph" "$figs/overlay_alt6.gph" ,  ///
col(2) imargin(none) 

graph export  "$figs/four_cases_overlay_`sample_period'.png", replace 
graph export  "$figs/four_cases_overlay_`sample_period'.pdf", replace 
}

}
