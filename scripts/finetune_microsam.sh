#!/bin/bash
#SBATCH --job-name=microsam-finetune
#SBATCH --output=microsam-finetune-%j.out
#SBATCH --error=microsam-finetune-%j.err
#SBATCH --time=24:00:00
#SBATCH --mem=32G
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
TRAINING_DIR="$MICROSAM_DIR/training_data"
OUTPUT_DIR="$MICROSAM_DIR/models/finetuned"

# Set the cache directory for micro-sam models
export MICROSAM_CACHEDIR="$MICROSAM_DIR/models"

# Create output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Enable access to data directories
export APPTAINER_BINDPATH="/data1,/scratchdata"

# Verify training data exists
if [ ! -d "$TRAINING_DIR/images" ] || [ ! -d "$TRAINING_DIR/masks" ]; then
    echo "Error: Training data not found in $TRAINING_DIR"
    echo "Please create the following structure:"
    echo "$TRAINING_DIR/images/  (place your training images here)"
    echo "$TRAINING_DIR/masks/   (place your mask images here)"
    exit 1
fi

# Count training images
IMAGE_COUNT=$(ls -1 $TRAINING_DIR/images/*.tif $TRAINING_DIR/images/*.tiff 2>/dev/null | wc -l)
MASK_COUNT=$(ls -1 $TRAINING_DIR/masks/*.tif $TRAINING_DIR/masks/*.tiff 2>/dev/null | wc -l)

echo "Found $IMAGE_COUNT training images and $MASK_COUNT masks"

if [ $IMAGE_COUNT -eq 0 ] || [ $MASK_COUNT -eq 0 ]; then
    echo "Error: No training images or masks found"
    exit 1
fi

if [ $IMAGE_COUNT -ne $MASK_COUNT ]; then
    echo "Warning: Number of images ($IMAGE_COUNT) doesn't match number of masks ($MASK_COUNT)"
    echo "Each image should have a corresponding mask"
fi

echo "Starting finetuning process..."
echo "This may take several hours depending on your dataset size"

# Run finetuning
singularity exec --nv $CONTAINER \
  python -c "
import micro_sam
from micro_sam.training import finetune_sam
import torch
import os

# Set your training parameters
finetune_sam(
    training_data_path='$TRAINING_DIR',
    output_path='$OUTPUT_DIR',
    model_type='vit_b',
    device=torch.device('cuda'),
    batch_size=4,
    epochs=100,
    save_checkpoint_every=10
)

print('Model saved to: $OUTPUT_DIR/sam_finetuned.pt')
"

echo "Finetuning complete!"
echo "The finetuned model is saved at: $OUTPUT_DIR/sam_finetuned.pt"
echo ""
echo "To use your finetuned model, run:"
echo "sbatch scripts/run_microsam_finetuned.sh input/your_image.tif output/result.tif"