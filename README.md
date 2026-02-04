# Abajian, Conte, and Fenichel (ACF 2026)

Readme file accompanying the scripts required to replicate findings in the main text and supplementary information for “Omitting the environment as an input biases measurement of economic productivity” (ACF 2026).

Replication files for the peer review responses are available from xander.abajian@gmail.com on request.

## Setup

Scripts in this repository are written in Stata. It's assumed that the replicator operates from a working directory containing all the necessary files and folders detailed in the structure below. Data are small enough to be included in the GitHub repo. To run the Stata scripts, this folder should be set as the root directory and the global macro $root should correspond to the folder containing all files in "ACF_NK_Measurement" (i.e.,  global root "{~/ACF_NK_Measurement}" needs to be run). Scripts will not run out of order (more below_).

## Requirements

All programs are run in the following versions of these applications:

* Stata: Stata/SE 18.5 for Mac 

and were executed on Mac OS 26.2 (Tahoe). Programs must be run in the order in which they appear in the directory. Running all files associated with the main manuscript takes about a day on a new laptop because the simulations are performed in stata and it's not particularly efficient at simulating data. Programs outside of the simulations should take 5-10 minutes because of the interpolation process fitting simulated TFP errors to each country. Outside of that, reading in data/building indices/running regressions should run instantaneously, give or take.

Running the Stata scripts requires

* REGHDFE
* ESTAB
* ESTAB2

# File Tree 

```bash
├── raw
│   ├── euro_area_mfp_panel_iso.dta
│   ├── FR_WLD_2024_195 [CWON DATA]
      ...
│   ├── pwt100_xsection.dta
│   ├── pwt100.dta
│   ├── renewable_wealth.dta
│   └── UN_FAO_TFP_panel.dta
├── README.md
├── scripts
│   ├── 0_CWON_Producivity_RegsQuantity_RHS.do
│   ├── 1_Make_Tornqvist_Indices.do
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
```
NB: additional folders "processed", "figs", "tables", "simulations", and "quantities" will be made by script 0_CWON_Producivity_RegsQuantity_RHS.do.

# Description of Scripts to Replicate our Analysis

The "scripts" folder contains all scripts that are used to generate findings in the paper and SM. Scripts all contain numerical prefixes. These prefixes denote the order they should be run in. They must be run in this order.

### Descriptions

Scripts run in this order do the following things:


## Section 2 - Regressions of TFP on renewables

- `0_CWON_Producivity_RegsQuantity_RHS` — Creates all directories listed above. Reads in quantities of seven renewable resources of interest from CWON raw data. Runs regressions of TFP on renewables in Section 2 of the manuscript (i.e., Table 1). Saves these quantities out for use when constructing Tornqvist indices.

## Section 3 - Tornqvist indices

- `1_Make_Tornqvist_Indices` — Creates tornqvist indices from raw CWON data.
- `2_Tornqvist_Indices_Regs` - Solves for average growth rates of Tornqvist indices across countries to be used to place them in Figure 1. Runs regressions of TFP and output on our two tornqvist indices that appear in the SM. 

## Figures

- `3_Figure1` - Assembles Figure 1 and a few appendix tables. This program is a wrapper which calls the following .do files:
      - `RMSE Program Case*`- Runs casewise simulations described in SM
      - `overlay*` - creates overlays of ISO codes on simulated heatmaps 

# Data Descriptions

1. `FR_WLD_2024_195` Folder -- CWON datatset. Take from here: [https://data360.worldbank.org/en/dataset/WB_CWON](CWON LINK)
2. `euro_area_mfp_panel_iso.dta` -- Eurostat experimental MFP series. Taken from here: https://ec.europa.eu/eurostat/documents/7894008/13933430/Crude-MFP-calculations-by-country.xlsx/b47324d8-7ae0-d3ac-32f8-873d188c3811?t=1639061621807
3. `pwt100.dta` -- PWT version 10.01, https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt1001
4. `pwt100_xsection.dta` -- cross section of PWT
5. `real_wealth_chained_tornqvist_unbalanced.dta` -- Read in from `FR_WLD_2024_195` folder. CWON version of tornqvist quantity indices that are in the wealth index dataset
5. `assets_volume_variables.dta` -- Read in from `FR_WLD_2024_195` folder. CWON panel opf renewable assert quantities at country level over time
6. `renewable_wealth.dta` -- Collapsed version of above file containing only renewables for convenience when merging to build weights for our index
7. `UN_FAO_TFP_panel.dta` -- Panel of agricultural TFP for 161 countries taken from the USDA ERS. Taken from here: https://www.ers.usda.gov/data-products/international-agricultural-productivity


## Attribution 

\lipsum[1]
