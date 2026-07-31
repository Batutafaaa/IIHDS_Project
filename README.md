# Forms of Employment Inequality: What Barriers are India's Marginalized Trapped In?

An econometric analysis of the **India Human Development Survey-II (IHDS-II, 2011-12)** investigating the heterogeneous mechanisms of employment marginalization across social groups (Muslims, Adivasis, and Dalits) in India.

## 📊 Project Overview

This project analyzes data from **204,568 individuals** across **371 districts** to move beyond uniform "binary" views of inequality. Our research Identifies three distinct "traps" that fragment the Indian labor market:

1.  **The Muslim Geographic Trap**: A quantity problem. Muslims suffer from geographic segregation in economically stagnant districts.
2.  **The Adivasi (ST) Subsistence Mirage**: A quality problem. High work intensity (distress employment) in subsistence economies masked by low per-job earnings.
3.  **The Dalit (SC) Distributed Barrier**: An access problem. Hiring discrimination and wage penalties that persist consistently across all geographies.

## 📁 Repository Structure & Analysis Pipeline

The analysis is organized into a sequential pipeline of R scripts located in the `scripts/` folder:

| Step | Script | Description |
|:---|:---|:---|
| 00 | `00_setup.r` | Dependency management, folder structure creation, and package setup. |
| Helper | `utils_functions.r` | Helper functions for modeling summaries and data formatting. |
| 01 | `01_data_loading.r` | Raw data ingestion and merging of IHDS-II individual and household RDA files. |
| 02 | `02_data_preparation.r` | Variable cleaning, recoding (education, groups, employment), and analytical subsetting. |
| 03 | `03_descriptive_stats.r` | Group-level descriptive statistics, wealth-work paradox, and urban/rural profiles. |
| 04 | `04_regression_models.r` | Core survey-weighted logistic regressions for employment. |
| 05 | `05_Interactions_ Subgroups.r` | Social capital interaction models (social group × organization membership). |
| 06 | `06_Marginal_Effects.r` | Computes Average Marginal Effects (AMEs) for the full sample. |
| 08 | `08_visualizations.r` | Renders diagnostic plots (wealth-work paradox, spatial correlations, heatmaps). |
| 09 | `09_robustness_checks.r` | Sensitivity checks (District FE LPM, exogenous controls, and survey-weighted District FE). |
| 10 | `10_geographic_analysis.r` | Spatial correlation and Muslim geographic trap analysis. |
| 11 | `11_sc_st_geographic_analysis.r` | Comparative geographic concentration and gap analyses for SC and ST groups. |
| 12 | `12_employment_quality.r` | Heckman selection-corrected wage regressions, contract types, and NREGA rates. |
| 13 | `13_urban_rural_dynamics.r` | Within-state urban-rural interaction regressions for employment and wages. |
| 07 | `07_final_report.r` | Consolidates results and outputs final report summaries. |


## 🛠️ Key Methodology

- **District Fixed Effects (FE)**: Used to isolate geographic effects from individual-level identity penalties.
- **Geographic Correlation Analysis**: Mapping group concentration against district-level economic outcomes.
- **Wage Regressions**: Controlling for education, age, gender, and location to estimate adjusted wage penalties.
- **Comparison/Falsification**: Using a three-way group comparison (Muslim-SC-ST) to validate historical and geographic narratives.

## 🚀 Getting Started

1.  Clone the repository:
    ```bash
    git clone https://github.com/ashwinnsr/IIHDS_Project.git
    ```
2.  Run the full analysis pipeline:
    ```r
    source("scripts/run_analysis.r")
    ```
    *Note: Ensure you have placed the IHDS-II `.rda` files in the root directory.*

## 📈 Visualizations
Key outputs are saved in `output/plots/`, including:
- **Wealth-Employment Paradox**: Bubble charts of economic distress vs. work.
- **Correlation Plots**: District concentration vs. employment rates.
- **Contract Distribution**: Informalization metrics across social groups.

## 📝 Submission & Reports
For the formal write-ups, refer to the `LaTeX_Submission/` folder, which contains the APA 7 formatted manuscript.

---
**License**: MIT  
**Author**: Ashwin Sreekumar (CHRIST Deemed to be University, Bangalore)
