#!/usr/bin/env Rscript
# =============================================================================
# Script: 10_process_acropora_respirometry.R
# Purpose: Process Acropora respirometry data through LoLinR
# Date: 2023-10-28
# =============================================================================

library(tidyverse)
library(LoLinR)

cat("\n=== PROCESSING ACROPORA RESPIROMETRY DATA ===\n\n")

# Set parameters for LoLinR
VOLUME <- 0.65  # Chamber volume in liters
DARK_START <- 25  # Dark phase starts after 25 minutes
LIGHT_START <- 10  # Light phase starts at 10 minutes
LIGHT_END <- 25   # Light phase ends at 25 minutes

# Dates to process
dates <- c("20230526", "20230528", "20230603", "20230619")

# Initialize results
all_results <- list()

for (date in dates) {
  cat("\nProcessing", date, ":\n")
  cat("================\n")

  input_dir <- paste0("data/raw/respirometry_runs/", date, "/Acropora/")
  output_dir <- paste0("data/processed/respirometry/", date, "/Acropora/")

  if (!dir.exists(input_dir)) {
    cat("  No Acropora data directory found\n")
    next
  }

  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Get list of files to process
  coral_files <- list.files(input_dir, pattern = "^[0-9]+\\.csv$", full.names = TRUE)
  blank_files <- list.files(input_dir, pattern = "^blank.*\\.csv$", full.names = TRUE)

  cat("  Found", length(coral_files), "coral files\n")
  cat("  Found", length(blank_files), "blank files\n")

  # Read blank assignment file if it exists
  blank_id_file <- paste0(input_dir, "blank_id.csv")
  if (file.exists(blank_id_file)) {
    blank_assignments <- read_csv(blank_id_file, show_col_types = FALSE)
    cat("  Using blank assignments from blank_id.csv\n")
  } else {
    cat("  WARNING: No blank_id.csv found\n")
    next
  }

  # Process each coral file
  date_results <- list()

  for (file in coral_files) {
    coral_id <- as.numeric(gsub(".*/(\\d+)\\.csv$", "\\1", file))
    cat("\n  Processing coral", coral_id, "...")

    tryCatch({
      # Read data - skip first row if needed
      data <- read_csv(file, skip = 1, show_col_types = FALSE)

      # Check if we have the necessary columns
      if (!"Time" %in% names(data) || !"Value" %in% names(data)) {
        cat(" ERROR: Missing required columns\n")
        next
      }

      # Prepare data for LoLinR
      lolinr_data <- data %>%
        select(Time, Value) %>%
        rename(time = Time, o2 = Value) %>%
        mutate(
          # Convert time to minutes from start
          time_min = as.numeric(difftime(time, time[1], units = "mins"))
        ) %>%
        select(time_min, o2)

      # Dark phase (respiration) - after 25 minutes
      dark_data <- lolinr_data %>%
        filter(time_min >= DARK_START)

      if (nrow(dark_data) > 10) {
        # Run LoLinR for dark phase
        dark_result <- thin_lin(
          dark_data$time_min,
          dark_data$o2,
          method = "z",
          n = 5
        )

        # Extract rate and R²
        dark_rate <- dark_result$slopes[1]  # µmol/L/min
        dark_r2 <- dark_result$R2[1]
        dark_n <- length(dark_result$indices[[1]])

        cat(" Dark R² =", round(dark_r2, 3))
      } else {
        dark_rate <- NA
        dark_r2 <- NA
        dark_n <- 0
        cat(" Insufficient dark data")
      }

      # Light phase (photosynthesis) - 10-25 minutes
      light_data <- lolinr_data %>%
        filter(time_min >= LIGHT_START, time_min <= LIGHT_END)

      if (nrow(light_data) > 10) {
        # Run LoLinR for light phase
        light_result <- thin_lin(
          light_data$time_min,
          light_data$o2,
          method = "z",
          n = 5
        )

        # Extract rate and R²
        light_rate <- light_result$slopes[1]  # µmol/L/min
        light_r2 <- light_result$R2[1]
        light_n <- length(light_result$indices[[1]])

        cat(", Light R² =", round(light_r2, 3))
      } else {
        light_rate <- NA
        light_r2 <- NA
        light_n <- 0
        cat(", No light data")
      }

      # Get blank assignment
      blank_id <- blank_assignments$blank_id[blank_assignments$coral_id == coral_id]
      if (length(blank_id) == 0) blank_id <- 1  # Default to blank 1

      # Store results
      date_results[[as.character(coral_id)]] <- data.frame(
        date = date,
        coral_id = coral_id,
        blank_id = blank_id,
        dark_rate_umol_L_min = dark_rate,
        dark_r2 = dark_r2,
        dark_n = dark_n,
        light_rate_umol_L_min = light_rate,
        light_r2 = light_r2,
        light_n = light_n,
        volume_L = VOLUME
      )

      cat(" ✓\n")

    }, error = function(e) {
      cat(" ERROR:", e$message, "\n")
    })
  }

  # Process blank files
  blank_results <- list()

  for (file in blank_files) {
    blank_num <- gsub(".*blank(\\d+)\\.csv$", "\\1", file)
    cat("\n  Processing blank", blank_num, "...")

    tryCatch({
      # Read data
      data <- read_csv(file, skip = 1, show_col_types = FALSE)

      # Prepare data for LoLinR
      lolinr_data <- data %>%
        select(Time, Value) %>%
        rename(time = Time, o2 = Value) %>%
        mutate(
          time_min = as.numeric(difftime(time, time[1], units = "mins"))
        ) %>%
        select(time_min, o2)

      # Dark phase
      dark_data <- lolinr_data %>%
        filter(time_min >= DARK_START)

      if (nrow(dark_data) > 10) {
        dark_result <- thin_lin(
          dark_data$time_min,
          dark_data$o2,
          method = "z",
          n = 5
        )

        dark_rate <- dark_result$slopes[1]
        dark_r2 <- dark_result$R2[1]

        cat(" Dark R² =", round(dark_r2, 3))
      } else {
        dark_rate <- NA
        dark_r2 <- NA
      }

      # Light phase
      light_data <- lolinr_data %>%
        filter(time_min >= LIGHT_START, time_min <= LIGHT_END)

      if (nrow(light_data) > 10) {
        light_result <- thin_lin(
          light_data$time_min,
          light_data$o2,
          method = "z",
          n = 5
        )

        light_rate <- light_result$slopes[1]
        light_r2 <- light_result$R2[1]

        cat(", Light R² =", round(light_r2, 3))
      } else {
        light_rate <- NA
        light_r2 <- NA
      }

      blank_results[[as.character(blank_num)]] <- data.frame(
        blank_id = as.numeric(blank_num),
        dark_blank_rate = dark_rate,
        dark_blank_r2 = dark_r2,
        light_blank_rate = light_rate,
        light_blank_r2 = light_r2
      )

      cat(" ✓\n")

    }, error = function(e) {
      cat(" ERROR:", e$message, "\n")
    })
  }

  # Combine results for this date
  if (length(date_results) > 0) {
    date_df <- bind_rows(date_results)

    # Add blank corrections if available
    if (length(blank_results) > 0) {
      blank_df <- bind_rows(blank_results)
      date_df <- date_df %>%
        left_join(blank_df, by = "blank_id")

      # Apply blank correction
      date_df <- date_df %>%
        mutate(
          dark_rate_corrected = dark_rate_umol_L_min - dark_blank_rate,
          light_rate_corrected = light_rate_umol_L_min - light_blank_rate
        )
    }

    # Save results for this date
    output_file <- paste0(output_dir, "acropora_rates_", date, ".csv")
    write_csv(date_df, output_file)
    cat("\n  Saved results to:", output_file, "\n")

    all_results[[date]] <- date_df
  }
}

# Combine all results
if (length(all_results) > 0) {
  combined_results <- bind_rows(all_results)

  # Save combined results
  output_file <- "data/processed/respirometry/acropora_rates_all.csv"
  write_csv(combined_results, output_file)

  cat("\n=== PROCESSING COMPLETE ===\n")
  cat("Combined results saved to:", output_file, "\n")
  cat("Total corals processed:", nrow(combined_results), "\n")

  # Summary statistics
  cat("\nSummary by date:\n")
  summary_stats <- combined_results %>%
    group_by(date) %>%
    summarise(
      n = n(),
      mean_dark_r2 = mean(dark_r2, na.rm = TRUE),
      mean_light_r2 = mean(light_r2, na.rm = TRUE),
      .groups = "drop"
    )
  print(summary_stats)
}

cat("\n✓ Acropora respirometry processing complete!\n\n")