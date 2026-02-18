clear all
set maxvar 32000
set seed 1234

*===============================*
* Paths / globals
*===============================*
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/quantities"

global root "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
global figs   "$root/figs"
global tables "$root/tables"
global raw "$root/raw"
global processed "$root/processed"
global CWON_inputs "$root/CWON Data/FR_WLD_2024_195/Reproducibility package/Output/Latest"

set scheme plotplain

//start 

use "$processed/tornqvist_panel.dta", clear


/* Merges in PWT */
merge 1:1 countrycode year using "$raw/pwt100.dta"
drop _merge

// Mine vs theirs
merge 1:1 countrycode year using "$raw/FR_WLD_2024_195/Reproducibility package/Working/real_wealth_chained_tornqvist_unbalanced.dta"
drop _merge

drop if country_byte == .
xtset country_byte year

// some cross checks with CWON
gen d_torn_renew_CWON         = torn_unch_renew     / L.torn_unch_renew     - 1
gen d_torn_nonrenewables_CWON = torn_unch_nonrenew  / L.torn_unch_nonrenew  - 1
gen d_torn_renew_chain_CWON         = torn_ch_renew     / L.torn_ch_renew     - 1
gen d_torn_nonrenewables_chain_CWON = torn_ch_nonrenew  / L.torn_ch_nonrenew  - 1
gen d_torn_renew_real_CWON  = torn_real_renew / L.torn_real_renew     - 1
gen d_torn_nonrenewables_real_CWON  = torn_real_nonrenew / L.torn_real_nonrenew     - 1

corr g_Q_Renew_Tornquist d_torn_renew_chain_CWON d_torn_renew_CWON d_torn_renew_real_CWON   g_Q_NonRewnew_Tornquist d_torn_nonrenewables_chain_CWON d_torn_nonrenewables_CWON  d_torn_nonrenewables_real_CWON 

sum g_Q_NonRewnew_Tornquist ///
    DQ_bauxite_quantity DQ_coal_quantity DQ_oil_quantity DQ_copper_quantity ///
    DQ_phosphate_quantity DQ_gas_quantity DQ_gold_quantity DQ_silver_quantity ///
    DQ_iron_quantity DQ_tin_quantity DQ_lead_quantity DQ_zinc_quantity ///
    DQ_nickel_quantity d_torn_nonrenewables_CWON if g_Q_NonRewnew_Tornquist != .

// winsorize
replace d_torn_nonrenewables_CWON = -1 if d_torn_nonrenewables_CWON < -1 & d_torn_nonrenewables_CWON != .
replace d_torn_nonrenewables_CWON =  1 if d_torn_nonrenewables_CWON >  1 & d_torn_nonrenewables_CWON != .
replace g_Q_NonRewnew_Tornquist   =  1 if g_Q_NonRewnew_Tornquist   >  1 & g_Q_NonRewnew_Tornquist   != .

corr D_Q_Tornquist_nonrenewables d_torn_nonrenewables_CWON  d_torn_nonrenewables_real_CWON torn_unch_nonrenew ///
     DQ_coal_quantity DQ_oil_quantity DQ_iron_quantity DQ_gas_quantity DQ_gold_quantity ///
     if D_Q_Tornquist_nonrenewables != .

corr DQ_oil_quantity D_Q_Tornquist_nonrenewables d_torn_nonrenewables_chain_CWON d_torn_nonrenewables_CWON  d_torn_nonrenewables_real_CWON ///
     DQ_coal_quantity  DQ_iron_quantity DQ_gas_quantity DQ_gold_quantity ///
     if (D_Q_Tornquist_nonrenewables != . & D_Q_Tornquist_nonrenewables != 1)


// PWT variables for growth within countries over time
// keep if year>1995
drop if country_byte == .
xtset country_byte year


// PWT variables for growth within countries over time
gen log_tfp       = ln(rtfp)
gen log_K         = ln(rkna)
gen log_L         = ln(emp)
gen log_HC        = ln(hc)
gen log_lab_share = ln(labsh)
gen log_y         = ln(rgdpna)
gen dlog_tfp = D.log_tfp

// rename for ease
gen g_n1      = g_Q_NonRewnew_Tornquist
gen g_n2      = g_Q_Renew_Tornquist
gen g_k       = d.log_K
gen g_n1_CWON  = d_torn_nonrenewables_CWON
gen g_n2_CWON  = d_torn_renew_CWON


xtset country_byte year
//cvlasso d.log_y ///
//     DQ_bauxite_quantity DQ_coal_quantity DQ_oil_quantity DQ_copper_quantity ///
//     DQ_phosphate_quantity DQ_gas_quantity DQ_gold_quantity DQ_silver_quantity ///
//     DQ_iron_quantity DQ_tin_quantity DQ_lead_quantity DQ_zinc_quantity DQ_nickel_quantity ///
//     DQ_q_urban DQ_prod_area DQ_land DQ_forest_area_km DQ_mangrove_ha DQ_b_e DQ_hp_gwh ///
//     d.log_K d.log_L d.log_HC d.log_lab_share i.year, fe
//cvlasso opt


pcorr d.log_y ///
    DQ_bauxite_quantity DQ_coal_quantity DQ_oil_quantity DQ_copper_quantity ///
    DQ_phosphate_quantity DQ_gas_quantity DQ_gold_quantity DQ_silver_quantity ///
    DQ_iron_quantity DQ_tin_quantity DQ_lead_quantity DQ_zinc_quantity DQ_nickel_quantity ///
    DQ_q_urban DQ_prod_area DQ_land DQ_forest_area_km DQ_mangrove_ha DQ_b_e DQ_hp_gwh ///
    d.log_K d.log_L d.log_HC d.log_lab_share i.year i.country_byte

pcorr d.log_tfp ///
    DQ_bauxite_quantity DQ_coal_quantity DQ_oil_quantity DQ_copper_quantity ///
    DQ_phosphate_quantity DQ_gas_quantity DQ_gold_quantity DQ_silver_quantity ///
    DQ_iron_quantity DQ_tin_quantity DQ_lead_quantity DQ_zinc_quantity DQ_nickel_quantity ///
    DQ_q_urban DQ_prod_area DQ_land DQ_forest_area_km DQ_mangrove_ha DQ_b_e DQ_hp_gwh ///
    d.log_K d.log_L d.log_HC d.log_lab_share i.year i.country_byte

corr g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist d_torn_renew_CWON d_torn_nonrenewables_CWON g_k

 
// Clean brefore regressionss
drop ///
    total_non_renewable_NK ///
    nickel_rent_weight bauxite_rent_weight coal_rent_weight oil_rent_weight ///
    copper_rent_weight phosphate_rent_weight gas_rent_weight gold_rent_weight ///
    silver_rent_weight iron_rent_weight tin_rent_weight lead_rent_weight ///
    zinc_rent_weight total_renewable_NK ///
    q_urban_weight prod_area_weight land_weight forest_area_km_weight ///
    mangrove_ha_weight b_e_weight hp_gwh_weight ///
    nickel_rent_weight_exponent bauxite_rent_weight_exponent coal_rent_weight_exponent ///
    oil_rent_weight_exponent copper_rent_weight_exponent phosphate_rent_weight_exponent ///
    gas_rent_weight_exponent gold_rent_weight_exponent silver_rent_weight_exponent ///
    iron_rent_weight_exponent tin_rent_weight_exponent lead_rent_weight_exponent ///
    zinc_rent_weight_exponent ///
    DQ_bauxite_exponentiated DQ_coal_exponentiated DQ_oil_exponentiated ///
    DQ_copper_exponentiated DQ_phosphate_exponentiated DQ_gas_exponentiated ///
    DQ_gold_exponentiated DQ_silver_exponentiated DQ_iron_exponentiated ///
    DQ_tin_exponentiated DQ_lead_exponentiated DQ_zinc_exponentiated ///
    DQ_nickel_exponentiated D_Q_Tornquist_nonrenewables ///
    DQ_q_urban_exponentiated DQ_prod_area_exponentiated DQ_land_exponentiated ///
    DQ_forest_area_km_exponentiated DQ_mangrove_ha_exponentiated DQ_b_e_exponentiated ///
    DQ_hp_gwh_exponentiated D_Q_Tornquist_renewables

//take logs of these 
local varlist   all_nk_vars  DQ_bauxite_quantity DQ_coal_quantity DQ_oil_quantity DQ_copper_quantity ///
    DQ_phosphate_quantity DQ_gas_quantity DQ_gold_quantity DQ_silver_quantity ///
    DQ_iron_quantity DQ_tin_quantity DQ_lead_quantity DQ_zinc_quantity DQ_nickel_quantity ///
    DQ_q_urban DQ_prod_area DQ_land DQ_forest_area_km DQ_mangrove_ha DQ_b_e DQ_hp_gwh 
	
foreach var of local all_nk_vars{
	
	replace `var' = ln(`var')
}
*============================================================*
* Tab : output  Growth vs. Natural Capital Growth (5 specs)
*============================================================*

// // lasso
cvlasso d.log_y g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist d.log_K d.log_L d.log_HC d.log_lab_share i.year, fe
cvlasso, lopt

pcorr d.log_y g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist d.log_K d.log_L d.log_HC d.log_lab_share i.year i.country_byte

//create average growth from these indices
preserve 
//renew 
sum g_Q_Renew_Tornquist if g_Q_Renew_Tornquist>0, d
scalar mu_2_plus = r(p50)
sum g_Q_Renew_Tornquist if g_Q_Renew_Tornquist<0 ,d 
scalar mu_2_minus = r(p50)
sum g_Q_Renew_Tornquist 
scalar sigma_2 = r(sd)

//NR
sum g_Q_NonRewnew_Tornquist if g_Q_NonRewnew_Tornquist>0, d
scalar mu_1_plus = r(p50)
sum g_Q_NonRewnew_Tornquist if g_Q_NonRewnew_Tornquist<0 ,d 
scalar mu_1_minus = r(p50)
sum g_Q_NonRewnew_Tornquist
scalar sigma_1 = r(sd)

drop _all
set obs 1
gen mu_1_plus = mu_1_plus
gen mu_1_minus = mu_1_minus
gen mu_2_plus = mu_2_plus
gen mu_2_minus = mu_2_minus
gen sigma_1 = sigma_1
gen sigma_2 = sigma_2
save "$processed/index_growth.dta", replace
restore


*============================================================*
* Robust per-column p-values via esttab
*============================================================*
eststo clear

*(1)
reg d.log_y g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist, vce(cluster country_byte)
eststo m1

*(2)
reg d.log_y g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist d.log_K d.log_L d.log_HC d.log_lab_share, ///
    vce(cluster country_byte)
eststo m2

*(3)
areg d.log_y g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist i.year, ///
    absorb(country_byte) vce(cluster country_byte)
eststo m3

*(4)
areg d.log_y g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(country_byte) vce(cluster country_byte)
eststo m4


*(5)
reghdfe d.log_y g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(i.country_byte##c.year) vce(cluster country_byte)
eststo m5

*---- export with esttab ----*
esttab m1 m2 m3 m4 m5 using "$tables/appendix_tornq_regs.tex", replace ///
    title("TFP Growth vs. Natural Capital Growth") ///
    keep(g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist) ///
    b(3) se(3) ///
    star(* 0.0001)


	
*============================================================*
* CWON version, wrong indices
*============================================================*
eststo clear

*(1)
reg d.log_y d_torn_renew_CWON d_torn_nonrenewables_CWON, vce(cluster country_byte)
eststo m1

*(2)
reg d.log_y d_torn_renew_CWON d_torn_nonrenewables_CWON d.log_K d.log_L d.log_HC d.log_lab_share, ///
    vce(cluster country_byte)
eststo m2

*(3)
areg d.log_y d_torn_renew_CWON d_torn_nonrenewables_CWON i.year, ///
    absorb(country_byte) vce(cluster country_byte)
eststo m3

*(4)
areg d.log_y d_torn_renew_CWON d_torn_nonrenewables_CWON i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(country_byte) vce(cluster country_byte)
eststo m4

*(5)
reghdfe d.log_y d_torn_renew_CWON d_torn_nonrenewables_CWON i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(i.country_byte##c.year) vce(cluster country_byte)
eststo m5

*---- export with esttab ----*
esttab m1 m2 m3 m4 m5 using "$tables/appendix_tornq_regs_CWON.tex", replace ///
    title("TFP Growth vs. Natural Capital Growth") ///
    keep(d_torn_renew_CWON d_torn_nonrenewables_CWON) ///
    b(3) se(3) ///
    star(* 0.0001)

	


*============================================================*
* Tab : TFP vs ALL NK vs. Natural Capital Growth (5 specs)
*============================================================*

eststo clear

local keepvars ///
	 DQ_coal_quantity DQ_oil_quantity DQ_copper_quantity ///
    DQ_phosphate_quantity DQ_gas_quantity DQ_gold_quantity DQ_silver_quantity ///
    DQ_iron_quantity DQ_tin_quantity DQ_lead_quantity DQ_zinc_quantity DQ_nickel_quantity ///
    DQ_q_urban DQ_prod_area DQ_land DQ_forest_area_km DQ_mangrove_ha DQ_b_e DQ_hp_gwh 

*(1)
reg d.log_tfp  `keepvars' , vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m1

*(2)
reg d.log_tfp  `keepvars'	d.log_K d.log_L d.log_HC d.log_lab_share, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m2

*(3)
areg d.log_tfp `keepvars' i.year, absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m3

*(4)
areg d.log_tfp `keepvars' i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m4

*(5)
reghdfe d.log_tfp `keepvars' i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(i.country_byte##c.year) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
// boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = 990
eststo m5

*(6) arellano bond

qui{
	forvalues i = 1995/2019  {
		gen year`i' = 1 if year==`i'
		replace year`i'=0 if  year!=`i'
}
}

xtabond d.log_tfp `keepvars' d.log_K d.log_L d.log_HC d.log_lab_share year1* year2*,  lags(2) vce(robust)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m6

drop year1* year2*


*---- export with esttab ----*
esttab m1 m2 m3 m4 m5 m6 using "$tables/tab1_appendix_all_NK.tex", replace ///
    title("TFP Growth vs. Natural Capital Growth") ///
    keep(`keepvars') ///
    b(3) se(3) ///
    star(* 0.0001) ///
    stats(p_joint p_joint_boot N, ///
          labels("Wald" "Bootstrap Wald" "N") ///
          fmt(3 3 0 3))
		  
		  
*============================================================*
* Tab : TFP vs ALL NK vs. Natural Capital Growth (5 specs), post 1994
*============================================================*

eststo clear

local keepvars ///
	 DQ_coal_quantity DQ_oil_quantity DQ_copper_quantity ///
    DQ_phosphate_quantity DQ_gas_quantity DQ_gold_quantity DQ_silver_quantity ///
    DQ_iron_quantity DQ_tin_quantity DQ_lead_quantity DQ_zinc_quantity DQ_nickel_quantity ///
    DQ_q_urban DQ_prod_area DQ_land DQ_forest_area_km DQ_mangrove_ha DQ_b_e DQ_hp_gwh 

*(1)
reg d.log_tfp  `keepvars'  if year>1994, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m1

*(2)
reg d.log_tfp  `keepvars'	d.log_K d.log_L d.log_HC d.log_lab_share  if year>1994 , vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m2

*(3)
areg d.log_tfp `keepvars' i.year  if year>1994, absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m3

*(4)
areg d.log_tfp `keepvars' i.year d.log_K d.log_L d.log_HC d.log_lab_share if year>1994, ///
    absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m4

*(5)
reghdfe d.log_tfp `keepvars' i.year d.log_K d.log_L d.log_HC d.log_lab_share  if year>1994, ///
    absorb(i.country_byte##c.year) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
// boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = 990
eststo m5

*(6) arellano bond

qui{
	forvalues i = 1995/2019  {
		gen year`i' = 1 if year==`i'
		replace year`i'=0 if  year!=`i'
}
}

xtabond d.log_tfp `keepvars' d.log_K d.log_L d.log_HC d.log_lab_share year1* year2* if year>1994,  lags(2) vce(robust)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m6

drop year1* year2*


*---- export with esttab ----*
esttab m1 m2 m3 m4 m5 m6 using "$tables/tab1_appendix_all_NK_post94.tex", replace ///
    title("TFP Growth vs. Natural Capital Growth") ///
    keep(`keepvars') ///
    b(3) se(3) ///
    star(* 0.0001) ///
    stats(p_joint p_joint_boot N, ///
          labels("Wald" "Bootstrap Wald" "N") ///
          fmt(3 3 0 3))
	
*============================================================*
* Country-level data out
*============================================================*
bysort country_byte: egen corr_N1_K      = corr(g_n1 g_k)
bysort country_byte: egen corr_N1_N2     = corr(g_n1 g_n2)
bysort country_byte: egen corr_N1_K_CWON = corr(g_n1_CWON g_k)
bysort country_byte: egen corr_N1_N2_CWON= corr(g_n1_CWON g_n2_CWON)

collapse (mean) ///
    corr_N1_K corr_N1_N2 corr_N1_N2_CWON corr_N1_K_CWON ///
    g_n1 g_k g_n2 g_n1_CWON g_n2_CWON dlog_tfp, by(country_byte)

sum corr_N1_K corr_N1_N2 corr_N1_N2_CWON corr_N1_K_CWON ///
    g_n1 g_k g_n2 g_n1_CWON g_n2_CWON if g_n1 != .

// scatter g_n1 g_n1_CWON

count
keep if corr_N1_N2 != .
keep if g_k > 0 & g_k != .
count

rename corr_N1_K  corr_N1_K_out
rename corr_N1_N2 corr_N1_N2_out

tostring country_byte, gen(country_string)
save "$processed/CWON_data.dta", replace
save "$root/simulations/CWON_data.dta", replace
