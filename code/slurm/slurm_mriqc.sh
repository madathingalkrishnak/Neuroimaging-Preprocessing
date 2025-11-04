#!/bin/bash
#SBATCH --job-name=mriqc
#SBATCH --output=logs/mriqc_%A_%a.out
#SBATCH --error=logs/mriqc_%A_%a.err
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=general
#SBATCH --array=1-10%5

# ============================================================================
# MRIQC SLURM Batch Script
# Runs participant-level QC for each subject
# ============================================================================

set -e
set -u

# Load modules
module purge
module load singularity/3.8.0

# Configuration
PIPELINE_DIR="/path/to/neuroimaging_pipeline"  # CHANGE THIS
BIDS_DIR="${PIPELINE_DIR}/bids_data"
OUTPUT_DIR="${PIPELINE_DIR}/derivatives/mriqc"
WORK_DIR="${PIPELINE_DIR}/work/mriqc"
CONTAINER_DIR="${PIPELINE_DIR}/containers"
SINGULARITY_IMAGE="${CONTAINER_DIR}/mriqc_23.1.0.sif"

mkdir -p "${OUTPUT_DIR}" "${WORK_DIR}" "${PIPELINE_DIR}/logs"

# Get subjects
SUBJECTS=($(ls -d "${BIDS_DIR}"/sub-* | xargs -n 1 basename))
N_SUBJECTS=${#SUBJECTS[@]}

if [ ${SLURM_ARRAY_TASK_ID} -gt ${N_SUBJECTS} ]; then
    exit 0
fi

SUBJECT=${SUBJECTS[$((SLURM_ARRAY_TASK_ID - 1))]}
PARTICIPANT_LABEL=${SUBJECT#sub-}

echo "========================================="
echo "MRIQC - ${SUBJECT}"
echo "Job ID: ${SLURM_JOB_ID}"
echo "Array Task: ${SLURM_ARRAY_TASK_ID}"
echo "========================================="

# Download container if needed
if [ ! -f "${SINGULARITY_IMAGE}" ]; then
    mkdir -p "${CONTAINER_DIR}"
    singularity pull "${SINGULARITY_IMAGE}" \
        docker://nipreps/mriqc:23.1.0
fi

# Work directory for this subject
WORK_DIR_SUBJ="${WORK_DIR}/${SUBJECT}"
mkdir -p "${WORK_DIR_SUBJ}"

# Run MRIQC
echo "Starting MRIQC..."
echo "Start time: $(date)"

singularity run --cleanenv \
    -B "${BIDS_DIR}:/data:ro" \
    -B "${OUTPUT_DIR}:/out" \
    -B "${WORK_DIR_SUBJ}:/work" \
    "${SINGULARITY_IMAGE}" \
    /data /out participant \
    --participant-label "${PARTICIPANT_LABEL}" \
    --work-dir /work \
    --n_procs ${SLURM_CPUS_PER_TASK} \
    --mem_gb 16 \
    --float32 \
    --verbose-reports \
    --write-graph

EXIT_CODE=$?

echo "End time: $(date)"
echo "Exit code: ${EXIT_CODE}"

# Optional cleanup
# if [ ${EXIT_CODE} -eq 0 ]; then
#     rm -rf "${WORK_DIR_SUBJ}"
# fi

exit ${EXIT_CODE}
