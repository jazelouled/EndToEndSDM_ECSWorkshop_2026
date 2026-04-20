# End-to-End SDM Workshop (ECS 2026)

This repository contains all the material needed to run an end-to-end Species Distribution Modelling (SDM) workflow, from raw tracking data to habitat suitability predictions.

<p align="center">
  <img src="workshopLogo.png" width="50%">
</p>

The workshop guides participants through a complete pipeline:

- tracking data processing  
- environmental data preparation  
- presence–absence dataset construction  
- model fitting (machine learning)  
- spatial and temporal prediction  


## Getting started

### 1. Clone the repository

```bash
git clone git@github.com:jazelouled/EndToEndSDM_ECSWorkshop_2026.git
cd EndToEndSDM_ECSWorkshop_2026
```

---

### 2. Prepare input data

Some large input files are not stored in the repository.

#### Bathymetry

Download from:

https://www.dropbox.com/scl/fi/e90xlk0ousn83qkpuwgoh/bathymetry_wmed.tif?rlkey=6dlp2qgayjvbg4hipn22xuo1n&dl=0

Place the file inside:

```
00inputOutput/00input/00rawData/00enviro/00StaticLayers/
```

#### Tracking data

Download from:

https://www.dropbox.com/scl/fi/lgr1izxp7ls9jn6waqxen/simulated_tracking_final.csv?rlkey=1hc94drsmj7e8zf04nm4jd6r6&dl=0

Place the file inside:

```
00inputOutput/00input/00rawData/01tracking/
```

Expected structure:

```
00inputOutput/
└── 00input/
    └── 00rawData/
        ├── 00enviro/
        │   └── 00StaticLayers/
        │       └── bathymetry_wmed.tif
        │
        └── 01tracking/
            ├── simulated_tracking_final.csv
            └── 00auxiliaryFiles/
                ├── bbox_env.txt
                └── tracking_dates.txt
```

---

## Project structure

```
EndToEndSDM_ECSWorkshop_2026/
│
├── 00README.md
│
├── 00inputOutput/
│   ├── 00input/
│   │   ├── 00rawData/
│   │   │   ├── 00enviro/
│   │   │   │   ├── 00StaticLayers/
│   │   │   │   ├── 01CMEMS/
│   │   │   │   └── oceanmask.tif
│   │   │   │
│   │   │   └── 01tracking/
│   │   │       └── 00auxiliaryFiles/
│   │   │
│   │   └── 01processedData/
│   │       ├── 00enviro/
│   │       │   ├── 02presentStacks/
│   │       │   └── 03futureStacks/
│   │       │
│   │       └── 01tracking/
│   │           ├── 00L0_data/
│   │           ├── 02L1_douglas/
│   │           ├── 03L1_spaceTimeSplit/
│   │           ├── 04L2_ssm_behaviour/
│   │           └── 06PresAbs_grid/
│   │
│   └── 01output/
│       ├── 00figures/
│       ├── 01rasters/
│       ├── 02models/
│       └── 03tables/
│
├── 01scripts/
│   ├── 00_main.R
│   │
│   ├── 00enviro/
│   │   ├── 00_oceanMask.R
│   │   ├── 01_downloadCMEMS.R
│   │   ├── 01_downloadCMEMS.sh
│   │   ├── 03_prepareStaticLayers.R
│   │   ├── 04_prepareCMEMS.R
│   │   └── 06_buildPresentStack.R
│   │
│   ├── 01tracking/
│   │   ├── 00_L0_read_and_standardize_Balaenoptera_artificialis_tracking.R
│   │   ├── 02_L1_douglas_speed_filter_Balaenoptera_artificialis_from_L0.R
│   │   ├── 03_L1_spacetime_split_Balaenoptera_artificialis.R
│   │   ├── 04_L2_ssm_by_segment_Balaenoptera_artificialis_QC_routePath.R
│   │   ├── 05_simulations_tracks_Balaenoptera_artificialis.R
│   │   └── 06_presAbs_grid_balancing_Balaenoptera_artificialis.R
│   │
│   └── 02habitatModel/
│       ├── 00_exploratoryDataAnalysis_Balaenoptera_artificialis
│       ├── 01_fitRF_Balaenoptera_artificialis
│       ├── 02_predictDaily_and_MeanSD_Balaenoptera_artificialis
│       └── 99sessionInfo.R
```
---

## Workflow overview

### Tracking data processing

```
00_L0_read_and_standardize_Balaenoptera_artificialis_tracking.R
02_L1_douglas_speed_filter_Balaenoptera_artificialis_from_L0.R
03_L1_spacetime_split_Balaenoptera_artificialis.R
04_L2_ssm_by_segment_Balaenoptera_artificialis_QC_routePath.R
05_simulations_tracks_Balaenoptera_artificialis.R
06_presAbs_grid_balancing_Balaenoptera_artificialis.R
```

Transforms raw tracking data into a structured presence–absence dataset.

---

### Environmental data processing

```
00_oceanMask.R
01_downloadCMEMS.R / 01_downloadCMEMS.sh
03_prepareStaticLayers.R
04_prepareCMEMS.R
06_buildPresentStack.R
```

Builds environmental predictors aligned in space and time.

---

### Habitat modelling

```
00_exploratoryDataAnalysis_Balaenoptera_artificialis.R
01_fitRF_Balaenoptera_artificialis.R
02_predictDaily_and_MeanSD_Balaenoptera_artificialis.R
99sessionInfo.R
```

Fits models and generates spatial predictions.

---

## Running the full workflow

```r
source("01scripts/00_main.R")
```

---

## Requirements

- R (≥ 4.0)
- Packages: terra, sf, tidyverse, aniMotum, caret, randomForest, ranger
- Git
- Copernicus Marine Toolbox (copernicusmarine)

---

## Notes

- The workflow is modular and reproducible  
- Input, processing, and outputs are clearly separated  
- Model outputs depend strongly on input data quality  
- The code is designed for teaching: clarity over optimization  