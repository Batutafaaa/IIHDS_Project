# ==============================================================================
# DATA VISUALIZATION
# ==============================================================================

print_section("SAVING VISUALIZATIONS")

# Load data
wealth_by_group <- read.csv("output/tables/wealth_by_group.csv")
analysis_data <- readRDS("output/analysis_data.rds")

# Wealth-Employment Paradox Plot
p1 <- ggplot(
  wealth_by_group %>% filter(!is.na(social_group)), 
  aes(x = mean_wealth, y = employment_rate, color = social_group, size = n)
) +
  geom_point(alpha = 0.7) +
  geom_text(aes(label = social_group), vjust = -0.5, size = 3, 
            show.legend = FALSE, check_overlap = TRUE) +
  labs(
    title = "Wealth-Employment Paradox by Social Group",
    subtitle = "Wealthier groups show LOWER employment rates",
    x = "Mean Wealth Index",
    y = "Employment Rate",
    size = "Sample Size"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

# Save plot
ggsave(
  filename = "output/plots/wealth_employment_paradox.png",
  plot = p1,
  width = 12,
  height = 8,
  dpi = 300
)
cat("✓ Saved: wealth_employment_paradox.png\n")

# Add more visualizations as needed...

cat("✓ All visualizations saved\n")