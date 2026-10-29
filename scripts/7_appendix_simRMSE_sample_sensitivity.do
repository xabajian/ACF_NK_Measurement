* Corrected CONDITIONAL RMSE: each model conditions on its own included inputs.
* Requires iid errors, linear conditional means, homoskedastic projection
* errors, and TFP independent of inputs. Empirical moments are fixed calibrations.
* With calibrated covariance V, Sxx=(n-ddof)*V and intercept variance is
* tau^2 * [1/n + mu' * inv(V) * mu / (n-ddof)]. Bias formulas are unchanged.
* ddof=1 matches sample SDs/covariances using n-1; use 0 for n normalization.
* Holding moments fixed while changing n defines a hypothetical matched design.
* Calibration uncertainty is excluded. Positive reduction favors including N1.
* Internal model indices 0/1 correspond to manuscript Models 1/2.

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
syntax [,  number_periods(integer 25) covariance_ddof(integer 1) gamma1(real 0.05) gamma2(real 0.05) corr_n1_k(real 0.01) corr_n1_n2(real 0.01) corr_n2_k(real 0.01) gn1(real 0.01)  gn2(real 0.01)   gk(real 0.01) sdk(real 0.01) sda(real 0.01) sdn1(real 0.01) sdn2(real 0.01) ga(real 0.01)  gl(real 0.01) sdl(real 0.01) corr_n1_l(real 0.01) corr_n2_l(real 0.01)   corr_l_k(real 0.01)  ] 

		

    * Validate the moment calibration before using invsym(), which can otherwise
    * silently return a generalized inverse for a singular design covariance.
    if `number_periods' < 4 | `number_periods' >= . {
        display as error "number_periods() must be at least 4"
        exit 198
    }
    if !inlist(`covariance_ddof', 0, 1) {
        display as error "covariance_ddof() must be 0 or 1"
        exit 198
    }
    foreach input in corr_n1_k corr_n1_n2 corr_n2_k corr_n1_l ///
        corr_n2_l corr_l_k gn1 gn2 gk gl sdn1 sdn2 sdk sdl sda gamma1 gamma2 {
        if missing(``input'') {
            display as error "Missing calibration input: `input'"
            exit 498
        }
    }
    if `sdk' <= 0 | `sdl' <= 0 | `sdn1' <= 0 | `sdn2' < 0 | `sda' < 0 {
        display as error "Included-input SDs must be positive; other SDs nonnegative"
        exit 498
    }
    foreach input in corr_n1_k corr_n1_n2 corr_n2_k corr_n1_l corr_n2_l corr_l_k {
        if abs(``input'') > 1 {
            display as error "Correlation outside [-1,1]: `input'"
            exit 498
        }
    }
    scalar rmse_cov_divisor = `number_periods' - `covariance_ddof'
    scalar rmse_n2_active = (`sdn2' > 0)
    matrix rmse_R = (1, `corr_n1_k', `corr_l_k', `corr_n2_k'*rmse_n2_active \ ///
        `corr_n1_k', 1, `corr_n1_l', `corr_n1_n2'*rmse_n2_active \ ///
        `corr_l_k', `corr_n1_l', 1, `corr_n2_l'*rmse_n2_active \ ///
        `corr_n2_k'*rmse_n2_active, `corr_n1_n2'*rmse_n2_active, ///
        `corr_n2_l'*rmse_n2_active, rmse_n2_active)
    matrix symeigen rmse_evec rmse_eval = rmse_R
    if rmse_eval[1,4] < -1e-10 {
        display as error "Input correlations do not define a positive semidefinite covariance"
        exit 498
    }
    matrix rmse_R_included = rmse_R[1..3,1..3]
    matrix symeigen rmse_evec rmse_eval = rmse_R_included
    if rmse_eval[1,3] <= 1e-10 {
        display as error "Included-input covariance is singular or numerically ill-conditioned"
        exit 498
    }

//gammas 
scalar gamma_1 = `gamma1'
scalar gamma_2 = `gamma2'

//make covariances

//------------------------------
// 1) Covariances
//------------------------------
scalar cov_N1_K = `corr_n1_k' * `sdk' * `sdn1'
scalar cov_N1_N2 = `corr_n1_n2'  * `sdn1' * `sdn2'
scalar cov_K_N2 = `corr_n2_k'  * `sdk' * `sdn2'
scalar cov_L_K    = `corr_l_k'   * `sdl'  * `sdk'
scalar cov_L_N1   = `corr_n1_l'  * `sdl'  * `sdn1'
scalar cov_L_N2   = `corr_n2_l'  * `sdl'  * `sdn2'



// variances
scalar var_K  = (`sdk')^2
scalar var_N1 = (`sdn1')^2
scalar var_N2 = (`sdn2')^2
scalar var_L  = (`sdl')^2

//====================================================
// Estimator 1: regressing output on {K, L} omitting {N1, N2}
// Bias = gamma1*(gn1 - b_N1K*gk - b_N1L*gl) + gamma2*(gn2 - b_N2K*gk - b_N2L*gl)
// where kappas = Var([gk,gl])^{-1} Cov([gk,gl], gN)
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
      gamma_1 * ( `gn1' - bKL_N1[1,1]*`gk' - bKL_N1[2,1]*`gl' ) ///
    + gamma_2 * ( `gn2' - bKL_N2[1,1]*`gk' - bKL_N2[2,1]*`gl' )

scalar g_hat = `ga' + tfp_bias_NK

//====================================================
// Estimator 2: regressing output on {K, L, N1} omitting {N2}
// Bias = gamma2*(gn2 - [lambdaK*gk + lambdaN1*gn1 + lambdaL*gl])
// where lambda = Var([gk gn1 gl])^{-1} Cov([gk gn1 gl], gn2) w
//====================================================

// Build Var([K N1 L]) and its inverse
matrix VKN1L = ( var_K    , cov_N1_K , cov_L_K  \ ///
                 cov_N1_K , var_N1   , cov_L_N1 \ ///
                 cov_L_K  , cov_L_N1 , var_L    )

matrix iVKN1L = invsym(VKN1L)

// Build Cov([K N1 L], N2)
matrix cKN1L_N2 = ( cov_K_N2 \ cov_N1_N2 \ cov_L_N2 )

// Projection coefficients (lambdas)
matrix lambda = iVKN1L * cKN1L_N2   // [lambdaK, lambdaN1, lambdaL]'


// Bias term for estimator 2
scalar tfp_bias_1K = gamma_2 * ( `gn2' - lambda[1,1]*`gk' - lambda[2,1]*`gn1' -  lambda[3,1]*`gl' )
scalar g_tilde = `ga' + tfp_bias_1K


//create outputs
scalar TFP_square_bias_1K = sqrt(tfp_bias_1K^2) 
scalar TFP_square_bias_NK = sqrt(tfp_bias_NK^2)
scalar abs_difference_TFP = TFP_square_bias_NK-TFP_square_bias_1K


// Conditional error variances: residualize omitted inputs on INCLUDED inputs.
// Model 0: X={K,L}, omitted inputs={N1,N2}.
matrix V_N = ( var_N1, cov_N1_N2 \ ///
               cov_N1_N2, var_N2 )
matrix C_KL_N = ( cov_N1_K, cov_K_N2 \ ///
                  cov_L_N1, cov_L_N2 )
matrix gamma_N = ( gamma_1 \ gamma_2 )
matrix V_N_resid = V_N - C_KL_N' * iVKL * C_KL_N
matrix omitted_var0 = gamma_N' * V_N_resid * gamma_N
scalar rmse_tau0 = `sda'^2 + omitted_var0[1,1]

// Model 1: X={K,N1,L}, omitted input=N2 (not N1).
matrix projected_var_N2 = cKN1L_N2' * iVKN1L * cKN1L_N2
scalar residual_var_N2 = var_N2 - projected_var_N2[1,1]
scalar rmse_tau1 = `sda'^2 + gamma_2^2 * residual_var_N2

// Intercept factors [(Z'Z)^(-1)]_11 = 1/n + mu'V^(-1)mu/(n-ddof).
// Keep the means in exactly the same order as the corresponding covariance.
matrix rmse_mu0 = ( `gk' \ `gl' )
matrix rmse_mu1 = ( `gk' \ `gn1' \ `gl' )
matrix rmse_D0 = rmse_mu0' * iVKL * rmse_mu0
matrix rmse_D1 = rmse_mu1' * iVKN1L * rmse_mu1
scalar rmse_factor0 = 1/`number_periods' + rmse_D0[1,1]/rmse_cov_divisor
scalar rmse_factor1 = 1/`number_periods' + rmse_D1[1,1]/rmse_cov_divisor

// Reject material negative/nonfinite variances; truncate only roundoff noise.
scalar rmse_var_scale = `sda'^2 + gamma_1^2*var_N1 + gamma_2^2*var_N2
if missing(rmse_tau0, rmse_tau1, rmse_factor0, rmse_factor1) | ///
    rmse_tau0 < -1e-10*rmse_var_scale | rmse_tau1 < -1e-10*rmse_var_scale | ///
    rmse_factor0 <= 0 | rmse_factor1 <= 0 {
    display as error "Invalid conditional error variance or intercept factor"
    exit 498
}
scalar rmse_tau0 = max(0, rmse_tau0)
scalar rmse_tau1 = max(0, rmse_tau1)
scalar var_no_NK = rmse_tau0 * rmse_factor0
scalar var_1_NK = rmse_tau1 * rmse_factor1

// Historical MSE_* names are retained for compatibility; these are ROOT MSEs.
scalar MSE_NK = sqrt(var_no_NK + tfp_bias_NK^2)
scalar MSE_1K = sqrt(var_1_NK + tfp_bias_1K^2)
scalar MSE_difference = MSE_NK - MSE_1K


//kick last things out out
return scalar abs_difference_TFP_out = abs_difference_TFP
return scalar MSE_difference_out = scalar(MSE_difference)
return scalar MSE_NK_out = scalar(MSE_NK)
return scalar MSE_1K_out = scalar(MSE_1K)
return scalar reduction_share = (scalar(MSE_NK)-scalar(MSE_1K))/scalar(MSE_NK)
return scalar g_hat_out   = scalar(g_hat)
return scalar g_tilde_out = scalar(g_tilde)

// Conditional RMSE diagnostics; existing return names remain unchanged.
return scalar tau0_out = scalar(rmse_tau0)
return scalar tau1_out = scalar(rmse_tau1)
return scalar intercept_factor0_out = scalar(rmse_factor0)
return scalar intercept_factor1_out = scalar(rmse_factor1)

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
							

							
gen int rmse_rc = .
gen double tau0 = .
gen double tau1 = .
gen double intercept_factor0 = .
gen double intercept_factor1 = .
gen double bias_reduction = .
gen double RMSE_reduction = .
gen double RMSE_baseline = .
gen double RMSE_baseline_NK = .
gen double RMSE_reduction_share = .
gen double g_A_bar = .
gen double g_hat_A = .
gen double g_tilde_A = .
gen double bias0 = .
gen double bias1 = .
gen double var0 = .
gen double var1 = .

* Conditional design settings: use ddof=0 only for 1/n-normalized covariances.
local rmse_periods = 25
local rmse_ddof = 1

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
		capture noisily solve_bias_variance, number_periods(`rmse_periods') covariance_ddof(`rmse_ddof') corr_n1_k(`corr_N1_K_in') corr_n1_n2(`corr_N1_N2_in') corr_n2_k(`corr_N2_K_in')  gn1(`g1_in')  gn2(`g2_in')  gk(`gk_in') sdk(`sdK_in') sda(`sdA_in') sdn1(`sd1_in') sdn2(`sd2_in') ga(`ga_in')  gl(`gl_in') sdl(`sdL_in') corr_n1_l(`corr_L_N1_in')  corr_n2_l(`corr_L_N2_in')  corr_l_k(`corr_L_K_in') 
			


        local rmse_call_rc = _rc
        replace rmse_rc = `rmse_call_rc' in `i'
        if `rmse_call_rc' != 0 {
            noisily display as error "Skipping observation `i': invalid RMSE calibration (rc=`rmse_call_rc')"
            continue
        }
        replace tau0 = r(tau0_out) in `i'
        replace tau1 = r(tau1_out) in `i'
        replace intercept_factor0 = r(intercept_factor0_out) in `i'
        replace intercept_factor1 = r(intercept_factor1_out) in `i'

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
tabulate rmse_rc, missing
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
  xtitle("Average Growth in Non-Renewable Resource Use (g{sub:N{sub:1}}), `sample_period' calibration", size(small))  ///
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
  xtitle("Average Growth in Renewable Resource Use (g{sub:N{sub:2}}), `sample_period' calibration", size(small))  ///
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
    ytitle("Estimated γ̂{sub:A} from Model 1", size(small)) ///
    legend(off) ///
    title("{bf:c}", pos(11) ring(0) just(left) size(medsmall) color(black)) ///
 saving("$figs/overlay_alt3.gph", replace) 

  //Figure d
twoway (lfit g_A_bar g_A_bar , color(grey%20)   lpattern(dash)) ///
(scatter g_tilde_A g_A_bar,   mcolor(red%100) msy(circle) msize(small)     ///
xlabel(, nogrid  labsize(small)) ///
ylabel(, nogrid  labsize(small)) ), ///
  xtitle("Average g{sub:A} from the PWT", size(small))  ///
    ytitle("Estimated γ̃{sub:A} from Model 2", size(small)) ///
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
