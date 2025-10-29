#!/usr/bin/env Rscript
# =============================================================================
# Script: 06_process_respirometry_final.R
# Purpose: Final respirometry processing with quality filtering and SA normalization
# Author: Regeneration Wound Respiration Project
# Date: 2023-10-27
# =============================================================================

# Load required libraries -----------------------------------------------------
suppressPackageStartupMessages({
  library(tidyverse)
  library(viridis)
  library(patchwork)
})

# Suppress default plotting
pdf(NULL)

# Define constants -------------------------------------------------------------
treatment_colors <- c("0" = "#2E86AB", "1" = "#A23B72", "2" = "#F18F01")
treatment_labels <- c("0" = "Control", "1" = "Small Wound", "2" = "Large Wound")

# Quality thresholds
R2_THRESHOLD <- 0.85  # Minimum R² for including measurements
MIN_POINTS <- 20      # Minimum data points for reliable regression

# Time windows (focusing on dark phase as per diagnostic findings)
DARK_START <- 25      # Dark phase starts after 25 minutes

cat("\n=== FINAL RESPIROMETRY PROCESSING ===\n\n")

# Load diagnostic data ---------------------------------------------------------
cat("Loading diagnostic rate data...\n")
rate_data <- read_csv("data/processed/respirometry/rate_summary_diagnostic.csv",
                      show_col_types = FALSE)

# Load surface area data -------------------------------------------------------
cat("Loading surface area data...\n")

# Initial (pre-wound) surface areas
initial_sa <- read_csv("data/processed/surface_area/initial_SA.csv",
                       show_col_types = FALSE) %>%
  select(coral_id, initial_SA = SA_cm2) %>%
  distinct(coral_id, .keep_all = TRUE)  # Remove duplicates

# Post-wound surface areas (wound-adjusted)
postwound_sa <- read_csv("data/processed/surface_area/postwound_SA.csv",
                         show_col_types = FALSE) %>%
  select(coral_id, postwound_SA = SA_cm2) %>%
  distinct(coral_id, .keep_all = TRUE)  # Remove duplicates

# Combine surface areas
sa_data <- initial_sa %>%
  left_join(postwound_sa, by = "coral_id")

cat("  - Loaded SA data for", nrow(sa_data), "corals\n")

# Apply quality filtering ------------------------------------------------------
cat("\nApplying quality filters...\n")

# Filter based on R² threshold (focus on dark phase as it's more reliable)
filtered_data <- rate_data %>%
  filter(
    treatment != "Blank",                  # Exclude blanks
    treatment != "Unknown",                 # Exclude unknown treatments
    dark_r2 >= R2_THRESHOLD,               # Good fit quality for respiration
    dark_n >= MIN_POINTS                   # Sufficient data points
  )

cat("  - Samples before filtering:", nrow(rate_data %>% filter(treatment != "Blank")), "\n")
cat("  - Samples after R² filtering:", nrow(filtered_data), "\n")
cat("  - Samples excluded:", nrow(rate_data %>% filter(treatment != "Blank")) - nrow(filtered_data), "\n")

# List excluded samples
excluded <- rate_data %>%
  filter(treatment != "Blank", treatment != "Unknown") %>%
  filter(dark_r2 < R2_THRESHOLD | dark_n < MIN_POINTS) %>%
  select(date, coral_id, treatment, dark_r2, dark_n)

if (nrow(excluded) > 0) {
  cat("\nExcluded samples due to low quality:\n")
  print(excluded)
}

# Apply surface area normalization --------------------------------------------
cat("\nApplying surface area normalization...\n")

# Merge with surface area data
normalized_data <- filtered_data %>%
  left_join(sa_data, by = "coral_id") %>%
  mutate(
    # Determine which SA to use based on timepoint
    surface_area_cm2 = case_when(
      date == "20230526" ~ initial_SA,      # Pre-wound uses initial SA
      TRUE ~ postwound_SA                   # Post-wound uses adjusted SA
    ),
    # Convert rates from µmol/L/min to µmol/cm²/hr
    # Assuming 0.65 L chamber volume (adjust if different)
    chamber_volume_L = 0.65,

    # Dark phase (respiration) - negative values
    resp_rate_umol_cm2_hr = (dark_rate_umol_L_min * 60 * chamber_volume_L) / surface_area_cm2,

    # Light phase (photosynthesis) - only if good quality
    photo_rate_umol_cm2_hr = ifelse(
      light_r2 >= R2_THRESHOLD,
      (light_rate_umol_L_min * 60 * chamber_volume_L) / surface_area_cm2,
      NA
    ),

    # Calculate P:R ratio (only when both are available)
    p_to_r_ratio = ifelse(
      !is.na(photo_rate_umol_cm2_hr) & resp_rate_umol_cm2_hr != 0,
      abs(photo_rate_umol_cm2_hr / resp_rate_umol_cm2_hr),
      NA
    ),

    # Add timepoint labels
    timepoint_label = case_when(
      date == "20230526" ~ "Pre-wound",
      date == "20230528" ~ "Day 1",
      date == "20230603" ~ "Day 7",
      date == "20230619" ~ "Day 23"
    ),
    timepoint = factor(timepoint_label,
                      levels = c("Pre-wound", "Day 1", "Day 7", "Day 23"))
  )

# Check for missing surface areas
missing_sa <- normalized_data %>%
  filter(is.na(surface_area_cm2))

if (nrow(missing_sa) > 0) {
  cat("\nWARNING: Missing surface area data for", nrow(missing_sa), "samples\n")
  cat("These will be excluded from normalized analysis\n")
  normalized_data <- normalized_data %>%
    filter(!is.na(surface_area_cm2))
}

cat("  - Successfully normalized", nrow(normalized_data), "samples\n")

# Calculate summary statistics -------------------------------------------------
cat("\nCalculating summary statistics...\n")

summary_stats <- normalized_data %>%
  group_by(timepoint, treatment) %>%
  summarize(
    n = n(),
    # Respiration (dark phase)
    mean_resp_rate = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
    se_resp_rate = sd(resp_rate_umol_cm2_hr, na.rm = TRUE) / sqrt(n()),
    sd_resp_rate = sd(resp_rate_umol_cm2_hr, na.rm = TRUE),

    # Photosynthesis (light phase) - only high quality
    n_photo = sum(!is.na(photo_rate_umol_cm2_hr)),
    mean_photo_rate = mean(photo_rate_umol_cm2_hr, na.rm = TRUE),
    se_photo_rate = sd(photo_rate_umol_cm2_hr, na.rm = TRUE) / sqrt(n_photo),

    # P:R ratio
    n_pr = sum(!is.na(p_to_r_ratio)),
    mean_pr_ratio = mean(p_to_r_ratio, na.rm = TRUE),
    se_pr_ratio = sd(p_to_r_ratio, na.rm = TRUE) / sqrt(n_pr),

    .groups = "drop"
  )

cat("\nSummary statistics (mean ± SE):\n")
print(summary_stats %>%
        select(timepoint, treatment, n,
               mean_resp_rate, se_resp_rate,
               mean_photo_rate, se_photo_rate))

# Create publication-quality figures ------------------------------------------
cat("\n=== CREATING PUBLICATION FIGURES ===\n\n")

# Figure 1: Respiration rates (normalized to surface area) --------------------
cat("Creating Figure 1: Normalized respiration rates...\n")

p1 <- ggplot(normalized_data,
             aes(x = treatment, y = resp_rate_umol_cm2_hr, fill = treatment)) +
  geom_boxplot(alpha = 0.8, outlier.shape = 21, outlier.size = 2) +
  geom_jitter(width = 0.2, alpha = 0.4, size = 2) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  facet_wrap(~timepoint, nrow = 1) +
  scale_fill_manual(values = treatment_colors, labels = treatment_labels) +
  scale_x_discrete(labels = treatment_labels) +
  labs(
    title = "Coral Respiration Rates Following Wounding",
    subtitle = "Dark phase measurements normalized to surface area",
    x = "",
    y = expression(paste("Respiration Rate (µmol O"[2], " cm"^-2, " hr"^-1, ")")),
    fill = "Treatment"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.5),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    strip.background = element_rect(fill = "grey95"),
    strip.text = element_text(face = "bold")
  )

ggsave("reports/Figures/respiration_normalized_final.png", p1,
       width = 12, height = 6, dpi = 300, bg = "white")

# Figure 2: Treatment comparison across time ----------------------------------
cat("Creating Figure 2: Treatment effects over time...\n")

p2_data <- summary_stats %>%
  mutate(
    days_post_wound = case_when(
      timepoint == "Pre-wound" ~ -1,
      timepoint == "Day 1" ~ 1,
      timepoint == "Day 7" ~ 7,
      timepoint == "Day 23" ~ 23
    )
  )

p2 <- ggplot(p2_data,
             aes(x = days_post_wound, y = mean_resp_rate,
                 color = treatment, group = treatment)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = mean_resp_rate - se_resp_rate,
                    ymax = mean_resp_rate + se_resp_rate),
                width = 0.5, linewidth = 0.7) +
  scale_color_manual(values = treatment_colors, labels = treatment_labels) +
  scale_x_continuous(breaks = c(-1, 1, 7, 23),
                     labels = c("Pre", "1", "7", "23")) +
  labs(
    title = "Respiration Rate Dynamics Following Wounding",
    subtitle = "Mean ± SE, n = 6 per treatment",
    x = "Days Post-Wounding",
    y = expression(paste("Respiration Rate (µmol O"[2], " cm"^-2, " hr"^-1, ")")),
    color = "Treatment"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = c(0.85, 0.85),
    legend.background = element_rect(fill = "white", color = "black"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
    panel.grid.major = element_line(color = "grey90", linewidth = 0.5)
  )

ggsave("reports/Figures/respiration_timecourse_final.png", p2,
       width = 8, height = 6, dpi = 300, bg = "white")

# Figure 3: P:R ratios (if sufficient data) -----------------------------------
photo_quality_data <- normalized_data %>%
  filter(!is.na(p_to_r_ratio))

if (nrow(photo_quality_data) > 20) {
  cat("Creating Figure 3: P:R ratios...\n")

  p3 <- ggplot(photo_quality_data,
               aes(x = treatment, y = p_to_r_ratio, fill = treatment)) +
    geom_boxplot(alpha = 0.8, outlier.shape = 21) +
    geom_jitter(width = 0.2, alpha = 0.4, size = 2) +
    geom_hline(yintercept = 1, linetype = "dashed", color = "red", alpha = 0.7) +
    facet_wrap(~timepoint, nrow = 1) +
    scale_fill_manual(values = treatment_colors, labels = treatment_labels) +
    scale_x_discrete(labels = treatment_labels) +
    labs(
      title = "Photosynthesis:Respiration Ratios",
      subtitle = "Values > 1 indicate net autotrophy (red line)",
      x = "",
      y = "P:R Ratio",
      fill = "Treatment"
    ) +
    theme_classic(base_size = 12) +
    theme(
      legend.position = "bottom",
      panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      strip.background = element_rect(fill = "grey95"),
      strip.text = element_text(face = "bold")
    )

  ggsave("reports/Figures/pr_ratio_final.png", p3,
         width = 12, height = 6, dpi = 300, bg = "white")
} else {
  cat("  - Insufficient high-quality photosynthesis data for P:R figure\n")
}

# Figure 4: Statistical comparison plot ---------------------------------------
cat("Creating Figure 4: Statistical comparison...\n")

# Calculate effect sizes relative to control
effect_sizes <- normalized_data %>%
  group_by(timepoint) %>%
  mutate(
    control_mean = mean(resp_rate_umol_cm2_hr[treatment == "0"], na.rm = TRUE),
    relative_change = ((resp_rate_umol_cm2_hr - control_mean) / abs(control_mean)) * 100
  ) %>%
  filter(treatment != "0") %>%
  group_by(timepoint, treatment) %>%
  summarize(
    mean_effect = mean(relative_change, na.rm = TRUE),
    se_effect = sd(relative_change, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

p4 <- ggplot(effect_sizes,
             aes(x = timepoint, y = mean_effect, fill = treatment)) +
  geom_col(position = position_dodge(0.8), alpha = 0.8) +
  geom_errorbar(aes(ymin = mean_effect - se_effect,
                    ymax = mean_effect + se_effect),
                position = position_dodge(0.8),
                width = 0.25) +
  geom_hline(yintercept = 0, linetype = "solid", color = "black") +
  scale_fill_manual(values = treatment_colors[-1],
                    labels = treatment_labels[-1]) +
  labs(
    title = "Wound Effect on Respiration Relative to Control",
    subtitle = "Percent change from control ± SE",
    x = "Timepoint",
    y = "Change from Control (%)",
    fill = "Treatment"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave("reports/Figures/respiration_effect_sizes.png", p4,
       width = 8, height = 6, dpi = 300, bg = "white")

# Save processed data ----------------------------------------------------------
cat("\nSaving processed data...\n")

# Save normalized data
write_csv(normalized_data,
          "data/processed/respirometry/respirometry_normalized_final.csv")

# Save summary statistics
write_csv(summary_stats,
          "data/processed/respirometry/respirometry_summary_final.csv")

cat("  - Saved normalized data to: data/processed/respirometry/respirometry_normalized_final.csv\n")
cat("  - Saved summary stats to: data/processed/respirometry/respirometry_summary_final.csv\n")

# Final summary ----------------------------------------------------------------
cat("\n=== PROCESSING COMPLETE ===\n\n")

cat("Quality filtering summary:\n")
cat("  - R² threshold used:", R2_THRESHOLD, "\n")
cat("  - Samples passing filter:", nrow(normalized_data), "of",
    nrow(rate_data %>% filter(treatment != "Blank")), "\n")
cat("  - Percent retained:",
    round(100 * nrow(normalized_data) / nrow(rate_data %>% filter(treatment != "Blank")), 1), "%\n")

cat("\nGenerated figures:\n")
cat("  1. respiration_normalized_final.png - Box plots by timepoint\n")
cat("  2. respiration_timecourse_final.png - Time series plot\n")
if (nrow(photo_quality_data) > 20) {
  cat("  3. pr_ratio_final.png - P:R ratios\n")
}
cat("  4. respiration_effect_sizes.png - Effect size comparison\n")

cat("\nKey findings:\n")
# Calculate overall treatment effects
overall_effects <- normalized_data %>%
  group_by(treatment) %>%
  summarize(
    mean_resp = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
    .groups = "drop"
  )

cat("  - Overall mean respiration rates (µmol O₂/cm²/hr):\n")
for (i in 1:nrow(overall_effects)) {
  cat("    ", treatment_labels[overall_effects$treatment[i]], ":",
      round(overall_effects$mean_resp[i], 2), "\n")
}

# Identify timepoint with largest effect
max_effect <- effect_sizes %>%
  filter(abs(mean_effect) == max(abs(mean_effect)))

cat("  - Largest wound effect:", treatment_labels[max_effect$treatment[1]],
    "at", max_effect$timepoint[1],
    "(", round(max_effect$mean_effect[1], 1), "% change)\n")

cat("\n✓ All analyses complete!\n")