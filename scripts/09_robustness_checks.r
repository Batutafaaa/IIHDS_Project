# ==============================================================================
# ROBUSTNESS CHECKS & SENSITIVITY ANALYSIS
# ==============================================================================

# Source setup but suppress output
source("scripts/00_setup.r")
print_section("ROBUSTNESS CHECKS INITIALIZED")

# Install specific packages for robustness if needed
if (!require("sandwich")) install.packages("sandwich")
if (!require("lmtest")) install.packages("lmtest")
library(sandwich)
library(lmtest)

# Load pre-prepared full analysis data
analysis_data_full <- readRDS("output/analysis_data_full.rds")
cat("Analysis dataset loaded. Rows:", nrow(analysis_data_full), "\n")

# ==============================================================================
# 3. MODEL SPECIFICATIONS
# ==============================================================================
cat("\n[3/5] Running Robustness Models...\n")

# Define clean model data
model_vars <- c(
    "employed", "org_membership", "education_years", "social_group",
    "female", "age", "age_sq", "wealth_index", "urban_resident", "district_id"
)

model_data_robust <- analysis_data_full %>%
    filter(complete.cases(pick(all_of(model_vars))))

cat("Sample size for robustness models:", nrow(model_data_robust), "\n")

# --- Model 1: Full Sample with Urban Control (Logit) ---
cat("   Running Model 1: Full Sample + Urban Control...\n")
m1_urban <- glm(
    employed ~ org_membership + education_years + social_group +
        female + age + age_sq + wealth_index + urban_resident + factor(STATEID_ind),
    family = binomial(link = "logit"),
    data = model_data_robust
)

# --- Model 2: District Fixed Effects (Linear Probability Model) ---
# Using LPM (lm) because Logit with many fixed effects (districts) is biased/slow
cat("   Running Model 2: District Fixed Effects (LPM)...\n")
m2_district_fe <- lm(
    employed ~ org_membership + education_years + social_group +
        female + age + age_sq + wealth_index + urban_resident + factor(district_id),
    data = model_data_robust
)

# --- Model 3: Clustered Standard Errors (Logit) ---
# Re-run Main Model (Rural Only) but with Clustering
# We filter to rural for strict comparison with original, or use full?
# Let's use FULL sample for consistency with M1, but cluster by PSU
cat("   Running Model 3: Clustered Standard Errors (Cluster = PSU)...\n")
# We use m1_urban model object but adjust SEs
vcov_cluster <- vcovCL(m1_urban, cluster = model_data_robust$PSUID_ind)
m3_clustered_test <- coeftest(m1_urban, vcov = vcov_cluster)

# --- Model 4: Exogenous Only (No Wealth, No Org) ---
cat("   Running Model 4: Exogenous Controls Only...\n")
m4_exogenous <- glm(
    employed ~ education_years + social_group +
        female + age + age_sq + urban_resident + factor(STATEID_ind),
    family = binomial(link = "logit"),
    data = model_data_robust
)

# ==============================================================================
# 4. EXTRACT COMPARISON RESULTS
# ==============================================================================
cat("\n[4/5] Compiling Results...\n")

# Helper to extract Muslim coefficient and SE
get_muslim_stats <- function(model_obj, model_name, is_coeftest = FALSE) {
    if (is_coeftest) {
        coefs <- model_obj
        idx <- grep("social_groupMuslims", rownames(coefs))
        est <- coefs[idx, "Estimate"]
        se <- coefs[idx, "Std. Error"]
        p <- coefs[idx, "Pr(>|z|)"]
    } else {
        coefs <- summary(model_obj)$coefficients
        idx <- grep("social_groupMuslims", rownames(coefs))
        est <- coefs[idx, "Estimate"]
        se <- coefs[idx, "Std. Error"]
        # Handle different column names for lm vs glm
        p <- if ("Pr(>|z|)" %in% colnames(coefs)) coefs[idx, "Pr(>|z|)"] else coefs[idx, "Pr(>|t|)"]
    }

    return(data.frame(
        Model = model_name,
        Estimate = est,
        StdError = se,
        P_Value = p
    ))
}

results_table <- rbind(
    get_muslim_stats(m1_urban, "1. Full Sample (Urban Ctrl)"),
    get_muslim_stats(m2_district_fe, "2. District Fixed Effects (LPM)"),
    get_muslim_stats(m3_clustered_test, "3. Clustered SEs (PSU)", is_coeftest = TRUE),
    get_muslim_stats(m4_exogenous, "4. Exogenous Only")
)

results_table <- results_table %>%
    mutate(
        Significance = case_when(
            P_Value < 0.001 ~ "***",
            P_Value < 0.01 ~ "**",
            P_Value < 0.05 ~ "*",
            TRUE ~ ""
        ),
        Conf_Low = Estimate - 1.96 * StdError,
        Conf_High = Estimate + 1.96 * StdError
    )

print(results_table)
write.csv(results_table, "output/tables/robustness_comparison.csv", row.names = FALSE)

# ==============================================================================
# 5. FULL SAMPLE MARGINAL EFFECTS (Correcting the sampling issue)
# ==============================================================================
cat("\n[5/5] Calculating Full-Sample Marginal Effects...\n")

# We will calculate AME for Muslim status in Model 1 (Full Sample)
# Using the manual method (predicting counterfactuals) for speed on large N

coef_muslim <- coef(m1_urban)["social_groupMuslims"]
pred_prob <- predict(m1_urban, type = "response")
# AME Approximation: Coef * Average Density
# Or better: Exact Average Partial Effect
# Construct counterfactuals
data_muslim <- model_data_robust
data_muslim$social_group <- "Muslims"

data_brahmin <- model_data_robust
data_brahmin$social_group <- "Brahmins"

# Predict in chunks to avoid memory issues if needed, but 200k is fine for modern R
cat("   Predicting counterfactuals (N =", nrow(model_data_robust), ")...\n")
pred_muslim <- predict(m1_urban, newdata = data_muslim, type = "response")
pred_brahmin <- predict(m1_urban, newdata = data_brahmin, type = "response")

ame_muslim <- mean(pred_muslim - pred_brahmin, na.rm = TRUE)
cat("\n>>> ROBUST MUSLIM DISADVANTAGE (Full Sample) <<<\n")
cat(
    "AME (Muslim vs Brahmin):", round(ame_muslim, 4),
    "(", round(ame_muslim * 100, 2), "pp )\n"
)

# Save detailed objects
saveRDS(results_table, "output/tables/robustness_results.rds")
saveRDS(m1_urban, "output/models/model_full_sample.rds")

cat("\n✓ Robustness checks complete. See output/tables/robustness_comparison.csv\n")
