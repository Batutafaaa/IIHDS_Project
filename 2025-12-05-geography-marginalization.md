---
layout: post
title: "The Hidden Geography of Inequality"
date: 2025-12-05
author:

comments: true
math: true  
description: "An analysis of IHDS-II (2011-2012) data examining how human capital, social capital, and geography interact to shape employment and wage outcomes across social groups in India."
---

## Abstract

Inequality in labor market outcomes persists despite India's rapid economic growth. This study draws on the India Human Development Survey-II (IHDS-II, 2011-12), a nationally representative dataset of 204,568 working-age individuals across 33 states and 371 districts, to investigate how social identity, geography, and human capital interact to shape employment and wage outcomes. Using survey-weighted logistic regression with state fixed-effects, district fixed-effects models, and Heckman selection-corrected wage regressions, we document a "Wealth-Employment Paradox": groups with the lowest mean wealth exhibit the highest employment rates, reflecting distress labor rather than economic mobility. We further disaggregate marginalization mechanisms across three groups. Muslims are caught in a *Geographic Trap*—their employment penalty (82% of which vanishes under district fixed-effects) is primarily driven by concentration in economically stagnant districts. Adivasis have India's highest employment rates coexist with the lowest wages and 89.8% casual labor rates. Dalits face a *Distributed Barrier*—wage penalties that persist across all districts (with 95.7% shrinkage under district FE in employment, leaving only 4.3% of the state-level effect, and significant selection-corrected wage gaps).

---

## Research Problem and Research Questions

Despite decades of affirmative action and poverty alleviation programs, India's marginalized communities—Dalits (Scheduled Castes), Adivasis (Scheduled Tribes), and Muslims—continue to face significant disparities in socio-economic outcomes. Existing frameworks often treat disadvantaged groups as a monolithic bloc, assuming that marginalization operates through similar mechanisms for everyone.

When analyzing employment statistics, a deceptive hierarchy emerges: Adivasis have the highest employment rate (53.3%), followed by OBCs (46.4%), Dalits (45.5%), and Forward Castes (43.3%), while Muslims are lowest at 35.5%. Far from being contradictory, these figures highlight a structural anomaly—the "Wealth-Employment Paradox." In Indian labor markets, there is a strong negative group-level correlation (−0.667) between a social group's wealth and its employment rate. The poorest communities work the most, not out of opportunity but out of necessity, engaging in distress labor to meet subsistence needs.

This paradox points to a critical research gap employment *quantity* cannot be conflated with employment *quality* or economic wellbeing. This study addresses the following research questions:

1. How do human capital (education), social capital (organizational membership), and geography interact to shape employment probabilities across different social groups in India?
2. How do within-state urban-rural dynamics shape employment and wage disparity across groups?
3. How does employment quality, measured by job security and wages, differ among groups with ostensibly "high" employment rates?

---

## Methodology

### Data

This study uses the India Human Development Survey-II (IHDS-II, 2011-2012), a nationally representative survey of 42,152 households covering 204,568 working-age individuals across 33 states, 371 districts, and 2,462 primary sampling units (PSUs). The IHDS-II follows a stratified multi-stage cluster sampling design; all regression models account for this through probability sampling weights (`WT_ind`) and PSU-level clustering.

**Key variables:**
- *Employment*: Binary indicator derived from `WKANY5`, classifying an individual as employed if they reported part-time (< 240 hours), part-time year-round, or full-time year-round work.
- *Social group*: Derived from `GROUPS_ind` into seven categories (Brahmins, Forward Castes, OBCs, Dalits, Adivasis, Muslims, Other Religions).
- *Social capital*: Organization membership (`ME1`), an indicator for participation in any formal or informal group.
- *Human capital*: Years of education, converted from the categorical `ED6` variable.
- *Geography*: Urban/rural residence (`URBAN2011`), state (`STATEID_ind`), and district (`DISTID_ind`).

### Analytical Framework

**Step 1 — Survey-weighted logistic regression (Main Model):** Employment probability is modeled using `svyglm` with a quasibinomial family and state fixed-effects, clustering at the unique PSU level (state × district × PSU concatenation). This ensures standard errors account for intra-cluster correlation. Average Marginal Effects (AMEs) are computed via the counterfactual method (predicting the difference at every observation and averaging).

**Step 2 — Robustness checks (5 specifications):**
- *Model 1 (Baseline):* Survey-weighted logit with state FE (replicates main model).
- *Model 2 (District FE - LPM):* Linear Probability Model with district fixed-effects and PSU-clustered standard errors. LPM is used here rather than logit to avoid the incidental parameters problem with 371 district dummies.
- *Model 3 (Clustered SE):* State-FE logit with PSU-clustered standard errors (naive unweighted comparison).
- *Model 4 (Exogenous-only):* Drops wealth and social capital to test whether group penalties survive removal of potentially endogenous controls.
- *Model 5 (Survey-weighted District FE):* svyglm with district fixed effects. In practice, due to high dimensionality and convergence/memory constraints with 371 districts under survey-weighted estimation, Model 2 (LPM District FE with clustered SEs) serves as the primary robust geographic trap test.


**Step 3 — Geographic Trap Test:** The central diagnostic compares social group coefficients between State FE (Model 1) and District FE (Model 2) specifications. A coefficient that shrinks substantially under district FE indicates that the group's disadvantage is primarily geographic (the group is concentrated in low-opportunity districts), rather than a portable identity-level barrier.

**Step 4 — Employment quality analysis (Rural subsample):** Using the rural subsample (N = 135,118), we analyze contract type, wage earnings (`WSEARN`), and NREGA participation. The Heckman two-step procedure (`heckit`) corrects for the selection bias inherent in wage regressions: only employed people have observed wages. The exclusion restriction is the wealth index, which plausibly affects selection into employment but not the conditional wage. Step 1 is a probit selection equation; Step 2 is an OLS wage equation with the Inverse Mills Ratio included.

**Step 5 — Within-state urban-rural dynamics:** The full sample (urban + rural) is used to estimate a `social_group × urban_resident` interaction model (survey-weighted logit) and a log-wage interaction model, showing how the urban-rural divide shapes group-level disparities differently.

---

## Results

### The Wealth-Employment Paradox

Traditional human capital models struggle to explain rural India's dynamics. We find a strong negative group-level correlation (−0.667) between wealth and employment rate. Each unit increase in the wealth index is associated with a **1.02 pp decrease** in employment probability (AME, p < 0.001). This reflects the substitution of market labor for subsistence labor as wealth increases—the poorest groups work more because they must, not because opportunities are better.

Conversely, human and social capital offer reliable pathways: each additional year of education increases employment probability by **+0.21 pp** (p < 0.001), and organizational membership yields a **+0.09 pp** increase overall (p < 0.001). Critically, only 8.9% of the sample participates in any organization, representing a significant untapped lever.

The female employment penalty is **−26.4 pp** (p < 0.001)—among the most severe observed in the comparative literature.

<figure class="text-center">
  <img src="\assets\img\IIHDSemploy\wealth_employment_paradox.png"
       alt="Wealth-Employment Paradox" 
       class="img-fluid" 
       style="max-width: 85%; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
  <figcaption class="mt-2 text-muted">
    <strong>Figure 1:</strong> Group-level scatter of mean wealth against employment rate. The strong negative relationship (r = −0.667) illustrates the wealth-employment paradox: poorer groups (Adivasis, Dalits) exhibit higher employment driven by distress labor, while wealthier groups (Brahmins) have lower but better-quality employment.
  </figcaption>
</figure>

### Social Capital Returns: Group-Differentiated

A key finding is that organizational membership does not benefit all groups equally. The interaction model (org_membership × social_group) reveals substantial heterogeneity in returns:

| Group | Org Membership AME |
|---|---|
| Brahmins | +1.71 pp *** |
| Other Religions | +1.07 pp *** |
| Muslims | +0.87 pp *** |
| Dalits | +0.37 pp *** |
| Forward Castes | +0.11 pp *** |
| Adivasis | −0.24 pp *** |
| OBCs | −0.44 pp *** |

Upper-caste groups extract more than four times the employment benefit from organizational membership than Dalits do, and Adivasis and OBCs exhibit a slight *negative* effect. This suggests that existing social organizations may not be structured to channel economic opportunities toward the most marginalized.

### The Muslim Geographic Trap

Muslims display a robust negative spatial signature: district-level Muslim population share is negatively correlated with district employment rate (r = −0.305, p < 0.001). Each 10 percentage-point increase in Muslim share is associated with a −1.69 pp reduction in district employment rates.

The critical test is the **Geographic Trap decomposition**:

| Model | Muslim Coefficient | Interpretation |
|---|---|---|
| State FE (svyglm) | +0.158 (p = 0.057) | Positive but marginal vs. Brahmins |
| District FE (LPM) | −0.028 (p = 0.005) | Penalty reverses within districts |
| Shrinkage | **82.3%** | Driven by district context |

The Muslim employment coefficient shrinks by 82% when comparing individuals within the same district rather than the same state. This strongly indicates that Muslim disadvantage is primarily a function of *where* Muslims live—concentrated in economically stagnant districts—rather than a portable identity barrier within a given labor market context.

Within-district individual-level comparisons corroborate this: the mean Muslim vs. non-Muslim employment gap within the same district is **−7.79 pp**, which, while not trivial, is substantially smaller than the aggregate 10.3 pp raw gap. This within-district gap likely reflects the residual identity component (discrimination, social network exclusion) that persists even after district context is controlled.

<figure class="text-center">
  <img src="\assets\img\IIHDSemploy\muslim_employment_correlation.png"
       alt="Muslim Employment Correlation" 
       class="img-fluid" 
       style="max-width: 85%; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
  <figcaption class="mt-2 text-muted">
    <strong>Figure 2:</strong> District-level scatter of Muslim population share against district employment rate (r = −0.305, p < 0.001). Top-Muslim-share districts (J&K, Assam, Western UP) show low employment rates, consistent with geographic concentration in stagnant labor markets.
  </figcaption>
</figure>

### The Adivasi Subsistence Mirage

Adivasis present the inverse spatial pattern: districts with high Adivasi concentration exhibit *higher* employment (r = +0.378, p < 0.001; +1.79 pp per 10pp increase in ST share). Yet the content of that employment tells a different story.

**Employment quality (rural sample):**
- 89.8% of employed Adivasis are in casual, non-contractual daily labor
- 0% report permanent contracts
- Mean annual earnings: ₹26,173—a **46.6% gap** versus Forward/Upper castes (₹49,049)

After Heckman selection correction (IMR = −0.310, p < 0.001), the selection-corrected Adivasi wage penalty is **−36.9%** versus Brahmins. NREGA participation is highest among Adivasis (10.6%), serving as a distress absorption mechanism.

The district FE shrinkage for Adivasis is 89.4%, indicating that most of their employment *advantage* (in quantity) is also geographic—their tribal districts have high labor participation driven by subsistence agriculture and forest-based work. The real concern is the depth of wage exploitation within these same districts.

**Urban-rural wage interaction:** In urban settings, the Adivasi earnings penalty is not statistically significant in the group × urban interaction ($p = 0.87$), suggesting that Adivasis in urban areas experience similar returns to urban location as Brahmins. The urban wage penalty problem is more acute for Muslims (−34.9%, p < 0.001), Dalits (−25.9%, p < 0.001), and OBCs (−17.7%, p < 0.001).

### The Dalit Distributed Barrier

Dalits display a near-zero geographic correlation in employment rates (+0.081, p = 0.12), meaning their disadvantage is not spatially concentrated—it is distributed uniformly across geographies. The district FE shrinkage is 95.7%, meaning that under district FE the Dalit employment coefficient falls from +0.441 (State FE) to +0.019. This high shrinkage, combined with the non-significant geographic correlation, indicates that Dalits are distributed broadly and their employment levels are primarily shaped by local district conditions, not a singular geographic trap.

However, the wage dimension reveals persistent discrimination. The OLS wage penalty for Dalits is **−18.9%** versus Brahmins. After Heckman selection correction, this becomes **−25.1%**—the correction *worsens* the estimate, indicating that Dalits who are employed are positively selected on unobservables: even conditional on the same observed education, age, and location, Dalits in wage employment are more able than average, yet still earn substantially less. This is consistent with hiring discrimination and occupational channeling.

---

## Discussion

### Three Distinct Mechanisms, Three Distinct Diagnostics

The falsification value of comparing all three groups simultaneously is high. If results were driven by statistical artifacts or model misspecification, we would expect similar patterns across groups. Instead:

| Diagnostic | Muslims | Adivasis | Dalits |
|---|---|---|---|
| **District FE shrinkage (employment)** | 82.3% | 89.4% | 95.7% |
| **Geographic correlation** | −0.305*** | +0.378*** | +0.081 n.s. |
| **Heckman wage penalty** | −16.7%*** | −36.9%*** | −25.1%*** |
| **Casual labor rate** | 85.3% | 89.8% | 88.4% |
| **NREGA participation** | 3.7% | 10.6% | 9.0% |

The divergent spatial signatures—negative for Muslims, strongly positive for Adivasis, near-zero for Dalits—map precisely onto three distinct political-economic histories: post-partition industrial disinvestment and geographic stagnation for Muslims; forest reservation and subsistence agricultural confinement for Adivasis; and horizontally distributed, institution-level caste discrimination for Dalits.

### Methodological Notes and Limitations

Several methodological choices require transparency:

1. **Exclusion restriction (Heckman):** We use the wealth index as the exclusion restriction in the Heckman selection model. While household wealth plausibly affects selection into employment, it may also directly affect conditional wages through job search quality. A stricter restriction (e.g., household demographic composition or head's employment status) would be preferable if available in the data.

2. **PSU clustering:** The IHDS-II sampling design specifies PSUs as the primary clustering unit. Because PSUID itself is not globally unique across states in this dataset, we create a unique PSU identifier (state × district × PSU). This resulted in 39 effective PSUs in the data (as reported), which is low relative to the 2,462 geographically unique clusters. This is a known feature of the `svydesign` PSU count in R; the model variance estimation remains valid but the degree-of-freedom approximation for t-tests should be treated as conservative.

3. **District FE and LPM:** We use a Linear Probability Model (not logit) for district fixed-effects models to avoid the incidental parameters problem. LPM coefficients near the tails of the probability distribution can exceed [0,1] bounds; for a binary outcome in our probability range (40–55%), LPM is a defensible approximation.

4. **General trust variable:** The IHDS-II `TR1` variable (used for general trust in previous analyses) was repurposed in the 2011-12 wave and does not contain a "most people can be trusted" question. As a result, the social capital analysis relies solely on organization membership. This is an important scope limitation—the social capital measure captures bridging capital only.

5. **Urban-rural interaction p-values (NaN):** The p-values for the group × urban interaction in the employment probability model showed `NaN`, indicating very high collinearity between `social_group` dummies and `social_group × urban_resident` interaction terms when the survey design degrees of freedom are extremely limited (39 effective PSUs against 50+ parameters). The directional coefficients and the wage interaction model (which uses OLS without the survey design constraint) are more reliable for this specific analysis.

### Policy Implications

The evidence strongly argues against uniform intervention:

- **Muslims — Place-Based Economic Development:** With 82% of the employment penalty attributable to geographic concentration, place-based industrial and infrastructure investments in high-Muslim-concentration districts are the highest-leverage intervention. Educational deficit reduction (3.4-year gap vs. Brahmins) must accompany place-based investment.

- **Adivasis — Wage Formalization and Floor Enforcement:** Adivasis do not lack employment; they lack *quality* employment. The priority is converting casual daily labor into contractual employment, enforcing minimum wage law in agricultural and forest-produce markets, and reforming NREGA from a coping mechanism into a platform for skill development.

- **Dalits — Anti-Discrimination Architecture:** The Heckman correction showing a larger wage gap than OLS implies that positively selected Dalits still earn substantially less—a signature consistent with hiring discrimination and occupational channeling. Policy must target private-sector hiring practices and occupational barriers rather than employment volume.

- **Social Capital:** With only 8.9% organizational membership, and returns that are highest for already-advantaged groups, scaling organizations that specifically serve marginalized communities (cooperatives, SHGs, labor unions in casual sectors) could materially improve outcomes.

---

### Summary Table: Pluralistic Forms of Marginalization

| Dimension | Muslims | Adivasis | Dalits |
|-----------|---------|----------|--------|
| **Employment Rate** | 35.5% (Lowest) | 53.3% (Highest) | 45.5% (Middle) |
| **Geographic Pattern** | Negative (−0.305***) | Positive (+0.378***) | None (+0.081 n.s.) |
| **District FE Shrinkage** | 82.3% | 89.4% | 95.7% |
| **Urban Employment Rate** | 30.7% | 38.0% | 36.4% |
| **Rural Employment Rate** | 39.7% | 55.9% | 49.3% |
| **Casual Employment Rate** | 85.3% | 89.8% | 88.4% |
| **Mean Annual Earnings (Rural)** | ₹38,597 | ₹26,173 (Lowest) | ₹31,180 |
| **Heckman Wage Penalty (vs Brahmins)** | −16.7%*** | −36.9%*** | −25.1%*** |
| **NREGA Participation** | 3.7% | 10.6% | 9.0% |
| **Primary Mechanism** | Geographic stagnation | Subsistence confinement | Distributed discrimination |
| **Target Policy Lever** | Place-based investment + Education | Wage formalization | Anti-discrimination enforcement |

---

## Data & Methods

- **Source**: Desai, Sonalde, Reeve Vanneman and National Council of Applied Economic Research. India Human Development Survey-II (IHDS-II), 2011-12. Inter-university Consortium for Political and Social Research [distributor], 2018-08-08. https://doi.org/10.3886/ICPSR36151.v6
- **Sample**: 204,569 individuals across 371 districts in 33 states (Urban: 69,450; Rural: 135,118)
- **Employment Model**: Survey-weighted logistic regression (`svyglm`, quasibinomial), State FE, PSU-clustered standard errors
- **Wage Model**: Heckman two-step (`heckit`), rural subsample, N = 135,118 for selection equation
- **Robustness**: District FE (LPM + clustered SE), unweighted logit + clustered SE, exogenous-only specification
- **McFadden R² (main model)**: 0.404

**Keywords**: Employment inequality, geographic sorting, social capital, caste, religion, labor market discrimination, India, development economics

---

## Bibliography

Basole, A (2019): "State of Working India 2019," Centre for Sustainable Employment, Azim Premji University.

Bhan, G., Anand, S., Nagpal, S., & Khandelwal, V. (2024). Reimagining urban employment programmes. *Economic & Political Weekly*, 59(22), 14-18.

Deshpande, A (2011): *The Grammar of Caste: Economic Discrimination in Contemporary India*, Oxford: Oxford University Press.

Drèze, J (2020): "Decentralised Urban Employment and Training (DUET) Scheme: A Proposal," Policy Brief No 23, National Centre for Demographic Studies.

Harriss-White, B and N Gooptu (2001): "Mapping India's World of Unorganised Labour," *Socialist Register*, Vol 37, pp 89–118.

Mhaskar, S. (2018). Ghettoisation of economic choices in a global city: A case study of Mumbai. *Economic and Political Weekly*, 29-37.

Thorat, S, Aryama and P Negi (eds) (2005): *Reservation and Private Sector: Quest for Equal Opportunity and Growth*, Indian Institute of Dalit Studies, New Delhi.

Thorat, S and P Attewell (2010): "The Legacy of Social Exclusion: A Correspondence Study of Job Discrimination in India's Urban Private Sector," *Blocked by Caste: Economic Discrimination in Modern India*, S Thorat and K S Newman (eds), New Delhi: Oxford University Press.

Thorat, S and K S Newman (eds) (2010): *Blocked by Caste: Economic Discrimination in Modern India*, New Delhi: Oxford University Press.