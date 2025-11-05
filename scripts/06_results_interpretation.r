# ==============================================================================
# RESULTS INTERPRETATION & MARGINAL EFFECTS
# ==============================================================================

print_section("MARGINAL EFFECTS ANALYSIS")

# Load models
model_employment <- readRDS("output/models/model_employment_main.rds")
analysis_data <- readRDS("output/analysis_data.rds")

# Create model data
model_vars <- c("employed", "org_membership", "education_years", "social_group", 
                "female", "age", "age_sq", "wealth_index", "STATEID_ind")
model_data <- analysis_data %>%
  filter(complete.cases(pick(all_of(model_vars))))

cat("\nCalculating Average Marginal Effects...\n")

# Calculate AME for key variables
ame_org <- calculate_ame(model_employment, model_data, "org_membership", TRUE)
ame_edu <- calculate_ame(model_employment, model_data, "education_years", FALSE)
ame_female <- calculate_ame(model_employment, model_data, "female", TRUE)
ame_wealth <- calculate_ame(model_employment, model_data, "wealth_index", FALSE)

ame_results <- data.frame(
  Variable = c("Organization Membership", "Education (per year)", 
               "Female", "Wealth Index"),
  AME = c(ame_org$AME, ame_edu$AME, ame_female$AME, ame_wealth$AME),
  SE = c(ame_org$SE, ame_edu$SE, ame_female$SE, ame_wealth$SE),
  z_value = c(ame_org$z, ame_edu$z, ame_female$z, ame_wealth$z),
  p_value = c(ame_org$p, ame_edu$p, ame_female$p, ame_wealth$p)
)

cat("\nAverage Marginal Effects:\n")
print(ame_results)

# Save marginal effects
write.csv(ame_results, "output/tables/marginal_effects.csv", row.names = FALSE)

# MODEL RESULTS SUMMARY
print_section("MAIN MODEL RESULTS SUMMARY")

mcfadden_r2 <- 1 - (model_employment$deviance / model_employment$null.deviance)

cat("\n>>> KEY MODEL RESULTS:\n\n")
# ... rest of your interpretation code

cat("✓ Results interpretation complete - marginal effects saved\n")