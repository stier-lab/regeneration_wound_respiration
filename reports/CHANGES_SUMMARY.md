# Pipeline Changes Summary

**Date:** 2025-10-27
**Status:** ✅ Pipeline cleaned and consolidated (no redundant analyses)

---

## What Was Done

I compared your pipeline against the published Acropora regeneration methods you provided and found several critical issues. The pipeline has been **cleaned up and fixed** with **no redundant analyses**.

---

## 🚨 Critical Issues Fixed

### 1. Respirometry Time Windows (CRITICAL BUG!)
**Problem:** Respiration was being measured during the **LIGHT PHASE** (10-25 min) instead of the **DARK PHASE** (>25 min)

**Impact:** All respiration measurements were fundamentally wrong

**Fix:** Created new unified script `04_process_respirometry.R` that correctly:
- Measures **Respiration** in dark phase (>25 min)
- Measures **Photosynthesis** in light phase (10-25 min)

---

### 2. Wrong Normalization Units (CRITICAL!)
**Problem:** Normalizing by **weight** (umol/g/hr) instead of **surface area** (umol/cm²/hr)

**Impact:** Violates standard coral physiology practices, makes results incomparable

**Fix:** All rates now normalized by surface area

---

### 3. Missing Wound Adjustment
**Problem:** Not accounting for surface area removed by wounding

**Impact:** Post-wound rates artificially inflated (same O₂ / less tissue)

**Fix:** New scripts calculate wound areas and adjust SA for all post-wound measurements

---

### 4. Growth Normalization
**Problem:** Using dimensionless weight ratio instead of standard units

**Impact:** Results not comparable to published studies

**Fix:** Now calculates mg/cm²/day normalized by final surface area

---

### 5. Missing Metabolic Metrics
**Problem:** Not calculating gross photosynthesis or P:R ratios

**Impact:** Missing key indicators of metabolic state (autotrophy vs heterotrophy)

**Fix:** Now calculated automatically

---

## 📁 Files Created (Clean - No Redundancy)

### New Scripts
1. **`scripts/02b_calculate_wound_areas.R`**
   - Calculates wound surface area for each treatment
   - Outputs: `data/processed/wound_areas.csv`

2. **`scripts/03b_calculate_adjusted_surface_areas.R`**
   - Creates initial and wound-adjusted surface areas
   - Outputs: `initial_SA.csv`, `postwound_SA.csv`

3. **`scripts/04_process_respirometry.R`** ← **MAIN CHANGE**
   - **REPLACES** old scripts 04 and 05 (archived as .OLD)
   - Processes all timepoints in one clean script
   - All fixes included
   - No redundancy

### Updated Scripts
1. **`scripts/01_process_growth.R`**
   - Added aragonite density constant (2.93 g/cm³)
   - Added NEW surface area normalization method
   - OLD method kept for comparison only

### Archived Scripts (Not Deleted - Renamed)
- `scripts/04_extract_respirometry.R.OLD`
- `scripts/05_calculate_rates.R.OLD`

### Documentation
- `UPDATED_PIPELINE.md` - Quick reference
- `PIPELINE_FIXES_SUMMARY.md` - One-page summary
- `reports/PIPELINE_COMPARISON.md` - Detailed comparison (26 KB)
- `reports/IMPLEMENTATION_GUIDE.md` - Troubleshooting (15 KB)
- `CHANGES_SUMMARY.md` - This file

---

## 🎯 How to Run (Clean Pipeline)

```bash
# Step 1: Calculate wound areas
Rscript scripts/02b_calculate_wound_areas.R

# Step 2: Calculate adjusted surface areas
Rscript scripts/03b_calculate_adjusted_surface_areas.R

# Step 3: Process growth data (with new normalization)
Rscript scripts/01_process_growth.R

# Step 4: Process ALL respirometry data (all fixes included)
Rscript scripts/04_process_respirometry.R

# Step 5: Process PAM data (no changes needed)
Rscript scripts/02_process_pam.R

# Step 6: Process surface area (no changes needed)
Rscript scripts/03_process_surface_area.R
```

**That's it!** No redundant scripts or analyses.

---

## 📊 Output Files (What to Use)

| Analysis | File | Column | Units |
|----------|------|--------|-------|
| **Growth** | `data/processed/growth/growth_SA_normalized.csv` | `mg_cm2_day` | mg/cm²/day |
| **Respiration** | `data/processed/respirometry/all_rates_combined.csv` | `R_umol.cm2.hr` | umol/cm²/hr |
| **Net Photo** | `data/processed/respirometry/all_rates_combined.csv` | `P_net_umol.cm2.hr` | umol/cm²/hr |
| **Gross Photo** | `data/processed/respirometry/all_rates_combined.csv` | `P_gross_umol.cm2.hr` | umol/cm²/hr |
| **Metabolic Status** | `data/processed/respirometry/all_rates_combined.csv` | `PR_ratio` | dimensionless |
| **PAM** | `data/processed/pam/all_fvfm.csv` | `fv_fm` | dimensionless |

---

## ✅ vs ❌ Comparison

| Metric | OLD Pipeline | NEW Pipeline |
|--------|--------------|--------------|
| Respiration phase | ❌ Light (10-25 min) | ✅ Dark (>25 min) |
| Photo phase | ✅ Light (10-25 min) | ✅ Light (10-25 min) |
| Resp units | ❌ umol/g/hr | ✅ umol/cm²/hr |
| Photo units | ❌ umol/g/hr | ✅ umol/cm²/hr |
| Growth units | ❌ g/g/day | ✅ mg/cm²/day |
| Wound SA adjust | ❌ Not done | ✅ Applied |
| P_gross | ❌ Missing | ✅ Calculated |
| P:R ratio | ❌ Missing | ✅ Calculated |
| Aragonite density | ❌ Unspecified | ✅ 2.93 g/cm³ |
| Script count | ❌ 2 (04 + 05) | ✅ 1 (04) |

---

## 🔬 Scientific Justification

### Why Surface Area Normalization Matters
- Gas exchange occurs at coral surface
- Skeleton is metabolically inactive
- Allows comparison across different sized corals
- **Standard practice** in coral physiology

### Why Time Windows Matter
- Respiration = O₂ **consumption** in **darkness**
- Photosynthesis = O₂ **production** in **light**
- Measuring respiration during light gives fundamentally wrong values

### Why P:R Ratio Matters
- **PR > 1**: Net autotrophy (producing more than consuming)
- **PR < 1**: Net heterotrophy (consuming more than producing)
- **PR ≈ 1**: Metabolic balance
- Key indicator of coral health and stress response

---

## ⚠️ Important Notes

1. **LoLinR Package Required**: The respirometry script needs LoLinR package
   ```r
   # If not installed:
   devtools::install_github("colin-olito/LoLinR")
   ```

2. **Old Scripts Preserved**: Nothing was deleted, just renamed to `.OLD` so you can reference them

3. **Two Growth Methods**: The script outputs BOTH old and new methods so you can compare

4. **No Redundancy**: One script (`04_process_respirometry.R`) replaces two old scripts

---

## 📚 Reference Methods

All fixes based on published methods you provided:

> "Respiration rates were standardized by the volume of water in the chamber and **initial geometric surface area** of the coral fragment"

> "O2 rates measured post-injury were standardized using **initial geometric surface area minus wound surface area**"

> "I measured **light-enhanced dark respiration for 15 minutes in complete darkness**"

> "**Gross photosynthesis (PGross) was calculated as PNet plus respiration** (as a positive value)"

> "Daily P:R ratios from hourly rates of PGross and respiration (R) for a **11h:13h day:night cycle**"

> "Dry skeletal mass was derived from coral buoyant weights (Davies 1989) using an **aragonite density of 2.93** (Jokiel 1978)"

---

## 🚀 Next Steps

1. **Test respirometry script**
   - Requires LoLinR package
   - Should process all 4 timepoints automatically
   - Outputs one master `all_rates_combined.csv` file

2. **Update integrated analysis**
   - Modify `Wound_Respiration_Analysis.Rmd` to read new data files
   - Use new column names (R_umol.cm2.hr not umol.g.hr)
   - Add P_gross and PR_ratio analyses

3. **Regenerate figures**
   - With correct normalization
   - New metric: P:R ratio over time

4. **Compare results**
   - How did conclusions change?
   - Document in methods section

---

## 📞 Questions?

See documentation:
- **Quick start**: `UPDATED_PIPELINE.md`
- **Detailed comparison**: `reports/PIPELINE_COMPARISON.md`
- **Troubleshooting**: `reports/IMPLEMENTATION_GUIDE.md`
- **One-page summary**: `PIPELINE_FIXES_SUMMARY.md`

---

## Summary

✅ **Pipeline is now clean** - No redundant analyses
✅ **All critical issues fixed** - Follows published methods
✅ **Old scripts preserved** - Renamed to .OLD
✅ **Fully documented** - Multiple reference docs
✅ **Ready to run** - Single script for respirometry

The main remaining task is to **test the new respirometry script** and **update the integrated analysis** to use the corrected data.

---

**Last Updated:** 2025-10-27
**Version:** 1.0 (Clean Pipeline)
