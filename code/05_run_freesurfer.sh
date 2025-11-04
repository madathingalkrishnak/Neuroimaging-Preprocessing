#!/bin/bash
# FreeSurfer - Cortical Reconstruction and Volumetric Segmentation
# Performs surface-based analysis of structural MRI data
#
# Usage: ./05_run_freesurfer.sh [participant_label]
#
# Requirements:
#   - FreeSurfer installation or Docker/Singularity
#   - FreeSurfer license
#
# Author: Neuroimaging Pipeline
# Date: November 2025

set -e
set -u

# Configuration
PIPELINE_DIR="/home/claude/neuroimaging_pipeline"
BIDS_DIR="${PIPELINE_DIR}/bids_data"
OUTPUT_DIR="${PIPELINE_DIR}/derivatives/freesurfer"
LOG_DIR="${PIPELINE_DIR}/logs"
FS_LICENSE="${PIPELINE_DIR}/code/license.txt"

# Participant to process
PARTICIPANT_LABEL="${1:-}"

mkdir -p "${OUTPUT_DIR}" "${LOG_DIR}"

LOGFILE="${LOG_DIR}/freesurfer_$(date +%Y%m%d_%H%M%S).log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOGFILE}"
}

log_message "========================================="
log_message "FreeSurfer - Cortical Reconstruction"
log_message "========================================="
log_message ""

# Check for FreeSurfer license
if [ ! -f "${FS_LICENSE}" ]; then
    log_message "ERROR: FreeSurfer license not found"
    log_message "Please obtain license from: https://surfer.nmr.mgh.harvard.edu/registration.html"
    exit 1
fi

# Check if FreeSurfer is installed locally
if command -v recon-all &> /dev/null; then
    log_message "Using local FreeSurfer installation"
    export FREESURFER_HOME=$(dirname $(dirname $(which recon-all)))
    export SUBJECTS_DIR="${OUTPUT_DIR}"
    source "${FREESURFER_HOME}/SetUpFreeSurfer.sh"
    
    # Find T1w images
    for subject_dir in "${BIDS_DIR}"/sub-*; do
        if [ -d "${subject_dir}" ]; then
            SUBJECT=$(basename "${subject_dir}")
            
            if [ -n "${PARTICIPANT_LABEL}" ] && [ "${SUBJECT}" != "sub-${PARTICIPANT_LABEL}" ]; then
                continue
            fi
            
            log_message "Processing ${SUBJECT}..."
            
            # Find T1w image
            T1W_IMAGE=$(find "${subject_dir}" -name "*T1w.nii.gz" -o -name "*T1w.nii" | head -n 1)
            
            if [ -z "${T1W_IMAGE}" ]; then
                log_message "  WARNING: No T1w image found for ${SUBJECT}"
                continue
            fi
            
            log_message "  Input: ${T1W_IMAGE}"
            
            # Run recon-all
            recon-all \
                -subject "${SUBJECT}" \
                -i "${T1W_IMAGE}" \
                -all \
                -parallel \
                -openmp 4 2>&1 | tee -a "${LOGFILE}"
            
            log_message "  ${SUBJECT} complete!"
        fi
    done

elif command -v docker &> /dev/null; then
    log_message "Using Docker FreeSurfer"
    
    FREESURFER_VERSION="7.4.1"
    
    for subject_dir in "${BIDS_DIR}"/sub-*; do
        if [ -d "${subject_dir}" ]; then
            SUBJECT=$(basename "${subject_dir}")
            
            if [ -n "${PARTICIPANT_LABEL}" ] && [ "${SUBJECT}" != "sub-${PARTICIPANT_LABEL}" ]; then
                continue
            fi
            
            log_message "Processing ${SUBJECT}..."
            
            T1W_IMAGE=$(find "${subject_dir}" -name "*T1w.nii.gz" -o -name "*T1w.nii" | head -n 1)
            
            if [ -z "${T1W_IMAGE}" ]; then
                log_message "  WARNING: No T1w image found for ${SUBJECT}"
                continue
            fi
            
            docker run --rm \
                -v "${subject_dir}:/input:ro" \
                -v "${OUTPUT_DIR}:/output" \
                -v "${FS_LICENSE}:/opt/freesurfer/license.txt:ro" \
                freesurfer/freesurfer:${FREESURFER_VERSION} \
                recon-all \
                -subject "${SUBJECT}" \
                -i "/input/$(basename "${T1W_IMAGE}")" \
                -sd /output \
                -all \
                -parallel \
                -openmp 4 2>&1 | tee -a "${LOGFILE}"
        fi
    done

else
    log_message "ERROR: FreeSurfer not found"
    log_message "Please install FreeSurfer or Docker"
    exit 1
fi

log_message ""
log_message "========================================="
log_message "FreeSurfer Complete!"
log_message "========================================="
log_message "Output: ${OUTPUT_DIR}"
log_message "Log: ${LOGFILE}"
log_message ""
log_message "Key outputs per subject:"
log_message "  - Brain volumes: stats/aseg.stats"
log_message "  - Cortical parcellation: stats/aparc.stats"
log_message "  - Surfaces: surf/lh.pial, surf/rh.pial"
log_message "  - QA images: mri/brainmask.mgz"
log_message ""
log_message "Visualize results:"
log_message "  freeview -v \${SUBJECTS_DIR}/sub-01/mri/T1.mgz \\"
log_message "           -f \${SUBJECTS_DIR}/sub-01/surf/lh.pial:edgecolor=red \\"
log_message "              \${SUBJECTS_DIR}/sub-01/surf/rh.pial:edgecolor=red"
