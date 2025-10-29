#!/usr/bin/env Rscript
# =============================================================================
# Script: 12_combined_species_analysis.R
# Purpose: Combined analysis and visualization of Porites and Acropora data
# Date: 2023-10-28
# =============================================================================

library(tidyverse)
library(patchwork)

cat("\n=== COMBINED SPECIES ANALYSIS ===\n\n")

# Read processed data for both species
cat("Loading data...\n")

# Porites data
porites_data <- read_csv("data/processed/respirometry/respirometry_normalized_final.csv",
                          show_col_types = FALSE) %>%
  mutate(species = "Porites compressa")

# Acropora data
acropora_data <- read_csv("data/processed/respirometry/acropora_rates_simple.csv",
                          show_col_types = FALSE) %>%
  mutate(
    species = "Acropora pulchra",
    # Add comparable columns to match Porites data
    treatment_label = case_when(
      treatment == 0 ~ "Control",
      treatment == 1 ~ "Small Wound",
      treatment == 2 ~ "Large Wound",
      TRUE ~ "Unknown"
    ),
    days_post_wound = case_when(
      timepoint == "Pre-wound" ~ -1,
      timepoint == "Day 1" ~ 1,
      timepoint == "Day 7" ~ 7,
      timepoint == "Day 23" ~ 23
    ),
    # For visualization, we need respiration as positive values
    respiration_rate_normalized = -dark_rate_umol_L_min * 60  # Convert to hourly
  )

# Combine data for comparative analysis
combined_data <- bind_rows(
  porites_data %>%
    select(species, coral_id, treatment, treatment_label, timepoint, days_post_wound,
           dark_rate_normalized, dark_r2) %>%
    rename(respiration_rate = dark_rate_normalized, r2 = dark_r2),

  acropora_data %>%
    select(species, coral_id, treatment, treatment_label, timepoint, days_post_wound,
           respiration_rate_normalized, dark_r2) %>%
    rename(respiration_rate = respiration_rate_normalized, r2 = dark_r2)
) %>%
  filter(r2 >= 0.85)  # Quality filter

cat("Data loaded: ", n_distinct(combined_data$coral_id), "corals from",
    n_distinct(combined_data$species), "species\n\n")

# Summary statistics
cat("Summary by Species, Timepoint, and Treatment:\n")
cat("==============================================\n")

summary_stats <- combined_data %>%
  group_by(species, timepoint, treatment_label) %>%
  summarise(
    n = n(),
    mean_resp = mean(respiration_rate, na.rm = TRUE),
    se_resp = sd(respiration_rate, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  arrange(species, match(timepoint, c("Pre-wound", "Day 1", "Day 7", "Day 23")), treatment_label)

print(as.data.frame(summary_stats), row.names = FALSE)

# Create combined visualization
cat("\nCreating visualizations...\n")

# Define consistent colors
treatment_colors <- c("Control" = "#2E86AB",
                      "Small Wound" = "#A23B72",
                      "Large Wound" = "#F18F01")

# Prepare data for plotting
plot_data <- combined_data %>%
  mutate(
    timepoint = factor(timepoint, levels = c("Pre-wound", "Day 1", "Day 7", "Day 23")),
    treatment_label = factor(treatment_label, levels = c("Control", "Small Wound", "Large Wound"))
  )

# Figure 1: Side-by-side species comparison
p1_porites <- ggplot(plot_data %>% filter(species == "Porites compressa"),
                      aes(x = days_post_wound, y = respiration_rate,
                          color = treatment_label, group = treatment_label)) +
  stat_summary(fun = mean, geom = "line", size = 1) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 1) +
  scale_color_manual(values = treatment_colors) +
  labs(
    title = "Porites compressa",
    x = "Days Post-Wounding",
    y = expression("Respiration Rate (µmol O"[2]*" cm"^-2*" hr"^-1*")"),
    color = "Treatment"
  ) +
  scale_x_continuous(breaks = c(-1, 1, 7, 23)) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "italic")
  ) +
  ylim(0, NA)

p1_acropora <- ggplot(plot_data %>% filter(species == "Acropora pulchra"),
                       aes(x = days_post_wound, y = respiration_rate,
                           color = treatment_label, group = treatment_label)) +
  stat_summary(fun = mean, geom = "line", size = 1) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 1) +
  scale_color_manual(values = treatment_colors) +
  labs(
    title = "Acropora pulchra",
    x = "Days Post-Wounding",
    y = "",
    color = "Treatment"
  ) +
  scale_x_continuous(breaks = c(-1, 1, 7, 23)) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "italic")
  ) +
  ylim(0, NA)

# Combine with patchwork
p_combined <- p1_porites + p1_acropora +
  plot_annotation(
    title = "Species Comparison of Wound-Induced Metabolic Response",
    theme = theme(plot.title = element_text(size = 14, face = "bold"))
  )

ggsave("reports/Figures/respiration_species_comparison.png", p_combined,
       width = 12, height = 6, dpi = 300, bg = "white")
cat("  Saved: respiration_species_comparison.png\n")

# Figure 2: Faceted by treatment
p2 <- ggplot(plot_data, aes(x = days_post_wound, y = respiration_rate,
                             color = species, shape = species, group = species)) +
  stat_summary(fun = mean, geom = "line", size = 1) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 1, alpha = 0.5) +
  facet_wrap(~ treatment_label, scales = "free_y") +
  scale_color_manual(values = c("Porites compressa" = "#2166AC",
                                "Acropora pulchra" = "#D6604D")) +
  labs(
    title = "Wound Response by Treatment and Species",
    x = "Days Post-Wounding",
    y = expression("Respiration Rate (µmol O"[2]*" hr"^-1*")"),
    color = "Species",
    shape = "Species"
  ) +
  scale_x_continuous(breaks = c(-1, 1, 7, 23)) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    strip.background = element_rect(fill = "grey95", color = NA),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold")
  )

ggsave("reports/Figures/respiration_treatment_facets.png", p2,
       width = 10, height = 6, dpi = 300, bg = "white")
cat("  Saved: respiration_treatment_facets.png\n")

# Figure 3: Effect sizes relative to control
effect_data <- combined_data %>%
  group_by(species, timepoint) %>%
  mutate(
    control_mean = mean(respiration_rate[treatment == 0], na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    effect_size = (respiration_rate - control_mean) / control_mean * 100
  ) %>%
  filter(treatment != 0)  # Remove control

p3 <- ggplot(effect_data %>%
               filter(timepoint != "Pre-wound"),  # No treatment before wounding
             aes(x = timepoint, y = effect_size, fill = treatment_label)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_boxplot(position = position_dodge(0.8), alpha = 0.7) +
  facet_wrap(~ species, scales = "free") +
  scale_fill_manual(values = treatment_colors[-1]) +  # Remove control color
  labs(
    title = "Wound Effect Sizes Relative to Control",
    x = "Timepoint",
    y = "% Change from Control",
    fill = "Treatment"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    strip.background = element_rect(fill = "grey95", color = NA),
    strip.text = element_text(face = "italic"),
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave("reports/Figures/respiration_effect_sizes_species.png", p3,
       width = 10, height = 6, dpi = 300, bg = "white")
cat("  Saved: respiration_effect_sizes_species.png\n")

# Statistical summary
cat("\nStatistical Summary:\n")
cat("====================\n")

# Peak responses by species
peak_responses <- combined_data %>%
  filter(timepoint == "Day 7") %>%
  group_by(species, treatment_label) %>%
  summarise(
    mean_resp = mean(respiration_rate, na.rm = TRUE),
    se_resp = sd(respiration_rate, na.rm = TRUE) / sqrt(n()),
    n = n(),
    .groups = "drop"
  )

cat("\nPeak Response (Day 7):\n")
print(as.data.frame(peak_responses), row.names = FALSE)

# Recovery assessment (Day 23 vs Pre-wound)
recovery_data <- combined_data %>%
  filter(timepoint %in% c("Pre-wound", "Day 23")) %>%
  group_by(species, treatment_label, timepoint) %>%
  summarise(
    mean_resp = mean(respiration_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = timepoint, values_from = mean_resp) %>%
  mutate(
    recovery_pct = ((`Day 23` - `Pre-wound`) / `Pre-wound`) * 100
  )

cat("\nRecovery Assessment (Day 23 vs Pre-wound):\n")
print(as.data.frame(recovery_data), row.names = FALSE)

# Save combined dataset
output_file <- "data/processed/respirometry/combined_species_respiration.csv"
write_csv(combined_data, output_file)
cat("\nCombined dataset saved to:", output_file, "\n")

cat("\n✓ Combined species analysis complete!\n\n")