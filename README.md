# micro-sam on HPC (Leiden University Alice)

## What is micro-sam?

[micro-sam](https://github.com/computational-cell-analytics/micro-sam) is a tool that adapts the Segment Anything Model (SAM) for microscopy images. It allows for powerful, AI-based automatic segmentation of biological structures in microscopy data.

## Prerequisites

Before starting, make sure you have:
- An account on the Alice HPC cluster 
- SSH keys set up for login with an `alice1` alias in your SSH config

## Overview of the Process

1. Clone this repository on the HPC
2. Build the micro-sam container (automatically sets up folders)
3. Use the scripts to run micro-sam on your images
4. (Optional) Finetune the model on your own data
5. (Optional) Use Jupyter notebooks for interactive analysis

## Getting Started

### 1. Log in to the HPC and Clone the Repository

First, connect to the HPC and clone this repository:

```bash
# Connect to the HPC (using the alice1 alias)
ssh alice1

# Clone the repository with all scripts
git clone https://github.com/maartenpaul/micro-sam-hpc.git
cd micro-sam-hpc
```

### 2. Build the micro-sam Container

Build the container using the included script:

```bash
# Make script executable
chmod +x scripts/build_microsam.sh
# Submit the build job
sbatch scripts/build_microsam.sh
```

This script will:
- Create a folder structure in `/data1/<username>/micro_sam` with subfolders for:
  - `input`: Place your images here for processing
  - `output`: Results will be saved here
  - `models`: Pre-trained and finetuned models are stored here
- Build the Singularity container with all required software

You can check if the job is complete with:

```bash
squeue -u $USER     # Check if job is still running
cat build-microsam-*.out  # View the output of the job
```

### 3. Run micro-sam on Your Images

#### Process a Single Image

```bash
# Run micro-sam on a single image
sbatch scripts/run_microsam.sh input/your_image.tif output/segmented_image.tif
```

#### Process Multiple Images

```bash
# Process all TIF files in the input directory
sbatch scripts/batch_microsam.sh
```

All images in the `/data1/<username>/micro_sam/input` directory will be processed and results saved to the `/data1/<username>/micro_sam/output` directory.

## Finetuning SAM for Your Data

Finetuning allows you to adapt the model to your specific microscopy data for improved segmentation.

### 1. Prepare Your Training Data

Organize your training data in this structure:

```
/data1/<username>/micro_sam/training_data/
├── images/
│   ├── image1.tif
│   ├── image2.tif
│   └── ...
└── masks/
    ├── image1_mask.tif
    ├── image2_mask.tif
    └── ...
```

### 2. Run the Finetuning Script

```bash
# Finetune the model (uses data in the training_data folder)
sbatch scripts/finetune_microsam.sh
```

### 3. Use Your Finetuned Model

```bash
# Run segmentation with your finetuned model
sbatch scripts/run_microsam_finetuned.sh input/your_image.tif output/segmented_image.tif
```

## Using Jupyter Notebooks (Optional)

For interactive analysis, you can use Jupyter notebooks with VS Code:

1. Install VS Code and the "Remote - SSH" extension on your local computer
2. Set up VS Code for the Alice HPC as described in the [Alice documentation](https://pubappslu.atlassian.net/wiki/spaces/HPCWIKI/pages/82640897/Setting+up+VSCode+to+work+on+the+cluster)
3. Start a Jupyter server:
   ```bash
   sbatch scripts/start_jupyter.sh
   ```
4. Follow the instructions in the job output to connect

The official micro-sam example notebooks are excellent resources:
- `basic_usage.ipynb` - Introduction to micro-sam
- `sam_finetuning.ipynb` - Detailed guide on finetuning

## Troubleshooting

If you encounter any issues, please contact [maartenpaul on GitHub](https://github.com/maartenpaul).

Common checks:
- Verify your image files are in TIF format
- Check your job output files for error messages
- Make sure you're using the correct paths

## Additional Resources

- [micro-sam GitHub repository](https://github.com/computational-cell-analytics/micro-sam)
- [Segment Anything Model (SAM) paper](https://segment-anything.com)
- [Alice HPC documentation](https://pubappslu.atlassian.net/wiki/spaces/HPCWIKI)