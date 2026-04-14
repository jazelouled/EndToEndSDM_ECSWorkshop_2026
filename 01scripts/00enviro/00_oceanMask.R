# ---------------------------------------------------------
# CREATE OCEAN MASK FROM CROPPED BATHYMETRY
# ---------------------------------------------------------
# 1 = ocean
# 0 = land
# Using the cropped bathymetry so the mask matches the study area
# ---------------------------------------------------------

oceanmask_dir <- "/Users/jazelouled-cheikhbonan/Dropbox/2026_ECS_WorkshopSDM/EndToEndSDM_ECSWorkshop_2026/00inputOutput/00input/00rawData/00enviro"
dir.create(oceanmask_dir, recursive = TRUE, showWarnings = FALSE)

oceanmask_file <- file.path(oceanmask_dir, "oceanmask.tif")

# If marine bathymetry is negative and land is NA or >= 0:
oceanmask <- ifel(!is.na(bathy) & bathy < 0, 0, 1)
names(oceanmask) <- "oceanmask"

writeRaster(
  oceanmask,
  filename = oceanmask_file,
  overwrite = TRUE
)

message("Ocean mask created from cropped bathymetry and saved at:")
message(oceanmask_file)