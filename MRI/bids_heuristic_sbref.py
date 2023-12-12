# Heuristic for converting DICOMs to BIDS using heudiconv
# This file is used by heudiconv to convert DICOMs to BIDS format.
# It is called by heudiconv using the -f (or --heuristic) flag, e.g.:
# heudiconv -d /path/to/dicoms/{subject}/*/*/*.dcm -s 001 -f bids_heuristic.py -c dcm2niix -b -o /path/to/bids
# 
# see https://heudiconv.readthedocs.io/en/latest/heuristics.html

# --------------------------------------------------------------------------------------
# create_key: A common helper function used to create the conversion key in infotodict. 
# But it is not used directly by HeuDiConv.
# --------------------------------------------------------------------------------------
def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes
# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------
# Dictionary to specify options to populate the 'IntendedFor' field of the fmap jsons.
#
# See https://heudiconv.readthedocs.io/en/latest/heuristics.html#populate-intended-for-opts
#
# If POPULATE_INTENDED_FOR_OPTS is not present in the heuristic file, IntendedFor will not be populated automatically.
# --------------------------------------------------------------------------------------
POPULATE_INTENDED_FOR_OPTS = {
    'matching_parameters': ['ModalityAcquisitionLabel'],
    'criterion': 'Closest'
}
# 'ModalityAcquisitionLabel': it checks for what modality (anat, func, dwi) each fmap is 
# intended by checking the _acq- label in the fmap filename and finding corresponding 
# modalities (e.g. _acq-fmri, _acq-bold and _acq-func will be matched with the func modality)

# --------------------------------------------------------------------------------------
# infotodict: A function to assist in creating the dictionary, and to be used inside heudiconv.
# This is a required function for heudiconv to run.
#
# seqinfo is a record of DICOM's passed in by heudiconv. Each item in seqinfo contains DICOM metadata 
# that can be used to isolate the series, and assign it to a conversion key.

# --------------------------------------------------------------------------------------
def infotodict(seqinfo):

    # Specify the conversion template for each series following the BIDS format.
    # See https://bids-specification.readthedocs.io/en/stable/04-modality-specific-files/01-magnetic-resonance-imaging-data.html
    
    # The structural/anatomical scan
    anat = create_key('sub-{subject}/anat/sub-{subject}_T1w')
    
    # The fieldmap scans
    fmap_mag = create_key('sub-{subject}/fmap/sub-{subject}_acq-func_magnitude')
    fmap_phase = create_key('sub-{subject}/fmap/sub-{subject}_acq-func_phasediff')
    fmap_rev_phase = create_key('sub-{subject}/fmap/sub-{subject}_acq-func_dir-PA_epi')
    fmap_sbref = create_key('sub-{subject}/fmap/sub-{subject}_acq-func_dir-PA_sbref')
    
    # The functional scans
    # You need to specify the task name in the filename. It must be a single string of letters WITHOUT spaces, underscores, or dashes!
    func_task = create_key(
        'sub-{subject}/func/sub-{subject}_task-video_run-0{item:01d}_bold')
    func_sbref = create_key(
        'sub-{subject}/func/sub-{subject}_task-video_run-0{item:01d}_sbref')
    
    # Create the dictionary that will be returned by this function.
    info = {
        anat: [], 
        fmap_mag: [], 
        fmap_phase: [], 
        fmap_rev_phase: [],
        fmap_sbref: [], 
        func_task: [], 
        func_sbref: []
        }

    #---------------------
    # For handling sbref images, as discussed here https://neurostars.org/t/handling-sbref-images-in-heudiconv/5681
    latest_sbref = None
    func2sbref = {}
    #---------------------

    # Loop through all the DICOM series and assign them to the appropriate conversion key.
    for s in seqinfo:
        # Uniquelly identify each series
        
        # Structural
        if "MPRAGE" in s.protocol_name:
            info[anat].append(s.series_id)
            
        # Field map Magnitude (the fieldmap with the largest dim3 is the magnitude, the other is the phase)
        if (s.dim3 == 76) and ('fieldmap' in s.protocol_name):
            info[fmap_mag].append(s.series_id)
            
        # Field map PhaseDiff
        if (s.dim3 == 38) and ('fieldmap' in s.protocol_name):
            info[fmap_phase].append(s.series_id)
            
        # Field map opposite phase-encoding direction (PA) and its sbref
        if (s.dim4 == 8) and ('_MB2_PA_2' in s.protocol_name):
            info[fmap_rev_phase].append(s.series_id)
        if (s.dim4 == 1) and ('_MB2_PA_2' in s.protocol_name):
            info[fmap_sbref].append(s.series_id)

        # Functional Reference (sbref)
        if (s.dim1 == 64) and (s.dim4 == 1) and ("MB2_AP_2" in s.protocol_name):
            latest_sbref = s.series_id
        # Functional Bold
        elif (s.dim1 == 64) and (s.dim4 > 100):
            info[func_task].append(s.series_id)
            # Only if functional is added, adds the latest sbref 
            # (e.g., avoids adding sbref if func is less than 100 volumes which would indicate a cancelled run)
            if latest_sbref is not None:
                func2sbref[s.series_id] = latest_sbref
                latest_sbref = None
    # Now adds all 'valid' sbref scans
    try:
        func_series_list = info[func_task]
    except Exception:
        func_series_list = None
    # loop through all func runs
    for func_series_id in func_series_list:
        sbref_series_id = func2sbref.get(func_series_id)
        if sbref_series_id is not None:
            info[func_sbref].append(sbref_series_id) 
            
    # Return the dictionary
    return info