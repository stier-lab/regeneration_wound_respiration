# Coral Respirometry: regeneration_wound_respiration experiment
 This repository houses the data and code for analysis of physiological measurements of wounded Porites sp. and Acropora pulchra. Physiological measurements include respiration and photosynthesis rates, photosynthetic efficiency (fv/fm), and growth. Experiments were conducted in Moorea, French Polynesia May-June 2023. 

## Repository structure
 regeneration_wound_respiration
  |_ Growth
    |_ Data
    |_ Output
    |_ Scripts
  |_ PAM
    |_ Data
    |_ Output
    |_ Scripts
  |_ rawdata
      |_ outputs
      |_ raw
  |_ Respirometry
      |_ Data
        |_ chamber_volumes
        |_ Runs
          |_ 20230525
          |_ 20230526
          |_ 20230528
          |_ 20230603
          |_ 20230619
      |_ Output
        |_Porites
          |_ Photosynthesis
            |_ 20230526
            |_ 20230528
            |_ 20230603
            |_ 20230619
          |_ Respiration
            |_ 20230526
            |_ 20230528
            |_ 20230603
            |_ 20230619
            |_ rates
      |_ scripts
  |_ Surface_Area
      |_ Data
      |_ Output
      |_ Scripts
  |_ sample_info
  
  
 ## Data 
-   `Growth/Output/`: Contains cleaned data sets of coral skeletal weight at each time point of experiment.
-   `PAM/Output/`: Contains cleaned data set of all replicated fvfm measurements and a cleaned data set of averaged fvfm values.
-   `rawdata/`: Houses all raw data sheets which cleaned data sets are generated from. 
-   `Respirometry/Output`: Contains respiration and photosynthesis rates including result summary figures of rate estimations 
-   `Surface_Area/`: Contains data, SA outputs, and SA analysis scripts for normalizing physiological measurements 
