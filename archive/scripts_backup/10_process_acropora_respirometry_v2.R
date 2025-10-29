# ============================================================================
# RESPIROMETRY PROCESSING - COMPLETE PIPELINE
# ============================================================================
# This script processes all respirometry data with correct methods:
# 1. Separate time windows for Respiration (dark) vs Photosynthesis (light)
# 2. Normalize by SURFACE AREA (cm²) not weight
# 3. Calculate Gross Photosynthesis and P:R ratios
#
# REPLACES: old scripts 04_extract_respirometry.R and 05_calculate_rates.R
# ============================================================================

library("ggplot2")
library("plotrix")
library("LoLinR")
library("lubridate")
library('dplyr')
library('stringr')
library('janitor')
library('purrr')
library('tidyverse')

# ============================================================================
# CONFIGURATION
# ============================================================================

# Set working directory
setwd("/Users/adrianstiermbp2023/regeneration_wound_respiration")

# Define all timepoints to process
TIMEPOINTS <- c("20230526", "20230528", "20230603", "20230619")
SPECIES <- "Acropora"
SPECIES_CODE <- "acr"

# Experimental timeline (minutes)
PHOTO_START <- 10   # Start of light phase
PHOTO_END <- 25     # End of light phase / start of dark phase
RESP_START <- 25    # Start of dark phase

# Day/night cycle for P:R calculation
LIGHT_HOURS <- 11   # Hours of daylight
DARK_HOURS <- 13    # Hours of darkness

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

get_volume_file <- function(timepoint) {
  # Return appropriate chamber volume file for each timepoint
  if(timepoint == "20230526") {
    return("data/raw/chamber_volumes/initial_vol.csv")
  } else if(timepoint == "20230528") {
    return("data/raw/chamber_volumes/postwound_vol.csv")
  } else if(timepoint == "20230603") {
    return("data/raw/chamber_volumes/day7postwound_vol.csv")
  } else {
    return("data/raw/chamber_volumes/final_weight.csv")
  }
}

get_SA_file <- function(timepoint) {
  # Return appropriate surface area file for each timepoint
  if(timepoint == "20230526") {
    # Initial: no wound adjustment needed
    return("data/processed/surface_area/initial_SA.csv")
  } else {
    # Post-wound: use wound-adjusted SA
    return("data/processed/surface_area/postwound_SA.csv")
  }
}

process_single_file <- function(file_path, phase = "respiration") {
  # Process a single respirometry file for either R or P
  # phase = "respiration" (dark) or "photosynthesis" (light)

  # Read O2 data
  data <- read.csv(file_path, header = TRUE) %>%
    select(delta_t, value, temp) %>%
    na.omit()

  # Filter to appropriate time window
  if(phase == "respiration") {
    data <- data %>%
      mutate(delta_t = as.numeric(delta_t)) %>%
      filter(delta_t > RESP_START)  # Dark phase only
  } else {
    data <- data %>%
      mutate(delta_t = as.numeric(delta_t)) %>%
      filter(delta_t > PHOTO_START & delta_t < PHOTO_END)  # Light phase only
  }

  # Check if we have enough data
  if(nrow(data) < 10) {
    warning(paste("Insufficient data in", basename(file_path), "for", phase))
    return(list(slope = NA, intercept = NA, temp = NA))
  }

  # Create time sequence
  n <- nrow(data)
  data$sec <- seq(1, by = 3, length.out = n)

  # Save original before thinning
  data_orig <- data

  # Thin data by every 5 points (per methods)
  data_thin <- thinData(data, by = 5)$newData1
  data_thin$sec <- as.numeric(rownames(data_thin))
  data_thin$temp <- thinData(data_orig, xy = c(1,3), by = 5)$newData1[,2]

  # Calculate rate using LoLinR (Olito et al. 2017)
  # alpha=0.5, method="pc" (density-based local regression)
  tryCatch({
    regs <- rankLocReg(
      xall = data_orig$sec,
      yall = data_orig$value,
      alpha = 0.5,
      method = "pc",
      verbose = FALSE
    )

    return(list(
      slope = regs$allRegs[1, 5],      # umol/L/sec
      intercept = regs$allRegs[1, 4],
      temp = mean(data_thin$temp, na.rm = TRUE)
    ))
  }, error = function(e) {
    warning(paste("LoLinR failed for", basename(file_path)))
    return(list(slope = NA, intercept = NA, temp = NA))
  })
}

# ============================================================================
# MAIN PROCESSING LOOP
# ============================================================================

# Store all results
all_rates_combined <- list()

for(TIMEPOINT in TIMEPOINTS) {

  cat("\n============================================================\n")
  cat(paste0("Processing timepoint: ", TIMEPOINT, " - ", SPECIES, "\n"))
  cat("============================================================\n\n")

  # -------------------------------------------------------------------
  # STEP 1: Process all files for this timepoint
  # -------------------------------------------------------------------

  data_path <- paste0("data/raw/respirometry_runs/", TIMEPOINT, "/", SPECIES)

  if(!dir.exists(data_path)) {
    cat("WARNING: No data found for", TIMEPOINT, "\n")
    next
  }

  file_names <- list.files(path = data_path, pattern = "csv$")
  coral_ids <- tools::file_path_sans_ext(file_names)

  cat(paste0("Found ", length(file_names), " files\n\n"))

  # Initialize results dataframes
  results_R <- data.frame(
    coral_id = coral_ids,
    Intercept_R = NA,
    umol.L.sec_R = NA,
    Temp_R = NA
  )

  results_P <- data.frame(
    coral_id = coral_ids,
    Intercept_P = NA,
    umol.L.sec_P = NA,
    Temp_P = NA
  )

  cat("Step 1: Calculating raw rates with LoLinR...\n")

  for(i in 1:length(file_names)) {
    file_path <- file.path(data_path, file_names[i])

    # Process for RESPIRATION (dark phase)
    res_R <- process_single_file(file_path, phase = "respiration")
    results_R$Intercept_R[i] <- res_R$intercept
    results_R$umol.L.sec_R[i] <- res_R$slope
    results_R$Temp_R[i] <- res_R$temp

    # Process for PHOTOSYNTHESIS (light phase)
    res_P <- process_single_file(file_path, phase = "photosynthesis")
    results_P$Intercept_P[i] <- res_P$intercept
    results_P$umol.L.sec_P[i] <- res_P$slope
    results_P$Temp_P[i] <- res_P$temp
  }

  cat("  ✓ Raw rates calculated\n\n")

  # -------------------------------------------------------------------
  # STEP 2: Normalize by chamber volume
  # -------------------------------------------------------------------

  cat("Step 2: Normalizing by chamber volume...\n")

  # Read sample info
  treatments <- read.csv('data/metadata/sample_info.csv') %>%
    filter(genus == SPECIES_CODE) %>%
    select(coral_id, genus, treatment)

  # Read chamber volumes
  vol_file <- get_volume_file(TIMEPOINT)
  volumes <- read.csv(vol_file) %>%
    filter(species == SPECIES_CODE) %>%
    select(coral_id, chamber_vol)

  sample_info <- left_join(treatments, volumes, by = "coral_id")

  # Add blank chambers (650 mL full volume)
  sample_info[nrow(sample_info) + 1,] <- list(0, SPECIES_CODE, NA, 650)
  sample_info[nrow(sample_info) + 1,] <- list(1, SPECIES_CODE, NA, 650)

  # Combine with rates
  results_R <- results_R %>%
    mutate(coral_id = as.numeric(coral_id)) %>%
    left_join(sample_info, by = "coral_id") %>%
    mutate(chamber_vol_L = chamber_vol / 1000) %>%
    mutate(umol.sec_R = umol.L.sec_R * chamber_vol_L)

  results_P <- results_P %>%
    mutate(coral_id = as.numeric(coral_id)) %>%
    left_join(sample_info, by = "coral_id") %>%
    mutate(chamber_vol_L = chamber_vol / 1000) %>%
    mutate(umol.sec_P = umol.L.sec_P * chamber_vol_L)

  cat("  ✓ Converted to umol/sec\n\n")

  # -------------------------------------------------------------------
  # STEP 3: Blank correction
  # -------------------------------------------------------------------

  cat("Step 3: Applying blank correction...\n")

  # Check if blank_id file exists
  blank_id_file <- paste0(data_path, "/blank_id.csv")

  if(file.exists(blank_id_file)) {
    # Extract blank rates
    blank_rates_R <- results_R %>%
      filter(coral_id %in% c(0, 1)) %>%
      select(coral_id, umol.sec_R) %>%
      rename(blank_id = coral_id, blank_rate_R = umol.sec_R)

    blank_rates_P <- results_P %>%
      filter(coral_id %in% c(0, 1)) %>%
      select(coral_id, umol.sec_P) %>%
      rename(blank_id = coral_id, blank_rate_P = umol.sec_P)

    # Read blank assignments
    blank_ids <- read.csv(blank_id_file)

    # Assign blanks to samples
    blanks_R <- left_join(blank_ids, blank_rates_R, by = "blank_id")
    blanks_P <- left_join(blank_ids, blank_rates_P, by = "blank_id")

    # Apply correction
    results_R <- results_R %>%
      filter(!coral_id %in% c(0, 1)) %>%  # Remove blanks
      left_join(blanks_R, by = "coral_id") %>%
      mutate(umol.sec.corr_R = umol.sec_R - blank_rate_R)

    results_P <- results_P %>%
      filter(!coral_id %in% c(0, 1)) %>%
      left_join(blanks_P, by = "coral_id") %>%
      mutate(umol.sec.corr_P = umol.sec_P - blank_rate_P)

  } else {
    # No blank file - assume blanks are corals 0 and 1, calculate mean
    cat("  WARNING: No blank_id.csv found, using mean of corals 0 and 1\n")

    mean_blank_R <- results_R %>%
      filter(coral_id %in% c(0, 1)) %>%
      summarize(mean_blank = mean(umol.sec_R, na.rm = TRUE)) %>%
      pull(mean_blank)

    mean_blank_P <- results_P %>%
      filter(coral_id %in% c(0, 1)) %>%
      summarize(mean_blank = mean(umol.sec_P, na.rm = TRUE)) %>%
      pull(mean_blank)

    results_R <- results_R %>%
      filter(!coral_id %in% c(0, 1)) %>%
      mutate(umol.sec.corr_R = umol.sec_R - mean_blank_R)

    results_P <- results_P %>%
      filter(!coral_id %in% c(0, 1)) %>%
      mutate(umol.sec.corr_P = umol.sec_P - mean_blank_P)
  }

  cat("  ✓ Blank correction applied\n\n")

  # -------------------------------------------------------------------
  # STEP 4: Normalize by SURFACE AREA (CRITICAL FIX!)
  # -------------------------------------------------------------------

  cat("Step 4: Normalizing by SURFACE AREA...\n")

  # Read appropriate SA file
  sa_file <- get_SA_file(TIMEPOINT)
  sa_data <- read.csv(sa_file) %>%
    filter(genus == SPECIES_CODE) %>%
    select(coral_id, SA_cm2)

  cat(paste0("  Using: ", sa_file, "\n"))

  # Normalize respiration
  results_R <- results_R %>%
    left_join(sa_data, by = "coral_id") %>%
    mutate(umol.hr_R = umol.sec.corr_R * 3600) %>%
    mutate(R_umol.cm2.hr = abs(umol.hr_R / SA_cm2))  # Take absolute value

  # Normalize photosynthesis
  results_P <- results_P %>%
    left_join(sa_data, by = "coral_id") %>%
    mutate(umol.hr_P = umol.sec.corr_P * 3600) %>%
    mutate(P_net_umol.cm2.hr = umol.hr_P / SA_cm2)  # Can be + or -

  cat("  ✓ Rates normalized to umol/cm²/hr\n\n")

  # -------------------------------------------------------------------
  # STEP 5: Calculate P_gross and P:R ratios
  # -------------------------------------------------------------------

  cat("Step 5: Calculating P_gross and P:R ratios...\n")

  # Combine R and P data
  combined <- results_R %>%
    select(coral_id, genus, treatment, R_umol.cm2.hr, SA_cm2, Temp_R) %>%
    left_join(
      results_P %>% select(coral_id, P_net_umol.cm2.hr, Temp_P),
      by = "coral_id"
    ) %>%
    mutate(
      # Gross photosynthesis
      P_gross_umol.cm2.hr = P_net_umol.cm2.hr + R_umol.cm2.hr,

      # P:R ratio (daily metabolic budget)
      PR_ratio = (LIGHT_HOURS * P_gross_umol.cm2.hr) / (DARK_HOURS * R_umol.cm2.hr),

      # Add timepoint identifier
      timepoint = TIMEPOINT,

      # Average temperature
      Temp_C = (Temp_R + Temp_P) / 2
    )

  cat("  ✓ P_gross and P:R calculated\n\n")

  # -------------------------------------------------------------------
  # STEP 6: Save outputs
  # -------------------------------------------------------------------

  cat("Step 6: Saving outputs...\n")

  # Create output directory if needed
  out_dir <- paste0("data/processed/respirometry/", SPECIES, "/", TIMEPOINT)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  # Save combined rates
  write.csv(combined, paste0(out_dir, "/rates_combined.csv"), row.names = FALSE)

  # Also save individual R and P files for reference
  write.csv(results_R %>% select(coral_id, treatment, R_umol.cm2.hr, SA_cm2, Temp_R),
            paste0(out_dir, "/respiration_normalized.csv"), row.names = FALSE)

  write.csv(results_P %>% select(coral_id, treatment, P_net_umol.cm2.hr, SA_cm2, Temp_P),
            paste0(out_dir, "/photosynthesis_normalized.csv"), row.names = FALSE)

  cat(paste0("  ✓ Saved to: ", out_dir, "\n\n"))

  # -------------------------------------------------------------------
  # STEP 7: Summary statistics
  # -------------------------------------------------------------------

  summary_stats <- combined %>%
    group_by(treatment) %>%
    summarize(
      n = n(),
      R_mean = mean(R_umol.cm2.hr, na.rm = TRUE),
      Pnet_mean = mean(P_net_umol.cm2.hr, na.rm = TRUE),
      Pgross_mean = mean(P_gross_umol.cm2.hr, na.rm = TRUE),
      PR_mean = mean(PR_ratio, na.rm = TRUE),
      .groups = "drop"
    )

  cat("Summary statistics:\n")
  print(summary_stats, n = 10)
  cat("\n")

  # Store for master file
  all_rates_combined[[TIMEPOINT]] <- combined
}

# ============================================================================
# COMBINE ALL TIMEPOINTS
# ============================================================================

cat("\n============================================================\n")
cat("Creating master combined file...\n")
cat("============================================================\n\n")

if(length(all_rates_combined) > 0) {
  master_rates <- bind_rows(all_rates_combined)

  write.csv(master_rates,
            "data/processed/respirometry/all_rates_combined.csv",
            row.names = FALSE)

  cat("✓ Master file saved: data/processed/respirometry/all_rates_combined.csv\n")
  cat(paste0("  Total rows: ", nrow(master_rates), "\n"))
  cat(paste0("  Timepoints: ", length(unique(master_rates$timepoint)), "\n"))
  cat(paste0("  Corals: ", length(unique(master_rates$coral_id)), "\n\n"))
}

# ============================================================================
# FINAL SUMMARY
# ============================================================================

cat("\n============================================================\n")
cat("PROCESSING COMPLETE!\n")
cat("============================================================\n\n")

cat("KEY IMPROVEMENTS FROM OLD PIPELINE:\n")
cat("  1. ✓ Respiration measured in DARK PHASE (>25 min)\n")
cat("  2. ✓ Photosynthesis measured in LIGHT PHASE (10-25 min)\n")
cat("  3. ✓ Normalized by SURFACE AREA (umol/cm²/hr)\n")
cat("  4. ✓ Surface area adjusted for wounds in post-wound timepoints\n")
cat("  5. ✓ Gross photosynthesis calculated (P_gross = P_net + R)\n")
cat("  6. ✓ P:R ratios calculated for metabolic assessment\n\n")

cat("OUTPUT COLUMNS:\n")
cat("  - coral_id, genus, treatment, timepoint\n")
cat("  - R_umol.cm2.hr (respiration rate)\n")
cat("  - P_net_umol.cm2.hr (net photosynthesis)\n")
cat("  - P_gross_umol.cm2.hr (gross photosynthesis)\n")
cat("  - PR_ratio (daily metabolic budget)\n")
cat("  - SA_cm2 (surface area used for normalization)\n")
cat("  - Temp_C (average temperature)\n\n")

cat("P:R RATIO INTERPRETATION:\n")
cat("  PR > 1 = Net autotrophy (producing more than consuming)\n")
cat("  PR < 1 = Net heterotrophy (consuming more than producing)\n\n")

cat("Next step: Update integrated analysis to use these corrected rates\n\n")
