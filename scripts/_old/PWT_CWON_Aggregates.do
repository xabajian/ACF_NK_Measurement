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


use "FR_WLD_2024_195/wealth_asset_long.dta", clear

keep countrycode countryname unit series year id torn_real_renew torn_real_nonrenew


/*
merge PWT and other datasets
*/
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

//FAO TFP panel
merge 1:1 year countrycode using "UN_FAO_TFP_panel.dta", gen(merge_UNFAO)
drop if merge_UNFAO==2



/*
1.2 -- prep data
*/
encode countrycode, gen(country_byte)
drop if country_byte == .

xtset country_byte year

//PWT variables for growth within countires over timea
gen log_tfp = ln(rtfp)
gen log_K   = ln(rkna)
gen log_L   = ln(emp)
gen log_HC  = ln(hc)
gen log_lab_share  = ln(labsh)
gen log_y   = ln(rgdpo)

replace UK_MFP = ln(UK_MFP)

gen log_eurostat_MFP = ln(mfp)

gen dlog_tfp = d.log_tfp

/*
generate logdiff of welath
*/
//change in renewable stocks assuming stocks proxy services
gen log_R_NK = ln(torn_real_renew)
gen dlog_R_NK = d.log_R_NK

//for non-renewables, the change in the *stock* is equal to the flow
gen d_NR_cap_level = d.torn_real_nonrenew

gen log_NR_NK = ln(torn_real_nonrenew)
gen dlog_NR_NK = d.log_NR_NK





//EU
gen dlog_eurostat_MFP = d.log_eurostat_MFP

/*
FAO ag TFP
*/

gen log_ag_TFP = ln(TFP_Index)
gen dlog_ag_TFP = d.log_ag_TFP


/*
@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#

Step 2 -- Model Selection and 

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/


/*
!@#$@!$#@!$@#$!@#$2
Step 2.1 --- LASSOs
!@#$@!$#@!$@#$!@#$2


//no winsor lasso
cvlasso d.log_tfp dlog_R_NK dlog_NR_NK //z/
      d.log_K d.log_L d.log_HC d.log_lab_share i.year, ///
        fe 
cvlasso, lopt



//winsor lasso
preserve
    sum dlog_tfp, d
    keep if dlog_tfp <= r(p95) & dlog_tfp >= r(p5)
cvlasso d.log_tfp d.log_R_NK d.log_NR_NK ///
      d.log_K d.log_L d.log_HC i.year, ///
        fe 
cvlasso, lopt
restore




preserve 
keep if log_tfp!=.
duplicates drop country_byte, force
list 	countryname
restore
	*/	
   
/*
!@#$!@$@
2.2 --- regressions
!@#$#!@$
*/


reghdfe d.log_y dlog_R_NK dlog_NR_NK ///
		d.log_K d.log_L d.log_HC d.log_lab_share, ///
        absorb(country_byte year) vce(cluster country_byte year)
		
reghdfe d.log_tfp dlog_R_NK , ///
        absorb(country_byte year) vce(cluster country_byte year)

reghdfe d.log_tfp dlog_R_NK ///
		d.log_K d.log_L d.log_HC d.log_lab_share, ///
        absorb(country_byte year) vce(cluster country_byte year)
		
pcorr d.log_y dlog_R_NK dlog_NR_NK  d.log_K  d.log_L d.log_HC d.log_lab_share ///
       i.country_byte i.year
	   
pcorr d.log_y dlog_total_NR_NK dlog_total_NK  d.log_K  d.log_L d.log_HC 	   
	   
pcorr d.log_tfp dlog_total_NR_NK dlog_total_NK  d.log_K  d.log_L d.log_HC ///
       i.country_byte i.year 
