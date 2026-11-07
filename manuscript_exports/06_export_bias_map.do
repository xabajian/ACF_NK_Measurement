* Corrected display ranges for saved absolute-bias results; no estimation.
preserve
set scheme plotplain

*============================================================*
* Panel A: Map
*============================================================*

use "$ACF_ANALYSIS/simulations/bias_rmse.dta", clear
keep if sdA != .

decode country_byte, gen(ISO3)

merge 1:1 ISO3 using "$ACF_ANALYSIS/maps/country_GIS_db_noAntarctica.dta", gen(merge)
* keep if merge == 3

* Rescale to basis points and reverse sign for color coding
replace bias_reduction = -bias_reduction*10000
assert inrange(bias_reduction,-1000,25) if !missing(bias_reduction)
assert merge != 1 if !missing(bias_reduction)

spmap bias_reduction using "$ACF_ANALYSIS/maps/country_GIS_coord_noAntarctica.dta", ///
    id(_ID) clmethod(custom) clbreaks(-1000 -100 -75 -50 -25 -5 0 25) ///
    fcolor(green green*0.5 green*0.4 green*0.3 green*0.2 green*0.1 blue*0.5) ///
    ndfcolor(gs15) ndocolor(black) ndsize(vvthin) ///
    legend(on size(small)) ///
    legtitle("Change in absolute bias" "(basis points)") ///
    text(83 -178 "{bf:a}", size(medsmall) placement(e)) ///
    plotregion(margin(zero)) ///
    graphregion(margin(zero)) ///
    name(panel_a_map_bias, replace)

graph save "$ACF_ANALYSIS/manuscript_exports/figs/panel_a_map_bias.gph", replace

*============================================================*
* Panel B: Histogram
*============================================================*

use "$ACF_ANALYSIS/simulations/bias_rmse.dta", clear
capture drop country_string
decode country_byte, gen(country_string)
keep if sdA != .

* Rescale to basis points
replace bias_reduction = bias_reduction*10000

sum bias_reduction, detail
count if bias_reduction > 100
//13


* Topcode and reverse sign for matching display convention
gen bias_topcode = min(bias_reduction, 100.0001)
local p90_in = -100
local p90_d: display %4.0f `p90_in'
replace bias_topcode = -1*bias_topcode

twoway ///
    (hist bias_topcode if bias_topcode < 0, ///
        color(green%50) lcolor(olive%80) freq width(5) start(-105)) ///
    (hist bias_topcode if bias_topcode > 0, ///
        color(blue%50) lcolor(navy%80) freq width(5) start(-105)), ///
    xline(0, lpattern(dash) lcolor(gray%80)) ///
    xscale(range(-110 5)) ///
    xlabel(`p90_in' -75 -50 -25 0 25, nogrid labsize(small)) ///
    ylabel(0(10)50, nogrid labsize(small) axis(1)) ///
    ytitle("Number of Countries") ///
    xtitle("Change in absolute bias (basis points)") ///
    text(17 -105 "{&Delta}|Bias| > 100 bps", size(vsmall)) ///
    text(51 -108 "{bf:b}", size(medsmall) placement(e)) ///
    legend(off) ///
    graphregion(margin(zero)) ///
    name(panel_b_hist_bias, replace)

graph save "$ACF_ANALYSIS/manuscript_exports/figs/panel_b_hist_bias.gph", replace

*============================================================*
* Combine vertically and export
*============================================================*

graph combine "$ACF_ANALYSIS/manuscript_exports/figs/panel_a_map_bias.gph" "$ACF_ANALYSIS/manuscript_exports/figs/panel_b_hist_bias.gph", ///
    cols(1) ///
    imargin(tiny) ///
    graphregion(margin(zero)) ///
    name(figure_map_hist_vertical_bias, replace)

graph export "$ACF_ANALYSIS/manuscript_exports/figs/figure_map_hist_vertical_bias.pdf", replace

graph export "$ACF_ANALYSIS/manuscript_exports/figs/figure_map_hist_vertical_bias.png", replace width(2400)


restore
