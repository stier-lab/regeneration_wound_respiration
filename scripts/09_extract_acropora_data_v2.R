#!/usr/bin/env Rscript
# =============================================================================
# Script: 09_extract_acropora_data_v2.R
# Purpose: Extract Acropora respirometry data from multi-channel run files
# Date: 2023-10-28
# Version 2: Fixed channel filtering issues
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
      # Handle different column names (probe_chamber vs channel_probe)
      if ("probe_chamber" %in% names(mapping)) {
        channel_col <- "probe_chamber"
      } else if ("channel_probe" %in% names(mapping)) {
        channel_col <- "channel_probe"
      } else {
        cat("  WARNING: No channel column found in mapping\n")
        next
      }

      acropora_mapping <- mapping %>%
        filter(tolower(species) == "acr") %>%
        select(all_of(channel_col), coral_id) %>%
        rename(probe_chamber = all_of(channel_col))

      if (nrow(acropora_mapping) > 0) {
        cat("  Found", nrow(acropora_mapping), "Acropora corals in", run, "\n")

        # Determine the run file location
        if (grepl("20230525", run)) {
          # May 25 runs are stored under 20230525 directory
          run_file <- paste0("data/raw/respirometry_runs/20230525/", run, ".csv")
        } else {
          # First try under the target date
          run_file <- paste0("data/raw/respirometry_runs/", date, "/", run, ".csv")

          # If not found, try under the run's own date
          if (!file.exists(run_file)) {
            run_date <- gsub("_run.*", "", run)
            run_file <- paste0("data/raw/respirometry_runs/", run_date, "/", run, ".csv")
          }
        }

        if (file.exists(run_file)) {
          cat("  Reading run file:", run_file, "\n")

          # Read the run file - skip the first row which is metadata
          run_data <- read_csv(run_file, skip = 1, show_col_types = FALSE)

          # Check column names
          if (!"Channel" %in% names(run_data)) {
            cat("  WARNING: No 'Channel' column found in run file\n")
            cat("  Available columns:", paste(names(run_data)[1:10], collapse = ", "), "...\n")
            next
          }

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
              # Convert coral_id to integer to remove decimal points
              coral_id_int <- as.integer(coral_id)
              output_file <- paste0(acropora_dir, coral_id_int, ".csv")
              coral_label <- paste0("Coral ", coral_id_int)
            }

            # Filter data for this channel - ensure channel is numeric
            channel_num <- as.numeric(channel)
            run_data_filtered <- run_data %>%
              mutate(Channel = as.numeric(Channel)) %>%
              filter(Channel == channel_num) %>%
              rename(channel = Channel)

            if (nrow(run_data_filtered) > 0) {
              # Write individual coral file
              write_csv(run_data_filtered, output_file)
              cat("    Extracted", coral_label, "(channel", channel_num, ") →",
                  basename(output_file), "(",  nrow(run_data_filtered), "rows)\n")
            } else {
              cat("    WARNING: No data found for channel", channel_num, "\n")
            }
          }
        } else {
          cat("  WARNING: Run file not found:", run_file, "\n")
        }
      } else {
        cat("  No Acropora corals found in", run, "\n")
      }

    }, error = function(e) {
      cat("  Error processing", run, ":", e$message, "\n")
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