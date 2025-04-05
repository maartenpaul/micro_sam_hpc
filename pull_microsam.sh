#!/bin/bash
#SBATCH --job-name=pull-microsam
#SBATCH --output=pull-microsam-%j.out
#SBATCH --error=pull-microsam-%j.err
#SBATCH --time=3:00:00     # Appropriate time allocation
#SBATCH --mem=32G          # Increased memory which is most critical
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4  # Reduced from 8 to 4 as more won't help much
#SBATCH --partition=cpu-short

# Set up temporary and cache directories in scratch space
export APPTAINER_TMPDIR=$SCRATCH/.apptainer-tmp
export APPTAINER_CACHEDIR=$SCRATCH/.apptainer-cache
mkdir -p $APPTAINER_TMPDIR
mkdir -p $APPTAINER_CACHEDIR

# Create output directory if it doesn't exist
mkdir -p /data1/$USER/micro_sam

# Pull the Docker image from Docker Hub and convert to Singularity
echo "Pulling docker://maartenpaul/microsam_gpu:latest..."
echo "This may take some time depending on image size and network speed."
singularity pull --dir $SCRATCH docker://maartenpaul/microsam_gpu:latest

# Only proceed with copy if pull was successful
if [ -f "$SCRATCH/microsam_gpu_latest.sif" ]; then
    # Copy the container to the requested location
    cp $SCRATCH/microsam_gpu_latest.sif /data1/$USER/micro_sam/micro_sam.sif
    
    # Verify the container was pulled and copied successfully
    echo "Container pulled and copied to /data1/$USER/micro_sam/micro_sam.sif"
    echo "Container size: $(du -h /data1/$USER/micro_sam/micro_sam.sif | cut -f1)"
else
    echo "ERROR: Singularity pull failed. Check the job output for error messages."
    exit 1
fi

# Clean up temporary files to save space
rm -f $SCRATCH/microsam_gpu_latest.sif
echo "Temporary files cleaned up."