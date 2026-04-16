# ============================================================
# SCRIPT NAME:
# 07_extractEnvironmentalData_Balaenoptera_artificialis.R
#
# PURPOSE:
# Extract environmental values for each presence-absence point
# from the daily environmental stacks.
#
# INPUT:
# - balanced presence-absence dataset
# - one environmental stack per day (.grd)
#
# OUTPUT:
# - one CSV including:
#   presence-absence data + extracted environmental variables
#
# WHY THIS STEP IS USEFUL:
# Habitat models need a table where each observation
# (presence or absence) is linked to the environmental
# conditions at the same place and time.
# ============================================================


# ============================================================
# 1. LOAD REQUIRED PACKAGES
# ============================================================

suppressPackageStartupMessages({
  library(raster)
  library(dplyr)
  library(lubridate)
  library(readr)
  library(here)
  library(sp)
})

message("Starting environmental extraction workflow...")


# ============================================================
# 2. DEFINE INPUT AND OUTPUT PATHS
# ============================================================

presabs_file <- here(
  "00inputOutput", "00input", "01processedData", "00tracking",
  "06PresAbs_grid", "Balaenoptera_artificialis_PresAbs_grid_balanced.csv"
)

stack_dir <- here(
  "00inputOutput", "00input", "01processedData", "00enviro",
  "02presentStacks"
)

out_dir <- here(
  "00inputOutput", "00input", "01processedData", "02habitatModel"
)

out_file <- file.path(
  out_dir,
  "Balaenoptera_artificialis_PresAbs_with_env.csv"
)

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(presabs_file)) {
  stop("Presence-absence file not found: ", presabs_file)
}

if (!dir.exists(stack_dir)) {
  stop("Environmental stack directory not found: ", stack_dir)
}


# ============================================================
# 3. LOAD PRESENCE-ABSENCE DATA
# ============================================================

message("Reading presence-absence dataset...")

presAbs <- read_csv(presabs_file, show_col_types = FALSE)

message("Rows loaded: ", nrow(presAbs))
message("Columns loaded: ", ncol(presAbs))

# ------------------------------------------------------------
# 3.1 Standardize date column
# ------------------------------------------------------------

if ("date" %in% names(presAbs)) {
  presAbs$dateTime <- as.POSIXct(presAbs$date, tz = "UTC")
} else if ("datetime" %in% names(presAbs)) {
  presAbs$dateTime <- as.POSIXct(presAbs$datetime, tz = "UTC")
} else if ("dateTime" %in% names(presAbs)) {
  presAbs$dateTime <- as.POSIXct(presAbs$dateTime, tz = "UTC")
} else {
  stop("The dataset must contain 'date', 'datetime', or 'dateTime'.")
}

presAbs$day <- format(presAbs$dateTime, "%Y-%m-%d")

if (!all(c("lon", "lat") %in% names(presAbs))) {
  stop("The dataset must contain 'lon' and 'lat' columns.")
}


# ============================================================
# 4. FIND AVAILABLE DAILY STACKS
# ============================================================

stack_files <- list.files(
  stack_dir,
  pattern = "^present_stack_\\d{4}-\\d{2}-\\d{2}\\.grd$",
  full.names = TRUE
)

if (length(stack_files) == 0) {
  stop("No daily environmental stacks found in: ", stack_dir)
}

message("Number of daily stacks found: ", length(stack_files))


# ============================================================
# 5. CREATE A LOOKUP TABLE FOR STACK FILES
# ============================================================

stack_table <- data.frame(
  file = stack_files,
  stringsAsFactors = FALSE
)

stack_table$file_name <- basename(stack_table$file)
stack_table$day <- gsub("^present_stack_|\\.grd$", "", stack_table$file_name)

message("Environmental stack lookup table ready.")


# ============================================================
# 6. GET UNIQUE DAYS IN TRACKING DATA
# ============================================================

all_days <- sort(unique(na.omit(presAbs$day)))

message("Number of unique dates in presence-absence data: ", length(all_days))


# ============================================================
# 7. LOOP THROUGH DATES AND EXTRACT ENVIRONMENTAL DATA
# ============================================================
# We do this sequentially:
# - simpler
# - easier to debug
# - better for teaching
# ============================================================

results_list <- vector("list", length(all_days))

for (i in seq_along(all_days)) {
  
  d <- all_days[i]
  
  message("====================================")
  message("Processing date ", i, " of ", length(all_days), ": ", d)
  
  df_day <- presAbs[presAbs$day == d, ]
  
  # ----------------------------------------------------------
  # 7.1 Find the matching environmental stack
  # ----------------------------------------------------------
  
  stack_path <- stack_table$file[stack_table$day == d]
  
  if (length(stack_path) == 1 && file.exists(stack_path)) {
    
    message("  Stack found: ", basename(stack_path))
    
    # --------------------------------------------------------
    # 7.2 Load the environmental stack
    # --------------------------------------------------------
    
    env_stack <- stack(stack_path)
    
    message("  Number of layers in stack: ", nlayers(env_stack))
    message("  Layer names: ", paste(names(env_stack), collapse = ", "))
    
    # --------------------------------------------------------
    # 7.3 Convert points to SpatialPoints
    # --------------------------------------------------------
    
    coords <- df_day %>%
      dplyr::select(lon, lat) %>%
      as.data.frame()
    
    sp_points <- SpatialPoints(
      coords,
      proj4string = CRS(projection(env_stack))
    )
    
    # --------------------------------------------------------
    # 7.4 Extract environmental values
    # --------------------------------------------------------
    # We use a 15 km buffer and compute the mean value.
    # --------------------------------------------------------
    
    extracted_vals <- raster::extract(
      env_stack,
      sp_points,
      buffer = 15000,
      fun = mean,
      na.rm = TRUE
    )
    
    extracted_vals <- as.data.frame(extracted_vals)
    
    # --------------------------------------------------------
    # 7.5 Combine extracted values with the observations
    # --------------------------------------------------------
    
    df_day <- bind_cols(df_day, extracted_vals)
    
  } else {
    
    warning("Missing environmental stack for date: ", d)
    
    # --------------------------------------------------------
    # 7.6 If stack is missing, create NA columns
    # --------------------------------------------------------
    # These names match the current daily stack structure.
    # --------------------------------------------------------
    
    df_day$bathymetry <- NA
    df_day$slope <- NA
    df_day$distance_to_coast <- NA
    df_day$mlotst <- NA
    df_day$zos <- NA
    df_day$thetao <- NA
    df_day$thetao_gradient <- NA
    df_day$so <- NA
    df_day$so_gradient <- NA
    df_day$uo <- NA
    df_day$vo <- NA
    df_day$chl <- NA
    df_day$nppv <- NA
  }
  
  results_list[[i]] <- df_day
}


# ============================================================
# 8. COMBINE ALL DAYS
# ============================================================

results_df <- bind_rows(results_list)

message("Final table rows: ", nrow(results_df))
message("Final table columns: ", ncol(results_df))


# ============================================================
# 9. SAVE FINAL OUTPUT
# ============================================================

write_csv(results_df, out_file)

message("====================================")
message("Environmental extraction completed successfully.")
message("Output saved to:")
message(out_file)
message("====================================")