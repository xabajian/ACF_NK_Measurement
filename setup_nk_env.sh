#!/bin/bash

# Name of environment
ENV_NAME="nk_contour"

echo "Creating conda environment: $ENV_NAME"

# Create environment with stable Python
conda create -y -n $ENV_NAME python=3.11

echo "Activating environment..."
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate $ENV_NAME

echo "Installing required packages..."
conda install -y numpy pandas scipy matplotlib

echo "Environment setup complete."
echo ""
echo "To activate later, run:"
echo "conda activate $ENV_NAME"