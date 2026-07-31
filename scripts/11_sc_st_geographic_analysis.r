# ==============================================================================
# 11_SC/ST GEOGRAPHIC ANALYSIS
# ==============================================================================
# Mirrors the two-level approach from script 10 for Dalits (SC) and Adivasis (ST):
#
#   LEVEL 1 (Ecological): District concentration × employment correlation
#   LEVEL 2 (Individual): Within-district SC/ST vs non-SC/ST employment gaps
#
# The three-group comparison (Muslim/Dalit/Adivasi) is the falsification baseline:
#   • Muslims → negative ecological correlation (geographic trap)
#   • Adivasis → positive ecological correlation (subsistence mirage)
#   • Dalits  → near-zero ecological correlation (distributed barrier)
#   The within-district gaps then tell us how much is geographic vs identity-based.
#
# Data: analysis_data.rds (full sample)
# ==============================================================================

print_section("SC/ST GEOGRAPHIC ANALYSIS")

source("scripts/00_setup.r")
source("scripts/utils_functions.r")

analysis_data <- readRDS("output/analysis_data.rds")
cat("Data loaded:", nrow(analysis_data), "observations\n")

analysis_data <- analysis_data %>%
  mutate(
    is_sc       = as.numeric(social_group == "Dalits"),
    is_st       = as.numeric(social_group == "Adivasis"),
    state_id    = STATEID_ind,
    district_id = DISTID_ind
  ) %>%
  filter(!is.na(employed))

cat("Total Dalits (SC):",   sum(analysis_data$is_sc, na.rm = TRUE), "\n")
cat("Total Adivasis (ST):", sum(analysis_data$is_st, na.rm = TRUE), "\n")

# ── LEVEL 1: ECOLOGICAL CORRELATIONS ─────────────────────────────────────────
cat("\n[1/4] District-level aggregation...\n")

district_summary <- analysis_data %>%
  group_by(district_id, state_id) %>%
  summarize(
    n_sample        = n(),
    sc_share        = mean(is_sc, na.rm = TRUE) * 100,
    st_share        = mean(is_st, na.rm = TRUE) * 100,
    employment_rate = mean(employed, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  filter(n_sample >= 50)

cat("Districts analysed:", nrow(district_summary), "\n")

# SC (Dalit) correlation
cor_sc  <- cor.test(district_summary$sc_share, district_summary$employment_rate)
lm_sc   <- lm(employment_rate ~ sc_share, data = district_summary, weights = n_sample)
slope_sc <- coef(lm_sc)["sc_share"]

cat("\n>>> SC (Dalit) Concentration Analysis <<<\n")
cat("Correlation:", round(cor_sc$estimate, 3), "| p:", format.pval(cor_sc$p.value), "\n")
cat("Slope per 10pp SC share:", round(slope_sc * 10, 2), "pp\n")

# ST (Adivasi) correlation
cor_st  <- cor.test(district_summary$st_share, district_summary$employment_rate)
lm_st   <- lm(employment_rate ~ st_share, data = district_summary, weights = n_sample)
slope_st <- coef(lm_st)["st_share"]

cat("\n>>> ST (Adivasi) Concentration Analysis <<<\n")
cat("Correlation:", round(cor_st$estimate, 3), "| p:", format.pval(cor_st$p.value), "\n")
cat("Slope per 10pp ST share:", round(slope_st * 10, 2), "pp\n")

# THREE-GROUP COMPARISON SUMMARY
cat("\n--- THREE-GROUP GEOGRAPHIC SUMMARY ---\n")
cat("This is the falsification baseline:\n")
cat(sprintf("  Muslims:  r = [see script 10]    → Geographic trap (negative)\n"))
cat(sprintf("  Adivasis: r = %+.3f (p = %s) → Subsistence mirage (positive)\n",
            cor_st$estimate, format.pval(cor_st$p.value)))
cat(sprintf("  Dalits:   r = %+.3f (p = %s) → Distributed barrier (near-zero)\n",
            cor_sc$estimate, format.pval(cor_sc$p.value)))
cat("Different spatial signatures → different mechanisms → different policy responses\n")

# ── LEVEL 2: WITHIN-DISTRICT INDIVIDUAL-LEVEL GAPS ────────────────────────────
cat("\n[2/4] Within-district individual gaps...\n")

# SC within-district gap
compute_within_gap <- function(data, group_var, group_label) {
  data %>%
    filter(!is.na(employed), !is.na(.data[[group_var]])) %>%
    group_by(district_id, state_id, val = .data[[group_var]]) %>%
    summarize(n = n(), emp_rate = mean(employed, na.rm = TRUE) * 100, .groups = "drop") %>%
    filter(n >= 20) %>%
    pivot_wider(id_cols = c(district_id, state_id),
                names_from = val, values_from = c(n, emp_rate),
                names_prefix = "g") %>%
    rename_with(~gsub("g0$", "non", .x)) %>%
    rename_with(~gsub("g1$", group_label, .x)) %>%
    filter(!is.na(.data[[paste0("emp_rate_", group_label)]]) &
           !is.na(emp_rate_non)) %>%
    mutate(within_gap = .data[[paste0("emp_rate_", group_label)]] - emp_rate_non)
}

within_sc <- compute_within_gap(analysis_data, "is_sc", "dalit")
within_st <- compute_within_gap(analysis_data, "is_st", "adivasi")

cat("Districts with within-SC gap data:", nrow(within_sc), "\n")
cat("Mean within-district SC gap (Dalit - non-Dalit):",
    round(mean(within_sc$within_gap, na.rm = TRUE), 2), "pp\n")
cat("Districts with within-ST gap data:", nrow(within_st), "\n")
cat("Mean within-district ST gap (Adivasi - non-Adivasi):",
    round(mean(within_st$within_gap, na.rm = TRUE), 2), "pp\n")

write.csv(district_summary, "output/tables/district_concentration_sc_st.csv", row.names = FALSE)
write.csv(within_sc, "output/tables/within_district_sc_gap.csv", row.names = FALSE)
write.csv(within_st, "output/tables/within_district_st_gap.csv", row.names = FALSE)

top_sc <- district_summary %>% arrange(desc(sc_share)) %>% head(15)
top_st <- district_summary %>% arrange(desc(st_share)) %>% head(15)
write.csv(top_sc, "output/tables/top_sc_districts.csv", row.names = FALSE)
write.csv(top_st, "output/tables/top_st_districts.csv", row.names = FALSE)

# ── VISUALIZATION ─────────────────────────────────────────────────────────────
cat("\n[3/4] Generating plots...\n")

theme_premium <- theme_minimal() +
  theme(
    text             = element_text(family = "serif"),
    plot.title       = element_text(face = "bold", size = 16),
    axis.title       = element_text(face = "italic"),
    panel.grid.minor = element_blank(),
    legend.position  = "right"
  )

plot_sc <- ggplot(district_summary, aes(x = sc_share, y = employment_rate)) +
  geom_point(aes(size = n_sample), alpha = 0.4, color = "#8e44ad") +
  geom_smooth(method = "lm", color = "#2980b9", fill = "#F4ECF7", linewidth = 1.2) +
  labs(
    title    = "Dalit (SC) Concentration vs. District Employment",
    subtitle = paste("Correlation:", round(cor_sc$estimate, 3),
                     "| NEAR ZERO = Distributed Barrier (geography-independent)"),
    x = "Dalit Population Share (%)", y = "District Employment Rate (%)", size = "Sample Size"
  ) +
  theme_premium + scale_size_continuous(range = c(2, 8))

ggsave("output/plots/sc_employment_correlation.png", plot_sc, width = 10, height = 7, dpi = 300)

plot_st <- ggplot(district_summary, aes(x = st_share, y = employment_rate)) +
  geom_point(aes(size = n_sample), alpha = 0.4, color = "#27ae60") +
  geom_smooth(method = "lm", color = "#c0392b", fill = "#E9F7EF", linewidth = 1.2) +
  labs(
    title    = "Adivasi (ST) Concentration vs. District Employment",
    subtitle = paste("Correlation:", round(cor_st$estimate, 3),
                     "| POSITIVE = Subsistence Mirage (distress labour)"),
    x = "Adivasi Population Share (%)", y = "District Employment Rate (%)", size = "Sample Size"
  ) +
  theme_premium + scale_size_continuous(range = c(2, 8))

ggsave("output/plots/st_employment_correlation.png", plot_st, width = 10, height = 7, dpi = 300)

cat("[4/4] ✓ Plots saved\n")
cat("\n✓ SC/ST geographic analysis complete\n")
