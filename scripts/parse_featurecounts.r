#######################################################################################################
## Script Author: Michael Grapin                                                                     ##                                             
## Purpose: Transforms Feature counts into csv output file for downstream analysis.                                                                                         ##
#######################################################################################################
#
# Transform feature counts output to simple counts.
#

# The results files to be compared.

# Count file produced by featurecounts.
counts_file <- "Counts_geneID.txt"

# The sample file must be in CSV format and must have the headers "sample" and "condition".
design_file = "design.csv"

# The name of the output file.
output_file = "GENE_ID_COUNTS.csv"

# Inform the user.
print("# Tool: Parse featurecounts")
print(paste("# Design: ", design_file))
print(paste("# Input: ", counts_file))

# Read the sample file.
sample_data <- read.csv(design_file, stringsAsFactors=F)

# Turn conditions into factors.
sample_data$condition <- factor(sample_data$condition)

# The first level should correspond to the first entry in the file!
# Required when building a model.
sample_data$condition <- relevel(sample_data$condition, toString(sample_data$condition[1]))

# Read the featurecounts output.
df <- read.table(counts_file, header=TRUE)

#
# It is absolutely essential that the order of the featurecounts headers is the same
# as the order of the sample names in the file! The code below will overwrite the headers!
#

# Subset the dataframe to the columns of interest.
#counts <- df[ ,c(1, 7:length(names(df)))]
#counts <- df[ ,c(1, 6:length(names(df)))]

counts <- df[, c(1, 7:ncol(df))]


# Rename the columns
names(counts) <- c("Symbol", "GeneID", sample_data$sample)

# Remove "GeneID:" from the GeneID column
counts$GeneID <- sub("GeneID:", "", counts$GeneID)


# Write the result to the standard output.
write.csv(counts, file=output_file, row.names=FALSE, quote=FALSE)

# Inform the user.
print(paste("# Output: ", output_file))
