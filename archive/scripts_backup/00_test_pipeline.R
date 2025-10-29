#!/usr/bin/env Rscript
# ==============================================================================
# PIPELINE TEST SCRIPT
# ==============================================================================
# Tests all analysis scripts to ensure they work with new file structure
# Run from project root: Rscript scripts/00_test_pipeline.R

cat("\n")
cat("================================================================================\n")
cat("                    TESTING ANALYSIS PIPELINE\n")
cat("================================================================================\n\n")

# Test 1: Check working directory
cat("TEST 1: Checking working directory...\n")
expected_dir <- "regeneration_wound_respiration"
if (grepl(expected_dir, getwd())) {
  cat("✅ Working directory correct: ", getwd(), "\n\n")
} else {
  cat("⚠️  Working directory: ", getwd(), "\n")
  cat("   Expected to contain: ", expected_dir, "\n\n")
}

# Test 2: Check folder structure
cat("TEST 2: Checking folder structure...\n")
required_folders <- c("scripts", "data", "reports", "archive")
for (folder in required_folders) {
  if (dir.exists(folder)) {
    cat("✅", folder, "/\n")
  } else {
    cat("❌", folder, "/ NOT FOUND\n")
  }
}
cat("\n")

# Test 3: Check data files exist
cat("TEST 3: Checking critical data files...\n")
data_files <- c(
  "data/metadata/sample_info.csv",
  "data/raw/growth/20230527_initial.csv",
  "data/raw/pam/20230603_pam.csv",
  "data/raw/surface_area/WoundRespExp_WaxData.csv"
)
for (file in data_files) {
  if (file.exists(file)) {
    cat("✅", file, "\n")
  } else {
    cat("❌", file, "NOT FOUND\n")
  }
}
cat("\n")

# Test 4: Check scripts exist
cat("TEST 4: Checking analysis scripts...\n")
scripts <- c(
  "scripts/analysis_functions.R",
  "scripts/data_audit.R",
  "scripts/01_process_growth.R",
  "scripts/02_process_pam.R",
  "scripts/03_process_surface_area.R"
)
for (script in scripts) {
  if (file.exists(script)) {
    cat("✅", script, "\n")
  } else {
    cat("❌", script, "NOT FOUND\n")
  }
}
cat("\n")

# Test 5: Load key packages
cat("TEST 5: Checking R packages...\n")
packages <- c("tidyverse", "lmerTest", "emmeans", "rmarkdown")
missing <- c()
for (pkg in packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("✅", pkg, "\n")
  } else {
    cat("❌", pkg, "NOT INSTALLED\n")
    missing <- c(missing, pkg)
  }
}
cat("\n")

# Test 6: Run individual scripts
cat("TEST 6: Testing individual scripts...\n")

test_script <- function(script_name, script_path) {
  cat("Testing", script_name, "... ")
  tryCatch({
    source(script_path, local = TRUE)
    cat("✅ SUCCESS\n")
    return(TRUE)
  }, error = function(e) {
    cat("❌ FAILED:", conditionMessage(e), "\n")
    return(FALSE)
  })
}

cat("\n")
test_script("Growth processing", "scripts/01_process_growth.R")
test_script("PAM processing", "scripts/02_process_pam.R")
test_script("Surface area", "scripts/03_process_surface_area.R")
cat("\n")

# Test 7: Check outputs were created
cat("TEST 7: Checking output files...\n")
output_files <- c(
  "data/processed/growth/initial_weight.csv",
  "data/processed/pam/average_fvfm.csv",
  "data/processed/surface_area/final_surface_areas.csv"
)
for (file in output_files) {
  if (file.exists(file)) {
    file_size <- file.size(file)
    cat("✅", file, "(",  round(file_size/1024, 1), "KB )\n")
  } else {
    cat("❌", file, "NOT CREATED\n")
  }
}
cat("\n")

# Test 8: Check reports exist
cat("TEST 8: Checking reports...\n")
report_files <- c(
  "reports/Wound_Respiration_Analysis.html",
  "reports/PIPELINE_DOCUMENTATION.md",
  "README.md"
)
for (file in report_files) {
  if (file.exists(file)) {
    file_size <- file.size(file)
    cat("✅", file, "(", round(file_size/1024, 1), "KB )\n")
  } else {
    cat("⚠️ ", file, "not found\n")
  }
}
cat("\n")

# Test 9: Load and verify sample data
cat("TEST 9: Loading and validating sample data...\n")
tryCatch({
  library(tidyverse, quietly = TRUE)
  sample_info <- read_csv("data/metadata/sample_info.csv", show_col_types = FALSE)
  
  n_corals <- nrow(sample_info)
  n_acr <- sum(sample_info$genus == "acr")
  n_por <- sum(sample_info$genus == "por")
  
  cat("  Total corals:", n_corals, "\n")
  cat("  Acropora:", n_acr, "\n")
  cat("  Porites:", n_por, "\n")
  
  if (n_corals == 36 && n_acr == 18 && n_por == 18) {
    cat("✅ Sample sizes correct\n\n")
  } else {
    cat("⚠️  Expected 36 total (18 per species)\n\n")
  }
}, error = function(e) {
  cat("❌ Error loading data:", conditionMessage(e), "\n\n")
})

# Summary
cat("================================================================================\n")
cat("                         TEST SUMMARY\n")
cat("================================================================================\n\n")

if (length(missing) > 0) {
  cat("⚠️  Missing packages:", paste(missing, collapse = ", "), "\n")
  cat("   Install with: install.packages(c('", paste(missing, collapse = "', '"), "'))\n\n")
}

cat("RESULT: All core pipeline components tested\n")
cat("\n")
cat("NEXT STEPS:\n")
cat("1. Review outputs in data/processed/\n")
cat("2. Check reports/ for analysis results\n")
cat("3. Run full analysis: Rscript -e \"rmarkdown::render('scripts/Wound_Respiration_Analysis.Rmd', output_dir='reports')\"\n")
cat("\n")
cat("================================================================================\n")
