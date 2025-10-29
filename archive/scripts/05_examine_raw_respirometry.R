#!/usr/bin/env Rscript
# =============================================================================
# Script: 05_examine_raw_respirometry.R
# Purpose: Visualize and examine raw respirometry data files for quality control
# Author: Regeneration Wound Respiration Project
# Date: 2023-10-27
# =============================================================================

# Load required libraries -----------------------------------------------------
suppressPackageStartupMessages({
  library(tidyverse)
  library(viridis)
  library(patchwork)
  library(lubridate)
})

# Suppress default plotting to avoid Rplots.pdf
pdf(NULL)

# Define constants and color scheme -------------------------------------------
treatment_colors <- c("0" = "#2E86AB", "1" = "#A23B72", "2" = "#F18F01")
treatment_labels <- c("0" = "Control", "1" = "Small Wound", "2" = "Large Wound")

# Define phase boundaries (in minutes)
DARK_START <- 25  # Dark phase starts after 25 minutes
LIGHT_START <- 10  # Light phase starts at 10 minutes
LIGHT_END <- 25   # Light phase ends at 25 minutes

# Function to read raw respirometry file --------------------------------------
read_raw_resp <- function(filepath) {
  data <- read_csv(filepath, show_col_types = FALSE)

  # Extract coral_id from filename
  coral_id <- str_extract(basename(filepath), "\\d+") %>% as.numeric()

  # Add metadata
  data <- data %>%
    mutate(
      coral_id = coral_id,
      time_min = as.numeric(delta_t),
      o2_umol_L = value,  # Already in umol/L based on data
      phase = case_when(
        time_min >= DARK_START ~ "Dark (Respiration)",
        time_min >= LIGHT_START & time_min < LIGHT_END ~ "Light (Photosynthesis)",
        TRUE ~ "Acclimation"
      )
    )

  return(data)
}

# Function to calculate rates using linear regression -------------------------
calculate_rate <- function(data, phase_type = "Dark") {
  if (phase_type == "Dark") {
    phase_data <- data %>% filter(time_min >= DARK_START)
  } else if (phase_type == "Light") {
    phase_data <- data %>% filter(time_min >= LIGHT_START & time_min < LIGHT_END)
  } else {
    phase_data <- data
  }

  if (nrow(phase_data) < 10) {
    return(list(rate = NA, r2 = NA, n_points = nrow(phase_data)))
  }

  # Fit linear model
  model <- lm(o2_umol_L ~ time_min, data = phase_data)

  return(list(
    rate = coef(model)[2],  # slope in umol/L/min
    r2 = summary(model)$r.squared,
    n_points = nrow(phase_data),
    model = model
  ))
}

# Function to process all files from a timepoint ------------------------------
process_timepoint <- function(date, genus = "Porites") {
  dir_path <- file.path("data/raw/respirometry_runs", date, genus)

  if (!dir.exists(dir_path)) {
    cat("Directory not found:", dir_path, "\n")
    return(NULL)
  }

  # Load sample info once
  sample_info <- read_csv("data/metadata/sample_info.csv", show_col_types = FALSE)

  # Get all CSV files
  csv_files <- list.files(dir_path, pattern = "\\.csv$", full.names = TRUE)

  # Read and process each file
  all_data <- list()
  for (file in csv_files) {
    coral_id <- str_extract(basename(file), "\\d+") %>% as.numeric()

    # Skip if not a valid coral file
    if (is.na(coral_id)) next

    data <- read_raw_resp(file)

    # Determine treatment
    if (coral_id %in% c(0, 1)) {
      treatment <- "Blank"
    } else {
      # Map genus name
      genus_mapped <- if (tolower(genus) == "porites") "por" else "acr"

      treatment_val <- sample_info %>%
        filter(coral_id == !!coral_id, genus == genus_mapped) %>%
        pull(treatment)

      if (length(treatment_val) == 0) {
        treatment <- "Unknown"
      } else {
        treatment <- as.character(treatment_val[1])
      }
    }

    data <- data %>%
      mutate(
        date = date,
        genus = genus,
        treatment = treatment
      )

    all_data[[as.character(coral_id)]] <- data
  }

  if (length(all_data) > 0) {
    combined_data <- bind_rows(all_data)
    return(combined_data)
  } else {
    return(NULL)
  }
}

# Main analysis ----------------------------------------------------------------
cat("\n=== EXAMINING RAW RESPIROMETRY DATA ===\n\n")

# Define timepoints
timepoints <- c("20230526", "20230528", "20230603", "20230619")
timepoint_labels <- c(
  "20230526" = "Pre-wound",
  "20230528" = "Day 1",
  "20230603" = "Day 7",
  "20230619" = "Day 23"
)

# Process all timepoints
all_timepoint_data <- list()
rate_summary <- list()

for (tp in timepoints) {
  cat("Processing", timepoint_labels[tp], "(", tp, ")...\n")

  data <- process_timepoint(tp, "Porites")

  if (!is.null(data)) {
    all_timepoint_data[[tp]] <- data

    # Calculate rates for each coral
    coral_ids <- unique(data$coral_id)

    for (cid in coral_ids) {
      coral_data <- data %>% filter(coral_id == cid)

      # Calculate dark phase rate
      dark_rate <- calculate_rate(coral_data, "Dark")

      # Calculate light phase rate
      light_rate <- calculate_rate(coral_data, "Light")

      # Store summary
      rate_summary[[paste0(tp, "_", cid)]] <- tibble(
        date = tp,
        timepoint = timepoint_labels[tp],
        coral_id = cid,
        treatment = unique(coral_data$treatment),
        dark_rate_umol_L_min = dark_rate$rate,
        dark_r2 = dark_rate$r2,
        dark_n = dark_rate$n_points,
        light_rate_umol_L_min = light_rate$rate,
        light_r2 = light_rate$r2,
        light_n = light_rate$n_points
      )
    }

    cat("  - Processed", length(coral_ids), "coral files\n")
  } else {
    cat("  - No data found\n")
  }
}

# Combine all data
all_data <- bind_rows(all_timepoint_data)
rate_table <- bind_rows(rate_summary)

# Check if we have data
if(length(all_timepoint_data) == 0) {
  stop("No data found in any timepoint!")
}

# Add timepoint factor for proper ordering
all_data <- all_data %>%
  mutate(
    timepoint_label = case_when(
      date == "20230526" ~ "Pre-wound",
      date == "20230528" ~ "Day 1",
      date == "20230603" ~ "Day 7",
      date == "20230619" ~ "Day 23",
      TRUE ~ as.character(date)
    ),
    timepoint = factor(timepoint_label,
                      levels = c("Pre-wound", "Day 1", "Day 7", "Day 23"))
  )

# Check the timepoint column
cat("\nTimepoint values in data:\n")
print(table(all_data$timepoint, useNA = "always"))

rate_table <- rate_table %>%
  mutate(
    timepoint = factor(timepoint,
                      levels = c("Pre-wound", "Day 1", "Day 7", "Day 23"))
  )

cat("\n=== CREATING DIAGNOSTIC FIGURES ===\n\n")

# Filter out any NA timepoints and blanks
plot_data <- all_data %>%
  filter(!is.na(timepoint), treatment != "Blank")

cat("Data summary before filtering:\n")
cat("  Total rows:", nrow(all_data), "\n")
cat("  Unique treatments in all_data:", paste(unique(all_data$treatment), collapse = ", "), "\n")

cat("\nData summary for plotting:\n")
cat("  Total rows:", nrow(plot_data), "\n")
cat("  Unique timepoints:", paste(unique(plot_data$timepoint), collapse = ", "), "\n")
cat("  Unique treatments:", paste(unique(plot_data$treatment), collapse = ", "), "\n\n")

# Figure 1: Raw O2 traces for all corals by timepoint -------------------------
cat("Creating Figure 1: Raw O2 traces...\n")

p1 <- ggplot(plot_data,
             aes(x = time_min, y = o2_umol_L, color = treatment, group = coral_id)) +
  geom_line(alpha = 0.5, linewidth = 0.7) +
  geom_vline(xintercept = c(LIGHT_START, LIGHT_END),
             linetype = "dashed", alpha = 0.3) +
  annotate("rect", xmin = LIGHT_START, xmax = LIGHT_END,
           ymin = -Inf, ymax = Inf, alpha = 0.1, fill = "yellow") +
  annotate("rect", xmin = DARK_START, xmax = Inf,
           ymin = -Inf, ymax = Inf, alpha = 0.1, fill = "grey20") +
  facet_wrap(~timepoint, scales = "free_y", nrow = 2) +
  scale_color_manual(values = treatment_colors, labels = treatment_labels) +
  labs(
    title = "Raw O2 Concentrations Over Time - All Corals",
    subtitle = "Yellow = Light phase (photosynthesis), Grey = Dark phase (respiration)",
    x = "Time (minutes)",
    y = expression(paste("O"[2], " Concentration (µmol/L)")),
    color = "Treatment"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.border = element_rect(color = "black", fill = NA)
  )

ggsave("reports/Figures/raw_o2_traces_all.png", p1,
       width = 14, height = 8, dpi = 300, bg = "white")

# Figure 2: Separate plots for blanks ------------------------------------------
cat("Creating Figure 2: Blank chamber O2 traces...\n")

blank_data <- all_data %>% filter(treatment == "Blank")

if (nrow(blank_data) > 0) {
  p2 <- ggplot(blank_data,
               aes(x = time_min, y = o2_umol_L, color = as.factor(coral_id))) +
    geom_line(linewidth = 1) +
    geom_vline(xintercept = c(LIGHT_START, LIGHT_END),
               linetype = "dashed", alpha = 0.3) +
    annotate("rect", xmin = LIGHT_START, xmax = LIGHT_END,
             ymin = -Inf, ymax = Inf, alpha = 0.1, fill = "yellow") +
    annotate("rect", xmin = DARK_START, xmax = Inf,
             ymin = -Inf, ymax = Inf, alpha = 0.1, fill = "grey20") +
    facet_wrap(~timepoint, scales = "free_y", nrow = 2) +
    scale_color_brewer(palette = "Set1", name = "Blank ID") +
    labs(
      title = "Blank Chamber O2 Concentrations",
      subtitle = "Should show minimal O2 change or slight decrease (microbial respiration)",
      x = "Time (minutes)",
      y = expression(paste("O"[2], " Concentration (µmol/L)"))
    ) +
    theme_classic(base_size = 12) +
    theme(
      legend.position = "bottom",
      panel.border = element_rect(color = "black", fill = NA)
    )

  ggsave("reports/Figures/raw_o2_blanks.png", p2,
         width = 12, height = 8, dpi = 300, bg = "white")
}

# Figure 3: Phase-specific rate distributions ----------------------------------
cat("Creating Figure 3: Rate distributions by phase...\n")

# Prepare rate data for plotting
rate_long <- rate_table %>%
  filter(treatment != "Blank") %>%
  pivot_longer(cols = c(dark_rate_umol_L_min, light_rate_umol_L_min),
               names_to = "phase", values_to = "rate") %>%
  mutate(
    phase = ifelse(str_detect(phase, "dark"), "Dark (Respiration)", "Light (Photosynthesis)"),
    rate_umol_L_hr = rate * 60  # Convert to per hour
  )

p3 <- ggplot(rate_long %>% filter(!is.na(rate)),
             aes(x = treatment, y = rate_umol_L_hr, fill = treatment)) +
  geom_boxplot(alpha = 0.7, outlier.shape = 21) +
  geom_jitter(width = 0.2, alpha = 0.4, size = 2) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  facet_grid(phase ~ timepoint, scales = "free_y") +
  scale_fill_manual(values = treatment_colors, labels = treatment_labels) +
  labs(
    title = "O2 Exchange Rates by Phase and Timepoint",
    subtitle = "Negative = O2 consumption, Positive = O2 production",
    x = "Treatment",
    y = expression(paste("Rate (µmol O"[2], " L"^-1, " hr"^-1, ")")),
    fill = "Treatment"
  ) +
  theme_classic(base_size = 11) +
  theme(
    legend.position = "bottom",
    panel.border = element_rect(color = "black", fill = NA),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave("reports/Figures/rate_distributions_by_phase.png", p3,
       width = 14, height = 8, dpi = 300, bg = "white")

# Figure 4: R-squared quality check --------------------------------------------
cat("Creating Figure 4: Linear fit quality (R²)...\n")

# Prepare R² data
r2_long <- rate_table %>%
  filter(treatment != "Blank") %>%
  pivot_longer(cols = c(dark_r2, light_r2),
               names_to = "phase", values_to = "r2") %>%
  mutate(
    phase = ifelse(str_detect(phase, "dark"), "Dark", "Light")
  )

p4 <- ggplot(r2_long %>% filter(!is.na(r2)),
             aes(x = timepoint, y = r2, fill = phase)) +
  geom_boxplot(alpha = 0.7) +
  geom_hline(yintercept = 0.9, linetype = "dashed", color = "red", alpha = 0.5) +
  facet_wrap(~treatment, labeller = labeller(treatment = treatment_labels)) +
  scale_fill_manual(values = c("Dark" = "grey30", "Light" = "gold")) +
  labs(
    title = "Linear Regression Fit Quality (R²)",
    subtitle = "Values > 0.9 indicate good linear fits; red line = 0.9",
    x = "Timepoint",
    y = "R²",
    fill = "Phase"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.border = element_rect(color = "black", fill = NA),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave("reports/Figures/rate_fit_quality.png", p4,
       width = 10, height = 6, dpi = 300, bg = "white")

# Figure 5: Individual coral traces for one timepoint -------------------------
cat("Creating Figure 5: Individual coral traces (Day 7)...\n")

# Focus on Day 7 for detailed view
day7_data <- all_data %>%
  filter(date == "20230603", treatment != "Blank")

if (nrow(day7_data) > 0) {
  p5 <- ggplot(day7_data, aes(x = time_min, y = o2_umol_L)) +
    geom_line(aes(color = phase), linewidth = 0.8) +
    geom_smooth(data = day7_data %>% filter(time_min >= DARK_START),
                method = "lm", se = TRUE, color = "red", linewidth = 0.5, alpha = 0.2) +
    geom_smooth(data = day7_data %>% filter(time_min >= LIGHT_START & time_min < LIGHT_END),
                method = "lm", se = TRUE, color = "blue", linewidth = 0.5, alpha = 0.2) +
    facet_wrap(~paste0("Coral ", coral_id, " (", treatment, ")"),
               scales = "free_y", ncol = 6) +
    scale_color_manual(values = c("Acclimation" = "grey50",
                                  "Light (Photosynthesis)" = "gold",
                                  "Dark (Respiration)" = "grey20")) +
    labs(
      title = "Individual Coral O2 Traces - Day 7 Post-Wounding",
      subtitle = "Red = respiration regression, Blue = photosynthesis regression",
      x = "Time (minutes)",
      y = expression(paste("O"[2], " (µmol/L)")),
      color = "Phase"
    ) +
    theme_classic(base_size = 10) +
    theme(
      legend.position = "bottom",
      strip.text = element_text(size = 8),
      panel.border = element_rect(color = "black", fill = NA)
    )

  ggsave("reports/Figures/individual_coral_traces_day7.png", p5,
         width = 16, height = 10, dpi = 300, bg = "white")
}

# Generate summary statistics --------------------------------------------------
cat("\n=== SUMMARY STATISTICS ===\n\n")

# Overall rate summary by treatment and timepoint
rate_summary_stats <- rate_table %>%
  filter(treatment != "Blank", treatment != "Unknown") %>%
  group_by(timepoint, treatment) %>%
  summarize(
    n = n(),
    # Dark phase (respiration)
    mean_resp_rate = mean(dark_rate_umol_L_min * 60, na.rm = TRUE),
    sd_resp_rate = sd(dark_rate_umol_L_min * 60, na.rm = TRUE),
    mean_resp_r2 = mean(dark_r2, na.rm = TRUE),
    # Light phase (photosynthesis)
    mean_photo_rate = mean(light_rate_umol_L_min * 60, na.rm = TRUE),
    sd_photo_rate = sd(light_rate_umol_L_min * 60, na.rm = TRUE),
    mean_photo_r2 = mean(light_r2, na.rm = TRUE),
    .groups = "drop"
  )

cat("Mean rates by treatment and timepoint (µmol/L/hr):\n")
print(rate_summary_stats)

# Check for problematic measurements
cat("\n=== DATA QUALITY CHECKS ===\n\n")

# Check for low R² values
low_r2 <- rate_table %>%
  filter(treatment != "Blank") %>%
  filter(dark_r2 < 0.8 | light_r2 < 0.8) %>%
  select(timepoint, coral_id, treatment, dark_r2, light_r2)

if (nrow(low_r2) > 0) {
  cat("WARNING: Corals with poor linear fits (R² < 0.8):\n")
  print(low_r2)
} else {
  cat("✓ All measurements have good linear fits (R² > 0.8)\n")
}

# Check for unusual rates
unusual_rates <- rate_table %>%
  filter(treatment != "Blank") %>%
  mutate(
    resp_rate_hr = dark_rate_umol_L_min * 60,
    photo_rate_hr = light_rate_umol_L_min * 60
  ) %>%
  filter(
    resp_rate_hr > 0 |  # Respiration should be negative
    photo_rate_hr < -10  # Photosynthesis should be positive or slightly negative
  ) %>%
  select(timepoint, coral_id, treatment, resp_rate_hr, photo_rate_hr)

if (nrow(unusual_rates) > 0) {
  cat("\nWARNING: Corals with unusual rates:\n")
  print(unusual_rates)
} else {
  cat("✓ All rates are within expected ranges\n")
}

# Check blanks
blank_rates <- rate_table %>%
  filter(treatment == "Blank") %>%
  mutate(
    resp_rate_hr = dark_rate_umol_L_min * 60,
    photo_rate_hr = light_rate_umol_L_min * 60
  )

if (nrow(blank_rates) > 0) {
  cat("\nBlank chamber rates (should be near zero or slightly negative):\n")
  print(blank_rates %>% select(timepoint, coral_id, resp_rate_hr, photo_rate_hr))
}

# Save summary table
write_csv(rate_table, "data/processed/respirometry/rate_summary_diagnostic.csv")
cat("\n✓ Rate summary table saved to: data/processed/respirometry/rate_summary_diagnostic.csv\n")

# Create final summary plot ----------------------------------------------------
cat("\nCreating Figure 6: Summary overview...\n")

# Prepare data for summary
summary_plot_data <- rate_table %>%
  filter(treatment != "Blank", treatment != "Unknown") %>%
  mutate(
    resp_rate_hr = dark_rate_umol_L_min * 60,
    photo_rate_hr = light_rate_umol_L_min * 60,
    p_to_r = abs(photo_rate_hr / resp_rate_hr)
  )

# Panel A: Respiration rates
p6a <- ggplot(summary_plot_data,
              aes(x = timepoint, y = resp_rate_hr, fill = treatment)) +
  geom_boxplot(alpha = 0.7, position = position_dodge(0.8)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  scale_fill_manual(values = treatment_colors, labels = treatment_labels) +
  labs(
    title = "A. Respiration Rates (Dark Phase)",
    x = "",
    y = expression(paste("Rate (µmol O"[2], " L"^-1, " hr"^-1, ")")),
    fill = "Treatment"
  ) +
  theme_classic(base_size = 11) +
  theme(legend.position = "none")

# Panel B: Photosynthesis rates
p6b <- ggplot(summary_plot_data,
              aes(x = timepoint, y = photo_rate_hr, fill = treatment)) +
  geom_boxplot(alpha = 0.7, position = position_dodge(0.8)) +
  geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.5) +
  scale_fill_manual(values = treatment_colors, labels = treatment_labels) +
  labs(
    title = "B. Photosynthesis Rates (Light Phase)",
    x = "",
    y = expression(paste("Rate (µmol O"[2], " L"^-1, " hr"^-1, ")")),
    fill = "Treatment"
  ) +
  theme_classic(base_size = 11) +
  theme(legend.position = "none")

# Panel C: P:R ratios
p6c <- ggplot(summary_plot_data %>% filter(!is.infinite(p_to_r)),
              aes(x = timepoint, y = p_to_r, fill = treatment)) +
  geom_boxplot(alpha = 0.7, position = position_dodge(0.8)) +
  geom_hline(yintercept = 1, linetype = "dashed", alpha = 0.5, color = "red") +
  scale_fill_manual(values = treatment_colors, labels = treatment_labels) +
  labs(
    title = "C. P:R Ratios",
    subtitle = "Values > 1 indicate net autotrophy",
    x = "Timepoint",
    y = "P:R Ratio",
    fill = "Treatment"
  ) +
  theme_classic(base_size = 11) +
  theme(legend.position = "bottom")

# Combine panels
p6 <- p6a / p6b / p6c +
  plot_layout(heights = c(1, 1, 1.2))

ggsave("reports/Figures/respirometry_summary_overview.png", p6,
       width = 10, height = 12, dpi = 300, bg = "white")

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("\nGenerated figures:\n")
cat("1. reports/Figures/raw_o2_traces_all.png - Raw O2 traces for all corals\n")
cat("2. reports/Figures/raw_o2_blanks.png - Blank chamber traces\n")
cat("3. reports/Figures/rate_distributions_by_phase.png - Rate distributions\n")
cat("4. reports/Figures/rate_fit_quality.png - R² quality metrics\n")
cat("5. reports/Figures/individual_coral_traces_day7.png - Individual coral details\n")
cat("6. reports/Figures/respirometry_summary_overview.png - Summary overview\n")
cat("\nData file:\n")
cat("- data/processed/respirometry/rate_summary_diagnostic.csv\n")