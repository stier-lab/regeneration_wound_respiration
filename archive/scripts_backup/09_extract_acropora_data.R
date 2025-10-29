#!/usr/bin/env Rscript
# =============================================================================
# Script: 09_extract_acropora_data.R
# Purpose: Extract Acropora respirometry data from multi-channel run files
# Date: 2023-10-28
# =============================================================================

library(tidyverse)
library(readxl)

cat("\n=== EXTRACTING ACROPORA RESPIROMETRY DATA ===\n\n")

# Read channel mapping file
mapping_file <- "archive/rawdata/Respirometry/trial_datasheets.xlsx"
if (!file.exists(mapping_file)) {
  stop("Channel mapping file not found!")
}

# Define dates and expected runs - CORRECTED based on species mapping
dates <- list(
  "20230526" = c("20230525_run_1", "20230525_run_2"),     # Pre-wound (using May 25 data)
  "20230528" = c("20230528_run_5", "20230528_run_6"),     # Day 1 post-wound
  "20230603" = c("20230603_run_9", "20230603_run_10"),    # Day 7 post-wound
  "20230619" = c("20230619_run_13", "20230619_run_14")    # Day 23 post-wound
)

# Process each date
for (date in names(dates)) {
  cat("\n", date, ":\n", sep = "")
  cat("==================\n")

  # Create Acropora directory if it doesn't exist
  acropora_dir <- paste0("data/raw/respirometry_runs/", date, "/Acropora/")
  if (!dir.exists(acropora_dir)) {
    dir.create(acropora_dir, recursive = TRUE)
    cat("  Created directory:", acropora_dir, "\n")
  }

  runs <- dates[[date]]

  for (run in runs) {
    cat("\nProcessing", run, ":\n")

    # Read mapping for this run
    tryCatch({
      mapping <- read_excel(mapping_file, sheet = run)

      # Filter for Acropora corals (handle both "acr" and "ACR")
      acropora_mapping <- mapping %>%
        filter(tolower(species) == "acr") %>%
        select(probe_chamber, coral_id)

      if (nrow(acropora_mapping) > 0) {
        cat("  Found", nrow(acropora_mapping), "Acropora corals in", run, "\n")

        # Read the run file
        # The run files use the full name from the Excel sheet
        # Special handling for May 25 runs (stored in different location)
        if (grepl("20230525", run)) {
          # May 25 runs are stored under 20230525 directory
          run_file <- paste0("data/raw/respirometry_runs/20230525/", run, ".csv")
        } else {
          # For other dates, look for the file with the sheet name
          # First try the exact sheet name
          run_file <- paste0("data/raw/respirometry_runs/", date, "/", run, ".csv")

          # If that doesn't exist, try extracting the date from the run name
          if (!file.exists(run_file)) {
            run_date <- gsub("_run.*", "", run)
            run_file <- paste0("data/raw/respirometry_runs/", run_date, "/", run, ".csv")
          }
        }
        if (file.exists(run_file)) {
          run_data <- read_csv(run_file, show_col_types = FALSE)

          # Extract data for each Acropora coral
          for (i in 1:nrow(acropora_mapping)) {
            channel <- acropora_mapping$probe_chamber[i]
            coral_id <- acropora_mapping$coral_id[i]

            # Handle blank designation
            if (is.na(coral_id) || coral_id == "" || grepl("blank", tolower(as.character(coral_id)))) {
              # Determine blank number from channel
              blank_num <- ifelse(channel == 0, 0, 1)
              output_file <- paste0(acropora_dir, "blank", blank_num, ".csv")
              coral_label <- paste0("blank", blank_num)
            } else {
              output_file <- paste0(acropora_dir, coral_id, ".csv")
              coral_label <- paste0("Coral ", coral_id)
            }

            # Filter data for this channel
            coral_data <- run_data %>%
              filter(Channel == channel) %>%
              rename(channel = Channel)

            # Write individual coral file
            write_csv(coral_data, output_file)
            cat("    Extracted", coral_label, "(channel", channel, ") →", basename(output_file), "\n")
          }
        } else {
          cat("  WARNING: Run file not found:", run_file, "\n")
        }
      } else {
        cat("  No Acropora corals found in", run, "\n")
      }

    }, error = function(e) {
      cat("  Error reading", run, ":", e$message, "\n")
    })
  }

  # Create blank_id.csv file for this date
  # Assign all corals to blank 1 (based on previous findings about blank 0 issues)
  blank_id_file <- paste0(acropora_dir, "blank_id.csv")

  # Get list of coral files
  coral_files <- list.files(acropora_dir, pattern = "^[0-9]+\\.csv$")
  if (length(coral_files) > 0) {
    coral_ids <- as.numeric(gsub("\\.csv$", "", coral_files))
    blank_assignments <- data.frame(
      coral_id = coral_ids,
      blank_id = 1  # Assign all to blank 1
    )
    write_csv(blank_assignments, blank_id_file)
    cat("\n  Created blank_id.csv with", nrow(blank_assignments), "corals assigned to blank 1\n")
  }
}

# Summary report
cat("\n=== EXTRACTION SUMMARY ===\n")

for (date in names(dates)) {
  acropora_dir <- paste0("data/raw/respirometry_runs/", date, "/Acropora/")
  if (dir.exists(acropora_dir)) {
    files <- list.files(acropora_dir, pattern = "\\.csv$")
    coral_files <- files[grepl("^[0-9]+\\.csv$", files)]
    blank_files <- files[grepl("^blank", files)]

    cat("\n", date, ":\n", sep = "")
    cat("  Coral files:", length(coral_files), "\n")
    if (length(coral_files) > 0) {
      coral_ids <- sort(as.numeric(gsub("\\.csv$", "", coral_files)))
      cat("  Coral IDs:", paste(coral_ids, collapse = ", "), "\n")
    }
    cat("  Blank files:", length(blank_files), "\n")
  }
}

cat("\n=== NEXT STEPS ===\n")
cat("1. Process Acropora data through LoLinR (script 04)\n")
cat("2. Add Acropora to final respirometry analysis (script 06)\n")
cat("3. Update figures to include both species\n")
cat("\n✓ Acropora data extraction complete!\n\n")