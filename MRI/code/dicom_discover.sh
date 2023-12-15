#!/bin/bash

# ============================================================
#
# Discovering DICOM files using HeuDiConv
#
# ============================================================

# Your project's root directory
PROJECT_PATH='/imaging/correia/da05/wiki/BIDS_conversion/MRI'

# Location of the raw data
RAW_PATH='/mridata/cbu/CBU090942_MR09029'

# Location of the output data (it will be created if it doesn't exist)
OUTPUT_PATH=$PROJECT_PATH/data/work/dicom_discovery/

# Subject ID
subject="01"

# Load the apptainer module
module load apptainer

# Run the container
apptainer run --cleanenv \
    --bind "${PROJECT_PATH},${RAW_PATH}" \
    /imaging/local/software/singularity_images/heudiconv/heudiconv_latest.sif \
    --files "${RAW_PATH}"/*/*/*.dcm \
    --outdir "$OUTPUT_PATH" \
    --heuristic convertall \
    --subjects "${subject}" \
    --converter none \
    --bids \
    --overwrite

# Unload the apptainer module
module unload apptainer