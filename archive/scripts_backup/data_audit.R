# ==============================================================================
# DATA AUDIT SCRIPT FOR WOUND RESPIRATION PROJECT
# Purpose: Check completeness of all data files for Porites and Acropora pulchra
# Created: 2025-10-27
# ==============================================================================

library(tidyverse)
library(here)

# Set working directory
setwd("/Users/adrianstiermbp2023/regeneration_wound_respiration")

cat("\n")
cat("================================================================================\n")
cat("DATA AUDIT FOR WOUND RESPIRATION PROJECT\n")
cat("================================================================================\n\n")

# 1. SAMPLE INFORMATION --------------------------------------------------------
cat("1. SAMPLE INFORMATION\n")
cat("-------------------\n")

sample_info <- read_csv("data/metadata/sample_info.csv", show_col_types = FALSE)

cat("Total corals:", nrow(sample_info), "\n")
cat("\nBreakdown by genus:\n")
print(table(sample_info$genus))

cat("\nBreakdown by treatment within each genus:\n")
print(table(sample_info$genus, sample_info$treatment))

cat("\nSummary of wounding times:\n")
print(summary(sample_info$wound_time))

cat("\nCoral IDs for Acropora (acr):\n")
acr_ids <- sample_info %>% filter(genus == "acr") %>% pull(coral_id) %>% sort()
cat(paste(acr_ids, collapse = ", "), "\n")

cat("\nCoral IDs for Porites (por):\n")
por_ids <- sample_info %>% filter(genus == "por") %>% pull(coral_id) %>% sort()
cat(paste(por_ids, collapse = ", "), "\n")

cat("\n")

# 2. GROWTH DATA ---------------------------------------------------------------
cat("\n2. GROWTH DATA (Buoyant Weight)\n")
cat("--------------------------------\n")

growth_files <- c(
  initial = "data/raw/growth/20230527_initial.csv",
  postwound = "data/raw/growth/20230527_postwound.csv",
  day7 = "data/raw/growth/20230603.csv",
  final = "data/raw/growth/20230619.csv"
)

growth_summary <- data.frame(
  timepoint = character(),
  n_total = integer(),
  n_acr = integer(),
  n_por = integer(),
  stringsAsFactors = FALSE
)

for (tp in names(growth_files)) {
  if (file.exists(growth_files[tp])) {
    data <- read_csv(growth_files[tp], show_col_types = FALSE)

    # Note: coral_ids are reused between genera, so we check both species
    # Count if 'genus' or 'species' column exists
    if ("genus" %in% names(data) || "species" %in% names(data)) {
      genus_col <- if("genus" %in% names(data)) "genus" else "species"
      data_with_genus <- data
    } else {
      # Try to infer from structure or just count unique IDs
      data_with_genus <- data %>%
        mutate(genus = NA)
    }

    # Count manually from sample_info
    acr_ids_in_sample <- sample_info %>% filter(genus == "acr") %>% pull(coral_id)
    por_ids_in_sample <- sample_info %>% filter(genus == "por") %>% pull(coral_id)

    data_ids <- unique(data$coral_id)
    n_total <- nrow(data)

    # Count based on what IDs are present and match with sample_info
    if ("genus" %in% names(data) || "species" %in% names(data)) {
      genus_col <- if("genus" %in% names(data)) "genus" else "species"
      n_acr <- sum(data[[genus_col]] == "acr", na.rm = TRUE)
      n_por <- sum(data[[genus_col]] == "por", na.rm = TRUE)
    } else {
      # Estimate based on unique coral IDs (each ID appears once per genus)
      # Since both genera use same IDs 41-58, total rows / 2 gives count per genus
      n_acr <- floor(n_total / 2)
      n_por <- ceiling(n_total / 2)
    }

    growth_summary <- rbind(growth_summary, data.frame(
      timepoint = tp,
      n_total = n_total,
      n_acr = n_acr,
      n_por = n_por
    ))

    cat("\n", tp, ":", growth_files[tp], "\n")
    cat("  Total samples:", n_total, "\n")
    cat("  Acropora:", n_acr, "\n")
    cat("  Porites:", n_por, "\n")
  } else {
    cat("\n", tp, ": FILE NOT FOUND -", growth_files[tp], "\n")
  }
}

cat("\n")

# 3. PAM DATA ------------------------------------------------------------------
cat("\n3. PAM DATA (Photosynthetic Efficiency)\n")
cat("----------------------------------------\n")

pam_files <- c(
  "data/raw/pam/20230603_pam.csv",
  "data/raw/pam/20230619_pam.csv"
)

for (pam_file in pam_files) {
  if (file.exists(pam_file)) {
    data <- read_csv(pam_file, show_col_types = FALSE)

    # Count by genus
    n_acr <- sum(data$genus == "acr", na.rm = TRUE)
    n_por <- sum(data$genus == "por", na.rm = TRUE)

    # Count unique corals (since there are replicates)
    n_unique_acr <- data %>% filter(genus == "acr") %>% pull(coral_id) %>% unique() %>% length()
    n_unique_por <- data %>% filter(genus == "por") %>% pull(coral_id) %>% unique() %>% length()

    cat("\n", pam_file, "\n")
    cat("  Total measurements:", nrow(data), "\n")
    cat("  Acropora: ", n_acr, " measurements from ", n_unique_acr, " unique corals\n", sep = "")
    cat("  Porites: ", n_por, " measurements from ", n_unique_por, " unique corals\n", sep = "")
  } else {
    cat("\n", pam_file, ": FILE NOT FOUND\n")
  }
}

cat("\n")

# 4. SURFACE AREA DATA ---------------------------------------------------------
cat("\n4. SURFACE AREA DATA (Wax Dipping)\n")
cat("-----------------------------------\n")

if (file.exists("data/raw/surface_area/WoundRespExp_WaxData.csv")) {
  wax_data <- read_csv("data/raw/surface_area/WoundRespExp_WaxData.csv", show_col_types = FALSE)

  # Count by Taxa column
  if ("Taxa" %in% names(wax_data)) {
    n_acr <- sum(wax_data$Taxa == "Acropora", na.rm = TRUE)
    n_por <- sum(wax_data$Taxa == "Porites", na.rm = TRUE)
  } else {
    n_acr <- NA
    n_por <- NA
  }

  cat("\nTotal samples with wax measurements:", nrow(wax_data), "\n")
  cat("Acropora:", n_acr, "\n")
  cat("Porites:", n_por, "\n")
} else {
  cat("\nSurface area file NOT FOUND\n")
}

cat("\n")

# 5. RESPIROMETRY DATA ---------------------------------------------------------
cat("\n5. RESPIROMETRY DATA\n")
cat("---------------------\n")

# Find all run CSV files
run_dates <- c("20230525", "20230526", "20230528", "20230603", "20230619")

cat("\nRaw run files (multi-channel data):\n")
for (date in run_dates) {
  run_dir <- paste0("data/raw/respirometry_runs/", date)
  if (dir.exists(run_dir)) {
    run_files <- list.files(run_dir, pattern = "^\\d{8}_run_\\d+\\.csv$", full.names = FALSE)
    cat("  ", date, ": ", length(run_files), " run files\n", sep = "")
  } else {
    cat("  ", date, ": DIRECTORY NOT FOUND\n", sep = "")
  }
}

cat("\nProcessed individual coral files:\n")

# Check Porites folder
por_files_by_date <- list()
for (date in run_dates) {
  por_dir <- paste0("data/raw/respirometry_runs/", date, "/Porites")
  if (dir.exists(por_dir)) {
    por_files <- list.files(por_dir, pattern = "\\.csv$", full.names = FALSE)
    # Remove blank files (0.csv, 1.csv, etc.)
    por_files <- por_files[!por_files %in% c("0.csv", "1.csv", "2.csv")]

    # Extract coral IDs
    coral_ids <- as.numeric(gsub(".csv", "", por_files))
    por_files_by_date[[date]] <- sort(coral_ids)

    cat("  ", date, " Porites: ", length(coral_ids), " coral files\n", sep = "")
    cat("    Coral IDs: ", paste(coral_ids, collapse = ", "), "\n", sep = "")
  } else {
    cat("  ", date, " Porites: DIRECTORY NOT FOUND\n", sep = "")
  }
}

# Check if there's an Acropora folder
cat("\nAcropora folders:\n")
for (date in run_dates) {
  acr_dir <- paste0("data/raw/respirometry_runs/", date, "/Acropora")
  if (dir.exists(acr_dir)) {
    acr_files <- list.files(acr_dir, pattern = "\\.csv$", full.names = FALSE)
    acr_files <- acr_files[!acr_files %in% c("0.csv", "1.csv", "2.csv")]
    coral_ids <- as.numeric(gsub(".csv", "", acr_files))
    cat("  ", date, " Acropora: ", length(coral_ids), " coral files\n", sep = "")
    cat("    Coral IDs: ", paste(coral_ids, collapse = ", "), "\n", sep = "")
  } else {
    cat("  ", date, " Acropora: DIRECTORY NOT FOUND (needs processing)\n", sep = "")
  }
}

cat("\n")

# 6. RESPIROMETRY OUTPUT -------------------------------------------------------
cat("\n6. RESPIROMETRY OUTPUT (Calculated Rates)\n")
cat("------------------------------------------\n")

# Check output directories
output_dates <- c("20230526", "20230528", "20230603", "20230619")

for (rate_type in c("Respiration", "Photosynthesis")) {
  cat("\n", rate_type, " rates:\n", sep = "")

  for (date in output_dates) {
    output_dir <- paste0("data/processed/respirometry/Porites/", rate_type, "/", date)

    if (dir.exists(output_dir)) {
      # Check for CSV file
      csv_file <- list.files(output_dir, pattern = "\\.csv$", full.names = TRUE)

      if (length(csv_file) > 0) {
        rate_data <- read_csv(csv_file[1], show_col_types = FALSE)
        cat("  ", date, ": ", nrow(rate_data), " rates calculated\n", sep = "")

        # Check for PDF files (plots)
        pdf_files <- list.files(output_dir, pattern = "\\.pdf$", full.names = FALSE)
        cat("    PDFs: ", length(pdf_files), "\n", sep = "")
      } else {
        cat("  ", date, ": NO CSV FILE FOUND\n", sep = "")
      }
    } else {
      cat("  ", date, ": DIRECTORY NOT FOUND\n", sep = "")
    }
  }
}

cat("\n")

# 7. SUMMARY AND MISSING DATA --------------------------------------------------
cat("\n7. DATA COMPLETENESS SUMMARY\n")
cat("=============================\n")

cat("\nExpected per species:\n")
cat("  Total corals: 18-19\n")
cat("  Control (treatment 0): 6\n")
cat("  Wound type 1 (treatment 1): 5-6\n")
cat("  Wound type 2 (treatment 2): 6-7\n")

cat("\nActual counts:\n")
cat("  Acropora: ", length(acr_ids), " corals\n", sep = "")
cat("  Porites: ", length(por_ids), " corals\n", sep = "")

# Check for missing coral IDs in respirometry data
cat("\n\nMissing Porites respirometry data by date:\n")
for (date in names(por_files_by_date)) {
  missing <- setdiff(por_ids, por_files_by_date[[date]])
  if (length(missing) > 0) {
    cat("  ", date, ": Missing coral IDs: ", paste(missing, collapse = ", "), "\n", sep = "")
  } else {
    cat("  ", date, ": All ", length(por_ids), " Porites corals present\n", sep = "")
  }
}

cat("\n")
cat("================================================================================\n")
cat("AUDIT COMPLETE\n")
cat("================================================================================\n")
