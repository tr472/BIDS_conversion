#!/bin/bash

# ============================================================
#
# Converting CBU DICOM files into BIDS format using Heudiconv
#
# ============================================================

# ------------------------------------------------------------
# Define your variables
# ------------------------------------------------------------

# Your project's root directory
PROJECT_PATH='/imaging/correia/da05/wiki/BIDS_conversion/MRI'

# Location of the raw data
RAW_PATH='/mridata/cbu/CBU090942_MR09029'

# Location of the output data
OUTPUT_PATH="${PROJECT_PATH}/data/"

# Subject ID
subject='01'

# Location of the heudiconv heuristic file
HEURISTIC_FILE="${PROJECT_PATH}/code/bids_heuristic.py"

# ------------------------------------------------------------
# Activate the heudiconv environment
# ------------------------------------------------------------
CONDA_ENV_PATH="/imaging/local/software/miniconda/envs/heudiconv"
source /imaging/local/software/miniconda/etc/profile.d/conda.sh
conda activate "$CONDA_ENV_PATH"
# ------------------------------------------------------------

# ------------------------------------------------------------
# Run the heudiconv
# ------------------------------------------------------------
heudiconv \
    --files "${RAW_PATH}"/*/*/*.dcm \
    --outdir "${OUTPUT_PATH}" \
    --heuristic "${HEURISTIC_FILE}" \
    --subjects "${subject}" \
    --converter dcm2niix \
    --bids \
    --overwrite
# ------------------------------------------------------------