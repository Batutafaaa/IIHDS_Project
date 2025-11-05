# ==============================================================================
# REGRESSION MODELING - OPTIMIZED FOR LARGE MODELS
# ==============================================================================

print_section("REGRESSION MODEL: EMPLOYMENT PROBABILITY")

# Load analysis data
analysis_data <- readRDS("output/analysis_data.rds")
cat("Data loaded successfully. Observations:", nrow(analysis_data), "\n")

# Create clean dataset for modeling
model_vars <- c("employed", "org_membership", "education_years", "social_group", 
                "female", "age", "age_sq", "wealth_index", "STATEID_ind")

model_data <- analysis_data %>%
  filter(complete.cases(pick(all_of(model_vars))))

cat("Clean data for modeling:", nrow(model_data), "observations\n")

# Check for potential issues
cat("\nData diagnostics:\n")
cat("• Employment rate:", round(mean(model_data$employed, na.rm = TRUE), 3), "\n")
cat("• Organization membership rate:", 
    round(mean(model_data$org_membership, na.rm = TRUE), 3), "\n")
cat("• Number of states:", length(unique(model_data$STATEID_ind)), "\n")

# MAIN MODEL with error handling
cat("\nFitting main regression model...\n")

model_employment <- tryCatch({
  glm(
    employed ~ org_membership +
      education_years + social_group +
      female + age + age_sq +
      wealth_index +
      factor(STATEID_ind),
    family = binomial(link = "logit"),
    data = model_data
  )
}, error = function(e) {
  cat("ERROR in model fitting:", e$message, "\n")
  return(NULL)
})

if (!is.null(model_employment)) {
  cat("✓ Model fitting completed successfully\n")
  cat("• Fisher Scoring iterations:", model_employment$iter, "\n")
  cat("• AIC:", round(AIC(model_employment), 1), "\n")
  
  # Save main model
  saveRDS(model_employment, "output/models/model_employment_main.rds")
  cat("✓ Model saved\n")
  
  # EFFICIENT SUMMARY EXTRACTION (avoids broom::tidy slowdown)
  cat("\nExtracting model summary efficiently...\n")
  
  coef_summary <- summary(model_employment)$coefficients
  
  model_summary <- data.frame(
    term = rownames(coef_summary),
    estimate = coef_summary[, "Estimate"],
    std.error = coef_summary[, "Std. Error"],
    statistic = coef_summary[, "z value"],
    p.value = coef_summary[, "Pr(>|z|)"],
    stringsAsFactors = FALSE
  )
  
  # Add confidence intervals using Wald method (fast)
  model_summary$conf.low <- model_summary$estimate - 1.96 * model_summary$std.error
  model_summary$conf.high <- model_summary$estimate + 1.96 * model_summary$std.error
  
  # Add significance stars
  model_summary$sig <- sapply(model_summary$p.value, function(p) {
    if (p < 0.001) return("***")
    if (p < 0.01) return("**")
    if (p < 0.05) return("*")
    if (p < 0.1) return(".")
    return("")
  })
  
  # Save full summary
  write.csv(model_summary, 
            "output/tables/model_employment_full_summary.csv", 
            row.names = FALSE)
  cat("✓ Full summary saved (", nrow(model_summary), "coefficients)\n")
  
  # Create KEY VARIABLES summary (exclude state dummies for readability)
  key_vars_pattern <- "^(Intercept|org_membership|education_years|social_group|female|age|wealth_index)"
  key_summary <- model_summary %>%
    filter(grepl(key_vars_pattern, term))
  
  write.csv(key_summary, 
            "output/tables/model_employment_key_vars.csv", 
            row.names = FALSE)
  
  cat("\n--- KEY VARIABLES SUMMARY ---\n")
  print(key_summary, row.names = FALSE)
  
  # Model fit statistics
  mcfadden_r2 <- 1 - (model_employment$deviance / model_employment$null.deviance)
  
  fit_stats <- data.frame(
    Metric = c("N", "AIC", "Null Deviance", "Residual Deviance", 
               "McFadden R²", "Log-Likelihood"),
    Value = c(
      nobs(model_employment),
      round(AIC(model_employment), 1),
      round(model_employment$null.deviance, 1),
      round(model_employment$deviance, 1),
      round(mcfadden_r2, 3),
      round(logLik(model_employment)[1], 1)
    )
  )
  
  cat("\n--- MODEL FIT STATISTICS ---\n")
  print(fit_stats, row.names = FALSE)
  
  write.csv(fit_stats, "output/tables/model_fit_statistics.csv", row.names = FALSE)
  
  # Quick coefficient interpretation
  cat("\n--- QUICK INTERPRETATION ---\n")
  
  org_or <- exp(coef(model_employment)["org_membership"])
  cat("• Organization membership OR:", round(org_or, 3), 
      "(", round(100 * (org_or - 1), 1), "% higher odds)\n")
  
  edu_or <- exp(coef(model_employment)["education_years"])
  cat("• Education (per year) OR:", round(edu_or, 3),
      "(", round(100 * (edu_or - 1), 1), "% higher odds)\n")
  
  wealth_or <- exp(coef(model_employment)["wealth_index"])
  cat("• Wealth OR:", round(wealth_or, 3),
      "(", round(100 * (1 - wealth_or), 1), "% LOWER odds)\n")
  
  if ("social_groupMuslims" %in% names(coef(model_employment))) {
    muslim_or <- exp(coef(model_employment)["social_groupMuslims"])
    cat("• Muslim (vs Brahmin) OR:", round(muslim_or, 3),
        "(", round(100 * (1 - muslim_or), 1), "% lower odds)\n")
  }
  
} else {
  cat("!!! Model fitting failed - check error messages above\n")
}

cat("\n✓ Regression modeling complete\n")