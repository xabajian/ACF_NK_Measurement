
program def simulate_MC_draw, rclass

 version 12.1
 syntax [, obs(integer 1) mu(real 0.01) sigma(real 0.01) gK(real 0.01) gL(real 0.01) gA(real 0.01) sdK(real 0.01) sdL(real 0.01) sdA(real 0.01)]
 drop _all
 scalar corr_N1_N2 = sign(runiform()-0.5) * floor(91*runiform())/100
 scalar corr_N1_K = sign(runiform()-0.5) * floor(91*runiform())/100
 matrix corrmat = (1, corr_N1_N2 , corr_N1_K, 0 , 0 \ corr_N1_N2 , 1, 0 ,0 , 0 \ corr_N1_K, 0, 1,0 , 0 \ 0, 0 , 0, 1,0 \ 0, 0, 0, 0, 1)
 scalar growth_exog = `mu'
 scalar sd_exog = `sigma'
 matrix M = (-growth_exog,growth_exog,growth_exog,growth_exog,growth_exog)
 matrix S = (sd_exog,sd_exog,`sdK',`sdL',`sdA')
 drawnorm g_N1 g_N2 g_K g_L g_TFP, forcepsd n(`obs') corr(corrmat) means(M) sds(S)
 scalar alpha = 0.3
 scalar gamma_1 = 0.05
 scalar gamma_2 = 0.1-gamma_1
 scalar beta = 1 - alpha - gamma_1 -gamma_2
 gen g_Y = g_TFP + g_N1 *gamma_1 + g_N2 * gamma_2 + g_K * alpha + g_L * (beta)
 reg g_Y g_K g_L
 scalar alpha_noNK = e(b)[1,1]
 scalar ga_noNK = e(b)[1,3]
 reg g_Y g_K g_L g_N1
 scalar alpha_1NK = e(b)[1,1]
 scalar ga_1NK = e(b)[1,4]
 sum g_TFP
 scalar ga_unbiased = r(mean)
 return scalar alpha_1NK_out = alpha_1NK
 return scalar alpha_noNK_out = alpha_noNK
 scalar no_N1_bias_scalar =ga_1NK - ga_unbiased
 scalar no_NK_bias_scalar =ga_noNK - ga_unbiased
 return scalar TFP_bias_n1 = no_N1_bias_scalar
 return scalar TFP_bias_nK = no_NK_bias_scalar
 return scalar corr_N1_N2_out = corr_N1_N2
 return scalar corr_N1_K_out = corr_N1_K
end
