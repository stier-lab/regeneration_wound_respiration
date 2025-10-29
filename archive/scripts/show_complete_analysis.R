#!/usr/bin/env Rscript
# =============================================================================
# Script: show_complete_analysis.R
# Purpose: Display the complete updated analysis
# Date: 2023-10-28
# =============================================================================

library(tidyverse)
library(patchwork)

cat("\n")
cat("================================================================================\n")
cat("      COMPLETE ANALYSIS OF CORAL WOUND HEALING METABOLIC RESPONSES\n")
cat("                    Moorea, French Polynesia\n")
cat("================================================================================\n\n")

# Load final QC dataset
data <- read_csv("data/processed/respirometry/combined_species_final_qc.csv",
                 show_col_types = FALSE)

cat("STUDY DETAILS\n")
cat("-------------\n")
cat("Location: CRIOBE Research Station, Moorea, French Polynesia\n")
cat("Species: Porites spp. and Acropora pulchra\n")
cat("Timeline: May-June 2023\n")
cat("Treatments: Control, Small Wound (6.35 mm), Large Wound (12.7 mm)\n\n")

cat("DATA QUALITY CONTROL\n")
cat("-------------------\n")
cat("Original dataset: 128 measurements\n")
cat("After physiological QC: 122 measurements (-6 with rates < -3 µmol/L/min)\n")
cat("After probe issue QC: 118 measurements (-4 with measurement errors)\n")
cat("Total excluded: 10 (7.8%)\n")
cat("Final dataset: 118 high-quality measurements\n\n")

cat("KEY FINDINGS\n")
cat("------------\n")
cat("1. MODERATE RESPONSES: Both species show moderate metabolic elevation\n")
cat("   - Porites spp.: Max increase ~77% at Day 7 (Small Wound)\n")
cat("   - Acropora pulchra: More variable, generally <2-fold increase\n\n")

cat("2. SPECIES DIFFERENCES:\n")
cat("   - Porites spp.: Consistent, predictable responses\n")
cat("   - Acropora pulchra: Variable, colony-specific responses\n\n")

cat("3. RECOVERY: Substantial recovery by Day 23 in both species\n\n")

cat("RESPIRATION RATES BY TREATMENT (µmol O₂/cm²/hr)\n")
cat("------------------------------------------------\n\n")

# Create summary table
summary_table <- data %>%
  group_by(species, timepoint, treatment_label) %>%
  summarise(
    n = n(),
    mean = round(mean(resp_rate_umol_cm2_hr, na.rm = TRUE), 2),
    se = round(sd(resp_rate_umol_cm2_hr, na.rm = TRUE)/sqrt(n()), 2),
    .groups = "drop"
  ) %>%
  mutate(
    rate = paste0(mean, " ± ", se, " (n=", n, ")")
  ) %>%
  select(species, timepoint, treatment_label, rate) %>%
  pivot_wider(names_from = treatment_label, values_from = rate)

print(as.data.frame(summary_table), row.names = FALSE)

cat("\n")
cat("PHOTOSYNTHESIS:RESPIRATION RATIOS\n")
cat("----------------------------------\n")

pr_summary <- data %>%
  mutate(p_to_r_ratio = (11 * photo_rate_umol_cm2_hr) / (13 * abs(resp_rate_umol_cm2_hr))) %>%
  filter(!is.na(p_to_r_ratio), p_to_r_ratio < 10) %>%
  group_by(species, timepoint) %>%
  summarise(
    mean_pr = round(mean(p_to_r_ratio, na.rm = TRUE), 2),
    .groups = "drop"
  )

cat("Mean P:R ratios by timepoint:\n")
print(as.data.frame(pr_summary), row.names = FALSE)
cat("\nNote: P:R > 1 indicates net autotrophy, < 1 indicates net heterotrophy\n")

cat("\nRECOVERY ASSESSMENT (% change from baseline)\n")
cat("---------------------------------------------\n")

recovery <- data %>%
  group_by(species, coral_id, treatment_label) %>%
  filter(timepoint %in% c("Pre-wound", "Day 23")) %>%
  summarise(
    baseline = mean(resp_rate_umol_cm2_hr[timepoint == "Pre-wound"], na.rm = TRUE),
    day23 = mean(resp_rate_umol_cm2_hr[timepoint == "Day 23"], na.rm = TRUE),
    n_timepoints = n_distinct(timepoint),
    .groups = "drop"
  ) %>%
  filter(n_timepoints == 2) %>%
  mutate(
    percent_change = round((day23 - baseline) / abs(baseline) * 100, 1)
  ) %>%
  group_by(species, treatment_label) %>%
  summarise(
    n_paired = n(),
    mean_change = round(mean(percent_change, na.rm = TRUE), 1),
    .groups = "drop"
  )

print(as.data.frame(recovery), row.names = FALSE)
cat("\nNote: Limited paired data for some groups\n")

# Create visualization
cat("\nGenerating summary visualization...\n")

# Define colors
treatment_colors <- c(
  "Control" = "#2E86AB",
  "Small Wound" = "#A23B72",
  "Large Wound" = "#F18F01"
)

# Prepare data
plot_data <- data %>%
  mutate(
    timepoint = factor(timepoint, levels = c("Pre-wound", "Day 1", "Day 7", "Day 23")),
    days_post = case_when(
      timepoint == "Pre-wound" ~ -1,
      timepoint == "Day 1" ~ 1,
      timepoint == "Day 7" ~ 7,
      timepoint == "Day 23" ~ 23
    )
  )

# Create plots
p1 <- ggplot(plot_data %>% filter(species == "Porites spp."),
             aes(x = days_post, y = resp_rate_umol_cm2_hr,
                 color = treatment_label, group = treatment_label)) +
  stat_summary(fun = mean, geom = "line", size = 1.2) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 2) +
  scale_color_manual(values = treatment_colors) +
  scale_x_continuous(breaks = c(-1, 1, 7, 23),
                     labels = c("Pre", "1", "7", "23")) +
  labs(title = expression(italic("Porites")~"spp."),
       x = "Days Post-Wound",
       y = expression("Respiration (µmol O"[2]*" cm"^{-2}*" hr"^{-1}*")"),
       color = "Treatment") +
  theme_classic(base_size = 12) +
  theme(legend.position = "bottom")

p2 <- ggplot(plot_data %>% filter(species == "Acropora pulchra"),
             aes(x = days_post, y = resp_rate_umol_cm2_hr,
                 color = treatment_label, group = treatment_label)) +
  stat_summary(fun = mean, geom = "line", size = 1.2) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 2) +
  scale_color_manual(values = treatment_colors) +
  scale_x_continuous(breaks = c(-1, 1, 7, 23),
                     labels = c("Pre", "1", "7", "23")) +
  labs(title = expression(italic("Acropora pulchra")),
       x = "Days Post-Wound",
       y = expression("Respiration (µmol O"[2]*" cm"^{-2}*" hr"^{-1}*")"),
       color = "Treatment") +
  theme_classic(base_size = 12) +
  theme(legend.position = "bottom")

# Combine plots
combined_plot <- p1 | p2

# Save
ggsave("figures/complete_analysis_summary.png", combined_plot,
       width = 14, height = 6, dpi = 300)

cat("Summary figure saved to: figures/complete_analysis_summary.png\n")

cat("\n")
cat("================================================================================\n")
cat("                           ANALYSIS COMPLETE\n")
cat("    Final dataset: data/processed/respirometry/combined_species_final_qc.csv\n")
cat("    HTML Report: Complete_Analysis_Final_QC.html\n")
cat("================================================================================\n")