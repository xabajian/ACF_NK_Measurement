# Publish analysis outputs to the manuscript

Run this in Stata after the desired analysis scripts have finished:

```stata
do "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/manuscript_exports/00_publish.do"
```

This exports existing results. It does **not** re-estimate regressions or rerun simulations. It requires Python 3 (standard library only), available as `python3`, and writes directly to the sibling manuscript repository:

- `ACF_Manuscript/tables/generated/`: 20 formatted LaTeX table includes, an export report, and source hashes.
- `ACF_Manuscript/figs/generated/`: 16 figures used by the two `.chat.tex` documents.

Both `0.main.chat.tex` and `0.SI.chat.tex` now read these relative paths, so Overleaf needs only the manuscript repository. Commit/sync the generated files and the edited `.chat.tex` files through your usual workflow; select the appropriate `.chat.tex` file as the Overleaf main document. There is no automatic Git commit, push, or Overleaf upload.

## Formatting and data ownership


The original table layouts, captions, labels, controls rows, notes, spacing, and font sizes live in **the manuscript repository's `tables/templates/`**. Edit those templates to change presentation, then rerun the publisher. Tokens such as `@@row0_b@@` mark generated cells. Do not edit `tables/generated/`: the next run replaces it.

The publisher maps Stata variable names to manuscript row labels, imports coefficients, standard errors, Wald/bootstrapped p-values and observation counts, and preserves the manuscript's star convention. The `990` bootstrap placeholder becomes `--`. Regression table wrappers from `esttab` are discarded so they do not create nested floats or duplicate captions. Country results are inserted into the existing multipage `longtable` with repeated headers. The malformed `\def#1` declarations in the original SI table blocks were corrected to `\def\sym#1`.

Of the 20 tables, **13 refresh from analysis outputs** (11 regression tables, the additional Wald tests, and the country-level results). The other **7 are editorial/descriptive tables**, retained verbatim in templates. This includes the covered-country list, resource descriptions/missingness summaries, and simulation-moment definitions; no corresponding machine-readable table exports were found for those. Their numbers and lists still require review if the sample or data construction changes.

Narrative findings, numeric claims in captions, and controls descriptions remain authored text. Review them when results or specifications change. This exporter does not infer changes to econometric specifications from coefficients.

## Country counts on future runs

Legacy `esttab` outputs omit country counts. For the initial export, the publisher retains manuscript country counts **only when both the entire source file hash and observation counts match the recorded baseline**. These retained counts have not been independently verified. If a result file changes and no valid metadata is present, its country row displays `--` and the report identifies it; old counts are never silently reused for a changed source. The agricultural TFP table currently has changed observation counts and therefore displays `--` for countries.

For fully automatic, sample-specific country counts, run the regression-producing scripts through the supplied wrapper:

```stata
do "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/manuscript_exports/30_run_analysis.do" "0_CWON_Regs.do"
do "/Users/xabajian/Documents/GitHub/ACF_NK_Measurement/manuscript_exports/30_run_analysis.do" "2_Tornqvist_Indices_Regs.do"
```

These commands **run the actual original analysis** and can be lengthy. Run the relevant prerequisite data-preparation stages first. The wrapper makes a temporary copy of the selected script and adds sample-capture calls immediately after `esttab` exports. It does not edit the original scripts. The hook restores each model, counts distinct `country_byte` values in `e(sample)`, and writes a `tables/<source>.sample_counts.json` sidecar bound to that exact table's SHA-256 hash. After the remaining figure/simulation stages are complete, run `00_publish.do`.

The wrapper also accepts other existing `scripts/*.do` filenames, but only the two regression-producing scripts receive country-count hooks. It propagates analysis errors and restores the original working directory. It does not repair pre-existing analysis failures or missing dependencies.

## Entry points

| File | Purpose |
|---|---|
| `00_publish.do` | Export all currently saved manuscript tables and figures |
| `10_export_tables.do` | Export tables only |
| `20_export_figures.do` | Export figures only |
| `30_run_analysis.do` | Run one existing analysis script; capture model samples where supported |
| `40_capture_samples.do` | Internal sample-capture helper |
| `config.do` | Shared paths and Python executable |
| `manifest.json` | Exact source-to-template/figure mappings and baseline values |
| `publish.py` | Formatting, validation, export report, and file publication |

To use another checkout, pass the two repository paths to `00_publish.do`, or set `ACF_ANALYSIS` and `ACF_MANUSCRIPT` globals. Set `ACF_PYTHON` to an absolute Python executable if `python3` is not on Stata's shell path. All `.do` scripts are independent of the current working directory.

You can also publish without Stata:

```sh
python3 manuscript_exports/publish.py
python3 manuscript_exports/publish.py --check
```

All source files and template substitutions are validated before destination files are written. A missing figure, missing coefficient, malformed numeric cell, unexpected coefficient row, or invalid p-value aborts the export. Each destination is replaced atomically. The report documents baseline changes; provenance records the exact imported files and their hashes. The check does not establish that saved outputs are all from the same analysis run: run the relevant analysis stages together when consistency across results is required.

## Sources and decisions to review

- Main renewable regression and SI robustness tables: `tables/tab1*.tex` from `scripts/0_CWON_Regs.do` or `scripts/2_Tornqvist_Indices_Regs.do`.
- SI output/index regression: `tables/appendix_tornq_regs.tex` (not `main_tornq_regs.tex`, which has a TFP outcome).
- Additional Wald tests: `tables/wald_bootstrap_pvalues.tex`.
- Country-level results: `tables/country_tab.tex` from `scripts/4_make_appendix_overlay_table.do`. The original malformed standalone header is discarded. Names are supplied by `country_names.json`; new unmapped codes stop the export for an explicit name update.
- RMSE decomposition: `tables/app_tab_decomp.tex` from `scripts/5_Figure2_RMSE.do`. That source uses conventional OLS errors; its manuscript note now says OLS standard errors instead of robust errors.
- The current all-natural-capital sources exclude urban land. Their obsolete Urban Land rows were removed. `DQ_prod_area` is mapped to Timber Land and `DQ_land` to Agricultural Land, correcting the pasted row-label mismatch.
- The main map and overlay now use the explicit `_bias.pdf` files. The SI includes separate bias and RMSE decomposition tables and FWL figures. Both saved decomposition regressions and FWL plots use positive reductions (model 1 minus model 2). The publisher copies coefficient signs unchanged. Rerun the Step 2 table exports after changing this convention; legacy negative-reduction tables must not be published with the positive-reduction mappings.
- Appendix correlation PDFs (`Bias_Correlations.pdf` and `RMSE_Correlations.pdf`) are copied from `figs/` and included separately in the SI. Together with the two MSE diagnostic PDFs, all four final PDF outputs of `scripts/6_appendix_figures.do` are published. PNG duplicates and intermediate `.gph` panels are not needed by Overleaf. Rerun the script before publishing to refresh these figures.
- RMSE diagnostic PDFs are now copied directly from `figs/RMSE_decomp1.pdf` and `figs/RMSE_decomp2.pdf`, produced by `scripts/6_appendix_figures.do`. Rerun that analysis script after edits before publishing. Neither publishing wrapper calls `05_export_diagnostics.do`; that helper is retained only as an unused historical fallback. The separate bias-map correction still runs.
- The country table now reads `simulations/bias_rmse.csv`, exported by the main figure script, instead of the stale `tables/country_tab.tex`. Re-run the figure script after simulations to refresh this CSV. The current manuscript revision verified that the CSV agrees with the DTA for all 103 countries.
- The GDP and agricultural TFP outputs differ materially from some pasted values. The source filenames and variable names determine the exports; see `tables/generated/export_report_all.md` for detailed numeric changes. Check the associated prose and captions before submission.
- Existing `scripts/Wrapper.do` references several filenames absent from this checkout. It was not changed or used as the publication entry point.

## Validation

`python3 manuscript_exports/test_publish.py` tests numerical substitution, significance formatting, uncomputed bootstrap values, invalid p-values, missing coefficients, column mismatches, and stale country metadata. The Stata publishing entry point and country-count helper have also been exercised with StataNow. The expensive original estimation and simulation pipeline was not rerun during setup.

The main Figure 2 caption now describes its current histogram panel (f). The map caption no longer hardcodes an outdated topcoded-country count or SI table number. Small table-spacing adjustments keep the multipage country table and wide descriptive tables within the page. Both edited documents compile through PDFLaTeX and Biber; existing duplicate labels (`sec:main4` and `subsec:rf_decomp`) remain warnings.

- `06_export_bias_map.do` rebuilds the bias map from saved results with color intervals spanning the current extrema (-1000 to +25 basis points in the change convention). Assertions prevent future out-of-range or unmatched country observations from silently disappearing. It runs automatically in the all/figures publishing wrappers.
- Country table reductions are published in basis points (one decimal); growth rates and correlations retain their existing units.

## Integrated robustness revision (2026-11-05)

The SI now includes the current bias Monte Carlo files (`bias_MC.pdf`, `MC_gamma1_bias.pdf`, `MC_gamma2_bias.pdf`) instead of legacy RMSE Monte Carlo outputs. Sample-period bias figures and the simulation robustness summary were recovered from current routines and calibration files; audit CSVs and source hashes are in `verification/2026-11-05`. Those two figures and the editorial summary table are saved audit outputs, not automatically recomputed by the publisher. Refresh them after changes to the underlying simulations. The latest manuscript explicitly qualifies the still-100-country Monte Carlo sampling.
