#!/bin/bash
# BIDS Validation Script
# Validates BIDS dataset structure and compliance
#
# Usage: ./02_validate_bids.sh
#
# Requirements:
#   - bids-validator (install: npm install -g bids-validator)
#   - OR use Docker: docker run -it --rm -v $(pwd)/bids_data:/data bids/validator /data
#
# Author: Neuroimaging Pipeline
# Date: November 2025

set -e
set -u

# Configuration
PIPELINE_DIR="/home/claude/neuroimaging_pipeline"
BIDS_DIR="${PIPELINE_DIR}/bids_data"
LOG_DIR="${PIPELINE_DIR}/logs"
LOGFILE="${LOG_DIR}/bids_validation_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "${LOG_DIR}"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOGFILE}"
}

log_message "========================================="
log_message "BIDS Dataset Validation"
log_message "========================================="

# Check if BIDS directory exists
if [ ! -d "${BIDS_DIR}" ]; then
    log_message "ERROR: BIDS directory not found: ${BIDS_DIR}"
    log_message "Please run 01_dicom2bids.sh first"
    exit 1
fi

# Check for bids-validator
if command -v bids-validator &> /dev/null; then
    log_message "Using local bids-validator"
    bids-validator "${BIDS_DIR}" --verbose 2>&1 | tee -a "${LOGFILE}"
    
elif command -v docker &> /dev/null; then
    log_message "Using Docker bids-validator"
    docker run --rm \
        -v "${BIDS_DIR}:/data:ro" \
        bids/validator:latest \
        /data --verbose 2>&1 | tee -a "${LOGFILE}"
        
else
    log_message "WARNING: bids-validator not found"
    log_message "Install with: npm install -g bids-validator"
    log_message "Or use Docker: docker pull bids/validator"
    log_message ""
    log_message "Performing basic structure check instead..."
    
    # Basic structure check
    log_message "Checking for required files:"
    
    required_files=(
        "dataset_description.json"
        "README"
        "participants.tsv"
    )
    
    all_present=true
    for file in "${required_files[@]}"; do
        if [ -f "${BIDS_DIR}/${file}" ]; then
            log_message "  ✓ ${file}"
        else
            log_message "  ✗ ${file} - MISSING"
            all_present=false
        fi
    done
    
    log_message ""
    log_message "Checking for subject data:"
    
    if [ -d "${BIDS_DIR}/sub-"* ] 2>/dev/null; then
        log_message "  ✓ Subject directories found"
        ls -d "${BIDS_DIR}"/sub-* | while read -r subdir; do
            log_message "    - $(basename "${subdir}")"
        done
    else
        log_message "  ✗ No subject directories found"
        all_present=false
    fi
    
    if [ "$all_present" = true ]; then
        log_message ""
        log_message "Basic structure check PASSED"
        log_message "Note: This is not a complete validation"
        log_message "Consider installing bids-validator for thorough validation"
    else
        log_message ""
        log_message "Basic structure check FAILED"
        log_message "Some required files or directories are missing"
        exit 1
    fi
fi

log_message ""
log_message "Validation complete!"
log_message "Log saved to: ${LOGFILE}"
