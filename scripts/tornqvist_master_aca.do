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

global home "/Users/xabajian/Desktop/Yale Postdoc/Eli Marc Final/FR_WLD_2024_195/Reproducibility package/"

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


******** TORNQVIST INDEX COMPUTATION *******************
******** CWON 2024 WEALTH COMPONENTS *******************
********** DRAFT May 22, 2024 *********************


/// STEP 1 - BUILD VOLUME VARIABLES OF EACH ASSET

* CATEGORIES:
* Net foreign assets
* Produced capital
* Renewable natural capital
* Nonrenewable natural capital
* Human capital


* CPI DATA

// 	import excel using "${input_pre}Final CPI data gapfilled.xlsx", clear firstrow case(lower)
// 	rename symbol countrycode
// 	keep countrycode year cpi2019100
// 	rename cpi2019100 cpi2019
// 	save "${working}cpi2019", replace
	

* PANEL BASE

	wbopendata, indicator(SP.POP.TOTL) clear long
	drop adminregion adminregionname lendingtype lendingtypename
	drop if region == "" | region == "NA"
	keep if year >=1995 & year <= 2020
	rename sp_pop_totl pop
	format countryname %25s

./* NET FOREIGN ASSETS
	
	* Asset: net foreign assets
	* Do-file: fa_fl_cwon2024.do
	* Variable: foreign assets (fa) and foreign liabilities (fl)
	* Source: Lane and Milessi-Ferreti
	* File with gapfilled estimates: fa_fl_filled.dta
	* Unit: US dollars
	* Observations: Used gapfilled CPI from WDI and Midsummer Analytics to deflate
	
// 	merge 1:1 countrycode year using "${working}cpi2019"
// 	drop if _merge==2
// 	drop _merge
// 	label var cpi2019 "Gapfilled CPI 2019=100, WDI plus gapfilling"

	merge 1:1 countrycode year using "${working}fa_fl_filled.dta", keepusing(fa fl)
	drop if _merge==2
	drop _merge
	rename fa fa_cd
	rename fl fl_cd
	
	* Drop the observations where FL exceed the value of ncwi. This will drop the value of ncwi for these years, but will avoid negative/zero wealth and unexplicable trends.
	foreach f in fa fl {
		replace `f'_cd = . if countrycode == "AGO" & year > 1994 & year < 2002
		replace `f'_cd = . if countrycode == "BGR" & year == 1995
		replace `f'_cd = . if countrycode == "BLR" & year > 1994 & year < 1999
		replace `f'_cd = . if countrycode == "COD" & year > 1994 & year < 2001
		replace `f'_cd = . if countrycode == "SDN" & year > 2011 & year < 2014
		replace `f'_cd = . if countrycode == "TUR" & year > 1994 & year < 1999
		replace `f'_cd = . if countrycode == "ZMB" & year > 1994 & year < 1997								
	}
	
	
	gen torn_real_fa = fa_cd / (cpi2019/100)
	gen torn_real_fl = fl_cd / (cpi2019/100)
	
	

	label var torn_real_fa "Foreign assets (real chained 2019 US dollars)"
	label var torn_real_fl "Foreign liabilities (real chained 2019 US dollars)"

*/
* PRODUCED CAPITAL


/*	
	* Asset: produced capital assets
	* Do-file: pk_filled.do
	* Variable: pk (Capital stock in chained 2019 dollars)
	* Source: PWT and WDI
	* File with gapfilled estimates: pk_filled.dta
	* Unit: US dollars
	* Observations: We don't have pure physical volumes for produced capital but we can estimate a chained index for fixed assets

	merge 1:1 countrycode year using "${working}pk_filled.dta", keepusing(q_pk) // we exclude pk as here we just include the quantity relative for tornqvist index computation
	drop if _merge==2
	drop _merge
	*label var pk "Produced capital assets (Capital stock at chained 2019 USD)"
	label var q_pk "Produced capital asset (excl. urban land) quantity relative"
*/

	* Asset: urban land
	* Do-file: pk_filled.do
	* Variable: urban_land_e (Urban land area)
	* Source: Center for International Earth Science Information Network (CIESIN) / Columbia University
	* File with gapfilled estimates: pk_filled.dta
	* Unit: US dollars
	* Observations: We don't have pure physical volumes for produced capital but we can estimate a chained index for fixed assets

	merge 1:1 countrycode year using "${working}pk_filled.dta", keepusing(q_urban) // we exclude urban area as here we just include the quantity relative for tornqvist index computation
	drop if _merge==2
	drop _merge
	*label var urban_area "Urban land area (sq. km)"
	label var q_urban "Urban land area quantity relative"


* RENEWABLE NATURAL CAPITAL	

{	
	* Asset: timber
	* Do-file: forest_timber_depletion.do
	* Variable: Productive area (prod_area)
	* Source: FAO FRA
	* Processing: line 563 - 601
	* File with gapfilled estimates: for_timber_gapfill.dta  
	* Unit: hectares
	* Observations: 

	merge 1:1 countrycode year using "${working}for_timber_gapfill", keepusing(prod_area)
	drop if _merge==2
	drop _merge
	label var prod_area "Productive forest area (hectares)"


	* Asset: agricultural land
	* Do-file: land.do
	* Variable: Crop and pasture land area (prod_area)
	* Source: FAO via WDI
	* Processing: line 1767-1921
	* File with gapfilled estimates: land_cropland_pasture_area.dta  
	* Unit: sq km
	* Observations: cropland and pastureland area are added up with same weight;
	* FAO provides stock of livestock measured in heads but rents are calculated using 
	* production in tonnes.

	merge 1:1 countrycode year using  "${working}land_cropland_pasture_area", keepusing(cropland pasture)
	drop if _merge==2
	drop _merge
	gen land = cropland + pasture
	label var land "Agricultural land area (km2)"
	drop cropland pasture
	
	
	* Asset: forest es
	* Do-file: forest_nontimber.do
	* Variable: accessible forest and nonwood forest products area
	* Source: IUCN
	* Processing: line 419-476
	* File with gapfilled estimates: for_nontimber_country_volume_shares.dta  
	* Unit: sq km
	* Observations: the predicted value reported is not conditional on forest 
	* being "active" for a particular service, but denotes expected value of 
	* that service "on average, per hectare of forest, by country". Estimates 
	* are derived by multiplying forest area by 1/y_it where yit is the fraction 
	* of forest applicable to each service in country i and year t.

* This corresponds to method 2 we are not using for this edition
/*	
	merge 1:1 countrycode year using  "${working}for_nontimber_country_volume_shares", keepusing(forest_area_km access_share nwfp_share)
	drop if _merge==2
	drop _merge
	gen accessible_area = forest_area_km * access_share
	gen nwfp_area = forest_area_km * nwfp_share
	label var accessible_area "Accessible forest area (km2)"	
	label var nwfp_area "Nonwood forest products area (km2)"
	drop forest_area_km access_share nwfp_share
*/

* This corresponds to method 1 we use for this edition

	merge 1:1 countrycode year using  "${working}for_nontimber_country_volume_shares", keepusing(forest_area_km)
	drop if _merge==2
	drop _merge
	label var forest_area_km "Total forest area in sq km (FAO)"

	
	* Asset: mangroves
	* Do-file: mangroves.do
	* Variable: mangroves area
	* Source: UCSC
	* Processing: n/a
	* File with gapfilled estimates: mangroves_total_value.dta  
	* Unit: hectares
	* Observations: TBA

	merge 1:1 countrycode year using  "${working}mangroves_total_value", keepusing(mangrove_ha)
	drop if _merge==2
	drop _merge
	label var mangrove_ha "Mangroves area (ha)"	
	
	
	* Asset: fish stock
	* Do-file: fisheries.do
	* Variable: biomass sustainable yield
	* Source: UBC
	* Processing: n/a
	* File with gapfilled estimates: fisheries_bbmsy_gapfilled.dta  
	* Unit: tons
	* Observations: Need to filter by health status 3 or 4

	merge 1:1 countrycode year using  "${working}fisheries_bbmsy_gapfilled", keepusing(b_e)
	drop if _merge==2
	drop _merge
	label var b_e "Sum of current biomass (tons)"	
	


	* Asset: renewable energy
	* Do-file: hydropower.do
	* Variable: electricity generation
	* Source: Midsummer Analytics
	* Processing: n/a
	* File with gapfilled estimates: hydropower_wealth.dta  
	* Unit: GWh
	* Observations: TBA

	merge 1:1 countrycode year using  "${working}hydropower_wealth", keepusing(hp_gwh)
	drop if _merge==2
	drop _merge
	label var hp_gwh "Electricity generation (GWh)"	
	
}

* NONRENEWABLE NATURAL CAPITAL	

{
	* Asset: oil
	* Do-file: energy_oil_new_usercost.do
	* Variable: reserves_oil
	* Source: BP, US EIA
	* Processing: n/a
	* File with gapfilled estimates: end_oil_reserves.dta  
	* Unit: barrels
	* Observations: In previous CWON reports time to depletion is gapfilled for countries without reserve data using regional production and reserve numbers from BP. This extra gapfilling is not reasonable in the case we use direct reserves in a volume index.


	merge 1:1 countrycode year using  "${working}end_oil_reserves_fill.dta", keepusing(reserves_oil)
	drop if _merge==2
	drop _merge
	label var reserves_oil "Proven reserves of oil (barrels)"
/*
	gsort countrycode year
	bys countrycode : replace reserves_oil = reserves_oil[_n-1] if mi(reserves_oil)
	gsort countrycode -year
	bys countrycode : replace reserves_oil = reserves_oil[_n-1] if mi(reserves_oil)
	gsort countrycode year
*/
	
	* Asset: gas
	* Do-file: energy_gas_new_usercost.do
	* Variable: reserves_gas
	* Source: BP, US EIA
	* Processing: n/a
	* File with gapfilled estimates: end_gas_reserves.dta  
	* Unit: Terajoules (TJ)
	* Observations: TBA


	merge 1:1 countrycode year using "${working}end_gas_reserves_fill.dta", keepusing(reserves_gas)
	drop if _merge==2
	drop _merge
	label var reserves_gas "Proven reserves of natural gas (TJ)"
/*
	gsort countrycode year
	bys countrycode : replace reserves_gas = reserves_gas[_n-1] if mi(reserves_gas)
	gsort countrycode -year
	bys countrycode : replace reserves_gas = reserves_gas[_n-1] if mi(reserves_gas)
	gsort countrycode year
*/


	* Asset: coal
	* Do-file: energy_coal_new_usercost_country_rr.do
	* Variable: res_coal
	* Source: EI, IEA, US EIA, German BGR
	* Processing: n/a
	* File with gapfilled estimates: end_coal_reserves.dta  
	* Unit: tons
	* Observations: TBA


	merge 1:1 countrycode year using  "${working}end_coal_fill.dta", keepusing(res_coal)
	drop if _merge==2
	drop _merge
	label var res_coal "Proven reserves of coal (tons)"
/*	
	gsort countrycode year
	bys countrycode : replace res_hard = res_hard[_n-1] if mi(res_hard)
	gsort countrycode -year
	bys countrycode : replace res_hard = res_hard[_n-1] if mi(res_hard)
	gsort countrycode year
*/


	* Asset: bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium
	* Do-file: mineal_depletion_usercost.do
	* Variable: reserves_bauxite
	* Source: USGS
	* Processing: n/a
	* File with gapfilled estimates: min_reserves.dta  
	* Unit: tons
	* Observations: Reserves data is not gapfilled - it has incomplete sereies that need to be gapfilled by duplicating the nearest value 


	local mineral bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium
	
	foreach m of local mineral {
		merge 1:1 countrycode year using  "${working}min_reserves_fill.dta", keepusing(reserves_`m')
		drop if _merge==2
		drop _merge
		label var reserves_`m' "Proven reserves of `m' (tons)"
		
		gsort countrycode year
		bys countrycode : replace reserves_`m' = reserves_`m'[_n-1] if mi(reserves_`m')
		gsort countrycode -year
		bys countrycode : replace reserves_`m' = reserves_`m'[_n-1] if mi(reserves_`m')
		gsort countrycode year

	}
	
}

* HUMAN CAPITAL	

	* Asset: human capital
	* Do-file: human_capital.do and ilo_pwt.do
	* Variable: ilo_emp_female ilo_emp_male ilo_self_female ilo_self_male
	* Source: ILO, I2D2 and PWT
	* Processing: n/a
	* File with gapfilled estimates: ilo_employment_sex.dta  
	* Unit: thousand people
	* Observations: TBA
	
	*merge 1:1 countrycode year using  "${working}ilo_employment_sex.dta", keepusing(emp_ilofemales emp_ilomales) // This is pre-correction version of the HC volume
	*drop if _merge==2
	*drop _merge

	merge 1:1 countrycode year using  "${working}ilo_pwt_employment_sex.dta", keepusing(emp_ilofemales_hc emp_ilomales_hc)
	drop if _merge==2
	drop _merge
	
	save "${working}assets_volume_variables", replace


/// STEP 2 - OBTAIN ASSETS VALUE SHARE IN NOMINAL WEALTH

* PANEL BASE


	wbopendata, indicator(SP.POP.TOTL) clear long

	drop adminregion adminregionname lendingtype lendingtypename
	keep if year >= ${balance_start} & year <= ${balance_end}
	rename sp_pop_totl pop
	drop if region == "NA" | region == ""
	format countryname %30s
	

	*use "${working}panel_base", clear											// use when WB system is down

* PRODUCED CAPITAL	
	

	merge 1:1 countrycode year using "${working}pk_filled.dta", keepus(pk_cd urban_cd pk_tot_cd) //pk_tot is total nominal value of produced capital including urban land
	tab countryname if _merge==1
	tab countrycode if _merge==2
	drop if _merge==2	// dropping extra years beyond 1995-2020
	drop _merge
	
	
	* Shares in produced capital // according to the Computation of Tornqvist Index formula following Kunte et al (1998) estimates, the share in wealth of PK equals 1/1.24 and the share for urban equals 0.24/1.24
/*	
	local var pk urban
	
	foreach v of local var{
	    gen `v'_share = `v'_cd / pk_tot
	}
*/

	


* RENEWABLE NATURAL CAPITAL

{
	* Forest timber

	merge 1:1 countrycode year using "${working}for_total_rent_smooth_gapfill.dta", keepus(forestwealth_cd)
	tab countryname if _merge==1
	tab countrycode if _merge==2
	drop if _merge==2	
	drop _merge	
	rename forestwealth_cd timber_cd
	
	* Agricultural land

	merge 1:1 countrycode year using "${working}land_crop_wealth_fixed_growth_smooth.dta", keepus(cropwealth_cd)
	tab countryname if _merge==1
	tab countrycode if _merge==2
	drop if _merge==2	
	drop _merge	
	
	
	merge 1:1 countrycode year using "${working}land_animal_wealth_fixed_growth_smooth.dta", keepus(animalwealth_cd)
	tab countryname if _merge==1
	tab countrycode if _merge==2
	drop if _merge==2	
	drop _merge	
	
	gen agland_cd = cropwealth_cd + animalwealth_cd
	
	* Mangroves

	merge 1:1 countrycode year using "${working}mangroves_total_value.dta", keepus(pv_mangroves_cd)
	tab countryname if _merge==1
	tab countryname if _merge==2
	drop if _merge==2	// dropping extra years beyond 1995-2020 and territories
	drop _merge
	rename pv_mangroves_cd mangroves_cd
	
	* Forest ES 


	merge 1:1 countrycode year using "${working}for_nontim_total_value.dta", keepus(pv_ecovalue_rec_cd pv_ecovalue_nwfp_cd pv_ecovalue_water_cd)
	tab countryname if _merge==1
	tab countryname if _merge==2
	drop if _merge==2	// dropping extra years beyond 1995-2020 and territories
	drop _merge
	
	rename pv_ecovalue_rec_cd forest_es1_cd 
	rename pv_ecovalue_nwfp_cd forest_es2_cd 
	rename pv_ecovalue_water_cd forest_es3_cd
	
	
* This corresponds to method 2 that is not used in this edition	
/*
	merge 1:1 countrycode year using  "${working}for_nontimber_country_volume_shares", keepusing(access_share nwfp_share)
	tab countryname if _merge==1
	tab countryname if _merge==2
	drop if _merge==2	// dropping extra years beyond 1995-2020 and territories
	drop _merge
	
	gen forest_es1_cd = pv_ecovalue_rec_cd * 1/access_share
	gen forest_es2_cd = pv_ecovalue_nwfp_cd * 1/nwfp_share
	gen forest_es3_cd = pv_ecovalue_water_cd * 1/access_share
	
	drop pv_ecovalue_rec_cd pv_ecovalue_nwfp_cd pv_ecovalue_water_cd access_share nwfp_share
*/
	

	* Fisheries

	merge 1:1 countrycode year using "${working}fisheries_total_value.dta", keepus(fisheries_cd)
	tab countryname if _merge==1
	tab countryname if _merge==2
	drop if _merge==2	// dropping extra years beyond 1995-2020 and territories
	drop _merge
	

	* Renewable energy 

	merge 1:1 countrycode year using "${working}hydropower_wealth.dta", keepus(hp_cd)
	tab countryname if _merge==1
	tab countryname if _merge==2
	drop if _merge==2	// dropping extra years beyond 1995-2020 and territories
	drop _merge
	rename hp_cd hydro_cd	
	
	
	* Renewable natural capital
	
	egen renew_cd = rowtotal(timber_cd agland_cd mangroves_cd forest_es1_cd forest_es2_cd forest_es3_cd fisheries_cd hydro_cd), missing
	
	* Shares in renewable natural capital 
	
	local var timber agland mangroves forest_es1 forest_es2 forest_es3 fisheries hydro 
	
	foreach v of local var{
	    gen `v'_share = `v'_cd / renew_cd
	}

		
	
}	
	
* NONRENEWABLE NATURAL CAPITAL	

{	
	* Oil

	merge 1:1 countrycode year using "${working}end_oil_wealth_depletion_usercostadj.dta", keepus(wealth_oil_cd)
	tab countryname if _merge==1
	tab countryname if _merge==2
	drop if _merge==2	// dropping extra years beyond 1995-2020 and territories
	drop _merge
	rename wealth_oil_cd oil_cd	
	
	
	* Gas

	merge 1:1 countrycode year using "${working}end_gas_wealth_depletion_usercostadj.dta", keepus(wealth_gas_cd)
	tab countryname if _merge==1
	tab countryname if _merge==2
	drop if _merge==2	// dropping extra years beyond 1995-2020 and territories
	drop _merge
	rename wealth_gas_cd gas_cd	
	
	
	* Coal

	merge 1:1 countrycode year using "${working}end_coal_wealth_depletion_usercost.dta", keepus(wealth_coal_cd)
	tab countryname if _merge==1
	tab countryname if _merge==2
	drop if _merge==2	// dropping extra years beyond 1995-2020 and territories
	drop _merge
	rename wealth_coal_cd coal_cd
	
	
	* Minerals

	merge 1:1 countrycode year using "${working}min_wealth_smooth_usercost.dta", ///
	keepus(wealth_bauxite_uc_cd wealth_copper_uc_cd wealth_gold_uc_cd wealth_iron_ore_uc_cd ///
	wealth_lead_uc_cd wealth_nickel_uc_cd wealth_phosphate_uc_cd wealth_silver_uc_cd wealth_tin_uc_cd ///
	wealth_zinc_uc_cd wealth_cobalt_uc_cd wealth_molybdenum_uc_cd wealth_lithium_uc_cd)
	
	tab countryname if _merge==1
	tab countryname if _merge==2
	drop if _merge==2	// dropping extra years beyond 1995-2020 and territories
	drop _merge
	
	local mineral bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium
	
	foreach m of local mineral {	
		rename wealth_`m'_uc_cd `m'_cd
	}

	
	
	**************************************
	****** GAPFILLING SECTION
	***********************************
/*	
	local asset oil gas hard brwn bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium
	
	foreach a of local asset{
	
	bys countrycode : ipolate `a'_cd year, gen(`a'_cd_e) e
	
	* When nominal interpolated values drop below zero (i.e. minerals), convert to zero
	replace `a'_cd_e = 0 if `a'_cd_e < 0
	drop `a'_cd
	rename `a'_cd_e `a'_cd
	}	
*/		


	

	* NonRenewable natural capital
	
	egen nonrenew_cd = rowtotal(oil_cd gas_cd coal_cd bauxite_cd copper_cd gold_cd iron_ore_cd ///
	lead_cd nickel_cd phosphate_cd silver_cd tin_cd zinc_cd cobalt_cd molybdenum_cd lithium_cd), missing
	
	egen min_cd = rowtotal(bauxite_cd copper_cd gold_cd iron_ore_cd ///
	lead_cd nickel_cd phosphate_cd silver_cd tin_cd zinc_cd cobalt_cd molybdenum_cd lithium_cd), missing
	
	* Shares in nonrenewable natural capital 
	
	local var oil gas coal bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium 
	
	foreach v of local var{
	    gen `v'_share = `v'_cd / nonrenew_cd
	}
	
	local var bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium 
	
	foreach v of local var{
	    gen `v'_min_share = `v'_cd / min_cd
	}
	
}	

* HUMAN CAPITAL



	merge 1:1 countrycode year using "${working}hc.dta", keepus(hc_emp_females_cd hc_emp_males_cd hc_self_females_cd hc_self_males_cd)
	
	tab countryname if _merge==1
	tab countryname if _merge==2
	drop if _merge==2	// dropping extra years beyond 1995-2020 and territories
	drop _merge	
	
	/*
	local asset hc_emp_females hc_self_females hc_emp_males hc_self_males
	
	foreach a of local asset{
	
	bys countrycode : ipolate `a'_cd year, gen(`a'_cd_e) e
	
	* When nominal interpolated values drop below zero (i.e. minerals), convert to zero
	replace `a'_cd_e = 0 if `a'_cd_e < 0
	drop `a'_cd
	rename `a'_cd_e `a'_cd
	}
	*/	
	
	egen emp_female_cd = rowtotal(hc_emp_females_cd hc_self_females_cd), missing
	egen emp_male_cd = rowtotal(hc_emp_males_cd hc_self_males_cd), missing
	
	egen hc_cd = rowtotal(emp_female_cd emp_male_cd), missing
	
	gen emp_female_share = emp_female_cd / hc_cd
	gen emp_male_share = emp_male_cd / hc_cd

	/*
	gen self_female_share = self_female_cd / hc_cd
	gen self_male_share = self_male_cd / hc_cd
	*/

	* Verify which countries have missing nominal data or incomplete series
	tab countrycode if pk_cd == .
	tab countrycode if pk_tot_cd == .
	tab countrycode if urban_cd == .
	tab countrycode if timber_cd == . 
	tab countrycode if cropwealth_cd == .
	tab countrycode if animalwealth_cd == .
	tab countrycode if agland_cd == .
	tab countrycode if mangroves_cd == .
	tab countrycode if forest_es3_cd == .
	tab countrycode if forest_es1_cd == .
	tab countrycode if forest_es2_cd == .
	tab countrycode if fisheries_cd == .
	tab countrycode if hydro_cd == .
	tab countrycode if renew_cd == .
	tab countrycode if oil_cd == .
	tab countrycode if gas_cd == .
	tab countrycode if coal_cd == .
	tab countrycode if bauxite_cd == .
	tab countrycode if copper_cd == .
	tab countrycode if gold_cd == .
	tab countrycode if iron_ore_cd == .
	tab countrycode if lead_cd == .
	tab countrycode if nickel_cd == .
	tab countrycode if phosphate_cd == .
	tab countrycode if silver_cd == .
	tab countrycode if tin_cd == .
	tab countrycode if zinc_cd == .
	tab countrycode if cobalt_cd == .
	tab countrycode if molybdenum_cd == .
	tab countrycode if lithium_cd == .
	tab countrycode if nonrenew_cd == .
	tab countrycode if emp_female_cd == .
	tab countrycode if emp_male_cd == .
	tab countrycode if hc_cd == .


	* Gapfilling nominal values using linear interpolation to have complete nominal series series
	
	*local asset renew timber agland mangroves forest_es1 forest_es2 forest_es3 fisheries hydro
	
	/*
	foreach a of local asset{
	
	bys countrycode : ipolate `a'_cd year, gen(`a'_cd_e) e
	
	* When nominal interpolated values drop below zero (i.e. minerals), convert to zero
	replace `a'_cd_e = 0 if `a'_cd_e < 0
	drop `a'_cd
	rename `a'_cd_e `a'_cd
	}
	*/

	save "${working}assets_wealth_shares", replace

	
	

/// STEP 3 - COMBINE QUANTITIES WITH WEALTH SHARES

	use "${working}assets_volume_variables", clear
	merge 1:1 countrycode year using "${working}assets_wealth_shares"
	drop _merge

	
	format countrycode %4s


/// STEP 4 - COMPUTE QUANTITY RELATIVE (qt / qt-1)

	order q_urban q_pk, after(lithium_share)

	gsort countrycode year
	bys countrycode : gen q_timber = prod_area / prod_area[_n-1]
	
	gsort countrycode year
	bys countrycode : gen q_agland = land / land[_n-1]
	
	gsort countrycode year
	bys countrycode : gen q_mangroves = mangrove_ha / mangrove_ha[_n-1]
	
	gsort countrycode year
	bys countrycode : gen q_forest_es1 = forest_area_km / forest_area_km[_n-1]

	gsort countrycode year
	bys countrycode : gen q_forest_es2 = forest_area_km / forest_area_km[_n-1]

	gsort countrycode year
	bys countrycode : gen q_forest_es3 = forest_area_km / forest_area_km[_n-1]


	gsort countrycode year
	bys countrycode : gen q_fisheries = b_e / b_e[_n-1]
	
	gsort countrycode year
	bys countrycode : gen q_hydro = hp_gwh / hp_gwh[_n-1]
	
	gsort countrycode year
	bys countrycode : gen q_oil = reserves_oil / reserves_oil[_n-1]
	
	gsort countrycode year
	bys countrycode : gen q_gas = reserves_gas / reserves_gas[_n-1]
	
	gsort countrycode year
	bys countrycode : gen q_coal = res_coal / res_coal[_n-1]
	
	
	
	local mineral bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium
	
	foreach m of local mineral{
	   	gsort countrycode year
		bys countrycode : gen q_`m' = reserves_`m' / reserves_`m'[_n-1] 
	}
	
		gsort countrycode year
		bys countrycode : gen q_emp_female = emp_ilofemales_hc / emp_ilofemales_hc[_n-1]
		
		gsort countrycode year
		bys countrycode : gen q_emp_male = emp_ilomales_hc / emp_ilomales_hc[_n-1]


	/*
	gsort countrycode year
	bys countrycode : gen q_self_female = ilo_self_female / ilo_self_female[_n-1]
	
	gsort countrycode year
	bys countrycode : gen q_self_male = ilo_self_male / ilo_self_male[_n-1]	
	*/	


/// STEP 5 - COMPUTE TORNQVIST WEIGHT (theta)

	local asset timber agland mangroves forest_es1 forest_es2 forest_es3 fisheries hydro ///
	oil gas coal bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium ///
	emp_female emp_male // pk urban 

	foreach a of local asset {
	    bys countrycode : gen s_`a' = (`a'_share + `a'_share[_n-1]) / 2
	}

	
	foreach a in bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium {
		bys countrycode : gen s_min_`a' = (`a'_min_share + `a'_min_share[_n-1]) / 2
	}

/// STEP 6 - COMPUTE WEIGHTED TORNQVIST WEIGHTED QUANTITY RELATIVE

	local asset timber agland mangroves forest_es1 forest_es2 forest_es3 fisheries hydro ///
	oil gas coal bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium ///
	emp_female emp_male // pk urban												

	foreach a of local asset {
	    gen torn_`a' = q_`a' ^ s_`a'
	}

	foreach a in bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium {
		 gen torn_min_`a' = q_`a' ^ s_min_`a'
	}
	
	* Produced capital and urban land shares are determined by the Kunte et al. (1998) 
	gen torn_pk = q_pk ^ (1 / 1 + ${ushare})
	gen torn_urban = q_urban ^ ( ${ushare} / 1 + ${ushare})

	
/// STEP 7 - COMPUTE CHAINED ASSET SPECIFIC QUANTITY RELATIVE

	local asset timber agland mangroves forest_es1 forest_es2 forest_es3 fisheries hydro ///
	oil gas coal bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium ///
	emp_female emp_male

	foreach a of local asset {
	    gsort countrycode -year	
	    gen torn_ch_`a' = 100 if year == 2019 
		
		forval i = 2018(-1)1995 {
		replace torn_ch_`a' = torn_ch_`a'[_n-1] / q_`a'[_n-1] if missing(torn_ch_`a') ///
		& year == `i' & countrycode == countrycode[_n-1] 						// series sorted in reverse order to compute from 2018 to 1995
		}
		
		replace torn_ch_`a' = torn_ch_`a'[_n+1] * q_`a' if year == 2020 & countrycode == countrycode[_n+1]
		
	gsort countrycode year
	
	}
		

/// STEP 8 - COMPUTE ASSET SPECIFIC VOLUME-BASED REAL WEALTH	

	gsort countrycode year
	
	local asset timber agland mangroves forest_es1 forest_es2 forest_es3 fisheries hydro ///
	emp_female emp_male

	foreach a of local asset {
	   	gsort countrycode year
	  	gen `a'_cd_2019 = `a'_cd if year == 2019 & q_`a' != .
		bys countrycode (`a'_cd_2019) : replace `a'_cd_2019 = `a'_cd_2019[_n-1] if mi(`a'_cd_2019)
		
		gsort countrycode year
		gen torn_real_`a' = `a'_cd_2019
		replace torn_real_`a' = torn_ch_`a' * `a'_cd_2019 / 100  if year != 2019
		
	}
	
{
	* Step 8b - apply macro-adjustments for nonrenewables 
	
	merge 1:1 countrycode year using "${working}general_gdp_deflator.dta", keep(3) keepus(d2014 d2015 d2016 d2017 d2018 d2020) nogen norep
	
	local asset oil gas coal bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium

	foreach a of local asset {
	   	gsort countrycode year
	  	gen `a'_cd_2019 = `a'_cd if year == 2019 & q_`a' != .
		
		// Macroadjustment to deal with zero rents in 2019
		by countrycode: replace `a'_cd_2019 = `a'_cd[_n-1] /d2018 if year == 2019 ///
		& `a'_cd_2019 == 0 & q_`a' != .
		by countrycode: replace `a'_cd_2019 = `a'_cd[_n+1] /d2020 if year == 2019 ///
		& `a'_cd_2019 == 0 & q_`a' != .
		by countrycode: replace `a'_cd_2019 = `a'_cd[_n-2] /d2017 if year == 2019 ///
		& `a'_cd_2019 == 0 & q_`a' != .
		by countrycode: replace `a'_cd_2019 = `a'_cd[_n-3] /d2016 if year == 2019 ///
		& `a'_cd_2019 == 0 & q_`a' != .
		//by countrycode: replace `a'_cd_2019 = `a'_cd[_n-4] /d2015 if year == 2019 ///
		//& `a'_cd_2019 == 0 & q_`a' != .
		//by countrycode: replace `a'_cd_2019 = `a'_cd[_n-5] /d2014 if year == 2019 ///
		//& `a'_cd_2019 == 0 & q_`a' != .
		
		bys countrycode (`a'_cd_2019) : replace `a'_cd_2019 = `a'_cd_2019[_n-1] if mi(`a'_cd_2019)

		gsort countrycode year
		gen torn_real_`a' = `a'_cd_2019
		replace torn_real_`a' = torn_ch_`a' * `a'_cd_2019 / 100  if year != 2019
	}
	drop d2014 d2015 d2016 d2017 d2018 d2020
	
}	

/// STEP 9 - COMPUTE UNCHAINED TORNQVIST INDEX FOR EACH WEALTH CATEGORY


	local asset timber agland mangroves forest_es1 forest_es2 forest_es3 fisheries hydro ///
	oil gas coal bauxite copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum lithium ///
	emp_female emp_male
	
	foreach a of local asset{
	    replace torn_`a' = 1 if mi(torn_`a')									// There are assets with missing torn values due to missing q_t/q_t+1 and converted to 1 to avoid multiplying by missing
	}
	
	gen torn_unch_pk = torn_pk * torn_urban

	gen torn_unch_renew =  torn_timber * torn_agland  * torn_mangroves * ///
	torn_forest_es1 * torn_forest_es2 * torn_forest_es3 * torn_fish * torn_hydro

	gen torn_unch_min = torn_min_bauxite * ///
	torn_min_copper * torn_min_gold * torn_min_iron_ore * torn_min_lead * torn_min_lead * torn_min_nickel * ///
	torn_min_phosphate * torn_min_silver * torn_min_tin * torn_min_zinc * torn_min_cobalt * torn_min_molybdenum * torn_min_lithium
	
	gen torn_unch_nonrenew = torn_oil * torn_gas * torn_coal * torn_bauxite * ///
	torn_copper * torn_gold * torn_iron_ore * torn_lead * torn_lead * torn_nickel * ///
	torn_phosphate * torn_silver * torn_tin * torn_zinc * torn_cobalt * torn_molybdenum * torn_lithium
	
	
	gen torn_unch_hc = torn_emp_female * torn_emp_male

	
/// STEP 10 - COMPUTE CHAINED TORNQVIST INDEX FOR EACH WEALTH CATEGORY
	
	local category pk renew min nonrenew hc
	
	foreach c of local category{
	    gsort countrycode -year
	    gen torn_ch_`c' = 100 if year == 2019
		
		forval i = 2018(-1)1995 {
		    replace torn_ch_`c' = torn_ch_`c'[_n-1] / torn_unch_`c'[_n-1] if missing(torn_ch_`c') ///
			& year == `i' & countrycode == countrycode[_n-1] 						// series sorted in reverse order to compute from 2019 to 1995
		}

		replace torn_ch_`c' = torn_ch_`c'[_n+1] * torn_unch_`c' if year == 2020 & countrycode == countrycode[_n+1]
	}
	
	gsort countrycode year
	
/// STEP 11 - COMPUTE REAL WEALTH BASED ON CHAINED TORNQVIST

	gen pk_only_cd = pk_cd
	replace pk_cd = pk_tot_cd
	
	local category pk renew min nonrenew hc
	
	foreach c of local category{
		gsort countrycode year
		gen `c'_cd_2019 = `c'_cd if year == 2019
		bys countrycode (`c'_cd_2019) : replace `c'_cd_2019 = `c'_cd_2019[_n-1] if mi(`c'_cd_2019)	
		gen torn_real_`c' = torn_ch_`c' * `c'_cd_2019 / 100
	  
	}
	
	replace pk_cd = pk_only_cd 
	drop pk_only_cd
	
	gsort countrycode year
	
	
	foreach var of varlist fa_cd-torn_real_nonrenew{
		format `var' %20.0fc
	}
	

/// STEP 12 - COMPUTE SHARES IN TOTAL WEALTH
	
	egen totwealth_cd = rowtotal(pk_tot_cd nonrenew_cd renew_cd hc_cd fa_cd), missing
	
	local category pk_tot nonrenew renew hc fa
	
	foreach c of local category{
	    gen `c'_share = `c'_cd / totwealth_cd
	}
		
	

/// STEP 13 - COMPUTE COMPREHENSIVE WEALTH TORNQVIST WEIGHT (theta)

	local category pk_tot nonrenew renew hc fa 

	foreach c of local category {
	    gsort countrycode year	    
	    bys countrycode : gen s_`c' = (`c'_share + `c'_share[_n-1]) / 2
	}
	 


/// STEP 14 - COMPUTE unchained comprehensive wealth Törnqvist volume index

	rename torn_ch_pk torn_ch_pk_tot

	local category pk_tot nonrenew renew hc

	foreach c of local category {
	    gsort countrycode year
	    bys countrycode : gen q_tw_`c' = torn_ch_`c' / torn_ch_`c'[_n-1]
	}

	gsort countrycode year
	bys countrycode : gen q_tw_fa = torn_real_fa / torn_real_fa[_n-1]
	
	gsort countrycode year
	bys countrycode : gen q_tw_fl = torn_real_fl / torn_real_fl[_n-1]

	
	local category pk_tot nonrenew renew hc fa

	foreach c of local category {
	    gsort countrycode year
	    bys countrycode : gen torn_unch_tw_`c' = q_tw_`c' ^ s_`c'
	}
			
	
	gsort countrycode year
	bys countrycode : gen torn_unch_tw_fl = q_tw_fl	
	
	local category torn_unch_tw_pk_tot torn_unch_tw_nonrenew torn_unch_tw_renew torn_unch_tw_hc torn_unch_tw_fa

	foreach c of local category{
	    replace `c' = 1 if mi(`c')									// There are categories with missing torn values due to missing q_t/q_t+1 and converted to 1 to avoid multiplying by missing
	}
	
	gen torn_unch_dcw = torn_unch_tw_pk_tot * torn_unch_tw_nonrenew * torn_unch_tw_renew * torn_unch_tw_hc
	gen torn_unch_tw = torn_unch_tw_pk_tot * torn_unch_tw_nonrenew * torn_unch_tw_renew * torn_unch_tw_hc * torn_unch_tw_fa
	
	 

/// STEP 15a - COMPUTE chained national comprehensive wealth Törnqvist volume index
	
	gsort countrycode -year
	gen torn_ch_tw = 100 if year == 2019
	
	forval i = 2018(-1)1995 {
		replace torn_ch_tw = torn_ch_tw[_n-1] / torn_unch_tw[_n-1] if missing(torn_ch_tw) ///
		& year == `i' & countrycode == countrycode[_n-1] 						// series sorted in reverse order to compute from 2018 to 1995
	}
	
	replace torn_ch_tw = torn_ch_tw[_n+1] * torn_unch_tw if year == 2020 & countrycode == countrycode[_n+1]
	
	
	gsort countrycode -year
	gen torn_ch_tw_fl = 100 if year == 2019	
	
	forval i = 2018(-1)1995 {
		replace torn_ch_tw_fl = torn_ch_tw_fl[_n-1] / torn_unch_tw_fl[_n-1] if missing(torn_ch_tw_fl) ///
		& year == `i' & countrycode == countrycode[_n-1] 						// series sorted in reverse order to compute from 2018 to 1995
	}
	
	replace torn_ch_tw_fl = torn_ch_tw_fl[_n+1] * torn_unch_tw_fl if year == 2020 & countrycode == countrycode[_n+1]

	
/// STEP 15b - COMPUTE domestic chained comprehensive wealth Törnqvist volume index
	
	gsort countrycode -year
	gen torn_ch_dcw = 100 if year == 2019
	
	forval i = 2018(-1)1995 {
		replace torn_ch_dcw = torn_ch_dcw[_n-1] / torn_unch_dcw[_n-1] if missing(torn_ch_dcw) ///
		& year == `i' & countrycode == countrycode[_n-1] 						// series sorted in reverse order to compute from 2018 to 1995
	}
	
	replace torn_ch_dcw = torn_ch_dcw[_n+1] * torn_unch_dcw if year == 2020 & countrycode == countrycode[_n+1]
	
	

/// STEP 16 - COMPUTE real estimates of comprehensive wealth	

	gsort countrycode year
	gen fl_cd_2019 = fl_cd if year == 2019
	bys countrycode (fl_cd_2019) : replace fl_cd_2019 = fl_cd_2019[_n-1] if mi(fl_cd_2019)	
	gen torn_real_tw_fl = torn_ch_tw_fl * fl_cd_2019 / 100
	
	gsort countrycode year
		
	gen totwealth_cd_2019 = totwealth_cd if year == 2019
	bys countrycode (totwealth_cd_2019) : replace totwealth_cd_2019 = totwealth_cd_2019[_n-1] if mi(totwealth_cd_2019)	
	
	gen ncw_cd = totwealth_cd - fl_cd 
	gen ncwi = ncw_cd if year == 2019
	replace ncwi = (torn_ch_tw * totwealth_cd_2019 / 100) - (torn_ch_tw_fl * fl_cd_2019 / 100) if year != 2019
	
	
	gen dcw_cd = ncw_cd - fa_cd + fl_cd
	gen dcw_cd_2019 = dcw_cd if year == 2019
	bys countrycode (dcw_cd_2019) : replace dcw_cd_2019 = dcw_cd_2019[_n-1] if mi(dcw_cd_2019)	
	
	gen dcwi = dcw_cd if year == 2019
	replace dcwi = (torn_ch_dcw * dcw_cd_2019 / 100) if year != 2019
		
	gsort countrycode year
	replace ncwi = 0 if ncwi < 0
	
	save "${working}real_wealth_chained_tornqvist_unbalanced.dta", replace
	
	
	
/// STEP 17 - REPLACE MISSING VALUES FOR ZEROS IN SELECTED COUNTRIES

	replace torn_real_timber = 0 if countrycode == "QAT"  						// Qatar has zero productive forest. It goes missing because qt/qt-1 goes to infinitum
	
	replace torn_real_forest_es1 = 0 if torn_real_forest_es1 == .				// Assume forest ES are zero if missing
	replace torn_real_forest_es2 = 0 if torn_real_forest_es2 == .
	replace torn_real_forest_es3 = 0 if torn_real_forest_es3 == .
	
		
	replace torn_real_hydro = 0 if torn_real_hydro == . & ///					// Assume that missing hydropower equals to zero except in countries with incomplete series
	countrycode != "BLZ" & ///
	countrycode != "KHM" & ///
	countrycode != "LSO" & ///
	countrycode != "SLE" 
	
	replace torn_real_mangroves = 0 if torn_real_mangroves == .					// Assume landlocked countries and missing mangroes wealth equal to zero
		
	replace torn_real_fisheries = 0 if torn_real_fisheries == .					// Assume landlocked countries and countries with missing data have 
																				// fisheries wealth equal to zero but check which countries go missing due to missing CPI

	
* Check countries that have missing values

	local var pk fa fl renew timber agland mangroves forest_es1 forest_es2 forest_es3 fisheries hydro hc emp_female emp_male
	
	foreach v of local var{
	    gen `v'_missing = mi(torn_real_`v')
	}
	
	
	egen sum_missing = rowtotal(pk_missing fa_missing fl_missing renew_missing timber_missing ///
	agland_missing mangroves_missing forest_es1_missing forest_es2_missing ///
	forest_es3_missing fisheries_missing hydro_missing hc_missing emp_female_missing ///
	emp_male_missing)
	
	gen sum_missing_dummy = sum_missing > 0
	
	bys countrycode : egen unbalanced = sum(sum_missing_dummy)
	gsort countrycode year
	
	replace unbalanced = 26 if countrycode == "TLS"							// Timor Leste has missing PK 1995-2018
	
	keep if unbalanced == 26
	
	tab countryname
		
	gen unbalanced_country = 1
	
	save "${working}CWON24_unbalanced_countries.dta", replace

	
	
/// STEP 18 - KEEP COUNTRIES WITH DATA FOR ALL ASSETS AND REPLACE MISSING VALUES FOR ZEROS IN SELECTED COUNTRIES
	
	use "${working}real_wealth_chained_tornqvist_unbalanced.dta", clear
	
	merge 1:1 countrycode year countrycode using "${working}CWON24_unbalanced_countries.dta", keepus(unbalanced_country)
	drop _merge
	drop if unbalanced_country == 1
	
	replace torn_real_timber = 0 if countrycode == "QAT"  						// Qatar has zero productive forest. It goes missing because qt/qt-1 goes to infinitum
	
	replace torn_real_forest_es1 = 0 if torn_real_forest_es1 == .				// Assume forest ES are zero if missing
	replace torn_real_forest_es2 = 0 if torn_real_forest_es2 == .
	replace torn_real_forest_es3 = 0 if torn_real_forest_es3 == .
	
		
	replace torn_real_hydro = 0 if torn_real_hydro == . & ///					// Assume that missing hydropower equals to zero except in countries with incomplete series
	countrycode != "BLZ" & ///
	countrycode != "KHM" & ///
	countrycode != "LSO" & ///
	countrycode != "SLE" 
	
	replace torn_real_mangroves = 0 if torn_real_mangroves == .					// Assume landlocked countries and missing mangroes wealth equal to zero
		
	replace torn_real_fisheries = 0 if torn_real_fisheries == .					// Assume landlocked countries and countries with missing data have 
																				// fisheries wealth equal to zero but check which countries go missing due to missing CPI
	
	* replace missing nonrenewable assets values for countries with missing reserves and missing production, leave as missing for countries with missing reserves but nonmissing years of production data
	
	merge m:1 countrycode using "${working}nonmissing_production_but_missing_reserves_nonrenewable"
	egen coal = rowtotal(hard brwn), missing
	keep if _merge==3
	drop _merge
	
	foreach nr in oil gas coal lithium copper gold iron_ore lead nickel phosphate silver tin zinc cobalt molybdenum bauxite {
	    replace torn_real_`nr' = 0 if torn_real_`nr' == . & `nr' == .
		
		replace torn_real_`nr' = . if year == 2019 & torn_real_`nr'[_n-1] == .  // countries with no reserves data (missing q) but nonmissing nominal data (ie Nickel wealth in Albania) 
	}


	tab countryname if torn_real_pk == .										// No missing
	tab countrycode if torn_real_fa == .										// No missing
	tab countrycode if torn_real_fl == .
	
	tab countrycode if torn_real_renew == .										// No missing
	tab countrycode if torn_real_timber == .									// No missing	 
	tab countrycode if torn_real_agland == .									// No missing
	tab countrycode if torn_real_mangroves == .									// No missing
	tab countrycode if torn_real_forest_es1 == . | ///
	torn_real_forest_es2 == . | torn_real_forest_es3 == . 						// No missing
	tab countrycode if torn_real_fisheries == .									// No missing
	tab countrycode if torn_real_hydro == .										// No missing 

	tab countrycode if torn_real_nonrenew == .									// No missing	
	tab countrycode if torn_real_oil == .
	tab countrycode if torn_real_gas == .
	tab countrycode if torn_real_coal == .
	tab countrycode if torn_real_gold == .	

	tab countrycode if torn_real_hc == .										// No missing
	tab countrycode if torn_real_emp_female == .								// No missing
	tab countrycode if torn_real_emp_male == .									// No missing

	tab countrycode if ncwi == .										// No missing


/// STEP 19 - ORDER AND LABEL ASSETS
	
	unique countrycode			
/*	
	merge m:1 countrycode using "${input_pre}CWON24_balanced_panel.dta", keepus(cwon21_balanced)	
	tab countrycode if _merge==3 & cwon21_balanced ==0                          // this edition adds Angola, Guinea Bissau, Israel, Saint Lucia, and New Zealand
*/	
	gen unit = "Real chained 2019 US$"
	
	order unit, before(year)	
	
	keep countryname countrycode region regionname incomelevel incomelevelname unit year pop  torn_real_* *_cd ncwi dcwi
		

	*** Order all variables
	
	drop totwealth_cd torn_real_tw_fl 				// These are dropped since we report ncw_cd that deducts foreign liabilities
	drop hc_emp_females_cd hc_emp_males_cd hc_self_females_cd hc_self_males_cd  // These are reported as emp_females_cd and emp_males_cd	 
	 
	order countrycode countryname countrycode countryname region regionname incomelevel incomelevelname unit year pop ///
	torn_real_pk torn_real_fa torn_real_fl torn_real_renew torn_real_agland torn_real_timber torn_real_mangroves ///
	torn_real_forest_es1 torn_real_forest_es2 torn_real_forest_es3 torn_real_fisheries torn_real_hydro ///
	torn_real_nonrenew torn_real_oil torn_real_gas torn_real_coal ///
	torn_real_bauxite torn_real_copper torn_real_gold torn_real_iron_ore torn_real_lead ///
	torn_real_nickel torn_real_phosphate torn_real_silver torn_real_tin torn_real_zinc torn_real_cobalt torn_real_molybdenum torn_real_lithium torn_real_min ///
	torn_real_hc torn_real_emp_female torn_real_emp_male ncwi dcwi ///
	pk_cd pk_tot_cd urban_cd fa_cd fl_cd renew_cd cropwealth_cd animalwealth_cd agland_cd timber_cd mangroves_cd ///
	forest_es1_cd forest_es2_cd forest_es3_cd fisheries_cd hydro_cd ///
	nonrenew_cd oil_cd gas_cd coal_cd ///
	bauxite_cd copper_cd gold_cd iron_ore_cd lead_cd nickel_cd phosphate_cd ///
	silver_cd tin_cd zinc_cd cobalt_cd molybdenum_cd lithium_cd ///
	hc_cd emp_female_cd emp_male_cd ncw_cd dcw_cd
	
	* Drop data in years before the foundation of Montenegro, Serbia and Sudan before South Sudan independence.
	foreach var of varlist  torn_real_pk-ncw_cd{
	    replace `var' = . if countrycode == "SDN" & year <= 2011
		replace `var' = . if countrycode == "MNE" & year <= 2006
		replace `var' = . if countrycode == "SRB" & year <= 2006

	} 

	rename pk_cd pkx_cd 
	rename pk_tot_cd pk_cd
	
	label var pkx_cd  "Produced capital excluding urban land (current US$)"
	label var pk_cd "Produced capital including urban land (current US$)"
	label var urban_cd "Urban land (current US$)"
	label var fa_cd "Foreign assets (current US$)"
	label var fl_cd "Foreign liabilities (current US$)"
	label var cropwealth_cd "Crop land wealth (current US$)"
	label var animalwealth_cd "Pasture land wealth (current US$)"
	label var renew_cd "Renewable natural capital (current US$)"
	label var nonrenew_cd "Nonrenewable natural capital (current US$)"
	label var emp_female_cd "Female human capital (current US$)"
	label var emp_male_cd "Male human capital (current US$)"
	label var hc_cd "Total human capital (current US$)"
	label var timber_cd "Forest timber wealth (current US$)"
	label var agland_cd "Agricultural land wealth (current US$)"
	label var mangroves_cd "Mangroves shoreline protection services (current US$)"
	label var forest_es1_cd "Forest recreation ecosystem services (current US$)"
	label var forest_es2_cd "Nonwood forest protection ecosystem services (current US$)"
	label var forest_es3_cd "Forest water ecosystem services (current US$)"
	label var fisheries_cd "Fisheries wealth (current US$)"
	label var hydro_cd "Renewable hydro power energy wealth (current US$)"
	label var oil_cd "Oil wealth (current US$)"
	label var gas_cd "Natural gas wealth (current US$)"
	label var coal_cd "Coal wealth (current US$)"
	label var bauxite_cd "Bauxite wealth (current US$)"
	label var copper_cd "Copper wealth (current US$)"
	label var gold_cd "Gold wealth (current US$)"
	label var iron_ore_cd "Iron ore wealth (current US$)"
	label var lead_cd "Lead wealth (current US$)"
	label var nickel_cd "Nickel wealth (current US$)"
	label var phosphate_cd "Phosphate wealth (current US$)"
	label var silver_cd "Silver wealth (current US$)"
	label var tin_cd "Tin wealth (current US$)"
	label var zinc_cd "Zinc wealth (current US$)"
	label var cobalt_cd "Cobalt wealth (current US$)"
	label var molybdenum_cd "Molybdenum wealth (current US$)"
	label var lithium_cd "Lithium wealth (current US$)"
	label var min_cd "Metals and minerals wealth (current US$)"
	label var coal_cd "Coal wealth (current US$)"
	label var ncw_cd "National comprehensive wealth (current US$)"
	label var dcw_cd "Domestic comprehensive wealth (current US$)"

	label var torn_real_timber "Timber wealth (real chained 2019 US$)"
	label var torn_real_agland "Agricultural land (real chained 2019 US$)"
	label var torn_real_mangroves "Mangroves shoreline protection services (real chained 2019 US$)"
	label var torn_real_forest_es1 "Forest recreation ecosystem services (real chained 2019 US$)"
	label var torn_real_forest_es2 "Nonwood forest protection ecosystem services (real chained 2019 US$)"
	label var torn_real_forest_es3 "Forest water ecosystem services (real chained 2019 US$)"
	label var torn_real_fisheries "Fisheries wealth (real chained 2019 US$)"
	label var torn_real_hydro "Renewable hydro power energy wealth (real chained 2019 US$)"
	label var torn_real_oil "Oil wealth (real chained 2019 US$)"
	label var torn_real_gas "Natural gas wealth (real chained 2019 US$)"
	label var torn_real_coal "Coal wealth (real chained 2019 US$)"
	label var torn_real_bauxite "Bauxite wealth (real chained 2019 US$)"
	label var torn_real_copper "Copper wealth (real chained 2019 US$)"
	label var torn_real_gold "Gold wealth (real chained 2019 US$)"
	label var torn_real_iron_ore "Iron ore wealth (real chained 2019 US$)"
	label var torn_real_lead "Lead wealth (real chained 2019 US$)"
	label var torn_real_nickel "Nickel wealth (real chained 2019 US$)"
	label var torn_real_phosphate "Phosphate wealth (real chained 2019 US$)"
	label var torn_real_silver "Silver wealth (real chained 2019 US$)"
	label var torn_real_tin "Tin wealth (real chained 2019 US$)"
	label var torn_real_zinc "Zinc wealth (real chained 2019 US$)"
	label var torn_real_cobalt "Cobalt wealth (real chained 2019 US$)"
	label var torn_real_molybdenum "Molybdenum wealth (real chained 2019 US$)"
	label var torn_real_lithium "Lithium wealth (real chained 2019 US$)"
	label var torn_real_emp_female "Female human capital (real chained 2019 US$)"
	label var torn_real_emp_male "Male human capital (real chained 2019 US$)"
	label var torn_real_pk "Produced capital (real chained 2019 US$)"
	label var torn_real_fa "Foreign assets (real chained 2019 US$)"
	label var torn_real_fl "Foreign liabilities (real chained 2019 US$)"
	label var torn_real_renew "Renewable natural capital (real chained 2019 US$)"
	label var torn_real_nonrenew "Nonrenewable natural capital (real chained 2019 US$)"
	label var torn_real_coal "Coal wealth (real chained 2019 US$)"
	label var torn_real_min "Metals and minerals, sub-index (real chained 2019 US$)"
	label var torn_real_hc "Total human capital (real chained 2019 US$)"
	label var ncwi "National comprehensive wealth index (real chained 2019 US$)"
	label var dcwi "Domestic comprehensive wealth index (real chained 2019 US$)"
	
	
	foreach var of varlist torn_real_pk-ncw_cd{
	    format `var' %25.0fc
	}
	
	** Separately estimate torn_real_min from disaggregated mineral wealth
	drop torn_real_min
	egen torn_real_min = rowtotal(torn_real_bauxite torn_real_copper torn_real_gold torn_real_iron_ore torn_real_lead torn_real_nickel torn_real_phosphate torn_real_silver torn_real_tin torn_real_zinc torn_real_cobalt torn_real_molybdenum torn_real_lithium), missing
	
	order torn_real_min, after(torn_real_lithium)
	label variable torn_real_min "Metals and minerals, sub-index (real chained 2019 US$)"


	save  "${working}real_wealth_chained_tornqvist_national.dta", replace
	export delimited using "${working}real_wealth_chained_tornqvist_national.csv", replace
	


/// STEP 20 - Create experimental PPP estimates

// Nominal values use the PLI/PPP for each year. Volume-based index use the 2019 PLI/PPP.

use "${working}real_wealth_chained_tornqvist_national.dta", clear

merge 1:1 countrycode year using "${working}general_pli_long.dta", nogen norep keep(3)

* Only keep Price Level Index (PPP) for year 2019
replace pli = . if year != ${chain_year}
bys countrycode: egen pli_${chain_year} = max(pli)
drop pli
tab countrycode if pli_${chain_year} == .
// Zimbabwe missing

merge 1:1 countrycode year using "${working}general_pli_long.dta", nogen norep keep(3) keepus(pli)
tab countryname year if pli ==.
*missing for Argentina, Bosnia, Ecuador, Liberia, Montenegro, Zimbabwe
ipolate pli year if countrycode != "ZWE", gen(pli_fill)
replace pli = pli_fill if pli == .
drop pli_fill
tab countryname year if pli ==.

foreach v in pk_cd pkx_cd urban_cd fa_cd fl_cd renew_cd cropwealth_cd animalwealth_cd agland_cd timber_cd mangroves_cd forest_es1_cd forest_es2_cd forest_es3_cd fisheries_cd hydro_cd nonrenew_cd oil_cd gas_cd coal_cd bauxite_cd copper_cd gold_cd iron_ore_cd lead_cd nickel_cd phosphate_cd silver_cd zinc_cd molybdenum_cd cobalt_cd lithium_cd hc_cd emp_female_cd emp_male_cd ncw_cd dcw_cd tin_cd {
	gen `v'_ppp =  `v'/pli
}

foreach v in torn_real_pk torn_real_fa torn_real_fl torn_real_renew torn_real_agland torn_real_timber torn_real_mangroves torn_real_forest_es1 torn_real_forest_es2 torn_real_forest_es3 torn_real_fisheries torn_real_hydro torn_real_nonrenew torn_real_oil torn_real_gas torn_real_coal torn_real_bauxite torn_real_copper torn_real_gold torn_real_iron_ore torn_real_lead torn_real_nickel torn_real_phosphate torn_real_silver torn_real_tin torn_real_zinc torn_real_cobalt torn_real_molybdenum torn_real_lithium torn_real_hc torn_real_emp_female torn_real_emp_male ncwi dcwi {
	gen `v'_ppp =  `v'/pli_${chain_year}
}

	label var pkx_cd_ppp  "Produced capital excluding urban land (current US$ in PPP terms, experimental estimate"
	label var pk_cd_ppp "Produced capital including urban land (current US$ in PPP terms, experimental estimate)"
	label var urban_cd_ppp "Urban land (current US$ in PPP terms, experimental estimate)"
	label var fa_cd_ppp "Foreing assets (current US$ in PPP terms, experimental estimate)"
	label var fl_cd_ppp "Foreing liabilities (current US$ in PPP terms, experimental estimate)"
	label var cropwealth_cd_ppp "Crop land wealth (current US$ in PPP terms, experimental estimate)"
	label var animalwealth_cd_ppp "Pasture land wealth (current US$ in PPP terms, experimental estimate)"
	label var renew_cd_ppp "Renewable natural capital (current US$ in PPP terms, experimental estimate)"
	label var nonrenew_cd_ppp "Nonrenewable natural capital (current US$ in PPP terms, experimental estimate)"
	label var emp_female_cd_ppp "Female human capital (current US$ in PPP terms, experimental estimate)"
	label var emp_male_cd_ppp "Male human capital (current US$ in PPP terms, experimental estimate)"
	label var hc_cd_ppp "Total human capital (current US$ in PPP terms, experimental estimate)"
	label var timber_cd_ppp "Forest timber wealth (current US$ in PPP terms, experimental estimate)"
	label var agland_cd_ppp "Agricultural land wealth (current US$ in PPP terms, experimental estimate)"
	label var mangroves_cd_ppp "Mangroves shoreline protection services (current US$ in PPP terms, experimental estimate)"
	label var forest_es1_cd_ppp "Forest recreation ecosystem services (current US$ in PPP terms, experimental estimate)"
	label var forest_es2_cd_ppp "Nonwood forest protection ecosystem services (current US$ in PPP terms, experimental estimate)"
	label var forest_es3_cd_ppp "Forest water ecosystem services (current US$ in PPP terms, experimental estimate)"
	label var fisheries_cd_ppp "Fisheries wealth (current US$ in PPP terms, experimental estimate)"
	label var hydro_cd_ppp "Renewable hydro power energy wealth (current US$ in PPP terms, experimental estimate)"
	label var oil_cd_ppp "Oil wealth (current US$ in PPP terms, experimental estimate)"
	label var gas_cd_ppp "Natural gas wealth (current US$ in PPP terms, experimental estimate)"
	label var coal_cd_ppp "Coal wealth (current US$ in PPP terms, experimental estimate)"
	label var bauxite_cd_ppp "Bauxite wealth (current US$ in PPP terms, experimental estimate)"
	label var copper_cd_ppp "Copper wealth (current US$ in PPP terms, experimental estimate)"
	label var gold_cd_ppp "Gold wealth (current US$ in PPP terms, experimental estimate)"
	label var iron_ore_cd_ppp "Iron ore wealth (current US$ in PPP terms, experimental estimate)"
	label var lead_cd_ppp "Lead wealth (current US$ in PPP terms, experimental estimate)"
	label var nickel_cd_ppp "Nickel wealth (current US$ in PPP terms, experimental estimate)"
	label var phosphate_cd_ppp "Phosphate wealth (current US$ in PPP terms, experimental estimate)"
	label var silver_cd_ppp "Silver wealth (current US$ in PPP terms, experimental estimate)"
	label var tin_cd_ppp "Tin wealth (current US$ in PPP terms, experimental estimate)"
	label var zinc_cd_ppp "Zinc wealth (current US$ in PPP terms, experimental estimate)"
	label var cobalt_cd_ppp "Cobalt wealth (current US$ in PPP terms, experimental estimate)"
	label var molybdenum_cd_ppp "Molybdenum wealth (current US$ in PPP terms, experimental estimate)"
	label var lithium_cd_ppp "Lithium wealth (current US$ in PPP terms, experimental estimate)"
	label var ncw_cd_ppp "National comprehensive wealth (current US$ in PPP terms, experimental estimate)"
	label var dcw_cd_ppp "Domestic comprehensive wealth (current US$ in PPP terms, experimental estimate)"

	label var torn_real_timber_ppp "Timber wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_agland_ppp "Agricultural land (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_mangroves_ppp "Mangroves shoreline protection services (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_forest_es1_ppp "Forest recreation ecosystem services (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_forest_es2_ppp "Nonwood forest protection ecosystem services (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_forest_es3_ppp "Forest water ecosystem services (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_fisheries_ppp "Fisheries wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_hydro_ppp "Renewable hydro power energy wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_oil_ppp "Oil wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_gas_ppp "Natural gas wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_coal_ppp "Coal wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_bauxite_ppp "Bauxite wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_copper_ppp "Copper wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_gold_ppp "Gold wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_iron_ore_ppp "Iron ore wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_lead_ppp "Lead wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_nickel_ppp "Nickel wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_phosphate_ppp "Phosphate wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_silver_ppp "Silver wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_tin_ppp "Tin wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_zinc_ppp "Zinc wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_cobalt_ppp "Cobalt wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_molybdenum_ppp "Molybdenum wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_lithium_ppp "Lithium wealth (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_emp_female_ppp "Female human capital (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_emp_male_ppp "Male human capital (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_pk_ppp "Produced capital (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_fa_ppp "Foreign assets (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_fl_ppp "Foreign liabilities (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_renew_ppp "Renewable natural capital (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_coal "Coal wealth, sub-index (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_min "Metals and minerals, sub-index (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var min_cd "Metals and minerals wealth (current US$ in PPP terms, experimental estimate)"
	label var coal_cd "Coal wealth (current US$ in PPP terms, experimental estimate)"
	label var torn_real_nonrenew_ppp "Nonrenewable natural capital (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var torn_real_hc_ppp "Total human capital (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var ncwi_ppp "National comprehensive wealth index (real chained 2019 US$ in PPP terms, experimental estimate)"
	label var dcwi_ppp "Domestic comprehensive wealth index (real chained 2019 US$ in PPP terms, experimental estimate)"


	save  "${working}real_wealth_chained_tornqvist_national_ppp.dta", replace
	



