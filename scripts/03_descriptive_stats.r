# ==============================================================================
# DESCRIPTIVE STATISTICS & EXPLORATORY ANALYSIS
# ==============================================================================

print_section("DESCRIPTIVE STATISTICS")

# Load analysis data
analysis_data <- readRDS("output/analysis_data.rds")

cat("\nEmployment Type Distribution:\n")
print(table(analysis_data$employment_type, useNA = "always"))

cat("\nSocial Group Distribution:\n")
print(table(analysis_data$social_group, useNA = "always"))

cat("\nEducation Category Distribution:\n")
print(table(analysis_data$education_cat, useNA = "always"))

# Missing values
cat("\nMissing Values in Key Variables:\n")
key_vars <- c("employed", "org_membership", "general_trust", "education_years", 
              "social_group", "female", "age", "wealth_index")
if (!rural_only) key_vars <- c(key_vars, "urban_resident")

missing_summary <- sapply(analysis_data[key_vars], function(x) sum(is.na(x)))
missing_df <- data.frame(
  Variable = names(missing_summary),
  Missing = missing_summary,
  Percent = round(100 * missing_summary / nrow(analysis_data), 2)
)
print(missing_df)

# Save missing data summary
write.csv(missing_df, "output/tables/missing_data_summary.csv", row.names = FALSE)

# WEALTH-EMPLOYMENT PARADOX ANALYSIS
print_section("WEALTH-EMPLOYMENT PARADOX BY SOCIAL GROUP")

wealth_by_group <- analysis_data %>%
  group_by(social_group) %>%
  summarise(
    n = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    mean_wealth = mean(wealth_index, na.rm = TRUE),
    mean_education = mean(education_years, na.rm = TRUE),
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

# Save wealth analysis
write.csv(wealth_by_group, "output/tables/wealth_by_group.csv", row.names = FALSE)

# MUSLIM GROUP DEEP DIVE
print_section("MUSLIM GROUP DISADVANTAGE ANALYSIS")

muslim_profile <- analysis_data %>%
  filter(social_group == "Muslims") %>%
  summarise(
    n = n(),
    employment_rate = mean(employed, na.rm = TRUE),
    mean_wealth = mean(wealth_index, na.rm = TRUE),
    mean_education = mean(education_years, na.rm = TRUE),
    female_rate = mean(female, na.rm = TRUE),
    org_membership_rate = mean(org_membership, na.rm = TRUE)
  )

cat("\nMuslim Group Characteristics:\n")
print(muslim_profile)

# Save Muslim profile
write.csv(muslim_profile, "output/tables/muslim_profile.csv", row.names = FALSE)

cat("✓ Descriptive statistics complete - tables saved\n")