# Neuroimaging Preprocessing Pipeline
## Complete DICOM → BIDS → Preprocessing Workflow

This repository contains a reproducible neuroimaging preprocessing pipeline covering DICOM conversion, quality control, and multiple preprocessing tools.

## 📁 Directory Structure

```
neuroimaging_pipeline/
├── raw_dicom/          # Place your DICOM data here
├── bids_data/          # BIDS-formatted dataset output
├── derivatives/        # Preprocessing outputs
│   ├── fmriprep/
│   ├── freesurfer/
│   ├── qsiprep/
│   └── mriqc/
├── code/               # All processing scripts
├── logs/               # Processing logs
├── qc_reports/         # Quality control reports
└── README.md           # This file
```

## 🚀 Quick Start

### 1. Setup Your Data

Extract your downloaded `example-dicom-functional` zip file:
```bash
# Place your zip file in raw_dicom directory
unzip example-dicom-functional-master.zip -d raw_dicom/
```

### 2. Convert DICOM to BIDS

```bash
# Run the conversion script
./code/01_dicom2bids.sh
```

### 3. Validate BIDS Dataset

```bash
./code/02_validate_bids.sh
```

### 4. Run Preprocessing

Choose your preprocessing pipeline:

```bash
# MRIQC - Quality Control (run this first!)
./code/03_run_mriqc.sh

# fMRIPrep - Functional preprocessing
./code/04_run_fmriprep.sh

# FreeSurfer - Structural preprocessing
./code/05_run_freesurfer.sh

# QSIPrep - Diffusion preprocessing
./code/06_run_qsiprep.sh
```

## 🖥️ HPC/SLURM Usage

All scripts have SLURM counterparts in `code/slurm/`:

```bash
# Submit individual jobs
sbatch code/slurm/slurm_fmriprep.sh

# Submit entire pipeline
./code/slurm/submit_pipeline.sh
```

## 📊 Tools Covered

1. **dcm2niix** - DICOM to NIfTI conversion
2. **BIDS Validator** - Dataset validation
3. **MRIQC** - Quality control metrics and reports
4. **fMRIPrep** - Functional MRI preprocessing
5. **FreeSurfer** - Cortical reconstruction
6. **QSIPrep** - Diffusion MRI preprocessing
7. **FSL** - Additional analyses

## 📋 Prerequisites

### Required Software

```bash
# Install dcm2niix
sudo apt-get install dcm2niix

# Install BIDS validator
npm install -g bids-validator

# Docker/Singularity for containerized tools
# fMRIPrep, MRIQC, QSIPrep are best run via containers
```

### Python Dependencies

```bash
pip install pydicom nibabel pandas numpy
```

## 🔬 Preprocessing Details

### MRIQC
- Extracts IQMs (Image Quality Metrics)
- Generates group-level reports
- No-reference metrics for quality assessment

### fMRIPrep
- Anatomical processing (brain extraction, segmentation)
- Functional processing (motion correction, slice-timing, distortion correction)
- Surface-based and volume-based outputs
- Confound regression matrices

### FreeSurfer
- Cortical surface reconstruction
- Subcortical segmentation
- Thickness and volume measurements

### QSIPrep
- Diffusion preprocessing
- Distortion correction
- Head motion correction
- Eddy current correction

## 📈 Quality Control

After running MRIQC:
```bash
# View QC reports
firefox qc_reports/mriqc/sub-*_bold.html

# Generate summary statistics
python code/qc_summary.py
```

## 🔄 Reproducibility

All scripts include:
- Version pinning for software
- Complete parameter documentation
- Provenance tracking
- BIDS derivatives structure

### Container Versions
```
fmriprep: 23.2.0
mriqc: 23.1.0
qsiprep: 0.19.0
freesurfer: 7.4.1
```

## 📝 Citation

If using these tools, please cite:

**fMRIPrep:**
Esteban et al. (2019). Nature Methods. doi:10.1038/s41592-018-0235-4

**MRIQC:**
Esteban et al. (2017). PLoS ONE. doi:10.1371/journal.pone.0184661

**FreeSurfer:**
Fischl (2012). NeuroImage. doi:10.1016/j.neuroimage.2012.01.021

**QSIPrep:**
Cieslak et al. (2021). Nature Methods. doi:10.1038/s41592-021-01185-5

## 🆘 Troubleshooting

### Common Issues

1. **dcm2niix not found**: Install via package manager or compile from source
2. **BIDS validation errors**: Check participant/session naming
3. **Out of memory**: Adjust `--mem_mb` in scripts or use HPC
4. **Missing fieldmaps**: Some corrections will be skipped

### Support

- Check logs in `logs/` directory
- Review QC reports for data quality issues
- Consult tool-specific documentation

## 📚 Additional Resources

- [BIDS Specification](https://bids-specification.readthedocs.io/)
- [fMRIPrep Docs](https://fmriprep.org/)
- [MRIQC Docs](https://mriqc.readthedocs.io/)
- [Nipreps Community](https://neurostars.org/)

## 🤝 Contributing

Feel free to submit issues or improvements to this pipeline!

---

**Version:** 1.0.0  
**Last Updated:** November 2025  
**License:** MIT
