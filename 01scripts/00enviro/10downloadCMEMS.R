# =========================================================
# SCRIPT: 10downloadCMEMS.R
# PURPOSE:
# Download daily environmental data from Copernicus Marine
# Service (CMEMS) for all tracking dates included in the
# study dataset.
#
# This script executes an external bash (.sh) script that:
#   1) Reads a vector of tracking dates
#   2) Downloads physical variables from CMEMS
#   3) Downloads biogeochemical variables from CMEMS
#   4) Saves outputs into the project input directory
#
# IMPORTANT:
# The associated shell script must be adapted by each user
# to their own local machine paths before execution.
#
# REQUIRED:
# - Copernicus Marine Toolbox installed
# - Valid Copernicus credentials configured
# - Bash shell available
#
# INPUT:
# 01scripts/10downloadCMEMS.sh
#
# OUTPUT:
# NetCDF environmental layers saved in:
# 00inputOutput/00input/00rawData/00CMEMS/
# =========================================================


message("Starting CMEMS download workflow...")


# Run external bash script containing Copernicus API commands.
# Users should inspect and adapt local paths if necessary.

system(
  "bash 01scripts/10downloadCMEMS.sh",
  intern = FALSE,
  wait   = TRUE
)


message("CMEMS download completed successfully.")