# Neuroimaging Pipeline Configuration
# Edit this file to customize your processing parameters

# ============================================================================
# General Settings
# ============================================================================

# Pipeline directory (automatically set by scripts)
PIPELINE_DIR="/home/claude/neuroimaging_pipeline"

# Number of CPUs to use (adjust based on your system)
N_CPUS=4

# Memory limit in GB
MEM_GB=16

# ============================================================================
# Container Settings
# ============================================================================

# Container engine (docker or singularity)
CONTAINER_ENGINE="docker"

# Container versions
FMRIPREP_VERSION="23.2.0"
MRIQC_VERSION="23.1.0"
QSIPREP_VERSION="0.19.0"
FREESURFER_VERSION="7.4.1"

# Singularity cache directory (for HPC)
SINGULARITY_CACHEDIR="${PIPELINE_DIR}/containers"

# ============================================================================
# BIDS Conversion Settings (dcm2niix)
# ============================================================================

# Output file compression (y/n)
COMPRESS_NIFTI="y"

# Create BIDS sidecar JSON (y/n)
CREATE_BIDS_JSON="y"

# Anonymize output (y/n) - set to 'n' to preserve all metadata
ANONYMIZE="n"

# ============================================================================
# fMRIPrep Settings
# ============================================================================

# Output spaces (space-separated list)
# Options: MNI152NLin2009cAsym, MNI152NLin6Asym, MNI152NLin2009cAsym:res-2, anat, fsnative, fsaverage
OUTPUT_SPACES="MNI152NLin2009cAsym:res-2 anat fsnative"

# Degrees of freedom for BOLD to T1w registration
BOLD2T1W_DOF=9

# Use fieldmap-free distortion correction (--use-syn-sdc)
USE_SYN_SDC=true

# Run FreeSurfer reconstruction (takes ~6-8 hours per subject)
RUN_FREESURFER=false

# Skip BIDS validation
SKIP_BIDS_VALIDATION=true

# Stop on first crash (useful for debugging)
STOP_ON_FIRST_CRASH=true

# ============================================================================
# MRIQC Settings
# ============================================================================

# Generate verbose reports with individual plots
VERBOSE_REPORTS=true

# Use 32-bit floating point (reduces memory)
FLOAT32=true

# ============================================================================
# QSIPrep Settings (Diffusion)
# ============================================================================

# Output resolution (1.25, 2, etc. in mm)
OUTPUT_RESOLUTION=2

# Head motion correction model (none, eddy, eddy_ingress_filter)
HMC_MODEL="eddy"

# Denoising method (none, dwidenoise, patch2self)
DENOISE_METHOD="dwidenoise"

# Output space for DWI (T1w, template)
DWI_OUTPUT_SPACE="T1w"

# ============================================================================
# HPC/SLURM Settings
# ============================================================================

# SLURM partition
SLURM_PARTITION="general"

# Maximum number of simultaneous jobs per array
SLURM_ARRAY_LIMIT=5

# Time limits
MRIQC_TIME="12:00:00"
FMRIPREP_TIME="24:00:00"
FREESURFER_TIME="30:00:00"
QSIPREP_TIME="20:00:00"

# Memory allocations (in GB)
MRIQC_MEM=16
FMRIPREP_MEM=32
FREESURFER_MEM=16
QSIPREP_MEM=32

# CPU allocations
MRIQC_CPUS=4
FMRIPREP_CPUS=8
FREESURFER_CPUS=4
QSIPREP_CPUS=8

# ============================================================================
# Quality Control Settings
# ============================================================================

# Framewise displacement threshold for motion flagging (mm)
FD_THRESHOLD=0.5

# Severe motion threshold for exclusion (mm)
FD_SEVERE_THRESHOLD=0.9

# Minimum acceptable temporal SNR
MIN_TSNR=40

# Minimum acceptable SNR for T1w
MIN_T1W_SNR=8

# ============================================================================
# Data Management
# ============================================================================

# Clean up work directories after successful completion
CLEANUP_WORK=false

# Keep intermediate files for debugging
KEEP_INTERMEDIATE=true

# Generate visual QC reports
GENERATE_QC_REPORTS=true

# ============================================================================
# FreeSurfer License
# ============================================================================

# Path to FreeSurfer license file
# Obtain from: https://surfer.nmr.mgh.harvard.edu/registration.html
FS_LICENSE="${PIPELINE_DIR}/code/license.txt"

# ============================================================================
# Notes
# ============================================================================

# - Adjust CPU and memory settings based on your system resources
# - For HPC use, modify SLURM settings in slurm/*.sh scripts
# - Container images will be cached in $SINGULARITY_CACHEDIR
# - Set CLEANUP_WORK=true to save disk space after successful runs
# - Enable RUN_FREESURFER only if you need cortical surface reconstructions
