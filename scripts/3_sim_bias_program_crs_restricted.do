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
    syntax [, number_periods(integer 25)                         ///
        corr_N1_K(real 0.01) corr_N1_N2(real 0.01)              ///
        corr_N2_K(real 0.01) corr_N1_L(real 0.01)               ///
        corr_N2_L(real 0.01) corr_L_K(real 0.01)                ///
        gn1(real 0.01) gn2(real 0.01) gK(real 0.01)             ///
        gL(real 0.01) gA(real 0.01)                             ///
        sdn1(real 0.01) sdn2(real 0.01) sdK(real 0.01)          ///
        sdL(real 0.01) sdA(real 0.01)                           ///
        betaK(real 0.30) betaL(real 0.60)                       ///
        gamma1(real 0.05) gamma2(real 0.05) ]

    if `number_periods' <= 0 {
        display as error "number_periods() must be positive"
        exit 198
    }

    *--------------------------------------------------------------------------
    * Country-level second moments
    *--------------------------------------------------------------------------
    scalar cov_N1_K  = `corr_N1_K'  * `sdK'  * `sdn1'
    scalar cov_N1_N2 = `corr_N1_N2' * `sdn1' * `sdn2'
    scalar cov_K_N2  = `corr_N2_K'  * `sdK'  * `sdn2'
    scalar cov_L_K   = `corr_L_K'   * `sdL'  * `sdK'
    scalar cov_L_N1  = `corr_N1_L'  * `sdL'  * `sdn1'
    scalar cov_L_N2  = `corr_N2_L'  * `sdL'  * `sdn2'

    scalar var_K  = (`sdK')^2
    scalar var_L  = (`sdL')^2
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

    matrix beta0  = ( `betaK' \ `betaL' )
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
    scalar s_bias0_crs = d0[1,1]*`gK' + d0[2,1]*`gL' + ///
                         `gamma1'*`gn1' + `gamma2'*`gn2'

    * Residual variance: Var(A + d0'X0 + gamma'Z0).
    matrix quad0  = d0'*V0*d0
    matrix cross0 = d0'*C0*gammaN
    matrix omit0  = gammaN'*VN*gammaN
    scalar residual_var0 = (`sdA')^2 + quad0[1,1] + ///
                           2*cross0[1,1] + omit0[1,1]
    scalar s_mean_var0_crs = max(0, residual_var0)/`number_periods'
    scalar s_RMSE_model0_crs = ///
        sqrt(s_mean_var0_crs + s_bias0_crs^2)

    *=========================================================================
    * Model 1: included inputs X1={K,N1,L}; omitted input Z1={N2}
    * Restriction: b_K + b_N1 + b_L = 1
    *=========================================================================
    matrix V1 = ( var_K, cov_N1_K, cov_L_K \ ///
                  cov_N1_K, var_N1, cov_L_N1 \ ///
                  cov_L_K, cov_L_N1, var_L )
    matrix iV1 = invsym(V1)

    matrix C1 = ( cov_K_N2 \ cov_N1_N2 \ cov_L_N2 )
    matrix beta1 = ( `betaK' \ `gamma1' \ `betaL' )
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

    scalar s_bias1_crs = d1[1,1]*`gK' + d1[2,1]*`gn1' + ///
                         d1[3,1]*`gL' + `gamma2'*`gn2'

    * Residual variance: Var(A + d1'X1 + gamma_2*N2).
    matrix quad1  = d1'*V1*d1
    matrix cross1 = d1'*C1
    scalar residual_var1 = (`sdA')^2 + quad1[1,1] + ///
                           2*`gamma2'*cross1[1,1] + ///
                           (`gamma2')^2*var_N2
    scalar s_mean_var1_crs = max(0, residual_var1)/`number_periods'
    scalar s_RMSE_model1_crs = ///
        sqrt(s_mean_var1_crs + s_bias1_crs^2)

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

    * Return model-level bias, variance of the mean, and RMSE.
    return scalar bias0_crs = scalar(s_bias0_crs)
    return scalar bias1_crs = scalar(s_bias1_crs)
    return scalar var0_crs = scalar(s_mean_var0_crs)
    return scalar var1_crs = scalar(s_mean_var1_crs)
    return scalar RMSE_model0_crs = scalar(s_RMSE_model0_crs)
    return scalar RMSE_model1_crs = scalar(s_RMSE_model1_crs)
    return scalar RMSE_reduction_crs = scalar(s_RMSE_reduction_crs)
    return scalar RMSE_reduction_share_crs = ///
        scalar(s_RMSE_reduction_share_crs)
    return scalar g_hat_A_crs = `gA' + scalar(s_bias0_crs)
    return scalar g_tilde_A_crs = `gA' + scalar(s_bias1_crs)
end


*-------------------------------------------------------------------------------
* Create country-level output variables
*-------------------------------------------------------------------------------
gen double coef_K_model0_crs  = .
gen double coef_L_model0_crs  = .
gen double coef_K_model1_crs  = .
gen double coef_N1_model1_crs = .
gen double coef_L_model1_crs  = .

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

        solve_bias_variance_crs, number_periods(25)             ///
            corr_N1_K(`corr_N1_K_in')                           ///
            corr_N1_N2(`corr_N1_N2_in')                         ///
            corr_N2_K(`corr_N2_K_in')                           ///
            corr_N1_L(`corr_L_N1_in')                           ///
            corr_N2_L(`corr_L_N2_in')                           ///
            corr_L_K(`corr_L_K_in')                             ///
            gn1(`g1_in') gn2(`g2_in')                           ///
            gK(`gk_in') gL(`gl_in') gA(`ga_in')                 ///
            sdn1(`sd1_in') sdn2(`sd2_in')                       ///
            sdK(`sdK_in') sdL(`sdL_in') sdA(`sdA_in')           ///
            betaK(0.30) betaL(0.60) gamma1(0.05) gamma2(0.05)

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


