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

1. **Wealth-Employment Paradox**: Why do wealthier social groups show lower employment rates?
2. **Muslim Disadvantage**: What structural barriers limit Muslim employment?
3. **Social Capital**: How does organizational membership affect employment probability?
4. **Cultural Capital**: What are the returns to education across social groups?
5. **Interaction Effects**: How do social and cultural capital interact?

### Key Features

- ✅ Comprehensive logistic regression with state fixed effects (N=203,924)
- ✅ Average Marginal Effects (AME) for intuitive interpretation
- ✅ Interaction effects analysis (social capital × education)
- ✅ Gender-stratified subgroup models
- ✅ Muslim-specific analysis
- ✅ Automated report generation with visualizations

---

## 🔍 Key Findings

### 1. Wealth-Employment Paradox
- **Correlation: -0.671** between group wealth and employment
- Each unit increase in wealth **decreases employment odds by 9.9%**
- Wealthier groups (Other_Religions, Brahmins) show lower labor force participation

### 2. Muslim Disadvantage (Multidimensional)
| Metric | Value | Comparison |
|--------|-------|------------|
| Employment Rate | **35.5%** | 2nd lowest among all groups |
| Employment Odds vs Brahmins | **-7.7%** | Statistically significant (p<0.05) |
| Salaried Employment | **1.9%** | Lowest of all groups |
| Education Gap | **3.4 years** | Behind Brahmins |
| Higher Education Rate | **9.7%** | vs Brahmins: 30.5% |

### 3. Social Capital Effects
- Organization membership increases employment probability by **1.05 percentage points**
- Only **8.9%** of rural sample are organization members
- **Stronger effect for women** (OR=1.149) than men (OR=1.026)

### 4. Gender Inequality
- Women face **26.6 percentage points** lower employment probability
- Muslim disadvantage is **severe for women** (OR=0.661) but positive for men (OR=1.173)

### 5. Interaction Effects
- **Negative interaction** between education and organization membership (β=-0.020, p<0.001)
- Education returns are **weaker** for organization members
- Suggests social and cultural capital operate as **substitutes**, not complements

---

## 📁 Project Structure

```
IIHDS_Project/
│
├── README.md                          # This file
├── LICENSE                            # MIT License
│
├── scripts/                           # Modular R scripts
│   ├── run_analysis.R                 # Master runner script
│   ├── 00_setup.R                     # Setup & configuration
│   ├── utils_functions.R              # Helper functions
│   ├── 01_data_loading.R              # Data loading & merging
│   ├── 02_data_preparation.R          # Variable construction
│   ├── 03_descriptive_stats.R         # Descriptive analysis
│   ├── 04_regression_models.R         # Main regression models
│   ├── 05_advanced_analysis.R         # Interactions & subgroups
│   ├── 06_marginal_effects.R          # AME calculations
│   ├── 07_visualizations.R            # Plot generation
│   └── 08_final_report.R              # Summary report
│
├── data/                              # Raw data files (not tracked)
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
│   │   └── wealth_by_group.csv
│   ├── models/                        # Saved model objects
│   │   ├── model_employment_main.rds
│   │   ├── model_interaction.rds
│   │   ├── model_male.rds
│   │   ├── model_female.rds
│   │   └── model_muslim.rds
│   ├── analysis_data.rds              # Prepared analysis dataset
│   └── merged_data.rds                # Merged raw data
│
├── docs/                              # Documentation
│   ├── analysis_report.Rmd            # RMarkdown report
│   └── analysis_report.html           # Rendered HTML report
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
  "margins",    # Marginal effects
  "knitr",      # Report generation (optional)
  "kableExtra"  # Table formatting (optional)
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
# 1. Setup environment
source("scripts/00_setup.R")
source("scripts/utils_functions.R")

# 2. Load and prepare data
source("scripts/01_data_loading.R")
source("scripts/02_data_preparation.R")

# 3. Run analysis
source("scripts/03_descriptive_stats.R")
source("scripts/04_regression_models.R")
source("scripts/05_advanced_analysis.R")
source("scripts/06_marginal_effects.R")

# 4. Generate outputs
source("scripts/07_visualizations.R")
source("scripts/08_final_report.R")
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
   - More intuitive than odds ratios
   - Shows change in probability (percentage points)
   - Calculated using finite differences method

3. **Interaction Models**
   ```
   employed ~ org_membership × education_years + controls
   ```
   - Tests whether social and cultural capital synergize

4. **Subgroup Analysis**
   - Gender-stratified models (male/female)
   - Muslim-specific model
   - Tests heterogeneity in effects

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

| Variable | AME (pp) | Interpretation |
|----------|----------|----------------|
| Organization Membership | +1.05 | 1.05 pp increase in employment probability |
| Education (per year) | +0.14 | 0.14 pp increase per additional year |
| Female | -26.58 | 26.58 pp decrease for women |
| Wealth Index | -1.38 | 1.38 pp decrease per unit increase |

**pp** = percentage points

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
Sreekumar. (2024). Social & Cultural Capital Effects on Employment in Rural India: 
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

---

## 🎓 Academic Context

### Theoretical Framework

This analysis draws on:

- **Bourdieu's Capital Theory**: Social, cultural, and economic capital as distinct forms
- **Human Capital Theory**: Education as investment in productivity
- **Social Network Theory**: Organizational membership as bridging/bonding capital
- **Intersectionality**: Multiple axes of disadvantage (caste, religion, gender)

### Related Literature

- **Muslim Employment in India**: Sachar Committee Report (2006), Kundu & Sarangi (2007)
- **Social Capital & Employment**: Granovetter (1973), Lin (2001), Fernández & Fernández-Mateo (2006)
- **Rural Labor Markets**: Deshpande & Sharma (2016), Thorat & Attewell (2007)


---

## 🙏 Acknowledgments

- **ICPSR** for providing access to IHDS data
- **Desai & Vanneman** for conducting the IHDS survey
- **R Core Team** and package developers
- **Open source community** for statistical computing tools



---

## 🔮 Future Work

1. **Temporal Analysis**: Compare IHDS-I (2004-05) vs IHDS-II (2011-12)
2. **Causal Inference**: Propensity score matching for organizational membership
3. **Spatial Analysis**: Geographic clustering of Muslim disadvantage
4. **Qualitative Interviews**: Understand mechanisms behind quantitative findings
5. **Policy Simulation**: Estimate impact of interventions (education, anti-discrimination)

---

## ⚙️ Technical Notes

### Performance Optimization

- **Avoid `broom::tidy()` with large models**: Use direct `summary()$coefficients` extraction (10-100x faster)
- **State fixed effects**: 34 states → use factor encoding, not dummy variables
- **Large sample size**: 200K+ observations → use vectorized operations, avoid loops

### Common Issues

**Issue**: `broom::tidy()` hangs with `conf.int=TRUE`  
**Solution**: Calculate Wald CIs manually: `estimate ± 1.96 * std.error`

**Issue**: Models won't converge  
**Solution**: Check for perfect separation in categorical variables

**Issue**: Out of memory errors  
**Solution**: Use data.table instead of dplyr for large datasets

