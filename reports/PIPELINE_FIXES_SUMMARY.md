# Pipeline Fixes - Quick Reference

**Date:** 2025-10-27
**Status:** Preparatory work completed, respirometry needs testing

---

## ✅ COMPLETED FIXES

### 1. Growth Rates
**File:** `scripts/01_process_growth.R`
- ✅ Added aragonite density constant (2.93 g/cm³)
- ✅ Created surface area normalization (mg/cm²/day)
- ✅ Output: `data/processed/growth/growth_SA_normalized.csv`

**To use:** Run `Rscript scripts/01_process_growth.R`

---

### 2. Wound Areas
**File:** `scripts/02b_calculate_wound_areas.R`
- ✅ Calculated wound surface areas for all treatments
- ✅ Porites small: 0.32 cm², large: 1.27 cm²
- ✅ Acropora: 3.02 cm²
- ✅ Output: `data/processed/wound_areas.csv`

**To use:** Run `Rscript scripts/02b_calculate_wound_areas.R`

---

### 3. Adjusted Surface Areas
**File:** `scripts/03b_calculate_adjusted_surface_areas.R`
- ✅ Created initial SA (for timepoint 1)
- ✅ Created postwound SA (SA - wound area, for timepoints 2-4)
- ✅ Outputs:
  - `data/processed/surface_area/initial_SA.csv`
  - `data/processed/surface_area/postwound_SA.csv`

**To use:** Run `Rscript scripts/03b_calculate_adjusted_surface_areas.R`

---

## ⚠️ CRITICAL ISSUES TO FIX

### 4. Respirometry Processing
**Files:** `scripts/04_extract_respirometry.R`, `scripts/05_calculate_rates.R`
**Template created:** `scripts/05b_calculate_rates_corrected.R`

**Problems identified:**
1. 🚨 **Respiration measured in WRONG phase** - Currently using light phase (10-25 min) instead of dark phase (>25 min)
2. 🚨 **Wrong normalization** - Using weight (umol/g/hr) instead of surface area (umol/cm²/hr)
3. ❌ **Missing P_gross** - Not calculating gross photosynthesis
4. ❌ **Missing P:R ratios** - Not calculating metabolic ratios

**Fix required in `scripts/05_calculate_rates.R`:**

**For RESPIRATION section (around line 273-305), change:**
```r
# CURRENT (WRONG)
Photo.Data1 %>% filter(delta_t > 10 & delta_t < 25)

# TO (CORRECT)
Resp.Data1 %>% filter(delta_t > 25)  # Dark phase only
```

**For PHOTOSYNTHESIS section (around line 363-390), keep as:**
```r
# CORRECT (already using light phase)
Photo.Data1 %>% filter(delta_t > 10 & delta_t < 25)
```

**For normalization in `scripts/04_extract_respirometry.R` (lines 50-55), change:**
```r
# CURRENT (WRONG)
w1 <- read.csv("Respirometry/Data/initial_weight.csv")
Respiration$umol.g.hr <- (Respiration$umol.sec.corr*3600)/Respiration$weight

# TO (CORRECT)
# For initial timepoint (20230526):
SA_data <- read.csv("data/processed/surface_area/initial_SA.csv") %>%
  filter(genus == "por") %>% select(coral_id, SA_cm2)

# For post-wound timepoints (20230528, 20230603, 20230619):
SA_data <- read.csv("data/processed/surface_area/postwound_SA.csv") %>%
  filter(genus == "por") %>% select(coral_id, SA_cm2)

Respiration <- left_join(Respiration, SA_data, by = "coral_id")
Respiration$umol.cm2.hr <- abs((Respiration$umol.sec.corr*3600)/Respiration$SA_cm2)
```

---

## 📋 WHAT TO DO NEXT

### Option 1: Use Template Script (Recommended)
1. Install LoLinR package if not available
2. Edit `scripts/05b_calculate_rates_corrected.R` to set timepoint
3. Run for each timepoint (20230526, 20230528, 20230603, 20230619)
4. Check outputs in `Respirometry/Output/All_Rates/[date]/rates_combined.csv`

### Option 2: Manual Edits to Existing Scripts
1. Edit `scripts/05_calculate_rates.R` - fix time windows
2. Edit `scripts/04_extract_respirometry.R` - fix normalization
3. Run scripts for each timepoint
4. Manually combine R and P data to calculate P_gross and P:R

---

## 📊 EXPECTED OUTPUT COLUMNS

### Growth Data (CORRECTED)
```
coral_id, genus, treatment, initial, postwound, day7, final,
growth_g, growth_mg, csa_cm2, mg_cm2_day
```

### Respirometry Data (NEEDED)
```
coral_id, genus, treatment, timepoint,
R_umol.cm2.hr, P_net_umol.cm2.hr, P_gross_umol.cm2.hr,
PR_ratio, SA_cm2, Temp.C
```

---

## 🔍 VALIDATION CHECKS

After fixing respirometry:

1. **Check units:** Should be `umol.cm2.hr` not `umol.g.hr`
2. **Check time windows:**
   - Respiration: Only data from >25 minutes
   - Photosynthesis: Only data from 10-25 minutes
3. **Check P_gross:** Should be positive, larger than P_net
4. **Check P:R ratio:** Should be around 0.5-2.0 typically
5. **Check SA normalization:** Rates should be similar magnitude across coral sizes

---

## 📖 DETAILED DOCUMENTATION

See these files for more information:
- `reports/PIPELINE_COMPARISON.md` - Detailed comparison with published methods
- `reports/IMPLEMENTATION_GUIDE.md` - Step-by-step implementation instructions
- Methods attachment (provided) - Original experimental methods

---

## 🎯 PRIORITY ORDER

1. **HIGH:** Fix respirometry time windows (dark vs light phase)
2. **HIGH:** Fix respirometry normalization (surface area)
3. **MEDIUM:** Add P_gross calculation
4. **MEDIUM:** Add P:R ratio calculation
5. **LOW:** Update integrated analysis with corrected data

---

## ✨ WHAT'S WORKING NOW

- ✅ Growth rate calculations (both methods available)
- ✅ Wound area calculations
- ✅ Surface area adjustments for wounds
- ✅ Surface area measurements (wax dipping)
- ✅ PAM fluorometry processing
- ✅ Buoyant weight conversions

---

## 🔴 WHAT NEEDS ATTENTION

- ⚠️ Respirometry time windows (CRITICAL)
- ⚠️ Respirometry normalization (CRITICAL)
- ⚠️ P_gross calculations (IMPORTANT)
- ⚠️ P:R ratio calculations (IMPORTANT)
- ⚠️ Statistical models (update after respirometry fixed)

---

## 📞 QUICK START

To fix the most critical issue (respirometry):

1. Open `scripts/05_calculate_rates.R`
2. Find the RESPIRATION processing section (~line 273)
3. Change `filter(delta_t > 10 & delta_t < 25)` to `filter(delta_t > 25)`
4. Keep PHOTOSYNTHESIS section as is (10-25 min is correct)
5. Update normalization to use surface area files
6. Re-run all timepoints

**OR** use the template script `05b_calculate_rates_corrected.R` which has all fixes.

---

## 🎓 KEY CONCEPTS

**Why surface area normalization matters:**
- Gas exchange occurs at coral surface
- Larger corals have more tissue = more O₂ exchange
- Weight includes skeleton (metabolically inactive)
- Standard practice in coral physiology

**Why time windows matter:**
- Respiration = O₂ consumption in darkness
- Photosynthesis = O₂ production in light
- Measuring respiration during light phase gives wrong values

**P:R ratio interpretation:**
- PR > 1: Net autotrophy (producing more than consuming)
- PR < 1: Net heterotrophy (consuming more than producing)
- PR ~ 1: Metabolic balance

---

**Last updated:** 2025-10-27
**Version:** 1.0
