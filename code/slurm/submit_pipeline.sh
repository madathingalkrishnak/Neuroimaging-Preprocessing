#!/bin/bash
# Master Pipeline Submission Script for SLURM
# Submits all preprocessing steps with proper dependencies
#
# Usage: ./submit_pipeline.sh
#
# Author: Neuroimaging Pipeline
# Date: November 2025

set -e
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINE_DIR="$(dirname "${SCRIPT_DIR}")"

echo "========================================="
echo "Neuroimaging Pipeline - SLURM Submission"
echo "========================================="
echo "Pipeline directory: ${PIPELINE_DIR}"
echo ""

# Check if in HPC environment
if ! command -v sbatch &> /dev/null; then
    echo "ERROR: sbatch not found. Are you on an HPC with SLURM?"
    exit 1
fi

echo "Step 1: Submitting MRIQC jobs..."
MRIQC_JOB_ID=$(sbatch --parsable "${SCRIPT_DIR}/slurm_mriqc.sh")
echo "  Submitted MRIQC: Job ID ${MRIQC_JOB_ID}"

echo ""
echo "Step 2: Submitting MRIQC group analysis..."
# Group analysis runs after all participant jobs complete
GROUP_JOB_ID=$(sbatch --parsable \
    --dependency=afterok:${MRIQC_JOB_ID} \
    --job-name=mriqc_group \
    --time=2:00:00 \
    --cpus-per-task=2 \
    --mem=8G \
    --wrap="singularity run --cleanenv \
        -B ${PIPELINE_DIR}/bids_data:/data:ro \
        -B ${PIPELINE_DIR}/derivatives/mriqc:/out \
        -B ${PIPELINE_DIR}/work/mriqc:/work \
        ${PIPELINE_DIR}/containers/mriqc_23.1.0.sif \
        /data /out group \
        --n_procs 2 \
        --mem_gb 8")
echo "  Submitted MRIQC group: Job ID ${GROUP_JOB_ID}"

echo ""
echo "Step 3: Submitting fMRIPrep jobs..."
# fMRIPrep starts after MRIQC group completes
FMRIPREP_JOB_ID=$(sbatch --parsable \
    --dependency=afterok:${GROUP_JOB_ID} \
    "${SCRIPT_DIR}/slurm_fmriprep.sh")
echo "  Submitted fMRIPrep: Job ID ${FMRIPREP_JOB_ID}"

echo ""
echo "Step 4: Submitting QC summary generation..."
# Generate QC summary after all jobs complete
QC_SUMMARY_JOB=$(sbatch --parsable \
    --dependency=afterok:${FMRIPREP_JOB_ID} \
    --job-name=qc_summary \
    --time=1:00:00 \
    --cpus-per-task=1 \
    --mem=4G \
    --wrap="python ${PIPELINE_DIR}/code/qc_summary.py")
echo "  Submitted QC summary: Job ID ${QC_SUMMARY_JOB}"

echo ""
echo "========================================="
echo "Pipeline Submitted Successfully!"
echo "========================================="
echo ""
echo "Job Chain:"
echo "  1. MRIQC participant: ${MRIQC_JOB_ID}"
echo "  2. MRIQC group: ${GROUP_JOB_ID}"
echo "  3. fMRIPrep: ${FMRIPREP_JOB_ID}"
echo "  4. QC summary: ${QC_SUMMARY_JOB}"
echo ""
echo "Monitor jobs:"
echo "  squeue -u \$USER"
echo "  sacct -j ${MRIQC_JOB_ID}"
echo ""
echo "Check logs:"
echo "  tail -f logs/mriqc_${MRIQC_JOB_ID}_*.out"
echo "  tail -f logs/fmriprep_${FMRIPREP_JOB_ID}_*.out"
echo ""
echo "Cancel jobs:"
echo "  scancel ${MRIQC_JOB_ID} ${GROUP_JOB_ID} ${FMRIPREP_JOB_ID} ${QC_SUMMARY_JOB}"
