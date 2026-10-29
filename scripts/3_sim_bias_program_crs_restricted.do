
*
*===============================================================================
* Country-level bias and RMSE under restricted OLS (constant returns to scale)
*
* Model 0: regress output on {K,L}, imposing b_K + b_L = 1.
* Model 1: regress output on {K,N1,L}, imposing b_K + b_N1 + b_L = 1.
*
* The data-generating process is
*   y = A + beta_K*K + beta_L*L + gamma_1*N1 + gamma_2*N2.
*
* Defaults beta_K=.30, beta_L=.60, gamma_1=.05, and gamma_2=.05 make the
* full technology constant returns to scale. All coefficients can be changed
* in the call to solve_bias_variance_crs below.
*
* For an unrestricted population OLS estimand b_U, the equality-restricted
* estimand is
*   b_R = b_U - V^(-1)q[q'V^(-1)q]^(-1)(q'b_U - 1),
* where q is a vector of ones. Thus no Monte Carlo approximation is required.
*===============================================================================

clear all
set more off

cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts"

global root      "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
global processed "$root/processed"
global sim_dir   "$root/simulations"

use "$processed/CWON_data.dta", clear


capture program drop solve_bias_variance_crs
program define solve_bias_variance_crs, rclass
    version 12.1
    syntax [, number_periods(integer 25) covariance_ddof(integer 1)                         ///
        corr_n1_k(real 0.01) corr_n1_n2(real 0.01)              ///
        corr_n2_k(real 0.01) corr_n1_l(real 0.01)               ///
        corr_n2_l(real 0.01) corr_l_k(real 0.01)                ///
        gn1(real 0.01) gn2(real 0.01) gk(real 0.01)             ///
        gl(real 0.01) ga(real 0.01)                             ///
        sdn1(real 0.01) sdn2(real 0.01) sdk(real 0.01)          ///
        sdl(real 0.01) sda(real 0.01)                           ///
        betak(real 0.30) betal(real 0.60)                       ///
        gamma1(real 0.05) gamma2(real 0.05) ]


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
        corr_n2_l corr_l_k gn1 gn2 gk gl sdn1 sdn2 sdk sdl sda {
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

    if missing(`betak', `betal', `gamma1', `gamma2') {
        display as error "Structural coefficients must be finite"
        exit 198
    }

    *--------------------------------------------------------------------------
    * Country-level second moments
    *--------------------------------------------------------------------------
    scalar cov_N1_K  = `corr_n1_k'  * `sdk'  * `sdn1'
    scalar cov_N1_N2 = `corr_n1_n2' * `sdn1' * `sdn2'
    scalar cov_K_N2  = `corr_n2_k'  * `sdk'  * `sdn2'
    scalar cov_L_K   = `corr_l_k'   * `sdl'  * `sdk'
    scalar cov_L_N1  = `corr_n1_l'  * `sdl'  * `sdn1'
    scalar cov_L_N2  = `corr_n2_l'  * `sdl'  * `sdn2'

    scalar var_K  = (`sdk')^2
    scalar var_L  = (`sdl')^2
    scalar var_N1 = (`sdn1')^2
    scalar var_N2 = (`sdn2')^2

    * Covariance matrix of the omitted natural inputs in model 0.
    matrix VN = ( var_N1, cov_N1_N2 \ ///
                  cov_N1_N2, var_N2 )

    *=========================================================================
    * Model 0: included inputs X0={K,L}; omitted inputs Z0={N1,N2}
    * Restriction: b_K + b_L = 1
    *=========================================================================
    matrix V0 = ( var_K, cov_L_K \ ///
                  cov_L_K, var_L )
    matrix iV0 = invsym(V0)

    matrix C0 = ( cov_N1_K, cov_K_N2 \ ///
                  cov_L_N1, cov_L_N2 )

    matrix beta0  = ( `betak' \ `betal' )
    matrix gammaN = ( `gamma1' \ `gamma2' )
    matrix one0   = ( 1 \ 1 )

    * Unrestricted and restricted population OLS coefficient estimands.
    matrix b0_u = beta0 + iV0*C0*gammaN
    matrix temp0 = one0'*iV0*one0
    matrix sum0  = one0'*b0_u
    scalar denom0 = temp0[1,1]
    scalar gap0   = sum0[1,1] - 1
    matrix b0_r = b0_u - (gap0/denom0)*iV0*one0

    * d0 is the included-input coefficient error relative to the DGP.
    matrix d0 = beta0 - b0_r

    * Bias of average measured productivity relative to average true A.
    scalar s_bias0_crs = d0[1,1]*`gk' + d0[2,1]*`gl' + ///
                         `gamma1'*`gn1' + `gamma2'*`gn2'

    * Conditional stochastic variance uses the unrestricted projection error.
    * A false CRS restriction adds deterministic fit error at fixed X; it enters
    * the bias above, not the stochastic error variance below.
    matrix rmse_Omega0 = VN - C0'*iV0*C0
    matrix rmse_omit0 = gammaN'*rmse_Omega0*gammaN
    scalar rmse_tau0 = `sda'^2 + rmse_omit0[1,1]

    * Covariance kernel for restricted slopes, q'b=1:
    * H = V^(-1) - V^(-1)q(q'V^(-1)q)^(-1)q'V^(-1).
    matrix rmse_H0 = iV0 - (1/denom0)*iV0*one0*one0'*iV0
    matrix rmse_mu0 = ( `gk' \ `gl' )
    matrix rmse_D0 = rmse_mu0'*rmse_H0*rmse_mu0
    scalar rmse_factor0 = 1/`number_periods' + rmse_D0[1,1]/rmse_cov_divisor

    *=========================================================================
    * Model 1: included inputs X1={K,N1,L}; omitted input Z1={N2}
    * Restriction: b_K + b_N1 + b_L = 1
    *=========================================================================
    matrix V1 = ( var_K, cov_N1_K, cov_L_K \ ///
                  cov_N1_K, var_N1, cov_L_N1 \ ///
                  cov_L_K, cov_L_N1, var_L )
    matrix iV1 = invsym(V1)

    matrix C1 = ( cov_K_N2 \ cov_N1_N2 \ cov_L_N2 )
    matrix beta1 = ( `betak' \ `gamma1' \ `betal' )
    matrix one1  = ( 1 \ 1 \ 1 )

    * Unrestricted and restricted population OLS coefficient estimands.
    matrix b1_u = beta1 + iV1*C1*`gamma2'
    matrix temp1 = one1'*iV1*one1
    matrix sum1  = one1'*b1_u
    scalar denom1 = temp1[1,1]
    scalar gap1   = sum1[1,1] - 1
    matrix b1_r = b1_u - (gap1/denom1)*iV1*one1

    * d1 is the included-input coefficient error relative to the DGP.
    matrix d1 = beta1 - b1_r

    scalar s_bias1_crs = d1[1,1]*`gk' + d1[2,1]*`gn1' + ///
                         d1[3,1]*`gl' + `gamma2'*`gn2'

    * Conditional error variance: only unexplained N2 growth and TFP are random.
    matrix rmse_projected1 = C1'*iV1*C1
    scalar rmse_tau1 = `sda'^2 + (`gamma2')^2*(var_N2-rmse_projected1[1,1])

    * Account for the CRS constraint when propagating slope uncertainty.
    matrix rmse_H1 = iV1 - (1/denom1)*iV1*one1*one1'*iV1
    matrix rmse_mu1 = ( `gk' \ `gn1' \ `gl' )
    matrix rmse_D1 = rmse_mu1'*rmse_H1*rmse_mu1
    scalar rmse_factor1 = 1/`number_periods' + rmse_D1[1,1]/rmse_cov_divisor

    scalar rmse_var_scale = `sda'^2 + (`gamma1')^2*var_N1 + (`gamma2')^2*var_N2
    if missing(rmse_tau0, rmse_tau1, rmse_factor0, rmse_factor1) | ///
        rmse_tau0 < -1e-10*rmse_var_scale | rmse_tau1 < -1e-10*rmse_var_scale | ///
        rmse_factor0 <= 0 | rmse_factor1 <= 0 {
        display as error "Invalid conditional error variance or intercept factor"
        exit 498
    }
    scalar rmse_tau0 = max(0, rmse_tau0)
    scalar rmse_tau1 = max(0, rmse_tau1)
    scalar s_mean_var0_crs = rmse_tau0 * rmse_factor0
    scalar s_mean_var1_crs = rmse_tau1 * rmse_factor1
    scalar s_RMSE_model0_crs = sqrt(s_mean_var0_crs + s_bias0_crs^2)
    scalar s_RMSE_model1_crs = sqrt(s_mean_var1_crs + s_bias1_crs^2)

    scalar s_RMSE_reduction_crs = ///
        s_RMSE_model0_crs - s_RMSE_model1_crs
    scalar s_RMSE_reduction_share_crs = ///
        (s_RMSE_model0_crs - s_RMSE_model1_crs)/s_RMSE_model0_crs

    * Return restricted coefficient estimands.
    return scalar coef_K_model0_crs  = b0_r[1,1]
    return scalar coef_L_model0_crs  = b0_r[2,1]
    return scalar coef_K_model1_crs  = b1_r[1,1]
    return scalar coef_N1_model1_crs = b1_r[2,1]
    return scalar coef_L_model1_crs  = b1_r[3,1]

    * Return conditional intercept bias, variance, and RMSE.
    return scalar bias0_crs = scalar(s_bias0_crs)
    return scalar bias1_crs = scalar(s_bias1_crs)
    return scalar var0_crs = scalar(s_mean_var0_crs)
    return scalar var1_crs = scalar(s_mean_var1_crs)
    return scalar RMSE_model0_crs = scalar(s_RMSE_model0_crs)
    return scalar RMSE_model1_crs = scalar(s_RMSE_model1_crs)
    return scalar RMSE_reduction_crs = scalar(s_RMSE_reduction_crs)
    return scalar RMSE_reduction_share_crs = ///
        scalar(s_RMSE_reduction_share_crs)
    * Diagnostics: tau is the error variance; factor is the intercept multiplier.
    return scalar tau0_crs = scalar(rmse_tau0)
    return scalar tau1_crs = scalar(rmse_tau1)
    return scalar intercept_factor0_crs = scalar(rmse_factor0)
    return scalar intercept_factor1_crs = scalar(rmse_factor1)
    return scalar g_hat_A_crs = `ga' + scalar(s_bias0_crs)
    return scalar g_tilde_A_crs = `ga' + scalar(s_bias1_crs)
end


*-------------------------------------------------------------------------------
* Create country-level output variables
*-------------------------------------------------------------------------------
gen double coef_K_model0_crs  = .
gen double coef_L_model0_crs  = .
gen double coef_K_model1_crs  = .
gen double coef_N1_model1_crs = .
gen double coef_L_model1_crs  = .

gen int rmse_rc = .
gen double tau0_crs = .
gen double tau1_crs = .
gen double intercept_factor0_crs = .
gen double intercept_factor1_crs = .
gen double bias0_crs = .
gen double bias1_crs = .
gen double var0_crs = .
gen double var1_crs = .
gen double RMSE_model0_crs = .
gen double RMSE_model1_crs = .
gen double RMSE_reduction_crs = .
gen double RMSE_reduction_share_crs = .
gen double g_hat_A_crs = .
gen double g_tilde_A_crs = .

label variable coef_K_model0_crs  "Restricted coefficient on K: model 0"
label variable coef_L_model0_crs  "Restricted coefficient on L: model 0"
label variable coef_K_model1_crs  "Restricted coefficient on K: model 1"
label variable coef_N1_model1_crs "Restricted coefficient on N1: model 1"
label variable coef_L_model1_crs  "Restricted coefficient on L: model 1"
label variable RMSE_model0_crs    "RMSE: restricted model 0"
label variable RMSE_model1_crs    "RMSE: restricted model 1"
label variable RMSE_reduction_crs "RMSE model 0 minus RMSE model 1"


* Conditional design settings: use ddof=0 only for 1/n-normalized covariances.
local rmse_periods = 25
local rmse_ddof = 1

count
local N = r(N)

quietly {
    forvalues i = 1/`N' {
        local corr_N1_K_in  = corr_N1_K_out[`i']
        local corr_N1_N2_in = corr_N1_N2_out[`i']
        local corr_N2_K_in  = corr_N2_K_out[`i']
        local corr_L_K_in   = corr_L_K[`i']
        local corr_L_N1_in  = corr_N1_L[`i']
        local corr_L_N2_in  = corr_N2_L[`i']
        local g1_in  = g_n1[`i']
        local g2_in  = g_n2[`i']
        local gk_in  = g_k[`i']
        local gl_in  = g_L[`i']
        local ga_in  = g_A[`i']
        local sd1_in = sdn1[`i']
        local sd2_in = sdn2[`i']
        local sdK_in = sdK[`i']
        local sdL_in = sdL[`i']
        local sdA_in = sdA[`i']

        capture noisily solve_bias_variance_crs, number_periods(`rmse_periods') covariance_ddof(`rmse_ddof')             ///
            corr_n1_k(`corr_N1_K_in')                           ///
            corr_n1_n2(`corr_N1_N2_in')                         ///
            corr_n2_k(`corr_N2_K_in')                           ///
            corr_n1_l(`corr_L_N1_in')                           ///
            corr_n2_l(`corr_L_N2_in')                           ///
            corr_l_k(`corr_L_K_in')                             ///
            gn1(`g1_in') gn2(`g2_in')                           ///
            gk(`gk_in') gl(`gl_in') ga(`ga_in')                 ///
            sdn1(`sd1_in') sdn2(`sd2_in')                       ///
            sdk(`sdK_in') sdl(`sdL_in') sda(`sdA_in')           ///
            betak(0.30) betal(0.60) gamma1(0.05) gamma2(0.05)

        local rmse_call_rc = _rc
        replace rmse_rc = `rmse_call_rc' in `i'
        if `rmse_call_rc' != 0 {
            noisily display as error "Skipping observation `i': invalid RMSE calibration (rc=`rmse_call_rc')"
            continue
        }
        replace tau0_crs = r(tau0_crs) in `i'
        replace tau1_crs = r(tau1_crs) in `i'
        replace intercept_factor0_crs = r(intercept_factor0_crs) in `i'
        replace intercept_factor1_crs = r(intercept_factor1_crs) in `i'

        replace coef_K_model0_crs  = r(coef_K_model0_crs) in `i'
        replace coef_L_model0_crs  = r(coef_L_model0_crs) in `i'
        replace coef_K_model1_crs  = r(coef_K_model1_crs) in `i'
        replace coef_N1_model1_crs = r(coef_N1_model1_crs) in `i'
        replace coef_L_model1_crs  = r(coef_L_model1_crs) in `i'

        replace bias0_crs = r(bias0_crs) in `i'
        replace bias1_crs = r(bias1_crs) in `i'
        replace var0_crs = r(var0_crs) in `i'
        replace var1_crs = r(var1_crs) in `i'
        replace RMSE_model0_crs = r(RMSE_model0_crs) in `i'
        replace RMSE_model1_crs = r(RMSE_model1_crs) in `i'
        replace RMSE_reduction_crs = r(RMSE_reduction_crs) in `i'
        replace RMSE_reduction_share_crs = ///
            r(RMSE_reduction_share_crs) in `i'
        replace g_hat_A_crs = r(g_hat_A_crs) in `i'
        replace g_tilde_A_crs = r(g_tilde_A_crs) in `i'
    }
}


tabulate rmse_rc, missing

* Verify the adding-up restrictions numerically.
assert abs(coef_K_model0_crs + coef_L_model0_crs - 1) < 1e-8 ///
    if !missing(coef_K_model0_crs, coef_L_model0_crs)

assert abs(coef_K_model1_crs + coef_N1_model1_crs + ///
    coef_L_model1_crs - 1) < 1e-8 ///
    if !missing(coef_K_model1_crs, coef_N1_model1_crs, coef_L_model1_crs)

capture drop country_string
decode country_byte, gen(country_string)

summarize RMSE_model0_crs RMSE_model1_crs RMSE_reduction_crs ///
    RMSE_reduction_share_crs, detail


summarize coef_K_model0_crs coef_L_model0_crs coef_K_model1_crs coef_N1_model1_crs coef_L_model1_crs , d
