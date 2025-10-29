#!/usr/bin/env Rscript
# =============================================================================
# Script: 11_process_acropora_simple.R
# Purpose: Simple processing of Acropora respirometry data
# Date: 2023-10-28
# Note: Creates preliminary rates for Acropora to add to analysis
# =============================================================================

library(tidyverse)

cat("\n=== PROCESSING ACROPORA RESPIROMETRY DATA (SIMPLE) ===\n\n")

# Read sample info
sample_info <- read_csv("data/metadata/sample_info.csv") %>%
  filter(genus == "acr") %>%
  select(coral_id, treatment)

# Define timepoints
dates <- c("20230526", "20230528", "20230603", "20230619")
date_labels <- c("Pre-wound", "Day 1", "Day 7", "Day 23")

# Initialize results
all_results <- list()

for (i in 1:length(dates)) {
  date <- dates[i]
  label <- date_labels[i]

  cat("\nProcessing", date, "(", label, "):\n")
  cat("================================\n")

  acropora_dir <- paste0("data/raw/respirometry_runs/", date, "/Acropora/")

  if (!dir.exists(acropora_dir)) {
    cat("  No Acropora directory found\n")
    next
  }

  # Get coral files
  coral_files <- list.files(acropora_dir, pattern = "^[0-9]+\\.csv$", full.names = TRUE)
  cat("  Found", length(coral_files), "coral files\n")

  date_results <- list()

  for (file in coral_files) {
    coral_id <- as.numeric(gsub(".*/(\\d+)\\.csv$", "\\1", file))

    tryCatch({
      # Read data
      data <- read_csv(file, show_col_types = FALSE)

      # Check if we have the necessary columns
      if (!"Time" %in% names(data) || !"Value" %in% names(data)) {
        cat("    Coral", coral_id, ": Missing required columns\n")
        next
      }

      # Convert time to minutes
      data <- data %>%
        mutate(
          time_min = as.numeric(difftime(Time, Time[1], units = "mins")),
          o2_umol_L = Value
        )

      # Calculate rates for different phases using simple linear regression
      # Dark phase (respiration) - after 25 minutes
      dark_data <- data %>%
        filter(time_min >= 25, time_min <= 40)  # 15 minute window

      if (nrow(dark_data) > 10) {
        dark_lm <- lm(o2_umol_L ~ time_min, data = dark_data)
        dark_rate <- coef(dark_lm)[2]  # slope in µmol/L/min
        dark_r2 <- summary(dark_lm)$r.squared
      } else {
        dark_rate <- NA
        dark_r2 <- NA
      }

      # Light phase (photosynthesis) - 10 to 25 minutes
      light_data <- data %>%
        filter(time_min >= 10, time_min <= 25)

      if (nrow(light_data) > 10) {
        light_lm <- lm(o2_umol_L ~ time_min, data = light_data)
        light_rate <- coef(light_lm)[2]  # slope in µmol/L/min
        light_r2 <- summary(light_lm)$r.squared
      } else {
        light_rate <- NA
        light_r2 <- NA
      }

      # Get treatment
      treatment <- sample_info$treatment[sample_info$coral_id == coral_id]
      if (length(treatment) == 0) treatment <- NA

      # Store results
      date_results[[as.character(coral_id)]] <- data.frame(
        date = date,
        timepoint = label,
        coral_id = coral_id,
        treatment = treatment,
        dark_rate_umol_L_min = dark_rate,
        dark_r2 = dark_r2,
        light_rate_umol_L_min = light_rate,
        light_r2 = light_r2
      )

      cat("    Coral", coral_id, ": Dark R² =", round(dark_r2, 3),
          ", Light R² =", round(light_r2, 3), "\n")

    }, error = function(e) {
      cat("    Coral", coral_id, ": ERROR -", e$message, "\n")
    })
  }

  if (length(date_results) > 0) {
    all_results[[date]] <- bind_rows(date_results)
  }
}

# Combine all results
if (length(all_results) > 0) {
  combined_results <- bind_rows(all_results)

  # Apply simple blank correction (use average blank rate)
  # For now, assume blank rate is minimal
  combined_results <- combined_results %>%
    mutate(
      # Convert to hourly rates
      dark_rate_umol_L_hr = dark_rate_umol_L_min * 60,
      light_rate_umol_L_hr = light_rate_umol_L_min * 60,

      # Assume chamber volume of 0.65 L
      dark_rate_umol_hr = dark_rate_umol_L_hr * 0.65,
      light_rate_umol_hr = light_rate_umol_L_hr * 0.65
    )

  # Add treatment labels
  combined_results <- combined_results %>%
    mutate(
      treatment_label = case_when(
        treatment == 0 ~ "Control",
        treatment == 1 ~ "Small Wound",
        treatment == 2 ~ "Large Wound",
        TRUE ~ "Unknown"
      )
    )

  # Save results
  output_file <- "data/processed/respirometry/acropora_rates_simple.csv"
  write_csv(combined_results, output_file)

  cat("\n=== PROCESSING COMPLETE ===\n")
  cat("Results saved to:", output_file, "\n")
  cat("Total corals processed:", nrow(combined_results), "\n")

  # Summary statistics
  cat("\nSummary by timepoint and treatment:\n")
  cat("=====================================\n")
  summary_stats <- combined_results %>%
    group_by(timepoint, treatment_label) %>%
    summarise(
      n = n(),
      mean_dark_rate = mean(dark_rate_umol_L_min, na.rm = TRUE),
      mean_dark_r2 = mean(dark_r2, na.rm = TRUE),
      mean_light_rate = mean(light_rate_umol_L_min, na.rm = TRUE),
      mean_light_r2 = mean(light_r2, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(match(timepoint, c("Pre-wound", "Day 1", "Day 7", "Day 23")), treatment_label)

  print(summary_stats, n = Inf)

  # Quality check
  cat("\nQuality Check (R² < 0.85):\n")
  cat("===========================\n")
  low_quality <- combined_results %>%
    filter(dark_r2 < 0.85 | light_r2 < 0.85) %>%
    select(timepoint, coral_id, treatment_label, dark_r2, light_r2)

  if (nrow(low_quality) > 0) {
    print(low_quality, n = Inf)
  } else {
    cat("All measurements have R² >= 0.85\n")
  }

  # Create simple visualization
  cat("\nCreating visualization...\n")

  # Prepare data for plotting
  plot_data <- combined_results %>%
    filter(!is.na(treatment_label), dark_r2 >= 0.85) %>%
    mutate(
      timepoint = factor(timepoint, levels = c("Pre-wound", "Day 1", "Day 7", "Day 23")),
      days_post_wound = case_when(
        timepoint == "Pre-wound" ~ -1,
        timepoint == "Day 1" ~ 1,
        timepoint == "Day 7" ~ 7,
        timepoint == "Day 23" ~ 23
      )
    )

  # Create plot
  p <- ggplot(plot_data, aes(x = days_post_wound, y = -dark_rate_umol_L_min * 60,
                              color = treatment_label, group = treatment_label)) +
    stat_summary(fun = mean, geom = "line", size = 1) +
    stat_summary(fun = mean, geom = "point", size = 3) +
    stat_summary(fun.data = mean_se, geom = "errorbar", width = 1) +
    scale_color_manual(values = c("Control" = "#2E86AB",
                                   "Small Wound" = "#A23B72",
                                   "Large Wound" = "#F18F01")) +
    labs(
      title = "Acropora pulchra Respiration Rates",
      x = "Days Post-Wounding",
      y = expression("Respiration Rate (µmol O"[2]*" L"^-1*" hr"^-1*")"),
      color = "Treatment"
    ) +
    theme_classic(base_size = 12) +
    theme(
      legend.position = "bottom",
      plot.title = element_text(face = "bold")
    )

  ggsave("reports/Figures/acropora_respiration_timecourse.png", p,
         width = 8, height = 6, dpi = 300, bg = "white")

  cat("Figure saved to: reports/Figures/acropora_respiration_timecourse.png\n")
}

cat("\n✓ Acropora processing complete!\n\n")