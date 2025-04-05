#!/bin/bash
#SBATCH --job-name=microsam-batch
#SBATCH --output=microsam-batch-%j.out
#SBATCH --error=microsam-batch-%j.err
#SBATCH --time=4:00:00
#SBATCH --mem=16G
#SBATCH --partition=testing
#SBATCH --gres=gpu:1

# Set up Singularity environment
export APPTAINER_TMPDIR=$SCRATCH/.apptainer-tmp
export APPTAINER_CACHEDIR=$SCRATCH/.apptainer-cache
mkdir -p $APPTAINER_TMPDIR
mkdir -p $APPTAINER_CACHEDIR

# Define paths
MICROSAM_DIR="/data1/$USER/micro_sam"
CONTAINER="$MICROSAM_DIR/micro_sam.sif"
INPUT_DIR="$MICROSAM_DIR/input"
OUTPUT_DIR="$MICROSAM_DIR/output"

# Set the cache directory for micro-sam models
export MICROSAM_CACHEDIR="$MICROSAM_DIR/models"

# Create output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Enable access to data directories
export APPTAINER_BINDPATH="/data1,/scratchdata"

# Check if there are any TIF files in the input directory
TIF_COUNT=$(ls -1 $INPUT_DIR/*.tif 2>/dev/null | wc -l)
if [ $TIF_COUNT -eq 0 ]; then
    TIF_COUNT=$(ls -1 $INPUT_DIR/*.tiff 2>/dev/null | wc -l)
    if [ $TIF_COUNT -eq 0 ]; then
        echo "No TIF files found in $INPUT_DIR"
        echo "Please place your TIF files in this directory"
        exit 1
    fi
fi

echo "Found $TIF_COUNT TIF files to process"

# Process each TIF file in the input directory
for INPUT_FILE in $INPUT_DIR/*.tif $INPUT_DIR/*.tiff; do
    if [ -f "$INPUT_FILE" ]; then
        FILENAME=$(basename "$INPUT_FILE")
        OUTPUT_FILE="$OUTPUT_DIR/${FILENAME%.*}_segmented.tif"
        
        echo "Processing $FILENAME..."
        singularity exec --nv $CONTAINER \
          micro_sam.automatic_segmentation \
          -i "$INPUT_FILE" \
          -o "$OUTPUT_FILE" \
          -v -m vit_b_lm
    fi
done

echo "Batch processing complete!"
echo "Results are saved in $OUTPUT_DIR"