capture {
clear
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/"
sysdir set PERSONAL "/Users/xabajian/Documents/Stata/ado/personal/"
sysdir set PLUS "/Users/xabajian/Library/Application Support/Stata/ado/plus/"
global S_ADO = `"BASE;SITE;.;PERSONAL;PLUS;OLDPLACE"'
mata: mata mlib index
mata: mata set matalibs "lmatabase;lmatamcmc;lmatabma;lmatacollect;lmatatab;lmataivqreg;lmatamixlog;lmatami;lmatasem;lmatagsem;lmatasp;lmatapss;lmatalasso;lmatapostest;lmatapath;lmatameta;lmatah2o;lmataopt;lmatats;lmatasvy;lmatajm;lmatanumlib;lmatahetdid;lmataado;lmatadata;lmataerm;lmatafc;livreg2;lftools;lsynth_mata_subr;lxtabond2;lboottest;lmoremata14;lparallel;lgtools;lsax12;lcolrspace;lmoremata10;lmoremata;l_cfrmt;lhonestdid;lmoremata11;l__pllbpogz442p3_mlib"
set seed 61554
noi di "{hline 80}"
noi di "Parallel computing with Stata"
noi di "{hline 80}"
noi di `"cmd/dofile   : "__pllbpogz442p3_sim_simul.do""'
noi di "pll_id       : bpogz442p3"
noi di "pll_instance : 6/16"
noi di "tmpdir       : `c(tmpdir)'"
noi di "date-time    : `c(current_time)' `c(current_date)'"
noi di "seed         : `c(seed)'"
noi di "{hline 80}"
local pll_instance 6
local pll_id bpogz442p3
global pll_instance 6
global pll_id bpogz442p3
mata: for(i=1;i<=1;i++) PLL_QUIET = st_tempname()
}
local result = _rc
if (c(rc)) {
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/"
mata: parallel_write_diagnosis(strofreal(c("rc")),"/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/__pllbpogz442p3_finito0006","while setting memory")
clear
exit
}

* Loading Programs *
capture {
run "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/__pllbpogz442p3_prog.do"
}
local result = _rc
if (c(rc)) {
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/"
mata: parallel_write_diagnosis(strofreal(c("rc")),"/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/__pllbpogz442p3_finito0006","while loading programs")
clear
exit
}

* Checking for break *
mata: parallel_break()

* Loading Globals *
capture {
cap run "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/__pllbpogz442p3_glob.do"
}
if (c(rc)) {
  cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/"
  mata: parallel_write_diagnosis(strofreal(c("rc")),"/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/__pllbpogz442p3_finito0006","while loading globals")
  clear
  exit
}

* Checking for break *
mata: parallel_break()
capture {
  noisily {

* Checking for break *
mata: parallel_break()
    use __pllbpogz442p3_sim_dta.dta, clear
    if (`pll_instance'==$PLL_CHILDREN) local reps = 62500
    else local reps = 62500
    local pll_instance : di %04.0f `pll_instance'
    simulate alpha_1NK_out = alpha_1NK alpha_noNK_out  = alpha_noNK TFP_bias_n1 = no_N1_bias_scalar TFP_bias_nK = no_NK_bias_scalar   corr_N1_N2_out = corr_N1_N2   corr_N1_K_out = corr_N1_K , sav(__pll`pll_id'_sim_eststore`pll_instance', replace  )  rep(`reps'): simulate_MC_draw , obs(70) mu(0.01) sigma(0.01) gK(0.01) gL(0.01) gA(0.01) sdK(.0094350790604949) sdL(.0138540137559175) sdA(.0107752569019794)
  }
}
if (c(rc)) {
  cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/"
  mata: parallel_write_diagnosis(strofreal(c("rc")),"/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/__pllbpogz442p3_finito0006","while running the command/dofile")
  clear
  exit
}
mata: parallel_write_diagnosis(strofreal(c("rc")),"/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/__pllbpogz442p3_finito0006","while executing the command")
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts/"
