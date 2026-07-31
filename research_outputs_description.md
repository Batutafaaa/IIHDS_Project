# Research Output Descriptions: "Three Groups, Three Traps"

This document provides a detailed description of the figures and tables generated for the analysis of IHDS-II data, contextualized within the research framework presented in the blog post: *""The Hidden Geography of Inequality: Why India's Marginalized Groups Need Different Solutions""*.

---

## 📊 Figures (`output/plots/`)

### 1. Geographic Sorting & Spatial Concentration
These plots demonstrate the foundational finding of the research: that geography affects marginalized groups in fundamentally different ways.

*   **`muslim_employment_correlation.png`**
    *   **Finding:** The "Muslim Geographic Trap."
    *   **Description:** A scatterplot showing a significant **negative correlation (-0.305)** between a district's Muslim population share and its overall employment rate. It supports the argument that Muslims are concentrated in economically stagnant regions where jobs are scarce for everyone.
*   **`st_employment_correlation.png`**
    *   **Finding:** The "Adivasi Subsistence Mirage."
    *   **Description:** A scatterplot showing a strong **positive correlation (+0.378)** between Adivasi (ST) population share and district employment. This visualizes the paradox where tribal belts have the highest employment rates in the country, but this is "distress employment" in subsistence agriculture.
*   **`sc_employment_correlation.png`**
    *   **Finding:** The "Dalit Distributed Pattern."
    *   **Description:** Shows a **near-zero correlation (+0.081, non-significant)** between Dalit (SC) concentration and district employment. This supports the claim that Dalit disadvantage is not geographic but is distributed across all regions due to caste-based barriers.

### 2. Employment Quality, Earnings & Wealth Paradox
These plots move beyond "if" people work to "how" they work and what they earn.

*   **`contract_type_distribution.png`**
    *   **Finding:** The Job Security Gap.
    *   **Description:** A stacked bar chart showing the percentage of workers in Casual, Temporary, and Permanent contracts across social groups. It highlights that **89.8% of Adivasis** and **88.4% of Dalits** are in casual labor.
*   **`earnings_distribution.png`**
    *   **Finding:** The Earnings Inequality.
    *   **Description:** Boxplots of annual earnings on a **Log Scale**. It shows the persistent shift toward higher earnings for Forward castes, even when ignoring outliers, and highlights the "Subsistence Mirage" of Adivasis who earn the least despite working the most.
*   **`wealth_employment_paradox.png`**
    *   **Finding:** Wealth vs. Work.
    *   **Description:** A bubble chart illustrating that groups with higher mean wealth (Forward castes) have lower employment rates, while the poorest groups (Adivasis) have the highest. This visualizes the "Distress Employment" theory.

### 3. Urban-Rural & District Gaps (New Outputs)
These plots examine within-district variation and urban-rural divisions.

*   **`urban_rural_employment_by_group.png`**
    *   **Finding:** Setting-Specific Labor Opportunities.
    *   **Description:** A grouped bar chart comparing the rural vs. urban employment rates for all seven social groups. It visualizes the drop in employment rates associated with urban residency for all groups.
*   **`regional_urban_rural_heatmap.png`**
    *   **Finding:** Regional Labor Market Gaps.
    *   **Description:** A faceted tile heatmap showing employment rates by social group, urban/rural setting, and broad geographic region (North, South, East, West, Central). It highlights regional variation in group-level employment.
*   **`muslim_within_district_gap.png`**
    *   **Finding:** The Persistent Local Identity Penalty.
    *   **Description:** A density plot showing the distribution of individual-level employment gaps between Muslims and non-Muslims within the same district. While the gap is smaller than the aggregate national gap, it centers below zero, showing a persistent identity-based penalty.

---

## 📋 Tables (`output/tables/`)

### 1. Master Data & Descriptives
*   **`wealth_by_group.csv`**: Basic summary of sample size, employment rate, mean wealth, mean education, and organization membership by social group.
*   **`group_comparison_detailed.csv`**: Comprehensive summary of all groups including employment rate, wealth, education, organization membership, and urban share, with rankings.
*   **`missing_data_summary.csv`**: A summary of missing data in key variables.
*   **`muslim_profile.csv`**: Detailed demographic profile of the Muslim sample (size, education, employment, gender, urban share).

### 2. Geographic & Spatial Analysis
*   **`district_concentration.csv`**: Master dataset for district-level correlations (Muslim share vs. employment).
*   **`district_concentration_sc_st.csv`**: Master dataset for SC/ST district correlations.
*   **`top_muslim_districts.csv` / `top_sc_districts.csv` / `top_st_districts.csv`**: Lists of the most concentrated districts for each group, used to identify geographic hubs.
*   **`within_district_muslim_gap.csv` / `within_district_sc_gap.csv` / `within_district_st_gap.csv`**: Individual-level within-district gap analyses for Muslims, SC, and ST groups respectively, documenting local disparities.

### 3. Employment Quality Detailed Results
*   **`job_security_by_group.csv`**: Raw percentages for the contract type distribution (Casual vs. Temporary/Permanent) across groups.
*   **`earnings_summary.csv`**: Statistical summary of mean/median earnings and the calculated "gap vs. forward castes" (Adivasis earning ~46.6% less).
*   **`formal_job_benefits.csv`**: Comparison of access to paid leave and formal benefits score—key indicators of job quality.
*   **`nrega_participation.csv`**: Shows participation in the rural employment guarantee (highest for Adivasis at 10.6% and lowest for Muslims at 3.7%).

### 4. Social Capital & Interaction Models
*   **`group_social_capital_ames.csv`**: Average Marginal Effects (AMEs) of organizational membership calculated separately for each social group.
*   **`interaction_org_x_group.csv`**: Full interaction model regression results for social group × organization membership.
*   **`interaction_trust_x_group.csv`**: Interaction results for general trust indicators by group.

### 5. Regression Models & Robustness Results
*   **`model_employment_key_vars.csv` / `model_employment_full_summary.csv`**: Logistic regression coefficients for the primary survey-weighted model.
*   **`model_simple_summary.csv`**: Simple summarized regression coefficients table.
*   **`model_fit_statistics.csv`**: Summary of model sample size, deviances, and McFadden R² (0.404).
*   **`marginal_effects.csv`**: The calculated Average Marginal Effects (AMEs) of the covariates.
*   **`group_marginal_effects.csv`**: Average Marginal Effects (AMEs) of social groups on employment.
*   **`robustness_comparison.csv`**: Sensitivity analysis results showing coefficients across Model 1 (State FE), Model 2 (District FE LPM), Model 3 (Naive GLM), and Model 4 (Exogenous only).
*   **`robustness_results.rds`**: Serialized R object containing the robustness model comparison details.

### 6. Urban-Rural Dynamics & Wage Penalties
*   **`urban_rural_group_descriptives.csv`**: Summary of key variables (education, wealth, organization membership) by group and setting.
*   **`urban_rural_employment_gap.csv`**: Rural and urban employment rates and absolute gaps by group.
*   **`urban_rural_group_interaction.csv`**: Employment interaction regression terms for group by urban setting.
*   **`predicted_probs_urban_rural.csv`**: Predicted employment probabilities by group and setting at mean covariate values.
*   **`regional_urban_rural_employment.csv`**: Employment rates by group, setting, and region.
*   **`wage_penalty_ols.csv`**: OLS wage regression estimates for each group.
*   **`wage_penalty_heckman.csv`**: Heckman selection-corrected wage regression estimates for each group.
*   **`wage_urban_rural_interaction.csv`**: Wage interaction regression terms for group by urban setting.
