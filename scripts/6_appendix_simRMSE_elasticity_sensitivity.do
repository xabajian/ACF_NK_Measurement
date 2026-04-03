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


use "$processed/CWON_data.dta", clear

keep if sdA!=.
sort country_byte
gen seed_in = _n
scalar seed_mc_trial = ceil(100*runiform())
display seed_mc_trial


program define solve_bias_variance, rclass 


version 12.1
syntax [,  number_periods(integer 25) corr_N1_K(real 0.01) corr_N1_N2(real 0.01) corr_N2_K(real 0.01) gn1(real 0.01)  gn2(real 0.01)   gK(real 0.01) sdK(real 0.01) sdA(real 0.01) sdn1(real 0.01) sdn2(real 0.01) gA(real 0.01)  gL(real 0.01) sdL(real 0.01) corr_N1_L(real 0.01) corr_N2_L(real 0.01)   corr_L_K(real 0.01)  ] 

		
//Stochastic part
scalar seed_mc_trial = ceil(100*runiform())
* country-specific values
local corr_N1_K = corr_N1_K_out[seed_mc_trial] 
local corr_N1_N2 = corr_N1_N2_out[seed_mc_trial]
local corr_N2_K = corr_N2_K_out[seed_mc_trial]
local corr_L_K =   corr_L_K[seed_mc_trial] 
local corr_L_N1 = corr_N1_L[seed_mc_trial]
local corr_L_N2 = corr_N2_L[seed_mc_trial]
local g1 = g_n1[seed_mc_trial]
local g2 = g_n2[seed_mc_trial]
local gK = g_k[seed_mc_trial]
local gA = g_A[seed_mc_trial]
local gL = g_L[seed_mc_trial]
local sdn1 = sdn1[seed_mc_trial]
local sdn2 = sdn2[seed_mc_trial]
local sdK = sdK[seed_mc_trial]
local sdA = sdA[seed_mc_trial]
local sdL = sdL[seed_mc_trial]
local number_periods = 25
		display `corr_N1_K'
		

scalar gamma_1 = 0.1*runiform()
scalar gamma_2 = 0.1*runiform()

//make covariances

//------------------------------
// 1) Covariances
//------------------------------
scalar cov_N1_K = `corr_N1_K' * `sdK' * `sdn1'
scalar cov_N1_N2 = `corr_N1_N2'  * `sdn1' * `sdn2'
scalar cov_K_N2 = `corr_N2_K'  * `sdK' * `sdn2'
scalar cov_L_K    = `corr_L_K'   * `sdL'  * `sdK'
scalar cov_L_N1   = `corr_L_N1'  * `sdL'  * `sdn1'
scalar cov_L_N2   = `corr_L_N2'  * `sdL'  * `sdn2'



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
return scalar MSE_difference = scalar(MSE_difference)
end
 
 
parallel initialize 16, f
parallel sim , expr(RMSE_reduction = MSE_difference seed_out  = seed_mc_trial gamma_1_out = gamma_1 gamma_2_out =gamma_2 ) reps(10000000): solve_bias_variance, number_periods(25) 




//summary stats
sum RMSE_reduction, d
count if RMSE_reduction<0
scalar count_negative = r(N)
count
scalar count_full = r(N)
display count_negative/count_full





