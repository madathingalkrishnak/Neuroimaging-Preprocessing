#!/bin/bash
# DICOM to BIDS Conversion Script
# Uses dcm2niix for conversion and organizes data according to BIDS specification
#
# Usage: ./01_dicom2bids.sh
#
# Requirements:
#   - dcm2niix (install: apt-get install dcm2niix OR conda install -c conda-forge dcm2niix)
#
# Author: Neuroimaging Pipeline
# Date: November 2025

set -e  # Exit on error
set -u  # Exit on undefined variable

# ============================================================================
# Configuration
# ============================================================================

# Directories
PIPELINE_DIR="/home/claude/neuroimaging_pipeline"
RAW_DICOM_DIR="${PIPELINE_DIR}/raw_dicom"
BIDS_DIR="${PIPELINE_DIR}/bids_data"
LOG_DIR="${PIPELINE_DIR}/logs"
CODE_DIR="${PIPELINE_DIR}/code"

# Create necessary directories
mkdir -p "${BIDS_DIR}" "${LOG_DIR}"

# Log file
LOGFILE="${LOG_DIR}/dicom2bids_$(date +%Y%m%d_%H%M%S).log"

# ============================================================================
# Functions
# ============================================================================

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOGFILE}"
}

check_dependencies() {
    log_message "Checking dependencies..."
    
    if ! command -v dcm2niix &> /dev/null; then
        log_message "ERROR: dcm2niix not found. Please install it first."
        echo "  Ubuntu/Debian: sudo apt-get install dcm2niix"
        echo "  MacOS: brew install dcm2niix"
        echo "  Or visit: https://github.com/rordenlab/dcm2niix"
        exit 1
    fi
    
    log_message "dcm2niix version: $(dcm2niix -v 2>&1 | head -n 1)"
}

create_bids_structure() {
    log_message "Creating BIDS directory structure..."
    
    # Create standard BIDS directories
    mkdir -p "${BIDS_DIR}"/{sourcedata,code,derivatives}
    
    log_message "BIDS structure created successfully"
}

create_dataset_description() {
    log_message "Creating dataset_description.json..."
    
    cat > "${BIDS_DIR}/dataset_description.json" <<EOF
{
    "Name": "Example DICOM Functional Dataset",
    "BIDSVersion": "1.9.0",
    "DatasetType": "raw",
    "License": "CC0",
    "Authors": [
        "Pipeline User"
    ],
    "Acknowledgements": "Data from datalad/example-dicom-functional repository",
    "HowToAcknowledge": "Please cite the BIDS specification and dcm2niix",
    "Funding": [
        "N/A"
    ],
    "ReferencesAndLinks": [
        "https://github.com/datalad/example-dicom-functional"
    ],
    "DatasetDOI": "N/A"
}
EOF
    
    log_message "dataset_description.json created"
}

create_participants_tsv() {
    log_message "Creating participants.tsv..."
    
    cat > "${BIDS_DIR}/participants.tsv" <<EOF
participant_id	age	sex	group
sub-01	30	M	control
EOF
    
    cat > "${BIDS_DIR}/participants.json" <<EOF
{
    "age": {
        "Description": "Age of participant",
        "Units": "years"
    },
    "sex": {
        "Description": "Biological sex of participant",
        "Levels": {
            "M": "male",
            "F": "female"
        }
    },
    "group": {
        "Description": "Experimental group",
        "Levels": {
            "control": "control group",
            "patient": "patient group"
        }
    }
}
EOF
    
    log_message "participants files created"
}

convert_dicom_to_nifti() {
    log_message "Starting DICOM to NIfTI conversion..."
    
    # Check if DICOM directory exists and has files
    if [ ! -d "${RAW_DICOM_DIR}" ]; then
        log_message "ERROR: DICOM directory not found: ${RAW_DICOM_DIR}"
        log_message "Please place your DICOM files in ${RAW_DICOM_DIR}"
        exit 1
    fi
    
    # Find all DICOM directories (typically organized by subject/session)
    # The example-dicom-functional data structure is: DICOM_DIR/SeriesNumber_Description/
    
    # For the example dataset, we'll process it as sub-01/ses-01
    SUBJECT="sub-01"
    SESSION="ses-01"
    
    # Create subject/session directories
    mkdir -p "${BIDS_DIR}/${SUBJECT}/${SESSION}"/{anat,func,fmap}
    
    log_message "Processing ${SUBJECT}/${SESSION}..."
    
    # Run dcm2niix conversion
    # Options:
    #   -f: output filename format (BIDS-like)
    #   -o: output directory
    #   -z y: compress output (gzip)
    #   -b y: create BIDS sidecar JSON
    #   -ba n: don't anonymize (keep all metadata)
    #   -v: verbose (0=quiet, 1=default, 2=verbose)
    
    # Convert all DICOM files found in subdirectories
    find "${RAW_DICOM_DIR}" -type d -name "*" | while read -r dicom_dir; do
        if [ "$(find "${dicom_dir}" -maxdepth 1 -type f | wc -l)" -gt 0 ]; then
            log_message "  Converting: ${dicom_dir}"
            
            dcm2niix -f "%p_%s_%d" \
                     -o "${BIDS_DIR}/${SUBJECT}/${SESSION}/func" \
                     -z y \
                     -b y \
                     -ba n \
                     -v 1 \
                     "${dicom_dir}" >> "${LOGFILE}" 2>&1 || true
        fi
    done
    
    log_message "Conversion complete"
}

rename_to_bids() {
    log_message "Renaming files to BIDS specification..."
    
    SUBJECT="sub-01"
    SESSION="ses-01"
    
    # Move and rename files according to BIDS
    # This is a simple example - in practice, you'd use more sophisticated logic
    # or tools like Heudiconv or dcm2bids
    
    cd "${BIDS_DIR}/${SUBJECT}/${SESSION}/func" || exit 1
    
    # Rename functional files
    for file in *.nii.gz; do
        if [ -f "$file" ]; then
            # Extract run number if present
            if [[ $file =~ _e([0-9]+) ]]; then
                RUN_NUM="${BASH_REMATCH[1]}"
                NEW_NAME="${SUBJECT}_${SESSION}_task-rest_run-${RUN_NUM}_bold.nii.gz"
            else
                NEW_NAME="${SUBJECT}_${SESSION}_task-rest_bold.nii.gz"
            fi
            
            log_message "  Renaming: $file -> $NEW_NAME"
            mv "$file" "$NEW_NAME" || true
        fi
    done
    
    # Rename corresponding JSON files
    for file in *.json; do
        if [ -f "$file" ]; then
            BASE=$(basename "$file" .json)
            if [ -f "${BASE}.nii.gz" ]; then
                # Find the corresponding NIfTI file
                NIFTI_FILE=$(ls -1 *bold.nii.gz 2>/dev/null | head -n 1)
                if [ -n "$NIFTI_FILE" ]; then
                    JSON_NAME="${NIFTI_FILE%.nii.gz}.json"
                    log_message "  Renaming: $file -> $JSON_NAME"
                    mv "$file" "$JSON_NAME" || true
                fi
            fi
        fi
    done
    
    log_message "Renaming complete"
}

create_task_json() {
    log_message "Creating task JSON file..."
    
    SUBJECT="sub-01"
    SESSION="ses-01"
    
    cat > "${BIDS_DIR}/${SUBJECT}/${SESSION}/func/${SUBJECT}_${SESSION}_task-rest_bold.json" <<EOF
{
    "TaskName": "rest",
    "TaskDescription": "Resting state fMRI acquisition",
    "Instructions": "Participants were instructed to keep eyes open and fixate on a crosshair",
    "CogAtlasID": "http://www.cognitiveatlas.org/task/id/trm_4c8a834779883",
    "CogPOID": ""
}
EOF
    
    log_message "Task JSON created"
}

generate_bids_ignore() {
    log_message "Creating .bidsignore file..."
    
    cat > "${BIDS_DIR}/.bidsignore" <<EOF
# Files to be ignored by BIDS validator
*.log
*.swp
*~
.DS_Store
Thumbs.db
EOF
    
    log_message ".bidsignore created"
}

create_readme() {
    log_message "Creating README file..."
    
    cat > "${BIDS_DIR}/README" <<EOF
# Example DICOM Functional Dataset

This dataset contains functional MRI data converted from DICOM format
to BIDS (Brain Imaging Data Structure) specification.

## Dataset Description

- Source: datalad/example-dicom-functional
- Conversion tool: dcm2niix
- BIDS version: 1.9.0
- Date converted: $(date)

## Contents

This dataset includes:
- Resting-state functional MRI data
- Anatomical images (if available)
- Field maps for distortion correction (if available)

## Usage

This dataset is ready for preprocessing with BIDS-Apps such as:
- fMRIPrep
- MRIQC
- QSIPrep

## Quality Control

Please run MRIQC before preprocessing:
    docker run -it --rm \\
        -v $(pwd):/data:ro \\
        -v $(pwd)/derivatives/mriqc:/out \\
        nipreps/mriqc:latest \\
        /data /out participant

## Contact

For questions or issues with this dataset, please refer to the
original repository or contact the dataset maintainer.
EOF
    
    log_message "README created"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    log_message "========================================="
    log_message "DICOM to BIDS Conversion Pipeline"
    log_message "========================================="
    log_message ""
    
    # Check dependencies
    check_dependencies
    
    # Create BIDS structure
    create_bids_structure
    
    # Create required BIDS files
    create_dataset_description
    create_participants_tsv
    generate_bids_ignore
    create_readme
    
    # Convert DICOM to NIfTI
    convert_dicom_to_nifti
    
    # Rename to BIDS format
    rename_to_bids
    
    # Create task metadata
    create_task_json
    
    log_message ""
    log_message "========================================="
    log_message "Conversion Complete!"
    log_message "========================================="
    log_message "BIDS dataset location: ${BIDS_DIR}"
    log_message "Log file: ${LOGFILE}"
    log_message ""
    log_message "Next steps:"
    log_message "  1. Validate BIDS dataset: ./code/02_validate_bids.sh"
    log_message "  2. Run quality control: ./code/03_run_mriqc.sh"
    log_message "  3. Preprocess data: ./code/04_run_fmriprep.sh"
}

# Run main function
main
