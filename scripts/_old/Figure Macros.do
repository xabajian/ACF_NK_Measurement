clear all
set maxvar 32000
set seed 1234
cd "/Users/xabajian/Desktop/Yale Postdoc/Eli Marc Final/CWON Data"
global figs  "/Users/xabajian/Desktop/Yale Postdoc/Eli Marc Final/CWON Data/figs"
set scheme plotplain


/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step 1 -- Read Data

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

    keep if comp_breakdown_1_label == "Aggregation: total"

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
    local outcomes ag_NK fisheries rec_forests FWE Hydro Mangroves NFS Timber total_NK

    foreach var of local outcomes {

        gen  log_`var'  = ln(`var')
        gen  dlog_`var' = d.log_`var'
    }
}




/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step 2 -- Analysis and figures

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/


		
/*
!@#$@!$#@!$@#$!@#$2
Step 2.2 --- no winsorizing figure loop
!@#$@!$#@!$@#$!@#$2




local lbl1 "Agricultural NK"
local lbl2 "Fisheries"
local lbl3 "Recreational Forests"
local lbl4 "Forest Water Ecosystems"
local lbl5 "Hydropower"
local lbl6 "Mangroves"
local lbl7 "Nonwood Forest Services"
local lbl8 "Timber"
local lbl9 "Total NK"


local nk_levels ///
    dlog_ag_NK ///
    dlog_fisheries ///
    dlog_rec_forests ///
    dlog_FWE ///
    dlog_Hydro ///
    dlog_Mangroves ///
    dlog_NFS ///
    dlog_Timber

local nk_changes ///
    dlog_ag_NK ///
    dlog_fisheries ///
    dlog_rec_forests ///
    dlog_FWE ///
    dlog_Hydro ///
    dlog_Mangroves ///
    dlog_NFS ///
    dlog_Timber

local outcomes Renewable_capital__agricultural_ Renewable_capital__fisheries Renewable_capital__forest_recrea ///
              Renewable_capital__forest_water_ Renewable_capital__hydropower_en Renewable_capital__mangroves ///
              Renewable_capital__nonwood_fores Renewable_capital__timber Renewable_capital__total


local i = 1
    foreach lhs of local nk_levels {

        preserve

        //locals
        local xlabel = "`lbl`i''"

        local NK_outcome : word `i' of `outcomes'
        local rhs "`nk_changes'"
        local dropvar : word `i' of `nk_changes'
        local rhs : list rhs - dropvar

        reghdfe `lhs' ///
            `rhs' ///
            d.log_K d.log_L d.log_HC if dlog_tfp != ., ///
            absorb(country_byte year) ///
            cluster(country_byte year) resid

        predict xb_residuals, resid

        //regression outcome on residuals
        reg dlog_tfp xb_residuals, vce(cluster country_byte)
        label var xb_residuals "Residual Variation in `xlabel'"

        //slopes and p values for caption
        lincom xb_residuals
        local b: display %4.3f r(estimate)
        local p: display %4.3f r(p)

        //center and plot
        sum dlog_tfp
        replace dlog_tfp = dlog_tfp - r(mean)

        twoway ///
            (lfit   dlog_tfp xb_residuals) ///
            (lpoly  dlog_tfp xb_residuals, lcolor(orange)) ///
            (lowess dlog_tfp xb_residuals, lcolor(blue)) ///
            (scatter dlog_tfp xb_residuals, mfcolor(none) mlcolor(gray%20) msize(tiny) msymbol(circle)), ///
            xtitle("Residual Growth in `xlabel'", size(small)) ///
            ytitle("TFP Growth", size(small)) ///
            legend( ///
                size(small)  ///
                order(1 "Linear Fit, {&beta} = `b', {it:p}-value: `p'") ///
                region(fcolor(none) lcolor(none) margin(zero)) ///
                bplacement(5) ring(0) ///
            ) ///
            saving("$figs/`NK_outcome'.gph", replace)

        restore
        local ++i

        //  legend(size(tiny) order(1 "Linear Fit, {&beta} = `b', {it:p}-value: `p'" 2 "Polynomial Fit" 3 "Lowess" 4 "") ///
    }


graph combine ///
    "$figs/Renewable_capital__agricultural_.gph" ///
    "$figs/Renewable_capital__fisheries.gph" ///
    "$figs/Renewable_capital__forest_recrea.gph" ///
    "$figs/Renewable_capital__forest_water_.gph" ///
    "$figs/Renewable_capital__hydropower_en.gph" ///
    "$figs/Renewable_capital__nonwood_fores.gph" ///
	"$figs/Renewable_capital__mangroves.gph" ///
   "$figs/Renewable_capital__timber.gph", ///
    col(4)

graph export $figs/nine_NK_nowinsor.png, replace
graph export $figs/nine_NK_nowinsor.pdf, replace
*/

/*
!@#$@!$#@!$@#$!@#$2
Step 2.2.1 --- no winsorizing figure loop, no mangroves
!@#$@!$#@!$@#$!@#$2
*/


local lbl1 "Agricultural NK"
local lbl2 "Fisheries"
local lbl3 "Recreational Forests"
local lbl4 "Forest Water Ecosystems"
local lbl5 "Hydropower"
local lbl6 "Nonwood Forest Services"
local lbl7 "Timber"
local lbl8 "Total NK"


local nk_levels ///
    dlog_ag_NK ///
    dlog_fisheries ///
    dlog_rec_forests ///
    dlog_FWE ///
    dlog_Hydro ///
    dlog_NFS ///
    dlog_Timber

local nk_changes ///
    dlog_ag_NK ///
    dlog_fisheries ///
    dlog_rec_forests ///
    dlog_FWE ///
    dlog_Hydro ///
    dlog_NFS ///
    dlog_Timber

local outcomes Renewable_capital__agricultural_ Renewable_capital__fisheries Renewable_capital__forest_recrea ///
              Renewable_capital__forest_water_ Renewable_capital__hydropower_en ///
              Renewable_capital__nonwood_fores Renewable_capital__timber Renewable_capital__total


local i = 1
    foreach lhs of local nk_levels {

        preserve

        //locals
        local xlabel = "`lbl`i''"

        local NK_outcome : word `i' of `outcomes'
        local rhs "`nk_changes'"
        local dropvar : word `i' of `nk_changes'
        local rhs : list rhs - dropvar

        reghdfe `lhs' ///
            `rhs' ///
            d.log_K d.log_L d.log_HC if dlog_tfp != ., ///
            absorb(country_byte year) ///
            cluster(country_byte year) resid

        predict xb_residuals, resid

        //regression outcome on residuals
        reg dlog_tfp xb_residuals, vce(cluster country_byte)
        label var xb_residuals "Residual Variation in `xlabel'"

        //slopes and p values for caption
        lincom xb_residuals
        local b: display %4.1f r(estimate)
        local p: display %4.3f r(p)

        //center and plot
        sum dlog_tfp
        replace dlog_tfp = dlog_tfp - r(mean)

        twoway ///
            (lfit   dlog_tfp xb_residuals) ///
            (lpoly  dlog_tfp xb_residuals, lcolor(orange)) ///
            (lowess dlog_tfp xb_residuals, lcolor(blue)) ///
            (scatter dlog_tfp xb_residuals, mfcolor(none) mlcolor(gray%20) msize(tiny) msymbol(circle)), ///
            xtitle("Residual Growth in `xlabel'", size(vsmall)) ///
            ytitle("TFP Growth", size(vsmall)) ///
            legend( ///
                size(small)  ///
                order(1 "Linear Fit, {it:p}-value: `p'") ///
                region(fcolor(none) lcolor(none) margin(zero)) ///
                bplacement(5) ring(0) ///
            ) ///
            saving("$figs/`NK_outcome'.gph", replace)

        restore
        local ++i

        //  legend(size(tiny) order(1 "Linear Fit, {&beta} = `b', {it:p}-value: `p'" 2 "Polynomial Fit" 3 "Lowess" 4 "") ///
    }


graph combine ///
    "$figs/Renewable_capital__agricultural_.gph" ///
    "$figs/Renewable_capital__fisheries.gph" ///
    "$figs/Renewable_capital__forest_recrea.gph" ///
    "$figs/Renewable_capital__forest_water_.gph" ///
    "$figs/Renewable_capital__hydropower_en.gph" ///
    "$figs/Renewable_capital__nonwood_fores.gph" ///
   "$figs/Renewable_capital__timber.gph", ///
    col(4)

graph export "$figs/nine_NK_nowinsor_noman.png", replace
graph export "$figs/nine_NK_nowinsor_noman.pdf", replace


/*
!@#$@!$#@!$@#$!@#$2
Step 2.3 winsorized figure loop
!@#$@!$#@!$@#$!@#$


preserve 

//winsorize
sum dlog_tfp, d
keep if dlog_tfp <= r(p95) & dlog_tfp >= r(p5)


local lbl1 "Agricultural NK"
local lbl2 "Fisheries"
local lbl3 "Recreational Forests"
local lbl4 "Forest Water Ecosystems"
local lbl5 "Hydropower"
local lbl6 "Mangroves"
local lbl7 "Nonwood Forest Services"
local lbl8 "Timber"
local lbl9 "Total NK"


local nk_levels ///
    dlog_ag_NK ///
    dlog_fisheries ///
    dlog_rec_forests ///
    dlog_FWE ///
    dlog_Hydro ///
    dlog_Mangroves ///
    dlog_NFS ///
    dlog_Timber

local nk_changes ///
    dlog_ag_NK ///
    dlog_fisheries ///
    dlog_rec_forests ///
    dlog_FWE ///
    dlog_Hydro ///
    dlog_Mangroves ///
    dlog_NFS ///
    dlog_Timber

local outcomes Renewable_capital__agricultural_ Renewable_capital__fisheries Renewable_capital__forest_recrea ///
              Renewable_capital__forest_water_ Renewable_capital__hydropower_en Renewable_capital__mangroves ///
              Renewable_capital__nonwood_fores Renewable_capital__timber Renewable_capital__total


//main regressions
reghdfe d.log_tfp dlog_ag_NK dlog_fisheries dlog_rec_forests dlog_FWE dlog_Hydro dlog_Mangroves ///
        dlog_NFS dlog_Timber d.log_K d.log_L d.log_HC, ///
        absorb(country_byte year) vce(cluster country_byte year)

test dlog_ag_NK dlog_fisheries dlog_rec_forests dlog_FWE dlog_Hydro dlog_Mangroves dlog_NFS dlog_Timber

//1 way cluster 
reghdfe d.log_tfp dlog_ag_NK dlog_fisheries dlog_rec_forests dlog_FWE dlog_Hydro dlog_Mangroves ///
        dlog_NFS dlog_Timber d.log_K d.log_L d.log_HC, ///
        absorb(country_byte year) vce(cluster country_byte)

test dlog_ag_NK dlog_fisheries dlog_rec_forests dlog_FWE dlog_Hydro dlog_Mangroves dlog_NFS dlog_Timber



pcorr d.log_tfp dlog_ag_NK dlog_fisheries dlog_rec_forests dlog_FWE dlog_Hydro dlog_Mangroves ///
        dlog_NFS dlog_Timber d.log_K d.log_L d.log_HC i.country_byte i.year

//output 
reghdfe d.log_y dlog_ag_NK dlog_fisheries dlog_rec_forests dlog_FWE dlog_Hydro dlog_Mangroves dlog_NFS dlog_Timber ///
         d.log_K d.log_L d.log_HC, ///
        absorb(country_byte year) vce(cluster country_byte year)
test dlog_ag_NK dlog_fisheries dlog_rec_forests dlog_FWE dlog_Hydro dlog_Mangroves dlog_NFS dlog_Timber
	
		
reghdfe d.log_tfp dlog_total_NK d.log_K d.log_L d.log_HC, ///
        absorb(country_byte year) vce(cluster country_byte year)

reghdfe d.log_y dlog_total_NK ///
         d.log_K d.log_L d.log_HC, ///
        absorb(country_byte year) vce(cluster country_byte year)


		
matrix r_2 = [.]
local i = 1
qui{
foreach lhs of local nk_levels {


	//locals
	local xlabel = "`lbl`i''"

	local NK_outcome : word `i' of `outcomes'
	local rhs "`nk_changes'"
	local dropvar : word `i' of `nk_changes'
	local rhs : list rhs - dropvar

	reghdfe `lhs' ///
		`rhs' ///
		d.log_K d.log_L d.log_HC if dlog_tfp != ., ///
		absorb(country_byte year) ///
		cluster(country_byte year) resid

	predict xb_residuals, resid

	//regression outcome on residuals
	sum dlog_tfp
	replace dlog_tfp = dlog_tfp - r(mean)

	reg dlog_tfp xb_residuals, vce(cluster country_byte) noconstant
		matrix r_2 =   r_2 \ e(r2)    
	label var xb_residuals "Residual Variation in `xlabel'"

	//slopes and p values for caption
	lincom xb_residuals
	local b: display %4.3f r(estimate)
	local p: display %4.3f r(p)

	//center and plot

	twoway ///
		(lfit   dlog_tfp xb_residuals) ///
		(lpoly  dlog_tfp xb_residuals, lcolor(orange)) ///
		(lowess dlog_tfp xb_residuals, lcolor(blue)) ///
		(scatter dlog_tfp xb_residuals, mfcolor(none) mlcolor(gray%20) msize(tiny) msymbol(circle)), ///
		xtitle("Residual Growth in `xlabel'", size(small) ) ///
		ytitle("TFP Growth", size(small) ) ///
		legend( ///
			size(tiny) ///
			order(1 "Linear Fit, {&beta} = `b', {it:p}-value: `p'") ///
			region(fcolor(none) lcolor(none) margin(zero)) ///
			bplacement(5) ring(0) ///
		) ///
		saving("$figs/`NK_outcome'.gph", replace)

	drop xb_residuals
	local ++i

	//  legend(size(tiny) order(1 "Linear Fit, {&beta} = `b', {it:p}-value: `p'" 2 "Polynomial Fit" 3 "Lowess" 4 "") ///
}
}

svmat r_2

graph combine ///
    "$figs/Renewable_capital__agricultural_.gph" ///
    "$figs/Renewable_capital__fisheries.gph" ///
    "$figs/Renewable_capital__forest_recrea.gph" ///
    "$figs/Renewable_capital__forest_water_.gph" ///
    "$figs/Renewable_capital__hydropower_en.gph" ///
    "$figs/Renewable_capital__nonwood_fores.gph" ///
   "$figs/Renewable_capital__timber.gph", ///
    col(4)

graph export $figs/nine_NK.png, replace
graph export $figs/nine_NK.pdf, replace

restore

*/


/*

!@#$!@#$!@#$!@#$!#@$
!@#$!@#$!@#$!@#$!#@$
!@#$!@#$!@#$!@#$!#@$

2.4 -- Eurostat MFP version

!@#$!@#$!@#$!@#$!#@$
!@#$!@#$!@#$!@#$!#@$
!@#$!@#$!@#$!@#$!#@$

*/

gen dlog_eurostat_MFP = d.log_eurostat_MFP

	
local lbl1 "Agricultural NK"
local lbl2 "Fisheries"
local lbl3 "Recreational Forests"
local lbl4 "Forest Water Ecosystems"
local lbl5 "Hydropower"
local lbl6 "Nonwood Forest Services"
local lbl7 "Timber"


local nk_levels ///
    dlog_ag_NK ///
    dlog_fisheries ///
    dlog_rec_forests ///
    dlog_FWE ///
    dlog_Hydro ///
    dlog_NFS ///
    dlog_Timber

local nk_changes ///
    dlog_ag_NK ///
    dlog_fisheries ///
    dlog_rec_forests ///
    dlog_FWE ///
    dlog_Hydro ///
    dlog_NFS ///
    dlog_Timber

local outcomes Renewable_capital__agricultural_ Renewable_capital__fisheries Renewable_capital__forest_recrea ///
              Renewable_capital__forest_water_ Renewable_capital__hydropower_en Renewable_capital__nonwood_fores ///
              Renewable_capital__timber Renewable_capital__total

local i = 1
    foreach lhs of local nk_levels {

        preserve

        //locals
        local xlabel = "`lbl`i''"
        local NK_outcome : word `i' of `outcomes'

        local rhs "`nk_changes'"
        local dropvar : word `i' of `nk_changes'
        local rhs : list rhs - dropvar

        reghdfe `lhs' ///
            `rhs' ///
            d.log_K d.log_L d.log_HC if dlog_eurostat_MFP != ., ///
            absorb(country_byte year) ///
            cluster(country_byte year) resid

        predict xb_residuals, resid

        //regression outcome on residuals
        reg dlog_eurostat_MFP xb_residuals, vce(cluster country_byte)


        //slopes and p values for caption
        lincom xb_residuals
        local b: display %4.3f r(estimate)
        local p: display %4.3f r(p)

        //plot
        sum dlog_eurostat_MFP
        replace dlog_eurostat_MFP = dlog_eurostat_MFP - r(mean)

        twoway ///
            (lfit   dlog_eurostat_MFP xb_residuals) ///
            (lpoly  dlog_eurostat_MFP xb_residuals, lcolor(orange)) ///
            (lowess dlog_eurostat_MFP xb_residuals, lcolor(blue)) ///
            (scatter dlog_eurostat_MFP xb_residuals, mfcolor(none) mlcolor(gray%20) msize(tiny) msymbol(circle)), ///
            xtitle("Residual Variation in `xlabel'", size(small) ) ///
            ytitle("Eurostat MFP Growth", size(small) ) ///
            legend( ///
                size(vsmall)  ///
                order(1 "Linear Fit, {&beta} = `b', {it:p}-value: `p'") ///
                region(fcolor(none) lcolor(none) margin(zero)) ///
                bplacement(5) ring(0) ///
            ) ///
            saving("$figs/`NK_outcome'.gph", replace)

        restore
        local ++i
    }

	

graph combine ///
    "$figs/Renewable_capital__agricultural_.gph" ///
    "$figs/Renewable_capital__fisheries.gph" ///
    "$figs/Renewable_capital__forest_recrea.gph" ///
    "$figs/Renewable_capital__forest_water_.gph" ///
    "$figs/Renewable_capital__hydropower_en.gph" ///
    "$figs/Renewable_capital__nonwood_fores.gph" ///
   "$figs/Renewable_capital__timber.gph", ///
    col(4)

graph export "$figs/nine_NK_EU.png", replace
graph export "$figs/nine_NK_EU.pdf", replace


/*

@!#$!@$#@!$ 
@!#$!@$#@!$ 

Version with all separate regressions

@!#$!@$#@!$ 
@!#$!@$#@!$ 

*/


	
local lbl1 "Agricultural NK"
local lbl2 "Fisheries"
local lbl3 "Recreational Forests"
local lbl4 "Forest Water Ecosystems"
local lbl5 "Hydropower"
local lbl6 "Mangroves"
local lbl7 "Nonwood Forest Services"
local lbl8 "Timber"
local lbl9 "Total NK"



local nk_levels dlog_ag_NK dlog_fisheries dlog_rec_forests dlog_FWE dlog_Hydro dlog_Mangroves dlog_NFS dlog_Timber dlog_total_NK

local outcomes Renewable_capital__agricultural_ Renewable_capital__fisheries Renewable_capital__forest_recrea ///
              Renewable_capital__forest_water_ Renewable_capital__hydropower_en Renewable_capital__mangroves ///
			  Renewable_capital__nonwood_fores Renewable_capital__timber Renewable_capital__total

matrix r_2_separate = [.]

local i = 1
foreach lhs of local nk_levels {
	

	

	preserve
	
	local xlabel = "`lbl`i''"
    local NK_outcome : word `i' of `outcomes'
	//winsorize

	
	//run residualization regression
	reghdfe `lhs' d.log_K d.log_L d.log_HC if dlog_tfp!=., absorb(country_byte year) cluster(country_byte year) resid
	predict xb_residuals, resid
	
	
	//regression outcome on residuals
	      sum dlog_tfp
        replace dlog_tfp = dlog_tfp - r(mean)

	reg d.log_tfp xb_residuals, vce(cluster country_byte) noconstant
			matrix r_2_separate =   r_2_separate \ e(r2)    
 
	//slopes and p values for caption
	lincom xb_residuals
	local b: display %4.3f r(estimate)
	local p: display %4.3f r(p)
	
     //plot
  
	twoway (lfit dlog_tfp xb_residuals) ///
	(lpoly dlog_tfp xb_residuals, lcolor(orange)) ///
	(lowess dlog_tfp xb_residuals, lcolor(blue)) ///
	(scatter dlog_tfp xb_residuals , mfcolor(none) mlcolor(gray%20) msize(tiny) msymbol(circle)) ///
	, xtitle("Residual Variation in `xlabel'", size(small)) ///
	ytitle("TFP Growth", size(small)) ///
	legend(size(tiny) order(1 "Linear Fit, {&beta} = `b', {it:p}-value: `p'") ///
	region(fcolor(none) lcolor(none) margin(zero)) bplacement(5) ring(0)  ) ///
	saving("$figs/`NK_outcome'.gph", replace) 
	
	
	restore
		
	local ++i
}

	svmat r_2_separate

graph combine 
    "$figs/Renewable_capital__agricultural_.gph" ///
    "$figs/Renewable_capital__fisheries.gph" ///
    "$figs/Renewable_capital__forest_recrea.gph" ///
    "$figs/Renewable_capital__forest_water_.gph" ///
    "$figs/Renewable_capital__hydropower_en.gph" ///
    "$figs/Renewable_capital__nonwood_fores.gph" ///
	"$figs/Renewable_capital__mangroves.gph" ///
   "$figs/Renewable_capital__timber.gph", ///
   "$figs/Renewable_capital__total.gph", ///
col(3) imargin(none)


graph export " $figs/nine_NK_separate.png", replace 
graph export  "$figs/nine_NK_separate.pdf", replace 


/*

FAO ag TFP
*/

gen log_ag_TFP = ln(TFP_Index)
gen dlog_ag_TFP = d.log_ag_TFP

		
local lbl1 "Agricultural NK"
local lbl2 "Fisheries"
local lbl3 "Recreational Forests"
local lbl4 "Forest Water Ecosystems"
local lbl5 "Hydropower"
local lbl6 "Mangroves"
local lbl7 "Nonwood Forest Services"
local lbl8 "Timber"
local lbl9 "Total NK"


local nk_levels ///
    dlog_ag_NK ///
    dlog_fisheries ///
    dlog_rec_forests ///
    dlog_FWE ///
    dlog_Hydro ///
    dlog_Mangroves ///
    dlog_NFS ///
    dlog_Timber

local nk_changes ///
    dlog_ag_NK ///
    dlog_fisheries ///
    dlog_rec_forests ///
    dlog_FWE ///
    dlog_Hydro ///
    dlog_Mangroves ///
    dlog_NFS ///
    dlog_Timber

local outcomes Renewable_capital__agricultural_ Renewable_capital__fisheries Renewable_capital__forest_recrea ///
              Renewable_capital__forest_water_ Renewable_capital__hydropower_en Renewable_capital__nonwood_fores ///
             Renewable_capital__mangroves  Renewable_capital__timber Renewable_capital__total

local i = 1
    foreach lhs of local nk_levels {

        preserve

        //locals
        local xlabel = "`lbl`i''"
        local NK_outcome : word `i' of `outcomes'

        local rhs "`nk_changes'"
        local dropvar : word `i' of `nk_changes'
        local rhs : list rhs - dropvar

        reghdfe `lhs' ///
            `rhs' ///
            d.log_K d.log_L d.log_HC if dlog_ag_TFP != ., ///
            absorb(country_byte year) ///
            cluster(country_byte year) resid

        predict xb_residuals, resid

        //regression outcome on residuals
        reg dlog_ag_TFP xb_residuals, vce(cluster country_byte)


        //slopes and p values for caption
        lincom xb_residuals
        local b: display %4.3f r(estimate)
        local p: display %4.3f r(p)

        //plot
        sum dlog_ag_TFP
        replace dlog_ag_TFP = dlog_ag_TFP - r(mean)

        twoway ///
            (lfit   dlog_ag_TFP xb_residuals) ///
            (lpoly  dlog_ag_TFP xb_residuals, lcolor(orange)) ///
            (lowess dlog_ag_TFP xb_residuals, lcolor(blue)) ///
            (scatter dlog_ag_TFP xb_residuals, mfcolor(none) mlcolor(gray%20) msize(tiny) msymbol(circle)), ///
            xtitle("Residual Variation in `xlabel'", size(small) ) ///
            ytitle("Eurostat MFP Growth", size(small) ) ///
            legend( ///
                size(small)  ///
                order(1 "Linear Fit, {&beta} = `b', {it:p}-value: `p'") ///
                region(fcolor(none) lcolor(none) margin(zero)) ///
                bplacement(5) ring(0) ///
            ) ///
            saving("$figs/`NK_outcome'.gph", replace)

        restore
        local ++i
    }


graph combine ///
    "$figs/Renewable_capital__agricultural_.gph" ///
    "$figs/Renewable_capital__fisheries.gph" ///
    "$figs/Renewable_capital__forest_recrea.gph" ///
    "$figs/Renewable_capital__forest_water_.gph" ///
    "$figs/Renewable_capital__hydropower_en.gph" ///
    "$figs/Renewable_capital__nonwood_fores.gph" ///
	"$figs/Renewable_capital__mangroves.gph" ///
   "$figs/Renewable_capital__timber.gph", ///
    col(3)

graph export $figs/nine_NK_ag.png, replace
graph export $figs/nine_NK_ag.pdf, replace

