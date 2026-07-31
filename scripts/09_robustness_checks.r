# ==============================================================================
# 09_ROBUSTNESS CHECKS & SENSITIVITY ANALYSIS
# ==============================================================================
# Validates core results across 5 model specifications:
#
#   Model 1 (Baseline): Main model — svyglm with state FE (replicated from 04)
#   Model 2 (District FE): Linear Probability Model with district fixed effects
#              LPM used because logit with many district dummies is biased (incidental
#              parameters problem). This is the individual-level test for whether
#              group penalties persist *within the same district*.
#   Model 3 (Clustered SE): State-FE logit with SEs clustered at PSU (sandwich)
#   Model 4 (Exogenous only): Drops wealth and social capital (potential endogeneity)
#   Model 5 (Survey-weighted District FE): svyglm with district FE as the
#              individual-level geographic trap test — key new addition.
#
# GEOGRAPHIC TRAP TEST (central methodological contribution):
#   Comparing group coefficients between Model 1 (state FE) and Model 2/5
#   (district FE) reveals whether group penalties are geographic or identity-based.
#   If a penalty shrinks under district FE → geographic concentration drives it.
#   If a penalty persists under district FE → it is an identity-level barrier.
# ==============================================================================

print_section("ROBUSTNESS CHECKS")

source("scripts/00_setup.r")
source("scripts/utils_functions.r")

analysis_data <- readRDS("output/analysis_data.rds")
cat("Analysis dataset loaded. Rows:", nrow(analysis_data), "\n")

# ------------------------------------------------------------------------------
# PREPARE UNIFIED MODEL DATA
# ------------------------------------------------------------------------------
model_vars <- c(
  "employed", "org_membership",  "education_years",
  "social_group", "female", "age", "age_sq", "wealth_index",
  "urban_resident", "STATEID_ind", "DISTID_ind", "PSUID_ind", "WT_ind"
)

model_data_robust <- analysis_data %>%
  filter(complete.cases(pick(all_of(model_vars)))) %>%
  mutate(unique_psu = paste(STATEID_ind, DISTID_ind, PSUID_ind, sep = "_"))

cat("Sample size for robustness models:", nrow(model_data_robust), "\n")
cat("Districts:", length(unique(model_data_robust$DISTID_ind)), "\n")

# Survey design for weighted models
svy_design_robust <- svydesign(
  ids = ~unique_psu,
  weights = ~WT_ind,
  data    = model_data_robust
)

# ------------------------------------------------------------------------------
# MODEL 1: Baseline (replicates main model from 04 for reference)
# ------------------------------------------------------------------------------
cat("\n[1/5] Model 1: Baseline — svyglm + State FE...\n")
m1_state_fe <- svyglm(
  employed ~ org_membership + education_years +
    social_group + female + age + age_sq + wealth_index +
    urban_resident + factor(STATEID_ind),
  design = svy_design_robust,
  family = quasibinomial(link = "logit")
)
cat("  ✓ Converged. AIC:", round(AIC(m1_state_fe), 1), "\n")

# ------------------------------------------------------------------------------
# MODEL 2: District Fixed Effects (LPM)
# Note: We use OLS (LPM) not logit here because logit with 300+ district dummies
# suffers from the incidental parameters problem — coefficients are inconsistent.
# LPM gives unbiased coefficients; SEs are clustered at PSU level for validity.
# ------------------------------------------------------------------------------
cat("\n[2/5] Model 2: District FE — LPM (clustered at PSU)...\n")
m2_district_fe <- lm(
  employed ~ org_membership + education_years +
    social_group + female + age + age_sq + wealth_index +
    urban_resident + factor(DISTID_ind),
  data = model_data_robust
)
# Clustered standard errors at PSU level
vcov_cluster_m2 <- vcovCL(m2_district_fe, cluster = model_data_robust$unique_psu)
m2_coeftest     <- coeftest(m2_district_fe, vcov = vcov_cluster_m2)
cat("  ✓ LPM with district FE + clustered SEs fitted\n")
cat("  District dummies absorbed:", length(unique(model_data_robust$DISTID_ind)), "\n")

# ------------------------------------------------------------------------------
# MODEL 3: Clustered SE (state FE logit, PSU-clustered, no survey weighting)
# This gives the "naive" clustered SE result for comparison
# ------------------------------------------------------------------------------
cat("\n[3/5] Model 3: State FE + Clustered SE (unweighted logit)...\n")
m3_base_glm <- glm(
  employed ~ org_membership + education_years +
    social_group + female + age + age_sq + wealth_index +
    urban_resident + factor(STATEID_ind),
  family = binomial(link = "logit"),
  data = model_data_robust
)
vcov_cluster_m3 <- vcovCL(m3_base_glm, cluster = model_data_robust$unique_psu)
m3_coeftest     <- coeftest(m3_base_glm, vcov = vcov_cluster_m3)
cat("  ✓ Fitted\n")

# ------------------------------------------------------------------------------
# MODEL 4: Exogenous-only (removes wealth and social capital to test for
# potential endogeneity — are group penalties robust even without these controls?)
# ------------------------------------------------------------------------------
cat("\n[4/5] Model 4: Exogenous Controls Only (no wealth, no social capital)...\n")
m4_exogenous <- svyglm(
  employed ~ education_years + social_group +
    female + age + age_sq + urban_resident +
    factor(STATEID_ind),
  design = svy_design_robust,
  family = quasibinomial(link = "logit")
)
cat("  ✓ Fitted\n")

# ------------------------------------------------------------------------------
# MODEL 5: Survey-weighted District FE (THE GEOGRAPHIC TRAP TEST)
# Uses svyglm with district FE — combines the rigour of survey weighting
# with within-district identification for the geographic trap hypothesis.
# This is the most demanding test for group-level penalties.
# ------------------------------------------------------------------------------
cat("\n[5/5] Model 5: svyglm + District FE (Geographic Trap Test)...\n")
cat("  Note: This model has", length(unique(model_data_robust$DISTID_ind)),
    "district dummies — may be slow\n")

m5_geo_trap <- tryCatch({
  svyglm(
    employed ~ org_membership + education_years +
      social_group + female + age + age_sq + wealth_index +
      urban_resident + factor(DISTID_ind),
    design = svy_design_robust,
    family = quasibinomial(link = "logit")
  )
}, error = function(e) {
  cat("  svyglm with district FE failed (memory/convergence):", e$message, "\n")
  cat("  Using LPM District FE as fallback (same as Model 2)\n")
  NULL
})

if (!is.null(m5_geo_trap)) {
  cat("  ✓ Weighted district FE model fitted\n")
} else {
  cat("  → Using Model 2 (LPM district FE) as the geographic trap test\n")
  m5_geo_trap <- m2_district_fe
}

# ------------------------------------------------------------------------------
# EXTRACT AND COMPARE RESULTS
# Helper: extract coefficient for a variable from different model types
# ------------------------------------------------------------------------------
get_coef_row <- function(model_obj, var_pattern, model_name,
                         is_coeftest = FALSE, is_lm = FALSE) {
  if (is_coeftest) {
    coefs <- model_obj
    idx   <- grep(var_pattern, rownames(coefs))
    if (length(idx) == 0) return(NULL)
    est <- coefs[idx[1], "Estimate"]
    se  <- coefs[idx[1], "Std. Error"]
    p   <- coefs[idx[1], ncol(coefs)]
  } else {
    coefs <- summary(model_obj)$coefficients
    idx   <- grep(var_pattern, rownames(coefs))
    if (length(idx) == 0) return(NULL)
    est <- coefs[idx[1], 1]
    se  <- coefs[idx[1], 2]
    p   <- coefs[idx[1], ncol(coefs)]
  }
  data.frame(
    Model     = model_name,
    Variable  = var_pattern,
    Estimate  = est,
    StdError  = se,
    P_Value   = p,
    Conf_Low  = est - 1.96 * se,
    Conf_High = est + 1.96 * se,
    Sig = case_when(
      p < 0.001 ~ "***", p < 0.01 ~ "**",
      p < 0.05  ~ "*",   p < 0.1  ~ ".",
      TRUE ~ ""
    ),
    stringsAsFactors = FALSE
  )
}

# ── KEY VARIABLES TO COMPARE ACROSS MODELS ─────────────────────────────────
vars_of_interest <- c(
  "social_groupMuslims", "social_groupDalits", "social_groupAdivasis",
  "org_membership",  "education_years"
)

robustness_table <- bind_rows(lapply(vars_of_interest, function(v) {
  bind_rows(
    get_coef_row(m1_state_fe,  v, "M1: State FE (svyglm)"),
    get_coef_row(m2_coeftest,  v, "M2: District FE (LPM, clustered)", is_coeftest = TRUE),
    get_coef_row(m3_coeftest,  v, "M3: State FE (glm, clustered)",    is_coeftest = TRUE),
    get_coef_row(m4_exogenous, v, "M4: Exogenous Only"),
    if (!inherits(m5_geo_trap, "lm")) get_coef_row(m5_geo_trap, v, "M5: District FE (svyglm)") else NULL
  )
}))

cat("\n--- ROBUSTNESS COMPARISON TABLE ---\n")
print(robustness_table %>% mutate(across(where(is.numeric), ~round(., 4))),
      row.names = FALSE)

write.csv(robustness_table, "output/tables/robustness_comparison.csv", row.names = FALSE)

# ── GEOGRAPHIC TRAP NARRATIVE ─────────────────────────────────────────────────
print_section("GEOGRAPHIC TRAP INTERPRETATION")

cat("\nKEY FINDING: Comparing State FE vs District FE coefficients for each group:\n\n")
cat("Method: If |Estimate| shrinks substantially from State FE → District FE,\n")
cat("        the penalty is driven by WHERE the group lives (geographic trap).\n")
cat("        If it persists, the penalty is an identity-level barrier.\n\n")

for (g in c("social_groupMuslims", "social_groupDalits", "social_groupAdivasis")) {
  m1_row <- robustness_table %>% filter(Model == "M1: State FE (svyglm)", Variable == g)
  m2_row <- robustness_table %>% filter(grepl("District FE", Model), Variable == g) %>% head(1)

  if (nrow(m1_row) > 0 && nrow(m2_row) > 0) {
    shrinkage <- 1 - abs(m2_row$Estimate) / abs(m1_row$Estimate)
    group_name <- gsub("social_group", "", g)
    cat(sprintf(
      "%s: State FE coef = %.3f | District FE coef = %.3f | Shrinkage = %.1f%%\n",
      group_name, m1_row$Estimate, m2_row$Estimate, 100 * shrinkage
    ))
    if (shrinkage > 0.4) {
      cat(sprintf("  → GEOGRAPHIC TRAP confirmed: penalty shrinks %.0f%% under district FE\n\n",
                  100 * shrinkage))
    } else if (shrinkage < 0.1) {
      cat("  → IDENTITY BARRIER confirmed: penalty largely persists within districts\n\n")
    } else {
      cat(sprintf("  → MIXED: %.0f%% of penalty explained by district context\n\n",
                  100 * shrinkage))
    }
  }
}

# Save models
saveRDS(m1_state_fe,   "output/models/model_robustness_m1.rds")
saveRDS(m2_district_fe, "output/models/model_robustness_m2_lpm.rds")

cat("\n✓ Robustness checks complete. See output/tables/robustness_comparison.csv\n")
