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

*============================================================*
* Nonrenewable resource extraction quantities
*============================================================*
local quantities_list ///
    coal_production.dta ///
    gas_production.dta ///
    min_production_bauxite.dta ///
    min_production_copper.dta ///
    min_production_gold.dta ///
    min_production_iron_ore.dta ///
    min_production_lead.dta ///
    min_production_nickel.dta ///
    min_production_phosphate.dta ///
    min_production_silver.dta ///
    min_production_tin.dta ///
    min_production_zinc.dta ///
    oil_production.dta

local lbl1  "Coal"
local lbl2  "Gas"
local lbl3  "Bauxite"
local lbl4  "Copper"
local lbl5  "Gold"
local lbl6  "Iron"
local lbl7  "Lead"
local lbl8  "Nickel"
local lbl9  "Phosphate"
local lbl10 "Silver"
local lbl11 "Tin"
local lbl12 "Zinc"
local lbl13 "Oil"

qui {
    local i = 1
    foreach q of local quantities_list {
        use "$CWON_inputs/`q'", clear

        local textlbl "`lbl`i''"
        reshape long YR, i(countrycode countryname) j(year)

        local varname : copy local textlbl
        local varname = lower("`varname'")
        local varname = subinstr("`varname'", " ", "_", .)
        local varname = subinstr("`varname'", "-", "_", .)
        local varname = subinstr("`varname'", "/", "_", .)

        rename YR `varname'_quantity
        save "`textlbl'_quantites.dta", replace

        display series[1]
        local ++i
    }
}


*============================================================*
* Repeat for rents
*============================================================*
local lbl1  "Coal"
local lbl2  "Gas"
local lbl3  "Bauxite"
local lbl4  "Copper"
local lbl5  "Gold"
local lbl6  "Iron"
local lbl7  "Lead"
local lbl8  "Nickel"
local lbl9  "Phosphate"
local lbl10 "Silver"
local lbl11 "Tin"
local lbl12 "Zinc"
local lbl13 "Oil"

local rents_list ///
    coal_rent_cd.dta ///
    gas_rent_cd.dta ///
    min_rent_bauxite_cd_uc.dta ///
    min_rent_copper_cd_uc.dta ///
    min_rent_gold_cd_uc.dta ///
    min_rent_iron_ore_cd_uc.dta ///
    min_rent_lead_cd_uc.dta ///
    min_rent_nickel_cd_uc.dta ///
    min_rent_phosphate_cd_uc.dta ///
    min_rent_silver_cd_uc.dta ///
    min_rent_tin_cd_uc.dta ///
    min_rent_zinc_cd_uc.dta ///
    oil_rent_cd.dta

local lbl1  "Coal"
local lbl2  "Gas"
local lbl3  "Bauxite"
local lbl4  "Copper"
local lbl5  "Gold"
local lbl6  "Iron"
local lbl7  "Lead"
local lbl8  "Nickel"
local lbl9  "Phosphate"
local lbl10 "Silver"
local lbl11 "Tin"
local lbl12 "Zinc"
local lbl13 "Oil"

qui {
    local i = 1
    foreach q of local rents_list {
        use "$CWON_inputs/`q'", clear

        local textlbl "`lbl`i''"
        reshape long YR, i(countrycode countryname) j(year)

        local varname : copy local textlbl
        local varname = lower("`varname'")
        local varname = subinstr("`varname'", " ", "_", .)
        local varname = subinstr("`varname'", "-", "_", .)
        local varname = subinstr("`varname'", "/", "_", .)

        rename YR `varname'_rent
        save "`textlbl'_rents.dta", replace

        local ++i
    }
}


*============================================================*
* Merge non-renewable resources into a single panel
*============================================================*
/*
merge non-renewable resources single panel
*/
local merge_list ///
    Nickel_rents.dta ///
    Bauxite_rents.dta ///
    Coal_quantites.dta ///
    Oil_quantites.dta ///
    Coal_rents.dta ///
    Oil_rents.dta ///
    Copper_quantites.dta ///
    Phosphate_quantites.dta ///
    Copper_rents.dta ///
    Phosphate_rents.dta ///
    Gas_quantites.dta ///
    Gas_rents.dta ///
    Gold_quantites.dta ///
    Silver_quantites.dta ///
    Gold_rents.dta ///
    Silver_rents.dta ///
    Iron_quantites.dta ///
    Tin_quantites.dta ///
    Iron_rents.dta ///
    Tin_rents.dta ///
    Lead_quantites.dta ///
    Zinc_quantites.dta ///
    Lead_rents.dta ///
    Zinc_rents.dta ///
    Nickel_quantites.dta

use Bauxite_quantites.dta

foreach q of local merge_list {
    merge 1:1 countrycode year using `q'
    drop _merge
}

save NR_Resource_Rents_Panel.dta, replace


/*
Step next... Make Tornquist indices
*/

*/

/*
Merge in renewables
*/
use NR_Resource_Rents_Panel.dta, clear

merge 1:1 countrycode year using renewable_quantities.dta
drop _merge

merge 1:1 countrycode year using renewable_wealth.dta
drop _merge

// ag_NK_wealth fisheries_wealth rec_forests_wealth FWE_wealth Hydro_wealth Mangroves_wealth NFS_wealth Timber_wealth
encode countrycode, gen(country_byte)
xtset country_byte year


local NR_quantities ///
    bauxite_quantity coal_quantity oil_quantity copper_quantity phosphate_quantity ///
    gas_quantity gold_quantity silver_quantity iron_quantity tin_quantity ///
    lead_quantity zinc_quantity nickel_quantity ///
    q_urban prod_area land forest_area_km mangrove_ha b_e hp_gwh


/*
gen Q'/Q with upper bound of 4
*/
xtset country_byte year
sort country_byte year

foreach var of local NR_quantities {
    qui {
        gen DQ_`var' = `var' / L.`var' if country_byte == country_byte[_n-1]
    }

    // remove anything that's using pct change from missings or zeros
    replace DQ_`var' = 1 if (L.`var' == . | L.`var' == 0 | F.`var' == 0 | F.`var' == .)

    // topcode
    replace DQ_`var' = 2 if DQ_`var' > 2
}


/*
Generate tornquist weights for NR Resources
*/
local NR_rents ///
    nickel_rent bauxite_rent coal_rent oil_rent copper_rent phosphate_rent ///
    gas_rent gold_rent silver_rent iron_rent tin_rent lead_rent zinc_rent

foreach var of local NR_rents {
    replace `var' = 0 if `var' == .
}

gen total_non_renewable_NK = ///
      nickel_rent + bauxite_rent + coal_rent + oil_rent + copper_rent + phosphate_rent ///
    + gas_rent + gold_rent + silver_rent + iron_rent + tin_rent + lead_rent + zinc_rent

// generate weights
local NR_rents ///
    nickel_rent bauxite_rent coal_rent oil_rent copper_rent phosphate_rent ///
    gas_rent gold_rent silver_rent iron_rent tin_rent lead_rent zinc_rent

foreach var of local NR_rents {
    gen `var'_weight = `var' / total_non_renewable_NK
}


/*
Generate tornquist weights for renewables
*/
local renewable_rents ///
    ag_NK_wealth fisheries_wealth rec_forests_wealth FWE_wealth Hydro_wealth ///
    Mangroves_wealth NFS_wealth Timber_wealth

foreach var of local renewable_rents {
    replace `var' = 0 if `var' == .
}

gen total_renewable_NK = ///
    ag_NK_wealth + rec_forests_wealth + FWE_wealth + Hydro_wealth + ///
    Mangroves_wealth + NFS_wealth + Timber_wealth

foreach var of local renewable_rents {
    gen `var'_weight = `var' / total_renewable_NK
}

gen test = ///
    ag_NK_wealth_weight + rec_forests_wealth_weight + FWE_wealth_weight + ///
    Hydro_wealth_weight + Mangroves_wealth_weight + NFS_wealth_weight + ///
    Timber_wealth_weigh
sum test
drop test


// collapse by countries and merge back indices
preserve
keep countrycode ///
    ag_NK_wealth_weight fisheries_wealth_weight rec_forests_wealth_weight ///
    FWE_wealth_weight Hydro_wealth_weight Mangroves_wealth_weight ///
    NFS_wealth_weight Timber_wealth_weight

foreach v in ag_NK_wealth_weight fisheries_wealth_weight rec_forests_wealth_weight ///
             FWE_wealth_weight Hydro_wealth_weight Mangroves_wealth_weight ///
             NFS_wealth_weight Timber_wealth_weight {
    drop if `v' == .
}

// averages
collapse ///
    ag_NK_wealth_weight fisheries_wealth_weight rec_forests_wealth_weight ///
    FWE_wealth_weight Hydro_wealth_weight Mangroves_wealth_weight ///
    NFS_wealth_weight Timber_wealth_weight, by(countrycode)

gen q_urban_weight         = ag_NK_wealth_weight / 2
gen prod_area_weight       = Timber_wealth_weight
gen land_weight            = ag_NK_wealth_weight / 2
gen forest_area_km_weight  = rec_forests_wealth_weight + NFS_wealth_weight
gen mangrove_ha_weight     = Mangroves_wealth_weight
gen b_e_weight             = FWE_wealth_weight
gen hp_gwh_weight          = Hydro_wealth_weight

save renewable_capital_weights.dta, replace
restore

merge m:1 countrycode using renewable_capital_weights.dta
drop _merge

gen total_weight = ///
      q_urban_weight ///
    + prod_area_weight ///
    + land_weight ///
    + forest_area_km_weight ///
    + mangrove_ha_weight ///
    + b_e_weight ///
    + hp_gwh_weight

sum total_weight
drop total_weight
drop ag_NK_wealth_weight fisheries_wealth_weight rec_forests_wealth_weight FWE_wealth_weight ///
     Hydro_wealth_weight Mangroves_wealth_weight NFS_wealth_weight Timber_wealth_weight


/*
OK, we have weights. now just need the exponents
*/
local NR_rents ///
    nickel_rent bauxite_rent coal_rent oil_rent copper_rent phosphate_rent ///
    gas_rent gold_rent silver_rent iron_rent tin_rent lead_rent zinc_rent

xtset country_byte year
foreach var of local NR_rents {
    gen `var'_weight_exponent = 0.5 * (`var'_weight + L.`var'_weight)
    replace `var'_weight_exponent = `var'_weight if L.`var'_weight == .
}


/*
NR Tornquist Quantity index
*/
local NR_resources bauxite coal oil copper phosphate gas gold silver iron tin lead zinc nickel

foreach var of local NR_resources {
    gen DQ_`var'_exponentiated = DQ_`var'_quantity^(`var'_rent_weight_exponent)
}

gen D_Q_Tornquist_nonrenewables = ///
      DQ_bauxite_exponentiated ///
    * DQ_coal_exponentiated ///
    * DQ_oil_exponentiated ///
    * DQ_copper_exponentiated ///
    * DQ_phosphate_exponentiated ///
    * DQ_gas_exponentiated ///
    * DQ_gold_exponentiated ///
    * DQ_silver_exponentiated ///
    * DQ_iron_exponentiated ///
    * DQ_tin_exponentiated ///
    * DQ_lead_exponentiated ///
    * DQ_zinc_exponentiated ///
    * DQ_nickel_exponentiated

sum D_Q_Tornquist_nonrenewables ///
    DQ_bauxite_quantity DQ_coal_quantity DQ_oil_quantity DQ_copper_quantity ///
    DQ_phosphate_quantity DQ_gas_quantity DQ_gold_quantity DQ_silver_quantity ///
    DQ_iron_quantity DQ_tin_quantity DQ_lead_quantity DQ_zinc_quantity ///
    DQ_nickel_quantity if D_Q_Tornquist_nonrenewables != .

gen g_Q_NonRewnew_Tornquist = D_Q_Tornquist_nonrenewables - 1


// renewables index
local renew_resources q_urban prod_area land forest_area_km mangrove_ha b_e hp_gwh

foreach var of local renew_resources {
    gen DQ_`var'_exponentiated = DQ_`var'^(`var'_weight)
}

gen D_Q_Tornquist_renewables = ///
      DQ_q_urban_exponentiated ///
    * DQ_prod_area_exponentiated ///
    * DQ_land_exponentiated ///
    * DQ_forest_area_km_exponentiated ///
    * DQ_mangrove_ha_exponentiated ///
    * DQ_b_e_exponentiated ///
    * DQ_hp_gwh_exponentiated

sum D_Q_Tornquist_renewables ///
    DQ_q_urban DQ_prod_area DQ_land DQ_forest_area_km DQ_mangrove_ha DQ_b_e DQ_hp_gwh ///
    if D_Q_Tornquist_renewables != .

gen g_Q_Renew_Tornquist = D_Q_Tornquist_renewables - 1


save "$processed/tornqvist_panel.dta", replace


