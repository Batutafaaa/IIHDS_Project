# ==============================================================================
# 04_REGRESSION MODELS — Survey-Weighted Employment Probability
# ==============================================================================
# Key methodological decisions:
#
#   1. SURVEY WEIGHTS: Uses svydesign() + svyglm() to properly account for
#      IHDS-II's stratified multistage sampling design. Clustering is at the
#      PSU (Primary Sampling Unit) level, matching the survey design.
#
#   2. TWO SOCIAL CAPITAL DIMENSIONS:
#      - org_membership: bridging social capital (formal/informal group membership)
#      - :  bonding social capital (generalised trust in others)
#
#   3. FULL SAMPLE: Includes both urban and rural respondents. urban_resident
#      is a control variable, not a filter. This allows urban-rural dynamics
#      to be estimated rather than assumed away.
#
#   4. STATE FIXED EFFECTS: factor(STATEID_ind) absorbs unobservable
#      state-level confounders (governance, institutions, culture).
#
#   5. REFERENCE GROUPS: Brahmins (social_group), Male (female=0)
# ==============================================================================

print_section("REGRESSION MODEL: EMPLOYMENT PROBABILITY")

analysis_data <- readRDS("output/analysis_data.rds")
cat("Data loaded:", nrow(analysis_data), "observations\n")
cat("Urban:", sum(analysis_data$urban_resident == 1, na.rm = TRUE),
    "| Rural:", sum(analysis_data$urban_resident == 0, na.rm = TRUE), "\n")

# ------------------------------------------------------------------------------
# PREPARE MODEL DATA
# ------------------------------------------------------------------------------
model_vars <- c("employed", "org_membership",  "education_years",
                "social_group", "female", "age", "age_sq", "wealth_index",
                "urban_resident", "STATEID_ind", "PSUID_ind", "WT_ind")

model_data <- analysis_data %>%
  filter(complete.cases(pick(all_of(model_vars))))

cat("\nComplete cases for modeling:", nrow(model_data), "observations\n")
cat("Employment rate in model sample:",
    round(mean(model_data$employed, na.rm = TRUE), 3), "\n")
cat("Org membership rate:",
    round(mean(model_data$org_membership, na.rm = TRUE), 3), "\n")

cat("Urban share:", round(mean(model_data$urban_resident, na.rm = TRUE), 3), "\n")
cat("Number of states:", length(unique(model_data$STATEID_ind)), "\n")
cat("Number of PSUs:", length(unique(model_data$PSUID_ind)), "\n")

# ------------------------------------------------------------------------------
# SURVEY DESIGN OBJECT
# ------------------------------------------------------------------------------
# ids: clustering at PSU level (primary sampling unit)
# weights: probability weights (WT_ind) from IHDS-II design
model_data$unique_psu <- paste(model_data$STATEID_ind, model_data$DISTID_ind, model_data$PSUID_ind, sep = "_")

cat("\nConstructing survey design object...\n")
svy_design <- svydesign(
  ids     = ~unique_psu,
  weights = ~WT_ind,
  data    = model_data
)
cat("✓ Survey design created\n")

# ------------------------------------------------------------------------------
# MAIN MODEL (Survey-weighted logistic regression)
# ------------------------------------------------------------------------------
cat("\nFitting main survey-weighted logistic regression...\n")
cat("Formula: employed ~ org_membership + education_years +\n")
cat("         social_group + female + age + age_sq + wealth_index +\n")
cat("         urban_resident + factor(STATEID_ind)\n\n")

model_employment <- tryCatch({
  svyglm(
    employed ~ org_membership  +
      education_years + social_group +
      female + age + age_sq +
      wealth_index + urban_resident +
      factor(STATEID_ind),
    design = svy_design,
    family = quasibinomial(link = "logit")
  )
}, error = function(e) {
  cat("ERROR in svyglm:", e$message, "\n")
  cat("Falling back to unweighted glm...\n")
  glm(
    employed ~ org_membership  +
      education_years + social_group +
      female + age + age_sq +
      wealth_index + urban_resident +
      factor(STATEID_ind),
    family = binomial(link = "logit"),
    data = model_data
  )
})

cat("✓ Model fitted\n")
cat("• AIC:", round(AIC(model_employment), 1), "\n")

# Save model
saveRDS(model_employment, "output/models/model_employment_main.rds")
# Save model data for use by downstream scripts
saveRDS(model_data, "output/models/model_data.rds")
saveRDS(svy_design, "output/models/svy_design.rds")
cat("✓ Model, model data, and survey design saved\n")

# ------------------------------------------------------------------------------
# EXTRACT AND SAVE COEFFICIENT SUMMARY
# ------------------------------------------------------------------------------
cat("\nExtracting model summary...\n")

coef_summary <- summary(model_employment)$coefficients

model_summary <- data.frame(
  term       = rownames(coef_summary),
  estimate   = coef_summary[, 1],
  std.error  = coef_summary[, 2],
  statistic  = coef_summary[, 3],
  p.value    = coef_summary[, 4],
  stringsAsFactors = FALSE
)
model_summary$conf.low  <- model_summary$estimate - 1.96 * model_summary$std.error
model_summary$conf.high <- model_summary$estimate + 1.96 * model_summary$std.error
model_summary$sig <- sapply(model_summary$p.value, function(p) {
  if (p < 0.001) "***" else if (p < 0.01) "**" else if (p < 0.05) "*"
  else if (p < 0.1) "." else ""
})

write.csv(model_summary, "output/tables/model_employment_full_summary.csv",
          row.names = FALSE)

# Key variables only (exclude state FE dummies)
key_pattern <- "^(Intercept|org_membership||education_years|social_group|female|age|wealth_index|urban_resident)"
key_summary <- model_summary %>% filter(grepl(key_pattern, term))
write.csv(key_summary, "output/tables/model_employment_key_vars.csv",
          row.names = FALSE)

cat("\n--- KEY VARIABLES SUMMARY ---\n")
print(key_summary[, c("term", "estimate", "std.error", "p.value", "sig")],
      row.names = FALSE, digits = 4)

# ------------------------------------------------------------------------------
# ODDS RATIOS FOR KEY VARIABLES
# ------------------------------------------------------------------------------
cat("\n--- ODDS RATIO QUICK INTERPRETATION ---\n")

interpret_or <- function(coef_name, label) {
  if (coef_name %in% names(coef(model_employment))) {
    or <- exp(coef(model_employment)[coef_name])
    pct <- round(100 * (or - 1), 1)
    direction <- ifelse(pct > 0, "higher", "lower")
    cat(sprintf("• %-35s OR = %.3f  (%+.1f%% odds)\n", label, or, pct))
  }
}

interpret_or("org_membership",       "Organisation membership")
interpret_or("education_years",      "Education (per year)")
interpret_or("wealth_index",         "Wealth index")
interpret_or("urban_resident",       "Urban vs rural")
interpret_or("female",               "Female vs male")
interpret_or("social_groupMuslims",  "Muslim vs Brahmin")
interpret_or("social_groupDalits",   "Dalit vs Brahmin")
interpret_or("social_groupAdivasis", "Adivasi vs Brahmin")

# ------------------------------------------------------------------------------
# MODEL FIT
# ------------------------------------------------------------------------------
mcfadden_r2 <- 1 - (model_employment$deviance / model_employment$null.deviance)

aic_val <- tryCatch(round(as.numeric(AIC(model_employment)["AIC"]), 1), error = function(e) NA_real_)
if (is.na(aic_val)) aic_val <- tryCatch(round(as.numeric(AIC(model_employment)[2]), 1), error = function(e) NA_real_)

fit_stats <- data.frame(
  Metric = c("N (model sample)", "Null Deviance", "Residual Deviance", "McFadden R²"),
  Value  = c(
    nrow(model_data),
    round(model_employment$null.deviance, 1),
    round(model_employment$deviance, 1),
    round(mcfadden_r2, 4)
  )
)
cat("\n--- MODEL FIT STATISTICS ---\n")
print(fit_stats, row.names = FALSE)
write.csv(fit_stats, "output/tables/model_fit_statistics.csv", row.names = FALSE)

cat("\n✓ Regression modeling complete\n")
