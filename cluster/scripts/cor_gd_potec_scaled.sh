#!/bin/bash
#SBATCH --job-name=scaled_potec_cor_gd
#SBATCH --output=logs/cor_gd_potec_scaled_%j.out
#SBATCH --error=logs/cor_gd_potec_scaled_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=10-00:00:00
#SBATCH --partition=long

# Load Conda and activate environment
source ~/miniconda3/etc/profile.d/conda.sh
conda activate my-r-env

# Optional: ensure cmdstan is installed
# Rscript -e "cmdstanr::install_cmdstan()"

# Run the model fitting script
Rscript src/cor_gd_potec_scaled.R

echo "✅ Finished fitting model for PoTeC Scaled."
