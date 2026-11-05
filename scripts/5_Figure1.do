*============================================================*
* Combined Figure: Map over Histogram (absolute bias)
* Panel A = map; Panel B = histogram
*============================================================*

clear all
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts"

global root "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
global figs   "$root/figs"
global tables "$root/tables"
global raw "$root/raw"
global processed "$root/processed"
global sim_dir "$root/simulations"
global map_dir "$root/maps"

set scheme plotplain

*============================================================*
* Panel A: Map
*============================================================*

use "$sim_dir/bias_rmse.dta", clear
export delimited using "$sim_dir/bias_rmse.csv", replace
keep if sdA != .

decode country_byte, gen(ISO3)

merge 1:1 ISO3 using "$map_dir/country_GIS_db_noAntarctica.dta", gen(merge)
* keep if merge == 3

* Rescale to basis points and reverse sign for color coding
replace bias_reduction = -bias_reduction*10000

spmap bias_reduction using "$map_dir/country_GIS_coord_noAntarctica.dta", ///
    id(_ID) clmethod(custom) clbreaks(-500 -100 -75 -50 -25 -5 0 5) ///
    fcolor(green green*0.5 green*0.4 green*0.3 green*0.2 green*0.1 blue*0.5) ///
    ndfcolor(gs15) ndocolor(black) ndsize(vvthin) ///
    legend(on size(small)) ///
    legtitle("Change in absolute bias" "(basis points)") ///
    text(83 -178 "{bf:a}", size(medsmall) placement(e)) ///
    plotregion(margin(zero)) ///
    graphregion(margin(zero)) ///
    name(panel_a_map_bias, replace)

graph save "$figs/panel_a_map_bias.gph", replace

*============================================================*
* Panel B: Histogram
*============================================================*

use "$sim_dir/bias_rmse.dta", clear
capture drop country_string
decode country_byte, gen(country_string)
export delimited using "$sim_dir/bias_rmse.csv", replace
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
    text(15 -105 "{&Delta}|bias| > 100 bps", size(vsmall)) ///
    text(51 -108 "{bf:b}", size(medsmall) placement(e)) ///
    legend(off) ///
    graphregion(margin(zero)) ///
    name(panel_b_hist_bias, replace)

graph save "$figs/panel_b_hist_bias.gph", replace

*============================================================*
* Combine vertically and export
*============================================================*

graph combine "$figs/panel_a_map_bias.gph" "$figs/panel_b_hist_bias.gph", ///
    cols(1) ///
    imargin(tiny) ///
    graphregion(margin(zero)) ///
    name(figure_map_hist_vertical_bias, replace)

graph export "$figs/figure_map_hist_vertical_bias.pdf", replace

graph export "$figs/figure_map_hist_vertical_bias.png", replace width(2400)

