#!/bin/bash

# ============================================================
# This script runs the HeuDiConv tool to convert DICOM files to NIfTI files and organize them into a BIDS structure.
#
# Usage:
#   ./heudiconv_script.sh <DICOM_PATH> <OUTPUT_PATH> <HEURISTIC_FILE> <SUBJECT_ID>
#
# Arguments:
#   DICOM_PATH: Path to the raw DICOM files
#   OUTPUT_PATH: Path to the output directory
#   HEURISTIC_FILE: Path to the heuristic file
#   SUBJECT_ID: Subject ID
#
# Example:
#   ./heudiconv_script.sh /home/username/data/dicom /home/username/data/bids /home/username/code/heuristic.py 01
#
# It is assumed that you have a conda environment called 'heudiconv' available (check with 'conda env list'). 
# If not, create a conda environment with the heudiconv and dcm2niix packages installed.
#
# ============================================================

# ------------------------------------------------------------
# Parse the arguments passed to the script
# ------------------------------------------------------------
DICOM_PATH="${1}"
OUTPUT_PATH="${2}"
HEURISTIC_FILE="${3}"
SUBJECT_ID="${4}"

# ------------------------------------------------------------
# Activate the heudiconv environment
# ------------------------------------------------------------
conda activate heudiconv

# ------------------------------------------------------------
# Run the heudiconv
# ------------------------------------------------------------
heudiconv \
    --files "${DICOM_PATH}"/*/*/*.dcm \
    --outdir "${OUTPUT_PATH}" \
    --heuristic "${HEURISTIC_FILE}" \
    --subjects "${SUBJECT_ID}" \
    --converter dcm2niix \
    --bids \
    --overwrite

# ------------------------------------------------------------
# Deactivate the heudiconv environment
# ------------------------------------------------------------
conda deactivate

# ============================================================
# HeudiConv parameters:
# --files: Files or directories containing files to process
# --outdir: Output directory
# --heuristic: Name of a known heuristic or path to the Python script containing heuristic
# --subjects: Subject ID
# --converter : dicom to nii converter (dcm2niix or none)
# --bids: Flag for output into BIDS structure
# --overwrite: Flag to overwrite existing files
# 
# For a full list of parameters, see: https://heudiconv.readthedocs.io/en/latest/usage.html 
#
# ============================================================