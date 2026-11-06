* Called immediately after an esttab export by an instrumented analysis run.
* Capture actual estimation samples; no re-estimation and no sample inference.
args source models
local original_model : word `: word count `models'' of `models'
tempfile sample_csv success
tempname fh
file open `fh' using "`sample_csv'", write text replace
file write `fh' "model,observations,countries" _n
foreach model of local models {
    estimates restore `model'
    local n = e(N)
    tempvar tag
    quietly egen byte `tag' = tag(country_byte) if e(sample)
    quietly count if `tag' == 1
    local countries = r(N)
    drop `tag'
    if `countries' == 0 {
        file close `fh'
        display as error "No country sample recovered for `model'."
        exit 459
    }
    file write `fh' "`model',`n',`countries'" _n
}
file close `fh'
estimates restore `original_model'
shell "$ACF_PYTHON" "$ACF_ANALYSIS/manuscript_exports/capture_samples.py" "`source'" "`sample_csv'" "`success'"
confirm file "`success'"
