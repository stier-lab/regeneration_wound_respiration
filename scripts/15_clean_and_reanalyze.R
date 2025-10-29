#!/usr/bin/env Rscript
# =============================================================================
# Script: 15_clean_and_reanalyze.R
# Purpose: Re-analyze data with quality filtering for suspicious values
# Date: 2023-10-28
# =============================================================================

library(tidyverse)
library(patchwork)

cat("\n=== CLEANED DATA ANALYSIS ===\n\n")

# Load exclusion recommendations
exclusions <- read_csv("data/processed/respirometry/quality_exclusions_recommended.csv",
                       show_col_types = FALSE)

# Load original data
acropora_raw <- read_csv("data/processed/respirometry/acropora_rates_simple.csv",
                         show_col_types = FALSE)
porites_data <- read_csv("data/processed/respirometry/respirometry_normalized_final.csv",
                         show_col_types = FALSE)
surface_areas <- read_csv("data/processed/surface_area/final_surface_areas.csv",
                          show_col_types = FALSE)
sample_info <- read_csv("data/metadata/sample_info.csv", show_col_types = FALSE)

# =============================================================================
# APPLY QUALITY FILTERING
# =============================================================================

cat("Applying quality filters...\n")
cat("---------------------------\n")

# Create exclusion key for joining
exclusion_key <- exclusions %>%
  mutate(exclude = TRUE) %>%
  select(coral_id, timepoint, exclude)

# Filter Acropora data
acropora_cleaned <- acropora_raw %>%
  left_join(exclusion_key, by = c("coral_id", "timepoint")) %>%
  filter(is.na(exclude) | exclude == FALSE) %>%
  select(-exclude)

cat("Original Acropora measurements:", nrow(acropora_raw), "\n")
cat("After quality filtering:", nrow(acropora_cleaned), "\n")
cat("Removed:", nrow(acropora_raw) - nrow(acropora_cleaned), "suspicious measurements\n\n")

# List what was removed
cat("Removed measurements:\n")
for (i in 1:nrow(exclusions)) {
  cat("  - Coral", exclusions$coral_id[i], "at", exclusions$timepoint[i],
      "(", exclusions$reason[i], ")\n")
}

# =============================================================================
# RECALCULATE WITH SURFACE AREA NORMALIZATION
# =============================================================================

cat("\nRecalculating normalized rates...\n")

# Get surface areas and wound info
wound_areas <- data.frame(
  treatment = c(0, 1, 2),
  genus = "acr",
  wound_area_cm2 = c(0, 0.317, 0.634)  # 0, small (6.35mm dia), large (2x small)
)

# Prepare surface area data
sa_acropora <- surface_areas %>%
  filter(taxa == "Acropora") %>%
  select(coral_id = coral_number, initial_SA = CSA_cm2)

# Join with surface area data (treatment already in acropora_cleaned)
acropora_with_sa <- acropora_cleaned %>%
  mutate(genus = "acr") %>%  # Add genus column
  left_join(sa_acropora, by = "coral_id") %>%
  left_join(wound_areas, by = c("treatment", "genus")) %>%
  mutate(
    # Calculate adjusted surface area
    surface_area_cm2 = case_when(
      timepoint == "Pre-wound" ~ initial_SA,
      TRUE ~ initial_SA - wound_area_cm2
    ),
    # Normalize rates (assuming 0.65 L chamber)
    chamber_volume_L = 0.65,
    resp_rate_umol_cm2_hr = (-dark_rate_umol_L_min * 60 * chamber_volume_L) / surface_area_cm2,
    photo_rate_umol_cm2_hr = (light_rate_umol_L_min * 60 * chamber_volume_L) / surface_area_cm2,
    species = "Acropora pulchra",
    genus = "acr",
    treatment_label = case_when(
      treatment == 0 ~ "Control",
      treatment == 1 ~ "Small Wound",
      treatment == 2 ~ "Large Wound"
    ),
    days_post_wound = case_when(
      timepoint == "Pre-wound" ~ -1,
      timepoint == "Day 1" ~ 1,
      timepoint == "Day 7" ~ 7,
      timepoint == "Day 23" ~ 23
    )
  )

# =============================================================================
# COMBINE WITH PORITES
# =============================================================================

combined_cleaned <- bind_rows(
  # Porites data (already quality filtered)
  porites_data %>%
    mutate(
      species = "Porites compressa",
      genus = "por",
      treatment_label = case_when(
        treatment == 0 ~ "Control",
        treatment == 1 ~ "Small Wound",
        treatment == 2 ~ "Large Wound"
      ),
      days_post_wound = case_when(
        timepoint == "Pre-wound" ~ -1,
        timepoint == "Day 1" ~ 1,
        timepoint == "Day 7" ~ 7,
        timepoint == "Day 23" ~ 23
      )
    ) %>%
    select(species, genus, coral_id, treatment, treatment_label, timepoint,
           days_post_wound, dark_r2, light_r2, surface_area_cm2,
           resp_rate_umol_cm2_hr, photo_rate_umol_cm2_hr),

  # Cleaned Acropora data
  acropora_with_sa %>%
    select(species, genus, coral_id, treatment, treatment_label, timepoint,
           days_post_wound, dark_r2, light_r2, surface_area_cm2,
           resp_rate_umol_cm2_hr, photo_rate_umol_cm2_hr)
) %>%
  filter(dark_r2 >= 0.85)  # Apply R² filter

# Save cleaned dataset
write_csv(combined_cleaned,
          "data/processed/respirometry/combined_species_cleaned.csv")
cat("\n✓ Cleaned dataset saved\n")

# =============================================================================
# SUMMARY STATISTICS
# =============================================================================

cat("\n=== CLEANED DATA SUMMARY ===\n")
cat("============================\n\n")

summary_stats <- combined_cleaned %>%
  group_by(species, timepoint, treatment_label) %>%
  summarise(
    n = n(),
    mean_resp = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
    se_resp = sd(resp_rate_umol_cm2_hr, na.rm = TRUE) / sqrt(n()),
    median_resp = median(resp_rate_umol_cm2_hr, na.rm = TRUE),
    mad_resp = mad(resp_rate_umol_cm2_hr, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(species, match(timepoint, c("Pre-wound", "Day 1", "Day 7", "Day 23")), treatment_label)

cat("Sample sizes and respiration rates (cleaned):\n")
print(as.data.frame(summary_stats %>%
                    select(species, timepoint, treatment_label, n, mean_resp, se_resp)),
      row.names = FALSE)

# =============================================================================
# CREATE CLEANED FIGURES
# =============================================================================

cat("\n\nGenerating cleaned figures...\n")

# Define colors
treatment_colors <- c(
  "Control" = "#2E86AB",
  "Small Wound" = "#A23B72",
  "Large Wound" = "#F18F01"
)

# Figure 1: Cleaned respiration rates over time
p1 <- ggplot(combined_cleaned,
             aes(x = days_post_wound, y = resp_rate_umol_cm2_hr,
                 color = treatment_label, group = treatment_label)) +
  stat_summary(fun = mean, geom = "line", size = 1) +
  stat_summary(fun = mean, geom = "point", size = 3) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 1) +
  facet_wrap(~ species) +
  scale_color_manual(values = treatment_colors) +
  scale_x_continuous(breaks = c(-1, 1, 7, 23)) +
  labs(
    title = "Respiration Rates - Quality Filtered Data",
    subtitle = "Physiologically implausible values removed",
    x = "Days Post-Wounding",
    y = expression("Respiration Rate (µmol O"[2]*" cm"^{-2}*" hr"^{-1}*")"),
    color = "Treatment"
  ) +
  theme_classic() +
  theme(
    legend.position = "bottom",
    strip.text = element_text(face = "italic"),
    plot.title = element_text(face = "bold")
  )

ggsave("reports/Figures/respiration_cleaned.png", p1,
       width = 10, height = 6, dpi = 300, bg = "white")

# Figure 2: Before/After comparison
# Load original combined data
combined_original <- read_csv("data/processed/respirometry/combined_species_normalized.csv",
                              show_col_types = FALSE)

comparison_data <- bind_rows(
  combined_original %>%
    mutate(dataset = "Original") %>%
    select(dataset, species, timepoint, treatment_label, resp_rate_umol_cm2_hr),
  combined_cleaned %>%
    mutate(dataset = "Cleaned") %>%
    select(dataset, species, timepoint, treatment_label, resp_rate_umol_cm2_hr)
) %>%
  filter(species == "Acropora pulchra")  # Focus on Acropora where issues were found

p2 <- ggplot(comparison_data,
             aes(x = treatment_label, y = resp_rate_umol_cm2_hr,
                 fill = dataset)) +
  geom_boxplot(position = position_dodge(0.8), alpha = 0.7) +
  facet_wrap(~ timepoint, scales = "free_y") +
  scale_fill_manual(values = c("Original" = "#E74C3C", "Cleaned" = "#27AE60")) +
  labs(
    title = "Impact of Quality Filtering - Acropora pulchra",
    subtitle = "Comparison of original vs. cleaned data",
    x = "Treatment",
    y = expression("Respiration Rate (µmol O"[2]*" cm"^{-2}*" hr"^{-1}*")"),
    fill = "Dataset"
  ) +
  theme_classic() +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave("reports/Figures/data_cleaning_comparison.png", p2,
       width = 10, height = 8, dpi = 300, bg = "white")

cat("✓ Figures saved\n")

# =============================================================================
# STATISTICAL COMPARISON
# =============================================================================

cat("\n=== IMPACT OF CLEANING ===\n")
cat("==========================\n\n")

# Compare means before and after
comparison_summary <- combined_original %>%
  filter(species == "Acropora pulchra") %>%
  group_by(timepoint, treatment_label) %>%
  summarise(
    original_mean = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
    original_n = n(),
    .groups = "drop"
  ) %>%
  inner_join(
    combined_cleaned %>%
      filter(species == "Acropora pulchra") %>%
      group_by(timepoint, treatment_label) %>%
      summarise(
        cleaned_mean = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
        cleaned_n = n(),
        .groups = "drop"
      ),
    by = c("timepoint", "treatment_label")
  ) %>%
  mutate(
    percent_change = round((cleaned_mean - original_mean) / original_mean * 100, 1),
    n_removed = original_n - cleaned_n
  )

cat("Change in mean respiration rates after cleaning:\n")
print(as.data.frame(comparison_summary), row.names = FALSE)

cat("\n\n✓ Cleaned analysis complete!\n")
cat("Key files generated:\n")
cat("  - data/processed/respirometry/combined_species_cleaned.csv\n")
cat("  - reports/Figures/respiration_cleaned.png\n")
cat("  - reports/Figures/data_cleaning_comparison.png\n\n")