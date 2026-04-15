# End-to-End SDM Workshop (ECS 2026)

This repository contains all the material needed to run an end-to-end Species Distribution Modelling (SDM) workflow, from raw tracking data to habitat predictions.

The workshop is designed to guide participants through the full pipeline:
- Tracking data processing
- Environmental data preparation
- Building presence–absence datasets
- Fitting machine learning models
- Predicting habitat in space and time

---

## 🚀 Getting Started

### 1. Clone the repository

git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git  
cd YOUR_REPO

---

### 2. Download required data

Some large input files are not stored directly in the repository.

### Bathymetry data

Download the bathymetry files from:

https://www.dropbox.com/scl/fo/qfywr8sc6p9bsmq1t3hwl/ADtf0NygMCTpLFFULwV4vKE?rlkey=j3q75cr9xdmuq0fowamip8k27&dl=0

Place the files inside:

00inputOutput/00input/00rawData/00enviro/00StaticLayers/

---

## 📂 Project Structure

01scripts/  
  ├── 00enviro/         Environmental data processing  
  ├── 01tracking/       Tracking data processing  
  └── 02habitatModel/   Modelling and predictions  

00inputOutput/  
  ├── 00input/          Raw and processed data  
  └── 01output/         Results (figures, rasters, models, tables)  

---

## 🧭 Workflow Overview

### 1. Tracking data processing

00_L0_read_and_standardize_Balaenoptera_artificialis_tracking.R  
01_L0_spaceTime_histograms_Balaenoptera_artificialis.R  
02_L1_douglas_speed_filter_Balaenoptera_artificialis_from_L0.R  
03_L1_spacetime_split_Balaenoptera_artificialis.R  
04_L2_ssm_by_segment_Balaenoptera_artificialis_QC_routePath.R  
05_simulations_tracks_Balaenoptera_artificialis.R  
06_presAbs_grid_balancing_Balaenoptera_artificialis.R  

Goal: transform raw tracking data into a clean, structured presence–absence dataset suitable for modelling.

---

### 2. Environmental data processing

00_oceanMask.R  
01_downloadCMEMS.R  
01_downloadCMEMS.sh  
02_downloadCMIP6.R  
03_prepareStaticLayers.R  
04_prepareCMEMS.R  
05_prepareCMIP6.R  
06_buildPresentStack.R  
07_buildFutureStack.R  

Goal: prepare environmental predictors and build spatio-temporally aligned raster stacks.

---

### 3. Habitat modelling

41fitRF.R  
42fitGBM.R  
43evaluateModels.R  
50predictPresent.R  
51predictFuture.R  
52mapPredictions.R  
53mapChanges.R  

Goal: fit models, evaluate them, and generate spatial predictions under present and future scenarios.

---

## ▶️ Running the full workflow

source("01scripts/00_main.R")

Or run scripts step by step following the order above.

---

## ⚙️ Requirements

- R (≥ 4.0)
- Required R packages (terra, sf, tidyverse, aniMotum, caret, etc.)
- Git
- Copernicus Marine Toolbox (copernicusmarine)

---

## 💡 Notes

- Models simplify reality — their usefulness depends on data quality and assumptions  
- The workflow is modular and reproducible  
- Feel free to explore, modify, and extend the scripts  

---