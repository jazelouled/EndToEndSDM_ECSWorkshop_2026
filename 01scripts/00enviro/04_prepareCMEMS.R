# ============================================================
# SCRIPT NAME:
# 04_prepareCMEMS.R
#
# PURPOSE:
# Prepare daily dynamic environmental layers from the CMEMS
# files downloaded previously.
#
# WHAT THIS SCRIPT DOES:
# 1. Reads the raw CMEMS NetCDF files
# 2. Extracts the daily layers contained in each file
# 3. Crops them to the study area
# 4. Resamples them to the same grid as the static template
# 5. Masks them to marine cells only
# 6. Saves one GeoTIFF per variable and day
#
# EXAMPLE OUTPUTS:
# - sst_2015-02-15.tif
# - chl_2015-02-15.tif
#
# WHY THIS STEP IS USEFUL:
# Tracking data are points in space and time.
# To match each position with environmental conditions,
# we first need environmental rasters with:
# - a consistent extent
# - a consistent resolution
# - one layer per day
# ============================================================


# ============================================================
# 1. LOAD REQUIRED PACKAGES
# ============================================================

suppressPackageStartupMessages({
  library(terra)
  library(here)
  library(stringr)
})

message("Starting CMEMS daily layer preparation...")


# ============================================================
# 2. DEFINE INPUT AND OUTPUT PATHS
# ============================================================
# Input:
# - raw CMEMS NetCDF files previously downloaded
#
# Output:
# - processed daily rasters, one file per variable and date
# ============================================================

raw_cmems_dir <- here(
  "00inputOutput", "00input", "00rawData", "00enviro", "01CMEMS"
)

template_file <- here(
  "00inputOutput", "00input", "01processedData", "00enviro",
  "00staticLayers", "bathymetry_wmed.tif"
)

out_dynamic_dir <- here(
  "00inputOutput", "00input", "01processedData", "00enviro",
  "01dynamicLayers", "daily"
)

dir.create(out_dynamic_dir, recursive = TRUE, showWarnings = FALSE)

if (!dir.exists(raw_cmems_dir)) {
  stop("Raw CMEMS directory not found: ", raw_cmems_dir)
}

if (!file.exists(template_file)) {
  stop("Template file not found: ", template_file)
}


# ============================================================
# 3. READ TEMPLATE
# ============================================================
# We use the bathymetry raster as the spatial template.
# This ensures that all dynamic layers have:
# - the same extent
# - the same resolution
# - the same land/ocean mask
# ============================================================

template <- rast(template_file)

message("Template loaded.")
message("Template resolution: ", paste(res(template), collapse = " x "))
message("Template extent: ", paste(round(ext(template)), collapse = ", "))


# ============================================================
# 4. FIND ALL CMEMS NETCDF FILES
# ============================================================
# We assume all downloaded CMEMS files are stored here as .nc
# files.
# ============================================================

cmems_files <- list.files(
  raw_cmems_dir,
  pattern = "\\.nc$",
  full.names = TRUE
)

if (length(cmems_files) == 0) {
  stop("No NetCDF files found in: ", raw_cmems_dir)
}

message("Number of CMEMS files found: ", length(cmems_files))


# ============================================================
# 5. LOOP THROUGH ALL CMEMS FILES
# ============================================================
# For each file:
# - identify the variable
# - read all layers
# - loop through each daily layer
# - crop / resample / mask
# - save to disk
# ============================================================

for (i in seq_along(cmems_files)) {
  
  f <- cmems_files[i]
  bn <- basename(f)
  
  message("====================================")
  message("Processing file ", i, " of ", length(cmems_files))
  message("File: ", bn)
  
  # ----------------------------------------------------------
  # 5.1 Guess the variable name from the file name
  # ----------------------------------------------------------
  # This is a simple and transparent rule for the workshop.
  # Adjust if your filenames follow a different convention.
  #
  # Examples:
  # - file name containing "thetao" -> variable becomes "sst"
  # - file name containing "chl"    -> variable becomes "chl"
  # ----------------------------------------------------------
  
  var_out <- NA_character_
  
  if (str_detect(tolower(bn), "thetao")) var_out <- "sst"
  if (str_detect(tolower(bn), "sst"))    var_out <- "sst"
  if (str_detect(tolower(bn), "chl"))    var_out <- "chl"
  
  if (is.na(var_out)) {
    message("  Could not identify variable from filename -> skipping file")
    next
  }
  
  message("  Identified variable: ", var_out)
  
  # ----------------------------------------------------------
  # 5.2 Read the NetCDF as a SpatRaster
  # ----------------------------------------------------------
  # A NetCDF can contain one or several layers.
  # In this case, we assume that each layer corresponds to one day.
  # ----------------------------------------------------------
  
  r <- rast(f)
  
  if (nlyr(r) == 0) {
    message("  No layers found in file -> skipping")
    next
  }
  
  message("  Number of layers in file: ", nlyr(r))
  
  # ----------------------------------------------------------
  # 5.3 Try to recover layer dates from the time dimension
  # ----------------------------------------------------------
  # If terra can read the time dimension correctly, we use it.
  # Otherwise, we will generate simple fallback names.
  # ----------------------------------------------------------
  
  layer_time <- time(r)
  
  if (is.null(layer_time)) {
    message("  No time dimension detected. Using fallback layer indices.")
  } else {
    message("  Time dimension detected.")
  }
  
  # ----------------------------------------------------------
  # 5.4 Loop through all layers in the current file
  # ----------------------------------------------------------
  
  for (j in 1:nlyr(r)) {
    
    message("    Processing layer ", j, " of ", nlyr(r))
    
    # Extract one daily layer
    r_day <- r[[j]]
    
    # --------------------------------------------------------
    # 5.5 Assign an output date
    # --------------------------------------------------------
    # If the time dimension exists, use it.
    # Otherwise, create a fallback name using the layer index.
    # --------------------------------------------------------
    
    if (!is.null(layer_time)) {
      this_date <- as.Date(layer_time[j])
      date_label <- format(this_date, "%Y-%m-%d")
    } else {
      date_label <- paste0("layer_", str_pad(j, width = 3, pad = "0"))
    }
    
    # --------------------------------------------------------
    # 5.6 Crop to template extent
    # --------------------------------------------------------
    
    r_day <- crop(r_day, ext(template))
    
    # --------------------------------------------------------
    # 5.7 Resample to template grid
    # --------------------------------------------------------
    # Bilinear interpolation is appropriate for continuous
    # environmental variables such as temperature or chlorophyll.
    # --------------------------------------------------------
    
    r_day <- resample(r_day, template, method = "bilinear")
    
    # --------------------------------------------------------
    # 5.8 Mask to marine cells only
    # --------------------------------------------------------
    # The template bathymetry already has NA on land,
    # so masking with it removes terrestrial cells.
    # --------------------------------------------------------
    
    r_day <- mask(r_day, template)
    
    # Rename layer
    names(r_day) <- var_out
    
    # --------------------------------------------------------
    # 5.9 Save the processed daily raster
    # --------------------------------------------------------
    
    out_file <- file.path(
      out_dynamic_dir,
      paste0(var_out, "_", date_label, ".tif")
    )
    
    writeRaster(
      r_day,
      filename = out_file,
      overwrite = TRUE
    )
    
    message("      Saved: ", basename(out_file))
  }
}

message("====================================")
message("CMEMS daily layers prepared successfully.")
message("Output directory: ", out_dynamic_dir)
message("====================================")