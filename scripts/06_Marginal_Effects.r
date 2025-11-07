# ==============================================================================
# MARGINAL EFFECTS ANALYSIS 
# ==============================================================================

print_section("MARGINAL EFFECTS ANALYSIS - OPTIMIZED")

# Load model and data
model_employment <- readRDS("output/models/model_employment_main.rds")
analysis_data <- readRDS("output/analysis_data.rds")

cat("Starting marginal effects calculation...\n")

# ==============================================================================
# PREPARE DATA - Recreate the exact model dataset
# ==============================================================================

cat("Preparing analysis data...\n")

# Get complete cases for all model variables
model_vars <- c("employed", "org_membership", "education_years", "social_group", 
                "female", "age", "age_sq", "wealth_index", "STATEID_ind")

# Filter to complete cases (same as what was used in model fitting)
analysis_sample_full <- analysis_data %>%
  filter(complete.cases(pick(all_of(model_vars))))

cat("Complete cases available:", nrow(analysis_sample_full), "\n")

# Take a sample for computational speed
set.seed(123)
sample_size <- min(5000, nrow(analysis_sample_full))

if (nrow(analysis_sample_full) > 0) {
  sample_indices <- sample(1:nrow(analysis_sample_full), sample_size)
  analysis_sample <- analysis_sample_full[sample_indices, ]
  cat("Using sample of", sample_size, "observations\n")
} else {
  stop("ERROR: No complete cases found in analysis data!")
}

# ==============================================================================
# MARGINAL EFFECTS CALCULATION WITH ERROR HANDLING
# ==============================================================================

calculate_robust_ame <- function(model, data) {
  cat("\nCalculating Average Marginal Effects...\n")
  
  results <- list()
  
  # Test prediction first to ensure data compatibility
  cat("Testing data compatibility... ")
  test_pred <- tryCatch({
    predict(model, newdata = data[1:min(10, nrow(data)), ], type = "response")
  }, error = function(e) {
    cat("\nERROR:", e$message, "\n")
    return(NULL)
  })
  
  if (is.null(test_pred)) {
    stop("Data is not compatible with the model. Check factor levels.")
  }
  cat("✓\n")
  
  # 1. ORGANIZATION MEMBERSHIP (Binary)
  cat("  • Organization membership... ")
  
  # Create counterfactual datasets
  data_org0 <- data
  data_org1 <- data
  data_org0$org_membership <- 0
  data_org1$org_membership <- 1
  
  # Predict probabilities
  pred_org0 <- predict(model, newdata = data_org0, type = "response")
  pred_org1 <- predict(model, newdata = data_org1, type = "response")
  
  # Calculate marginal effect
  marginal_effects_org <- pred_org1 - pred_org0
  ame_org <- mean(marginal_effects_org, na.rm = TRUE)
  se_org <- sd(marginal_effects_org, na.rm = TRUE) / sqrt(length(marginal_effects_org))
  z_org <- ame_org / se_org
  p_org <- 2 * pnorm(-abs(z_org))
  
  results$org_membership <- list(AME = ame_org, SE = se_org, z = z_org, p = p_org)
  cat("✓\n")
  
  # 2. EDUCATION (Continuous)
  cat("  • Education years... ")
  
  # Get coefficient and predicted probabilities
  coef_edu <- coef(model)["education_years"]
  pred_prob <- predict(model, newdata = data, type = "response")
  
  # AME for continuous variable in logit
  ame_edu <- coef_edu * mean(pred_prob * (1 - pred_prob), na.rm = TRUE)
  
  # Standard error (delta method approximation)
  se_edu <- summary(model)$coefficients["education_years", "Std. Error"] * 
            mean(pred_prob * (1 - pred_prob), na.rm = TRUE)
  z_edu <- ame_edu / se_edu
  p_edu <- 2 * pnorm(-abs(z_edu))
  
  results$education_years <- list(AME = ame_edu, SE = se_edu, z = z_edu, p = p_edu)
  cat("✓\n")
  
  # 3. FEMALE (Binary)
  cat("  • Gender (female)... ")
  
  data_male <- data
  data_female <- data
  data_male$female <- 0
  data_female$female <- 1
  
  pred_male <- predict(model, newdata = data_male, type = "response")
  pred_female <- predict(model, newdata = data_female, type = "response")
  
  marginal_effects_female <- pred_female - pred_male
  ame_female <- mean(marginal_effects_female, na.rm = TRUE)
  se_female <- sd(marginal_effects_female, na.rm = TRUE) / sqrt(length(marginal_effects_female))
  z_female <- ame_female / se_female
  p_female <- 2 * pnorm(-abs(z_female))
  
  results$female <- list(AME = ame_female, SE = se_female, z = z_female, p = p_female)
  cat("✓\n")
  
  # 4. WEALTH INDEX (Continuous)
  cat("  • Wealth index... ")
  
  coef_wealth <- coef(model)["wealth_index"]
  ame_wealth <- coef_wealth * mean(pred_prob * (1 - pred_prob), na.rm = TRUE)
  se_wealth <- summary(model)$coefficients["wealth_index", "Std. Error"] * 
               mean(pred_prob * (1 - pred_prob), na.rm = TRUE)
  z_wealth <- ame_wealth / se_wealth
  p_wealth <- 2 * pnorm(-abs(z_wealth))
  
  results$wealth_index <- list(AME = ame_wealth, SE = se_wealth, z = z_wealth, p = p_wealth)
  cat("✓\n")
  
  return(results)
}

# Calculate marginal effects with timing
start_time <- Sys.time()

marginal_effects <- tryCatch({
  calculate_robust_ame(model_employment, analysis_sample)
}, error = function(e) {
  cat("\nERROR in marginal effects calculation:\n")
  cat(e$message, "\n")
  cat("\nThis may be due to factor level mismatches.\n")
  cat("Attempting alternative calculation method...\n\n")
  
  # FALLBACK: Use coefficient-based approximation
  cat("Using coefficient approximation method...\n")
  
  avg_pred_prob <- mean(fitted(model_employment), na.rm = TRUE)
  scaling_factor <- avg_pred_prob * (1 - avg_pred_prob)
  
  coefs <- coef(model_employment)
  
  list(
    org_membership = list(
      AME = coefs["org_membership"] * scaling_factor,
      SE = NA, z = NA, p = NA
    ),
    education_years = list(
      AME = coefs["education_years"] * scaling_factor,
      SE = NA, z = NA, p = NA
    ),
    female = list(
      AME = coefs["female"] * scaling_factor,
      SE = NA, z = NA, p = NA
    ),
    wealth_index = list(
      AME = coefs["wealth_index"] * scaling_factor,
      SE = NA, z = NA, p = NA
    )
  )
})

end_time <- Sys.time()

cat("\n✓ Calculation completed in", 
    round(difftime(end_time, start_time, units = "secs"), 1), "seconds\n")

# ==============================================================================
# FORMAT AND DISPLAY RESULTS
# ==============================================================================

ame_results <- data.frame(
  Variable = c("Organization Membership", "Education (per year)", 
               "Female", "Wealth Index"),
  AME = c(
    marginal_effects$org_membership$AME,
    marginal_effects$education_years$AME,
    marginal_effects$female$AME,
    marginal_effects$wealth_index$AME
  ),
  SE = c(
    marginal_effects$org_membership$SE,
    marginal_effects$education_years$SE,
    marginal_effects$female$SE,
    marginal_effects$wealth_index$SE
  ),
  z_value = c(
    marginal_effects$org_membership$z,
    marginal_effects$education_years$z,
    marginal_effects$female$z,
    marginal_effects$wealth_index$z
  ),
  p_value = c(
    marginal_effects$org_membership$p,
    marginal_effects$education_years$p,
    marginal_effects$female$p,
    marginal_effects$wealth_index$p
  ),
  stringsAsFactors = FALSE
)

# Add derived columns
ame_results <- ame_results %>%
  mutate(
    AME_percentage = AME * 100,
    CI_lower = if_else(is.na(SE), NA_real_, (AME - 1.96 * SE) * 100),
    CI_upper = if_else(is.na(SE), NA_real_, (AME + 1.96 * SE) * 100),
    sig = case_when(
      is.na(p_value) ~ "",
      p_value < 0.001 ~ "***",
      p_value < 0.01 ~ "**",
      p_value < 0.05 ~ "*",
      p_value < 0.1 ~ ".",
      TRUE ~ ""
    )
  )

# Display results
cat("\n")
print_section("AVERAGE MARGINAL EFFECTS RESULTS")

display_cols <- c("Variable", "AME_percentage", "SE", "CI_lower", "CI_upper", "p_value", "sig")
if (all(is.na(ame_results$SE))) {
  display_cols <- c("Variable", "AME_percentage")
  cat("\nNote: Standard errors not available (approximation method used)\n\n")
}

print(ame_results %>% 
        select(all_of(display_cols)) %>%
        mutate(across(where(is.numeric), ~round(., 3))),
      row.names = FALSE)

# Save results
write.csv(ame_results, "output/tables/marginal_effects.csv", row.names = FALSE)
cat("\n✓ Results saved to output/tables/marginal_effects.csv\n")

# ==============================================================================
# INTERPRETATION
# ==============================================================================

print_section("INTERPRETATION OF RESULTS")

cat("\n>>> EMPLOYMENT PROBABILITY EFFECTS <<<\n\n")

for (i in 1:nrow(ame_results)) {
  row <- ame_results[i, ]
  cat(sprintf("%d. %s:\n", i, toupper(row$Variable)))
  
  if (!is.na(row$CI_lower)) {
    cat(sprintf("   Effect: %+.2f percentage points", row$AME_percentage))
    cat(sprintf(" [95%% CI: %.2f, %.2f] %s\n", row$CI_lower, row$CI_upper, row$sig))
  } else {
    cat(sprintf("   Effect: %+.2f percentage points\n", row$AME_percentage))
  }
  
  # Interpretation
  if (row$Variable == "Organization Membership") {
    cat("   → Being in an organization is associated with a")
    cat(sprintf(" %.1f pp %s in employment probability\n", 
                abs(row$AME_percentage), 
                ifelse(row$AME_percentage > 0, "increase", "decrease")))
  } else if (row$Variable == "Education (per year)") {
    cat("   → Each additional year of education increases employment")
    cat(sprintf(" probability by %.2f pp\n", row$AME_percentage))
  } else if (row$Variable == "Female") {
    cat("   → Women have")
    cat(sprintf(" %.1f pp %s employment probability than men\n", 
                abs(row$AME_percentage),
                ifelse(row$AME_percentage > 0, "higher", "lower")))
  } else if (row$Variable == "Wealth Index") {
    cat("   → Each unit increase in wealth index is associated with")
    cat(sprintf(" %.2f pp %s in employment probability\n", 
                abs(row$AME_percentage),
                ifelse(row$AME_percentage > 0, "increase", "decrease")))
  }
  cat("\n")
}

# ==============================================================================
# COMPARISON WITH ODDS RATIOS
# ==============================================================================

cat("=== ODDS RATIOS VS MARGINAL EFFECTS ===\n\n")

org_or <- exp(coef(model_employment)["org_membership"])
edu_or <- exp(coef(model_employment)["education_years"])
female_or <- exp(coef(model_employment)["female"])
wealth_or <- exp(coef(model_employment)["wealth_index"])

comparison <- data.frame(
  Variable = c("Organization", "Education", "Female", "Wealth"),
  Odds_Ratio = c(org_or, edu_or, female_or, wealth_or),
  OR_pct_change = c((org_or-1)*100, (edu_or-1)*100, (female_or-1)*100, (wealth_or-1)*100),
  Marginal_Effect_pp = ame_results$AME_percentage
)

print(comparison %>% mutate(across(where(is.numeric), ~round(., 2))), row.names = FALSE)

cat("\nNote: Marginal effects (pp) are more interpretable than odds ratios.\n")

# ==============================================================================
# MODEL FIT STATISTICS
# ==============================================================================

cat("\n")
print_section("MODEL FIT STATISTICS")

mcfadden_r2 <- 1 - (model_employment$deviance / model_employment$null.deviance)

fit_stats <- data.frame(
  Metric = c("N", "AIC", "McFadden R²", "Log-Likelihood"),
  Value = c(
    nobs(model_employment),
    round(AIC(model_employment), 1),
    round(mcfadden_r2, 4),
    round(logLik(model_employment)[1], 1)
  )
)

print(fit_stats, row.names = FALSE)

cat("\n✓ Marginal effects analysis complete!\n")

# ==============================================================================
# MUSLIM-SPECIFIC MARGINAL EFFECTS
# ==============================================================================

print_section("MUSLIM DISADVANTAGE MARGINAL EFFECTS")

# Calculate marginal effect for Muslim vs Brahmin (reference group)
calculate_muslim_ame <- function(model, data) {
  # Create counterfactual datasets
  data_brahmin <- data
  data_muslim <- data
  
  # Set all observations to Brahmin (reference group)
  data_brahmin$social_group <- "Brahmins"
  # Set all observations to Muslim
  data_muslim$social_group <- "Muslims"
  
  # Predict probabilities
  pred_brahmin <- predict(model, newdata = data_brahmin, type = "response")
  pred_muslim <- predict(model, newdata = data_muslim, type = "response")
  
  # Marginal effect = Muslim prob - Brahmin prob
  marginal_effects <- pred_muslim - pred_brahmin
  ame <- mean(marginal_effects, na.rm = TRUE)
  se <- sd(marginal_effects, na.rm = TRUE) / sqrt(length(marginal_effects))
  
  return(list(AME = ame, SE = se, z = ame/se, 
              p = 2 * (1 - pnorm(abs(ame/se)))))
}

# Calculate Muslim disadvantage
muslim_ame <- calculate_muslim_ame(model_employment, analysis_sample)

cat("Muslim vs Brahmin Marginal Effect:\n")
cat(sprintf("AME: %.3f (%.3f percentage points)\n", 
            muslim_ame$AME, muslim_ame$AME * 100))
cat(sprintf("95%% CI: [%.3f, %.3f]\n",
            (muslim_ame$AME - 1.96 * muslim_ame$SE) * 100,
            (muslim_ame$AME + 1.96 * muslim_ame$SE) * 100))
cat(sprintf("p-value: %.4f\n", muslim_ame$p))

# Add to your existing AME results
muslim_row <- data.frame(
  Variable = "Muslim (vs Brahmin)",
  AME = muslim_ame$AME,
  SE = muslim_ame$SE,
  z_value = muslim_ame$z,
  p_value = muslim_ame$p,
  AME_percentage = muslim_ame$AME * 100,
  CI_lower = (muslim_ame$AME - 1.96 * muslim_ame$SE) * 100,
  CI_upper = (muslim_ame$AME + 1.96 * muslim_ame$SE) * 100,
  sig = ifelse(muslim_ame$p < 0.001, "***",
               ifelse(muslim_ame$p < 0.01, "**",
                      ifelse(muslim_ame$p < 0.05, "*",
                             ifelse(muslim_ame$p < 0.1, ".", ""))))
)

# Combine with existing results
ame_results_enhanced <- rbind(ame_results, muslim_row)

print(ame_results_enhanced %>% 
        select(Variable, AME_percentage, CI_lower, CI_upper, p_value, sig) %>%
        mutate(across(where(is.numeric), ~round(., 3))),
      row.names = FALSE)