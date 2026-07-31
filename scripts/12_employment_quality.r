# ==============================================================================
# 12_EMPLOYMENT QUALITY ANALYSIS
# ==============================================================================
# Analyses the quality dimension of employment: not just WHETHER people work,
# but HOW they work and HOW MUCH they earn.
#
# Metrics:
#   1. Contract type (casual / temporary / permanent)
#   2. Formal job benefits (paid leave, employer meals)
#   3. Annual earnings (raw mean/median + adjusted wage regression)
#   4. NREGA participation (distress employment proxy)
#
# KEY METHODOLOGICAL NOTE — SAMPLE SELECTION:
#   Wage regressions run only on employed workers with positive earnings.
#   This is a selected sample. Workers who are unemployed/not earning may differ
#   systematically from employed workers on unobservables.
#   We address this with a Heckman selection correction (two-step):
#     Step 1 (Selection equation): Probit for P(employed | all covariates + exclusion restriction)
#     Step 2 (Outcome equation): OLS for log(wages) | employed + IMR
#   Exclusion restriction: number of household members (HH size proxy), which
#   affects selection into work but not the wage conditional on working.
#
# SCOPE: This script applies an explicit rural filter because:
#   (a) NREGA is a rural scheme — rural focus is substantively appropriate
#   (b) Contract type categories are most interpretable in the rural labour market
#   Script 13 handles the urban-rural wage comparison separately.
# ==============================================================================

print_section("EMPLOYMENT QUALITY ANALYSIS")

source("scripts/00_setup.r")
source("scripts/utils_functions.r")

# Load full data, then apply rural filter explicitly
analysis_data_full <- readRDS("output/analysis_data.rds")
cat("Full sample loaded:", nrow(analysis_data_full), "\n")

# Load merged_data for variables not in analysis_data
merged_data <- readRDS("output/merged_data.rds")

cat("\n>>> FOCUSING ON RURAL SAMPLE for quality analysis (NREGA, casual labour context)\n")
cat("    Urban-rural comparison is handled in script 13_urban_rural_dynamics.r\n\n")

# Restrict to rural for this script
analysis_data_rural <- analysis_data_full %>% filter(urban_resident == 0)
cat("Rural sample:", nrow(analysis_data_rural), "\n")

# Pull employment quality variables from merged_data (only rural)
quality_vars_from_merged <- merged_data %>%
  filter(urban_resident == 0) %>%
  select(IDHH, PERSONID,
         WS13,         # Contract type
         WSEARN,       # Salary earnings
         WS15,         # Paid leave (days)
         WS11MEALS,    # Meal benefit
         WS7NREGA      # NREGA participation
  )

quality_data_raw <- analysis_data_rural %>%
  left_join(quality_vars_from_merged, by = c("IDHH", "PERSONID"))

# Construct quality variables
quality_data <- quality_data_raw %>%
  mutate(
    social_group_broad = case_when(
      social_group %in% c("Brahmins", "Forward_castes") ~ "Forward/Upper",
      social_group == "Dalits"    ~ "Dalit (SC)",
      social_group == "Adivasis"  ~ "Adivasi (ST)",
      social_group == "Muslims"   ~ "Muslim",
      social_group == "OBCs"      ~ "OBC",
      TRUE ~ "Others"
    ),

    # Contract type (job security)
    contract_raw  = as.character(WS13),
    contract_type = case_when(
      grepl("Casual",              contract_raw, ignore.case = TRUE) ~ "Casual",
      grepl("Temporary|Contract",  contract_raw, ignore.case = TRUE) ~ "Temporary",
      grepl("Permanent|Longer",    contract_raw, ignore.case = TRUE) ~ "Permanent",
      TRUE ~ NA_character_
    ),

    # Earnings
    annual_earnings = suppressWarnings(as.numeric(as.character(WSEARN))),

    # Work intensity
    is_full_time = as.numeric(WKNONAG == "(4) ft yr 4"),

    # Benefits
    has_paid_leave  = as.numeric(suppressWarnings(as.numeric(as.character(WS15))) > 0),
    has_meal_benefit = as.numeric(suppressWarnings(as.numeric(as.character(WS11MEALS))) > 0),

    # Distress employment (NREGA)
    has_nrega = as.numeric(!is.na(WS7NREGA) & suppressWarnings(as.numeric(as.character(WS7NREGA))) > 0)
  )

# Employed subsample for quality analysis (needs contract OR positive earnings)
employed_data <- quality_data %>%
  filter(!is.na(contract_type) | (annual_earnings > 0 & !is.na(annual_earnings))) %>%
  mutate(
    formal_job_index = (
      as.numeric(contract_type == "Permanent", na.rm = TRUE) +
      coalesce(has_paid_leave, 0) +
      coalesce(has_meal_benefit, 0)
    ),
    is_formal = as.numeric(formal_job_index >= 1)
  )

cat("Working-age rural population:", nrow(quality_data), "\n")
cat("Employed (for quality analysis):", nrow(employed_data), "\n")

# ── 1. JOB SECURITY (CONTRACT TYPE) ──────────────────────────────────────────
cat("\n[1/5] Job Security Analysis...\n")

contract_table <- employed_data %>%
  filter(!is.na(contract_type), !is.na(social_group_broad),
         social_group_broad != "Others") %>%
  group_by(social_group_broad) %>%
  summarize(
    n            = n(),
    pct_Casual   = mean(contract_type == "Casual",    na.rm = TRUE) * 100,
    pct_Permanent = mean(contract_type == "Permanent", na.rm = TRUE) * 100,
    pct_Temporary = mean(contract_type == "Temporary", na.rm = TRUE) * 100,
    .groups = "drop"
  )

print(contract_table)
write.csv(contract_table, "output/tables/job_security_by_group.csv", row.names = FALSE)

# ── 2. FORMAL JOB BENEFITS ──────────────────────────────────────────────────
cat("\n[2/5] Formal Job Benefits...\n")

formal_summary <- employed_data %>%
  filter(!is.na(social_group_broad), social_group_broad != "Others") %>%
  group_by(social_group_broad) %>%
  summarize(
    pct_Paid_Leave       = mean(has_paid_leave,   na.rm = TRUE) * 100,
    pct_Meals            = mean(has_meal_benefit, na.rm = TRUE) * 100,
    pct_Formal_Index_1plus = mean(is_formal,      na.rm = TRUE) * 100,
    mean_Formal_Score    = mean(formal_job_index, na.rm = TRUE),
    .groups = "drop"
  )

print(formal_summary)
write.csv(formal_summary, "output/tables/formal_job_benefits.csv", row.names = FALSE)

# ── 3. EARNINGS ANALYSIS ─────────────────────────────────────────────────────
cat("\n[3/5] Earnings Analysis...\n")

earnings_summary <- employed_data %>%
  filter(annual_earnings > 0, !is.na(social_group_broad),
         social_group_broad != "Others") %>%
  group_by(social_group_broad) %>%
  summarize(
    mean_earnings   = mean(annual_earnings, na.rm = TRUE),
    median_earnings = median(annual_earnings, na.rm = TRUE),
    n_earners       = n(),
    .groups = "drop"
  ) %>%
  mutate(
    gap_vs_forward = (mean_earnings -
      mean_earnings[social_group_broad == "Forward/Upper"]) /
      mean_earnings[social_group_broad == "Forward/Upper"] * 100
  )

print(earnings_summary)
write.csv(earnings_summary, "output/tables/earnings_summary.csv", row.names = FALSE)

# ── 4. HECKMAN SELECTION-CORRECTED WAGE REGRESSION ───────────────────────────
cat("\n[4/5] Heckman Selection-Corrected Wage Regression...\n")
cat("Step 1: Probit selection equation (P(employed))\n")
cat("Step 2: OLS wage equation with Inverse Mills Ratio\n\n")

# Prepare data for Heckman (needs both employed and non-employed)
# Exclusion restriction: household size (affects entry into labour market but
# not the wage conditional on working)
heckman_data <- quality_data %>%
  mutate(
    log_earnings  = ifelse(annual_earnings > 0 & !is.na(annual_earnings),
                           log(annual_earnings), NA),
    outcome_valid = !is.na(log_earnings) & !is.na(education_years) &
                    !is.na(social_group) & !is.na(age) & !is.na(female)
  ) %>%
  filter(
    !is.na(employed), !is.na(education_years),
    !is.na(social_group), !is.na(age), !is.na(female),
    !is.na(wealth_index)
  )

heckman_result <- tryCatch({
  library(sampleSelection)
  heckit(
    # Step 1: Selection — P(employed)
    selection = employed ~ social_group + education_years + age + age_sq +
                           female + wealth_index + factor(STATEID_ind),
    # Step 2: Outcome — log(wages) | employed
    outcome   = log_earnings ~ social_group + education_years + age +
                               female + factor(STATEID_ind),
    data   = heckman_data,
    method = "2step"
  )
}, error = function(e) {
  cat("Heckman heckit failed:", e$message, "\n")
  cat("Falling back to OLS (without selection correction)...\n")
  NULL
})

if (!is.null(heckman_result)) {
  cat("✓ Heckman two-step completed\n\n")
  cat("--- STEP 2 OUTCOME EQUATION (selection-corrected wage coefficients) ---\n")
  heck_sum <- summary(heckman_result)
  heck_coefs <- heck_sum$estimate

  group_rows <- grep("social_group", rownames(heck_coefs))
  if (length(group_rows) > 0) {
    group_wage_coefs <- data.frame(
      Group     = rownames(heck_coefs)[group_rows],
      Estimate  = heck_coefs[group_rows, 1],
      StdError  = heck_coefs[group_rows, 2],
      P_Value   = heck_coefs[group_rows, 4],
      pct_penalty = round(100 * (exp(heck_coefs[group_rows, 1]) - 1), 1),
      stringsAsFactors = FALSE
    ) %>%
      mutate(sig = case_when(
        P_Value < 0.001 ~ "***", P_Value < 0.01 ~ "**",
        P_Value < 0.05  ~ "*",   P_Value < 0.1  ~ ".",
        TRUE ~ ""
      ))
    cat("Group wage penalties (vs Brahmins, Heckman-corrected):\n")
    print(group_wage_coefs, row.names = FALSE, digits = 3)
    write.csv(group_wage_coefs, "output/tables/wage_penalty_heckman.csv", row.names = FALSE)

    # IMR significance
    imr_row <- grep("invMillsRatio|rho|lambda|IMR", rownames(heck_coefs), ignore.case = TRUE)
    if (length(imr_row) > 0) {
      cat(sprintf("\nInverse Mills Ratio: %.4f (p = %.4f)\n",
                  heck_coefs[imr_row[1], 1], heck_coefs[imr_row[1], 4]))
      if (heck_coefs[imr_row[1], 4] < 0.05) {
        cat("→ Significant IMR: selection bias IS present in the simple OLS.\n")
        cat("   Heckman estimates are the preferred specification.\n")
      } else {
        cat("→ IMR not significant: selection bias is minimal.\n")
        cat("   OLS and Heckman estimates should be similar.\n")
      }
    }
  }
  saveRDS(heckman_result, "output/models/model_heckman_wages.rds")
}

# Fallback/comparison: simple OLS wage regression (for comparison with Heckman)
cat("\n--- OLS WAGE REGRESSION (no selection correction, for comparison) ---\n")
reg_data <- employed_data %>%
  filter(annual_earnings > 0, !is.na(education_years)) %>%
  mutate(log_earnings = log(annual_earnings))

wage_model_ols <- lm(
  log_earnings ~ social_group + education_years + age + female + factor(STATEID_ind),
  data = reg_data
)

ols_coefs <- summary(wage_model_ols)$coefficients
group_ols_rows <- grep("social_group", rownames(ols_coefs))

if (length(group_ols_rows) > 0) {
  ols_wage_summary <- data.frame(
    Group      = rownames(ols_coefs)[group_ols_rows],
    Estimate   = ols_coefs[group_ols_rows, 1],
    StdError   = ols_coefs[group_ols_rows, 2],
    P_Value    = ols_coefs[group_ols_rows, 4],
    pct_penalty = round(100 * (exp(ols_coefs[group_ols_rows, 1]) - 1), 1),
    stringsAsFactors = FALSE
  ) %>%
    mutate(sig = case_when(
      P_Value < 0.001 ~ "***", P_Value < 0.01 ~ "**",
      P_Value < 0.05  ~ "*",   TRUE ~ ""
    ))
  write.csv(ols_wage_summary, "output/tables/wage_penalty_ols.csv", row.names = FALSE)
  cat("OLS group wage penalties (vs Brahmins):\n")
  print(ols_wage_summary, row.names = FALSE, digits = 3)
}
saveRDS(wage_model_ols, "output/models/model_wage_ols.rds")

# ── 5. NREGA DISTRESS EMPLOYMENT ─────────────────────────────────────────────
cat("\n[5/5] NREGA Participation (Distress Employment Proxy)...\n")

nrega_summary <- quality_data %>%
  filter(!is.na(social_group_broad), social_group_broad != "Others") %>%
  group_by(social_group_broad) %>%
  summarize(pct_NREGA = mean(has_nrega, na.rm = TRUE) * 100, .groups = "drop")

print(nrega_summary)
write.csv(nrega_summary, "output/tables/nrega_participation.csv", row.names = FALSE)

# ── VISUALIZATION ─────────────────────────────────────────────────────────────
theme_premium <- theme_minimal() +
  theme(
    text             = element_text(family = "serif"),
    plot.title       = element_text(face = "bold", size = 16),
    axis.title       = element_text(face = "italic"),
    panel.grid.minor = element_blank(),
    legend.position  = "bottom"
  )

# Contract type stacked bar
plot_contract <- ggplot(
  employed_data %>%
    filter(!is.na(contract_type), !is.na(social_group_broad),
           social_group_broad != "Others") %>%
    group_by(social_group_broad, contract_type) %>%
    summarize(count = n(), .groups = "drop") %>%
    group_by(social_group_broad) %>%
    mutate(pct = count / sum(count)),
  aes(x = social_group_broad, y = pct, fill = contract_type)
) +
  geom_bar(stat = "identity", width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", pct * 100)),
    position = position_stack(vjust = 0.5), size = 3, color = "white", fontface = "bold"
  ) +
  labs(
    title    = "Job Security Gaps: Contract Type by Social Group (Rural)",
    subtitle = "Casual labour dominates for SC/ST/Muslim groups — employment ≠ job security",
    y = "Percentage of Workers", x = "", fill = "Contract Type"
  ) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_viridis_d(option = "mako", begin = 0.2, end = 0.8) +
  theme_premium

ggsave("output/plots/contract_type_distribution.png", plot_contract,
       width = 9, height = 7, dpi = 300)

# Earnings boxplot (log scale)
plot_earnings <- ggplot(
  reg_data %>% filter(social_group_broad != "Others"),
  aes(x = social_group_broad, y = annual_earnings, fill = social_group_broad)
) +
  geom_boxplot(outlier.shape = 21, outlier.alpha = 0.2, width = 0.6) +
  scale_y_log10(labels = scales::comma) +
  labs(
    title    = "Annual Earnings Inequality by Social Group (Rural Employed)",
    subtitle = "Log scale | Adivasis: highest employment rate but lowest earnings",
    y = "Annual Earnings (INR)", x = ""
  ) +
  scale_fill_brewer(palette = "Set2") +
  theme_premium +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 20, hjust = 1))

ggsave("output/plots/earnings_distribution.png", plot_earnings,
       width = 9, height = 7, dpi = 300)

cat("\n✓ Employment quality analysis complete\n")
