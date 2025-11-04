#!/bin/bash
# fMRIPrep - Functional MRI Preprocessing Pipeline
# A robust preprocessing workflow for functional MRI data
#
# Usage: ./04_run_fmriprep.sh [participant_label]
#
# Requirements:
#   - Docker or Singularity with fMRIPrep image
#   - FreeSurfer license file
#
# Author: Neuroimaging Pipeline
# Date: November 2025

set -e
set -u

# Configuration
PIPELINE_DIR="/home/claude/neuroimaging_pipeline"
BIDS_DIR="${PIPELINE_DIR}/bids_data"
OUTPUT_DIR="${PIPELINE_DIR}/derivatives/fmriprep"
WORK_DIR="${PIPELINE_DIR}/work/fmriprep"
LOG_DIR="${PIPELINE_DIR}/logs"
FS_LICENSE="${PIPELINE_DIR}/code/license.txt"

# fMRIPrep version
FMRIPREP_VERSION="23.2.0"

# Participant to process (optional, processes all if not specified)
PARTICIPANT_LABEL="${1:-}"

# Create directories
mkdir -p "${OUTPUT_DIR}" "${WORK_DIR}" "${LOG_DIR}"

LOGFILE="${LOG_DIR}/fmriprep_$(date +%Y%m%d_%H%M%S).log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOGFILE}"
}

log_message "========================================="
log_message "fMRIPrep - Functional MRI Preprocessing"
log_message "========================================="
log_message "fMRIPrep version: ${FMRIPREP_VERSION}"
if [ -n "${PARTICIPANT_LABEL}" ]; then
    log_message "Processing participant: ${PARTICIPANT_LABEL}"
else
    log_message "Processing: ALL participants"
fi
log_message ""

# Check FreeSurfer license
if [ ! -f "${FS_LICENSE}" ]; then
    log_message "WARNING: FreeSurfer license not found at ${FS_LICENSE}"
    log_message "Creating placeholder license file..."
    log_message "Please replace with your actual FreeSurfer license from:"
    log_message "  https://surfer.nmr.mgh.harvard.edu/registration.html"
    
    cat > "${FS_LICENSE}" <<EOF
# FreeSurfer License
# Please replace this with your actual license
# Get license from: https://surfer.nmr.mgh.harvard.edu/registration.html

your.email@institution.edu
12345
*AbCdEfGh
FSabcdefghij
EOF
fi

# Detect container engine
if command -v docker &> /dev/null; then
    CONTAINER_ENGINE="docker"
    log_message "Using Docker"
elif command -v singularity &> /dev/null; then
    CONTAINER_ENGINE="singularity"
    log_message "Using Singularity"
else
    log_message "ERROR: Neither Docker nor Singularity found"
    exit 1
fi

# Build participant label argument
PARTICIPANT_ARG=""
if [ -n "${PARTICIPANT_LABEL}" ]; then
    PARTICIPANT_ARG="--participant-label ${PARTICIPANT_LABEL}"
fi

# Run fMRIPrep
log_message "Starting fMRIPrep..."
log_message "This will take several hours per participant..."
log_message ""

if [ "${CONTAINER_ENGINE}" == "docker" ]; then
    docker run --rm -it \
        -v "${BIDS_DIR}:/data:ro" \
        -v "${OUTPUT_DIR}:/out" \
        -v "${WORK_DIR}:/work" \
        -v "${FS_LICENSE}:/opt/freesurfer/license.txt:ro" \
        nipreps/fmriprep:${FMRIPREP_VERSION} \
        /data /out participant \
        ${PARTICIPANT_ARG} \
        --work-dir /work \
        --output-spaces MNI152NLin2009cAsym:res-2 anat fsnative \
        --bold2t1w-dof 9 \
        --bold2t1w-init register \
        --use-syn-sdc \
        --output-layout bids \
        --n_cpus 4 \
        --mem_mb 16000 \
        --skip_bids_validation \
        --write-graph \
        --stop-on-first-crash \
        --fs-no-reconall 2>&1 | tee -a "${LOGFILE}"

elif [ "${CONTAINER_ENGINE}" == "singularity" ]; then
    SINGULARITY_IMAGE="${PIPELINE_DIR}/containers/fmriprep_${FMRIPREP_VERSION}.sif"
    
    if [ ! -f "${SINGULARITY_IMAGE}" ]; then
        log_message "Pulling Singularity image (this may take a while)..."
        mkdir -p "$(dirname "${SINGULARITY_IMAGE}")"
        singularity pull "${SINGULARITY_IMAGE}" \
            docker://nipreps/fmriprep:${FMRIPREP_VERSION}
    fi
    
    singularity run --cleanenv \
        -B "${BIDS_DIR}:/data:ro" \
        -B "${OUTPUT_DIR}:/out" \
        -B "${WORK_DIR}:/work" \
        -B "${FS_LICENSE}:/opt/freesurfer/license.txt:ro" \
        "${SINGULARITY_IMAGE}" \
        /data /out participant \
        ${PARTICIPANT_ARG} \
        --work-dir /work \
        --output-spaces MNI152NLin2009cAsym:res-2 anat fsnative \
        --bold2t1w-dof 9 \
        --bold2t1w-init register \
        --use-syn-sdc \
        --output-layout bids \
        --n_cpus 4 \
        --mem_mb 16000 \
        --skip_bids_validation \
        --write-graph \
        --stop-on-first-crash \
        --fs-no-reconall 2>&1 | tee -a "${LOGFILE}"
fi

log_message ""
log_message "========================================="
log_message "fMRIPrep Complete!"
log_message "========================================="
log_message "Output directory: ${OUTPUT_DIR}"
log_message "Log file: ${LOGFILE}"
log_message ""
log_message "Key outputs:"
log_message "  - Preprocessed BOLD: ${OUTPUT_DIR}/sub-*/ses-*/func/*_space-*_desc-preproc_bold.nii.gz"
log_message "  - Brain mask: ${OUTPUT_DIR}/sub-*/ses-*/func/*_space-*_desc-brain_mask.nii.gz"
log_message "  - Confounds: ${OUTPUT_DIR}/sub-*/ses-*/func/*_desc-confounds_timeseries.tsv"
log_message "  - HTML reports: ${OUTPUT_DIR}/sub-*.html"
log_message ""
log_message "View HTML reports in your browser:"
log_message "  firefox ${OUTPUT_DIR}/sub-*.html"
