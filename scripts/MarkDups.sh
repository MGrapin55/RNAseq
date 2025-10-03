#!/bin/bash
#SBATCH --time=168:00:00
#SBATCH --job-name=MarkDuplicates
#SBATCH --error=./std.err/%x.%J.err
#SBATCH --output=./std.out/%x.%J.out
#SBATCH --nodes=1
#SBATCH --ntasks=4              # Number of parallel jobs
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --partition=batch
set -eou pipefail

# ENV (HCC SWAN)
module purge
module load picard/3.0
module load anaconda/25.3
module load multiqc/py37/1.8

# Conda Env
conda activate "$NRDSTOR/biostar"

#==================================================================#
# Mark Duplicate Reads with Picard MarkDuplicates
# JULY 15, 2025
#==================================================================#
# Fill out fields and submit
# Usage: sbatch MarkDups.sh

# Path to Directory Containning BAM Files
ALIGN=""

#############################################################
##                      COMMANDS		              			   ##
#############################################################

# Create output directories
mkdir -p "${ALIGN}/DUP/marked" "${ALIGN}/DUP/metric" "${ALIGN}/DUP/multiqc"

# Run MarkDuplicates in Parallel
find "$ALIGN" -name "*.bam" | parallel -j "$N" "
  picard MarkDuplicates \
    I={} \
    O=\"${ALIGN}/DUP/metric/{/.}.marked.bam\" \
    M=\"${ALIGN}/DUP/metric/{/.}.metrics\" \
    CREATE_INDEX=true \
    VALIDATION_STRINGENCY=LENIENT
"
multiqc "${ALIGN}/DUP/metric" --outdir "${ALIGN}/DUP/multiqc" --filename "MarkDup.html"
echo " Marked Bams in: "${ALIGN}/DUP/marked" " 
echo " Examine results in: "${ALIGN}/DUP/metric/multiqc" "


# find "$ALIGN" -name "*.bam" | parallel -j "$N" '
#   infile={}
#   base=$(basename "$infile" .bam)
#   outfile='"$MARKED_DIR"'/${base}.marked.bam
#   metrics='"$METRICS_DIR"'/${base}.metrics.txt

#   picard MarkDuplicates \
#     I="$infile" \
#     O="$outfile" \
#     M="$metrics" \
#     CREATE_INDEX=true \
#     VALIDATION_STRINGENCY=LENIENT
# '

echo "######################################################################"
echo "=== SLURM Job Efficiency Report ==="
echo "Check SLURM job stats with: seff $SLURM_JOB_ID"
echo "######################################################################"
