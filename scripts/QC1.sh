#!/bin/bash
#SBATCH --time=168:00:00          
#SBATCH --job-name=InitialQC
#SBATCH --error=./std.err/%x.%J.err
#SBATCH --output=./std.out/%x.%J.out
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1gb
#SBATCH --partition=batch

set -eou pipefail

# ENV (HCC SWAN)
module purge
module load fastqc/0.12
module load multiqc/py37/1.8
module load anaconda/25.3
# Load conda environment
conda activate "$NRDSTOR/biostar"

#==================================================================#
# Preforms initial sequence quality control with FASTQC and MULTIQC
#
# JUNE 10, 2025
#===================================================================#
# Location For Analysis 
WKDIR=""

# Design File In The Working Direcory
DESIGN="DESIGN.tsv"

# Quality Control Report
REPORT="QC1"

# Number of Jobs
N=1

#############################################################
##                      COMMANDS		              			   ##
#############################################################

# Create Needed Directories
mkdir -p "$WKDIR/$REPORT" "$WKDIR/$REPORT/HTML" "$WKDIR/$REPORT/ZIP"

# Skip the header, extract forward and reverse files, run fastqc in parallel
tail -n +2 "$WKDIR/$DESIGN" | \
  awk -F'\t' '{print $3 "\t" $4}' | \
  parallel --colsep '\t' -j $N fastqc -o "$WKDIR/$REPORT" {1} {2}	

# Go to the for Output files
cd "$WKDIR/$REPORT"

# Move all HTML files to HTML/ subdirectory
mv "$WKDIR/$REPORT"/*.html HTML/

# Move all ZIP files to ZIP/ subdirectory
mv "$WKDIR/$REPORT"/*.zip ZIP/

# Generate MultiQC Report 
multiqc "$WKDIR/$REPORT/ZIP" --outdir "$WKDIR/$REPORT/MULTQC" --filename "${REPORT}.html"

echo script completed!

echo "######################################################################"
echo "=== SLURM Job Efficiency Report ==="
echo "Check: seff $SLURM_JOB_ID"
echo "######################################################################"

