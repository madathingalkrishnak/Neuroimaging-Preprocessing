#!/bin/bash
# MRIQC - MRI Quality Control Script
# Generates quality metrics and visual reports for neuroimaging data
#
# Usage: ./03_run_mriqc.sh [participant|group]
#
# Requirements:
#   - Docker or Singularity with MRIQC image
#
# Author: Neuroimaging Pipeline
# Date: November 2025

set -e
set -u

# Configuration
PIPELINE_DIR="/home/claude/neuroimaging_pipeline"
BIDS_DIR="${PIPELINE_DIR}/bids_data"
OUTPUT_DIR="${PIPELINE_DIR}/derivatives/mriqc"
WORK_DIR="${PIPELINE_DIR}/work/mriqc"
LOG_DIR="${PIPELINE_DIR}/logs"
QC_REPORTS_DIR="${PIPELINE_DIR}/qc_reports"

# MRIQC version
MRIQC_VERSION="23.1.0"

# Processing level (participant or group)
ANALYSIS_LEVEL="${1:-participant}"

# Create directories
mkdir -p "${OUTPUT_DIR}" "${WORK_DIR}" "${LOG_DIR}" "${QC_REPORTS_DIR}"

LOGFILE="${LOG_DIR}/mriqc_${ANALYSIS_LEVEL}_$(date +%Y%m%d_%H%M%S).log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOGFILE}"
}

log_message "========================================="
log_message "MRIQC - MRI Quality Control"
log_message "========================================="
log_message "Analysis level: ${ANALYSIS_LEVEL}"
log_message "MRIQC version: ${MRIQC_VERSION}"
log_message ""

# Check if BIDS directory exists
if [ ! -d "${BIDS_DIR}" ]; then
    log_message "ERROR: BIDS directory not found: ${BIDS_DIR}"
    exit 1
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
    log_message "Please install one of these container engines"
    exit 1
fi

# Run MRIQC
log_message "Starting MRIQC..."
log_message "This may take a while depending on data size..."

if [ "${CONTAINER_ENGINE}" == "docker" ]; then
    docker run --rm -it \
        -v "${BIDS_DIR}:/data:ro" \
        -v "${OUTPUT_DIR}:/out" \
        -v "${WORK_DIR}:/work" \
        nipreps/mriqc:${MRIQC_VERSION} \
        /data /out ${ANALYSIS_LEVEL} \
        --work-dir /work \
        --n_procs 4 \
        --mem_gb 16 \
        --float32 \
        --verbose-reports \
        --write-graph 2>&1 | tee -a "${LOGFILE}"

elif [ "${CONTAINER_ENGINE}" == "singularity" ]; then
    # Pull Singularity image if not present
    SINGULARITY_IMAGE="${PIPELINE_DIR}/containers/mriqc_${MRIQC_VERSION}.sif"
    
    if [ ! -f "${SINGULARITY_IMAGE}" ]; then
        log_message "Pulling Singularity image..."
        mkdir -p "$(dirname "${SINGULARITY_IMAGE}")"
        singularity pull "${SINGULARITY_IMAGE}" \
            docker://nipreps/mriqc:${MRIQC_VERSION}
    fi
    
    singularity run --cleanenv \
        -B "${BIDS_DIR}:/data:ro" \
        -B "${OUTPUT_DIR}:/out" \
        -B "${WORK_DIR}:/work" \
        "${SINGULARITY_IMAGE}" \
        /data /out ${ANALYSIS_LEVEL} \
        --work-dir /work \
        --n_procs 4 \
        --mem_gb 16 \
        --float32 \
        --verbose-reports \
        --write-graph 2>&1 | tee -a "${LOGFILE}"
fi

# Copy reports to QC directory
log_message "Copying reports to QC directory..."
if [ "${ANALYSIS_LEVEL}" == "group" ]; then
    cp -r "${OUTPUT_DIR}"/*.html "${QC_REPORTS_DIR}/" 2>/dev/null || true
fi

log_message ""
log_message "========================================="
log_message "MRIQC Complete!"
log_message "========================================="
log_message "Output: ${OUTPUT_DIR}"
log_message "Reports: ${QC_REPORTS_DIR}"
log_message "Log: ${LOGFILE}"
log_message ""

if [ "${ANALYSIS_LEVEL}" == "participant" ]; then
    log_message "Next step: Run group analysis"
    log_message "  ./code/03_run_mriqc.sh group"
else
    log_message "View QC reports:"
    log_message "  firefox ${QC_REPORTS_DIR}/*.html"
fi
