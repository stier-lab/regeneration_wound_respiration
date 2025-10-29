# Quick Start - Updated Pipeline

## 🚀 Run Complete Pipeline (Clean - No Redundancy)

```bash
# Navigate to project
cd /Users/adrianstiermbp2023/regeneration_wound_respiration

# Run all processing scripts in order
Rscript scripts/02b_calculate_wound_areas.R
Rscript scripts/03b_calculate_adjusted_surface_areas.R  
Rscript scripts/01_process_growth.R
Rscript scripts/04_process_respirometry.R  # ← Main fix (replaces old 04 & 05)
Rscript scripts/02_process_pam.R
Rscript scripts/03_process_surface_area.R
```

## 📁 What to Use for Analysis

**Growth rates:**
- File: `data/processed/growth/growth_SA_normalized.csv`
- Column: `mg_cm2_day`

**Respirometry (all metrics in one file):**
- File: `data/processed/respirometry/all_rates_combined.csv`
- Columns: `R_umol.cm2.hr`, `P_net_umol.cm2.hr`, `P_gross_umol.cm2.hr`, `PR_ratio`

**PAM:**
- File: `data/processed/pam/all_fvfm.csv`
- Column: `fv_fm`

## 📖 Documentation

- **CHANGES_SUMMARY.md** - What changed and why
- **UPDATED_PIPELINE.md** - Complete workflow guide
- **PIPELINE_FIXES_SUMMARY.md** - One-page reference
- **reports/PIPELINE_COMPARISON.md** - Detailed technical comparison

## ⚠️ Note

If `04_process_respirometry.R` fails, you may need to install LoLinR:
```r
devtools::install_github("colin-olito/LoLinR")
```
