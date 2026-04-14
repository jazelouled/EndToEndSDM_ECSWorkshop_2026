# ============================================================
# SCRIPT NAME:
# 06_buildPresentStack.R
#
# PURPOSE:
# Build one environmental stack per day for the present period.
#
# Each daily stack will contain:
# - static variables (same every day)
# - dynamic variables (change every day)
# - selected gradients (temperature and salinity only)
#
# EXAMPLE:
# For a given day, one stack may contain:
# - bathymetry
# - slope
# - distance_to_coast
# - sst
# - sst_gradient
# - so
# - so_gradient
# - chl
#
# WHY THIS STEP IS USEFUL:
# Tracking data are matched to environmental conditions in space
# and time. To do that efficiently, it is useful to build one
# environmental raster stack per day.
#
# INPUT:
# - static layers already prepared
# - daily dynamic layers already prepared
#
# OUTPUT:
# - one multilayer environmental stack per date
# ============================================================


# ============================================================
# 1. LOAD REQUIRED PACKAGES
# ============================================================

suppressPackageStartupMessages({
  library(terra)
  library(here)
  library(stringr)
})

message("Starting present-day environmental stack building...")


# ============================================================
# 2. DEFINE INPUT AND OUTPUT PATHS
# ============================================================

static_dir <- here(
  "00inputOutput", "00input", "01processedData", "00enviro",
  "00staticLayers"
)

dynamic_dir <- here(
  "00inputOutput", "00input", "01processedData", "00enviro",
  "01dynamicLayers", "daily"
)

out_dir <- here(
  "00inputOutput", "00input", "01processedData", "00enviro",
  "02presentStacks"
)

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!dir.exists(static_dir)) {
  stop("Static layer directory not found: ", static_dir)
}

if (!dir.exists(dynamic_dir)) {
  stop("Dynamic layer directory not found: ", dynamic_dir)
}


# ============================================================
# 3. READ STATIC LAYERS
# ============================================================

message("Reading static layers...")

# ------------------------------------------------------------
# 3.1 Bathymetry
# ------------------------------------------------------------

bath_file <- file.path(static_dir, "bathymetry_wmed.tif")

if (!file.exists(bath_file)) {
  stop("Bathymetry file not found: ", bath_file)
}

bathymetry <- rast(bath_file)
names(bathymetry) <- "bathymetry"

message("  Loaded bathymetry")

# ------------------------------------------------------------
# 3.2 Slope
# ------------------------------------------------------------

slope_file <- file.path(static_dir, "slope_wmed.tif")

if (!file.exists(slope_file)) {
  stop("Slope file not found: ", slope_file)
}

slope <- rast(slope_file)
names(slope) <- "slope"

message("  Loaded slope")

# ------------------------------------------------------------
# 3.3 Distance to coast
# ------------------------------------------------------------

dist_file_1 <- file.path(static_dir, "distance_to_coast_wmed.tif")
dist_file_2 <- file.path(static_dir, "dist_coast_wmed.tif")

if (file.exists(dist_file_1)) {
  dist_file <- dist_file_1
} else if (file.exists(dist_file_2)) {
  dist_file <- dist_file_2
} else {
  stop("Distance-to-coast file not found in: ", static_dir)
}

distance_to_coast <- rast(dist_file)
names(distance_to_coast) <- "distance_to_coast"

message("  Loaded distance to coast")


# ============================================================
# 4. LIST ALL DAILY DYNAMIC FILES
# ============================================================

message("Listing daily dynamic layers...")

dynamic_files <- list.files(
  dynamic_dir,
  pattern = "\\.tif$",
  full.names = TRUE
)

if (length(dynamic_files) == 0) {
  stop("No daily dynamic raster files found in: ", dynamic_dir)
}

message("  Number of dynamic files found: ", length(dynamic_files))


# ============================================================
# 5. BUILD A LOOKUP TABLE FOR DYNAMIC FILES
# ============================================================

dynamic_table <- data.frame(
  file = dynamic_files,
  stringsAsFactors = FALSE
)

dynamic_table$file_name <- basename(dynamic_table$file)

# Remove ".tif"
dynamic_table$file_stub <- str_remove(dynamic_table$file_name, "\\.tif$")

# Extract date from file name
dynamic_table$date <- str_extract(dynamic_table$file_stub, "\\d{4}-\\d{2}-\\d{2}$")

# Extract variable name from file name
dynamic_table$variable <- str_remove(dynamic_table$file_stub, "_\\d{4}-\\d{2}-\\d{2}$")

# Keep only valid rows
dynamic_table <- dynamic_table[!is.na(dynamic_table$date), ]

if (nrow(dynamic_table) == 0) {
  stop("No dynamic files matched the expected naming format: variable_YYYY-MM-DD.tif")
}

message("Dynamic file table built successfully.")


# ============================================================
# 6. IDENTIFY ALL UNIQUE DATES
# ============================================================

all_dates <- sort(unique(dynamic_table$date))

message("Number of unique dates found: ", length(all_dates))


# ============================================================
# 7. LOOP THROUGH DATES AND BUILD ONE STACK PER DAY
# ============================================================

for (i in seq_along(all_dates)) {
  
  this_date <- all_dates[i]
  
  message("====================================")
  message("Processing date ", i, " of ", length(all_dates), ": ", this_date)
  
  # ----------------------------------------------------------
  # 7.1 Select all dynamic files for this date
  # ----------------------------------------------------------
  
  daily_rows <- dynamic_table[dynamic_table$date == this_date, ]
  
  if (nrow(daily_rows) == 0) {
    message("  No dynamic layers found for this date -> skipping")
    next
  }
  
  message("  Number of dynamic variables for this day: ", nrow(daily_rows))
  
  # ----------------------------------------------------------
  # 7.2 Start the stack with static variables
  # ----------------------------------------------------------
  
  daily_stack <- c(
    bathymetry,
    slope,
    distance_to_coast
  )
  
  # ----------------------------------------------------------
  # 7.3 Add dynamic variables one by one
  # ----------------------------------------------------------
  
  for (j in seq_len(nrow(daily_rows))) {
    
    dynamic_file <- daily_rows$file[j]
    dynamic_var  <- daily_rows$variable[j]
    
    message("    Adding variable: ", dynamic_var)
    
    r <- rast(dynamic_file)
    
    # If a file contains more than one layer, keep only the first
    if (nlyr(r) > 1) {
      r <- r[[1]]
    }
    
    # Assign the real variable name
    names(r) <- dynamic_var
    
    # --------------------------------------------------------
    # 7.3.1 Match geometry to the static template if needed
    # --------------------------------------------------------
    
    if (!compareGeom(r, bathymetry, stopOnError = FALSE)) {
      message("      Geometry differs from template -> resampling")
      r <- resample(r, bathymetry, method = "bilinear")
      r <- mask(r, bathymetry)
    }
    
    # --------------------------------------------------------
    # 7.3.2 Add original dynamic layer
    # --------------------------------------------------------
    
    daily_stack <- c(daily_stack, r)
    
    # --------------------------------------------------------
    # 7.3.3 Compute gradients ONLY for temperature and salinity
    # --------------------------------------------------------
    # We identify temperature-like and salinity-like variable names.
    #
    # Temperature examples:
    # - temperature
    # - temp
    # - sst
    # - thetao
    #
    # Salinity examples:
    # - salinity
    # - sal
    # - so
    # --------------------------------------------------------
    
    # ----- TEMPERATURE GRADIENT -----
    if (dynamic_var %in% c("temperature", "temp", "sst", "thetao")) {
      
      message("      Computing temperature gradient")
      
      gradient_r <- terrain(
        r,
        v = "slope",
        unit = "radians",
        neighbors = 8
      )
      
      gradient_r <- mask(gradient_r, bathymetry)
      names(gradient_r) <- "temperature_gradient"
      
      daily_stack <- c(daily_stack, gradient_r)
    }
    
    # ----- SALINITY GRADIENT -----
    if (dynamic_var %in% c("salinity", "sal", "so")) {
      
      message("      Computing salinity gradient")
      
      gradient_r <- terrain(
        r,
        v = "slope",
        unit = "radians",
        neighbors = 8
      )
      
      gradient_r <- mask(gradient_r, bathymetry)
      names(gradient_r) <- "salinity_gradient"
      
      daily_stack <- c(daily_stack, gradient_r)
    }
  }
  
  # ----------------------------------------------------------
  # 7.4 Save the daily stack
  # ----------------------------------------------------------
  
  out_file <- file.path(
    out_dir,
    paste0("present_stack_", this_date, ".tif")
  )
  
  writeRaster(
    daily_stack,
    filename = out_file,
    overwrite = TRUE
  )
  
  message("  Saved stack: ", basename(out_file))
  message("  Variables in stack: ", paste(names(daily_stack), collapse = ", "))
}


# ============================================================
# 8. FINAL MESSAGE
# ============================================================

message("====================================")
message("Present-day environmental stacks created successfully.")
message("Temperature and salinity gradients were added when available.")
message("Output directory: ", out_dir)
message("====================================")