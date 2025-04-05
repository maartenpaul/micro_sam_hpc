#!/bin/bash
#SBATCH --job-name=build-microsam
#SBATCH --output=build-microsam-%j.out
#SBATCH --error=build-microsam-%j.err
#SBATCH --time=2:00:00
#SBATCH --mem=8G
#SBATCH --partition=testing

# Set up temporary directories for Singularity
export APPTAINER_TMPDIR=$SCRATCH/.apptainer-tmp
export APPTAINER_CACHEDIR=$SCRATCH/.apptainer-cache
mkdir -p $APPTAINER_TMPDIR
mkdir -p $APPTAINER_CACHEDIR

# Create folder structure for micro-sam
MICROSAM_DIR="/data1/$USER/micro_sam"
mkdir -p $MICROSAM_DIR/{input,output,models,training_data,training_data/images,training_data/masks}

echo "Created directory structure at $MICROSAM_DIR"

# Pull/build the container from Docker Hub
echo "Building micro-sam container..."
singularity build $MICROSAM_DIR/micro_sam.sif docker://computationalcellanalytics/microsam:latest

if [ $? -eq 0 ]; then
    echo "Container successfully built at $MICROSAM_DIR/micro_sam.sif"
    echo ""
    echo "Next steps:"
    echo "1. Place your images in $MICROSAM_DIR/input"
    echo "2. Run sbatch scripts/run_microsam.sh"
else
    echo "Container build failed. Check the error messages above."
fi
