clear all
set maxvar 32000
set seed 1234
// set scheme plotplain
set scheme stcolor
global sim_dir "$root/simulations"

			
							
set obs 181
gen index = _n
gen corr_N1_K = -0.9  +  0.01*(index-1)
gen corr_N1_N2 = -0.9  +  0.01*(index-1)
fillin corr_N1_K corr_N1_N2

							
//set scalars governing factor shares
scalar gamma_1 = 0.05
scalar gamma_2 = 0.05

append using  "$processed/usa_growth_accounting.dta"


//parameterize
scalar bar_K = 0.01
scalar sigma_K = sd_K[32762]


scalar gn1 = 0.01
scalar gn2 = -0.01
scalar sdn1 = 0.01
scalar sdn2 = 0.01
scalar sdA = 0.01 


//make covariances
gen cov_N1_K = corr_N1_K * sigma_K * sdn1
gen cov_N1_N2 = corr_N1_N2  * sdn1 * sdn2


//drop 
drop N g_A g_K g_L sd_A sd_K sd_L index _fillin country_byte

gen  tfp_bias_NK  = gamma_1 * gn1 ///
	- gamma_1 * bar_K * (cov_N1_K  / (sigma_K)^2) ///
	+ gamma_2 * gn2
	
	
//help with this one 	
gen lambdaN1 = (cov_N1_N2 *  sigma_K^2) / (sdn1^2 * sigma_K^2 - cov_N1_K^2 )
gen lambdaK = ( - cov_N1_N2  *  cov_N1_K) / (sdn1^2 * sigma_K^2 - cov_N1_K^2 )

gen  tfp_bias_1K = gamma_2 * gn2 ///
		- gamma_2 * bar_K * lambdaK ///
		- gamma_2 * gn1 * lambdaN1



gen TFP_square_bias_1K = sqrt(tfp_bias_1K^2) 
gen TFP_square_bias_NK = sqrt(tfp_bias_NK^2)

gen abs_difference_TFP = TFP_square_bias_NK-TFP_square_bias_1K

gen corr_N1_K_out = corr_N1_K

gen  corr_N1_N2_out = corr_N1_N2

drop if _n==32762


//save out
save "$sim_dir/bias_case1.dta", replace 

//repeate for expected squared error 

gen var_no_NK = (sdA^2 + gamma_1 ^2 * sdn1^2 + gamma_2 ^2 * sdn2^2 + 2*gamma_1*gamma_2*cov_N1_N2) /70
gen var_1_NK = (sdA^2 + gamma_2 ^2 ) /70

gen MSE_NK = sqrt(var_no_NK + tfp_bias_NK^2)
gen MSE_1K = sqrt(var_1_NK + tfp_bias_1K^2)

gen MSE_difference = MSE_NK - MSE_1K
//save out
save "$sim_dir/RMSE_case1.dta", replace 

