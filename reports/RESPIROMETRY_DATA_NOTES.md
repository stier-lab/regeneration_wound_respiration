# Respirometry Data Quality Notes

**Date:** 2025-10-27

---

## Blank Correction Issues

### Problem Identified

During respiration measurements, blank chambers (no coral) should show O₂ **decreasing** in the dark due to microbial respiration. However, for some timepoints, one blank chamber showed O₂ **increasing**, suggesting residual photosynthesis.

### Affected Timepoints

**Day 7 (20230603):**
- Blank 0 (coral_id = 0): +0.0065 umol/sec (O₂ increasing - ABNORMAL)
- Blank 1 (coral_id = 1): -0.00019 umol/sec (O₂ decreasing - NORMAL)

**Day 23 (20230619):**
- Similar pattern observed

### Likely Cause

**Residual symbiont photosynthesis:** Even in "dark" conditions, if there's any ambient light, Symbiod

iniaceae algae can photosynthesize. This is a known phenomenon in coral respirometry and is why strict light control is critical.

### Solution Implemented

**For timepoints with compromised blanks (20230603, 20230619):**
- **ALL corals assigned to blank 1** (the reliable blank showing O₂ decrease)
- This provides conservative blank correction
- Alternative would be to exclude these timepoints, but data is valuable

**For timepoints with good blanks (20230526, 20230528):**
- Used original blank assignments (half to blank 0, half to blank 1)

### Impact on Results

Using the photosynthesizing blank would have:
1. Made respiration rates appear artificially HIGH (more negative after correction)
2. Created systematic bias between corals assigned to different blanks
3. Produced unrealistic values

**Example calculation showing the problem:**
```
Coral actual respiration: -0.014 umol/sec (O₂ decreasing)
Bad blank (photosynthesizing): +0.0065 umol/sec (O₂ increasing)
Corrected rate: -0.014 - (+0.0065) = -0.0205 umol/sec (TOO NEGATIVE!)

Correct blank: -0.0002 umol/sec
Corrected rate: -0.014 - (-0.0002) = -0.0138 umol/sec (realistic)
```

### Recommendations for Future Studies

1. **Strict light exclusion** - Use blackout fabric, not just turning off lights
2. **Monitor blank O₂ trends** - Check that blanks show expected O₂ decrease
3. **Multiple blanks** - Run 3-4 blanks per run to identify outliers
4. **Blank validation** - Visually inspect blank chambers for algae/biofilm

---

## Data Quality Flags

### High Quality
- ✅ 20230526 (Initial) - Both blanks behaving normally
- ✅ 20230528 (Post-wound day 1) - Both blanks behaving normally

### Compromised Blanks (still usable with single blank correction)
- ⚠️ 20230603 (Day 7) - Blank 0 showing photosynthesis, used blank 1 only
- ⚠️ 20230619 (Day 23) - Blank 0 showing photosynthesis, used blank 1 only

### Notes for Analysis

- Rates from compromised timepoints are **still valid** but have **higher uncertainty**
- Consider adding timepoint as random effect in statistical models
- Report blank correction method in methods section

---

## LoLinR Rate Calculation

The LoLinR package (Olito et al. 2017) identifies the most linear segment of the O₂ time series using density-based local regression. This automatically:
- Avoids noisy data at beginning/end of measurement
- Identifies stable respiration rates
- Provides robust slope estimates

**Parameters used:**
- `alpha = 0.5` - Minimum 50% of data used for regression
- `method = "pc"` - Percentile-based method (most robust)

### Quality Control

Each LoLinR run generates diagnostic plots showing:
1. Original O₂ trace
2. Thinned data (every 5th point)
3. Selected linear segment
4. Regression fit

These plots are saved to `data/processed/respirometry/Porites/[timepoint]/` for manual inspection if needed.

---

## Surface Area Normalization

**Critical:** Respiration rates **MUST** be normalized by surface area, not weight.

**Why:**
- Gas exchange occurs at coral surface
- Skeleton (bulk of weight) is metabolically inactive
- Surface area correlates with tissue/symbiont biomass

**Units:**
- Correct: `umol O₂ cm⁻² hr⁻¹`
- Incorrect: `umol O₂ g⁻¹ hr⁻¹` (includes inactive skeleton mass)

### Surface Area Sources

**Initial timepoint (20230526):**
- Use: `initial_SA.csv` (final SA as proxy)

**Post-wound timepoints (20230528, 20230603, 20230619):**
- Use: `postwound_SA.csv` (final SA - wound area)
- Accounts for tissue removed by wounding

---

## Expected Rate Ranges

Based on literature for similar corals at ~28°C:

**Respiration:**
- Typical: 0.5 - 3.0 umol O₂ cm⁻² hr⁻¹
- High stress: 3.0 - 5.0 umol O₂ cm⁻² hr⁻¹
- FLAG if: > 10 umol O₂ cm⁻² hr⁻¹ (likely calculation error)

**Net Photosynthesis:**
- Typical: 2.0 - 8.0 umol O₂ cm⁻² hr⁻¹
- Light-saturated: 10 - 20 umol O₂ cm⁻² hr⁻¹

**P:R Ratio (daily budget):**
- Autotrophic: > 1.2
- Balanced: 0.8 - 1.2
- Heterotrophic: < 0.8

---

## References

- Olito et al. 2017. Estimating monotonic rates from biological data using local linear regression. *Journal of Experimental Biology* 220: 759-764.
- Barott et al. 2021. Coral bleaching response is unaltered following acclimatization to reefs with distinct environmental conditions. *PNAS* 118: e2025435118.
- Davies 1989. Short-term growth measurements of corals using an accurate buoyant weighing technique. *Marine Biology* 101: 389-395.

---

**Last Updated:** 2025-10-27
**Contact:** Check with lab PI before publishing these data
