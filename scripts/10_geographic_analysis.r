# ==============================================================================
# 10_GEOGRAPHIC ANALYSIS — Muslim Geographic Concentration
# ==============================================================================
# Two levels of evidence for the "Muslim Geographic Trap":
#
#   LEVEL 1 (Ecological): District-level correlation between Muslim population
#            share and overall district employment rate.
#
#   LEVEL 2 (Individual): Within each district, compare Muslim vs non-Muslim
#            employment rates. This directly corroborates the ecological finding
#            and guards against ecological fallacy: if Muslims in high-Muslim
#            districts have similar employment to non-Muslims there, the trap is
#            truly geographic (scarce jobs for everyone). If Muslims still lag
#            even within-district, there is also an identity-level barrier.
#
# Data: analysis_data.rds (full sample — urban + rural, no premature filter)
# ==============================================================================

print_section("GEOGRAPHIC ANALYSIS — MUSLIM CONCENTRATION")

source("scripts/00_setup.r")
source("scripts/utils_functions.r")

analysis_data <- readRDS("output/analysis_data.rds")
cat("Data loaded:", nrow(analysis_data), "observations\n")

analysis_data <- analysis_data %>%
  mutate(
    is_muslim  = as.numeric(social_group == "Muslims"),
    state_id   = STATEID_ind,
    district_id = DISTID_ind
  ) %>%
  filter(!is.na(employed))

# ── LEVEL 1: DISTRICT-LEVEL ECOLOGICAL CORRELATION ───────────────────────────
cat("\n[1/4] Ecological Analysis: District-level aggregation...\n")

district_summary <- analysis_data %>%
  group_by(district_id, state_id) %>%
  summarize(
    n_sample       = n(),
    muslim_share   = mean(is_muslim, na.rm = TRUE) * 100,
    employment_rate = mean(employed, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  filter(n_sample >= 50)

cat("Districts analysed (n ≥ 50):", nrow(district_summary), "\n")

cor_res <- cor.test(district_summary$muslim_share, district_summary$employment_rate)
cat("Correlation (Muslim % vs District Employment %):", round(cor_res$estimate, 3), "\n")
cat("P-value:", format.pval(cor_res$p.value), "\n")

lm_geo <- lm(employment_rate ~ muslim_share, data = district_summary,
             weights = n_sample)
slope <- coef(lm_geo)["muslim_share"]
cat("Weighted regression slope:", round(slope, 3), "\n")
cat("Interpretation: 10% increase in Muslim share →",
    round(slope * 10, 2), "pp change in district employment\n")

write.csv(district_summary, "output/tables/district_concentration.csv", row.names = FALSE)

top_muslim_districts <- district_summary %>%
  arrange(desc(muslim_share)) %>%
  head(20) %>%
  select(district_id, state_id, muslim_share, employment_rate, n_sample)

write.csv(top_muslim_districts, "output/tables/top_muslim_districts.csv", row.names = FALSE)
cat("\nTop 20 districts by Muslim share:\n")
print(top_muslim_districts)

# ── LEVEL 2: INDIVIDUAL-LEVEL WITHIN-DISTRICT COMPARISON ─────────────────────
cat("\n[2/4] Individual-level within-district comparison...\n")

# For each district: compute Muslim employment rate and non-Muslim employment rate
within_district <- analysis_data %>%
  filter(!is.na(employed), !is.na(is_muslim)) %>%
  group_by(district_id, state_id, is_muslim) %>%
  summarize(
    n               = n(),
    employment_rate = mean(employed, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  filter(n >= 20) %>%
  pivot_wider(
    id_cols    = c(district_id, state_id),
    names_from = is_muslim,
    values_from = c(n, employment_rate),
    names_prefix = "g"
  )

# Rename for clarity
names(within_district) <- gsub("g0$", "nonmuslim", names(within_district))
names(within_district) <- gsub("g1$", "muslim", names(within_district))

within_district <- within_district %>%
  filter(!is.na(employment_rate_muslim) & !is.na(employment_rate_nonmuslim)) %>%
  mutate(
    within_gap = employment_rate_muslim - employment_rate_nonmuslim
  )

cat("Districts with both Muslim and non-Muslim observations:", nrow(within_district), "\n")
cat("Mean within-district gap (Muslim - non-Muslim):",
    round(mean(within_district$within_gap, na.rm = TRUE), 2), "pp\n")
cat("If gap ≈ 0 → geographic trap confirmed (district context explains it all)\n")
cat("If gap is substantially negative → identity-level barrier within districts\n")

write.csv(within_district, "output/tables/within_district_muslim_gap.csv", row.names = FALSE)

# ── VISUALIZATIONS ────────────────────────────────────────────────────────────
cat("\n[3/4] Generating plots...\n")

theme_premium <- theme_minimal() +
  theme(
    text                = element_text(family = "serif"),
    plot.title          = element_text(face = "bold", size = 16),
    axis.title          = element_text(face = "italic"),
    panel.grid.minor    = element_blank(),
    legend.position     = "right"
  )

# Ecological scatter
plot_geo <- ggplot(district_summary, aes(x = muslim_share, y = employment_rate)) +
  geom_point(aes(size = n_sample), alpha = 0.4, color = "#2c3e50") +
  geom_smooth(method = "lm", color = "#e74c3c", fill = "#ecf0f1", linewidth = 1.2) +
  labs(
    title    = "District-Level: Muslim Share vs. Employment (Ecological)",
    subtitle = paste("Correlation:", round(cor_res$estimate, 3),
                     "| Slope per 10pp Muslim share:",
                     round(slope * 10, 2), "pp"),
    x        = "Muslim Population Share (%)",
    y        = "Overall District Employment Rate (%)",
    size     = "Sample Size"
  ) +
  theme_premium +
  scale_size_continuous(range = c(2, 8))

ggsave("output/plots/muslim_employment_correlation.png", plot_geo,
       width = 10, height = 7, dpi = 300)

# Within-district gap distribution
plot_within <- ggplot(within_district, aes(x = within_gap)) +
  geom_histogram(bins = 40, fill = "#2c3e50", alpha = 0.7) +
  geom_vline(xintercept = 0, color = "#e74c3c", linetype = "dashed", linewidth = 1) +
  geom_vline(
    xintercept = mean(within_district$within_gap, na.rm = TRUE),
    color = "#f39c12", linetype = "solid", linewidth = 1.2
  ) +
  labs(
    title    = "Within-District Employment Gap: Muslims vs Non-Muslims",
    subtitle = paste("Mean gap:", round(mean(within_district$within_gap, na.rm = TRUE), 2),
                     "pp | Red = 0 (no gap) | Orange = mean"),
    x        = "Employment Rate Difference (Muslim pp − Non-Muslim pp)",
    y        = "Number of Districts"
  ) +
  theme_premium

ggsave("output/plots/muslim_within_district_gap.png", plot_within,
       width = 10, height = 7, dpi = 300)

cat("[4/4] ✓ Plots saved\n")
cat("\n✓ Geographic analysis complete\n")
