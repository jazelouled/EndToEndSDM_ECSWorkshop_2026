# =========================================================
# CREATE ECS WORKSHOP PROJECT STRUCTURE
# =========================================================

project_dir <- "~/Dropbox/2026_ECS_WorkshopSDM/EndToEndSDM_ECSWorkshop_2026"

# ---------------------------------------------------------
# DIRECTORY STRUCTURE
# ---------------------------------------------------------

dirs <- c(
  
  # MAIN
  "00inputOutput",
  
  # INPUT
  "00inputOutput/00input",
  "00inputOutput/00input/00rawData",
  "00inputOutput/00input/00rawData/00CMEMS",
  "00inputOutput/00input/00rawData/01CMIP6",
  "00inputOutput/00input/00rawData/02Occurrences",
  "00inputOutput/00input/00rawData/03StaticLayers",
  
  "00inputOutput/00input/01processedData",
  "00inputOutput/00input/01processedData/00Environmental",
  "00inputOutput/00input/01processedData/01Species",
  "00inputOutput/00input/01processedData/02ModellingTables",
  
  # OUTPUT
  "00inputOutput/01output",
  "00inputOutput/01output/00figures",
  "00inputOutput/01output/01rasters",
  "00inputOutput/01output/02models",
  "00inputOutput/01output/03tables",
  "00inputOutput/01output/04logs",
  
  # SCRIPTS
  "01scripts",
  "01scripts/00enviro",
  "01scripts/01tracking",
  "01scripts/02habitatModel"
)

# ---------------------------------------------------------
# FILES
# ---------------------------------------------------------

files <- c(
  
  "00README.md",
  ".gitignore",
  
  # MAIN (first alphabetically inside scripts)
  "01scripts/00_main.R",
  
  # ENVIRO
  "01scripts/00enviro/10downloadCMEMS.R",
  "01scripts/00enviro/11downloadCMIP6.R",
  "01scripts/00enviro/20prepareStaticLayers.R",
  "01scripts/00enviro/21prepareCMEMS.R",
  "01scripts/00enviro/22prepareCMIP6.R",
  "01scripts/00enviro/23buildPresentStack.R",
  "01scripts/00enviro/24buildFutureStack.R",
  
  # TRACKING
  "01scripts/01tracking/00_L0_read_and_standardize_simulatedSpecies_tracking.R",
  "01scripts/01tracking/01_L0_spaceTime_histograms_simulatedSpecies.R",
  "01scripts/01tracking/02_L1_douglas_speed_filter_simulatedSpecies_from_L0.R",
  "01scripts/01tracking/03_L1_spacetime_split_simulatedSpecies.R",
  "01scripts/01tracking/04_L2_ssm_by_segment_simulatedSpecies_QC_routePath.R",
  "01scripts/01tracking/05_simulations_tracks_simulatedSpecies.R",
  "01scripts/01tracking/06_presAbs_grid_balancing_simulatedSpecies.R",
  
  # HABITAT MODEL
  "01scripts/02habitatModel/30importOccurrences.R",
  "01scripts/02habitatModel/31cleanOccurrences.R",
  "01scripts/02habitatModel/32generatePseudoAbsences.R",
  "01scripts/02habitatModel/33extractEnvironmentalData.R",
  "01scripts/02habitatModel/34buildModellingTable.R",
  "01scripts/02habitatModel/40partitionData.R",
  "01scripts/02habitatModel/41fitRF.R",
  "01scripts/02habitatModel/42fitGBM.R",
  "01scripts/02habitatModel/43evaluateModels.R",
  "01scripts/02habitatModel/50predictPresent.R",
  "01scripts/02habitatModel/51predictFuture.R",
  "01scripts/02habitatModel/52mapPredictions.R",
  "01scripts/02habitatModel/53mapChanges.R",
  "01scripts/02habitatModel/99sessionInfo.R"
)

# ---------------------------------------------------------
# CREATE ROOT
# ---------------------------------------------------------

dir.create(project_dir, recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------
# CREATE DIRECTORIES
# ---------------------------------------------------------

for (d in dirs) {
  dir.create(file.path(project_dir, d), recursive = TRUE, showWarnings = FALSE)
}

# ---------------------------------------------------------
# CREATE FILES
# ---------------------------------------------------------

for (f in files) {
  file.create(file.path(project_dir, f), showWarnings = FALSE)
}

# ---------------------------------------------------------
# DONE
# ---------------------------------------------------------

cat("Project structure created successfully.\n")