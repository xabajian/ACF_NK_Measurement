* Run ONE existing analysis script, capturing country counts after esttab.
* This runs the actual analysis and can take hours for bootstrap/MC scripts.
* Example: do ".../30_run_analysis.do" "0_CWON_Regs.do"
* Then run 00_publish.do after all desired analysis stages have completed.
args script analysis manuscript
if `"`script'"' == "" {
    display as error "Supply an existing scripts/*.do filename."
    exit 198
}
if `"`analysis'"' != "" global ACF_ANALYSIS `"`analysis'"'
if `"`manuscript'"' != "" global ACF_MANUSCRIPT `"`manuscript'"'
if "$ACF_ANALYSIS" == "" global ACF_ANALYSIS "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
do "$ACF_ANALYSIS/manuscript_exports/config.do"
local initial_pwd `"`c(pwd)'"'
tempfile runner success
shell "$ACF_PYTHON" "$ACF_ANALYSIS/manuscript_exports/prepare_run.py" --analysis "$ACF_ANALYSIS" --script "`script'" --output "`runner'" --success-marker "`success'"
confirm file "`success'"
capture noisily do "`runner'"
local result = _rc
cd `"`initial_pwd'"'
if `result' exit `result'
display as result "Analysis completed. Run 00_publish.do to refresh the manuscript."
