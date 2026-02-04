clear all
set maxvar 32000
set seed 1234
cd "/Users/xabajian/Desktop/Yale Postdoc/Eli Marc Final/CWON Data"
global figs  "/Users/xabajian/Desktop/Yale Postdoc/Eli Marc Final/CWON Data/figs"
set scheme plotplain


/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step 1 -- Read Data for CWON with current (calendar year 2019) measures of wealth at narrow asset classes

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/


qui {

    /*
    1.1. Read CWON 1 data and process into workable panel
    */
    //get CWON
    import delimited "cwon_wide.csv", clear

    keep if indicator_label == "Nonrenewable natural capital" | ///
            indicator_label == "Renewable natural capital"

    drop if indicator_label == "Nonrenewable natural capital" & ///
            comp_breakdown_2_label != "Nonrenewable capital: total"

    keep if comp_breakdown_1_label == "Aggregation: total"z

    // keep if comp_breakdown_2_label=="Renewable capital: total" | comp_breakdown_2_label=="Nonrenewable natural capital" |
    keep ref_area ref_area_label comp_breakdown_2_label indicator indicator_label year*

    reshape long year, ///
        i(ref_area ref_area_label comp_breakdown_2_label indicator indicator_label) ///
        j(dummy)

    rename year  NK_Value_
    rename dummy year

    //reshape wide
    encode comp_breakdown_2_label, gen(resource_indicator_variable)
    levelsof comp_breakdown_2_label, local(vals)

    display `vals'
    global vals `vals'

    drop comp_breakdown_2_label indicator_label indicator
    sort ref_area ref_area_label year resource_indicator_variable
    tab  resource_indicator_variable

    //put in logs
    reshape wide NK_Value_, i(ref_area ref_area_label year) j(resource_indicator_variable)

    //Re-name variables for stata compatibiity
    local i = 1
    foreach v of local vals {

        local old "NK_Value_`i'"

        * sanitize target name (turns "Renewable natural capital" -> "Renewable_natural_capital")
        local new = strtoname("`v'")

        di as txt "Trying: rename `old' -> `new'"

        * does old var exist?
        capture confirm variable `old'
        if _rc {
            di as err "  FAIL: variable `old' does not exist"
            local ++i
            continue
        }

        * does new var already exist?
        capture confirm variable `new'
        if !_rc {
            di as err "  FAIL: target name `new' already exists"
            local ++i
            continue
        }

        rename `old' `new'
        local ++i
    }

    drop NK_Value_3 NK_Value_4


    /*
    merge PWT and other datasets
    */
    rename ref_area countrycode
    merge 1:1 countrycode year using "pwt100.dta", keep(3)
    drop _merge

    //merge BLS productivity series for the US
    merge 1:1 year countrycode using "US_MFP.dta", gen(merge_BLS_TFP)
    drop if merge_BLS_TFP == 2

    //merge UK ONS MFP datset
    merge 1:1 year countrycode using "UK_MFP.dta", gen(merge_UK_ONS_TFP)
    drop if merge_UK_ONS_TFP == 2

    gen iso3 = countrycode

    //Merge the euro area version from Eurostat
    merge 1:1 year iso3 using "euro_area_mfp_panel_iso.dta", gen(merge_EU)
    drop if merge_EU == 2

    //water from UNFAO
    merge 1:1 year iso3 using "AQUASTAT_with_iso3.dta", gen(merge_aquastat)
    drop if merge_aquastat == 2

    //merge GRACE Water data from NASA JPL
    merge 1:1 year countrycode using "grace_income.dta", gen(merge_grace)
    drop if merge_grace == 2

    rename Value internal_water_resources

	//FAO TFP panle
	merge 1:1 year countrycode using "UN_FAO_TFP_panel.dta", gen(merge_UNFAO)
	drop if merge_UNFAO==2

    /*
    1.2 -- prep data
    */
    encode countrycode, gen(country_byte)
    drop if country_byte == .

    xtset country_byte year

    gen log_tfp = ln(rtfp)
    gen log_K   = ln(rk)
    gen log_L   = ln(emp)
    gen log_HC  = ln(hc)
    gen log_labshare  = ln(labsh)
    gen log_y   = ln(rgdpo)

    replace UK_MFP = ln(UK_MFP)

    gen log_eurostat_MFP = ln(mfp)

    gen dlog_tfp = d.log_tfp
    by country_byte: gen g_water = (d.avg_tws_cc) / l.avg_tws_cc if _n > 1


    //Label variables
    label var Renewable_capital__agricultural_  "Agricultural NK"
    label var Renewable_capital__fisheries     "Fisheries"
    label var Renewable_capital__forest_recrea "Recreational Forests"
    label var Renewable_capital__forest_water_ "Forest Water Ecosystems"
    label var Renewable_capital__hydropower_en "Hydropower"
    label var Renewable_capital__mangroves     "Mangroves"
    label var Renewable_capital__nonwood_fores "Nonwood Forest Services"
    label var Renewable_capital__timber        "Timber"
    label var Renewable_capital__total         "Total Renewable NK"
    label var Nonrenewable_capital__total         "Total Non-Renewable NK"

    //rename
    rename Renewable_capital__agricultural_  ag_NK
    rename Renewable_capital__fisheries     fisheries
    rename Renewable_capital__forest_recrea rec_forests
    rename Renewable_capital__forest_water_ FWE
    rename Renewable_capital__hydropower_en Hydro
    rename Renewable_capital__mangroves     Mangroves
    rename Renewable_capital__nonwood_fores NFS
    rename Renewable_capital__timber        Timber
    rename Renewable_capital__total         total_NK
    rename Nonrenewable_capital__total   total_NR_NK

    //gen log levels
    local outcomes  total_NK total_NR_NK

    foreach var of local outcomes {

        gen  log_`var'  = ln(`var')
        gen  dlog_`var' = d.log_`var'
    }
}


preserve
keep countrycode year total_NK
save "/Users/xabajian/Desktop/Yale Postdoc/Eli Marc Final/CWON Data/Quantities/renewable_wealth.dta", replace
restore
/*
constructing non-renewable NK use
*/

gen d_total_NR_NK = d.total_NR_NK
/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step 2 -- Analysis and figures

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/


/*
!@#$@!$#@!$@#$!@#$2
Step 2.1 --- LASSOs
!@#$@!$#@!$@#$!@#$2
*/

//no winsor lasso
cvlasso d.log_tfp dlog_total_NK dlog_total_NR_NK  ///
        d.log_K d.log_L d.log_HC d.log_labshare i.year, ///
        fe 
cvlasso, lopt

//winsor lasso
preserve
    sum dlog_tfp, d
    keep if dlog_tfp <= r(p95) & dlog_tfp >= r(p5)
cvlasso d.log_tfp dlog_total_NK dlog_total_NR_NK  ///
        d.log_K d.log_L d.log_HC d.log_labshare i.year, ///
        fe 
cvlasso, lopt
restore
	

/*
Other outcomes

*/

//EU
gen dlog_eurostat_MFP = d.log_eurostat_MFP

/*
FAO ag TFP
*/

gen log_ag_TFP = ln(TFP_Index)
gen dlog_ag_TFP = d.log_ag_TFP


/*
1#$!@#$!@#$!@#$#@
1#$!@#$!@#$!@#$#@
1#$!@#$!@#$!@#$#@
1#$!@#$!@#$!@#$#@

Step 3 -- Regressions, d(P*Q) as regresors 

!@#$!@#$!@#$2
!@#$!@#$!@#$2
!@#$!@#$!@#$2
!@#$!@#$!@#$2
*/


/*
Aggregates 
*/
corr log_total_NK dlog_total_NR_NK d.log_K

reg d.log_tfp dlog_total_NK dlog_total_NR_NK , ///
        vce(cluster country_byte year)
reghdfe d.log_tfp dlog_total_NK dlog_total_NR_NK , ///
        absorb(country_byte year) vce(cluster country_byte year)

		
reghdfe d.log_y dlog_total_NK dlog_total_NR_NK ///
		d.log_K d.log_L d.log_HC d.log_labshare, ///
        absorb(country_byte year) vce(cluster country_byte year)
		
		
reghdfe d.log_tfp dlog_total_NK dlog_total_NR_NK ///
		d.log_K d.log_L d.log_HC d.log_labshare, ///
        absorb(i.year i.country_byte##c.year) vce(cluster country_byte year)

		
pcorr d.log_y dlog_total_NR_NK dlog_total_NK  d.log_K  d.log_L d.log_HC 	   
pcorr d.log_y dlog_total_NR_NK dlog_total_NK  d.log_K  d.log_L d.log_HC ///
       i.country_byte i.year
	   
	   
pcorr d.log_tfp dlog_total_NR_NK dlog_total_NK  d.log_K  d.log_L d.log_HC ///
       i.country_byte i.year 
