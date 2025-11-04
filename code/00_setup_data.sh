#!/bin/bash
# Data Setup Script
# Helps extract and organize the example DICOM data
#
# Usage: ./00_setup_data.sh /path/to/example-dicom-functional-master.zip
#
# Author: Neuroimaging Pipeline
# Date: November 2025

set -e
set -u

PIPELINE_DIR="/home/claude/neuroimaging_pipeline"
RAW_DICOM_DIR="${PIPELINE_DIR}/raw_dicom"
LOG_DIR="${PIPELINE_DIR}/logs"

mkdir -p "${LOG_DIR}"
LOGFILE="${LOG_DIR}/data_setup_$(date +%Y%m%d_%H%M%S).log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOGFILE}"
}

log_message "========================================="
log_message "Data Setup Script"
log_message "========================================="
log_message ""

# Check if zip file provided
if [ $# -eq 0 ]; then
    log_message "Usage: $0 /path/to/example-dicom-functional-master.zip"
    log_message ""
    log_message "This script will:"
    log_message "  1. Extract your DICOM data"
    log_message "  2. Organize it in the correct structure"
    log_message "  3. Prepare it for BIDS conversion"
    log_message ""
    log_message "If you don't have the data yet, download it from:"
    log_message "  https://github.com/datalad/example-dicom-functional"
    log_message "  (Click 'Code' > 'Download ZIP')"
    exit 1
fi

ZIP_FILE="$1"

# Check if zip file exists
if [ ! -f "${ZIP_FILE}" ]; then
    log_message "ERROR: File not found: ${ZIP_FILE}"
    exit 1
fi

log_message "Input file: ${ZIP_FILE}"
log_message "Extracting to: ${RAW_DICOM_DIR}"
log_message ""

# Create raw_dicom directory
mkdir -p "${RAW_DICOM_DIR}"

# Extract zip file
log_message "Extracting data..."
unzip -q "${ZIP_FILE}" -d "${RAW_DICOM_DIR}"

# Find the extracted directory
EXTRACTED_DIR=$(find "${RAW_DICOM_DIR}" -maxdepth 1 -type d -name "*example-dicom-functional*" | head -n 1)

if [ -z "${EXTRACTED_DIR}" ]; then
    log_message "ERROR: Could not find extracted directory"
    exit 1
fi

log_message "Found extracted directory: ${EXTRACTED_DIR}"

# Move DICOM files to the correct location
log_message "Organizing DICOM files..."

# The example dataset structure is typically: SeriesNumber_SeriesDescription/
# We want to move these to the main raw_dicom directory
if [ -d "${EXTRACTED_DIR}" ]; then
    # Move all subdirectories containing DICOM files
    find "${EXTRACTED_DIR}" -type d -exec sh -c '
        if ls "$1"/*.dcm 2>/dev/null || ls "$1"/*.IMA 2>/dev/null; then
            echo "Moving: $1"
            mv "$1" "'"${RAW_DICOM_DIR}"/"'"
        fi
    ' sh {} \;
    
    # Remove the now-empty extracted directory
    rm -rf "${EXTRACTED_DIR}"
fi

log_message ""
log_message "Data structure:"
tree -L 2 "${RAW_DICOM_DIR}" | tee -a "${LOGFILE}"

log_message ""
log_message "========================================="
log_message "Setup Complete!"
log_message "========================================="
log_message "DICOM data location: ${RAW_DICOM_DIR}"
log_message ""
log_message "Next steps:"
log_message "  1. Convert DICOM to BIDS:"
log_message "       ./code/01_dicom2bids.sh"
log_message ""
log_message "  2. Validate BIDS dataset:"
log_message "       ./code/02_validate_bids.sh"
log_message ""
log_message "  3. Run quality control:"
log_message "       ./code/03_run_mriqc.sh"
log_message ""
log_message "See README.md for complete pipeline documentation"
