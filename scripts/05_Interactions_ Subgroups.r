# ==============================================================================
# 05_INTERACTION EFFECTS & SUBGROUP ANALYSIS
# ==============================================================================
# Tests three interaction hypotheses:
#
#   1. org_membership × social_group:
#      Does social capital (org membership) benefit all groups equally?
#      If the coefficient on org_membership × Dalits is negative,
#      Dalits gain less from organisations than Brahmins.
#
#   2.  × social_group:
#      Does generalised trust have group-differentiated employment effects?
#
#   3. org_membership × education_years:
#      Are social capital returns higher for educated workers?
#      (Replicates original interaction for continuity)
#
#   4. Gender subgroup models: male-only and female-only
#      (Full sample with urban_resident control)
#
# All models use the same survey design object as the main model.
# ==============================================================================

print_section("INTERACTION EFFECTS & SUBGROUP ANALYSIS")

# Load model data and survey design
model_data  <- readRDS("output/models/model_data.rds")
svy_design  <- readRDS("output/models/svy_design.rds")

cat("Model data loaded:", nrow(model_data), "observations\n")

# Helper: update the survey design to a filtered subset
# This is needed for gender subgroup models
subset_design <- function(design, condition) {
  subset(design, condition)
}

# ── 1. SOCIAL CAPITAL × SOCIAL GROUP INTERACTIONS ────────────────────────────
print_section("INTERACTION 1: org_membership × social_group")

model_org_x_group <- tryCatch({
  svyglm(
    employed ~ org_membership * social_group  +
      education_years + female + age + age_sq +
      wealth_index + urban_resident + factor(STATEID_ind),
    design = svy_design,
    family = quasibinomial(link = "logit")
  )
}, error = function(e) {
  cat("svyglm failed, using glm:", e$message, "\n")
  glm(
    employed ~ org_membership * social_group  +
      education_years + female + age + age_sq +
      wealth_index + urban_resident + factor(STATEID_ind),
    family = binomial(link = "logit"),
    data = model_data
  )
})

# Extract interaction terms
org_group_coefs <- summary(model_org_x_group)$coefficients
org_interaction_rows <- grep("org_membership:social_group", rownames(org_group_coefs))

if (length(org_interaction_rows) > 0) {
  org_interaction_summary <- data.frame(
    term      = rownames(org_group_coefs)[org_interaction_rows],
    estimate  = org_group_coefs[org_interaction_rows, 1],
    std.error = org_group_coefs[org_interaction_rows, 2],
    p.value   = org_group_coefs[org_interaction_rows, 4],
    stringsAsFactors = FALSE
  ) %>%
    mutate(
      odds_ratio = exp(estimate),
      sig = case_when(
        p.value < 0.001 ~ "***", p.value < 0.01 ~ "**",
        p.value < 0.05 ~ "*",   p.value < 0.1  ~ ".",
        TRUE ~ ""
      )
    )
  cat("\nOrg × Group Interaction Coefficients:\n")
  print(org_interaction_summary, row.names = FALSE, digits = 3)
  write.csv(org_interaction_summary,
            "output/tables/interaction_org_x_group.csv", row.names = FALSE)
  cat("\nInterpretation: Negative coefficient = organisation membership helps\n")
  cat("                LESS for that group compared to Brahmins\n")
} else {
  cat("No org × group interaction terms found in output — check factor levels\n")
}

saveRDS(model_org_x_group, "output/models/model_org_x_group.rds")

# ── 2. GENERAL TRUST × SOCIAL GROUP INTERACTION ────────────────────────────────
print_section("INTERACTION 2:  × social_group")

model_trust_x_group <- tryCatch({
  svyglm(
    employed ~ org_membership  * social_group +
      education_years + female + age + age_sq +
      wealth_index + urban_resident + factor(STATEID_ind),
    design = svy_design,
    family = quasibinomial(link = "logit")
  )
}, error = function(e) {
  cat("svyglm failed, using glm:", e$message, "\n")
  glm(
    employed ~ org_membership  * social_group +
      education_years + female + age + age_sq +
      wealth_index + urban_resident + factor(STATEID_ind),
    family = binomial(link = "logit"),
    data = model_data
  )
})

trust_group_coefs <- summary(model_trust_x_group)$coefficients
trust_interaction_rows <- grep(":social_group", rownames(trust_group_coefs))

if (length(trust_interaction_rows) > 0) {
  trust_interaction_summary <- data.frame(
    term      = rownames(trust_group_coefs)[trust_interaction_rows],
    estimate  = trust_group_coefs[trust_interaction_rows, 1],
    std.error = trust_group_coefs[trust_interaction_rows, 2],
    p.value   = trust_group_coefs[trust_interaction_rows, 4],
    stringsAsFactors = FALSE
  ) %>%
    mutate(
      odds_ratio = exp(estimate),
      sig = case_when(
        p.value < 0.001 ~ "***", p.value < 0.01 ~ "**",
        p.value < 0.05 ~ "*",   p.value < 0.1  ~ ".",
        TRUE ~ ""
      )
    )
  cat("\nTrust × Group Interaction Coefficients:\n")
  print(trust_interaction_summary, row.names = FALSE, digits = 3)
  write.csv(trust_interaction_summary,
            "output/tables/interaction_trust_x_group.csv", row.names = FALSE)
}

saveRDS(model_trust_x_group, "output/models/model_trust_x_group.rds")

# ── 3. ORG MEMBERSHIP × EDUCATION INTERACTION ─────────────────────────────────
print_section("INTERACTION 3: org_membership × education_years")

model_interaction <- tryCatch({
  svyglm(
    employed ~ org_membership * education_years  +
      social_group + female + age + age_sq +
      wealth_index + urban_resident + factor(STATEID_ind),
    design = svy_design,
    family = quasibinomial(link = "logit")
  )
}, error = function(e) {
  cat("svyglm failed, using glm:", e$message, "\n")
  glm(
    employed ~ org_membership * education_years  +
      social_group + female + age + age_sq +
      wealth_index + urban_resident + factor(STATEID_ind),
    family = binomial(link = "logit"),
    data = model_data
  )
})

inter_coefs <- summary(model_interaction)$coefficients
inter_row <- grep("org_membership:education_years", rownames(inter_coefs))
if (length(inter_row) > 0) {
  cat("\norg_membership × education_years:\n")
  cat(sprintf("  Coefficient: %.4f | SE: %.4f | p: %.4f\n",
              inter_coefs[inter_row, 1],
              inter_coefs[inter_row, 2],
              inter_coefs[inter_row, 4]))
  cat("  Positive = social capital returns are amplified by education\n")
}

saveRDS(model_interaction, "output/models/model_interaction.rds")

# ── 4. GENDER SUBGROUP MODELS ─────────────────────────────────────────────────
print_section("GENDER SUBGROUP ANALYSIS")

model_male <- tryCatch({
  svyglm(
    employed ~ org_membership + education_years +
      social_group + age + age_sq + wealth_index +
      urban_resident + factor(STATEID_ind),
    design = subset(svy_design, female == 0),
    family = quasibinomial(link = "logit")
  )
}, error = function(e) {
  cat("svyglm failed for male model, using glm:", e$message, "\n")
  glm(
    employed ~ org_membership + education_years +
      social_group + age + age_sq + wealth_index +
      urban_resident + factor(STATEID_ind),
    family = binomial(link = "logit"),
    data = filter(model_data, female == 0)
  )
})

model_female <- tryCatch({
  svyglm(
    employed ~ org_membership + education_years +
      social_group + age + age_sq + wealth_index +
      urban_resident + factor(STATEID_ind),
    design = subset(svy_design, female == 1),
    family = quasibinomial(link = "logit")
  )
}, error = function(e) {
  cat("svyglm failed for female model, using glm:", e$message, "\n")
  glm(
    employed ~ org_membership + education_years +
      social_group + age + age_sq + wealth_index +
      urban_resident + factor(STATEID_ind),
    family = binomial(link = "logit"),
    data = filter(model_data, female == 1)
  )
})

saveRDS(model_male,   "output/models/model_male.rds")
saveRDS(model_female, "output/models/model_female.rds")

# Compare key coefficients across male/female
compare_gender <- function(coef_name, label) {
  m_coef <- tryCatch(coef(model_male)[coef_name], error = function(e) NA)
  f_coef <- tryCatch(coef(model_female)[coef_name], error = function(e) NA)
  if (!is.na(m_coef) && !is.na(f_coef)) {
    cat(sprintf("  %-30s Male: %+.3f | Female: %+.3f | Diff: %+.3f\n",
                label, m_coef, f_coef, f_coef - m_coef))
  }
}
cat("\nGender comparison of key coefficients (log-odds):\n")
compare_gender("org_membership",   "Org membership")
compare_gender(    "General trust")
compare_gender("education_years",  "Education (per year)")
compare_gender("social_groupDalits",   "Dalit vs Brahmin")
compare_gender("social_groupAdivasis", "Adivasi vs Brahmin")
compare_gender("social_groupMuslims",  "Muslim vs Brahmin")

cat("\n✓ Interaction effects and subgroup analysis complete\n")
