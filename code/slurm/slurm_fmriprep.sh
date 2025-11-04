#!/bin/bash
#SBATCH --job-name=fmriprep
#SBATCH --output=logs/fmriprep_%A_%a.out
#SBATCH --error=logs/fmriprep_%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=general
#SBATCH --array=1-10%5
# Array processes 10 subjects, max 5 running simultaneously
# Adjust array range based on number of subjects

# ============================================================================
# fMRIPrep SLURM Batch Script
# Processes one subject per array job
# ============================================================================

set -e
set -u

# Load required modules (adjust for your HPC environment)
module purge
module load singularity/3.8.0  # or whatever version is available
# module load freesurfer/7.4.1  # if FreeSurfer is available as module

# Configuration
PIPELINE_DIR="/path/to/neuroimaging_pipeline"  # CHANGE THIS
BIDS_DIR="${PIPELINE_DIR}/bids_data"
OUTPUT_DIR="${PIPELINE_DIR}/derivatives/fmriprep"
WORK_DIR="${PIPELINE_DIR}/work/fmriprep"
FS_LICENSE="${PIPELINE_DIR}/code/license.txt"
CONTAINER_DIR="${PIPELINE_DIR}/containers"
SINGULARITY_IMAGE="${CONTAINER_DIR}/fmriprep_23.2.0.sif"

# Create directories
mkdir -p "${OUTPUT_DIR}" "${WORK_DIR}" "${PIPELINE_DIR}/logs"

# Get list of subjects
SUBJECTS=($(ls -d "${BIDS_DIR}"/sub-* | xargs -n 1 basename))
N_SUBJECTS=${#SUBJECTS[@]}

# Check if array task ID is valid
if [ ${SLURM_ARRAY_TASK_ID} -gt ${N_SUBJECTS} ]; then
    echo "Array task ID ${SLURM_ARRAY_TASK_ID} exceeds number of subjects ${N_SUBJECTS}"
    exit 0
fi

# Get subject for this array job (arrays start at 1, bash arrays at 0)
SUBJECT=${SUBJECTS[$((SLURM_ARRAY_TASK_ID - 1))]}
PARTICIPANT_LABEL=${SUBJECT#sub-}  # Remove 'sub-' prefix

echo "========================================="
echo "Job ID: ${SLURM_JOB_ID}"
echo "Array Task ID: ${SLURM_ARRAY_TASK_ID}"
echo "Processing: ${SUBJECT}"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
echo "Memory: ${SLURM_MEM_PER_NODE}MB"
echo "Node: ${SLURMD_NODENAME}"
echo "========================================="
echo ""

# Work directory for this subject
WORK_DIR_SUBJ="${WORK_DIR}/${SUBJECT}"
mkdir -p "${WORK_DIR_SUBJ}"

# Download container if not present
if [ ! -f "${SINGULARITY_IMAGE}" ]; then
    echo "Singularity image not found. Pulling image..."
    mkdir -p "${CONTAINER_DIR}"
    singularity pull "${SINGULARITY_IMAGE}" \
        docker://nipreps/fmriprep:23.2.0
fi

# Check FreeSurfer license
if [ ! -f "${FS_LICENSE}" ]; then
    echo "ERROR: FreeSurfer license not found at ${FS_LICENSE}"
    echo "Please add your FreeSurfer license file"
    exit 1
fi

# Set Singularity environment variables
export SINGULARITYENV_TEMPLATEFLOW_HOME=/templateflow
export SINGULARITY_BIND="${BIDS_DIR}:/data:ro,${OUTPUT_DIR}:/out,${WORK_DIR_SUBJ}:/work,${FS_LICENSE}:/opt/freesurfer/license.txt:ro"

# Run fMRIPrep
echo "Starting fMRIPrep for ${SUBJECT}..."
echo "Start time: $(date)"

singularity run --cleanenv \
    "${SINGULARITY_IMAGE}" \
    /data /out participant \
    --participant-label "${PARTICIPANT_LABEL}" \
    --work-dir /work \
    --output-spaces MNI152NLin2009cAsym:res-2 anat fsnative \
    --bold2t1w-dof 9 \
    --bold2t1w-init register \
    --use-syn-sdc \
    --output-layout bids \
    --n_cpus ${SLURM_CPUS_PER_TASK} \
    --mem_mb ${SLURM_MEM_PER_NODE} \
    --skip_bids_validation \
    --write-graph \
    --stop-on-first-crash \
    --fs-no-reconall

EXIT_CODE=$?

echo ""
echo "End time: $(date)"
echo "Exit code: ${EXIT_CODE}"

# Clean up work directory to save space (optional)
# Uncomment if you want to remove intermediate files after successful run
# if [ ${EXIT_CODE} -eq 0 ]; then
#     echo "Cleaning up work directory..."
#     rm -rf "${WORK_DIR_SUBJ}"
# fi

echo "========================================="
echo "Job complete for ${SUBJECT}"
echo "========================================="

exit ${EXIT_CODE}
