# Abajian, Conte, and Fenichel (ACF 2026)

Read me file accompanying the scripts required to replicate findings in the main text and supplementary information for “Omitting the environment as an input biases measurement of economic productivity” (ACF 2026).

Replication files for the peer review responses are available from xander.abajian@gmail.com on request.

## Setup

Scripts in this repository are written in Stata. Throughout this document, it is assumed that the replicator operates from a working directory containing all the necessary files and folders detailed in the structure below. Data are small enough to be included in the github repo. to run the Stata scripts, this folder should be set as the root directory and the global macro $root should correspond to the folder containing all files in "ACF_NK_Measurement". 
(IE,  global root "{~/ACF_NK_Measurement}" needs to be run).

## Requirements

All programs are run in the following versions of these applications:

* Stata: Stata/SE 18.5 for Mac 

and were executed on Mac OS 26.2 (Tahoe). Programs must be run in the order in which they appear in the directory. Running all files associated with the main manuscript takes 5-10 minutes in total on an average laptop.

Running the Stata scripts requires

* REGHDFE
* ESTAB
* ESTAB2

# File Tree 

```bash
├── processed
│   ├── CWON_data.dta
│   ├── euro_area_mfp_panel_iso.dta
│   ├── pwt100_xsection.dta
│   ├── pwt100.dta
│   ├── real_wealth_chained_tornqvist_unbalanced.dta
│   ├── renewable_quantities.dta
│   ├── ritest1.dta
│   ├── tornqvist_panel.dta
│   ├── UN_FAO_TFP_panel.dta
│   └── US_MFP.dta
├── raw
│   ├── Eurostat MFP
│   │   └── Crude-MFP-calculations-by-country.xlsx
│   └── FR_WLD_2024_195
│       ├── LICENSE.txt
│       ├── README.pdf
│       ├── Repoducibility verification-RR_WLD_2024_195.pdf
│       └── Reproducibility package
│           ├── Data Dictionary.xlsx
│           ├── Output
│              ... [full CWON Data]
├── scripts
│   ├── ~0_Make_Tornqvist_Indices.do.stswp
│   ├── ~3_Figure1.do.stswp
│   ├── 0_Make_Tornqvist_Indices.do
│   ├── 1_CWON_Producivity_RegsQuantity_RHS.do
│   ├── 2_Tornqvist_Indices_Regs.do
│   ├── 3_Figure1.do
│   ├── overlay1.do
│   ├── overlay2.do
│   ├── overlay3.do
│   ├── overlay4.do
│   ├── RMSE Program Case1.do
│   ├── RMSE Program Case2.do
│   ├── RMSE Program Case3.do
│   └── RMSE Program Case4.do
├── simulations
│   ├── country_tab.tex
│   ├── CWON_data.dta
│   ├── four_cases_overlay.pdf
│   ├── four_cases_overlay.png
│   ├── oos_means1.dta
│   ├── oos_means2.dta
│   ├── oos_means3.dta
│   ├── oos_means4.dta
│   ├── overlay1.gph
│   ├── overlay2.gph
│   ├── overlay3.gph
│   ├── overlay4.gph
│   ├── RMSE_N1_N2_case1.dta
│   ├── RMSE_N1_N2_case2.dta
│   ├── RMSE_N1_N2_case3.dta
│   └── RMSE_N1_N2_case4.dta
```


# Description of Scripts to Replicate our Analysis

The Stata scripts all contain numerical prefixes. These prefixes denote the order they should be run in. 

# "~/IEA Data Processing"

This directory contains all scripts required to process the raw IEA data into the emissions factors used in our analysis. In summary, these files create average emissions factors at the country-year-fuel level by creating a consumption-weighted average of emissions factors across each primary-fuel _r_ listed in the IEA data consumed in sectors outside of transportation. The mathmatical process amounts to solving equation (5) of our methods section many times as described in section 5.2.

The dataset that these files take as an argument is proprietary. The Emissions Intensities Report (EIR) from the International Energy Agency (IEA 2021 in our manuscript) is not publicly available. It is available for purchase here https://www.iea.org/data-and-statistics/data-product/emissions-factors-2021. It is our external source for the emissions intensities (kgCO2 emitted per kWh of final energy produced) at the primary fuel level. We use this in tandem with the IEA's World Energy Balances (WEB( data series (IEA 2022 -- https://www.iea.org/data-and-statistics/data-product/world-energy-balances) to construct our empirical measures of the consumption-weighted averages in equation (5) of our methods section.



### Descriptions

## Section 2 - Regressions of TFP on renewables

- `1_CWON_Producivity_RegsQuantity_RHS` — Runs regressions of TFP on renewables in section 2

## Section 3 - Tornqvist indices

- `0_Make_Tornqvist_Indices` — Creates tornqvist indices from raw CWON data.
- `2_Tornqvist_Indices_Regs' - solves for average growth rates of Tornqvist indices across countries to be used to place them in Figure 1. Runs regressions of TFP and output on our two tornqvist indices that appear in the SM. 

## Figures

- `3_Figure1` - Assembles Figure 1 and a few appendix tablers
- `RMSE Program Case*`- Runs casewise simulations described in appendix
- `overlay*` - creates overlays of ISO codes on simulated heatmaps 

# Data Descriptions

##  Raw

Raw files used as inputs  

1. `FR_WLD_2024_195'


## Processed

CWON_data.dta
euro_area_mfp_panel_iso.dta
pwt100_xsection.dta
pwt100.dta
real_wealth_chained_tornqvist_unbalanced.dta
renewable_quantities.dta
ritest1.dta
tornqvist_panel.dta
UN_FAO_TFP_panel.dta
US_MFP.dta


Finished files that store the results from various procedures documented in the methods section (manuscript section 5) or the SI. 


## Attribution 
 ...
