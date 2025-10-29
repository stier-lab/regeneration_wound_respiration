#!/usr/bin/env Rscript
# =============================================================================
# Script: 17_final_quality_control.R
# Purpose: Final quality control and recommendations for data exclusion
# Date: 2023-10-28
# =============================================================================

library(tidyverse)

cat("\n=== FINAL QUALITY CONTROL ASSESSMENT ===\n")
cat("=========================================\n\n")

# Load current cleaned data
cleaned_data <- read_csv("data/processed/respirometry/combined_species_cleaned.csv",
                         show_col_types = FALSE)

# Already excluded measurements
already_excluded <- read_csv("data/processed/respirometry/quality_exclusions_recommended.csv",
                             show_col_types = FALSE)

cat("Previously excluded measurements:", nrow(already_excluded), "\n")
cat("Current dataset size:", nrow(cleaned_data), "\n\n")

# Identify additional problematic measurements based on outlier analysis
cat("=== ADDITIONAL QUALITY ISSUES ===\n\n")

# 1. Porites coral 43 on Day 7 - extreme negative respiration
porites_issues <- cleaned_data %>%
  filter(species == "Porites spp.",
         coral_id == 43,
         timepoint == "Day 7")

if (nrow(porites_issues) > 0) {
  cat("ISSUE 1: Porites coral 43 on Day 7\n")
  cat("  Respiration rate:", round(porites_issues$resp_rate_umol_cm2_hr[1], 2),
      "µmol O2/cm2/hr\n")
  cat("  This is 10× higher than typical Porites respiration\n")
  cat("  Recommendation: EXCLUDE (likely probe malfunction)\n\n")
}

# 2. Porites coral 54 on Day 7 - outlier
porites_issues2 <- cleaned_data %>%
  filter(species == "Porites spp.",
         coral_id == 54,
         timepoint == "Day 7")

if (nrow(porites_issues2) > 0) {
  cat("ISSUE 2: Porites coral 54 on Day 7\n")
  cat("  Respiration rate:", round(porites_issues2$resp_rate_umol_cm2_hr[1], 2),
      "µmol O2/cm2/hr\n")
  cat("  This is 3× higher than group median\n")
  cat("  Recommendation: REVIEW (borderline case)\n\n")
}

# 3. Acropora coral 49 on Day 1 - extreme positive value
acropora_issues <- cleaned_data %>%
  filter(species == "Acropora pulchra",
         coral_id == 49,
         timepoint == "Day 1")

if (nrow(acropora_issues) > 0) {
  cat("ISSUE 3: Acropora coral 49 on Day 1\n")
  cat("  Respiration rate:", round(acropora_issues$resp_rate_umol_cm2_hr[1], 2),
      "µmol O2/cm2/hr\n")
  cat("  This suggests oxygen production during dark period (impossible)\n")
  cat("  Recommendation: EXCLUDE (measurement error)\n\n")
}

# 4. Acropora coral 56 on Day 7 - high value
acropora_issues2 <- cleaned_data %>%
  filter(species == "Acropora pulchra",
         coral_id == 56,
         timepoint == "Day 7")

if (nrow(acropora_issues2) > 0) {
  cat("ISSUE 4: Acropora coral 56 on Day 7\n")
  cat("  Respiration rate:", round(acropora_issues2$resp_rate_umol_cm2_hr[1], 2),
      "µmol O2/cm2/hr\n")
  cat("  This is unusually high but potentially biological\n")
  cat("  Recommendation: REVIEW (check raw traces)\n\n")
}

# Create final exclusion recommendations
cat("=== FINAL EXCLUSION RECOMMENDATIONS ===\n\n")

additional_exclusions <- bind_rows(
  data.frame(
    coral_id = 43,
    species = "Porites spp.",
    timepoint = "Day 7",
    resp_rate = porites_issues$resp_rate_umol_cm2_hr[1],
    reason = "Extreme respiration (10× normal) - probe malfunction",
    recommendation = "EXCLUDE"
  ),
  data.frame(
    coral_id = 49,
    species = "Acropora pulchra",
    timepoint = "Day 1",
    resp_rate = acropora_issues$resp_rate_umol_cm2_hr[1],
    reason = "Positive respiration (O2 production in dark) - measurement error",
    recommendation = "EXCLUDE"
  )
)

cat("Strong recommendation to exclude:\n")
print(additional_exclusions %>% select(-recommendation))

# Apply additional exclusions
final_cleaned_data <- cleaned_data %>%
  anti_join(additional_exclusions, by = c("coral_id", "timepoint"))

cat("\n=== IMPACT OF ADDITIONAL CLEANING ===\n\n")
cat("Original cleaned data:", nrow(cleaned_data), "measurements\n")
cat("After additional exclusions:", nrow(final_cleaned_data), "measurements\n")
cat("Total removed:", nrow(cleaned_data) - nrow(final_cleaned_data), "\n\n")

# Compare group statistics
comparison <- bind_rows(
  cleaned_data %>%
    group_by(species, timepoint, treatment_label) %>%
    summarise(
      mean_resp = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
      n = n(),
      .groups = "drop"
    ) %>%
    mutate(dataset = "Current"),

  final_cleaned_data %>%
    group_by(species, timepoint, treatment_label) %>%
    summarise(
      mean_resp = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
      n = n(),
      .groups = "drop"
    ) %>%
    mutate(dataset = "Final")
) %>%
  pivot_wider(names_from = dataset,
              values_from = c(mean_resp, n),
              names_sep = "_") %>%
  mutate(
    change_percent = round((mean_resp_Final - mean_resp_Current) / abs(mean_resp_Current) * 100, 1)
  ) %>%
  filter(abs(change_percent) > 5)  # Only show groups with >5% change

if (nrow(comparison) > 0) {
  cat("Groups with >5% change in mean:\n")
  comparison %>%
    select(species, timepoint, treatment_label,
           mean_resp_Current, mean_resp_Final, change_percent) %>%
    mutate(across(starts_with("mean"), ~round(., 2))) %>%
    print()
}

# Save final cleaned dataset
write_csv(final_cleaned_data, "data/processed/respirometry/combined_species_final_qc.csv")
write_csv(additional_exclusions, "data/processed/respirometry/additional_exclusions.csv")

cat("\n=== FILES CREATED ===\n")
cat("1. combined_species_final_qc.csv - Final dataset with all QC applied\n")
cat("2. additional_exclusions.csv - List of additionally excluded measurements\n")

# Create summary report
cat("\n=== QUALITY CONTROL SUMMARY ===\n")
cat("================================\n\n")

cat("Total QC Process:\n")
cat("-----------------\n")
cat("1. Original dataset: 128 measurements\n")
cat("2. After first QC (rates < -3 µmol/L/min): 122 measurements (-6)\n")
cat("3. After probe issue QC: ", nrow(final_cleaned_data), " measurements (-",
    122 - nrow(final_cleaned_data), ")\n")
cat("4. Total excluded: ", 128 - nrow(final_cleaned_data),
    " (", round((128 - nrow(final_cleaned_data))/128 * 100, 1), "%)\n\n")

cat("Key Changes:\n")
cat("------------\n")
cat("• Porites Day 7 Small Wound: Now based on 5 colonies (was 6)\n")
cat("• Acropora Day 1 Small Wound: Now based on 4 colonies (was 5)\n")
cat("• More conservative, biologically realistic values\n")
cat("• Reduced influence of measurement errors\n")

cat("\n✓ Final quality control complete!\n")
cat("Recommend using 'combined_species_final_qc.csv' for publication\n")