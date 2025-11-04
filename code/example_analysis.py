#!/usr/bin/env python3
"""
Example Post-Preprocessing Analysis
Demonstrates basic analysis steps after fMRIPrep

This script shows how to:
1. Load preprocessed fMRI data
2. Apply confound regression
3. Extract time series
4. Calculate connectivity matrices

Usage:
    python example_analysis.py

Author: Neuroimaging Pipeline
Date: November 2025
"""

import os
import numpy as np
import pandas as pd
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# Try to import neuroimaging libraries
try:
    import nibabel as nib
    from nilearn import image, masking, signal
    from nilearn.connectome import ConnectivityMeasure
    from nilearn.input_data import NiftiLabelsMasker
    print("✓ All required packages available")
except ImportError as e:
    print(f"⚠️  Missing package: {e}")
    print("\nInstall required packages with:")
    print("  pip install nibabel nilearn")
    print("\nThis is just an example script showing post-processing steps.")
    exit(0)


class PostPreprocessingAnalysis:
    """Example analysis pipeline for fMRIPrep outputs"""
    
    def __init__(self, fmriprep_dir, subject_id, session_id='ses-01'):
        self.fmriprep_dir = Path(fmriprep_dir)
        self.subject_id = subject_id
        self.session_id = session_id
        
        # Paths
        self.subject_dir = self.fmriprep_dir / subject_id / session_id / 'func'
        
        # Find preprocessed BOLD file
        bold_files = list(self.subject_dir.glob('*_space-MNI*_desc-preproc_bold.nii.gz'))
        if not bold_files:
            raise FileNotFoundError(f"No preprocessed BOLD files found in {self.subject_dir}")
        
        self.bold_file = bold_files[0]
        
        # Find confounds file
        confounds_files = list(self.subject_dir.glob('*_desc-confounds_timeseries.tsv'))
        if not confounds_files:
            raise FileNotFoundError(f"No confounds file found in {self.subject_dir}")
        
        self.confounds_file = confounds_files[0]
        
        # Find brain mask
        mask_files = list(self.subject_dir.glob('*_space-MNI*_desc-brain_mask.nii.gz'))
        self.mask_file = mask_files[0] if mask_files else None
        
        print(f"Initialized analysis for {subject_id}")
        print(f"  BOLD: {self.bold_file.name}")
        print(f"  Confounds: {self.confounds_file.name}")
        print(f"  Mask: {self.mask_file.name if self.mask_file else 'None'}")
    
    def load_data(self):
        """Load preprocessed fMRI data"""
        print("\nLoading fMRI data...")
        self.bold_img = nib.load(self.bold_file)
        print(f"  Shape: {self.bold_img.shape}")
        print(f"  TR: {self.bold_img.header.get_zooms()[3]:.2f}s")
        return self.bold_img
    
    def load_confounds(self, confound_names=None):
        """Load and select confound regressors"""
        print("\nLoading confounds...")
        confounds_df = pd.read_csv(self.confounds_file, sep='\t')
        
        if confound_names is None:
            # Default confounds for nuisance regression
            confound_names = [
                'trans_x', 'trans_y', 'trans_z',
                'rot_x', 'rot_y', 'rot_z',
                'framewise_displacement',
                'csf', 'white_matter',
                'global_signal'
            ]
        
        # Select available confounds
        available_confounds = [c for c in confound_names if c in confounds_df.columns]
        
        if not available_confounds:
            print("  ⚠️  No standard confounds found")
            return None
        
        confounds = confounds_df[available_confounds]
        
        # Handle NaN values (first row for FD)
        confounds = confounds.fillna(0)
        
        print(f"  Selected {len(available_confounds)} confounds:")
        for conf in available_confounds:
            print(f"    - {conf}")
        
        return confounds.values
    
    def apply_confound_regression(self, confounds):
        """Remove confounds from fMRI data"""
        print("\nApplying confound regression...")
        
        # Extract time series from masked data
        if self.mask_file:
            mask_img = nib.load(self.mask_file)
        else:
            print("  Creating mask from data...")
            mask_img = masking.compute_epi_mask(self.bold_img)
        
        # Clean the signal
        cleaned_img = image.clean_img(
            self.bold_img,
            confounds=confounds,
            standardize=True,
            detrend=True,
            low_pass=0.1,  # Low-pass filter at 0.1 Hz
            high_pass=0.01,  # High-pass filter at 0.01 Hz
            t_r=self.bold_img.header.get_zooms()[3],
            mask_img=mask_img
        )
        
        print("  ✓ Signal cleaned")
        return cleaned_img
    
    def extract_roi_timeseries(self, cleaned_img, atlas='aal'):
        """Extract time series from ROIs using atlas"""
        print(f"\nExtracting ROI time series using {atlas.upper()} atlas...")
        
        try:
            from nilearn import datasets
            
            # Load atlas
            if atlas == 'aal':
                atlas_data = datasets.fetch_atlas_aal()
                atlas_img = atlas_data.maps
                labels = atlas_data.labels
            elif atlas == 'harvard_oxford':
                atlas_data = datasets.fetch_atlas_harvard_oxford('cort-maxprob-thr25-2mm')
                atlas_img = atlas_data.maps
                labels = atlas_data.labels
            else:
                print(f"  ⚠️  Atlas {atlas} not implemented")
                return None, None
            
            # Create masker
            masker = NiftiLabelsMasker(
                labels_img=atlas_img,
                standardize=True,
                memory='nilearn_cache',
                verbose=0
            )
            
            # Extract time series
            timeseries = masker.fit_transform(cleaned_img)
            
            print(f"  ✓ Extracted {timeseries.shape[1]} ROIs")
            print(f"  ✓ Timeseries shape: {timeseries.shape}")
            
            return timeseries, labels
            
        except Exception as e:
            print(f"  ⚠️  Error extracting ROI timeseries: {e}")
            return None, None
    
    def compute_connectivity(self, timeseries, kind='correlation'):
        """Compute functional connectivity matrix"""
        print(f"\nComputing {kind} connectivity...")
        
        connectivity_measure = ConnectivityMeasure(kind=kind)
        connectivity_matrix = connectivity_measure.fit_transform([timeseries])[0]
        
        print(f"  ✓ Connectivity matrix shape: {connectivity_matrix.shape}")
        print(f"  ✓ Mean connectivity: {np.mean(connectivity_matrix):.3f}")
        
        return connectivity_matrix
    
    def save_results(self, timeseries, connectivity_matrix, labels, output_dir='analysis_outputs'):
        """Save analysis results"""
        print(f"\nSaving results to {output_dir}/...")
        
        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)
        
        # Save time series
        timeseries_file = output_path / f'{self.subject_id}_timeseries.npy'
        np.save(timeseries_file, timeseries)
        print(f"  ✓ Time series: {timeseries_file}")
        
        # Save connectivity matrix
        connectivity_file = output_path / f'{self.subject_id}_connectivity.npy'
        np.save(connectivity_file, connectivity_matrix)
        print(f"  ✓ Connectivity: {connectivity_file}")
        
        # Save ROI labels
        labels_file = output_path / f'{self.subject_id}_labels.txt'
        with open(labels_file, 'w') as f:
            for i, label in enumerate(labels):
                f.write(f"{i}\t{label}\n")
        print(f"  ✓ Labels: {labels_file}")
        
        # Save connectivity as CSV for easy viewing
        connectivity_csv = output_path / f'{self.subject_id}_connectivity.csv'
        pd.DataFrame(
            connectivity_matrix,
            columns=labels,
            index=labels
        ).to_csv(connectivity_csv)
        print(f"  ✓ Connectivity CSV: {connectivity_csv}")
        
        return output_path
    
    def run_complete_analysis(self):
        """Run the complete analysis pipeline"""
        print("="*60)
        print("Post-Preprocessing Analysis Pipeline")
        print("="*60)
        
        # 1. Load data
        self.load_data()
        
        # 2. Load confounds
        confounds = self.load_confounds()
        
        # 3. Apply confound regression
        cleaned_img = self.apply_confound_regression(confounds)
        
        # 4. Extract ROI time series
        timeseries, labels = self.extract_roi_timeseries(cleaned_img, atlas='aal')
        
        if timeseries is not None:
            # 5. Compute connectivity
            connectivity_matrix = self.compute_connectivity(timeseries)
            
            # 6. Save results
            output_path = self.save_results(timeseries, connectivity_matrix, labels)
            
            print("\n" + "="*60)
            print("Analysis Complete!")
            print("="*60)
            print(f"\nResults saved to: {output_path}")
            print("\nNext steps:")
            print("  1. Visualize connectivity matrix")
            print("  2. Perform group-level statistics")
            print("  3. Compare with behavioral data")
            
            return output_path
        else:
            print("\n⚠️  Analysis incomplete - could not extract time series")
            return None


def main():
    """Main function"""
    
    # Example usage
    fmriprep_dir = 'derivatives/fmriprep'
    subject_id = 'sub-01'
    session_id = 'ses-01'
    
    print("="*60)
    print("Example Post-Preprocessing Analysis")
    print("="*60)
    print("\nThis script demonstrates basic analysis steps:")
    print("  1. Load preprocessed fMRI data from fMRIPrep")
    print("  2. Apply confound regression")
    print("  3. Extract ROI time series")
    print("  4. Compute functional connectivity")
    print("  5. Save results")
    print("\n" + "="*60)
    
    # Check if fMRIPrep directory exists
    if not Path(fmriprep_dir).exists():
        print(f"\n⚠️  fMRIPrep directory not found: {fmriprep_dir}")
        print("\nThis is an example script. To use it:")
        print("  1. Run fMRIPrep first: ./code/04_run_fmriprep.sh")
        print("  2. Modify paths in this script if needed")
        print("  3. Run: python code/example_analysis.py")
        return
    
    try:
        # Initialize analysis
        analysis = PostPreprocessingAnalysis(
            fmriprep_dir=fmriprep_dir,
            subject_id=subject_id,
            session_id=session_id
        )
        
        # Run complete analysis
        analysis.run_complete_analysis()
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        print("\nPlease ensure:")
        print("  1. fMRIPrep has been run successfully")
        print("  2. Subject ID and session ID are correct")
        print("  3. Required packages are installed: nibabel, nilearn")


if __name__ == '__main__':
    main()
