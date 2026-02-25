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
| 00 | `00_setup.r` | Dependency management and environment setup. |
| 01 | `01_data_loading.r` | Raw data ingestion (IHDS-II rda files). |
| 02 | `02_data_preparation.r` | Variable cleaning, recoding, and subsetting. |
| 03 | `03_descriptive_stats.r` | Initial group-level summary and wealth-work paradox analysis. |
| 04 | `04_regression_models.r` | Core logistic and OLS models for employment and earnings. |
| 05 | `05_Interactions_Subgroups.r` | Complex interaction effects and heterogeneity checks. |
|  07 | `07_final_report.r` | Generation of tabular results and regression summaries. |
| 08 | `08_visualizations.r` | Code for generating the core diagnostic plots. |
| 09 | `09_robustness_checks.r` | Validation of results across different model specifications. |
| 10 | `10_geographic_analysis.r` | District-level correlation and Muslim geographic trap analysis. |
| 11 | `11_sc_st_geographic_analysis.r` | Comparative geographic analysis for SC and ST groups. |
| 12 | `12_employment_quality.r` | Analysis of contract types, informality, and formal benefits. |

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
