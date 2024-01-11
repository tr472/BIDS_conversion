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
OUTPUT_PATH="${PROJECT_PATH}/data/work/dicom_discovery/"

# Subject ID
subject='01'

# ------------------------------------------------------------
# Activate the heudiconv environment
# ------------------------------------------------------------
conda activate heudiconv

# ------------------------------------------------------------
# Run the heudiconv
# ------------------------------------------------------------
heudiconv \
    --files "${RAW_PATH}"/*/*/*.dcm \
    --outdir "${OUTPUT_PATH}" \
    --heuristic convertall \
    --subjects "${subject}" \
    --converter none \
    --bids \
    --overwrite
# ------------------------------------------------------------

# Deactivate the heudiconv environment
conda deactivate