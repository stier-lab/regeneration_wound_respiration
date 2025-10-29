#!/usr/bin/env Rscript
# =============================================================================
# Script: verify_cleaned_report.R
# Purpose: Verify that the HTML report uses cleaned data
# Date: 2023-10-28
# =============================================================================

library(tidyverse)

cat("\n=== VERIFYING CLEANED REPORT ===\n\n")

# Load datasets
cleaned_data <- read_csv("data/processed/respirometry/combined_species_cleaned.csv",
                         show_col_types = FALSE)
original_data <- read_csv("data/processed/respirometry/combined_species_normalized.csv",
                         show_col_types = FALSE)

# Check key differences
cat("Dataset Comparison:\n")
cat("------------------\n")
cat("Original dataset rows:", nrow(original_data), "\n")
cat("Cleaned dataset rows:", nrow(cleaned_data), "\n")
cat("Rows removed:", nrow(original_data) - nrow(cleaned_data), "\n\n")

# Check Acropora Day 1 Small Wound (where biggest outliers were)
acropora_d1_sw_original <- original_data %>%
  filter(species == "Acropora pulchra",
         timepoint == "Day 1",
         treatment == 1) %>%
  summarise(
    mean_resp = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
    max_resp = max(resp_rate_umol_cm2_hr, na.rm = TRUE),
    n = n()
  )

acropora_d1_sw_cleaned <- cleaned_data %>%
  filter(species == "Acropora pulchra",
         timepoint == "Day 1",
         treatment == 1) %>%
  summarise(
    mean_resp = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
    max_resp = max(resp_rate_umol_cm2_hr, na.rm = TRUE),
    n = n()
  )

cat("Acropora Day 1 Small Wound Comparison:\n")
cat("--------------------------------------\n")
cat("Original - Mean:", round(acropora_d1_sw_original$mean_resp, 2),
    "Max:", round(acropora_d1_sw_original$max_resp, 2),
    "n:", acropora_d1_sw_original$n, "\n")
cat("Cleaned  - Mean:", round(acropora_d1_sw_cleaned$mean_resp, 2),
    "Max:", round(acropora_d1_sw_cleaned$max_resp, 2),
    "n:", acropora_d1_sw_cleaned$n, "\n")
cat("Reduction in mean:",
    round((1 - acropora_d1_sw_cleaned$mean_resp/acropora_d1_sw_original$mean_resp) * 100, 1),
    "%\n\n")

# Check that exclusions are documented
exclusions <- read_csv("data/processed/respirometry/quality_exclusions_recommended.csv",
                       show_col_types = FALSE)

cat("Documented Exclusions:\n")
cat("---------------------\n")
cat("Total excluded measurements:", nrow(exclusions), "\n")
cat("Coral IDs excluded:", paste(unique(exclusions$coral_id), collapse = ", "), "\n\n")

# Verify HTML file exists and was recently modified
html_file <- "Complete_Analysis_Enhanced_Cleaned.html"
if (file.exists(html_file)) {
  file_info <- file.info(html_file)
  cat("Report Status:\n")
  cat("-------------\n")
  cat("✓ HTML report exists:", html_file, "\n")
  cat("✓ File size:", round(file_info$size / 1024 / 1024, 2), "MB\n")
  cat("✓ Last modified:", format(file_info$mtime, "%Y-%m-%d %H:%M:%S"), "\n\n")

  # Check if report is newer than the cleaned data
  cleaned_data_time <- file.info("data/processed/respirometry/combined_species_cleaned.csv")$mtime
  if (file_info$mtime > cleaned_data_time) {
    cat("✓ Report is newer than cleaned dataset - using updated data\n")
  } else {
    cat("⚠ Warning: Report may be older than cleaned dataset\n")
  }
} else {
  cat("✗ HTML report not found\n")
}

# Summary statistics for paper
cat("\n=== FINAL STATISTICS FOR PAPER ===\n")
cat("==================================\n\n")

final_stats <- cleaned_data %>%
  group_by(species, timepoint, treatment_label) %>%
  summarise(
    n = n(),
    mean_resp = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
    se_resp = sd(resp_rate_umol_cm2_hr, na.rm = TRUE) / sqrt(n()),
    mean_photo = mean(photo_rate_umol_cm2_hr, na.rm = TRUE),
    se_photo = sd(photo_rate_umol_cm2_hr, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  filter(timepoint %in% c("Day 1", "Day 7")) %>%
  arrange(species, timepoint, treatment_label)

cat("Key Results (Day 1 and Day 7 only):\n\n")
print(as.data.frame(final_stats %>%
                    select(species, timepoint, treatment_label, n,
                           mean_resp, se_resp) %>%
                    mutate(mean_resp = round(mean_resp, 2),
                           se_resp = round(se_resp, 2))),
      row.names = FALSE)

cat("\n✓ Verification complete!\n\n")