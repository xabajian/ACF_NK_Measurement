************************************
* Wealth Accounts Updater          *
* Revised August 2024			    *
* Requires STATA 13.1 or higher     *
************************************

/* This master file specifies initial settings and parameters, successively 
calls all the .do files for each wealth component, and generates output files */

********************************************************************************
	
** INITIALIZATIONS **
clear
set checksum off, //permanently
//ssc install wbopendata, replace
version 13.1
set more off
set type double
set varabbrev on
*pause on

**** Set sortseed
set sortseed 180720
set seed     766371

* Root folder globals
* ----------------------

global home ""

/* Note: Only change the file path of the home directory above; do not change 
the following sub-directories, or else the updater will not run; make sure these
folders are created and organized properly before running the updater */

global input_user "${home}Input\User_update/" // input files to be updated by user 
global input_pre "${home}Input\Predefined/" // predefined input files (not updated)
global input_other "${home}Input\Other/"
global working "${home}Working/" // working data files
global working_other "${home}Working\Other/"
global output_archive "${home}Output\Archive/" // archive of time-stamped outputs
global output_latest "${home}Output\Latest/" // where final results are stored
global output_load "${home}Output\Load/" // load file for giving data to DECDG
global output_other "${home}Output\Other/"
global do "${home}Do/" // .do files
global analysis "${home}Analysis/"
global qa "${home}QA/"

global minerals "${origin}Minerals/"
global working_minerals "${working}minerals/"
global working_temp "${working}temp/"

cd "${working}" // set the working directory

* Create date and time stamp for output file names
global c_date = c(current_date)
global c_time = c(current_time)
global c_time_date = "$c_date" + "_" + "$c_time"
global time_string = subinstr("$c_time_date", ":", "_", .)
global time_string = subinstr("$time_string", " ", "_", .)

* STATA packages to install prior to use of wealth data updater
//ssc install wbopendata

//ssc install carryforward

//ssc install egenmore

//ssc install renvarlab
sysdir set PLUS "${do}ado"
********************************************************************************

** KEY PARAMETERS **

//For CWON 2024 we are moving from having all wealth account series in constant USD to all series in current USD, a volume-based measure of assets and a real-terms PPP measure of total wealth (i.e. only applied to aggregate values). For comparison to previous CWONs we will continue to produce the GDP deflator series, and outputs on our working files in both current and constant 2020 USD, however we will only publish series in current USD, volume-based and PPP units.

******************************
*Notes on the data: CWON 2024 no longer smoothes the rental rates over 5-year lagged intervals. 5yr smoothed variables are subscripted '5yr', otherwise variables are no longer smoothed.
*******************************

//For the reproducibility assessment by the internal DIME unit, we will remove the GDP deflators.

* Starting year of data
global base_year 1970

* Target year for which update is being performed
global target_year 2020

* Base year for the chained tornquist index
global chain_year 2019

* Base year for USD deflator (year in which constant USD are expressed) *Note the USD deflator series is based in 2015, but we want 2020 constant USD for our outputs*
global cousd_year 2020

* Base year for GDP in constant US$ at market prices in the WDI (NY.GDP.MKTP.KD)
global ny_gdp_mktp_kd_yr 2015

* Beginning year for constructing balanced data set (first year countries must have data to be included)
global balance_start 1995

* Ending year for balanced data set (last year countries must have data to be included)
global balance_end 2020

* Calendar year from which World Bank income classifications are based
global income_year 2020 // Note: FY16 classifications apply to data for 2014 calendar year

* Discount rate
global discount .04
global discount_low 0.02 //For experimental analysis of strong sustainability.

* Pure rate of time preference
global prtr .015

* Rystad data cut-off year (last year of observed data)
global rystad_latest_yr 2020

* Growth rate for crop returns in high-income countries
global crop_devd .0097

* Growth rate for crop returns in low- and middle-income countries
global crop_deving .0194

* Growth rate for pastureland returns in high-income countries (half of previous report)
global animal_devd .00445

* Growth rate for pastureland returns in low- and middle-income countries (half of previous report)
global animal_deving .01475

* Latest year in Penn World Table database (for produced capital)
global pwt_latest_yr 2019

* Lower tolerance, ratio reported gross capital formation (GCF) to GCF as calculated from national accounting identity
global gcf_low .7

* Upper tolerance, ratio reported gross capital formation (GCF) to GCF as calculated from national accounting identity
global gcf_high 1.3

* Base year for constant national prices in PWT data
global pwt_base 2017

* Ratio of value of urban land to total physical capital stock
global ushare .24

* Old year (for creating input files for subsequent years' updates)
global oldyear = $target_year + 1
global oldyear "${oldyear}"
global newold = $target_year + 2
global newold "${newold}"


********************************************************************************
** WEALTH AND ITS COMPONENTS **

// Note: Each component must be run successively.

* General macroeconomic data
do "${do}general.do" // general macroeconomic data (ANS) 
do "${do}general_gns_filled.do" // gap-filled GNS series 
do "${do}general_economy_r.do" // economy wide rate of return estimate used for the fossil fuel, metals and minerals rent estimates.

* Produced capital and urban land
do "${do}pk_urban.do" 
do "${do}pk.do" // produced capital estimates from Penn World Table  
do "${do}pk_gapfill.do" // alternative estimates for gap-filling, using CWON 2011 method. 

* Metals and minerals

//switch to usercost scripts and possibly change the script labels once approved by methodology adviser and TTL.
do "${do}mineral_cost_00_pink_sheet_price.do" // mineral prices
//do "{do}mineral_cost_01_metal_production_cost.do" 
do "${do}mineral_cost_01_metal_production_cost_usercost.do"
//mineral unit rents
//do "{do}mineral_cost_02_processing_SP_data.do" 
do "${do}mineral_cost_02_processing_SP_data_usercost.do" //mineral rent at country, regional, global level formatting
//do "${do}mineral_depletion.do" 
do "${do}mineral_depletion_usercost.do" // mineral depletion (ANS)
//do "${do}mineral_wealth.do" 
do "${do}mineral_wealth_usercost.do"

* Oil, gas and coal
*version 17.0
*do "${do}energy_oil_rystad.do" // produces end_oil_unit_cost_revenue_yearly_rystad.dta
*version 13.1

//do "${do}energy_oil_new.do"
do "${do}energy_oil_new_usercost_country_rr.do"
//do "${do}energy_gas_new.do"
do "${do}energy_gas_new_usercost_country_rr.do"
//do "${do}energy_coal_new.do"
do "${do}energy_coal_new_usercost_country_rr.do"

* Cropland and pastureland
do "${do}land.do"  

* Forest - timber values
do "${do}forest_timber_depletion.do" // net forest depletion (ANS) 
do "${do}forest_timber_wealth.do" 
do "${do}forest_timber_gapfill.do" // gap-filling 

* Forest - non-timber values 
do "${do}forest_nontimber.do" 

* Human capital
do "${do}human_capital.do" // ILO_employment.dta & cellsize.dta is created from separate human capital do-files // imports results of human capital estimates
do "${do}ilo_pwt.do" // produces "ilo_pwt_employment_sex.dta"

* Mangroves
do "${do}mangroves.do"

//add carbon retention mangroves
//renewable energy

* Fisheries 
do "${do}fisheries.do"

* Hydropower renewable energy 
do "${do}hydropower.do" 

* Carbon retention 
do "${do}carbon_retention.do" 

* Net foreign assets
version 17.0
do "${do}fa_fl.do"
version 13.1

* Tornqvist volume-based indices for all assets
do "${do}tornqvist_index_master.do" // compute the tornqvist NCWI 
do "${do}tornqvist_index_master_ss.do" // volume-based index with strong sustainability adjustments (lower discount rates on renewable capital)
do "${do}tornqvist_index_master_ss_rpc.do" 
do "${do}tornqvist_index_master_ss_rpc_c.do" 

do "${do}tornqvist_index_carbon.do" // compute the Tornqvist asset specific index for forest and mangrove carbon 



** OUTPUT FILES **
do "${do}output_wide.do" // creates Excel files for individual indicators (one indicator per file)
do "${do}output_general_wide.do" // general macro-economic data used in calculations
do "${do}output_data_dictionary.do" // dictionary of Excel files created by output_wide.do


/* Note: A complete alphabetical list of output files with data descriptions 
can be found in "Data Dictionary.xlsx" in the home directory. */