#!/usr/bin/env Rscript
# =============================================================================
# Script: 16_trace_quality_control_simple.R
# Purpose: Implement quality control for oxygen traces to detect probe issues
# Date: 2023-10-28
# =============================================================================

library(tidyverse)

cat("\n=== OXYGEN TRACE QUALITY CONTROL ===\n")
cat("=====================================\n\n")

# Function to assess trace quality
assess_trace_quality <- function(file_path) {
  tryCatch({
    data <- read_csv(file_path, show_col_types = FALSE)

    # Check if required columns exist
    if (!all(c("time_min", "o2_umol_L") %in% names(data))) {
      return(NULL)
    }

    # Extract metadata from path
    file_name <- basename(file_path)
    path_parts <- strsplit(dirname(file_path), "/")[[1]]
    date <- path_parts[length(path_parts) - 1]
    coral_id <- str_extract(file_name, "\\d+")

    quality_checks <- list()
    quality_checks$file <- file_name
    quality_checks$coral_id <- coral_id
    quality_checks$date <- date
    quality_checks$n_points <- nrow(data)

    # 1. Check for sudden jumps (probe issues)
    if (nrow(data) > 1) {
      o2_diff <- diff(data$o2_umol_L)
      max_jump <- max(abs(o2_diff), na.rm = TRUE)
      mean_change <- mean(abs(o2_diff), na.rm = TRUE)

      quality_checks$max_jump <- max_jump
      quality_checks$mean_change <- mean_change
      quality_checks$jump_ratio <- max_jump / mean_change
      quality_checks$has_jumps <- max_jump > (10 * mean_change)
    }

    # 2. Check for flat-lining
    if (nrow(data) > 10) {
      # Calculate variation in windows
      window_size <- 5
      min_sd <- Inf
      for (i in 1:(nrow(data) - window_size + 1)) {
        window_sd <- sd(data$o2_umol_L[i:(i+window_size-1)], na.rm = TRUE)
        if (window_sd < min_sd) min_sd <- window_sd
      }
      quality_checks$min_variation <- min_sd
      quality_checks$has_flatline <- min_sd < 0.1
    }

    # 3. Check for noise
    if (nrow(data) > 2) {
      o2_smooth <- stats::smooth.spline(data$time_min, data$o2_umol_L, spar = 0.5)
      residuals <- data$o2_umol_L - predict(o2_smooth, data$time_min)$y
      noise_level <- sd(residuals, na.rm = TRUE)

      quality_checks$noise_level <- noise_level
      quality_checks$high_noise <- noise_level > 5
    }

    # 4. Check O2 range
    quality_checks$min_o2 <- min(data$o2_umol_L, na.rm = TRUE)
    quality_checks$max_o2 <- max(data$o2_umol_L, na.rm = TRUE)
    quality_checks$unrealistic <- data$o2_umol_L[1] < 50 | data$o2_umol_L[1] > 350

    # 5. Check dark phase linearity (respiration should be ~linear)
    dark_data <- data %>% filter(time_min >= 25)
    if (nrow(dark_data) > 10) {
      lm_fit <- lm(o2_umol_L ~ time_min, data = dark_data)
      quality_checks$dark_r2 <- summary(lm_fit)$r.squared
      quality_checks$dark_slope <- coef(lm_fit)[2]
      quality_checks$poor_fit <- quality_checks$dark_r2 < 0.8
    }

    return(as.data.frame(quality_checks))

  }, error = function(e) {
    return(NULL)
  })
}

# Process all available trace files
cat("Finding trace files...\n")

# Acropora files
acropora_files <- list.files("data/raw/respirometry_runs/",
                             pattern = "coral_\\d+_Acropora.*csv",
                             recursive = TRUE, full.names = TRUE)

# Porites files
porites_files <- list.files("data/raw/respirometry_runs/",
                            pattern = "coral_\\d+_Porites.*csv",
                            recursive = TRUE, full.names = TRUE)

cat("Found", length(acropora_files), "Acropora files\n")
cat("Found", length(porites_files), "Porites files\n\n")

# Process files
all_quality <- NULL

if (length(acropora_files) > 0) {
  cat("Processing Acropora traces...\n")
  acropora_quality <- map_dfr(acropora_files, assess_trace_quality)
  if (!is.null(acropora_quality)) {
    acropora_quality$species <- "Acropora pulchra"
    all_quality <- acropora_quality
  }
}

if (length(porites_files) > 0) {
  cat("Processing Porites traces...\n")
  porites_quality <- map_dfr(porites_files, assess_trace_quality)
  if (!is.null(porites_quality)) {
    porites_quality$species <- "Porites spp."
    all_quality <- bind_rows(all_quality, porites_quality)
  }
}

if (!is.null(all_quality) && nrow(all_quality) > 0) {

  # Identify problematic measurements
  problematic <- all_quality %>%
    filter(has_jumps == TRUE |
           has_flatline == TRUE |
           high_noise == TRUE |
           unrealistic == TRUE |
           poor_fit == TRUE)

  cat("\n=== QUALITY CONTROL SUMMARY ===\n")
  cat("Total traces analyzed:", nrow(all_quality), "\n")
  cat("Problematic traces:", nrow(problematic), "\n\n")

  if (nrow(problematic) > 0) {
    cat("Issues breakdown:\n")
    cat("- Large jumps:", sum(problematic$has_jumps, na.rm = TRUE), "\n")
    cat("- Flat-lining:", sum(problematic$has_flatline, na.rm = TRUE), "\n")
    cat("- High noise:", sum(problematic$high_noise, na.rm = TRUE), "\n")
    cat("- Unrealistic O2:", sum(problematic$unrealistic, na.rm = TRUE), "\n")
    cat("- Poor fit (R² < 0.8):", sum(problematic$poor_fit, na.rm = TRUE), "\n\n")

    cat("Affected measurements:\n")
    problematic %>%
      select(species, coral_id, date, dark_r2, max_jump, noise_level) %>%
      print()
  }

  # Save results
  write_csv(all_quality, "data/processed/respirometry/trace_quality_assessment.csv")
  if (nrow(problematic) > 0) {
    write_csv(problematic, "data/processed/respirometry/problematic_traces.csv")
  }

  # Check correlation with high respiration values
  cat("\n=== CHECKING HIGH RESPIRATION COLONIES ===\n")

  cleaned_data <- read_csv("data/processed/respirometry/combined_species_cleaned.csv",
                           show_col_types = FALSE)

  # Find colonies with unusually high respiration (outliers in Porites)
  high_resp_colonies <- cleaned_data %>%
    filter(resp_rate_umol_cm2_hr > 2 | resp_rate_umol_cm2_hr < -3) %>%
    select(species, coral_id, timepoint, resp_rate_umol_cm2_hr) %>%
    arrange(desc(abs(resp_rate_umol_cm2_hr)))

  if (nrow(high_resp_colonies) > 0) {
    cat("\nColonies with extreme respiration rates:\n")
    print(high_resp_colonies)

    cat("\nChecking trace quality for these colonies:\n")
    for (i in 1:nrow(high_resp_colonies)) {
      colony_id <- high_resp_colonies$coral_id[i]
      colony_issues <- all_quality %>%
        filter(coral_id == as.character(colony_id))

      if (nrow(colony_issues) > 0) {
        cat("\nCoral", colony_id, "- Quality issues:\n")
        issues <- colony_issues %>%
          select(date, has_jumps, has_flatline, high_noise, poor_fit, dark_r2)
        print(issues)
      }
    }
  }

  cat("\n✓ Trace quality control complete!\n")

} else {
  cat("No trace files found or could be processed.\n")
}

# Now specifically check the Porites outliers
cat("\n=== PORITES OUTLIER INVESTIGATION ===\n")

porites_outliers <- cleaned_data %>%
  filter(species == "Porites spp.",
         abs(resp_rate_umol_cm2_hr) > 1.5) %>%
  arrange(desc(abs(resp_rate_umol_cm2_hr)))

if (nrow(porites_outliers) > 0) {
  cat("\nPorites measurements with |respiration| > 1.5:\n")
  porites_outliers %>%
    select(coral_id, timepoint, treatment_label, resp_rate_umol_cm2_hr) %>%
    print()

  cat("\nRecommendation: Review these measurements for potential probe issues.\n")
}