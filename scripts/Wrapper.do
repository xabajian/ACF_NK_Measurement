clear all
set maxvar 32000
set seed 1234

*===============================*
* Paths / globals
*===============================*
cd "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/scripts"

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

Set directories where applicable 

One probably needs to batch replace all of the "root" macros in the .do files using something like the bash command


find . -type f -exec sed -i '' 's/old-text/new-text/g' {} +


after setting your pwd to ACF_NK_Measurement/scripts.

@!#$!@#$#@!$@!#$#!#
@!#$!@#$#@!$@!#$#!#
*/

do 0_CWON_Regs.do			
cd "$root/scripts"

do 0_PWT_XSection.do		
cd "$root/scripts"

do 1_Make_Tornqvist_Indices.do	
cd "$root/scripts"
	
do 2_Tornqvist_Indices_Regs.do	
cd "$root/scripts"

do 3_sim_bias_program.do		
cd "$root/scripts"

do 4_make_appendix_overlay_table.do
cd "$root/scripts"

do 5_Figure2.do
cd "$root/scripts"

do 6_RMSE_correlations.do
cd "$root/scripts"
