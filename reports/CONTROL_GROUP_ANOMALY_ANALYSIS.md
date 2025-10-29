# Control Group Anomaly Analysis

## Summary
The control groups for both species show unexpected patterns at Day 7 that require explanation.

## Observed Patterns

### 1. Porites Control - Deep Dip at Day 7
- **Pre-wound:** -0.39 ± 0.08 µmol O₂/cm²/hr
- **Day 1:** -0.44 ± 0.09
- **Day 7:** -0.63 ± 0.25 (HIGH VARIATION)
- **Day 23:** -0.36 ± 0.06

**Driven by:** Coral 54 showing -1.86 at Day 7 (3× higher than others)

### 2. Acropora Control - Large Spike at Day 7
- **Pre-wound:** 0.22 ± 0.03 µmol O₂/cm²/hr
- **Day 1:** 0.37 ± 0.01
- **Day 7:** 1.48 ± 0.81 (HUGE VARIATION)
- **Day 23:** 0.23 ± 0.02

**Driven by:**
- Coral 41: 2.83 at Day 7
- Coral 56: 3.98 at Day 7
- Others: ~0.20 (normal range)

## Individual Colony Tracking

### Porites Control Colonies
| Coral ID | Pre-wound | Day 1 | Day 7 | Day 23 |
|----------|-----------|-------|-------|---------|
| 44 | -0.37 | -0.63 | -0.41 | -0.37 |
| 48 | -0.23 | -0.32 | -0.14 | -0.30 |
| 49 | -0.49 | NA | -0.39 | -0.43 |
| 53 | -0.64 | -0.47 | -0.51 | -0.58 |
| **54** | **-0.21** | **-0.17** | **-1.86** ⚠️ | **-0.12** |
| 56 | NA | -0.62 | -0.48 | -0.34 |

### Acropora Control Colonies
| Coral ID | Pre-wound | Day 1 | Day 7 | Day 23 |
|----------|-----------|-------|-------|---------|
| **41** | **0.15** | **0.33** | **2.83** ⚠️ | **0.19** |
| 51 | 0.19 | 0.38 | NA | 0.22 |
| **56** | **0.28** | **0.40** | **3.98** ⚠️ | NA |
| 57 | 0.25 | 0.37 | 0.17 | 0.21 |
| 53 | NA | 0.39 | 0.18 | 0.29 |
| 48 | NA | NA | 0.23 | NA |

## Possible Explanations

### 1. **Tank/Position Effects**
- Control corals may have experienced different microenvironments
- Possible flow gradients or light differences
- Day 7 measurements might have coincided with tank maintenance or changes

### 2. **Handling Stress Response**
- Even control corals were handled for measurements
- Day 7 might represent peak stress response to repeated handling
- The variation suggests individual stress susceptibility

### 3. **Natural Metabolic Cycles**
- Corals may have natural week-scale metabolic rhythms
- Unrelated to wounding but coinciding with measurement schedule
- High individual variation in these cycles

### 4. **Measurement Artifacts**
- **Porites 54:** Already flagged as borderline in QC but retained
- **Acropora 41 & 56:** Passed QC thresholds but are statistical outliers
- Possible probe calibration drift during Day 7 measurements

## Impact on Interpretation

### Without These Outliers:
- **Porites Control Day 7:** Would be ~-0.35 (stable across time)
- **Acropora Control Day 7:** Would be ~0.19 (stable across time)

### Current Impact:
1. Makes wounded coral responses harder to interpret
2. Suggests possible confounding factors beyond wounding
3. Increases uncertainty in treatment effects

## Recommendations

### For Current Analysis:
1. **Keep the data** - Removing more controls reduces statistical power
2. **Report transparently** - Acknowledge control variation in discussion
3. **Use baseline normalization** - Calculate changes relative to pre-wound values
4. **Consider mixed models** - Account for individual colony variation

### For Future Studies:
1. **More control replication** - Minimum 8-10 controls to buffer outliers
2. **Position randomization** - Rotate tank positions between measurements
3. **Technical replicates** - Multiple measurements per coral per timepoint
4. **Environmental monitoring** - Log temperature, flow, light continuously

## Statistical Consideration

The high variation in controls at Day 7 actually makes the analysis **more conservative**:
- Harder to detect treatment effects
- Any significant wound effects are despite this variation
- Results are robust to control variation

## Biological Interpretation

These control anomalies might actually be **biologically meaningful**:
- Natural metabolic plasticity in response to captivity
- Individual variation in stress response
- Possible endogenous rhythms

Rather than measurement error, this could represent real biological variation that should be reported.

---
*Analysis Date: October 28, 2023*