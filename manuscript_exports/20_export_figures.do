* Publish existing results; does not run the estimation/simulation pipeline.
* Optional arguments: analysis repository, manuscript repository.
args analysis manuscript
if `"`analysis'"' != "" global ACF_ANALYSIS `"`analysis'"'
if `"`manuscript'"' != "" global ACF_MANUSCRIPT `"`manuscript'"'
if "$ACF_ANALYSIS" == "" global ACF_ANALYSIS "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
do "$ACF_ANALYSIS/manuscript_exports/config.do"
* RMSE decomposition PDFs come from scripts/6_appendix_figures.do.
* Rerun that script after changing the analysis; exports copy its saved PDFs.
do "$ACF_ANALYSIS/manuscript_exports/06_export_bias_map.do"
tempfile success
shell "$ACF_PYTHON" "$ACF_ANALYSIS/manuscript_exports/publish.py" --analysis "$ACF_ANALYSIS" --manuscript "$ACF_MANUSCRIPT" --mode figures --success-marker "`success'"
capture confirm file "`success'"
if _rc {
    display as error "Export failed. See the Python error above; no success was recorded."
    exit 198
}
display as result "Manuscript figures exports complete."
