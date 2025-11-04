# Pipeline Manifest
## Complete List of Tools, Scripts, and Resources

Last Updated: November 2025

## 📋 Core Scripts

### Data Preparation
- **00_setup_data.sh**: Extract and organize DICOM data from zip file
- **01_dicom2bids.sh**: Convert DICOM to BIDS format using dcm2niix
- **02_validate_bids.sh**: Validate BIDS dataset structure

### Quality Control
- **03_run_mriqc.sh**: Run MRIQC for quality assessment
- **qc_summary.py**: Generate QC reports and exclusion recommendations

### Preprocessing
- **04_run_fmriprep.sh**: Functional MRI preprocessing pipeline
- **05_run_freesurfer.sh**: Cortical reconstruction and segmentation
- **06_run_qsiprep.sh**: Diffusion MRI preprocessing

### HPC/SLURM Scripts
- **slurm/slurm_mriqc.sh**: MRIQC on HPC cluster
- **slurm/slurm_fmriprep.sh**: fMRIPrep on HPC cluster
- **slurm/submit_pipeline.sh**: Submit complete pipeline with dependencies

## 🔧 Configuration Files

- **config.sh**: Central configuration for all parameters
- **code/license.txt**: FreeSurfer license (user must provide)
- **.bidsignore**: Files to ignore during BIDS validation

## 📁 Directory Structure

```
neuroimaging_pipeline/
├── raw_dicom/           # Input DICOM files
├── bids_data/           # BIDS-formatted dataset
│   ├── dataset_description.json
│   ├── participants.tsv
│   ├── participants.json
│   ├── README
│   └── sub-*/          # Subject directories
├── derivatives/         # Preprocessing outputs
│   ├── fmriprep/       # fMRIPrep outputs
│   ├── freesurfer/     # FreeSurfer outputs
│   ├── mriqc/          # MRIQC outputs
│   └── qsiprep/        # QSIPrep outputs
├── work/               # Temporary working directories
│   ├── fmriprep/
│   ├── mriqc/
│   └── qsiprep/
├── logs/               # All processing logs
├── qc_reports/         # Quality control summaries
│   ├── bold_qc_summary.csv
│   ├── t1w_qc_summary.csv
│   └── suggested_exclusions.csv
├── code/               # Scripts directory
│   ├── slurm/         # HPC batch scripts
│   ├── *.sh           # Bash scripts
│   └── *.py           # Python scripts
└── containers/         # Singularity images (for HPC)
```

## 🛠️ Software Tools

### Required
- **dcm2niix**: DICOM to NIfTI conversion
- **Docker** or **Singularity**: Container runtime
- **Python 3.8+**: For analysis scripts

### Optional
- **bids-validator**: Dataset validation (npm package)
- **FSL**: Additional neuroimaging tools
- **AFNI**: Alternative preprocessing tools

### Containerized Tools (via Docker/Singularity)
- **fMRIPrep 23.2.0**: Functional preprocessing
- **MRIQC 23.1.0**: Quality control
- **QSIPrep 0.19.0**: Diffusion preprocessing
- **FreeSurfer 7.4.1**: Cortical reconstruction

## 📊 Output Files Guide

### BIDS Dataset (bids_data/)
```
sub-01/
├── ses-01/
│   ├── anat/
│   │   ├── sub-01_ses-01_T1w.nii.gz
│   │   └── sub-01_ses-01_T1w.json
│   └── func/
│       ├── sub-01_ses-01_task-rest_bold.nii.gz
│       ├── sub-01_ses-01_task-rest_bold.json
│       └── sub-01_ses-01_task-rest_events.tsv (if applicable)
```

### fMRIPrep Outputs (derivatives/fmriprep/)
```
sub-01/
├── ses-01/
│   ├── anat/
│   │   ├── *_desc-preproc_T1w.nii.gz          # Preprocessed T1w
│   │   ├── *_desc-brain_mask.nii.gz           # Brain mask
│   │   ├── *_dseg.nii.gz                       # Segmentation
│   │   └── *_space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz
│   └── func/
│       ├── *_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
│       ├── *_desc-confounds_timeseries.tsv     # Confound regressors
│       ├── *_desc-brain_mask.nii.gz
│       └── *_space-MNI152NLin2009cAsym_boldref.nii.gz
├── sub-01.html                                  # Visual QC report
└── logs/                                        # Processing logs
```

### MRIQC Outputs (derivatives/mriqc/)
```
sub-01/
├── ses-01/
│   ├── anat/
│   │   └── sub-01_ses-01_T1w.json              # T1w IQMs
│   └── func/
│       └── sub-01_ses-01_task-rest_bold.json   # BOLD IQMs
├── sub-01_ses-01_task-rest_bold.html           # Individual report
└── group_bold.html                              # Group report
```

### FreeSurfer Outputs (derivatives/freesurfer/)
```
sub-01/
├── mri/
│   ├── T1.mgz                                   # Original T1
│   ├── brain.mgz                                # Skull-stripped
│   ├── aseg.mgz                                 # Subcortical segmentation
│   └── aparc+aseg.mgz                           # Cortical parcellation
├── surf/
│   ├── lh.pial                                  # Left hemisphere pial surface
│   ├── rh.pial                                  # Right hemisphere pial surface
│   ├── lh.white                                 # Left white matter surface
│   └── rh.white                                 # Right white matter surface
├── label/
│   ├── lh.aparc.annot                           # Left hemisphere labels
│   └── rh.aparc.annot                           # Right hemisphere labels
└── stats/
    ├── aseg.stats                               # Subcortical volumes
    ├── lh.aparc.stats                           # Left hemisphere stats
    └── rh.aparc.stats                           # Right hemisphere stats
```

## 🎯 Workflow Steps

1. **Data Setup**: Extract and organize DICOM files
2. **DICOM → BIDS**: Convert to BIDS format
3. **Validation**: Verify BIDS compliance
4. **Quality Control**: Run MRIQC
5. **QC Analysis**: Review metrics and flag issues
6. **Preprocessing**: Run fMRIPrep
7. **Surface Analysis**: (Optional) Run FreeSurfer
8. **Diffusion**: (Optional) Run QSIPrep
9. **Review**: Check all QC reports
10. **Analysis**: Proceed with statistical analysis

## 📈 Quality Metrics

### BOLD fMRI Metrics (MRIQC)
- **fd_mean**: Mean framewise displacement (motion)
- **tsnr**: Temporal signal-to-noise ratio
- **snr**: Signal-to-noise ratio
- **gcor**: Global correlation
- **dvars**: Temporal derivative of variance
- **aor**: Artifact-to-outlier ratio

### T1w Metrics (MRIQC)
- **snr**: Signal-to-noise ratio
- **cnr**: Contrast-to-noise ratio
- **fber**: Foreground-background energy ratio
- **efc**: Entropy focus criterion
- **qi_1/qi_2**: Quality indices
- **cjv**: Coefficient of joint variation

### Quality Thresholds
- **Motion (FD)**: < 0.5 mm (good), > 0.9 mm (exclude)
- **tSNR**: > 40 (acceptable), > 50 (good)
- **T1w SNR**: > 8 (acceptable), > 10 (good)

## 🔄 Processing Times

Estimated times per subject (varies by data size and hardware):

| Tool | Time | CPU | Memory |
|------|------|-----|--------|
| DICOM → BIDS | 5-15 min | 1 | 2 GB |
| MRIQC | 1-2 hours | 4 | 16 GB |
| fMRIPrep (no FreeSurfer) | 2-4 hours | 8 | 32 GB |
| fMRIPrep (with FreeSurfer) | 8-12 hours | 8 | 32 GB |
| FreeSurfer alone | 6-8 hours | 4 | 16 GB |
| QSIPrep | 3-6 hours | 8 | 32 GB |

## 💾 Disk Space Requirements

Per subject (approximate):

- **Raw DICOM**: 500 MB - 2 GB
- **BIDS NIfTI**: 200 MB - 1 GB
- **fMRIPrep derivatives**: 2-4 GB
- **fMRIPrep working directory**: 10-20 GB (can be deleted)
- **FreeSurfer**: 1-2 GB
- **MRIQC**: 100-500 MB

**Total recommended**: 50 GB per subject including work directories

## 🚀 Performance Tips

1. **Use SSDs** for work directories
2. **Parallel processing** with job arrays on HPC
3. **Clean work dirs** after successful runs
4. **Skip FreeSurfer** if only volumetric analysis needed
5. **Use --low-mem** flags when memory-constrained

## 📚 Citation Information

If you use this pipeline, please cite:

**BIDS:**
Gorgolewski et al. (2016). Scientific Data. doi:10.1038/sdata.2016.44

**dcm2niix:**
Li et al. (2016). Journal of Open Source Software. doi:10.21105/joss.00102

**fMRIPrep:**
Esteban et al. (2019). Nature Methods. doi:10.1038/s41592-018-0235-4

**MRIQC:**
Esteban et al. (2017). PLoS ONE. doi:10.1371/journal.pone.0184661

**FreeSurfer:**
Fischl (2012). NeuroImage. doi:10.1016/j.neuroimage.2012.01.021

**QSIPrep:**
Cieslak et al. (2021). Nature Methods. doi:10.1038/s41592-021-01185-5

## 🆘 Support Resources

- **BIDS Starter Kit**: https://bids-standard.github.io/bids-starter-kit/
- **fMRIPrep Documentation**: https://fmriprep.org/
- **Neurostars Forum**: https://neurostars.org/
- **GitHub Issues**: Report bugs and request features
- **Slack/Discord**: Join neuroimaging communities

## ✅ Validation Checklist

Before starting preprocessing:
- [ ] BIDS dataset validates without errors
- [ ] All required metadata files present
- [ ] FreeSurfer license installed
- [ ] Container images downloaded
- [ ] Sufficient disk space available
- [ ] MRIQC completed and reviewed
- [ ] No critical QC issues identified

After preprocessing:
- [ ] HTML reports reviewed for all subjects
- [ ] Motion parameters checked
- [ ] Confound files generated
- [ ] Registration quality verified
- [ ] Outputs in expected locations
- [ ] Derivatives properly organized

## 📝 Version History

**v1.0.0** (November 2025)
- Initial release
- DICOM to BIDS conversion
- fMRIPrep, MRIQC, FreeSurfer, QSIPrep support
- HPC/SLURM batch processing
- QC reporting and summary generation

---

For detailed usage instructions, see QUICKSTART.md
For complete documentation, see README.md
