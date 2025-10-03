#!/bin/bash
#SBATCH --time=168:00:00          
#SBATCH --job-name=FASTP
#SBATCH --error=./std.err/%x.%J.err
#SBATCH --output=./std.out/%x.%J.out
#SBATCH --mail-user=
#SBATCH --mail-type=END,FAIL
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=1 
#SBATCH --mem=8gb
#SBATCH --partition=batch

set -eou pipefail
# ENV (HCC SWAN)
module purge
module load fastp/0.23
module load anaconda/25.3
module load multiqc/py37/1.8
module load fastqc/0.12
# Conda ENV
conda activate "$NRDSTOR/biostar"

#==================================================================#
# Trimming Script with Fastp
#
# July 8, 2025
#==================================================================#
# Location for analysis 
WKDIR=""

# Path to design file (tab-separated with columns: sample, R1, R2, condition ... metadata)
DESIGN=""

# Report Name
REPORT="TRIM_QC2"

# Fastp Parameters
W=4
Q=20
ML=36

# Threads for parallel processing
N=8

#############################################################
##					DIRECTORY SETUP						   ##
#############################################################

# Define report-specific working directories
REPORT_DIR="$WKDIR/$REPORT"
TRIM_DIR="$REPORT_DIR/02_TRIMMED_DATA"
QC_DIR="$REPORT_DIR/03_REVISED_QC"
ZIP_DIR="$QC_DIR/ZIP"
HTML_DIR="$QC_DIR/HTML"
MULTIQC_DIR="$QC_DIR/MULTIQC"
FASTP_DIR="$TRIM_DIR/FASTP"

mkdir -p "$REPORT_DIR" "$TRIM_DIR" "$ZIP_DIR" "$HTML_DIR" "$MULTIQC_DIR" "$FASTP_DIR"

#############################################################
##					              Commands              				   ##
#############################################################

cd "$TRIM_DIR"

# Run fastp in parallel
tail -n +2 "$DESIGN" | awk -F'\t' '{print $1, $2, $3}' | \
parallel --colsep '/t' -j "$N" '
 SAMPLE={1}
 R1={2}
 R2={3}

 fastp \
   -i "$R1" -I "$R2" \
   -o "${SAMPLE}_R1_PE.fastq.gz" -O "${SAMPLE}_R2_PE.fastq.gz" \
   --detect_adapter_for_pe \
   --cut_right \
   --cut_right_window_size '"$W"' \
   --cut_right_mean_quality '"$Q"' \
   --length_required '"$ML"' \
   --thread 8 \
   --html "${SAMPLE}.html" \
   --json "${SAMPLE}.json"
'

mv "$TRIM_DIR"/*.html "$FASTP_DIR"/
mv "$TRIM_DIR"/*.json "$FASTP_DIR"/

echo "Trimming complete."

# Run Fastqc in Parallel
find "$TRIM_DIR" -name "*.fastq.gz" -print0 | \
  parallel \
    -0 \
    -j "$N" \
    --bar \
    --joblog "$QC_DIR/parallel_fastqc.log" \
    "fastqc --outdir $QC_DIR {}"

mv "$QC_DIR"/*.html "$HTML_DIR"/
mv "$QC_DIR"/*.zip "$ZIP_DIR"/


# Generate MultiQC Report
multiqc "$ZIP_DIR" --outdir "$MULTIQC_DIR" --filename "${REPORT}_W${W}_Q${Q}_ML${ML}_.html"

echo "######################################################################"
echo "=== SLURM Job Efficiency Report ==="
echo "Check with: seff $SLURM_JOB_ID"
echo "######################################################################"