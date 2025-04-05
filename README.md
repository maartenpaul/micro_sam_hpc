# Running micro-sam on HPC

This guide explains how to run micro-sam on a High-Performance Computing (HPC) cluster using a containerized approach. This makes it easy to deal with all dependencies. The container is built with Docker and stored on DockerHub, then converted to Singularity format for use on the HPC.

## Building the container

Building the container is only necessary when you make changes to the container. Otherwsie you can skip this section and pull the container from Dockerhub.

```bash
docker build -t microsam_dev .
```

### Interactive use (local development)

```bash
# CPU version
docker run -it -v ${PWD}/test:/tmp/micro-sam -e MICROSAM_CACHEDIR=/tmp/micro-sam/models microsam_dev

# GPU version
docker run -it --gpus all -v ${PWD}/test:/tmp/micro-sam -e MICROSAM_CACHEDIR=/tmp/micro-sam/models microsam_gpu
```

Example command to run within the container:
```bash
micro_sam.automatic_segmentation -i input/test.tif -o output/test.tif -v -m vit_b_lm
```

## Using micro-sam on Alice HPC
This assumes you have setup ssh connection to alice with ssh keys
See: https://pubappslu.atlassian.net/wiki/spaces/HPCWIKI/pages/37748788/Login+to+ALICE+or+SHARK+from+Linux#Making-logins-even-more-convenient-with-ssh-keys

In this example the ssh alias is 'alice1' which gives direct access to the login node

### 1. Prepare the Singularity container

First we need to get the Docker/Singularity container using this script:

```bash
# Copy the script to your account
--> TODO here we need to ssh copy!!!
cp /path/to/scripts/pull_microsam.sh .
chmod +x pull_microsam.sh

# Submit the job to pull and convert the container
--> then login to alice first
sbatch pull_microsam.sh
```

The script will pull the container from DockerHub and save it to `/data1/$USER/micro_sam/micro_sam.sif`. You can check the job status with `squeue -u $USER` and check output with `cat pull-microsam-*.out`.

### 2. Running micro-sam on HPC

Create a job script for processing your data:

```bash
#!/bin/bash
#SBATCH --job-name=microsam-process
#SBATCH --output=microsam-process-%j.out
#SBATCH --error=microsam-process-%j.err
#SBATCH --time=4:00:00
#SBATCH --mem=16G
#SBATCH --partition=testing  # Use appropriate partition with GPU
#SBATCH --gres=gpu:1

# Set up Singularity environment
export APPTAINER_TMPDIR=$SCRATCH/.apptainer-tmp
export APPTAINER_CACHEDIR=$SCRATCH/.apptainer-cache
mkdir -p $APPTAINER_TMPDIR $APPTAINER_CACHEDIR

# Bind data directories
export APPTAINER_BINDPATH="/data1,/scratchdata"

# Container path
CONTAINER=/data1/$USER/micro_sam/micro_sam.sif

# Run micro-sam command
singularity exec --nv $CONTAINER \
  micro_sam.automatic_segmentation \
  -i /path/to/input/image.tif \
  -o /path/to/output/segmented.tif \
  -v -m vit_b_lm

echo "Processing complete!"
```

Save this script (e.g., `run_microsam.sh`), make it executable with `chmod +x run_microsam.sh`, and submit with `sbatch run_microsam.sh`.

### 3. Batch processing multiple files

For processing multiple files, you can create a batch script:

```bash
#!/bin/bash
#SBATCH --job-name=microsam-batch
#SBATCH --output=microsam-batch-%j.out
#SBATCH --error=microsam-batch-%j.err
#SBATCH --time=12:00:00
#SBATCH --mem=16G
#SBATCH --partition=testing  # Use appropriate partition with GPU
#SBATCH --gres=gpu:1

# Set up Singularity environment
export APPTAINER_TMPDIR=$SCRATCH/.apptainer-tmp
export APPTAINER_CACHEDIR=$SCRATCH/.apptainer-cache
mkdir -p $APPTAINER_TMPDIR $APPTAINER_CACHEDIR

# Bind data directories
export APPTAINER_BINDPATH="/data1,/scratchdata"

# Container path
CONTAINER=/data1/$USER/micro_sam/micro_sam.sif

# Input/output directories
INPUT_DIR="/data1/$USER/micro_sam/input"
OUTPUT_DIR="/data1/$USER/micro_sam/output"
mkdir -p $OUTPUT_DIR

# Process each TIF file in the input directory
for INPUT_FILE in $INPUT_DIR/*.tif; do
    FILENAME=$(basename "$INPUT_FILE")
    OUTPUT_FILE="$OUTPUT_DIR/${FILENAME%.tif}_segmented.tif"
    
    echo "Processing $FILENAME..."
    singularity exec --nv $CONTAINER \
      micro_sam.automatic_segmentation \
      -i "$INPUT_FILE" \
      -o "$OUTPUT_FILE" \
      -v -m vit_b_lm
done

echo "Batch processing complete!"
```

## Using Jupyter Notebooks with micro-sam

There are two main approaches to working with Jupyter notebooks on the HPC:

### Option 1: Running a Jupyter Notebook server on the HPC

Create a script to start a Jupyter server:

```bash
#!/bin/bash
#SBATCH --job-name=microsam-jupyter
#SBATCH --output=microsam-jupyter-%j.out
#SBATCH --error=microsam-jupyter-%j.err
#SBATCH --time=8:00:00
#SBATCH --mem=16G
#SBATCH --partition=testing  # Use appropriate partition with GPU
#SBATCH --gres=gpu:1

# Set up Singularity environment
export APPTAINER_TMPDIR=$SCRATCH/.apptainer-tmp
export APPTAINER_CACHEDIR=$SCRATCH/.apptainer-cache
mkdir -p $APPTAINER_TMPDIR $APPTAINER_CACHEDIR

# Bind data directories
export APPTAINER_BINDPATH="/data1,/scratchdata"

# Container path
CONTAINER=/data1/$USER/micro_sam/micro_sam.sif

# Get the hostname and port
NODE=$(hostname -s)
PORT=8888

# Create a workspace directory
WORKSPACE="/data1/$USER/micro_sam/jupyter_workspace"
mkdir -p $WORKSPACE

# Start Jupyter notebook server
echo "Starting Jupyter Notebook server on $NODE:$PORT"
echo "When connecting, use: ssh -L $PORT:$NODE:$PORT $USER@alice-login.hpc.rug.nl"

singularity exec --nv $CONTAINER jupyter notebook \
  --no-browser \
  --port=$PORT \
  --ip=0.0.0.0 \
  --notebook-dir=$WORKSPACE
```

Save this script as `start_jupyter.sh`, make it executable, and submit it with `sbatch start_jupyter.sh`.

#### Connecting to the Jupyter server from your local machine

1. Check the job output file to get connection details: `cat microsam-jupyter-*.out`
2. Open an SSH tunnel from your local machine:
   ```bash
   ssh -L 8888:nodeXXX:8888 username@alice-login.hpc.rug.nl
   ```
   (Replace nodeXXX with the actual node name from the job output)
3. Open a web browser and navigate to: `http://localhost:8888`
4. Enter the token provided in the job output when prompted

### Option 2: Using VSCode with Remote SSH and Jupyter (Recommended)

This is the easier option for most users. For detailed instructions on setting up VSCode with the HPC, refer to the HPC wiki: [Setting up VSCode to work on the cluster](https://pubappslu.atlassian.net/wiki/spaces/HPCWIKI/pages/37028145/Setting+up+VSCode+to+work+on+the+cluster)

1. Set up VSCode with Remote SSH extension as described in the Alice documentation

2. Create your Jupyter notebook server job script:
   ```bash
   #!/bin/bash
   #SBATCH --job-name=jupyter-server
   #SBATCH --output=jupyter-server-%j.out
   #SBATCH --error=jupyter-server-%j.err
   #SBATCH --time=8:00:00
   #SBATCH --mem=16G
   #SBATCH --partition=testing  # Use appropriate partition with GPU
   #SBATCH --gres=gpu:1
   
   # Set up Singularity environment
   export APPTAINER_TMPDIR=$SCRATCH/.apptainer-tmp
   export APPTAINER_CACHEDIR=$SCRATCH/.apptainer-cache
   mkdir -p $APPTAINER_TMPDIR $APPTAINER_CACHEDIR
   
   # Bind data directories
   export APPTAINER_BINDPATH="/data1,/scratchdata"
   
   # Container path
   CONTAINER=/data1/$USER/micro_sam/micro_sam.sif
   
   # Get the hostname and port
   NODE=$(hostname -s)
   PORT=8888
   
   # Create a workspace directory
   WORKSPACE="/data1/$USER/micro_sam/jupyter_workspace"
   mkdir -p $WORKSPACE
   
   # Start Jupyter notebook server
   echo "Starting Jupyter Notebook server on $NODE:$PORT"
   echo "Add this to your VSCode SSH Config (~/.ssh_vscode/config):"
   echo ""
   echo "Host alice-notebook"
   echo "    HostName $NODE"
   echo "    User $USER"
   echo "    ProxyJump alicegw:22"
   echo "    LocalForward $PORT localhost:$PORT"
   echo "    ServerAliveInterval 60"
   echo "    IdentityFile ~/.ssh/id_rsa"  # Adjust path to your key
   
   singularity exec --nv $CONTAINER jupyter notebook \
     --no-browser \
     --port=$PORT \
     --ip=127.0.0.1 \
     --notebook-dir=$WORKSPACE
   ```

3. Submit the job: `sbatch start_jupyter_vscode.sh`

4. Check the job output and add the suggested settings to your VSCode SSH config

5. In VSCode:
   - Open Remote SSH Explorer
   - Connect to "alice-notebook"
   - Install the "Jupyter" extension in the remote session if not already installed
   - Open or create a notebook in your workspace directory
   - Select "Jupyter: localhost:8888" as your kernel when prompted

#### Example notebook to test micro-sam

Create a new notebook with the following code to test that everything is working:

```python
# Import required packages
import matplotlib.pyplot as plt
from micro_sam import automatic_segmentation
import os

# Define paths
input_path = "/path/to/your/image.tif"  # Adjust this path
output_path = os.path.join(os.getcwd(), "segmented_output.tif")

# Run segmentation
result = automatic_segmentation(
    input_path,
    output_path,
    model_type="vit_b_lm",
    verbose=True
)

# Display results
plt.figure(figsize=(16, 8))
plt.subplot(1, 2, 1)
plt.imshow(result['image'][0])
plt.title('Original Image')
plt.axis('off')

plt.subplot(1, 2, 2)
plt.imshow(result['mask'][0])
plt.title('Segmentation Mask')
plt.axis('off')

plt.tight_layout()
plt.show()

print(f"Segmentation complete. Found {result['num_objects']} objects.")
```

## Using TensorBoard for Fine-tuning

If you're fine-tuning micro-sam models, you can use TensorBoard to monitor the training progress. Here's how to set it up:

### 1. Create a SLURM job with TensorBoard logging

```bash
#!/bin/bash
#SBATCH --job-name=microsam-finetune
#SBATCH --output=microsam-finetune-%j.out
#SBATCH --error=microsam-finetune-%j.err
#SBATCH --time=12:00:00
#SBATCH --mem=32G
#SBATCH --partition=testing  # Use appropriate partition with GPU
#SBATCH --gres=gpu:1

# Set up Singularity environment
export APPTAINER_TMPDIR=$SCRATCH/.apptainer-tmp
export APPTAINER_CACHEDIR=$SCRATCH/.apptainer-cache
mkdir -p $APPTAINER_TMPDIR $APPTAINER_CACHEDIR

# Bind data directories
export APPTAINER_BINDPATH="/data1,/scratchdata"

# Container path
CONTAINER=/data1/$USER/micro_sam/micro_sam.sif

# Create logs directory for TensorBoard
LOGS_DIR="$PWD/logs"
mkdir -p $LOGS_DIR

# Run fine-tuning script with TensorBoard logging
singularity exec --nv $CONTAINER \
  python /path/to/finetune_script.py \
  --input_dir=/path/to/training/data \
  --output_dir=/path/to/save/model \
  --log_dir=$LOGS_DIR \
  --epochs=100

echo "Fine-tuning complete!"
```

### 2. Start TensorBoard on the login node

After submitting your job, you can start TensorBoard on the login node (for more detailed instructions, see the [HPC wiki TensorFlow with TensorBoard example](https://pubappslu.atlassian.net/wiki/spaces/HPCWIKI/pages/82640897/TensorFlow+with+TensorBoard+example)):

```bash
module load TensorFlow/2.4.1-fosscuda-2020b
tensorboard --port=0 --logdir=$PWD/logs
```

TensorBoard will display a message indicating which port it's using (e.g., `TensorBoard 2.4.1 at http://localhost:6006/`).

### 3. Connect to TensorBoard from your local machine

Open a new terminal on your local machine and create an SSH tunnel:

```bash
ssh -L 6006:localhost:<port> username@alice-login.hpc.rug.nl
```

Replace `<port>` with the port number shown in the TensorBoard output. If you have SSH aliases configured in your `~/.ssh/config`, you can use them:

```bash
ssh -L 6006:localhost:<port> alice1
```

Then, open your browser and navigate to:
```
http://localhost:6006
```

If data appears to be missing, use the "Reload" button in TensorBoard to refresh the data.

## Troubleshooting

### Common issues and solutions

1. **GPU not detected in container**
   - Make sure to use the `--nv` flag with Singularity
   - Check if the node has GPUs with `nvidia-smi`
   - Verify you're using a partition with GPU access

2. **Out of memory errors**
   - Increase the `--mem` allocation in your SLURM job
   - Process fewer images at once or use smaller images

3. **Container not found**
   - Verify the path to your SIF file
   - Check that the pull job completed successfully

4. **Slow processing**
   - Use a different model type (e.g., `vit_b` is faster than `vit_h`)
   - Preprocess images to reduce size if appropriate

5. **VSCode can't connect to Jupyter kernel**
   - Make sure your SSH tunnel is properly set up
   - Check that the Jupyter server is running (verify with `squeue`)
   - Try restarting the Jupyter kernel

6. **Permission denied errors**
   - Make sure your SSH key has the correct permissions (chmod 600)
   - Verify that you have access to the directories you're trying to read/write

For additional help or issues, contact your HPC administrator or open an issue on the project's GitHub repository.