#!/usr/bin/env Rscript
# =============================================================================
# Script: 16_outlier_trace_analysis.R
# Purpose: Analyze oxygen traces for colonies with extreme respiration values
# Date: 2023-10-28
# =============================================================================

library(tidyverse)
library(patchwork)

cat("\n=== OUTLIER TRACE ANALYSIS ===\n")
cat("===============================\n\n")

# Load cleaned data to identify outliers
cleaned_data <- read_csv("data/processed/respirometry/combined_species_cleaned.csv",
                         show_col_types = FALSE)

# Identify extreme values for each species
porites_outliers <- cleaned_data %>%
  filter(species == "Porites spp.") %>%
  group_by(timepoint, treatment_label) %>%
  mutate(
    group_median = median(resp_rate_umol_cm2_hr, na.rm = TRUE),
    deviation = abs(resp_rate_umol_cm2_hr - group_median)
  ) %>%
  ungroup() %>%
  filter(abs(resp_rate_umol_cm2_hr) > 1.5 |
         deviation > 1) %>%
  arrange(desc(abs(resp_rate_umol_cm2_hr)))

acropora_outliers <- cleaned_data %>%
  filter(species == "Acropora pulchra") %>%
  group_by(timepoint, treatment_label) %>%
  mutate(
    group_median = median(resp_rate_umol_cm2_hr, na.rm = TRUE),
    deviation = abs(resp_rate_umol_cm2_hr - group_median)
  ) %>%
  ungroup() %>%
  filter(resp_rate_umol_cm2_hr > 3 |
         deviation > 2) %>%
  arrange(desc(resp_rate_umol_cm2_hr))

cat("=== EXTREME VALUES IDENTIFIED ===\n\n")

if (nrow(porites_outliers) > 0) {
  cat("Porites spp. outliers:\n")
  cat("----------------------\n")
  porites_outliers %>%
    select(coral_id, timepoint, treatment_label,
           resp_rate_umol_cm2_hr, group_median, deviation) %>%
    print()
}

if (nrow(acropora_outliers) > 0) {
  cat("\nAcropora pulchra outliers:\n")
  cat("--------------------------\n")
  acropora_outliers %>%
    select(coral_id, timepoint, treatment_label,
           resp_rate_umol_cm2_hr, group_median, deviation) %>%
    print()
}

# Function to load and analyze a trace
analyze_trace <- function(coral_id, date, species_folder) {
  # Try different file patterns
  possible_files <- c(
    file.path("data/raw/respirometry_runs", date, species_folder, paste0(coral_id, ".csv")),
    file.path("data/raw/respirometry_runs", date, species_folder,
              paste0("coral_", coral_id, "_", species_folder, "_time_series.csv"))
  )

  for (file_path in possible_files) {
    if (file.exists(file_path)) {
      data <- read_csv(file_path, show_col_types = FALSE)

      # Check column names - handle different formats
      if ("time_min" %in% names(data) && "o2_umol_L" %in% names(data)) {
        # Standard format
      } else if ("Time" %in% names(data) && any(grepl("CH", names(data)))) {
        # Multi-channel format - need to extract relevant channel
        # For now, skip these
        return(NULL)
      } else {
        return(NULL)
      }

      # Analyze the trace
      analysis <- list()
      analysis$coral_id <- coral_id
      analysis$date <- date
      analysis$n_points <- nrow(data)

      # Check for jumps
      o2_diff <- diff(data$o2_umol_L)
      analysis$max_jump <- max(abs(o2_diff), na.rm = TRUE)
      analysis$mean_change <- mean(abs(o2_diff), na.rm = TRUE)

      # Check dark phase
      dark_data <- data %>% filter(time_min >= 25, time_min <= 40)
      if (nrow(dark_data) > 10) {
        lm_fit <- lm(o2_umol_L ~ time_min, data = dark_data)
        analysis$dark_slope <- coef(lm_fit)[2]
        analysis$dark_r2 <- summary(lm_fit)$r.squared

        # Check for non-monotonic behavior
        residuals <- residuals(lm_fit)
        analysis$residual_sd <- sd(residuals)
        analysis$max_residual <- max(abs(residuals))
      }

      # Check light phase
      light_data <- data %>% filter(time_min >= 10, time_min <= 25)
      if (nrow(light_data) > 10) {
        lm_fit <- lm(o2_umol_L ~ time_min, data = light_data)
        analysis$light_slope <- coef(lm_fit)[2]
        analysis$light_r2 <- summary(lm_fit)$r.squared
      }

      # Overall O2 range
      analysis$min_o2 <- min(data$o2_umol_L, na.rm = TRUE)
      analysis$max_o2 <- max(data$o2_umol_L, na.rm = TRUE)
      analysis$o2_range <- analysis$max_o2 - analysis$min_o2

      return(as.data.frame(analysis))
    }
  }
  return(NULL)
}

# Map timepoints to dates
timepoint_to_date <- function(timepoint) {
  switch(timepoint,
         "Pre-wound" = "20230526",
         "Day 1" = "20230528",
         "Day 7" = "20230603",
         "Day 23" = "20230619",
         NA)
}

# Analyze traces for outliers
cat("\n=== ANALYZING OUTLIER TRACES ===\n\n")

all_trace_analyses <- list()

# Analyze Porites outliers
if (nrow(porites_outliers) > 0) {
  cat("Analyzing Porites traces...\n")
  for (i in 1:nrow(porites_outliers)) {
    row <- porites_outliers[i,]
    date <- timepoint_to_date(row$timepoint)
    if (!is.na(date)) {
      analysis <- analyze_trace(row$coral_id, date, "Porites")
      if (!is.null(analysis)) {
        analysis$species <- "Porites spp."
        analysis$resp_rate <- row$resp_rate_umol_cm2_hr
        analysis$timepoint <- row$timepoint
        all_trace_analyses[[length(all_trace_analyses) + 1]] <- analysis
      }
    }
  }
}

# Analyze Acropora outliers
if (nrow(acropora_outliers) > 0) {
  cat("Analyzing Acropora traces...\n")
  for (i in 1:nrow(acropora_outliers)) {
    row <- acropora_outliers[i,]
    date <- timepoint_to_date(row$timepoint)
    if (!is.na(date)) {
      analysis <- analyze_trace(row$coral_id, date, "Acropora")
      if (!is.null(analysis)) {
        analysis$species <- "Acropora pulchra"
        analysis$resp_rate <- row$resp_rate_umol_cm2_hr
        analysis$timepoint <- row$timepoint
        all_trace_analyses[[length(all_trace_analyses) + 1]] <- analysis
      }
    }
  }
}

# Combine and display results
if (length(all_trace_analyses) > 0) {
  trace_results <- bind_rows(all_trace_analyses)

  cat("\n=== TRACE ANALYSIS RESULTS ===\n\n")

  # Identify potential probe issues
  probe_issues <- trace_results %>%
    filter(
      max_jump > 20 |                    # Large sudden jumps
      dark_r2 < 0.85 |                   # Poor linear fit in dark
      residual_sd > 10 |                 # High variability around linear fit
      o2_range > 150 |                   # Unrealistic O2 range
      abs(dark_slope) > 5               # Unrealistic respiration rate
    )

  if (nrow(probe_issues) > 0) {
    cat("POTENTIAL PROBE ISSUES DETECTED:\n")
    cat("--------------------------------\n")
    probe_issues %>%
      select(species, coral_id, timepoint, resp_rate, dark_r2,
             max_jump, residual_sd, dark_slope) %>%
      mutate(across(where(is.numeric), ~round(., 3))) %>%
      print()

    cat("\nRECOMMENDATIONS:\n")
    cat("- Corals with dark_r2 < 0.85: Poor linear fit suggests measurement issues\n")
    cat("- Corals with max_jump > 20: Likely probe disconnection/reconnection\n")
    cat("- Corals with |dark_slope| > 5: Physiologically unrealistic rates\n")
    cat("- Consider excluding these measurements from final analysis\n")

    # Save problematic traces
    write_csv(probe_issues, "data/processed/respirometry/probe_issue_traces.csv")
    cat("\nProblematic traces saved to: data/processed/respirometry/probe_issue_traces.csv\n")
  } else {
    cat("No obvious probe issues detected in outlier traces.\n")
    cat("High values may be biological variation rather than measurement error.\n")
  }

  # Save all trace analyses
  write_csv(trace_results, "data/processed/respirometry/outlier_trace_analysis.csv")

} else {
  cat("Could not analyze traces - files may be in different format.\n")
}

# Create visualization of outliers vs normal range
cat("\n=== CREATING OUTLIER VISUALIZATION ===\n")

pdf(NULL) # Suppress automatic plot output

p1 <- ggplot(cleaned_data %>% filter(species == "Porites spp."),
             aes(x = interaction(timepoint, treatment_label),
                 y = resp_rate_umol_cm2_hr)) +
  geom_boxplot(aes(fill = treatment_label), alpha = 0.6) +
  geom_point(data = porites_outliers,
             aes(x = interaction(timepoint, treatment_label)),
             color = "red", size = 3) +
  scale_fill_manual(values = c("Control" = "#2E86AB",
                               "Small Wound" = "#A23B72",
                               "Large Wound" = "#F18F01")) +
  labs(title = "Porites spp. - Outlier Identification",
       subtitle = "Red points indicate potential measurement issues",
       x = "Timepoint.Treatment",
       y = expression("Respiration Rate (µmol O"[2]*" cm"^{-2}*" hr"^{-1}*")")) +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom")

p2 <- ggplot(cleaned_data %>% filter(species == "Acropora pulchra"),
             aes(x = interaction(timepoint, treatment_label),
                 y = resp_rate_umol_cm2_hr)) +
  geom_boxplot(aes(fill = treatment_label), alpha = 0.6) +
  geom_point(data = acropora_outliers,
             aes(x = interaction(timepoint, treatment_label)),
             color = "red", size = 3) +
  scale_fill_manual(values = c("Control" = "#2E86AB",
                               "Small Wound" = "#A23B72",
                               "Large Wound" = "#F18F01")) +
  labs(title = "Acropora pulchra - Outlier Identification",
       subtitle = "Red points indicate potential measurement issues",
       x = "Timepoint.Treatment",
       y = expression("Respiration Rate (µmol O"[2]*" cm"^{-2}*" hr"^{-1}*")")) +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom")

combined_plot <- p1 / p2

ggsave("figures/outlier_identification.png", combined_plot,
       width = 12, height = 10, dpi = 300)

cat("\nOutlier visualization saved to: figures/outlier_identification.png\n")
cat("\n✓ Outlier trace analysis complete!\n")