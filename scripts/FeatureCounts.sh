#!/bin/bash
#SBATCH --time=10:00:00          # Run time in hh:mm:ss
#SBATCH --job-name=COUNT
#SBATCH --error=/%x.%J.err
#SBATCH --output=/%x.%J.out
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=6gb
#SBATCH --partition=batch


#==================================================================#
# Transcript quantification with Feature Counts
# JUNE 26, 2025
#==================================================================#

set -uex

#############################################################
##						SCRIPT PARAMETERS				   ##
#############################################################

# Working directory 
WKDIR="/work/moorelab/mgrapin2/BOVINE_RNAseq"

# Reference genome GTF
GTF="/work/moorelab/mgrapin2/BOVINE_RNAseq/REPORT_3/ARS-UCD2.0.filtered.gtf"

# Name of output file 
OUTPUT="counts2.0.txt"

# Aligned data directory
ALIGN="${WKDIR}/REPORT_3/04_ALIGNMENT/marked_bams"

# Output directory for BAMs
COUNT_DIR="${WKDIR}/REPORT_3/05_QUANTIFICATION"

# Number of threads for alignment
THREADS=$SLURM_CPUS_PER_TASK


#############################################################
##						ENVIRONMENT SETUP				   ##
#############################################################
set +uex
module purge
module load biodata/1.0
module load anaconda/25.3		
module load multiqc/py37/1.8
module load subread/2.0


source ~/.bashrc
conda activate "$NRDSTOR/biostar"

set -uex

mkdir -p "$COUNT_DIR"
mkdir -p "$COUNT_DIR/MULTQC"
cd "$COUNT_DIR"

#############################################################
##					  	Commands						   ##
#############################################################

find "$ALIGN" -maxdepth 1 -name "*.bam" -print0 | xargs -0 readlink -f > "$COUNT_DIR/bam_list.txt"

# Feature Counts commmand from subread package V: featureCounts v2.0.6
featureCounts -t exon -g gene_name -p -a "$GTF" -o "$OUTPUT" -T $THREADS -Q 20 -C -B -M --fraction --countReadPairs --extraAttributes db_xref,gene_biotype,gene_name $(<bam_list.txt)			#< Bash built-in file read like 'cat filename'


# https://subread.sourceforge.net/featureCounts.html (will need to look for proper use examples)


echo "Counting complete at $(date)"


multiqc "$COUNT_DIR" --outdir "$COUNT_DIR/MULTQC" --filename "Counts.html"

# Make custom plotting script to plot extracted data from feature counts 

echo "######################################################################"
echo "=== Memory Report for INITIAL_QUALITY.sh ==="
mem_report

echo "=== SLURM Job Efficiency Report ==="
echo "Check SLURM job stats with: seff $SLURM_JOB_ID"
echo "######################################################################"