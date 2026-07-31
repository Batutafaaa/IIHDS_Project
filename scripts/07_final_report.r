# ==============================================================================
# 07_FINAL REPORT — Comprehensive Research Findings Summary
# ==============================================================================
# Assembles all outputs from scripts 03–13 into a single narrative summary.
# Reads from saved CSV/RDS files rather than relying on environment objects,
# so it can be run independently.
# ==============================================================================

print_section("COMPREHENSIVE RESEARCH FINDINGS SUMMARY")

# ── LOAD ALL OUTPUTS ──────────────────────────────────────────────────────────
wealth_by_group     <- read.csv("output/tables/wealth_by_group.csv")
group_comparison    <- read.csv("output/tables/group_comparison_detailed.csv")
ame_results         <- read.csv("output/tables/marginal_effects.csv")
group_ame_results   <- tryCatch(read.csv("output/tables/group_marginal_effects.csv"), error = function(e) NULL)
group_org_ames      <- tryCatch(read.csv("output/tables/group_social_capital_ames.csv"), error = function(e) NULL)
robustness_table    <- tryCatch(read.csv("output/tables/robustness_comparison.csv"), error = function(e) NULL)
ur_descriptive      <- tryCatch(read.csv("output/tables/urban_rural_group_descriptives.csv"), error = function(e) NULL)
ur_gap              <- tryCatch(read.csv("output/tables/urban_rural_employment_gap.csv"), error = function(e) NULL)
interaction_org     <- tryCatch(read.csv("output/tables/interaction_org_x_group.csv"), error = function(e) NULL)
earnings_summary    <- tryCatch(read.csv("output/tables/earnings_summary.csv"), error = function(e) NULL)
nrega_summary       <- tryCatch(read.csv("output/tables/nrega_participation.csv"), error = function(e) NULL)
heckman_wages       <- tryCatch(read.csv("output/tables/wage_penalty_heckman.csv"), error = function(e) NULL)
ols_wages           <- tryCatch(read.csv("output/tables/wage_penalty_ols.csv"), error = function(e) NULL)
fit_stats           <- tryCatch(read.csv("output/tables/model_fit_statistics.csv"), error = function(e) NULL)
muslim_edu_emp      <- tryCatch(read.csv("output/tables/muslim_education_employment.csv"), error = function(e) NULL)
muslim_gender_gap   <- tryCatch(read.csv("output/tables/muslim_gender_gap.csv"), error = function(e) NULL)

cat(">>> ANALYSIS SCOPE: Full India (Urban + Rural) — N =",
    format(sum(group_comparison$n), big.mark = ","), "individuals <<<\n\n")

# ── 1. WEALTH-EMPLOYMENT PARADOX ─────────────────────────────────────────────
wealth_emp_cor <- cor(wealth_by_group$mean_wealth, wealth_by_group$employment_rate,
                      use = "complete.obs")
cat("1. WEALTH-EMPLOYMENT PARADOX:\n")
cat("   • Correlation (wealth vs employment rate, group-level):",
    round(wealth_emp_cor, 3), "\n")
wealth_ame <- ame_results$AME_pp[ame_results$Variable == "Wealth Index"]
if (length(wealth_ame) > 0)
  cat("   • Marginal effect of wealth:", round(wealth_ame, 2), "pp per unit\n")
cat("   • Implication: Employment ≠ prosperity in rural India;\n")
cat("     high rates among poorest groups reflect distress labour\n\n")

# ── 2. SOCIAL CAPITAL ────────────────────────────────────────────────────────
cat("2. SOCIAL CAPITAL EFFECTS:\n")
org_ame <- ame_results$AME_pp[ame_results$Variable == "Organisation Membership"]
trust_ame <- ame_results$AME_pp[ame_results$Variable == "General Trust"]
org_sig <- ame_results$sig[ame_results$Variable == "Organisation Membership"]
trust_sig <- ame_results$sig[ame_results$Variable == "General Trust"]

if (length(org_ame) > 0)
  cat(sprintf("   • Org membership: %+.2f pp %s\n", org_ame,
              ifelse(length(org_sig) > 0, org_sig, "")))
if (length(trust_ame) > 0)
  cat(sprintf("   • General trust:  %+.2f pp %s\n", trust_ame,
              ifelse(length(trust_sig) > 0, trust_sig, "")))

org_rate <- round(100 * wealth_by_group$org_membership_rate, 1)
cat("   • Org membership rates by group (lowest to highest):\n")
for (i in seq_len(nrow(wealth_by_group))) {
  cat(sprintf("     - %-20s %.1f%%\n",
              wealth_by_group$social_group[i],
              wealth_by_group$org_membership_rate[i] * 100))
}

if (!is.null(group_org_ames)) {
  cat("\n   • Group-differentiated social capital returns (org_membership AME):\n")
  for (i in seq_len(nrow(group_org_ames))) {
    cat(sprintf("     %-40s %+.2f pp %s\n",
                group_org_ames$Variable[i],
                group_org_ames$AME_pp[i],
                group_org_ames$sig[i]))
  }
}
cat("\n")

# ── 3. HUMAN CAPITAL ─────────────────────────────────────────────────────────
cat("3. HUMAN CAPITAL (EDUCATION):\n")
edu_ame <- ame_results$AME_pp[ame_results$Variable == "Education (per year)"]
edu_sig <- ame_results$sig[ame_results$Variable == "Education (per year)"]
if (length(edu_ame) > 0)
  cat(sprintf("   • Each additional year: %+.2f pp %s\n", edu_ame,
              ifelse(length(edu_sig) > 0, edu_sig, "")))
cat("   • Education by group:\n")
for (i in order(group_comparison$mean_education, decreasing = TRUE)) {
  cat(sprintf("     %-20s %.1f years\n",
              group_comparison$social_group[i],
              group_comparison$mean_education[i]))
}
cat("\n")

# ── 4. URBAN-RURAL DYNAMICS ──────────────────────────────────────────────────
cat("4. WITHIN-STATE URBAN-RURAL DYNAMICS:\n")
if (!is.null(ur_gap)) {
  cat("   Urban-rural employment gap by group (positive = urban advantage):\n")
  for (i in seq_len(nrow(ur_gap))) {
    if (!is.na(ur_gap$urban_rural_gap[i]))
      cat(sprintf("     %-20s %+.1f pp (%s)\n",
                  ur_gap$social_group[i],
                  ur_gap$urban_rural_gap[i],
                  ur_gap$direction[i]))
  }
} else {
  cat("   [Run script 13 to populate this section]\n")
}
cat("\n")

# ── 5. SOCIAL GROUP PENALTIES ─────────────────────────────────────────────────
cat("5. SOCIAL GROUP EMPLOYMENT PENALTIES (vs Brahmins):\n")
if (!is.null(group_ame_results)) {
  for (i in seq_len(nrow(group_ame_results))) {
    cat(sprintf("   %-35s %+.2f pp [%.2f, %.2f] %s\n",
                group_ame_results$Variable[i],
                group_ame_results$AME_pp[i],
                group_ame_results$CI_lower_pp[i],
                group_ame_results$CI_upper_pp[i],
                group_ame_results$sig[i]))
  }
}
cat("\n")

# ── 6. GEOGRAPHIC TRAP TEST (ROBUSTNESS) ─────────────────────────────────────
cat("6. GEOGRAPHIC TRAP TEST — State FE vs District FE:\n")
cat("   Method: penalty shrinkage from state FE → district FE reveals\n")
cat("           how much of the disadvantage is geographic vs identity-based\n")
if (!is.null(robustness_table)) {
  for (g in c("social_groupMuslims", "social_groupDalits", "social_groupAdivasis")) {
    m1 <- robustness_table[robustness_table$Variable == g &
                             grepl("State FE", robustness_table$Model), ]
    m2 <- robustness_table[robustness_table$Variable == g &
                             grepl("District FE", robustness_table$Model), ]
    if (nrow(m1) > 0 && nrow(m2) > 0) {
      shrink <- 1 - abs(m2$Estimate[1]) / abs(m1$Estimate[1])
      cat(sprintf("   %-12s State FE: %.3f | District FE: %.3f | Shrinkage: %.0f%%\n",
                  gsub("social_group", "", g),
                  m1$Estimate[1], m2$Estimate[1], 100 * shrink))
    }
  }
}
cat("\n")

# ── 7. EMPLOYMENT QUALITY ────────────────────────────────────────────────────
cat("7. EMPLOYMENT QUALITY (Rural):\n")
if (!is.null(earnings_summary)) {
  cat("   Annual earnings (mean) and gap vs Forward/Upper castes:\n")
  for (i in seq_len(nrow(earnings_summary))) {
    cat(sprintf("     %-20s ₹%s  (%+.1f%%)\n",
                earnings_summary$social_group_broad[i],
                format(round(earnings_summary$mean_earnings[i]), big.mark = ","),
                earnings_summary$gap_vs_forward[i]))
  }
}

wage_table <- if (!is.null(heckman_wages)) heckman_wages else ols_wages
wage_label <- if (!is.null(heckman_wages)) "Heckman-corrected" else "OLS (uncorrected)"
if (!is.null(wage_table)) {
  cat(sprintf("\n   Adjusted wage penalties (%s, vs Brahmins):\n", wage_label))
  for (i in seq_len(nrow(wage_table))) {
    cat(sprintf("     %-35s %+.1f%% %s\n",
                wage_table$Group[i],
                wage_table$pct_penalty[i],
                wage_table$sig[i]))
  }
}

if (!is.null(nrega_summary)) {
  cat("\n   NREGA participation (distress employment proxy):\n")
  for (i in seq_len(nrow(nrega_summary))) {
    cat(sprintf("     %-20s %.1f%%\n",
                nrega_summary$social_group_broad[i],
                nrega_summary$pct_NREGA[i]))
  }
}
cat("\n")

# ── 8. GENDER ────────────────────────────────────────────────────────────────
cat("8. GENDER:\n")
female_ame <- ame_results$AME_pp[ame_results$Variable == "Female (vs Male)"]
female_sig <- ame_results$sig[ame_results$Variable == "Female (vs Male)"]
if (length(female_ame) > 0)
  cat(sprintf("   • Female employment penalty: %+.1f pp %s\n", female_ame,
              ifelse(length(female_sig) > 0, female_sig, "")))

# ── 9. POLICY SUMMARY ────────────────────────────────────────────────────────
print_section("POLICY IMPLICATIONS SUMMARY")

cat("
GROUP-SPECIFIC POLICY LEVERS (based on differentiated mechanisms):

1. MUSLIMS — Geographic Trap + Educational Deficit
   • Place-based economic development in high-Muslim-concentration districts
   • Close the ~3.4-year education gap vs Brahmins through targeted infrastructure
   • General employment schemes deliver little without addressing geographic stagnation

2. ADIVASIS — Subsistence Mirage (high employment, lowest wages)
   • Formalise casual contracts — 85%+ in casual labour with no security
   • Enforce minimum agricultural wages and reform forest produce pricing
   • NREGA is a coping mechanism, not a solution; quality upgrades needed

3. DALITS — Distributed Barrier (identity penalty regardless of geography)
   • Anti-discrimination enforcement in private sector hiring
   • Wage penalty persists after controlling for education, age, location
   • District FE does NOT eliminate the penalty → requires identity-level intervention

4. SOCIAL CAPITAL (universal lever)
   • Org membership: +%.2f pp employment probability
   • Group-differentiated returns — scale organisations especially where returns are lowest
   • Only ~8-9%% of rural population in any organisation — massive untapped potential

5. GENDER (cross-cutting)
   • Female penalty: ~26 pp — one of the largest gender gaps in the literature
   • Gender-specific employment programmes needed, especially for Muslim women
",
    org_ame[1]
)

# Save summary
final_summary <- list(
  scope           = "Full India (Urban + Rural)",
  sample_size     = sum(group_comparison$n),
  wealth_emp_cor  = wealth_emp_cor,
  ame_results     = ame_results,
  group_ame       = group_ame_results,
  robustness      = robustness_table
)
saveRDS(final_summary, "output/final_comprehensive_summary.rds")
cat("\n✓ Summary saved to output/final_comprehensive_summary.rds\n")
cat(rep("=", 80), "\n", sep = "")
