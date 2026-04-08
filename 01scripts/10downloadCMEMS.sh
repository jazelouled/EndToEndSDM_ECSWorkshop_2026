#!/bin/bash
set -e

# ============================================================
# Download Copernicus data ONLY for tracking dates
# Fin whale – Mediterranean
# ============================================================

# ----------------------------
# BASE DIRECTORY
# ----------------------------
BASE_DIR="/Volumes/ADATA HD330/2026_FinWhale_RdeStephanis"
DATES_FILE="${BASE_DIR}/tracking_dates2.txt"
OUTDIR="${BASE_DIR}/envData"

mkdir -p "${OUTDIR}"

# ----------------------------
# STUDY AREA (+5º buffer)
# (based on tracking extent)
# ----------------------------
MIN_LON=-20
MAX_LON=15
MIN_LAT=29
MAX_LAT=51

# ----------------------------
# DEPTHS (surface)
# ----------------------------
PHY_DEPTH=0.49402499198913574
BGC_DEPTH=0.5057600140571594

# ============================================================
# LOOP OVER DATES
# ============================================================

while read DATE; do

  echo "=============================================="
  echo "Processing date: ${DATE}"
  echo "=============================================="

  START="${DATE}T00:00:00"
  END="${DATE}T23:59:59"

  # ----------------------------
  # PHYSICAL VARIABLES
  # ----------------------------
  copernicusmarine subset \
    --dataset-id cmems_mod_glo_phy_my_0.083deg_P1D-m \
    --variable mlotst \
    --variable zos \
    --variable thetao \
    --variable so \
    --variable uo \
    --variable vo \
    --start-datetime ${START} \
    --end-datetime ${END} \
    --minimum-longitude ${MIN_LON} \
    --maximum-longitude ${MAX_LON} \
    --minimum-latitude ${MIN_LAT} \
    --maximum-latitude ${MAX_LAT} \
    --minimum-depth ${PHY_DEPTH} \
    --maximum-depth ${PHY_DEPTH} \
    --output-directory "${OUTDIR}"

  # ----------------------------
  # BIOGEOCHEMICAL VARIABLES
  # ----------------------------
  copernicusmarine subset \
    --dataset-id cmems_mod_glo_bgc_my_0.25deg_P1D-m \
    --variable chl \
    --variable nppv \
    --start-datetime ${START} \
    --end-datetime ${END} \
    --minimum-longitude ${MIN_LON} \
    --maximum-longitude ${MAX_LON} \
    --minimum-latitude ${MIN_LAT} \
    --maximum-latitude ${MAX_LAT} \
    --minimum-depth ${BGC_DEPTH} \
    --maximum-depth ${BGC_DEPTH} \
    --output-directory "${OUTDIR}"

done < "${DATES_FILE}"

echo "=============================================="
echo "DONE"
echo "Environmental data downloaded ONLY for tracking dates"
echo "Output directory: ${OUTDIR}"
echo "=============================================="