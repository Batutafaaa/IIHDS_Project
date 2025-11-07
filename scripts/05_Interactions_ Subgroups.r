# ==============================================================================
# ADVANCED ANALYSIS: INTERACTIONS & SUBGROUPS
# ==============================================================================

print_section("INTERACTION EFFECTS: SOCIAL CAPITAL × EDUCATION")

# Load data and main model
analysis_data <- readRDS("output/analysis_data.rds")
model_employment <- readRDS("output/models/model_employment_main.rds")

# Create model data (same as in regression script)
model_vars <- c("employed", "org_membership", "education_years", "social_group", 
                "female", "age", "age_sq", "wealth_index", "STATEID_ind")
model_data <- analysis_data %>%
  filter(complete.cases(pick(all_of(model_vars))))

# INTERACTION MODEL
model_interaction <- glm(
  employed ~ org_membership * education_years + 
    social_group + female + age + age_sq + 
    wealth_index + factor(STATEID_ind),
  family = binomial(link = "logit"),
  data = model_data
)

cat("\nInteraction Model Summary:\n")
print(summary(model_interaction))

# Save interaction model
saveRDS(model_interaction, "output/models/model_interaction.rds")

# SUBGROUP ANALYSIS
print_section("GENDER SUBGROUP ANALYSIS")

model_male <- glm(
  employed ~ org_membership + education_years + social_group + 
    age + age_sq + wealth_index + factor(STATEID_ind),
  family = binomial(link = "logit"),
  data = filter(model_data, female == 0)
)

model_female <- glm(
  employed ~ org_membership + education_years + social_group + 
    age + age_sq + wealth_index + factor(STATEID_ind),
  family = binomial(link = "logit"),
  data = filter(model_data, female == 1)
)

# Save subgroup models
saveRDS(model_male, "output/models/model_male.rds")
saveRDS(model_female, "output/models/model_female.rds")

# MUSLIM-SPECIFIC ANALYSIS
print_section("MUSLIM-SPECIFIC SUBGROUP ANALYSIS")

model_muslim <- glm(
  employed ~ org_membership + education_years + 
    female + age + age_sq + wealth_index + factor(STATEID_ind),
  family = binomial(link = "logit"),
  data = filter(model_data, social_group == "Muslims")
)

saveRDS(model_muslim, "output/models/model_muslim.rds")

cat("✓ Advanced analysis complete - all models saved\n")