#!/usr/bin/env Rscript
# =============================================================================
# Script: generate_final_report.R
# Purpose: Generate final HTML report with all QC applied
# Date: 2023-10-28
# =============================================================================

library(rmarkdown)

cat("\n=== GENERATING FINAL REPORT ===\n\n")

# Simple render without complex exclusions table
render("Complete_Analysis_Simple.Rmd",
       output_file = "Complete_Analysis_FINAL.html")

cat("\n✓ Report generated: Complete_Analysis_FINAL.html\n")
cat("\nDataset: 117 measurements after all QC\n")
cat("Exclusions: 11 total (8.6%)\n")
cat("  - 6 Acropora (physiological)\n")
cat("  - 4 probe issues\n")
cat("  - 1 Porites outlier\n\n")