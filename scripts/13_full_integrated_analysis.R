#!/usr/bin/env Rscript
# =============================================================================
# Script: 13_full_integrated_analysis.R
# Purpose: Fully integrated analysis of Porites and Acropora respirometry data
# Date: 2023-10-28
# =============================================================================

library(tidyverse)
library(patchwork)

cat("\n=== FULL INTEGRATED ANALYSIS - PORITES & ACROPORA ===\n\n")

# =============================================================================
# LOAD ALL DATA
# =============================================================================

# Sample information
sample_info <- read_csv("data/metadata/sample_info.csv", show_col_types = FALSE)

# Surface areas
surface_areas <- read_csv("data/processed/surface_area/final_surface_areas.csv",
                          show_col_types = FALSE) %>%
  select(taxa, coral_number, CSA_cm2) %>%
  rename(coral_id = coral_number, initial_SA = CSA_cm2)

# Wound areas
wound_areas <- read_csv("data/processed/wound_areas.csv", show_col_types = FALSE)

# Calculate adjusted surface areas (post-wound)
adjusted_SA <- sample_info %>%
  left_join(surface_areas %>%
            mutate(genus = ifelse(taxa == "Acropora", "acr", "por")) %>%
            select(-taxa),
            by = c("coral_id", "genus")) %>%
  left_join(wound_areas %>% select(treatment, genus, wound_area_cm2),
            by = c("treatment", "genus")) %>%
  mutate(
    postwound_SA = case_when(
      treatment == 0 ~ initial_SA,  # Control - no wound
      TRUE ~ initial_SA - wound_area_cm2  # Subtract wound area
    )
  )

# =============================================================================
# PROCESS ACROPORA DATA WITH SURFACE AREA NORMALIZATION
# =============================================================================

cat("Processing Acropora data with surface area normalization...\n")

# Load Acropora raw rates
acropora_rates <- read_csv("data/processed/respirometry/acropora_rates_simple.csv",
                           show_col_types = FALSE)

# Add surface areas and normalize
# First, get unique surface areas per coral
acropora_SA <- adjusted_SA %>%
  filter(genus == "acr") %>%
  select(coral_id, initial_SA, postwound_SA, treatment, wound_area_cm2) %>%
  distinct()

acropora_normalized <- acropora_rates %>%
  left_join(acropora_SA, by = c("coral_id", "treatment")) %>%
  mutate(
    # Use appropriate surface area based on timepoint
    surface_area_cm2 = case_when(
      timepoint == "Pre-wound" ~ initial_SA,
      TRUE ~ postwound_SA
    ),
    # Assume chamber volume of 0.65 L for Acropora
    chamber_volume_L = 0.65,
    # Convert rates to µmol/cm²/hr
    resp_rate_umol_cm2_hr = (-dark_rate_umol_L_min * 60 * chamber_volume_L) / surface_area_cm2,
    photo_rate_umol_cm2_hr = (light_rate_umol_L_min * 60 * chamber_volume_L) / surface_area_cm2,
    # Calculate gross photosynthesis (P_gross = P_net + R)
    gross_photo_rate = photo_rate_umol_cm2_hr + resp_rate_umol_cm2_hr,
    # Calculate P:R ratio (11hr light * P_gross) / (13hr dark * R)
    p_to_r_ratio = (11 * gross_photo_rate) / (13 * resp_rate_umol_cm2_hr),
    # Add species identifier
    species = "Acropora pulchra",
    genus = "Acropora"
  )

# =============================================================================
# LOAD AND STANDARDIZE PORITES DATA
# =============================================================================

cat("Loading and standardizing Porites data...\n")

porites_normalized <- read_csv("data/processed/respirometry/respirometry_normalized_final.csv",
                               show_col_types = FALSE) %>%
  mutate(
    species = "Porites compressa",
    genus = "Porites",
    # Calculate gross photosynthesis for consistency
    gross_photo_rate = photo_rate_umol_cm2_hr + resp_rate_umol_cm2_hr
  )

# =============================================================================
# COMBINE BOTH SPECIES
# =============================================================================

cat("Combining data from both species...\n")

combined_data <- bind_rows(
  # Porites data
  porites_normalized %>%
    select(species, genus, coral_id, treatment, timepoint, timepoint_label,
           dark_r2, light_r2, surface_area_cm2,
           resp_rate_umol_cm2_hr, photo_rate_umol_cm2_hr,
           gross_photo_rate, p_to_r_ratio),

  # Acropora data
  acropora_normalized %>%
    mutate(timepoint_label = timepoint) %>%
    select(species, genus, coral_id, treatment, timepoint, timepoint_label,
           dark_r2, light_r2, surface_area_cm2,
           resp_rate_umol_cm2_hr, photo_rate_umol_cm2_hr,
           gross_photo_rate, p_to_r_ratio)
) %>%
  # Add treatment labels
  mutate(
    treatment_label = case_when(
      treatment == 0 ~ "Control",
      treatment == 1 ~ "Small Wound",
      treatment == 2 ~ "Large Wound",
      TRUE ~ "Unknown"
    ),
    # Add days post wound for plotting
    days_post_wound = case_when(
      timepoint == "Pre-wound" ~ -1,
      timepoint == "Day 1" ~ 1,
      timepoint == "Day 7" ~ 7,
      timepoint == "Day 23" ~ 23
    ),
    # Factor levels for proper ordering
    timepoint = factor(timepoint, levels = c("Pre-wound", "Day 1", "Day 7", "Day 23")),
    treatment_label = factor(treatment_label, levels = c("Control", "Small Wound", "Large Wound"))
  ) %>%
  # Quality filter
  filter(dark_r2 >= 0.85)

# Save combined dataset
write_csv(combined_data, "data/processed/respirometry/combined_species_normalized.csv")
cat("  Saved combined normalized data\n")

# =============================================================================
# SUMMARY STATISTICS
# =============================================================================

cat("\n=== SUMMARY STATISTICS ===\n\n")

summary_stats <- combined_data %>%
  group_by(species, timepoint, treatment_label) %>%
  summarise(
    n = n(),
    mean_resp = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
    se_resp = sd(resp_rate_umol_cm2_hr, na.rm = TRUE) / sqrt(n()),
    mean_photo = mean(photo_rate_umol_cm2_hr, na.rm = TRUE),
    se_photo = sd(photo_rate_umol_cm2_hr, na.rm = TRUE) / sqrt(n()),
    mean_pr = mean(p_to_r_ratio, na.rm = TRUE),
    .groups = "drop"
  )

cat("Respiration rates by species, timepoint, and treatment:\n")
print(as.data.frame(summary_stats %>%
                    select(species, timepoint, treatment_label, n, mean_resp, se_resp)),
      row.names = FALSE)

# =============================================================================
# VISUALIZATIONS
# =============================================================================

cat("\n=== CREATING FIGURES ===\n")

# Define consistent colors
treatment_colors <- c("Control" = "#2E86AB",
                     "Small Wound" = "#A23B72",
                     "Large Wound" = "#F18F01")

species_colors <- c("Porites compressa" = "#2166AC",
                   "Acropora pulchra" = "#D6604D")

# Create reports/Figures directory if it doesn't exist
if (!dir.exists("reports/Figures")) {
  dir.create("reports/Figures", recursive = TRUE)
}

# Figure 1: Respiration rates over time - both species
p1 <- ggplot(combined_data,
             aes(x = days_post_wound, y = resp_rate_umol_cm2_hr,
                 color = treatment_label, group = treatment_label)) +
  stat_summary(fun = mean, geom = "line", size = 1) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 1) +
  facet_wrap(~ species) +
  scale_color_manual(values = treatment_colors) +
  scale_x_continuous(breaks = c(-1, 1, 7, 23)) +
  labs(
    title = "Respiration Response to Wounding in Two Coral Species",
    x = "Days Post-Wounding",
    y = expression("Respiration Rate (µmol O"[2]*" cm"^-2*" hr"^-1*")"),
    color = "Treatment"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "italic"),
    strip.background = element_rect(fill = "grey95", color = NA),
    plot.title = element_text(face = "bold", size = 14)
  )

ggsave("reports/Figures/respiration_both_species.png", p1,
       width = 12, height = 6, dpi = 300, bg = "white")
cat("  Created: respiration_both_species.png\n")

# Figure 2: Photosynthesis rates
p2 <- ggplot(combined_data %>% filter(!is.na(photo_rate_umol_cm2_hr)),
             aes(x = days_post_wound, y = photo_rate_umol_cm2_hr,
                 color = treatment_label, group = treatment_label)) +
  stat_summary(fun = mean, geom = "line", size = 1) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 1) +
  facet_wrap(~ species) +
  scale_color_manual(values = treatment_colors) +
  scale_x_continuous(breaks = c(-1, 1, 7, 23)) +
  labs(
    title = "Photosynthesis Response to Wounding",
    x = "Days Post-Wounding",
    y = expression("Net Photosynthesis Rate (µmol O"[2]*" cm"^-2*" hr"^-1*")"),
    color = "Treatment"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "italic"),
    strip.background = element_rect(fill = "grey95", color = NA),
    plot.title = element_text(face = "bold", size = 14)
  )

ggsave("reports/Figures/photosynthesis_both_species.png", p2,
       width = 12, height = 6, dpi = 300, bg = "white")
cat("  Created: photosynthesis_both_species.png\n")

# Figure 3: P:R Ratios
p3 <- ggplot(combined_data %>% filter(!is.na(p_to_r_ratio), p_to_r_ratio < 10),
             aes(x = timepoint, y = p_to_r_ratio, fill = treatment_label)) +
  geom_boxplot(position = position_dodge(0.8), alpha = 0.7) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "red", alpha = 0.5) +
  facet_wrap(~ species) +
  scale_fill_manual(values = treatment_colors) +
  labs(
    title = "Photosynthesis to Respiration Ratios",
    x = "Timepoint",
    y = "P:R Ratio",
    fill = "Treatment",
    caption = "Red line indicates P:R = 1 (metabolic balance)"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "italic"),
    strip.background = element_rect(fill = "grey95", color = NA),
    plot.title = element_text(face = "bold", size = 14),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave("reports/Figures/pr_ratios_both_species.png", p3,
       width = 10, height = 6, dpi = 300, bg = "white")
cat("  Created: pr_ratios_both_species.png\n")

# Figure 4: Species comparison at peak response (Day 7)
peak_data <- combined_data %>%
  filter(timepoint == "Day 7")

p4 <- ggplot(peak_data,
             aes(x = species, y = resp_rate_umol_cm2_hr, fill = treatment_label)) +
  geom_boxplot(position = position_dodge(0.8), alpha = 0.7) +
  geom_point(position = position_dodge(0.8), alpha = 0.5) +
  scale_fill_manual(values = treatment_colors) +
  labs(
    title = "Peak Metabolic Response (Day 7 Post-Wounding)",
    x = "Species",
    y = expression("Respiration Rate (µmol O"[2]*" cm"^-2*" hr"^-1*")"),
    fill = "Treatment"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(face = "italic"),
    plot.title = element_text(face = "bold", size = 14)
  )

ggsave("reports/Figures/peak_response_comparison.png", p4,
       width = 8, height = 6, dpi = 300, bg = "white")
cat("  Created: peak_response_comparison.png\n")

# Figure 5: Recovery assessment
recovery_data <- combined_data %>%
  filter(timepoint %in% c("Pre-wound", "Day 23")) %>%
  select(species, coral_id, treatment_label, timepoint, resp_rate_umol_cm2_hr) %>%
  # Take mean if there are duplicates
  group_by(species, coral_id, treatment_label, timepoint) %>%
  summarise(resp_rate_umol_cm2_hr = mean(resp_rate_umol_cm2_hr, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = timepoint, values_from = resp_rate_umol_cm2_hr) %>%
  mutate(
    recovery_pct = ((`Day 23` - `Pre-wound`) / `Pre-wound`) * 100
  ) %>%
  filter(!is.na(recovery_pct))

p5 <- ggplot(recovery_data,
             aes(x = treatment_label, y = recovery_pct, fill = species)) +
  geom_boxplot(position = position_dodge(0.8), alpha = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  scale_fill_manual(values = species_colors) +
  labs(
    title = "Metabolic Recovery (Day 23 vs Pre-wound)",
    x = "Treatment",
    y = "% Change in Respiration Rate",
    fill = "Species",
    caption = "Values > 0 indicate incomplete recovery"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 14)
  )

ggsave("reports/Figures/recovery_comparison.png", p5,
       width = 8, height = 6, dpi = 300, bg = "white")
cat("  Created: recovery_comparison.png\n")

# =============================================================================
# STATISTICAL ANALYSIS
# =============================================================================

cat("\n=== STATISTICAL ANALYSIS ===\n\n")

# Peak response comparison
cat("Peak Response (Day 7) - Mean ± SE:\n")
cat("=====================================\n")
peak_summary <- peak_data %>%
  group_by(species, treatment_label) %>%
  summarise(
    n = n(),
    mean = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
    se = sd(resp_rate_umol_cm2_hr, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  mutate(summary = sprintf("%.2f ± %.2f (n=%d)", mean, se, n))

print(as.data.frame(peak_summary %>% select(species, treatment_label, summary)),
      row.names = FALSE)

# Recovery assessment
cat("\nRecovery Assessment (% change from pre-wound to Day 23):\n")
cat("=========================================================\n")
recovery_summary <- recovery_data %>%
  group_by(species, treatment_label) %>%
  summarise(
    n = n(),
    mean_change = mean(recovery_pct, na.rm = TRUE),
    se_change = sd(recovery_pct, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  mutate(summary = sprintf("%.1f%% ± %.1f%%", mean_change, se_change))

print(as.data.frame(recovery_summary %>% select(species, treatment_label, summary)),
      row.names = FALSE)

# Effect sizes at Day 7
cat("\nEffect Sizes at Day 7 (relative to control):\n")
cat("=============================================\n")
effect_sizes <- peak_data %>%
  group_by(species) %>%
  mutate(control_mean = mean(resp_rate_umol_cm2_hr[treatment == 0], na.rm = TRUE)) %>%
  filter(treatment != 0) %>%
  group_by(species, treatment_label) %>%
  summarise(
    effect_size_pct = mean((resp_rate_umol_cm2_hr - control_mean) / control_mean * 100,
                           na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(summary = sprintf("%.1f%%", effect_size_pct))

print(as.data.frame(effect_sizes %>% select(species, treatment_label, summary)),
      row.names = FALSE)

# =============================================================================
# EXPORT SUMMARY TABLE
# =============================================================================

cat("\n=== CREATING SUMMARY TABLE ===\n")

# Create comprehensive summary table
summary_table <- combined_data %>%
  group_by(species, timepoint, treatment_label) %>%
  summarise(
    n = n(),
    resp_mean = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
    resp_se = sd(resp_rate_umol_cm2_hr, na.rm = TRUE) / sqrt(n()),
    photo_mean = mean(photo_rate_umol_cm2_hr, na.rm = TRUE),
    photo_se = sd(photo_rate_umol_cm2_hr, na.rm = TRUE) / sqrt(n()),
    pr_mean = mean(p_to_r_ratio, na.rm = TRUE),
    pr_se = sd(p_to_r_ratio, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  mutate(
    resp_summary = sprintf("%.2f ± %.2f", resp_mean, resp_se),
    photo_summary = sprintf("%.2f ± %.2f", photo_mean, photo_se),
    pr_summary = sprintf("%.2f ± %.2f", pr_mean, pr_se)
  ) %>%
  select(species, timepoint, treatment_label, n,
         resp_summary, photo_summary, pr_summary)

write_csv(summary_table, "data/processed/respirometry/summary_table_both_species.csv")
cat("  Saved summary table\n")

cat("\n✓ FULL INTEGRATED ANALYSIS COMPLETE!\n")
cat("\nGenerated outputs:\n")
cat("  - data/processed/respirometry/combined_species_normalized.csv\n")
cat("  - data/processed/respirometry/summary_table_both_species.csv\n")
cat("  - reports/Figures/respiration_both_species.png\n")
cat("  - reports/Figures/photosynthesis_both_species.png\n")
cat("  - reports/Figures/pr_ratios_both_species.png\n")
cat("  - reports/Figures/peak_response_comparison.png\n")
cat("  - reports/Figures/recovery_comparison.png\n")
cat("\n")