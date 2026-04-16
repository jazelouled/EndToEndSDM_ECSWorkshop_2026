# ---------------------------------------------------------
# CREATE OCEAN MASK FROM CROPPED BATHYMETRY
# ---------------------------------------------------------
# 1 = ocean
# 0 = land
# ---------------------------------------------------------

suppressPackageStartupMessages({
  library(terra)
  library(here)
})

message("Creating ocean mask...")

# ---------------------------------------------------------
# PATHS (RELATIVE)
# ---------------------------------------------------------

bathy_file <- here(
  "00inputOutput", "00input", "00rawData",
  "00enviro", "00StaticLayers",
  "bathymetry_wmed.tif"
)

oceanmask_dir <- here(
  "00inputOutput", "00input", "00rawData",
  "00enviro"
)

dir.create(oceanmask_dir, recursive = TRUE, showWarnings = FALSE)

oceanmask_file <- file.path(oceanmask_dir, "oceanmask.tif")

# ---------------------------------------------------------
# READ BATHYMETRY
# ---------------------------------------------------------

if (!file.exists(bathy_file)) {
  stop("Bathymetry file not found: ", bathy_file)
}

bathy <- rast(bathy_file)

message("Bathymetry loaded")
message("Resolution: ", paste(res(bathy), collapse = " x "))
message("Extent: ", paste(ext(bathy)))

# ---------------------------------------------------------
# CREATE MASK
# ---------------------------------------------------------
# Ocean = depth < 0
# Land  = depth >= 0 or NA
# ---------------------------------------------------------

oceanmask <- ifel(!is.na(bathy) & bathy < 0, 1, 0)

names(oceanmask) <- "oceanmask"

# ---------------------------------------------------------
# SAVE
# ---------------------------------------------------------

writeRaster(
  oceanmask,
  filename = oceanmask_file,
  overwrite = TRUE
)

message("Ocean mask saved at:")
message(oceanmask_file)