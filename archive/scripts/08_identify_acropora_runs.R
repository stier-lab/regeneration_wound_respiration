#!/usr/bin/env Rscript
# =============================================================================
# Script: 08_identify_acropora_runs.R
# Purpose: Identify which respirometry runs contain Acropora data
# Date: 2023-10-28
# =============================================================================

library(tidyverse)

cat("\n=== IDENTIFYING ACROPORA RESPIROMETRY RUNS ===\n\n")

# Analysis logic:
# - Both species have coral IDs 41-58 (18 corals each)
# - 10 channels per run (0-9 typically, with 0-1 as blanks)
# - 18 corals + 2 blanks = 20 spots needed per species
# - Therefore need 2 runs per species (20 spots)

# For dates with 4 runs (May 28, June 3, June 19):
# - Runs should be split: 2 for Porites, 2 for Acropora

# Check existing Porites data to identify which runs were used
dates <- c("20230528", "20230603", "20230619")

for (date in dates) {
  cat("\n", date, ":\n", sep = "")
  cat("-----------------\n")

  # Check which channels Porites corals are in
  porites_dir <- paste0("data/raw/respirometry_runs/", date, "/Porites/")

  if (dir.exists(porites_dir)) {
    # Read a Porites coral file to get channel info
    sample_file <- paste0(porites_dir, "41.csv")

    if (file.exists(sample_file)) {
      sample_data <- read_csv(sample_file, show_col_types = FALSE)
      channel_used <- unique(sample_data$channel)[1]

      cat("  Porites coral 41 uses channel:", channel_used, "\n")

      # Check all run files to see which contain this channel at the right time
      run_files <- list.files(paste0("data/raw/respirometry_runs/", date),
                             pattern = "run.*\\.csv", full.names = TRUE)

      cat("  Available run files:", length(run_files), "\n")

      for (run_file in run_files) {
        # Read just the first 100 lines to check channels
        run_data <- read_csv(run_file, n_max = 100, show_col_types = FALSE,
                           col_types = cols(.default = "c"))

        if ("Channel" %in% names(run_data)) {
          channels_in_run <- unique(run_data$Channel)
          run_name <- basename(run_file)
          cat("    ", run_name, "has channels:",
              paste(sort(as.numeric(channels_in_run)), collapse = ", "), "\n")
        }
      }
    }
  }
}

cat("\n=== HYPOTHESIS ===\n")
cat("Based on 4 runs per post-wound date and 2 species:\n")
cat("- Each species likely uses 2 runs (20 channels total)\n")
cat("- Porites appears to use lower-numbered runs\n")
cat("- Acropora likely uses higher-numbered runs\n\n")

# Proposed assignment
cat("Proposed Run Assignments:\n")
cat("-------------------------\n")
cat("May 26 (Pre-wound): Runs 3-4 = Porites only\n")
cat("May 28 (Day 1):     Runs 5-6 = Porites, Runs 7-8 = Acropora\n")
cat("June 3 (Day 7):     Runs 9-10 = Porites, Runs 11-12 = Acropora\n")
cat("June 19 (Day 23):   Runs 13-14 = Porites, Runs 15-16 = Acropora\n")

cat("\n=== NEXT STEPS ===\n")
cat("1. Verify this hypothesis by checking channel assignments\n")
cat("2. Create extraction script for Acropora runs\n")
cat("3. Process through LoLinR for rate calculations\n")