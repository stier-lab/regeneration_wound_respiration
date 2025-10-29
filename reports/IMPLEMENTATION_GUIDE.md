# Pipeline Fixes - Implementation Guide

**Date:** 2025-10-27
**Status:** Preparatory scripts completed, respirometry processing needs testing

---

## COMPLETED FIXES ✅

### 1. Wound Area Calculations
**Script:** `scripts/02b_calculate_wound_areas.R`
**Status:** ✅ WORKING

**What it does:**
- Calculates wound surface area for each coral based on treatment
- Porites small: 1/4" circular = 0.32 cm²
- Porites large: 1/2" circular = 1.27 cm²
- Acropora: 8mm branch cut = 3.02 cm²

**Output:** `data/processed/wound_areas.csv`

**Validation:**
```r
Rscript scripts/02b_calculate_wound_areas.R
```
Results matched expected values ✓

---

### 2. Adjusted Surface Areas
**Script:** `scripts/03b_calculate_adjusted_surface_areas.R`
**Status:** ✅ WORKING

**What it does:**
- Uses final SA from wax dipping as baseline
- Calculates wound-adjusted SA = final SA - wound area
- Creates timepoint-specific SA files for respirometry normalization

**Outputs:**
- `data/processed/surface_area/adjusted_surface_areas.csv` (master file)
- `data/processed/surface_area/initial_SA.csv` (for initial timepoint)
- `data/processed/surface_area/postwound_SA.csv` (for post-wound timepoints)

**Validation:**
```r
Rscript scripts/03b_calculate_adjusted_surface_areas.R
```
Results show proper SA calculations ✓

---

### 3. Growth Rate Calculations
**Script:** `scripts/01_process_growth.R`
**Status:** ✅ WORKING (updated)

**Changes made:**
1. Added aragonite density constant: `density_aragonite <- 2.93  # g/cm³`
2. Created NEW normalization method alongside old method
3. New method uses final SA and calculates mg/cm²/day

**Outputs:**
- `data/processed/growth/growth_weight_normalized.csv` (OLD method - for comparison)
- `data/processed/growth/growth_SA_normalized.csv` (NEW method - use this!)

**Key differences:**
- OLD: dimensionless ratio (final weight / initial weight / days)
- NEW: mg/cm²/day (standardized, comparable across studies)

**Validation:**
```r
Rscript scripts/01_process_growth.R
```
Both methods calculated successfully ✓

---

## PENDING FIXES ⚠️

### 4. Respirometry Processing
**Script:** `scripts/05b_calculate_rates_corrected.R`
**Status:** ⚠️ CREATED BUT NOT TESTED (LoLinR package missing)

**Critical changes needed:**

#### A. Time Window Separation
**Current problem:** Both R and P use same window (10-25 min = light phase)

**Fix:**
```r
# PHOTOSYNTHESIS (light phase)
filter(delta_t > 10 & delta_t < 25)  # 10-25 minutes

# RESPIRATION (dark phase)
filter(delta_t > 25)  # After 25 minutes
```

#### B. Surface Area Normalization
**Current problem:** Normalizing by weight (umol.g.hr)

**Fix:**
```r
# For INITIAL timepoint (20230526)
SA_data <- read.csv("data/processed/surface_area/initial_SA.csv")

# For POST-WOUND timepoints (20230528, 20230603, 20230619)
SA_data <- read.csv("data/processed/surface_area/postwound_SA.csv")

# Normalize
umol.cm2.hr <- (umol.sec.corr * 3600) / SA_cm2
```

#### C. Gross Photosynthesis
**Not currently calculated**

**Add:**
```r
P_gross <- P_net + abs(R)
```

#### D. P:R Ratios
**Not currently calculated**

**Add:**
```r
# Daily metabolic budget
LIGHT_HOURS <- 11  # Hours of light in Moorea
DARK_HOURS <- 13   # Hours of darkness

PR_ratio <- (LIGHT_HOURS * P_gross) / (DARK_HOURS * R)
```

**Interpretation:**
- PR > 1 = Net autotrophy (producing more than consuming)
- PR < 1 = Net heterotrophy (consuming more than producing)

---

## IMPLEMENTATION STEPS

### Step 1: Test Existing Respirometry (Current Method)
To understand current data structure:

```r
# Run existing script to see what it produces
Rscript scripts/05_calculate_rates.R
```

### Step 2: Manual Fixes to Existing Scripts

If `05b_calculate_rates_corrected.R` doesn't work due to LoLinR issues, manually edit the existing `04_extract_respirometry.R` and `05_calculate_rates.R`:

**In `05_calculate_rates.R` around line 305:**

Change:
```r
# CURRENT (WRONG - this is for photosynthesis)
Photo.Data1 <- Photo.Data1 %>%
  mutate(delta_t=as.numeric(delta_t)) %>%
  filter(delta_t > 10 & delta_t < 25)
```

To:
```r
# FOR PHOTOSYNTHESIS SECTION - keep as is
Photo.Data1 <- Photo.Data1 %>%
  mutate(delta_t=as.numeric(delta_t)) %>%
  filter(delta_t > 10 & delta_t < 25)  # Light phase

# FOR RESPIRATION SECTION - change to:
Resp.Data1 <- Resp.Data1 %>%
  mutate(delta_t=as.numeric(delta_t)) %>%
  filter(delta_t > 25)  # Dark phase only
```

**In `04_extract_respirometry.R` around line 50-52:**

Change:
```r
# CURRENT (WRONG)
w1 <- read.csv("Respirometry/Data/initial_weight.csv") %>%
  rename(weight = X1) %>%
  select(coral_id, weight)
Respiration$umol.g.hr <- (Respiration$umol.sec.corr*3600)/Respiration$weight
```

To:
```r
# NEW (CORRECT)
# For initial timepoint
SA_data <- read.csv("data/processed/surface_area/initial_SA.csv") %>%
  filter(genus == "por") %>%
  select(coral_id, SA_cm2)

# For post-wound timepoints, use:
# SA_data <- read.csv("data/processed/surface_area/postwound_SA.csv")

Respiration <- left_join(Respiration, SA_data, by = "coral_id")
Respiration$umol.cm2.hr <- abs((Respiration$umol.sec.corr*3600)/Respiration$SA_cm2)
```

### Step 3: Create Combined Rates File

After processing both R and P separately with correct methods:

```r
# Combine respiration and photosynthesis
combined_rates <- Resp_final %>%
  rename(R_umol.cm2.hr = umol.cm2.hr) %>%
  left_join(
    Photo_final %>%
      rename(P_net_umol.cm2.hr = umol.cm2.hr) %>%
      select(coral_id, P_net_umol.cm2.hr),
    by = "coral_id"
  ) %>%
  mutate(P_gross_umol.cm2.hr = P_net_umol.cm2.hr + R_umol.cm2.hr) %>%
  mutate(PR_ratio = (11 * P_gross_umol.cm2.hr) / (13 * R_umol.cm2.hr))

write.csv(combined_rates, "data/processed/respirometry/rates_combined_corrected.csv")
```

### Step 4: Process All Timepoints

Repeat for each timepoint with appropriate SA file:

| Timepoint | Date | SA File to Use |
|-----------|------|----------------|
| Initial | 20230526 | initial_SA.csv |
| Post-wound | 20230528 | postwound_SA.csv |
| Day 7 | 20230603 | postwound_SA.csv |
| Final | 20230619 | postwound_SA.csv |

### Step 5: Update Statistical Analysis

Once corrected respirometry data is generated, update `Wound_Respiration_Analysis.Rmd`:

**Change data loading:**
```r
# OLD
resp_data <- read.csv("data/processed/respirometry/respiration.csv")

# NEW
resp_data <- read.csv("data/processed/respirometry/rates_combined_corrected.csv")
```

**Update column names:**
```r
# OLD column names
# umol.g.hr, weight

# NEW column names
# R_umol.cm2.hr, P_net_umol.cm2.hr, P_gross_umol.cm2.hr, PR_ratio, SA_cm2
```

**Update models to include new metrics:**
```r
# Add P:R ratio analysis
pr_model <- lmer(PR_ratio ~ treatment * timepoint + (1|coral_id),
                 data = resp_data)

# Add gross photosynthesis analysis
pgross_model <- lmer(P_gross_umol.cm2.hr ~ treatment * timepoint + (1|coral_id),
                     data = resp_data)
```

---

## VALIDATION CHECKLIST

After implementing fixes, verify:

### Growth Data ✅
- [ ] Aragonite density = 2.93 in script
- [ ] Units are mg/cm²/day
- [ ] Normalized by final surface area
- [ ] Growth calculated from postwound to final (23 days)

### Surface Area Data ✅
- [ ] Wax dipping calibration R² > 0.95
- [ ] Initial SA calculated for all corals
- [ ] Wound areas match treatment specifications
- [ ] Postwound SA = initial SA - wound area

### Respirometry Data ⚠️ (Needs Testing)
- [ ] Respiration uses dark phase (delta_t > 25 min)
- [ ] Photosynthesis uses light phase (10 < delta_t < 25 min)
- [ ] Units are umol/cm²/hr (not umol/g/hr)
- [ ] Initial timepoint uses initial_SA.csv
- [ ] Post-wound timepoints use postwound_SA.csv
- [ ] Gross photosynthesis calculated
- [ ] P:R ratios calculated
- [ ] Blank correction applied correctly

### Statistical Models ⚠️ (Pending)
- [ ] Models use corrected respirometry data
- [ ] Growth models use mg/cm²/day data
- [ ] P:R ratio analysis included
- [ ] Gross photosynthesis analysis included

---

## FILES REFERENCE

### Created/Modified Files

**New scripts:**
- `scripts/02b_calculate_wound_areas.R` ✅
- `scripts/03b_calculate_adjusted_surface_areas.R` ✅
- `scripts/05b_calculate_rates_corrected.R` ⚠️ (needs testing)

**Modified scripts:**
- `scripts/01_process_growth.R` ✅ (added aragonite density + SA normalization)

**New data files:**
- `data/processed/wound_areas.csv` ✅
- `data/processed/surface_area/adjusted_surface_areas.csv` ✅
- `data/processed/surface_area/initial_SA.csv` ✅
- `data/processed/surface_area/postwound_SA.csv` ✅
- `data/processed/growth/growth_SA_normalized.csv` ✅

**Pending data files:**
- `data/processed/respirometry/rates_combined_corrected.csv` ⚠️

### Reference Documents
- `reports/PIPELINE_COMPARISON.md` - Detailed comparison of methods
- `reports/IMPLEMENTATION_GUIDE.md` - This document
- Methods attachment - Original experimental methods

---

## TROUBLESHOOTING

### Issue: LoLinR package not found
**Solution:** Install LoLinR or use existing working scripts with manual edits

### Issue: Column name mismatches
**Problem:** Old scripts use different column names than new data files

**Solution:** Use `clean_names()` and verify column names:
```r
library(janitor)
data <- read.csv("file.csv") %>% clean_names()
names(data)  # Check actual column names
```

### Issue: coral_id vs coral_number
**Problem:** Different files use different ID column names

**Solution:** Standardize after reading:
```r
data <- data %>% rename(coral_id = coral_number)
```

### Issue: Missing SA for some corals
**Problem:** Not all corals have final SA measurements

**Solution:** Check which corals are missing:
```r
missing_SA <- anti_join(sample_info, final_SA, by = "coral_id")
print(missing_SA$coral_id)
```

---

## NEXT STEPS

1. **Test respirometry processing** - Verify the new time windows work correctly
2. **Validate all outputs** - Check that numbers make biological sense
3. **Update integrated analysis** - Use corrected data in Rmd
4. **Generate new figures** - With correct normalization
5. **Compare old vs new** - Document how results changed

---

## SUMMARY OF KEY CHANGES

| Metric | OLD Method | NEW Method | Status |
|--------|-----------|------------|--------|
| **Growth** | g/g/day (weight ratio) | mg/cm²/day (by SA) | ✅ Fixed |
| **Aragonite density** | Unspecified | 2.93 g/cm³ | ✅ Fixed |
| **Respiration time** | 10-25 min (WRONG) | >25 min (dark) | ⚠️ Script ready |
| **Photo time** | 10-25 min | 10-25 min (correct) | ✅ Correct |
| **Resp units** | umol/g/hr | umol/cm²/hr | ⚠️ Script ready |
| **Photo units** | umol/g/hr | umol/cm²/hr | ⚠️ Script ready |
| **Wound SA adjust** | Not applied | Initial SA - wound SA | ✅ Fixed |
| **P_gross** | Not calculated | P_net + \|R\| | ⚠️ Script ready |
| **P:R ratio** | Not calculated | (11×P)/(13×R) | ⚠️ Script ready |

---

**Legend:**
- ✅ = Completed and validated
- ⚠️ = Script created but needs testing/installation
- ❌ = Not yet started

---

## CONTACT & QUESTIONS

If you encounter issues:
1. Check PIPELINE_COMPARISON.md for detailed method descriptions
2. Verify data file paths and column names
3. Check R package installations (LoLinR, tidyverse, etc.)
4. Validate intermediate outputs at each step

**Important:** Always save original scripts before modifying. The `archive/` folder contains the original pipeline for reference.
