* Run every .do file in scripts sequentially, excluding this wrapper.
* Default: run the full pipeline (including sensitivity analyses).
* Preview only: do "/path/to/scripts/Wrapper.do" list
clear all
set maxvar 32000
set seed 1234
set more off
args mode
if !inlist("`mode'", "", "list") {
    display as error "Use no argument to run, or list to preview the sequence."
    exit 198
}

* Keep paths in caller-local macros: child scripts change globals and directories.
local wrapper_root "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
local wrapper_scripts "`wrapper_root'/scripts"
local wrapper_files : dir "`wrapper_scripts'" files "*.do"
local wrapper_files : list sort wrapper_files
local wrapper_count = 0
foreach wrapper_file of local wrapper_files {
    if lower("`wrapper_file'") != "wrapper.do" {
        local ++wrapper_count
    }
}
if `wrapper_count' == 0 {
    display as error "No analysis do-files found in `wrapper_scripts'."
    exit 601
}

local wrapper_step = 0
foreach wrapper_file of local wrapper_files {
    if lower("`wrapper_file'") == "wrapper.do" continue
    local ++wrapper_step
    display as text "[`wrapper_step'/`wrapper_count'] `wrapper_file'"
    if "`mode'" == "list" continue

    * Re-establish shared paths before each script, including those it inherits.
    global root "`wrapper_root'"
    global scripts "`wrapper_scripts'"
    global figs "$root/figs"
    global tables "$root/tables"
    global raw "$root/raw"
    global processed "$root/processed"
    global sim_dir "$root/simulations"
    global map_dir "$root/maps"
    foreach wrapper_dir in quantities tables figs simulations processed {
        capture mkdir "`wrapper_root'/`wrapper_dir'"
    }
    cd "`wrapper_scripts'"
    capture noisily do "`wrapper_scripts'/`wrapper_file'"
    local wrapper_rc = _rc
    cd "`wrapper_scripts'"
    if `wrapper_rc' {
        display as error "Stopped at `wrapper_file' (Stata error `wrapper_rc')."
        exit `wrapper_rc'
    }
}
if "`mode'" == "list" {
    display as result "Listed `wrapper_count' scripts; no analysis scripts were run."
}
else {
    display as result "Completed all `wrapper_count' scripts."
}
