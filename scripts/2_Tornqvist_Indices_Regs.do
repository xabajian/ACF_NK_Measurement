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
merge 1:1 countrycode year using "$processed/pwt100.dta"
drop _merge

// Mine vs theirs
merge 1:1 countrycode year using "$processed/real_wealth_chained_tornqvist_unbalanced.dta"
drop _merge

drop if country_byte == .
xtset country_byte year

// some cross checks
gen d_torn_renew_CWON         = torn_unch_renew     / L.torn_unch_renew     - 1
gen d_torn_nonrenewables_CWON = torn_unch_nonrenew  / L.torn_unch_nonrenew  - 1

corr g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist d_torn_renew_CWON d_torn_nonrenewables_CWON

sum g_Q_NonRewnew_Tornquist ///
    DQ_bauxite_quantity DQ_coal_quantity DQ_oil_quantity DQ_copper_quantity ///
    DQ_phosphate_quantity DQ_gas_quantity DQ_gold_quantity DQ_silver_quantity ///
    DQ_iron_quantity DQ_tin_quantity DQ_lead_quantity DQ_zinc_quantity ///
    DQ_nickel_quantity d_torn_nonrenewables_CWON if g_Q_NonRewnew_Tornquist != .

// winsorize
replace d_torn_nonrenewables_CWON = -1 if d_torn_nonrenewables_CWON < -1 & d_torn_nonrenewables_CWON != .
replace d_torn_nonrenewables_CWON =  1 if d_torn_nonrenewables_CWON >  1 & d_torn_nonrenewables_CWON != .
replace g_Q_NonRewnew_Tornquist   =  1 if g_Q_NonRewnew_Tornquist   >  1 & g_Q_NonRewnew_Tornquist   != .

corr D_Q_Tornquist_nonrenewables d_torn_nonrenewables_CWON torn_unch_nonrenew ///
     DQ_coal_quantity DQ_oil_quantity DQ_iron_quantity DQ_gas_quantity DQ_gold_quantity ///
     if D_Q_Tornquist_nonrenewables != .

corr D_Q_Tornquist_nonrenewables d_torn_nonrenewables_CWON torn_unch_nonrenew ///
     DQ_coal_quantity DQ_oil_quantity DQ_iron_quantity DQ_gas_quantity DQ_gold_quantity ///
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
    bauxite_quantity nickel_rent bauxite_rent coal_quantity oil_quantity coal_rent oil_rent ///
    copper_quantity phosphate_quantity copper_rent phosphate_rent gas_quantity gas_rent ///
    gold_quantity silver_quantity gold_rent silver_rent iron_quantity tin_quantity iron_rent ///
    tin_rent lead_quantity zinc_quantity lead_rent zinc_rent nickel_quantity ///
    q_urban prod_area land forest_area_km mangrove_ha b_e hp_gwh ///
    ag_NK_wealth fisheries_wealth rec_forests_wealth FWE_wealth Hydro_wealth ///
    Mangroves_wealth NFS_wealth Timber_wealth ///
    DQ_bauxite_quantity DQ_coal_quantity DQ_oil_quantity DQ_copper_quantity ///
    DQ_phosphate_quantity DQ_gas_quantity DQ_gold_quantity DQ_silver_quantity ///
    DQ_iron_quantity DQ_tin_quantity DQ_lead_quantity DQ_zinc_quantity DQ_nickel_quantity ///
    DQ_q_urban DQ_prod_area DQ_land DQ_forest_area_km DQ_mangrove_ha DQ_b_e DQ_hp_gwh ///
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


*============================================================*
* Tab 1: TFP Growth vs. Natural Capital Growth (5 specs)
*   - locals for p-values (no scalars)
*   - unique p-values per column
*   - adec() prevents rounding collapse
*============================================================*

// // lasso
// cvlasso d.log_y g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist d.log_K d.log_L d.log_HC d.log_lab_share i.year, fe
// cvlasso, lopt

pcorr d.log_y g_Q_Renew_Tornquist g_Q_NonRewnew_Tornquist d.log_K d.log_L d.log_HC d.log_lab_share i.year i.country_byte


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
* Robust per-column p-values via esttab
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
