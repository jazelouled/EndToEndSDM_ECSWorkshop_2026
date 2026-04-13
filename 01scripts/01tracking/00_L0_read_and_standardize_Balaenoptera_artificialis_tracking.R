# ============================================================
# Script name: 00_L0_read_and_standardize_Balaenoptera_artificialis_tracking.R
# Description:
# Reads the final simulated tracking dataset for Balaenoptera
# artificialis, harmonizes it, maps all locations, saves a
# raw map, creates minimal standardized L0 files per tag,
# and generates one QC plot per individual with:
# - land
# - auto zoom
# - line colored by time
# - fixed color per Argos quality
# - start point in red
# - track summary on the map
# ============================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(lubridate)
  library(sf)
  library(rnaturalearth)
  library(rnaturalearthdata)
  library(grid)
})

sf::sf_use_s2(FALSE)

message("Starting L0 standardization workflow for Balaenoptera artificialis...")

# ============================================================
# Paths
# ============================================================

base_dir <- "/Users/jazelouled-cheikhbonan/Dropbox/2026_ECS_WorkshopSDM/00workshopPreparation"

path_simulated <- file.path(
  base_dir,
  "01simulation",
  "01output",
  "simulated_tracking_final.RDS"
)

out_dir <- file.path(
  base_dir,
  "03analysisWithStudents",
  "00tracking",
  "00L0_data"
)

out_plots_dir <- file.path(out_dir, "plots_individuals")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(out_plots_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(path_simulated)) {
  stop("Simulated tracking file not found: ", path_simulated)
}

# ============================================================
# Read data
# ============================================================

message("Reading simulated tracking dataset...")

sim_raw <- readRDS(path_simulated)

message(
  "Loaded ",
  nrow(sim_raw), " positions from ",
  n_distinct(sim_raw$id), " simulated individuals."
)

# ============================================================
# Harmonized dataset for global map
# ============================================================

sim_map <- sim_raw %>%
  mutate(
    id = as.character(.data$id),
    DateTime = as.POSIXct(.data$datetime, tz = "UTC"),
    Latitude = .data$lat,
    Longitude = .data$lon,
    source = "Simulated"
  ) %>%
  filter(
    !is.na(.data$DateTime),
    !is.na(.data$Latitude),
    !is.na(.data$Longitude)
  ) %>%
  filter(
    .data$Longitude >= -6, .data$Longitude <= 16,
    .data$Latitude  >= 30, .data$Latitude  <= 46
  )

# ============================================================
# Global map
# ============================================================

message("Building global map...")

world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  st_make_valid()

world_crop <- st_crop(
  world,
  xmin = -6, xmax = 16,
  ymin = 30, ymax = 46
)

sim_sf <- st_as_sf(
  sim_map,
  coords = c("Longitude", "Latitude"),
  crs = 4326
)

p_map <- ggplot() +
  geom_sf(data = world_crop, fill = "grey90", color = "grey40") +
  geom_sf(
    data = sim_sf,
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
    title = expression(italic("Balaenoptera artificialis") ~ "- all simulated tracks"),
    color = "Dataset",
    x = "Longitude",
    y = "Latitude"
  )

ggsave(
  filename = file.path(out_dir, "Balaenoptera_artificialis_AllTags_rawMap.png"),
  plot = p_map,
  width = 8,
  height = 6,
  dpi = 300
)

# ============================================================
# Create minimal standardized L0 files per tag
# ============================================================

message("Creating standardized L0 files per individual...")

sim_tags <- split(sim_raw, sim_raw$id)

walk(sim_tags, function(df) {
  
  df_std <- df %>%
    mutate(
      PTT_ID = as.character(.data$id),
      DateTime = as.POSIXct(.data$datetime, tz = "UTC"),
      Latitude = .data$lat,
      Longitude = .data$lon,
      LocationClass = as.character(.data$argos_class)
    ) %>%
    filter(
      !is.na(.data$DateTime),
      !is.na(.data$Latitude),
      !is.na(.data$Longitude)
    ) %>%
    filter(
      .data$Longitude >= -6, .data$Longitude <= 16,
      .data$Latitude  >= 30, .data$Latitude  <= 46
    ) %>%
    arrange(.data$DateTime) %>%
    select(
      .data$PTT_ID,
      .data$DateTime,
      .data$Latitude,
      .data$Longitude,
      .data$LocationClass
    )
  
  tag_id <- unique(df_std$PTT_ID)
  
  if (length(tag_id) == 1 && nrow(df_std) > 0) {
    write_csv(
      df_std,
      file.path(out_dir, paste0("Balaenoptera_artificialis_L0_", tag_id, ".csv"))
    )
  }
})

message("L0 files exported.")

# ============================================================
# Helpers for individual plots
# ============================================================

make_bbox <- function(df, buffer_deg = 0.5) {
  
  xr <- range(df$Longitude, na.rm = TRUE)
  yr <- range(df$Latitude,  na.rm = TRUE)
  
  if (diff(xr) < 0.2) xr <- xr + c(-0.2, 0.2)
  if (diff(yr) < 0.2) yr <- yr + c(-0.2, 0.2)
  
  xlim <- c(xr[1] - buffer_deg, xr[2] + buffer_deg)
  ylim <- c(yr[1] - buffer_deg, yr[2] + buffer_deg)
  
  xlim[1] <- max(xlim[1], -6)
  xlim[2] <- min(xlim[2], 16)
  ylim[1] <- max(ylim[1], 30)
  ylim[2] <- min(ylim[2], 46)
  
  list(
    xlim = xlim,
    ylim = ylim
  )
}

# Fixed color mapping for Argos quality
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
# Function to plot one individual track
# ============================================================

plot_individual_track <- function(df, tag_id, world) {
  
  df <- df %>%
    mutate(
      DateTime = as.POSIXct(.data$DateTime, tz = "UTC"),
      LocationClass = factor(.data$LocationClass, levels = names(quality_map))
    ) %>%
    filter(
      !is.na(.data$DateTime),
      .data$Longitude >= -6, .data$Longitude <= 16,
      .data$Latitude  >= 30, .data$Latitude  <= 46
    ) %>%
    arrange(.data$DateTime)
  
  if (nrow(df) < 2) return(NULL)
  
  bb <- make_bbox(df, buffer_deg = 0.5)
  start_point <- df %>% slice(1)
  
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
  
  track_text <- paste0(
    "Start: ", format(start_date, "%Y-%m-%d %H:%M"), "\n",
    "End: ", format(end_date, "%Y-%m-%d %H:%M"), "\n",
    "Positions: ", n_total, "\n",
    "Days: ", total_days, "\n",
    "Argos classes: ", quality_text
  )
  
  x_text <- bb$xlim[1] + 0.03 * diff(bb$xlim)
  y_text <- bb$ylim[2] - 0.03 * diff(bb$ylim)
  
  p <- ggplot() +
    geom_sf(data = world, fill = "grey90", color = "grey40") +
    
    geom_path(
      data = df,
      aes(x = Longitude, y = Latitude, color = DateTime),
      linewidth = 0.7,
      alpha = 0.7
    ) +
    
    geom_point(
      data = df,
      aes(
        x = Longitude,
        y = Latitude,
        fill = LocationClass
      ),
      shape = 21,
      size = 1.3,
      alpha = 0.6,
      color = "black",
      stroke = 0.15
    ) +
    
    geom_point(
      data = start_point,
      aes(x = Longitude, y = Latitude),
      color = "red",
      size = 2.5
    ) +
    
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
    
    scale_color_datetime(
      name = "Time",
      date_labels = "%Y-%m-%d",
      low = "blue",
      high = "yellow"
    ) +
    
    scale_fill_manual(
      values = quality_map,
      limits = names(quality_map),
      drop = FALSE,
      na.value = "grey70"
    ) +
    
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
# Plot individuals
# ============================================================

message("Creating individual QC plots...")

walk(sim_tags, function(df) {
  
  df_std <- df %>%
    mutate(
      PTT_ID = as.character(.data$id),
      DateTime = as.POSIXct(.data$datetime, tz = "UTC"),
      Latitude = .data$lat,
      Longitude = .data$lon,
      LocationClass = as.character(.data$argos_class)
    ) %>%
    filter(
      !is.na(.data$DateTime),
      !is.na(.data$Latitude),
      !is.na(.data$Longitude)
    ) %>%
    filter(
      .data$Longitude >= -6, .data$Longitude <= 16,
      .data$Latitude  >= 30, .data$Latitude  <= 46
    ) %>%
    arrange(.data$DateTime) %>%
    select(
      .data$PTT_ID,
      .data$DateTime,
      .data$Latitude,
      .data$Longitude,
      .data$LocationClass
    )
  
  tag_id <- unique(df_std$PTT_ID)
  
  if (length(tag_id) == 1 && nrow(df_std) > 1) {
    plot_individual_track(df_std, tag_id, world_crop)
  }
})

message("Individual QC plots saved.")
message("L0 standardization workflow completed.")