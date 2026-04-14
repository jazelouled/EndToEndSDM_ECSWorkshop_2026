# =========================================================
# SCRIPT: 10downloadCMEMS.R
# PURPOSE:
# Execute the shell script that downloads daily CMEMS
# environmental data for the simulated species tracking dates.
#
# INPUT:
# 01scripts/00enviro/10downloadCMEMS.sh
#
# OUTPUT:
# 00inputOutput/00input/00rawData/00CMEMS/
# =========================================================

message("Starting CMEMS download workflow...")

system(
  "bash 01scripts/00enviro/10downloadCMEMS.sh",
  intern = FALSE,
  wait = TRUE
)

message("CMEMS download completed successfully.")