message("Running Copernicus download script...")

system(
  "bash 01scripts/10downloadCMEMS.sh",
  intern = FALSE,
  wait = TRUE
)

message("Download complete.")

