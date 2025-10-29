#!/usr/bin/env Rscript
# =============================================================================
# DATA CONSISTENCY CHECK
# =============================================================================
# Purpose: Verify data integrity and consistency across all datasets
# Date: 2023-10-28
# =============================================================================

library(tidyverse)

cat("\n")
cat("==============================================\n")
cat("       DATA CONSISTENCY CHECK                 \n")
cat("==============================================\n")
cat("\n")

# Set working directory
setwd("/Users/adrianstiermbp2023/regeneration_wound_respiration")

# Track issues
issues_found <- 0

# =============================================================================
# 1. CHECK SAMPLE INFO
# =============================================================================

cat("1. SAMPLE INFORMATION\n")
cat("---------------------\n")

sample_info <- read_csv("data/metadata/sample_info.csv", show_col_types = FALSE)

# Check for duplicates
duplicates <- sample_info %>%
  group_by(coral_id, genus) %>%
  filter(n() > 1)

if (nrow(duplicates) > 0) {
  cat("  ✗ Found duplicate coral IDs:\n")
  print(duplicates)
  issues_found <- issues_found + 1
} else {
  cat("  ✓ No duplicate coral IDs\n")
}

# Check treatment distribution
treatment_dist <- sample_info %>%
  group_by(genus, treatment) %>%
  summarise(n = n(), .groups = "drop")

cat("  Treatment distribution:\n")
print(treatment_dist, n = Inf)

# Check if all corals have wound dates
missing_dates <- sample_info %>%
  filter(is.na(wound_date))

if (nrow(missing_dates) > 0) {
  cat("  ✗ Missing wound dates for", nrow(missing_dates), "corals\n")
  issues_found <- issues_found + 1
} else {
  cat("  ✓ All corals have wound dates\n")
}

cat("\n")

# =============================================================================
# 2. CHECK SURFACE AREA DATA
# =============================================================================

cat("2. SURFACE AREA DATA\n")
cat("--------------------\n")

if (file.exists("data/processed/surface_area/final_surface_areas.csv")) {
  sa_data <- read_csv("data/processed/surface_area/final_surface_areas.csv",
                       show_col_types = FALSE)

  # Check for negative or zero surface areas
  invalid_sa <- sa_data %>%
    filter(CSA_cm2 <= 0)

  if (nrow(invalid_sa) > 0) {
    cat("  ✗ Found", nrow(invalid_sa), "invalid surface areas\n")
    issues_found <- issues_found + 1
  } else {
    cat("  ✓ All surface areas are valid (>0)\n")
  }

  # Check if all corals have surface areas
  sample_corals <- unique(sample_info$coral_id)
  sa_corals <- unique(sa_data$coral_number)
  missing_sa <- setdiff(sample_corals, sa_corals)

  if (length(missing_sa) > 0) {
    cat("  ✗ Missing surface areas for corals:", paste(missing_sa, collapse = ", "), "\n")
    issues_found <- issues_found + 1
  } else {
    cat("  ✓ All corals have surface area measurements\n")
  }
} else {
  cat("  ✗ Surface area file not found\n")
  issues_found <- issues_found + 1
}

cat("\n")

# =============================================================================
# 3. CHECK RESPIROMETRY DATA
# =============================================================================

cat("3. RESPIROMETRY DATA\n")
cat("--------------------\n")

# Check Porites data
if (file.exists("data/processed/respirometry/respirometry_normalized_final.csv")) {
  porites_resp <- read_csv("data/processed/respirometry/respirometry_normalized_final.csv",
                           show_col_types = FALSE)

  cat("  Porites data:\n")
  cat("    Records:", nrow(porites_resp), "\n")
  cat("    Corals:", n_distinct(porites_resp$coral_id), "\n")
  cat("    Timepoints:", paste(unique(porites_resp$timepoint), collapse = ", "), "\n")

  # Check for missing values
  missing_rates <- porites_resp %>%
    filter(is.na(resp_rate_umol_cm2_hr))

  if (nrow(missing_rates) > 0) {
    cat("    ✗", nrow(missing_rates), "records with missing respiration rates\n")
    issues_found <- issues_found + 1
  } else {
    cat("    ✓ No missing respiration rates\n")
  }
} else {
  cat("  ✗ Porites respirometry file not found\n")
  issues_found <- issues_found + 1
}

# Check Acropora data
if (file.exists("data/processed/respirometry/acropora_rates_simple.csv")) {
  acropora_resp <- read_csv("data/processed/respirometry/acropora_rates_simple.csv",
                            show_col_types = FALSE)

  cat("  Acropora data:\n")
  cat("    Records:", nrow(acropora_resp), "\n")
  cat("    Corals:", n_distinct(acropora_resp$coral_id), "\n")
  cat("    Timepoints:", paste(unique(acropora_resp$timepoint), collapse = ", "), "\n")

  # Check R² values
  low_r2 <- acropora_resp %>%
    filter(dark_r2 < 0.85)

  cat("    Low quality (R² < 0.85):", nrow(low_r2), "records\n")
} else {
  cat("  ✗ Acropora respirometry file not found\n")
  issues_found <- issues_found + 1
}

cat("\n")

# =============================================================================
# 4. CHECK COMBINED DATASET
# =============================================================================

cat("4. COMBINED SPECIES DATA\n")
cat("------------------------\n")

if (file.exists("data/processed/respirometry/combined_species_normalized.csv")) {
  combined <- read_csv("data/processed/respirometry/combined_species_normalized.csv",
                       show_col_types = FALSE)

  # Check species balance
  species_summary <- combined %>%
    group_by(species, timepoint, treatment_label) %>%
    summarise(n = n(), .groups = "drop") %>%
    pivot_wider(names_from = treatment_label, values_from = n, values_fill = 0)

  cat("  Species × Timepoint × Treatment:\n")
  print(species_summary, n = Inf)

  # Check for outliers (values > 3 SD from mean)
  outliers <- combined %>%
    group_by(species) %>%
    mutate(
      mean_resp = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
      sd_resp = sd(resp_rate_umol_cm2_hr, na.rm = TRUE),
      z_score = abs((resp_rate_umol_cm2_hr - mean_resp) / sd_resp)
    ) %>%
    filter(z_score > 3)

  if (nrow(outliers) > 0) {
    cat("\n  ⚠ Found", nrow(outliers), "potential outliers (>3 SD from mean)\n")
    cat("    Corals:", paste(unique(outliers$coral_id), collapse = ", "), "\n")
  } else {
    cat("\n  ✓ No extreme outliers detected\n")
  }
} else {
  cat("  ✗ Combined dataset not found\n")
  issues_found <- issues_found + 1
}

cat("\n")

# =============================================================================
# 5. CHECK DATA DIRECTORIES
# =============================================================================

cat("5. DATA DIRECTORY STRUCTURE\n")
cat("---------------------------\n")

# Check for Acropora extraction
acropora_dirs <- c(
  "data/raw/respirometry_runs/20230526/Acropora",
  "data/raw/respirometry_runs/20230528/Acropora",
  "data/raw/respirometry_runs/20230603/Acropora",
  "data/raw/respirometry_runs/20230619/Acropora"
)

for (dir in acropora_dirs) {
  if (dir.exists(dir)) {
    n_files <- length(list.files(dir, pattern = "\\.csv$"))
    cat("  ✓", basename(dirname(dir)), "Acropora:", n_files, "files\n")
  } else {
    cat("  ✗", basename(dirname(dir)), "Acropora directory missing\n")
    issues_found <- issues_found + 1
  }
}

cat("\n")

# =============================================================================
# 6. CHECK FIGURES
# =============================================================================

cat("6. FIGURE FILES\n")
cat("---------------\n")

fig_dir <- "reports/Figures"
if (dir.exists(fig_dir)) {
  n_figs <- length(list.files(fig_dir, pattern = "\\.png$"))
  cat("  ✓ Found", n_figs, "figure files\n")

  # Check key figures
  key_figs <- c(
    "respiration_both_species.png",
    "photosynthesis_both_species.png",
    "peak_response_comparison.png",
    "recovery_comparison.png",
    "pr_ratios_both_species.png"
  )

  for (fig in key_figs) {
    if (file.exists(file.path(fig_dir, fig))) {
      size_kb <- round(file.info(file.path(fig_dir, fig))$size / 1024, 1)
      cat("    ✓", fig, "(", size_kb, "KB)\n")
    } else {
      cat("    ✗", fig, "missing\n")
      issues_found <- issues_found + 1
    }
  }
} else {
  cat("  ✗ Figure directory not found\n")
  issues_found <- issues_found + 1
}

cat("\n")

# =============================================================================
# 7. CHECK HTML REPORTS
# =============================================================================

cat("7. HTML REPORTS\n")
cat("---------------\n")

report_files <- c(
  "reports/Complete_Analysis_Both_Species.html",
  "reports/Complete_Analysis_Simple.html",
  "reports/Wound_Respiration_Analysis.html"
)

for (report in report_files) {
  if (file.exists(report)) {
    size_mb <- round(file.info(report)$size / (1024 * 1024), 2)
    cat("  ✓", basename(report), "(", size_mb, "MB)\n")
  } else {
    cat("  ✗", basename(report), "not found\n")
    issues_found <- issues_found + 1
  }
}

cat("\n")

# =============================================================================
# SUMMARY
# =============================================================================

cat("==============================================\n")
cat("              SUMMARY                          \n")
cat("==============================================\n")
cat("\n")

if (issues_found == 0) {
  cat("✓ ALL CHECKS PASSED!\n")
  cat("  Data integrity verified\n")
  cat("  All files present and consistent\n")
} else {
  cat("⚠ ISSUES FOUND:", issues_found, "\n")
  cat("  Please review the issues above\n")
}

cat("\n")

# Additional statistics
if (exists("combined")) {
  cat("Dataset Statistics:\n")
  cat("------------------\n")
  cat("  Total measurements:", nrow(combined), "\n")
  cat("  Species:", paste(unique(combined$species), collapse = ", "), "\n")
  cat("  Date range:", min(combined$days_post_wound), "to",
      max(combined$days_post_wound), "days post-wound\n")
  cat("  Mean R² (dark phase):", round(mean(combined$dark_r2, na.rm = TRUE), 3), "\n")
  cat("  Data completeness:", round(sum(!is.na(combined$resp_rate_umol_cm2_hr)) /
                                     nrow(combined) * 100, 1), "%\n")
}

cat("\n")
cat("Consistency check complete!\n")
cat("\n")