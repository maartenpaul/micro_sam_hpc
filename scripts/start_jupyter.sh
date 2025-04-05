#!/bin/bash
#SBATCH --job-name=jupyter-server
#SBATCH --output=jupyter-server-%j.out
#SBATCH --error=jupyter-server-%j.err
#SBATCH --time=8:00:00
#SBATCH --mem=16G
#SBATCH --partition=testing
#SBATCH --gres=gpu:1

# Set up Singularity environment
export APPTAINER_TMPDIR=$SCRATCH/.apptainer-tmp
export APPTAINER_CACHEDIR=$SCRATCH/.apptainer-cache
mkdir -p $APPTAINER_TMPDIR $APPTAINER_CACHEDIR

# Define paths
MICROSAM_DIR="/data1/$USER/micro_sam"
CONTAINER="$MICROSAM_DIR/micro_sam.sif"

# Set the cache directory for micro-sam models
export MICROSAM_CACHEDIR="$MICROSAM_DIR/models"

# Bind data directories
export APPTAINER_BINDPATH="/data1,/scratchdata"

# Get the hostname and port
NODE=$(hostname -s)
PORT=8888

# Create a workspace directory
WORKSPACE="$MICROSAM_DIR/jupyter_workspace"
mkdir -p $WORKSPACE

# Start Jupyter notebook server
echo "========================================================"
echo "Starting Jupyter Notebook server on $NODE:$PORT"
echo "========================================================"
echo ""
echo "To connect in VS Code:"
echo ""
echo "1. Update your SSH config file with these settings:"
echo "   Host alice-notebook"
echo "       HostName $NODE"
echo "       User $USER"
echo "       ProxyJump alicegw:22"
echo "       ServerAliveInterval 60"
echo "       LocalForward 8888 localhost:8888"
echo "       IdentityFile ~/.ssh/id_rsa"
echo ""
echo "2. Connect using VS Code Remote SSH to 'alice-notebook'"
echo ""
echo "3. Open http://localhost:8888 in your browser"
echo "   Password/token (if needed): See below"
echo ""
echo "========================================================"

singularity exec --nv $CONTAINER jupyter notebook \
  --no-browser \
  --port=$PORT \
  --ip=127.0.0.1 \
  --notebook-dir=$WORKSPACE

echo "Jupyter notebook server has stopped"