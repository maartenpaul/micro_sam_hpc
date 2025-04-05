# micro-sam on HPC (Leiden University Alice)

## What is micro-sam?

[micro-sam](https://github.com/computational-cell-analytics/micro-sam) is a tool that adapts the Segment Anything Model (SAM) for microscopy images. It allows for powerful, AI-based automatic segmentation of biological structures in microscopy data.

## Prerequisites

Before starting, make sure you have:
- An account on the Alice HPC cluster 
- SSH keys set up for login (see [Alice documentation](https://pubappslu.atlassian.net/wiki/spaces/HPCWIKI/pages/37748788/Login+to+ALICE+or+SHARK+from+Linux#Making-logins-even-more-convenient-with-ssh-keys))

## Overview of the Process

1. Clone this repository on the HPC
2. Prepare the micro-sam container on the HPC
3. Run micro-sam to process your images
4. (Optional) Use Jupyter notebooks for interactive analysis
5. (Optional) Finetune the model on your own data

## Getting Started

### 1. Log in to the HPC and Clone the Repository

First, connect to the HPC and clone this repository:

```bash
# Connect to the HPC
ssh alice1
# Clone the repository with all scripts
git clone https://github.com/maartenpaul/micro-sam-hpc.git
cd micro-sam-hpc
```

## 2. Running micro-sam on the HPC

### Single Image Processing

Create a file named `run_microsam.sh` with the following content:

Make the following changes to the script:
- Change `/path/to/input/image.tif` to your actual input image path
- Change `/path/to/output/segmented.tif` to where you want to save the result

Then run the script:

```bash
chmod +x run_microsam.sh  # Make the script executable
sbatch run_microsam.sh    # Submit the job
```

### Processing Multiple Images

If you have many images to process, create a file named `batch_microsam.sh`:

Change the `INPUT_DIR` to the folder with your images, then run:

```bash
chmod +x batch_microsam.sh
sbatch batch_microsam.sh
```

## 3. Using Jupyter Notebooks with micro-sam

For interactive analysis, you can use Jupyter notebooks with the micro-sam container. The simplest approach is to use Visual Studio Code (VS Code) with the Remote SSH extension.

### Setup VS Code with Remote SSH for Jupyter

To use VS Code for interactive work with Jupyter notebooks on the HPC:

1. Install VS Code on your local computer: [Download VS Code](https://code.visualstudio.com/)

2. Install the "Remote - SSH" extension in VS Code

3. Follow the instructions in the VS Code documentation to create a dedicated SSH config file and set it up for the Alice HPC: [Alice VS Code Setup](https://pubappslu.atlassian.net/wiki/spaces/HPCWIKI/pages/82640897/Setting+up+VSCode+to+work+on+the+cluster)

4. Start a Jupyter server on the HPC:
   ```bash
   sbatch scripts/start_jupyter.sh
   ```

5. Check the job output for the node name and update your SSH config accordingly:
   ```bash
   cat jupyter-server-*.out
   ```

6. Connect to the HPC with VS Code using the Remote SSH extension and open Jupyter notebooks

### Using the Official micro-sam Notebooks

Once connected, you can use the official micro-sam example notebooks to explore the tool's capabilities:

1. Clone the micro-sam repository on the HPC:
   ```bash
   git clone https://github.com/computational-cell-analytics/micro-sam.git
   cd micro-sam/notebooks
   ```

2. Open the notebooks in VS Code and explore the examples, particularly:
   - `basic_usage.ipynb` for an introduction to micro-sam
   - `sam_finetuning.ipynb` for finetuning on your own data

The official [sam_finetuning.ipynb](https://github.com/computational-cell-analytics/micro-sam/blob/master/notebooks/sam_finetuning.ipynb) notebook provides detailed instructions on how to finetune SAM for your specific microscopy data.

## Troubleshooting

If you encounter any issues or have questions about using micro-sam on the HPC, please reach out to [maartenpaul on GitHub](https://github.com/maartenpaul).

Common issues and quick checks:
- Make sure your job is requesting GPU resources (`--gres=gpu:1`)
- Verify your image files are in the correct format (TIF is recommended)
- Check your job output files for error messages

## Exploring micro-sam Features

### Using the Official micro-sam Notebooks

To explore the full capabilities of micro-sam, you can use the official example notebooks:

```bash
# Clone the micro-sam repository
git clone https://github.com/computational-cell-analytics/micro-sam.git
cd micro-sam/notebooks
```

Key notebooks to explore:
- `basic_usage.ipynb` - Introduction to micro-sam's basic functionality
- `sam_finetuning.ipynb` - Detailed guide on finetuning SAM for your data

### Data Preparation for Finetuning

When finetuning SAM, organize your training data in this structure:

```
training_data/
├── images/
│   ├── image1.tif
│   ├── image2.tif
│   └── ...
└── masks/
    ├── image1_mask.tif
    ├── image2_mask.tif
    └── ...
```

The [sam_finetuning.ipynb](https://github.com/computational-cell-analytics/micro-sam/blob/master/notebooks/sam_finetuning.ipynb) notebook provides detailed guidance on preparing your data and the finetuning process.

## Troubleshooting

If you encounter any issues or have questions about using micro-sam on the HPC, please reach out to [maartenpaul on GitHub](https://github.com/maartenpaul).

Common issues and quick checks:
- Make sure your job is requesting GPU resources (`--gres=gpu:1`)
- Verify your image files are in the correct format (TIF is recommended)
- Check your job output files for error messages

## Additional Resources

- [micro-sam GitHub repository](https://github.com/computational-cell-analytics/micro-sam)
- [Segment Anything Model (SAM) paper](https://segment-anything.com)
- [Alice HPC documentation](https://pubappslu.atlassian.net/wiki/spaces/HPCWIKI)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/ssh)