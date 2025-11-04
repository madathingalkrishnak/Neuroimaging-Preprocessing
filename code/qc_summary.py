#!/usr/bin/env python3
"""
QC Summary Generator
Analyzes MRIQC outputs and generates comprehensive quality control reports

Usage:
    python qc_summary.py [--derivatives-dir PATH]

Author: Neuroimaging Pipeline
Date: November 2025
"""

import os
import json
import pandas as pd
import numpy as np
from pathlib import Path
import argparse
import warnings
warnings.filterwarnings('ignore')


class MRIQCAnalyzer:
    """Analyzer for MRIQC quality metrics"""
    
    def __init__(self, derivatives_dir):
        self.derivatives_dir = Path(derivatives_dir)
        self.mriqc_dir = self.derivatives_dir / 'mriqc'
        self.output_dir = Path('qc_reports')
        self.output_dir.mkdir(exist_ok=True)
        
    def load_bold_metrics(self):
        """Load BOLD quality metrics"""
        bold_files = list(self.mriqc_dir.glob('sub-*/**/func/*_bold.json'))
        
        if not bold_files:
            print("WARNING: No BOLD quality metrics found")
            return None
        
        metrics_list = []
        for json_file in bold_files:
            with open(json_file, 'r') as f:
                data = json.load(f)
                # Extract key metrics
                metrics = {
                    'subject_id': data.get('bids_meta', {}).get('subject_id', 'unknown'),
                    'session_id': data.get('bids_meta', {}).get('session_id', 'unknown'),
                    'task': data.get('bids_meta', {}).get('task_id', 'unknown'),
                    'fd_mean': data.get('fd_mean', np.nan),
                    'fd_num': data.get('fd_num', np.nan),
                    'fd_perc': data.get('fd_perc', np.nan),
                    'snr': data.get('snr', np.nan),
                    'tsnr': data.get('tsnr', np.nan),
                    'gcor': data.get('gcor', np.nan),
                    'dvars_std': data.get('dvars_std', np.nan),
                    'dvars_nstd': data.get('dvars_nstd', np.nan),
                    'aor': data.get('aor', np.nan),
                    'aqi': data.get('aqi', np.nan),
                }
                metrics_list.append(metrics)
        
        return pd.DataFrame(metrics_list)
    
    def load_t1w_metrics(self):
        """Load T1w quality metrics"""
        t1w_files = list(self.mriqc_dir.glob('sub-*/**/anat/*_T1w.json'))
        
        if not t1w_files:
            print("WARNING: No T1w quality metrics found")
            return None
        
        metrics_list = []
        for json_file in t1w_files:
            with open(json_file, 'r') as f:
                data = json.load(f)
                metrics = {
                    'subject_id': data.get('bids_meta', {}).get('subject_id', 'unknown'),
                    'session_id': data.get('bids_meta', {}).get('session_id', 'unknown'),
                    'snr': data.get('snr_total', np.nan),
                    'cnr': data.get('cnr', np.nan),
                    'fber': data.get('fber', np.nan),
                    'efc': data.get('efc', np.nan),
                    'qi_1': data.get('qi_1', np.nan),
                    'qi_2': data.get('qi_2', np.nan),
                    'cjv': data.get('cjv', np.nan),
                    'wm2max': data.get('wm2max', np.nan),
                }
                metrics_list.append(metrics)
        
        return pd.DataFrame(metrics_list)
    
    def generate_bold_summary(self, df):
        """Generate summary statistics for BOLD data"""
        print("\n" + "="*60)
        print("BOLD QUALITY METRICS SUMMARY")
        print("="*60)
        
        summary = df.describe()
        print(summary)
        
        # Identify potential issues
        print("\n" + "-"*60)
        print("QUALITY FLAGS")
        print("-"*60)
        
        # High motion subjects (FD mean > 0.5mm)
        high_motion = df[df['fd_mean'] > 0.5]
        if len(high_motion) > 0:
            print(f"\n⚠️  High motion detected ({len(high_motion)} subjects):")
            print(high_motion[['subject_id', 'session_id', 'fd_mean']])
        
        # Low tSNR (< 50)
        low_tsnr = df[df['tsnr'] < 50]
        if len(low_tsnr) > 0:
            print(f"\n⚠️  Low temporal SNR detected ({len(low_tsnr)} subjects):")
            print(low_tsnr[['subject_id', 'session_id', 'tsnr']])
        
        # Save summary to CSV
        summary_file = self.output_dir / 'bold_qc_summary.csv'
        df.to_csv(summary_file, index=False)
        print(f"\n✓ Summary saved to: {summary_file}")
        
        return summary
    
    def generate_t1w_summary(self, df):
        """Generate summary statistics for T1w data"""
        print("\n" + "="*60)
        print("T1W QUALITY METRICS SUMMARY")
        print("="*60)
        
        summary = df.describe()
        print(summary)
        
        # Identify potential issues
        print("\n" + "-"*60)
        print("QUALITY FLAGS")
        print("-"*60)
        
        # Low SNR (< 10)
        low_snr = df[df['snr'] < 10]
        if len(low_snr) > 0:
            print(f"\n⚠️  Low SNR detected ({len(low_snr)} subjects):")
            print(low_snr[['subject_id', 'session_id', 'snr']])
        
        # High EFC (> 0.5, indicates non-uniformity)
        high_efc = df[df['efc'] > 0.5]
        if len(high_efc) > 0:
            print(f"\n⚠️  High entropy (non-uniformity) detected ({len(high_efc)} subjects):")
            print(high_efc[['subject_id', 'session_id', 'efc']])
        
        # Save summary to CSV
        summary_file = self.output_dir / 't1w_qc_summary.csv'
        df.to_csv(summary_file, index=False)
        print(f"\n✓ Summary saved to: {summary_file}")
        
        return summary
    
    def create_exclusion_list(self, bold_df, t1w_df):
        """Create list of subjects to potentially exclude based on QC"""
        exclusions = []
        
        if bold_df is not None:
            # Exclude subjects with extreme motion
            high_motion = bold_df[bold_df['fd_mean'] > 0.9]
            for _, row in high_motion.iterrows():
                exclusions.append({
                    'subject_id': row['subject_id'],
                    'session_id': row['session_id'],
                    'reason': f'High motion (FD={row["fd_mean"]:.3f}mm)',
                    'severity': 'high'
                })
            
            # Warn about moderate motion
            mod_motion = bold_df[(bold_df['fd_mean'] > 0.5) & (bold_df['fd_mean'] <= 0.9)]
            for _, row in mod_motion.iterrows():
                exclusions.append({
                    'subject_id': row['subject_id'],
                    'session_id': row['session_id'],
                    'reason': f'Moderate motion (FD={row["fd_mean"]:.3f}mm)',
                    'severity': 'moderate'
                })
            
            # Low tSNR
            low_tsnr = bold_df[bold_df['tsnr'] < 40]
            for _, row in low_tsnr.iterrows():
                exclusions.append({
                    'subject_id': row['subject_id'],
                    'session_id': row['session_id'],
                    'reason': f'Low tSNR ({row["tsnr"]:.2f})',
                    'severity': 'moderate'
                })
        
        if t1w_df is not None:
            # Very low SNR
            low_snr = t1w_df[t1w_df['snr'] < 8]
            for _, row in low_snr.iterrows():
                exclusions.append({
                    'subject_id': row['subject_id'],
                    'session_id': row['session_id'],
                    'reason': f'Very low SNR ({row["snr"]:.2f})',
                    'severity': 'high'
                })
        
        if exclusions:
            exclusion_df = pd.DataFrame(exclusions)
            exclusion_file = self.output_dir / 'suggested_exclusions.csv'
            exclusion_df.to_csv(exclusion_file, index=False)
            
            print("\n" + "="*60)
            print("SUGGESTED EXCLUSIONS")
            print("="*60)
            print(f"\nFound {len(exclusions)} potential quality issues:")
            print(exclusion_df)
            print(f"\n✓ Exclusion list saved to: {exclusion_file}")
        else:
            print("\n✓ No subjects flagged for exclusion based on QC metrics")
        
        return exclusions
    
    def run(self):
        """Run complete QC analysis"""
        print("="*60)
        print("MRIQC Quality Control Analysis")
        print("="*60)
        print(f"MRIQC directory: {self.mriqc_dir}")
        print(f"Output directory: {self.output_dir}")
        
        # Load metrics
        bold_df = self.load_bold_metrics()
        t1w_df = self.load_t1w_metrics()
        
        if bold_df is None and t1w_df is None:
            print("\nERROR: No quality metrics found!")
            print("Please run MRIQC first")
            return
        
        # Generate summaries
        if bold_df is not None:
            self.generate_bold_summary(bold_df)
        
        if t1w_df is not None:
            self.generate_t1w_summary(t1w_df)
        
        # Create exclusion recommendations
        self.create_exclusion_list(bold_df, t1w_df)
        
        print("\n" + "="*60)
        print("QC ANALYSIS COMPLETE")
        print("="*60)
        print(f"\nReports saved to: {self.output_dir}")
        print("\nReview the HTML reports in the MRIQC derivatives folder:")
        print(f"  firefox {self.mriqc_dir}/*.html")


def main():
    parser = argparse.ArgumentParser(
        description='Generate QC summary from MRIQC outputs'
    )
    parser.add_argument(
        '--derivatives-dir',
        default='derivatives',
        help='Path to derivatives directory (default: derivatives)'
    )
    
    args = parser.parse_args()
    
    analyzer = MRIQCAnalyzer(args.derivatives_dir)
    analyzer.run()


if __name__ == '__main__':
    main()
