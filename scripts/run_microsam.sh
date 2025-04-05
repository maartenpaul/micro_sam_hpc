#!/bin/bash
#SBATCH --job-name=microsam-process
#SBATCH --output=microsam-process-%j.out
#SBATCH --error=microsam-process-%j.err
#SBATCH --time=1:00:00
#SBATCH --mem=16G
#SBATCH --partition=testing
#SBATCH --gres=gpu:1

# Get input and output paths from arguments
INPUT_FILE=$1
OUTPUT_FILE=$2

# Check if input file was provided
if [ -z "$INPUT_FILE" ]; then
    echo "Error: Input file not specified"
    echo "Usage: sbatch run_microsam.sh input/image.tif output/result.tif"
    exit 1
fi

# Check if output file was provided
if [ -z "$OUTPUT_FILE" ]; then
    echo "Error: Output file not specified"
    echo "Usage: sbatch run_microsam.sh input/image.tif output/result.tif"
    exit 1
fi

# Set up Singularity environment
export APPTAINER_TMPDIR=$SCRATCH/.apptainer-tmp
export APPTAINER_CACHEDIR=$SCRATCH/.apptainer-cache
mkdir -p $APPTAINER_TMPDIR
mkdir -p $APPTAINER_CACHEDIR

# Define paths
MICROSAM_DIR="/data1/$USER/micro_sam"
CONTAINER="$MICROSAM_DIR/micro_sam.sif"

# Set the cache directory for micro-sam models
export MICROSAM_CACHEDIR="$MICROSAM_DIR/models"

# Check if input paths are absolute, if not, make them relative to micro_sam directory
if [[ "$INPUT_FILE" != /* ]]; then
    INPUT_FILE="$MICROSAM_DIR/$INPUT_FILE"
fi

if [[ "$OUTPUT_FILE" != /* ]]; then
    OUTPUT_FILE="$MICROSAM_DIR/$OUTPUT_FILE"
fi

# Create output directory if it doesn't exist
mkdir -p $(dirname "$OUTPUT_FILE")

# Enable access to data directories
export APPTAINER_BINDPATH="/data1,/scratchdata"

echo "Processing image: $INPUT_FILE"
echo "Output will be saved to: $OUTPUT_FILE"

# Run micro-sam command
singularity exec --nv $CONTAINER \
  micro_sam.automatic_segmentation \
  -i "$INPUT_FILE" \
  -o "$OUTPUT_FILE" \
  -v -m vit_b_lm

echo "Processing complete!"