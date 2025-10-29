# Diagnostic script to check respiration calculations
# Investigating large negative values for day 7, treatment 1

library(tidyverse)
library(janitor)

cat("=== RESPIROMETRY DIAGNOSTIC ===\n\n")

# Read raw LoLinR output for day 7 (20230603)
raw_resp <- read.csv("data/processed/respirometry/Porites/Respiration/20230603/Respiration.csv") %>%
  clean_names()

cat("Raw LoLinR output (Day 7):\n")
print(head(raw_resp, 10))

# Read sample info
sample_info <- read.csv("data/metadata/sample_info.csv") %>%
  filter(genus == "por") %>%
  select(coral_id, genus, treatment)

# Read chamber volumes for day 7
volumes <- read.csv("data/raw/chamber_volumes/day7postwound_vol.csv") %>%
  filter(species == "por") %>%
  select(coral_id, chamber_vol)

# Add blank chambers
sample_info_with_blanks <- sample_info
sample_info_with_blanks[nrow(sample_info_with_blanks) + 1,] <- list(0, "por", NA)
sample_info_with_blanks[nrow(sample_info_with_blanks) + 1,] <- list(1, "por", NA)

volumes_with_blanks <- volumes
volumes_with_blanks[nrow(volumes_with_blanks) + 1,] <- list(0, 650)
volumes_with_blanks[nrow(volumes_with_blanks) + 1,] <- list(1, 650)

# Merge
data <- raw_resp %>%
  left_join(sample_info_with_blanks, by = "coral_id") %>%
  left_join(volumes_with_blanks, by = "coral_id") %>%
  mutate(chamber_vol_L = chamber_vol / 1000) %>%
  mutate(umol_sec = umol_l_sec * chamber_vol_L)

cat("\nAfter merging with sample info and volumes:\n")
print(head(data, 10))

# Check blank values
blanks <- data %>% filter(coral_id %in% c(0, 1))
cat("\nBlank rates:\n")
print(blanks %>% select(coral_id, umol_l_sec, chamber_vol, umol_sec))

# Read blank assignments
blank_id_file <- "data/raw/respirometry_runs/20230603/Porites/blank_id.csv"
if(file.exists(blank_id_file)) {
  blank_assignments <- read.csv(blank_id_file)
  cat("\nBlank assignments:\n")
  print(blank_assignments)

  # Join blank rates with assignments
  blank_rates <- data %>%
    filter(coral_id %in% c(0, 1)) %>%
    select(coral_id, umol_sec) %>%
    rename(blank_id = coral_id, blank_rate = umol_sec)

  blanks_assigned <- blank_assignments %>%
    left_join(blank_rates, by = "blank_id")

  cat("\nBlanks assigned to corals:\n")
  print(blanks_assigned)

  # Apply blank correction
  data_corr <- data %>%
    filter(!coral_id %in% c(0, 1)) %>%
    left_join(blanks_assigned, by = "coral_id") %>%
    mutate(umol_sec_corr = umol_sec - blank_rate)

  cat("\nAfter blank correction:\n")
  print(data_corr %>% select(coral_id, treatment, umol_sec, blank_rate, umol_sec_corr))

  # Read surface areas for day 7
  SA_data <- read.csv("data/processed/surface_area/postwound_SA.csv") %>%
    filter(genus == "por") %>%
    select(coral_id, SA_cm2)

  cat("\nSurface areas:\n")
  print(head(SA_data))

  # Normalize to SA
  data_final <- data_corr %>%
    left_join(SA_data, by = "coral_id") %>%
    mutate(umol_hr = umol_sec_corr * 3600) %>%
    mutate(umol_cm2_hr = umol_hr / SA_cm2) %>%
    mutate(umol_cm2_hr_abs = abs(umol_cm2_hr))  # Take absolute value

  cat("\nFinal normalized rates:\n")
  print(data_final %>%
         select(coral_id, treatment, umol_sec_corr, SA_cm2, umol_cm2_hr, umol_cm2_hr_abs) %>%
         arrange(treatment))

  # Check treatment 1 specifically
  cat("\n=== TREATMENT 1 (Small Wound) ===\n")
  treatment1 <- data_final %>% filter(treatment == 1)
  print(treatment1 %>% select(coral_id, umol_l_sec, umol_sec, blank_rate, umol_sec_corr, SA_cm2, umol_cm2_hr))

  cat("\nSummary statistics by treatment:\n")
  summary_stats <- data_final %>%
    group_by(treatment) %>%
    summarize(
      n = n(),
      mean_raw_slope = mean(umol_l_sec, na.rm = TRUE),
      mean_blank_rate = mean(blank_rate, na.rm = TRUE),
      mean_umol_sec_corr = mean(umol_sec_corr, na.rm = TRUE),
      mean_SA = mean(SA_cm2, na.rm = TRUE),
      mean_rate = mean(umol_cm2_hr, na.rm = TRUE),
      mean_rate_abs = mean(umol_cm2_hr_abs, na.rm = TRUE),
      min_rate = min(umol_cm2_hr, na.rm = TRUE),
      max_rate = max(umol_cm2_hr, na.rm = TRUE)
    )
  print(summary_stats)

  cat("\n=== ISSUE DIAGNOSIS ===\n")
  cat("Large negative values suggest:\n")
  cat("1. Blank correction may be wrong (blank > sample)\n")
  cat("2. Surface area may be too small\n")
  cat("3. LoLinR may have picked wrong segment\n\n")

  # Check which corals have extreme values
  extreme <- data_final %>%
    filter(abs(umol_cm2_hr) > 10) %>%
    select(coral_id, treatment, umol_l_sec, blank_rate, umol_sec_corr, SA_cm2, umol_cm2_hr)

  if(nrow(extreme) > 0) {
    cat("Corals with extreme rates (|rate| > 10):\n")
    print(extreme)
  }

} else {
  cat("\nWARNING: No blank_id.csv found for this timepoint\n")
}

cat("\n=== END DIAGNOSTIC ===\n")
