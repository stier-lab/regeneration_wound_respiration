#!/usr/bin/env Rscript
# =============================================================================
# Script: 17_update_species_names.R
# Purpose: Update species names from Porites compressa to Porites spp.
# Date: 2023-10-28
# =============================================================================

library(tidyverse)

cat("\n=== UPDATING SPECIES NAMES ===\n")
cat("===============================\n\n")

# Update combined cleaned dataset
cat("Updating combined_species_cleaned.csv...\n")
cleaned_data <- read_csv("data/processed/respirometry/combined_species_cleaned.csv",
                         show_col_types = FALSE)

cleaned_data_updated <- cleaned_data %>%
  mutate(species = ifelse(species == "Porites compressa", "Porites spp.", species))

write_csv(cleaned_data_updated, "data/processed/respirometry/combined_species_cleaned.csv")

# Update original combined dataset
cat("Updating combined_species_normalized.csv...\n")
original_data <- read_csv("data/processed/respirometry/combined_species_normalized.csv",
                          show_col_types = FALSE)

original_data_updated <- original_data %>%
  mutate(species = ifelse(species == "Porites compressa", "Porites spp.", species))

write_csv(original_data_updated, "data/processed/respirometry/combined_species_normalized.csv")

# Update summary table
cat("Updating summary_table_both_species.csv...\n")
summary_table <- read_csv("data/processed/respirometry/summary_table_both_species.csv",
                         show_col_types = FALSE)

if ("species" %in% names(summary_table)) {
  summary_table_updated <- summary_table %>%
    mutate(species = ifelse(species == "Porites compressa", "Porites spp.", species))

  write_csv(summary_table_updated, "data/processed/respirometry/summary_table_both_species.csv")
}

# Update Porites rates file
cat("Updating respirometry_normalized_final.csv...\n")
porites_rates <- read_csv("data/processed/respirometry/respirometry_normalized_final.csv",
                          show_col_types = FALSE)

if ("species" %in% names(porites_rates)) {
  porites_rates_updated <- porites_rates %>%
    mutate(species = ifelse(species == "Porites compressa", "Porites spp.", species))
} else {
  # Add species column if it doesn't exist
  porites_rates_updated <- porites_rates %>%
    mutate(species = "Porites spp.")
}

write_csv(porites_rates_updated, "data/processed/respirometry/respirometry_normalized_final.csv")

cat("\n✓ Species names updated successfully!\n")
cat("  Changed: Porites compressa → Porites spp.\n")
cat("  Unchanged: Acropora pulchra\n\n")

# Verify changes
final_data <- read_csv("data/processed/respirometry/combined_species_cleaned.csv",
                       show_col_types = FALSE)
cat("Species in final dataset:\n")
print(table(final_data$species))

cat("\n✓ Update complete!\n")