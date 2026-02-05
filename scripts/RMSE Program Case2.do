clear all
set maxvar 32000
set seed 1234
// set scheme plotplain
set scheme stcolor
global sim_dir "$root/simulations"

		

program define simulate_MC_draw, rclass 


version 12.1
syntax [, obs(integer 1) mu(real 0.01) sigma(real 0.01)  gK(real 0.01) gL(real 0.01) gA(real 0.01) sdK(real 0.01) sdL(real 0.01) sdA(real 0.01)] 

drop _all

//correlation matrices
scalar corr_N1_N2 =  sign(runiform()-0.5)  * floor(91*runiform())/100
scalar corr_N1_K =   sign(runiform()-0.5) * floor(91*runiform())/100

//generate correlations
//g_N1 g_N2 g_K g_L g_TFP
matrix corrmat = (1,	corr_N1_N2 , corr_N1_K, 0 , 0 \ ///
///
corr_N1_N2	,     1, 0 ,0 , 0   \ /// 
///
corr_N1_K, 0,     1,0 , 0 \ /// 
///
0, 0 , 0,    1,0 \ ///
///
0, 0, 0, 0,    1) 


//means
scalar growth_exog = `mu'
scalar sd_exog = `sigma'


//means
matrix M = (-growth_exog,growth_exog,`gK',`gL',`gA')


//sds
matrix S = (sd_exog,sd_exog,`sdK',`sdL',`sdA')

//simulate historical data for OLS estimates of share parameters
drawnorm g_N1 g_N2 g_K g_L g_TFP, forcepsd n(`obs') corr(corrmat) means(M) sds(S) 

							
//set scalars governing factor shares
scalar alpha = 0.3
scalar gamma_1 = 0.05
//scalar gamma_1 = 0.1*runiform()
scalar gamma_2 = 0.1-gamma_1
scalar beta = 1 - alpha - gamma_1 -gamma_2



//solve for simulated past output
gen g_Y = g_TFP  + g_N1 *gamma_1 + g_N2 * gamma_2 + g_K * alpha  + g_L * (beta)

/* 
step 1 for recovering TFP -- estimate factor shares
*/


/*
1.1 -- no NK terms
*/


reg g_Y g_K g_L


scalar alpha_noNK = e(b)[1,1]
scalar ga_noNK =  e(b)[1,3]


/*
1.1 -- include N1  term
*/


reg g_Y g_K g_L g_N1

scalar alpha_1NK = e(b)[1,1]
scalar ga_1NK = e(b)[1,4]


 
/* 
step 2: intercept terms are estimate of average TFP growth
*/



sum g_TFP
scalar ga_unbiased = r(mean)

//kick out things i need
return scalar alpha_1NK_out = alpha_1NK
return  scalar alpha_noNK_out  = alpha_noNK 
scalar no_N1_bias_scalar =ga_1NK - ga_unbiased 
scalar no_NK_bias_scalar =ga_noNK - ga_unbiased  
return scalar TFP_bias_n1 = no_N1_bias_scalar
return scalar TFP_bias_nK = no_NK_bias_scalar

//kick correlations out
return scalar corr_N1_N2_out = corr_N1_N2
return scalar corr_N1_K_out = corr_N1_K



 
 end
 


use  "$processed/usa_growth_accounting.dta", clear

local T_periods = N[1]
local bar_A = g_A[1]
local bar_K = g_K[1]
local bar_L = g_L[1]
local sigma_A = sd_A[1]
local sigma_K = sd_K[1]
local sigma_L = sd_L[1]

parallel initialize 16, f
parallel sim , expr(alpha_1NK_out = alpha_1NK alpha_noNK_out  = alpha_noNK TFP_bias_n1 = no_N1_bias_scalar TFP_bias_nK = no_NK_bias_scalar   corr_N1_N2_out = corr_N1_N2   corr_N1_K_out = corr_N1_K ) reps(1000000): simulate_MC_draw, obs(`T_periods') mu(0.01) sigma(0.01) gK(0.01) gL(0.01) gA(0.01) sdK(`sigma_K') sdL(`sigma_L') sdA(`sigma_A') 



scalar alpha = 0.3
gen bias_1NK = alpha_1NK_out - alpha
gen bias_noNK = alpha_noNK_out - alpha

gen square_bias_1NK =  bias_1NK^2
gen square_bias_noNK =  bias_noNK^2

gen TFP_square_bias_1K = TFP_bias_n1^2
gen TFP_square_bias_NK = TFP_bias_nK^2



collapse (mean) bias_1NK bias_noNK  square_bias_1NK  square_bias_noNK TFP_square_bias_1K TFP_square_bias_NK, by(corr_N1_N2_out  corr_N1_K_out)



replace square_bias_1NK = sqrt(square_bias_1NK)
replace square_bias_noNK = sqrt(square_bias_noNK)
replace  TFP_square_bias_1K = sqrt(TFP_square_bias_1K) 
replace TFP_square_bias_NK = sqrt(TFP_square_bias_NK)

gen MSE_difference_alphas = square_bias_noNK-square_bias_1NK
gen MSE_difference_TFP = TFP_square_bias_NK-TFP_square_bias_1K



//save out
save "$sim_dir/RMSE_N1_N2_case2.dta", replace 
