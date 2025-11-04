# Installation Guide
## Setting Up the Neuroimaging Pipeline

This guide walks through installing all required software and dependencies.

## System Requirements

### Minimum Requirements
- **OS**: Linux (Ubuntu 20.04+), macOS 10.15+, or Windows with WSL2
- **CPU**: 4 cores
- **RAM**: 16 GB
- **Disk**: 100 GB free space
- **Internet**: For downloading containers and packages

### Recommended Requirements
- **CPU**: 8+ cores
- **RAM**: 32+ GB
- **Disk**: 500 GB+ (SSD preferred)

## Step 1: Install Core Dependencies

### Ubuntu/Debian Linux

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install essential tools
sudo apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    unzip \
    tree

# Install dcm2niix (DICOM converter)
sudo apt-get install -y dcm2niix

# Verify installation
dcm2niix -v
```

### macOS

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dcm2niix
brew install dcm2niix

# Verify installation
dcm2niix -v
```

### Windows (WSL2)

```bash
# Install WSL2 with Ubuntu
# Follow: https://docs.microsoft.com/en-us/windows/wsl/install

# Then follow Ubuntu instructions above
```

## Step 2: Install Container Engine

Choose either Docker (easier, local use) or Singularity (HPC use).

### Docker

#### Linux
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, then test
docker run hello-world
```

#### macOS
```bash
# Download and install Docker Desktop
# https://www.docker.com/products/docker-desktop

# Start Docker Desktop
# Test installation
docker run hello-world
```

### Singularity (for HPC)

```bash
# On Ubuntu 20.04
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    libseccomp-dev \
    pkg-config \
    squashfs-tools \
    cryptsetup

# Install Go
export VERSION=1.20.5 OS=linux ARCH=amd64
wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz
sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz
rm go$VERSION.$OS-$ARCH.tar.gz

# Add to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Install Singularity
export VERSION=3.11.3
wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz
tar -xzf singularity-ce-${VERSION}.tar.gz
cd singularity-ce-${VERSION}
./mconfig
make -C builddir
sudo make -C builddir install

# Verify
singularity --version
```

## Step 3: Install Python Dependencies

```bash
# Install Python 3.8+
sudo apt-get install -y python3 python3-pip

# Install required packages
pip3 install --user \
    numpy \
    pandas \
    nibabel \
    pydicom \
    nilearn \
    matplotlib \
    seaborn

# Verify installation
python3 -c "import nibabel, pandas, numpy; print('✓ All packages installed')"
```

## Step 4: Install Optional Tools

### BIDS Validator (Recommended)

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install BIDS validator
sudo npm install -g bids-validator

# Verify
bids-validator --version
```

### FSL (Optional - for advanced analyses)

```bash
# Download FSL installer
wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py

# Run installer
python3 fslinstaller.py

# Follow prompts and add to PATH
echo 'source /usr/local/fsl/etc/fslconf/fsl.sh' >> ~/.bashrc
source ~/.bashrc

# Verify
fsl --version
```

## Step 5: Get FreeSurfer License

**IMPORTANT**: A FreeSurfer license is required for fMRIPrep and FreeSurfer.

1. Register at: https://surfer.nmr.mgh.harvard.edu/registration.html
2. You'll receive a `license.txt` file via email
3. Save it to: `neuroimaging_pipeline/code/license.txt`

```bash
# Example license.txt content:
your.email@institution.edu
12345
*AbCdEfGhIjKl
FSabcdefghijk
```

## Step 6: Download Container Images

### Using Docker

```bash
# Pull required containers (optional - will auto-download when needed)
docker pull nipreps/fmriprep:23.2.0
docker pull nipreps/mriqc:23.1.0
docker pull pennbbl/qsiprep:0.19.0
docker pull freesurfer/freesurfer:7.4.1

# Verify
docker images
```

### Using Singularity

```bash
# Create containers directory
mkdir -p ~/neuroimaging_pipeline/containers

# Pull containers
cd ~/neuroimaging_pipeline/containers

singularity pull fmriprep_23.2.0.sif docker://nipreps/fmriprep:23.2.0
singularity pull mriqc_23.1.0.sif docker://nipreps/mriqc:23.1.0
singularity pull qsiprep_0.19.0.sif docker://pennbbl/qsiprep:0.19.0

# Note: This may take 30-60 minutes per container
```

## Step 7: Configure Pipeline

```bash
# Download/setup the pipeline
cd ~
# (Assuming you have the pipeline files)

# Update paths in configuration
nano neuroimaging_pipeline/config.sh

# Make scripts executable
chmod +x neuroimaging_pipeline/code/*.sh
chmod +x neuroimaging_pipeline/code/slurm/*.sh
chmod +x neuroimaging_pipeline/code/*.py

# Add FreeSurfer license
nano neuroimaging_pipeline/code/license.txt
# Paste your license content
```

## Step 8: Verify Installation

```bash
# Run verification script
cd ~/neuroimaging_pipeline

# Check dependencies
echo "Checking installations..."

# dcm2niix
which dcm2niix && echo "✓ dcm2niix installed" || echo "✗ dcm2niix missing"

# Docker or Singularity
which docker && echo "✓ Docker installed" || which singularity && echo "✓ Singularity installed" || echo "✗ No container engine"

# Python packages
python3 -c "import nibabel; print('✓ nibabel')" 2>/dev/null || echo "✗ nibabel missing"
python3 -c "import pandas; print('✓ pandas')" 2>/dev/null || echo "✗ pandas missing"

# BIDS validator (optional)
which bids-validator && echo "✓ bids-validator installed" || echo "○ bids-validator not installed (optional)"

# FreeSurfer license
[ -f code/license.txt ] && echo "✓ FreeSurfer license found" || echo "✗ FreeSurfer license missing"

echo ""
echo "Setup verification complete!"
```

## HPC-Specific Setup

If using an HPC cluster with SLURM:

### 1. Load Required Modules

```bash
# Check available modules
module avail

# Common modules needed
module load singularity
module load python/3.8
module load dcm2niix
```

### 2. Update SLURM Scripts

```bash
# Edit each SLURM script
nano code/slurm/slurm_fmriprep.sh

# Update these variables:
PIPELINE_DIR="/path/to/your/neuroimaging_pipeline"  # Change this!

# Update module loads in the script
module load singularity/3.8.0  # Use your HPC's version
```

### 3. Test SLURM Submission

```bash
# Submit a test job
sbatch --wrap="echo 'SLURM test successful'"

# Check status
squeue -u $USER
```

## Troubleshooting

### Issue: "dcm2niix not found"

```bash
# Compile from source
git clone https://github.com/rordenlab/dcm2niix.git
cd dcm2niix
mkdir build && cd build
cmake ..
make
sudo make install
```

### Issue: "Docker permission denied"

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in
# Or use: newgrp docker
```

### Issue: "Insufficient disk space"

```bash
# Check space
df -h

# Clean Docker
docker system prune -a

# Clean Singularity cache
singularity cache clean
```

### Issue: "Out of memory"

- Reduce `--n_cpus` and `--mem_mb` in scripts
- Close other applications
- Consider processing fewer subjects simultaneously

## Resource Links

- **dcm2niix**: https://github.com/rordenlab/dcm2niix
- **Docker**: https://docs.docker.com/get-docker/
- **Singularity**: https://sylabs.io/docs/
- **BIDS**: https://bids-specification.readthedocs.io/
- **fMRIPrep**: https://fmriprep.org/
- **FreeSurfer**: https://surfer.nmr.mgh.harvard.edu/
- **Nilearn**: https://nilearn.github.io/

## Quick Start After Installation

```bash
# 1. Setup data
./code/00_setup_data.sh /path/to/dicom/zip

# 2. Convert to BIDS
./code/01_dicom2bids.sh

# 3. Validate
./code/02_validate_bids.sh

# 4. Run QC
./code/03_run_mriqc.sh participant
./code/03_run_mriqc.sh group

# 5. Analyze QC
python code/qc_summary.py

# 6. Preprocess
./code/04_run_fmriprep.sh
```

## Next Steps

After installation:
1. Read `QUICKSTART.md` for usage instructions
2. Review `README.md` for complete documentation
3. Check `MANIFEST.md` for all available tools
4. Run test dataset to verify everything works

## Getting Help

If you encounter issues:
1. Check this guide's troubleshooting section
2. Review log files in `logs/` directory
3. Search Neurostars forum: https://neurostars.org/
4. Check tool-specific documentation
5. Ask in neuroimaging Slack/Discord communities

---

**Last Updated**: November 2025
**Pipeline Version**: 1.0.0
