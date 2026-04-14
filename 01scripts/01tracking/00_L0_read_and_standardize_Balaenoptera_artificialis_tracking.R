# ============================================================
# SCRIPT NAME:
# 00_L0_read_and_standardize_Balaenoptera_artificialis_tracking.R
#
# PURPOSE:
# This script prepares the initial tracking dataset (L0 level)
# for the workshop.
#
# In practical terms, it does four things:
#
# 1. Reads the raw tracking file
# 2. Renames individuals into simple PTT-style IDs
# 3. Exports one standardized L0 file per individual
# 4. Produces quality-control (QC) maps
#
# WHY THIS STEP MATTERS:
# Before doing any filtering or modelling, it is useful to:
# - inspect the raw data
# - make sure coordinates and dates look correct
# - organize the data consistently
# - save one file per individual
#
# OUTPUTS:
# - One global map with all tracks
# - One standardized L0 CSV per individual
# - One QC plot per individual
# ============================================================

# ============================================================
# LOAD REQUIRED PACKAGES
# ============================================================
# tidyverse      -> data wrangling + plotting
# lubridate      -> date/time handling
# sf             -> spatial objects
# rnaturalearth  -> coastline / land polygons
# grid           -> used internally by some ggplot elements
# here           -> build paths relative to the project root
# ============================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(sf)
  library(rnaturalearth)
  library(rnaturalearthdata)
  library(grid)
  library(here)
})

# We disable s2 because some cropped world polygons can produce
# topology issues in simple plotting workflows.
sf::sf_use_s2(FALSE)

message("Starting L0 standardization workflow for Balaenoptera artificialis...")

# ============================================================
# 1. DEFINE INPUT AND OUTPUT PATHS
# ============================================================
# We use the package 'here' so that paths are defined relative
# to the project root, not to the user's computer.
#
# Input:
# - one CSV file containing the full tracking dataset
#
# Outputs:
# - one folder for standardized L0 files
# - one folder for QC plots
# ============================================================

path_tracking <- here(
  "00inputOutput", "00input", "00rawData", "01tracking",
  "simulated_tracking_final.csv"
)

out_dir <- here(
  "00inputOutput", "00input", "01processedData", "01tracking",
  "00L0_data"
)

out_plots_dir <- file.path(out_dir, "plots_individuals")

# Create output folders if they do not exist
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(out_plots_dir, recursive = TRUE, showWarnings = FALSE)

# Safety check: stop early if input file is missing
if (!file.exists(path_tracking)) {
  stop("Tracking file not found: ", path_tracking)
}

# ============================================================
# 2. READ THE RAW TRACKING DATASET
# ============================================================
# This file contains all positions from all individuals.
# At this stage we keep it as it is and inspect the structure.
# ============================================================

message("Reading tracking dataset...")

tracking_raw <- read_csv(
  path_tracking,
  show_col_types = FALSE
)

message(
  "Loaded ",
  nrow(tracking_raw), " positions from ",
  n_distinct(tracking_raw$id), " individuals."
)

# ============================================================
# 3. RENAME INDIVIDUAL IDS INTO A SIMPLE PTT FORMAT
# ============================================================
# The original IDs may be long or not very convenient.
# For teaching purposes, we rename them as:
#
# PTT_01, PTT_02, PTT_03, ...
#
# This makes later scripts easier to read and avoids confusion.
# ============================================================

message("Renaming individual IDs to PTT format...")

id_lookup <- tibble(
  id_original = sort(unique(tracking_raw$id)),
  PTT_ID = paste0(
    "PTT_",
    stringr::str_pad(
      seq_along(sort(unique(tracking_raw$id))),
      width = 2,
      pad = "0"
    )
  )
)

tracking_raw <- tracking_raw %>%
  left_join(id_lookup, by = c("id" = "id_original"))

message("Assigned IDs:")
print(id_lookup)

# ============================================================
# 4. PREPARE A CLEAN VERSION OF THE DATA FOR THE GLOBAL MAP
# ============================================================
# Here we:
# - convert datetime
# - rename coordinates to more explicit names
# - keep only positions inside the workshop study area
#
# The study area is the Western Mediterranean domain used
# throughout the workshop.
# ============================================================

tracking_map <- tracking_raw %>%
  mutate(
    DateTime = as.POSIXct(datetime, tz = "UTC"),
    Latitude = lat,
    Longitude = lon,
    source = "Tracking"
  ) %>%
  filter(
    !is.na(DateTime),
    !is.na(Latitude),
    !is.na(Longitude)
  ) %>%
  filter(
    Longitude >= -6, Longitude <= 16,
    Latitude  >= 30, Latitude  <= 46
  )

# ============================================================
# 5. BUILD A GLOBAL MAP WITH ALL TRACKS
# ============================================================
# This map is useful as a first visual QC step:
# - do all points fall in the expected region?
# - are there obvious coordinate problems?
# - do tracks look roughly reasonable?
# ============================================================

message("Building global map...")

# Download / load country polygons
world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  st_make_valid()

# Crop the world to the workshop study area
world_crop <- st_crop(
  world,
  xmin = -6, xmax = 16,
  ymin = 30, ymax = 46
)

# Convert the tracking data into an sf object
tracking_sf <- st_as_sf(
  tracking_map,
  coords = c("Longitude", "Latitude"),
  crs = 4326
)

# Build the map
p_map <- ggplot() +
  geom_sf(data = world_crop, fill = "grey90", color = "grey40") +
  geom_sf(
    data = tracking_sf,
    aes(color = source),
    size = 0.7,
    alpha = 0.6
  ) +
  coord_sf(
    xlim = c(-6, 16),
    ylim = c(30, 46),
    expand = FALSE
  ) +
  theme_bw() +
  labs(
    title = expression(italic("Balaenoptera artificialis") ~ "- all tracks"),
    color = "Dataset",
    x = "Longitude",
    y = "Latitude"
  )

# Save the figure
ggsave(
  filename = file.path(out_dir, "Balaenoptera_artificialis_AllTags_rawMap.png"),
  plot = p_map,
  width = 8,
  height = 6,
  dpi = 300
)

# ============================================================
# 6. EXPORT ONE STANDARDIZED L0 FILE PER INDIVIDUAL
# ============================================================
# L0 here means:
# - raw tracking data
# - one file per individual
# - harmonized column names
#
# This is useful because later steps in the workflow operate
# on one individual at a time.
# ============================================================

message("Creating standardized L0 files per individual...")

# Split the data into a list, one element per individual
tracking_tags <- split(tracking_raw, tracking_raw$PTT_ID)

walk(tracking_tags, function(df) {
  
  # Reformat and standardize column names
  df_std <- df %>%
    mutate(
      DateTime = as.POSIXct(datetime, tz = "UTC"),
      Latitude = lat,
      Longitude = lon,
      LocationClass = as.character(argos_class)
    ) %>%
    filter(
      !is.na(DateTime),
      !is.na(Latitude),
      !is.na(Longitude)
    ) %>%
    filter(
      Longitude >= -6, Longitude <= 16,
      Latitude  >= 30, Latitude  <= 46
    ) %>%
    arrange(DateTime) %>%
    select(
      PTT_ID,
      DateTime,
      Latitude,
      Longitude,
      LocationClass
    )
  
  # Extract the unique tag ID
  tag_id <- unique(df_std$PTT_ID)
  
  # Only save if the object is valid
  if (length(tag_id) == 1 && nrow(df_std) > 0) {
    write_csv(
      df_std,
      file.path(out_dir, paste0("Balaenoptera_artificialis_L0_", tag_id, ".csv"))
    )
  }
})

message("L0 files exported.")

# ============================================================
# 7. HELPER FUNCTIONS FOR INDIVIDUAL QC PLOTS
# ============================================================
# We now define:
# - a function to compute a plotting bounding box
# - a color palette for Argos classes
# - a function that plots one individual track
# ============================================================

# ------------------------------------------------------------
# Function: make_bbox()
# ------------------------------------------------------------
# This creates a custom bounding box around one track.
# It adds a small buffer so the track is not too close
# to the edges of the figure.
# ------------------------------------------------------------

make_bbox <- function(df, buffer = 0.5) {
  
  xr <- range(df$Longitude, na.rm = TRUE)
  yr <- range(df$Latitude, na.rm = TRUE)
  
  # If the track is very narrow spatially, widen it a bit
  if (diff(xr) < 0.2) xr <- xr + c(-0.2, 0.2)
  if (diff(yr) < 0.2) yr <- yr + c(-0.2, 0.2)
  
  xlim <- xr + c(-buffer, buffer)
  ylim <- yr + c(-buffer, buffer)
  
  # Keep within workshop domain
  xlim[1] <- max(xlim[1], -6)
  xlim[2] <- min(xlim[2], 16)
  ylim[1] <- max(ylim[1], 30)
  ylim[2] <- min(ylim[2], 46)
  
  list(xlim = xlim, ylim = ylim)
}

# ------------------------------------------------------------
# Color palette for Argos classes
# ------------------------------------------------------------
# These are fixed so the same class always has the same color
# in all figures throughout the workshop.
# ------------------------------------------------------------

quality_map <- c(
  "3" = "#1b9e77",
  "2" = "#66a61e",
  "1" = "#e6ab02",
  "0" = "#d95f02",
  "A" = "#7570b3",
  "B" = "#e7298a",
  "Z" = "#666666"
)

# ============================================================
# 8. FUNCTION TO PLOT ONE INDIVIDUAL TRACK
# ============================================================
# This function creates a QC plot with:
# - land background
# - track line colored by time
# - points colored by Argos class
# - first point highlighted in red
# - a small summary box on the map
# ============================================================

plot_individual_track <- function(df, tag_id, world) {
  
  # Standardize date and factor levels
  df <- df %>%
    mutate(
      DateTime = as.POSIXct(DateTime, tz = "UTC"),
      LocationClass = factor(LocationClass, levels = names(quality_map))
    ) %>%
    filter(
      !is.na(DateTime),
      Longitude >= -6, Longitude <= 16,
      Latitude  >= 30, Latitude  <= 46
    ) %>%
    arrange(DateTime)
  
  # If there are too few points, do not plot
  if (nrow(df) < 2) return(NULL)
  
  # Get custom extent for this individual
  bb <- make_bbox(df)
  
  # First point of the track
  start_point <- df[1, ]
  
  # Summary statistics
  start_date <- min(df$DateTime, na.rm = TRUE)
  end_date   <- max(df$DateTime, na.rm = TRUE)
  
  n_total <- nrow(df)
  total_days <- as.numeric(as.Date(end_date) - as.Date(start_date)) + 1
  
  quality_counts <- df %>%
    count(LocationClass, name = "n") %>%
    arrange(LocationClass)
  
  quality_text <- paste(
    paste0(quality_counts$LocationClass, ": ", quality_counts$n),
    collapse = " | "
  )
  
  # Text box shown on the plot
  track_text <- paste0(
    "Start: ", format(start_date, "%Y-%m-%d %H:%M"), "\n",
    "End: ", format(end_date, "%Y-%m-%d %H:%M"), "\n",
    "Positions: ", n_total, "\n",
    "Days: ", total_days, "\n",
    "Argos classes: ", quality_text
  )
  
  # Position of the text box
  x_text <- bb$xlim[1] + 0.03 * diff(bb$xlim)
  y_text <- bb$ylim[2] - 0.03 * diff(bb$ylim)
  
  # Build the figure
  p <- ggplot() +
    geom_sf(data = world, fill = "grey90", color = "grey40") +
    
    # Track line colored by time
    geom_path(
      data = df,
      aes(x = Longitude, y = Latitude, color = DateTime),
      linewidth = 0.7,
      alpha = 0.7
    ) +
    
    # Track positions colored by Argos class
    geom_point(
      data = df,
      aes(x = Longitude, y = Latitude, fill = LocationClass),
      shape = 21,
      size = 1.3,
      alpha = 0.6,
      color = "black",
      stroke = 0.15
    ) +
    
    # First point in red
    geom_point(
      data = start_point,
      aes(x = Longitude, y = Latitude),
      color = "red",
      size = 2.5
    ) +
    
    # Text summary
    annotate(
      "label",
      x = x_text,
      y = y_text,
      label = track_text,
      hjust = 0,
      vjust = 1,
      size = 3,
      label.size = 0.2,
      fill = "white",
      alpha = 0.9
    ) +
    
    # Continuous time color scale
    scale_color_datetime(
      name = "Time",
      date_labels = "%Y-%m-%d",
      low = "blue",
      high = "yellow"
    ) +
    
    # Discrete Argos class color scale
    scale_fill_manual(
      values = quality_map,
      limits = names(quality_map),
      drop = FALSE,
      na.value = "grey70"
    ) +
    
    # Legend formatting
    guides(
      fill = guide_legend(
        override.aes = list(
          shape = 21,
          size = 2.5,
          alpha = 1,
          color = "black"
        )
      ),
      color = guide_colorbar(barheight = unit(3, "cm"))
    ) +
    
    coord_sf(
      xlim = bb$xlim,
      ylim = bb$ylim,
      expand = FALSE
    ) +
    theme_bw() +
    theme(
      legend.text = element_text(size = 7),
      legend.title = element_text(size = 8),
      legend.key.size = unit(0.4, "cm")
    ) +
    labs(
      title = bquote(italic("Balaenoptera artificialis") ~ "-" ~ .(tag_id)),
      x = "Longitude",
      y = "Latitude",
      fill = "Argos class"
    )
  
  # Save figure
  ggsave(
    filename = file.path(
      out_plots_dir,
      paste0("Balaenoptera_artificialis_track_", tag_id, ".png")
    ),
    plot = p,
    width = 7,
    height = 6,
    dpi = 300
  )
}

# ============================================================
# 9. GENERATE QC PLOTS FOR ALL INDIVIDUALS
# ============================================================
# We now loop over all individuals and create one QC plot
# per track.
# ============================================================

message("Creating individual QC plots...")

walk(tracking_tags, function(df) {
  
  df_plot <- df %>%
    mutate(
      DateTime = as.POSIXct(datetime, tz = "UTC"),
      Latitude = lat,
      Longitude = lon,
      LocationClass = as.character(argos_class)
    ) %>%
    filter(
      !is.na(DateTime),
      !is.na(Latitude),
      !is.na(Longitude)
    ) %>%
    filter(
      Longitude >= -6, Longitude <= 16,
      Latitude  >= 30, Latitude  <= 46
    ) %>%
    arrange(DateTime) %>%
    select(
      PTT_ID,
      DateTime,
      Latitude,
      Longitude,
      LocationClass
    )
  
  tag_id <- unique(df_plot$PTT_ID)
  
  if (length(tag_id) == 1 && nrow(df_plot) > 1) {
    plot_individual_track(df_plot, tag_id, world_crop)
  }
})

message("Individual QC plots saved.")
message("L0 standardization workflow completed.")