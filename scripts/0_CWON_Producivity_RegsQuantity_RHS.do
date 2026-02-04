clear all
set maxvar 32000
set seed 1234

*===============================*
* Paths / globals
*===============================*
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"

//make directories
capture mkdir quantities
capture mkdir tables
capture mkdir figs
capture mkdir simulations
capture mkdir processed



global root "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
global figs   "$root/figs"
global tables "$root/tables"
global raw "$root/raw"
global processed "$root/processed"
set scheme plotplain


/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step 1 -- Read Data

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/



use "$raw/FR_WLD_2024_195/Reproducibility package/Working/assets_volume_variables.dta", clear

keep countrycode countryname region regionname incomelevel incomelevelname year pop ///
    q_pk q_urban prod_area land forest_area_km mangrove_ha b_e hp_gwh ///
    reserves_oil reserves_gas res_coal reserves_bauxite reserves_copper reserves_gold ///
    reserves_iron_ore reserves_lead reserves_nickel reserves_phosphate reserves_silver ///
    reserves_tin reserves_zinc reserves_cobalt reserves_molybdenum reserves_lithium


/*
merge PWT and other datasets
*/
merge 1:1 countrycode year using "$raw/pwt100.dta", keep(3)
drop _merge

gen iso3 = countrycode

// merge the euro area version from Eurostat
merge 1:1 year iso3 using "$raw/euro_area_mfp_panel_iso.dta", gen(merge_EU)
drop if merge_EU == 2

// FAO TFP panel
merge 1:1 year countrycode using "$raw/UN_FAO_TFP_panel.dta", gen(merge_UNFAO)
drop if merge_UNFAO == 2


/*
Prep % changes of renewable NK stocks
*/
encode countrycode, gen(country_byte)
xtset country_byte year


local resources q_urban prod_area land forest_area_km mangrove_ha b_e hp_gwh

foreach var of local resources {

    qui {
        gen log_`var'  = ln(`var')
        gen dlog_`var' = d.log_`var'
    }

    gen flag_`var' = 1 if dlog_`var' == .
    replace flag_`var' = 0 if dlog_`var' != .
    replace dlog_`var' = 0 if dlog_`var' == .

    drop log_`var'

    gen d_`var' = d.`var'
}


/*
1.2 -- prep outcomes and covariates from PWT
*/

/*
Other outcomes
*/

// Eurostat 287 + norway TFP measures
gen log_eurostat_MFP = ln(mfp)

/*
FAO ag TFP
*/
gen log_ag_TFP = ln(TFP_Index)


// PWT variables for growth within countries over time
gen log_tfp       = ln(rtfp)
gen log_K         = ln(rkna)
gen log_L         = ln(emp)
gen log_HC        = ln(hc)
gen log_lab_share = ln(labsh)
gen log_y         = ln(rgdpna)
gen ldiff_TFP = d.log_tfp

/*
save my seven stocks
*/
preserve
keep countrycode year q_urban prod_area land forest_area_km mangrove_ha b_e hp_gwh
save "$processed/renewable_quantities.dta", replace
restore


// Lassos

// First stage, test ability to predict GDP
cvlasso d.log_y dlog* d.log_K d.log_L d.log_HC d.log_lab_share i.year, fe
cvlasso, lopt

// Second stage, test ability to predict TFP
cvlasso d.log_tfp dlog* d.log_K d.log_L d.log_HC d.log_lab_share i.year, fe
cvlasso, lopt


// PWT

*============================================================*
* Tab 1: TFP Growth vs. Natural Capital Growth (5 specs)
*   - locals for p-values (no scalars)
*   - unique p-values per column
*   - adec() prevents rounding collapse
*============================================================*

label var dlog_q_urban        "Urban Land"
label var dlog_prod_area      "Productive Forest"
label var dlog_land           "Agricultural Land"
label var dlog_forest_area_km "Forest Area"
label var dlog_mangrove_ha    "Mangroves"
label var dlog_b_e            "Biomass"
label var dlog_hp_gwh         "Hydropower"


*============================================================*
* Main table: PWT TFP outcome
*============================================================*
eststo clear

local keepvars ///
    dlog_q_urban dlog_prod_area dlog_land ///
    dlog_forest_area_km dlog_mangrove_ha ///
    dlog_b_e dlog_hp_gwh

*(1)
reg d.log_tfp dlog*, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m1

*(2)
reg d.log_tfp dlog* d.log_K d.log_L d.log_HC d.log_lab_share, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m2

*(3)
areg d.log_tfp dlog* i.year, absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m3

*(4)
areg d.log_tfp dlog* i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m4

*(5)
reghdfe d.log_tfp dlog* i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(i.country_byte##c.year) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
// boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = 990
eststo m5


*---- export with esttab ----*
esttab m1 m2 m3 m4 m5 using "$tables/tab1.tex", replace ///
    title("TFP Growth vs. Natural Capital Growth") ///
    keep(`keepvars') ///
    b(3) se(3) ///
    star(* 0.0001) ///
    stats(p_joint p_joint_boot N, ///
          labels("Wald" "Bootstrap Wald" "N") ///
          fmt(3 3 0 3))

sum flag_* if year > 1995 & d.log_tfp != .
codebook countryname if flag_q_urban ==0 & d.log_tfp != .
codebook countryname if flag_prod_area ==0 & d.log_tfp != .
codebook countryname if flag_land ==0 & d.log_tfp != .
codebook countryname if flag_forest_area_km ==0 & d.log_tfp != .
codebook countryname if flag_mangrove_ha==0 & d.log_tfp != .
codebook countryname if flag_b_e==0 & d.log_tfp != .
codebook countryname if flag_hp_gwh==0 & d.log_tfp != .

// RI test

//old
//permute ldiff_TFP F_test = Ftail(e(df_m), e(df_r), e(F))


permute ldiff_TFP F_test = e(F), ///
    saving("$processed/ritest1.dta", replace) ///
    strata(country_byte) ///
    reps(10000) ///
    dots(100) ///
    seed(1234) : ///
    areg ldiff_TFP dlog*, absorb(country_byte) vce(cluster country_byte)

 areg ldiff_TFP dlog*, absorb(country_byte) vce(cluster country_byte)

local keepvars ///
    dlog_q_urban dlog_prod_area dlog_land ///
    dlog_forest_area_km dlog_mangrove_ha ///
    dlog_b_e dlog_hp_gwh

test `keepvars'
// display %4.3f r(p)
// local p : display %4.3f r(p)
display %4.3f r(F)
local F : display %4.3f r(F)

preserve
use "$processed/ritest1.dta", clear

count if F_test < `F'
    
display r(N) / 10000
// .9815


histogram F_test, ///
    lcolor(red) color(red%40) bins(50) ///
    text(1400 4.4 "{it:F} = `F'", size(vsmall)) ///
    legend(off) ///
    ytitle("Number of Resampled Estimates") ///
    xline(`F', lcolor(gray) extend lpattern(dash)) ///
    xtitle("Placebo {it:F}-stat of Wald Test") ///
    ylabel(0(500)1500) ///
    frequency

graph export "$figs/robustness_RI.png", replace
restore


*============================================================*
* Tab 1 (narrow): drop some stocks
*   drop dlog_mangrove_ha dlog_b_e dlog_hp_gwh
*============================================================*
preserve
drop dlog_mangrove_ha dlog_b_e dlog_hp_gwh

eststo clear

local keepvars ///
    dlog_q_urban dlog_prod_area dlog_land ///
    dlog_forest_area_km

*(1)
reg d.log_tfp dlog*, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m1

*(2)
reg d.log_tfp dlog* d.log_K d.log_L d.log_HC d.log_lab_share, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m2

*(3)
areg d.log_tfp dlog* i.year, absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m3

*(4)
areg d.log_tfp dlog* i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m4

*(5)
reghdfe d.log_tfp dlog* i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(i.country_byte##c.year) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
// boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = 990
eststo m5


*---- export with esttab ----*
esttab m1 m2 m3 m4 m5 using "$tables/tab1_narrow.tex", replace ///
    title("TFP Growth vs. Natural Capital Growth") ///
    keep(`keepvars') ///
    b(3) se(3) ///
    star(* 0.0001) ///
    stats(p_joint p_joint_boot N, ///
          labels("Wald" "Bootstrap Wald" "N") ///
          fmt(3 3 0 3))

sum flag_* if year > 1995 & d.log_tfp != .
restore


*============================================================*
* Tab 2: Eurostat MFP Growth vs. Natural Capital Growth (5 specs)
*============================================================*
eststo clear

local keepvars ///
    dlog_q_urban dlog_prod_area dlog_land ///
    dlog_forest_area_km dlog_mangrove_ha ///
    dlog_b_e dlog_hp_gwh

*(1)
reg d.log_eurostat_MFP dlog*, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m1

*(2)
reg d.log_eurostat_MFP dlog* d.log_K d.log_L d.log_HC d.log_lab_share, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m2

*(3)
areg d.log_eurostat_MFP dlog* i.year, absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m3

*(4)
areg d.log_eurostat_MFP dlog* i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m4

*(5)
reghdfe d.log_eurostat_MFP dlog* i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(i.country_byte##c.year) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
// boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = 990
eststo m5


*---- export with esttab ----*
esttab m1 m2 m3 m4 m5 using "$tables/tab2.tex", replace ///
    title("Eurostat MFP Growth vs. Natural Capital Growth") ///
    keep(`keepvars') ///
    b(3) se(3) ///
    star(* 0.0001) ///
    stats(p_joint p_joint_boot N, ///
          labels("Wald" "Bootstrap Wald" "N") ///
          fmt(3 3 0 3))


*============================================================*
* Tab 3: EU + Norway PWT TFP Growth vs. Natural Capital Growth
*   (apples-to-apples vs Eurostat MFP)
*============================================================*
eststo clear

local keepvars ///
    dlog_q_urban dlog_prod_area dlog_land ///
    dlog_forest_area_km ///
    dlog_b_e dlog_hp_gwh

preserve
// keep EU + Norway for apples to apples
local keep_codes ///
    AUT BEL BGR CYP CZE DEU DNK ESP EST FIN FRA GRC HRV HUN ///
    IRL ITA LTU LUX LVA MLT NLD NOR POL PRT ROU SVK SVN SWE

gen byte keep_flag = 0
decode country_byte, gen(country_string)

foreach c of local keep_codes {
    replace keep_flag = 1 if country_string == "`c'"
}

keep if keep_flag == 1
drop keep_flag

corr d.log_tfp d.log_eurostat_MFP


*(1)
reg d.log_tfp dlog* if year > 2002, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m1

*(2)
reg d.log_tfp dlog* d.log_K d.log_L d.log_HC d.log_lab_share if year > 2002, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m2

*(3)
areg d.log_tfp dlog* i.year if year > 2002, absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m3

*(4)
areg d.log_tfp dlog* i.year d.log_K d.log_L d.log_HC d.log_lab_share if year > 2002, ///
    absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m4

*(5)
reghdfe d.log_tfp dlog* i.year d.log_K d.log_L d.log_HC d.log_lab_share if year > 2002, ///
    absorb(i.country_byte##c.year) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
// boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = 990
eststo m5


*---- export with esttab ----*
esttab m1 m2 m3 m4 m5 using "$tables/tabEU_comp.tex", replace ///
    title("EU + Norway PWT TFP Growth vs. Natural Capital Growth") ///
    keep(`keepvars') ///
    b(3) se(3) ///
    star(* 0.0001) ///
    stats(p_joint p_joint_boot N, ///
          labels("Wald" "Bootstrap Wald" "N") ///
          fmt(3 3 0 3))


// run seemingly unrelated regression to test equality
sureg ///
    (d.log_tfp dlog* i.year i.country_byte d.log_K d.log_L d.log_HC d.log_lab_share) ///
    (d.log_eurostat_MFP dlog* i.year i.country_byte d.log_K d.log_L d.log_HC d.log_lab_share)

test [D_log_tfp = D_log_eurostat_MFP]: ///
    dlog_q_urban dlog_prod_area dlog_land ///
    dlog_forest_area_km ///
    dlog_b_e dlog_hp_gwh

restore


*============================================================*
* Tab 4: Agricultural TFP Growth vs. Natural Capital Growth
*============================================================*
eststo clear

local keepvars ///
    dlog_q_urban dlog_prod_area dlog_land ///
    dlog_forest_area_km dlog_mangrove_ha ///
    dlog_b_e dlog_hp_gwh

*(1)
reg d.log_tfp dlog*, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m1

*(2)
reg d.log_ag_TFP dlog* d.log_K d.log_L d.log_HC d.log_lab_share, vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m2

*(3)
areg d.log_ag_TFP dlog* i.year, absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m3

*(4)
areg d.log_ag_TFP dlog* i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(country_byte) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = r(p)
eststo m4

*(5)
reghdfe d.log_ag_TFP dlog* i.year d.log_K d.log_L d.log_HC d.log_lab_share, ///
    absorb(i.country_byte##c.year) vce(cluster country_byte)
test `keepvars'
estadd scalar p_joint = r(p)
// boottest `keepvars', cluster(country_byte) nograph
estadd scalar p_joint_boot = 990
eststo m5


*---- export with esttab ----*
esttab m1 m2 m3 m4 m5 using "$tables/other_robustness.tex", replace ///
    title("Agricultural TFP Growth vs. Natural Capital Growth") ///
    keep(`keepvars') ///
    b(3) se(3) ///
    star(* 0.0001) ///
    stats(p_joint p_joint_boot N, ///
          labels("Wald" "Bootstrap Wald" "N") ///
          fmt(3 3 0 3)
