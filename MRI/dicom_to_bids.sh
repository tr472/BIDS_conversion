#!/bin/bash

# ============================================================
#
# Converting CBU DICOM files into BIDS format using Heudiconv
#
# Run the script with this command: sbatch dicom_to_bids.sh
#
# ============================================================


# ------------------------------------------------------------
# SLURM job configuration
# !Edit the SBATCH variables as needed!
# !The output and error directories must exist before running the script!
# ------------------------------------------------------------
#SBATCH --job-name=heudiconv_%a
#SBATCH --output=/imaging/correia/da05/wiki/BIDS_conversion/MRI/data/work/heudiconv_job_%A_%a.out
#SBATCH --error=/imaging/correia/da05/wiki/BIDS_conversion/MRI/data/work/heudiconv_job_%A_%a.err
#SBATCH --array=0  # Adjust the array range to match the number of subjects, in this case 4 (indexed from 0)

# SLURM will create separate tasks for each array index (each subject). The SLURM_ARRAY_TASK_ID (used later in the script)
# will correspond to the subject index. SLURM will handle the parallelization across the specified array range.

# ------------------------------------------------------------
# !Fill in the following variables according to your project!
# ------------------------------------------------------------
# Your project's root directory
PROJECT_PATH="/imaging/correia/da05/wiki/BIDS_conversion/MRI"
# Location of the output data
OUTPUT_PATH=$PROJECT_PATH/data/
# Your MRI project code, to locate your data
PROJECT_CODE="MR09029"
# List of subject CBU codes as they appear in the /mridata/cbu/ folder
SUBJECT_CBU_CODES=(
    "CBU090942" # Subject 01
    "CBU090938" # Subject 02
    "CBU090964" # Subject 03
    "CBU090928" # Subject 04
)

# Create a list of subject IDs as they will appear in the BIDS dataset
SUBJECT_LIST=(01 02 03 04)
# If your subject IDs are from 01 to [number of items in the SUBJECT_CBU_CODES], you can generate this list automatically 
# using the following command:
# SUBJECT_LIST=($(seq -f "%02g" 1 ${#RAW_PATH_LIST[@]}))

# Location of the heudiconv heuristic file
HEURISTIC_FILE="${PROJECT_PATH}/bids_heuristic.py"

# ------------------------------------------------------------



# ------------------------------------------------------------
# You don't have to change anything below this line!
# ------------------------------------------------------------

# Create a list of paths to the raw data for each subject
RAW_PATH_LIST=()
for subject in "${SUBJECT_CBU_CODES[@]}"; do
    SUBJECT_PATH="/mridata/cbu/${subject}_${PROJECT_CODE}"
    RAW_PATH_LIST+=("$SUBJECT_PATH")
done
# The above loop is equivalent to:
# RAW_PATH_LIST=(
#     '/mridata/cbu/CBU090942_MR09029'
#     '/mridata/cbu/CBU090938_MR09029'
#     '/mridata/cbu/CBU090964_MR09029'
#     '/mridata/cbu/CBU090928_MR09029'
# )

# Check if the heuristic file exists. If not, add to the error output log (that's what >&2 does) and exit the script.
if [ ! -f "$HEURISTIC_FILE" ]; then
    echo "Heuristic file not found: ${HEURISTIC_FILE}. Exiting..." >&2
    exit 1
fi

# Get the subject ID for the current job
subject="${SUBJECT_LIST[$SLURM_ARRAY_TASK_ID]}"

# Add some information to the job output
cbu_code="${SUBJECT_CBU_CODES[$SLURM_ARRAY_TASK_ID]}"
echo "Processing subject ${subject} (${cbu_code})..."

# Get the path to the raw data for the current job
RAW_PATH="${RAW_PATH_LIST[$SLURM_ARRAY_TASK_ID]}"

# Check if the raw data path exists. 
if [ ! -d "$RAW_PATH" ]; then
    echo "Raw data path for ${cbu_code} not found. Exiting..." >&2
    exit 1
fi

# Load the apptainer module
module purge # Unload any existing modules to avoid conflicts
module load apptainer

# Check if the module was loaded successfully
if ! module list 2>&1 | grep -q "apptainer"; then
    echo "Failed to load apptainer module. Exiting..." >&2
    exit 1
fi

# Run the container
apptainer run --cleanenv \
    --bind "${PROJECT_PATH},${RAW_PATH},${HEURISTIC_FILE}" \
    /imaging/local/software/singularity_images/heudiconv/heudiconv_latest.sif \
    --files "${RAW_PATH}"/*/*/*.dcm \
    --outdir "$OUTPUT_PATH" \
    --heuristic "${HEURISTIC_FILE}" \
    --subjects "${subject}" \
    --converter dcm2niix \
    --bids \
    --overwrite

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

# Unload the apptainer module
module unload apptainer