#!/bin/bash
#SBATCH --job-name=scaled_gecozh_cor_gd
#SBATCH --output=logs/cor_gd_gecozh_scaled_%j.out
#SBATCH --error=logs/cor_gd_gecozh_scaled_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=10-00:00:0
#SBATCH --partition=long

# Load Conda and activate environment
source ~/miniconda3/etc/profile.d/conda.sh
conda activate my-r-env

# Optional: ensure cmdstan is installed
# Rscript -e "cmdstanr::install_cmdstan()"

# Run the model fitting script
Rscript src/cor_gd_gecozh_scaled.R

echo "✅ Finished fitting model for gecozh scaled."
