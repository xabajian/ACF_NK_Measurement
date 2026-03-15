
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



* Install wbopendata if needed
capture which wbopendata
if _rc ssc install wbopendata, replace

clear all

* Download both indicators from WDI
wbopendata, indicator(NY.GDP.TOTL.RT.ZS;NY.ADJ.DRES.GN.ZS) long clear

* Keep only 2019
keep if year == 2019

* Keep relevant variables
keep countrycode  ny_gdp_totl_rt_zs ny_adj_dres_gn_zs 

* Rename variables
rename ny_gdp_totl_rt_zs resource_rents_gdp
rename ny_adj_dres_gn_zs resource_depletion_gni

* Drop aggregates (World, regions, income groups)
drop if missing(countrycode)
drop if strlen(countrycode) != 3

* Order variables nicely
order countrycode resource_rents_gdp resource_depletion_gni


* Save
save "$processed/wdi_resource_rents_2019.dta", replace

