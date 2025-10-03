#!/bin/bash
#SBATCH --time=168:00:00
#SBATCH --job-name=AlignReads
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=50gb		
#SBATCH --mail-user=
#SBATCH --mail-type=END,FAIL
#SBATCH --error=./std.err/%x.%J.err
#SBATCH --output=./std.out/%x.%J.out
#SBATCH --partition=batch


set -euo pipefail

# ENV (HCC SWAN)
module purge 
module load hisat2/2.2
module load samtools/1.20
module load anaconda/25.3
module load multiqc/py37/1.8
conda activate "$NRDSTOR/biostar"


# Michael Grapin @ Moore Lab Research Technician 
# September 24th 2025
####################################################################################################################
##											Parameters and Setup												  ##
####################################################################################################################
# Fill out required fields and then submit via slurm 
# Usage sbatch AlignReads.sh 

# Path to where you want to output the Hisat2 run (Change if you don't want it in the same directory that you submit the script)
OUTDIR= 

# Path to directory contaning the trimmed data
TRIM=

# !!! MASK SURE TO INDEX YOUR GENOME FIRST !!!  -> IDX.sh
# Path to Hisat2 Indices Prefix (ex. <PREFIX>.1.h2)
IDX=


# Number of Jobs in Parallel
N=$SLURM_NTASKS

# Number of Cores Per Job 
THREADS=$SLURM_CPUS_PER_TASK

####################################################################################################################
##												Commands														  ##
####################################################################################################################
# Make Output Directory
mkdir -p $OUTDIR 

# Move to OUTDIR
cd $OUTDIR

# Align with Hisat2 
echo "Starting alignment at $(date)"

# Find all the R1 FASTQ files in the specified directory.
# This assumes your files are named like 'Sample_R1.fastq.gz'.
# It uses 'find' to create a clean list of files.
find "$TRIM" -name "*_R1*.fastq.gz" | sort | while read R1_FILE; do
    # For each R1 file, derive the sample name, R2 file, and output BAM file.

    # Derives 'Sample' from '.../Sample_R1.fastq.gz'
    SAMPLE_NAME=$(basename "$R1_FILE" | sed 's/_R1.*.fastq.gz//')

    # Derives '.../Sample_R2.fastq.gz' from '.../Sample_R1.fastq.gz'
    R2_FILE=$(echo "$R1_FILE" | sed 's/_R1/_R2/')

    # Creates the output file name 'Sample.sorted.bam'
    OUTPUT_BAM="${SAMPLE_NAME}.bam"

    # Add the command to a list for GNU Parallel to execute.
    # The command pipes the output of hisat2 directly to samtools sort.
    echo "hisat2 -p $THREADS -x \"$IDX\" -1 \"$R1_FILE\" -2 \"$R2_FILE\" 2> ${SAMPLE_NAME}.hisat2.log | samtools sort -@ 4 -o \"$OUTPUT_BAM\"" 

done | parallel -j $N

# Clean up logs 
for f in $OUTDIR/*.log; do
    echo "===== $(basename "$f") ====="
    cat "$f"
    echo
done > Hisat2Job_"$SLURM_JOB_ID".out

tar -czf Hisat2Logs_$SLURM_JOB_ID.tar.gz $OUTDIR/*.log
rm $OUTDIR/*.log


echo "Alignment complete at $(date)"

echo "[Done Hisat2]" 
echo " "
echo " "
echo "[RESOURCE REPORT]"
echo "Run: seff $SLURM_JOB_ID"