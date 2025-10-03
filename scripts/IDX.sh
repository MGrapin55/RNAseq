#!/bin/bash
#SBATCH --time=168:00:00                     
#SBATCH --job-name=IdxBuild
#SBATCH --error=./std.err/%x.%J.err
#SBATCH --output=./std.out/%x.%J.out
#SBATCH --mail-user=
#SBATCH --mail-type=END,FAIL
#SBATCH --nodes=1                            
#SBATCH --ntasks=1                           
#SBATCH --cpus-per-task=12                   
#SBATCH --mem=12gb                           
#SBATCH --partition=batch                    

set -euo pipefail

# ENV (HCC SWAN)
module purge 
module load hisat2/2.2

# Michael Grapin @ Moore Lab Research Technician 
# September 24th 2025
#############################################################
##						SCRIPT PARAMETERS				   ##
#############################################################
# Build Hisat2 Index 
# Usage: sbatch Hisat2Index.sh <FASTA> <WKDIR> <ORGANISM_NAME_VERSION>
# Reference genome FASTA
FASTA=

# Path to store the HISAT2 index
WKDIR=

# Output prefix (organism + assembly version)
ORG=

#############################################################
##					  Commands  	        			   ##
#############################################################
# Check if FASTA file exists
[ -f "$FASTA" ] || { echo "FASTA file not found: $FASTA"; exit 1; }

# Ensure output directory exists
mkdir -p $WKDIR $WKDIR/Indices
cd $WKDIR/Indices

echo "==== Starting HISAT2 index build at $(date) ===="
hisat2-build -p $SLURM_CPUS_PER_TASK "$FASTA" "$ORG"
echo "==== Finished HISAT2 index build at $(date) ===="
echo "Path to Hisat2 indices $WKDIR/Indices"


echo "######################################################################"
echo "=== SLURM Job Efficiency Report ==="
echo "Check SLURM job stats with: seff $SLURM_JOB_ID"
echo "######################################################################"
