# ==============================================================================
# 06_MARGINAL EFFECTS ANALYSIS
# ==============================================================================
# Computes Average Marginal Effects (AMEs) for all key variables using the
# counterfactual method (predict-the-difference-at-every-observation).
#
# Key improvements over previous version:
#   1. No subsampling — AMEs computed on FULL model dataset (~200k obs)
#   2. AMEs for both social capital dimensions (org_membership )
#   3. AME for urban_resident (new variable in model)
#   4. Group-differentiated social capital AMEs (from interaction model):
#      org_membership effect computed separately per social group
#   5. All group AMEs (every social group vs Brahmins)
# ==============================================================================

print_section("MARGINAL EFFECTS ANALYSIS")

readRDS_safe <- function(file_path, retries = 3) {
  for (i in 1:retries) {
    res <- tryCatch(readRDS(file_path), error = function(e) e)
    if (!inherits(res, "error")) return(res)
    Sys.sleep(1)
  }
  stop("Failed to read RDS file: ", file_path)
}

model_employment   <- readRDS_safe("output/models/model_employment_main.rds")
model_org_x_group  <- readRDS_safe("output/models/model_org_x_group.rds")
model_data         <- readRDS_safe("output/models/model_data.rds")

cat("Model data loaded:", nrow(model_data), "observations\n")
cat("Computing AMEs on full model sample (no subsampling)...\n")

# ── CORE AME FUNCTION ─────────────────────────────────────────────────────────
# For binary variables: AME = mean(P(Y=1|X=1) - P(Y=1|X=0)) across all obs
# For continuous variables: AME = coef * mean(P*(1-P)) [delta method]

compute_ame_binary <- function(model, data, var_name) {
  data0 <- data; data1 <- data
  data0[[var_name]] <- 0
  data1[[var_name]] <- 1
  pred0 <- predict(model, newdata = data0, type = "response")
  pred1 <- predict(model, newdata = data1, type = "response")
  diffs <- pred1 - pred0
  list(
    AME = mean(diffs, na.rm = TRUE),
    SE  = sd(diffs, na.rm = TRUE) / sqrt(sum(!is.na(diffs)))
  )
}

compute_ame_continuous <- function(model, data, var_name) {
  coef_val <- coef(model)[var_name]
  pred_prob <- predict(model, newdata = data, type = "response")
  avg_density <- mean(pred_prob * (1 - pred_prob), na.rm = TRUE)
  ame <- coef_val * avg_density
  se_raw <- summary(model)$coefficients[var_name, "Std. Error"]
  se  <- se_raw * avg_density
  list(AME = ame, SE = se)
}

compute_ame_group <- function(model, data, group_label) {
  data_ref   <- data; data_ref$social_group   <- factor("Brahmins",   levels = levels(data$social_group))
  data_group <- data; data_group$social_group <- factor(group_label, levels = levels(data$social_group))
  pred_ref   <- predict(model, newdata = data_ref,   type = "response")
  pred_group <- predict(model, newdata = data_group, type = "response")
  diffs <- pred_group - pred_ref
  list(
    AME = mean(diffs, na.rm = TRUE),
    SE  = sd(diffs, na.rm = TRUE) / sqrt(sum(!is.na(diffs)))
  )
}

finalize_ame <- function(res, label) {
  z <- res$AME / res$SE
  p <- 2 * pnorm(-abs(z))
  data.frame(
    Variable      = label,
    AME           = res$AME,
    AME_pp        = res$AME * 100,
    SE            = res$SE,
    CI_lower_pp   = (res$AME - 1.96 * res$SE) * 100,
    CI_upper_pp   = (res$AME + 1.96 * res$SE) * 100,
    z_value       = z,
    p_value       = p,
    sig = case_when(
      p < 0.001 ~ "***", p < 0.01 ~ "**",
      p < 0.05 ~ "*",   p < 0.1  ~ ".",
      TRUE ~ ""
    ),
    stringsAsFactors = FALSE
  )
}

# ── COMPUTE AMES FOR MAIN MODEL ───────────────────────────────────────────────
cat("\n[1/4] Computing main variable AMEs...\n")

start_time <- Sys.time()

ame_list <- list(
  finalize_ame(compute_ame_binary(model_employment, model_data, "org_membership"),
               "Organisation Membership"),

  finalize_ame(compute_ame_continuous(model_employment, model_data, "education_years"),
               "Education (per year)"),
  finalize_ame(compute_ame_binary(model_employment, model_data, "female"),
               "Female (vs Male)"),
  finalize_ame(compute_ame_continuous(model_employment, model_data, "wealth_index"),
               "Wealth Index"),
  finalize_ame(compute_ame_binary(model_employment, model_data, "urban_resident"),
               "Urban (vs Rural)")
)

cat("  ✓ Completed in", round(difftime(Sys.time(), start_time, units = "secs"), 1), "seconds\n")

# ── GROUP AMES (all groups vs Brahmins) ───────────────────────────────────────
cat("\n[2/4] Computing group AMEs (each group vs Brahmins)...\n")

groups_to_test <- c("Forward_castes", "OBCs", "Dalits", "Adivasis", "Muslims", "Other_Religions")

group_ame_list <- lapply(groups_to_test, function(g) {
  cat("  •", g, "... ")
  res <- tryCatch(
    compute_ame_group(model_employment, model_data, g),
    error = function(e) { cat("ERROR\n"); return(NULL) }
  )
  if (is.null(res)) return(NULL)
  cat("✓\n")
  finalize_ame(res, paste0(g, " (vs Brahmins)"))
})
group_ame_list <- Filter(Negate(is.null), group_ame_list)

# ── GROUP-SPECIFIC SOCIAL CAPITAL AMES (from interaction model) ───────────────
cat("\n[3/4] Computing group-specific org_membership AMEs (from interaction model)...\n")

group_org_ame_list <- lapply(levels(model_data$social_group), function(g) {
  sub_data <- model_data %>% filter(social_group == g)
  if (nrow(sub_data) < 50) return(NULL)
  cat("  •", g, "... ")
  res <- tryCatch(
    compute_ame_binary(model_org_x_group, sub_data, "org_membership"),
    error = function(e) { cat("ERROR\n"); return(NULL) }
  )
  if (is.null(res)) return(NULL)
  cat("✓\n")
  finalize_ame(res, paste0("Org membership | ", g))
})
group_org_ame_list <- Filter(Negate(is.null), group_org_ame_list)

cat("\n[4/4] Assembling and saving results...\n")

# ── ASSEMBLE RESULTS ──────────────────────────────────────────────────────────
ame_results         <- bind_rows(ame_list)
group_ame_results   <- bind_rows(group_ame_list)
group_org_ame_res   <- bind_rows(group_org_ame_list)

# Save all outputs
write.csv(ame_results,       "output/tables/marginal_effects.csv",            row.names = FALSE)
write.csv(group_ame_results, "output/tables/group_marginal_effects.csv",      row.names = FALSE)
write.csv(group_org_ame_res, "output/tables/group_social_capital_ames.csv",   row.names = FALSE)

# ── DISPLAY ───────────────────────────────────────────────────────────────────
print_section("AVERAGE MARGINAL EFFECTS — MAIN VARIABLES")
cat("(Percentage point change in employment probability)\n\n")
print(
  ame_results %>%
    select(Variable, AME_pp, CI_lower_pp, CI_upper_pp, p_value, sig) %>%
    mutate(across(where(is.numeric), ~round(., 3))),
  row.names = FALSE
)

print_section("AVERAGE MARGINAL EFFECTS — SOCIAL GROUPS vs BRAHMINS")
print(
  group_ame_results %>%
    select(Variable, AME_pp, CI_lower_pp, CI_upper_pp, p_value, sig) %>%
    mutate(across(where(is.numeric), ~round(., 3))),
  row.names = FALSE
)

print_section("ORG MEMBERSHIP AME BY SOCIAL GROUP (Interaction Model)")
cat("A positive AME = org membership increases employment probability for this group\n")
cat("Compare across groups to see differential social capital returns\n\n")
print(
  group_org_ame_res %>%
    select(Variable, AME_pp, CI_lower_pp, CI_upper_pp, p_value, sig) %>%
    mutate(across(where(is.numeric), ~round(., 3))),
  row.names = FALSE
)

cat("\n✓ Marginal effects analysis complete\n")
