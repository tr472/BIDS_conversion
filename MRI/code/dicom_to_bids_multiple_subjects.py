#!/usr/bin/env /usr/bin/python3.6

# ============================================================
# Requires Python 3.6 or higher! (because of f-strings)
#
# This script is used to convert multiple subjects from DICOM to BIDS.
# The script calls the 'heudiconv_script.sh' bash script for each subject in the SUBJECT_LIST.
#
# Usage:
#   Configure the variables below and run the script with SLURM: sbatch dicom_to_bids_multiple_subjects.py
#
# ============================================================

# ------------------------------------------------------------
# SLURM job configuration
#
# !Edit the SBATCH variables as needed!
# !The output and error directories must exist before running the script!
# ------------------------------------------------------------

#SBATCH --job-name=heudiconv_%a
#SBATCH --output=/imaging/correia/da05/wiki/BIDS_conversion/MRI/data/work/heudiconv_job_%A_%a.out
#SBATCH --error=/imaging/correia/da05/wiki/BIDS_conversion/MRI/data/work/heudiconv_job_%A_%a.err
#SBATCH --array=1-3

# ------------------------------------------------------------
# SLURM will handle the parallelization across the specified array range.
# SLURM will create separate tasks for each array index.
# The SLURM_ARRAY_TASK_ID will be used later in the script to select a subject from subjects list. 

# ------------------------------------------------------------
# Import packages
# ------------------------------------------------------------
import os # To get environment variables
import sys # To exit the script in case of error
import subprocess # To run shell commands

# ------------------------------------------------------------
#
# !FILL IN THE VARIABLES BELOW!
#
# ------------------------------------------------------------

# Your project's root directory
PROJECT_PATH = '/imaging/correia/da05/wiki/BIDS_conversion/MRI'

# Location of the heudiconv_script bash script
HEUDICONV_SCRIPT = f"{PROJECT_PATH}/code/heudiconv_script.sh"

# Location of the output data
OUTPUT_PATH = f"{PROJECT_PATH}/data/"

# Location of the heudiconv heuristic file
HEURISTIC_FILE = f"{PROJECT_PATH}/code/bids_heuristic.py"

# Root location of dicom files
DICOM_ROOT = '/mridata/cbu'

# Your MRI project code, to locate your data
PROJECT_CODE = 'MR09029'

# List of subject IDs and their corresponding CBU codes as they appear in the DICOM_ROOT folder
SUBJECT_LIST= {
    '02': 'CBU090938', # sub-id how to appear in BIDS and CBU code as in raw dicom folder
    '03': 'CBU090964',
    '04': 'CBU090928'
}
# ------------------------------------------------------------


# ------------------------------------------------------------
# You don't have to change anything below this line!
#
# It is assumed that your raw data is located in /mridata/cbu/{cbu_code}_{PROJECT_CODE}
# If you want to change this, edit the dicom_path variable below and possibly the SUBJECT_LIST above
# ------------------------------------------------------------

# ------------------------------------------------------------
# Get the current subject data
# ------------------------------------------------------------
# SLURM Array Task ID
task_id = int(os.environ.get('SLURM_ARRAY_TASK_ID', 0))

# Get the subject's ID and CBU code
subject_id, cbu_code = list(SUBJECT_LIST.items())[task_id-1] # -1 because SLURM_ARRAY_TASK_ID starts at 1, but python lists start at 0

# Get the path to the raw data
dicom_path = f"{DICOM_ROOT}/{cbu_code}_{PROJECT_CODE}"

# ------------------------------------------------------------
# Start the processing of the current subject
# ------------------------------------------------------------
print(f"Processing subject {subject_id} ({cbu_code})...")

# Check if the heuristic file exists. If not, exit the script.
if not os.path.isfile(HEURISTIC_FILE):
    sys.stderr.write(f"Heuristic file not found: {HEURISTIC_FILE}. Exiting...\n")
    sys.exit(1)

# Check if the raw data path exists. If not, exit the script.
if not os.path.isdir(dicom_path):
    sys.stderr.write(f"Raw data path for {cbu_code} not found. Exiting...\n")
    sys.exit(1)

# Call and run the heudiconv_script bash script
command = (
    f"{HEUDICONV_SCRIPT} {dicom_path} {OUTPUT_PATH} {HEURISTIC_FILE} {subject_id}"
)
subprocess.run(command, shell=True, check=True)

# ------------------------------------------------------------
# End of processing for the current subject
# ------------------------------------------------------------
print(f"Processing of subject {subject_id} ({cbu_code}) finished.")