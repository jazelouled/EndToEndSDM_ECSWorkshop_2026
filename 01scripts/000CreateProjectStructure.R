# =========================================================
# CREATE ECS WORKSHOP PROJECT STRUCTURE
# =========================================================

project_dir <- "~/Dropbox/2026_ECS_WorkshopSDM"

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
  "01scripts"
)

# ---------------------------------------------------------
# FILES
# ---------------------------------------------------------

files <- c(
  
  "00README.md",
  ".gitignore",
  
  "01scripts/00main.R",
  "01scripts/01packages.R",
  "01scripts/02functions.R",
  
  "01scripts/10downloadCMEMS.R",
  "01scripts/11downloadCMIP6.R",
  
  "01scripts/20prepareStaticLayers.R",
  "01scripts/21prepareCMEMS.R",
  "01scripts/22prepareCMIP6.R",
  "01scripts/23buildPresentStack.R",
  "01scripts/24buildFutureStack.R",
  
  "01scripts/30importOccurrences.R",
  "01scripts/31cleanOccurrences.R",
  "01scripts/32generatePseudoAbsences.R",
  "01scripts/33extractEnvironmentalData.R",
  "01scripts/34buildModellingTable.R",
  
  "01scripts/40partitionData.R",
  "01scripts/41fitRF.R",
  "01scripts/42fitGBM.R",
  "01scripts/43evaluateModels.R",
  
  "01scripts/50predictPresent.R",
  "01scripts/51predictFuture.R",
  "01scripts/52mapPredictions.R",
  "01scripts/53mapChanges.R",
  
  "01scripts/99sessionInfo.R"
)

# ---------------------------------------------------------
# CREATE ROOT
# ---------------------------------------------------------

dir.create(project_dir, recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------
# CREATE DIRECTORIES
# ---------------------------------------------------------

for (d in dirs) {
  
  dir.create(
    file.path(project_dir, d),
    recursive = TRUE,
    showWarnings = FALSE
  )
  
}

# ---------------------------------------------------------
# CREATE FILES
# ---------------------------------------------------------

for (f in files) {
  
  file.create(
    file.path(project_dir, f),
    showWarnings = FALSE
  )
  
}

# ---------------------------------------------------------
# DONE
# ---------------------------------------------------------

cat("Project structure created successfully.\n")