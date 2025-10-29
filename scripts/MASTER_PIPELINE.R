#!/usr/bin/env Rscript
# =============================================================================
# MASTER PIPELINE SCRIPT
# =============================================================================
# Purpose: Run complete analysis pipeline for both Porites and Acropora
# Author: Adrian Stier Lab
# Date: 2023-10-28
# =============================================================================

cat("\n")
cat("===============================================\n")
cat("   CORAL WOUND RESPIRATION MASTER PIPELINE    \n")
cat("===============================================\n")
cat("\n")

# Set working directory
setwd("/Users/adrianstiermbp2023/regeneration_wound_respiration")

# Track timing
start_time <- Sys.time()

# =============================================================================
# STEP 1: PROCESS GROWTH DATA
# =============================================================================

cat("\n[STEP 1] Processing growth data...\n")
cat("-----------------------------------------\n")

tryCatch({
  source("scripts/01_process_growth.R")
  cat("✓ Growth data processed successfully\n")
}, error = function(e) {
  cat("✗ Error in growth processing:", e$message, "\n")
})

# =============================================================================
# STEP 2: PROCESS PAM DATA
# =============================================================================

cat("\n[STEP 2] Processing PAM fluorometry data...\n")
cat("-----------------------------------------\n")

tryCatch({
  source("scripts/02_process_pam.R")
  cat("✓ PAM data processed successfully\n")
}, error = function(e) {
  cat("✗ Error in PAM processing:", e$message, "\n")
})

# =============================================================================
# STEP 3: CALCULATE WOUND AREAS
# =============================================================================

cat("\n[STEP 3] Calculating wound areas...\n")
cat("-----------------------------------------\n")

tryCatch({
  source("scripts/02b_calculate_wound_areas.R")
  cat("✓ Wound areas calculated successfully\n")
}, error = function(e) {
  cat("✗ Error in wound area calculation:", e$message, "\n")
})

# =============================================================================
# STEP 4: PROCESS SURFACE AREAS
# =============================================================================

cat("\n[STEP 4] Processing surface area data...\n")
cat("-----------------------------------------\n")

tryCatch({
  source("scripts/03_process_surface_area.R")
  cat("✓ Surface areas processed successfully\n")
}, error = function(e) {
  cat("✗ Error in surface area processing:", e$message, "\n")
})

# =============================================================================
# STEP 5: CALCULATE ADJUSTED SURFACE AREAS
# =============================================================================

cat("\n[STEP 5] Calculating adjusted surface areas...\n")
cat("-----------------------------------------\n")

tryCatch({
  source("scripts/03b_calculate_adjusted_surface_areas.R")
  cat("✓ Adjusted surface areas calculated successfully\n")
}, error = function(e) {
  cat("✗ Error in adjusted surface area calculation:", e$message, "\n")
})

# =============================================================================
# STEP 6: PROCESS PORITES RESPIROMETRY
# =============================================================================

cat("\n[STEP 6] Processing Porites respirometry data...\n")
cat("-----------------------------------------\n")

tryCatch({
  source("scripts/04_process_respirometry.R")
  cat("✓ Porites respirometry processed successfully\n")
}, error = function(e) {
  cat("✗ Error in Porites respirometry processing:", e$message, "\n")
})

# =============================================================================
# STEP 7: FINAL PORITES PROCESSING WITH QUALITY CONTROL
# =============================================================================

cat("\n[STEP 7] Final Porites processing with QC...\n")
cat("-----------------------------------------\n")

tryCatch({
  source("scripts/06_process_respirometry_final.R")
  cat("✓ Final Porites processing completed successfully\n")
}, error = function(e) {
  cat("✗ Error in final Porites processing:", e$message, "\n")
})

# =============================================================================
# STEP 8: EXTRACT ACROPORA DATA
# =============================================================================

cat("\n[STEP 8] Extracting Acropora respirometry data...\n")
cat("-----------------------------------------\n")

tryCatch({
  source("scripts/09_extract_acropora_data_v2.R")
  cat("✓ Acropora data extracted successfully\n")
}, error = function(e) {
  cat("✗ Error in Acropora extraction:", e$message, "\n")
})

# =============================================================================
# STEP 9: PROCESS ACROPORA DATA
# =============================================================================

cat("\n[STEP 9] Processing Acropora respirometry data...\n")
cat("-----------------------------------------\n")

tryCatch({
  source("scripts/11_process_acropora_simple.R")
  cat("✓ Acropora data processed successfully\n")
}, error = function(e) {
  cat("✗ Error in Acropora processing:", e$message, "\n")
})

# =============================================================================
# STEP 10: INTEGRATED ANALYSIS OF BOTH SPECIES
# =============================================================================

cat("\n[STEP 10] Running integrated analysis...\n")
cat("-----------------------------------------\n")

tryCatch({
  source("scripts/13_full_integrated_analysis.R")
  cat("✓ Integrated analysis completed successfully\n")
}, error = function(e) {
  cat("✗ Error in integrated analysis:", e$message, "\n")
})

# =============================================================================
# STEP 11: GENERATE HTML REPORTS
# =============================================================================

cat("\n[STEP 11] Generating HTML reports...\n")
cat("-----------------------------------------\n")

tryCatch({
  library(rmarkdown)

  # Generate main report
  render("Complete_Analysis_Both_Species.Rmd",
         output_file = "reports/Complete_Analysis_Both_Species.html",
         quiet = TRUE)
  cat("✓ Main HTML report generated successfully\n")

}, error = function(e) {
  cat("✗ Error in report generation:", e$message, "\n")
})

# =============================================================================
# SUMMARY
# =============================================================================

end_time <- Sys.time()
duration <- round(difftime(end_time, start_time, units = "mins"), 2)

cat("\n")
cat("===============================================\n")
cat("            PIPELINE COMPLETE                  \n")
cat("===============================================\n")
cat("\n")
cat("Total time:", duration, "minutes\n")
cat("\n")

# Check output files
cat("Generated outputs:\n")
cat("-----------------\n")

# Check data files
data_files <- c(
  "data/processed/growth/growth_summary.csv",
  "data/processed/pam/pam_summary.csv",
  "data/processed/wound_areas.csv",
  "data/processed/surface_area/final_surface_areas.csv",
  "data/processed/surface_area/adjusted_surface_areas.csv",
  "data/processed/respirometry/respirometry_normalized_final.csv",
  "data/processed/respirometry/acropora_rates_simple.csv",
  "data/processed/respirometry/combined_species_normalized.csv",
  "data/processed/respirometry/summary_table_both_species.csv"
)

for (file in data_files) {
  if (file.exists(file)) {
    cat("  ✓", basename(file), "\n")
  } else {
    cat("  ✗", basename(file), "(missing)\n")
  }
}

cat("\n")

# Check figures
fig_files <- list.files("reports/Figures", pattern = "\\.png$", full.names = TRUE)
cat("Generated", length(fig_files), "figures in reports/Figures/\n")

# Check HTML reports
html_files <- list.files("reports", pattern = "\\.html$", full.names = TRUE)
cat("Generated", length(html_files), "HTML reports\n")

cat("\n")
cat("Pipeline execution complete!\n")
cat("\n")

# Optional: Open main report
cat("To view the main report, run:\n")
cat("  open reports/Complete_Analysis_Both_Species.html\n")
cat("\n")