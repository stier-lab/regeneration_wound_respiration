#!/usr/bin/env Rscript
# =============================================================================
# Script: 16_trace_quality_control.R
# Purpose: Implement quality control for oxygen traces to detect probe issues
# Date: 2023-10-28
# =============================================================================

library(tidyverse)
library(here)

cat("\n=== OXYGEN TRACE QUALITY CONTROL ===\n")
cat("=====================================\n\n")

# Load raw Acropora data with traces
acropora_files <- list.files("data/processed/respirometry/acropora_extracted/",
                             pattern = "*.csv", full.names = TRUE)

# Function to assess trace quality
assess_trace_quality <- function(file_path) {
  data <- read_csv(file_path, show_col_types = FALSE)

  # Extract metadata from filename
  file_name <- basename(file_path)
  parts <- str_split(file_name, "_")[[1]]
  date <- parts[1]
  run <- paste0("run_", parts[3])
  coral_id <- str_extract(parts[5], "\\d+")

  # Check for various quality issues
  quality_checks <- list()

  # 1. Check for sudden jumps (probe disconnection/reconnection)
  if (nrow(data) > 1) {
    o2_diff <- diff(data$o2_umol_L)
    max_jump <- max(abs(o2_diff), na.rm = TRUE)
    mean_jump <- mean(abs(o2_diff), na.rm = TRUE)

    # Flag if max jump is > 10x the mean change
    quality_checks$sudden_jumps <- max_jump > (10 * mean_jump)
    quality_checks$max_jump_size <- max_jump
  }

  # 2. Check for flat-lining (probe malfunction)
  if (nrow(data) > 10) {
    # Calculate rolling standard deviation
    window_size <- min(10, floor(nrow(data)/4))
    rolling_sd <- numeric(nrow(data) - window_size + 1)

    for (i in 1:(nrow(data) - window_size + 1)) {
      rolling_sd[i] <- sd(data$o2_umol_L[i:(i+window_size-1)], na.rm = TRUE)
    }

    # Check if any window has near-zero variation
    quality_checks$flat_line <- any(rolling_sd < 0.1, na.rm = TRUE)
    quality_checks$min_variation <- min(rolling_sd, na.rm = TRUE)
  }

  # 3. Check for noise (high frequency oscillations)
  if (nrow(data) > 2) {
    # Calculate second derivative to detect oscillations
    o2_diff2 <- diff(diff(data$o2_umol_L))
    noise_metric <- sd(o2_diff2, na.rm = TRUE) / mean(abs(diff(data$o2_umol_L)), na.rm = TRUE)

    quality_checks$high_noise <- noise_metric > 2
    quality_checks$noise_level <- noise_metric
  }

  # 4. Check for unrealistic oxygen values
  quality_checks$unrealistic_values <- any(data$o2_umol_L < 0 | data$o2_umol_L > 400, na.rm = TRUE)
  quality_checks$min_o2 <- min(data$o2_umol_L, na.rm = TRUE)
  quality_checks$max_o2 <- max(data$o2_umol_L, na.rm = TRUE)

  # 5. Check for non-monotonic trends during respiration
  # In dark period (after 25 min), O2 should generally decrease
  dark_data <- data %>% filter(time_min >= 25)
  if (nrow(dark_data) > 10) {
    # Fit linear model and check residuals
    lm_fit <- lm(o2_umol_L ~ time_min, data = dark_data)
    residuals <- residuals(lm_fit)

    # Check for systematic patterns in residuals
    runs_test <- sum(diff(sign(residuals)) != 0)
    expected_runs <- (2 * sum(residuals > 0) * sum(residuals < 0)) / length(residuals) + 1

    quality_checks$non_linear <- abs(runs_test - expected_runs) > sqrt(length(residuals))
    quality_checks$r_squared <- summary(lm_fit)$r.squared
  }

  return(data.frame(
    coral_id = coral_id,
    date = date,
    run = run,
    file = file_name,
    sudden_jumps = quality_checks$sudden_jumps %||% NA,
    max_jump = quality_checks$max_jump_size %||% NA,
    flat_line = quality_checks$flat_line %||% NA,
    min_variation = quality_checks$min_variation %||% NA,
    high_noise = quality_checks$high_noise %||% NA,
    noise_level = quality_checks$noise_level %||% NA,
    unrealistic_values = quality_checks$unrealistic_values %||% NA,
    min_o2 = quality_checks$min_o2 %||% NA,
    max_o2 = quality_checks$max_o2 %||% NA,
    non_linear = quality_checks$non_linear %||% NA,
    r_squared = quality_checks$r_squared %||% NA
  ))
}

# Process all Acropora files
cat("Processing Acropora trace files...\n")
acropora_quality <- map_dfr(acropora_files, assess_trace_quality)

# Process Porites files
porites_files <- list.files("data/raw/respirometry_runs/",
                            pattern = "*Porites_time_series.csv",
                            recursive = TRUE, full.names = TRUE)

cat("Processing Porites trace files...\n")
porites_quality <- map_dfr(porites_files, function(file) {
  data <- read_csv(file, show_col_types = FALSE)

  # Extract metadata
  path_parts <- str_split(file, "/")[[1]]
  date <- path_parts[length(path_parts) - 1]
  coral_id <- str_extract(basename(file), "\\d+")

  # Run same quality checks
  assess_trace_quality(file) %>%
    mutate(species = "Porites spp.")
})

# Add species column to Acropora
acropora_quality <- acropora_quality %>%
  mutate(species = "Acropora pulchra")

# Combine results
all_quality <- bind_rows(acropora_quality, porites_quality)

# Identify problematic measurements
problematic <- all_quality %>%
  filter(sudden_jumps == TRUE |
         flat_line == TRUE |
         high_noise == TRUE |
         unrealistic_values == TRUE |
         r_squared < 0.7)

cat("\n=== QUALITY CONTROL SUMMARY ===\n")
cat("Total traces analyzed:", nrow(all_quality), "\n")
cat("Problematic traces identified:", nrow(problematic), "\n\n")

if (nrow(problematic) > 0) {
  cat("Issues found:\n")
  cat("- Sudden jumps:", sum(problematic$sudden_jumps, na.rm = TRUE), "\n")
  cat("- Flat-lining:", sum(problematic$flat_line, na.rm = TRUE), "\n")
  cat("- High noise:", sum(problematic$high_noise, na.rm = TRUE), "\n")
  cat("- Unrealistic values:", sum(problematic$unrealistic_values, na.rm = TRUE), "\n")
  cat("- Poor R² (<0.7):", sum(problematic$r_squared < 0.7, na.rm = TRUE), "\n\n")

  cat("Affected coral IDs:\n")
  print(unique(problematic$coral_id))
}

# Save quality assessment
write_csv(all_quality, "data/processed/respirometry/trace_quality_assessment.csv")
write_csv(problematic, "data/processed/respirometry/problematic_traces.csv")

# Now check against the high respiration values we found earlier
cat("\n=== CHECKING HIGH RESPIRATION VALUES ===\n")

# Load the cleaned dataset
cleaned_data <- read_csv("data/processed/respirometry/combined_species_cleaned.csv",
                         show_col_types = FALSE)

# Load original rates
acropora_rates <- read_csv("data/processed/respirometry/acropora_rates_simple.csv",
                           show_col_types = FALSE)
porites_rates <- read_csv("data/processed/respirometry/respirometry_normalized_final.csv",
                          show_col_types = FALSE)

# Find colonies with unusually high respiration
high_resp_colonies <- cleaned_data %>%
  group_by(species, coral_id) %>%
  summarise(
    max_resp = max(resp_rate_umol_cm2_hr, na.rm = TRUE),
    mean_resp = mean(resp_rate_umol_cm2_hr, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(max_resp > 2)  # Higher than 2 µmol O2/cm2/hr is unusual

cat("\nColonies with high respiration rates:\n")
print(high_resp_colonies)

# Cross-reference with quality issues
if (nrow(high_resp_colonies) > 0) {
  cat("\nQuality issues in high-respiration colonies:\n")

  for (i in 1:nrow(high_resp_colonies)) {
    colony <- high_resp_colonies[i,]
    quality_issues <- all_quality %>%
      filter(coral_id == colony$coral_id)

    if (nrow(quality_issues) > 0) {
      cat("\nCoral", colony$coral_id, "(", colony$species, "):\n")
      cat("  Max respiration:", round(colony$max_resp, 2), "µmol O2/cm2/hr\n")

      issues <- quality_issues %>%
        select(date, sudden_jumps, flat_line, high_noise, unrealistic_values, r_squared) %>%
        filter(sudden_jumps | flat_line | high_noise | unrealistic_values | r_squared < 0.85)

      if (nrow(issues) > 0) {
        cat("  Quality issues found:\n")
        print(issues)
      } else {
        cat("  No major quality issues detected in traces\n")
      }
    }
  }
}

cat("\n=== RECOMMENDATIONS ===\n")
cat("Based on trace quality analysis:\n\n")

# Generate recommendations
recommendations <- problematic %>%
  mutate(
    reason = case_when(
      unrealistic_values ~ "Unrealistic O2 values",
      sudden_jumps & max_jump > 50 ~ "Severe probe disconnection",
      flat_line ~ "Probe flat-lining",
      high_noise & noise_level > 5 ~ "Excessive noise",
      r_squared < 0.5 ~ "Very poor linear fit",
      TRUE ~ "Multiple minor issues"
    )
  ) %>%
  select(coral_id, date, species, reason, r_squared, max_jump, noise_level)

if (nrow(recommendations) > 0) {
  cat("Measurements recommended for exclusion:\n\n")
  print(recommendations)

  write_csv(recommendations, "data/processed/respirometry/trace_quality_exclusions.csv")
  cat("\nRecommendations saved to: data/processed/respirometry/trace_quality_exclusions.csv\n")
} else {
  cat("No additional measurements require exclusion based on trace quality.\n")
}

cat("\n✓ Trace quality control complete!\n")