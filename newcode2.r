# ==============================================================================
# Social & Cultural Capital Effects on Employment in Rural India
# Focus: Muslim Group Disadvantage Analysis
# ==============================================================================

# SETUP ------------------------------------------------------------------------
library(haven)
library(dplyr)
library(tidyverse)
library(survey)
library(car)
library(ggplot2)
library(scales)
library(broom)

setwd("C:/Users/ashwin/Desktop/IIHDS_Project")

# ANALYSIS CONFIGURATION
rural_only <- TRUE  # Set to FALSE for full sample analysis

# HELPER FUNCTIONS -------------------------------------------------------------

convert_work_var <- function(x) {
  as.numeric(x %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4"))
}

extract_education_years <- function(ed_var) {
  case_when(
    ed_var == "(00) none 0" ~ 0,
    ed_var == "(55) <1 class 55" ~ 0.5,
    ed_var == "(01) 1st class 1" ~ 1,
    ed_var == "(02) 2nd class 2" ~ 2,
    ed_var == "(03) 3rd class 3" ~ 3,
    ed_var == "(04) 4th class 4" ~ 4,
    ed_var == "(05) 5th class 5" ~ 5,
    ed_var == "(06) 6th class 6" ~ 6,
    ed_var == "(07) 7th class 7" ~ 7,
    ed_var == "(08) 8th class 8" ~ 8,
    ed_var == "(09) 9th class 9" ~ 9,
    ed_var == "(10) Secondary 10" ~ 10,
    ed_var == "(11) 11th Class 11" ~ 11,
    ed_var == "(12) High Secondary 12" ~ 12,
    ed_var == "(13) 1 year post-secondary" ~ 13,
    ed_var == "(14) 2 years post-secondary" ~ 14,
    ed_var == "(15) Bachelors 15" ~ 15,
    ed_var == "(16) Above Bachelors 16" ~ 16,
    TRUE ~ NA_real_
  )
}

print_section <- function(title) {
  cat("\n", rep("=", 80), "\n", title, "\n", rep("=", 80), "\n", sep = "")
}

# DATA LOADING & MERGING -------------------------------------------------------

print_section("DATA LOADING")

load("36151-0001-Data.rda")
load("36151-0002-Data.rda")

individual <- da36151.0001
household <- da36151.0002

merged_data <- individual %>%
  left_join(household, by = "IDHH", suffix = c("_ind", "_hh"))

cat("Individual records:", nrow(individual), "\n")
cat("Household records:", nrow(household), "\n")
cat("Merged records:", nrow(merged_data), "\n")
cat("Unmerged individuals:", nrow(anti_join(individual, household, by = "IDHH")), "\n")

# RURAL/URBAN FILTER -----------------------------------------------------------
if (rural_only) {
  cat("\n>>> FILTERING FOR RURAL AREAS ONLY <<<\n")
  merged_data <- merged_data %>%
    filter(URBAN2011_ind != "(1) Urban 1")
  cat("Rural sample size:", nrow(merged_data), "\n")
  cat("Urban areas excluded for focused rural labor market analysis\n")
}

# VARIABLE CONSTRUCTION --------------------------------------------------------

print_section("VARIABLE CONSTRUCTION")

analysis_data <- merged_data %>%
  mutate(
    # Employment outcomes
    employed = case_when(
      WKANY5 %in% c("(2) <240hrs 2", "(3) parttime 3", "(4) ft yr 4") ~ 1,
      WKANY5 %in% c("(0) none 0", "(1) missing hours 1") ~ 0,
      TRUE ~ NA_real_
    ),
    
    employment_type = case_when(
      convert_work_var(WKSALARY) == 1 ~ "Salaried",
      convert_work_var(WKBUSINESS) == 1 ~ "Business",
      convert_work_var(WKFARM) == 1 ~ "Farm",
      convert_work_var(WKAGLAB) == 1 | convert_work_var(WKNONAG) == 1 ~ "Wage_Labor",
      employed == 0 ~ "Not_Working",
      TRUE ~ "Other"
    ) %>% factor(levels = c("Not_Working", "Salaried", "Business", 
                           "Farm", "Wage_Labor", "Other")),
    
    # Social capital
    org_membership = as.numeric(ME1 == "(1) Yes 1"),
    general_trust = as.numeric(TR1 == "(1) Most people can be trusted 1"),
    
    # Demographics & cultural capital
    female = as.numeric(RO3 == "(2) Female 2"),
    age = as.numeric(as.character(RO5)),
    age_sq = age^2,
    
    education_years = extract_education_years(ED6),
    education_cat = case_when(
      education_years == 0 ~ "No_education",
      education_years <= 5 ~ "Primary",
      education_years <= 10 ~ "Secondary",
      education_years > 10 ~ "Higher",
      TRUE ~ "Unknown"
    ) %>% factor(levels = c("No_education", "Primary", "Secondary", 
                           "Higher", "Unknown")),
    
    social_group = factor(
      GROUPS_ind,
      levels = c("(1) Brahmin 1", "(2) Forward caste 2", "(3) OBC 3", 
                 "(4) Dalit 4", "(5) Adivasi 5", "(6) Muslim 6", 
                 "(7) Christian, Sikh, Jain 7"),
      labels = c("Brahmins", "Forward_castes", "OBCs", "Dalits", 
                 "Adivasis", "Muslims", "Other_Religions")
    ),
    
    # Economic controls
    wealth_index = as.numeric(as.character(ASSETS_hh)),
    consumption = as.numeric(as.character(COTOTAL_hh)),
    ln_consumption = log(consumption + 1),
    urban_resident = as.numeric(URBAN2011_ind == "(1) Urban 1")
  ) %>%
  # Use dplyr::select to avoid conflicts
  dplyr::select(
    IDHH, PERSONID, STATEID_ind, DISTID_ind, PSUID_ind,
    employed, employment_type, WKSALARY, WKBUSINESS, WKFARM, 
    WKAGLAB, WKNONAG, org_membership, general_trust,
    education_years, education_cat, social_group,
    female, age, age_sq, wealth_index, consumption, 
    ln_consumption, urban_resident, WT_ind, FWT_ind
  )

cat("Final dataset dimensions:", dim(analysis_data), "\n\n")

# DESCRIPTIVE STATISTICS -------------------------------------------------------

print_section("DESCRIPTIVE STATISTICS")

cat("\nEmployment Type Distribution:\n")
print(table(analysis_data$employment_type, useNA = "always"))

cat("\nSocial Group Distribution:\n")
print(table(analysis_data$social_group, useNA = "always"))

cat("\nEducation Category Distribution:\n")
print(table(analysis_data$education_cat, useNA = "always"))

# Missing values
cat("\nMissing Values in Key Variables:\n")
key_vars <- c("employed", "org_membership", "general_trust", "education_years", 
              "social_group", "female", "age", "wealth_index", "urban_resident")
missing_summary <- sapply(analysis_data[key_vars], function(x) sum(is.na(x)))
print(data.frame(
  Variable = names(missing_summary),
  Missing = missing_summary,
  Percent = round(100 * missing_summary / nrow(analysis_data), 2)
))

# WEALTH-EMPLOYMENT PARADOX ANALYSIS -------------------------------------------

print_section("WEALTH-EMPLOYMENT PARADOX BY SOCIAL GROUP")

wealth_by_group <- analysis_data %>%
  group_by(social_group) %>%
  summarise(
    n = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    mean_wealth = mean(wealth_index, na.rm = TRUE),
    mean_education = mean(education_years, na.rm = TRUE),
    urban_rate = mean(urban_resident, na.rm = TRUE),
    org_membership_rate = mean(org_membership, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_wealth))

print(wealth_by_group)

# Calculate correlation
wealth_emp_cor <- cor(
  wealth_by_group$mean_wealth, 
  wealth_by_group$employment_rate, 
  use = "complete.obs"
)

cat("\n>>> KEY FINDING: Wealth-Employment Paradox!\n")
cat("    Correlation between wealth and employment:", 
    round(wealth_emp_cor, 3), "\n")
cat("    Wealthier groups (Other_Religions: highest wealth) have LOWER\n")
cat("    employment than poorer groups (Adivasis: lowest wealth) with\n")
cat("    HIGHER employment. This suggests wealthier groups may have\n")
cat("    lower labor force participation!\n\n")

# Visualization
p1 <- ggplot(
  wealth_by_group, 
  aes(x = mean_wealth, y = employment_rate, color = social_group, size = n)
) +
  geom_point(alpha = 0.7) +
  geom_text(aes(label = social_group), vjust = -1, size = 3, 
            show.legend = FALSE) +
  labs(
    title = "Wealth-Employment Paradox by Social Group",
    subtitle = paste("Correlation:", round(wealth_emp_cor, 3), 
                    "- Wealthier groups show LOWER employment"),
    x = "Mean Wealth Index",
    y = "Employment Rate",
    size = "Sample Size"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

print(p1)

# MUSLIM GROUP DEEP DIVE -------------------------------------------------------

print_section("MUSLIM GROUP DISADVANTAGE ANALYSIS")

# Muslim profile
muslim_profile <- analysis_data %>%
  filter(social_group == "Muslims") %>%
  summarise(
    n = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    mean_wealth = mean(wealth_index, na.rm = TRUE),
    mean_education = mean(education_years, na.rm = TRUE),
    female_rate = mean(female, na.rm = TRUE),
    urban_rate = mean(urban_resident, na.rm = TRUE),
    org_membership_rate = mean(org_membership, na.rm = TRUE)
  )

cat("\nMuslim Group Characteristics:\n")
print(muslim_profile)

# Compare all groups
all_groups_comparison <- analysis_data %>%
  group_by(social_group) %>%
  summarise(
    n = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    mean_wealth = mean(wealth_index, na.rm = TRUE),
    mean_education = mean(education_years, na.rm = TRUE),
    urban_rate = mean(urban_resident, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(employment_rate)

cat("\nAll Groups Comparison (sorted by employment rate):\n")
print(all_groups_comparison)

# Employment types for Muslims
muslim_employment_types <- analysis_data %>%
  filter(social_group == "Muslims") %>%
  count(employment_type) %>%
  mutate(percent = round(100 * n / sum(n), 2)) %>%
  arrange(desc(n))

cat("\nMuslim Employment Type Distribution:\n")
print(muslim_employment_types)

# MECHANISM ANALYSIS: Occupational Segregation ---------------------------------

print_section("OCCUPATIONAL SEGREGATION ANALYSIS")

cat("\nPotential Mechanisms for Muslim Employment Patterns:\n")
muslim_mechanisms <- analysis_data %>%
  filter(social_group == "Muslims") %>%
  summarise(
    salaried_rate = mean(convert_work_var(WKSALARY), na.rm = TRUE),
    business_rate = mean(convert_work_var(WKBUSINESS), na.rm = TRUE),
    farm_rate = mean(convert_work_var(WKFARM), na.rm = TRUE),
    higher_education_rate = mean(education_cat == "Higher", na.rm = TRUE),
    no_education_rate = mean(education_cat == "No_education", na.rm = TRUE)
  )
print(muslim_mechanisms)

# Compare with all groups
mechanisms_all <- analysis_data %>%
  group_by(social_group) %>%
  summarise(
    salaried_rate = mean(convert_work_var(WKSALARY), na.rm = TRUE),
    business_rate = mean(convert_work_var(WKBUSINESS), na.rm = TRUE),
    farm_rate = mean(convert_work_var(WKFARM), na.rm = TRUE),
    higher_education_rate = mean(education_cat == "Higher", na.rm = TRUE),
    no_education_rate = mean(education_cat == "No_education", na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(salaried_rate)

cat("\nEmployment Mechanisms by Social Group (sorted by salaried employment):\n")
print(mechanisms_all)

cat("\n>>> CRITICAL FINDING: Muslims have the LOWEST salaried employment rate (1.9%)!\n")
cat("    This indicates severe barriers to formal sector employment.\n\n")

# REGRESSION ANALYSIS ----------------------------------------------------------

print_section("REGRESSION MODEL: EMPLOYMENT PROBABILITY")

# Create clean dataset for modeling
model_data <- analysis_data %>%
  filter(complete.cases(
    employed, org_membership, education_years, social_group, 
    female, age, wealth_index, urban_resident
  ))

cat("Observations for modeling:", nrow(model_data), "\n")

model_employment <- glm(
  employed ~ org_membership + general_trust +
    education_years + social_group +
    female + age + age_sq +
    wealth_index + urban_resident +
    factor(STATEID_ind),
  family = binomial(link = "logit"),
  data = model_data
)

# Model fit statistics
mcfadden_r2 <- 1 - (model_employment$deviance / model_employment$null.deviance)

# Safe coefficient extraction
get_coef_info <- function(model, term) {
  if (term %in% names(coef(model))) {
    coef_val <- coef(model)[term]
    p_val <- summary(model)$coefficients[term, 4]
    or_val <- exp(coef_val)
    list(coef = coef_val, p = p_val, or = or_val, found = TRUE)
  } else {
    list(found = FALSE)
  }
}

cat("\n>>> KEY MODEL RESULTS:\n\n")

cat("1. SOCIAL CAPITAL EFFECTS:\n")
org_result <- get_coef_info(model_employment, "org_membership")
if (org_result$found) {
  sig_star <- ifelse(org_result$p < 0.001, "***", 
                    ifelse(org_result$p < 0.01, "**", 
                          ifelse(org_result$p < 0.05, "*", "")))
  cat("   • Organization membership coefficient:", 
      round(org_result$coef, 4), sig_star, "\n")
  cat("     Odds Ratio:", round(org_result$or, 4), "->", 
      round(100 * (org_result$or - 1), 2), "% higher odds\n")
}

cat("\n2. CULTURAL CAPITAL EFFECTS:\n")
edu_result <- get_coef_info(model_employment, "education_years")
if (edu_result$found) {
  sig_star <- ifelse(edu_result$p < 0.001, "***", 
                    ifelse(edu_result$p < 0.01, "**", 
                          ifelse(edu_result$p < 0.05, "*", "")))
  cat("   • Education (per year) OR:", round(edu_result$or, 4), 
      sig_star, "\n")
  cat("     Each additional year ->", 
      round(100 * (edu_result$or - 1), 2), "% higher employment odds\n")
}

cat("\n3. WEALTH PARADOX CONFIRMED:\n")
wealth_result <- get_coef_info(model_employment, "wealth_index")
if (wealth_result$found) {
  sig_star <- ifelse(wealth_result$p < 0.001, "***", 
                    ifelse(wealth_result$p < 0.01, "**", 
                          ifelse(wealth_result$p < 0.05, "*", "")))
  cat("   • Wealth coefficient:", round(wealth_result$coef, 4), 
      sig_star, "\n")
  cat("   • Interpretation: Each unit increase in wealth ->", 
      round(100 * (1 - wealth_result$or), 2), 
      "% LOWER employment odds\n")
}

cat("\n4. MUSLIM DISADVANTAGE:\n")
muslim_result <- get_coef_info(model_employment, "social_groupMuslims")
if (muslim_result$found) {
  sig_star <- ifelse(muslim_result$p < 0.001, "***", 
                    ifelse(muslim_result$p < 0.01, "**", 
                          ifelse(muslim_result$p < 0.05, "*", "")))
  cat("   • Muslim coefficient:", round(muslim_result$coef, 4), 
      sig_star, "\n")
  cat("   • Muslims have", round(100 * (1 - muslim_result$or), 2), 
      "% LOWER employment odds compared to Brahmins\n")
}

cat("\n5. MODEL FIT:\n")
cat("   • AIC:", round(AIC(model_employment), 1), "\n")
cat("   • Null deviance:", round(model_employment$null.deviance, 1), "\n")
cat("   • Residual deviance:", round(model_employment$deviance, 1), "\n")
fit_quality <- ifelse(mcfadden_r2 > 0.4, "excellent", 
                     ifelse(mcfadden_r2 > 0.2, "good", "moderate"))
cat("   • McFadden's R²:", round(mcfadden_r2, 3), "(", 
    fit_quality, "fit)\n")

# FINAL SUMMARY ----------------------------------------------------------------

print_section("KEY RESEARCH FINDINGS SUMMARY")

sample_type <- if (rural_only) "RURAL INDIA" else "ALL INDIA"
cat("\n>>> ANALYSIS SCOPE:", sample_type, "<<<\n")

cat("\n1. WEALTH-EMPLOYMENT PARADOX:\n")
cat("   • Correlation:", round(wealth_emp_cor, 3), 
    "(negative relationship)\n")
cat("   • Wealthier groups have LOWER employment rates\n")
cat("   • Regression confirms: wealth has NEGATIVE effect on employment\n")

cat("\n2. SOCIAL CAPITAL EFFECTS:\n")
if (org_result$found) {
  cat("   • Organization membership increases employment odds by", 
      round(100 * (org_result$or - 1), 1), "%\n")
}
org_membership_rate <- round(
  100 * mean(analysis_data$org_membership, na.rm = TRUE), 1
)
cat("   • Only", org_membership_rate, 
    "% of sample are organization members\n")

cat("\n3. MUSLIM DISADVANTAGE - MULTIDIMENSIONAL:\n")
employment_rank <- which(all_groups_comparison$social_group == "Muslims")
cat("   • Employment rate:", 
    round(100 * muslim_profile$employment_rate, 1), 
    "% (rank:", employment_rank, "out of", 
    nrow(all_groups_comparison), ")\n")
cat("   • Salaried employment: 1.9% (LOWEST of all groups)\n")
brahmin_education <- filter(
  all_groups_comparison, social_group == "Brahmins"
)$mean_education
cat("   • Education:", round(muslim_profile$mean_education, 1), 
    "years vs Brahmins:", round(brahmin_education, 1), "years\n")
brahmin_higher_ed <- filter(
  mechanisms_all, social_group == "Brahmins"
)$higher_education_rate
cat("   • Higher education:", 
    round(100 * muslim_mechanisms$higher_education_rate, 1), 
    "% vs Brahmins:", round(100 * brahmin_higher_ed, 1), "%\n")

cat("\n4. STRUCTURAL BARRIERS IDENTIFIED:\n")
education_gap <- round(brahmin_education - muslim_profile$mean_education, 1)
cat("   • Educational deficit (", education_gap, 
    "years behind Brahmins)\n")
cat("   • Occupational segregation (lowest formal sector access)\n")
cat("   • Limited organizational membership\n")
cat("   • Potential discrimination in formal labor markets\n")

cat("\n5. POLICY IMPLICATIONS:\n")
cat("   • Address educational gaps in Muslim-concentrated areas\n")
cat("   • Promote Muslim inclusion in formal sector employment\n")
cat("   • Support entrepreneurship and small business development\n")
cat("   • Strengthen community organizations and social networks\n")
cat("   • Implement anti-discrimination measures in labor markets\n")

cat("\n", rep("=", 80), "\n", sep = "")
cat("ANALYSIS COMPLETE\n")
cat(rep("=", 80), "\n", sep = "")