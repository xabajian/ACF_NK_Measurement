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
							

program define solve_bias_variance, rclass 


version 12.1
syntax [,  number_periods(integer 70) corr_N1_K(real 0.01) corr_N1_N2(real 0.01)  gn1(real 0.01)  gn2(real 0.01)   gK(real 0.01) sdK(real 0.01) sdA(real 0.01) sdn1(real 0.01) sdn2(real 0.01)  ] 

		
//gammas 
scalar gamma_1 = 0.05
scalar gamma_2 = 0.05

//make covariances
scalar cov_N1_K = `corr_N1_K' * `sdK' * `sdn1'
scalar cov_N1_N2 = `corr_N1_N2'  * `sdn1' * `sdn2'


//drop 
scalar  tfp_bias_NK  = gamma_1 * `gn1' ///
	- gamma_1 * `gK' * (cov_N1_K  / (`sdK')^2) ///
	+ gamma_2 * `gn2'
	
	
//help with this one 	
scalar lambdaN1 = (cov_N1_N2 *  `sdK'^2) / (`sdn1'^2 * `sdK'^2 - cov_N1_K^2 )
scalar lambdaK = ( - cov_N1_N2  *  cov_N1_K) / (`sdn1'^2 * `sdK'^2 - cov_N1_K^2 )

scalar  tfp_bias_1K = gamma_2 * `gn2' ///
		- gamma_2 * `gK' * lambdaK ///
		- gamma_2 * `gn1' * lambdaN1



scalar TFP_square_bias_1K = sqrt(tfp_bias_1K^2) 
scalar TFP_square_bias_NK = sqrt(tfp_bias_NK^2)
scalar abs_difference_TFP = TFP_square_bias_NK-TFP_square_bias_1K



//repeate for expected squared error 
scalar var_no_NK = (`sdA'^2 + gamma_1 ^2 * `sdn1'^2 + gamma_2 ^2 * `sdn2'^2 + 2*gamma_1*gamma_2*cov_N1_N2) / 70
scalar var_1_NK = (`sdA'^2 + gamma_2 ^2 * `sdn1'^2  ) /70
scalar MSE_NK = sqrt(var_no_NK + tfp_bias_NK^2)
scalar MSE_1K = sqrt(var_1_NK + tfp_bias_1K^2)
scalar MSE_difference = MSE_NK - MSE_1K

//kick last things out out
return scalar abs_difference_TFP_out = abs_difference_TFP
return scalar MSE_difference_out = MSE_difference
return scalar MSE_1K_out = MSE_1K

 
 end
 
 
gen bias_reduction = .
gen RMSE_reduction = .
gen RMSE_baseline = .

count
quietly {
    forvalues i = 1/`r(N)' {
        
        * Pull row-specific values
        local corr_N1_K_in = corr_N1_K_out[`i'] 
        local corr_N1_N2_in = corr_N1_N2_out[`i']
        local g1_in = g_n1[`i']
        local g2_in = g_n2[`i']
		local gk_in = g_k[`i']
		local sd1_in = sdn1[`i']
        local sd2_in = sdn2[`i']
		local sdK_in = sdK[`i']
		local sdA_in = sdA[`i']
		display `gk_in'
        * Run your program (example)
		solve_bias_variance, number_periods(70) corr_N1_K(`corr_N1_K_in') corr_N1_N2(`corr_N1_N2_in')  gn1(`g1_in')  gn2(`g2_in')  gK(`gk_in') sdK(`sdK_in') sdA(`sdA_in') sdn1(`sd1_in') sdn2(`sd2_in') 

        * Store returned results
        replace bias_reduction = r(abs_difference_TFP_out) in `i'
        replace RMSE_reduction = r(MSE_difference_out) in `i'
        replace RMSE_baseline = r(MSE_1K_out) in `i'
    }
}

 
save "$sim_dir/bias_rmse.dta", replace
