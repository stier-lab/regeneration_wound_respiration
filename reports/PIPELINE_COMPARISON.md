# Pipeline Comparison: Current vs. Acropora Regeneration Reference

**Date:** 2025-10-27
**Purpose:** Compare current Porites wound respiration pipeline against published Acropora regeneration methods to ensure best practices

---

## EXECUTIVE SUMMARY

### ✅ CORRECT IMPLEMENTATIONS
1. **LoLinR parameters** - Using correct alpha=0.5, method="pc"
2. **Wax dipping method** - Correct formula CSA = 2πRH + πR²
3. **Buoyant weight conversion** - Correct density calculations (0.9965 for freshwater)
4. **Data thinning** - Using by=5 parameter correctly
5. **Blank correction** - Matched blanks to samples appropriately

### ⚠️ CRITICAL ISSUES IDENTIFIED

| Issue | Current Pipeline | Should Be (per Methods) | Priority |
|-------|------------------|-------------------------|----------|
| **Respiration time window** | delta_t > 10 & < 25 | delta_t > 25 (dark phase only) | **HIGH** |
| **Photosynthesis time window** | delta_t > 10 & < 25 | 10 < delta_t < 25 (light phase) | **HIGH** |
| **Normalization units** | umol.g.hr (by weight) | umol.cm2.hr (by surface area) | **CRITICAL** |
| **Surface area usage** | Initial SA only | Initial SA - wound SA for post-wound | **HIGH** |
| **P:R ratio calculation** | Not calculated | Should be: (11hr × P_gross) / (13hr × R) | **MEDIUM** |
| **Gross photosynthesis** | Not calculated | P_gross = P_net + |R| | **MEDIUM** |
| **Growth normalization** | By initial weight | Should be mg/cm2/day by final SA | **HIGH** |
| **Aragonite density** | Not specified | Should be 2.93 g/cm³ | **MEDIUM** |

---

## DETAILED COMPARISON BY PROCESSING STEP

## 1. RESPIROMETRY PROCESSING

### A. LoLinR Implementation

**Current Pipeline (`05_calculate_rates.R`):**
```r
# Line 344: ✅ CORRECT
Regs <- rankLocReg(xall=Photo.Data.orig$sec, yall=Photo.Data.orig$value,
                   alpha=0.5, method="pc", verbose=TRUE)
```

**Reference Method (Acropora):**
```r
Regs <- rankLocReg(xall=Photo.Data.orig$sec, yall=Photo.Data.orig$Value,
                   alpha=0.5, method="pc", verbose=TRUE)
```

**Assessment:** ✅ **CORRECT** - Same parameters

---

### B. Data Trimming Windows

**Current Pipeline (`05_calculate_rates.R`):**

**PHOTOSYNTHESIS (Line 305):**
```r
Photo.Data1 <- Photo.Data1 %>%
  mutate(delta_t=as.numeric(delta_t)) %>%
  filter(delta_t > 10 & delta_t < 25)  # ✅ CORRECT for photosynthesis
```

**RESPIRATION (Line 305 - SAME CODE):**
```r
# ⚠️ PROBLEM: Uses same window for respiration!
Photo.Data1 <- Photo.Data1 %>%
  mutate(delta_t=as.numeric(delta_t)) %>%
  filter(delta_t > 10 & delta_t < 25)  # ❌ WRONG - this is light phase
```

**Reference Methods (from attached document):**

> "I measured light-enhanced dark respiration for 15 minutes in complete darkness"
> "PNet was measured for 15 minutes at 100% light intensity"
> "each coral was light acclimated (5 min at 40% and 5 min at 70% light intensity) prior to measuring photosynthesis"

**Acropora Reference Code:**
- **Respiration:** `filter(delta_t > 25)` - Start after photosynthesis phase ends
- **Photosynthesis:** `filter(delta_t > 10 & delta_t < 25)` - Light phase only

**⚠️ CRITICAL ISSUE:** Your current pipeline uses the SAME time window (10-25 min) for BOTH photosynthesis and respiration. This means you're measuring respiration during the LIGHT PHASE, not the dark phase!

**Expected Experimental Timeline:**
```
0-10 min:  Light acclimation (40% → 70%)
10-25 min: PHOTOSYNTHESIS measurement (100% light, 15 min)
25-40 min: RESPIRATION measurement (dark, 15 min)
```

---

### C. Data Thinning

**Current Pipeline:**
```r
# Line 328: ✅ CORRECT
Photo.Data1 <- thinData(Photo.Data1, by=5)$newData1
```

**Reference:**
```r
Photo.Data1 <- thinData(Photo.Data1, by=5)$newData1
```

**Assessment:** ✅ **CORRECT** - Same thinning factor

---

### D. Blank Correction

**Current Pipeline (`04_extract_respirometry.R`):**
```r
# Lines 34-47: Matched blank approach
blankrows <- c(1,2)
blank_rates <- Respiration[blankrows, ] %>%
  rename(blank_id = coral_id) %>%
  select(blank_id, umol.sec)

blank_id <- read.csv("...blank_id.csv")
blanks <- left_join(blank_id, blank_rates, by = "blank_id")

Respiration <- left_join(Respiration, blanks, by = "coral_id")
Respiration$umol.sec.corr <- Respiration$umol.sec - Respiration$blank_rate
```

**Reference Approach:**
- Calculate mean blank for each run/timepoint
- Subtract specific matched blank
- Use blank from same environmental conditions

**Assessment:** ✅ **CORRECT** - Properly matched blanks to samples

---

### E. Normalization

**Current Pipeline (`04_extract_respirometry.R`):**
```r
# Line 52: ❌ WRONG UNITS
w1 <- read.csv("initial_weight.csv") %>%
  rename(weight = X1) %>%
  select(coral_id, weight)

Respiration <- left_join(Respiration, w1, by = "coral_id")
Respiration$umol.g.hr <- (Respiration$umol.sec.corr * 3600) / Respiration$weight
```

**Units:** `umol.g.hr` - **normalized by WEIGHT (grams)**

**Reference Method (from attached document):**

> "Respiration rates were standardized by the volume of water in the chamber and **initial geometric surface area** of the coral fragment"

> "O2 rates measured post-injury were standardized using **initial geometric surface area minus wound surface area**"

**Reference Code:**
```r
# Normalize to surface area
umol.cm2.hr <- (umol.sec.corr * 3600) / surf.area.cm2
umol.cm2.hr <- abs(umol.cm2.hr)
```

**Units:** `umol.cm2.hr` - **normalized by SURFACE AREA (cm²)**

**⚠️ CRITICAL ISSUE:** You are normalizing by **weight** instead of **surface area**. This is fundamentally incorrect for respirometry analysis.

**Why Surface Area Matters:**
- Gas exchange occurs at the coral surface
- Larger surface area = more tissue = more O₂ exchange
- Weight includes skeleton (metabolically inactive)
- Standard practice in coral physiology to use surface area

**Required Changes:**

1. **For INITIAL timepoint:**
   ```r
   # Use geometric surface area from branch measurements
   initial_SA <- read.csv("initial_geometric_SA.csv")
   Respiration$umol.cm2.hr <- (Respiration$umol.sec.corr * 3600) / initial_SA$CSA_cm2
   ```

2. **For POST-WOUND timepoints:**
   ```r
   # Calculate wound area
   wound_area <- 2*pi*r*h + pi*r^2  # Surface area removed

   # Adjust surface area
   SA_post_wound <- initial_SA - wound_area

   # Normalize
   Respiration$umol.cm2.hr <- (Respiration$umol.sec.corr * 3600) / SA_post_wound
   ```

---

### F. Gross Photosynthesis & P:R Ratio

**Current Pipeline:**
- ❌ **NOT CALCULATED**

**Reference Method (from attached document):**

> "Gross photosynthesis (PGross) was calculated as PNet plus respiration (as a positive value)"

> "I calculated daily P:R ratios from hourly rates of PGross and respiration (R) for a 11h:13h day:night cycle (the length of light and dark hours in Moorea during austral winter) with the following equation:
>
> **Daily P:R = 11 × PGross h⁻¹ / 13 × Respiration h⁻¹**"

> "A ratio greater than 1 can be indicative of net autotrophy, suggesting a coral is producing more energy than it demands. A ratio of less than 1 suggests net heterotrophy"

**Reference Code:**
```r
# Calculate P_gross
rates_combined$P_gross <- rates_combined$P_net + abs(rates_combined$R)

# Calculate P:R ratio (11hr light, 13hr dark)
rates_combined$PR_ratio <- (11 * rates_combined$P_gross) / (13 * abs(rates_combined$R))
```

**⚠️ MEDIUM PRIORITY:** These are key metabolic indicators that should be included in analysis

---

## 2. SURFACE AREA CALCULATIONS

### A. Wax Dipping Calibration

**Current Pipeline (`03_process_surface_area.R`):**
```r
# Lines 5-10: ✅ CORRECT
calibration <- read.csv('20230712_wax_calibration.csv') %>%
  mutate(wax_weight_g = postwax_weight_g - prewax_weight_g) %>%
  mutate(cal_radius_cm = (diameter_mm / 2) / 10) %>%
  mutate(height_cm = height_mm / 10) %>%
  mutate(CSA_cm2 = (2*3.14*cal_radius_cm*height_cm) + 3.14*(cal_radius_cm)^2)

stnd.curve <- lm(CSA_cm2 ~ wax_weight_g, data=calibration)
smpls$CSA_cm2 <- stnd.curve$coefficients[2] * smpls$wax_weight_g +
                 stnd.curve$coefficients[1]
```

**Reference:**
```r
# Same approach
CSA_cm2 = 2πRH + πR²  # Cylinder curved surface + top circle
```

**Assessment:** ✅ **CORRECT** - Proper wax dipping method

---

### B. Initial Geometric Surface Area

**Current Pipeline:**
- ❌ **NOT FOUND** - No script calculates initial geometric surface area from branch measurements

**Reference Method (from attached document):**

> "Initial geometric surface area was obtained for each coral by measuring **branch length and width with digital calipers**, calculating CSA for each branch, and taking the **sum of branch surface areas** for each coral"

**Reference Code:**
```r
data <- read.csv("geometric_SA_initial.csv") %>%
  mutate(branch_height_cm = branch_height_mm / 10) %>%
  mutate(avg_diameter_mm = (diameter_base_mm + diameter_tip_mm) / 2) %>%
  mutate(radius_cm = (avg_diameter_mm/2) / 10) %>%
  mutate(radius_tip_cm = (diameter_tip_mm/2) / 10) %>%
  mutate(CSA_cm2 = 2*3.14*(radius_cm*branch_height_cm) +
                   3.14*(radius_tip_cm)^2)

# Sum all branches per coral
initial_SA <- data %>%
  group_by(coral_id) %>%
  summarize(SA = sum(CSA_cm2))
```

**⚠️ HIGH PRIORITY:** You need initial geometric SA for:
1. Normalizing initial respirometry measurements
2. Calculating wound-adjusted SA for post-wound measurements

---

### C. Wound Surface Area Adjustment

**Current Pipeline:**
- ❌ **NOT IMPLEMENTED**

**Reference Method (from attached document):**

> "O2 rates measured post-injury were standardized using **initial geometric surface area minus wound surface area** (i.e., the area of coral tissue removed or damaged by the injury)"

> "I calculate the amount of tissue removed with the formula for surface area of a cylinder (CSA) disregarding one of the circular faces: **CSA = 2πrh + πr²**"

**Required Implementation:**
```r
# Calculate wound area from wound dimensions
sample_info <- read.csv("sample_info.csv") %>%
  mutate(wound_radius_cm = (wound_diameter_mm / 2) / 10) %>%
  mutate(wound_height_cm = wound_length_mm / 10) %>%
  mutate(wound_area_cm2 = case_when(
    treatment == "abrasion" ~ 2*pi*wound_radius_cm*wound_height_cm + pi*wound_radius_cm^2,
    treatment == "fragmentation" ~ 2*pi*wound_radius_cm*wound_height_cm + pi*wound_radius_cm^2,
    treatment == "control" ~ 0
  ))

# Adjust surface area for post-wound timepoints
SA_adjusted <- initial_SA %>%
  left_join(sample_info, by = "coral_id") %>%
  mutate(SA_post_wound = SA - wound_area_cm2)
```

**⚠️ HIGH PRIORITY:** Essential for accurate post-wound metabolic rates

---

## 3. GROWTH CALCULATIONS

### A. Buoyant Weight Conversion

**Current Pipeline (`01_process_growth.R`):**
```r
# Lines 11-14: ✅ CORRECT FORMULA
w1 <- read.csv("20230527_initial.csv") %>%
  mutate(density_stopper = (air_weight_g * 0.9965) / (air_weight_g - fresh_weight_g)) %>%
  mutate(density_sw = (air_weight_g - salt_weight_g) / (air_weight_g / density_stopper)) %>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw)) %>%
  mutate(dry_mass_coral_g = vol_coral_cm3 * density_aragonite)
```

**Reference:**
```r
# Same formulas
density_stopper = 0.9965
vol_coral_cm3 = bouyantweight_g / (density_aragonite - density_sw)
dry_mass_coral_g = vol_coral_cm3 * density_aragonite
```

**Assessment:** ✅ **CORRECT** - Proper Davies 1989 method

**⚠️ MEDIUM ISSUE:** Aragonite density not explicitly set

**Reference Method (from attached document):**

> "Dry skeletal mass was derived from coral buoyant weights (Davies 1989) using an **aragonite density of 2.93** (Jokiel 1978)"

**Fix:**
```r
density_aragonite <- 2.93  # g/cm³

w1 <- read.csv("20230527_initial.csv") %>%
  mutate(density_stopper = (air_weight_g * 0.9965) / (air_weight_g - fresh_weight_g)) %>%
  mutate(density_sw = (air_weight_g - salt_weight_g) / (air_weight_g / density_stopper)) %>%
  mutate(vol_coral_cm3 = weight_g / (density_aragonite - density_sw)) %>%
  mutate(dry_mass_coral_g = vol_coral_cm3 * density_aragonite)
```

---

### B. Growth Rate Normalization

**Current Pipeline (`01_process_growth.R`):**
```r
# Lines 106-118: ❌ WRONG NORMALIZATION
growth_por <- por_weights %>%
  mutate(growth_g = final - postwound) %>%
  mutate(g_day = (growth_g/23))

full_por <- left_join(growth_por, sampinfo, by = "coral_id") %>%
  mutate(growth_g_norm = growth_g / initial) %>%  # Normalizing by initial WEIGHT
  mutate(growth_norm_day = (growth_g_norm/23))
```

**Units:** Dimensionless ratio (final weight / initial weight per day)

**Reference Method (from attached document):**

> "I quantified calcification rate by taking the difference in dry skeletal mass (final – initial) of each coral fragment and **normalizing by final surface area and time** (19 days) to report as **mg cm⁻² day⁻¹**"

**Reference Code:**
```r
# Merge with final SA from wax dipping
growth <- all_weights %>%
  left_join(final_SA, by='coral_id') %>%
  mutate(growth_g = final - hr24) %>%  # Note: final - 24hr (not initial)
  mutate(growth_mg = growth_g * 1000) %>%
  mutate(mg_cm2_day = growth_mg / (19 * SA))  # mg / (days × cm²)
```

**⚠️ HIGH PRIORITY:** Incorrect normalization approach

**Required Changes:**
1. Calculate growth from 24hr post-wound, not initial
2. Normalize by FINAL surface area (from wax dipping), not weight
3. Use units of mg/cm²/day

**Why This Matters:**
- Surface area normalization allows comparison across different sized corals
- Using final SA accounts for actual growth during the experiment
- Standard reporting units for coral calcification rates

---

## 4. PAM FLUOROMETRY

**Current Pipeline (`02_process_pam.R`):**
```r
# Processing appears correct, but not reviewed in detail
# Calculates Fv/Fm = (fm - f0) / fm
```

**Reference Method (from attached document):**

> "I also measured photosynthetic efficiency (Fv/Fm) of each coral throughout the study (day 0, 10, 19) with an Underwater Fluorometer Diving-PAM"

> "Corals were dark acclimated before measuring photosynthetic efficiency by taking measurements **30 minutes to an hour after sunset**"

> "**Three measurements were taken per coral and averaged** to produce a single Fv/Fm value"

**Assessment:** ✅ Likely correct, but verify:
1. Dark acclimation documented
2. Three measurements per coral averaged
3. Timepoints align (day 0, 10, 19 vs your timepoints)

---

## 5. STATISTICAL ANALYSIS

### Current Approach

**From `Wound_Respiration_Analysis.Rmd`:**
```r
# Growth model
lm(growth_normalized ~ treatment, data = growth_data)

# Repeated measures
lmer(response ~ treatment * timepoint + (1|coral_id), data = data)

# Pairwise comparisons
emmeans(model, pairwise ~ treatment | timepoint, adjust = "tukey")
```

### Reference Method (from attached document)

> "I fit linear mixed models to respiration, net photosynthesis, gross photosynthesis, daily P:R, and photosynthetic efficiency with **injury** (non-injured, abrasion, or fragmentation), **temperature** (ambient or warming), **time** (1st, 10th, or 19th day), and all **two-way interactions** and a **three way interaction** between injury, temperature, and time as fixed effects using the lme4 package"

> "**Parental colony** was included as a random effect, with **individual coral nested within parental colony** to allow random intercepts for each coral individual"

**Reference Models:**
```r
# Full model structure
model <- lmer(response ~ injury * temperature * time +
              (1|parental_colony/coral_id),
              data = data)

# For growth (no time component)
model <- lmer(calcification_rate ~ injury * temperature +
              (1|parental_colony),
              data = growth_data)
```

**⚠️ MEDIUM PRIORITY DIFFERENCES:**

1. **Temperature not included** - Your experiment was at "controlled temperature" (per your description), so this is acceptable if truly a single temperature

2. **Parental colony structure** - Do you have parental colony information? If so, should include as random effect

3. **Three-way interaction** - Should test `treatment * timepoint * temperature` if temperature varied

---

## 6. MISSING DATA PROCESSING

### Not Found in Current Pipeline:

1. **Initial geometric surface area calculation** from branch measurements
   - Need: Branch length, diameter measurements
   - Calculate CSA per branch, sum for each coral

2. **Wound area calculations** from treatment information
   - Need: Wound dimensions (length, diameter)
   - Calculate CSA of removed tissue

3. **P:R ratio calculations**
   - Need: Combine photosynthesis and respiration
   - Calculate daily metabolic budget

4. **Quality control filtering**
   - Reference removed compromised corals
   - Should document any removed samples

---

## SUMMARY OF REQUIRED FIXES

### Priority 1 (CRITICAL - Affects Core Results):

1. **Fix respirometry normalization**
   - Change from `umol.g.hr` (weight) to `umol.cm2.hr` (surface area)
   - Requires initial geometric SA calculations

2. **Fix respiration time window**
   - Currently measuring during light phase (10-25 min)
   - Should measure during dark phase (>25 min)
   - Need separate processing for R vs. P

3. **Fix growth normalization**
   - Change from weight ratio to `mg/cm2/day`
   - Normalize by final SA (from wax dipping)
   - Calculate from 24hr post-wound, not initial

### Priority 2 (HIGH - Important for Accuracy):

4. **Calculate initial geometric surface area**
   - Need branch measurement data
   - Sum branches per coral
   - Use for initial timepoint normalization

5. **Calculate wound-adjusted surface area**
   - Calculate wound area from treatment dimensions
   - Subtract from initial SA
   - Use for post-wound timepoint normalization

6. **Specify aragonite density**
   - Add `density_aragonite <- 2.93` explicitly

### Priority 3 (MEDIUM - Adds Important Metrics):

7. **Calculate gross photosynthesis**
   - P_gross = P_net + |R|

8. **Calculate P:R ratios**
   - Daily P:R = (11 × P_gross) / (13 × R)
   - Key indicator of metabolic state

9. **Consider parental colony structure**
   - Add to random effects if data available

---

## DATA FILES NEEDED

To implement fixes, you need:

1. **Initial branch measurements CSV:**
   ```
   coral_id, branch_number, length_mm, diameter_base_mm, diameter_tip_mm
   ```

2. **Wound dimensions CSV (or add to sample_info.csv):**
   ```
   coral_id, treatment, wound_type, wound_length_mm, wound_diameter_mm
   ```

3. **Parental colony information (optional):**
   ```
   coral_id, parental_colony
   ```

---

## REFERENCES

**Methods Document:** Attached "Coral processing and experimental design" section

**Key Citations:**
- Davies 1989 - Buoyant weight method
- Jokiel 1978 - Aragonite density (2.93 g/cm³)
- Olito et al. 2017 - LoLinR package
- Barott et al. 2021; Innis et al. 2021 - Light-enhanced dark respiration

**Reference Pipeline:**
- `/archive/similar analysis/Acropora_Regeneration-main/`
- Key scripts: `PR.rates.3.R`, `Growth.2.R`, `SA_calculation.R`

---

## NEXT STEPS

1. **Immediate:** Review and confirm data availability
   - Do you have initial branch measurements?
   - Do you have wound dimensions recorded?

2. **High Priority:** Fix respirometry processing
   - Separate R and P processing scripts
   - Add SA normalization
   - Recalculate all rates

3. **Medium Priority:** Update growth calculations
   - Add final SA normalization
   - Change units to mg/cm²/day

4. **Documentation:** Update README with correct methods
   - Document all normalization approaches
   - Add references to methods paper

Would you like me to proceed with implementing these fixes?
