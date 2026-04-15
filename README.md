# End-to-End SDM Workshop (ECS 2026)

This repository contains all the material needed to run an end-to-end Species Distribution Modelling workflow, from raw tracking data to habitat predictions.

The workshop is designed to guide participants through the full pipeline:
- tracking data processing
- environmental data preparation
- building presence-absence datasets
- fitting machine learning models
- predicting habitat in space and time


## Getting started

### 1. Clone the repository

```bash
git clone git@github.com:jazelouled/EndToEndSDM_ECSWorkshop_2026.git
cd EndToEndSDM_ECSWorkshop_2026
```

### 2. Download required data

Some large input files are not stored directly in the repository.

### Bathymetry data

Download the bathymetry files from:

https://www.dropbox.com/scl/fo/qfywr8sc6p9bsmq1t3hwl/ADtf0NygMCTpLFFULwV4vKE?rlkey=j3q75cr9xdmuq0fowamip8k27&dl=0

Place the files inside:

```
00inputOutput/00input/00rawData/00enviro/00StaticLayers/
```


## Project structure

```
EndToEndSDM_ECSWorkshop_2026/
│
├── 00README.md
├── EndToEndSDM_Workshop_Presentation.pptx
│
├── 00inputOutput/
│   ├── 00input/
│   │   ├── 00rawData/
│   │   │   ├── 00enviro/
│   │   │   │   ├── 00StaticLayers/
│   │   │   │   ├── 01CMEMS/
│   │   │   │   ├── 02CMIP6/
│   │   │   │   └── oceanmask.tif
│   │   │   │
│   │   │   └── 01tracking/
│   │   │       ├── simulated_tracking_final.csv
│   │   │       └── 00auxiliaryFiles/
│   │   │
│   │   └── 01processedData/
│   │       ├── 00enviro/
│   │       │   ├── 00staticLayers/
│   │       │   ├── 01dynamicLayers/
│   │       │   ├── 02presentStacks/
│   │       │   └── 03futureStacks/
│   │       │
│   │       └── 00tracking/
│   │           ├── 00L0_data/
│   │           ├── 02L1_douglas/
│   │           │   ├── L1_filtered/
│   │           │   ├── L1_withFlags/
│   │           │   └── plots/
│   │           │
│   │           ├── 03L1_spaceTimeSplit/
│   │           ├── 04L2_ssm_behaviour/
│   │           ├── 05simulations_Behaviour/
│   │           └── 06PresAbs_grid/
│   │
│   └── 01output/
│       ├── 00figures/
│       ├── 01rasters/
│       ├── 02models/
│       ├── 03tables/
│       └── 04logs/
│
├── 01scripts/
│   ├── 00_main.R
│   │
│   ├── 00enviro/
│   │   ├── 00_oceanMask.R
│   │   ├── 01_downloadCMEMS.R
│   │   ├── 01_downloadCMEMS.sh
│   │   ├── 02_downloadCMIP6.R
│   │   ├── 03_prepareStaticLayers.R
│   │   ├── 04_prepareCMEMS.R
│   │   ├── 05_prepareCMIP6.R
│   │   ├── 06_buildPresentStack.R
│   │   └── 07_buildFutureStack.R
│   │
│   ├── 01tracking/
│   │   ├── 00_L0_read_and_standardize_Balaenoptera_artificialis_tracking.R
│   │   ├── 01_L0_spaceTime_histograms_Balaenoptera_artificialis.R
│   │   ├── 02_L1_douglas_speed_filter_Balaenoptera_artificialis_from_L0.R
│   │   ├── 03_L1_spacetime_split_Balaenoptera_artificialis.R
│   │   ├── 04_L2_ssm_by_segment_Balaenoptera_artificialis_QC_routePath.R
│   │   ├── 05_simulations_tracks_Balaenoptera_artificialis.R
│   │   └── 06_presAbs_grid_balancing_Balaenoptera_artificialis.R
│   │
│   └── 02habitatModel/
│       ├── 41fitRF.R
│       ├── 42fitGBM.R
│       ├── 43evaluateModels.R
│       ├── 50predictPresent.R
│       ├── 51predictFuture.R
│       ├── 52mapPredictions.R
│       ├── 53mapChanges.R
│       └── 99sessionInfo.R
```


## Workflow overview

### Tracking data processing

```
00_L0_read_and_standardize_Balaenoptera_artificialis_tracking.R
01_L0_spaceTime_histograms_Balaenoptera_artificialis.R
02_L1_douglas_speed_filter_Balaenoptera_artificialis_from_L0.R
03_L1_spacetime_split_Balaenoptera_artificialis.R
04_L2_ssm_by_segment_Balaenoptera_artificialis_QC_routePath.R
05_simulations_tracks_Balaenoptera_artificialis.R
06_presAbs_grid_balancing_Balaenoptera_artificialis.R
```

Transforms raw tracking data into a clean and structured presence-absence dataset suitable for modelling.


### Environmental data processing

```
00_oceanMask.R
01_downloadCMEMS.R
01_downloadCMEMS.sh
02_downloadCMIP6.R
03_prepareStaticLayers.R
04_prepareCMEMS.R
05_prepareCMIP6.R
06_buildPresentStack.R
07_buildFutureStack.R
```

Prepares environmental predictors and builds spatio-temporally aligned raster stacks.


### Habitat modelling

```
41fitRF.R
42fitGBM.R
43evaluateModels.R
50predictPresent.R
51predictFuture.R
52mapPredictions.R
53mapChanges.R
```

Fits models, evaluates them, and generates spatial predictions under present and future scenarios.


## Running the full workflow

```r
source("01scripts/00_main.R")
```

Alternatively, run scripts step by step following the order above.


## Requirements

- R (4.0 or higher)
- Required R packages such as terra, sf, tidyverse, aniMotum, caret
- Git
- Copernicus Marine Toolbox (copernicusmarine)


## Notes

- Models simplify reality, so their usefulness depends on data quality and assumptions
- The workflow is modular and reproducible
- The repository is structured to clearly separate inputs, processing steps, and outputs
- Feel free to explore, modify, and extend the scripts