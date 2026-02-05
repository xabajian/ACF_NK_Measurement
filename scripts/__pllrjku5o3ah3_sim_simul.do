use __pllrjku5o3ah3_sim_dta.dta, clear
if (`pll_instance'==$PLL_CHILDREN) local reps = 62500
else local reps = 62500
local pll_instance : di %04.0f `pll_instance'
simulate alpha_1NK_out = alpha_1NK alpha_noNK_out  = alpha_noNK TFP_bias_n1 = no_N1_bias_scalar TFP_bias_nK = no_NK_bias_scalar   corr_N1_N2_out = corr_N1_N2   corr_N1_K_out = corr_N1_K , sav(__pll`pll_id'_sim_eststore`pll_instance', replace  )  rep(`reps'): simulate_MC_draw , obs(70) mu(0.01) sigma(0.01) gK(0.01) gL(0.01) gA(0.01) sdK(.0094350790604949) sdL(.0138540137559175) sdA(.0107752569019794)
