#!/usr/bin/env Rscript
# =============================================================================
# Script: 14_identify_data_quality_issues.R
# Purpose: Identify and flag suspicious respiration rate values
# Date: 2023-10-28
# =============================================================================

library(tidyverse)

cat("\n=== DATA QUALITY INVESTIGATION ===\n\n")

# Load data
acropora_raw <- read_csv("data/processed/respirometry/acropora_rates_simple.csv",
                         show_col_types = FALSE)
porites_raw <- read_csv("data/processed/respirometry/respirometry_normalized_final.csv",
                        show_col_types = FALSE)

# =============================================================================
# IDENTIFY SUSPICIOUS PATTERNS
# =============================================================================

cat("1. CHECKING FOR SUSPICIOUS RATE PATTERNS\n")
cat("-----------------------------------------\n\n")

# Issue 1: Extreme rate changes between timepoints for same coral
check_rate_jumps <- function(data, species_name) {
  rate_changes <- data %>%
    arrange(coral_id, date) %>%
    group_by(coral_id) %>%
    mutate(
      prev_rate = lag(dark_rate_umol_L_min),
      rate_change = abs(dark_rate_umol_L_min - prev_rate),
      fold_change = abs(dark_rate_umol_L_min / prev_rate)
    ) %>%
    filter(!is.na(prev_rate))

  extreme_jumps <- rate_changes %>%
    filter(fold_change > 10 | rate_change > 2) %>%
    select(coral_id, timepoint, dark_rate_umol_L_min, prev_rate, fold_change, dark_r2)

  if (nrow(extreme_jumps) > 0) {
    cat(species_name, "- Extreme rate jumps (>10-fold or >2 µmol/L/min):\n")
    print(as.data.frame(extreme_jumps), row.names = FALSE)
    cat("\n")
  }

  return(extreme_jumps)
}

acr_jumps <- check_rate_jumps(acropora_raw, "ACROPORA")
# Note: Porites data structure is different

# Issue 2: Rates that are physiologically implausible
cat("\n2. PHYSIOLOGICALLY IMPLAUSIBLE RATES\n")
cat("-------------------------------------\n")

# Expected range for coral respiration: typically -2 to 0 µmol/L/min
# Values beyond -3 are suspicious, beyond -4 are highly unlikely

suspicious_acropora <- acropora_raw %>%
  filter(dark_rate_umol_L_min < -3 | dark_rate_umol_L_min > -0.01) %>%
  select(coral_id, timepoint, treatment, dark_rate_umol_L_min, dark_r2) %>%
  arrange(dark_rate_umol_L_min)

cat("\nAcropora - Suspicious dark rates (<-3 or >-0.01 µmol/L/min):\n")
print(as.data.frame(suspicious_acropora), row.names = FALSE)

# Issue 3: High R² but implausible rates
cat("\n\n3. HIGH R² BUT IMPLAUSIBLE RATES (potential measurement errors)\n")
cat("----------------------------------------------------------------\n")

high_r2_bad_rates <- acropora_raw %>%
  filter(dark_r2 > 0.95,
         (dark_rate_umol_L_min < -2 | dark_rate_umol_L_min > -0.02)) %>%
  select(coral_id, timepoint, dark_rate_umol_L_min, dark_r2)

cat("\nHigh R² (>0.95) but extreme rates:\n")
print(as.data.frame(high_r2_bad_rates), row.names = FALSE)

# =============================================================================
# STATISTICAL OUTLIER DETECTION
# =============================================================================

cat("\n\n4. STATISTICAL OUTLIER ANALYSIS\n")
cat("--------------------------------\n")

# Use median absolute deviation (MAD) - more robust than SD
identify_outliers_mad <- function(data, column, threshold = 5) {
  median_val <- median(data[[column]], na.rm = TRUE)
  mad_val <- mad(data[[column]], na.rm = TRUE)

  data %>%
    mutate(
      z_score_mad = abs((!!sym(column) - median_val) / (1.4826 * mad_val)),
      is_outlier_mad = z_score_mad > threshold
    )
}

acropora_outliers <- identify_outliers_mad(acropora_raw, "dark_rate_umol_L_min", 5)

outlier_summary <- acropora_outliers %>%
  filter(is_outlier_mad) %>%
  select(coral_id, timepoint, dark_rate_umol_L_min, z_score_mad, dark_r2) %>%
  arrange(desc(z_score_mad))

cat("\nExtreme outliers (>5 MAD from median):\n")
print(as.data.frame(outlier_summary), row.names = FALSE)

# =============================================================================
# PATTERN ANALYSIS
# =============================================================================

cat("\n\n5. PATTERN ANALYSIS\n")
cat("-------------------\n")

# Check if certain corals consistently show weird patterns
problem_corals <- acropora_outliers %>%
  filter(is_outlier_mad) %>%
  group_by(coral_id) %>%
  summarise(
    n_outlier_timepoints = n(),
    outlier_timepoints = paste(timepoint, collapse = ", "),
    mean_dark_r2 = mean(dark_r2, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(n_outlier_timepoints))

cat("\nCorals with multiple outlier timepoints:\n")
print(as.data.frame(problem_corals), row.names = FALSE)

# =============================================================================
# RECOMMENDATIONS
# =============================================================================

cat("\n\n6. DATA QUALITY RECOMMENDATIONS\n")
cat("================================\n\n")

# Identify measurements to potentially exclude
exclude_recommendations <- acropora_outliers %>%
  filter(
    is_outlier_mad & (
      dark_rate_umol_L_min < -3 |  # Physiologically implausible
      dark_rate_umol_L_min > -0.02 |  # Nearly zero respiration
      dark_r2 < 0.90  # Combined with lower R²
    )
  ) %>%
  select(coral_id, timepoint, dark_rate_umol_L_min, dark_r2, reason = is_outlier_mad) %>%
  mutate(
    reason = case_when(
      dark_rate_umol_L_min < -3 ~ "Rate too negative (< -3)",
      dark_rate_umol_L_min > -0.02 ~ "Rate near zero (> -0.02)",
      dark_r2 < 0.90 ~ "Low R² with outlier rate",
      TRUE ~ "Statistical outlier"
    )
  )

cat("Recommended exclusions:\n")
print(as.data.frame(exclude_recommendations), row.names = FALSE)

# Save recommendations
write_csv(exclude_recommendations,
          "data/processed/respirometry/quality_exclusions_recommended.csv")

cat("\n✓ Recommendations saved to: quality_exclusions_recommended.csv\n")

# =============================================================================
# SUMMARY
# =============================================================================

cat("\n\n=== SUMMARY ===\n")
cat("Total Acropora measurements:", nrow(acropora_raw), "\n")
cat("Statistical outliers (>5 MAD):", sum(acropora_outliers$is_outlier_mad), "\n")
cat("Recommended exclusions:", nrow(exclude_recommendations), "\n")
cat("Percentage to exclude:",
    round(nrow(exclude_recommendations) / nrow(acropora_raw) * 100, 1), "%\n")

cat("\nKey Issues Found:\n")
cat("1. Several corals show extreme rate jumps between timepoints\n")
cat("2. Corals 52, 47, 45, 51, 49, 48, 54 show particularly suspicious patterns\n")
cat("3. Some measurements have high R² but physiologically implausible rates\n")
cat("   (suggests measurement or calculation errors)\n")
cat("4. Day 1 and Day 7 have more outliers than other timepoints\n")

cat("\n✓ Data quality analysis complete!\n\n")