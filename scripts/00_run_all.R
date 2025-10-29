#!/usr/bin/env Rscript
# ==============================================================================
# MASTER SCRIPT: Run Complete Analysis Pipeline
# ==============================================================================
# This script runs all analysis steps in order
# Run from project root: Rscript scripts/00_run_all.R

cat("\n")
cat("================================================================================\n")
cat("                  CORAL WOUND RESPIRATION ANALYSIS PIPELINE\n")
cat("================================================================================\n\n")

# Set working directory to project root
setwd(dirname(dirname(rstudioapi::getActiveDocumentContext()$path)))

# Step 1: Process Growth Data
cat("STEP 1: Processing growth data (buoyant weight → dry mass)...\n")
source("scripts/01_process_growth.R")
cat("✅ Growth data processed\n\n")

# Step 2: Process PAM Data
cat("STEP 2: Processing PAM fluorometry data (Fv/Fm)...\n")
source("scripts/02_process_pam.R")
cat("✅ PAM data processed\n\n")

# Step 3: Process Surface Area
cat("STEP 3: Processing surface area data (wax dipping)...\n")
source("scripts/03_process_surface_area.R")
cat("✅ Surface area data processed\n\n")

# Step 4: Note about respirometry
cat("STEP 4: Respirometry data extraction (if needed)...\n")
cat("⚠️  Run scripts/04_extract_respirometry.R manually if processing new data\n")
cat("⚠️  Run scripts/05_calculate_rates.R manually after extraction\n\n")

# Step 5: Generate integrated report
cat("STEP 5: Generating integrated analysis report...\n")
rmarkdown::render(
  "scripts/Wound_Respiration_Analysis.Rmd",
  output_dir = "reports",
  output_file = "Wound_Respiration_Analysis.html"
)
cat("✅ Analysis report generated\n\n")

cat("================================================================================\n")
cat("                           PIPELINE COMPLETE!\n")
cat("================================================================================\n\n")
cat("View results: open reports/Wound_Respiration_Analysis.html\n")
cat("View figures: open reports/Figures/\n\n")
