#!/bin/bash
#SBATCH --time=168:00:00
#SBATCH --job-name=BamQC
#SBATCH --error=./std.err/%x.%J.err
#SBATCH --output=./std.out/%x.%J.out
#SBATCH --nodes=1
#SBATCH --ntasks=1              
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --partition=batch
set -eou pipefail

# ENV (HCC SWAN)
module purge
module load qualimap/2.3
module load anaconda/25.3
module load multiqc/py37/1.8
# Conda ENV
conda activate "$NRDSTOR/biostar"

#==================================================================#
# Run Quality Control on BAM Files
# JULY 15, 2025
#==================================================================#
# Fill out required fields and submit
# Usage: sbatch BamQC.sh 

# Path to BAM files
ALIGN=""

# Number of parallel commands 
N=$SLURM_NTASKS
#############################################################
##					      Commands              		   ##
#############################################################
mkdir -p "$ALIGN/BamQC" "$ALIGN/BamQC/multiqc"

# For loop over Bam files
# i=1
# for bam in "$ALIGN"/*.bam; do
#     sample=$(basename "$bam" .bam)
#     qualimap bamqc -bam "$bam" -outdir "$ALIGN/BamQC" -sd -sdmode 0 --java-mem-size=4G
#     echo "Done sample $i"
#     ((i++))
# done

# Parallel of Bam files 
find "$ALIGN" -name "*.bam" | parallel -j "$N" "
    qualimap bamqc -bam {} -outdir \"$ALIGN/BamQC/{/.}\" -sd -sdmode 0 --java-mem-size=4G
"

echo "Done running bamqc!"

# Generate MultiQC Report 
multiqc "$ALIGN/BamQC" --outdir "$ALIGN/BamQC/multiqc" --filename "BAM_REPORT.html" 

echo "######################################################################"
echo "=== SLURM Job Efficiency Report ==="
echo "Check SLURM job stats with: seff $SLURM_JOB_ID"
echo "######################################################################"