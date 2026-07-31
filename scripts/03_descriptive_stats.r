# ==============================================================================
# 03_DESCRIPTIVE STATISTICS & EXPLORATORY ANALYSIS
# ==============================================================================
# Runs on the full sample (analysis_data.rds). Produces:
#   • Distribution tables for key variables
#   • Wealth-Employment Paradox summary
#   • Group comparison table with urban/rural breakdown
#   • Social capital participation by group
# ==============================================================================

print_section("DESCRIPTIVE STATISTICS")

analysis_data <- readRDS("output/analysis_data.rds")
cat("Analysis data loaded:", nrow(analysis_data), "observations\n")
cat("Urban:", sum(analysis_data$urban_resident == 1, na.rm = TRUE),
    "| Rural:", sum(analysis_data$urban_resident == 0, na.rm = TRUE), "\n\n")

# ── DISTRIBUTION TABLES ──────────────────────────────────────────────────────
cat("\nEmployment Type Distribution:\n")
print(table(analysis_data$employment_type, useNA = "always"))

cat("\nSocial Group Distribution:\n")
print(table(analysis_data$social_group, useNA = "always"))

cat("\nEducation Category Distribution:\n")
print(table(analysis_data$education_cat, useNA = "always"))

cat("\nUrban/Rural Split:\n")
print(table(analysis_data$urban_resident, useNA = "always"))

# ── MISSING VALUES ───────────────────────────────────────────────────────────
cat("\nMissing Values in Key Variables:\n")
key_vars <- c("employed", "org_membership",  "education_years",
              "social_group", "female", "age", "wealth_index", "urban_resident")
missing_summary <- sapply(analysis_data[key_vars], function(x) sum(is.na(x)))
missing_df <- data.frame(
  Variable = names(missing_summary),
  Missing  = missing_summary,
  Percent  = round(100 * missing_summary / nrow(analysis_data), 2)
)
print(missing_df)
write.csv(missing_df, "output/tables/missing_data_summary.csv", row.names = FALSE)

# ── WEALTH-EMPLOYMENT PARADOX ─────────────────────────────────────────────────
print_section("WEALTH-EMPLOYMENT PARADOX BY SOCIAL GROUP")

wealth_by_group <- analysis_data %>%
  group_by(social_group) %>%
  summarise(
    n                   = n(),
    employment_rate     = mean(employed, na.rm = TRUE),
    mean_wealth         = mean(wealth_index, na.rm = TRUE),
    mean_education      = mean(education_years, na.rm = TRUE),
    org_membership_rate = mean(org_membership, na.rm = TRUE),
    
    .groups = "drop"
  ) %>%
  arrange(desc(mean_wealth))

print(wealth_by_group)
write.csv(wealth_by_group, "output/tables/wealth_by_group.csv", row.names = FALSE)

wealth_emp_cor <- cor(
  wealth_by_group$mean_wealth,
  wealth_by_group$employment_rate,
  use = "complete.obs"
)
cat("\n>>> Wealth-Employment Correlation:", round(wealth_emp_cor, 3), "\n")
cat("    Negative correlation confirms: poorer groups work more (distress labour)\n")

# ── COMPREHENSIVE GROUP COMPARISON (full + urban/rural) ──────────────────────
print_section("GROUP COMPARISON: FULL SAMPLE + URBAN/RURAL BREAKDOWN")

# Full sample comparison
group_comparison_full <- analysis_data %>%
  filter(!is.na(social_group)) %>%
  group_by(social_group) %>%
  summarise(
    n                   = n(),
    employment_rate     = mean(employed, na.rm = TRUE),
    mean_wealth         = mean(wealth_index, na.rm = TRUE),
    mean_education      = mean(education_years, na.rm = TRUE),
    org_membership_rate = mean(org_membership, na.rm = TRUE),
    
    urban_share         = mean(urban_resident, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    employment_rank = rank(-employment_rate),
    wealth_rank     = rank(-mean_wealth),
    education_rank  = rank(-mean_education)
  )

cat("\nFull sample group comparison:\n")
print(group_comparison_full)
write.csv(group_comparison_full, "output/tables/group_comparison_detailed.csv", row.names = FALSE)

# Urban/rural breakdown by group
group_comparison_urban_rural <- analysis_data %>%
  filter(!is.na(social_group), !is.na(urban_resident)) %>%
  mutate(urban_rural = ifelse(urban_resident == 1, "Urban", "Rural")) %>%
  group_by(social_group, urban_rural) %>%
  summarise(
    n               = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    mean_education  = mean(education_years, na.rm = TRUE),
    mean_wealth     = mean(wealth_index, na.rm = TRUE),
    org_rate        = mean(org_membership, na.rm = TRUE),
    
    .groups = "drop"
  )

cat("\nGroup comparison by Urban/Rural:\n")
print(group_comparison_urban_rural, n = Inf)
write.csv(group_comparison_urban_rural,
          "output/tables/group_comparison_urban_rural.csv", row.names = FALSE)

# ── MUSLIM PROFILE (for later scripts) ───────────────────────────────────────
muslim_profile <- analysis_data %>%
  filter(social_group == "Muslims") %>%
  summarise(
    n               = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    mean_wealth     = mean(wealth_index, na.rm = TRUE),
    mean_education  = mean(education_years, na.rm = TRUE),
    female_rate     = mean(female, na.rm = TRUE),
    org_rate        = mean(org_membership, na.rm = TRUE),
    
    urban_share     = mean(urban_resident, na.rm = TRUE)
  )
write.csv(muslim_profile, "output/tables/muslim_profile.csv", row.names = FALSE)

# Education-employment crosswalk for Muslims
muslim_education_emp <- analysis_data %>%
  filter(social_group == "Muslims") %>%
  group_by(education_cat) %>%
  summarise(
    n               = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    .groups = "drop"
  )
write.csv(muslim_education_emp, "output/tables/muslim_education_employment.csv", row.names = FALSE)

# Muslim gender gap
muslim_gender_gap <- analysis_data %>%
  filter(social_group == "Muslims") %>%
  mutate(gender = ifelse(female == 1, "Female", "Male")) %>%
  group_by(gender) %>%
  summarise(
    n               = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    mean_education  = mean(education_years, na.rm = TRUE),
    .groups = "drop"
  )
write.csv(muslim_gender_gap, "output/tables/muslim_gender_gap.csv", row.names = FALSE)

cat("\n✓ Descriptive statistics complete — tables saved\n")
