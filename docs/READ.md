# Social & Cultural Capital Effects on Employment in Rural India

[![R Version](https://img.shields.io/badge/R-%E2%89%A5%204.0.0-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-active-success.svg)]()

> **Analyzing the multidimensional disadvantages faced by Muslim communities in rural Indian labor markets through social and cultural capital frameworks**

---

## 📋 Table of Contents

- [Overview](#overview)
- [Key Findings](#key-findings)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Data](#data)
- [Methodology](#methodology)
- [Results](#results)
- [Contributing](#contributing)
- [License](#license)
- [Citation](#citation)

---

## 🎯 Overview

This project examines how **social capital** (organizational membership, trust) and **cultural capital** (education) affect employment outcomes across different social groups in rural India, with particular focus on understanding barriers faced by Muslim communities.

### Research Questions

1. **Wealth-Employment Paradox**: Why do wealthier social groups show systematically lower employment rates?
2. **Muslim Disadvantage**: What structural barriers limit Muslim employment beyond education and wealth differences?
3. **Social Capital**: How does organizational membership affect employment probability across different groups?
4. **Cultural Capital**: What are the returns to education across social groups in rural labor markets?
5. **Intersectional Effects**: How do gender, caste, and religion interact to shape employment outcomes?

### Key Features

- ✅ **Large-scale analysis**: 204,568 individuals across rural India
- ✅ **Advanced econometrics**: Logistic regression with state fixed effects
- ✅ **Intuitive interpretation**: Average Marginal Effects (AME) in percentage points
- ✅ **Interaction effects**: Social capital × education analysis
- ✅ **Subgroup analysis**: Gender-stratified and Muslim-specific models
- ✅ **Comprehensive reporting**: Automated tables, visualizations, and policy recommendations

---

## Key Findings

### Wealth-Employment Paradox
- **Strong negative correlation**: -0.671 between group wealth and employment rates
- **Marginal effect**: Each unit increase in wealth decreases employment probability by **1.37 percentage points**
- **Theoretical challenge**: Contradicts standard human capital predictions

### Muslim Disadvantage (Multidimensional Exclusion)

| Dimension | Muslim Performance | Rank (vs 7 groups) | Gap vs Brahmins |
|-----------|-------------------|-------------------|-----------------|
| Employment Rate | **35.5%** | 6th/7 | -4.3 percentage points |
| Wealth Index | 15.3 | 6th/7 | -4.3 points |
| Education | 4.3 years | 7th/7 | -3.4 years |
| Organization Membership | 5.5% | Lowest | -50% lower rate |

**Net disadvantage**: Muslims have **7.7% lower employment odds** than Brahmins after controlling for education, wealth, age, gender, and state

### Social Capital Effects
- Organization membership increases employment probability by **1.05 percentage points**
- Only **8.9%** of rural population are organization members
- **Untapped potential**: Massive scope for social capital interventions

### Education Returns
- Each additional year of education increases employment probability by **0.14 percentage points**
- **Linear relationship**: No threshold effects in rural labor markets
- **Muslim education crisis**: 3.4-year gap vs Brahmins drives employment disadvantage

### Gender Inequality
- Women face **26.44 percentage points** lower employment probability
- **Massive gap**: One of the largest gender employment disparities documented
- **Intersectional disadvantage**: Muslim women face compounded barriers

### Interaction Effects
- **Negative interaction** between education and organization membership (β=-0.020, p<0.001)
- Education returns are **weaker** for organization members
- Suggests social and cultural capital operate as **substitutes** in rural labor markets

---
---

## 📁 Project Structure

```
IIHDS_Project/
│
├── README.md                          # This file
├── LICENSE                            # MIT License
│
├── scripts/                           # Modular R scripts
│   ├── run_analysis.R                 # Master runner script (executes all below)
│   ├── 00_setup.R                     # Setup, packages, configuration
│   ├── utils_functions.R              # Helper functions & utilities
│   ├── 01_data_loading.R              # Data loading & merging
│   ├── 02_data_preparation.R          # Variable construction & cleaning
│   ├── 03_descriptive_stats.R         # Exploratory analysis & descriptives
│   ├── 04_regression_models.R         # Main regression models
│   ├── 05_Interactions_ Subgroups.R   # Interaction effects & subgroup analysis
│   ├── 06_Marginal_Effects.R          # AME calculations & interpretation
│   ├── 07_final_report.R              # Comprehensive findings summary
│   └── 08_visualizations.R            # Plot generation
│
├── data/                              # Raw data files (not tracked in git)
│   ├── 36151-0001-Data.rda           # IIHDS Individual data
│   └── 36151-0002-Data.rda           # IIHDS Household data
│
├── output/                            # Generated outputs
│   ├── plots/                         # Visualizations
│   │   └── wealth_employment_paradox.png
│   ├── tables/                        # CSV result tables
│   │   ├── model_employment_key_vars.csv
│   │   ├── marginal_effects.csv
│   │   ├── muslim_profile.csv
│   │   ├── wealth_by_group.csv
│   │   ├── group_comparison_detailed.csv
│   │   └── missing_data_summary.csv
│   ├── models/                        # Saved model objects
│   │   ├── model_employment_main.rds
│   │   ├── model_interaction.rds
│   │   ├── model_male.rds
│   │   ├── model_female.rds
│   │   └── model_muslim.rds
│   ├── analysis_data.rds              # Prepared analysis dataset
│   ├── merged_data.rds                # Merged raw data
│   └── final_comprehensive_summary.rds # Complete results summary
│
└── .gitignore                         # Git ignore rules
```

---

## 🚀 Installation

### Prerequisites

- **R** (≥ 4.0.0) - [Download R](https://www.r-project.org/)
- **RStudio** (recommended) - [Download RStudio](https://posit.co/downloads/)

### Required Packages

```r
# Install all required packages
install.packages(c(
  "haven",      # Read Stata/SPSS data
  "dplyr",      # Data manipulation
  "tidyverse",  # Data wrangling ecosystem
  "survey",     # Survey data analysis
  "car",        # Regression diagnostics
  "ggplot2",    # Visualization
  "scales",     # Axis formatting
  "broom",      # Model tidying
  "margins"     # Marginal effects
))
```

### Clone Repository

```bash
git clone https://github.com/Batutafaaa/IIHDS_Project.git
cd IIHDS_Project
```

---

## 💻 Usage

### Quick Start (Complete Analysis)

```r
# Set working directory
setwd("path/to/IIHDS_Project")

# Run entire analysis pipeline
source("scripts/run_analysis.R")
```

**Output**: All tables, plots, and models saved to `output/` directory

### Step-by-Step Execution

```r
# 1. Setup and configuration
source("scripts/00_setup.R")

# 2. Load helper functions
source("scripts/utils_functions.R")

# 3. Data processing
source("scripts/01_data_loading.R")
source("scripts/02_data_preparation.R")

# 4. Analysis
source("scripts/03_descriptive_stats.R")  # Wealth-paradox discovery
source("scripts/04_regression_models.R")  # Main regression models
source("scripts/05_Interactions_ Subgroups.R")  # Interactions & subgroups
source("scripts/06_Marginal_Effects.R")   # AME calculations

# 5. Output generation
source("scripts/07_final_report.R")       # Comprehensive summary
source("scripts/08_visualizations.R")     # Plot generation
```

### Generate HTML Report

```r
# Render RMarkdown report
rmarkdown::render("docs/analysis_report.Rmd")
```

### Configuration Options

Edit `scripts/00_setup.R` to customize:

```r
# Analysis scope
rural_only <- TRUE          # Set to FALSE for full sample

# Working directory
setwd("YOUR/PATH/HERE")

# Output directories (auto-created)
output_dirs <- c("output/plots", "output/tables", "output/models")
```

---

## 📊 Data

### Source

**India Human Development Survey (IHDS)** - Wave II (2011-12)
- **Provider**: ICPSR (Inter-university Consortium for Political and Social Research)
- **Coverage**: 42,152 households, 204,569 individuals
- **Geographic Scope**: All Indian states and union territories

### Data Files Required

```
data/
├── 36151-0001-Data.rda    # Individual-level data
└── 36151-0002-Data.rda    # Household-level data
```

**Note**: Data files are **not included** in this repository. Download from [ICPSR](https://www.icpsr.umich.edu/web/ICPSR/studies/36151).

### Variables Used

#### Dependent Variable
- `employed`: Binary employment status (1=employed, 0=not employed)

#### Key Independent Variables
- `org_membership`: Organization membership (binary)
- `education_years`: Years of formal education (0-16)
- `social_group`: Caste/religious group (Brahmins, Forward_castes, OBCs, Dalits, Adivasis, Muslims, Other_Religions)

#### Control Variables
- `female`: Gender (1=female, 0=male)
- `age`, `age_sq`: Age and age squared
- `wealth_index`: Household wealth index
- `STATEID_ind`: State fixed effects (34 states)

---

## 📈 Methodology

### Statistical Approach

1. **Logistic Regression** (Main Model)
   ```
   employed ~ org_membership + education_years + social_group + 
              female + age + age² + wealth_index + state_FE
   ```
   - Family: Binomial (logit link)
   - N = 203,924 observations
   - McFadden R² = 0.403 (excellent fit)

2. **Average Marginal Effects (AME)**
   - `Method`: Finite differences for binary variables, analytical for continuous
   - `Advantage`: More interpretable than odds ratios
   - `Output`: Percentage point changes in employment probability

3. **Interaction Models**
   ```
   employed ~ org_membership × education_years + controls
   ```
   - Tests whether social and cultural capital synergize

4. **Subgroup Analysis**
   - Gender-stratified models (male/female)
   - Muslim-specific model
   - Tests heterogeneity in effects across groups

### Key Functions

#### `convert_work_var(x)`
Converts employment variables to binary (0/1)

#### `extract_education_years(ed_var)`
Extracts numeric years from categorical education variable

#### `calculate_ame(model, data, variable, is_binary)`
Calculates Average Marginal Effects using finite differences

---

## 📑 Results

### Main Regression Results

| Variable | Coefficient | Odds Ratio | P-Value | Interpretation |
|----------|-------------|------------|---------|----------------|
| Organization Membership | 0.079 | 1.082 | *** | +8.2% higher employment odds |
| Education (per year) | 0.011 | 1.011 | *** | +1.1% higher odds per year |
| Muslims (vs Brahmins) | -0.081 | 0.923 | * | -7.7% lower odds |
| Female | -1.929 | 0.145 | *** | -85.5% lower odds |
| Wealth Index | -0.104 | 0.901 | *** | -9.9% lower odds per unit |

**Significance**: *** p<0.001, ** p<0.01, * p<0.05

### Marginal Effects

| Variable | AME (pp) | 95% CI| Interpretation |
|----------|----------|-------|----------------|
| Organization Membership | +1.05 | [1.03, 1.06] | 1.05 pp increase in employment probability |
| Education (per year) | +0.14 | [0.10, 0.18] | 0.14 pp increase per additional year |
| Female | -26.44 | [-26.86, -26.03] |26.44 pp decrease for women |
| Wealth Index | -1.37 | [-1.41, -1.34] | 1.38 pp decrease per unit increase |
| Muslim (vs Brahmin)| -2.10* | [-3.82, -0.38] | 2.10 pp net disadvantage |
**pp** = percentage points
*Calculated separately using counterfactual prediction method

### Model Performance 

|Metric | Value|
|-------|------|
|Observations| 203,924|
| AIC       | 167,239|
| McFadden R²| 0.403 |
| Null Deviance| 280,088| 
| Residual Deviance| 167,149| 


### Output Files

All results are saved in `output/tables/`:

- `model_employment_key_vars.csv` - Main regression coefficients
- `model_fit_statistics.csv` - Model diagnostics
- `marginal_effects.csv` - AME estimates
- `muslim_profile.csv` - Muslim community characteristics
- `wealth_by_group.csv` - Descriptive statistics by social group

---

## 📊 Visualizations

### Wealth-Employment Paradox

![Wealth-Employment Paradox](output/plots/wealth_employment_paradox.png)

*Scatter plot showing negative correlation (-0.671) between group wealth and employment rates*

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** changes (`git commit -m 'Add AmazingFeature'`)
4. **Push** to branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Contribution Ideas

- [ ] Add robustness checks (alternative specifications)
- [ ] Implement survey weights in analysis
- [ ] Create interactive visualizations (plotly/shiny)
- [ ] Add spatial analysis (state-level mapping)
- [ ] Extend to urban sample comparison
- [ ] Add machine learning classification models

---

## 📄 License

**Data Usage**: IIHDS data is subject to ICPSR terms of use. Cite original data source in publications.

---

## 📝 Citation

If you use this code or analysis in your research, please cite:

### APA Format
```
Sreekumar. (2025). Social & Cultural Capital Effects on Employment in Rural India: 
Muslim Group Disadvantage Analysis. GitHub repository. 
https://github.com/Batutafaaa/IIHDS_Project
```

### BibTeX
```bibtex
@software{iihds_social_capital_2024,
  author = {Ashwin Sreekumar},
  title = {Social & Cultural Capital Effects on Employment in Rural India},
  year = {2024},
  url = {https://github.com/Batutafaaa/IIHDS_Project},
  note = {GitHub repository}
}
```

### Data Citation
```
Desai, Sonalde, and Reeve Vanneman. India Human Development Survey-II (IHDS-II), 
2011-12. Inter-university Consortium for Political and Social Research [distributor], 
2018-08-08. https://doi.org/10.3886/ICPSR36151.v6
```


--

