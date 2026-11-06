* Shared paths. Override globals before running, or pass paths to 00_publish.do.
if "$ACF_ANALYSIS" == "" global ACF_ANALYSIS "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement"
if "$ACF_MANUSCRIPT" == "" global ACF_MANUSCRIPT "/Users/xabajian/Documents/GitHub/ACF_Manuscript"
if "$ACF_PYTHON" == "" global ACF_PYTHON "python3"
confirm file "$ACF_ANALYSIS/manuscript_exports/publish.py"
confirm file "$ACF_MANUSCRIPT/0.main.chat.tex"
confirm file "$ACF_MANUSCRIPT/0.SI.chat.tex"
