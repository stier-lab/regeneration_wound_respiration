#!/usr/bin/env Rscript
library(readxl)

mapping_file <- "archive/rawdata/Respirometry/trial_datasheets.xlsx"
sheets <- excel_sheets(mapping_file)

cat("Species distribution across runs:\n")
cat("================================\n\n")

for(sheet_name in sheets) {
  data <- read_excel(mapping_file, sheet = sheet_name)

  # Get species column if it exists
  if ("species" %in% names(data)) {
    species <- unique(data$species[!is.na(data$species)])
    if (length(species) > 0) {
      cat(sprintf("%-20s: %s\n", sheet_name, paste(species, collapse=", ")))

      # Count by species
      if (length(species) > 1 || !("por" %in% species)) {
        species_count <- table(data$species)
        for (sp in names(species_count)) {
          if (!is.na(sp)) {
            cat(sprintf("  %s: %d corals\n", sp, species_count[sp]))
          }
        }
      }
    }
  }
}

cat("\n\nLooking for 'acr' species entries...\n")
cat("====================================\n")

acr_found <- FALSE
for(sheet_name in sheets) {
  data <- read_excel(mapping_file, sheet = sheet_name)

  if ("species" %in% names(data)) {
    if (any(data$species == "acr", na.rm = TRUE)) {
      acr_found <- TRUE
      cat("\nFound 'acr' in", sheet_name, "\n")
      acr_data <- data[which(data$species == "acr"), c("probe_chamber", "coral_id", "species")]
      print(acr_data)
    }
  }
}

if (!acr_found) {
  cat("\nNo 'acr' species found. Checking for other Acropora identifiers...\n")

  for(sheet_name in sheets) {
    data <- read_excel(mapping_file, sheet = sheet_name)

    if ("species" %in% names(data)) {
      unique_species <- unique(data$species[!is.na(data$species)])
      if (length(unique_species) > 0 && !all(unique_species %in% c("por", "blank", NA))) {
        cat("\nUnusual species values in", sheet_name, ":", paste(unique_species, collapse=", "), "\n")
      }
    }
  }
}