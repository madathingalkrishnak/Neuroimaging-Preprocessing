# Quick Start Guide
## Neuroimaging Preprocessing Pipeline

This guide will walk you through converting DICOM data to BIDS format and running a complete preprocessing pipeline.

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Docker or Singularity installed
- [ ] dcm2niix installed (for DICOM conversion)
- [ ] At least 50GB free disk space
- [ ] Your DICOM data ready
- [ ] FreeSurfer license (get from: https://surfer.nmr.mgh.harvard.edu/registration.html)

## Step-by-Step Instructions

### 1. Setup Your Environment

```bash
cd neuroimaging_pipeline

# If you have the example-dicom-functional zip file:
./code/00_setup_data.sh /path/to/example-dicom-functional-master.zip

# OR if you have your own DICOM data:
cp -r /path/to/your/dicoms raw_dicom/
```

### 2. Add FreeSurfer License

```bash
# Edit code/license.txt and add your FreeSurfer license
# Get license from: https://surfer.nmr.mgh.harvard.edu/registration.html
nano code/license.txt
```

### 3. Convert DICOM to BIDS

```bash
# Run the conversion script
./code/01_dicom2bids.sh

# This will:
# - Convert DICOM files to NIfTI format
# - Organize files according to BIDS specification
# - Create necessary metadata files
# - Generate dataset_description.json

# Expected output:
# bids_data/
#   ├── dataset_description.json
#   ├── participants.tsv
#   ├── README
#   └── sub-01/
#       └── ses-01/
#           └── func/
#               ├── sub-01_ses-01_task-rest_bold.nii.gz
#               └── sub-01_ses-01_task-rest_bold.json
```

### 4. Validate BIDS Dataset

```bash
# Check if your BIDS dataset is valid
./code/02_validate_bids.sh

# This uses bids-validator to check:
# - Correct file naming
# - Required metadata files
# - Proper directory structure

# If validation fails, check the log file for specific errors
```

### 5. Quality Control with MRIQC

```bash
# Run participant-level QC
./code/03_run_mriqc.sh participant

# Wait for completion, then run group-level QC
./code/03_run_mriqc.sh group

# This generates:
# - Individual HTML reports per subject
# - Group statistics and visualizations
# - IQMs (Image Quality Metrics) in JSON format

# View reports:
firefox derivatives/mriqc/sub-*.html
```

### 6. Generate QC Summary

```bash
# Analyze MRIQC outputs and create summary
python code/qc_summary.py

# This creates:
# - qc_reports/bold_qc_summary.csv
# - qc_reports/t1w_qc_summary.csv
# - qc_reports/suggested_exclusions.csv

# Review the suggested exclusions before preprocessing
```

### 7. Preprocess with fMRIPrep

```bash
# Run fMRIPrep on all subjects
./code/04_run_fmriprep.sh

# OR process a specific subject:
./code/04_run_fmriprep.sh 01

# This takes 2-8 hours per subject and produces:
# - Preprocessed BOLD data
# - Anatomical derivatives
# - Confound regressors
# - HTML visual reports

# Expected outputs:
# derivatives/fmriprep/
#   ├── sub-01/
#   │   └── ses-01/
#   │       └── func/
#   │           ├── *_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
#   │           ├── *_desc-confounds_timeseries.tsv
#   │           └── *_desc-brain_mask.nii.gz
#   └── sub-01.html
```

### 8. Optional: FreeSurfer Reconstruction

```bash
# For surface-based analysis (takes 6-8 hours per subject)
./code/05_run_freesurfer.sh

# OR for specific subject:
./code/05_run_freesurfer.sh 01

# Outputs:
# derivatives/freesurfer/
#   └── sub-01/
#       ├── surf/  # Cortical surfaces
#       ├── mri/   # Volumetric data
#       └── stats/ # Morphometric statistics
```

### 9. Optional: Diffusion Processing with QSIPrep

```bash
# Only if you have diffusion data
./code/06_run_qsiprep.sh

# Outputs:
# derivatives/qsiprep/
#   └── sub-01/
#       └── ses-01/
#           └── dwi/
#               ├── *_space-T1w_desc-preproc_dwi.nii.gz
#               └── *_desc-confounds_timeseries.tsv
```

## HPC/SLURM Usage

For processing on an HPC cluster:

### 1. Update Paths in SLURM Scripts

```bash
# Edit each SLURM script and update PIPELINE_DIR
nano code/slurm/slurm_fmriprep.sh
nano code/slurm/slurm_mriqc.sh

# Change this line:
# PIPELINE_DIR="/path/to/neuroimaging_pipeline"
# to your actual path
```

### 2. Submit Individual Jobs

```bash
# Submit MRIQC
sbatch code/slurm/slurm_mriqc.sh

# Submit fMRIPrep
sbatch code/slurm/slurm_fmriprep.sh

# Check job status
squeue -u $USER

# View logs
tail -f logs/fmriprep_*.out
```

### 3. Submit Complete Pipeline

```bash
# This submits all jobs with proper dependencies
./code/slurm/submit_pipeline.sh

# Jobs will run in sequence:
# 1. MRIQC participant → 2. MRIQC group → 3. fMRIPrep → 4. QC summary

# Cancel all jobs if needed
scancel -u $USER
```

## Troubleshooting

### Common Issues

**1. "dcm2niix not found"**
```bash
# Install dcm2niix
sudo apt-get install dcm2niix  # Ubuntu/Debian
brew install dcm2niix          # macOS
conda install -c conda-forge dcm2niix  # Conda
```

**2. "Docker daemon not running"**
```bash
sudo systemctl start docker
sudo usermod -aG docker $USER  # Add user to docker group
# Log out and back in for group changes to take effect
```

**3. "Out of memory" errors**
```bash
# Reduce memory/CPU usage in scripts
# Edit the script and change:
--mem_mb 16000  # to a lower value
--n_cpus 4      # to fewer CPUs
```

**4. "FreeSurfer license not found"**
```bash
# Get license from:
# https://surfer.nmr.mgh.harvard.edu/registration.html
# Save to: code/license.txt
```

**5. BIDS validation errors**
```bash
# Check specific errors in log file
cat logs/bids_validation_*.log

# Common fixes:
# - Ensure files follow BIDS naming: sub-XX_ses-YY_task-ZZ_bold.nii.gz
# - Check that all JSON sidecar files exist
# - Verify dataset_description.json is present
```

## Next Steps

After preprocessing:

1. **Review QC Reports**
   - Check fMRIPrep HTML reports for each subject
   - Review MRIQC metrics for quality issues
   - Examine suggested exclusions

2. **Statistical Analysis**
   - Use preprocessed data for your analyses
   - Apply confound regression
   - Run group-level statistics

3. **Visualization**
   ```bash
   # View preprocessed data
   fsleyes derivatives/fmriprep/sub-01/ses-01/func/*_space-MNI*_desc-preproc_bold.nii.gz
   
   # View FreeSurfer surfaces
   freeview -v derivatives/freesurfer/sub-01/mri/T1.mgz \
            -f derivatives/freesurfer/sub-01/surf/lh.pial:edgecolor=red
   ```

## Tips for Success

1. **Start Small**: Process 1-2 subjects first to test the pipeline
2. **Check Logs**: Always review log files for errors
3. **Monitor Resources**: Keep an eye on CPU and memory usage
4. **Save Space**: Enable work directory cleanup after successful runs
5. **Document Everything**: Keep notes on any issues and solutions
6. **Version Control**: Track any modifications to scripts

## Getting Help

- **BIDS**: https://bids-specification.readthedocs.io/
- **fMRIPrep**: https://fmriprep.org/
- **MRIQC**: https://mriqc.readthedocs.io/
- **Neurostars Forum**: https://neurostars.org/
- **Check logs**: All scripts create detailed logs in `logs/` directory

## File Organization Summary

```
neuroimaging_pipeline/
├── raw_dicom/              # Your DICOM data
├── bids_data/              # BIDS-formatted dataset
├── derivatives/            # All preprocessing outputs
│   ├── fmriprep/          # fMRIPrep results
│   ├── freesurfer/        # FreeSurfer results
│   ├── mriqc/             # MRIQC quality reports
│   └── qsiprep/           # QSIPrep results
├── work/                   # Temporary working files
├── logs/                   # Processing logs
├── qc_reports/            # QC summaries
├── code/                   # All scripts
│   ├── slurm/             # HPC batch scripts
│   └── *.sh               # Local processing scripts
├── config.sh              # Configuration file
└── README.md              # Full documentation
```

Happy preprocessing! 🧠🔬
